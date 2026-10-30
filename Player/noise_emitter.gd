extends Node3D
## Skickar fotsteg till vakter inom ljudradien och uppdaterar ringen.

@export_group("Speeds")
## Under gränsen räknas spelaren som stilla.
@export var still_threshold: float = 0.1
## Gräns mellan smygande och gång.
@export var walk_threshold: float = 1.3
## Gräns mellan gång och löpning.
@export var run_threshold: float = 3

@export_group("Hearing range")
@export var sneak_radius: float = 0.5
@export var walk_radius: float = 2.0
@export var run_radius: float = 4.0
## Avstånd utanför ringen där varningen börjar.
@export var warning_margin: float = 2.0

@export_group("Footsteps and visuals")
## Fotstegen som utlöser ljudhändelser.
@export var footsteps: Node
@export var ring: MeshInstance3D

var current_radius := 0.0

var _shown_radius := 0.0
var _pulse := 0.0

@onready var body: CharacterBody3D = get_parent()


func _ready() -> void:
	if ring:
		# Ringen följer positionen, men inte spelarens rotation.
		ring.top_level = true
	if footsteps:
		footsteps.step.connect(_make_noise)


func _physics_process(delta: float) -> void:
	var speed := Vector2(body.velocity.x, body.velocity.z).length()

	if not body.is_on_floor() or speed < still_threshold:
		# Inget ljud i luften eller vid stillastående.
		current_radius = 0.0
	elif speed < walk_threshold:
		current_radius = sneak_radius
	elif speed < run_threshold:
		current_radius = walk_radius
	else:
		current_radius = run_radius

	_update_ring(delta)


func _make_noise() -> void:
	if current_radius <= 0.0:
		return
	_pulse = 1.0

	for guard in get_tree().get_nodes_in_group("guards"):
		if guard.global_position.distance_to(body.global_position) <= current_radius:
			guard.hear_noise(body.global_position)


func _closest_guard_distance() -> float:
	var best := INF
	for guard in get_tree().get_nodes_in_group("guards"):
		best = minf(best, guard.global_position.distance_to(body.global_position))
	return best


func _update_ring(delta: float) -> void:
	if not ring:
		return

	# Mjukt byte av ringens storlek.
	_shown_radius = lerpf(_shown_radius, current_radius, 1.0 - exp(-10.0 * delta))
	_pulse = move_toward(_pulse, 0.0, delta * 3.0)

	ring.visible = _shown_radius > 0.05
	ring.global_position = body.global_position + Vector3.UP * 0.05
	ring.scale = Vector3(_shown_radius, 1.0, _shown_radius)

	# 0 = ingen varning, 1 = vakt inom ljudradien.
	var danger := 0.0
	if current_radius > 0.0:
		var d := _closest_guard_distance()
		danger = clampf(inverse_lerp(current_radius + warning_margin, current_radius, d), 0.0, 1.0)

	ring.set_instance_shader_parameter("danger", danger)
	ring.set_instance_shader_parameter("pulse", _pulse)
