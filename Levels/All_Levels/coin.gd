extends Area3D
## A coin that spins and bobs. The player takes it by walking into it.
## Place coin.tscn anywhere in a level. The HUD counts the coins by itself.

@export var pickup_sound: AudioStream
@export var pickup_volume_db := -4.0
@export var spin_speed := 2.5
@export var bob_height := 0.08
@export var bob_speed := 2.2

var _taken := false
var _time := 0.0
var _rest_height := 0.0

@onready var _model: Node3D = $Model


func _ready() -> void:
	add_to_group("coins")
	_rest_height = _model.position.y
	# Start at a random point so the coins don't bob in sync
	_time = randf() * TAU
	_model.rotation.y = randf() * TAU
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	_model.rotation.y += spin_speed * delta
	_model.position.y = _rest_height + sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node3D) -> void:
	if _taken or body != PlayerManager.player:
		return
	_taken = true
	remove_from_group("coins")
	set_deferred("monitoring", false)
	get_tree().call_group("hud", "add_coin")
	if pickup_sound:
		Sfx.play(pickup_sound, pickup_volume_db)

	# Same feel as the access card: jump up, spin, shrink away
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_model, "position:y", _model.position.y + 0.45, 0.25) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_model, "rotation:y", _model.rotation.y + TAU, 0.25)
	tween.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.15).set_delay(0.12)
	tween.chain().tween_callback(queue_free)
