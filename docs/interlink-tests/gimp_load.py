import gi
gi.require_version("Gimp","3.0")
from gi.repository import Gimp, Gio
for p in ("/tmp/claude-1000/interlink/bl/out/t16.png","/tmp/claude-1000/interlink/bl/out/t.exr","/tmp/claude-1000/interlink/rt/u16.psd"):
    im=Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path(p))
    L=im.get_layers()
    print("LOAD", p.split('/')[-1], im.get_precision().value_nick, "layers", [l.get_name() for l in L], L[-1].get_pixel(10,10).get_rgba())
