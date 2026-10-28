extends SceneTree

func _initialize(): call_deferred("run")

func key(code, pressed):
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func run():
	var level = load("res://Level2.tscn").instantiate()
	root.add_child(level)
	for guard in get_nodes_in_group("guards"): guard.set_physics_process(false)
	var player = level.get_node("Player")
	var failures := 0
	for x in [-9.0, 4.4]:
		for uphill in [true, false]:
			player.position = Vector3(x, 6.7 if uphill else 10.7, -32 if uphill else -40)
			player.velocity = Vector3.ZERO
			player.camera_pivot.rotation = Vector3(0, 0 if uphill else PI, 0)
			for i in range(30): await physics_frame
			key(KEY_W, true)
			key(KEY_SHIFT, true)
			var previous_y: float = player.position.y
			var biggest_step := 0.0
			for i in range(160):
				await physics_frame
				biggest_step = maxf(biggest_step, absf(player.position.y - previous_y))
				previous_y = player.position.y
				if (uphill and player.position.z < -39.5) or (not uphill and player.position.z > -32): break
			key(KEY_W, false)
			key(KEY_SHIFT, false)
			var reached: bool = player.position.z < -39.5 if uphill else player.position.z > -32
			print("UPPER x=", x, " uphill=", uphill, " reached=", reached, " max height/frame=", biggest_step)
			if not reached or biggest_step > 0.1: failures += 1
	print("Upper stair failures: ", failures)
	quit(1 if failures else 0)
