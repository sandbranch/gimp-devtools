#!/bin/sh
# Shared settings for the scripts of gimp-devtools; source it.
#
# GIMP is the native GIMP 3 on the PATH (a distribution package or a PPA,
# with its development files for building plug-ins). The GIMP Flatpak is
# not used: building and testing against the native GIMP is simpler and
# faster, and the plug-ins are built for it.
#
# Sets GIMP_VERSION, GIMP_SERIES, GIMP_CONSOLE (the gimp-console command
# of that series), GIMP_PLUGINDIR and GEGL_OPDIR. Sourcing it never exits
# the shell: if GIMP cannot be found, GIMP_ENV_ERROR says why and the
# scripts stop with it.

# the variables are used by the scripts that source this one
# shellcheck disable=SC2034

GIMP_ENV_ERROR=
GIMP_VERSION=
GIMP_CONSOLE=

if [ -n "${GIMP_FLATPAK:-}" ] && [ "$GIMP_FLATPAK" != 0 ]; then
    GIMP_ENV_ERROR="GIMP_FLATPAK=$GIMP_FLATPAK: the GIMP Flatpak is no longer supported by gimp-devtools, only the native GIMP"
fi

if [ -z "$GIMP_ENV_ERROR" ]; then
    for gimp_cmd in gimp-console-3.4 gimp-console-3.2 gimp-console-3.0 gimp-console gimp; do
        if command -v "$gimp_cmd" >/dev/null 2>&1; then
            GIMP_VERSION=$(LC_ALL=C "$gimp_cmd" --version 2>/dev/null |
                sed -n 's/.* \([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9.]*\).*/\1/p' | head -n 1)
            if [ -n "$GIMP_VERSION" ]; then
                GIMP_CONSOLE=$gimp_cmd
                break
            fi
        fi
    done
    unset gimp_cmd
    [ -n "$GIMP_VERSION" ] ||
        GIMP_ENV_ERROR="no GIMP found: no gimp-console or gimp on the PATH; install GIMP 3 with its development files, e.g.
    sudo apt install gimp libgimp-3.0-dev"
fi

# the series, which names the profile folder: 3.2.8 -> 3.2
GIMP_SERIES=$(echo "$GIMP_VERSION" | cut -d. -f1,2)

case $GIMP_SERIES in
    [012].*) [ -n "$GIMP_ENV_ERROR" ] ||
        GIMP_ENV_ERROR="GIMP $GIMP_VERSION found, but these scripts are for GIMP 3" ;;
esac

# the user's folder for GIMP plug-ins. GIMP3_DIRECTORY moves the whole
# profile, relative to the home folder unless it is an absolute path.
case $GIMP3_DIRECTORY in
    '') GIMP_PLUGINDIR="${XDG_CONFIG_HOME:-$HOME/.config}/GIMP/$GIMP_SERIES/plug-ins" ;;
    /*) GIMP_PLUGINDIR="$GIMP3_DIRECTORY/plug-ins" ;;
    *) GIMP_PLUGINDIR="$HOME/$GIMP3_DIRECTORY/plug-ins" ;;
esac

# the user's folder for GEGL operations, which GIMP loads at start
GEGL_OPDIR="${XDG_DATA_HOME:-$HOME/.local/share}/gegl-0.4/plug-ins"

die () {
    echo "$(basename "$0"): $*" >&2
    exit 1
}
