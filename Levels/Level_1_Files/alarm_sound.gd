extends AudioStreamPlayer
## Put this on an AudioStreamPlayer in the level.
## Starts the alarm when the loot is taken and keeps it going, just like the
## alarm lights, until the level ends. Call stop_alarm() to fade it out.

## How long the fade-out takes (seconds) when stop_alarm() is called.
@export var fade_time: float = 1.5

var _active := false
var _start_volume := 0.0


func _ready() -> void:
	_start_volume = volume_db
	# Restart the sound when it ends, so it loops even if the file doesn't
	finished.connect(_on_finished)
	_connect_loot.call_deferred()


func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(start_alarm)


func start_alarm() -> void:
	if _active:
		return
	_active = true
	volume_db = _start_volume
	play()


func stop_alarm() -> void:
	if not _active:
		return
	_active = false
	var tween := create_tween()
	tween.tween_property(self, "volume_db", -40.0, fade_time)
	await tween.finished
	stop()
	volume_db = _start_volume


func _on_finished() -> void:
	if _active:
		play()
