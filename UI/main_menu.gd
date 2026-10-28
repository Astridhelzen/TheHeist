extends Control

class LockIcon extends Control:
 func _draw() -> void:
  var color=Color("929aa7")
  draw_arc(Vector2(24,20),12,PI,TAU,24,color,6,true)
  draw_line(Vector2(12,20),Vector2(12,30),color,6,true)
  draw_line(Vector2(36,20),Vector2(36,30),color,6,true)
  var body=StyleBoxFlat.new();body.bg_color=color;body.set_corner_radius_all(4)
  draw_style_box(body,Rect2(4,28,40,31))
  draw_circle(Vector2(24,40),4,Color("10151b"))
  draw_rect(Rect2(22,40,4,10),Color("10151b"))

## Three small gold coins on a level card: the best result on that level.
class MedalRow extends Control:
 var medals := 0
 func _draw() -> void:
  for i in range(3):
   _draw_coin(Vector2(10 + i * 26, size.y / 2), i < medals)
 func _draw_coin(c: Vector2, filled: bool) -> void:
  if not filled:
   draw_circle(c, 10, Color(0.06, 0.075, 0.09, 0.9))
   draw_arc(c, 10, 0, TAU, 32, Color("3a4048"), 1.5, true)
   return
  draw_circle(c, 10, Color(0.76, 0.53, 0.15))
  draw_circle(c, 8, Color(1.0, 0.79, 0.32))
  draw_arc(c, 5.5, 0, TAU, 24, Color(0.84, 0.6, 0.18), 1.5, true)

@export_file("*.tscn") var first_level: String = "res://Levels/Level_1/Level_1.tscn"
@export_file("*.tscn") var second_level: String = "res://Level2.tscn"
@export_file("*.tscn") var credits: String = "res://UI/credits.tscn"
const Progress = preload("res://Managers/level_progress.gd")
const GOLD = Color("efc260")
const MUTED = Color("87909f")
var selected_level := 0
var canvas: Control
var cards: Array[Button] = []
var _starting_level := false
var settings: AcceptDialog
var title_font = preload("res://UI/Fonts/title.tres")
const MENU_BUTTON = preload("res://UI/menu_button.tscn")
const MENU_THEME = preload("res://UI/Themes/ui_theme.tres")
var overline_font = preload("res://UI/Fonts/overline.tres")

func panel(color: Color, border: Color, width: int = 1) -> StyleBoxFlat:
 var s = StyleBoxFlat.new()
 s.bg_color = color
 s.border_color = border
 s.set_border_width_all(width)
 s.set_corner_radius_all(7)
 return s

func label_at(text_value: String, pos: Vector2, font_size: int, color: Color, font: Font = null, parent: Node = null) -> Label:
 var l = Label.new()
 l.text = text_value
 l.position = pos
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", color)
 if font: l.add_theme_font_override("font", font)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 (parent if parent else canvas).add_child(l)
 return l

func _ready() -> void:
 theme = MENU_THEME
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 Sfx.stop_all()
 canvas = Control.new()
 canvas.name = "LevelSelection"
 add_child(canvas)
 canvas.size = Vector2(1280,720)
 var bg = ColorRect.new()
 bg.size = canvas.size
 bg.color = Color("080c10")
 bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
 canvas.add_child(bg)
 label_at("A STEALTH GAME", Vector2(76,65), 14, MUTED, overline_font)
 label_at("THE HEIST", Vector2(72,86), 108, Color("eef0f3"), title_font)
 label_at("SELECT A LEVEL", Vector2(78,211), 16, MUTED)
 var titles = ["SETTINGS", "CREDITS", "QUIT"]
 var actions = [_on_settings, _on_credits, _on_quit]
 for i in range(titles.size()):
  var b = MENU_BUTTON.instantiate()
  b.name = titles[i].capitalize()
  b.text = titles[i]
  b.position = Vector2(80,316+i*60)
  b.size = Vector2(220,54)
  canvas.add_child(b)
  b.pressed.connect(actions[i])
 var subtitles=["THE BANK","THE GRAND BANK","THE ROOFTOP","THE VAULT"]
 for i in range(4):
  var unlocked=Progress.is_level_unlocked(i+1)
  var b=Button.new()
  b.name="Level"+str(i+1)
  b.position=Vector2(324+i*228,249)
  b.size=Vector2(216,355)
  b.clip_contents=true
  b.disabled=not unlocked
  b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
  canvas.add_child(b)
  cards.append(b)
  var picture=TextureRect.new()
  picture.position=Vector2(3,3)
  picture.size=Vector2(210,349)
  picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
  picture.texture=load("res://UI/LevelPreviews/level"+str(1 if i==0 else 2)+".png")
  if not unlocked:picture.modulate=Color(.18,.20,.24,1)
  b.add_child(picture)
  var fade=TextureRect.new()
  fade.position=picture.position;fade.size=picture.size;fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var gradient=Gradient.new()
  gradient.offsets=PackedFloat32Array([0,.42,.82,1])
  gradient.colors=PackedColorArray([Color(0,0,0,.04),Color(0,0,0,.08),Color(.025,.035,.045,.94),Color(.025,.035,.045,1)])
  var texture=GradientTexture2D.new();texture.gradient=gradient;texture.fill_from=Vector2(0,0);texture.fill_to=Vector2(0,1)
  fade.texture=texture;b.add_child(fade)
  label_at("LEVEL "+str(i+1),Vector2(20,249),34,Color.WHITE if unlocked else MUTED,title_font,b)
  label_at(subtitles[i],Vector2(21,295),15,Color("c0c5cd") if unlocked else MUTED,null,b)
  if unlocked:_add_best_result(b,i+1)
  if not unlocked:
   var icon=LockIcon.new();icon.position=Vector2(84,130);icon.size=Vector2(48,64);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(icon)
   b.tooltip_text="Complete Level 1 to unlock" if i==1 else "Coming soon"
  else:
   b.pressed.connect(_start_level.bind(i))
   b.focus_entered.connect(_select_level.bind(i))
 _select_level(0)
 cards[0].grab_focus()
 resized.connect(_resize)
 _resize()
 _build_settings()

## Best result on a level card: filled gold coins + best score (saved by the score screen)
func _add_best_result(card: Button, level: int) -> void:
 var row=MedalRow.new();row.medals=Progress.get_best_medals(level)
 row.position=Vector2(20,322);row.size=Vector2(80,22);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row)
 var best=Progress.get_best_score(level)
 if best<=0:return
 var best_label=label_at("BEST "+str(best),Vector2(96,322),13,GOLD,null,card)
 best_label.size=Vector2(100,20);best_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT

func _resize() -> void:
 if not canvas:return
 var factor=minf(size.x/1280.0,size.y/720.0)
 canvas.scale=Vector2.ONE*factor
 canvas.position=(size-Vector2(1280,720)*factor)*.5

func _select_level(index: int) -> void:
 if index<0 or not Progress.is_level_unlocked(index+1):return
 selected_level=index
 for i in range(cards.size()):
  var style=panel(Color("0c1118"),GOLD if i==index else Color("3a4048"),3 if i==index else 2)
  if i==index:style.shadow_color=Color(.94,.72,.25,.2);style.shadow_size=10
  cards[i].add_theme_stylebox_override("normal",style)
  cards[i].add_theme_stylebox_override("disabled",style)
  cards[i].add_theme_stylebox_override("hover",panel(Color("0c1118"),GOLD,3))
  cards[i].add_theme_stylebox_override("focus",panel(Color.TRANSPARENT,GOLD,3))

func _unhandled_key_input(event: InputEvent) -> void:
 if settings.visible:return
 if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
  var next_level = 1-selected_level
  if Progress.is_level_unlocked(next_level+1): cards[next_level].grab_focus()
  get_viewport().set_input_as_handled()

func _start_level(index: int) -> void:
 if _starting_level or index < 0 or index > 1 or not Progress.is_level_unlocked(index+1): return
 _starting_level = true
 _select_level(index)
 for card in cards: card.disabled = true
 var error = get_tree().change_scene_to_file(first_level if index==0 else second_level)
 if error != OK:
  _starting_level = false
  for i in range(cards.size()): cards[i].disabled = not Progress.is_level_unlocked(i+1)
  push_error("Could not start level: " + error_string(error))

func _build_settings() -> void:
 settings=AcceptDialog.new();settings.title="SETTINGS";settings.min_size=Vector2i(360,160);add_child(settings)
 var box=VBoxContainer.new();settings.add_child(box)
 var heading=Label.new();heading.text="Master volume";box.add_child(heading)
 var volume=HSlider.new();volume.max_value=100;volume.value=AudioServer.get_bus_volume_linear(0)*100;box.add_child(volume)
 volume.value_changed.connect(func(value):AudioServer.set_bus_volume_linear(0,value/100.0))
 var fullscreen=CheckButton.new();fullscreen.text="Fullscreen";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;box.add_child(fullscreen)
 fullscreen.toggled.connect(func(enabled):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))

func _on_settings() -> void:settings.popup_centered()
func _on_credits() -> void:get_tree().change_scene_to_file(credits)
func _on_quit() -> void:get_tree().quit()
