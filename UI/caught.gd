extends CanvasLayer

const MAIN_MENU := "res://UI/main_menu.tscn"

@export var show_time := 2.0

func _ready() -> void:
	visible = false
	_connect_guards.call_deferred()

func _connect_guards() -> void:
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.player_caught.connect(show_caught)

func show_caught() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true

	await get_tree().create_timer(show_time, true).timeout

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)
