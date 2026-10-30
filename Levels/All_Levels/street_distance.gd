@tool
extends Node3D
## Gatans bakgrund tonar ut i mörkret.

func _ready() -> void:
	for direction in [-1.0, 1.0]:
		var edge := -45.0 if direction < 0 else 55.0
		_strip(45.148, 43.704, 5.9, edge, direction, Color(0.1, 0.12, 0.15))
		_strip(26.148, 5.704, 6.0, edge, direction, Color(0.46, 0.48, 0.49))
		_strip(43.0, 8.0, 6.0, edge, direction, Color(0.46, 0.48, 0.49))
		for i in range(20):
			var mark := MeshInstance3D.new()
			var mesh := PlaneMesh.new()
			mesh.size = Vector2(0.18, 2.5)
			mark.mesh = mesh
			mark.position = Vector3(34, 5.91, edge + direction * (3.0 + i * 6.0))
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.79, 0.69).lerp(Color(0.001, 0.001, 0.002), smoothstep(0, 75, i * 6.0))
			material.roughness = 1.0
			mark.material_override = material
			add_child(mark)

func _strip(x: float, width: float, height: float, edge: float, direction: float, color: Color) -> void:
	var surface := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(width, 120)
	surface.mesh = mesh
	surface.position = Vector3(x, height, edge + direction * 60)
	if direction < 0: surface.rotation.y = PI
	var shader := Shader.new()
	shader.code = """shader_type spatial;
uniform vec4 road_color : source_color;
void fragment() {
 ALBEDO = mix(road_color.rgb, vec3(0.001, 0.001, 0.002), smoothstep(0.15, 0.9, UV.y));
 ROUGHNESS = 0.88;
 SPECULAR = 0.5;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("road_color", color)
	surface.material_override = material
	add_child(surface)
