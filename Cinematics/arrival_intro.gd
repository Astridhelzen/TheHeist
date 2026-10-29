extends Node3D
## Menu-only arrival sequence. The level is frozen until control is handed over.
const CAR = preload("res://Assets/Models/car/2004_mazda_b-series_un_2500_double_cab/scene.gltf")
const DEFAULT_LEVEL := "res://Levels/Level_1/Level_1.tscn"
const DRIVE_TIME := 4.2
const EXIT_START := 4.8
const END_TIME := 7.5

var level: Node3D
var player: CharacterBody3D
var exterior: Node3D
var car: Node3D
var camera: Camera3D
var hud: Control
var overlay: CanvasLayer
var fade: ColorRect
var parked := Vector3(31, 6, 31)
var spawn := Vector3.ZERO
var elapsed := 0.0
var finished := false
var stepping_out := false
var wheel_axles: Array[Node3D] = []

func _ready() -> void:
 var path: String = get_tree().get_meta("arrival_level", DEFAULT_LEVEL)
 if get_tree().has_meta("arrival_level"):
  get_tree().remove_meta("arrival_level")
 var packed = load(path) as PackedScene
 if packed == null:
  get_tree().change_scene_to_file("res://UI/main_menu.tscn")
  return
 level = packed.instantiate()
 level.process_mode = Node.PROCESS_MODE_DISABLED
 add_child(level)
 player = level.get_node("Player")
 exterior = level.get_node("BankExterior")
 hud = get_tree().get_first_node_in_group("hud")
 hud.hide()
 hud.timer_running = false
 player.hide()
 player.get_node("NoiseRing").hide()
 player.camera_input_enabled = false
 parked = exterior.get_node("GetawayBody").position - Vector3(0, 0.6, 0)
 spawn = exterior.to_global(parked + Vector3(3.1, 0.02, -1.6))
 _build_car()
 camera = Camera3D.new()
 camera.near = 0.15
 camera.far = 250.0
 camera.fov = 55
 add_child(camera)
 camera.make_current()
 _build_overlay()
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 _update_shot(0.0)

func _build_car() -> void:
 # Replace the old blockout car at the existing escape location.
 for child in exterior.get_children():
  if child.name.begins_with("Getaway") or child.name.begins_with("Wheel"):
   exterior.remove_child(child)
   child.queue_free()
 car = Node3D.new()
 car.name = "GetawayPickup"
 exterior.add_child(car)
 var model = CAR.instantiate()
 car.add_child(model)
 # Source units are centimetres; rotate its +X nose along the arrival road (+Z).
 model.scale = Vector3.ONE * (5.2 / 513.4083)
 model.rotation.y = -PI / 2
 # The source groups each axle's tyres/rims into these four mesh parts.
 for front in [true, false]:
  var axle := Node3D.new()
  car.add_child(axle)
  var unit := 5.2 / 513.4083
  axle.position = Vector3(0, 34.6066 * unit, (170.8218 if front else -125.8477) * unit)
  for index in range(77 if front else 81, 81 if front else 85):
   var wheel = model.find_child("Object_%d" % index, true, false)
   if wheel != null: wheel.reparent(axle, true)
  wheel_axles.append(axle)
 car.position = parked + Vector3(0, 0, -17)

func _build_overlay() -> void:
 overlay = CanvasLayer.new()
 overlay.layer = 100
 add_child(overlay)
 var ui := Control.new()
 overlay.add_child(ui)
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for bottom in [false, true]:
  var bar := ColorRect.new()
  ui.add_child(bar)
  bar.color = Color(0.025, 0.03, 0.04)
  bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
  bar.offset_top = -64 if bottom else 0
  bar.offset_bottom = 0 if bottom else 64
 var label := Label.new()
 ui.add_child(label)
 label.position = Vector2(32, 19)
 label.text = "THE HEIST  /  ARRIVAL"
 label.add_theme_font_override("font", preload("res://UI/Fonts/overline.tres"))
 label.add_theme_color_override("font_color", Color("efc260"))
 var skip := Button.new()
 ui.add_child(skip)
 skip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
 skip.offset_left = -255
 skip.offset_top = -52
 skip.offset_right = -24
 skip.offset_bottom = -12
 skip.text = "SKIP INTRO  [SPACE]"
 skip.theme = preload("res://UI/Themes/ui_theme.tres")
 skip.pressed.connect(_finish)
 fade = ColorRect.new()
 ui.add_child(fade)
 fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fade.color = Color.BLACK
 fade.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_ESCAPE]:
  get_viewport().set_input_as_handled()
  _finish()

func _process(delta: float) -> void:
 if finished or not is_instance_valid(level): return
 elapsed += delta
 _update_shot(elapsed)
 if stepping_out:
  player.animation_player.advance(delta)
 if elapsed >= END_TIME: _finish()

func _update_shot(time: float) -> void:
 var progress := clampf(time / DRIVE_TIME, 0, 1)
 # Smooth braking as the pickup reaches the escape parking space.
 var eased := 1.0 - pow(1.0 - progress, 2.0)
 car.position = parked + Vector3(0, 0, lerpf(-17.0, 0.0, eased))
 for axle in wheel_axles:
  axle.rotation.x = 17.0 * eased / 0.3505
 if time < EXIT_START:
  camera.global_position = exterior.to_global(parked + Vector3(7.0, 3.2, 6.0))
  camera.look_at(car.global_position + Vector3.UP * 0.85)
  fade.color.a = maxf(1.0 - time / 0.5, clampf((time - 4.5) / 0.3, 0, 1))
 else:
  if not stepping_out:
   stepping_out = true
   player.show()
   player.animation_player.play("movement/walking")
   var facing := (exterior.global_basis * Vector3(1.85, 0, -2.3)).normalized()
   player.character_model.global_rotation.y = atan2(facing.x, facing.z)
  var step := clampf((time - EXIT_START) / 1.3, 0, 1)
  var side := parked + Vector3(lerpf(1.25, 3.1, step), 0.02 + 0.38 * pow(1.0-step, 2), lerpf(0.7, -1.6, step))
  player.global_position = exterior.to_global(side)
  if step >= 1.0: player.animation_player.play("movement/idle", 0.2)
  camera.global_position = exterior.to_global(parked + Vector3(6.0, 2.4, 3.0))
  camera.look_at(exterior.to_global(parked + Vector3(2.2, 0.9, -0.4)))
  fade.color.a = maxf(1.0 - (time - EXIT_START) / 0.25, clampf((time - 7.15) / 0.35, 0, 1))

func _finish() -> void:
 if finished or not is_instance_valid(level): return
 finished = true
 car.position = parked
 # Only the parked car blocks movement; no animated collider pushes actors.
 var body := StaticBody3D.new()
 body.name = "ParkedCollision"
 car.add_child(body)
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = Vector3(1.95, 1.35, 5.0)
 collider.shape = shape
 collider.position.y = 0.85
 body.add_child(collider)
 player.global_position = spawn
 player.velocity = Vector3.ZERO
 player.show()
 player.camera_input_enabled = true
 var towards_bank := -exterior.global_basis.x.normalized()
 # Face the first nearby coin so the arrival naturally leads into the route.
 var coins := level.get_node_or_null("Coins")
 var nearest_distance := INF
 if coins != null:
  for coin in coins.get_children():
   if not coin is Node3D: continue
   var direction: Vector3 = coin.global_position - spawn
   direction.y = 0
   if direction.length_squared() < nearest_distance and direction.length_squared() > 0.01:
    nearest_distance = direction.length_squared()
    towards_bank = direction.normalized()
 player.camera_pivot.global_rotation = Vector3(-0.08, atan2(-towards_bank.x, -towards_bank.z), 0)
 player.character_model.global_rotation.y = atan2(towards_bank.x, towards_bank.z)
 player.animation_player.play("movement/idle")
 player.camera.make_current()
 player.reset_physics_interpolation()
 hud.elapsed_time = 0
 hud.timer_running = true
 hud.show()
 level.reparent(get_tree().root)
 get_tree().current_scene = level
 level.process_mode = Node.PROCESS_MODE_INHERIT
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 queue_free()
