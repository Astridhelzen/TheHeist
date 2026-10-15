extends Node3D

@export var target_energy := 1.2
@export var fade_time := 0.3
## Valfritt: dra in nivåns WorldEnvironment så blir även skuggorna ljusare
@export var world_environment: WorldEnvironment
@export var alarm_ambient_energy := 1.0

@onready var light: DirectionalLight3D = $Light
@onready var red_flash: ColorRect = $Overlay/RedFlash

func _ready() -> void:
	light.visible = false
	light.light_energy = 0.0
	red_flash.color.a = 0.0
	_connect_loot.call_deferred()

func _connect_loot() -> void:
	for loot in get_tree().get_nodes_in_group("loot"):
		loot.taken.connect(_turn_on)

func _turn_on() -> void:
	# Banken lyses upp
	light.visible = true
	var tween := create_tween()
	tween.tween_property(light, "light_energy", target_energy, fade_time)
	if world_environment:
		tween.parallel().tween_property(
			world_environment.environment, "ambient_light_energy",
			alarm_ambient_energy, fade_time)

	# Röd puls i skärmen, för alltid
	var pulse := create_tween().set_loops()
	pulse.tween_property(red_flash, "color:a", 0.12, 0.5)
	pulse.tween_property(red_flash, "color:a", 0.0, 0.5)
