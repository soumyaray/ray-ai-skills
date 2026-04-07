---
name: ray-poster-create
description: Generate or update an event poster PDF. Use this skill whenever the user wants to change poster content (text, dates, speaker info, sponsors), adjust poster layout or styling (fonts, spacing, colors, sections), add/remove/resize logos or images, or regenerate the poster PDF. Also use when the user mentions "poster", "flyer", "event poster", or references event-poster/ files.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# ray-poster-create: Event Poster Generation & Updates

Generate or update an event poster. The poster is an A4 single-page PDF built with Python (reportlab + PIL), with content separated from layout.

> Throughout this skill the example project uses the directory `event-poster/`, the output file `poster.pdf`, and asset names like `logo-left.png`, `logo-right.png`, `speaker-photo.png`, etc. These are illustrative defaults — use whatever directory and filenames suit your project, and update `generate_poster.py` accordingly.

## Architecture: Content vs. Layout

The poster has a clean separation between what it says and how it looks:

- **`event-poster/poster.yaml`** — all editable text: title, subtitle, intro paragraphs, themes, agenda items, projects, speaker bio, event details, footer credits. Edit content here.
- **`event-poster/generate_poster.py`** — rendering: layout structure, styles, colors, spacing, image processing. Edit presentation here.
- **`event-poster/assets/`** — source images (logos, speaker photo, theme icons, QR code) and cached generated files (circular crops, trimmed logos, small icons).

This separation matters because content changes (fixing a typo, updating a time) should never require touching Python, and layout changes (adjusting font sizes, rearranging sections) should never require hunting through text strings.

## Workflow

### Creating a new poster from scratch

When building a poster for the first time (or substantially redesigning one):

1. **Gather content** — ask the user for: event title, subtitle, description, agenda/sections, speaker info, date/time/venue, sponsors/logos, and any branding requirements (colors, fonts).
2. **Create `poster.yaml`** — populate all text content into the YAML structure (see existing file for the schema).
3. **Collect image assets** — ask the user to provide source images (logos, speaker photo, illustrations) and place them in `event-poster/assets/`. For any images not yet available, use the `ImagePlaceholder` flowable class in the script (it draws a labeled rounded rectangle with diagonal cross lines) so the layout can proceed without blocking on assets.
4. **Build `generate_poster.py`** — create the rendering script. Start with the existing one as a template. The script uses reportlab with canvas-level drawing for backgrounds and platypus flowables for text content.
5. **Generate small icons with PIL** — for inline icons (map pins, transport, etc.), generate them programmatically rather than relying on emoji (Helvetica can't render emoji). Use the `make_map_pin_icon` / `make_bus_icon` pattern in the existing script.
6. **Iterate visually** — regenerate and preview after each structural change. Expect 2-3 rounds of spacing adjustments to get everything fitting on a single A4 page.

If the user needs images generated (illustrations, icons, theme graphics), offer to create them with PIL or suggest they generate them separately with an image generation tool and provide the files for `assets/`.

### For content changes (text, dates, names)

1. Edit `event-poster/poster.yaml`
2. Regenerate and preview (see below)

### For layout/style changes (fonts, spacing, colors, sections)

1. Read `event-poster/generate_poster.py` to understand current layout
2. Make targeted edits to styles, spacers, or structure
3. Regenerate and preview

### For image changes (logos, photos, icons)

1. Place source images in `event-poster/assets/`
2. Update references in `generate_poster.py`
3. Delete any cached derivatives (circular crops, trimmed versions) from `assets/` so they regenerate
4. Regenerate and preview

### Regenerate and preview

Always run both steps together:

```bash
cd event-poster && python generate_poster.py
qlmanage -t -s 1400 -o /tmp poster.pdf 2>/dev/null
```

Then read `/tmp/poster.pdf.png` to visually verify.

The PDF itself is too large (~2MB) to read directly — always convert to PNG preview first. This is a hard constraint; do not attempt to read the PDF with the Read tool.

## Example Page Layout (top to bottom)

A typical event poster built with this skill might lay out as follows. Adapt these sections to fit your event — add, remove, reorder, or rename them in `generate_poster.py`.

1. **Header band** — dark background drawn by a `draw_header_band` page callback. Typically contains: left-side logo, center title + subtitle + tagline, right-side logo.
2. **Intro paragraphs** — one or two short paragraphs describing the event
3. **Audience bar** — light tag strip: who it's for + format
4. **Content grid** — 2x2 (or NxM) cards with icons covering the main themes/topics
5. **Agenda / sessions** — numbered card strips (left) with an illustration (right)
6. **Secondary grid** (optional) — additional grid of cards (e.g., projects, sponsors, partners)
7. **Speaker / organizer card** — circular photo + name/title/bio on light background
8. **Event info band** — dark band with QR code, date/time, venue/location with icons
9. **Footer credit** — standalone line below the event band (e.g., co-organizer attribution)

## Critical Constraints

### Single-page A4
Everything must fit on one page. After any change that adds content or increases font sizes, always preview to check for page overflow. If content spills to page 2, compensate by:
- Reducing spacers between sections (the `Spacer(1, N)` calls throughout `build_poster`)
- Slightly reducing font sizes or leading
- Tightening table padding

### Header band overlap
The header band height (`HEADER_BAND_H`) is independent of the content flowables. If header content changes height (different logos, different text), the intro text may start on top of the dark band. After any header change, verify visually that intro text begins fully below the band edge. Adjust `HEADER_BAND_H` and the post-header spacer together.

### Emoji rendering
Helvetica cannot render emoji characters — they show as squares. For inline icons (map pin, bus, etc.), generate small PNG icons with PIL and use them as inline images via the `_icon_row` helper.

### Cached images
The script caches generated images in `assets/` (circular crops, trimmed logos, small icons). These only regenerate if the cached file is missing. When changing source images or icon generation code, delete the cached files first (substitute your own filenames):
```bash
rm -f event-poster/assets/logo-right-trimmed.png
rm -f event-poster/assets/icon-map-pin.png event-poster/assets/icon-bus.png
rm -f event-poster/assets/speaker-photo-circle.png
```

### Logo sizing
Logos from different sources have different amounts of whitespace padding. When two logos need to appear the same size, trim whitespace first (PIL `getbbox()` + `crop()`), then set the same display dimensions. The example script does this for the right-side logo.

### Text wrapping
Control orphaned words or awkward line breaks by inserting `<br/>` tags directly in the YAML content. Reportlab reflows text within its column width, so source-code line breaks in YAML have no effect on rendering.

## Color Palette

Key colors defined as `CLR_*` constants at the top of `generate_poster.py`:

| Role | Hex |
|---|---|
| Dark backgrounds (header, event band) | `#102a43` |
| Accent (headings, links, badges) | `#2a7ab5` |
| Warm highlight | `#e07a2f` |
| Body text | `#2d3748` |
| Muted text | `#718096` |
| Card backgrounds | `#edf2f7` |
| Tag background | `#e8f0f8` |

## Troubleshooting & Errors to Avoid

These are real issues encountered during poster development — the skill should prevent them from recurring.

### Page overflow is the most common issue
Every content or font change risks pushing content to page 2. The fix is always the same: reduce spacers, tighten padding, or slightly reduce font sizes. But the better approach is to **preview after every single change** rather than making multiple changes and then discovering overflow. Make one change, regenerate, preview, confirm — then make the next change.

### Reading the PDF directly fails silently
The generated PDF is ~2MB. Reading it with the Read tool either fails or returns unusable output. Always convert to PNG first via `qlmanage`. This wasted multiple turns before being identified.

### Emoji characters render as squares
Helvetica (reportlab's built-in font) cannot render Unicode emoji. Characters like `&#128205;` (map pin) or `&#128652;` (bus) show as filled squares in the PDF. The solution is to generate small icon PNGs with PIL and use them as inline `Image` flowables via a helper like `_icon_row`. Never use emoji HTML entities in poster text that will be rendered by reportlab.

### Logo size mismatch despite identical dimensions
Two logos set to the same pixel dimensions (e.g., 0.8 inch) can appear very different sizes if one image has whitespace padding and the other doesn't. Always trim whitespace from logo images using PIL's `getbbox()` + `crop()` before sizing. Don't try to compensate by making one logo larger — that approach creates header overflow and is fragile.

### Cached images block updates
The script checks `if not os.path.exists(cached_path)` before generating derived images. If you change the source image or the generation parameters, the old cached version persists. Always delete cached files before regenerating:
```bash
rm -f event-poster/assets/{logo-right-trimmed,speaker-photo-circle,icon-map-pin,icon-bus}.png
```

### Header band and content are independent
The dark header band is drawn by a page-level canvas callback at a fixed height. Content flowables start at `topMargin` and flow downward independently. These two systems don't know about each other, so changing one without adjusting the other causes overlap (text on dark band) or excessive gaps. After any header change, tune both `HEADER_BAND_H` and the post-header `Spacer` together, and always verify visually.

### PyYAML may not be installed
The `yaml` module requires `pyyaml`. If it's not available, install with `pip3 install --break-system-packages pyyaml` (macOS) or `pip install pyyaml`.

## Dependencies

- Python 3 with: `reportlab`, `Pillow`, `pyyaml`
- macOS `qlmanage` for PDF-to-PNG preview

## File Reference

| File | Purpose | Edit when... |
|---|---|---|
| `event-poster/poster.yaml` | All editable text content | Changing any words, dates, names, descriptions |
| `event-poster/generate_poster.py` | Rendering script (layout, styles, colors) | Changing visual design, adding/removing sections, adjusting spacing |
| `event-poster/assets/` | Images: source, generated, cached | Adding logos, photos, icons; delete cached files to force regeneration |
| `event-poster/poster.pdf` | Generated output | Never edit directly — regenerate from script |

### Assets folder contents

The names below are illustrative — use whatever naming suits your project, and update `generate_poster.py` to match.

Source images (provided by user, checked in):
- `logo-left.png` — left-side header logo source
- `logo-right.png` — right-side header logo source (a trimmed version is typically cached)
- `speaker-photo.png` — speaker headshot source
- `icon-<theme>.png` — theme card icons (one per content card)
- `illustration-<name>.png` — large illustration beside an agenda or section
- `qr-register.png` — registration QR code

Cached/generated (auto-created, delete to regenerate):
- `logo-left-circle.png` — circular crop of left logo (if needed)
- `logo-right-trimmed.png` — whitespace-trimmed right logo
- `speaker-photo-circle.png` — circular crop of speaker photo
- `icon-map-pin.png`, `icon-bus.png` — small PIL-generated icons for the event info band

## Exporting PNG for Social Media

When the user wants a PNG for sharing on Facebook, LinkedIn, etc., do **not** use `sips` alone — it produces a PNG with a transparent background (the PDF's white page background is not embedded as opaque). Instead, convert the PDF to PNG and then flatten transparency onto a white background:

```python
from PIL import Image
import subprocess

subprocess.run(['sips', '-s', 'format', 'png', '--resampleWidth', '2400',
    'event-poster/poster.pdf',
    '--out', '/tmp/poster-transparent.png'], check=True)

img = Image.open('/tmp/poster-transparent.png').convert('RGBA')
bg = Image.new('RGBA', img.size, (255, 255, 255, 255))
bg.paste(img, (0, 0), img)
bg.convert('RGB').save('event-poster/poster.png', 'PNG')
```

Key points:
- `sips` PDF-to-PNG conversion treats the page background as transparent
- Flatten onto an opaque white `RGBA` background with PIL before saving
- Save as `RGB` (not `RGBA`) so there is no alpha channel in the final file
- 2400px width produces a high-quality image suitable for social media
