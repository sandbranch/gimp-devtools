# Status of the GIMP 3 plug-in work

Where everything stands, and what comes next. Last updated 2026-09-26 (overnight).

## The plan

Plug-ins many of us used in GIMP 2 and that have not reached GIMP 3:

- A) port the abandoned ones, and fix what is wrong with them;
- B) offer the work upstream where that is possible;
- C) port them properly: 16-bit and float images, GIMP 3 dialogs, no
  8-bit shortcuts;
- D) host everything on github.com/sandbranch (public), and open the
  upstream pull requests from there.

GIMP 3 has non-destructive filters (live preview, editable later) only for
GEGL operations, not for plug-ins. So where it fits, a filter exists in
both forms: the ported plug-in (for upstream and GIMP 2 habits) and a GEGL
operation (the future).

## Repositories

All under `~/store/code/sandbranch`, pushed to github.com/sandbranch.

| Repo | What | Branch | State |
|---|---|---|---|
| gimp-devtools | build and test scripts for all of them (this repo) | main | done; used by all builds below |
| gimp-wavelet-denoise | Wavelet Denoise plug-in, ported | gimp3 (default), gimp3-upstream | works, 16-bit and float; not yet offered upstream |
| gimp-wavelet-sharpen | Wavelet Sharpen plug-in, ported | gimp3 (default), gimp3-upstream | works; not yet offered upstream |
| gegl-wavelet | `wavelet:sharpen` and `wavelet:denoise` as GEGL operations | main | work, same output as the plug-ins; installed and in use |
| gimp-lqr | Liquid Rescale | gimp3 (default) | works; builds liblqr itself (meson subproject); polish open |
| gimp-lensfun | lens correction with the Lensfun database, plug-in and GEGL filter | gimp3 (default) | rewritten for GIMP 3; lensfun:correct keeps it editable; installed |
| gegl-underwater | underwater filters: marine snow removal (works), color correction (first version works) | main | both tested; color tuned on 42 Commons photos |
| gimp-bimp | BIMP, batch processing | gimp3 (default) | ported; 31 batch tests pass; window tested; installed |
| gegl-depth-blur | Depth Blur: blur by a depth map (successor to Focus Blur) | main | first version works (command line and GIMP); on GitHub |
| gimp-tileset-export | Tileset Export: PNG plus Tiled .tsx/.tsj and Godot .tres from an XCF (grid, properties, collision paths, animations, extrusion) | main | works; 95 checks (headless GIMP, Tiled, isolated Godot, Broadway GUI); installed. docs/godot.md: an XCF importer for Godot is feasible |
| gimp-blender-link | GIMP Link for Blender: Edit in GIMP / Send to Blender, layered XCF with UV link layers, island masks, seam bleed; coexists with the Krita links | main | works end to end; 223 checks (headless Blender and GIMP, Broadway GUI); installed (2026-09-27) |
| gegl-lut | Color Lookup (LUT): .cube, .3dl and Hald CLUTs as a non-destructive GEGL filter (Colors > Color Lookup), LGPL-3.0+ for upstream | main | works; 205 checks (also under ASan), GIMP checks, matches FFmpeg to 1.8e-7; installed. GEGL png-load and tiff-load bugs found (PLAN.md), not reported yet |
| gimp-layerfx | Layer Effects (Jonathan Stipe, GPL-3.0+) ported to GIMP 3 and Python 3: 11 Photoshop-style effects as separate layers with their own blend modes, reapply | main | all 11 work; 72 checks pass (headless and Broadway GUI); installed |
| gimp-lqr-tng | Liquid Rescale TNG (was Liquid Rescale Paint): seam carving with keep, remove and straight painted in its dialog, live preview; after Carlo Baldassi's Liquid Rescale | main | does all the port does and more; 57 GIMP cases + 30 unit tests pass, also under ASan; 7 GUI checks; installed |
| gegl-adjustments | Selective Color, Black & White, Blend If and luminosity masks as GEGL filters (Colors), plus Create Luminosity Masks; LGPL-3.0+ | main | works; 130 checks (also under ASan), 129 cross-checks against FFmpeg, 78 GIMP checks; installed and on GitHub (2026-09-27) |
| gimp-pixel-scale | pixel art scalers hqx, xBR, Scale2x/3x/4x: GEGL filters plus Image > Scale Pixel Art (was gegl-pixel-scale) | main | works; 28 of 28 byte-exact against the references, 67 checks, 25 GIMP checks, 7 GUI checks; installed and on GitHub (2026-09-27) |
| gimp-uv-tools | UV Tools: import UV layouts (Blender SVG, OBJ, Blockbench) as paths, channel and island layers; select islands, seam bleed, fill outside, pack channels | main | works; 285 checks (unit, headless GIMP and Blender, Broadway GUI); installed and on GitHub (2026-09-27) |
| gimp-forensics | image forensics: 12 filters (ELA, JPEG Ghost, noise, wavelet noise, min/max, bit planes, echo, median and resampling detection, luminance gradient, clone detection, PCA; Filters > Forensics), the Forensics Workbench, JPEG Info (quality, JPEGsnoop signatures, double compression, thumbnail) and the Content Credentials (C2PA) viewer (Image > Forensics); samples/ with free test images | main | works; 247 operation checks (also under ASan), 179 GIMP checks, 21 Workbench, 49 JPEG Info, 17 GUI, 138 Content Credentials; round 2 installed and on GitHub (2026-09-28) |
| gegl-presence | Clarity, Texture, Dehaze (Filters > Enhance), Whites and Blacks (Colors): Camera Raw presence controls, local Laplacian and dark channel | main | works; 114 checks (108 also under ASan), 86 GIMP checks, 12 GUI checks; installed and on GitHub (2026-09-28) |
| gegl-equalizers | Saturation Equalizer and Advanced Unsharp Mask (Tibor Bamhor), GPL-3.0-only | main | works; within 1 level of the fixed originals on 99.987 % of pixels, 83 checks (ASan), 56 GIMP checks; installed and on GitHub (2026-09-28) |
| gimp-fusion | Merge Exposures (Mertens), Focus Stack with depth map, Align Layers by Content (Image menu); C plug-in | main | works; 64 unit checks (ASan), 43 GIMP checks, 13 real-image checks (NASA MAHLI, BBBC006), 14 GUI checks; installed and on GitHub (2026-09-28) |
| gegl-control-points | Control Points (Colors): U-Point style local adjustments, 8 points picked on the image, masks shown | main | works; 50 checks (48 also under ASan), GIMP checks, GUI with the coordinate picker; Nik patents expired; installed and on GitHub (2026-09-28) |
| gimp-save-for-web | Export for Web (File menu): live preview of the encoded result, exact size, target size, 7 formats, resize, crop, metadata choices; Python rewrite of Aurimas Juska's GIMP 2 plug-in | main | works; 57 unit, 16 GIMP checks over 187 exports, 561 file checks, 36 GUI checks; installed and on GitHub (2026-09-28) |

The branch `gimp3-upstream` is the port without the "this is a fork" note
in the README, ready for an upstream pull request.

The old gimp-lqr is uninstalled (2026-09-27, the user keeps only Liquid Rescale TNG; a copy is in ~/store/code/links/backup-20260927). Installed locally (2026-09-27): GEGL operations `adj-black-and-white.so`, `adj-blend-if.so`,
`adj-luminosity-mask.so`, `adj-selective-color.so`, `color-lookup.so`,
`forensics-*.so` (twelve), `presence-*.so` (four), `equalizers-*.so` (two), `control-points.so`,
`depth-blur.so`, `marine-snow.so`, `underwater-correct.so`,
`pixel-art-scale.so`, `pixel-art-rescale.so`, `wavelet-denoise.so` and
`wavelet-sharpen.so` (the wavelet plug-ins are uninstalled on purpose; the
GEGL versions are the ones in use); plug-ins `bimp`, `content-credentials`, `forensics-workbench`, `gimp-blender-link`, `gimp-fusion`, `jpeg-info`, `save-for-web`,
`gimp-lensfun`, `gimp-lqr-tng`, `layerfx`, `luminosity-masks`,
`pixel-art-scale`, `tileset-export` and `uv-tools`.

## Rebuilding everything

Everything builds from a fresh clone; nothing lives outside the repos.
With the Flatpak GIMP, from each repo's folder
(`gimp-build.sh` is in this repo):

    # plug-ins
    gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
    # (gimp-lqr calls the option -Dgimp_plugindir)
    gimp-build.sh . ninja -C build install

    # GEGL operations (gegl-wavelet, gegl-underwater)
    gimp-build.sh . meson setup build -Dmoduledir=\$GEGL_OPDIR
    gimp-build.sh . ninja -C build install

Restart GIMP afterwards. The script says how to install the GNOME SDK if it
is missing. For testing dialogs without a screen, see `gui/cdp.mjs` in the
README.

## Overnight queue (2026-09-25, from David)

In this order, each committed in its own repo as it goes:

1. **BIMP** port to GIMP 3 (`gimp-bimp`, branch `gimp3`, on github.com/sandbranch/gimp-bimp). No one else has started one: upstream
   is silent since 2023, `v3-dev` is older than master, no forks have
   GIMP 3 work. Adds a non-interactive procedure that runs a saved
   `.bimp` set on files, which also makes it testable headlessly.
2. **Marine snow**: `underwater:marine-snow` in gegl-underwater (PLAN 4b). Done:
   Filters > Enhance > Remove Marine Snow..., tested on a synthetic scene
   and in GIMP; next is real photos.
3. **Lensfun as a GEGL filter** (live preview, non-destructive). Done:
   `lensfun:correct` in the gimp-lensfun repo (shares the correction code);
   the plug-in adds it with the Exif settings ("Keep as an editable
   filter"). tests/compare.sh: plug-in and filter agree.

## Next: gegl-underwater

This is the one in progress. Its own `PLAN.md` has the full list.

Done (2026-09-26): the color correction `underwater:correct` works in a
first version (milestones 1 to 3). Test photos: 42 freely licensed ones
from Wikimedia Commons, listed in `tests/images/manifest.json` and
downloaded with `tests/images/fetch.py` (the photos are not committed).
`tests/run.sh` writes before/after sheets and measurements;
`tests/gimp-test.sh` checks the filter non-destructively in GIMP (same
result as the command line). The pipeline as built, and where it
differs from the papers, is in `docs/design.md`.

Next, in order:

1. The known issues in `docs/design.md`. Fixed since the first version
   (a water color map, Oklab keep water, p = 2 white balance): green
   sunlit water, lavender blue water, khaki murk. Left: a gray reef in
   very green water (ambient-green-08), glow around subjects, a gray
   shark going warm, speed (about 4 s on 24 MP). `tests/compare.py a b`
   puts runs side by side.
2. Real dive photos from David, to check against the Commons set.
3. SQUID (Berman et al.) color charts as an accuracy test.
4. Milestone 4b: "reduce red noise" with the wavelet denoise algorithm;
   marine snow on real photos. (The Farhadifard rule and the patent
   check are in `docs/research.md`: the marine snow patents need video.)

Patents to keep clear of, with the reasons, are in `docs/design.md` and
`docs/research.md`. Any change to the pipeline is checked against them.

## Liquid Rescale TNG (2026-09-26)

The user's idea: a Liquid Rescale window with a small view of the image,
green Keep and red Remove buttons to paint with, and the controls around
it. A new plug-in on liblqr (repo gimp-lqr-tng, renamed from
gimp-lqr-paint; GitHub redirects), not in the ported gimp-lqr,
which stays as the faithful port for upstream. Menu Layer > Liquid
Rescale TNG..., procedure `plug-in-lqr-tng`.

- Paint Keep, Remove and Straight (a rigidity mask: seams bend less
  there); masks stored as hidden layers and carved along; one undo step;
  all precisions, gray, alpha, layer masks.
- After carving: crop, keep the size, carve back, or scale back (both,
  width, height); output to the layer, a new layer or a new image; seam
  maps as layers; aspect ratio lock.
- It does everything the port does; the user decided it is the one to
  recommend.

Next, with the user: trying it on real photos; translations (Swedish
first?); keyboard shortcuts (K, R, S, E, Ctrl+Z); report the two liblqr
leaks (carver list, vmap list) upstream.

## Audit (2026-09-26)

Every repo was reviewed for bugs, and each has a pass/fail test suite
that runs with one command, without a display or network, in a
throwaway GIMP profile (`GIMP3_DIRECTORY`), and under AddressSanitizer
and UBSan (the Flatpak SDK has the runtimes; `flatpak run --devel`).

| Repo | Real bugs fixed | Checks |
|---|---|---|
| gegl-wavelet | CIELAB NaN, abort on unbounded input, zero settings changed the image, abort without memory | 116 (`tests/run.sh`) |
| gimp-wavelet-denoise | YCbCr round trip not exact, CIELAB NaN, indexed/groups/locked layers "succeeded" | 233 (`tests/run.sh`) |
| gimp-wavelet-sharpen | YCbCr round trip, indexed/groups/locked layers | 209 (`tests/run.sh`) |
| gimp-lensfun | uninitialized Lanczos table, arbitrary lens guessed, positions up to 0.3 px off, stale filter cache, database not thread safe, gray path, groups | 50 (`tests/run.sh`) |
| gimp-lqr | rigidity and enlargement step ignored, masks by name never found, Repeat always 100x100, seam colour crash, no translation, 1 px crash in liblqr, new-image masks | 74 (`tests/run.sh`, `--asan`) |
| gimp-bimp | crash on header-less .bimp, repeated manipulations, reads past arrays, use-after-free in curves, alpha added to every PNG/TIFF/WebP, GIF always failed, metadata dropped, errors counted as success | 70 plus unit tests (`tests/run.sh`, `BIMP_SANITIZE=1`) |
| gegl-depth-blur | result depended on tiling and threads, highlights and depth in the wrong color space, rotation reversed, NaN spread | 114 (`tests/run.sh`) |
| gegl-underwater | heap overflow on thin images, one NaN pixel spoiled all, marine snow depended on tiling, hang on unbounded input | 25 + 8 (`tests/check.sh`, `tests/gimp-check.sh`) |
| gimp-devtools | flatpak info translated labels broke the version, `$*` quoting, wrong key codes | 179 (`tests/run.sh`) |

Open decisions from the audit:

- Tests on `gimp3-upstream` of the wavelet plug-ins (that branch had none).
- Wavelet: YCbCr/CIELAB constants inherited from GIMP 2 (small drift in
  the GEGL ops; CIELAB assumes sRGB); colour not premultiplied by alpha.
- Lensfun filter keeps two full float copies and ignores the zoom level.
- LQR: `batch/batch-gimp-lqr.scm` is GIMP 2 Script-Fu (port or drop);
  licence headers missing in some UI files; report the liblqr 1 px
  out-of-bounds read upstream.
- BIMP: same file name from two input folders overwrites or is skipped;
  skipped files count as processed (both upstream behaviour).
- Depth Blur is slow in small render pieces (a cached region rounded to
  the tile grid would help); report GEGL's `get_source_space` ignoring
  its pad argument upstream.
- Underwater: alpha is ignored in the estimates; backscatter 0 still
  changes the photo; open water gets darker by default.

## Candidates for later

[docs/candidates.md](docs/candidates.md) (2026-09-26): a fact-checked
sweep of abandoned GIMP 2 plug-ins that still have an unmet need in GIMP
3, ranked, with licenses read from the sources, plus what exists for HDR
merging, focus stacking and stitching. Nothing chosen yet.

## Photoshop gaps (2026-09-27)

[docs/photoshop-gaps.md](docs/photoshop-gaps.md): Photoshop plug-ins and
built-ins GIMP 3.2 lacks, ranked. Top: a 3D LUT (Color Lookup) GEGL op,
a Photoshop-compatible Selective Color op, a hue-weighted Black & White
op, Blend If, luminosity masks; upstream GIMP asks for the first two
(issue #15505). Nothing chosen yet.

## Level editors (2026-09-27)

[docs/level-editors.md](docs/level-editors.md): Tiled, LDtk and Godot
already reload images GIMP saves (Tiled tested); the gap is metadata. Top:
a GIMP 3 Tileset Export (PNG plus TSX with grid, properties, collision,
animations), tile extrusion, autotile templates, Quake WAD export, a
GimpSpriteAtlas port. Nothing chosen yet.

## Interlinks (2026-09-27)

[docs/interlinks.md](docs/interlinks.md): GIMP and Blender texture painting
(nothing maintained links them; GIMP 3.2 link layers, Blender's
`Image.reload`, UV SVG and 16-bit PNG/EXR round trips tested headless) and
other links for GIMP, with a ranked list of projects. First: a GIMP Link
for Blender (Blender add-on plus a resident GIMP plug-in over localhost).
Nothing chosen yet.

## Test isolation (2026-09-27)

GIMP runs in the Flatpak write GIO's file-metadata journal
(`~/.var/app/org.gimp.GIMP/data/gvfs-metadata`), caches (babl, the ccache of
builds) and `flatpak run` its `.ld.so` cache into the
Flatpak's own folders, even with a throwaway `GIMP3_DIRECTORY`. Done: every
test script of the repos above starts GIMP (and Blender) through
`gimp-run.sh` (via each repo's copy of `isolate.sh`), and builds with
`GIMP_RUN_HOME` set; each suite lists the user's folders before and
after (`snapshot.sh`) and fails if anything changed. gimp-tileset-export
has its own version of the same.

## Other open items

- **Tests in the repos** (done 2026-09-26): every repo has `tests/run.sh`
  (gimp-lensfun `tests/compare.sh`), which runs headless in the Flatpak
  GIMP and checks results.
- **Upstream pull requests.** Wavelet Denoise: upstream already has a
  pull request #6 by Arvil (8-bit only); plan is to open ours from
  `gimp3-upstream` and comment on #6. Wavelet Sharpen: open from
  `gimp3-upstream`. LQR and Lensfun: after the polish below.
- **Menu labels**: the wavelet plug-ins use the old style ("Wavelet
  sharpen ...") instead of GIMP 3 Title Case ("Wavelet Sharpen..."); both
  versions sit in Filters > Enhance. Sharpen's default amount to review.
- **Liquid Rescale polish**: done (license string, `-DDEBUG`, deprecated
  GTK stock items, help registration and per-language help install).
- **Packaging**: release tarballs, and Flatpak packages so the filters
  work on other computers with Flatpak GIMP. Postponed until the filters
  settle.
- **Focus Blur** became the GEGL filter Depth Blur, `depth:blur`
  (gegl-depth-blur, 2026-09-25): no plug-in port, since its upstream
  is gone and a GEGL filter covers it. Its own `PLAN.md` has the next
  steps; first, look at the dialog in GIMP. GIMP merges filters with an aux input on OK
  (a TODO in GIMP), so it is not kept as an editable filter.
- **BIMP** (2026-09-25/26): ported to GIMP 3, with a new non-interactive
  `plug-in-bimp-batch`. Open: a manipulation for GIMP 3's filters, which
  are GEGL operations and not procedures, so "Other GIMP procedure..."
  cannot list them (GimpDrawableFilter with its config would do it); the
  Windows installer (`nsis/`); offering the port upstream (no reply from
  the author since 2023, issue #420).

## Things learned the hard way

- `gimp_procedure_dialog_fill_box_list(..., NULL)` means *all*
  arguments; a custom box needs a hidden placeholder label.
- `GEGL_PATH` replaces GEGL's default path, and meson's JSON files in a
  build folder crash GEGL: for command line tests, copy the `.so` into a
  clean folder and use `GEGL_PATH=<folder>:/app/lib/gegl-0.4`.
- Paper summaries from web tools have invented content: read the PDF
  itself (`pdftotext`, or the page images for scanned patents).
