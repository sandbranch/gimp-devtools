import gi
gi.require_version("Gimp","3.0"); gi.require_version("Gegl","0.4")
from gi.repository import Gimp, Gio, Gegl
p="/tmp/claude-1000/leveleditors/test/"
img=Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path(p+"g.xcf"))
img.resize(64,64,0,0)
for l in img.get_layers(): l.resize_to_image_size()
for n in ("g.xcf",):
    print("SAVE", n, Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, img, Gio.File.new_for_path(p+n), None))
