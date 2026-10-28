extends Node3D

const CollisionBuilder = preload("res://Levels/Level_1/bank_collision.gd")

@export var keypad_path: NodePath
@export var hinge_path: NodePath
@export var player_path: NodePath
@export var code_note_path: NodePath
@export var interaction_distance: float = 1.6
@export var close_distance: float = 2.0
@export var open_angle: float = -100.0

var is_open: bool = false
var is_unlocked: bool = false
var entered_code: String = ""
var status: String = "Enter code"
var _dismissed: bool = false
var _wrong_code: bool = false
var _elapsed: float = 0.0
var _door_tween: Tween
var _door_body: AnimatableBody3D

@onready var _keypad: Node3D = get_node(keypad_path)
@onready var _hinge: Node3D = get_node(hinge_path)
@onready var _player: CharacterBody3D = get_node(player_path)
@onready var _code_note: Node3D = get_node(code_note_path)
@onready var _overlay: Control = $CanvasLayer/Overlay
@onready var _panel: Control = $CanvasLayer/Overlay/Keypad
@onready var _marker: MeshInstance3D = $Marker


func _ready() -> void:
	# Modellen är sparad med öppen dörr i Blender; starta spelet med den stängd.
	_hinge.rotation.y = 0.0
	_door_body = AnimatableBody3D.new()
	_door_body.name = "VaultDoorCollision"
	_door_body.sync_to_physics = false
	_hinge.add_child(_door_body)
	var collision := CollisionShape3D.new()
	_door_body.add_child(collision)
	collision.shape = CollisionBuilder.build_shape(_hinge, _door_body)
	_overlay.hide()
	_update_panel()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_marker.global_position = _keypad.to_global(Vector3(0, 0.7 + sin(_elapsed * 2.5) * 0.06, 0.45))
	_marker.rotation.y += delta
	if is_unlocked:
		return
	var offset := _player.global_position - _keypad.global_position
	var distance := Vector2(offset.x, offset.z).length()
	if distance > close_distance or absf(offset.y) > 2.0:
		_dismissed = false
		_close_panel()
		return
	var limit := close_distance if is_open else interaction_distance
	if distance <= limit and not _dismissed and _has_line_of_sight():
		if not is_open:
			_open_panel()
	elif is_open:
		_close_panel()


func _has_line_of_sight() -> bool:
	# Punkten ligger framför låset så att låsets egen kollision inte skymmer den.
	var target := _keypad.to_global(Vector3(0, 0, 0.3))
	var query := PhysicsRayQueryParameters3D.create(
		_player.global_position + Vector3(0, 1.45, 0), target, 1, [_player.get_rid()]
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _open_panel() -> void:
	is_open = true
	entered_code = ""
	_wrong_code = false
	status = "Enter code"
	_player.camera_input_enabled = false
	_overlay.show()
	_marker.hide()
	_update_panel()


func _close_panel() -> void:
	if not is_open:
		return
	is_open = false
	_overlay.hide()
	_player.camera_input_enabled = true
	_marker.visible = not is_unlocked


func _input(event: InputEvent) -> void:
	if not is_open or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		_dismissed = true
		_close_panel()
	elif is_unlocked:
		return
	elif event.keycode == KEY_BACKSPACE:
		entered_code = entered_code.left(-1)
		_wrong_code = false
		status = "Enter code"
		_update_panel()
	elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		_submit_code()
	elif event.keycode >= KEY_0 and event.keycode <= KEY_9:
		_add_digit(str(event.keycode - KEY_0))
	elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
		_add_digit(str(event.keycode - KEY_KP_0))
	else:
		return
	get_viewport().set_input_as_handled()


func _add_digit(digit: String) -> void:
	if _wrong_code:
		entered_code = ""
		_wrong_code = false
		status = "Enter code"
	if entered_code.length() < _code_note.vault_code.length():
		entered_code += digit
	_update_panel()
	if entered_code.length() == _code_note.vault_code.length():
		_submit_code()


func _submit_code() -> void:
	if entered_code != _code_note.vault_code:
		_wrong_code = true
		status = "Incorrect code"
		_update_panel()
		return
	is_unlocked = true
	status = "Access granted · Opening vault"
	_update_panel()
	_marker.hide()
	# Fysiktween: dörrens kollision följer gångjärnet under hela öppningen.
	_door_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_door_tween.tween_property(_hinge, "rotation:y", deg_to_rad(open_angle), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	get_tree().create_timer(0.7).timeout.connect(_close_panel)


func _update_panel() -> void:
	_panel.digits = entered_code
	_panel.code_length = _code_note.vault_code.length()
	_panel.message = status
	_panel.error = _wrong_code
	_panel.unlocked = is_unlocked
	_panel.queue_redraw()
