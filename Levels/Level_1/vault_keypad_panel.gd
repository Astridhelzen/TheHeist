extends Control

var digits: String = ""
var code_length: int = 4
var message: String = "Enter code"
var error: bool = false
var unlocked: bool = false


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var panel_scale := minf(size.x / 560.0, size.y / 700.0)
	draw_set_transform((size - Vector2(420, 590) * panel_scale) * 0.5, 0, Vector2.ONE * panel_scale)
	_box(Rect2(10, 14, 420, 590), Color(0, 0, 0, 0.35), 18)
	_box(Rect2(0, 0, 420, 590), Color("293039"), 18, Color("59636d"))
	_text("VAULT ACCESS", 50, 24, Color("e5e7e9"))
	for point in [Vector2(20, 20), Vector2(400, 20), Vector2(20, 570), Vector2(400, 570)]:
		draw_circle(point, 4, Color("111820"))
	_box(Rect2(35, 76, 350, 116), Color("101d1b"), 8, Color("42544c"))
	var tint := Color("f18e83") if error else Color("a7e0b3")
	var display := digits + "_".repeat(maxi(0, code_length - digits.length()))
	_text(display, 131, 39, tint)
	_text(message, 171, 18, tint)
	var keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "↵"]
	for index in range(keys.size()):
		var column := index % 3
		var row := floori(index / 3.0)
		var rect := Rect2(38 + column * 118, 217 + row * 73, 108, 61)
		var fill := Color("414b57")
		if index == 11:
			fill = Color("426653")
		_box(rect, fill, 7, Color("71808a"))
		draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 41), keys[index], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 28, Color("f2f3ef"))
	_text("Type using the number keys", 539, 17, Color("d0d4d8"))
	_text("Backspace to delete · Esc to close", 565, 16, Color("9faab5"))
	draw_set_transform(Vector2.ZERO)


func _text(value: String, baseline: float, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(20, baseline), value, HORIZONTAL_ALIGNMENT_CENTER, 380, font_size, color)


func _box(rect: Rect2, color: Color, radius: int, border: Color = Color.TRANSPARENT) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(1)
	draw_style_box(style, rect)

