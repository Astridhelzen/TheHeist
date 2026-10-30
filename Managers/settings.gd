extends Node
## Autoload named "Settings". Keeps the player's settings, saves them to
## user://settings.cfg and applies them everywhere:
## - Master, Music and Effects volume (three audio buses)
## - Mouse sensitivity for the camera
## It also makes the big heading fonts sharp at every size (see FONTS below).
##
## Sounds are sorted onto the buses automatically: a sound player with
## "music" in its name goes to the Music bus, every other sound to SFX.

const SAVE_PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

## The "normal" values, used the first time and by the RESET button.
## Volumes are 0-1. Mouse sensitivity 1 = the camera speed set on the Player (0.25-2.0).
const DEFAULTS := {
	"master_volume": 0.8,
	"music_volume": 0.7,
	"effects_volume": 1.0,
	"mouse_sensitivity": 1.0,
}

var master_volume: float = DEFAULTS.master_volume
var music_volume: float = DEFAULTS.music_volume
var effects_volume: float = DEFAULTS.effects_volume
var mouse_sensitivity: float = DEFAULTS.mouse_sensitivity


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_use_sharp_fonts()
	_create_bus(MUSIC_BUS)
	_create_bus(SFX_BUS)
	_load()
	apply()
	get_tree().node_added.connect(_on_node_added)
	# Sounds and players that already exist (e.g. the main menu music)
	for node in get_tree().root.find_children("*", "", true, false):
		_on_node_added(node)


## Changes one setting, applies it and saves.
func set_setting(setting: String, value: float) -> void:
	set(setting, value)
	apply()
	save()


## Puts every setting back to its default value, applies it and saves.
func reset_to_defaults() -> void:
	for setting in DEFAULTS:
		set(setting, DEFAULTS[setting])
	apply()
	save()


func apply() -> void:
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(MUSIC_BUS, music_volume)
	_set_bus_volume(SFX_BUS, effects_volume)
	if PlayerManager.player != null and is_instance_valid(PlayerManager.player):
		_apply_mouse(PlayerManager.player)


func save() -> void:
	var file := ConfigFile.new()
	file.set_value("audio", "master", master_volume)
	file.set_value("audio", "music", music_volume)
	file.set_value("audio", "effects", effects_volume)
	file.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	file.save(SAVE_PATH)


func _load() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return
	master_volume = file.get_value("audio", "master", master_volume)
	music_volume = file.get_value("audio", "music", music_volume)
	effects_volume = file.get_value("audio", "effects", effects_volume)
	mouse_sensitivity = file.get_value("controls", "mouse_sensitivity", mouse_sensitivity)


func _create_bus(bus_name: StringName) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")


func _set_bus_volume(bus_name: StringName, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, value <= 0.001)
	AudioServer.set_bus_volume_linear(index, maxf(value, 0.001))


func _on_node_added(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.bus == &"Master":
			node.bus = MUSIC_BUS if "music" in String(node.name).to_lower() else SFX_BUS
	elif node is CharacterBody3D and "mouse_sensitivity" in node:
		_apply_mouse(node)


func _apply_mouse(player: Node) -> void:
	# Remember the speed set on the Player once, then scale it
	if not player.has_meta("base_mouse_sensitivity"):
		player.set_meta("base_mouse_sensitivity", player.mouse_sensitivity)
	player.mouse_sensitivity = player.get_meta("base_mouse_sensitivity") * mouse_sensitivity


# --------------------
# FONTS
# --------------------
## The big heading fonts. They are drawn in many sizes (and scaled with the
## window), and Godot could then sometimes draw letters with black boxes in
## them. With MSDF each letter is made once and scaled sharply to every size.
const SHARP_FONTS := [
	"res://UI/Fonts/Big_Shoulders/static/BigShoulders-Black.ttf",
	"res://UI/Fonts/Big_Shoulders/static/BigShoulders-Bold.ttf",
]

# Kept here so the changed fonts stay in memory (otherwise they are unloaded
# and loaded again later without the change)
var _sharp_fonts: Array[FontFile] = []

func _use_sharp_fonts() -> void:
	for path in SHARP_FONTS:
		var font := load(path) as FontFile
		if font == null:
			continue
		_sharp_fonts.append(font)
		if font.multichannel_signed_distance_field:
			continue
		font.msdf_pixel_range = 16
		font.msdf_size = 64
		font.multichannel_signed_distance_field = true
