extends Control
## The main menu, in two views:
## - HOME: START HEIST, SETTINGS, CREDITS, QUIT
## - LEVELS: the level cards (opened with START HEIST)
## Everything works with the keyboard: arrows to move, Enter to choose,
## Esc to go back. The mouse works too.

class LockIcon extends Control:
	func _draw() -> void:
		var color := Color("929aa7")
		draw_arc(Vector2(24, 20), 12, PI, TAU, 24, color, 6, true)
		draw_line(Vector2(12, 20), Vector2(12, 30), color, 6, true)
		draw_line(Vector2(36, 20), Vector2(36, 30), color, 6, true)
		var body := StyleBoxFlat.new()
		body.bg_color = color
		body.set_corner_radius_all(4)
		draw_style_box(body, Rect2(4, 28, 40, 31))
		draw_circle(Vector2(24, 40), 4, Color("10151b"))
		draw_rect(Rect2(22, 40, 4, 10), Color("10151b"))

## Three small gold coins on a level card: the best result on that level.
class MedalRow extends Control:
	var medals := 0
	func _draw() -> void:
		for i in range(3):
			_draw_coin(Vector2(10 + i * 26, size.y / 2), i < medals)
	func _draw_coin(c: Vector2, filled: bool) -> void:
		if not filled:
			draw_circle(c, 10, Color(0.06, 0.075, 0.09, 0.9))
			draw_arc(c, 10, 0, TAU, 32, Color("3a4048"), 1.5, true)
			return
		draw_circle(c, 10, Color(0.76, 0.53, 0.15))
		draw_circle(c, 8, Color(1.0, 0.79, 0.32))
		draw_arc(c, 5.5, 0, TAU, 24, Color(0.84, 0.6, 0.18), 1.5, true)

@export_file("*.tscn") var first_level: String = "res://Levels/Level_1/Level_1.tscn"
@export_file("*.tscn") var second_level: String = "res://Level2.tscn"
@export_file("*.tscn") var credits: String = "res://UI/credits.tscn"
const Progress = preload("res://Managers/level_progress.gd")
const GOLD = Color("efc260")
const MUTED = Color("87909f")
const HINT = Color("5d646e")
const BACKGROUND = Color("080c10")
const MENU_BUTTON = preload("res://UI/menu_button.tscn")
const MENU_THEME = preload("res://UI/Themes/ui_theme.tres")
var title_font = preload("res://UI/Fonts/title.tres")
var overline_font = preload("res://UI/Fonts/overline.tres")

## Shown under the lock on a level card that can't be played yet
const LOCK_TEXTS = ["", "FINISH LEVEL 1", "COMING SOON", "UNDER CONSTRUCTION"]
const SUBTITLES = ["THE BANK", "THE GRAND BANK", "THE ROOFTOP", "THE VAULT"]
const CARD_SIZE := Vector2(262, 355)
const CARD_GAP := 24.0

## Where the menu opens next time: "levels" after playing a level,
## or the name of a home button (e.g. "Credits") to select it.
static var _return_to := ""
## The level card that was played last
static var _last_level := 0

var selected_level := 0
var canvas: Control
var home: Control
var levels: Control
var home_buttons := {}
var floor_plan: MenuFloorPlan
var back_button: Button
var cards: Array[Button] = []
var settings: SettingsScreen
var _starting_level := false
var _tween: Tween


func _ready() -> void:
	theme = MENU_THEME
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.stop_all()
	canvas = Control.new()
	canvas.name = "Canvas"
	canvas.size = Vector2(1280, 720)
	add_child(canvas)
	var background := ColorRect.new()
	background.size = canvas.size
	background.color = BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(background)
	_keep_music_playing()
	_build_home()
	_build_levels()
	_build_settings()
	resized.connect(_resize)
	_resize()

	if Progress.is_level_unlocked(_last_level + 1):
		selected_level = _last_level
	_select_level(selected_level)
	if _return_to == "levels":
		_show_levels(false)
	elif home_buttons.has(_return_to):
		_show_home(false, _return_to)
	else:
		_show_home(false)
	_return_to = ""


func _unhandled_input(event: InputEvent) -> void:
	if settings.visible:
		return
	if not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if levels.visible:
		_show_home(true, "StartHeist")
	elif home_buttons["Quit"].has_focus():
		# Esc twice (or Esc on QUIT) quits the game
		_on_quit()
	else:
		# The first Esc points the light at QUIT, so you don't quit by mistake
		home_buttons["Quit"].grab_focus()


# --------------------
# HOME
# --------------------
func _build_home() -> void:
	home = _view("Home")
	# A bank seen from above, with a guard pointing his flashlight at the
	# selected option (see UI/menu_floor_plan.gd)
	floor_plan = MenuFloorPlan.new()
	home.add_child(floor_plan)
	label_at("A STEALTH GAME", Vector2(76, 150), 14, MUTED, overline_font, home)
	label_at("THE HEIST", Vector2(72, 171), 108, Color("eef0f3"), title_font, home)
	var titles := ["START HEIST", "SETTINGS", "CREDITS", "QUIT"]
	var actions := [_show_levels, _on_settings, _on_credits, _on_quit]
	for i in titles.size():
		var button: Button = MENU_BUTTON.instantiate()
		button.name = titles[i].capitalize().replace(" ", "")
		button.text = titles[i]
		button.position = Vector2(80, 340 + i * 62)
		button.size = Vector2(300, 54)
		home.add_child(button)
		button.pressed.connect(actions[i])
		home_buttons[button.name] = button
		button.focus_entered.connect(_aim_light.bind(button))
	_hint(home, "↑↓  MOVE     ENTER  SELECT     ESC  QUIT")


## Points the guard's flashlight at the middle of a button's text.
func _aim_light(button: Button) -> void:
	var font := button.get_theme_font("font")
	var text_width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
	var point := button.position + Vector2(text_width / 2.0, button.size.y / 2.0)
	# Jump straight there when the menu has just opened
	floor_plan.aim_at(point, home.visible and is_node_ready())


func _show_home(animate := true, focus := "StartHeist") -> void:
	_switch(levels, home, animate, -1.0)
	home_buttons[focus].grab_focus()


# --------------------
# LEVELS
# --------------------
func _build_levels() -> void:
	levels = _view("Levels")
	levels.add_child(MenuFloorPlan.page_background())
	label_at("THE HEIST", Vector2(76, 65), 14, MUTED, overline_font, levels)
	label_at("SELECT A LEVEL", Vector2(72, 86), 96, Color("eef0f3"), title_font, levels)
	for i in range(4):
		_build_card(i)

	back_button = MENU_BUTTON.instantiate()
	back_button.name = "Back"
	back_button.text = "BACK"
	back_button.position = Vector2(80, 622)
	back_button.size = Vector2(200, 54)
	back_button.pressed.connect(_show_home.bind(true, "StartHeist"))
	levels.add_child(back_button)
	back_button.focus_neighbor_left = back_button.get_path()
	back_button.focus_neighbor_right = back_button.get_path()
	back_button.focus_neighbor_bottom = back_button.get_path()
	_hint(levels, "←→  CHOOSE     ENTER  START     ESC  BACK")
	_link_cards()


func _build_card(i: int) -> void:
	var unlocked := Progress.is_level_unlocked(i + 1)
	var width := CARD_SIZE.x
	var card := Button.new()
	card.name = "Level" + str(i + 1)
	card.position = Vector2(80 + i * (width + CARD_GAP), 236)
	card.size = CARD_SIZE
	card.clip_contents = true
	card.disabled = not unlocked
	card.focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	levels.add_child(card)
	cards.append(card)

	var picture := TextureRect.new()
	picture.position = Vector2(3, 3)
	picture.size = CARD_SIZE - Vector2(6, 6)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.texture = load("res://UI/LevelPreviews/level" + str(1 if i == 0 else 2) + ".png")
	if not unlocked:
		picture.modulate = Color(.18, .20, .24, 1)
	card.add_child(picture)
	_fade(card, picture.position, picture.size, Vector2(0, 1), [0.04, 0.08, 0.94, 1.0], [0.0, 0.42, 0.82, 1.0])

	label_at("LEVEL " + str(i + 1), Vector2(20, 249), 34, Color.WHITE if unlocked else MUTED, title_font, card)
	label_at(SUBTITLES[i], Vector2(21, 295), 15, Color("c0c5cd") if unlocked else MUTED, null, card)
	if unlocked:
		_add_best_result(card, i + 1)
		card.pressed.connect(_start_level.bind(i))
		card.focus_entered.connect(_select_level.bind(i))
		card.mouse_entered.connect(card.grab_focus)
		return
	var icon := LockIcon.new()
	icon.position = Vector2((width - 48) / 2, 130)
	icon.size = Vector2(48, 64)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(icon)
	# Small text under the lock, so it is clear why the level can't be played
	var tight_font: FontVariation = overline_font.duplicate()
	tight_font.spacing_glyph = 2
	var note := label_at(LOCK_TEXTS[i], Vector2(0, 208), 13, Color("929aa7"), tight_font, card)
	note.size = Vector2(width, 20)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


## Left/right jumps between the levels that can be played; down goes to BACK.
func _link_cards() -> void:
	var playable: Array[Button] = []
	for card in cards:
		if not card.disabled:
			playable.append(card)
	for i in playable.size():
		var card := playable[i]
		card.focus_neighbor_left = card.get_path_to(playable[maxi(i - 1, 0)])
		card.focus_neighbor_right = card.get_path_to(playable[mini(i + 1, playable.size() - 1)])
		card.focus_neighbor_top = card.get_path()
		card.focus_neighbor_bottom = card.get_path_to(back_button)


## Best result on a level card: filled gold coins + best score (saved by the score screen)
func _add_best_result(card: Button, level: int) -> void:
	var row := MedalRow.new()
	row.medals = Progress.get_best_medals(level)
	row.position = Vector2(20, 322)
	row.size = Vector2(80, 22)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var best: int = Progress.get_best_score(level)
	if best <= 0:
		return
	var best_label := label_at("BEST " + str(best), Vector2(CARD_SIZE.x - 120, 322), 13, GOLD, null, card)
	best_label.size = Vector2(100, 20)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


func _show_levels(animate := true) -> void:
	_switch(home, levels, animate, 1.0)
	cards[selected_level].grab_focus()


func _select_level(index: int) -> void:
	if index < 0 or not Progress.is_level_unlocked(index + 1):
		return
	selected_level = index
	back_button.focus_neighbor_top = back_button.get_path_to(cards[index])
	for i in range(cards.size()):
		var style := panel(Color("0c1118"), GOLD if i == index else Color("3a4048"), 3 if i == index else 2)
		if i == index:
			style.shadow_color = Color(.94, .72, .25, .2)
			style.shadow_size = 10
		cards[i].add_theme_stylebox_override("normal", style)
		cards[i].add_theme_stylebox_override("disabled", style)
		cards[i].add_theme_stylebox_override("hover", style)
		cards[i].add_theme_stylebox_override("pressed", style)
		cards[i].add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _start_level(index: int) -> void:
	if _starting_level or index < 0 or index > 1 or not Progress.is_level_unlocked(index + 1):
		return
	_starting_level = true
	_select_level(index)
	for card in cards:
		card.disabled = true
	_stop_music()
	# Come back to the level cards after playing
	_return_to = "levels"
	_last_level = index
	# The loading screen loads the level in the background, then plays the arrival intro
	LoadingScreen.open(get_tree(), first_level if index == 0 else second_level, index + 1)


# --------------------
# SETTINGS, CREDITS, QUIT
# --------------------
## The settings page (volume and mouse sensitivity), see UI/settings_screen.gd
func _build_settings() -> void:
	settings = SettingsScreen.new()
	settings.menu_background = true
	add_child(settings)
	settings.closed.connect(func(): home_buttons["Settings"].grab_focus())


# --------------------
# MUSIC
# The menu music is moved out of this scene, so it keeps playing on the
# credits page too. It stops when a level starts.
# --------------------
const MUSIC_PLAYER := "MenuMusicPlayer"

func _keep_music_playing() -> void:
	var own: AudioStreamPlayer = get_node_or_null("MenuMusic")
	if own == null:
		return
	own.stop()
	own.autoplay = false
	if get_tree().root.has_node(MUSIC_PLAYER):
		own.queue_free()
		return
	var music := AudioStreamPlayer.new()
	music.name = MUSIC_PLAYER
	music.stream = own.stream
	music.volume_db = own.volume_db
	music.autoplay = true
	own.queue_free()
	get_tree().root.add_child.call_deferred(music)


func _stop_music() -> void:
	var music := get_tree().root.get_node_or_null(MUSIC_PLAYER)
	if music == null:
		return
	music.name = "MenuMusicFadingOut"
	var fade := music.create_tween()
	fade.tween_property(music, "volume_db", -60.0, 0.6)
	fade.tween_callback(music.queue_free)


func _on_settings() -> void:
	settings.open()


func _on_credits() -> void:
	_return_to = "Credits"
	get_tree().change_scene_to_file(credits)


func _on_quit() -> void:
	get_tree().quit()


# --------------------
# HELPERS
# --------------------
## An empty full-screen layer for one view (home or levels).
func _view(view_name: String) -> Control:
	var view := Control.new()
	view.name = view_name
	view.size = canvas.size
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(view)
	return view


## Hides one view and shows the other, sliding in from the side.
func _switch(from: Control, to: Control, animate: bool, direction: float) -> void:
	from.hide()
	to.show()
	if _tween:
		_tween.kill()
	if not animate:
		to.modulate.a = 1.0
		to.position.x = 0.0
		return
	to.modulate.a = 0.0
	to.position.x = 40.0 * direction
	_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(to, "modulate:a", 1.0, 0.2)
	_tween.tween_property(to, "position:x", 0.0, 0.3)


## Small key hints in the bottom right corner.
func _hint(parent: Control, text: String) -> void:
	var tight_font: FontVariation = overline_font.duplicate()
	tight_font.spacing_glyph = 2
	var label := label_at(text, Vector2(600, 652), 13, HINT, tight_font, parent)
	label.size = Vector2(600, 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


## A gradient from the background colour (alpha 0-1 at each offset) over a rect.
func _fade(parent: Control, at: Vector2, area: Vector2, direction: Vector2, alphas: Array, offsets: Array) -> void:
	var gradient := Gradient.new()
	var colors := PackedColorArray()
	for alpha in alphas:
		colors.append(Color(BACKGROUND, alpha))
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2.ZERO
	texture.fill_to = direction
	var fade := TextureRect.new()
	fade.position = at
	fade.size = area
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fade)


func panel(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(7)
	return s


func label_at(text_value: String, pos: Vector2, font_size: int, color: Color, font: Font = null, parent: Node = null) -> Label:
	var l := Label.new()
	l.text = text_value
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else canvas).add_child(l)
	return l


func _resize() -> void:
	if not canvas:
		return
	var factor := minf(size.x / 1280.0, size.y / 720.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - Vector2(1280, 720) * factor) * .5
