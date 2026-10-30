extends Area3D
## Roterande mynt med ljus och upplockningseffekt.

@export var pickup_sound: AudioStream
@export var pickup_volume_db := -4.0
@export var spin_speed := 2.5
@export var bob_height := 0.08
@export var bob_speed := 2.2
## Myntets ljusstyrka. 0 stänger av ljuset.
@export var light_energy := 0.45
## Glödens synlighet (0–1).
@export var glow_strength := 0.15

var _taken := false
var _time := 0.0
var _rest_height := 0.0

@onready var _model: Node3D = $Model
@onready var _light: OmniLight3D = $Light
@onready var _glow: MeshInstance3D = $Glow
@onready var _ring: MeshInstance3D = $Ring


func _ready() -> void:
	add_to_group("coins")
	_rest_height = _model.position.y
	# Slumpa startläget så att mynten rör sig olika.
	_time = randf() * TAU
	_model.rotation.y = randf() * TAU
	_light.light_energy = light_energy
	_light.visible = light_energy > 0.0
	# Egna material så att bara det upplockade myntet tonas ut.
	_glow.material_override = _glow.material_override.duplicate()
	_ring.material_override = _ring.material_override.duplicate()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	_model.rotation.y += spin_speed * delta
	var wave := sin(_time * bob_speed)
	_model.position.y = _rest_height + wave * bob_height
	_glow.position.y = _model.position.y
	# Låt ljuset pulsera med rörelsen.
	var breathe := 0.5 + 0.5 * wave
	_light.light_energy = light_energy * (0.8 + 0.4 * breathe)
	_set_alpha(glow_strength * (0.75 + 0.25 * breathe), _glow)
	_set_alpha(0.3 + 0.35 * breathe, _ring)
	_ring.scale = Vector3(1.0 + 0.08 * breathe, 0.15, 1.0 + 0.08 * breathe)


func _on_body_entered(body: Node3D) -> void:
	if _taken or body != PlayerManager.player:
		return
	_taken = true
	remove_from_group("coins")
	set_deferred("monitoring", false)
	get_tree().call_group("hud", "add_coin")
	if pickup_sound:
		Sfx.play(pickup_sound, pickup_volume_db)
	_sparkle()

	# Låt myntet hoppa upp och krympa bort.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_model, "position:y", _model.position.y + 0.45, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_model, "rotation:y", _model.rotation.y + TAU, 0.25)
	tween.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.15).set_delay(0.12)
	tween.tween_property(_light, "light_energy", light_energy * 3.0, 0.08)
	tween.tween_property(_light, "light_energy", 0.0, 0.4).set_delay(0.08)
	tween.tween_property(_glow, "scale", Vector3.ONE * 1.8, 0.3)
	tween.tween_method(_set_alpha.bind(_glow), glow_strength * 2.0, 0.0, 0.3)
	tween.tween_method(_set_alpha.bind(_ring), 0.6, 0.0, 0.3)
	# Vänta tills partiklarna är klara.
	tween.chain().tween_interval(0.6)
	tween.chain().tween_callback(queue_free)


## Korta guldgnistor vid upplockning.
func _sparkle() -> void:
	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 0.9
	sparks.amount = 18
	sparks.lifetime = 0.6
	sparks.position = _model.position
	sparks.direction = Vector3.UP
	sparks.spread = 180.0
	sparks.initial_velocity_min = 1.0
	sparks.initial_velocity_max = 2.2
	sparks.gravity = Vector3(0, -4.0, 0)
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	sparks.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.025
	mesh.height = 0.05
	mesh.radial_segments = 6
	mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.85, 0.45)
	mesh.material = material
	sparks.mesh = mesh
	add_child(sparks)
	sparks.emitting = true


func _set_alpha(alpha: float, target: MeshInstance3D) -> void:
	var material := target.material_override as StandardMaterial3D
	material.albedo_color.a = alpha
