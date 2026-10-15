extends Area3D

signal escaped

@onready var hint: CanvasLayer = $Hint

var active := false

func _ready() -> void:
	add_to_group("exits")
	hint.visible = false
	body_entered.connect(_on_body_entered)
	_connect_loot.call_deferred()

func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(_activate)

func _activate() -> void:
	active = true
	hint.visible = true

func _on_body_entered(body: Node3D) -> void:
	if active and body == PlayerManager.player:
		active = false
		hint.visible = false
		escaped.emit()
