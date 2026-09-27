import gi
gi.require_version("Gimp","3.0"); gi.require_version("Gegl","0.4")
from gi.repository import Gimp, Gio, Gegl
p="/tmp/claude-1000/leveleditors/test/"
def build(prec, tag):
    img=Gimp.Image.new_with_precision(64,32,Gimp.ImageBaseType.RGB,prec)
    bg=Gimp.Layer.new(img,"base",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL); img.insert_layer(bg,None,0)
    Gimp.context_set_foreground(Gegl.Color.new("rgb(0.2,0.4,0.8)")); bg.edit_fill(Gimp.FillType.FOREGROUND)
    grp=Gimp.GroupLayer.new(img,"grp"); img.insert_layer(grp,None,0)
    a=Gimp.Layer.new(img,"mul",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.MULTIPLY); img.insert_layer(a,grp,0)
    a.fill(Gimp.FillType.TRANSPARENT); img.select_rectangle(Gimp.ChannelOps.REPLACE,0,0,32,32)
    Gimp.context_set_foreground(Gegl.Color.new("rgb(1,0.5,0)")); a.edit_fill(Gimp.FillType.FOREGROUND)
    h=Gimp.Layer.new(img,"hidden",64,32,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL); img.insert_layer(h,None,0)
    img.select_rectangle(Gimp.ChannelOps.REPLACE,48,0,16,16); Gimp.context_set_foreground(Gegl.Color.new("rgb(0,1,0)")); h.fill(Gimp.FillType.TRANSPARENT); h.edit_fill(Gimp.FillType.FOREGROUND); h.set_visible(False)
    o=Gimp.Layer.new(img,"half",64,32,Gimp.ImageType.RGBA_IMAGE,50,Gimp.LayerMode.NORMAL); img.insert_layer(o,None,0)
    o.fill(Gimp.FillType.TRANSPARENT); img.select_rectangle(Gimp.ChannelOps.REPLACE,16,16,32,16); Gimp.context_set_foreground(Gegl.Color.new("rgb(1,1,1)")); o.edit_fill(Gimp.FillType.FOREGROUND)
    Gimp.Selection.none(img)
    for ext in ("xcf","png"):
        print("SAVE",tag,ext,Gimp.file_save(Gimp.RunMode.NONINTERACTIVE,img,Gio.File.new_for_path(p+"h_"+tag+"."+ext),None))
build(Gimp.Precision.U8_NON_LINEAR,"u8")
build(Gimp.Precision.U16_NON_LINEAR,"u16")
build(Gimp.Precision.FLOAT_LINEAR,"f32")
