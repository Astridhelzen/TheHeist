extends SceneTree

const GroundMotion = preload("res://Movement/ground_motion.gd")
var failures := 0

func _initialize(): call_deferred("run")

func box(world: Node3D, size: Vector3, pos: Vector3):
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	body.position = pos
	return body

func run():
	var world := Node3D.new()
	root.add_child(world)
	box(world, Vector3(20, 0.2, 20), Vector3(0, -0.1, 0))
	var actor := CharacterBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 2.0
	collision.shape = shape
	collision.position.y = 1
	actor.add_child(collision)
	world.add_child(actor)
	actor.floor_snap_length = 0.35
	actor.floor_constant_speed = true
	for case in [["kerb", 0.15, true], ["desk", 0.95, false], ["wall", 3.0, false]]:
		var obstacle = box(world, Vector3(4, case[1], 2), Vector3(0, case[1] / 2, 1))
		actor.position = Vector3(0, 0.1, -1)
		actor.velocity = Vector3.ZERO
		for i in range(120):
			await physics_frame
			actor.velocity = Vector3(0, 0 if actor.is_on_floor() else actor.velocity.y - 9.8 / 60, 3)
			GroundMotion.move(actor, 1.0 / 60)
		var passed: bool = actor.position.z > 2.5
		print(case[0], " crossed=", passed, " expected=", case[2], " final=", actor.position)
		if passed != case[2]: failures += 1
		obstacle.queue_free()
		await physics_frame
	print("Ground motion failures: ", failures)
	quit(1 if failures else 0)
