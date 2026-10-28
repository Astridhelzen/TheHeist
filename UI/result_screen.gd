extends CanvasLayer
## Shared base for the end-of-level screens (heist_complete.gd and caught.gd).
## Builds the dark overlay, the title and the row of buttons in the same style
## as the pause menu and the HUD, and handles Retry / Next level / Main menu.
## The screen keeps running while the game is paused (process_mode = Always).

const MAIN_MENU := "res://UI/main_menu.tscn"
const MenuButtonScene := preload("res://UI/menu_button.tscn")
const UI_THEME := preload("res://UI/Themes/ui_theme.tres")
const TITLE_FONT := preload("res://UI/Fonts/title.tres")
const MENU_FONT := preload("res://UI/Fonts/menu.tres")
const OVERLINE_FONT := preload("res://UI/Fonts/overline.tres")

const GOLD := Color(0.949, 0.827, 0.541)
const TEXT := Color("e8ecef")
const MUTED := Color("7d848c")
const EDGE := Color("262b32")
const DIM := Color(0.027, 0.035, 0.047, 0.86)

## Shown above the title, e.g. "LEVEL 1". 0 = just "THE HEIST".
@export var level_number: int = 0

var root: Control
var content: VBoxContainer
var buttons: HBoxContainer

## Read from the HUD when the screen opens.
var coins_collected := 0
var coins_total := 0
var elapsed_time := 0.0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


## Copies coins and time from the HUD. A level without a HUD gives 0 / 0 and 00:00:00.
func read_results() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	coins_collected = hud.coins_collected
	coins_total = hud.coins_total
	elapsed_time = hud.elapsed_time


func format_time(seconds: float) -> String:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		return hud.format_time(seconds)
	return "00:00:00"


# --------------------
# BUILDING THE SCREEN
# --------------------
func build_base(title: String, title_color: Color) -> void:
	root = Control.new()
	root.name = "Root"
	root.theme = UI_THEME
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)

	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 8)
	center.add_child(content)

	var overline := "LEVEL %d" % level_number if level_number > 0 else "THE HEIST"
	add_label(content, overline, OVERLINE_FONT, 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	add_label(content, title, TITLE_FONT, 96, title_color, HORIZONTAL_ALIGNMENT_CENTER)

	buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 36)


## Adds the row of buttons at the bottom. Call after the rest of the content.
func add_buttons_row() -> void:
	add_spacer(content, 26)
	content.add_child(buttons)


func add_label(parent: Node, text: String, font: Font, font_size: int, color: Color,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func add_spacer(parent: Node, height: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(spacer)


func add_divider(parent: Node, width: float) -> void:
	var line := ColorRect.new()
	line.color = EDGE
	line.custom_minimum_size = Vector2(width, 1)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


## A button in the same style as the pause menu (amber ▶ when selected).
func add_button(text: String, on_pressed: Callable) -> Button:
	var button: Button = MenuButtonScene.instantiate()
	button.text = text
	# Fixed width, so the row doesn't jump when the selected button grows
	button.custom_minimum_size = Vector2(180, 56)
	button.pressed.connect(on_pressed)
	buttons.add_child(button)
	return button


# --------------------
# OPEN / LEAVE
# --------------------
func open() -> void:
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Hide the HUD so its boxes don't show through behind the title
	get_tree().call_group("hud", "hide")
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.3)


## Waits that also work while the game is paused.
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


func retry() -> void:
	_leave()
	get_tree().reload_current_scene()


func go_to(scene_path: String) -> void:
	_leave()
	get_tree().change_scene_to_file(scene_path)


func main_menu() -> void:
	go_to(MAIN_MENU)


func _leave() -> void:
	# Stops the siren / alarm sounds that Sfx is still playing
	Sfx.stop_all()
	# Stop every sound in the level (alarm, music, footsteps) BEFORE unpausing.
	# Otherwise the paused alarm starts again and keeps howling while the next
	# level loads, which can take a few seconds.
	var level := get_tree().current_scene
	if level:
		for sound in level.find_children("*", "AudioStreamPlayer", true, false):
			sound.stop()
		for sound in level.find_children("*", "AudioStreamPlayer3D", true, false):
			sound.stop()
		for sound in level.find_children("*", "AudioStreamPlayer2D", true, false):
			sound.stop()
	get_tree().paused = false


func play_sound(stream: AudioStream, pitch := 1.0, volume_db := 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func load_if_exists(path: String) -> AudioStream:
	return load(path) if ResourceLoader.exists(path) else null
