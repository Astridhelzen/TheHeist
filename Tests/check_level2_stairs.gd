extends SceneTree
func _initialize(): call_deferred("run")
func key(code, pressed):
 var event = InputEventKey.new()
 event.keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)
func run():
 var level=load("res://Level2.tscn").instantiate()
 root.add_child(level)
 for g in get_nodes_in_group("guards"): g.set_physics_process(false)
 var p=level.get_node("Player")
 var failures := 0
 for x in [-5.0,-2.285,0.0]:
  for up in [true,false]:
   key(KEY_W,false)
   key(KEY_SHIFT,false)
   p.global_position=Vector3(x,1.7 if up else 6.7,-41.5 if up else -32.0)
   p.velocity=Vector3.ZERO
   p.camera_pivot.rotation=Vector3(0,PI if up else 0.0,0)
   for i in range(35): await physics_frame
   key(KEY_W,true)
   key(KEY_SHIFT,true)
   for i in range(180): await physics_frame
   print("RUN ",x," up ",up," final ",p.global_position)
   if (up and p.global_position.z < -32.0) or (not up and p.global_position.z > -41.5):
    failures += 1
   if abs(p.character_model.position.y) > 0.15:
    failures += 1
   for i in range(p.get_slide_collision_count()):
    var c=p.get_slide_collision(i)
    print("HIT ",c.get_collider().get_path()," normal ",c.get_normal())
 key(KEY_W,false)
 key(KEY_SHIFT,false)
 print("Stair regression failures: ", failures)
 quit(1 if failures else 0)

