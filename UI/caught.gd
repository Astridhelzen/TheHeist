extends "res://UI/result_screen.gd"
## The screen when a guard catches the player. Same look as the score screen,
## but without points: it shows how far you got, then Retry / Main menu.

@export var lose_sound: AudioStream

## A dull red for the title, so it doesn't look like a win.
const RED := Color(0.86, 0.32, 0.28)


func _ready() -> void:
	super()
	_connect_guards.call_deferred()


func _connect_guards() -> void:
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.player_caught.connect(show_caught)


func show_caught() -> void:
	if visible or get_tree().paused:
		return
	read_results()
	_build()
	open()
	if lose_sound:
		Sfx.play(lose_sound)

	# Wait a moment before the buttons can be used, so a key the player
	# is still holding doesn't press Retry by accident
	buttons.modulate.a = 0.0
	await wait(0.8)
	create_tween().tween_property(buttons, "modulate:a", 1.0, 0.25)
	for button: Button in buttons.get_children():
		button.disabled = false
	# Retry is selected from the start (the last button, on the right)
	buttons.get_child(buttons.get_child_count() - 1).grab_focus()


func _build() -> void:
	build_base("CAUGHT", RED)
	add_label(content, "The guard got you.", OVERLINE_FONT, 16, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	add_spacer(content, 22)

	# The same rows as on the score screen, without points
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 48)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	_add_row(grid, "COINS", "%d / %d" % [coins_collected, coins_total])
	_add_row(grid, "TIME", format_time(elapsed_time))

	add_buttons_row()
	# Main menu on the left, Retry on the right
	add_button("MAIN MENU", main_menu).disabled = true
	add_button("RETRY", retry).disabled = true


func _add_row(grid: GridContainer, row_name: String, value: String) -> void:
	var label := add_label(grid, row_name, OVERLINE_FONT, 14, MUTED)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.custom_minimum_size = Vector2(110, 0)
	add_label(grid, value, MENU_FONT, 30, TEXT).custom_minimum_size = Vector2(140, 0)
