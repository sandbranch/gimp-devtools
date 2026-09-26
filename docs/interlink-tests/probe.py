import bpy, os, shutil, sys
print("VERSION", bpy.app.version_string)
print("TEMPDIR", bpy.app.tempdir)
print("XCF_IN_EXT", '.xcf' in bpy.path.extensions_image)
print("EXTS", sorted(bpy.path.extensions_image))
print("which gimp", shutil.which("gimp"), "flatpak-spawn", shutil.which("flatpak-spawn"), "flatpak", shutil.which("flatpak"))
print("image_editor pref", repr(bpy.context.preferences.filepaths.image_editor))
fmts=[i.identifier for i in bpy.types.ImageFormatSettings.bl_rna.properties["file_format"].enum_items]
print("SAVE FORMATS", fmts)
print("color depth enum PNG")
img=bpy.data.images.new("t",64,64,float_buffer=True)
img.pixels[:]=[0.5]*64*64*4
out="/tmp/claude-1000/interlink/bl/out/"
s=bpy.context.scene.render.image_settings
s.file_format='PNG'; s.color_depth='16'
img.save_render(out+"t16.png")
s.file_format='OPEN_EXR'; s.color_depth='32'
img.save_render(out+"t.exr")
print("saved", os.listdir(out))
print("timers", hasattr(bpy.app,'timers'))
print("ocio", bpy.context.scene.display_settings.display_device, bpy.context.scene.view_settings.view_transform)
print("colorspaces", [i.identifier for i in bpy.types.ColorManagedInputColorspaceSettings.bl_rna.properties['name'].enum_items][:40])
