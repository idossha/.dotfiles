---
name: idofig
description: >-
  Make, fix or refine a publication figure the idofig way — a figure is one
  directory (figures/<id>/): matplotlib producer scripts draw panels at their
  printed size, figure.json places panels and letters, style.json refines named
  parts. Use whenever the user asks to create a figure, fix a figure's layout,
  move a panel letter, nudge a label or legend, restyle part of a plot, check a
  figure against a journal, or works in a folder with figures/*/figure.json or
  suna.json — including inside a SUNA project.
---

# idofig — reproducible, editable publication figures

The contract lives with idofig, not in this skill: read `SPEC.md` (file formats, edit
ops, properties, checks) and `README.md` (the idea) in the idofig checkout —
`~/00_development/idofig/` on this machine, else https://github.com/idossha/idofig.
In a SUNA project also read SUNA's `FIGURES.md` (the `suna` skill says where).

## The model — one place for every adjustment

| to change | edit | unit | cost |
|---|---|---|---|
| what is drawn (data, marks, text wording) | the producer script | — | panel redraw |
| a panel's position / size | `figure.json` `panels[].place` | mm | recompose / redraw on w,h |
| all letters (size, case, weight, wrapper, color, offset) | `figure.json` `letters` | pt / mm | recompose |
| one panel's letter position | `figure.json` `panels[].letter_offset_mm: [dx, dy]` | mm, y down | recompose |
| a part's look (colour, width, font, text, visibility) | `panels/<p>/style.json` | pt … | panel redraw |
| a text or legend part's position | `style.json` props `dx_mm`, `dy_mm` | mm, y down | panel redraw |
| tick marks of an axis | `style.json` on the axis part: `tickdir`, `ticklength`, `tickwidth` | pt | panel redraw |
| marks over the figure (arrows, brackets, boxes, text) | `figure.json` `annotations` | mm, anchored to parts/data | recompose |

## Rules

1. **Scripts own what is drawn; files refine it by name.** Never hand-edit `panel.svg`,
   `manifest.json` or `figure.svg` — they are builds. Never move a whole panel to fix where
   its letter sits: use `letter_offset_mm`. Never bake a nudge into a script when a
   `dx_mm`/`dy_mm` override says it by name (a script change is right when the drawing itself
   is wrong: glyphs, wording, data, layout of the axes).
2. **Edit through the ops when you can** — `python -m idofig rpc update_figure '{…}'` /
   `update_style '{…}'` (params are one JSON object; SPEC "Edit operations") validate,
   re-read and write atomically; a misspelt field is an error, never ignored. Hand edits are
   fine if a build validates them — but a hand-added `letter_offset_mm` or `letters.color`
   needs `"schema": 3` with it (the ops set it), so an older idofig refuses the file
   instead of drawing it wrong.
3. **Nothing derived is stored**: figure numbers never; each panel stores its letter string,
   drawn at compose time from the figure-wide `letters` style plus its own offset.
4. **Checks are advisory** (`idofig check`): text below the journal's floor, parts outside
   their panel, panels past the figure edge, thin strokes, letter size. Fix them in the
   right file; never invent a journal number the journal does not state.
5. **Reproducible:** `python figures/<id>/make.py` equals `idofig build`; same inputs, same
   bytes. Rebuild with `python -m idofig build [<fig>]`, then `idofig status --exit-code`.

## Loop

`idofig parts <fig> <panel>` names what you can address → edit the right file (table) →
`idofig build` → render `figure.svg` (headless Chromium or `rsvg-convert`) and LOOK at it →
`idofig check`. In SUNA, the canvas does the same edits: drag a letter, drag or arrow-nudge
a label/legend, the inspector for everything else.
