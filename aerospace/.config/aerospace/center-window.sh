#!/bin/bash
# Usage: center-window.sh <workspace> <process> <title-suffix> <width-fraction> <height-fraction>
# Shows <workspace>, then sizes the <process> window whose title ends in <title-suffix> to the given
# fractions of that monitor and centers it. AeroSpace parks windows of hidden workspaces off-screen,
# so the workspace has to be visible before the window can be placed.
ws=$1 proc=$2 suffix=$3 fw=$4 fh=$5

aerospace workspace "$ws"
screen=$(aerospace list-monitors --focused --format '%{monitor-appkit-nsscreen-screens-id}')

exec osascript -l JavaScript - "$proc" "$suffix" "$fw" "$fh" "$screen" <<'JS'
ObjC.import('AppKit');
function run(argv) {
  const [proc, suffix, fw, fh, screen] = argv;
  const se = Application('System Events');
  let win;
  // The callback can fire before the window has its final title.
  for (let i = 0; i < 30 && !win; i++) {
    win = se.processes.byName(proc).windows().find(w => w.name().endsWith(suffix));
    if (!win) delay(0.1);
  }
  if (!win) return;
  const screens = $.NSScreen.screens.js;
  const mainH = screens[0].frame.size.height;
  const f = (screens[Number(screen) - 1] || screens[0]).frame;
  // NSScreen measures from the main screen's bottom-left; System Events from its top-left.
  const sx = f.origin.x, sy = mainH - f.origin.y - f.size.height;
  const w = Math.round(f.size.width * Number(fw)), h = Math.round(f.size.height * Number(fh));
  win.size = [w, h];
  win.position = [Math.round(sx + (f.size.width - w) / 2), Math.round(sy + (f.size.height - h) / 2)];
}
JS
