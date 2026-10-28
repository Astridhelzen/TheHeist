extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func run():
 for path in ["res://Levels/Level_1/Level_1.tscn","res://Level2.tscn"]:
  var level=load(path).instantiate()
  root.add_child(level)
  for guard in get_nodes_in_group("guards"): guard.set_physics_process(false)
  var player=level.get_node("Player")
  player.set_physics_process(false)
  var exterior=level.get_node("BankExterior")
  var barrier=exterior.get_node("EdgeBarriers")
  for i in range(20): await physics_frame
  var west=barrier.west_edge
  var cases=[
   [Vector3(30,6.1,-43),Vector3(0,0,-4)],
   [Vector3(30,6.1,53),Vector3(0,0,4)],
   [Vector3(65,6.1,0),Vector3(4,0,0)],
   [Vector3(west+1.2,6.1,-40),Vector3(-4,0,0)],
   [Vector3(west+1.2,6.1,45),Vector3(-4,0,0)]
  ]
  for c in cases:
   player.global_position=exterior.to_global(c[0])
   await physics_frame
   var hit=player.move_and_collide(exterior.global_basis*c[1])
   var p=exterior.to_local(player.global_position)
   var safe=hit!=null and p.x>=west and p.x<=67 and p.z>=-45 and p.z<=55
   if not safe: failures+=1
   print(path," edge ",c[0]," stopped ",safe," position ",p)
  # Check barriers alone leave an opening for the entrance and ignore camera rays.
  var mid=(barrier.entrance_start+barrier.entrance_end)/2
  var space=level.get_world_3d().direct_space_state
  var query=PhysicsRayQueryParameters3D.create(exterior.to_global(Vector3(west+2,7,mid)),exterior.to_global(Vector3(west-2,7,mid)),32)
  query.exclude=[player.get_rid()]
  if not space.intersect_ray(query).is_empty(): failures+=1
  if player.camera_arm.collision_mask & 32: failures+=1
  level.queue_free()
  for i in range(5): await physics_frame
 print("Boundary failures: ",failures)
 quit(failures)
