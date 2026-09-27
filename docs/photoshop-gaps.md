# Photoshop features and plug-ins that GIMP 3.2 lacks: a fact-checked sweep

Date of research: 2026-09-27. Reference build: Flathub `org.gimp.GIMP` 3.2.6 (commit dated 2026-09-20) with the Flathub G'MIC 4.0.5, Resynthesizer 3.0.1 and Fourier extensions installed. GIMP source checked at tag `GIMP_3_2_6`; GEGL source at master (version 0.4.73, last commit 2026-09-17).

This builds on `gimp-plugin-devtools/docs/candidates.md` (abandoned GIMP 2 plug-ins) and does not repeat it. Where a Photoshop gap is already a candidate there (exposure fusion and focus stacking, Refocus, Save for Web, Separate+), it is only cross-referenced.

Items marked **UNVERIFIED** could not be checked against a primary source. Popularity is the weakest evidence in this report: Adobe publishes no feature usage data, so it rests on best-of lists, vendor user claims (marked as such), GIMP issue votes and forum threads.

## 0. Facts that shape the whole list

1. **What GIMP 3.2.6 actually ships.**
   - Every GEGL operation in the Flatpak was listed with `flatpak run --command=gegl org.gimp.GIMP --list-all`.
   - Every GEGL and `gimp:` operation GIMP puts in its menus was read from `app/actions/filters-actions.c`.
   - GEGL ops can also add themselves to menus through the `gimp:menu-path` key. In GEGL master only six do: `bevel`, `inner-glow`, `styles`, `local-threshold`, `sharpen` and `shuffle-search`.
   - Anything else can still be reached through Tools > GEGL Operation.
   - The Flatpak ships no LUT op, no selective-colour op, no hue-weighted black-and-white op, no clarity/texture/dehaze op and no deconvolution op.
2. **Upstream GIMP itself lists the missing Photoshop adjustments.**
   - GIMP issue [#15505](https://gitlab.gnome.org/GNOME/gimp/-/work_items/15505), "Implement PSD Adjustment Layers as GEGL Filters" (2025-12), tracks which PSD adjustment layers can be imported.
   - For **Selective Color** and **Color Lookup**, it says "Not sure what the equivalent GEGL filter(s) would be". **Gradient Map** only has a workshop op. **Black/White** and **Photo Filter** are only approximated.
   - Draft MR [!2598](https://gitlab.gnome.org/GNOME/gimp/-/merge_requests/2598) (Akascape, last updated 2026-05-03) maps B&W, Photo Filter, Exposure and Vibrance to "similar GEGL operations". It still lists Selective Color and Gradient Map under "Need Help".
   - Already merged: !2563 (8 adjustment types, 2026-06-01) and !2975 (PSD Curves import, 2026-08-26).
   - So new ops written here do two jobs at once: they are filters people use, and they are what PSD import needs. Upstream is asking for them.
3. **Aux-input filters are still forced destructive** (candidates.md section 0, item 5; still true in 3.2.6). GIMP issue [#11904](https://gitlab.gnome.org/GNOME/gimp/-/work_items/11904) "Enable filters with Aux Inputs to be non-destructive" is open.
   - This decides the form of several candidates. A single-input op gets full non-destructive editing (NDE).
   - Anything that needs a second image cannot be NDE today: Match Color against a reference, Sky Replacement with a sky layer, and the "underlying layer" half of Blend If.
4. **Plug-ins cannot create interactive tools.** GIMP issue [#9015](https://gitlab.gnome.org/GNOME/gimp/-/work_items/9015) "Add possibility to create tools to the plugin interface" is open.
   - Brush-driven Photoshop features therefore need GIMP core C work, not a plug-in: Liquify, Spot Healing Brush, Quick Selection and Pattern Preview.
   - They are listed separately in section 3.
5. **GIMP 3.2 already has the NDE plumbing Photoshop users look for.**
   - Non-destructive filters work on layers, groups and channels.
   - "Pass through" groups with filters work as adjustment layers.
   - Link layers work like linked Smart Objects, and vector layers exist.
   - PS curves and levels presets (`.acv` and `.alv`) can be imported.
   - Source: [GIMP 3.2 release notes](https://www.gimp.org/release-notes/gimp-3.2.html); `.acv` and `.alv` also confirmed in `app/tools/gimpcurvestool.c` and `gimplevelstool.c`.
   - NDE filters on channels matter a lot for candidate 5 (luminosity masks).
6. **Coordinate with work already in flight.**
   - WarisMaqbool (GSoC 2026, issue [#16339](https://gitlab.gnome.org/GNOME/gimp/-/work_items/16339)) has two GEGL MRs:
     - Draft GEGL MR [!275](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/275) "Implement PSD compatible gegl:inner-glow" (2026-09-04).
     - GEGL MR [!269](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/269), which ported the legacy sharpen plug-in to a GEGL op (merged 2026-08-13).
     - A PSD-compatible Bevel is his next stated task.
     - This overlaps the layerfx port directly, so talk to him before duplicating Inner Glow or Bevel.
   - clodman84 opened GEGL MR [!288](https://gitlab.gnome.org/GNOME/gegl/-/merge_requests/288) on 2026-09-16. It adds `refocus`, `wiener-filter`, `fft`, `fftshift` and `fftmagnitude` ops using Wiener deconvolution with a known PSF.
     - That overlaps candidates.md item 7 (Refocus) and is the natural base for Shake Reduction (candidate 10 here).
7. **Nik Collection already runs from GIMP 3.**
   - [iiey/nikGimp](https://github.com/iiey/nikGimp): GPL-3.0, last push 2025-06-06, needs GIMP 3.0 or newer. It is a ShellOut-style bridge to the Nik executables, tested with the free Google Nik 1.2.11 on Windows 10 and 11.
   - Google Nik 1.2.11 is closed freeware: 101,810 downloads on [TechSpot](https://www.techspot.com/downloads/6809-google-nik-collection.html). Its installer fails on macOS Sonoma and later ([odd.blog](https://odd.blog/2021/10/02/the-old-nik-collection-is-still-free/), [marcrphoto 2026-06](https://marcrphoto.wordpress.com/2026/06/02/the-free-google-nik-collection-still-exists-in-2026-but-theres-a-catch/)).
   - So "convert Nik" is not the job. The job is open equivalents of the parts that have none, chiefly Viveza's U-Point control points (candidate 7).
8. **Photoshop 8bf hosting: PSPI has no GIMP 3 version.**
   - [draekko/gimp-pspi](https://github.com/draekko/gimp-pspi): MIT, © 2008 Tor Lillqvist, last push 2017, 32-bit Windows only.
   - [PSFilterPdn](https://github.com/0xC0000054/PSFilterPdn), the MIT-licensed 8bf host for Paint.NET, is maintained (push 2026-08-31) and would be the reference for a port.
   - A port would be Windows-only and large, so it is not ranked here (see section 4).

## 1. Ranked candidates

Score = gap (0 to 3) x popularity (1 to 3) / effort (small 1, medium 2, large 3). As in candidates.md, scores are a judgement aid, not a measurement.

| # | Candidate | Photoshop origin | Gap | Pop | Effort | Score | Form |
|---|---|---|---|---|---|---|---|
| 1 | Color Lookup: 3D LUT op (.cube, .3dl, Hald) | Color Lookup adjustment | 3 | 3 | S | 9.0 | GEGL op (+ PSD `clrL` import MR) |
| 2 | Selective Color (PS-compatible) | Selective Color adjustment | 3 | 2.5 | S | 7.5 | GEGL op (+ PSD `selc` import) |
| 3 | Hue-weighted Black & White with tint | Black & White adjustment; Silver Efex core | 2.5 | 2.5 | S | 6.3 | GEGL op (+ PSD `blwh`) |
| 4 | Blend If (this-layer tonal/channel split sliders) | Layer Style > Blending Options | 2.5 | 2 | S | 5.0 | GEGL op |
| 5 | Luminosity / zone / saturation masks panel | TK9, Lumenzia, Raya Pro panels | 2 | 2.5 | S | 5.0 | Plug-in using NDE filters on channels |
| 6 | Camera Raw "presence" set: Clarity, Texture, Dehaze (dehaze: patent caution), Whites/Blacks | Camera Raw filter | 2.5 | 3 | M | 3.8 | GEGL ops |
| 7 | Control points (U-Point style local adjustments) | Nik Viveza / Color Efex control points | 3 | 2.5 | M | 3.8 | GEGL op + plug-in (points from a path) |
| 8 | Sky Replacement (classical mask + colour harmonisation) | Edit > Sky Replacement | 2.5 | 2.5 | M | 3.1 | Plug-in (+ small GEGL helper ops) |
| 9 | Photomerge / Auto-Align / Auto-Blend via Hugin | Photomerge, Auto-Align, Auto-Blend Layers | 2.5 | 2.5 | M | 3.1 | Plug-in (external tools) |
| 10 | Skin retouch (Portraiture-style) | Imagenomic Portraiture, retouch panels | 2 | 3 | M | 3.0 | GEGL op (+ skin-mask op) |
| 11 | Astro toolkit (star shrink, gradient removal, star colour; port Hennig) | Astronomy Tools actions, RC Astro | 2.5 | 1.5 | S/M | 2.5 | Plug-in + GEGL ops |
| 12 | Shake Reduction (blind motion-kernel estimation; patent caution) | Filter > Sharpen > Shake Reduction | 3 | 2 | L | 2.0 | GEGL op on top of MR !288 |
| 13 | Puppet Warp: finish and promote N-Point Deformation | Edit > Puppet Warp | 1.5 | 2.5 | M | 1.9 | Upstream core |
| 14 | Oil Paint (PS-style, with bristle lighting) | Filter > Stylize > Oil Paint | 1.5 | 2 | M | 1.5 | GEGL op |
| 15 | Path Blur and elliptical Spin Blur (patent caution) | Blur Gallery | 2 | 1.5 | M | 1.5 | GEGL op + plug-in (path input) |
| 16 | Physically based lens flare | Knoll Light Factory (discontinued), Optics | 1.5 | 2 | M | 1.5 | GEGL op |
| 17 | Liquify parity (freeze mask, pucker/bloat presets, face-aware) | Filter > Liquify | 1.5 | 3 | L | 1.5 | Upstream core (warp tool) |

(Section 1 details below; section 2 is "checked and already covered"; section 3 lists the core-only gaps; section 4 lists what was rejected and why.)

## 1a. Candidate details

### 1. Color Lookup: a native 3D LUT op
- **What Photoshop does:** the Color Lookup adjustment layer applies a `.cube`, `.3dl` or `.look` LUT, or an abstract/device-link ICC profile, as an editable adjustment with opacity and blend mode. It is the standard way film looks, video grades and preset packs are sold (the whole "LUT pack" market targets it).
- **Popularity:** high. It is the common currency between Photoshop, Lightroom (profiles), Premiere/Resolve and phone apps; pixls.us has a long-running "GIMP - How to apply 3D LUT?" thread (2016-06) and about 47 topics match "gimp .cube" (pixls.us search, 2026-09-27). Qualitative, no hard numbers.
- **What GIMP 3.2 has:** nothing native. No LUT op in GEGL master or the 3.2.6 Flatpak; no `.cube`/`.3dl`/Hald handling anywhere in GIMP 3.2.6 `app/` or `plug-ins/` (grep); GIMP issue #15505 lists Color Lookup as having no GEGL equivalent. GitHub repository search for a GIMP LUT plug-in ("gimp lut", "gimp cube", "gimp clut", "gimp color lookup", "gimp3 lut") found nothing. G'MIC "Colors > Apply External CLUT" (`fx_apply_haldclut`, updated 2025-05-28) loads `.cube` via `input_cube` or a HaldCLUT PNG: it works, but it is destructive, lives in the G'MIC dialog, and has no blend or opacity beyond "Strength".
- **Real gap:** no non-destructive, reusable, scriptable LUT filter; no PSD `clrL` import target.
- **Open method:** trivial and patent-free (trilinear or tetrahedral 3D interpolation). Reference parsers: FFmpeg `libavfilter/vf_lut3d.c` (LGPL-2.1+, © Clément Bœsch 2013, Paul B Mahol 2018; parses `.cube`, `.3dl`, `.dat`, `.m3d`, `.csp`, plus 1D LUTs and Hald). LGPL-2.1+ code can go into GEGL (LGPL-3+).
- **Effort/form:** small. `gegl:lut3d` with a `path` property (GEGL ops already take file paths, e.g. `gegl:load`), interpolation choice, input/output space choice (the LUT's expected encoding: sRGB-gamma, linear, log), strength. Then a tiny upstream PSD MR to map `clrL`. Upstreamable; strongest ratio in this sweep.

### 2. Selective Color (Photoshop-compatible)
- **What Photoshop does:** adjusts cyan/magenta/yellow/black amounts inside nine colour families (reds, yellows, greens, cyans, blues, magentas, whites, neutrals, blacks), relative or absolute. A retouching and colour-grading staple, also exposed in Camera Raw-style workflows by many tutorials.
- **Popularity:** high among retouchers (qualitative). Upstream demand is concrete: GIMP #15505 and MR !2598 both list it as the blocker for PSD `selc` import.
- **What GIMP 3.2 has:** Hue-Saturation with six hue ranges (hue/lightness/saturation only, no CMY-style shifts and no whites/neutrals/blacks families). GEGL workshop `selective-hue-saturation` (Elle Stone 2017, LGPL-3+, not built). G'MIC "Select-Replace Color" and "Selective Desaturation" do different jobs.
- **Real gap:** full; the Photoshop behaviour cannot be reproduced in GIMP.
- **Open method:** the algorithm was reverse engineered and published by Clément Bœsch ([blog.pkh.me, "Understanding selective coloring in Adobe Photoshop"](http://blog.pkh.me/p/22-understanding-selective-coloring-in-adobe-photoshop.html)) and implemented in FFmpeg `libavfilter/vf_selectivecolor.c` (LGPL-2.1+, © 2015-2016 Clément Bœsch; it even reads Photoshop `.asv` preset files). A second independent implementation is Graphite's `selective_color` node (`node-graph/nodes/raster/src/adjustments.rs`, Apache-2.0, which is compatible with (L)GPL-3). No patent found (section 5).
- **Effort/form:** small. Single-input GEGL op with 9 x 4 properties plus method; can load `.asv`. Upstream both the op and the PSD mapping.

### 3. Hue-weighted Black & White with tint
- **What Photoshop does:** the Black & White adjustment weights six hue families (reds, yellows, greens, cyans, blues, magentas) rather than RGB channels, then optionally tints. It is also the core of Silver Efex's "colour filter" controls.
- **Popularity:** high (qualitative; it is the default B&W route in Photoshop tutorials). Silver Efex is part of the #1 plug-in family on [PetaPixel's list](https://petapixel.com/best-plugins-photoshop-lightroom/).
- **What GIMP 3.2 has:** `gegl:mono-mixer` (RGB weights), `gimp:desaturate` modes, `gegl:c2g`. G'MIC "Black & White" uses red/green/blue levels only (checked in `gmic_stdlib.gmic`). MR !2598 approximates PSD `blwh` with existing ops.
- **Real gap:** real but narrower than 1 and 2: channel mixing gets close for many images, but hue-selective control (darkening only a blue sky, lifting only skin) needs this.
- **Open method:** the formula is in Graphite's `black_and_white` node (Apache-2.0, cites the Adobe PSD spec for `blwh`); a hue-interpolated weight is textbook. No patent found (section 5).
- **Effort/form:** small. GEGL op, NDE, with Photoshop's presets; pair with a PSD `blwh` mapping.

### 4. Blend If ("This Layer" split sliders)
- **What Photoshop does:** Blending Options > Blend If hides pixels of the current layer by their own (or the underlying layer's) gray or per-channel value, with split (feathered) sliders. Classic for sky blends, luminosity-based compositing, texture overlays.
- **Popularity:** medium to high among photo compositors (qualitative); GIMP issue [#6369](https://gitlab.gnome.org/GNOME/gimp/-/work_items/6369) "Blend If Threshold Option" is open (2 votes).
- **What GIMP 3.2 has:** layer masks you build by hand; `gimp:threshold-alpha` and Color to Alpha are not the same. No op found in GEGL or G'MIC's layer blending that does split-slider tonal alpha on the layer itself.
- **Real gap:** full for the "This Layer" half. The "Underlying Layer" half needs the composite below, which a GIMP filter cannot see (filters get only their drawable; aux inputs are forced destructive).
- **Open method:** trivial (smoothstep on luminance or a channel into alpha). No patent concern known.
- **Effort/form:** small GEGL op, NDE. For "Underlying", document a workaround (put the layer in a group with a copy of the underlying content) rather than an aux pad.

### 5. Luminosity, zone and saturation masks
- **What the Photoshop panels do:** [TK9](https://goodlight.us/writing/tk9/tk9.html) (Tony Kuyper, v4 May 2026), [Lumenzia](https://gregbenzphotography.com/lumenzia) ($39.99, v11.7) and [Raya Pro](https://www.shutterevolve.com/raya-pro-the-ultimate-digital-blending-workflow-panel-for-photoshop/) (vendor claim "over 25,000 photographers") generate Lights/Darks/Midtones masks (1 to 5 levels), zone masks, colour and saturation masks, then apply them as selections, layer masks or adjustment masks.
- **What GIMP 3.2 has:** G'MIC "Tones to Layers" and "Slice Luminosity" (destructive layers), community "Masques B&W Masks". Old GIMP 2 scripts (Patrick David, saulgoode) are dead with the compat removal. GIMP 3 attempts found: fguilleme/gimp-plugins `luminosity-masks` (GIMP 2.99, 2022, 1 star, no licence), tins11/gimp-luminosity-masks (MIT, 2022, GimpFu, i.e. GIMP 2). A pixls.us thread "Interactive luminosity masks for GIMP 3" (2025-09) exists; its plug-in, licence and state are **UNVERIFIED** (pixls.us rate-limited the check).
- **Real gap:** partial. The key GIMP 3.2 enabler is new: NDE filters on channels mean a mask channel can be a live Curves/Levels filter over a luminance channel instead of a baked copy.
- **Open method:** trivial arithmetic, no patents.
- **Effort/form:** small Python plug-in: creates named channels (L1 to L5, D1 to D5, M1 to M5, zones, saturation, colour range) from the visible composite or a chosen layer, optionally as editable NDE filter stacks, plus "to selection / to layer mask" actions. Check the pixls.us plug-in first and contribute if it is good.

### 6. Camera Raw "presence" set: Clarity, Texture, Dehaze, Whites/Blacks
- **What Photoshop does:** Filter > Camera Raw Filter applies the Lightroom develop engine to a layer as a smart filter. The pieces with no GIMP equivalent are Texture (fine local contrast), Clarity (mid-scale local contrast), Dehaze, and Whites/Blacks (end-point tone controls).
- **Popularity:** very high; Camera Raw Filter is one of the most used filters in Photoshop photo work (qualitative). "gimp clarity" and "gimp dehaze" each return about 50 pixls.us topics.
- **What GIMP 3.2 has:** Shadows-Highlights, Retinex, Unsharp Mask with large radius, Fattal/Mantiuk/Reinhard/Stress, Vibrance (new), Levels/Curves. G'MIC: "Local Contrast" (afre), "Local Contrast Enhancement" (Arto Huotari), "DCP Dehaze" (Jérôme Boulanger, Details), "Simple Dehaze" (Testing), "Details Equalizer". The raw loaders (darktable, RawTherapee, ART) only work on raw files, not layers.
- **Real gap:** no NDE clarity/texture/dehaze op with halo-free edge-aware decomposition; the G'MIC ones are destructive.
- **Open methods:** local Laplacian filters (Paris, Hasinoff, Kautz 2011) and fast local Laplacian (Aubry et al. 2014); guided filter (He et al. 2010); dark channel prior dehaze (He, Sun, Tang 2009). darktable implements local Laplacian (`src/common/locallaplacian.c`, GPL-3+) and haze removal (`src/iop/hazeremoval.c`, GPL-3+); GPL-3 code fits GEGL's `operations/common-gpl3+` directory or an out-of-tree op. GEGL already ships edge-preserving building blocks (`gegl:domain-transform`, `gegl:bilateral-filter`, `gegl:mean-curvature-blur`; all in the 3.2.6 Flatpak list). Patents: no patent found for local Laplacian; dark channel prior dehaze is Microsoft US 8,340,461 (about 2031-06 if fees were paid), so dehaze is **caution** (section 5).
- **Effort/form:** medium. Three GEGL ops (`clarity` with scale and amount, `texture`, `dehaze`), maybe one `develop` meta-op bundling them with whites/blacks. All single-input, so full NDE.

### 7. Control points (U-Point style local adjustments)
- **What it is:** Nik Viveza (and control points in Color Efex, Silver Efex, Analog Efex) lets you drop points on the image; each point adjusts brightness, contrast, saturation, warmth and structure in a region defined by distance plus colour/texture similarity to the pixel under the point. DxO still sells it (Nik Collection 8, $169.99; v8 added polygon masks: [Digital Camera World review](https://www.digitalcameraworld.com/tech/software/dxo-nik-collection-8-review)).
- **Popularity:** Nik is #1 on [PetaPixel's best plug-ins list](https://petapixel.com/best-plugins-photoshop-lightroom/) (updated 2026-01-05); more than 15,000 signed a petition to keep Nik alive ([Thomas Fitzgerald](https://blog.thomasfitzgeraldphotography.com/blog/2023/8/dxo-releases-nik-collection-63)). Control points are Nik's signature feature.
- **What GIMP 3.2 has:** nothing equivalent. Nik itself can be called through nikGimp (Windows, closed freeware). darktable's parametric plus drawn masks are the nearest open tool; no GIMP or G'MIC filter does point-seeded colour-similarity masks.
- **Real gap:** full.
- **Open method:** a weighted mask per point, w = spatial falloff(d / r) x colour similarity (distance in a perceptual space to the seed colour) x optional texture term, then the adjustment blended by w, is standard image processing. Patents: the Nik U Point family (US 6,728,421, 7,031,547 and continuations) all chain to a 2002-10-24 filing and **expired 2022-10-24** (section 5).
- **Effort/form:** medium. A GEGL op with a fixed number of point slots (say 8, each x, y, radius, and adjustments) gives full NDE; a Python plug-in front end reads the points from a GIMP path's anchors (plug-ins cannot draw on-canvas handles, section 0 item 4) and writes them into the NDE filter.

### 8. Sky Replacement
- **What Photoshop does:** Edit > Sky Replacement (Photoshop 2021; release date not checked) auto-masks the sky with an Adobe Sensei model, drops in a sky, refines the edge, and relights the foreground to match. Luminar's sky replacement made the feature popular.
- **Popularity:** high in landscape and real-estate photography (qualitative); about 24 pixls.us topics on "gimp sky replacement", e.g. "Replacing a sky with gimp" (2022-07).
- **What GIMP 3.2 has:** manual workflow (Fuzzy/Foreground Select, `gegl:matting-levin` and `gegl:matting-global` are shipped, layer masks). AI segmentation plug-ins for GIMP 3: [pierspad/GIMPSAM](https://github.com/pierspad/GIMPSAM) (AGPL-3.0, 2026-08), [bunnywaffle/gimp-sam-select](https://github.com/bunnywaffle/gimp-sam-select) (MIT, 2026-09), [intel/openvino-ai-plugins-gimp](https://github.com/intel/openvino-ai-plugins-gimp) (Apache-2.0, v3.3.0 2026-06-23, includes semantic segmentation). None does the replace plus colour-harmonise step.
- **Real gap:** the one-click workflow: sky mask, edge refinement (colour decontamination around foliage), foreground colour/tone match to the new sky.
- **Open method:** classical sky mask from a seeded region (top border) plus gradient/colour statistics, refined by guided filter or Levin matting (both in GEGL); colour harmonisation by Reinhard 2001 or MKL statistics transfer (not Pitié IDT, which is patented to about 2029; section 5). GrabCut and Levin matting patents expired in 2026. Optional small segmentation model (licences in section 5).
- **Effort/form:** medium Python plug-in orchestrating GEGL ops (mask is destructive-by-necessity because it needs the sky layer as a second image; section 0 item 3).

### 9. Photomerge, Auto-Align Layers, Auto-Blend Layers
- **What Photoshop does:** Photomerge stitches panoramas (auto, perspective, cylindrical, spherical); Auto-Align Layers registers brackets or stacks; Auto-Blend Layers does seamless panorama blending or focus stacking.
- **Popularity:** high (qualitative); about 50 pixls.us topics on "gimp focus stacking", "Stitching photos together: panoramas, HDR, focus stacking" (2023-03).
- **What GIMP 3.2 has:** no automatic stitching; Pandora (manual arrangement) ported; alignment via G'MIC Align Layers and gimp-image-reg v3.0.0; exposure fusion and focus stacking are candidates.md item 6.
- **Real gap:** stitching and one-dialog "align these layers, then blend" inside GIMP.
- **Open method:** Hugin's command-line chain (`pto_gen`, `cpfind`, `autooptimiser`, `pano_modify`, `nona`, `enblend`/`enfuse`, `align_image_stack`). Hugin is GPL-2+ (Hugin 2025.0.1, see candidates.md section 2). SIFT's patent (US 6,711,293, UBC) expired 2020-03-06; avoid SURF (section 5).
- **Effort/form:** medium Python plug-in: export selected layers to temp TIFF (float), run Hugin tools, load the result as layers (aligned) or one layer (stitched/blended). Pairs naturally with the candidates.md item 6 GEGL fusion op. Flatpak note: the plug-in would have to call Hugin on the host (`flatpak-spawn --host`) or bundle it; check before promising Flatpak support.

### 10. Skin retouch (Portraiture-style)
- **What it is:** [Imagenomic Portraiture](https://www.imagenomic.com/Pricing) ($249.95) auto-detects skin tones, then smooths by frequency band while keeping pores and edges. Retouch4me Heal and Dodge&Burn ([pricing](https://retouch4.me/pricing)), Beauty Retouch (vendor claim 20,100+ users), Delicious Retouch DR5, Ultimate Retouch Panel all serve the same job.
- **Popularity:** Portraiture #4 and Retouch4me #5 on PetaPixel's list.
- **What GIMP 3.2 has:** G'MIC "Smooth [Skin]" (stdlib), community "Easy Skin Retouch" (Testing), "Portrait Retouching" (Tom Keil, Details), "Skin Mask" (Testing), "Make Up" (Iain Fergusson); GIMP's wavelet-decompose plug-in and Grain Extract/Merge for manual frequency separation. Beautify (hejiann) is blocked on licence (candidates.md). A new GIMP 3 plug-in [AiZViberCoder/gimp-auto-dodge-burn](https://github.com/AiZViberCoder/gimp-auto-dodge-burn) (2026-09-22, 0 stars, MediaPipe + BiSeNet, licence file present but GitHub reports NOASSERTION: **UNVERIFIED**) does AI dodge and burn.
- **Real gap:** partial: no NDE, one-slider skin smoother with an automatic skin-tone mask and band controls. G'MIC covers it destructively.
- **Open method:** skin-likelihood in YCbCr or a Gaussian skin model plus edge-aware band-pass smoothing (bilateral, guided or wavelet bands; our Wavelet Denoise code is directly reusable). No specific patent search was done for skin smoothing (**UNVERIFIED**).
- **Effort/form:** medium; GEGL op (`skin-smooth`: skin-tone mask, smoothing per wavelet band, detail restore), plus a `skin-mask` op usable on channels.

### 11. Astro toolkit
- **What the Photoshop tools do:** [Astronomy Tools actions](https://www.prodigitalsoftware.com/AstronomyToolsActions.html) (Noel Carboni, v1.6.2, $21.95, 34 actions) include Light Pollution Removal, Make Stars Smaller, Space and Deep Space Noise Reduction, Increase Star Color, gradient removal, banding reduction, blue halo reduction, star spikes. [RC Astro](https://www.rc-astro.com/) sells StarXTerminator, NoiseXTerminator, GradientXTerminator (Photoshop-only) and StarShrink.
- **What exists openly:** Siril (GPL-3.0, v1.4.4 2026-06-17) and GraXpert (GPL-3.0, background extraction) handle stacking and gradients before GIMP. StarNet (nekitmm/starnet code MIT; weights licence **UNVERIFIED**). In GIMP: Georg Hennig's gimp-plugin-astronomy (GPL-2+ per `src/star_rounding.c`, © 2006-2018; alignment, merge, background gradient, star rounding, artificial stars) is GIMP 2 only (uses `gimp_pixel_rgn_*`; gimp-plugins-justice fork last push 2023-10-21). Not in candidates.md.
- **Real gap:** in-GIMP finishing steps: star mask, star shrink (morphological min under a star mask), gradient/light-pollution removal from sampled background points (polynomial or RBF surface fit), star colour boost, banding removal.
- **Open method:** all classical and patent-free (morphology, surface fitting).
- **Effort/form:** small to medium. A few GEGL ops (`star-mask`, `star-reduce`, `background-fit` from sample points passed as properties) plus a plug-in; port Hennig's C where useful.

### 12. Shake Reduction (blind motion deblur)
- **What Photoshop does:** Filter > Sharpen > Shake Reduction estimates a non-linear camera-shake blur kernel from the image (optionally from user-chosen regions) and deconvolves. Whether it is still present in current Photoshop is **UNVERIFIED** (Adobe's help pages returned 403).
- **Popularity:** medium (qualitative); it was a headline CC feature.
- **What GIMP 3.2 has:** nothing blind. G'MIC "Sharpen [Richardson-Lucy]", "Sharpen [Deblur]", "Sharpen [Gold-Meinel]", community "Deconvolve" (known PSF), "Deblur Texture" (Testing). GEGL MR !288 (open) adds Wiener deconvolution with known PSF, including linear motion.
- **Real gap:** kernel estimation.
- **Open method:** Fergus et al. 2006, Shan, Jia, Agarwala 2008, Xu and Jia 2010, Krishnan, Tay, Fergus 2011 (normalised sparsity), Pan et al. 2014 (L0). Patents: Fergus/MIT US 7,616,826 (about 2027-12), Microsoft US 8,139,886 (about 2030-11) and several Adobe deblur patents (about 2033 to 2034) are active if maintained; no patent found for Krishnan 2011 or Pan 2014 (section 5). **Caution.**
- **Effort/form:** large. GEGL op that estimates a kernel on a region then hands it to MR !288's Wiener op; best as a contribution on top of !288 rather than a separate stack.

### 13. Puppet Warp: finish N-Point Deformation
- **What Photoshop does:** Edit > Puppet Warp places pins on a mesh and deforms as-rigid-as-possible.
- **What GIMP 3.2 has:** Cage Transform (shipped) and the N-Point Deformation tool (`gegl:npd`, ARAP-based), which in 3.2.6 is still behind the Playground flag (`playground-npd-tool` in `app/config/gimpguiconfig.c`). Mesh transform request [#8017](https://gitlab.gnome.org/GNOME/gimp/-/work_items/8017) is open (3 votes).
- **Real gap:** a supported, non-hidden puppet tool. The algorithm is already in GEGL.
- **Open method:** Igarashi, Moscovich, Hughes 2005 ARAP; GEGL `npd` code already exists. Patents: no Adobe Puppet Warp patent found (section 5).
- **Effort/form:** medium, upstream C (fix NPD bugs, UX, NDE via a transform filter). Not a plug-in.

### 14. Oil Paint
- **What Photoshop does:** Filter > Stylize > Oil Paint (stylization, cleanliness, scale, bristle detail, lighting angle, shine).
- **What GIMP 3.2 has:** `gegl:oilify` (mode filter), Van Gogh LIC plug-in, GIMPressionist, `gegl:cartoon`, G'MIC "Painting", "Lylejk's Painting", "Vector Painting", "Morphology Painting", plus LinuxBeaver ops.
- **Real gap:** narrow: the flow-aligned strokes with embossed bristle lighting look is not a single NDE op.
- **Open method:** anisotropic Kuwahara (Kyprianidis et al. 2009) or structure-tensor flow + line integral convolution, then a bump/emboss light pass (`gegl:bump-map` exists). No patent found (section 5).
- **Effort/form:** medium GEGL meta-op.

### 15. Path Blur and elliptical Spin Blur
- **What Photoshop does:** Blur Gallery has Field, Iris, Tilt-Shift, Path and Spin blur with on-canvas handles.
- **What GIMP 3.2 has:** `gegl:focus-blur` covers Iris and Tilt-Shift (shapes circle, square, diamond, horizontal, vertical; Gaussian or Lens type; aspect ratio, rotation, midpoint, on-canvas focus widget). Field blur is `gegl:variable-blur` with a gradient mask. Spin blur is `gegl:motion-blur-circular` (centre and angle, circular only). No path blur.
- **Real gap:** Path Blur (blur along user curves with speed/taper) and elliptical, strobed Spin Blur.
- **Open method:** motion blur along a vector field built from path tangents (line integral convolution); ellipse by coordinate scaling before circular blur. Patents: Adobe holds path-blur patents (US 9,723,204, 9,779,484, 9,955,065, about 2034 to 2035 if maintained), so **caution**; design from classic LIC motion blur, not Adobe's kernel or UI (section 5).
- **Effort/form:** medium; GEGL op taking a flow field or a path (GEGL has `GeglPath` properties, see `gegl:path`, `gegl:vector-stroke`), plus a plug-in that passes the active GIMP path.

### 16. Physically based lens flare
- **What it is:** Knoll Light Factory was discontinued in March 2023 (Maxon support article "Knoll Light Factory Deprecation", fetched via search snippet only: **UNVERIFIED** in detail), replaced by Real Lens Flares; Boris FX Optics (#8 on PetaPixel) and Rosenman's Ultraflares are the paid options.
- **What GIMP 3.2 has:** `gegl:lens-flare`, `gegl:supernova`, Gradient Flare plug-in (editable presets), G'MIC "Light Glow", "Light Rays", "Guided Light Rays", "Light Leaks".
- **Real gap:** narrow: multi-element ghosts along the optical axis, anamorphic streaks, flare from detected highlights.
- **Effort/form:** medium GEGL op. Popularity too uncertain to rank higher.

### 17. Liquify parity
- **What Photoshop does:** Liquify: forward warp, reconstruct, smooth, twirl, pucker, bloat, push left, freeze/thaw mask, Face-Aware Liquify (face landmark sliders), save/load mesh.
- **What GIMP 3.2 has:** Warp Transform tool with Move, Grow, Shrink, Swirl CW/CCW, Erase (reconstruct), Smooth, animation frames (`app/tools/tools-enums.h`). The selection clips the effect area; no freeze brush, no face sliders, no mesh save.
- **Real gap:** partial. Face-aware needs landmarks (MediaPipe Face Mesh, Apache-2.0: **UNVERIFIED** for weights).
- **Effort/form:** large, upstream core only (section 0 item 4).


## 2. Checked and already covered (or covered well enough)

| Photoshop feature or plug-in | What covers it in GIMP 3.2 (verified) |
|---|---|
| Adjustment layers | NDE filters on layers, groups and channels, plus pass-through groups ([3.2 release notes](https://www.gimp.org/release-notes/gimp-3.2.html)). PSD adjustment import in progress upstream (!2563 merged, !2975 Curves merged, !2598 draft). |
| Linked Smart Objects | 3.2 Link Layers (live-updating external files). Embedded Smart Objects and NDE raster transforms are not covered (core work). |
| Layer Styles | Being ported now (layerfx); GEGL `styles`, `bevel`, `inner-glow`, `dropshadow`, `long-shadow` shipped; GSoC work on PSD-compatible Inner Glow (GEGL !275) and Bevel (#16339). Coordinate. |
| Content-Aware Fill, Content-Aware Move/Patch, Remove tool (non-AI part) | Resynthesizer 3.0.1 (Flathub branch 3): heal selection, heal transparency, uncrop, enlarge, render texture (candidates.md section 3). G'MIC "Inpaint [Patch-Based]", "[Multi-Scale]", "[Transport-Diffusion]". Core "native heal selection" request [#4762](https://gitlab.gnome.org/GNOME/gimp/-/work_items/4762) is closed (16 votes, the highest-voted Photoshop-parity issue seen). |
| Content-Aware Scale | Our Liquid Rescale port and LQR TNG. |
| Lens Correction, Camera Raw lens profiles | Our gimp-lensfun (`lensfun:correct` in the local op list). |
| Lens Blur (depth map) | `gegl:lens-blur` and `gegl:focus-blur` in GIMP; our Depth Blur (`depth:blur`). |
| Iris, Tilt-Shift, Field blur | `gegl:focus-blur` shapes and on-canvas widget; `gegl:variable-blur` with a mask. (Path and elliptical Spin are candidate 15.) |
| HDR Toning (tone mapping) | Native Fattal 2002, Mantiuk 2006, Reinhard 2005, Stress, Retinex, Shadows-Highlights. Merge and fusion are candidates.md item 6. |
| Frequency separation actions | Built-in Wavelet-decompose plug-in (in the Flatpak plug-in list), Grain Extract/Merge modes; G'MIC "Split Details [Gaussian]" and "[Wavelets]"; pixls.us threads "Updated frequency separation plugin for GIMP 3" (2025-09) and "Frequency separation plug-in: demo and tutorial" (2025-04) exist (plug-in details **UNVERIFIED**, rate-limited). Retouch4me now gives its FS plug-in away free ([pricing](https://retouch4.me/pricing)), a sign the feature is commoditised. |
| Dodge/Burn with tonal range | Dodge/Burn tool with Shadows/Midtones/Highlights (`GimpTransferMode`, default Midtones in `app/paint/gimpdodgeburnoptions.c`). |
| Symmetry painting | Mirror, Tiling, Mandala symmetry (`app/core/gimpsymmetry-*.c`). |
| Vibrance | New `gegl:vibrance` in 3.2 (GEGL !244 added PSD compatibility). |
| Replace Color | Color Exchange, Rotate Colors, Hue-Saturation per range; G'MIC "Select-Replace Color". |
| Match Color | G'MIC "Transfer Colors [Multi]" (stdlib), "[Histogram]", "[PCA]", "[Patch-Based]", "[Curves]"; destructive because it needs a reference image (section 0 item 3). A GEGL op would still be forced destructive, so little to gain until #11904 is fixed. |
| Gradient Map | Built-in Gradient Map plug-in (destructive); GEGL workshop `gradient-map` (not built) and LinuxBeaver's `port:gradient-map` (installed here as `gradient-map-port.so`) give an NDE version. The remaining work is upstream promotion of the workshop op for PSD import, which is small and worth an MR but is not a new filter. |
| Photo Filter, Exposure | `gegl:color-temperature`, `gegl:exposure`, colour overlay modes; PSD import mapping drafted in !2598. |
| Select Subject, Object Selection | AI plug-ins for GIMP 3: GIMPSAM (AGPL-3.0), gimp-sam-select (MIT), OpenVINO AI plug-ins (Apache-2.0, v3.3.0). Classical: Foreground Select (Levin matting), Paint Select (Playground, see section 3). |
| Neural Filters, Generative Fill, Super Zoom | OpenVINO AI plug-ins (Stable Diffusion, super-resolution, segmentation); Nenotriple/gimp_upscale (MIT, 144 stars, Real-ESRGAN ncnn, GIMP 2.10 and 3.0). Topaz Gigapixel-class upscaling: Real-ESRGAN (BSD-3-Clause), Upscayl (AGPL-3.0) outside GIMP. |
| Nik Collection (as a product) | nikGimp bridge (GPL-3.0, GIMP 3, Windows). Colour Efex/Analog Efex looks: G'MIC "Simulate Film" and CLUT sets; Dfine: GEGL noise-reduction, our Wavelet Denoise, G'MIC; Sharpener: unsharp, our Wavelet Sharpen, new `gegl:sharpen` (!269). Missing parts are candidates 3 and 7. |
| Smart Sharpen | Unsharp Mask, `gegl:sharpen` (!269), our Wavelet Sharpen, G'MIC sharpeners; known-PSF deconvolution arriving in GEGL !288. Blind part is candidate 12. |
| Vanishing Point (partly) | Perspective Clone tool and 3D Transform. Multi-plane grids and perspective paste onto planes are not covered; no GIMP issue asking for them was found. |
| Perspective Warp (single quad) | Handle Transform, Perspective, Unified and 3D Transform tools. Multi-quad content-preserving warp is not covered (section 4). |
| Fontself | Out of scope for GIMP; FontForge (GPL-3.0+) is the open tool. |
| PixelSquid | Discontinued by Shutterstock (about 2025-11); nothing to replace. |
| Knoll Light Factory (as a product) | Discontinued by Maxon in 2023; flare needs covered by existing ops except candidate 16. |

## 3. Real gaps that only GIMP core can close (not plug-in or GEGL work)

These are listed so the ranking above is honest about what a plug-in cannot do (section 0 item 4). Each would be an upstream C contribution.

- **Quick Selection brush.** GIMP issue [#2912](https://gitlab.gnome.org/GNOME/gimp/-/work_items/2912) "quick selection tool" is the most upvoted open GIMP issue in the first 300 by popularity (12 votes, checked via the GitLab API 2026-09-27). GIMP already has the Paint Select tool, but in 3.2.6 it is still behind the Playground flag (`playground-paint-select-tool`). Finishing and promoting it is the realistic path.
- **Spot Healing Brush** (brush-driven content-aware heal, no source point). Could use Resynthesizer's engine or GEGL workshop `alpha-inpaint` (Øyvind Kolås 2018-2019, LGPL-3+, not built). Related request [#6876](https://gitlab.gnome.org/GNOME/gimp/-/work_items/6876) "Heal selection from mask" is open (3 votes).
- **Liquify parity**: candidate 17.
- **Puppet Warp**: candidate 13 (promote N-Point Deformation).
- **Pattern Preview / wrap-around canvas** (paint across tile edges and see the repeat live). GIMP has Tiling symmetry for strokes and Tile Seamless, but no wrap-around view. A workaround plug-in using 3.2 link layers (a 3 x 3 image of link layers to the saved file) is possible but updates only on save.
- **Embedded Smart Objects and NDE transforms** of raster layers.

## 4. Considered and not ranked

- **PSPI (8bf host) for GIMP 3:** would reopen the Photoshop filter catalogue, but only on Windows, only for plug-ins that still ship 64-bit 8bf, and the host API is large. Reference: PSFilterPdn (MIT, maintained). Large effort, one platform; left out of the ranking.
- **Adaptive Wide Angle and multi-quad Perspective Warp:** content-preserving projection optimisation (Carroll, Agrawala, Agarwala 2009). Large effort, niche; patents in section 5.
- **Filter Forge / node filter editor:** Filter Forge 15.0 (2025-12-08, 14,173 filters, [filterforge.com](https://www.filterforge.com/)) is alive. A visual GEGL graph editor would be a large standalone project; `gegl:gegl` already takes a graph string. Related to candidates.md item 16 (User Filter) and 20 (MathMap).
- **Infinite Color panel:** a randomised grading preset generator ([infinitecolorpanel.com](https://infinitecolorpanel.com/collections/products), $129, 21 reviews). Becomes a small plug-in once candidates 1 and 2 exist (random LUT or selective-colour settings); not worth ranking alone.
- **Retouch4me, Topaz, PortraitPro, Luminar AI features:** AI models trained on proprietary data; no open, classical equivalent with the same quality. Covered as far as practical by the AI plug-ins in section 2.
- **Flaming Pear (Flood, LunarCell):** still sold ([flamingpear.com](https://www.flamingpear.com/)); `gegl:reflect`, planet render scripts (candidates.md registry list) and G'MIC cover the ideas; low demand evidence.


## 5. Patents and licences

Method: Google Patents, Justia and Espacenet all blocked automated requests. The patent data comes from freepatentsonline.com searches plus the official USPTO front-page PDFs, which were OCR'd to read term adjustment (PTA) days and parent chains.

Expiry here means 20 years from the earliest US non-provisional filing, plus PTA. **Maintenance-fee status was not checked for any patent.** "Active" therefore means "in force if the fees were paid", and a lapsed fee would make any of them expire earlier. Claims were not analysed in legal depth. The "none found" rows come from keyword searches, so the absence of a patent is **UNVERIFIED**.

| Technique (candidate) | Patents found | Status (computed) | Verdict |
|---|---|---|---|
| 3D LUT (1), Selective Color (2) | None found for either | n/a | Safe. `.cube` is an open format. The Selective Color formulas are published by Bœsch; FFmpeg is LGPL-2.1+ and prod80's ReShade shader is MIT. |
| Hue-weighted B&W (3), Blend If (4), luminosity masks (5) | Shinyfields US 11,089,234 and US 11,750,935 use "luminosity mask" in claims about a specific pseudo-HDR EV-bracket pipeline | Active (about 2038 or later) | Safe. Just do not build Shinyfields' single-image EV-bracket pipeline. |
| U-Point control points (7) | Nik Software US 6,728,421 family (US 7,031,547, 7,602,991, 8,064,725, 7,970,233, 7,602,968), all chained to a 2002-10-24 filing with PTA 0 | **Expired 2022-10-24** | Safe |
| Clarity, Texture: local Laplacian (6) | None found | n/a | Safe. darktable `locallaplacian.c` is GPL-3+ and Halide's local Laplacian app is MIT. |
| Dehaze, dark channel prior (6) | Microsoft US 8,340,461 (filed 2010-02-01, PTA 507); Adobe US 9,508,126 (filed 2015-02-17) and US 9,305,339 | US 8,340,461 about 2031-06-23 if fees paid; US 9,508,126 about 2035 | **Caution.** Check the fee status of US 8,340,461 first. Otherwise ship Clarity and Texture first and choose a dehaze method outside the dark-channel claims. |
| Sky mask (8): GrabCut, Levin matting | Microsoft GrabCut US 7,660,463; Yissum Levin matting US 7,692,664 | **Expired** 2026-03-10 and 2026-07-17 | Safe |
| Colour harmonisation (8), Match Color | Pitié and Kokaram US 7,796,812 claims iterative 1D-PDF transfer (IDT); no patent found for Reinhard or MKL | US 7,796,812 about 2029-06-23 if fees paid | Use Reinhard or MKL. **Do not use IDT** until about 2029. |
| Segmentation weights (8) | Licences checked: SAM, SAM2 and MODNet are Apache-2.0; BiRefNet is MIT; U2-Net code is Apache-2.0 (weights unstated); RMBG-1.4 is non-commercial and RMBG-2.0 is gated | n/a | SAM, BiRefNet and MODNet are usable. Avoid RMBG. |
| Stitching features (9) | SIFT US 6,711,293 (UBC); SURF US 8,165,401 | SIFT **expired 2020-03-06**. SURF about 2029-04 if fees paid. | Use SIFT or ORB (Hugin's `cpfind` default), not SURF. Hugin and libpano13 are GPL-2+. |
| Skin smoothing (10) | None specifically searched beyond frequency separation (none found) | **UNVERIFIED** | Probably safe (standard band-pass smoothing), not checked |
| Blind deconvolution (12) | Fergus/MIT US 7,616,826 (about 2027-12); Microsoft US 8,139,886 (about 2030-11); Adobe US 8,897,588, 9,076,205 and 9,208,543 (about 2033 to 2034) and more | Active if fees paid | **Caution.** Base it on Krishnan 2011 or Pan 2014 L0 (no patents found) and avoid variational-Bayes and edge-prediction claims. |
| Puppet Warp, ARAP (13) | No Adobe Puppet Warp patent found | n/a | Safe. GEGL `npd` is LGPL-3+ (© 2013 Marek Dvoroznak (as spelled in the header check)). |
| Oil Paint (14) | None found (Kuwahara, Kyprianidis, Hertzmann) | n/a | Safe |
| Path Blur (15) | Adobe US 9,723,204, 9,779,484 and 9,955,065 (path blur kernel and UI); US 8,831,371 (Blur Gallery patterns) | About 2032 to 2035 if fees paid | **Caution.** Design flow-field blur from classic LIC motion blur, and do not copy Adobe's path-blur kernel or UI mechanics. |
| Content-Aware Fill, PatchMatch (section 3) | Adobe PatchMatch US 8,407,575, 8,285,055 and 8,811,749; Generalized PatchMatch US 8,571,328; CAF US 8,818,135 and 10,706,509; Spot Healing US 9,202,299 | About 2029 to 2038 if fees paid | Caution for PatchMatch-based fill. Expired and therefore safe: Criminisi (US 6,987,520, about 2023-03), Adobe's original Healing Brush (US 6,587,592, 2021-11), Poisson editing (US 6,856,705, about 2023-04) and "healing in differential space" (US 7,558,433, 2026-07-29). Resynthesizer's best-fit synthesis is not PatchMatch. |
| Adaptive Wide Angle, Perspective Warp (section 4) | Adobe US 8,525,871 (about 2031-08); US 9,117,253 "Perspective warp" (about 2033-06) | Active if fees paid | Caution. This is one more reason they are not ranked. |

> Note (2026-09-27): settled by a later check
> (gegl-underwater/docs/patents-transmission.md): US 8,340,461 B2 expired
> for non-payment of the 7.5-year fee, lapse effective 2020-12-25 (Google
> Patents legal events). The dark channel prior is free; the Adobe dehaze
> patents above still need checking.


Licence notes for code to borrow:

| Source | Licence | Fit |
|---|---|---|
| FFmpeg `vf_lut3d.c`, `vf_selectivecolor.c` | LGPL-2.1+ | Fits GEGL (LGPL-3+) |
| Graphite `adjustments.rs` | Apache-2.0 | Compatible with (L)GPL-3 |
| darktable local Laplacian, haze removal | GPL-3+ | Fits GEGL's `common-gpl3+` or an out-of-tree op |
| hahnec/color-matcher | GPL-3.0 | Implements Reinhard, MKL, MVGD and histogram matching |
| Pitié's Matlab code | GPL-2.0 | Includes IDT, which is patented (see above) |
| G'MIC | CeCILL-C or CeCILL 2.1 | Usable as a reference |
| Hennig astronomy plug-ins | GPL-2+ | Fine to port |

## 6. Suggested order

1. **Colour ops batch, all small and upstreamable:** `lut3d` (1), `selective-color` (2), `black-and-white` (3) and `blend-if` (4).
   - Each is an NDE single-input op.
   - Send them to GEGL with matching PSD import MRs, coordinating with cmyk.student and Akascape on #15505 and !2598.
2. **Luminosity masks plug-in (5).** It exercises the 3.2 channel NDE filters.
3. **Clarity and Texture (6), then Dehaze** once the US 8,340,461 status is known.
4. **Control points (7).**
5. **The Hugin bridge (9),** shipped together with the candidates.md item 6 fusion op.
6. **Before starting candidates 12 and 17**, and before any more layerfx Inner Glow or Bevel work, coordinate with clodman84 (GEGL !288) and WarisMaqbool (GEGL !275, GIMP #16339).

## 7. Method notes

- **GEGL ops:** from the Flatpak (`gegl --list-all`, 472 ops including locally installed third-party ones).
- **GIMP menus, tools and Playground flags:** from the `GIMP_3_2_6` source.
- **G'MIC filters:** parsed from `gmic_stdlib.gmic` (master) and the 29 community files in GreycLab/gmic-community. That gave 1,228 GUI entries; community filters in the "Testing" category are noted as such.
- **GIMP and GEGL issues and MRs:** read through the gitlab.gnome.org API. Issue comments need auth and were not read.
- **Popularity:** PetaPixel's best-plugins list (updated 2026-01-05), vendor pages (vendor claims marked), pixls.us topic counts, and GitLab vote counts.
  - pixls.us rate-limited the later checks.
  - Adobe helpx returned 403, so Photoshop feature details come from general knowledge and are not version-checked.
  - The session's web-search budget ran out, so later checks used direct fetches and the GitHub API.
- **Earlier sweep:** one cross-check against candidates.md found that G'MIC now has a "Saturation EQ" filter (iain_fergusson.gmic, category Colors). candidates.md item 4 says there is no port; that should be re-checked, since it may be a reimplementation rather than a port.
