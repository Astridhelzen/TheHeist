extends Control
## Visar mål, instruktioner, mynt och tid. Nås via gruppen hud.

## Instruktioner som visas vid banstart.
@export var intro_messages: Array[String] = [
 "Hold Ctrl to sneak",
 "Hold Shift to run"
]
## Starta tiden direkt, eller låt introt starta den.
@export var timer_starts_on_ready := true
## Visa hundradelar i tiden.
@export var show_hundredths := true
## Visningstid per meddelande i sekunder.
@export var notice_time := 4.0
@export_group("Fonts")
## Typsnitt för mål och instruktioner.
@export var font: Font
## Typsnitt för små etiketter.
@export var small_font: Font

const BG := Color(0.035, 0.04, 0.05, 0.88)
const EDGE := Color("262b32")
const ACCENT := Color("e5b04a")
const TEXT := Color("e8ecef")
const MUTED := Color("7d848c")

var has_card := false
var unlocked := false
var prompt := ""
var notice := ""
var objective := "Find the access card"
var _queue: Array[String] = []
var _notice_left := 0.0
## Myntantal för HUD och resultatskärm.
var coins_collected := 0
var coins_total := 0
var _coin_pop := 0.0
## Speltid i sekunder. Stannar vid paus.
var elapsed_time := 0.0
var timer_running := false

func _ready() -> void:
 add_to_group("hud")
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
 _queue.append_array(intro_messages)
 # Räkna mynten när alla noder är redo.
 _count_coins.call_deferred()
 timer_running = timer_starts_on_ready
 # Stoppa tiden vid flykt.
 _connect_exits.call_deferred()

func _process(delta: float) -> void:
 _notice_left -= delta
 _coin_pop = maxf(_coin_pop - delta * 4.0, 0.0)
 if timer_running:
  elapsed_time += delta
 if _notice_left <= 0.0:
  if _queue.is_empty():
   notice = ""
  else:
   notice = _queue.pop_front()
   _notice_left = notice_time
 queue_redraw()

## Visa direkt, före köade meddelanden.
func notify(message: String) -> void:
 notice = message
 _notice_left = notice_time

## Uppdatera målet.
func set_objective(text: String) -> void:
 objective = text

## Anropas när ett mynt plockas upp.
func add_coin() -> void:
 coins_collected += 1
 _coin_pop = 1.0

func _count_coins() -> void:
 coins_total = coins_collected + get_tree().get_nodes_in_group("coins").size()

func start_timer() -> void:
 timer_running = true

func stop_timer() -> void:
 timer_running = false

func _connect_exits() -> void:
 for door in get_tree().get_nodes_in_group("exits"):
  door.escaped.connect(stop_timer)

## Formatera sekunder som minuter, sekunder och valfria hundradelar.
@warning_ignore("integer_division")
static func format_time(seconds: float, with_hundredths := true) -> String:
 var hundredths := int(seconds * 100.0)
 var minutes := hundredths / 6000
 var secs := (hundredths / 100) % 60
 if not with_hundredths:
  return "%02d:%02d" % [minutes, secs]
 return "%02d:%02d:%02d" % [minutes, secs, hundredths % 100]

func _draw() -> void:
 var s := minf(size.x / 1280.0, size.y / 720.0)
 draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * s)
 var width := size.x / s
 var height := size.y / s
 _draw_objective(width)
 _draw_timer()
 if coins_total > 0:
  _draw_coins(width)
 if not notice.is_empty():
  _draw_notice(width, height)
 if not prompt.is_empty():
  _draw_prompt(width, height)
 draw_set_transform(Vector2.ZERO)

# Layout
func _draw_objective(width: float) -> void:
 var rect := Rect2(width - 330, 26, 304, 76)
 _panel(rect)
 # Gul kantlinje.
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("OBJECTIVE", rect.position + Vector2(22, 26), 13, MUTED, _small(), 2.5)
 _draw_text(objective.to_upper(), rect.position + Vector2(22, 60), 26, TEXT, _big())
 # Kortikonen lyser när kortet är upplockat.
 var card := Rect2(rect.position + Vector2(rect.size.x - 44, 14), Vector2(26, 17))
 if has_card:
  draw_rect(card, ACCENT)
 else:
  draw_rect(card, MUTED, false, 1.5)

func _draw_timer() -> void:
 # Tidspanelen.
 var rect := Rect2(26, 26, 200, 76)
 _panel(rect)
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("TIME", rect.position + Vector2(22, 26), 13, MUTED, _small(), 2.5)
 _draw_text(format_time(elapsed_time, show_hundredths), rect.position + Vector2(22, 60), 28, MUTED, _big())

func _draw_coins(width: float) -> void:
 # Mynträknaren under målet.
 var rect := Rect2(width - 330, 112, 304, 46)
 _panel(rect)
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("COINS", rect.position + Vector2(22, 29), 13, MUTED, _small(), 2.5)
 # Förstora texten kort vid upplockning.
 var grow := 1.0 + 0.35 * _coin_pop
 var center := rect.position + Vector2(rect.size.x - 40, rect.size.y / 2)
 draw_circle(center, 9.0 * grow, ACCENT)
 draw_circle(center, 5.0 * grow, BG.lerp(ACCENT, 0.45))
 var text := "%d" % [coins_collected]
 var size_px := int(24 * grow)
 var text_width := _big().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
 var color := ACCENT if coins_collected == coins_total else TEXT
 _draw_text(text, Vector2(center.x - 22 - text_width, rect.position.y + 32 + (grow - 1.0) * 8), size_px, color, _big())

func _draw_notice(width: float, height: float) -> void:
 var text := notice.to_upper()
 var text_width := _big().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
 # Visa meddelanden ovanför eventuell interaktionstext.
 var y := height - 112 if prompt.is_empty() else height - 176
 var rect := Rect2(width / 2 - (text_width + 64) / 2, y, text_width + 64, 52)
 _panel(rect)
 _triangle(rect.position + Vector2(20, 20))
 _draw_text(text, rect.position + Vector2(42, 35), 24, TEXT, _big())

func _draw_prompt(width: float, height: float) -> void:
 # Markera interaktionstangenten i gult.
 var key := ""
 var rest := prompt
 if prompt.begins_with("[") and prompt.contains("]"):
  var end := prompt.find("]") + 1
  key = prompt.substr(0, end)
  rest = prompt.substr(end).strip_edges()
 rest = rest.to_upper()
 var gap := 14.0 if not key.is_empty() else 0.0
 var key_width := _big().get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
 var rest_width := _big().get_string_size(rest, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
 var total := key_width + gap + rest_width
 var rect := Rect2(width / 2 - (total + 48) / 2, height - 112, total + 48, 54)
 _panel(rect)
 var x := rect.position.x + 24
 if not key.is_empty():
  _draw_text(key, Vector2(x, rect.position.y + 36), 24, ACCENT, _big())
 _draw_text(rest, Vector2(x + key_width + gap, rect.position.y + 36), 24, TEXT, _big())

# Hjälpfunktioner
func _panel(rect: Rect2) -> void:
 # Panel i samma stil som menyn.
 draw_rect(rect, BG)
 draw_rect(rect, EDGE, false, 1.0)

func _triangle(at: Vector2) -> void:
 # Gul pil som i menyn.
 draw_colored_polygon(PackedVector2Array([at, at + Vector2(0, 12), at + Vector2(10, 6)]), ACCENT)

func _draw_text(value: String, at: Vector2, font_size: int, color: Color, with_font: Font) -> void:
 draw_string(with_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## Rita text med extra bokstavsavstånd i pixlar.
func _draw_spaced(value: String, at: Vector2, font_size: int, color: Color, with_font: Font, spacing: float) -> void:
 var x := at.x
 for letter in value:
  draw_string(with_font, Vector2(x, at.y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
  x += with_font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + spacing

func _big() -> Font:
 return font if font else ThemeDB.fallback_font

func _small() -> Font:
 return small_font if small_font else ThemeDB.fallback_font
