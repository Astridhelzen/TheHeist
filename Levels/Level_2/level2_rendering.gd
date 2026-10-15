@tool
extends Node3D

# Also apply to already imported bank materials when opening the level.
func _ready() -> void:
 for mesh in $Bank.find_children("*", "MeshInstance3D", true, false):
  for surface in range(mesh.mesh.get_surface_count()):
   var material = mesh.get_active_material(surface)
   if material is BaseMaterial3D:
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
