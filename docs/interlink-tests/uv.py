import bpy
o=bpy.data.objects.get("Cube"); bpy.context.view_layer.objects.active=o; o.select_set(True)
print("modes", [i.identifier for i in bpy.ops.uv.export_layout.get_rna_type().properties['mode'].enum_items])
bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT')
for m,e in (('SVG','svg'),('PNG','png')):
    r=bpy.ops.uv.export_layout(filepath="/tmp/claude-1000/interlink/rt/uv."+e, mode=m, size=(1024,1024), export_all=True)
    print("UV", m, r)
