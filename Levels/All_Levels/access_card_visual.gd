@tool
extends Node3D
## Bygger kort och läsare. Kortet svävar tills det plockas upp.

@export var reader: bool = false

@export_group("Floating card")
## Höjd över bordet i meter.
@export var float_height := 0.3
@export var bob_height := 0.04
@export var bob_speed := 2.0
## Rotationshastighet i radianer per sekund.
@export var spin_speed := 1.2
## Kortets lutning.
@export var tilt_degrees := 65.0
## Skala medan kortet svävar.
@export var float_scale := 2.0
@export var ring_color := Color("e5b04a")

var _pivot: Node3D
var _ring: MeshInstance3D
var _floating := false
var _time := 0.0

func _ready() -> void:
 if get_child_count() > 0:
  return
 if reader:
  _box(Vector3(0.38, 0.55, 0.055), Vector3.ZERO, Color("172932"))
  _box(Vector3(0.29, 0.07, 0.012), Vector3(0, 0.17, 0.034), Color("54c9bb"), true)
  _box(Vector3(0.24, 0.006, 0.015), Vector3(0, -0.15, 0.034), Color("050e14"))
  _label("CARD ACCESS", Vector3(0, 0.065, 0.038), Vector3.ZERO, 0.0011)
  _label("HOLD CARD HERE", Vector3(0, -0.055, 0.038), Vector3.ZERO, 0.00065)
  return
 # Animera delarna i en pivot utan att flytta kortets rotnod.
 _pivot = Node3D.new()
 _pivot.name = "Float"
 add_child(_pivot)
 _box(Vector3(0.22, 0.008, 0.14), Vector3.ZERO, Color("e5e9df"), false, _pivot)
 _box(Vector3(0.045, 0.002, 0.14), Vector3(-0.087, 0.005, 0), Color("239c99"), false, _pivot)
 _box(Vector3(0.036, 0.002, 0.028), Vector3(-0.028, 0.005, 0.025), Color("ddbb66"), false, _pivot)
 _label("THE HEIST", Vector3(0.015, 0.007, -0.036), Vector3(-PI / 2, 0, 0), 0.0005, _pivot)
 _label("VAULT ACCESS", Vector3(0.025, 0.007, -0.009), Vector3(-PI / 2, 0, 0), 0.00035, _pivot)
 # Animera bara under spel.
 if Engine.is_editor_hint():
  return
 _floating = true
 _pivot.scale = Vector3.ONE * float_scale
 # Svagt ljus så att kortet syns i mörkret.
 for part in _pivot.get_children():
  _make_glow(part)
 _time = randf() * TAU
 _add_ring()
 visibility_changed.connect(_on_visibility_changed)

func _process(delta: float) -> void:
 if not _floating:
  return
 _time += delta
 _pivot.position.y = float_height + sin(_time * bob_speed) * bob_height
 # Luta kortet och snurra runt lodaxeln.
 _pivot.rotation = Vector3(deg_to_rad(tilt_degrees), _time * spin_speed, 0)
 # Låt ringen pulsera med kortets rörelse.
 var glow := 0.5 + 0.5 * sin(_time * bob_speed)
 var ring_material := _ring.material_override as StandardMaterial3D
 ring_material.albedo_color.a = 0.35 + 0.4 * glow
 _ring.scale = Vector3.ONE * (1.0 + 0.08 * glow)

func _add_ring() -> void:
 var torus := TorusMesh.new()
 torus.inner_radius = 0.17
 torus.outer_radius = 0.2
 torus.rings = 48
 torus.ring_segments = 8
 var material := StandardMaterial3D.new()
 material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.albedo_color = ring_color
 _ring = MeshInstance3D.new()
 _ring.name = "Ring"
 _ring.mesh = torus
 _ring.material_override = material
 _ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # Platta ut glöden mot bordet.
 _ring.scale = Vector3(1, 0.15, 1)
 _ring.position.y = 0.006
 add_child(_ring)

func _make_glow(part: Node) -> void:
 if not part is MeshInstance3D:
  return
 var material := (part as MeshInstance3D).mesh.material as StandardMaterial3D
 material.emission_enabled = true
 material.emission = material.albedo_color
 material.emission_energy_multiplier = 0.45

func _on_visibility_changed() -> void:
 if visible:
  return
 # Stoppa svävandet när kortet plockas upp.
 _floating = false
 _pivot.position = Vector3.ZERO
 _pivot.rotation = Vector3.ZERO
 _pivot.scale = Vector3.ONE
 if _ring:
  _ring.queue_free()
  _ring = null

func _box(dimensions: Vector3, at: Vector3, color: Color, glow: bool = false, parent: Node3D = null) -> void:
 var instance := MeshInstance3D.new()
 var box := BoxMesh.new()
 box.size = dimensions
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.55
 material.emission_enabled = glow
 material.emission = color
 box.material = material
 instance.mesh = box
 instance.position = at
 (parent if parent else self).add_child(instance)

func _label(value: String, at: Vector3, angles: Vector3, pixels: float, parent: Node3D = null) -> void:
 var label := Label3D.new()
 label.text = value
 label.font_size = 32
 label.pixel_size = pixels
 label.modulate = Color("96e0d7") if reader else Color("142b34")
 label.outline_size = 0
 label.position = at
 label.rotation = angles
 (parent if parent else self).add_child(label)
