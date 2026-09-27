import gi
gi.require_version("Gimp","3.0"); gi.require_version("Gegl","0.4")
from gi.repository import Gimp, Gio, Gegl
p="/tmp/claude-1000/leveleditors/test/"
img=Gimp.Image.new(64,32,Gimp.ImageBaseType.RGB)
bg=Gimp.Layer.new(img,"base",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL); img.insert_layer(bg,None,0)
Gimp.context_set_foreground(Gegl.Color.new("rgb(0.2,0.4,0.8)")); bg.edit_fill(Gimp.FillType.FOREGROUND)
f=Gimp.DrawableFilter.new(bg,"gegl:invert-gamma","inv")
bg.append_filter(f)
print("filters", [x.get_name() for x in bg.get_filters()])
for ext in ("xcf","png"):
    print("SAVE",ext,Gimp.file_save(Gimp.RunMode.NONINTERACTIVE,img,Gio.File.new_for_path(p+"n."+ext),None))
