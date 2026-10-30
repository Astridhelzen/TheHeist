extends Button
## Markerar vald knapp med ljus text och en gul linje.

const SIZE_SELECTED := 38
const SIZE_NORMAL := 30
const LINE_COLOR := Color("efc260")
const LINE_WIDTH := 3.0
## Avstånd mellan linje och text i pixlar.
const LINE_GAP := 16.0
## Versalhöjd som andel av teckenstorleken.
const CAP_HEIGHT := 0.7

@onready var arrow: Label = $Arrow

var _shown := 0.0   # 0 = dold linje, 1 = fullt synlig.
var _tween: Tween


func _ready() -> void:
	# Den gamla pilen finns kvar i scenen men döljs.
	arrow.visible = false
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(grab_focus)
	if not has_focus():
		_on_focus_exited()


func _on_focus_entered() -> void:
	add_theme_font_size_override("font_size", SIZE_SELECTED)
	# Lys bara upp vald knapp, även när mus och tangentbord används samtidigt.
	add_theme_color_override("font_hover_color", get_theme_color("font_focus_color"))
	_animate_line(1.0, 0.18)


func _on_focus_exited() -> void:
	add_theme_font_size_override("font_size", SIZE_NORMAL)
	add_theme_color_override("font_hover_color", get_theme_color("font_color"))
	_animate_line(0.0, 0.1)


func _animate_line(target: float, time: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_shown, _shown, target, time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _set_shown(value: float) -> void:
	_shown = value
	queue_redraw()


func _draw() -> void:
	if _shown <= 0.01:
		return
	var font_size := get_theme_font_size("font_size")
	var middle := _text_middle()
	var height := font_size * CAP_HEIGHT * 1.05 * _shown
	draw_rect(Rect2(-LINE_GAP - LINE_WIDTH, middle - height / 2.0, LINE_WIDTH, height), Color(LINE_COLOR, _shown))


## Centrera markeringen mot versalerna, inte hela textradens höjd.
func _text_middle() -> float:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var line_top := (size.y - font.get_height(font_size)) / 2.0
	var baseline := line_top + font.get_ascent(font_size)
	return baseline - font_size * CAP_HEIGHT / 2.0
