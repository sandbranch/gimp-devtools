import gi
gi.require_version("Gimp","3.0")
from gi.repository import Gimp, Gio
rt="/tmp/claude-1000/interlink/rt/"
f=Gio.File.new_for_path(rt+"uv.svg")
img=Gimp.Image.new(1024,1024,Gimp.ImageBaseType.RGB)
ok,paths=img.import_paths_from_file(f, False, True)
print("PATHS", ok, len(paths) if paths else paths)
try:
    ll=Gimp.LinkLayer.new(img, f)
    print("LINKLAYER", ll, ll and ll.get_file().get_path(), ll and (ll.get_width(), ll.get_height()))
    img.insert_layer(ll,None,0)
except Exception as e: print("LINK FAIL", e)
try:
    ll2=Gimp.LinkLayer.new(img, Gio.File.new_for_path(rt+"u8.png")); img.insert_layer(ll2,None,0); print("LINK PNG", ll2.get_mime_type())
    ll3=Gimp.LinkLayer.new(img, Gio.File.new_for_path(rt+"u8.xcf")); print("LINK XCF", ll3)
except Exception as e: print("LINK2 FAIL", e)
print("export paths", img.export_path_to_file(Gio.File.new_for_path(rt+"paths_out.svg"), None))
Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, img, Gio.File.new_for_path(rt+"uvlinked.xcf"), None)
img2=Gimp.file_load(Gimp.RunMode.NONINTERACTIVE, Gio.File.new_for_path(rt+"uvlinked.xcf"))
print("reloaded layers", [(l.get_name(), l.is_link_layer()) for l in img2.get_layers()])
