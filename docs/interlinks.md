# GIMP interlinks: GIMP and Blender texture painting, and other links

Research date 2026-09-27, on GIMP 3.2.6 (Flatpak org.gimp.GIMP), Blender
5.2.0 LTS, Krita 5.3.3, darktable 5.6.1 and Inkscape 1.4.4 (all Flatpak).
Results marked **[tested]** come from headless runs with throwaway
profiles (scripts in [interlink-tests/](interlink-tests/)). Anything not
confirmed from a primary source is marked **UNVERIFIED**. Web search ran
out early; Reddit, blender.stackexchange, Polycount and gimp-forum.net
could not be fetched, so painters' complaints come mostly from
BlenderArtists, the GIMP tracker, projects.blender.org and GitHub.

## Summary

Nothing maintained links GIMP (2.10 or 3.x) with Blender. Krita,
Aseprite, ZBrush and Photoshop all have bridges. GIMP 3.2 now has the
pieces to build one:

- a GIMP 3.2 **link layer** picked up a replaced PNG within a second and
  survives saving and reloading an XCF [tested];
- Blender's `Image.reload()` picks up an external change, even of bit
  depth [tested];
- Blender exports the UV layout as SVG headless (PNG export needs a GPU);
  GIMP imports it as paths and as a link layer [tested];
- 16-bit PNG and OpenEXR carry data correctly both ways [tested].

Traps:

- Blender cannot read XCF or ORA at all; it reads PSD only as the
  flattened composite and tags a 16-bit GIMP PSD as Linear Rec.709 although
  the data is sRGB-encoded (too bright); from a layered TIFF it showed only
  the base layer [tested];
- `Image.save_render` bakes the AgX view transform into the file; a
  bridge must use `Image.save()` [tested];
- with Flatpaks, Blender's Edit Externally and Quick Edit do not reach
  GIMP: the Image Editor preference takes one path and no arguments, there
  is no `gimp` in Blender's sandbox, `flatpak-spawn --host` needs a
  sandbox-weakening override, and Blender's `/tmp` is private [tested].
  What works across both sandboxes: a localhost TCP socket (both share the
  network) and a shared folder under `$HOME`;
- there is no darktable, rawtherapee, enfuse or inkscape inside GIMP's
  Flatpak, so opening raws through GIMP may not reach a separate darktable
  Flatpak (not confirmed).

Ranked recommendation (details in section 4):

1. GIMP Link for Blender: live texture round trip (medium to large)
2. GIMP UV Tools: island outlines, per-island masks, seam dilation,
   channel packing (small to medium)
3. Texture Set export from XCF layer groups (small)
4. ComfyUI bridge for GIMP 3, after krita-ai-diffusion (large)
5. darktable round trip that works with Flatpaks (small to medium)
6. Hugin and enfuse: exposure and focus stacking, cross-platform (medium)
7. "Edit source externally" for link layers (small)
8. A shared localhost control socket library for the others (small)

## 1. What exists for GIMP and Blender

### 1.1 Blender's built-in external editing

Source: `scripts/startup/bl_operators/image.py` in Blender 5.2 (read
locally); manual pages
https://docs.blender.org/manual/en/latest/editors/preferences/file_paths.html
and
https://docs.blender.org/manual/en/latest/sculpt_paint/texture_paint/tool_settings/options.html

- **Preferences > File Paths > Applications > Image Editor** is one
  executable path, passed to `subprocess.Popen` with the file; no argument
  field (the Text Editor has one). Empty, Linux falls back to `gimp` on
  PATH. Open request since 2018 for full command lines, "Edit Images
  Externally is unable to launch Gimp 2.10 flatpak":
  https://projects.blender.org/blender/blender/issues/56158
- **Image > Edit Externally** opens the image file in the editor; refuses
  packed or unsaved images; Blender does not watch the file afterwards
  (Image > Reload by hand). Blender has no file watcher: proposals #147309,
  #148795 and PR #147237 were closed by December 2025 without merging.
- **Texture Paint > Options > External: Quick Edit, Apply, Apply Camera
  Image.** Quick Edit renders the 3D view offscreen (8-bit, premultiplied
  alpha, view and projection matrices kept as `view_data`), saves it as
  PNG next to a saved .blend or in `bpy.app.tempdir`, and calls Edit
  Externally. Apply finds that image by a class variable (the source says
  "TODO, deal with this nicer"; lost on restart), reloads it and projects
  it back once. It needs a GPU context. Limits: 8-bit, one view, layers
  lost, symmetry ignored, and painting over the exported base darkens the
  result (https://blenderartists.org/t/issues-with-projecting-paint-quick-edit/552802,
  https://blenderartists.org/t/quick-edit-does-not-respect-texture-paint-symmetry-settings-when-applied/1528782).
- **With Flatpak GIMP on this machine it does not work** [tested]: no
  `gimp` in Blender's sandbox; `flatpak-spawn --host` is refused without
  `flatpak override --user --talk-name=org.freedesktop.Flatpak
  org.blender.Blender` (which lets Blender run anything on the host);
  Blender's `/tmp` is private (`filesystems=host` excludes `/tmp`), so
  Quick Edit on an unsaved .blend writes a file GIMP cannot see; with a
  saved .blend it lands under `$HOME`. `xdg-open` goes through the OpenURI
  portal; the default for PNG here is Loupe (app chooser UNVERIFIED).
- Across both sandboxes: both have `shared=network` (localhost TCP works)
  and `filesystems=host` (a folder under `$HOME` works). Blender has no
  session bus permission for `org.gimp.GIMP.UI`.

### 1.2 Add-ons and plug-ins (and the closest analogues)

No maintained add-on or plug-in links GIMP with Blender (extensions.blender.org
API, 1454 listings, nothing for "gimp" or "xcf"; GitHub code search empty).

| Project | What it does | Licence | Last activity | Versions |
|---|---|---|---|---|
| io_import_gimp_image_to_scene (old Blender contrib) | XCF layers as planes via xcftools | GPL-2.0+ | removed 2019 | Blender 2.7x |
| [Auto Reload](https://github.com/samytichadou/Auto_Reload_Blender_addon) | timer mtime poll plus `img.reload()` | GPL-3.0+ | 2025-05 | Blender 4.2+ |
| TextureWatch | reload textures on save | paid | 2018 | UNVERIFIED |
| [Blender Krita Link](https://github.com/heisenshark/blender-krita-link-plugin) | live pixels Krita and Blender: localhost connection plus shared memory, UV export | GPL-3.0 | 2026-09 | Blender 5.2, Krita 5.3/6 |
| [Blender Layer](https://github.com/Yuntokon/BlenderLayer) | Blender viewport as a Krita layer | GPL-3.0 | 2024-10 (fork for 5.2, 2026-08) | Krita 5.2 |
| [Pribambase](https://github.com/AlienPolygon/pribambase) / [Spritedash](https://github.com/Half-Baked-Park/spritedash) | Aseprite and Blender over a localhost WebSocket, with UV layout | GPL-3.0 | 2026-07 | Blender 5.x |
| [blender_psd](https://github.com/heinn-dev/blender_psd) | two-way Photoshop layer sync (JSX push, Windows only) | no licence file | 2026-08 | Blender 4.5/5.0 |
| [GoB](https://github.com/JoseConseco/GoB) | ZBrush bridge: shared folder and a timer polling a file's mtime | GPL-3.0+ | 2026-09 | Blender 4.2+ |
| [GIMP_Texture_plugin](https://github.com/aitwar90/GIMP_Texture_plugin) | normal, AO and metallic maps | MIT | 2026-07 | GIMP 3.2 |
| [Ucupaint](https://github.com/ucupumar/ucupaint) | layered painting inside Blender | GPL-3.0 | 2026-09 | Blender 4.2+ |

Krita has two live bridges and auto-updating file layers; GIMP has none,
but now has link layers.

### 1.3 Formats and APIs

Round trip GIMP 3.2.6 to Blender 5.2, a blue base plus a red Multiply
layer at 50 % [tested]:

| File from GIMP | Blender |
|---|---|
| PNG, 8-bit | 8-bit, composite right |
| PNG, 16-bit or float image | GIMP writes 16-bit PNG; Blender loads float, sRGB, composite right |
| OpenEXR | float, linear, exact, flattened |
| PSD, 16-bit | composite, but tagged linear although sRGB-encoded: too bright. Avoid |
| TIFF, layered | only the base layer. Flatten first |
| XCF, ORA | not read at all |

- Blender to GIMP [tested]: a 16-bit PNG loads as u16 non-linear, EXR as
  float linear (exact).
- `Image.save_render` bakes the view transform (linear 0.5 came out
  0.556); use `Image.save()` or `save_as()`.
- UV layout: `uv.export_layout` SVG works headless, PNG needs a GPU; GIMP
  imports the SVG as paths (6 for the default cube) or as a link layer.
- **GIMP 3.2 link layers** (`app/core/gimplink.c`): `Gimp.LinkLayer.new`
  works from Python for SVG, PNG and XCF; survives XCF save and reload; a
  replaced PNG showed within a second [tested].
- **GIMP 3 plug-in API** [introspection]: Python 3.13; `persistent_enable`,
  `persistent_process`, `add_temp_procedure` (a resident plug-in is
  possible); Gio file monitors and socket services; `get_xcf_file`,
  `is_dirty`. No "user saved" hook: use an explicit "Send to Blender", or
  poll dirty state or mtime (UNVERIFIED in the GUI).
- A resident GIMP 3 Python plug-in serving a socket exists:
  [maorcc/gimp-mcp](https://github.com/maorcc/gimp-mcp) (GPL-3.0, threaded
  TCP on localhost:9877). PDB calls from a worker thread are UNVERIFIED as
  safe; a `Gio.SocketService` on the main loop is cleaner.
- Other GIMP control paths: D-Bus `org.gimp.GIMP.UI` (`Open`,
  `OpenAsNew`, `BatchRun`, `Activate`); the Script-Fu server
  (127.0.0.1:10008, Scheme); batch mode [tested].
- Blender: `bpy.app.timers`; `Image.reload()` [tested];
  `image.pixels.foreach_set` for in-memory updates.
- UDIM: Blender `name.1001.png`; GIMP has no UDIM, so one image per tile
  or a stitched grid.
- Colour: Blender uses OCIO, GIMP babl and LittleCMS with ICC (no OCIO,
  UNVERIFIED). Albedo as sRGB PNG; data maps Non-Color in Blender and no
  profile conversion in GIMP; HDR as EXR (linear both sides) [tested].

## 2. What texture and skin painters do and complain about

1. The alt-tab loop: "export PNG, alt+tab to Blender, reload texture,
   notice the mistakes..." (2023),
   https://blenderartists.org/t/krita-plugin-to-help-with-texture-painting/1490808
2. Blender does not reload by itself, asked for since 2006
   (https://blenderartists.org/t/auto-reload-textures-feature-request/369397,
   https://blenderartists.org/t/blender-should-eat-the-gimp-what-do-you-think/469826).
3. Edit Externally confuses beginners: a grey image without UVs
   (https://blenderartists.org/t/how-to-export-and-texture-paint-in-krita-or-gimp/1520227);
   with Flatpak GIMP the accepted fix was uninstalling the Flatpak
   (https://blenderartists.org/t/how-to-find-location-of-gimp-to-associate-with-blender-linux-mint-tara-19-cinnamon/1128901).
4. Blender painting has no layers and is slow at 2K and up (2025 threads;
   the roadmap lists texture layers as in development, no release).
5. People want layered GIMP or Krita files used directly (ORA suggested,
   2016).
6. UV export is crude: outlines only wanted, no per-island masks.
7. No masking to a UV face in 2D; the workaround is a stencil in GIMP.
8. Seam bleed and dilation by hand
   (https://gitlab.gnome.org/GNOME/gimp/-/work_items/12887,
   https://github.com/ucupumar/ucupaint/issues/415).
9. Alpha and premultiplication mismatches
   (https://gitlab.gnome.org/GNOME/gimp/-/work_items/2213,
   https://gitlab.gnome.org/GNOME/gimp/-/work_items/5533).
10. Blockbench (GPL-3.0) is the design that works for Minecraft-style
    skins: edit externally, `fs.watch` with a 60 ms debounce, reload.
    VRChat and Minecraft threads were not gathered (UNVERIFIED).

The friction sits at the seam between the two apps: no automatic reload,
fragile external editor setup (worst with Flatpak), no clean UV overlay or
island masks in the 2D editor, Quick Edit darkening and symmetry, manual
seam dilation, alpha and colour space surprises.

## 3. Other interlinks for GIMP

- **darktable, RawTherapee, ART**: GIMP calls `darktable --gimp` (4.6+),
  one way only; the way back is darktable's
  [contrib/gimp.lua](https://github.com/darktable-org/lua-scripts/blob/master/contrib/gimp.lua)
  (GIMP 3 UNVERIFIED). On this machine GIMP's Flatpak has no darktable or
  rawtherapee on PATH, so raw opening through GIMP likely cannot reach
  darktable's Flatpak (UNVERIFIED).
- **Inkscape**: GIMP 3.2 imports and exports SVG paths [tested], has
  vector layers, and an SVG link layer updates when Inkscape saves.
  Missing: an "edit link layer source in Inkscape" action.
- **Krita**: ORA and PSD shared; Krita removed XCF import in 2026-08
  (whether released: UNVERIFIED).
- **Scribus**: GIMP 3 has CMYK soft proofing and CMYK export; Scribus'
  image editor defaults to `gimp` (reload behaviour UNVERIFIED).
- **LibreOffice**: "Edit with External Tool" watches a temp file; works if
  GIMP is the default app.
- **Hugin and enfuse**: only [dcknuth/gimp_focus_stack](https://github.com/dcknuth/gimp_focus_stack)
  (MIT, Windows only, 8-bit JPEG); nothing for panoramas.
- **Kdenlive, OBS**: reload images on change already. Natron: last
  release 2022.
- **G'MIC-Qt** 4.0.5 supports GIMP 3 (installed here).
- **Local AI**: [intel/openvino-ai-plugins-gimp](https://github.com/intel/openvino-ai-plugins-gimp)
  (Apache-2.0, GIMP 3); Charlweed/gimp_comfyui (MIT, alpha, 2025-01);
  swaynos/gimp-comfyui-sam (GPL-3.0, SAM selection only);
  shsmad/stable-gimpfusion3 (no licence); best in class
  [krita-ai-diffusion](https://github.com/Acly/krita-ai-diffusion)
  (GPL-3.0, about 10.6k stars), no GIMP port.
- **Godot, Unity**: reimport PNG and EXR on change; an XCF "export texture
  set" is the useful piece.
- **FreeCAD, Fiji/ImageJ, Nextcloud**: low value; Nextcloud should work
  through GIO and GVfs (UNVERIFIED live).

## 4. Ranked recommendation

### 1. GIMP Link for Blender (medium to large)

For the user: in Blender, "Edit in GIMP" on the active texture; GIMP opens
a layered XCF (texture as base, UV layout as a live link layer, islands as
paths, an empty paint layer); every "Send to Blender" (or Ctrl+S) updates
the texture in the viewport within a second; reopening keeps the layers.

How (two parts, GPL-3.0, after GoB and Blender Krita Link):

- An exchange folder next to the .blend or under
  `~/.local/share/gimplink/`, never `/tmp`.
- Blender add-on: save with `Image.save()` (16-bit PNG for colour, EXR for
  data maps); export the UV SVG plus an islands-only outline and per-island
  masks from bmesh; write `manifest.json` (path, colour space, size, UDIM,
  port); ask the resident GIMP plug-in over localhost TCP to open it
  (fallback: the Image Editor preference or a wrapper, documenting the
  Flatpak override and its trade-off); a `bpy.app.timers` job polls the
  returned file's mtime and listens for a "reload" message, then
  `image.reload()`.
- GIMP 3 plug-in (Python, resident): a `Gio.SocketService` on 127.0.0.1 on
  the main loop; builds the XCF (base, UV link layer, island paths, paint
  layer; linear and no conversion for Non-Color maps); "Send to Blender"
  hides helper layers, optionally dilates islands by N px, exports a
  flattened 16-bit PNG or EXR atomically (`os.replace`), and pings Blender.
- A better Quick Edit: the snapshot as a locked reference layer and a
  separate paint layer, sending back only the paint (no darkening); the
  view link kept in the manifest.
- Reverse live view for free: a GIMP link layer to the texture refreshes
  when Blender saves it [tested].

Tests, all headless: Blender makes a cube with a known texture and exports
texture, SVG and manifest; gimp-console with a throwaway profile runs the
plug-in's build and send functions and paints a known rectangle; Blender
reloads and asserts the pixels at that UV location (1/65535 for 16-bit,
exact for EXR), for sRGB and Non-Color maps; a link layer test; a socket
protocol test; a manual GUI checklist (Flatpak and native, UDIM).

Risks: launching Flatpak GIMP from Flatpak Blender needs a host-spawn
override (avoided if GIMP is already running with the plug-in); no GIMP
save hook (explicit send is the reliable path); the resident plug-in's
behaviour in the GUI needs a spike first; UDIM adds work; Blender's
planned texture layers may lower demand later.

### 2. GIMP UV Tools (small to medium)

Import a UV SVG (Blender, Blockbench) as island outlines, one path or
selection per island, and an island mask channel; dilate or bleed islands
N px; select the island under the cursor; fill outside islands; channel
pack and unpack (e.g. ORM). Dilation at 4K as a GEGL op, the house
pattern. Low risk.

### 3. Texture Set export (small)

Top-level layer groups named albedo, normal, roughness and so on export to
engine-ready PNG or EXR with the right bit depth and no conversion for
data maps, optional channel packing, atomically, so Godot, Unity, Blender
and Blockbench pick them up. Presets for engine naming.

### 4. ComfyUI bridge for GIMP 3 (large)

Inpaint, outpaint, upscale and seamless textures from a selection against
a local ComfyUI server; results as layers. The demand is shown by
krita-ai-diffusion. Large scope, fast-moving APIs.

### 5. darktable round trip with Flatpaks (small to medium)

Make raw opening work when both are Flatpaks, and add "Send back to
darktable" (16-bit TIFF next to the raw, grouped by darktable). First
verify whether `file-darktable` reaches a Flatpak darktable; may be an
upstream Flatpak manifest fix.

### 6. Hugin and enfuse for GIMP 3 (medium)

Align (`align_image_stack`) and fuse (`enfuse`, exposure or focus) layers
or files, returning 16-bit. Needs Flatpak extensions or a documented
override.

### 7. "Edit source externally" for link layers (small)

A right-click action opening a link layer's source in its app through a
configurable command; GIMP already reloads on change. Check the GIMP
tracker first and offer upstream.

### 8. A shared localhost control socket (small)

The resident `Gio.SocketService` plug-in and a narrow JSON protocol bound
to 127.0.0.1 with a token file, for 1, 4, 5 and 7 (safer than gimp-mcp's
threaded `exec()` server).

### Not recommended now

FreeCAD texture link, a Fiji bridge, Scribus, LibreOffice, Kdenlive and OBS
links (their own watchers reload already), Nextcloud (GIO covers it; worth
a live test).
