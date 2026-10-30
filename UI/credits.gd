extends Control
## Visar upphovspersoner och licenser. Uppdatera även CREDITS.md vid ändringar.

@onready var go_back: Button = %MainMenu
@export_file("*.tscn") var main_menu: String = "res://UI/main_menu.tscn"

const MENU_FONT := preload("res://UI/Fonts/menu.tres")
const OVERLINE_FONT := preload("res://UI/Fonts/overline.tres")
const GOLD := Color("efc260")
const TEXT := Color("e8ecef")
const MUTED := Color("87909f")

## Text ovanför rubriken.
const MADE_BY := "THE HEIST  ·  MADE BY ASTRID HELZÉN & ELLA BERGSTRÖM"

const CC_BY := "[url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url]"
const OFL := "[url=https://openfontlicense.org]SIL OFL 1.1[/url]"

## Format: rubrik, kolumn (0/1), lista med titel och beskrivning. Beskrivningar stöder URL-taggar.
const CREDITS := [
	["3D MODELS", 0, [
		["\"The Bank Hall\" by Veterock", "[url=https://sketchfab.com/3d-models/the-bank-hall-7ff86c154ac843c48c4b0ec0149d4321]Sketchfab[/url] · " + CC_BY + " · modified · Level 2 bank"],
		["\"Money\" by Dakta.Grower.Nzl", "[url=https://sketchfab.com/3d-models/money-c8ea0b52ff1b4c7a8dadaba6f16319d7]Sketchfab[/url] · " + CC_BY + " · modified"],
		["\"2004 Mazda B-Series UN 2500 Double Cab\" by Res1n", "[url=https://sketchfab.com/3d-models/2004-mazda-b-series-un-2500-double-cab-e25bd7759aa5478b9ea3d0b1622bdcfc]Sketchfab[/url] · " + CC_BY + " · modified · getaway car"],
		["Guard character and all animations", "[url=https://www.mixamo.com]Mixamo[/url] by Adobe"],
	]],
	["MUSIC", 1, [
		["\"Heist\" by Zambolino", "Menu music · [url=https://freetouse.com/music]freetouse.com/music[/url]"],
	]],
	["SOUND", 1, [
		["Sound effects by Kenney", "[url=https://kenney.nl]kenney.nl[/url] · CC0"],
		["Car engine, intro drone and car door", "Made for The Heist"],
	]],
	["FONTS", 1, [
		["Big Shoulders", "The Big Shoulders Project Authors · " + OFL],
		["IBM Plex Mono", "IBM Corp. · " + OFL],
	]],
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_match_menu_pages()
	_build_credits()
	go_back.grab_focus()
	%MainMenu.pressed.connect(_on_main_menu)


func _on_main_menu() -> void:
	get_tree().change_scene_to_file(main_menu)


## Esc återgår till menyn.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_main_menu()


## Gemensam menybakgrund och tangenttips.
func _match_menu_pages() -> void:
	var root: Control = $Root
	root.add_child(MenuFloorPlan.page_background())
	root.move_child(root.get_child(-1), 0)
	var dim := get_node_or_null("Root/Dim") as ColorRect
	if dim:
		dim.color.a = 0.0
	var margin := get_node_or_null("Root/Margin") as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_left", 76)
		margin.add_theme_constant_override("margin_top", 65)
	var title := get_node_or_null("Root/Margin/Layout/Title") as Label
	if title:
		title.add_theme_font_size_override("font_size", 96)
	var hint_font: FontVariation = OVERLINE_FONT.duplicate()
	hint_font.spacing_glyph = 2
	var hint := Label.new()
	hint.text = "ESC  BACK"
	hint.position = Vector2(600, 652)
	hint.size = Vector2(600, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_font_override("font", hint_font)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("5d646e"))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint)


func _build_credits() -> void:
	var container: VBoxContainer = $Root/Margin/Layout/CreditContainer
	# Minska avståndet så att allt får plats.
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
				_details(column, entry[1])


func _label(parent: Node, text: String, font: Font, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# Mindre avstånd till beskrivningen.
	label.add_theme_constant_override("line_spacing", -2)
	parent.add_child(label)


## Beskrivning med klickbara länkar.
func _details(parent: Node, bbcode: String) -> void:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("normal_font_size", 13)
	text.add_theme_color_override("default_color", MUTED)
	text.text = bbcode.replace("[url=", "[color=#efc260][url=").replace("[/url]", "[/url][/color]")
	text.meta_clicked.connect(func(link): OS.shell_open(str(link)))
	parent.add_child(text)


func _spacer(parent: Node, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	parent.add_child(spacer)
