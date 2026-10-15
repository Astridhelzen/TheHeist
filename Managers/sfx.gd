extends Node
## Autoload named "Sfx". Plays one-shot sound effects from anywhere:
##     Sfx.play(my_sound)
## The sounds keep playing even if the node that triggered them is removed
## (e.g. a picked-up item that calls queue_free) or the scene changes.
##
## It also gives EVERY button in the game a hover sound and a click sound
## automatically, in all menus. Put the sound files at the paths below.

const HOVER_SOUND_PATH := "res://Assets/Sounds/ui_hover.ogg"
const CLICK_SOUND_PATH := "res://Assets/Sounds/ui_click.ogg"
const UI_VOLUME_DB := -5

var _hover_sound: AudioStream
var _click_sound: AudioStream
var _last_hovered: Control
var _last_button_added_frame := -100


func _ready() -> void:
	# Keep playing even when the game is paused (e.g. in the pause menu)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_hover_sound = _load_if_exists(HOVER_SOUND_PATH)
	_click_sound = _load_if_exists(CLICK_SOUND_PATH)

	# Hook up every button that appears in the game, now and later
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().root.find_children("*", "BaseButton", true, false):
		_hook_button(node)


func play(stream: AudioStream, volume_db: float = 0.0, is_ui: bool = false) -> void:
	if not stream:
		push_warning("Sfx.play() was called without a sound")
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	if is_ui:
		player.set_meta("ui", true)
	add_child(player)
	# Remove the player when the sound is done
	player.finished.connect(player.queue_free)
	player.play()


## Stops every sound that Sfx is playing right now, except menu clicks
## (so the click on "Main menu" isn't cut off when the menu opens).
func stop_all() -> void:
	for player in get_children():
		if player.has_meta("ui"):
			continue
		player.stop()
		player.queue_free()


# --------------------
# BUTTON SOUNDS
# --------------------
func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)


func _hook_button(button: BaseButton) -> void:
	_last_button_added_frame = Engine.get_process_frames()
	if not button.mouse_entered.is_connected(_on_hover):
		button.mouse_entered.connect(_on_hover.bind(button))
		button.mouse_exited.connect(_on_mouse_left.bind(button))
		button.focus_entered.connect(_on_focus.bind(button))
		button.pressed.connect(_on_click.bind(button))


func _on_hover(button: BaseButton) -> void:
	if button.disabled or button == _last_hovered:
		return
	_last_hovered = button
	if _hover_sound:
		play(_hover_sound, UI_VOLUME_DB, true)


func _on_mouse_left(button: BaseButton) -> void:
	# So hovering the same button again makes a sound again
	if _last_hovered == button:
		_last_hovered = null


func _on_focus(button: BaseButton) -> void:
	# A menu that just opened and selects its first button shouldn't click
	if Engine.get_process_frames() - _last_button_added_frame < 5:
		_last_hovered = button
		return
	# Clicking with the mouse also gives focus; the hover already made a sound
	if button == _last_hovered:
		return
	_on_hover(button)


func _on_click(button: BaseButton) -> void:
	_last_hovered = button
	if _click_sound:
		play(_click_sound, UI_VOLUME_DB, true)


func _load_if_exists(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Sfx: no sound found at " + path)
	return null
