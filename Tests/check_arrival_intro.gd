extends SceneTree
var failures:=0
func _initialize(): call_deferred("run")
func check(ok:bool,label:String):
 print(label,": ",ok)
 if not ok: failures+=1
func run():
 for path in ["res://Levels/Level_1/Level_1.tscn","res://Level2.tscn"]:
  for skip in [true,false]:
   set_meta("arrival_level",path)
   var intro=load("res://Cinematics/arrival_intro.tscn").instantiate()
   root.add_child(intro)
   current_scene=intro
   var level=intro.level
   var hud=intro.hud
   for i in range(5): await process_frame
   check(hud.elapsed_time==0,"timer frozen")
   check(not level.get_node("Player").is_processing(),"player frozen")
   if skip: intro._finish()
   else:
    while is_instance_valid(intro): await process_frame
   for i in range(5): await physics_frame
   check(current_scene==level,"level handed over")
   check(hud.timer_running and hud.visible,"HUD started")
   check(level.get_node("Player").camera.current,"game camera restored")
   check(level.get_node("BankExterior/GetawayPickup/ParkedCollision")!=null,"parked car")
   check(not paused,"not paused")
   print(path," skip=",skip," spawn=",level.get_node("Player").position)
   level.queue_free()
   for i in range(5): await process_frame
 print("Intro failures: ",failures)
 quit(1 if failures else 0)
