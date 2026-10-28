extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var failures=0
 for scene in ["res://Levels/Level_1_Files/Level_1.tscn","res://Level2.tscn"]:
  var level=load(scene).instantiate()
  root.add_child(level)
  for g in get_nodes_in_group("guards"): g.set_physics_process(false)
  var player=level.get_node("Player")
  player.set_physics_process(false)
  player.global_position=Vector3(100,30,100)
  level.get_node("Caught").queue_free()
  var guard=level.get_node("Guard")
  guard.target=null
  for i in range(20): await physics_frame
  var start=Vector3(1,0.2,3) if "Level_1" in scene else Vector3(16,6.8,20)
  var goal=Vector3(-8.886,0,11.1675) if "Level_1" in scene else Vector3(26.8,6.8,31)
  if "Level2" in scene:
   level.get_node("BasementVault/AccessCard")._unlock()
   await create_timer(2.3).timeout
  guard.global_position=start
  player.global_position=goal
  guard.target=player
  guard.lights_on=true
  guard.investigate_position=goal
  guard._enter_state(guard.State.CHASE)
  guard.set_physics_process(true)
  for i in range(600):
   await physics_frame
   if guard.state==guard.State.ATTACK: break
  print(scene," OUT ",guard.global_position," target ",goal)
  if Vector2(guard.position.x-goal.x,guard.position.z-goal.z).length()>2.5:
   failures+=1
   for j in range(guard.get_slide_collision_count()): print("BLOCK ",guard.get_slide_collision(j).get_collider().get_path())
  guard.target=null
  guard.investigate_position=start
  guard._enter_state(guard.State.RUSH)
  for i in range(600):
   await physics_frame
   if guard.state==guard.State.INVESTIGATE: break
  print(scene," BACK ",guard.global_position)
  if Vector2(guard.position.x-start.x,guard.position.z-start.z).length()>2.5:
   failures+=1
   for j in range(guard.get_slide_collision_count()): print("BLOCK ",guard.get_slide_collision(j).get_collider().get_path())
  level.queue_free()
  for i in range(5): await physics_frame
 print("FAILURES ",failures)
 quit(failures)

