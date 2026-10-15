extends Control

@onready var new_heist: Button = $Menu/NewHeist
@export_file("*.tscn") var first_level: String = "res://Levels/Level_1_Files/Level_1.tscn"
@export_file("*.tscn") var credits: String = "res://UI/credits.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	new_heist.grab_focus()
	Sfx.stop_all()
	$Menu/NewHeist.pressed.connect(_on_new_heist)
	$Menu/Settings.pressed.connect(_on_settings)
	$Menu/Credits.pressed.connect(_on_credits)
	$Menu/Quit.pressed.connect(_on_quit)

func _on_new_heist() -> void:
	get_tree().change_scene_to_file(first_level)

func _on_settings() -> void:
	pass   # bygg senare

func _on_credits() -> void:
	get_tree().change_scene_to_file(credits)

func _on_quit() -> void:
	get_tree().quit()
