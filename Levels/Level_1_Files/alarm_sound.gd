extends AudioStreamPlayer
## Put this on an AudioStreamPlayer in the level.
## Starts the alarm when the loot is taken and keeps it going for as long as
## the guards are in alarm mode (their alarm_duration), then fades it out.

## How long the fade-out at the end takes (seconds).
@export var fade_time: float = 1.5
## Used only if no guard is found to read alarm_duration from.
@export var fallback_duration: float = 10.0

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

	# Same length as the guards' alarm mode
	var duration := fallback_duration
	var guard := get_tree().get_first_node_in_group("guards")
	if guard:
		duration = guard.alarm_duration

	await get_tree().create_timer(maxf(duration - fade_time, 0.0), false).timeout
	stop_alarm()


func stop_alarm() -> void:
	if not _active:
		return
	var tween := create_tween()
	tween.tween_property(self, "volume_db", -40.0, fade_time)
	await tween.finished
	_active = false
	stop()
	volume_db = _start_volume


func _on_finished() -> void:
	if _active:
		play()
