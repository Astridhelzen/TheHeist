@tool
extends Node3D

# Also apply to already imported bank materials when opening the level.
func _ready() -> void:
 for mesh in $Bank.find_children("*", "MeshInstance3D", true, false):
  if mesh.name in ["TheHall_310_MAT_0", "EntryThreshold"]:
   _separate_floor_overlay(mesh)
  # Both staircases have smooth ramps. Keep their visible treads, but disable
  # duplicate step collisions so the actor and camera do not bounce every step.
  if mesh.name in ["TheHall_220_MAT_0", "TheHall_195_MAT_0"]:
   for body in mesh.find_children("*", "StaticBody3D", true, false):
    body.collision_layer = 0
    body.collision_mask = 0
  for surface in range(mesh.mesh.get_surface_count()):
   var material = mesh.get_active_material(surface)
   if material is BaseMaterial3D:
    material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
    if mesh.name == "TheHall_176_MAT_0":
     # Imported marble floor triangles have collapsed UVs (all U = 1),
     # stretching a single texture column across metres of floor. Project the
     # original marble in world space instead; decorative inlays are separate.
     var marble = material.duplicate() as BaseMaterial3D
     marble.uv1_triplanar = true
     marble.uv1_world_triplanar = true
     marble.uv1_scale = Vector3.ONE * 0.5
     mesh.set_surface_override_material(surface, marble)


func _separate_floor_overlay(instance: MeshInstance3D) -> void:
 # The entrance's decorative border and threshold are coplanar with the
 # marble at world Y=6.53478. Separate only their floor-level render vertices;
 # keep the imported collision shapes and all upper-floor geometry intact.
 var source := instance.mesh
 var corrected := ArrayMesh.new()
 var local_offset := instance.global_basis.inverse() * Vector3(0, 0.01, 0)
 var changed := false
 for surface in range(source.get_surface_count()):
  var arrays := source.surface_get_arrays(surface)
  var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
  for index in range(vertices.size()):
   var world_vertex := instance.global_transform * vertices[index]
   if absf(world_vertex.y - 6.53478) < 0.002:
    vertices[index] += local_offset
    changed = true
  arrays[Mesh.ARRAY_VERTEX] = vertices
  # Imported meshes also carry custom vertex channels; retain their formats.
  var flags: int = source.surface_get_format(surface) if source is ArrayMesh else 0
  corrected.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays, [], {}, flags)
  corrected.surface_set_material(surface, source.surface_get_material(surface))
 if changed:
  instance.mesh = corrected
