extends CanvasLayer

const Progress = preload("res://Managers/level_progress.gd")
@export var level_number: int = 0

const MAIN_MENU := "res://UI/main_menu.tscn"

@export var show_time := 3.0
@export var win_sound: AudioStream

func _ready() -> void:
	visible = false
	_connect_exits.call_deferred()

func _connect_exits() -> void:
	for door in get_tree().get_nodes_in_group("exits"):
		door.escaped.connect(show_win)

func show_win() -> void:
	if visible or get_tree().paused:
		return
	Progress.complete_level(level_number)
	visible = true
	Sfx.play(win_sound)
	get_tree().paused = true

	await get_tree().create_timer(show_time, true).timeout

	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU)
