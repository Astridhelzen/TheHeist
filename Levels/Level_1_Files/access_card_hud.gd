extends Control

var has_card := false
var unlocked := false
var prompt := ""
var notice := ""

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)

func _draw() -> void:
 var s := minf(size.x / 1280.0, size.y / 720.0)
 draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * s)
 var width := size.x / s
 var height := size.y / s
 _panel(Rect2(width - 298, 26, 272, 66), Color("13242d"))
 _panel(Rect2(width - 282, 42, 42, 30), Color("4ebdb1") if has_card else Color("53616a"))
 draw_line(Vector2(width - 274, 50), Vector2(width - 248, 50), Color("dcece7"), 3)
 _text("VAULT ACCESS", Vector2(width - 226, 50), 15, Color("91a6ad"))
 _text("Unlocked" if unlocked else ("Card collected" if has_card else "Find the access card"), Vector2(width - 226, 74), 17, Color("eff5ed"))
 if not notice.is_empty():
  _panel(Rect2(width / 2 - 230, 110, 460, 54), Color("183c3d"))
  draw_string(ThemeDB.fallback_font, Vector2(width / 2 - 220, 144), notice, HORIZONTAL_ALIGNMENT_CENTER, 440, 20, Color("baf2dd"))
 if not prompt.is_empty():
  _panel(Rect2(width / 2 - 240, height - 112, 480, 58), Color("13242d"))
  draw_string(ThemeDB.fallback_font, Vector2(width / 2 - 228, height - 75), prompt, HORIZONTAL_ALIGNMENT_CENTER, 456, 21, Color("f3f1e4"))
 draw_set_transform(Vector2.ZERO)

func _panel(rect: Rect2, color: Color) -> void:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.set_corner_radius_all(10)
 style.border_color = Color("42616a")
 style.set_border_width_all(1)
 draw_style_box(style, rect)

func _text(value: String, at: Vector2, font_size: int, color: Color) -> void:
 draw_string(ThemeDB.fallback_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
