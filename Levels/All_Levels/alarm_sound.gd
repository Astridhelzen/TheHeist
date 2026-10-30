extends AudioStreamPlayer
## Loopar larmet efter stölden. stop_alarm() tonar ut ljudet.

## Tid för uttoning i sekunder.
@export var fade_time: float = 1.5

var _active := false
var _start_volume := 0.0


func _ready() -> void:
	_start_volume = volume_db
	# Starta om ljudet när det tar slut.
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
