#!/bin/sh
# Lists the user's own folders of GIMP, Blender, Godot, Krita and Tiled
# (native and Flatpak): every file and folder with its type, size and
# modification time, or "absent" for a folder that is not there. A test
# takes one listing before and one after and compares them, to prove that
# it changed nothing of the user's.
#
#   snapshot.sh                    print the listing
#   snapshot.sh > before.txt       ... run the tests ...
#   snapshot.sh --compare before.txt
#                                  exit 0 if nothing changed, otherwise
#                                  print the differences and exit 1
#   snapshot.sh --dirs             print only the folders it looks at
#
# Only names, sizes and times are read, never the contents of the files.
# Nothing is ignored: any change counts. SNAPSHOT_HOME lists another
# folder than $HOME (for the tests of this script).
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

h=${SNAPSHOT_HOME:-$HOME}

folders () {
    for d in \
        .config/GIMP \
        .var/app/org.gimp.GIMP \
        .var/app/org.blender.Blender \
        .config/blender \
        .cache/blender \
        .var/app/org.godotengine.Godot \
        .config/godot \
        .local/share/godot \
        .cache/godot \
        .var/app/org.kde.krita \
        .config/kritarc \
        .config/kritadisplayrc \
        .local/share/krita \
        .var/app/org.mapeditor.Tiled \
        .config/tiled \
        .local/share/tiled \
        .cache/tiled
    do
        printf '%s\n' "$h/$d"
    done
}

listing () {
    folders | while IFS= read -r dir; do
        if [ -e "$dir" ] || [ -L "$dir" ]; then
            find "$dir" -printf '%y %s %T@ %p\n' 2>/dev/null | LC_ALL=C sort -k4
        else
            echo "absent $dir"
        fi
    done
}

case $1 in
    '') listing ;;
    --dirs) folders ;;
    --compare)
        [ -f "$2" ] || { echo "snapshot.sh: no listing $2" >&2; exit 2; }
        now=$(listing)
        if printf '%s\n' "$now" | cmp -s "$2" -; then
            exit 0
        fi
        printf '%s\n' "$now" | diff "$2" -
        exit 1 ;;
    -h|--help)
        sed -n '2,17s/^# \{0,1\}//p' "$0" ;;
    *) echo "usage: snapshot.sh [--compare <listing> | --dirs]" >&2; exit 2 ;;
esac
