# gimp-devtools

Scripts for building and testing GIMP 3 plug-ins and GEGL operations
against the native GIMP 3, used for the plug-ins under
[github.com/sandbranch](https://github.com/sandbranch).

Where that work stands and what comes next: [STATUS.md](STATUS.md).

## What you need

- A POSIX shell (the scripts are `/bin/sh`, tested with dash, bash and
  BusyBox).
- A native GIMP 3 with its development files (`gimp-console-3.x` or
  `gimp` on the `PATH`, plus a compiler, meson and ninja), e.g. on Debian
  and Ubuntu:

      sudo apt install gimp libgimp-3.0-dev meson ninja-build

  The GIMP Flatpak is not supported: we build and test against the native
  GIMP, which is simpler and faster (no SDK, no sandbox), and the plug-ins
  are built for it. `GIMP_FLATPAK=1` is refused.
- For `gui/cdp.mjs`: node 22 or later and Google Chrome or Chromium.

## gimp-build.sh

Runs a build command in a source folder against the native GIMP:

    gimp-build.sh <source folder> <command...>
    gimp-build.sh --env        # print what it found, build nothing

It checks that a GIMP 3 is there and runs the command in the folder. The
exit code is that of the command.

Two variables are set for the command; escape the `$` so that they are
expanded there:

- `$GIMP_PLUGINDIR`: the user's plug-in folder, e.g.
  `~/.config/GIMP/3.2/plug-ins`; under
  `$XDG_CONFIG_HOME` if that is set, or `$GIMP3_DIRECTORY/plug-ins` if that
  is set, as GIMP itself does
- `$GEGL_OPDIR`: the user's folder for GEGL operations,
  `~/.local/share/gegl-0.4/plug-ins` (under `$XDG_DATA_HOME` if that is
  set), which GIMP loads at start

Examples, from a plug-in's source folder:

    gimp-build.sh . meson setup build -Dplugindir=\$GIMP_PLUGINDIR
    gimp-build.sh . ninja -C build install

    # a GEGL operation
    gimp-build.sh . meson setup build -Dmoduledir=\$GEGL_OPDIR

Each argument of the command stays one word, so paths with spaces work
(`gimp-build.sh "$src" meson setup "$out/build"`). A command given as a
single argument is run as a shell command line, for `&&`, pipes or
redirections:

    gimp-build.sh . 'meson setup build && ninja -C build install'

`gimp-build.sh --env` also prints `GIMP_VERSION` and `GIMP_CONSOLE`, the
`gimp-console-3.x` command found.

## gimp-run.sh

Runs a command isolated from your own folders, for tests: GIMP natively,
or another app (Blender, Godot, Krita) in its Flatpak if it is installed
that way:

    gimp-run.sh --home="$out/home" --env=GIMP3_DIRECTORY="$out/profile" -- \
      gimp-console-3.2 --no-interface --batch-interpreter python-fu-eval -b ... --quit

A throwaway GIMP3_DIRECTORY is not enough: GIMP, GEGL and GTK also write
into your other folders (GIO's file metadata journal, babl's cache, the
ccache of builds). So `gimp-run.sh` sets HOME and `XDG_CONFIG_HOME`,
`XDG_DATA_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME` to the throwaway
home, and `GIO_USE_VFS=local` (no GVFS), and then runs the command.

For an app in a Flatpak, `flatpak run --env=XDG_...=` does not help,
because the Flatpak sets the XDG variables itself after `--env`: there
`gimp-run.sh` starts a shell inside the Flatpak that sets them, and runs
it with `--no-documents-portal`. `flatpak run` itself gets the throwaway
home as HOME too, as it keeps a cache of the libraries in
`~/.var/app/<app>/.ld.so` (your own Flatpak installation stays in use
through `FLATPAK_USER_DIR`).

Options (also as two words, `--home DIR`):

- `--home=DIR`: the throwaway home, created if it is missing; by default
  `$GIMP_RUN_HOME`. Required. Your own home folder is refused.
- `--env=VAR=VALUE`: a variable for the command; `XDG_*` variables work
  too
- `--app=ID`: another app, e.g. `org.godotengine.Godot` or
  `org.kde.krita`: run in its Flatpak if that is installed, otherwise
  natively. Without it the command is GIMP's, run natively.
- `--native`: run the other app natively even if its Flatpak is there
- `--flatpak`: run the other app in its Flatpak (refused for GIMP)
- `--filesystem=DIR`: a folder the Flatpak may see (`DIR:ro` read only);
  ignored natively
- `--devel`: run the Flatpak with its SDK; ignored natively

Each argument of the command stays one word. The exit code is that of the
command. For an app in a Flatpak, keep the throwaway home under your home
folder or `/tmp`.

`gimp-build.sh` runs isolated the same way when `GIMP_RUN_HOME` is set
(tests set it, so that a build and the checks it runs leave nothing in
your folders either).

## snapshot.sh

Lists your own folders of GIMP, Blender, Godot, Krita and Tiled, native and
Flatpak (`~/.config/GIMP`, `~/.local/share/gegl-0.4`, `~/.cache/gimp`,
`~/.cache/babl`,
`~/.var/app/org.blender.Blender`, `~/.var/app/org.godotengine.Godot`,
`~/.var/app/org.kde.krita`, `~/.config/tiled` and others; `snapshot.sh
--dirs` prints them all): every file and folder with its type, size and
modification time. Only names, sizes and times are read, never contents.

    snapshot.sh > before.txt
    ... run the tests ...
    snapshot.sh --compare before.txt   # exit 1 and the differences if anything changed

Nothing is ignored. A GIMP of yours that runs meanwhile changes these
folders too, so close it during tests.

## isolate.sh

The piece each plug-in repository copies into its `tests/` (as
`tests/isolate.sh`) and sources: `gimp_run [--timeout=SECONDS] ... --
<command>` runs the command through `gimp-run.sh`, and `snapshot_take` and
`snapshot_check` wrap `snapshot.sh`. Without gimp-devtools next to
the repository (or at `$GIMP_PLUGIN_DEVTOOLS`) `gimp_run` does the same
isolation itself, so the tests still run, and the snapshot check is
skipped. Keep the copies the same as this file.

## gimp-env.sh

Shared settings for the scripts, sourced by them: the native GIMP's
version and `gimp-console` command, and the two folders above. Sourcing it never
exits your shell; if no GIMP 3 is found, `$GIMP_ENV_ERROR` says why.

## gui/cdp.mjs

Drives a page in a headless Chrome over the DevTools protocol: navigate,
click, type, press keys and take screenshots. With GTK's Broadway backend
GIMP draws into a web page, so dialogs can be tested and screenshotted
without a display:

    # GIMP on a Broadway display, running a Python script (e.g. one that
    # opens an image and a plug-in dialog), isolated from your folders;
    # broadwayd stops with GIMP
    gimp-run.sh --home="$HOME/gimp-test-home" \
      --env=GDK_BACKEND=broadway --env=BROADWAY_DISPLAY=:5 -- sh -c \
      "broadwayd --port 8085 :5 & bw=\$!; sleep 2; gimp-3.2 --no-splash \
       --batch-interpreter python-fu-eval -b \"exec(open('script.py').read())\"; \
       kill \$bw" &

    # a headless Chrome to look at it
    google-chrome --headless=new --remote-debugging-port=9333 \
      --user-data-dir=/tmp/cdp-chrome --password-store=basic about:blank &

    node gui/cdp.mjs size:1600,1000 nav:http://127.0.0.1:8085/ wait:6000 shot:dialog.png
    node gui/cdp.mjs click:552,691 wait:2000 shot:after.png

    kill %2    # the Chrome, when done; GIMP quits when you close it

`gimp-3.2` is the native GIMP; `gimp-build.sh --env` shows the version. Without `--password-store=basic` a new Chrome can wait some 25
seconds for a keyring on its first page load, longer than a short `wait:`.

Actions:

- `nav:url`, `size:w,h` (of the page), `wait:ms`, `shot:file.png`
- `click:x,y`, `down:x,y` and `up:x,y` (press and hold, release),
  `move:x,y`
- `key:Name`: Enter, Tab, Escape, Backspace, Delete, Insert, Home, End,
  PageUp, PageDown, Left, Right, Up, Down, F1 to F12, Space, or a single
  character
- `text:abc`: types the text; a newline is Enter, a tab is Tab
- `eval:expression`: prints the value of a JavaScript expression in the
  page

All actions are checked before any is run; an unknown one is an error.
Settings, from the environment: `CDP_PORT`, the Chrome's debugging port
(9333); `CDP_TIMEOUT`, how long to wait for Chrome to answer, in ms
(30000).

Close a running GIMP of yours first: a second GIMP hands its work over to
the running one.

## Tests

    tests/run.sh

Checks the scripts with shellcheck, `gimp-build.sh`, `gimp-env.sh`,
`gimp-run.sh` and `isolate.sh` against a fake native GIMP and a fake
`flatpak` in a throwaway HOME (native GIMP 3, GIMP 2, no GIMP, a GIMP
Flatpak that must be ignored, `GIMP_FLATPAK=1` refused, paths with spaces,
the isolated environment natively and for another app in its Flatpak,
`isolate.sh` with and without gimp-devtools), `snapshot.sh` on a folder of
its own, the key events of `cdp.mjs`, `cdp.mjs` against a headless Chrome,
and typing into a GTK text field on Broadway (natively, through
`gimp-run.sh`). What is not installed (shellcheck, node 22, Chrome,
broadwayd) is skipped. Needs no network and touches nothing outside a temporary folder:
a snapshot of your folders of GIMP and the other apps before and after
checks that.

## License

GPL version 3 or later.
