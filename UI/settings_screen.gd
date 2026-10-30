class_name SettingsScreen
extends CanvasLayer
## Gemensam inställningssida för huvudmeny och pausmeny. Skickar closed vid återgång.

signal closed

const MenuButtonScene := preload("res://UI/menu_button.tscn")
const UI_THEME := preload("res://UI/Themes/ui_theme.tres")
const TITLE_FONT := preload("res://UI/Fonts/title.tres")
const MENU_FONT := preload("res://UI/Fonts/menu.tres")
const OVERLINE_FONT := preload("res://UI/Fonts/overline.tres")
const GOLD := Color("efc260")
const TEXT := Color("e8ecef")
const MUTED := Color("87909f")
const EDGE := Color("2e343c")
const DIM := Color(0.027, 0.035, 0.047, 0.94)

## Format: etikett, inställningsnamn, min, max, visningsformat.
const ROWS := [
	["MASTER VOLUME", "master_volume", 0.0, 1.0, "percent"],
	["MUSIC VOLUME", "music_volume", 0.0, 1.0, "percent"],
	["EFFECTS VOLUME", "effects_volume", 0.0, 1.0, "percent"],
	["MOUSE SENSITIVITY", "mouse_sensitivity", 0.25, 2.0, "times"],
]

## Välj bankbakgrund i huvudmenyn eller genomskinligt lager vid paus, före add_child().
var menu_background := false

var _sliders: Array[HSlider] = []
var _back: Button


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for i in _sliders.size():
		_sliders[i].set_value_no_signal(Settings.get(ROWS[i][1]))
		_update_value_label(i)
	_sliders[0].grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	# Esc lämnar inställningarna utan att stänga pausmenyn.
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


# Layout
func _build() -> void:
	var root := Control.new()
	root.theme = UI_THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	if menu_background:
		root.add_child(MenuFloorPlan.page_background())
	else:
		var dim := ColorRect.new()
		dim.color = DIM
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(dim)

	# Anpassa rubriken efter menytypen.
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var left := 76 if menu_background else 110
	var top := 65 if menu_background else 110
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", left)
	margin.add_theme_constant_override("margin_bottom", 40)
	root.add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	_label(layout, "THE HEIST", OVERLINE_FONT, 14, MUTED)
	_label(layout, "SETTINGS", TITLE_FONT, 96 if menu_background else 110, TEXT)
	_hint(root, "↑↓  CHOOSE     ←→  ADJUST     ESC  BACK")
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	layout.add_child(gap)

	# Inställningar med återställningsknapp.
	var block := VBoxContainer.new()
	block.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	block.add_theme_constant_override("separation", 6)
	layout.add_child(block)
	var top_row := HBoxContainer.new()
	block.add_child(top_row)
	var push_right := Control.new()
	push_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(push_right)
	top_row.add_child(_build_reset_button())

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 18)
	block.add_child(grid)
	for i in ROWS.size():
		_add_row(grid, i)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 34)
	layout.add_child(gap2)
	var back_margin := MarginContainer.new()
	back_margin.add_theme_constant_override("margin_left", 32)
	layout.add_child(back_margin)
	_back = MenuButtonScene.instantiate()
	_back.text = "BACK"
	_back.pressed.connect(close)
	back_margin.add_child(_back)


## Tangenttips nere till höger.
func _hint(parent: Control, text: String) -> void:
	var font: FontVariation = OVERLINE_FONT.duplicate()
	font.spacing_glyph = 2
	var hint := _label(parent, text, font, 13, Color("5d646e"))
	hint.position = Vector2(600, 652)
	hint.size = Vector2(600, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


## Knapp som återställer standardvärdena.
func _build_reset_button() -> Button:
	var button := Button.new()
	button.flat = true
	button.icon = _reset_icon()
	button.tooltip_text = "Reset to default"
	button.custom_minimum_size = Vector2(40, 40)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.focus_mode = Control.FOCUS_ALL
	# Gul markering vid muspekare eller tangentbordsfokus.
	button.add_theme_color_override("icon_normal_color", MUTED)
	for state in ["hover", "focus", "pressed", "hover_pressed"]:
		button.add_theme_color_override("icon_%s_color" % state, GOLD)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.mouse_entered.connect(button.grab_focus)
	button.pressed.connect(func():
		_reset()
		# Vrid pilen kort bakåt.
		button.pivot_offset = button.size / 2.0
		button.rotation = 0.0
		var tween := create_tween()
		tween.tween_property(button, "rotation", -TAU, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	return button


## Återställ alla reglage.
func _reset() -> void:
	Settings.reset_to_defaults()
	for i in _sliders.size():
		_sliders[i].set_value_no_signal(Settings.get(ROWS[i][1]))
		_update_value_label(i)


## Vit återställningspil som färgas av knappen.
func _reset_icon() -> ImageTexture:
	var size := 34
	var center := Vector2(size, size) / 2.0
	var radius := size * 0.3
	var thickness := size * 0.07
	var gap_start := deg_to_rad(-165.0)   # Öppningen är uppe till vänster.
	var gap_end := deg_to_rad(-105.0)
	# Placera pilspetsen vid ringens öppning.
	var tip_point := center + Vector2.from_angle(gap_end) * radius
	var along := Vector2.from_angle(gap_end - PI / 2.0)
	var outward := Vector2.from_angle(gap_end)
	var head := PackedVector2Array([
		tip_point + along * size * 0.2,
		tip_point + outward * size * 0.16,
		tip_point - outward * size * 0.16,
	])
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			# 4 × 4 prover per pixel för jämna kanter.
			var hits := 0
			for sy in 4:
				for sx in 4:
					var p := Vector2(x + (sx + 0.5) / 4.0, y + (sy + 0.5) / 4.0)
					var angle := (p - center).angle()
					var on_ring := absf(p.distance_to(center) - radius) <= thickness and not (angle > gap_start and angle < gap_end)
					if on_ring or Geometry2D.is_point_in_polygon(p, head):
						hits += 1
			image.set_pixel(x, y, Color(1, 1, 1, hits / 16.0))
	return ImageTexture.create_from_image(image)


func _add_row(grid: GridContainer, index: int) -> void:
	var row: Array = ROWS[index]
	var name_label := _label(grid, row[0], MENU_FONT, 28, MUTED)
	name_label.custom_minimum_size = Vector2(300, 0)

	var slider := HSlider.new()
	slider.min_value = row[2]
	slider.max_value = row[3]
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(380, 28)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(slider)
	grid.add_child(slider)
	_sliders.append(slider)

	var value_label := _label(grid, "", OVERLINE_FONT, 16, TEXT)
	value_label.custom_minimum_size = Vector2(90, 0)
	value_label.name = "Value%d" % index

	slider.value_changed.connect(func(value: float):
		Settings.set_setting(row[1], value)
		_update_value_label(index))
	# Markera vald rad i gult.
	slider.focus_entered.connect(func(): name_label.add_theme_color_override("font_color", GOLD))
	slider.focus_exited.connect(func(): name_label.add_theme_color_override("font_color", MUTED))
	slider.mouse_entered.connect(slider.grab_focus)


func _update_value_label(index: int) -> void:
	var value := _sliders[index].value
	var label: Label = _sliders[index].get_parent().get_node("Value%d" % index)
	if ROWS[index][4] == "percent":
		label.text = "%d %%" % int(round(value * 100.0))
	else:
		label.text = "%.2fx" % value


func _style_slider(slider: HSlider) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = EDGE
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var filled := track.duplicate()
	filled.bg_color = GOLD
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	slider.add_theme_icon_override("grabber", _dot(TEXT))
	slider.add_theme_icon_override("grabber_highlight", _dot(GOLD))
	slider.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Runt reglagehandtag.
func _dot(color: Color) -> ImageTexture:
	var size := 18
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x, y).distance_to(center)
			var alpha := clampf(size / 2.0 - 1.0 - d + 0.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(color, alpha))
	return ImageTexture.create_from_image(image)


func _label(parent: Node, text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(label)
	return label
