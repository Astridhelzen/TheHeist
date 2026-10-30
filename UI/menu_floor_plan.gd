class_name MenuFloorPlan
extends Control
## Menybakgrund med banken ovanifrån. Renderad från BANK.blend, layout i 1280 × 720.

const BANK_PICTURE := preload("res://UI/menu_bank.png")
## Vaktens position i menyn, vid axlarnas mitt.
const GUARD_POSITION := Vector2(630, 470)
## Vaktbildens visningsstorlek.
const GUARD_SCALE := 0.5
## Lampans läge relativt vakten och vaktens ljusstyrka.
const GUARD_SHADE := Color(0.3, 0.33, 0.4)
const LAMP_OFFSET := Vector2(185, 67) * GUARD_SCALE
## Tid för ljusets förflyttning i sekunder.
const SWEEP_TIME := 0.35

const LIGHT_SHADER := """
shader_type canvas_item;
// Lampans position och mål i menykoordinater.
uniform vec2 origin;
uniform vec2 target;
// Ljuskäglans halvvinkel i radianer.
uniform float spread = 0.2;
// Ljusstyrka utanför ljuskäglan (0–1).
uniform float ambient = 0.13;
// Ljusstyrka mitt i ljuskäglan (0–1).
uniform float lit = 0.62;
uniform vec3 light_color : source_color = vec3(1.0, 0.84, 0.6);
// Storlek på ljusfläcken vid målet.
uniform float spot_radius = 50.0;
// 0 stänger av ficklampan.
uniform float strength = 1.0;
// Blå ton i mörka områden.
uniform vec3 night_tint : source_color = vec3(0.55, 0.65, 0.85);
varying vec2 local;

void vertex() {
	local = VERTEX;
}

void fragment() {
	vec2 dir = normalize(target - origin);
	vec2 to_point = local - origin;
	float dist = length(to_point);
	float reach = length(target - origin) * 1.2;
	float angle = dot(to_point / max(dist, 0.001), dir);
	// Mjuka kanter och uttoning för ljuskäglan.
	float beam = smoothstep(cos(spread), cos(spread * 0.4), angle);
	beam *= 1.0 - smoothstep(reach * 0.7, reach, dist);
	// Ljusfläck utdragen längs strålen.
	vec2 d = local - target;
	vec2 across_dir = vec2(-dir.y, dir.x);
	float spot = length(vec2(dot(d, dir) / (spot_radius * 2.0), dot(d, across_dir) / spot_radius));
	spot = 1.0 - smoothstep(0.15, 1.0, spot);
	// Glöd runt lampan.
	float lamp = 1.0 - smoothstep(0.0, 55.0, dist);
	float light = clamp(beam * 0.45 + spot + lamp * 0.4, 0.0, 1.0) * strength;
	vec3 dark = COLOR.rgb * night_tint * ambient;
	vec3 bright = COLOR.rgb * light_color * lit;
	COLOR.rgb = mix(dark, bright, light);
}
"""

## Dölj vakt och ficklampa på övriga menysidor.
var with_guard := true
## Extra mörker bakom texten (0–1).
var dim := 0.0

var _guard: Guard
var _aim := Vector2(170, 367)
var _tween: Tween
var _time := 0.0
var _material: ShaderMaterial


## Vaktbild från Idle.fbx, riktad åt höger. facing styr rotationen.
class Guard extends Control:
	const PICTURE := preload("res://UI/menu_guard.png")
	var facing := 0.0
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, facing, Vector2.ONE * GUARD_SCALE)
		# Mjuk golvskugga.
		for i in 4:
			draw_circle(Vector2(6, 8), 52 - i * 10, Color(0, 0, 0, 0.12))
		# Mörk vakt med lysande lampa.
		draw_texture(PICTURE, -PICTURE.get_size() / 2.0, GUARD_SHADE)
		# Svag glöd vid lampan.
		draw_circle(LAMP_OFFSET / GUARD_SCALE, 10, Color(1.0, 0.9, 0.65, 0.25))
		draw_circle(LAMP_OFFSET / GUARD_SCALE, 5, Color(1.0, 0.93, 0.75, 0.9))
		draw_set_transform(Vector2.ZERO)


func _ready() -> void:
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := TextureRect.new()
	picture.texture = BANK_PICTURE
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.size = size
	picture.stretch_mode = TextureRect.STRETCH_SCALE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = LIGHT_SHADER
	_material.shader = shader
	picture.material = _material
	add_child(picture)
	# Mörkare bakom rubriken.
	var shade := TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.03, 0.045, 0.06, 0.75), Color(0.03, 0.045, 0.06, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.15, 0.3)
	texture.fill_to = Vector2(0.75, 0.3)
	shade.texture = texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.size = size
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	if dim > 0.0:
		var darkness := ColorRect.new()
		darkness.color = Color(0.03, 0.045, 0.06, dim)
		darkness.size = size
		darkness.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(darkness)
	if not with_guard:
		_material.set_shader_parameter("strength", 0.0)
		set_process(false)
		return
	_guard = Guard.new()
	_guard.position = GUARD_POSITION
	_guard.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_guard)


## Rikta lampan mot en punkt. animate=false flyttar den direkt.
func aim_at(point: Vector2, animate := true) -> void:
	if _tween:
		_tween.kill()
	if not animate or not is_inside_tree():
		_aim = point
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "_aim", point, SWEEP_TIME)


func _process(delta: float) -> void:
	_time += delta
	# Liten handrörelse för ljuset.
	var sway := Vector2(sin(_time * 1.3) * 4.0, sin(_time * 0.9 + 1.0) * 3.0)
	var target := _aim + sway
	_guard.facing = (target - GUARD_POSITION).angle()
	_guard.queue_redraw()
	var lamp := GUARD_POSITION + LAMP_OFFSET.rotated(_guard.facing)
	_material.set_shader_parameter("origin", lamp)
	_material.set_shader_parameter("target", target)


## Mörk bankbakgrund utan vakt.
static func page_background(darkness := 0.45) -> MenuFloorPlan:
	var plan := MenuFloorPlan.new()
	plan.with_guard = false
	plan.dim = darkness
	return plan
