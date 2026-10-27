@tool
extends Node3D

@export var reader: bool = false

func _ready() -> void:
 if get_child_count() > 0:
  return
 if reader:
  _box(Vector3(0.38, 0.55, 0.055), Vector3.ZERO, Color("172932"))
  _box(Vector3(0.29, 0.07, 0.012), Vector3(0, 0.17, 0.034), Color("54c9bb"), true)
  _box(Vector3(0.24, 0.006, 0.015), Vector3(0, -0.15, 0.034), Color("050e14"))
  _label("CARD ACCESS", Vector3(0, 0.065, 0.038), Vector3.ZERO, 0.0011)
  _label("HOLD CARD HERE", Vector3(0, -0.055, 0.038), Vector3.ZERO, 0.00065)
 else:
  _box(Vector3(0.22, 0.008, 0.14), Vector3.ZERO, Color("e5e9df"))
  _box(Vector3(0.045, 0.002, 0.14), Vector3(-0.087, 0.005, 0), Color("239c99"))
  _box(Vector3(0.036, 0.002, 0.028), Vector3(-0.028, 0.005, 0.025), Color("ddbb66"))
  _label("THE HEIST", Vector3(0.015, 0.007, -0.036), Vector3(-PI / 2, 0, 0), 0.0005)
  _label("VAULT ACCESS", Vector3(0.025, 0.007, -0.009), Vector3(-PI / 2, 0, 0), 0.00035)

func _box(dimensions: Vector3, at: Vector3, color: Color, glow: bool = false) -> void:
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
 add_child(instance)

func _label(value: String, at: Vector3, angles: Vector3, pixels: float) -> void:
 var label := Label3D.new()
 label.text = value
 label.font_size = 32
 label.pixel_size = pixels
 label.modulate = Color("96e0d7") if reader else Color("142b34")
 label.outline_size = 0
 label.position = at
 label.rotation = angles
 add_child(label)
