extends CanvasLayer

const MAIN_MENU := "res://UI/main_menu.tscn"

@onready var resume_button: Button = %Resume
@onready var settings_button: Button = %Settings
@onready var quit_button: Button = %Quit

func _ready() -> void:
	visible = false
	resume_button.pressed.connect(resume)
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

func _on_settings() -> void:
	pass   # bygg senare

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU)
