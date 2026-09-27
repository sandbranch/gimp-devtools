# GIMP and level editors

Research date 2026-09-27, on GIMP 3.2.6, Godot 4.7.2, Krita 5.3.3 and
Blockbench 5.2.1 (Flatpak) and the Tiled 1.12.2 AppImage, with the sources of
Tiled, LDtk, TrenchBroom and OGMO 3 CE read from their repositories. Marks:
**[tested]** run here (scripts and fixtures in
[level-editor-tests/](level-editor-tests/); they still use the scratch
paths they were written with), **[source]** read in the program's source,
**[docs]** vendor docs or trackers, **UNVERIFIED** not confirmed.

## Short answer

The big 2D editors already reload images by themselves:

- **Tiled** reloads a tileset image about half a second after GIMP writes
  it, including atomic saves [tested], and reloads a changed `.tsx` when it
  has no unsaved changes [source].
- **LDtk** reloads tileset images [source], but misses every save after the
  first from editors that save by rename (Krita does; GIMP's PNG export and
  Aseprite write in place).
- **Godot** reimports when its window gets focus [source].

So no live link is needed for Tiled, LDtk or Godot. What is missing is
everything that is not pixels: tileset metadata (grid, margin, spacing,
tile properties, collision shapes, Wang/terrain sets, animations),
autotile templates, extrusion against bleeding, atlas packing with
metadata, and Quake WAD export for TrenchBroom. GIMP 3 has none of it, and
the GIMP 2 plug-ins that did parts of it do not run on GIMP 3.

A surprise: the Tiled Flatpak can very likely open `.xcf` directly, since its
KDE runtime ships kimageformats' `kimg_xcf` (and `kimg_psd`, `kimg_kra`).
With those plug-ins in the Tiled AppImage, Tiled read and live-reloaded a
GIMP 3.2 XCF [tested]. It fails once a GIMP 3 feature raises the XCF version
above 12 (a non-destructive filter gave v022), blends partial opacity in
sRGB instead of GIMP's linear light, and shows 32-bit float XCF far too dark.
Fine for plain pixel-art layer stacks; not something to build on. (The
Tiled Flatpak itself was not run.)

## 1. 2D editors

GitHub stars on 2026-09-27: Tiled 12919, LDtk 4227, OGMO 3 CE 590.

### Tiled (Flatpak org.mapeditor.Tiled)

- Tilesets are one image plus a grid in `.tsx`/`.tsj`, or an image
  collection (https://doc.mapeditor.org/en/latest/manual/editing-tilesets/).
- Reload [source + tested]: `src/libtiled/tilesetmanager.cpp` watches every
  tileset image with `QFileSystemWatcher`, waits 500 ms after the last
  change, reloads, and re-adds the watch after a rename ("This happens
  commonly with applications that do atomic saving"). Preference
  `Storage/ReloadTilesets`, on by default. Tested headless (offscreen Qt,
  throwaway HOME): in-place rewrites, atomic replaces and a GIMP 3.2 XCF
  re-save all showed up with the right size and tile count.
- `.tsx` and `.tmx` documents are watched too (`src/tiled/documentmanager.cpp`):
  reloaded if unmodified, else a "changed on disk" warning [source].
- Aseprite files: Tiled 1.11.1 and later ship
  [qaseprite](https://github.com/mapeditor/qaseprite) (MIT); a minimal
  `.aseprite` tileset rendered correctly [tested].
- XCF, PSD, KRA through the Flatpak runtime's kimageformats (see above);
  ORA not (no `kimg_ora`). kimageformats rejects XCF above version 12
  (https://invent.kde.org/frameworks/kimageformats/-/raw/master/src/imageformats/xcf.cpp).
- "Open with System Editor" on a tile opens the tileset PNG, not its XCF.
- JavaScript extensions (`~/.config/tiled/extensions/`) can register
  actions, formats and tools, run programs, read and write files and
  images; `tiled --evaluate script.js` runs a script without the editor, a
  good test harness [tested].
- Tiled can hold what GIMP cannot write: margin and spacing, tile
  properties and classes, per-tile collision objects, animations, Wang sets
  (`src/libtiled/mapwriter.cpp`).

### LDtk

- A tileset points at one image (`.png .gif .jpg .jpeg .aseprite .ase`);
  no XCF, PSD or ORA.
- Reload [source + simulated]: `misc/FileWatcher.hx` uses Node `fs.watch`;
  on "change" it reloads after 1 s while the window has focus; on "rename"
  it does nothing (`// TODO support renaming?`). A Node simulation showed an
  atomic replace is picked up once, then the watch sits on the old inode and
  later saves are missed until the project is reopened [tested]. GIMP 3.2
  writes PNG exports in place and XCF atomically [tested with inotify];
  Aseprite saves in place [source]; Krita exports through `QSaveFile`
  (atomic) [source], so Krita users hit this.
- Last release v1.5.3 (2024-01-15); project file reload request open
  (https://github.com/deepnight/ldtk/issues/976); Aseprite layer opacity
  ignored (#661); engine importers often need a PNG anyway.

### Godot 4 TileMap / TileSet

- Imported textures (PNG, JPG, WebP, SVG, TGA, BMP, EXR, HDR, DDS, KTX);
  no PSD, XCF or Aseprite. Rescans on window focus
  (`editor/editor_node.cpp`) [source]; headless import tested.
- The TileSet editor can keep an old texture after a size change until a
  restart (https://github.com/godotengine/godot/issues/74946).
- `use_texture_padding` (on by default) pads tiles internally: no
  extrusion needed for Godot 4.
- Aseprite: [Aseprite Wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard)
  (MIT). Autotile templates: [TileBitTools](https://github.com/dandeliondino/tile_bit_tools) (MIT).

### Others

- OGMO 3 CE (MIT, last commit 2022): no tileset image watching [source].
- Sprite Fusion (web): manual image swap only.
- Tilesetter (commercial): generates Blob and Wang sets, exports to many
  engines; the paid tool that covers the autotile gap.
- Open autotile generators: [TilePipe](https://github.com/aleksandrbazhin/TilePipe)
  (MIT, 2023), [autotiler](https://github.com/itsjavi/autotiler) (MIT, active).

## 2. 3D editors

- **TrenchBroom** (GPL-3.0): textures from WAD2 (Quake), WAD3 (Half-Life),
  `.wal` (Quake 2) or loose PNG/TGA/JPG (Quake 3, Generic; Godot's
  [func_godot](https://github.com/func-godot/func_godot_plugin) uses
  Generic). No file watching of materials: reload by hand with F5
  [source]; issue open (https://github.com/TrenchBroom/TrenchBroom/issues/5487).
  No scripting API. GIMP has no WAD support; Quake textures need the Quake
  palette, sizes in multiples of 16 and four mip levels
  (https://quakewiki.org/wiki/Texture_Wad, https://twhl.info/wiki/page/WAD).
- Unity (reimport on focus, Aseprite Importer), Unreal (Auto Reimport),
  Blockbench (watches textures), Crocotile 3D (refreshes tilesets every
  couple of minutes, has UV padding). J.A.C.K., Hammer, Sledge not checked.

## 3. GIMP tools that exist

Built into GIMP 3.2.6: Configure Grid and snapping, guides (new, percent,
from selection), Guillotine, Tile and Tile Small, `gegl:tile-seamless`,
Offset with wrap-around, tiling symmetry painting, animation playback and
optimisation. None writes tileset metadata, extrudes or packs an atlas.

| Plug-in | What | Licence | Last push | GIMP 3? |
|---|---|---|---|---|
| [tilemancer](https://github.com/malteehrlen/tilemancer) | layers to sprite sheet | MIT | 2026-01 | yes (Script-Fu) |
| [sprite-packer](https://github.com/pyl0ader/sprite-packer) | layers to sprite sheet | none | 2026-09 | yes |
| [Batcher](https://github.com/kamilburda/batcher) | batch layer export | BSD-3 | 2026-08 | yes |
| [GimpSpriteAtlas](https://github.com/BdR76/GimpSpriteAtlas) | atlas packing plus JSON/XML/CSS | GPL-3.0 | 2024-03 | no |
| [gimp-export-spritesheet](https://github.com/jarnik/gimp-export-spritesheet) | TextureAtlas | MIT | 2019 | no |
| [gimp-tilemap-helper](https://github.com/bbbbbr/gimp-tilemap-helper) | tile dedup | GPL-3.0 | 2020 | no |
| [gimp-tilemap-gb](https://github.com/bbbbbr/gimp-tilemap-gb) | Game Boy tilemaps | GPL-3.0 | 2024 | no |
| [gimp-vera-tileset-plugin](https://github.com/jestin/gimp-vera-tileset-plugin) | X16 tiles, writes `.tsx` | none | 2025-10 | no |
| [resynth-tiles](https://github.com/BorisTheBrave/resynth-tiles) | tileset synthesis | GPL-3.0 | 2013 | no |
| [gimp-tmxtileme](https://github.com/lumley/gimp-tmxtileme) | layer to TMX | GPL-3.0 | 2013 | no |
| [GIMP-hl-sprite-plugin](https://github.com/Psycrow101/GIMP-hl-sprite-plugin) | Half-Life `.spr` | none | 2024 | no |
| [tile-extruder](https://github.com/sporadic-labs/tile-extruder) | extrusion (web, CLI; not GIMP) | none | 2026-02 | n/a |

## 4. What users describe

Paint in GIMP or Aseprite, export PNG, and Tiled or LDtk reloads it.
Aseprite users asked Tiled to read `.aseprite` directly
(https://discourse.mapeditor.org/t/aseprite-files-as-tileset-images/5084),
which became qaseprite. Threads on keeping collision data with a tileset
were seen only as search results (UNVERIFIED). Reddit and itch not checked.

## 5. Ranked recommendation

Nothing is needed for plain reloading. Build the metadata side:

1. **Tileset Export for GIMP 3: XCF to PNG plus TSX (medium).** File >
   Export Tileset and a quick "Send to Tiled": grid from Configure Grid,
   tile properties from a layer naming convention or a parasite (which
   convention users want: UNVERIFIED), GIMP paths in a tile cell as its
   collision polygon, a layer group like "anim:walk" as an animation;
   `.tsx`/`.tsj`, which Tiled reloads with no Tiled-side code. Later Godot
   `.tres`, LDtk. Test: headless GIMP writes XCF, PNG and TSX; `tiled
   --evaluate` asserts tile count, properties, polygons and animations;
   `tmxrasterizer` renders a fixture map against a golden PNG.
2. **Extrude/pad tiles (small):** a GEGL op or part of 1, copying edge
   pixels outward and writing the matching margin and spacing. For engines
   with filtering (Phaser, Love2D; UNVERIFIED per engine); not needed for
   Godot 4 or Crocotile. Test pixel by pixel.
3. **Autotile template generator and composer (medium):** a layered XCF with
   guides for Wang 16, blob 47, Godot 3x3 minimal or RPG Maker A2 (which
   matter most: UNVERIFIED), optionally composed from a few painted parts
   (TilePipe and autotiler, MIT, have the tables); 1 writes the Wang sets.
   Test: blob 47 from 5 flat parts, wangids against a table, then paint
   terrain with a `tiled --evaluate` script.
4. **Quake WAD2 / Half-Life WAD3 export (small to medium):** layers as mip
   textures, Quake palette (optionally without fullbrights) or 256 colours
   per texture, the `{` transparency rule, size checks and 4 mips; then F5
   in TrenchBroom. Test against an independent reader (licence to check).
5. **Port GimpSpriteAtlas to GIMP 3 (small to medium):** GPL-3.0, fits the
   plan of porting abandoned plug-ins. Test by cropping each rectangle from
   the JSON and comparing with the layers.
6. **Small links:** a Tiled extension "Edit Tileset Source in GIMP"
   (opens the sibling `.xcf` through the desktop portal; untested); an LDtk
   PR re-watching a file after "rename" (a few lines; LDtk has not released
   since January 2024); a TrenchBroom PR for material watching (medium, C++).

Not recommended: extending kimageformats' XCF reader past version 12. XCF
stores no composite, so a faithful reader needs GIMP's compositing and GEGL
filters; exporting PNG is the robust path.
