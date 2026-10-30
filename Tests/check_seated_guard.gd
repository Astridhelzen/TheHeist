extends SceneTree
var failures=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
 print(label,": ",ok)
 if not ok: failures+=1
func run():
 var level=load("res://Level2.tscn").instantiate()
 root.add_child(level)
 for g in get_nodes_in_group("guards"): g.set_physics_process(false)
 var guard=level.get_node("DeskStation/Guard")
 var player=level.get_node("Player")
 player.set_physics_process(false)
 await create_timer(1.0).timeout
 check(guard.seated and guard.anim.current_animation=="Seated","starts seated")
 check(level.get_node("DeskStation/Desk/ScreenGlow").light_energy>0,"screen light enabled")
 player.position=Vector3(-2.7,6.61,-4.5)
 guard.target=player
 await create_timer(.15).timeout
 check(guard._can_see_player(),"sees player beside desk")
 guard._state_idle()
 check(guard.state==guard.State.CHASE and not guard.seated,"sight triggers chase and stand")
 var start=guard.position
 guard.set_physics_process(true)
 await create_timer(1.8).timeout
 check(guard.position.distance_to(start)>1.0,"leaves chair and moves around desk")
 print("GUARD position=",guard.global_position," state=",guard.state)
 guard.set_physics_process(false)
 # En vägg ska blockera sikt även för skrivbordsvakten.
 var wall=StaticBody3D.new()
 level.add_child(wall)
 var shape=CollisionShape3D.new()
 var box=BoxShape3D.new()
 box.size=Vector3(4,3,.3)
 shape.shape=box
 wall.add_child(shape)
 guard.global_position=Vector3(-4,6.61,0)
 player.position=Vector3(-4,6.61,-4)
 wall.position=Vector3(-4,7.6,-2)
 await create_timer(.15).timeout
 check(not guard._has_line_of_sight(),"wall blocks detection")
 check(level.get_node("Coins").get_node_or_null("OfficeCoin6")!=null,"six room coins exist")
 print("Failures: ",failures)
 quit(1 if failures else 0)

