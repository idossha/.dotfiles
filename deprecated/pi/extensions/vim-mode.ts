/** Lightweight Vim-style modal editor for Pi.
 * Insert mode is normal Pi editing. Escape enters normal mode.
 * Normal mode supports h/j/k/l, w/b, 0/$, x, i/a/I/A, o/O, dd, u, p.
 */
import { CustomEditor, type ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

class VimModeEditor extends CustomEditor {
  private mode: "normal" | "insert" = "insert";
  private pending = "";

  private pass(seq: string): void {
    super.handleInput(seq);
  }

  handleInput(data: string): void {
    if (matchesKey(data, "escape")) {
      this.mode = "normal";
      this.pending = "";
      return;
    }

    if (this.mode === "insert") {
      super.handleInput(data);
      return;
    }

    // Keep app-level control shortcuts working in normal mode.
    if (data.length !== 1 || data.charCodeAt(0) < 32) {
      super.handleInput(data);
      return;
    }

    if (this.pending === "d") {
      this.pending = "";
      if (data === "d") {
        this.pass("\x01"); // line start
        this.pass("\x15"); // delete to line start (no-op after home, but keeps kill-ring sane)
        this.pass("\x0b"); // delete to line end
        return;
      }
    }

    switch (data) {
      case "i": this.mode = "insert"; return;
      case "a": this.mode = "insert"; this.pass("\x1b[C"); return;
      case "I": this.mode = "insert"; this.pass("\x01"); return;
      case "A": this.mode = "insert"; this.pass("\x05"); return;
      case "o": this.mode = "insert"; this.pass("\x05"); this.pass("\n"); return;
      case "O": this.mode = "insert"; this.pass("\x01"); this.pass("\n"); this.pass("\x1b[A"); return;
      case "h": this.pass("\x1b[D"); return;
      case "j": this.pass("\x1b[B"); return;
      case "k": this.pass("\x1b[A"); return;
      case "l": this.pass("\x1b[C"); return;
      case "w": this.pass("\x1bf"); return;
      case "b": this.pass("\x1bb"); return;
      case "0": this.pass("\x01"); return;
      case "$": this.pass("\x05"); return;
      case "x": this.pass("\x1b[3~"); return;
      case "u": this.pass("\x1f"); return; // ctrl+_
      case "p": this.pass("\x19"); return; // ctrl+y kill-ring paste
      case "d": this.pending = "d"; return;
      default:
        // Ignore printable characters in normal mode.
        return;
    }
  }

  render(width: number): string[] {
    const lines = super.render(width);
    if (lines.length === 0) return lines;
    const labelText = this.mode === "normal" ? " NORMAL " : " INSERT ";
    const label = this.mode === "normal" ? `\x1b[30;43m${labelText}\x1b[0m` : `\x1b[30;42m${labelText}\x1b[0m`;
    const last = lines.length - 1;
    if (visibleWidth(lines[last]!) >= labelText.length) {
      lines[last] = truncateToWidth(lines[last]!, Math.max(0, width - labelText.length), "") + label;
    }
    return lines;
  }
}

export default function activate(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;
    ctx.ui.setEditorComponent((tui, theme, keybindings) => new VimModeEditor(tui, theme, keybindings));
  });
}
