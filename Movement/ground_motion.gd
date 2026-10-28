extends RefCounted
## Shared collision-tested stepping for small kerbs and floor thresholds.
const MAX_STEP_HEIGHT := 0.25

static func move(body: CharacterBody3D, delta: float) -> void:
	var motion := Vector3(body.velocity.x, 0, body.velocity.z) * delta
	if body.is_on_floor() and body.velocity.y <= 0.0 and motion.length_squared() > 0.000001:
		var hit := KinematicCollision3D.new()
		var start := body.global_transform
		if body.test_move(start, motion, hit) and hit.get_normal().dot(Vector3.UP) < cos(body.floor_max_angle):
			var lift := Vector3.UP * MAX_STEP_HEIGHT
			var raised := start.translated(lift)
			# Check headroom and forward clearance before looking for a landing.
			if not body.test_move(start, lift) and not body.test_move(raised, motion):
				var landing := raised.translated(motion)
				# At a kerb edge Jolt reports the capsule's rounded contact normal,
				# not necessarily the flat top's normal. Upward support is sufficient;
				# the full capsule has already cleared the obstacle at raised height.
				if body.test_move(landing, -lift, hit) and hit.get_normal().dot(Vector3.UP) > 0.01:
					var height := MAX_STEP_HEIGHT + hit.get_travel().y
					if height > 0.001:
						body.global_position.y += height
	body.move_and_slide()
	if not body.is_on_floor() and body.velocity.y <= 0.0:
		body.apply_floor_snap()
