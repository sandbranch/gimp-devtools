#!/bin/sh
# Run a build command for a GIMP plug-in in the given source folder, against
# the native GIMP 3 (its development files, found with pkg-config).
#
#   gimp-build.sh <source folder> <command...>
#   gimp-build.sh --env      # print the settings found, build nothing
#
# e.g.
#   gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
#   gimp-build.sh . ninja -C build install
#   gimp-build.sh . 'meson setup build && ninja -C build install'
#
# $GIMP_PLUGINDIR and $GEGL_OPDIR are the user's folders for plug-ins and
# GEGL operations; escape the $ so that they are expanded in the build
# environment. Each argument of the command stays one word, spaces and all;
# a command given as a single argument is run as a shell command line.
#
# With GIMP_RUN_HOME set to a throwaway folder, the command runs isolated
# from the user's folders, as with gimp-run.sh: HOME and the XDG folders
# there, no GVFS. For tests, so that a build and the checks it runs leave
# nothing in the user's folders (ccache, GEGL's swap, GIO's metadata).
# $GIMP_PLUGINDIR and $GEGL_OPDIR are still the user's folders.

usage="usage: $(basename "$0") <source folder> <command...>
       $(basename "$0") --env"

case $1 in
    -h|--help) echo "$usage"; exit 0 ;;
esac

. "$(dirname "$0")/gimp-env.sh"

if [ "$1" = --env ]; then
    echo "GIMP_VERSION=$GIMP_VERSION"
    echo "GIMP_CONSOLE=$GIMP_CONSOLE"
    echo "GIMP_PLUGINDIR=$GIMP_PLUGINDIR"
    echo "GEGL_OPDIR=$GEGL_OPDIR"
    [ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"
    exit 0
fi

[ $# -ge 2 ] || die "$usage"
[ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"
dir=$(CDPATH='' cd -- "$1" && pwd) || die "no folder $1"
shift

# the command line for sh -c: a single argument as it is, otherwise each
# argument in double quotes, so that it stays one word but $VARIABLES in it
# are still expanded
if [ $# = 1 ]; then
    cmd=$1
else
    cmd=
    for arg; do
        arg=$(printf '%s\n' "$arg" | sed 's/[\\"`]/\\&/g')
        cmd="$cmd \"$arg\""
    done
    cmd=${cmd# }
fi

# (the command runs in the source folder: $0 of this shell)
# shellcheck disable=SC2016
in_dir='cd "$0" && sh -c "$1"'

if [ -n "$GIMP_RUN_HOME" ]; then
    exec "$(dirname "$0")/gimp-run.sh" --home="$GIMP_RUN_HOME" \
        --env=GIMP_PLUGINDIR="$GIMP_PLUGINDIR" --env=GEGL_OPDIR="$GEGL_OPDIR" \
        -- sh -c "$in_dir" "$dir" "$cmd"
fi
cd "$dir" || die "cannot enter $dir"
GIMP_PLUGINDIR=$GIMP_PLUGINDIR GEGL_OPDIR=$GEGL_OPDIR exec sh -c "$cmd"
