# Interlink test scripts (prototypes)

The headless probes behind [../interlinks.md](../interlinks.md), as they
were run on 2026-09-27: GIMP scripts (`gimp_*.py`) run with
`gimp-console-3.2 ... --batch-interpreter python-fu-eval` and a throwaway
`GIMP3_DIRECTORY`; Blender scripts (`load.py`, `probe.py`, `reload.py`,
`uv.py`) with `blender -b --factory-startup --python` and a throwaway
`BLENDER_USER_CONFIG`. They still use the scratch paths under
`/tmp/claude-1000/interlink/` they were written with; they are the start
of the test harness for a GIMP and Blender link, not a finished suite.
