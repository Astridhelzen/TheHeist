extends Node3D

const MAIN_MENU := "res://UI/main_menu.tscn"

@onready var caught: CanvasLayer = %Caught

func _ready() -> void:
	caught.visible = false
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.player_caught.connect(_on_player_caught)

func _on_player_caught() -> void:
	caught.visible = true
	get_tree().paused = true

	await get_tree().create_timer(2.0, true).timeout

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)
