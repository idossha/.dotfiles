#!/usr/bin/env python3
"""Inspect the installed MNE-Python API without touching the user's MNE config."""

from __future__ import annotations

import argparse
import importlib
import inspect
import os
import pkgutil
import sys
import tempfile
from types import ModuleType
from typing import Any


def _prepare_env() -> None:
    os.environ.setdefault("MNE_DONTWRITE_HOME", "true")
    os.environ.setdefault("MNE_HOME", os.path.join(tempfile.gettempdir(), "mne-agent-home"))
    os.makedirs(os.environ["MNE_HOME"], exist_ok=True)


def _import_mne() -> ModuleType:
    _prepare_env()
    import mne

    return mne


def _resolve(name: str) -> Any:
    parts = name.split(".")
    if not parts or parts[0] != "mne":
        raise ValueError("Use a fully qualified MNE name, e.g. mne.io.Raw.filter")

    obj: Any = _import_mne()
    consumed = ["mne"]
    for part in parts[1:]:
        candidate_module = ".".join(consumed + [part])
        try:
            obj = importlib.import_module(candidate_module)
        except Exception:
            obj = getattr(obj, part)
        consumed.append(part)
    return obj


def _iter_modules(mne: ModuleType) -> list[ModuleType]:
    modules = [mne]
    package_path = getattr(mne, "__path__", None)
    if not package_path:
        return modules
    for info in pkgutil.walk_packages(package_path, prefix="mne."):
        name = info.name
        if any(piece in name for piece in ("._", ".tests", ".commands")):
            continue
        try:
            modules.append(importlib.import_module(name))
        except Exception:
            continue
    return modules


def _search(terms: list[str], limit: int) -> None:
    mne = _import_mne()
    lowered = [term.lower() for term in terms]
    hits: list[str] = []
    for module in _iter_modules(mne):
        for attr in dir(module):
            if attr.startswith("_"):
                continue
            full_name = f"{module.__name__}.{attr}"
            haystack = full_name.lower()
            if all(term in haystack for term in lowered):
                hits.append(full_name)
    for hit in sorted(set(hits))[:limit]:
        print(hit)


def _print_object(name: str, show_source: bool, source_lines: int) -> None:
    mne = _import_mne()
    obj = _resolve(name)
    print(f"MNE version: {mne.__version__}")
    print(f"MNE path: {mne.__file__}")
    print(f"Object: {name}")
    print(f"Type: {type(obj).__name__}")

    try:
        print(f"Signature: {inspect.signature(obj)}")
    except (TypeError, ValueError):
        pass

    try:
        print(f"Defined in: {inspect.getsourcefile(obj) or inspect.getfile(obj)}")
    except TypeError:
        pass

    doc = inspect.getdoc(obj) or ""
    if doc:
        print("\nDoc summary:")
        print("\n".join(doc.splitlines()[:25]))

    if show_source:
        try:
            source = inspect.getsource(obj).splitlines()
        except (OSError, TypeError):
            print("\nSource unavailable.")
        else:
            print("\nSource:")
            print("\n".join(source[:source_lines]))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", nargs="?", help="Fully qualified object name, e.g. mne.Epochs")
    parser.add_argument("--version", action="store_true", help="Print installed MNE version and path")
    parser.add_argument("--source", action="store_true", help="Print source snippet for the object")
    parser.add_argument("--source-lines", type=int, default=120, help="Maximum source lines to print")
    parser.add_argument("--search", nargs="+", help="Search public MNE names containing all terms")
    parser.add_argument("--limit", type=int, default=80, help="Maximum search results")
    args = parser.parse_args()

    if args.version:
        mne = _import_mne()
        print(f"MNE version: {mne.__version__}")
        print(f"MNE path: {mne.__file__}")
        return 0

    if args.search:
        _search(args.search, args.limit)
        return 0

    if not args.name:
        parser.error("provide an object name, --version, or --search")
    _print_object(args.name, args.source, args.source_lines)
    return 0


if __name__ == "__main__":
    sys.exit(main())
