extends CanvasLayer

const MAIN_MENU := "res://UI/main_menu.tscn"

@export var show_time := 3.0

func _ready() -> void:
	visible = false
	_connect_loot.call_deferred()

func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(show_win)

func show_win() -> void:
	if visible or get_tree().paused:
		return
	visible = true
	get_tree().paused = true

	await get_tree().create_timer(show_time, true).timeout

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)
