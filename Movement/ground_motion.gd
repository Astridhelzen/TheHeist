extends RefCounted
## Gemensam rörelse över låga kanter för spelare och vakter.

## Steghöjd i meter. Den rundade kapseln kan nå något högre.
const MAX_STEP_HEIGHT := 0.25
## Sök en bit framåt så att kapseln inte fastnar på kanten.
const LOOK_AHEAD := 0.12
## Tillåt steg även när kroppen är strax ovanför golvet.
const GROUND_PROBE := 0.15


static func move(body: CharacterBody3D, delta: float) -> void:
	var motion := Vector3(body.velocity.x, 0, body.velocity.z) * delta
	if body.velocity.y <= 0.0 and motion.length_squared() > 0.000001 and _near_ground(body):
		_step_up(body, motion)
	body.move_and_slide()
	if not body.is_on_floor() and body.velocity.y <= 0.0:
		body.apply_floor_snap()


static func _near_ground(body: CharacterBody3D) -> bool:
	return body.is_on_floor() or body.test_move(body.global_transform, Vector3.DOWN * GROUND_PROBE)


## Kliv upp om kanten är låg och det finns plats.
static func _step_up(body: CharacterBody3D, motion: Vector3) -> void:
	var start := body.global_transform
	var ahead := motion.normalized() * maxf(motion.length(), LOOK_AHEAD)
	var hit := KinematicCollision3D.new()
	if not body.test_move(start, ahead, hit):
		return   # Fri väg.
	if hit.get_normal().y > 0.95:
		return   # Bara golvet.
	var lift := Vector3.UP * MAX_STEP_HEIGHT
	if body.test_move(start, lift):
		return   # För lågt i tak.
	var raised := start.translated(lift)
	if body.test_move(raised, ahead):
		return   # Hindret är för högt.
	# Sök stöd på kanten. Jolt kan ge en rundad kontaktnormal från kapseln.
	var landing := raised.translated(ahead)
	var support := KinematicCollision3D.new()
	if not body.test_move(landing, -lift, support) or support.get_normal().y < 0.01:
		return
	var height := MAX_STEP_HEIGHT + support.get_travel().y
	if height > 0.005 and height <= MAX_STEP_HEIGHT:
		body.global_position.y += height
