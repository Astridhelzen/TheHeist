extends Node3D

## Visa lappen på nära håll utan att stoppa rörelsen.
@export var vault_code: String = "1234"
@export var note_path: NodePath
@export var player_path: NodePath
@export var read_distance: float = 1.65
@export var close_distance: float = 2.0

var is_reading: bool = false
var _elapsed: float = 0.0
var _fade: Tween

@onready var _note: Node3D = get_node(note_path)
@onready var _player: CharacterBody3D = get_node(player_path)
@onready var _overlay: Control = $CanvasLayer/Overlay
@onready var _paper: Control = $CanvasLayer/Overlay/Paper
@onready var _marker: MeshInstance3D = $Marker


func _ready() -> void:
	_paper.code = vault_code
	_overlay.modulate.a = 0.0
	_overlay.hide()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_marker.global_position = _note.global_position + Vector3(0, 0.48 + sin(_elapsed * 2.5) * 0.06, 0)
	_marker.rotation.y += delta
	var offset := _player.global_position - _note.global_position
	var distance := Vector2(offset.x, offset.z).length()
	var limit := close_distance if is_reading else read_distance
	var nearby := distance <= limit and absf(offset.y) < 1.8
	_set_reading(nearby and _has_line_of_sight())


func _has_line_of_sight() -> bool:
	# Hindrar att lappen visas genom en vägg eller från ett annat rum.
	var query := PhysicsRayQueryParameters3D.create(
		_player.global_position + Vector3(0, 1.45, 0),
		_note.global_position + Vector3(0, 0.15, 0), 1, [_player.get_rid()]
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _set_reading(value: bool) -> void:
	if value == is_reading:
		return
	is_reading = value
	if _fade:
		_fade.kill()
	_overlay.show()
	_marker.visible = not is_reading
	_fade = create_tween()
	_fade.tween_property(_overlay, "modulate:a", 1.0 if is_reading else 0.0, 0.18)
	if not is_reading:
		_fade.tween_callback(_overlay.hide)
