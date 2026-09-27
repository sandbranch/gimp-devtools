import gi
gi.require_version("Gimp","3.0"); gi.require_version("Gegl","0.4")
from gi.repository import Gimp, Gio, Gegl
out="/tmp/claude-1000/leveleditors/test/"
img=Gimp.Image.new(64,32,Gimp.ImageBaseType.RGB)
bg=Gimp.Layer.new(img,"base",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL)
img.insert_layer(bg,None,0)
Gimp.context_set_foreground(Gegl.Color.new("rgb(0.2,0.4,0.8)"))
bg.edit_fill(Gimp.FillType.FOREGROUND)
top=Gimp.Layer.new(img,"paint",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL)
img.insert_layer(top,None,0)
top.fill(Gimp.FillType.TRANSPARENT)
img.select_rectangle(Gimp.ChannelOps.REPLACE,0,0,16,16)
Gimp.context_set_foreground(Gegl.Color.new("rgb(1,0,0)"))
top.edit_fill(Gimp.FillType.FOREGROUND)
Gimp.Selection.none(img)
for ext in ("xcf","psd","ora","png"):
    f=Gio.File.new_for_path(out+"g."+ext)
    print("EXPORT",ext,Gimp.file_save(Gimp.RunMode.NONINTERACTIVE,img,f,None))
