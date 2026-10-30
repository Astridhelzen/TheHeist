extends SceneTree

var failures := 0

func _initialize():
	call_deferred("run")

func run():
	for scene in ["res://Levels/Level_1/Level_1.tscn", "res://Level2.tscn"]:
		var level = load(scene).instantiate()
		root.add_child(level)
		var player = level.get_node("Player")
		player.set_physics_process(false)
		player.position = Vector3(100, 30, 100)
		for g in get_nodes_in_group("guards"):
			g.set_physics_process(false)
			g.target = null
		var guard = level.get_node("Guard")
		level.get_node("Caught").queue_free()
		for i in range(20): await physics_frame
		var routes: Array = []
		if "Level_1" in scene:
			routes = [
				["between desks", Vector3(-1.986, 0, -1), Vector3(-1.986, 0, -4.5)],
				["card desk left side", Vector3(-8.68, 0, -1.3), Vector3(-8.68, 0, -4.5)],
				["behind card desk", Vector3(-8.68, 0, -4.5), Vector3(-6.1, 0, -4.5)],
				["partition doorway", Vector3(4, 0, -0.8), Vector3(6.1, 0, -0.8)],
			]
		else:
			for x in [-5.0, -2.285, 0.0]:
				routes.append(["stairs %s" % x, Vector3(x, 1.7, -42), Vector3(x, 6.7, -31.5)])
		# Testa spelare och vakter genom passagerna i båda riktningarna.
		for route in routes:
			for actor in [player, guard]:
				for backwards in [false, true]:
					var start: Vector3 = route[2] if backwards else route[1]
					var goal: Vector3 = route[1] if backwards else route[2]
					actor.global_position = start
					actor.velocity = Vector3.ZERO
					for i in range(30):
						await physics_frame
						actor.velocity = Vector3(0, -1, 0)
						actor.move_and_slide()
					var direction = (goal - start) * Vector3(1, 0, 1)
					direction = direction.normalized()
					for i in range(420):
						await physics_frame
						if ((goal - actor.global_position) * Vector3(1, 0, 1)).length() < 0.15: break
						actor.velocity.x = direction.x * 3.0
						actor.velocity.z = direction.z * 3.0
						actor.velocity.y = 0.0 if actor.is_on_floor() else actor.velocity.y - 9.8 / 60
						preload("res://Movement/ground_motion.gd").move(actor, 1.0 / 60.0)
					var distance = ((goal - actor.global_position) * Vector3(1, 0, 1)).length()
					print(route[0], " ", actor.name, " reverse=", backwards, " distance=", distance, " final=", actor.global_position)
					if distance > 0.3:
						failures += 1
						for c in range(actor.get_slide_collision_count()):
							print("BLOCK ", actor.get_slide_collision(c).get_collider().get_path())
					actor.position = Vector3(100, 30, 100)
		# Testa även vaktens tillstånd och navigation.
		if "Level_1" in scene:
			level.get_node("AccessCard")._unlock()
			await create_timer(2.3).timeout
			routes.append(["open vault", Vector3(7.8, 0, -4), Vector3(4, 0, 2.5)])
		for route in routes:
			for backwards in [false, true]:
				guard.position = route[2] if backwards else route[1]
				var goal: Vector3 = route[1] if backwards else route[2]
				guard.velocity = Vector3.ZERO
				guard.investigate_position = goal
				guard._enter_state(guard.State.RUSH)
				guard.set_physics_process(true)
				for i in range(700):
					await physics_frame
					if ((guard.position - goal) * Vector3(1, 0, 1)).length() < 0.4: break
				guard.set_physics_process(false)
				var distance = ((guard.position - goal) * Vector3(1, 0, 1)).length()
				print("NAV ", route[0], " reverse=", backwards, " distance=", distance, " final=", guard.position)
				if distance > 0.5: failures += 1
		level.queue_free()
		for i in range(5): await physics_frame
	print("Passage failures: ", failures)
	quit(1 if failures else 0)
