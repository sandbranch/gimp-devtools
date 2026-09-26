import bpy, shutil, os, time
rt="/tmp/claude-1000/interlink/rt/"
shutil.copy(rt+"u16.png", rt+"bl_live.png")
im=bpy.data.images.load(rt+"bl_live.png")
w,h=im.size
print("BEFORE", tuple(round(v,3) for v in im.pixels[:4]))
shutil.copy(rt+"live.png", rt+"bl_live.tmp"); os.replace(rt+"bl_live.tmp", rt+"bl_live.png")
print("NO RELOAD", tuple(round(v,3) for v in im.pixels[:4]))
im.reload()
print("AFTER RELOAD", tuple(round(v,3) for v in im.pixels[:4]), "size", tuple(im.size))
print("timers in bg:", bpy.app.background)
