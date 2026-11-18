#!/bin/sh
# Builds the sandbranch GIMP plug-ins and GEGL filters natively from the
# repositories next to gimp-devtools and installs them into your own GIMP:
# GEGL operations into ~/.local/share/gegl-0.4/plug-ins, plug-ins into
# ~/.config/GIMP/3.2/plug-ins (the folders gimp-env.sh finds).
#
#   install-all.sh              all repositories below that are there
#   install-all.sh repo...      only those (e.g. gegl-lut gimp-fusion)
#
# Each meson repository is configured afresh in its build-install folder
# (not touching the build folders of its tests). Python plug-ins are
# copied file by file over the installed folder, so files that are not in
# the repository (e.g. content-credentials/vendor, the downloaded C2PA
# library) stay. Restart GIMP afterwards. Prints one line per repository
# and exits non-zero if any failed.
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
top=$(dirname "$here")
. "$here/gimp-env.sh"
[ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"

failed=0
log_dir=${TMPDIR:-/tmp}/install-all.$$
mkdir -p "$log_dir"

# meson <repo> <meson options...>: a fresh native build, installed
meson_install () {
    repo=$1; shift
    (
        cd "$top/$repo" || exit 1
        rm -rf build-install
        meson setup build-install "$@" &&
            ninja -C build-install install
    ) >"$log_dir/$repo.log" 2>&1
}

# python <source folder> <plug-in name>: copy the plug-in's files
python_install () {
    srcdir=$1 name=$2
    dest=$GIMP_PLUGINDIR/$name
    mkdir -p "$dest" || return 1
    (cd "$srcdir" && find . -type f ! -path '*/__pycache__/*' ! -name '*.pyc') |
      while read -r f; do
          mkdir -p "$dest/$(dirname "$f")" && cp "$srcdir/$f" "$dest/$f" || exit 1
      done || return 1
    chmod 755 "$dest/$name.py"
}

install_one () {
    case $1 in
        gegl-adjustments|gimp-forensics|gimp-pixel-scale)
            meson_install "$1" -Dmoduledir="$GEGL_OPDIR" -Dplugindir="$GIMP_PLUGINDIR" ;;
        gegl-lut|gegl-control-points|gegl-depth-blur|gegl-equalizers|gegl-underwater|gegl-presence|gegl-wavelet)
            meson_install "$1" -Dmoduledir="$GEGL_OPDIR" ;;
        gimp-bimp|gimp-fusion|gimp-lqr-tng)
            meson_install "$1" -Dplugindir="$GIMP_PLUGINDIR" ;;
        gimp-lensfun)
            # keep the installed lens database (a copy: the install
            # replaces the folder it comes from)
            db=
            if [ -d "$GIMP_PLUGINDIR/gimp-lensfun/lensfun-db" ]; then
                db=$log_dir/lensfun-db
                cp -r "$GIMP_PLUGINDIR/gimp-lensfun/lensfun-db" "$db"
            fi
            meson_install "$1" -Dplugindir="$GIMP_PLUGINDIR" -Dmoduledir="$GEGL_OPDIR" \
              -Dgegl_op=enabled ${db:+-Dlensfun_db="$db"} ;;
        gimp-forensics-python)
            # content-credentials has no meson rules: copied
            python_install "$top/gimp-forensics/plug-ins/content-credentials" content-credentials ;;
        gimp-layerfx) python_install "$top/$1/layerfx" layerfx ;;
        gimp-save-for-web) python_install "$top/$1/save-for-web" save-for-web ;;
        gimp-tileset-export) python_install "$top/$1/tileset-export" tileset-export ;;
        gimp-uv-tools) python_install "$top/$1/uv-tools" uv-tools ;;
        gimp-blender-link) python_install "$top/$1/gimp/gimp-blender-link" gimp-blender-link ;;
        *) echo "unknown: $1" >&2; return 1 ;;
    esac
}

all="gegl-adjustments gegl-lut gegl-control-points gegl-depth-blur gegl-equalizers
gegl-underwater gegl-presence gegl-wavelet gimp-forensics gimp-forensics-python
gimp-pixel-scale gimp-lensfun gimp-bimp gimp-fusion gimp-lqr-tng gimp-layerfx
gimp-save-for-web gimp-tileset-export gimp-uv-tools gimp-blender-link"
[ $# -gt 0 ] || set -- $all

for r; do
    case $r in gimp-forensics-python) d=gimp-forensics ;; *) d=$r ;; esac
    if [ ! -d "$top/$d" ]; then
        echo "SKIP $r (not next to gimp-devtools)"
        continue
    fi
    if install_one "$r"; then
        echo "OK   $r"
    else
        echo "FAIL $r (log: $log_dir/$r.log)"
        failed=$((failed + 1))
    fi
done
echo "installed into $GEGL_OPDIR and $GIMP_PLUGINDIR; restart GIMP"
[ "$failed" = 0 ]
