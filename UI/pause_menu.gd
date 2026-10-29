extends CanvasLayer

const MAIN_MENU := "res://UI/main_menu.tscn"

@onready var resume_button: Button = %Resume
@onready var retry_button: Button = %Retry
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit

func _ready() -> void:
	visible = false
	resume_button.pressed.connect(resume)
	retry_button.pressed.connect(_on_retry)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()

func pause() -> void:
	# Spelet är redan pausat av något annat, t.ex. CAUGHT-skärmen
	if get_tree().paused:
		return
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()

func resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Starts the level again from the beginning.
func _on_retry() -> void:
	visible = false
	# Stop the alarm, music and other sounds first, so nothing plays on while the level reloads
	Sfx.stop_all()
	var level := get_tree().current_scene
	if level:
		for sound in level.find_children("*", "AudioStreamPlayer", true, false):
			sound.stop()
		for sound in level.find_children("*", "AudioStreamPlayer3D", true, false):
			sound.stop()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_settings() -> void:
	pass   # bygg senare

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
