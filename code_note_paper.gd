extends Control

var code: String = "1234":
	set(value):
		code = value
		queue_redraw()

var _handwriting := SystemFont.new()


func _ready() -> void:
	_handwriting.font_names = PackedStringArray(["Segoe Print", "Comic Sans MS"])
	resized.connect(queue_redraw)


func _draw() -> void:
	# Rita i fasta papperskoordinater, skala sedan för små och stora fönster.
	var paper_scale := minf(size.x / 560.0, size.y / 640.0)
	draw_set_transform((size - Vector2(440, 520) * paper_scale) * 0.5, 0, Vector2.ONE * paper_scale)
	var outline := PackedVector2Array([
		Vector2(14, 18), Vector2(421, 0), Vector2(440, 508),
		Vector2(9, 496), Vector2(0, 154)
	])
	var shadow := PackedVector2Array()
	for point in outline:
		shadow.append(point + Vector2(10, 15))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.25))
	draw_colored_polygon(outline, Color("eee6d6"))
	# Diskreta veck i papperet.
	draw_colored_polygon(PackedVector2Array([Vector2(0, 154), Vector2(216, 240), Vector2(9, 276)]), Color(1, 1, 1, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(9, 276), Vector2(216, 240), Vector2(435, 335)]), Color(0.55, 0.48, 0.36, 0.055))
	draw_line(Vector2(216, 9), Vector2(226, 502), Color(0.6, 0.5, 0.4, 0.09), 1.0, true)
	draw_line(Vector2(9, 276), Vector2(431, 253), Color(1, 1, 1, 0.22), 1.0, true)
	_center_text("VAULT ACCESS CODE", 112, 25, Color("302f2b"))
	draw_line(Vector2(68, 140), Vector2(370, 134), Color("716955"), 1.5, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(73, 211), Vector2(367, 199), Vector2(372, 305), Vector2(69, 315)
	]), Color("efd174"))
	_center_text(code, 283, 61, Color("322d20"))
	draw_set_transform(Vector2.ZERO)


func _center_text(text: String, baseline: float, font_size: int, color: Color) -> void:
	draw_string(_handwriting, Vector2(25, baseline), text, HORIZONTAL_ALIGNMENT_CENTER, 390, font_size, color)
