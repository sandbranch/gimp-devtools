#!/bin/sh
# Runs a command in the Flatpak of GIMP (or of another app, such as
# Blender or Godot) isolated from the user's own folders: HOME, the XDG
# folders (config, data, cache, state) and GIO's file metadata all point
# into a throwaway home, so that a test leaves nothing in
# ~/.var/app/<app>, ~/.config/GIMP and the like. Natively
# (GIMP_FLATPAK=0, or --native) the command gets the same environment.
#
#   gimp-run.sh [options] [--] <command> [arguments...]
#
# e.g.
#   gimp-run.sh --home="$out/home" --env=GIMP3_DIRECTORY="$out/profile" \
#     --filesystem="$src" -- gimp-console-3.2 --no-interface -b ... --quit
#
# Options (also as two words: --home DIR):
#   --home=DIR        the throwaway home, created if missing; default
#                     $GIMP_RUN_HOME. Required. Keep it under your home
#                     folder or /tmp, which the Flatpak can see.
#   --env=VAR=VALUE   set VAR for the command (repeatable); unlike
#                     flatpak run --env, also XDG_* variables
#   --filesystem=DIR  let the Flatpak see DIR (repeatable; natively
#                     ignored); DIR:ro for read only
#   --devel           run with the SDK (flatpak run --devel), e.g. for
#                     the sanitizer runtimes
#   --app=ID          the Flatpak: $GIMP_APP_ID (org.gimp.GIMP) by default
#   --flatpak, --native
#                     run in the Flatpak, or natively. By default, for
#                     GIMP as GIMP_FLATPAK says (0 native, 1 Flatpak,
#                     unset the Flatpak if it is installed); for another
#                     app the Flatpak if it is installed
#
# Why each part is needed: the Flatpak sets the XDG_* variables itself,
# after flatpak run --env, so they are set inside the sandbox by a shell
# that then runs the command. flatpak run gets the throwaway home too (see
# below), so that it keeps nothing in ~/.var/app/<app> either. GIO_USE_VFS=local keeps GIO from writing its
# metadata journal (~/.var/app/<app>/data/gvfs-metadata) through GVFS.
# --no-documents-portal keeps files from being registered with the
# document portal. The exit code is that of the command.
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

usage="usage: $(basename "$0") [--home=DIR] [--env=VAR=VALUE]... [--filesystem=DIR]...
       [--devel] [--app=ID] [--flatpak | --native] [--] <command> [arguments...]"

die () {
    echo "$(basename "$0"): $*" >&2
    exit 2
}

# quotes a word for eval
q () {
    printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

home=$GIMP_RUN_HOME
app=${GIMP_APP_ID:-org.gimp.GIMP}
app_given=
mode=
devel=
fs=
envs=
while [ $# -gt 0 ]; do
    opt=$1
    case $opt in
        --home|--env|--filesystem|--app)
            [ $# -ge 2 ] || die "$opt needs a value"
            shift
            opt="$opt=$1" ;;
    esac
    case $opt in
        -h|--help) echo "$usage"; exit 0 ;;
        --home=*) home=${opt#--home=} ;;
        --env=*=*) envs="$envs $(q "${opt#--env=}")" ;;
        --env=*) die "--env needs VAR=VALUE, not ${opt#--env=}" ;;
        --filesystem=?*) fs="$fs $(q "$opt")" ;;
        --app=?*) app=${opt#--app=}; app_given=1 ;;
        --devel) devel=--devel ;;
        --flatpak) mode=flatpak ;;
        --native) mode=native ;;
        --) shift; break ;;
        -*) die "unknown option $opt
$usage" ;;
        *) break ;;
    esac
    shift
done
[ $# -gt 0 ] || die "no command given
$usage"
[ -n "$home" ] || die "no throwaway home: give --home=DIR or set GIMP_RUN_HOME"

mkdir -p "$home" || die "cannot create $home"
home=$(CDPATH='' cd -- "$home" && pwd) || die "cannot enter $home"
# the user's own home is not a throwaway one
real_home=$(CDPATH='' cd -- "$HOME" 2>/dev/null && pwd)
[ "$home" != "$real_home" ] && [ "$home" != / ] || die "$home is not a throwaway home"

if [ -z "$mode" ]; then
    if [ -z "$app_given" ] || [ "$app" = "${GIMP_APP_ID:-org.gimp.GIMP}" ]; then
        case $GIMP_FLATPAK in
            1) mode=flatpak ;;
            0) mode=native ;;
            '') ;;
            *) die "GIMP_FLATPAK must be 0 (native GIMP), 1 (the Flatpak) or unset (either), not '$GIMP_FLATPAK'" ;;
        esac
    fi
    if [ -z "$mode" ]; then
        if command -v flatpak >/dev/null 2>&1 && flatpak info "$app" >/dev/null 2>&1; then
            mode=flatpak
        else
            mode=native
        fi
    fi
fi

# the shell that sets up the environment and runs the command; its
# arguments: the home, the VAR=VALUE settings, --, the command
# shellcheck disable=SC2016 # expanded by that shell
inner='h=$1; shift
export GIO_USE_VFS=local HOME="$h" XDG_CONFIG_HOME="$h/.config" XDG_DATA_HOME="$h/.local/share" XDG_CACHE_HOME="$h/.cache" XDG_STATE_HOME="$h/.local/state"
while [ "$1" != -- ]; do export "$1"; shift; done
shift
exec "$@"'

if [ "$mode" = native ]; then
    eval "exec sh -c $(q "$inner") sh $(q "$home") $envs -- \"\$@\""
fi
command -v flatpak >/dev/null 2>&1 || die "flatpak is not installed"
# flatpak run itself, outside the sandbox, keeps files of the app under
# HOME too (~/.var/app/<app>/.ld.so, a cache of the libraries, which
# changes between runs with and without --devel) and maps
# xdg-config/... of the app's permissions to the XDG folders: it gets the
# throwaway home as well, and the user's own installation of Flatpaks
# (FLATPAK_USER_DIR), for runtimes such as the SDK installed there
FLATPAK_USER_DIR=${FLATPAK_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/flatpak}
HOME=$home XDG_CONFIG_HOME=$home/.config XDG_DATA_HOME=$home/.local/share \
    XDG_CACHE_HOME=$home/.cache XDG_STATE_HOME=$home/.local/state
export FLATPAK_USER_DIR HOME XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
eval "exec flatpak run $devel --no-documents-portal $(q "--filesystem=$home") $fs \
    --command=sh $(q "$app") -c $(q "$inner") sh $(q "$home") $envs -- \"\$@\""
