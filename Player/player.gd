extends CharacterBody3D

@export var sneak_speed: float = 1
@export var walk_speed: float = 1.7
@export var run_speed: float = 5.0
@export var turn_speed: float = 12.0
@export_range(0.0005, 0.01, 0.0005) var mouse_sensitivity: float = 0.003

const ROTATION_SPEED = 2.0
const ANIMATION_BLEND = 0.2

var camera_input_enabled: bool = true
var is_sneaking: bool = false

@onready var animation_player: AnimationPlayer = $Standing_Idle/AnimationPlayer
@onready var character_model: Node3D = $Standing_Idle
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera_pivot: Node3D = $CameraPivot


func _ready() -> void:
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_stop_on_slope = true
	# Kameran ska stoppas av omgivningen, men inte av spelarens egen kapsel.
	PlayerManager.player = self
	camera_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Alla Mixamo-klipp spelas på den synliga karaktärens skelett.
	var library := AnimationLibrary.new()
	_add_animation(library, &"idle", animation_player)
	_add_animation(library, &"walking", $Walking/AnimationPlayer)
	_add_animation(library, &"running", $Running/AnimationPlayer)
	_add_animation(library, &"sneaking", $Sneaking/AnimationPlayer)
	animation_player.add_animation_library(&"movement", library)
	animation_player.play(&"movement/idle")
	$AudioListener3D.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if not camera_input_enabled:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_camera(event.relative)


func _rotate_camera(mouse_movement: Vector2) -> void:
	# Vrid kamerans pivot, så att karaktären inte vrids av musen.
	camera_pivot.rotation.y -= mouse_movement.x * mouse_sensitivity
	camera_pivot.rotation.x = clampf(
		camera_pivot.rotation.x - mouse_movement.y * mouse_sensitivity,
		deg_to_rad(-40.0), deg_to_rad(25.0)
	)


func _add_animation(library: AnimationLibrary, anim_name: StringName, source: AnimationPlayer) -> void:
	var animation := source.get_animation(&"mixamo_com").duplicate() as Animation
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(anim_name, animation)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# -------------------------
	# PILTANGENTER = VRID KAMERAN
	# -------------------------

	if camera_input_enabled and Input.is_key_pressed(KEY_LEFT):
		camera_pivot.rotation.y += ROTATION_SPEED * delta

	if camera_input_enabled and Input.is_key_pressed(KEY_RIGHT):
		camera_pivot.rotation.y -= ROTATION_SPEED * delta


	# -------------------------
	# WASD = MOVEMENT
	# -------------------------

	var move_direction := Vector3.ZERO
	# Styr relativt kameran, oberoende av vilket håll modellen tittar åt.
	var camera_forward := -camera.global_transform.basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera.global_transform.basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()

	# W = framåt
	if Input.is_key_pressed(KEY_W):
		move_direction += camera_forward

	# S = bakåt
	if Input.is_key_pressed(KEY_S):
		move_direction -= camera_forward

	# A = sidled vänster
	if Input.is_key_pressed(KEY_A):
		move_direction -= camera_right

	# D = sidled höger
	if Input.is_key_pressed(KEY_D):
		move_direction += camera_right


	# -------------------------
	# FLYTTA SPELAREN
	# -------------------------

	# Shift = springa, Ctrl eller C = smyga. Håller man båda vinner springet.
	var is_moving := move_direction != Vector3.ZERO
	var is_running := is_moving and Input.is_key_pressed(KEY_SHIFT)
	is_sneaking = is_moving and not is_running \
			and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_C))

	var speed := walk_speed
	var next_animation: StringName = &"movement/idle"

	if is_running:
		speed = run_speed
	elif is_sneaking:
		speed = sneak_speed

	if is_moving:
		move_direction = move_direction.normalized()
		# Mixamo-modellen har +Z som framåt. Vrid bara modellen, inte kameran.
		var target_angle := atan2(move_direction.x, move_direction.z)
		character_model.global_rotation.y = lerp_angle(
			character_model.global_rotation.y, target_angle, 1.0 - exp(-turn_speed * delta)
		)

		velocity.x = move_direction.x * speed
		velocity.z = move_direction.z * speed

		if is_running:
			next_animation = &"movement/running"
		elif is_sneaking:
			next_animation = &"movement/sneaking"
		else:
			next_animation = &"movement/walking"
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

	# Byt bara när tillståndet ändras så att klippet inte startar om varje bildruta.
	if animation_player.current_animation != next_animation:
		animation_player.play(next_animation, ANIMATION_BLEND)
