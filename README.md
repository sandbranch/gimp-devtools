# gimp-devtools

Scripts for building and testing GIMP 3 plug-ins and GEGL operations,
especially against the Flatpak version of GIMP, used for the plug-ins under
[github.com/sandbranch](https://github.com/sandbranch).

Where that work stands and what comes next: [STATUS.md](STATUS.md).

## What you need

- A POSIX shell (the scripts are `/bin/sh`, tested with dash, bash and
  BusyBox).
- Either the Flatpak GIMP and the GNOME SDK it was built with:

      flatpak install flathub org.gimp.GIMP
      gimp-build.sh --env        # shows GIMP_SDK, e.g. org.gnome.Sdk/x86_64/50
      flatpak install flathub org.gnome.Sdk//50

  (`gimp-build.sh` tells you the exact command if the SDK is missing), or a
  native GIMP 3 with its development files (`gimp-console` or `gimp` on the
  `PATH`, plus a compiler, meson and ninja).
- For `gui/cdp.mjs`: node 22 or later and Google Chrome or Chromium.

## gimp-build.sh

Runs a build command in a source folder against the GIMP that will run the
result:

    gimp-build.sh <source folder> <command...>
    gimp-build.sh --env        # print what it found, build nothing

With the Flatpak `org.gimp.GIMP` the command runs inside the Flatpak with
the GNOME SDK that GIMP was built with, so the result links against the
libraries of the Flatpak. The script reads the SDK from
`flatpak info org.gimp.GIMP` and tells you how to install it if it is
missing. Without the Flatpak (or with `GIMP_FLATPAK=0`) the command runs
natively. The exit code is that of the command.

Two variables are set for the command; escape the `$` so that they are
expanded there:

- `$GIMP_PLUGINDIR`: the user's plug-in folder, e.g.
  `~/.config/GIMP/3.2/plug-ins` (the Flatpak shares it); under
  `$XDG_CONFIG_HOME` if that is set, or `$GIMP3_DIRECTORY/plug-ins` if that
  is set, as GIMP itself does
- `$GEGL_OPDIR`: the user's folder for GEGL operations,
  `~/.local/share/gegl-0.4/plug-ins`; for the Flatpak
  `~/.var/app/org.gimp.GIMP/data/gegl-0.4/plug-ins`

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

Settings, from the environment:

- `GIMP_FLATPAK`: `1` to use the Flatpak, `0` for the native GIMP; unset,
  the Flatpak is used if it is installed
- `GIMP_APP_ID`: the Flatpak, `org.gimp.GIMP` by default

## gimp-run.sh

Runs a command in the GIMP Flatpak (or natively) isolated from your own
folders, for tests:

    gimp-run.sh --home="$out/home" --filesystem="$src" \
      --env=GIMP3_DIRECTORY="$out/profile" -- \
      gimp-console-3.2 --no-interface --batch-interpreter python-fu-eval -b ... --quit

A throwaway GIMP3_DIRECTORY is not enough: GIMP, GEGL and GTK also write
into the Flatpak's own folders, `~/.var/app/org.gimp.GIMP` (seen in the
tests of these plug-ins: GIO's file metadata journal in
`data/gvfs-metadata`, babl's cache and the ccache of builds in `cache`),
and `flatpak run --env=XDG_...=` does not
help, because the Flatpak sets the XDG variables itself after `--env`.
So `gimp-run.sh` starts a shell inside the Flatpak that sets HOME and
`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME` and `XDG_STATE_HOME`
to the throwaway home, and `GIO_USE_VFS=local` (no GVFS), and then runs
the command; the Flatpak runs with `--no-documents-portal`. `flatpak run`
itself gets the throwaway home as HOME too: it keeps a cache of the
libraries in `~/.var/app/<app>/.ld.so`, which changes between runs with
and without `--devel` (your own Flatpak installation, for runtimes such as
the SDK, stays in use through `FLATPAK_USER_DIR`). Natively the command
gets the same environment.

Options (also as two words, `--home DIR`):

- `--home=DIR`: the throwaway home, created if it is missing; by default
  `$GIMP_RUN_HOME`. Required. Your own home folder is refused.
- `--env=VAR=VALUE`: a variable for the command; unlike `flatpak run
  --env`, `XDG_*` variables work too
- `--filesystem=DIR`: a folder the Flatpak may see (`DIR:ro` read only)
- `--devel`: run with the SDK (for the sanitizer runtimes)
- `--app=ID`: another Flatpak, e.g. `org.blender.Blender` or
  `org.godotengine.Godot` (they write into `~/.var/app/<ID>` the same way)
- `--flatpak`, `--native`: where to run. By default GIMP runs as
  `GIMP_FLATPAK` says (0 native, 1 the Flatpak, unset the Flatpak if it is
  installed); another app in its Flatpak if that is installed.

Each argument of the command stays one word. The exit code is that of the
command. Keep the throwaway home under your home folder or `/tmp` (the
GIMP Flatpak sees both; for other apps it is added with `--filesystem`).

`gimp-build.sh` runs isolated the same way when `GIMP_RUN_HOME` is set
(tests set it, so that a build and the checks it runs inside the Flatpak
leave nothing there either).

## snapshot.sh

Lists your own folders of GIMP, Blender, Godot, Krita and Tiled, native and
Flatpak (`~/.config/GIMP`, `~/.var/app/org.gimp.GIMP`,
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

Shared settings for the scripts, sourced by them: whether GIMP is the
Flatpak, its version and SDK, and the two folders above. Sourcing it never
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

`gimp-3.2` is the GIMP of the Flatpak; `gimp-build.sh --env` shows the
version. Without `--password-store=basic` a new Chrome can wait some 25
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
`gimp-run.sh` and `isolate.sh` against a fake `flatpak` and a fake native
GIMP in a throwaway HOME (native, Flatpak, no GIMP, GIMP 2, missing SDK,
translated `flatpak info`, paths with spaces, the isolated environment
inside the Flatpak and natively, `isolate.sh` with and without
gimp-devtools), `snapshot.sh` on a folder of its own, the key events
of `cdp.mjs`, `cdp.mjs` against a headless Chrome, and typing into a GTK
text field on Broadway (in the GIMP Flatpak, through `gimp-run.sh`). What
is not installed (shellcheck, node 22, Chrome, the Flatpak GIMP) is
skipped. Needs no network and touches nothing outside a temporary folder:
a snapshot of your folders of GIMP and the other apps before and after
checks that.

## License

GPL version 3 or later.
