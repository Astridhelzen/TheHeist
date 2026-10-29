extends Control
## The credits page. The list below is drawn as two columns of headed sections.
## To add something: add a line to CREDITS ([title, details]) under the right heading.
## The same list is in CREDITS.md in the project folder.

@onready var go_back: Button = %MainMenu
@export_file("*.tscn") var main_menu: String = "res://UI/main_menu.tscn"

const MENU_FONT := preload("res://UI/Fonts/menu.tres")
const OVERLINE_FONT := preload("res://UI/Fonts/overline.tres")
const GOLD := Color("efc260")
const TEXT := Color("e8ecef")
const MUTED := Color("87909f")

## [heading, column (0 = left, 1 = right), [[title, details], ...]]
## Shown above the big CREDITS title.
const MADE_BY := "THE HEIST  ·  MADE BY ASTRID HELZÉN & ELLA BERGSTRÖM"

const CREDITS := [
	["3D MODELS", 0, [
		["\"The Bank Hall\" by Veterock", "Sketchfab · CC BY 4.0 · modified · Level 2 bank"],
		["\"Money\" by Dakta.Grower.Nzl", "Sketchfab · CC BY 4.0"],
		["\"2004 Mazda B-Series UN 2500 Double Cab\" by Res1n", "Sketchfab · CC BY 4.0 · getaway car"],
		["Guard character and all animations", "Mixamo by Adobe"],
	]],
	["MUSIC", 1, [
		["\"Heist\" by Zambolino", "Menu music · freetouse.com/music"],
		["\"Case File Open\" by Zolvi", "Game music · freetouse.com/music"],
	]],
	["SOUND", 1, [
		["Sound effects by Kenney", "kenney.nl · CC0"],
		["Car engine, intro drone and car door", "Made for The Heist"],
	]],
	["FONTS", 1, [
		["Big Shoulders", "The Big Shoulders Project Authors · SIL OFL 1.1"],
		["IBM Plex Mono", "IBM Corp. · SIL OFL 1.1"],
	]],
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_credits()
	go_back.grab_focus()
	%MainMenu.pressed.connect(_on_main_menu)


func _on_main_menu() -> void:
	get_tree().change_scene_to_file(main_menu)


func _build_credits() -> void:
	var container: VBoxContainer = $Root/Margin/Layout/CreditContainer
	# Less empty space under the big title, so everything fits above the button
	var spacer := get_node_or_null("Root/Margin/Layout/Spacer") as Control
	if spacer:
		spacer.custom_minimum_size.y = 12
	var overline := get_node_or_null("Root/Margin/Layout/Overline") as Label
	if overline:
		overline.text = MADE_BY
	for child in container.get_children():
		child.queue_free()
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 72)
	container.add_child(columns)
	var column_nodes: Array[VBoxContainer] = []
	for i in 2:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 3)
		column.custom_minimum_size = Vector2(470, 0)
		columns.add_child(column)
		column_nodes.append(column)
	for section in CREDITS:
		var column: VBoxContainer = column_nodes[section[1]]
		if column.get_child_count() > 0:
			_spacer(column, 10)
		_label(column, section[0], OVERLINE_FONT, 13, GOLD)
		for entry in section[2]:
			_label(column, entry[0], MENU_FONT, 21, TEXT)
			if entry[1] != "":
				_label(column, entry[1], null, 13, MUTED)


func _label(parent: Node, text: String, font: Font, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# Less space between a title and its details line
	label.add_theme_constant_override("line_spacing", -2)
	parent.add_child(label)


func _spacer(parent: Node, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)
