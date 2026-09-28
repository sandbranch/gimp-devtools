# Prior art for the to-build list: does a GIMP 3 version already exist?

Research date: 2026-09-27. Reference: GIMP 3.2.6 (tag `GIMP_3_2_6`) and GIMP master (2026-09-26), GEGL master (2026-09-26), G'MIC stdlib master plus the 29 files of GreycLab/gmic-community, the Flathub `org.gimp.GIMP` manifest and the locally installed Flatpak.

For every idea on the list in `candidates.md`, `photoshop-gaps.md` and `level-editors.md`, this checks whether someone already made a GIMP 3 version: a plug-in, a Script-Fu script, a GEGL op, a G'MIC filter usable from GIMP 3, something built into GIMP 3.0 to 3.2.6 or master, or an open MR.

Marks: **verified in code** means the source was read (for GIMP 3 targeting: `gi.require_version('Gimp', '3.0')`, `Gimp.PlugIn`, `libgimp-3.0`, `script-fu-register-filter`, or a GEGL 0.4 op with `gimp:menu-path`). **claims** means a README, a forum post or a web page says so and it was not checked in code. Nothing was run in GIMP.

Where to look first: section 0 (facts that decide the "fit" column), the summary table, then section 5 (re-ranking).

## 0. Facts that decide the fit column

1. **Filters with an aux input are forced destructive.** Verified at `GIMP_3_2_6` and still in master: `app/tools/gimpfiltertool.c` line 456, `if (gegl_node_has_pad (filter_tool->operation, "aux")) disabled_reason = _("Disabled because this filter depends on another image.");`, under the TODO "Once we can serialize GimpDrawable, remove so that filters with aux nodes can be non-destructive". GIMP issue #11904 is open. `app/actions/filters-actions.c` also hard-codes Oilify, Bump Map, Displace, Variable Blur, Lens Blur and Selective Gaussian Blur as aux filters, so those are destructive in GIMP too. Anything needing a second image (exposure fusion, focus stacking, sky replacement with a sky layer, match colour) is therefore a plug-in in practice.
2. **Plug-ins cannot define tools or get canvas events.** Verified in GIMP master libgimp: the procedure types are Batch, Export, File, Image, Load, PDB, Thumbnail and VectorLoad, with no tool procedure; the display API is `is_valid`, `id_is_valid`, `delete`, `present`, `displays_flush`, `displays_reconnect`, with no pointer or event API. GIMP issue #9015 "Add possibility to create tools to the plugin interface" is open (2023-01-02). But "needs core" is narrower than the older docs said:
   - GEGL filters can already take clicked points: `app/propgui/gimppropgui-generic.c` at `GIMP_3_2_6` (lines 93 to 187) gives a property pair tagged `axis=x`/`axis=y` with `unit=pixel-coordinate` a "Pick coordinates from the image" button. Draggable on-canvas handles exist only for ops with hand-written core UI (focus-blur, vignette, supernova, spiral).
   - Plug-ins can run their own interactive canvas in a dialog (hexsian/gimp-mesh-warp, bunnywaffle/GIMP-Quick-Selection, G'MIC-Qt), read `Gimp.Path` as input, and attach editable filters with `Gimp.DrawableFilter` / `gimp_drawable_append_filter` (`libgimp/gimpdrawable.h:96`).
   - What truly needs core: brush tools on GIMP's own canvas with its tool options and dynamics (Liquify parity, a native Quick Selection, promoting N-Point Deformation).
3. **The Flatpak GIMP cannot run host programs.** Verified two ways: the Flathub `org.gimp.GIMP` manifest finish-args (commit 27bd12a1, 2026-09-20) and `flatpak info --show-permissions org.gimp.GIMP` on this machine. Session bus talk names are only `com.canonical.AppMenu.Registrar`, `org.kde.kwin.Screenshot`, `org.gtk.vfs.*`, `org.gnome.Shell.Screenshot` and `org.freedesktop.FileManager1`; there is no `org.freedesktop.Flatpak`, so `flatpak-spawn --host` is not available. It does have `shared=network`, `filesystems=host` and `devices=all`. So an "external tool" bridge (Hugin, enfuse, Siril, apngasm) works on a distro GIMP, and on the Flatpak only after the user runs `flatpak override --user --talk-name=org.freedesktop.Flatpak org.gimp.GIMP` or if the tool is bundled as an `org.gimp.GIMP.Plugin.*` extension. A network bridge (ComfyUI on localhost) works as is. (The `flatpak-spawn --host` result in gimp-tileset-export `docs/godot.md` was inside Godot's sandbox, which has the permission; it does not apply to GIMP.)
4. **Search caveat.** `gh search repos "a b c"` treats a quoted multi-word argument as one phrase, so some empty results from quick searches can be false negatives; the checks below were redone with separate terms or `gh api search/...` where it mattered. The GitHub code-search quota ran out near the end, so a few late code queries (dehaze/skin/clarity with `script-fu-register-filter`, CMYK and perspective code search) did not run. Repo search, fork lists and file reads all completed.

## Summary table

Fit values: **NDE GEGL filter** (single input, stays editable), **plug-in** (multi-image input, file export, or its own dialog canvas), **needs core** (on-canvas brush tools), **belongs elsewhere** (another project or an open MR), **external tool** (wraps a host program; see fact 3).

| Idea | Exists for GIMP 3? | Best existing option | Verdict | Fit for GIMP 3 |
|---|---|---|---|---|
| Clarity / Texture / Dehaze / Whites-Blacks | partly (destructive) | [nicolasloizeau/gimp-multiscale-clahe](https://github.com/nicolasloizeau/gimp-multiscale-clahe); G'MIC afre "Local Contrast", "Texture", "DCP Dehaze" | partly covered by the CLAHE plug-in and G'MIC | NDE GEGL filter |
| Control points (U-Point) | no | G'MIC "Local Similarity Mask" (one point, mask only) | open gap | NDE GEGL filter (point pickers) |
| Sky Replacement | partly (mask only) | [bunnywaffle/gimp-sam-select](https://github.com/bunnywaffle/gimp-sam-select), [pierspad/GIMPSAM](https://github.com/pierspad/GIMPSAM) | partly covered by the SAM plug-ins | plug-in |
| Photomerge / Auto-Align / Auto-Blend via Hugin | no (alignment only) | [CharonM72/gimp3-pythonfu-auto-align-layers](https://github.com/CharonM72/gimp3-pythonfu-auto-align-layers), gimp-image-reg v3, G'MIC Align Layers | open gap | external tool |
| Frequency separation | yes | [Chuck Henrich FS group v3](https://www.chuckhenrich.com/gimp-frequency-separation-plug-in-version-3/); built-in Wavelet-decompose | covered by Henrich FS v3: drop it | n/a |
| Skin retouch (Portraiture-style auto smoother) | partly (destructive) | G'MIC "Smooth [Skin]", Tom Keil "Beauty Retouch" | partly covered by G'MIC | NDE GEGL filter |
| Astro toolkit | no | none (Hennig's plug-ins are GIMP 2 only) | open gap | NDE GEGL filters (+ plug-in) |
| Shake Reduction / blind deconvolution | partly (known PSF only) | [GEGL MR !288](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/288) (open) | partly covered by !288; blind part open | belongs elsewhere (build on !288) |
| Oil Paint (PS-style) | partly | `gegl:oilify`, G'MIC "Brushify" | partly covered by oilify and G'MIC | NDE GEGL filter |
| Path Blur / Spin Blur | partly | `gegl:motion-blur-circular`, G'MIC "Blur [Motion]" | partly covered; path-following and elliptical spin open | NDE GEGL filter (+ path hand-off) |
| Lens flare | mostly | Gradient Flare, `gegl:lens-flare`, G'MIC Light Glow | partly covered: low value | NDE GEGL filter |
| Puppet Warp / NPD | partly | [hexsian/gimp-mesh-warp](https://github.com/hexsian/gimp-mesh-warp) (RBF pins, not ARAP); NPD in Playground | partly covered by gimp-mesh-warp | needs core (promote NPD) |
| Liquify parity | partly | Warp Transform tool; G'MIC "Warp [Interactive]" | partly covered by the Warp tool | needs core |
| Saturation Equalizer | no | G'MIC "Saturation EQ" (a different filter) | open gap | NDE GEGL filter |
| Advanced Unsharp Mask | partly | G'MIC "Sharpen [Multiscale]", LinuxBeaver Sharpen Deluxe | partly covered by G'MIC | NDE GEGL filter |
| Exposure fusion + focus stacking | partly | [dcknuth/gimp_focus_stack](https://github.com/dcknuth/gimp_focus_stack) (Windows, 8-bit); G'MIC Exfusion (Testing) | open gap | plug-in |
| Refocus (Lippe) | yes, pending | [GEGL MR !288](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/288) `gegl:refocus` | covered by !288: drop it (review it instead) | belongs elsewhere (GEGL !288) |
| PhotoRestore | no | none | open gap | plug-in |
| Save for Web | no | JPEG export preview only | open gap | plug-in |
| Ofnuts path tools | no | none; the author ported 8 non-path scripts only | open gap (coordinate with Ofnuts) | plug-in |
| gimp-data-extras | partly | [vitforlinux-gimp/scm](https://github.com/vitforlinux-gimp/scm) (some logo scripts) | open gap for the official package | belongs elsewhere (upstream MR) |
| Smart Separate Sharpen | partly | [v-lavrentikov/gimp-smart-sharpening](https://github.com/v-lavrentikov/gimp-smart-sharpening) | partly covered | NDE GEGL filter |
| Contact Sheet | yes | [Chuck Henrich Contact Sheet v3](https://www.chuckhenrich.com/contact-sheets-in-gimp-3/) | covered by Henrich v3: drop it | plug-in |
| APNG export | partly | [wobbo/gimp-apng](https://github.com/wobbo/gimp-apng) (needs `apngasm`) | partly covered by wobbo/gimp-apng | belongs elsewhere (upstream file-png) |
| DCamNoise2 | no | GEGL noise-reduction, G'MIC denoisers, our Wavelet Denoise | partly covered; the method itself is open | NDE GEGL filter |
| DivideScannedImages | yes | [aschenzle/GIMP-3.x-DivideScannedImages](https://github.com/aschenzle/GIMP-3.x-DivideScannedImages) | covered by aschenzle's port: drop it | plug-in |
| Separate+ | no port; core work in progress | GIMP 3.2 CMYK export; [GIMP draft MR !2379](https://gitlab.gnome.org/GNOME/gimp/-/merge_requests/2379) | partly covered by GIMP core | GCR: NDE GEGL filter; plates/spot/PDF: needs core |
| User Filter / Filter Factory | no | G'MIC "Custom Code" (not compatible) | open gap (small demand) | plug-in |
| Fix-CA | yes | [JoesCat/gimp3-fix-ca](https://github.com/JoesCat/gimp3-fix-ca); our `lensfun:correct` `correct_tca` | covered: drop it | n/a (NDE already via lensfun:correct for known lenses) |
| Automatic upright perspective | no | none | open gap | plug-in |
| Valve VTF | yes, beta | [chev2/gimp-vtf](https://github.com/chev2/gimp-vtf) (Linux only) | partly covered by chev2/gimp-vtf: contribute there | plug-in |
| MathMap | no | G'MIC "Custom Code" and community MathMap demos | partly covered: low value | plug-in (large) |
| Autotile template generator | no | [itsjavi/autotiler](https://github.com/itsjavi/autotiler) (outside GIMP) | open gap inside GIMP | plug-in |
| Sprite atlas packer (GimpSpriteAtlas) | yes | [matheusd/GimpSpriteAtlas](https://github.com/matheusd/GimpSpriteAtlas) (GIMP 3 port); nerudaj spritesheetize | covered by matheusd's port: drop it (test and upstream it) | plug-in |
| Quake / Half-Life WAD export | no | [pwitvoet/wadmaker](https://github.com/pwitvoet/wadmaker) (outside GIMP) | open gap | plug-in |
| Godot XCF importer | no | none; [godot-4-importality](https://github.com/nklbdev/godot-4-importality) is the model | open gap | belongs elsewhere (Godot-side importer) |
| Tiled "edit in GIMP" | partly | Tiled built-in Commands (`%mapfile`, `%mappath`) | partly covered by Tiled Commands | belongs elsewhere (Tiled extension) |
| ComfyUI bridge | yes, several | [nchenevey1/gimp-comfy-tools](https://github.com/nchenevey1/gimp-comfy-tools); [Spellcaster](https://github.com/laboratoiresonore/spellcaster) | covered: drop it | plug-in (network, works in Flatpak) |

## 1. Photo ideas (from photoshop-gaps.md)

### Clarity, Texture, Dehaze, Whites/Blacks
- **Exists:** partly, destructive only. Fit: NDE GEGL filter (single input).
- nicolasloizeau/gimp-multiscale-clahe: GPL-3.0, 4 stars, pushed 2026-08-06, GIMP 3 **verified in code**; blends CLAHE local contrast at six scales, needs numpy, destructive. pixls.us thread 59695 has a user saying it works on 3.2 for Windows (**claims**).
- G'MIC (destructive): stdlib "Details Equalizer", "Equalize Local Histograms"; community afre "Local Contrast" and "Texture", Arto Huotari "Local Contrast Enhancement", Boulanger "DCP Dehaze", Kelday "Simple Dehaze".
- GIMP3-ML's AI dehaze (ivvv/GIMP3-ML 2023; kritiksoman GIMP3-ML branch, last commit 2024-09-21) is written against the 2.99 API (`n_drawables`, `config.begin_run`; `begin_run` is not in 3.2.6's `gimpprocedureconfig.h`): broken on 3.x (**verified in code**, not run).
- GEGL master has no clarity, texture, local Laplacian or dehaze op. LinuxBeaver has none either. No GIMP or GEGL MR.
- **Correction to photoshop-gaps.md:** it missed the CLAHE plug-in and afre "Texture", and implied G'MIC "Local Contrast" is in the stdlib; it is in the community file `afre.gmic`.

### Control points (U-Point style)
- **Exists:** no. Fit: NDE GEGL filter, with the points as `pixel-coordinate` property pairs so each gets a picker (fact 2).
- Searches for control point, upoint, u-point and viveza found no implementation. Nearest: Iain Fergusson's G'MIC "Local Similarity Mask" (one point, mask only, destructive, 2018). nikGimp bridges to the closed Nik executables (Windows).
- **Correction to photoshop-gaps.md:** it said points must come from a GIMP path because plug-ins cannot draw handles. True for plug-ins, but a GEGL op gets coordinate pickers in its dialog, so the path front end is optional.

### Sky Replacement
- **Exists:** partly (segmentation only). Fit: plug-in (the sky is a second image, fact 1).
- Masking for GIMP 3: bunnywaffle/gimp-sam-select (MIT, pushed 2026-09-14, GIMP 3 **verified in code**; text, click and box prompts, one model described as "sky vs ground"); pierspad/GIMPSAM (AGPL-3.0, 2026-08); intel/openvino-ai-plugins-gimp (Apache-2.0, 805 stars, segmentation). afre's G'MIC "Dark Sky" only darkens a sky. Spellcaster has generative sky prompt presets only.
- Nothing does mask, replace and relight/colour-match in one step: the replace plus harmonise workflow is the open part.

### Photomerge, Auto-Align, Auto-Blend via Hugin
- **Exists:** no stitching or blending; alignment only. Fit: external tool (Hugin), which the Flatpak GIMP cannot launch without an override (fact 3).
- Code search for hugin, enfuse, align_image_stack or cpfind inside a GIMP 3 plug-in found nothing. ricardobentes/enfuse (2016) and the old stitchpanorama package are GIMP 2.
- Alignment: CharonM72/gimp3-pythonfu-auto-align-layers (GPL-3.0, 0 stars, 2025-08, GIMP 3 **verified in code**, translation-only cross-correlation); gimp-image-reg v3.0.0; G'MIC "Align Layers". kamilburda/gimp-align-layers (BSD-3, 2026-04) is geometric, not content-based.
- A public list, XDesigns-gfx/Gimp-Plugins-list (27 stars), names a "Hugin (For GIMP 2.99+)" plug-in; the link is Hugin's own download page and no such plug-in exists (**claim found false**).
- **Settled open point from photoshop-gaps.md:** "check before promising Flatpak support": it does not work out of the box.

### Skin retouch and frequency separation
- **Frequency separation: covered.** Chuck Henrich's "Frequency separation group" v3 (chuckhenrich.com; pixls.us threads 2025-03-31 and 2025-09-13): GPL-3+, `Gimp.PlugIn`, GIMP 3, **verified in code**; its blur is a `Gimp.DrawableFilter` running `gegl:gaussian-blur`, so the split stays editable. No git repo; the zip only downloads with a Referer header. Wavelet-decompose is also built into 3.2.6 (source present at the tag).
- **Automatic skin smoother: partly covered.** Fit: NDE GEGL filter. G'MIC (destructive): stdlib "Smooth [Skin]", "Detect Skin"; Tom Keil "Beauty Retouch", "Portrait Retouching"; Iain Fergusson "Easy Skin Retouch", "Skin Mask". AiZViberCoder/gimp-auto-dodge-burn (GIMP 3, 2026-09-22) does AI dodge and burn. No editable one-slider skin smoother exists.
- **Corrections to photoshop-gaps.md:** the frequency separation plug-in it marked UNVERIFIED is Henrich's (GPL-3+, GIMP 3). auto-dodge-burn's `LICENSE.txt` is plain MIT (© 2026 Mariano Sokal); GitHub shows NOASSERTION only because of a title line. G'MIC "Beauty Retouch" and "Detect Skin" were missing. Outside this list: the "Interactive luminosity masks for GIMP 3" plug-in it marked UNVERIFIED is also Henrich's (GPL-3+, GIMP 3 **verified in code**, 5,161 lines, 14 languages), which overlaps our gegl-adjustments luminosity masks.

### Astro toolkit (star shrink, gradient removal, Hennig)
- **Exists:** no. Fit: NDE GEGL filters (star mask, star reduce, star colour; gradient removal from sample points passed as coordinate properties), plus a small plug-in if needed.
- Every copy of Georg Hennig's gimp-plugin-astronomy is GIMP 2: gimp-plugins-justice (pushed 2023-10-21), JoesCat's fork (2024-02-19; `configure.ac` requires `gimp-2.0`), funxiun (2019). pigeond/gimp-plugin-starnet and IgnacioChiaravalle/Astrophotography-Processor are GimpFu (GIMP 2). verove-jordan/astronomy drives Siril and GIMP 2.10 Script-Fu from outside.
- G'MIC has no star-reduction or gradient-removal filter (grep over stdlib and all 29 community files). Siril's GraXpert integration lives in Siril.
- photoshop-gaps.md was right; it lacked the JoesCat fork.

### Shake Reduction / blind deconvolution
- **Exists:** partly. Fit: belongs elsewhere: build on GEGL MR !288.
- GEGL MR !288 (clodman84, LGPL-3+): opened 2026-09-16, updated 2026-09-24, open, not draft, needs a rebase. Adds `gegl:refocus`, `gegl:wiener-filter`, `fft`, `fftshift`, `fftmagnitude` and bundles pocketfft (**verified in the diff**). PSF is parametric only (linear motion, disc, Gaussian, noise ratio); no user kernel. The author writes that the FFT ops open the way to blind deconvolution. Addresses GEGL issues #12 (2011) and #415 (2020).
- G'MIC: GUI filters need a known kernel (Deblur, Richardson-Lucy, Gold-Meinel, community "Deconvolve"). Community command `deconvolve_richardsonlucy_blind` in `jerome_boulanger.gmic` is truly blind (**verified in code**) but has no GUI entry.
- JoesCat refocus-it `gimp3` branch (last commit 2026-03-01) needs a known kernel. GIMP3-ML "deblur" targets the 2.99 API.
- photoshop-gaps.md is correct.

### Oil Paint (Photoshop style)
- **Exists:** partly. Fit: NDE GEGL filter, keeping any bump-map step internal (fact 1: Oilify and Bump Map are aux filters in GIMP, so destructive).
- `gegl:oilify` (mode filter; radius, exponent, intensity mode). G'MIC "Brushify" (with light type and strength), "Kuwahara" (isotropic only), "Painting", "Lylejk's Painting", "Vector Painting". No anisotropic Kuwahara anywhere; no GIMP 3 oil-paint plug-in.
- **Correction to photoshop-gaps.md:** "`gegl:bump-map` exists" is true, but in GIMP it is forced destructive as a filter.

### Path Blur and Spin Blur
- **Exists:** partly. Fit: NDE GEGL filter, with a small plug-in handing over the active `Gimp.Path`. Not core work. Patent caution from photoshop-gaps.md still applies.
- Spin: `gegl:motion-blur-circular` (circular only), G'MIC "Blur [Angular]". No elliptical or strobed spin.
- Path: G'MIC "Blur [Motion]" (Tschumperlé, updated 2024-04-02) builds one curved kernel from 2 to 5 control points and applies it everywhere (**verified in code**): a curved shake, not blur along paths that varies over the image.
- **Correction to photoshop-gaps.md:** it missed G'MIC "Blur [Motion]".

### Lens flare
- **Exists:** mostly. Fit: NDE GEGL filter; low value.
- Gradient Flare (C plug-in in GIMP master, destructive) has secondary flares with size, rotation, hue and probability gradients, and presets. `gegl:lens-flare` generates reflections from an X/Y position. LinuxBeaver "Starburst" is decorative.
- **Correction to photoshop-gaps.md:** "multi-element ghosts along the optical axis" are already in Gradient Flare. Missing: anamorphic streaks, flare from detected highlights, and an editable version.

### Puppet Warp / N-Point Deformation
- **Exists:** partly. Fit: needs core (promote NPD); the plug-in route is proven for RBF warps.
- NPD is still Playground-only: `app/tools/gimpnpointdeformationtool.c` registers the tool only when `playground_npd_tool` is set, at `GIMP_3_2_6` and in master (**verified in code**). No MR to promote it. GEGL MR !251 "libs/npd: Fix crash" merged 2026-02-13. GIMP issues #649 (open since 2015) and #8017 (open, 3 votes).
- hexsian/gimp-mesh-warp (GPL-3.0, created 2026-09-27, fork of bunnywaffle/gimp-mesh-warp, 2026-08-21): Python plug-in plus C GEGL op, requires Gimp 3.0, attaches a `Gimp.DrawableFilter` (**verified in code**). Editable mesh warp, 15 Photoshop Warp presets, "Puppet Pins" in its own canvas; its README says pins use a Gaussian RBF, not ARAP, and "cannot rotate limbs around a joint".
- **Correction to photoshop-gaps.md:** it missed gimp-mesh-warp.

### Liquify parity
- **Exists:** partly. Fit: needs core for brush parity; face-aware sliders alone could be a plug-in (landmarks to displacement field to editable op).
- Warp Transform modes in master: Move, Grow, Shrink, Swirl CW/CCW, Erase, Smooth; no freeze mask in `gimpwarptool.c`. Warp MRs from 2023 and 2024 are closed; recent issues are crash bugs. G'MIC "Warp [Interactive]" (keypoints in its own window) is a partial alternative (not tested on Wayland). No GIMP 3 liquify or face-aware plug-in.
- photoshop-gaps.md holds. Related, outside this list: bunnywaffle/GIMP-Quick-Selection (brush in its own dialog, licence NOASSERTION, not vetted) shows that the doc's "Quick Selection needs core" is overstated.

## 2. Old plug-ins (from candidates.md)

### Saturation Equalizer and Advanced Unsharp Mask (Tibor Bamhor)
- **Sat EQ: open gap.** Fit: NDE GEGL filter. tibor95/gimp-plugin-satequalizer (GPL-3.0, 2 stars, pushed 2016-06-07), no port. G'MIC "Saturation EQ" (gmic-community `iain_fergusson.gmic`, 2014) is not a port (**verified in code**): it sets saturation by lightness (9 bands) and hue (9 bands) in 8-bit HSL, not by current saturation, with no temperature or auto-align.
- **AUMask: partly covered** by G'MIC "Sharpen [Multiscale]" and "Details Equalizer", and LinuxBeaver's GEGL "Sharpen Deluxe" (GPL-3.0, high-pass with a choice of blur, NDE). Fit: NDE GEGL filter.
- **Settles photoshop-gaps.md's note** that the G'MIC filter "may be a port": it is not. candidates.md was right.

### Exposure fusion (Mertens) and focus stacking
- **Exists:** partly. Fit: plug-in (N input layers; aux filters are destructive anyway, fact 1). A self-contained implementation beats an enfuse wrapper because of fact 3.
- dcknuth/gimp_focus_stack (MIT, 3 stars, 2025-08): README says Windows-only, calls `focus-stack.exe`, works on a folder not layers, outputs 8-bit JPEG (**claims**).
- G'MIC Exfusion, Exfusion3, Exfusion5 and Arto Huotari's "Exposure Fusion Weight Map" are all in Testing.
- No GIMP 3 enfuse or align_image_stack wrapper; no GEGL fusion MR. GEGL !270 (merged 2026-05-05) only cleans up `exp-combine`, still not in any GIMP menu.
- candidates.md is still accurate.

### Refocus (Lippe)
- **Covered by GEGL MR !288: drop it.** `gegl:refocus` does disc, Gaussian and linear motion Wiener deconvolution (FFT-based rather than Lippe's FIR, same purpose). Help review and test !288 instead.
- Lippe's Refocus is still GIMP 2 only. JoesCat refocus-it `gimp3`: 2026-02-28 commit says it compiles but "needs more work".
- **Correction to candidates.md:** "No deconvolution op in GEGL" is true of master but misses the open !288.

### PhotoRestore (Daniell)
- **Open gap.** Fit: plug-in (Python first).
- stongey/PhotoRestore (GPL-3.0, 70 stars) last pushed 2020-05-10; issues #1 and #2 (GIMP 3, 2025-01) unanswered; none of its 5 forks is ported. G'MIC "Retro Fade" and "Old Photograph" do the opposite.
- **Correction to candidates.md:** "last activity 2019-07-23" is a commit date; the last push is 2020-05-10.

### Save for Web (Juska)
- **Open gap.** Fit: plug-in.
- auris/gimp-save-for-web (94 stars, pushed 2022-08), no GIMP 3 fork. GIMP master: only JPEG export has a preview and "File size without metadata"; WebP, PNG, GIF, HEIF/AVIF and JPEG XL show neither. No MR.
- candidates.md is correct.

### Ofnuts path tools
- **Open gap: not ported.** The brief for this research said they are ported already; that is **wrong**. Checked 2026-09-27 via the SourceForge RSS listing of gimp3-tools: `general/` has layer-tiles, export-layers, list-guides, align-layers, colormap-to-paths, interleave-layers, mirror-layers, and `management/` has resource-manager. That is 8 scripts, none of them path tools. The gimp-path-tools page still says its scripts "will not run on Gimp 3.x"; its newest file is ofn-path-edits (2025-04-02, GIMP 2). No third-party ports on GitHub and none in sandbranch. The author has published nothing for 15 months.
- Fit: plug-in; still a "coordinate with Ofnuts" item.
- candidates.md is accurate.

### gimp-data-extras
- **Open gap for the official package.** Fit: belongs elsewhere (upstream MR to gitlab.gnome.org/GNOME/gimp-data-extras).
- No release since 2.0.4 (2018); last MR merged 2023-08-20. A few pieces are GIMP 3 already (py-slice, benchmark-foreground-extract, max-rgb in C); clothify, shadow_bevel, sphere and whirlpinch are still Python 2. 35 of its 54 Script-Fu files call procedures removed in GIMP 3 (grep in a clone).
- vitforlinux-gimp/scm (GPL-3.0, 19 stars, 2026-05) has about 50 logo scripts updated for GIMP 3, with little overlap.

### Smart Separate Sharpen
- **Partly covered.** Fit: NDE GEGL filter (edge mask, unsharp, light/dark split).
- v-lavrentikov/gimp-smart-sharpening (BSD-3, 2 stars, 2026-08-13): GIMP 3 C plug-in (**verified in code**): edge mask, denoise outside, sharpen inside; destructive; no separate light and dark halos. G'MIC "Sharpen [Unsharp Mask]" has darkness/lightness but no edge mask. LinuxBeaver Sharpen Deluxe has no halo split. The original script is unported.

### Contact Sheet
- **Covered by Chuck Henrich Contact Sheet v3: drop it.** Zip downloaded and headers read: GPL-3+, version 2026-04-05, GIMP 3 (**verified in code**); grid, captions, multi-page, 8/16-bit, colour profiles, saved settings. No public git repo.
- GIMP issue #9281 still open; GIMP MR !1087 (contact sheet) closed unmerged 2024-05.
- **Correction to candidates.md:** licence and source were marked UNVERIFIED; both are now confirmed.

### APNG export
- **Partly covered by wobbo/gimp-apng.** Fit: belongs elsewhere (an export procedure in GIMP's `file-png.c`).
- GIMP master `file-png.c`: APNG load only (MR !2220, merged 2025-06); no export and no MR for it. wobbo/gimp-apng (MIT, 0 stars, 2026-08-18) is GIMP 3 Python (**verified in code**) but shells out to `apngasm`, which the Flatpak cannot reach (fact 3). Other forks (stonedDiscord 2024, peterkaczorowski 2025) are GIMP 2 C.

### DCamNoise2
- **Partly covered; the method itself is open.** Fit: NDE GEGL filter.
- Only GIMP 2 packaging exists (pld-linux 2012, AUR). G'MIC has many denoisers but no DCamNoise port; GEGL issue #83 (NL-Means) open. candidates.md is accurate.

### DivideScannedImages
- **Covered by aschenzle/GIMP-3.x-DivideScannedImages: drop it.** Python 3 plug-in with `gi.require_version("Gimp","3.0")`, `Gimp.PlugIn`, `Gimp.ImageProcedure`, `Gimp.file_save` (**verified in code**, not run): single and batch entries, built-in deskew, preview with per-crop rotate and keep, tests. LICENSE says GPL-2+ (GitHub: NOASSERTION); 0 stars, pushed 2026-05-20; installer is PowerShell only; an `Agents.MD` suggests AI-assisted. Offered upstream in FrancoisMalan issue #22 (no reply; upstream idle since 2022-02). GIMP issue #329 closed 2026-08-05 as a third-party idea.
- **Corrections to candidates.md:** calling both ports "unvetted" was wrong for aschenzle's, which is complete. The lilcheeks fork (2026-03-02) is not a port: a 25-line `from gimpfu import *` stub whose body is `pass`.

### Separate+
- **Partly covered by GIMP core work.** Fit: GCR/UCR as an NDE GEGL filter; plates, spot channels and CMYK PDF need core.
- GIMP draft MR !2379 "First steps for full CMYK mode" (cmyk.student, updated 2026-09-20): per its description, convert to CMYK, CMYK channels, CMYK JPEG XL/TIFF/JPEG/PSD import and export without conversion, XCF (**claims**, MR description). `file-pdf-export.c` on the 3.2 branch has no CMYK code. GEGL `gegl:gcr` lives in `operations/workshop/gcr.c` (Kolås 2018, ink limit and amount), not built by default. G'MIC has only "Mixer [CMYK]" and "CMYK Tone". LinuxBeaver's "CMYK Print Preview" is an RGB look only. pgei.de's "for GIMP 3.2" Separate+ is still a libgimp-2.0 build.
- **Corrections to candidates.md:** it missed MR !2379, and the op name is `gegl:gcr`, not `gray-component-replacement`.

### User Filter / Filter Factory
- **Open gap, small demand.** Fit: plug-in (the evaluator could back a GEGL op).
- No GIMP 3 or G'MIC interpreter; a 2023 pixls.us thread concluded G'MIC lacks it. References: 0xC0000054/pdn-filter-factory (GPL-3.0, reuses UserFilter's parser per its author), danielmarschall/filter_foundry (GPL-2.0, active 2026-08). UserFilter's own source licence is still UNVERIFIED (SourceForge blocked the download).

### Fix-CA
- **Covered: drop it.** JoesCat/gimp3-fix-ca 5.0 (2026-02-13, GPL-3.0, C, GIMP 3, **verified in code**; destructive). Fedora review bug 2327257 still NEW; not on Flathub.
- **New finding:** our own gimp-lensfun op `lensfun:correct` has a `correct_tca` property (`gegl/lensfun-correct.cc:79`): NDE lateral CA correction already exists for lenses in the Lensfun database. candidates.md item 17 (NDE Fix-CA op) is therefore mostly covered; only lenses without a profile remain. GEGL has no CA op or MR; GIMP issue #9702 is open. G'MIC "Chromatic Aberrations" simulates; community "Unpurple" removes fringing.

### Automatic upright perspective
- **Open gap.** Fit: plug-in (automatic mode), with a guided mode reading lines from a GIMP path.
- Nothing on GitHub, in G'MIC (a manual 2010 warp only) or in GIMP MRs. GIMP issues #2026 and #2165 (2018) open. darktable `src/iop/ashift.c` (GPL-3+) is the reference. candidates.md is accurate.

### Valve VTF
- **Partly covered by chev2/gimp-vtf: contribute there.** GIMP 3 C++ plug-in with load and export procedures on sourcepp (**verified in code**); GPL-3.0, 10 stars, pushed 2025-08-05; no releases, no Windows or macOS build (its issue #1); issue #2 (2025-10-29) reports crashes and corrupt output on non-RGBA8 formats. Artfunkel's issue #16 "Gimp 3 support" (12 reactions) does not mention it.
- **Correction to candidates.md:** it said there was no port and planned porting Artfunkel's code.

### MathMap
- **Partly covered, low value.** schani/mathmap last commit 2022-04-19; no fork has new work. G'MIC "Custom Code" covers formula filters; community "Demo Mathmap XY/RA", "Mathmap Flag", "Spiral" imitate it. The node Composer is unfilled but not worth the effort.

## 3. Game and level ideas (from level-editors.md)

### Autotile template generator
- **Open gap inside GIMP.** Fit: plug-in (builds layers and guides, writes Wang sets together with gimp-tileset-export).
- Nearest GIMP 3 item: raghavshrma/gimp-v3-plugins "Tileset Quick Generator" (no licence, 1 star, 2025-06-16, **verified in code**), one personal layout, not Wang/blob 47/RPG Maker. pyrareae/GodotAutotileAssembler (28 stars, 2018, no licence) is GimpFu (GIMP 2).
- Outside GIMP: itsjavi/autotiler (MIT, 74 stars, pushed 2026-09-26, web and itch.io, exports to Godot), lascent/autotileset-generator (MIT, 2026-09), toku-sa-n/blob-tileset-generator (BSD-3), ticial/3x3-min-gen (CC0), TilePipe (MIT), Aseprite "AutoBlob", Tilesetter (paid). An itch.io search found no GIMP plug-in.

### Sprite atlas packers (GimpSpriteAtlas)
- **Covered by matheusd/GimpSpriteAtlas: drop the port.** Commit "First GIMP 3.0 version" 2025-04-25, `Gimp.PlugIn`, Gimp 3.0 (**verified in code**, not run on 3.2); GPL-3.0, 0 stars; writes JSON array and hash, .atlas, CSS, XML. Never sent upstream (BdR76/GimpSpriteAtlas, 43 stars, pushed 2024-03-09, issue #5 "doesn't work" open). What is left: test it on 3.2 and offer it upstream or package it.
- Other GIMP 3 options: nerudaj/gimp-pixel-art-utils `spritesheetize` (Apache-2.0, 10 stars, 2026-02-20, sheet plus JSON), alsimoes/handcrafted_gimp_tools (MIT, 2026-09-05, sheet plus JSON), HavilandTuff/guillotine-plus (GPL-3.0, 2026-02, slicer), tilemancer and sprite-packer (no metadata).
- **Correction to level-editors.md:** its table marks GimpSpriteAtlas "GIMP 3? no" and misses the four plug-ins above.

### Quake WAD2 / Half-Life WAD3 export
- **Open gap.** Fit: plug-in (export procedure).
- No GIMP plug-in for WAD at all; a 2009 gimp-developer thread was told to write one. Psycrow101/GIMP-hl-sprite-plugin (Half-Life `.spr`, 18 stars, 2024-03-01, no licence) is GimpFu; its two forks have no GIMP 3 work.
- References outside GIMP: pwitvoet/wadmaker (MIT, 69 stars, 2026-05-12, WAD3 and sprites), strisselstudios/WadForge (GPL-3.0, 2026-08, WAD2 and WAD3), kennedypro86/wad-toolkit (GPL-3.0), urgorri/fastwad (MIT), makewad-rb (MIT).

### Godot XCF importer
- **Open gap.** Fit: belongs elsewhere (a Godot-side import plug-in calling `gimp-console-3.2`, as sketched in gimp-tileset-export `docs/godot.md`).
- Godot Asset Library API: 0 results for "xcf" and "gimp" (Godot 3.5, 4.2, 4.4), against 4 to 8 Aseprite importers. No XCF proposal in godot-proposals (PSD: #6303 open, 46 reactions). nklbdev/godot-4-importality (MIT, 538 stars, 2026-03-21) imports Aseprite, Krita, Pencil2D, Piskel and Pixelorama, drives Krita for export, and is the model; no GIMP request in its issues.

### Tiled "edit in GIMP"
- **Partly covered by Tiled's built-in Commands.** Fit: belongs elsewhere (a small Tiled JavaScript extension).
- `src/tiled/command.cpp` (master): on a tileset document `%mapfile` is the `.tsx` and `%mappath` its folder, so `gimp %mappath/<name>.xcf` or a wrapper works today; there is no variable for the tileset image. The tiled-extensions collection has nothing for GIMP.

### ComfyUI and other AI bridges
- **Covered: drop it.** Fit: plug-in over HTTP (works in the Flatpak: `shared=network`).
- Spellcaster by laboratoiresonore ([github.com/laboratoiresonore/spellcaster](https://github.com/laboratoiresonore/spellcaster)): a GIMP 3 ComfyUI bridge with many tools; created 2026-03-31, pushed 2026-09-26, 60 stars; licence not stated consistently (checked 2026-09-27).
- nchenevey1/gimp-comfy-tools (GPL-3.0, 137 stars, 2026-01-13, GIMP 3 **verified in code**): text-to-image, image-to-image, inpaint from selection, workflow manager, metadata viewer. Companion nodes: nchenevey1/comfyui-gimp-nodes (GPL-3.0).
- Others: Charlweed/gimp_comfyui (MIT, 36 stars, pushed 2025-01-08; open issues suggest it is stale on 3.0 final), ProgrammerDruid/gimp-comfy-ai (MIT, 2025-12, **claims** 3.0.4+), swaynos/gimp-comfyui-sam (GPL-3.0, 2026-09-23), gwpelletier/gimp-plugin-ComfyUI (GPL-3.0, 2026-09-23).
- Non-ComfyUI: intel/openvino-ai-plugins-gimp (Apache-2.0, 805 stars, 2026-09-14), zquestz/dream-prompter (MIT, 151 stars, cloud via Replicate), bunnywaffle/gimp-sd-cpp (MIT, stable-diffusion.cpp), qualcomm/wos-ai-plugins (Snapdragon Windows, licence unclear), Nenotriple/gimp_upscale (MIT, 144 stars, **claims** 3.0), mamipi972 deep_erase (LaMa) and rembg plug-ins (MIT). Still GIMP 2 only: gimp-stable-boy (404 stars), blueturtleai/gimp-stable-diffusion (352 stars).
- Only open space: Krita AI Diffusion style live painting and regions; Charlweed's attempt looks stale.

## 4. LinuxBeaver check

115 repos under github.com/LinuxBeaver; his GEGL ops are GEGL 0.4 binaries with `gimp:menu-path`, so GIMP 3 and NDE. None covers clarity/texture/dehaze, control points, sky replacement, skin smoothing, astro, Saturation EQ, chromatic aberration, perspective, Filter Factory, path blur, oil paint or optical lens flare. Partly relevant: "Sharpen Deluxe" (GPL-3.0, high-pass sharpen with a choice of blur; overlaps AUMask and Smart Separate Sharpen without a halo split), "Orton", "Bokeh", "Starburst", "Radiance" (bloom), and "AI_Vibe_Coded_GEGL_Plugins" (its "CMYK Print Preview" is an RGB look, not separation). None turns an idea into "drop it".

## 5. Re-ranked: what is still worth building

Dropped as covered: Frequency separation (Henrich FS v3), Refocus (GEGL !288: review it), Contact Sheet (Henrich v3), DivideScannedImages (aschenzle), Fix-CA (JoesCat plus our `lensfun:correct` TCA), GimpSpriteAtlas port (matheusd), ComfyUI bridge (gimp-comfy-tools, Spellcaster).

Redirected to contributions rather than new projects: Valve VTF (chev2/gimp-vtf), shake reduction (on top of GEGL !288), APNG (export in GIMP `file-png.c`), gimp-data-extras (upstream MR), Separate+ (coordinate with MR !2379; `gegl:gcr` promotion), Puppet Warp and Liquify (core), GimpSpriteAtlas (test matheusd's port and upstream it), Godot XCF importer and Tiled "edit in GIMP" (other projects).

Top 8, weighing gap, demand, effort and fit (NDE GEGL filters rank up because they give what nobody else has: editable versions of things that exist only destructively in G'MIC):

1. **Clarity and Texture (then Dehaze)** as NDE GEGL filters: very high demand, only destructive G'MIC filters and one numpy CLAHE plug-in exist, and the Microsoft dark channel patent lapsed in 2020 (Adobe dehaze patents still unchecked).
2. **Control points (U-Point)** as an NDE GEGL filter with coordinate pickers: a complete gap in all open software, patents expired 2022, and fact 2 means no core work is needed.
3. **Exposure fusion and focus stacking** as a self-contained plug-in: nothing usable in GIMP 3 (a Windows-only 8-bit wrapper and G'MIC Testing filters), and a built-in Mertens core avoids the Flatpak host-spawn wall that sinks an enfuse wrapper.
4. **Saturation Equalizer** as an NDE GEGL filter: small, fully open (G'MIC's "Saturation EQ" is a different filter), a top-10 registry plug-in.
5. **Save for Web** as a plug-in: the #2 registry plug-in of all time, still no GIMP 3 replacement and no upstream MR; medium to large.
6. **Astro toolkit** (star mask, star reduce, gradient removal from sample points) as NDE GEGL filters: nothing in GIMP 3, G'MIC or LinuxBeaver, all classical methods, small to medium.
7. **PhotoRestore** as a Python plug-in: open gap with a documented algorithm, 70 stars and an unanswered GIMP 3 issue.
8. **Automatic upright perspective** as a plug-in: need is high and nothing exists anywhere for GIMP, with darktable's ashift as a GPL-3 reference; medium to large.

Next in line: an NDE skin smoother (G'MIC covers it destructively), Quake/Half-Life WAD export (small, fully open, TrenchBroom users), the autotile template generator (pairs with gimp-tileset-export), APNG export as a GIMP MR (small), Smart Separate Sharpen as an NDE op (small), Ofnuts path tools (only with the author's agreement), and PS-style Oil Paint (narrow gap).
