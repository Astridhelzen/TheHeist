extends RefCounted
## Shared collision-tested stepping for small kerbs, floor thresholds and the
## edges of raised floors. Used by the player and the guards:
##     preload("res://Movement/ground_motion.gd").move(self, delta)

## The highest edge a character steps up onto by itself (metres). In practice
## a little more (about 0.3 m), as the rounded capsule first rides up the edge.
const MAX_STEP_HEIGHT := 0.25
## How far ahead to look for an edge. A walking guard only moves ~3 cm per
## frame, so without looking ahead the rounded bottom of the capsule rides up
## onto the edge first and then hangs on it, off the floor, and never steps.
const LOOK_AHEAD := 0.12
## Counts as standing when the ground is this close below (also when the
## capsule is hanging on an edge a few centimetres above the floor).
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


## Lifts the body onto an edge in front of it, if the edge is low enough and
## there is room to stand on top of it.
static func _step_up(body: CharacterBody3D, motion: Vector3) -> void:
	var start := body.global_transform
	var ahead := motion.normalized() * maxf(motion.length(), LOOK_AHEAD)
	var hit := KinematicCollision3D.new()
	if not body.test_move(start, ahead, hit):
		return   # nothing in the way
	if hit.get_normal().y > 0.95:
		return   # only the flat floor itself
	var lift := Vector3.UP * MAX_STEP_HEIGHT
	if body.test_move(start, lift):
		return   # no headroom
	var raised := start.translated(lift)
	if body.test_move(raised, ahead):
		return   # still blocked when raised: a wall or something tall
	# Look down from above the edge for something to stand on.
	# At an edge Jolt reports the capsule's rounded contact normal rather than
	# the flat top's normal, so any upward support is accepted here.
	var landing := raised.translated(ahead)
	var support := KinematicCollision3D.new()
	if not body.test_move(landing, -lift, support) or support.get_normal().y < 0.01:
		return
	var height := MAX_STEP_HEIGHT + support.get_travel().y
	if height > 0.005 and height <= MAX_STEP_HEIGHT:
		body.global_position.y += height
