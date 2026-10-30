extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var vision_ray: RayCast3D = $VisionRay
@onready var flashlight: SpotLight3D = $Flashlight


# Inställningar
@export var patrol_points: Array[Node3D] = []
@export var speed_walk: float = 1.7
@export var speed_run: float = 3.0
@export var attack_range: float = 2.0
@export var investigate_wait_time: float = 4.0
@export var patrol_wait_time: float = 3.0
@export var patrol_look_angle: float = 40.0   # hur mycket den tittar runt vid patrullpunkter
@export var update_interval: float = 0.2
@export var look_around_angle: float = 70.0   # hur långt åt varje håll (grader)
@export var pursue_time: float = 2.5          # hur länge den jagar utan att se dig
@export var aim_height: float = 0.8           # var på spelaren synstrålen siktar
@export var catch_time: float = 0.4          # hur länge spelaren måste vara nära
@export var escape_margin: float = 1.2       # hur långt bort spelaren måste för att slippa

@export_group("Ficklampa")
## Färgen ficklampan får när spelaren står i ljuset.
@export var spotted_color: Color = Color(1.0, 0.15, 0.1)
## Hur snabbt färgen skiftar (högre = snabbare).
@export var color_fade_speed: float = 8.0

@export_group("Hörsel")
## Hur länge vakten stannar och tittar mot ett ljud (sekunder).
@export var hear_turn_time: float = 0.8
## Hur snabbt vakten vänder sig mot ljudet (högre = snabbare).
@export var hear_turn_speed: float = 8.0
## Minsta ljudvinkel som utlöser en vändning.
@export var hear_turn_min_angle: float = 30.0

@export_group("När lamporna tänds")
## Synvinkel åt varje sida efter larmet, i grader.
@export var lit_view_angle: float = 75.0
## Hur långt vakten ser när banken är upplyst (meter).
@export var lit_view_range: float = 20.0
## Spring till valvet när larmet går.
@export var rush_to_vault_on_alarm: bool = true


# Tillstånd
enum State { IDLE, PATROL, INVESTIGATE, CHASE, PURSUE, ATTACK, RETURN, RUSH }
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
const SMOOTHING_FACTOR = 0.2
signal player_caught
var attack_timer := 0.0
var has_caught := false
var lights_on := false
var _normal_light_color: Color
var _hear_turn_timer := 0.0
var _heard_position: Vector3

func _ready() -> void:
	floor_snap_length = 0.35
	floor_constant_speed = true
	floor_stop_on_slope = true
	add_to_group("guards")
	target = PlayerManager.player
	# Synstrålen blir lika lång som ficklampans ljus
	vision_ray.target_position = Vector3(0, 0, -flashlight.spot_range)
	# Kom ihåg ficklampans vanliga färg
	_normal_light_color = flashlight.light_color
	# Fäst ficklampan i handen utan att ändra ljusets riktning.
	GuardFlashlight.attach(self, flashlight)
	# Utan patrullpunkter börjar vakten i IDLE.
	_enter_state(State.PATROL)
	_connect_loot.call_deferred()


# Uppdatering
func _physics_process(delta: float) -> void:
	_update_path(delta)

	if _hear_turn_timer > 0.0 and state not in [State.CHASE, State.PURSUE, State.ATTACK]:
		# Har hört något: stanna och vänd dig mot ljudet först
		_hear_turn_timer -= delta
		_turn_towards_sound(delta)
		if _can_see_player():
			_hear_turn_timer = 0.0
			_enter_state(State.CHASE)
	else:
		match state:
			State.IDLE:        _state_idle()
			State.PATROL:      _state_patrol(delta)
			State.INVESTIGATE: _state_investigate(delta)
			State.CHASE:       _state_chase(delta)
			State.PURSUE:      _state_pursue(delta)
			State.ATTACK:      _state_attack(delta)
			State.RETURN:      _state_return(delta)
			State.RUSH:        _state_rush(delta)

	_apply_gravity(delta)
	preload("res://Movement/ground_motion.gd").move(self, delta)
	_update_flashlight_color(delta)

# Beteenden
func _state_idle() -> void:
	if _can_see_player():
		_enter_state(State.CHASE)

func _state_patrol(delta: float) -> void:
	if agent.is_navigation_finished():
		if patrol_timer <= 0.0:
			patrol_timer = patrol_wait_time
			look_base_yaw = rotation.y   # kom ihåg vilket håll den kom ifrån
			_stop_and_idle()
		else:
			patrol_timer -= delta
			_look_around(patrol_timer, patrol_wait_time, patrol_look_angle)
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
			_look_around(investigate_timer, investigate_wait_time, look_around_angle)
			if investigate_timer <= 0.0:
				_enter_state(State.RETURN)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

	if _can_see_player():
		_enter_state(State.CHASE)

## Spring mot valvet med hjälp av navigeringen.
func _state_rush(_delta: float) -> void:
	if _can_see_player():
		_enter_state(State.CHASE)
		return

	if agent.is_navigation_finished():
		# Undersök platsen när vakten når valvet.
		_enter_state(State.INVESTIGATE)
	else:
		_walk_to(agent.get_next_path_position(), speed_run)

func _state_chase(_delta: float) -> void:
	if not target:
		_enter_state(State.RETURN)
		return

	_walk_to(agent.get_next_path_position(), speed_run)

	if global_position.distance_to(target.global_position) < attack_range and _has_line_of_sight():
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

	if global_position.distance_to(target.global_position) < attack_range and _has_line_of_sight():
		_enter_state(State.ATTACK)
		return

	pursue_timer -= delta
	if pursue_timer <= 0.0:
		investigate_position = target.global_position
		_enter_state(State.INVESTIGATE)
		
func _state_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if not target:
		_enter_state(State.RETURN)
		return

	_face_target()
	# Avbryt attacken om sikten blockeras.
	if not _has_line_of_sight():
		attack_timer = 0.0
		anim.play("Run")
		_enter_state(State.PURSUE)
		return

	# Spelaren smet undan, jaga vidare
	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range * escape_margin:
		_enter_state(State.CHASE)
		return

	attack_timer += delta
	if attack_timer >= catch_time and not has_caught:
		has_caught = true
		player_caught.emit()

func _state_return(_delta: float) -> void:
	if agent.is_navigation_finished():
		_enter_state(State.PATROL)
	elif _can_see_player():
		_enter_state(State.CHASE)
	else:
		_walk_to(agent.get_next_path_position(), speed_walk)

# Hjälpfunktioner
func _enter_state(new_state: State) -> void:
	# Utan patrullpunkter väntar vakten i IDLE.
	if new_state == State.PATROL and patrol_points.is_empty():
		new_state = State.IDLE

	# Spara platsen som vakten ska återvända till.
	if state in [State.IDLE, State.PATROL, State.RETURN] \
			and new_state in [State.CHASE, State.INVESTIGATE, State.RUSH]:
		return_position = global_position

	state = new_state
	match state:
		State.IDLE:
			_stop_and_idle()
		State.PATROL:
			patrol_timer = 0.0
			_go_to_next_patrol_point()
		State.INVESTIGATE:
			investigate_timer = 0.0
			agent.set_target_position(investigate_position)
		State.PURSUE:
			pursue_timer = pursue_time
		State.RUSH:
			agent.set_target_position(investigate_position)
		State.CHASE:
			_hear_turn_timer = 0.0
		State.ATTACK:
			velocity.x = 0.0
			velocity.z = 0.0
			attack_timer = 0.0
			anim.play("Attack")

func _update_agent_target() -> void:
	match state:
		State.PATROL:
			if patrol_points.size() > 0:
				agent.set_target_position(patrol_points[patrol_index].global_position)
		State.INVESTIGATE, State.RUSH:
			agent.set_target_position(investigate_position)
		State.CHASE, State.PURSUE:
			if target:
				agent.set_target_position(target.global_position)
		State.RETURN:
			agent.set_target_position(return_position)

func _walk_to(next_pos: Vector3, speed: float) -> void:
	anim.play("Run" if speed >= speed_run else "Walk")
	_move_towards(next_pos, speed)

func _stop_and_idle() -> void:
	velocity = Vector3.ZERO
	anim.play("Idle")

func _go_to_next_patrol_point() -> void:
	patrol_index = (patrol_index + 1) % patrol_points.size()
	agent.set_target_position(patrol_points[patrol_index].global_position)

func _move_towards(next_pos: Vector3, speed: float) -> void:
	var dir := next_pos - global_position
	dir.y = 0.0
	if is_zero_approx(dir.length()):
		velocity.x = lerp(velocity.x, 0.0, SMOOTHING_FACTOR)
		velocity.z = lerp(velocity.z, 0.0, SMOOTHING_FACTOR)
		return

	dir = dir.normalized()
	var current_facing := -global_transform.basis.z
	var new_dir := current_facing.slerp(dir, 0.12).normalized()
	look_at(global_position + new_dir, Vector3.UP)

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

func _look_around(timer: float, total_time: float, angle_deg: float) -> void:
	if total_time <= 0.0:
		return
	# Hur långt vi har kommit i väntan, från 0.0 till 1.0
	var progress := 1.0 - timer / total_time
	# sin() ger ett mjukt svep: vänster → mitten → höger → mitten
	var offset := sin(progress * TAU) * deg_to_rad(angle_deg)
	rotation.y = lerp_angle(rotation.y, look_base_yaw + offset, 0.1)

func _update_path(delta: float) -> void:
	update_timer -= delta
	if update_timer <= 0.0:
		_update_agent_target()
		update_timer = update_interval

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

# Syn
func _can_see_player() -> bool:
	if not target:
		return false

	# Mörkt: bara i ficklampans kon. Upplyst: hela synfältet också.
	var in_sight := _is_in_flashlight() or (lights_on and _is_in_lit_view())
	return in_sight and _has_line_of_sight()

func _has_line_of_sight() -> bool:
	var aim_point := _player_aim_point()
	if vision_ray.global_position.is_equal_approx(aim_point):
		return false

	# Sikta strålen rakt på spelaren och kolla om något är i vägen
	vision_ray.look_at(aim_point, Vector3.UP)
	vision_ray.force_raycast_update()
	return vision_ray.is_colliding() and vision_ray.get_collider() == target

## Rött ljus när spelaren är synlig i ljuskäglan.
func _update_flashlight_color(delta: float) -> void:
	var in_beam := target != null and _is_in_flashlight() and _has_line_of_sight()
	var wanted := spotted_color if in_beam else _normal_light_color
	flashlight.light_color = flashlight.light_color.lerp(wanted, 1.0 - exp(-color_fade_speed * delta))

func _is_in_flashlight() -> bool:
	var to_player := _player_aim_point() - flashlight.global_position

	# För långt bort?
	if to_player.length() > flashlight.spot_range:
		return false

	# spot_angle är ljuskäglans halvvinkel.
	var forward := -flashlight.global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_player))
	return angle <= flashlight.spot_angle

func _is_in_lit_view() -> bool:
	var to_player := _player_aim_point() - vision_ray.global_position

	# För långt bort?
	if to_player.length() > lit_view_range:
		return false

	# Kontrollera vinkeln från vaktens riktning.
	to_player.y = 0.0
	var forward := -global_transform.basis.z
	forward.y = 0.0
	return rad_to_deg(forward.angle_to(to_player)) <= lit_view_angle

func _player_aim_point() -> Vector3:
	return target.global_position + Vector3.UP * aim_height
	
func _face_target() -> void:
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.01:
		look_at(global_position + to_target, Vector3.UP)
		
func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(alert.bind(loot.global_position))

## Larmet ger bredare synfält, men avslöjar inte spelarens position.
func alert(loot_position: Vector3 = Vector3.INF) -> void:
	if not target:
		target = PlayerManager.player
	lights_on = true
	# Synstrålen måste nå lika långt som det nya synfältet
	vision_ray.target_position = Vector3(0, 0, -maxf(lit_view_range, flashlight.spot_range))

	# Spring till valvet, om vakten inte redan jagar någon
	if rush_to_vault_on_alarm and loot_position.is_finite() \
			and state not in [State.CHASE, State.PURSUE, State.ATTACK]:
		investigate_position = loot_position
		_enter_state(State.RUSH)

# Hörsel
func hear_noise(pos: Vector3) -> void:
	# Under en jakt bryr sig vakten inte om ljud
	if state in [State.CHASE, State.PURSUE, State.ATTACK]:
		return

	# Vänd mot ljudet om det kommer från sidan eller bakom vakten.
	if _angle_to(pos) > hear_turn_min_angle:
		_heard_position = pos
		_hear_turn_timer = hear_turn_time

	# Undersök ljudet, men behåll valvmålet under RUSH.
	if state != State.RUSH:
		investigate_position = pos
		_enter_state(State.INVESTIGATE)

func _turn_towards_sound(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	anim.play("Idle")

	var dir := _heard_position - global_position
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	# Vakten tittar längs -Z, så vinkeln räknas därifrån
	var target_yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-hear_turn_speed * delta))

## Vinkeln mellan vaktens riktning och ljudet.
func _angle_to(pos: Vector3) -> float:
	var to_pos := pos - global_position
	to_pos.y = 0.0
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if to_pos.length() < 0.01:
		return 0.0
	return rad_to_deg(forward.angle_to(to_pos))
