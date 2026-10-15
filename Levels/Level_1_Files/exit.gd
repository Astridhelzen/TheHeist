extends Area3D

signal escaped

@export var hint_text := "GET TO EXIT"

@onready var hint: CanvasLayer = $Hint

var active := false

func _ready() -> void:
	add_to_group("exits")
	hint.visible = false

	$Hint/HintLabel.text = hint_text
	body_entered.connect(_on_body_entered)
	_connect_loot.call_deferred()

func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(_activate)

func _activate() -> void:
	active = true
	# Visas i samma HUD som accesskortets instruktioner
	get_tree().call_group("hud", "notify", "The alarm went off! Get out!")
	get_tree().call_group("hud", "set_objective", "Get to the exit")

func _on_body_entered(body: Node3D) -> void:
	if active and body == PlayerManager.player:
		active = false
		escaped.emit()
