extends "res://UI/result_screen.gd"
## The score screen when the player escapes.
## Coins and time give points that count up one by one, with a coin "clink"
## for each step. Every time the score passes a limit, one of the three
## gold coins at the top fills in. Then: Retry / Next level / Main menu.
## Press any key or click while it counts to skip to the end.

const Progress = preload("res://Managers/level_progress.gd")

## The level the "Next level" button loads. Empty = no button (last level).
@export_file("*.tscn") var next_level: String = ""
@export var win_sound: AudioStream

@export_group("Score")
@export var points_per_coin: int = 100
## The most points you can get for time.
@export var max_time_bonus: int = 1000
## Done in this many seconds or faster = the full time bonus.
@export var par_time: float = 90.0
## Done in this many seconds or slower = no time bonus. In between it goes down evenly.
@export var slow_time: float = 300.0
## The score needed for coin 1, 2 and 3.
@export var medal_scores: Array[int] = [600, 1100, 1500]
## How long the counting stops when a gold coin fills in, so you see each one.
@export var medal_pause: float = 0.6
## Let the player skip the counting with Space ("PRESS SPACE TO SKIP" is shown).
@export var skippable: bool = true

@export_group("Sounds")
## The clink while the points count. Empty = Assets/Sounds/coin_collected.ogg
@export var tick_sound: AudioStream
## Plays when a gold coin fills in. Empty = Assets/Sounds/ka_ching.mp3
@export var medal_sound: AudioStream
@export var tick_volume_db: float = -6.0

var coin_points := 0
var time_points := 0
var total_score := 0

var _score := 0.0
var _coin_shown := 0
var _time_shown := 0.0
var _next_medal := 0
var _counting := false
var _skipping := false
var _last_tick_ms := 0
var _medal_just_filled := false
var _skip_hint: Label
var _previous_best := 0
var _new_best: Label

var _medals: Array[Medal] = []
var _medal_labels: Array[Label] = []
var _coins_value: Label
var _coins_points: Label
var _time_value: Label
var _time_points: Label
var _score_label: Label


func _ready() -> void:
	super()
	if tick_sound == null:
		tick_sound = load_if_exists("res://Assets/Sounds/coin_collected.ogg")
	if medal_sound == null:
		medal_sound = load_if_exists("res://Assets/Sounds/ka_ching.mp3")
	_connect_exits.call_deferred()


func _connect_exits() -> void:
	for door in get_tree().get_nodes_in_group("exits"):
		door.escaped.connect(show_win)


func show_win() -> void:
	if visible or get_tree().paused:
		return
	Progress.complete_level(level_number)
	read_results()
	_calculate_score()
	# Save the best result for the level cards in the main menu
	if level_number > 0:
		_previous_best = Progress.get_best_score(level_number)
		Progress.save_best(level_number, total_score, _medals_for(total_score))
	_build()
	open()
	if win_sound:
		Sfx.play(win_sound)
	_count_up()


func _calculate_score() -> void:
	coin_points = coins_collected * points_per_coin
	var t := 1.0
	if slow_time > par_time:
		t = clampf((slow_time - elapsed_time) / (slow_time - par_time), 0.0, 1.0)
	# Round to tens so the numbers look tidy
	time_points = int(round(max_time_bonus * t / 10.0)) * 10
	total_score = coin_points + time_points


## How many gold coins (0-3) a score gives.
func _medals_for(score: int) -> int:
	var count := 0
	for needed in medal_scores.slice(0, 3):
		if score >= needed:
			count += 1
	return count


# --------------------
# LAYOUT
# --------------------
func _build() -> void:
	build_base("HEIST COMPLETE", GOLD)

	# The three gold coins, with the score each one needs under it
	add_spacer(content, 8)
	var medal_row := HBoxContainer.new()
	medal_row.alignment = BoxContainer.ALIGNMENT_CENTER
	medal_row.add_theme_constant_override("separation", 44)
	content.add_child(medal_row)
	for i in 3:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		medal_row.add_child(column)
		var medal := Medal.new()
		medal.font = TITLE_FONT
		medal.custom_minimum_size = Vector2(96, 96)
		column.add_child(medal)
		_medals.append(medal)
		var needed := medal_scores[i] if i < medal_scores.size() else 0
		_medal_labels.append(add_label(column, str(needed), OVERLINE_FONT, 14, MUTED, HORIZONTAL_ALIGNMENT_CENTER))
	add_spacer(content, 18)

	# COINS   6 / 8      +600
	# TIME    01:12:40   +480
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 48)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	_add_row_name(grid, "COINS")
	_coins_value = _add_row_value(grid, "%d / %d" % [coins_collected, coins_total])
	_coins_points = _add_row_points(grid)
	_add_row_name(grid, "TIME")
	_time_value = _add_row_value(grid, format_time(elapsed_time))
	_time_points = _add_row_points(grid)
	# The rows fade in one at a time
	for child in grid.get_children():
		child.modulate.a = 0.0

	add_spacer(content, 4)
	add_divider(content, 460)

	# SCORE   1080
	var score_row := HBoxContainer.new()
	score_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	score_row.custom_minimum_size = Vector2(460, 0)
	content.add_child(score_row)
	var score_name := add_label(score_row, "SCORE", OVERLINE_FONT, 14, MUTED)
	score_name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	score_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# "NEW BEST" next to the score, shown at the end if the record was beaten
	_new_best = add_label(score_row, "NEW BEST", OVERLINE_FONT, 14, GOLD)
	_new_best.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_new_best.modulate.a = 0.0
	add_spacer(score_row, 0)
	score_row.get_child(score_row.get_child_count() - 1).custom_minimum_size = Vector2(18, 0)
	_score_label = add_label(score_row, "0", TITLE_FONT, 64, TEXT, HORIZONTAL_ALIGNMENT_RIGHT)

	add_buttons_row()
	add_button("RETRY", retry)
	if not next_level.is_empty() and ResourceLoader.exists(next_level):
		add_button("NEXT LEVEL", go_to.bind(next_level))
	add_button("MAIN MENU", main_menu)
	buttons.modulate.a = 0.0
	_set_buttons_enabled(false)


func _add_row_name(grid: GridContainer, text: String) -> void:
	var label := add_label(grid, text, OVERLINE_FONT, 14, MUTED)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.custom_minimum_size = Vector2(110, 0)


func _add_row_value(grid: GridContainer, text: String) -> Label:
	var label := add_label(grid, text, MENU_FONT, 30, TEXT)
	label.custom_minimum_size = Vector2(140, 0)
	return label


func _add_row_points(grid: GridContainer) -> Label:
	var label := add_label(grid, "+0", MENU_FONT, 30, GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	label.custom_minimum_size = Vector2(110, 0)
	return label


# --------------------
# COUNTING UP
# --------------------
func _count_up() -> void:
	_counting = true
	if skippable:
		_add_skip_hint()
	await _pause(0.7)

	# Coins: one clink per coin, a little higher each time
	_show_row(0)
	await _pause(0.3)
	var step := clampf(1.0 / maxf(coins_collected, 1), 0.08, 0.18)
	for i in coins_collected:
		if _skipping:
			break
		_coin_shown += points_per_coin
		_coins_points.text = "+%d" % _coin_shown
		_add_score(points_per_coin)
		_pop(_coins_points)
		play_sound(tick_sound, 1.0 + i * 0.06, tick_volume_db)
		await _pause(step)
		# A gold coin filled in: hold for a moment so the player sees it
		if _medal_just_filled:
			_medal_just_filled = false
			await _pause(medal_pause)

	# Time: the bonus runs up fast and slows down at the end
	await _pause(0.35)
	_show_row(1)
	await _pause(0.3)
	if not _skipping and time_points > 0:
		var tween := create_tween()
		tween.tween_method(_set_time_shown, 0.0, float(time_points),
				clampf(time_points / 700.0, 0.6, 1.5)) \
				.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		while tween.is_running() and not _skipping:
			await get_tree().process_frame
			if _medal_just_filled and tween.is_running():
				# Stop the count for a moment while the gold coin pops
				_medal_just_filled = false
				tween.pause()
				await _pause(medal_pause)
				tween.play()
		tween.kill()

	_finish()


## Like wait(), but returns right away once the player has skipped.
func _pause(seconds: float) -> void:
	if not _skipping:
		await wait(seconds)


func _set_time_shown(value: float) -> void:
	_add_score(value - _time_shown)
	_time_shown = value
	_time_points.text = "+%d" % int(value)
	# A clink about every 55 ms, rising in pitch as the bonus fills up
	var now := Time.get_ticks_msec()
	if now - _last_tick_ms > 55:
		_last_tick_ms = now
		play_sound(tick_sound, 1.0 + 0.5 * value / maxf(time_points, 1.0), tick_volume_db - 2.0)


func _add_score(amount: float) -> void:
	_score += amount
	_score_label.text = str(int(round(_score)))
	while _next_medal < 3 and _next_medal < medal_scores.size() \
			and int(round(_score)) >= medal_scores[_next_medal]:
		_fill_medal(_next_medal, not _skipping)
		_next_medal += 1
		# One gold coin at a time while counting. The next one fills on the next step.
		if not _skipping and _counting:
			_medal_just_filled = true
			break


func _fill_medal(index: int, with_sound: bool) -> void:
	var medal := _medals[index]
	medal.filled = true
	medal.pop = 1.0
	create_tween().tween_property(medal, "pop", 0.0, 0.8) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_medal_labels[index].add_theme_color_override("font_color", GOLD)
	_pop(_score_label, 1.25)
	if with_sound:
		play_sound(medal_sound, 1.0 + index * 0.12)


func _finish() -> void:
	# Jump to the final numbers (only changes anything if the player skipped)
	_show_row(0)
	_show_row(1)
	_coins_points.text = "+%d" % coin_points
	_time_points.text = "+%d" % time_points
	_counting = false
	_hide_skip_hint()
	var had_medals := _next_medal
	_add_score(total_score - _score)
	if _skipping and _next_medal > had_medals:
		play_sound(medal_sound, 1.0 + (_next_medal - 1) * 0.12)

	if level_number > 0 and total_score > _previous_best:
		_new_best.modulate.a = 1.0
		_pop(_new_best, 1.4)

	await wait(0.45)
	create_tween().tween_property(buttons, "modulate:a", 1.0, 0.25)
	_set_buttons_enabled(true)
	# Next level if there is one, otherwise Retry
	var first: Button = buttons.get_child(1) if buttons.get_child_count() == 3 else buttons.get_child(0)
	first.grab_focus()


func _show_row(row: int) -> void:
	var grid := _coins_value.get_parent()
	for column in 3:
		var cell: Control = grid.get_child(row * 3 + column)
		if cell.modulate.a < 1.0:
			create_tween().tween_property(cell, "modulate:a", 1.0, 0.2)


func _pop(label: Label, amount := 1.15) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2.ONE * amount
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.15)


func _set_buttons_enabled(enabled: bool) -> void:
	for button: Button in buttons.get_children():
		button.disabled = not enabled
		button.focus_mode = Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	# Only Space skips. Other keys (W, Shift...) are ignored: the player is
	# usually still holding them when running through the exit.
	if not skippable or not _counting or _skipping:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_SPACE:
		_skipping = true
		_hide_skip_hint()
		get_viewport().set_input_as_handled()


func _add_skip_hint() -> void:
	_skip_hint = Label.new()
	_skip_hint.text = "PRESS SPACE TO SKIP"
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_hint.add_theme_font_override("font", OVERLINE_FONT)
	_skip_hint.add_theme_font_size_override("font_size", 13)
	_skip_hint.add_theme_color_override("font_color", MUTED)
	_skip_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Bottom centre of the screen, below where the buttons appear
	_skip_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_skip_hint.offset_left = -300
	_skip_hint.offset_right = 300
	_skip_hint.offset_top = -48
	_skip_hint.offset_bottom = -24
	root.add_child(_skip_hint)
	# Slow blink, so it is noticed but doesn't steal attention
	_skip_hint.modulate.a = 0.0
	var blink := _skip_hint.create_tween().set_loops()
	blink.tween_property(_skip_hint, "modulate:a", 1.0, 0.7)
	blink.tween_property(_skip_hint, "modulate:a", 0.35, 0.7)


func _hide_skip_hint() -> void:
	if _skip_hint:
		_skip_hint.queue_free()
		_skip_hint = null


# --------------------
# THE GOLD COIN
# --------------------
class Medal extends Control:
	const RIM := Color(0.76, 0.53, 0.15)
	const FACE := Color(1.0, 0.79, 0.32)
	const LINE := Color(0.84, 0.6, 0.18)
	const MARK := Color(0.66, 0.44, 0.1)
	const EMPTY_FILL := Color(0.06, 0.075, 0.09, 0.9)
	const EMPTY_RIM := Color("3a4048")
	const EMPTY_LINE := Color("262b32")

	var font: Font
	var filled := false:
		set(value):
			filled = value
			queue_redraw()
	## 1 right when it fills in, then falls to 0 (grow, glow and rays).
	var pop := 0.0:
		set(value):
			pop = value
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := 36.0
		if not filled:
			draw_circle(size / 2.0, r, EMPTY_FILL)
			draw_arc(size / 2.0, r, 0.0, TAU, 64, EMPTY_RIM, 2.5, true)
			draw_arc(size / 2.0, r * 0.68, 0.0, TAU, 48, EMPTY_LINE, 2.0, true)
			return

		draw_set_transform(size / 2.0, 0.0, Vector2.ONE * (1.0 + 0.35 * pop))
		if pop > 0.0:
			draw_circle(Vector2.ZERO, r * 1.6, Color(1.0, 0.8, 0.35, 0.22 * pop))
			for i in 10:
				var direction := Vector2.from_angle(i * TAU / 10.0)
				draw_line(direction * r * 1.2, direction * r * (1.25 + 0.6 * pop),
						Color(1.0, 0.86, 0.5, pop), 3.0, true)
		draw_circle(Vector2.ZERO, r, RIM)
		draw_circle(Vector2.ZERO, r - 4.0, FACE)
		draw_arc(Vector2.ZERO, r * 0.68, 0.0, TAU, 48, LINE, 3.0, true)
		# Shine in the top left
		draw_arc(Vector2.ZERO, r - 8.0, deg_to_rad(195.0), deg_to_rad(265.0), 16,
				Color(1.0, 0.96, 0.8, 0.85), 3.0, true)
		if font:
			var mark_size := font.get_string_size("$", HORIZONTAL_ALIGNMENT_LEFT, -1, 36)
			draw_string(font, Vector2(-mark_size.x / 2.0, 12.0), "$",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 36, MARK)
		draw_set_transform(Vector2.ZERO)
