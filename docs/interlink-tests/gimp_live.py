import gi, time, shutil
gi.require_version("Gimp","3.0")
from gi.repository import Gimp, Gio
rt="/tmp/claude-1000/interlink/rt/"
img=Gimp.Image.new(256,256,Gimp.ImageBaseType.RGB)
ll=Gimp.LinkLayer.new(img, Gio.File.new_for_path(rt+"live.png")); img.insert_layer(ll,None,0)
def px(): 
    c=ll.get_pixel(200,200); return c.get_rgba()
print("BEFORE", px())
shutil.copy(rt+"uv.svg.png" if False else rt+"u8.tif", rt+"tmp_ignore")
# overwrite live.png with a differently coloured png: use f32.png? same colour. Make solid red via GIMP
r=Gimp.Image.new(256,256,Gimp.ImageBaseType.RGB); l=Gimp.Layer.new(r,"x",256,256,Gimp.ImageType.RGB_IMAGE,100,Gimp.LayerMode.NORMAL); r.insert_layer(l,None,0)
gi.require_version("Gegl","0.4"); from gi.repository import Gegl
Gimp.context_set_foreground(Gegl.Color.new("red")); l.edit_fill(Gimp.FillType.FOREGROUND)
Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, r, Gio.File.new_for_path(rt+"live_new.png"), None)
import os; os.replace(rt+"live_new.png", rt+"live.png")
for i in range(8):
    time.sleep(1); Gimp.displays_flush()
    print("AFTER", i, px())
