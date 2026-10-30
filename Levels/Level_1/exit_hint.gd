extends Control
## Flyktinstruktion med samma utseende som kortets HUD.

@export var text := "Get to the exit!"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)


func _draw() -> void:
	# Anpassa storleken till fönstret.
	var s := minf(size.x / 1280.0, size.y / 720.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * s)
	var width := size.x / s

	# Samma placering som kortets meddelanden.
	_panel(Rect2(width / 2 - 230, 110, 460, 54), Color("183c3d"))
	draw_string(ThemeDB.fallback_font, Vector2(width / 2 - 220, 144), text,
			HORIZONTAL_ALIGNMENT_CENTER, 440, 20, Color("baf2dd"))

	draw_set_transform(Vector2.ZERO)


func _panel(rect: Rect2, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.border_color = Color("42616a")
	style.set_border_width_all(1)
	draw_style_box(style, rect)
