extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay 
 
# --------------------
# CONFIG
# --------------------
@export var patrol_points: Array[Node3D] = []
@export var speed_walk: float = 1.7
@export var speed_run: float = 3.0
@export var attack_range: float = 2.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var update_interval: float = 0.2
@export var look_around_angle: float = 70.0   # hur långt åt varje håll (grader)
@export var pursue_time: float = 1.5   # hur länge den jagar utan att se dig

const VIEW_ANGLE: float = 190.0
const SMOOTHING_FACTOR = 0.2
 
# --------------------
# STATE MACHINE
# --------------------
enum State { IDLE, PATROL, INVESTIGATE, PURSUE, CHASE, ATTACK, RETURN }
var state: State = State.IDLE
 
var patrol_index := 0
var patrol_timer := 0.0
var investigate_timer := 0.0
var investigate_position: Vector3
var return_position: Vector3
var target: Node3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var update_timer := 0.0
var look_base_yaw := 0.0
var pursue_timer := 0.0
 
# --------------------
# READY
# --------------------
func _ready() -> void:
	target = PlayerManager.player
	_enter_state( State.IDLE if patrol_points.is_empty() else State.PATROL)
 
# --------------------
# MAIN LOOP
# --------------------
func _physics_process(delta: float) -> void:
	_update_path(delta)
 
	match state:
		State.IDLE:        _state_idle()
		State.PATROL:      _state_patrol(delta)
		State.INVESTIGATE: _state_investigate(delta)
		State.CHASE:       _state_chase(delta)
		State.PURSUE:      _state_pursue(delta)
		State.ATTACK:      _state_attack()
		State.RETURN:      _state_return(delta)
 
	_looking()
	_apply_gravity(delta)
	move_and_slide()
 
# --------------------
# STATE HANDLERS
# --------------------
func _state_idle() -> void:
	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_patrol(delta: float) -> void:
	if agent.is_navigation_finished():
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			_stop_and_idle()
		else:
			patrol_timer -= delta
			if patrol_timer <= 0.0:
				_go_to_next_patrol_point()
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)
 
	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_investigate(delta: float) -> void:
	if agent.is_navigation_finished():
		if investigate_timer <= 0.0:
			investigate_timer = investigate_wait_time
			look_base_yaw = rotation.y   # kom ihåg vilket håll den tittade från början
			_stop_and_idle()
		else:
			investigate_timer -= delta
			_look_around()
			if investigate_timer <= 0.0:
				_enter_state(State.RETURN)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)
 
func _state_chase(delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return
 
	_walk_to(agent.get_next_path_position(), speed_run)
 
	if global_transform.origin.distance_to(target.global_transform.origin) < attack_range:
		_enter_state(State.ATTACK)
	elif not _can_see_player():
		_enter_state(State.PURSUE)
 
func _state_pursue(delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return

	_walk_to(agent.get_next_path_position(), speed_run)

	if _can_see_player():
		_enter_state(State.CHASE)
		return

	if global_transform.origin.distance_to(target.global_transform.origin) < attack_range:
		_enter_state(State.ATTACK)
		return

	pursue_timer -= delta
	if pursue_timer <= 0.0:
		investigate_position = target.global_transform.origin
		_enter_state(State.INVESTIGATE)
		

	
func _state_attack() -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if not anim.is_playing():   # Attack-animationen är klar
		# TODO: handle player capture
		_enter_state(State.CHASE)
 
func _state_return(delta: float) -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	elif _can_see_player():
		_enter_state(State.CHASE)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)
 
# --------------------
# HELPERS
# --------------------
func _enter_state(new_state: State) -> void:
	# Utan patrullpunkter finns ingen runda att gå, så stå still istället
	if new_state == State.PATROL and patrol_points.is_empty():
		new_state = State.IDLE

	# Spara var vakten var innan den började jaga/undersöka
	if state in [State.IDLE, State.PATROL, State.RETURN] \
			and new_state in [State.CHASE, State.INVESTIGATE]:
		return_position = global_transform.origin

	state = new_state
	match state:
		State.IDLE:
			_stop_and_idle()
		State.PATROL:
			patrol_timer = 0
			_go_to_next_patrol_point()
		State.INVESTIGATE:
			investigate_timer = 0.0
			agent.set_target_position(investigate_position)
		State.PURSUE:
			pursue_timer = pursue_time
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			anim.play("Attack")

func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if patrol_points.size() > 0:
				agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
		State.INVESTIGATE:
			agent.set_target_position(investigate_position)
		State.CHASE, State.PURSUE:
			if target:
				agent.set_target_position(target.global_transform.origin)
		State.RETURN:
			agent.set_target_position(return_position)
 
func _walk_to(next_pos: Vector3, speed: float) -> void:
	anim.play("Run" if speed >= speed_run else "Walk")
	_move_towards(next_pos, speed)
 
func _stop_and_idle() -> void:
	velocity = Vector3.ZERO
	anim.play("Idle")
 
func _go_to_next_patrol_point() -> void:
	patrol_index = ( patrol_index + 1 ) % patrol_points.size()
	agent.set_target_position(patrol_points[patrol_index].global_transform.origin)
 
func _move_towards(next_pos: Vector3, speed: float) -> void:
	var dir = (next_pos - global_transform.origin)
	dir.y = 0.0
	if  is_zero_approx( dir.length() ):
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		velocity.z = lerp(velocity.z, 0.0, SMOOTHING_FACTOR)
		return
 
	dir = dir.normalized()
	var current_facing = -global_transform.basis.z
	var new_dir = current_facing.slerp(dir, 0.12).normalized()
	look_at(global_transform.origin + new_dir, Vector3.UP)
 
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	
func _look_around() -> void:
	# Hur långt vi har kommit i väntan, från 0.0 till 1.0
	var progress := 1.0 - investigate_timer / investigate_wait_time
	# sin() ger ett mjukt svep: vänster → mitten → höger → mitten
	var offset := sin(progress * TAU) * deg_to_rad(look_around_angle)
	rotation.y = lerp_angle(rotation.y, look_base_yaw + offset, 0.1)
 
func _update_path(delta):
	update_timer -= delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval
 
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
 
# --------------------
# VISION
# --------------------
func _can_see_player() -> bool:
	return target and vision_ray.is_colliding() and vision_ray.get_collider() == target
 
func _looking() -> void:
	if not target:
		return
 
	var to_player = (target.global_transform.origin - global_transform.origin).normalized()
	var forward = -global_transform.basis.z
	var angle_deg = rad_to_deg(acos(clamp(forward.dot(to_player), -1.0, 1.0)))
	if angle_deg > VIEW_ANGLE * 0.5:
		return
 
	var ray_forward = -vision_ray.global_transform.basis.z
	var new_dir = ray_forward.slerp(to_player, SMOOTHING_FACTOR).normalized()
	vision_ray.look_at(vision_ray.global_transform.origin + new_dir, Vector3.UP)
 
# --------------------
# SOUND
# --------------------
func hear_noise(pos: Vector3) -> void:
	if state not in [State.CHASE, State.ATTACK, State.PURSUE]:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)
 
