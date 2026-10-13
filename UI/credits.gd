extends Control

@onready var go_back: Button = %MainMenu
@export_file("*.tscn") var main_menu: String = "res://UI/main_menu.tscn"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	go_back.grab_focus()
	%MainMenu.pressed.connect(_on_main_menu)

func _on_main_menu() -> void:
	get_tree().change_scene_to_file(main_menu)
