@tool
extends Node3D

# Also apply to already imported bank materials when opening the level.
func _ready() -> void:
 for mesh in $Bank.find_children("*", "MeshInstance3D", true, false):
  # The basement stairs use BasementVault/StairCollision for locomotion.
  # Imported tread/riser triangles otherwise catch the capsule on the sides.
  if mesh.name == "TheHall_220_MAT_0":
   for body in mesh.find_children("*", "StaticBody3D", true, false):
    body.collision_layer = 0
    body.collision_mask = 0
  for surface in range(mesh.mesh.get_surface_count()):
   var material = mesh.get_active_material(surface)
   if material is BaseMaterial3D:
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
