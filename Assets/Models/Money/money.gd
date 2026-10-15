extends Area3D

signal taken

@export var pickup_sound: AudioStream

@onready var model: Node3D = $Model

var is_taken := false
var base_y := 0.0
var time := 0.0

func _ready() -> void:
	add_to_group("loot")
	base_y = model.position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Svävar och snurrar sakta, så att det syns att man kan ta den
	time += delta
	model.position.y = base_y + sin(time * 2.0) * 0.05

func _on_body_entered(body: Node3D) -> void:
	if body == PlayerManager.player and not is_taken:
		is_taken = true
		# Sfx spelar klart ljudet även fast pengarna tas bort direkt
		Sfx.play(pickup_sound)
		taken.emit()
		queue_free()
