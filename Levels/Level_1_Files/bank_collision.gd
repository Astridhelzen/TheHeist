extends StaticBody3D


func _ready() -> void:
	# Bygg från den aktuella Blender-modellen varje gång banan startas.
	# Då följer kollisionerna med när väggar och möbler ändras i Blender.
	var bank := get_parent() as Node3D
	var door := bank.get_node_or_null("Vault_Door_Hinge")
	$CollisionShape3D.shape = build_shape(bank, self, door)


static func build_shape(source: Node3D, relative_to: Node3D, excluded: Node = null) -> ConcavePolygonShape3D:
	var faces := PackedVector3Array()
	var world_to_local := relative_to.global_transform.affine_inverse()
	for node in source.find_children("*", "MeshInstance3D", true, false):
		if excluded != null and (node == excluded or excluded.is_ancestor_of(node)):
			continue
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var mesh_transform := world_to_local * mesh_instance.global_transform
		var vertices := mesh_instance.mesh.get_faces()
		for index in range(0, vertices.size(), 3):
			var a := mesh_transform * vertices[index]
			var b := mesh_transform * vertices[index + 1]
			var c := mesh_transform * vertices[index + 2]
			if not a.is_finite() or not b.is_finite() or not c.is_finite():
				continue
			if (b - a).cross(c - a).length_squared() <= 0.000000000001:
				continue
			faces.append(a)
			faces.append(b)
			faces.append(c)
	var bank_shape := ConcavePolygonShape3D.new()
	bank_shape.backface_collision = true
	bank_shape.set_faces(faces)
	return bank_shape
