import gi
gi.require_version("Gimp","3.0"); gi.require_version("Gegl","0.4")
from gi.repository import Gimp, Gio, Gegl
out="/tmp/claude-1000/interlink/rt/"
pdb=Gimp.get_pdb()
def export(img, name):
    f=Gio.File.new_for_path(out+name)
    ok=Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, img, f, None)
    print("EXPORT", name, ok)
for prec,name in ((Gimp.Precision.U8_NON_LINEAR,"u8"),(Gimp.Precision.U16_NON_LINEAR,"u16"),(Gimp.Precision.FLOAT_LINEAR,"f32")):
    img=Gimp.Image.new_with_precision(256,256,Gimp.ImageBaseType.RGB,prec)
    bg=Gimp.Layer.new(img,"base",256,256,Gimp.ImageType.RGBA_IMAGE,100,Gimp.LayerMode.NORMAL)
    img.insert_layer(bg,None,0)
    c=Gegl.Color.new("rgb(0.2,0.4,0.8)"); Gimp.context_set_foreground(c)
    bg.edit_fill(Gimp.FillType.FOREGROUND)
    top=Gimp.Layer.new(img,"paint",256,256,Gimp.ImageType.RGBA_IMAGE,50,Gimp.LayerMode.MULTIPLY)
    img.insert_layer(top,None,0)
    top.fill(Gimp.FillType.TRANSPARENT)
    img.select_rectangle(Gimp.ChannelOps.REPLACE,0,0,128,128)
    Gimp.context_set_foreground(Gegl.Color.new("rgb(1,0,0)"))
    top.edit_fill(Gimp.FillType.FOREGROUND)
    Gimp.Selection.none(img)
    for ext in ("xcf","png","psd","ora","exr","tif"):
        try: export(img, f"{name}.{ext}")
        except Exception as e: print("FAIL", name, ext, e)
