import bpy,pathlib
from mathutils import Matrix
root=pathlib.Path.cwd();hinge=bpy.data.objects['Vault_Door_Hinge'];hinge.rotation_euler=(0,0,0);bpy.context.view_layer.update()
selected=[hinge]+list(hinge.children_recursive)
bpy.ops.object.select_all(action='DESELECT')
for o in selected:o.select_set(True)
hinge.location=(0,0,0)
bpy.ops.export_scene.gltf(filepath=str(root/'Levels/Level_2/Assets/Vault_Door_Level1.glb'),export_format='GLB',use_selection=True,export_animations=False)
print('EXPORTED_DOOR',[(o.name,o.type) for o in selected])
