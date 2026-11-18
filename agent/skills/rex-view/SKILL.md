---
name: rex-view
description: Show a picture to the user in a Rex side pane — a diagram or chart that supports an explanation, a figure being worked on, or a PDF page. Use inside a Rex terminal (REX_SESSION is set) when an explanation would be clearer with a visual than as long prose, when the user asks to see a figure or says "show me", or when iterating on an idofig or SUNA figure so each rebuild appears without asking. Not for making or restyling the figure itself (idofig), arranging panes and tabs (rex), or sessions outside Rex, where images cannot be drawn.
---

# Rex View

One viewer pane per Rex session draws SVG, PDF, PNG and JPEG with the kitty graphics protocol and
redraws a file when it changes on disk. The command is `scripts/rexview.py`, beside this file; run it
by its path. Rex has no image pane of its own and the agent's own pane cannot show images, so the
picture always goes to a neighbouring pane. It is view-only: the user cannot point at parts of it.

## Explain with a picture

When an answer describes structure, flow, a comparison over numbers or a before/after, draw it
instead of adding paragraphs: write one SVG or PNG to the scratch directory, show it, and keep the
chat reply short and pointed at the picture. One picture per idea; replace it as the conversation
moves on rather than piling up files.

```bash
scripts/rexview.py show /path/to/scratch/pipeline.svg
```

## Show a figure

```bash
scripts/rexview.py show figures/fig-main            # a directory resolves to figure.svg, figure.png, or figure.pdf
scripts/rexview.py show plot.png report.pdf --page 3
```

The first call splits a `Figures` pane to the right of the calling pane without taking focus; later
calls reuse it. It prints JSON; a non-null `problem` means the file could not be rendered. Prefer an
SVG over a PNG export, because it is rasterised at the pane's own pixel size.

Leave the pane open while iterating. After a rebuild writes the file the pane redraws by itself, so
do not call `show` again for the same file. The user pages with `n`/`p` and closes with `q`; call
`close` when the picture is no longer relevant.

## Check it yourself

```bash
scripts/rexview.py snapshot   # path of a PNG of the pane as the user sees it
```

Read that image before telling the user a picture is ready.

## Limits

Needs `uv` (the script declares Pillow), `rsvg-convert` for SVG and `pdftoppm` for PDF.
