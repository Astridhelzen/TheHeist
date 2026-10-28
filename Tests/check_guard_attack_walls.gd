extends SceneTree
# Run: godot --headless --path . --script res://Tests/check_guard_attack_walls.gd
var failures := 0
var caught_count := 0
func _initialize():
 call_deferred("run")
func check(condition: bool, label: String):
 if not condition:
  failures += 1
  push_error(label)
 else:
  print("PASS: ", label)
func run():
 var world := Node3D.new()
 root.add_child(world)
 var region := NavigationRegion3D.new()
 var mesh := NavigationMesh.new()
 mesh.vertices = PackedVector3Array([Vector3(-5,0,-5),Vector3(5,0,-5),Vector3(5,0,5),Vector3(-5,0,5)])
 mesh.add_polygon(PackedInt32Array([0,1,2,3]))
 region.navigation_mesh = mesh
 world.add_child(region)
 var player := CharacterBody3D.new()
 var capsule := CollisionShape3D.new()
 capsule.shape = CapsuleShape3D.new()
 capsule.position.y = 1.0
 player.add_child(capsule)
 world.add_child(player)
 player.position = Vector3(0,0,-1.5)
 root.get_node("PlayerManager").player = player
 var guard = load("res://Guard/guard.tscn").instantiate()
 world.add_child(guard)
 guard.set_physics_process(false)
 guard.player_caught.connect(func(): caught_count += 1)
 var wall := StaticBody3D.new()
 var wall_shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(3,3,0.15)
 wall_shape.shape = box
 wall.add_child(wall_shape)
 world.add_child(wall)
 wall.position = Vector3(0,1,-0.75)
 for i in range(20): await physics_frame
 guard.agent.target_position = player.position
 guard._enter_state(guard.State.CHASE)
 guard._state_chase(0.1)
 check(guard.state == guard.State.PURSUE, "Wall prevents CHASE from starting an attack")
 guard._state_pursue(0.1)
 check(guard.state == guard.State.PURSUE, "Wall prevents PURSUE from starting an attack")
 wall.position.x = 10
 await physics_frame
 await physics_frame
 guard._enter_state(guard.State.CHASE)
 guard._state_chase(0.1)
 check(guard.state == guard.State.ATTACK, "Nearby unobstructed player can be attacked")
 guard._state_attack(0.2)
 check(caught_count == 0, "Capture still requires its delay")
 wall.position.x = 0
 await physics_frame
 await physics_frame
 guard._state_attack(0.3)
 check(caught_count == 0 and guard.state == guard.State.PURSUE, "A new obstacle cancels capture mid-attack")
 check(guard.attack_timer == 0.0 and guard.anim.current_animation != "Attack", "Cancellation clears timer and kick animation")
 wall.position.x = 10
 await physics_frame
 await physics_frame
 guard._enter_state(guard.State.CHASE)
 guard._state_chase(0.1)
 guard._state_attack(0.2)
 check(caught_count == 0, "A new attack does not reuse previous progress")
 guard._state_attack(0.21)
 check(caught_count == 1, "Unobstructed attack catches the player after the full delay")
 guard._state_attack(1.0)
 check(caught_count == 1, "Capture signal is emitted only once")
 root.get_node("PlayerManager").player = null
 world.queue_free()
 await process_frame
 print("Attack regression failures: ", failures)
 quit(1 if failures else 0)
