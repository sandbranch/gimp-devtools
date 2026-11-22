#!/bin/sh
# Builds the release files of the sandbranch plug-ins and filters, checks
# them in a throwaway home, and (separately) makes draft GitHub releases.
#
#   release.sh build [repo...]   build and check; files in dist/<repo>/
#   release.sh draft repo...     tag and make a DRAFT release of dist/<repo>/
#   release.sh list              the repositories and their versions
#
# build, for each repository (all of the list below if none is given):
#
# 1. exports the committed HEAD (git archive, so nothing that is not
#    committed gets in) into a fresh work folder;
# 2. builds it natively against the GIMP and GEGL on this machine
#    (gimp-build.sh, isolated: HOME and the XDG folders in the work
#    folder) and installs it into a staging home, not into your GIMP;
# 3. packs it:
#    - C and GEGL repositories: <repo>-<version>-linux-x86_64.tar.gz, to
#      be extracted into the home folder, with the files below
#      .local/share/gegl-0.4/plug-ins/<repo>/ (GEGL operations) and
#      .config/GIMP/3.2/plug-ins/<name>/ (GIMP plug-ins);
#    - Python plug-ins: <repo>-<version>.zip of the plug-in folder, to be
#      unpacked into GIMP's plug-in folder (Inkscape's extensions folder
#      for inkscape-xcf-export);
#    every folder gets INSTALL.txt and the licence files (COPYING,
#    LICENSE, NOTICE and the licences of bundled libraries);
# 4. checks the package: extracts it into another throwaway home, exactly
#    where a user would, starts GIMP there without a window
#    (gimp-console, gimp-run.sh) and checks that every GEGL operation of
#    the source registers and every plug-in folder registers procedures
#    (from GIMP's pluginrc, and in the PDB);
# 5. writes dist/<repo>/SHA256SUMS, dist/<repo>/RELEASE-NOTES.md and
#    dist/SHA256SUMS (all files in dist/).
#
# draft, for each repository: an annotated tag v<version> on HEAD (which
# must be the commit that was built and be pushed), pushed, and a DRAFT
# release with the files of dist/<repo>/ and RELEASE-NOTES.md as its text.
# It never publishes: gh release create --draft, and it stops if a
# release of that tag exists. RELEASE_NO_TAG=1 does not push the tag:
# the draft then names HEAD as its target and GitHub makes the tag when
# the release is published (for a version that is still to be decided).
#
# The version is the one of meson.build (0.1 becomes 0.1.0), else of the
# Blender manifest (gimp-blender-link), else 0.1.0.
#
# The work folder is a new one in $TMPDIR (or /tmp), removed afterwards
# unless RELEASE_KEEP=1. Exits non-zero if anything failed.
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

# the texts for users have ~ in them as it is
# shellcheck disable=SC2088

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
top=$(dirname "$here")
dist=$here/dist
. "$here/gimp-env.sh"
[ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"

all="gegl-adjustments gegl-control-points gegl-presence gegl-equalizers gegl-lut
gegl-depth-blur gegl-underwater gegl-wavelet gimp-forensics gimp-fusion
gimp-save-for-web gimp-layerfx gimp-lensfun gimp-bimp gimp-lqr-tng
gimp-pixel-scale gimp-tileset-export gimp-uv-tools gimp-blender-link
inkscape-xcf-export gegl-astro gegl-photo-restore gimp-auto-perspective"

# the folders inside a home, relative to it
GEGL_REL=.local/share/gegl-0.4/plug-ins
GIMP_REL=.config/GIMP/$GIMP_SERIES/plug-ins
INK_REL=.config/inkscape/extensions
# the home that meson is configured with: no real folder, so that a path
# a binary keeps from the build is found by the check below
FAKE_HOME=/release-home

GEGL_VERSION=$(pkg-config --modversion gegl-0.4)
OS_NAME=$(. /etc/os-release && echo "$PRETTY_NAME")
ARCH=$(uname -m)

# kind <repo>: meson or python
kind () {
    case $1 in
        gimp-save-for-web|gimp-layerfx|gimp-tileset-export|gimp-uv-tools|gimp-blender-link|inkscape-xcf-export)
            echo python ;;
        *) echo meson ;;
    esac
}

# version <source folder>: x.y.z
version () {
    v=
    [ -f "$1/meson.build" ] &&
        v=$(sed -n "/^project *(/,/)/s/^ *version *: *'\([^']*\)'.*/\1/p" "$1/meson.build" | head -n 1)
    [ -n "$v" ] || [ ! -f "$1/blender/gimp_link/blender_manifest.toml" ] ||
        v=$(sed -n 's/^version = "\(.*\)"$/\1/p' "$1/blender/gimp_link/blender_manifest.toml")
    [ -n "$v" ] || v=0.1.0
    case $v in
        *[!0-9.]*) ;;          # e.g. 3.0.0-dev: as it is (build refuses it)
        *.*.*) ;;
        *.*) v=$v.0 ;;
        *) v=$v.0.0 ;;
    esac
    echo "$v"
}

# python_folder <repo>: <folder in the repository> <name of the plug-in>
python_folder () {
    case $1 in
        gimp-save-for-web) echo save-for-web save-for-web ;;
        gimp-layerfx) echo layerfx layerfx ;;
        gimp-tileset-export) echo tileset-export tileset-export ;;
        gimp-uv-tools) echo uv-tools uv-tools ;;
        gimp-blender-link) echo gimp/gimp-blender-link gimp-blender-link ;;
        inkscape-xcf-export) echo . inkscape-xcf-export ;;
    esac
}

# the files of the Inkscape extension (as dev/install.sh links them)
INK_FILES="xcf_export.inx xcf_export.py xcf_writer.py css_blend.py
xcf_import.inx xcf_import.py xcf_reader.py"

# meson options of a repository besides the folders
meson_extra () {
    case $1 in
        gimp-lensfun) echo -Dgegl_op=enabled -Dbundled_lensfun=enabled ;;
        gimp-lqr-tng) echo -Dbundled_liblqr=enabled -Dplugin=enabled ;;
        gimp-fusion) echo -Dplugin=enabled ;;
        gimp-auto-perspective) echo -Dplugin=enabled ;;
    esac
}

# binaries that may keep the build-time path: the path is only their
# fallback (lensfun:correct finds its database next to itself first)
may_keep_path () {
    case $1 in
        */lensfun-correct.so) return 0 ;;
    esac
    return 1
}

log () { echo "$*" >&2; }

# the licence files of a source folder into a folder
copy_licences () {
    for f in COPYING COPYING.LESSER LICENSE LICENSE.txt LICENSE.md NOTICE NOTICE.txt NOTICE.md; do
        [ ! -f "$1/$f" ] || cp "$1/$f" "$2/$f"
    done
}

# third_party <source folder> <build folder> <folder>: the licences of
# libraries built into the binaries, and THIRD-PARTY-NOTICES.txt
third_party () {
    tp_src=$1 tp_out=$2
    notes=
    if [ -d "$tp_src/subprojects/lensfun" ]; then
        mkdir -p "$tp_out/third-party/lensfun"
        cp "$tp_src/subprojects/lensfun/docs/lgpl-3.0.txt" "$tp_src/subprojects/lensfun/docs/gpl-3.0.txt" \
           "$tp_src/subprojects/lensfun/docs/cc-by-sa-3.0.txt" "$tp_out/third-party/lensfun/" 2>/dev/null
        notes="$notes
lensfun $(git -C "$tp_src/subprojects/lensfun" describe --tags 2>/dev/null || echo 0.3.4)
  https://github.com/lensfun/lensfun
  The library is linked in statically: LGPL-3.0 (third-party/lensfun/lgpl-3.0.txt,
  which builds on the GPL-3.0 text, gpl-3.0.txt). Its lens database
  (the lensfun-db folders) is under CC BY-SA 3.0 (cc-by-sa-3.0.txt).
"
    fi
    if [ -d "$tp_src/subprojects/liblqr" ]; then
        mkdir -p "$tp_out/third-party/liblqr"
        for f in COPYING COPYING.LESSER AUTHORS; do
            [ ! -f "$tp_src/subprojects/liblqr/$f" ] || cp "$tp_src/subprojects/liblqr/$f" "$tp_out/third-party/liblqr/"
        done
        notes="$notes
liblqr (Liquid Rescale library, commit $(git -C "$tp_src/subprojects/liblqr" rev-parse --short HEAD 2>/dev/null))
  https://github.com/carlobaldassi/liblqr
  Linked in statically, with the two patches in subprojects/packagefiles
  of the source: LGPL-3.0 (third-party/liblqr/COPYING.LESSER, which builds
  on the GPL-3.0 text, COPYING).
"
    fi
    if [ -f "$tp_out/vendor/VERSION" ] && [ -d "$tp_out/vendor/c2pa" ]; then
        notes="$notes
c2pa-python $(cut -d' ' -f1 "$tp_out/vendor/VERSION"), with libc2pa_c.so (the C API of c2pa-rs)
  https://github.com/contentauth/c2pa-python
  From the wheel on PyPI that fetch-deps.py names (checked by SHA-256,
  see vendor/VERSION): MIT OR Apache-2.0, vendor/c2pa/LICENSE-MIT and
  vendor/c2pa/LICENSE-APACHE. libc2pa_c.so links its Rust dependencies
  statically, under their own licences, listed in the SBOM of the
  c2pa-rs release.
  The trust lists in trust/ and their licences: trust/SOURCES.txt.
"
    fi
    [ -z "$notes" ] || printf 'Libraries built into this release\n=================================\n%s' "$notes" > "$tp_out/THIRD-PARTY-NOTICES.txt"
}

# needed_libs <files...>: the shared libraries the binaries need that a
# native GIMP does not bring along (not needed by GIMP, libgimpui or GEGL)
needed_libs () {
    have=$( { ldd "$(command -v "$GIMP_CONSOLE")"
              ldd "$(pkg-config --variable=libdir gimp-3.0)/libgimpui-3.0.so.0"
              echo libgimpui-3.0.so.0
            } 2>/dev/null | awk '{print $1}' | sort -u)
    for f; do
        objdump -p "$f" 2>/dev/null | awk '/NEEDED/ {print $2}'
    done | sort -u | while read -r lib; do
        echo "$have" | grep -qxF "$lib" || echo "$lib"
    done
}

# install_txt <kind> <repo> <version> <commit> <asset> <folders...>
install_txt () {
    it_kind=$1 repo=$2 ver=$3 commit=$4 asset=$5
    shift 5
    url=https://github.com/sandbranch/$repo
    if [ "$repo" = inkscape-xcf-export ]; then
        app="Inkscape 1.x"
    else
        app="GIMP $GIMP_SERIES"
    fi
    echo "$repo $ver"
    echo
    echo "For $app. Source: $url"
    echo "Built from commit $commit (tag v$ver)."
    echo
    case $it_kind in
    tar)
        echo "Built on $OS_NAME ($ARCH) against GIMP $GIMP_VERSION and GEGL $GEGL_VERSION"
        echo "(the native GIMP of the distribution, not the Flatpak or Snap), and"
        echo "checked only there. It may load in the native GIMP $GIMP_SERIES of other"
        echo "recent Linux systems; if it does not, build it from source as the"
        echo "README says: $url#readme"
        echo
        echo "Install"
        echo "-------"
        echo
        echo "Extract the archive into your home folder and restart GIMP:"
        echo
        echo "    tar -xzf $asset -C ~"
        echo
        echo "That puts these folders in place:"
        echo
        for d; do echo "    ~/$d/"; done
        echo
        echo "(GEGL operations go into ~/$GEGL_REL, GIMP plug-ins into"
        echo "~/$GIMP_REL. If you set XDG_DATA_HOME or XDG_CONFIG_HOME,"
        echo "move them there; Edit > Preferences > Folders > Plug-ins in GIMP shows"
        echo "the folders it reads.)"
        echo
        echo "Uninstall by removing those folders."
        if [ -n "$NEEDED" ]; then
            echo
            echo "Besides GIMP and GEGL it needs these shared libraries:"
            echo
            for l in $NEEDED; do echo "    $l"; done
        fi
        ;;
    zip)
        if [ "$repo" = inkscape-xcf-export ]; then
            echo "An Inkscape extension in Python; nothing to build. Tested with Inkscape"
            echo "1.x on $OS_NAME."
            echo
            echo "Install"
            echo "-------"
            echo
            echo "Unpack the zip into Inkscape's extensions folder and restart Inkscape:"
            echo
            echo "    mkdir -p ~/$INK_REL"
            echo "    unzip $asset -d ~/$INK_REL"
            echo
            echo "so that you have ~/$INK_REL/$1/xcf_export.inx."
            echo "For the Inkscape Flatpak the folder is"
            echo "~/.var/app/org.inkscape.Inkscape/config/inkscape/extensions; Edit >"
            echo "Preferences > System in Inkscape shows it as \"User extensions\"."
            echo
            echo "Uninstall by removing the folder $1."
        else
            echo "A GIMP 3 plug-in in Python; nothing to build. Checked with GIMP"
            echo "$GIMP_VERSION on $OS_NAME. GIMP needs its Python support (the gimp"
            echo "package of Debian and Ubuntu has it)."
            echo
            echo "Install"
            echo "-------"
            echo
            echo "Unpack the zip into GIMP's plug-in folder and restart GIMP:"
            echo
            echo "    mkdir -p ~/$GIMP_REL"
            echo "    unzip $asset -d ~/$GIMP_REL"
            echo
            echo "so that you have ~/$GIMP_REL/$1/$1.py (the zip keeps it"
            echo "executable). On Windows the folder is %APPDATA%\\GIMP\\$GIMP_SERIES\\plug-ins\\, on"
            echo "macOS ~/Library/Application Support/GIMP/$GIMP_SERIES/plug-ins/ (not tried"
            echo "there). Edit > Preferences > Folders > Plug-ins in GIMP shows the"
            echo "folders it reads."
            echo
            echo "Uninstall by removing the folder $1."
        fi
        ;;
    esac
    echo
    echo "Licence: see the licence files next to this one (COPYING and the"
    echo "others), and THIRD-PARTY-NOTICES.txt where there is one."
}

# check_package <repo> <kind> <asset> <source folder> <work folder>
check_package () {
    repo=$1 ck_kind=$2 asset=$3 src=$4 work=$5
    vh=$work/check-home
    rm -rf "$vh"
    mkdir -p "$vh"
    case $ck_kind in
        tar) tar -xzf "$asset" -C "$vh" || return 1 ;;
        zip)
            if [ "$repo" = inkscape-xcf-export ]; then
                mkdir -p "$vh/$INK_REL" && unzip -q "$asset" -d "$vh/$INK_REL" || return 1
            else
                mkdir -p "$vh/$GIMP_REL" && unzip -q "$asset" -d "$vh/$GIMP_REL" || return 1
            fi ;;
    esac

    # the operations the source defines
    ops=$(grep -rlE --include='*.c' --include='*.cc' gegl_operation_class_set_keys "$src" |
          grep -v -e /tests/ -e /subprojects/ |
          xargs -r grep -hoE '"name", *"[a-z0-9_-]+:[a-z0-9_-]+"' |
          sed 's/.*"\([^"]*\)"$/\1/' | sort -u | tr '\n' ' ')
    plugins=
    [ ! -d "$vh/$GIMP_REL" ] || plugins=$(ls "$vh/$GIMP_REL")
    echo "ops: ${ops:-none}" > "$work/check.log"
    echo "plug-in folders: $(echo $plugins)" >> "$work/check.log"

    if [ -n "$ops" ] || [ -n "$plugins" ]; then
        cat > "$work/check.py" <<'EOF'
import os
import gi
gi.require_version('Gegl', '0.4')
from gi.repository import Gegl, Gimp
Gegl.init(None)
known = set(Gegl.list_operations())
for op in os.environ['CHECK_OPS'].split():
    print('%s operation %s' % ('PASS' if op in known else 'FAIL', op))
pdb = Gimp.get_pdb()
with open(os.environ['CHECK_PROCS'], 'w') as f:
    f.write('\n'.join(pdb.query_procedures('.*', '', '', '', '', '', '', '')))
EOF
        # nothing but the throwaway home: GIMP finds the operations and
        # plug-ins where the package put them, as on a user's machine
        GIMP_RUN_HOME=$vh "$here/gimp-run.sh" --env=CHECK_OPS="$ops" \
          --env=CHECK_PROCS="$work/procs.txt" -- \
          "$GIMP_CONSOLE" --no-interface --no-data --no-fonts \
          --batch-interpreter python-fu-eval -b "exec(open('$work/check.py').read())" --quit \
          > "$work/gimp.log" 2>&1
        grep -E '^(PASS|FAIL)' "$work/gimp.log" >> "$work/check.log"
        python3 -I - "$vh/${GIMP_REL%/plug-ins}/pluginrc" "$work/procs.txt" $plugins >> "$work/check.log" <<'EOF'
import re, sys
rc, procs_file, plugins = sys.argv[1], sys.argv[2], sys.argv[3:]
try:
    text = open(rc, encoding='utf-8', errors='replace').read()
except OSError:
    text = ''
try:
    live = set(open(procs_file).read().split())
except OSError:
    live = set()
defs = {}
for chunk in text.split('(plug-in-def ')[1:]:
    m = re.match(r'"([^"]+)"', chunk)
    if m:
        defs[m.group(1)] = re.findall(r'\(proc-def "([^"]+)"', chunk)
for p in plugins:
    names = [n for path, ns in defs.items() if '/plug-ins/%s/' % p in path for n in ns]
    ok = names and all(n in live for n in names)
    print('%s plug-in %s: %s' % ('PASS' if ok else 'FAIL', p, ' '.join(names) or 'no procedures'))
EOF
    fi

    if [ "$repo" = gimp-lensfun ]; then
        # lensfun:correct finds the database it came with (it corrects a
        # lens of it; without the database it passes the image through)
        cat > "$work/lensfun.py" <<'EOF'
import struct
import gi
gi.require_version('Gegl', '0.4')
from gi.repository import Gegl
Gegl.init(None)
W, H, FMT = 200, 100, 'RGBA float'
r = Gegl.Rectangle.new(0, 0, W, H)
px = []
for y in range(H):
    for x in range(W):
        v = 0.1 if (x % 10 < 2 or y % 10 < 2) else 0.9
        px += [v, v, v, 1.0]
buf = Gegl.Buffer.new(FMT, 0, 0, W, H)
buf.set(r, FMT, struct.pack('%df' % len(px), *px))
g = Gegl.Node()
src = g.create_child('gegl:buffer-source')
src.set_property('buffer', buf)
op = g.create_child('lensfun:correct')
for k, v in dict(camera_maker='Nikon', camera_model='D90',
                 lens_model='Nikkor AF-S 18-105mm f/3.5-5.6G DX ED VR',
                 focal_length=18.0).items():
    op.set_property(k, v)
src.connect_to('output', op, 'input')
out = Gegl.Buffer.new(FMT, 0, 0, W, H)
op.blit_buffer(out, r, 0, Gegl.AbyssPolicy.NONE)
d = struct.unpack('%df' % (W * H * 4), bytes(out.get(r, 1.0, FMT, Gegl.AbyssPolicy.NONE)))
n = sum(1 for a, b in zip(px, d) if abs(a - b) > 1e-3)
print('%s lensfun:correct corrects with its database (%d values changed)' % ('PASS' if n else 'FAIL', n))
EOF
        GIMP_RUN_HOME=$vh "$here/gimp-run.sh" -- python3 -I "$work/lensfun.py" 2>&1 |
            grep -E '^(PASS|FAIL)' >> "$work/check.log" ||
            echo "FAIL lensfun:correct check did not run" >> "$work/check.log"
    fi

    if [ "$repo" = inkscape-xcf-export ]; then
        # an export by the extension in Inkscape, opened in GIMP
        cp "$src/tests/data/layers.svg" "$vh/in.svg"
        if GIMP_RUN_HOME=$vh "$here/gimp-run.sh" --app=org.inkscape.Inkscape -- \
             inkscape "$vh/in.svg" --export-extension=org.sandbranch.output.xcf \
             --export-filename="$vh/out.xcf" > "$work/inkscape.log" 2>&1 &&
           head -c 9 "$vh/out.xcf" 2>/dev/null | grep -q 'gimp xcf'; then
            cat > "$work/open.py" <<EOF
from gi.repository import Gimp, Gio
img = Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path('$vh/out.xcf'))
print('PASS inkscape export opens in GIMP: %d layers' % len(img.get_layers()))
EOF
            GIMP_RUN_HOME=$vh "$here/gimp-run.sh" -- "$GIMP_CONSOLE" --no-interface \
              --batch-interpreter python-fu-eval -b "exec(open('$work/open.py').read())" --quit \
              > "$work/open.log" 2>&1
            grep -q '^PASS' "$work/open.log" && grep '^PASS' "$work/open.log" >> "$work/check.log" ||
                echo "FAIL the exported XCF does not open in GIMP" >> "$work/check.log"
        else
            echo "FAIL inkscape export with the extension (log: $work/inkscape.log)" >> "$work/check.log"
        fi
    fi

    cat "$work/check.log" >&2
    grep -q '^PASS' "$work/check.log" && ! grep -q '^FAIL' "$work/check.log"
}

# build_one <repo>
build_one () {
    repo=$1
    [ -d "$top/$repo/.git" ] || { log "$repo: no repository at $top/$repo"; return 1; }
    work=$(mktemp -d "${TMPDIR:-/tmp}/release-$repo.XXXXXX") || return 1
    src=$work/src
    mkdir -p "$src" "$work/home"
    commit=$(git -C "$top/$repo" rev-parse HEAD)
    short=$(git -C "$top/$repo" rev-parse --short HEAD)
    when=$(git -C "$top/$repo" log -1 --format=%ct)
    git -C "$top/$repo" archive HEAD | tar -x -C "$src" || return 1
    ver=$(version "$src")
    case $ver in
        *[!0-9.]*) log "$repo: version $ver is not a release version (meson.build)"; return 1 ;;
    esac
    k=$(kind "$repo")
    out=$dist/$repo
    rm -rf "$out"
    mkdir -p "$out"
    log "== $repo $ver ($short)"
    [ -z "$(git -C "$top/$repo" status --porcelain --untracked-files=no)" ] ||
        log "$repo: note: uncommitted changes are not in the package (built from HEAD)"

    if [ "$k" = meson ]; then
        stage=$work/stage
        home=$stage$FAKE_HOME
        moddir=$FAKE_HOME/$GEGL_REL
        # every repository's operations in a folder of its own
        grep -q "moduledir / meson.project_name()" "$src/meson.build" || moddir=$moddir/$repo
        opts=
        grep -q "option('moduledir'" "$src/meson_options.txt" && opts="$opts -Dmoduledir=$moddir"
        grep -q "option('plugindir'" "$src/meson_options.txt" && opts="$opts -Dplugindir=$FAKE_HOME/$GIMP_REL"
        # shellcheck disable=SC2046,SC2086 # word lists
        GIMP_RUN_HOME=$work/home "$here/gimp-build.sh" "$src" \
            meson setup "$work/build" $opts $(meson_extra "$repo") > "$work/build.log" 2>&1 &&
          GIMP_RUN_HOME=$work/home "$here/gimp-build.sh" "$src" \
            meson install -C "$work/build" --strip --destdir "$stage" >> "$work/build.log" 2>&1 ||
          { log "$repo: build failed (log: $work/build.log)"; RELEASE_KEEP=1; return 1; }

        # anything installed elsewhere (e.g. into the prefix) would be lost
        other=$(find "$stage" -mindepth 1 -maxdepth 1 ! -name "${FAKE_HOME#/}")
        [ -z "$other" ] ||
            { log "$repo: files installed outside the home: $other"; RELEASE_KEEP=1; return 1; }

        if [ "$repo" = gimp-forensics ]; then
            # content-credentials has no meson rules; with its C2PA
            # library (fetch-deps.py: pinned, checked by SHA-256)
            cc=$home/$GIMP_REL/content-credentials
            mkdir -p "$cc"
            (cd "$src/plug-ins/content-credentials" && tar -cf - --exclude=__pycache__ .) | tar -xf - -C "$cc"
            chmod 755 "$cc/content-credentials.py"
            python3 -I "$cc/fetch-deps.py" >> "$work/build.log" 2>&1 ||
                { log "$repo: fetch-deps.py failed (log: $work/build.log)"; RELEASE_KEEP=1; return 1; }
            find "$cc" -name __pycache__ -prune -exec rm -rf {} +
        fi

        # a path from the build in a binary breaks once it is moved
        bins=$(find "$home" -type f \( -name '*.so' -o -perm -u+x \) ! -name '*.py')
        bad=0
        for b in $bins; do
            if grep -qaF "$FAKE_HOME" "$b"; then
                if may_keep_path "$b"; then
                    log "$repo: ${b#"$home"/} keeps the build path (only as a fallback)"
                else
                    log "$repo: ${b#"$home"/} keeps the build path $FAKE_HOME"; bad=1
                fi
            fi
        done
        [ "$bad" = 0 ] || { RELEASE_KEEP=1; return 1; }
        # shellcheck disable=SC2086
        NEEDED=$(needed_libs $bins | tr '\n' ' ')

        folders=
        for d in "$home/$GEGL_REL"/* "$home/$GIMP_REL"/*; do
            [ -d "$d" ] || continue
            folders="$folders ${d#"$home"/}"
        done
        asset=$repo-$ver-linux-$ARCH.tar.gz
        FOLDERS=$folders
        for d in $folders; do
            # (not into the database of lensfun:correct)
            case $d in */lensfun-db) continue ;; esac
            copy_licences "$src" "$home/$d"
            third_party "$src" "$home/$d"
            # shellcheck disable=SC2086
            install_txt tar "$repo" "$ver" "$commit" "$asset" $folders > "$home/$d/INSTALL.txt"
        done
        # only the folders of the package, not .config and the others
        # above them, whose permissions tar would change when extracting
        # shellcheck disable=SC2086
        tar --sort=name --owner=0 --group=0 --numeric-owner --mtime="@$when" \
            --mode=u+rwX,go+rX,go-w -C "$home" -cf - $folders | gzip -n -9 > "$out/$asset" || return 1
        assets=$asset
        check_kind=tar
    else
        # shellcheck disable=SC2046 # two words
        set -- $(python_folder "$repo")
        folder=$1 name=$2
        stage=$work/stage
        pdir=$stage/$name
        mkdir -p "$pdir"
        if [ "$repo" = inkscape-xcf-export ]; then
            for f in $INK_FILES; do cp "$src/$f" "$pdir/"; done
        else
            (cd "$src/$folder" && tar -cf - --exclude=__pycache__ .) | tar -xf - -C "$pdir"
            chmod 755 "$pdir/$name.py"
        fi
        NEEDED=
        asset=$repo-$ver.zip
        [ "$repo" != gimp-blender-link ] || asset=$repo-$ver-gimp.zip
        copy_licences "$src" "$pdir"
        install_txt zip "$repo" "$ver" "$commit" "$asset" "$name" > "$pdir/INSTALL.txt"
        chmod -R u+rwX,go+rX,go-w "$stage"
        find "$stage" -exec touch -h -d "@$when" {} +
        (cd "$stage" && find "$name" | LC_ALL=C sort | zip -q -X -@ "$out/$asset") || return 1
        assets=$asset
        check_kind=zip
        if [ "$repo" = gimp-blender-link ]; then
            # the Blender extension and legacy add-on, built by the
            # repository's own tools/build.sh (with Blender, isolated)
            GIMP_PLUGIN_DEVTOOLS=$here sh "$src/tools/build.sh" > "$work/blender.log" 2>&1 ||
                { log "$repo: tools/build.sh failed (log: $work/blender.log)"; RELEASE_KEEP=1; return 1; }
            for z in "gimp_link-$ver.zip" "gimp_link-$ver-legacy-addon.zip"; do
                [ -f "$src/dist/$z" ] || { log "$repo: tools/build.sh made no $z"; return 1; }
                cp "$src/dist/$z" "$out/"
                assets="$assets $z"
            done
        fi
    fi

    check_package "$repo" "$check_kind" "$out/$asset" "$src" "$work" ||
        { log "$repo: CHECK FAILED (work folder: $work)"; RELEASE_KEEP=1; return 1; }
    cp "$work/check.log" "$out/check.log"

    (cd "$out" && sha256sum $assets > SHA256SUMS)
    notes "$repo" "$ver" "$commit" "$src" "$assets" > "$out/RELEASE-NOTES.md"
    echo "$ver $commit" > "$out/VERSION"
    for a in $assets; do
        log "   $a $(du -h "$out/$a" | cut -f1)"
    done
    [ "${RELEASE_KEEP:-0}" = 1 ] && log "   work folder kept: $work" || rm -rf "$work"
}

# the first paragraph of the README after the title, without images, and
# the list right after it if there is one
readme_intro () {
    awk '
        NR == 1 || /^(=+|-+)$/ { next }
        /^#/ { if (started) exit; next }
        /^!\[/ { next }
        /^>/ && !started { next }
        /^ *$/ { if (started) blank = 1; next }
        {
            if (blank) {
                if (/^([-*] |[0-9]+\. )/ || (inlist && /^  /)) { inlist = 1; print "" }
                else exit
                blank = 0
            }
            started = 1
            print
        }
    ' "$1/README.md"
}

# notes <repo> <version> <commit> <source folder> <assets>
notes () {
    repo=$1 ver=$2 commit=$3 src=$4 assets=$5
    url=https://github.com/sandbranch/$repo
    readme_intro "$src"
    case $repo in
        gimp-bimp)
            # the note at the top: which BIMP this is
            echo
            sed -n 's/^> \{0,1\}//p' "$src/README.md" | sed 's/^\*\*\(.*\)\*\*\(.*\)$/\1\2/' ;;
        gimp-lensfun)
            echo
            awk '/^This is the GIMP 3 version/ {p = 1} p && /^ *$/ {exit} p' "$src/README.md"
            echo
            echo "## Changes in $ver"
            echo
            awk -v v="$ver" '$0 == v {p = 1; getline; next} p && /^ *$/ {exit} p' "$src/CHANGES.txt" ;;
    esac
    echo
    echo "## Install"
    echo
    case $assets in
    *.tar.gz*)
        a=${assets%% *}
        echo "Download \`$a\`, extract it into your home folder and restart GIMP:"
        echo
        echo "    tar -xzf $a -C ~"
        echo
        echo "That puts these folders in place (\`INSTALL.txt\` in each says how to"
        echo "uninstall):"
        echo
        for d in $FOLDERS; do echo "- \`~/$d/\`"; done
        echo
        echo "Built on $OS_NAME ($ARCH) against GIMP $GIMP_VERSION and GEGL"
        echo "$GEGL_VERSION, for the native GIMP (not the Flatpak or Snap), and checked"
        echo "only there. On other systems, build from source: see the"
        echo "[README]($url#readme)."
        ;;
    *)
        a=${assets%% *}
        if [ "$repo" = inkscape-xcf-export ]; then
            echo "Download \`$a\` and unpack it into Inkscape's extensions folder, then"
            echo "restart Inkscape:"
            echo
            echo "    mkdir -p ~/$INK_REL"
            echo "    unzip $a -d ~/$INK_REL"
            echo
            echo "Python only, nothing to build. \`INSTALL.txt\` in the folder has the"
            echo "details (the Flatpak's folder, uninstalling)."
        else
            echo "Download \`$a\` and unpack it into GIMP's plug-in folder, then restart"
            echo "GIMP:"
            echo
            echo "    mkdir -p ~/$GIMP_REL"
            echo "    unzip $a -d ~/$GIMP_REL"
            echo
            echo "Python only, nothing to build; GIMP $GIMP_SERIES with its Python support."
            echo "Checked with GIMP $GIMP_VERSION on $OS_NAME. \`INSTALL.txt\` in the folder"
            echo "has the Windows and macOS folders."
        fi
        if [ "$repo" = gimp-blender-link ]; then
            echo
            echo "The Blender side: \`gimp_link-$ver.zip\` is the extension for Blender"
            echo "4.2 and later (Edit > Preferences > Get Extensions > Install from"
            echo "Disk...), \`gimp_link-$ver-legacy-addon.zip\` the legacy add-on. See"
            echo "the [README]($url#install)."
        fi
        ;;
    esac
    echo
    echo "\`SHA256SUMS\` has the checksums. Source: commit ${commit%"${commit#????????????}"}, tag v$ver."
}

cmd_build () {
    [ $# -gt 0 ] || set -- $all
    failed=
    for r; do
        build_one "$r" || failed="$failed $r"
    done
    (cd "$dist" && find . -mindepth 2 -maxdepth 2 \( -name '*.tar.gz' -o -name '*.zip' \) |
       sed 's|^\./||' | LC_ALL=C sort | xargs -r sha256sum > SHA256SUMS)
    if [ -n "$failed" ]; then
        log "FAILED:$failed"
        return 1
    fi
    log "all built and checked; files in $dist"
}

cmd_draft () {
    [ $# -gt 0 ] || die "draft: name the repositories"
    command -v gh >/dev/null 2>&1 || die "gh is not installed"
    failed=
    for repo; do
        out=$dist/$repo
        if [ ! -f "$out/VERSION" ]; then log "$repo: not built (release.sh build $repo)"; failed="$failed $repo"; continue; fi
        read -r ver commit < "$out/VERSION"
        tag=v$ver
        r=$top/$repo
        head=$(git -C "$r" rev-parse HEAD)
        branch=$(git -C "$r" branch --show-current)
        if [ "$head" != "$commit" ]; then
            log "$repo: HEAD is $head, the build is of $commit: build again"; failed="$failed $repo"; continue
        fi
        git -C "$r" fetch -q origin "$branch" &&
          [ "$(git -C "$r" rev-parse "origin/$branch")" = "$head" ] ||
          { log "$repo: HEAD is not pushed to origin/$branch"; failed="$failed $repo"; continue; }
        slug=$(git -C "$r" remote get-url origin | sed -e 's|.*github.com[:/]||' -e 's|\.git$||')
        if gh release view "$tag" -R "$slug" >/dev/null 2>&1; then
            log "$repo: a release $tag exists already; not touched"; failed="$failed $repo"; continue
        fi
        # the tag must be on GitHub already, unless RELEASE_NO_TAG
        target=--verify-tag
        if [ "${RELEASE_NO_TAG:-0}" = 1 ]; then
            target="--target $head"
        else
            if git -C "$r" rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
                [ "$(git -C "$r" rev-parse "$tag^{commit}")" = "$head" ] ||
                    { log "$repo: tag $tag exists on another commit"; failed="$failed $repo"; continue; }
            else
                git -C "$r" tag -a "$tag" -m "$repo $ver" "$head" || { failed="$failed $repo"; continue; }
            fi
            git -C "$r" push -q origin "refs/tags/$tag" || { log "$repo: pushing $tag failed"; failed="$failed $repo"; continue; }
        fi
        files=$(cd "$out" && ls -- *.tar.gz *.zip 2>/dev/null)
        # shellcheck disable=SC2086
        if (cd "$out" && gh release create "$tag" --draft $target -R "$slug" \
              --title "$repo $ver" --notes-file RELEASE-NOTES.md $files SHA256SUMS) ; then
            :
        else
            log "$repo: gh release create failed"; failed="$failed $repo"
        fi
    done
    [ -z "$failed" ] || { log "FAILED:$failed"; return 1; }
}

cmd_list () {
    for r in $all; do
        [ -d "$top/$r/.git" ] || continue
        printf '%-22s %-8s %s\n' "$r" "$(kind "$r")" "$(version "$top/$r")"
    done
}

case $1 in
    build) shift; cmd_build "$@" ;;
    draft) shift; cmd_draft "$@" ;;
    list) cmd_list ;;
    *) echo "usage: $(basename "$0") build [repo...] | draft repo... | list" >&2; exit 2 ;;
esac
