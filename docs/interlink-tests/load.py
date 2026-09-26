import bpy, glob, os
for p in sorted(glob.glob("/tmp/claude-1000/interlink/rt/*")):
    if p.endswith(".py"): continue
    try:
        im=bpy.data.images.load(p)
        w,h=im.size
        px=im.pixels[:]
        def s(x,y):
            i=(y*w+x)*4; return tuple(round(v,3) for v in px[i:i+4])
        # blender origin bottom-left; GIMP top-left red square => blender (64, h-64)
        print(os.path.basename(p), im.type, im.file_format, "depth",im.depth,"float",im.is_float,"ch",im.channels,"cs",im.colorspace_settings.name,
              "TL",s(64,h-64),"BR",s(192,64), "layers", [l.name for l in im.render_slots] if False else "")
    except Exception as e:
        print(os.path.basename(p), "LOAD FAIL", e)
