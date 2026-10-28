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

@export_file("*.tscn") var first_level: String = "res://Levels/Level_1/Level_1.tscn"
@export_file("*.tscn") var second_level: String = "res://Level2.tscn"
@export_file("*.tscn") var credits: String = "res://UI/credits.tscn"
const Progress = preload("res://Managers/level_progress.gd")
const GOLD = Color("efc260")
const MUTED = Color("87909f")
var selected_level := 0
var canvas: Control
var cards: Array[Button] = []
var new_heist: Button
var settings: AcceptDialog
var title_font = preload("res://UI/Fonts/title.tres")
var menu_font = preload("res://UI/Fonts/menu.tres")

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
 label_at("A  S T E A L T H  G A M E", Vector2(76,65), 15, MUTED)
 label_at("THE HEIST", Vector2(72,86), 108, Color("eef0f3"), title_font)
 label_at("Stay in the dark.", Vector2(78,211), 20, MUTED)
 var titles = ["START HEIST", "SETTINGS", "CREDITS", "QUIT"]
 for i in range(4):
  var b = Button.new()
  b.name = titles[i].replace(" ", "")
  b.text = titles[i]
  b.position = Vector2(48,296+i*53)
  b.size = Vector2(240,47)
  b.alignment = HORIZONTAL_ALIGNMENT_LEFT
  b.add_theme_font_override("font",menu_font)
  b.add_theme_font_size_override("font_size",29)
  b.add_theme_color_override("font_color", Color("11171c") if i==0 else MUTED)
  b.add_theme_color_override("font_hover_color", Color.WHITE if i>0 else Color("11171c"))
  b.add_theme_color_override("font_focus_color", Color.WHITE if i>0 else Color("11171c"))
  var normal=panel(GOLD if i==0 else Color.TRANSPARENT,Color.TRANSPARENT,0)
  normal.content_margin_left=20
  b.add_theme_stylebox_override("normal",normal)
  b.add_theme_stylebox_override("hover",panel(Color("f9d58a") if i==0 else Color("161e27"),GOLD,1))
  b.add_theme_stylebox_override("focus",panel(Color.TRANSPARENT,GOLD,2))
  canvas.add_child(b)
  if i==0:new_heist=b;b.pressed.connect(_on_new_heist)
  elif i==1:b.pressed.connect(_on_settings)
  elif i==2:b.pressed.connect(_on_credits)
  else:b.pressed.connect(_on_quit)
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
  if not unlocked:
   var icon=LockIcon.new();icon.position=Vector2(84,130);icon.size=Vector2(48,64);icon.mouse_filter=Control.MOUSE_FILTER_IGNORE;b.add_child(icon)
   b.tooltip_text="Complete Level 1 to unlock" if i==1 else "Coming soon"
  else:
   b.pressed.connect(_select_level.bind(i))
   b.focus_entered.connect(_select_level.bind(i))
 _select_level(0)
 new_heist.grab_focus()
 resized.connect(_resize)
 _resize()
 _build_settings()

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
  _select_level(1-selected_level)
  get_viewport().set_input_as_handled()

func _on_new_heist() -> void:
 if not Progress.is_level_unlocked(selected_level+1):return
 new_heist.disabled=true
 get_tree().change_scene_to_file(first_level if selected_level==0 else second_level)

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
