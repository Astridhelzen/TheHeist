extends Node
## Gives the player a soft bright edge (rim light) so she stands out against
## dark backgrounds, plus an optional very faint light that follows her.
## The edge is drawn on top of the model's own materials, so her textures
## and colours stay the same. Put this node under the Player.

## The visible character model.
@export var model: Node3D
@export var rim_color := Color(0.78, 0.86, 1.0)
## How bright the edge is. 0 = no edge.
@export_range(0.0, 2.0, 0.05) var rim_strength := 1.1
## Higher = thinner edge, lower = the glow reaches further in over the body.
@export_range(1.0, 8.0, 0.1) var rim_width := 2.2
## A very faint light on her. 0 = off.
@export var light_energy := 0.15
@export var light_range := 2.5
## Where the light sits, relative to the camera's pivot: up, and a bit towards
## the camera. It turns with the camera, so it always lights the side you see,
## softly from above (never from below like a torch under the chin).
@export var light_offset := Vector3(0, 0.9, 1.0)
## Lower = more even light over her whole body.
@export var light_attenuation := 0.7

const RIM_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_back;

uniform vec4 rim_color : source_color = vec4(0.78, 0.86, 1.0, 1.0);
uniform float strength = 0.6;
uniform float width = 3.0;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, width);
	ALBEDO = rim_color.rgb * rim * strength;
}
"""

var _rim_material: ShaderMaterial


func _ready() -> void:
	if model == null:
		push_warning("PlayerOutline: no model set")
		return
	var shader := Shader.new()
	shader.code = RIM_SHADER
	_rim_material = ShaderMaterial.new()
	_rim_material.shader = shader
	_update_rim()
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		_add_rim(mesh)
	if light_energy > 0.0:
		var light := OmniLight3D.new()
		light.name = "PlayerGlow"
		light.light_color = rim_color
		light.light_energy = light_energy
		light.omni_range = light_range
		light.omni_attenuation = light_attenuation
		light.shadow_enabled = false
		light.position = light_offset
		# Follow the camera's turning if there is a CameraPivot, otherwise sit above her
		var pivot := get_parent().get_node_or_null("CameraPivot")
		if pivot == null:
			pivot = get_parent()
			light.position = Vector3(0, 2.4, 0)
		pivot.add_child.call_deferred(light)


func _update_rim() -> void:
	_rim_material.set_shader_parameter("rim_color", rim_color)
	_rim_material.set_shader_parameter("strength", rim_strength)
	_rim_material.set_shader_parameter("width", rim_width)


## Draws the edge as an extra pass on top of each of the model's materials.
func _add_rim(mesh: MeshInstance3D) -> void:
	if mesh.mesh == null:
		return
	for i in mesh.mesh.get_surface_count():
		var original := mesh.get_active_material(i)
		var material: Material = original.duplicate() if original else StandardMaterial3D.new()
		material.next_pass = _rim_material
		mesh.set_surface_override_material(i, material)
