#!/bin/sh
# Runs the full test suite of every sandbranch repository next to
# gimp-devtools, one repository after another (the GUI tests share ports
# and must not run at the same time), against the native GIMP. Each step
# is a test script of that repository, run from its folder; the log of
# each step is kept.
#
#   test-all.sh                 all repositories below that are there
#   test-all.sh repo...         only those
#   TEST_ALL_LOGS=dir           where the logs go (default: a new folder
#                               in $TMPDIR)
#
# Prints one line per step (PASS or FAIL, with its log) and a summary,
# and exits non-zero if any step failed. Some checks compare against the
# gegl command line tool (on Debian and Ubuntu the package gegl).
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
top=$(dirname "$here")
logs=${TEST_ALL_LOGS:-$(mktemp -d "${TMPDIR:-/tmp}/test-all.XXXXXX")}
mkdir -p "$logs" || exit 1

# the steps of each repository, in order (paths below tests/)
steps () {
    case $1 in
        gegl-adjustments) echo check.sh crosscheck.sh gimp-check.sh gui/shots.sh ;;
        gegl-astro) echo check.sh gimp-check.sh gui/look.sh gui/dialogs.sh ;;
        gegl-control-points) echo check.sh gimp-check.sh gui/shots.sh ;;
        gegl-depth-blur) echo run.sh gimp-test.sh ;;
        gegl-equalizers) echo check.sh orig-check.sh gimp-check.sh gui/shots.sh ;;
        gegl-lut) echo check.sh crosscheck.sh gimp-check.sh ;;
        gegl-photo-restore) echo check.sh gimp-check.sh gui/shots.sh ;;
        gegl-presence) echo check.sh gimp-check.sh gui/shots.sh ;;
        gegl-underwater) echo check.sh gimp-check.sh gimp-test.sh ;;
        gimp-forensics) echo run-all.sh ;;
        gimp-lqr-tng) echo run.sh gui/gui-test.sh ;;
        gegl-wavelet|gimp-auto-perspective|gimp-bimp|gimp-blender-link|gimp-fusion|\
        gimp-layerfx|gimp-lensfun|gimp-lqr|gimp-pixel-scale|\
        gimp-save-for-web|gimp-tileset-export|gimp-uv-tools|gimp-wavelet-denoise|\
        gimp-wavelet-sharpen|inkscape-xcf-export) echo run.sh ;;
        *) return 1 ;;
    esac
}

all="gegl-adjustments gegl-astro gegl-control-points gegl-depth-blur
gegl-equalizers gegl-lut gegl-photo-restore gegl-presence gegl-underwater
gegl-wavelet gimp-auto-perspective gimp-bimp gimp-blender-link gimp-forensics
gimp-fusion gimp-layerfx gimp-lensfun gimp-lqr gimp-lqr-tng
gimp-pixel-scale gimp-save-for-web gimp-tileset-export gimp-uv-tools
gimp-wavelet-denoise gimp-wavelet-sharpen inkscape-xcf-export"
[ $# -gt 0 ] || set -- $all

passed=0 failed=0 failures=
for repo; do
    if [ ! -d "$top/$repo/tests" ]; then
        echo "SKIP $repo (not next to gimp-devtools)"
        continue
    fi
    list=$(steps "$repo") || { echo "SKIP $repo (no steps known)"; continue; }
    for step in $list; do
        log="$logs/$repo--$(echo "$step" | tr / -).log"
        if (cd "$top/$repo" && "tests/$step") >"$log" 2>&1; then
            echo "PASS $repo tests/$step"
            passed=$((passed + 1))
        else
            echo "FAIL $repo tests/$step (log: $log)"
            failed=$((failed + 1))
            failures="$failures $repo:$step"
        fi
    done
done
echo "$passed steps passed, $failed failed (logs in $logs)"
[ -z "$failures" ] || echo "failed:$failures"
[ "$failed" = 0 ]
