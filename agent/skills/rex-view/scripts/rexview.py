#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow>=10"]
# ///
"""Show figures in a Rex pane.

show PATH...   open or reuse the viewer pane beside the caller
snapshot       print the path of a PNG of the pane as the user sees it
close          stop the viewer

The viewer draws with the kitty graphics protocol at the pane's own pixel size
and redraws when the file changes on disk.
"""
from __future__ import annotations

import argparse
import base64
import fcntl
import io
import json
import os
import re
import select
import shutil
import signal
import struct
import subprocess
import sys
import termios
import time
import tty
from pathlib import Path

from PIL import Image

RASTER = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".tif", ".tiff", ".bmp"}


def status_text(text: str) -> str:
    return re.sub(r"[\x00-\x1f\x7f-\x9f]", "", text)


def page_count(path: Path) -> int:
    if path.suffix.lower() != ".pdf":
        return 1
    info = subprocess.run(["pdfinfo", str(path)], capture_output=True, text=True).stdout
    m = re.search(r"^Pages:\s+(\d+)", info, re.M)
    return int(m.group(1)) if m else 1


def rasterise(path: Path, page: int, max_w: int, max_h: int) -> Image.Image:
    """The file as an image that fits max_w x max_h, rendered at that size where the format allows."""
    kind = path.suffix.lower()
    if kind == ".svg":
        png = subprocess.run(["rsvg-convert", "-w", str(max_w), "-h", str(max_h), "--keep-aspect-ratio",
                              "-f", "png", str(path)], capture_output=True, check=True).stdout
        image = Image.open(io.BytesIO(png)).convert("RGBA")
    elif kind == ".pdf":
        png = subprocess.run(["pdftoppm", "-png", "-f", str(page), "-l", str(page), "-scale-to",
                              str(max(max_w, max_h)), str(path)], capture_output=True, check=True).stdout
        image = Image.open(io.BytesIO(png)).convert("RGBA")
    else:
        image = Image.open(path).convert("RGBA")
    scale = min(max_w / image.width, max_h / image.height)
    if abs(scale - 1) > 0.002:
        size = (max(int(image.width * scale), 1), max(int(image.height * scale), 1))
        image = image.resize(size, Image.LANCZOS)
    white = Image.new("RGBA", image.size, "white")   # transparent figures stay readable on a dark pane
    return Image.alpha_composite(white, image).convert("RGB")


def resolve(arg: str) -> Path:
    path = Path(arg).expanduser().resolve()
    if path.is_dir():
        for name in ("figure.svg", "figure.png", "figure.pdf"):
            if (path / name).exists():
                return path / name
        raise SystemExit(f"rexview: no figure.svg in {path}")
    if not path.exists():
        raise SystemExit(f"rexview: {path} does not exist")
    if path.suffix.lower() not in RASTER | {".svg", ".pdf"}:
        raise SystemExit(f"rexview: cannot show {path.suffix or 'this'} files (svg, pdf, png, jpeg)")
    return path


class Viewer:
    BACKGROUND = (24, 24, 24)

    def __init__(self, state: Path):
        self.state = state
        self.fd = os.open("/dev/tty", os.O_RDWR)
        self.files: list[Path] = []
        self.index, self.page, self.pages = 0, 1, 1
        self.request_seen = 0.0
        self.mtime = 0.0
        self.geometry = None            # (cols, rows, px_w, px_h)
        self.reported_px = None         # from CSI 14t, when the ioctl carries no pixel size
        self.image: Image.Image | None = None
        self.message = ""
        self.buffer = b""
        self.dirty = True

    def write(self, data: bytes | str):
        data = data.encode() if isinstance(data, str) else data
        while data:
            try:
                data = data[os.write(self.fd, data):]
            except BlockingIOError:
                select.select([], [self.fd], [])

    def size(self):
        rows, cols, px_w, px_h = struct.unpack("HHHH", fcntl.ioctl(self.fd, termios.TIOCGWINSZ, b"\0" * 8))
        if not px_w or not px_h:
            px_w, px_h = self.reported_px or (cols * 8, rows * 16)
        return cols, rows, px_w, px_h

    def run(self):
        saved = termios.tcgetattr(self.fd)
        tty.setraw(self.fd)
        self.write("\x1b[?1049h\x1b[?25l\x1b[14t")
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        signal.signal(signal.SIGHUP, lambda *_: sys.exit(0))
        try:
            while True:
                if select.select([self.fd], [], [], 0.2)[0]:
                    self.buffer += os.read(self.fd, 65536)
                    if self.handle_input() == "quit":
                        return
                self.poll_files()
                geometry = self.size()
                if geometry != self.geometry:
                    self.geometry, self.image, self.dirty = geometry, None, True
                    self.write("\x1b[14t")
                if self.dirty:
                    self.draw()
        finally:
            (self.state / "viewer.json").unlink(missing_ok=True)
            try:    # the pane may already be gone
                self.write("\x1b_Ga=d,d=A,q=2\x1b\\\x1b[?25h\x1b[?1049l")
                termios.tcsetattr(self.fd, termios.TCSADRAIN, saved)
            except OSError:
                pass

    def handle_input(self):
        token = re.compile(rb"\x1b\[4;(\d+);(\d+)t|\x1b_G[^\x1b]*\x1b\\|\x1b\[[0-9;?<]*[A-Za-z~]|\x1b|[^\x1b]")
        pos = 0
        while (m := token.match(self.buffer, pos)):
            text = m.group()
            if text == b"\x1b" and m.end() == len(self.buffer) and len(self.buffer) > 1:
                break                       # an escape sequence split across reads
            pos = m.end()
            if m.group(1):
                self.reported_px = (int(m.group(2)), int(m.group(1)))
            elif text in (b"q", b"\x03"):
                return "quit"
            elif text in (b"n", b" ", b"\x1b[C", b"\x1b[B"):
                self.step(1)
            elif text in (b"p", b"\x1b[D", b"\x1b[A"):
                self.step(-1)
        self.buffer = self.buffer[pos:]

    def step(self, delta: int):
        if not self.files:
            return
        if 1 <= self.page + delta <= self.pages:
            self.page += delta
        elif len(self.files) > 1:
            self.index = (self.index + delta) % len(self.files)
            self.pages = page_count(self.files[self.index])
            self.page = 1 if delta > 0 else self.pages
        else:
            return
        self.image, self.mtime, self.dirty = None, 0.0, True

    def poll_files(self):
        request = self.state / "request.json"
        try:
            stamp = request.stat().st_mtime
        except OSError:
            stamp = 0.0
        if stamp and stamp != self.request_seen:
            try:
                data = json.loads(request.read_text())
            except ValueError:
                return
            self.request_seen = stamp
            self.files = [Path(p) for p in data["files"]]
            self.index = 0
            self.pages = page_count(self.files[0]) if self.files else 1
            self.page = min(max(int(data.get("page") or 1), 1), self.pages)
            self.image, self.mtime, self.dirty = None, 0.0, True
        if self.files:
            try:
                mtime = self.files[self.index].stat().st_mtime
            except OSError:
                return
            if mtime != self.mtime and time.time() - mtime > 0.15:   # let the writer finish
                self.mtime, self.image, self.dirty = mtime, None, True

    def draw(self):
        self.dirty = False
        cols, rows, px_w, px_h = self.geometry
        if rows < 3 or cols < 10:
            return
        image_rows = rows - 1
        canvas_w, canvas_h = px_w, int(px_h * image_rows / rows)
        canvas = Image.new("RGB", (canvas_w, canvas_h), self.BACKGROUND)
        if self.files and self.image is None:
            try:
                self.image = rasterise(self.files[self.index], self.page, canvas_w, canvas_h)
                self.message = ""
            except (subprocess.CalledProcessError, OSError, ValueError) as error:
                detail = getattr(error, "stderr", b"") or str(error).encode()
                lines = detail.decode(errors="replace").strip().splitlines() or [type(error).__name__]
                self.message = "cannot render: " + status_text(lines[-1])[:120]
        if self.image is not None:
            canvas.paste(self.image, ((canvas_w - self.image.width) // 2, (canvas_h - self.image.height) // 2))
        png = io.BytesIO()
        canvas.save(png, "PNG", compress_level=1)
        (self.state / "view.png").write_bytes(png.getvalue())   # what `snapshot` hands to an agent
        data = base64.standard_b64encode(png.getvalue())
        out = [b"\x1b[?2026h\x1b[H"]
        for start in range(0, len(data), 4096):
            head = f"a=T,f=100,i=1,p=1,q=2,C=1,c={cols},r={image_rows}," if start == 0 else ""
            more = 1 if start + 4096 < len(data) else 0
            out.append(f"\x1b_G{head}m={more};".encode() + data[start:start + 4096] + b"\x1b\\")
        out.append(f"\x1b[{rows};1H\x1b[2K\x1b[7m{self.status(cols)}\x1b[0m\x1b[?2026l".encode())
        self.write(b"".join(out))
        info = {"pid": os.getpid(), "block": os.environ.get("REX_BLOCK"),
                "file": str(self.files[self.index]) if self.files else None, "page": self.page,
                "px": [px_w, px_h], "message": self.message, "drawn": time.time()}
        tmp = self.state / "viewer.tmp"
        tmp.write_text(json.dumps(info))
        tmp.replace(self.state / "viewer.json")

    def status(self, cols: int) -> str:
        if not self.files:
            return " waiting for a figure ".ljust(cols)[:cols]
        path = self.files[self.index]
        label = f"{path.parent.name}/{path.name}" if path.name.startswith("figure.") else path.name
        parts = [status_text(label)]
        if self.pages > 1:
            parts.append(f"page {self.page}/{self.pages}")
        if len(self.files) > 1:
            parts.append(f"file {self.index + 1}/{len(self.files)}")
        if self.message:
            parts.append(status_text(self.message))
        if self.pages > 1 or len(self.files) > 1:
            parts.append("n/p")
        parts.append("q closes")
        return (" " + "  │  ".join(parts) + " ").ljust(cols)[:cols]


def state_dir() -> Path:
    base = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "rexview"
    session = re.sub(r"[^A-Za-z0-9-]", "_", os.environ.get("REX_SESSION") or "default")
    path = base / session
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    path.chmod(0o700)
    return path


def viewer_info(state: Path) -> dict | None:
    try:
        info = json.loads((state / "viewer.json").read_text())
        os.kill(info["pid"], 0)
        command = subprocess.run(["ps", "-p", str(info["pid"]), "-o", "command="],
                                 capture_output=True, text=True, check=True).stdout
        if "rexview.py" not in command or "_serve" not in command:
            return None
        return info
    except (OSError, TypeError, ValueError, KeyError, subprocess.CalledProcessError):
        return None


def cmd_show(args):
    files = [resolve(p) for p in args.paths]
    for tool, kinds in (("rsvg-convert", {".svg"}), ("pdftoppm", {".pdf"})):
        if any(f.suffix.lower() in kinds for f in files) and not shutil.which(tool):
            raise SystemExit(f"rexview: {tool} is not installed")
    state = state_dir()
    tmp = state / "request.tmp"
    tmp.write_text(json.dumps({"files": [str(f) for f in files], "page": args.page}))
    tmp.replace(state / "request.json")
    info = viewer_info(state)
    opened = False
    if not info:
        session, block = os.environ.get("REX_SESSION"), os.environ.get("REX_BLOCK")
        if not (session and block and shutil.which("rex")):
            raise SystemExit("rexview: not inside a Rex terminal (REX_SESSION and REX_BLOCK are unset)")
        subprocess.run(["rex", "split", "-s", session, "-b", block, f"--split={args.side}", "--ratio",
                        str(args.ratio), "--label", "Figures", "--focus=false", "--json", "--",
                        str(Path(__file__).resolve()), "_serve", str(state)],
                       check=True, capture_output=True)
        opened = True
    started = time.time()
    while time.time() < started + 60:
        info = viewer_info(state)
        if info and info.get("file") == str(files[0]) and info.get("drawn", 0) >= started - 1:
            break
        time.sleep(0.2)
    else:
        raise SystemExit("rexview: the viewer pane did not draw the figure within 60 s")
    print(json.dumps({"showing": info["file"], "pane": info.get("block"), "opened_pane": opened,
                      "files": len(files), "problem": info.get("message") or None}))


def cmd_snapshot(_args):
    state = state_dir()
    if not viewer_info(state) or not (state / "view.png").exists():
        raise SystemExit("rexview: no viewer is running")
    print(state / "view.png")


def cmd_close(_args):
    info = viewer_info(state_dir())
    if info:
        os.kill(info["pid"], signal.SIGTERM)
    print(json.dumps({"closed": bool(info)}))


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="command", required=True)
    show = sub.add_parser("show", help="show figures in the viewer pane")
    show.add_argument("paths", nargs="+", help="svg, pdf, png or jpeg files, or a figure directory")
    show.add_argument("--page", type=int, default=1)
    show.add_argument("--side", default="right", choices=["right", "left", "above", "below"])
    show.add_argument("--ratio", type=int, default=45)
    show.set_defaults(run=cmd_show)
    sub.add_parser("snapshot", help="print the path of a PNG of the pane as the user sees it"
                   ).set_defaults(run=cmd_snapshot)
    sub.add_parser("close", help="stop the viewer").set_defaults(run=cmd_close)
    serve = sub.add_parser("_serve")
    serve.add_argument("state", type=Path)
    serve.set_defaults(run=lambda a: Viewer(a.state).run())
    args = parser.parse_args()
    args.run(args)


if __name__ == "__main__":
    main()
