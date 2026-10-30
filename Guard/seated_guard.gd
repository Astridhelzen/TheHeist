extends "res://Guard/guard.gd"
## Sittande vakt med samma syn, hörsel och jakt som övriga vakter.
var seated := true
var stand_time := 0.0

func _ready() -> void:
	var library := anim.get_animation_library("").duplicate()
	library.add_animation("Seated", preload("res://Guard/seated_pose.tres"))
	anim.remove_animation_library("")
	anim.add_animation_library("", library)
	super._ready()
	var chair := get_node_or_null("../Chair/Body") as PhysicsBody3D
	if chair: add_collision_exception_with(chair)
	flashlight.position.y -= 0.4
	vision_ray.position.y = 1.05

func _stop_and_idle() -> void:
	if seated:
		velocity = Vector3.ZERO
		anim.play("Seated")
	else:
		super._stop_and_idle()

func _enter_state(new_state: State) -> void:
	if seated and new_state in [State.CHASE, State.INVESTIGATE, State.RUSH]:
		seated = false
		stand_time = 0.55
		anim.play("Idle", 0.5)
		flashlight.position.y += 0.4
		vision_ray.position.y += 0.4
	super._enter_state(new_state)

func _physics_process(delta: float) -> void:
	if stand_time > 0:
		stand_time -= delta
		velocity = Vector3.ZERO
		return
	super._physics_process(delta)
