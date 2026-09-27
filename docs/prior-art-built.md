# Prior art for what we built: other GIMP 3 versions

Date of research: 2026-09-27. Current GIMP: 3.2.6 (2026-09-10). Sources
checked: GitHub (repository and code search, then the API for each hit:
pushed date, stars, licence, branches, the code itself), gitlab.gnome.org
(GIMP and GEGL issues and merge requests through the API, and shallow
clones of GIMP master at 973b38e, 2026-09-26, and GEGL master at 2d6f9f5,
2026-09-26), the G'MIC stdlib (GreycLab/gmic master) and the 29 community
filter files (GreycLab/gmic-community), LinuxBeaver's 115 repositories,
Flathub manifests, the Blender extensions platform API, discuss.pixls.us
(its JSON search and topic API), and web searches restricted to
gimp-forum.net and gimpchat.com.

This covers the 15 tools of this project (see [../STATUS.md](../STATUS.md)).
It does not repeat [candidates.md](candidates.md) or
[photoshop-gaps.md](photoshop-gaps.md); where those two already checked
something, it was checked again here.

How sure each claim is:

- **verified in code**: the source was read (API, clone or download) and
  it targets GIMP 3 (`gi.require_version('Gimp', '3.0')`, `Gimp.PlugIn`,
  `GimpPlugIn`/`GIMP_MAIN`, `script-fu-register-filter`) or does what is
  said.
- **claims**: what the README or a forum post says; not run here (GIMP was
  not run for this report).
- **UNVERIFIED**: could not be checked; the reason is given.

## Summary

| # | Our tool | Other GIMP 3 versions found | Verdict |
|---|---|---|---|
| 1a | Wavelet Denoise (plug-in and GEGL filter) | Arvil's PR #6 upstream (open, 8-bit only) | One other port, 8-bit only; ours adds 16-bit and float, a non-destructive filter, tests |
| 1b | Wavelet Sharpen (plug-in and GEGL filter) | none | Ours is the only GIMP 3 version |
| 2a | Liquid Rescale (faithful port) | Timo Stolz's PR #18 on Tom Hodder's prototype (open, 8-bit) | A second port exists, unreviewed and 8-bit; ours carves in float and fixes more |
| 2b | Liquid Rescale TNG | G'MIC Seamcarve (keep/remove mask layer, destructive) | Ours is the only one painted in its own dialog with live preview |
| 3 | BIMP | Batcher (mature, maintained), two new small tools | Ours is the only BIMP for GIMP 3; Batcher is a good alternative and is what users are told to use: point to both |
| 4 | Lensfun | none in GIMP; raw developers do it for raw files | Ours is the only GIMP 3 Lensfun tool |
| 5 | Depth Blur | GIMP's own Lens Blur with a mask; G'MIC Blur [Depth-of-Field] | Close relatives exist; ours is the only one with a focus depth, occlusion and bokeh shapes |
| 6 | Underwater correction, marine snow | none | Ours is the only GIMP 3 version |
| 7 | Color Lookup (LUT) | G'MIC Apply External CLUT (destructive) | G'MIC works and ships many LUTs; ours is the only non-destructive LUT filter |
| 8 | Selective Color, Black & White, Blend If, luminosity masks | Chuck Henrich's Interactive Luminosity Masks (GIMP 3); nothing for the other three | Only the masks have another GIMP 3 tool, and it is good; the other three are ours only |
| 9 | Layer Effects (layerfx) | GIMP's GEGL Styles and single ops; LinuxBeaver's GEGL Effects; bunnywaffle's adjustment-layer | Non-destructive alternatives exist and are strong for text; ours is the only layerfx port (effects as layers, Satin, overlays, reapply) |
| 10 | Pixel art scalers | G'MIC Upscale [Scale2x], Xbr2x (2x only, Testing) | Ours is the only GIMP 3 hqx and xBR at 3x and 4x |
| 11 | GIMP Link for Blender | BlendGimp (new, 2026-08-31); Blender's built-in Edit Externally | A second GIMP 3 link exists with a different design; not verified in use |
| 12 | UV Tools | none; G'MIC Solidify and GIMP Compose/Decompose cover parts | Ours is the only GIMP 3 version |
| 13 | Tileset Export | sprite sheet exporters (Spritesheetize, tilemancer, export_tileset) | None writes Tiled or Godot metadata; ours is the only one |
| 14 | Forensics (ELA, JPEG Ghost, noise, clone detection, PCA) | none working in GIMP 3; Sherloq outside GIMP | Ours is the only GIMP 3 version; Sherloq is the more complete standalone toolkit |
| 15 | Content Credentials (C2PA) viewer | none in GIMP | Ours is the only one in GIMP; c2patool and web viewers exist outside |

Things that duplicate or beat ours, in order of how much they matter:

1. **Batcher** (BIMP): maintained, 219 stars, releases every few weeks, and
   the answer people give in BIMP's own issues. For many users it already
   fills the gap.
2. **Arvil's Wavelet Denoise PR #6** and **Timo Stolz's Liquid Rescale PR
   #18**: both sit open upstream as competing GIMP 3 ports. Both are 8-bit
   only (verified in code). When we offer ours upstream, say how they
   relate.
3. **GEGL Styles** (built into GIMP 3) and **LinuxBeaver's GEGL Effects**:
   non-destructive layer styling in one filter; better than layerfx when an
   editable filter is wanted rather than separate layers.
4. **Chuck Henrich's Interactive Luminosity Masks**: GIMP 3, GPL-3.0+,
   translated into 13 languages, reported working in 3.2.4.
5. **G'MIC** (in GIMP 3 through G'MIC-Qt): Apply External CLUT, Seamcarve,
   Scale2x, Blur [Depth-of-Field]: working but destructive equivalents.
6. **BlendGimp**: a second GIMP 3 and Blender link, brand new.

## 1. Wavelet Denoise and Wavelet Sharpen

Ours: [gimp-wavelet-denoise](https://github.com/sandbranch/gimp-wavelet-denoise),
[gimp-wavelet-sharpen](https://github.com/sandbranch/gimp-wavelet-sharpen)
(plug-ins, 8-bit, 16-bit and float) and
[gegl-wavelet](https://github.com/sandbranch/gegl-wavelet)
(`wavelet:denoise`, `wavelet:sharpen`, non-destructive).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Upstream Wavelet Denoise | [mrossini-ethz/gimp-wavelet-denoise](https://github.com/mrossini-ethz/gimp-wavelet-denoise) | Marco Rossini | GPL-2.0 (API) | push 2022-11-06 | GIMP 2 only | the original we ported |
| PR #6 "Port to GIMP 3" | [pull/6](https://github.com/mrossini-ethz/gimp-wavelet-denoise/pull/6), fork [Arvil/gimp-wavelet-denoise](https://github.com/Arvil/gimp-wavelet-denoise) | Arvil (commit by Guilhem Marion); the PR text says it "was mostly handled by Gemini 3.8 Flash High" | GPL-2.0 (inherits) | opened 2026-09-16, amended 2026-09-17; open, no review | verified in code: `GimpPlugIn`, GEGL buffers, GTK 3; `src/denoise.c` reads and writes only `Y' u8`, `Y'A u8`, `R'G'B' u8`, `R'G'B'A u8`, so 16-bit and float images are cut to 8 bits | same algorithm; no high bit depth, no GEGL filter, no tests |
| Upstream Wavelet Sharpen | [mrossini-ethz/gimp-wavelet-sharpen](https://github.com/mrossini-ethz/gimp-wavelet-sharpen) | Marco Rossini | GPL-2.0 | push 2023-06-11; only PRs are build fixes | GIMP 2 only; no forks other than ours | the original we ported |
| Other copies | [gimp-plugins-justice/wavelet-denoise](https://github.com/gimp-plugins-justice/wavelet-denoise) (2017), [vzzbx/wavelet-denoise](https://github.com/vzzbx/wavelet-denoise) (2018), JoesCat/gimp-wavelet-denoise (2022) | various | GPL | 2017 to 2022 | GIMP 2 only (no GIMP 3 branch) | none |
| GIMP's Wavelet-decompose | GIMP `plug-ins/common/wavelet-decompose.c`, Filters > Enhance | GIMP | GPL-3.0+ | GIMP 3.2.6 | built in | splits into scale layers for manual retouching; no thresholding denoise |
| GEGL `noise-reduction`, `denoise-dct` | GEGL `operations/common`, `common-cxx` | GEGL | LGPL-3.0+ | master | built in | other denoisers, not per-channel wavelet thresholds |
| GEGL workshop `sharpen` | GEGL MR [!269](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/269) (merged 2026-08-13), `operations/workshop/sharpen.c` | WarisMaqbool | LGPL-3.0+ | master | workshop op (not built by default) | the old GIMP Sharpen filter, not wavelet sharpening |
| G'MIC Smooth [Wavelets], Smooth [IUWT], Split Details [Wavelets], Sharpen [Wavelet] | gmic_stdlib.gmic; jerome_boulanger.gmic; sylvie_alexandre.gmic | Tschumperlé and Boulanger (2013); Boulanger; Tschumperlé (2016); samj (2016) | CeCILL-C or CeCILL 2.1 | stdlib 2026-09 | work in GIMP 3 through G'MIC-Qt (float), destructive | different wavelet methods; no per-channel YCbCr or CIELAB thresholds |

Verdict: **Wavelet Denoise**: Arvil's PR #6 exists and does the plain
8-bit port; ours adds 16-bit and float, a non-destructive GEGL filter and
233 checks. Worth a friendly comment on PR #6 when we offer ours upstream,
since the maintainer will see two ports. **Wavelet Sharpen**: ours is the
only GIMP 3 version.

## 2. Liquid Rescale and Liquid Rescale TNG

Ours: [gimp-lqr](https://github.com/sandbranch/gimp-lqr) (faithful port,
liblqr in float) and [gimp-lqr-tng](https://github.com/sandbranch/gimp-lqr-tng)
(Keep, Remove and Straight painted in its dialog, live preview).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Upstream Liquid Rescale | [carlobaldassi/gimp-lqr-plugin](https://github.com/carlobaldassi/gimp-lqr-plugin) | Carlo Baldassi | GPL-2.0 (API) | push 2024-08-30 (autotools fixes) | GIMP 2 only | the original |
| GIMP 3 prototype | [tolland/gimp-lqr-plugin](https://github.com/tolland/gimp-lqr-plugin), branches `prototype-3-version` (2025-05-30) and `gimp3-port-clean-tolland` (640d672, 2026-02-26) | Tom Hodder | GPL-2.0 | 2026-02-26 | verified in code: builds a carver with `lqr_carver_new` (8-bit) | the base of PR #18; 8-bit |
| PR #18 "Port plugin to GIMP 3 and fix mask workflow runtime issues" | [pull/18](https://github.com/carlobaldassi/gimp-lqr-plugin/pull/18), fork TimoStolz/gimp-lqr-plugin | Timo Stolz | GPL-2.0 | opened 2026-02-25, open, no comments or review | verified in code: meson, GIMP 3 API; `io_functions.c` copies native bytes into `guchar` buffers and `render.c` uses `lqr_carver_new` (8-bit); the PR itself lists remaining GTK deprecation warnings; tested by hand per the PR text | a working 8-bit port; ours carves with `LQR_COLDEPTH_32F`, fixes rigidity, masks by name, the 1 px crash and more, with 74 checks |
| Max1Truc gimp3 branch | [Max1Truc/gimp-lqr-plugin](https://github.com/Max1Truc/gimp-lqr-plugin) | Max1Truc | GPL-2.0 | 2026-01-27 | one commit changing `configure.ac`; not a port | none |
| GIMP issue #575 "Add Liquid Rescale plug-in to GIMP" | [work_items/575](https://gitlab.gnome.org/GNOME/gimp/-/work_items/575) | from Bugzilla 735227 (2014) | n/a | updated 2026-04-14, open, 19 notes | request only (notes need a login: UNVERIFIED) | shows the demand |
| G'MIC Seamcarve | gmic_stdlib.gmic `fx_seamcarve` | Garagecoder and David Tschumperlé | CeCILL-C or CeCILL 2.1 | filter dated 2014-06-02 | works in GIMP 3 through G'MIC-Qt; destructive | content-aware resize with an optional top layer (red removes, green keeps); a different seam algorithm, no rigidity, no live painting, no seam maps |
| pgei.de "Liquid Rescale for GIMP 3.2" | [pgei.de](https://pgei.de/old/en/plugin.php?title=Liquid+Rescale) | repackager | n/a | page 2026 | the file offered is `gimp-lqr-plugin_0.7.1-liblqr_0.4.1_GIMP2.8_win32_setup.exe` (a GIMP 2.8 build; cannot load in GIMP 3), so the "3.2" label is false | none |
| Flathub `org.gimp.GIMP.Plugin.LiquidRescale` | [flathub](https://github.com/flathub/org.gimp.GIMP.Plugin.LiquidRescale) | Flathub | GPL-2.0 | 2024-03-23 | manifest `"branch": "2-40"`: GIMP 2 only | none |

Verdict: **port**: a second GIMP 3 port exists (PR #18), 8-bit and
unreviewed; ours carves in float, fixes more and is tested. **TNG**: G'MIC
Seamcarve does keep/remove masks destructively; nothing else lets you
paint in the dialog with a live result, so ours is the only one.

## 3. BIMP

Ours: [gimp-bimp](https://github.com/sandbranch/gimp-bimp) (BIMP ported,
plus a non-interactive procedure for saved sets).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Upstream BIMP | [alessandrofrancesconi/gimp-plugin-bimp](https://github.com/alessandrofrancesconi/gimp-plugin-bimp) | Alessandro Francesconi | GPL-2.0+ (LICENSE text; API reports NOASSERTION) | last commit 2023-03-19; `v3-dev` last commit 2021-01-12 | GIMP 2 only; issues #420 (2024-11), #430, #433, #442 (2026-05) ask for GIMP 3 without an answer from the author | the original |
| Forks | 10 forks pushed since 2024-06; checked naumanmy (branch `V3.0-tesst` has no new commits) and victorhugoperezlujan-crypto (a personal photo commit) | | | | no GIMP 3 work | none |
| Batcher | [kamilburda/batcher](https://github.com/kamilburda/batcher) | Kamil Burda | BSD-3-Clause | release 1.2.10 on 2026-07-26, push 2026-08-02; 219 stars | GIMP 3 (claims, and recommended in BIMP issues #420, #430 and #433 as the replacement) | batch convert, export layers, edit open images, any filter or plug-in as an action; more capable than BIMP for layers; one user in #430 finds it harder than BIMP for simple jobs |
| Batch Folder | [mamipi972/gimp-batch-folder](https://github.com/mamipi972/gimp-batch-folder) | mamipi972 | GPL-3.0 | created 2026-09-22, push 2026-09-23; 0 stars | verified in code (`Gimp.PlugIn`, `require_version("Gimp", "3.0")`); README claims 144 tests | new Python BIMP replacement: resize, crop, watermark, convert, rename, GEGL "looks"; days old |
| GIMP Batch Automation | [abelduarte/gimp-batch-automation](https://github.com/abelduarte/gimp-batch-automation) | Abel Duarte | MIT | 2026-04-12; 2 stars, 4 commits | verified in code: command line tool that runs GIMP 3 with `--batch-interpreter=python-fu-eval` | command line only, no GUI; JSON workflows |
| Flathub `org.gimp.GIMP.Plugin.BIMP` | [flathub](https://github.com/flathub/org.gimp.GIMP.Plugin.BIMP) | Flathub | | 2024-03-23 | manifest `"branch": "2-40"` | none |

Verdict: **ours is the only GIMP 3 BIMP.** Batcher is as good or better
for layer export and general batch work and is actively maintained:
point BIMP users who want something new to Batcher, and users who want
BIMP's window and saved `.bimp` sets to ours.

## 4. Lensfun

Ours: [gimp-lensfun](https://github.com/sandbranch/gimp-lensfun)
(plug-in rewritten for GIMP 3, plus the `lensfun:correct` GEGL filter).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Upstream GIMP-Lensfun | [seebk/GIMP-Lensfun](https://github.com/seebk/GIMP-Lensfun) | Sebastian Kraft | GPL-3.0 | push 2019-08-04; PR #30 (Exiv2 0.28, pinotree, 2024-09) open | GIMP 2 only; the only other fork with recent pushes (pinotree) is that Exiv2 fix | the original |
| Flathub `org.gimp.GIMP.Plugin.Lensfun` | [flathub](https://github.com/flathub/org.gimp.GIMP.Plugin.Lensfun) | Flathub | | 2024-03-23 | manifest `"branch": "2-40"` | none |
| GEGL `lens-distortion` | GEGL `operations/common-gpl3+/lens-distortion.c`, in GIMP's Filters menu (`app.filters-lens-distortion`) | GEGL | GPL-3.0+ | master | built in, non-destructive | manual main/edge/zoom sliders; no lens database, no Exif matching |
| darktable, RawTherapee, ART as GIMP raw loaders | GIMP `plug-ins/file-raw/` (`file-darktable.c`, `file-rawtherapee.c`, `file-another-rawtherapee.c`) | GIMP | GPL-3.0+ | GIMP 3.2.6 | built in | they apply Lensfun (or their own profiles) while developing a raw file, better than ours for raw; the format list in `file-raw-formats.h` has raw formats only, so not for JPEG, TIFF or a layer already in GIMP |
| GIMP issue #2876 "please use lensfun better with gegl:lens-correct" | [work_items/2876](https://gitlab.gnome.org/GNOME/gimp/-/work_items/2876) | Phil (phd21) | | opened 2019, updated 2025-03-01, open | request only | demand |

Verdict: **ours is the only GIMP 3 Lensfun tool.** For raw files the raw
developers are the better route; ours is for JPEG, TIFF and layers.

## 5. Depth Blur

Ours: [gegl-depth-blur](https://github.com/sandbranch/gegl-depth-blur)
(`depth:blur`, focus depth, occlusion, polygon and ring bokeh).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Focus Blur (GIMP 2) | [JMoerman/gimp-focusblur-plugin](https://github.com/JMoerman/gimp-focusblur-plugin) | Kyoichiro Suda | GPL-2.0+ | 2019-02-21; three forks, none newer | GIMP 2 only; Flathub `FocusBlur` manifest is `"branch": "2-40"`; the gimp-forum.net thread "Realistic GIMP Focus Blur Plugin" (2021) is about GIMP 2.10 | the model ours follows |
| GIMP Lens Blur | GEGL `common-cxx/lens-blur.cc`, Filters > Blur > Lens Blur, aux input | Ell | LGPL-3.0+ | master | built in; the mask on the aux input sets each pixel's radius; merged on OK (aux inputs are never non-destructive in GIMP 3) | the closest native tool: radius per pixel from a map, highlight boost; no focus depth, no near-over-far occlusion, round kernel only |
| GIMP Variable Blur, Focus Blur | GEGL `variable-blur.c`, `focus-blur.c` | Ell | LGPL-3.0+ | master | built in | radius from a mask, or around a shape you place; no depth map model |
| G'MIC Blur [Depth-of-Field] | gmic_stdlib.gmic `fx_blur_dof` | David Tschumperlé | CeCILL-C or CeCILL 2.1 | 2014-02-25 | works in GIMP 3 through G'MIC-Qt, destructive | Gaussian falloff or a depth layer (bottom layer luminance); no bokeh shapes or occlusion |
| G'MIC Depth Blur (Testing) | gmic-community andy_kelday.gmic `gcd_depth_blur` | Garagecoder | CeCILL-C or CeCILL 2.1 | 2013-02-24 | Testing category | estimates depth itself from the image |
| LinuxBeaver Bokeh | [GEGL-GIMP-PLUGIN_Bokeh](https://github.com/LinuxBeaver/GEGL-GIMP-PLUGIN_Bokeh) | LinuxBeaver | GPL-3.0 | 2026-06-13 | GEGL op | a pseudo bokeh effect, not depth based (claims) |
| DepthForge (depth maps) | [GrzegorzOle/DepthForge](https://github.com/GrzegorzOle/DepthForge) | Grzegorz Ole | MIT | 2026-08-04 | verified in code: GIMP 3 plug-in (Filters > DepthForge) making depth maps with MiDaS and DPT on OpenVINO | complements ours: a source of depth maps, not a blur |

Verdict: close relatives exist (GIMP's Lens Blur with a mask is good for
simple depth effects); **ours is the only one with a focus depth,
occlusion and aperture shapes.**

## 6. Underwater colour correction and marine snow removal

Ours: [gegl-underwater](https://github.com/sandbranch/gegl-underwater)
(`underwater:correct`, `underwater:marine-snow`).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| GIMP 2 scripts | "Under Water red correction" (Script-Fu, 2006); [UnderwaterCorrection.py gist](https://gist.github.com/edouardklein/6fef6a268c8117a2b7ba) | various; Edouard Klein | | 2006; 2014 | GIMP 2 only (Python 2, removed procedures), from gegl-underwater/docs/research.md | none |
| G'MIC | DCP Dehaze (Boulanger), Simple Dehaze (Testing) | | CeCILL | | in GIMP 3, destructive | haze on land; no underwater model; grep of all 1,018 filter entries found no underwater or marine snow filter |
| dive-color-corrector | [bornfree/dive-color-corrector](https://github.com/bornfree/dive-color-corrector) | bornfree | GPL-3.0 | 2025-11-26 | standalone, not GIMP | a global correction (see gegl-underwater/docs/survey-2026.md) |
| Marine snow research code | [ychtanaka/marine-snow](https://github.com/ychtanaka/marine-snow) (dataset), MarineSnowCNN, SeaSnow-GAN | researchers | various | 2019 to 2023 | not GIMP | datasets and neural models |

GitHub repository search for "underwater gimp", "underwater color
correction" and "marine snow" found only ours for GIMP.

Verdict: **ours is the only GIMP 3 version** of both.

## 7. Color Lookup (3D LUT)

Ours: [gegl-lut](https://github.com/sandbranch/gegl-lut)
(`lut:color-lookup`, `.cube`, `.3dl`, Hald, non-destructive).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| G'MIC Apply External CLUT | gmic_stdlib.gmic `fx_apply_haldclut` | David Tschumperlé | CeCILL-C or CeCILL 2.1 | 2025-05-28 | works in GIMP 3 through G'MIC-Qt (G'MIC 4.0.5, 2026-09-04); destructive | loads `.cube` or a Hald image from a file or a layer, with strength; no `.3dl`, no choice of encoding, no opacity or blend beyond strength |
| G'MIC Apply From CLUT Set, film and colour presets, Customize CLUT, CLUT from After - Before Layers | gmic_stdlib.gmic | David Tschumperlé | CeCILL | stdlib 2026-09 (the LUT pack filter is dated 2023-06-01) | in GIMP 3, destructive | a large bundled LUT library and LUT making tools that ours does not have |
| GEGL and GIMP master | clones of 2026-09-26 | | | | grep for Hald, `.cube`, LUT and color lookup in GEGL `operations/` finds no LUT op; GIMP's PSD loader lists `clrL` but does not convert it | none |
| GIMP issue #15505 | [work_items/15505](https://gitlab.gnome.org/GNOME/gimp/-/work_items/15505) | cmyk.student | | 2025-12 | lists Color Lookup as "Not sure what the equivalent GEGL filter(s) would be" (per photoshop-gaps.md) | ours is that filter |
| GitHub | searches "gimp lut", "gimp cube lut", "hald clut gimp"; code search `".cube" Gimp.PlugIn lut` | | | | nothing for GIMP | |

Verdict: G'MIC does the job destructively and has far more LUTs to pick
from; **ours is the only non-destructive LUT filter in GIMP 3.** Point
people to G'MIC's CLUT sets for looks and to ours to apply their own files.

## 8. Selective Color, Black & White, Blend If, luminosity masks

Ours: [gegl-adjustments](https://github.com/sandbranch/gegl-adjustments)
(`adj:selective-color`, `adj:black-and-white`, `adj:blend-if`,
`adj:luminosity-mask`, plus Colors > Create Luminosity Masks).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Interactive Luminosity Masks v3 | [chuckhenrich.com](https://www.chuckhenrich.com/gimp-interactive-luminosity-masks/), [pixls.us thread](https://discuss.pixls.us/t/interactive-luminosity-masks-for-gimp-3/52559) | Chuck Henrich | GPL-3.0+ (file header) | zip dated 2026-03-19; "works in GIMP 3.2.4" (author, 2026-06-06) | verified in code: `gi.require_version('Gimp', '3.0')`, 5,161 lines of Python; builds a layer mask from a desaturated copy with curves, 3 variations each of lights, midtones and darks, then a live levels dialog; 13 translations | friendlier for a quick mask; destructive layer masks, 9 presets; ours adds live masks on channels, Kuyper's Lights, Darks and Midtones 1 to 5, zones, saturation and hue ranges |
| LR style mask preview | [pixls.us thread](https://discuss.pixls.us/t/python-plug-in-lr-style-mask-preview-for-gimp3/53208) | yasuo | UNVERIFIED (Google Drive download, not fetched) | 2025-09-30 | claims GIMP 3 | a mask preview helper, not a mask maker |
| tins11/gimp-luminosity-masks | [GitHub](https://github.com/tins11/gimp-luminosity-masks) | tins11 | MIT | 2022-07-22 | GimpFu, GIMP 2 (per photoshop-gaps.md) | none |
| G'MIC Tones to Layers, Slice Luminosity, Masques B&W Masks, Hue Overlay Masks | stdlib; sylvie_alexandre.gmic; mccap.gmic | Tschumperlé (2014, 2015); samj; mccap | CeCILL | | in GIMP 3, destructive | tonal slices as layers; no Photoshop-style series on channels |
| G'MIC Black & White, Selective Desaturation | stdlib | David Tschumperlé | CeCILL | 2013; 2015 | in GIMP 3, destructive | B&W by red, green and blue levels only (no hue weights); desaturation by colour, not CMYK inks |
| bunnywaffle adjustment-layer | [bunnywaffle/adjustment-layer](https://github.com/bunnywaffle/adjustment-layer) | bunnywaffle | GPL-3.0 | 2026-08-27; 5 stars | verified in code (plug-in wrapping native GEGL ops as NDE filters) | its "Black & White" is `gegl:c2g` (local contrast), not hue weighted; no Selective Color or Blend If |
| GIMP and GEGL master | clones of 2026-09-26 | | | | no selective colour, hue-weighted B&W, blend-if or luminosity mask op; workshop `selective-hue-saturation` is hue, saturation and lightness per range; PSD loader lists `selc` and `blwh` and skips blending ranges ("FIXME") | none |
| GIMP draft MR !2598, issue #6369 | [!2598](https://gitlab.gnome.org/GNOME/gimp/-/merge_requests/2598), [#6369](https://gitlab.gnome.org/GNOME/gimp/-/work_items/6369) | Akascape (!2598) | | !2598 2026-05-03 draft; #6369 open | !2598 approximates B&W with existing ops and lists Selective Color under "Need Help"; #6369 asks for Blend If | ours are what they ask for |

Verdict: for luminosity masks, **Chuck Henrich's plug-in is a good GIMP 3
option** and easier for a first mask; ours adds live, non-destructive
masks and the full series. For **Selective Color, hue-weighted Black &
White and Blend If, ours is the only GIMP 3 version.** gegl-adjustments'
README calls the pixls.us plug-in UNVERIFIED; it is now verified (above).

## 9. Layer Effects (layerfx)

Ours: [gimp-layerfx](https://github.com/sandbranch/gimp-layerfx) (Jonathan
Stipe's 11 effects as separate layers with their own modes, reapply).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Original layerfx | [earl-kent/layerfx](https://github.com/earl-kent/layerfx) (registry mirror) | Jonathan Stipe | GPL-3.0+ | 2022 mirror of 2012 code | GIMP 2 only | the original |
| GEGL Styles and single ops in GIMP 3 | GEGL `common/styles.c` (header: "2023 Sam Lester, GEGL Styles is based on a 2022 text styling plugin"; whether that plug-in is LinuxBeaver's is UNVERIFIED), `bevel.c`, `inner-glow.c`, `dropshadow.c`, `long-shadow.c` | Sam Lester (styles), GEGL | LGPL-3.0+ | master | built in, non-destructive, one filter with outline, shadow or glow, bevel, inner glow, image overlay | editable as one filter and kept in the XCF; no Satin, no gradient or pattern overlay, no separate layers to paint on |
| GEGL Effects | [LinuxBeaver/Gimp_Layer_Effects_Text_Styler_Plugin_GEGL_Effects](https://github.com/LinuxBeaver/Gimp_Layer_Effects_Text_Styler_Plugin_GEGL_Effects) | LinuxBeaver | GPL-3.0 | push 2026-06-13 (README: stable version 2025-05-31); 112 stars | GEGL op for GIMP 3 (claims; Linux and Windows binaries) | "GEGL Styles with far more options": the strongest text styling tool; one filter, not layers |
| LinuxBeaver bevels, glows, strokes | e.g. Custom Bevel (19 stars), Ringed Bevel ("similar to LayerFX's Bevel and Emboss"), stroke_shadow_glow, Dropshadow_seperate_layer | LinuxBeaver | GPL-3.0 | 2026-06-13 | GEGL ops (claims) | single effects, many more bevel styles than layerfx |
| bunnywaffle adjustment-layer | [bunnywaffle/adjustment-layer](https://github.com/bunnywaffle/adjustment-layer) | bunnywaffle | GPL-3.0 | 2026-08-27 | verified in code; README: Layer > Layer Effects adds Stroke, Drop Shadow, Long Shadow, Bevel & Emboss, Inner Glow, Layer Styles as NDE filters | a menu over the native ops; no inner shadow, satin or overlays |
| GIMP PSD import of layer styles | GIMP MRs !2331 (Inner Shadow), !2562 (Outer Glow), `psd-load.c` maps to `gegl:dropshadow`, `gegl:inner-glow`, `gegl:color-overlay` | cmyk.student | GPL-3.0+ | 2025 to 2026, merged | built into master | PSD styles become NDE filters |
| GSoC PSD-compatible layer styles | GIMP [#16339](https://gitlab.gnome.org/GNOME/gimp/-/work_items/16339); GEGL draft MR [!275](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/275) inner glow | WarisMaqbool | LGPL-3.0+ | !275 2026-09-04, #16339 2026-08-23 | in progress | overlaps our Inner Glow and Bevel |
| pgei.de "LayerFX for GIMP 3.2" | [pgei.de](https://pgei.de/old/en/plugin.php?title=LayerFX) | repackager | | 2026 page | not downloaded; candidates.md found other pgei "3.2" labels false: UNVERIFIED for this one | |

Verdict: GIMP 3's own GEGL Styles and LinuxBeaver's GEGL Effects are
**better when you want one editable, non-destructive filter** (text
styling especially): point users there for that. **Ours is the only
layerfx port**: each effect a real layer, Satin and the three overlays,
Photoshop-like contour and knockout options, reapply after edits.
Coordinate with WarisMaqbool before more Inner Glow or Bevel work.

## 10. Pixel art scalers (hqx, xBR, Scale2x)

Ours: [gimp-pixel-scale](https://github.com/sandbranch/gimp-pixel-scale)
(GEGL ops and Image > Scale Pixel Art, byte exact against references).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| Pixel Art Scalers | [bbbbbr/gimp-plugin-pixel-art-scalers](https://github.com/bbbbbr/gimp-plugin-pixel-art-scalers) | bbbbbr | GPL-3.0 (hqx, xBR files LGPL-2.1+) | 2020-08-25; 105 stars; issue #8 "GIMP 3 / GTK3 migration" open since 2020; no fork pushed since 2024 | GIMP 2 only | the original feature set |
| Super-xBR | [abelbriggs1/gimp-superxBR](https://github.com/abelbriggs1/gimp-superxBR) | Abel Briggs | MIT | 2021-12-28 | GIMP 2 only (Python 2) | a different, smoothing algorithm |
| G'MIC Upscale [Scale2x] | stdlib `fx_scalenx` | David Tschumperlé | CeCILL | 2010-12-29 | in GIMP 3, destructive | Scale2x and Scale3x combined (2, 3, 4, 6, 8, 9 ... 27 times); no hqx or xBR |
| G'MIC Xbr2x (Testing) | gmic-community andy_kelday.gmic `gcd_xbr2x` | Garagecoder | CeCILL | 2013-05-29 | in GIMP 3, destructive | xBR 2x without blending; its note says it "may not fully represent the original routine" |
| GIMP and GEGL master | | | | | no pixel art scaler (grep for hqx, xBR, Scale2x); `gegl:antialias` uses Scale3x to smooth edges at the same size | none |

Verdict: **ours is the only GIMP 3 version of hqx and of xBR at 3x and
4x**; G'MIC covers Scale2x family scaling destructively.

## 11. GIMP Link for Blender

Ours: [gimp-blender-link](https://github.com/sandbranch/gimp-blender-link)
(Edit in GIMP, Send to Blender, layered XCF with UV link layers; files on
disk plus a token-checked JSON socket; see its
[docs/prior-art.md](https://github.com/sandbranch/gimp-blender-link/blob/main/docs/prior-art.md)
for the Krita links).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| BlendGimp | [ALS-Sanbox/BlendGimp](https://github.com/ALS-Sanbox/BlendGimp) | ALS-Sanbox | GPL-3.0-or-later in `blender_manifest.toml`; no LICENSE file, GitHub reports none | created 2026-08-31, last push 2026-09-17 (v0.5.21); 0 stars | verified in code: a persistent GIMP 3 extension (`extension-blendgimp`, `require_version("Gimp", "3.0")`, 10,203 lines) serving newline-delimited JSON on 127.0.0.1:8765, and a Blender 5.0+ extension; README says GIMP 3.2+ | a different model: you paint in Blender's viewport with GIMP as the owner of pixels and layers (brush preview, layers, masks, selections through GIMP). Ours edits in GIMP and reloads the texture file in Blender. fixed port 8765; a grep of both sides found no connection authentication; not run here |
| Blender's Image > Edit Externally | built into Blender | Blender | GPL | current | opens the image in a configured editor such as GIMP | no layers, UV layout or automatic reload |
| Krita links (Blender Krita Link, Blender Layer, Pribambase/Spritedash) | see gimp-blender-link/docs/prior-art.md | | GPL-3.0 | 2024 to 2026 | Krita or Aseprite only | ours is the GIMP one |
| gimp-blender-import | [AILab-FOI/gimp-blender-import](https://github.com/AILab-FOI/gimp-blender-import) | AILab-FOI | GPL-3.0 | 2024-05-28 | Blender add-on importing XCF layers as planes | not a link |
| Blender extensions platform | API listing of 1,454 extensions (2026-09-27) | | | | no extension with GIMP in its name or tagline | |

Verdict: **BlendGimp is a second GIMP 3 and Blender link**, three weeks
old, with a Blender-centric painting design; ours is file-based and
survives restarts and sandboxes. Worth testing it side by side and
mentioning it in our README; not verified in use.

## 12. UV Tools

Ours: [gimp-uv-tools](https://github.com/sandbranch/gimp-uv-tools) (UV
layouts from Blender SVG, OBJ, Blockbench as island paths, channels,
island selection, seam bleed, fill outside, channel packing).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| GIMP Import Path / Open as Layers (SVG) | built in | GIMP | GPL-3.0+ | 3.2.6 | built in | imports Blender's UV SVG with every face edge, no islands |
| GIMP Compose and Decompose | `plug-ins/common/compose.c`, `decompose.c` | GIMP | GPL-3.0+ | 3.2.6 | built in | channel packing and unpacking by hand; ours keeps the numbers exact and names the maps |
| G'MIC Solidify | stdlib `fx_solidify_td` | David Tschumperlé | CeCILL | 2016-04-07 | in GIMP 3, destructive | fills all transparent areas by diffusion; not an N pixel bleed from the nearest island pixel |
| Blender bake margin | Blender | | GPL | | inside Blender | bleeds at bake time, not in GIMP |
| GitHub | repo searches "gimp uv", "uv layout gimp"; code search `"uv layout" Gimp.PlugIn` | | | | only ours | |

Verdict: **ours is the only GIMP 3 version.**

## 13. Tileset Export

Ours: [gimp-tileset-export](https://github.com/sandbranch/gimp-tileset-export)
(PNG plus Tiled `.tsx`/`.tsj` and Godot `.tres`: grid, properties,
collision paths, animations, extrusion).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| GIMP Pixel Art Utils (Spritesheetize, Load as tiles, Tile preview, Animation preview) | [nerudaj/gimp-pixel-art-utils](https://github.com/nerudaj/gimp-pixel-art-utils) | nerudaj | Apache-2.0 | 2026-02-20; 10 stars | verified in code (GIMP 3 Python) | exports sheets with offset and spacing and its own `.clip` JSON (frame, spacing, bounds); tile and animation previews ours lacks; no Tiled or Godot files |
| tilemancer | [malteehrlen/tilemancer](https://github.com/malteehrlen/tilemancer) | Malte Ehrlen | MIT | 2026-01-02; 55 stars | verified in code (`script-fu-register-filter`, GIMP 3) | layers to a sprite sheet PNG |
| gimp-v3-plugins (Export Tileset, Tileset Generator) | [raghavshrma/gimp-v3-plugins](https://github.com/raghavshrma/gimp-v3-plugins) | raghavshrma | none (no licence file) | 2025-06-16 | verified in code (GIMP 3) | PNG export with spacing and an autotile generator; no metadata |
| sprite-packer | [pyl0ader/sprite-packer](https://github.com/pyl0ader/sprite-packer) | pyl0ader | none | 2026-09-24 | claims GIMP 3 (level-editors.md) | layers to a sheet |
| Batcher | above | | BSD-3 | | GIMP 3 | batch layer export, no metadata |
| gimp-vera-tileset-plugin | [jestin/gimp-vera-tileset-plugin](https://github.com/jestin/gimp-vera-tileset-plugin) | jestin | none | 2025-10-26 | GIMP 2.10 (README install paths) | writes a Tiled `.tsx` for the Commander X16 VERA chip |
| GimpSpriteAtlas, gimp-tmxtileme, gimp-tilemap-helper and others | see level-editors.md | | | 2013 to 2024 | GIMP 2 only | |

Verdict: **ours is the only GIMP 3 tool that writes Tiled or Godot
tileset metadata.** nerudaj's utilities have tile and animation previews
worth pointing users to alongside ours.

## 14. Forensics

Ours: [gimp-forensics](https://github.com/sandbranch/gimp-forensics) (six
non-destructive GEGL filters: ELA, JPEG Ghost, noise, luminance gradient,
clone detection, PCA; the Forensics Workbench).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| GIMP-ELA | [sentenza/GIMP-ELA](https://github.com/sentenza/GIMP-ELA) | Alfredo Torre | MIT | 2018-10-02; 75 stars; 13 forks, none pushed after 2018 | GIMP 2 only (Python 2); issue #3 "Will not work in Gimp 3.04" (2025-09, per candidates.md) | ELA only |
| elsamuko Error Level Analysis | [elsamuko/gimp-elsamuko](https://github.com/elsamuko/gimp-elsamuko), branch `gimp-3` | elsamuko | GPL-3.0+ | branch 2025-04-24; repo 2026-09-20 | verified in code: the `gimp-3` copy of `elsamuko-error-level-analysis.scm` still calls `gimp-image-get-active-drawable` and `file-jpeg-save`, removed in GIMP 3; PR #9 (Matthias Zepper, 2026-07) ports three other scripts, not ELA | none working |
| gimp-forensic-tools | [ZlobinSergey/gimp-forensic-tools](https://github.com/ZlobinSergey/gimp-forensic-tools) | ZlobinSergey | none | 2026-07-19 | README only, no code | measurements and action logging, not image analysis |
| SourceForge Gimp Forensics | [sourceforge.net/p/gimp-forensics](https://sourceforge.net/p/gimp-forensics/wiki/Error%20Level%20Analysis/) | | | old | GIMP 2 (per candidates.md) | ELA and JPEG ghost |
| G'MIC, GIMP, GEGL | | | | | no ELA, JPEG ghost or clone detection (grep of the stdlib, community files and both source trees) | none |
| Sherloq | [GuidoBartoli/sherloq](https://github.com/GuidoBartoli/sherloq) | Guido Bartoli | GPL-3.0 | 2026-07-16; 3,213 stars | standalone Python and Qt, not GIMP | a much larger forensic workbench |
| Forensically, FotoForensics | 29a.ch, fotoforensics.com | Jonas Wagner; Neal Krawetz | | | web | the references our README quotes |

Verdict: **ours is the only GIMP 3 version.** For serious casework
Sherloq is the more complete tool; ours is for doing it inside GIMP,
non-destructively.

## 15. Content Credentials (C2PA) viewer

Ours: Image > Forensics > Content Credentials in
[gimp-forensics](https://github.com/sandbranch/gimp-forensics) (reads and
validates, never writes).

| Name | Link | Author | Licence | Last activity | GIMP 3 status | Compared with ours |
|---|---|---|---|---|---|---|
| GIMP issue #8117 "Support the C2PA standard" | [work_items/8117](https://gitlab.gnome.org/GNOME/gimp/-/work_items/8117) | | | opened 2022-04-24, updated 2026-02-17, open | request only; nothing in GIMP master (grep for c2pa and content credentials) | none |
| c2patool and c2pa-rs | [contentauth/c2pa-rs](https://github.com/contentauth/c2pa-rs) | Content Authenticity Initiative | LICENSE-MIT and LICENSE-APACHE files (API reports NOASSERTION) | 2026-09-27 | command line and library | the library behind ours |
| Web and browser viewers | contentcredentials.org/verify, [c2paviewer.com](https://c2paviewer.com/), [Digimarc extension](https://github.com/digimarc-corp/c2pa-content-credentials-extension) | | | | outside GIMP | read files you upload |
| GitHub | code searches `c2pa Gimp.PlugIn`, `c2pa filename:*.py gimp`; repo searches "c2pa gimp", "content credentials gimp" | | | | nothing | |

Verdict: **ours is the only C2PA viewer in GIMP.**

## Method notes and gaps

- GitHub search API limits (30 repository and 10 code searches a minute,
  shared with another agent) made some searches fail once; they were
  repeated. GitHub code search is noisy for these terms and only indexes
  default branches, so a port on a side branch could be missed.
- GitLab issue comments need a login, so only titles, descriptions,
  states and vote counts were read (for example the 19 notes on #575).
- Reddit could not be fetched. GIMP Chat and gimp-forum.net were covered
  only through web searches restricted to those sites; the one relevant
  hit (the 2021 Focus Blur thread) was read.
- pixls.us was searched through its JSON API; the threads cited were
  read. A new thread "Favourite plugins for GIMP 3?" (Chuck Henrich,
  2026-09-27) is collecting a list; worth watching and answering.
- The pgei.de LayerFX download was not fetched (UNVERIFIED); its Liquid
  Rescale file name was read from the page.
- Nothing was run: "claims" rows have not been tested in GIMP.
