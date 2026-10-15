@tool
extends EditorScenePostImport

# Static bank geometry gets collision again whenever the Blender file changes.
# The animated vault door belongs to BasementVault and is not part of this import.
func _post_import(scene: Node) -> Object:
	_add_collisions(scene, scene, false)
	return scene

func _add_collisions(node: Node, scene: Node, inside_body: bool) -> void:
	inside_body = inside_body or node is CollisionObject3D
	var children := node.get_children()
	if node is MeshInstance3D and not inside_body:
		var instance := node as MeshInstance3D
		# Preserve detail without shimmering at grazing viewing angles.
		if instance.mesh != null:
			for surface in range(instance.mesh.get_surface_count()):
				var material := instance.get_active_material(surface)
				if material is BaseMaterial3D:
					material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		# The source's invisible helper material became opaque during conversion.
		# Keep its useful collision, but never draw it over the textured surfaces.
		if "Invisible_M" in instance.name:
			instance.visible = false
		var already_has_collision := false
		for child in children:
			if child is CollisionObject3D:
				already_has_collision = true
		if instance.mesh != null and not already_has_collision:
			var shape := instance.mesh.create_trimesh_shape()
			if shape != null:
				shape.backface_collision = true
				var body := StaticBody3D.new()
				body.name = "BankCollision"
				body.collision_layer = 1
				body.collision_mask = 1
				instance.add_child(body)
				body.owner = scene
				var collider := CollisionShape3D.new()
				collider.name = "Shape"
				collider.shape = shape
				body.add_child(collider)
				collider.owner = scene
	for child in children:
		_add_collisions(child, scene, inside_body)
