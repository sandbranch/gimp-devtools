#!/bin/sh
# Checks that the sandbranch filters and plug-ins installed in your own
# GIMP (install-all.sh) register: starts the native GIMP without a window,
# isolated from your profile (a throwaway home and GIMP3_DIRECTORY), with
# your GEGL operations and plug-in folders added, and asks GEGL for every
# operation and the PDB for every procedure listed below.
#
#   check-installed.sh
#
# Prints PASS or FAIL per name and exits non-zero if any is missing.
#
# Copyright 2026 David
# SPDX-License-Identifier: GPL-3.0-or-later

here=$(CDPATH='' cd -- "$(dirname "$0")" && pwd)
. "$here/gimp-env.sh"
[ -z "$GIMP_ENV_ERROR" ] || die "$GIMP_ENV_ERROR"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-installed.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/profile"
printf '(plug-in-path "%s:${gimp_plug_in_dir}/plug-ins")\n' "$GIMP_PLUGINDIR" > "$tmp/profile/gimprc"
# GEGL_PATH replaces GEGL's own folders: give both
gegl_ops="$GEGL_OPDIR:$(pkg-config --variable=pluginsdir gegl-0.4)"

cat > "$tmp/check.py" <<'EOF'
import gi
gi.require_version('Gegl', '0.4')
from gi.repository import Gegl, Gimp
Gegl.init(None)  # a plug-in initialises GEGL itself
ops = '''adj:selective-color adj:black-and-white adj:blend-if adj:luminosity-mask
lut:color-lookup control-points:adjust depth:blur
equalizer:saturation equalizer:sharpness
underwater:correct underwater:marine-snow
presence:clarity presence:texture presence:dehaze presence:whites-blacks
wavelet:sharpen wavelet:denoise lensfun:correct pixel-art:scale pixel-art:rescale
forensics:error-level forensics:jpeg-ghost forensics:noise forensics:wavelet-noise
forensics:minmax forensics:bit-plane forensics:echo forensics:luminance-gradient
forensics:clone-detect forensics:median-detect forensics:resampling forensics:pca'''.split()
known = set(Gegl.list_operations())
fails = 0
for op in ops:
    ok = op in known
    fails += not ok
    print('%s operation %s' % ('PASS' if ok else 'FAIL', op))
pdb = Gimp.get_pdb()
procs = set(pdb.query_procedures('.*', '', '', '', '', '', '', ''))
for words in ['bimp', 'fusion', 'lensfun', 'lqr', 'layerfx', 'save-for-web',
              'tileset', 'uv', 'blender', 'forensics', 'jpeg-info',
              'content-credentials', 'luminosity', 'pixel-art', 'gegl-nodes']:
    hits = sorted(p for p in procs if words in p)
    fails += not hits
    print('%s procedure *%s*: %s' % ('PASS' if hits else 'FAIL', words, ' '.join(hits)))
print('RESULT %d missing' % fails)
EOF

GIMP_RUN_HOME=$tmp/home "$here/gimp-run.sh" --env=GIMP3_DIRECTORY="$tmp/profile" \
  --env=GEGL_PATH="$gegl_ops" -- \
  "$GIMP_CONSOLE" --no-interface --no-data --no-fonts \
  --batch-interpreter python-fu-eval -b "exec(open('$tmp/check.py').read())" --quit \
  > "$tmp/gimp.log" 2>&1
grep -E '^(PASS|FAIL|RESULT)' "$tmp/gimp.log"
grep -q '^RESULT 0 missing' "$tmp/gimp.log" || { grep -i -E 'error|warning|traceback' "$tmp/gimp.log" | head -20; exit 1; }
