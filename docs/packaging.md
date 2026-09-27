# Packaging the sandbranch GIMP tools (2026-09-27)

Checked against official docs, the real manifests and repos, the GIMP
3.2.6 and GEGL 0.4.72 sources and the package archives. **UNVERIFIED**
marks what could not be checked.

## Four findings that shape the plan

1. **Flathub already has IDs for three of our ports, stuck on GIMP 2**:
   `org.gimp.GIMP.Plugin.BIMP`, `LiquidRescale` and `Lensfun` (and
   `FocusBlur`), last built 2024-03, branch `2-40`, which GIMP 3 does not
   mount. A GIMP Flatpak maintainer (@brunvonlope) asked on 2025-05-07 to
   unpublish them because they will never work on GIMP 3; no reply. They
   still get about 500 installs a month each. Updating those repos (like
   Resynthesizer's move to GIMP 3 in its PR #16) beats new submissions.
2. **Flathub's AI policy** (2026-09-04 and 2026-09-21,
   [requirements](https://docs.flathub.org/docs/for-app-authors/requirements)):
   submitters must disclose AI-generated code and its extent; "Flathub
   manifests must not contain AI-generated or AI-assisted content"; "AI
   tools or agents must not open or automate Flathub submission pull
   requests, or generate their commit messages, descriptions, review
   comments, or replies"; reviewers may reject based on the extent of
   generated material. So the manifests and PRs must be written by hand,
   and the AI share disclosed. Claude co-authored all commits of the new
   projects and a minority of the forks (gimp-lensfun 13/73,
   gimp-plugin-bimp 16/231, gimp-lqr-plugin 20/228).
3. **GEGL operations cannot ship as a Flathub extension or a .gex today.**
   The GIMP Flatpak's extension point merges only `plug-ins` and `scripts`,
   does not set `GEGL_PATH`, and GIMP 3.2.6 loads GEGL modules only from
   `/app/lib/gegl-0.4` and `~/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins`
   (from the source; untested with a real extension). A small change to the
   GIMP Flatpak would fix it: `gegl-0.4` in `merge-dirs` and GEGL (or GIMP)
   reading `/app/extensions/gegl-0.4`. GIMP's roadmap lists "GEGL
   operations in extensions" without a date.
4. **.gex is not a channel in GIMP 3.2**: `file-gex-load` can unpack a .gex
   (File > Open), but the extension manager's menu entry is compiled out of
   release builds and user extensions are off by default, so an installed
   .gex cannot be switched on (from the source; untested). No GEGL key in
   the format. extensions.gimp.org does not resolve yet.

## Flathub details

- Extension point `org.gimp.GIMP.Plugin`, version `3`, directory
  `extensions`, `add-ld-path` lib, `merge-dirs` `plug-ins;scripts`
  ([manifest](https://github.com/flathub/org.gimp.GIMP/blob/master/org.gimp.GIMP.json)).
  Extensions install to `/app/extensions/<Name>/plug-ins/<name>/<name>`
  and `share/metainfo/org.gimp.GIMP.Plugin.<Name>.metainfo.xml`.
- Models: [GMic](https://github.com/flathub/org.gimp.GIMP.Plugin.GMic),
  [Resynthesizer](https://github.com/flathub/org.gimp.GIMP.Plugin.Resynthesizer)
  (meson, the model for ours), [Fourier](https://github.com/flathub/org.gimp.GIMP.Plugin.Fourier).
- Metainfo: `type="addon"`, `<extends>org.gimp.GIMP</extends>`, name,
  summary, url, `metadata_license` CC0-1.0, `project_license`, developer,
  releases.
- No network during builds: liblqr and lensfun become manifest modules.
  Stable tagged releases only. One extension per project (a single Wavelet
  extension for both wavelet plug-ins is reasonable).
- Submission: PR to `flathub/flathub` branch `new-pr`, "Add
  org.gimp.GIMP.Plugin.X"; volunteers review with no time limit.
- Installs in the last 30 daily entries: GIMP 72119; GMic 2206,
  Resynthesizer 2075, Fourier 1174; the broken BIMP 566, LiquidRescale 489,
  Lensfun 470, FocusBlur 441.

## Blender (gimp-blender-link)

- [extensions.blender.org](https://extensions.blender.org/terms-of-service/)
  requires GPL-3.0-or-later (ours is). Its moderation guidelines say an
  add-on "should not have functionality which is extended by external
  software" (localhost is fine) and to ask #extension-moderators when in
  doubt: acceptance of a GIMP bridge is UNVERIFIED.
- The manual says an add-on must check `bpy.app.online_access` "if the
  add-on needs to use internet"
  ([manual](https://docs.blender.org/manual/en/latest/advanced/extensions/addons.html));
  the link only talks to 127.0.0.1, and the moderation guidelines say
  "localhost is fine", so it does not check (as docs/design.md of
  gimp-blender-link decided). Say so when asking the moderators.
- Fallback without review: a static extension repository (`blender
  --command extension server-generate`) on GitHub Pages; users add it once.

## Other channels

- **AUR**: Arch has GIMP 3.2.6. The old gimp-plugin-lqr and
  gimp-plugin-wavelet-denoise are orphaned (adoptable); gimp-plugin-bimp,
  gimp-plugin-wavelet-sharpen and gimp-plugin-layerfx are maintained but
  GIMP 2 only (ask the maintainers). New packages for the rest, and native
  packages install GEGL ops cleanly to `/usr/lib/gegl-0.4`.
- **Debian**: libgimp-3.0-dev 3.0.4 in Debian 13, 3.2.6 in testing;
  gimp-plugin-registry is only in unstable (removed from testing
  2024-09-25) and already bundles lqr, layer-effects and wavelet-denoise;
  routes are a Salsa merge request or sponsored new packages (weeks to
  months, UNVERIFIED).
- **Windows**: per-user plug-ins in `%APPDATA%\GIMP\3.2\plug-ins`; MSYS2
  CLANG64 has GIMP 3.2.6, matching how official Windows GIMP is built
  (whether such builds need extra DLLs is UNVERIFIED). **macOS**: no
  headers packaged; leave for now.
- **Discovery**: no official index. [XDesigns-gfx/Gimp-Plugins-list](https://github.com/XDesigns-gfx/Gimp-Plugins-list)
  lists BIMP as "?" and Liquid Rescale and Lensfun as GIMP 2 only; the
  pixls.us thread "Which GIMP 3 plugins are you using?"; GIMP Chat's GIMP 3
  forum; GitHub topics `gimp-plugin`, `gegl`, `gimp3`.
- **GitHub**: no repo has releases, workflows, metainfo, or an org
  profile yet; only 6 of 13 have topics.

## Ranked plan

1. Tagged GitHub Releases with built files, from one reusable workflow in
   gimp-plugin-devtools (Linux: the GNOME 50 Flatpak SDK container, or
   Ubuntu 26.04 / Debian testing packages). Prerequisite for everything,
   and the only route for GEGL ops on Flatpak today (download the .so into
   the user GEGL folder).
2. Flathub, the existing IDs (BIMP, LiquidRescale with the faithful port,
   Lensfun): hand-written manifests and PRs, comments on the unpublish
   issues. Most Linux users, one click.
3. Flathub, new extensions: LiquidRescaleTNG, LayerFX, Wavelet,
   BlenderLink (highest disclosure risk: new, mostly AI-written code).
4. AUR: adopt the orphans, ask the maintainers, add new packages
   (including the GEGL ops).
5. Propose GEGL ops in GIMP Flatpak extensions (an issue on
   flathub/org.gimp.GIMP, hand-written).
6. Blender: ask the moderators (localhost only, no internet), meanwhile a
   static repository.
7. Discovery: org profile README and topics, a PR to the plug-ins list, a
   pixls.us post.
8. Windows zips from MSYS2 CLANG64, tested on a real Windows GIMP first.
9. Later: Debian; .gex once GIMP ships the manager and the site.
