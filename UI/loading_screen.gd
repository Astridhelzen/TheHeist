class_name LoadingScreen
extends Control
## Laddar banan i bakgrunden och visar tips. Kan starta med bilintrot.

const LOADING_SCENE := "res://UI/loading_screen.tscn"
const INTRO_SCENE := "res://Cinematics/arrival_intro.tscn"

const TITLE_FONT := preload("res://UI/Fonts/title.tres")
const MENU_FONT := preload("res://UI/Fonts/menu.tres")
const OVERLINE_FONT := preload("res://UI/Fonts/overline.tres")
const BACKGROUND := Color("080c10")
const GOLD := Color("efc260")
const TEXT := Color("e8ecef")
const MUTED := Color("7d848c")
const EDGE := Color("262b32")

const LEVEL_NAMES := ["THE BANK", "THE GRAND BANK", "THE ROOFTOP", "THE VAULT"]

const TIPS := [
	"Stay out of the guards' flashlights. The light is how they see you.",
	"Hold Ctrl to sneak. Guards can't hear you when you sneak.",
	"Running is fast, but guards can hear you from far away.",
	"The ring around your feet shows how far your steps can be heard.",
	"Guards look around at the end of their route. Wait for them to turn.",
	"Coins on a guard's route are worth the risk, if you time it right.",
	"Take every coin and be quick to earn all three gold coins.",
	"Find the access card before you go for the vault.",
	"When you grab the money, the alarm goes off. Run for the car!",
	"Hide in the dark and let the guard walk past.",
]

## Tid per tips i sekunder.
const TIP_TIME := 3.5
## Minsta visningstid för laddskärmen.
const MIN_TIME := 2.0

# Sätts av open() före scenbytet.
static var _target := ""
static var _level_number := 0
static var _with_intro := true
# Behåll banan i minnet tills introt tar över.
static var _loaded: Array[Resource] = []

var _paths: Array[String] = []
var _current := 0          # Filen som laddas nu.
var _real_progress := 0.0  # Rapporterad laddning (0–1).
var _elapsed := 0.0
var _shown_progress := 0.0
var _tip_index := 0
var _tip_time := 0.0
var _done := false

var _bar_fill: ColorRect
var _bar_back: ColorRect
var _percent: Label
var _tip: Label


## Öppna laddskärmen och börja ladda banan.
static func open(tree: SceneTree, level_path: String, level_number := 0, with_intro := true) -> void:
	_target = level_path
	_level_number = level_number
	_with_intro = with_intro
	tree.paused = false
	tree.change_scene_to_file(LOADING_SCENE)


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_loaded.clear()
	_build()
	_paths = [_target]
	if _with_intro and ResourceLoader.exists(INTRO_SCENE):
		_paths.append(INTRO_SCENE)
	# Ladda bana och intro i turordning för att undvika låsning på gemensamma resurser.
	ResourceLoader.load_threaded_request(_paths[0], "", false)
	_tip_index = randi() % TIPS.size()
	_show_tip(false)


func _process(delta: float) -> void:
	_elapsed += delta
	_update_tip(delta)
	if _done:
		return

	var part := 0.0
	if _current < _paths.size():
		var path := _paths[_current]
		var progress := []
		var status := ResourceLoader.load_threaded_get_status(path, progress)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_loaded.append(ResourceLoader.load_threaded_get(path))
			_current += 1
			if _current < _paths.size():
				ResourceLoader.load_threaded_request(_paths[_current], "", false)
		elif status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			part = progress[0] if not progress.is_empty() else 0.0
		else:
			# Återgå till menyn om laddningen misslyckas.
			push_error("Could not load " + path)
			_done = true
			get_tree().change_scene_to_file("res://UI/main_menu.tscn")
			return

	var all_loaded := _current >= _paths.size()
	_real_progress = maxf(_real_progress, (_current + part) / _paths.size())
	if all_loaded:
		_shown_progress = move_toward(_shown_progress, 1.0, delta * 1.5)
	elif _shown_progress < _real_progress:
		_shown_progress = move_toward(_shown_progress, _real_progress, delta * 1.5)
	else:
		# Låt stapeln röra sig även när en stor fil inte rapporterar framsteg.
		var limit := minf(_real_progress + 0.15, 0.95)
		_shown_progress = minf(_shown_progress + delta * 0.015, limit)
	_set_progress(_shown_progress)

	if all_loaded and _elapsed >= MIN_TIME and _shown_progress >= 0.999:
		_start()


func _start() -> void:
	_done = true
	if _with_intro and _loaded.size() > 1:
		# Introt instansierar den redan laddade banan.
		get_tree().set_meta("arrival_level", _target)
		get_tree().change_scene_to_packed(_loaded[1])
	else:
		get_tree().change_scene_to_packed(_loaded[0])


# Layout
func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(620, 0)
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)

	var overline := "THE HEIST"
	if _level_number > 0:
		var level_name: String = LEVEL_NAMES[_level_number - 1] if _level_number <= LEVEL_NAMES.size() else ""
		overline = "LEVEL %d  ·  %s" % [_level_number, level_name]
	_label(column, overline, OVERLINE_FONT, 14, MUTED)
	_label(column, "LOADING", TITLE_FONT, 96, TEXT)

	# Laddningsstapel med procenttal.
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 16)
	column.add_child(bar_row)
	_bar_back = ColorRect.new()
	_bar_back.color = EDGE
	_bar_back.custom_minimum_size = Vector2(0, 4)
	_bar_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar_back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(_bar_back)
	_bar_fill = ColorRect.new()
	_bar_fill.color = GOLD
	_bar_fill.size = Vector2(0, 4)
	_bar_back.add_child(_bar_fill)
	_percent = _label(bar_row, "0 %", MENU_FONT, 22, GOLD)
	_percent.custom_minimum_size = Vector2(64, 0)
	_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 36)
	column.add_child(gap)

	# Tips med gul pil.
	var tip_row := HBoxContainer.new()
	tip_row.add_theme_constant_override("separation", 14)
	column.add_child(tip_row)
	var arrow := _label(tip_row, "▶", null, 14, GOLD)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var tip_column := VBoxContainer.new()
	tip_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_column.add_theme_constant_override("separation", 6)
	tip_row.add_child(tip_column)
	_label(tip_column, "TIP", OVERLINE_FONT, 13, MUTED)
	_tip = _label(tip_column, "", MENU_FONT, 28, TEXT)
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip.custom_minimum_size = Vector2(0, 72)


func _label(parent: Node, text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	if font:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func _set_progress(value: float) -> void:
	_bar_fill.size = Vector2(_bar_back.size.x * value, _bar_back.size.y)
	_percent.text = "%d %%" % int(round(value * 100.0))


# Tips
func _update_tip(delta: float) -> void:
	_tip_time += delta
	if _tip_time >= TIP_TIME:
		_tip_time = 0.0
		_tip_index = (_tip_index + 1) % TIPS.size()
		_show_tip(true)


func _show_tip(animate: bool) -> void:
	if not animate:
		_tip.text = TIPS[_tip_index]
		return
	var tween := create_tween()
	tween.tween_property(_tip, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): _tip.text = TIPS[_tip_index])
	tween.tween_property(_tip, "modulate:a", 1.0, 0.3)
