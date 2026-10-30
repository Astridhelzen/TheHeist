extends Area3D
## Aktiverar flykten vid bilen när bytet har tagits.

signal escaped

@export var hint_text := "Get to the car"
## Flykttexten visas efter stölden.
@export var exit_sign: Label3D
## Flyktzonens storlek i meter. Noll använder scenens befintliga form.
@export var zone_size := Vector3.ZERO

var active := false

func _ready() -> void:
	add_to_group("exits")
	body_entered.connect(_on_body_entered)
	if zone_size != Vector3.ZERO:
		var box := BoxShape3D.new()
		box.size = zone_size
		$CollisionShape3D.shape = box
		$CollisionShape3D.transform = Transform3D.IDENTITY
	if exit_sign:
		exit_sign.hide()
	_connect_loot.call_deferred()

func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(_activate)

func _activate() -> void:
	active = true
	# Visas i samma HUD som accesskortets instruktioner
	get_tree().call_group("hud", "notify", "The alarm went off! Get out!")
	get_tree().call_group("hud", "set_objective", hint_text)
	_show_sign()

func _show_sign() -> void:
	if not exit_sign:
		return
	# Visa skylten ovanför bilen.
	exit_sign.show()
	var full_size := exit_sign.scale
	exit_sign.scale = full_size * 0.2
	exit_sign.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(exit_sign, "scale", full_size, 0.45) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(exit_sign, "modulate:a", 1.0, 0.25)

func _on_body_entered(body: Node3D) -> void:
	if active and body == PlayerManager.player:
		active = false
		escaped.emit()
