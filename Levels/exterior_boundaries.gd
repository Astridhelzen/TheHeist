extends StaticBody3D
## Bangräns för spelaren. Lager 6 används inte av kameran eller vaktens syn.
@export var west_edge := 23.296
@export var entrance_start := 12.0
@export var entrance_end := 32.0

func _ready() -> void:
	collision_layer = 32
	collision_mask = 0
	# Placera gränsen innan marken tar slut.
	_wall("North", Vector2((west_edge + 67.0) / 2.0, -44.85), Vector2(67.0 - west_edge + 0.6, 0.3))
	_wall("South", Vector2((west_edge + 67.0) / 2.0, 54.85), Vector2(67.0 - west_edge + 0.6, 0.3))
	_wall("East", Vector2(66.85, 5.0), Vector2(0.3, 100.0))
	_wall("WestNorth", Vector2(west_edge + 0.15, (-45.0 + entrance_start) / 2.0), Vector2(0.3, entrance_start + 45.0))
	_wall("WestSouth", Vector2(west_edge + 0.15, (entrance_end + 55.0) / 2.0), Vector2(0.3, 55.0 - entrance_end))

func _wall(wall_name: String, centre: Vector2, dimensions: Vector2) -> void:
	var shape := BoxShape3D.new()
	shape.size = Vector3(dimensions.x, 8.0, dimensions.y)
	var collider := CollisionShape3D.new()
	collider.name = wall_name
	collider.shape = shape
	collider.position = Vector3(centre.x, 8.0, centre.y)
	add_child(collider)
