extends Node
## Fotsteg för spelare och vakter, synkade med animationen.

signal step

@export var animation_player: AnimationPlayer
@export var audio: AudioStreamPlayer3D
## Stegtider som andel av animationen (0–1). Övriga animationer är tysta.
@export var step_times: Dictionary = {
	&"movement/sneaking": [0.253, 0.733],
	&"movement/walking": [0.331, 0.786],
	&"movement/running": [0.343, 0.843],
}
## Volymändring per animation i dB.
@export var volume_offsets: Dictionary = {
	&"movement/sneaking": -14.0,
	&"movement/running": +14.0,
}
## Lite variation i tonhöjd mellan stegen.
@export var pitch_variation: float = 0.1
 
var _base_volume := 0.0
var _last_anim: StringName = &""
var _last_pos := 0.0
 
 
func _ready() -> void:
	if audio:
		_base_volume = audio.volume_db
 
 
func _process(_delta: float) -> void:
	if not animation_player or not animation_player.is_playing():
		_last_anim = &""
		return
 
	var anim := animation_player.current_animation
	if not step_times.has(anim):
		_last_anim = anim
		return
 
	var length := animation_player.current_animation_length
	if length <= 0.0:
		return
	var pos := animation_player.current_animation_position / length
 
	# Starta om stegtimingen vid animationsbyte.
	if anim != _last_anim:
		_last_anim = anim
		_last_pos = pos
		return
 
	for t in step_times[anim]:
		if _crossed(_last_pos, pos, t):
			_play_step(anim)
 
	_last_pos = pos
 
 
## Kontrollerar om tiden passerats, även vid loopning.
func _crossed(from: float, to: float, t: float) -> bool:
	if to >= from:
		return from < t and t <= to
	# Animationen har börjat om.
	return t > from or t <= to
 
 
func _play_step(anim: StringName) -> void:
	if audio:
		audio.volume_db = _base_volume + volume_offsets.get(anim, 0.0)
		audio.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		audio.play()
	step.emit()
 
