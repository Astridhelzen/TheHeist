extends Node3D

const CollisionBuilder = preload("res://Levels/Level_1_Files/bank_collision.gd")
@export var player_path: NodePath
@export var bank_path: NodePath
@export var interaction_distance := 1.65
@export var open_angle := 100.0
@export_group("Sounds")
@export var pickup_sound: AudioStream = preload("res://Assets/Sounds/pick_up_access_card.ogg")
@export var scan_sound: AudioStream = preload("res://Assets/Sounds/scan_access_card.ogg")
@export var vault_open_sound: AudioStream = preload("res://Assets/Sounds/vault_opens.mp3")
var has_card := false
var is_unlocked := false
var _busy := false
var _elapsed := 0.0
var _door_body: AnimatableBody3D
@onready var _player: CharacterBody3D = get_node(player_path)
@onready var _bank: Node3D = get_node(bank_path)
@onready var _hinge: Node3D = _bank.get_node("VaultDoor")
@onready var _card: Node3D = $Card
@onready var _reader: Node3D = $Reader
@onready var _hud: Control = $CanvasLayer/HUD
@onready var _marker: Label3D = $Marker

func _ready() -> void:
 # Replace the old paper and numeric keypad visually; retain the bank source asset.
 pass # Level2 uses its own vault layout.
 for node in _bank.find_children("Vault_Keypad*", "Node3D", true, false):
  node.hide()
 _hinge.rotation.y = 0.0
 _door_body = AnimatableBody3D.new()
 _door_body.name = "VaultDoorCollision"
 _door_body.sync_to_physics = false
 _hinge.add_child(_door_body)
 var collision := CollisionShape3D.new()
 _door_body.add_child(collision)
 collision.shape = CollisionBuilder.build_shape(_hinge, _door_body)

func _physics_process(delta: float) -> void:
 _elapsed += delta
 _marker.position = _card.position + Vector3(0, 0.39 + sin(_elapsed * 2.4) * 0.035, 0)
 _marker.visible = not has_card
 _hud.has_card = has_card
 _hud.unlocked = is_unlocked
 _hud.prompt = ""
 if not _busy and not is_unlocked:
  if not has_card and _can_reach(_card.global_position + Vector3(0, 0.06, 0)):
   _hud.prompt = "[E]  Pick up access card"
  elif _can_reach(_reader.global_position + Vector3(0, 0, 0.13)):
   _hud.prompt = "[E]  Scan access card" if has_card else "Access card required"
 _hud.queue_redraw()

func _can_reach(target: Vector3) -> bool:
 var offset := _player.global_position - target
 if Vector2(offset.x, offset.z).length() > interaction_distance or absf(offset.y) > 1.8:
  return false
 var query := PhysicsRayQueryParameters3D.create(_player.global_position + Vector3(0, 1.45, 0), target, 1, [_player.get_rid()])
 query.hit_back_faces = true
 return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
  if try_interact():
   get_viewport().set_input_as_handled()

func try_interact() -> bool:
 if _busy or is_unlocked or get_tree().paused:
  return false
 if not has_card and _can_reach(_card.global_position + Vector3(0, 0.06, 0)):
  _pick_up()
  return true
 if _can_reach(_reader.global_position + Vector3(0, 0, 0.13)):
  if has_card:
   _unlock()
  else:
   _notify("Find the access card on the small table in the cloakroom")
  return true
 return false

func _pick_up() -> void:
 has_card = true
 _busy = true
 _marker.hide()
 _notify("Access card collected")
 _hud.set_objective("Open the vault")
 Sfx.play(pickup_sound)
 var tween := create_tween().set_parallel(true)
 tween.tween_property(_card, "position:y", _card.position.y + 0.32, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 tween.tween_property(_card, "rotation:y", _card.rotation.y + PI * 0.6, 0.3)
 tween.tween_property(_card, "scale", Vector3.ONE * 0.01, 0.18).set_delay(0.2)
 tween.chain().tween_callback(func():
  _card.hide()
  _busy = false
 )

func _unlock() -> void:
 is_unlocked = true
 _busy = true
 _notify("Access granted — opening vault")
 _hud.set_objective("Grab the money")
 Sfx.play(scan_sound)
 # Brief scan animation at the reader; the card remains in inventory.
 _card.show()
 _card.scale = Vector3.ONE
 _card.global_position = _reader.global_position + Vector3(0, -0.03, 0.12)
 _card.rotation = Vector3(PI / 2, 0, 0)
 var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
 tween.tween_property(_card, "position:y", _card.position.y + 0.13, 0.35)
 tween.tween_callback(_card.hide)
 tween.tween_callback(func(): Sfx.play(vault_open_sound))
 tween.tween_property(_hinge, "rotation:y", deg_to_rad(open_angle), 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 tween.tween_callback(func():
  # Both meshes include the entrance and street. Swap only once the physical
  # door is open so the vault route also matches the current collision layout.
  _bank.get_parent().get_node("GuardNavigation").navigation_mesh = preload("res://Levels/Level_2/GuardNavigationOpenVault.tres")
  _busy = false
 )

func _notify(message: String) -> void:
 _hud.notify(message)
