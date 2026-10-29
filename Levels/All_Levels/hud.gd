extends Control
## The game's HUD. One HUD for all on-screen instructions:
## - the current objective (top right)
## - short messages, e.g. the intro tips (bottom centre)
## - interaction prompts like "[E] Pick up access card" (bottom centre)
## - the coin counter (under the objective)
## - the level timer (top left)
## Other scripts find it through the group "hud", e.g.:
##     get_tree().call_group("hud", "set_objective", "Get to the exit")
## The style matches the main menu: dark flat panels, amber accents,
## a condensed heading font and a small spaced-out monospace label.

## Shown one after another when the level starts.
@export var intro_messages: Array[String] = [
 "Hold Ctrl to sneak",
 "Hold Shift to run"
]
## Start the timer as soon as the level loads. Turn off if something else
## (e.g. an intro) should start it with start_timer().
@export var timer_starts_on_ready := true
## On: "01:23:45". Off: "01:23".
@export var show_hundredths := true
## How long each message is shown (seconds).
@export var notice_time := 4.0
@export_group("Fonts")
## Big text (objective, messages, prompts). Use the menu's button/title font.
@export var font: Font
## Small label ("O B J E C T I V E"). Use the menu's monospace font ("Stay in the dark.").
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
## Coins in this level. Read by e.g. the score screen.
var coins_collected := 0
var coins_total := 0
var _coin_pop := 0.0
## Seconds played in this level. Read by e.g. the score screen.
## Stops by itself while the game is paused.
var elapsed_time := 0.0
var timer_running := false

func _ready() -> void:
 add_to_group("hud")
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
 _queue.append_array(intro_messages)
 # Count the coins once every node in the level has run _ready
 _count_coins.call_deferred()
 timer_running = timer_starts_on_ready
 # Stop the clock the moment the player escapes
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

## Shows a message right away. Messages waiting in line are shown afterwards.
func notify(message: String) -> void:
 notice = message
 _notice_left = notice_time

## Changes the objective in the top right corner.
func set_objective(text: String) -> void:
 objective = text

## Called by coin.gd when the player takes a coin.
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

## 83.456 seconds -> "01:23:45", or "01:23" with with_hundredths = false
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

# --------------------
# PARTS
# --------------------
func _draw_objective(width: float) -> void:
 var rect := Rect2(width - 330, 26, 304, 76)
 _panel(rect)
 # Amber line on the left, like an accent in the menu
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("OBJECTIVE", rect.position + Vector2(22, 26), 13, MUTED, _small(), 2.5)
 _draw_text(objective.to_upper(), rect.position + Vector2(22, 60), 26, TEXT, _big())
 # Small access card icon: amber when you have the card
 var card := Rect2(rect.position + Vector2(rect.size.x - 44, 14), Vector2(26, 17))
 if has_card:
  draw_rect(card, ACCENT)
 else:
  draw_rect(card, MUTED, false, 1.5)

func _draw_timer() -> void:
 # Same kind of box as the objective, but in the top left corner
 var rect := Rect2(26, 26, 200, 76)
 _panel(rect)
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("TIME", rect.position + Vector2(22, 26), 13, MUTED, _small(), 2.5)
 # "01:23:45", all in the same grey and size
 _draw_text(format_time(elapsed_time, show_hundredths), rect.position + Vector2(22, 60), 28, MUTED, _big())

func _draw_coins(width: float) -> void:
 # Small box under the objective: a coin icon and "3 / 10"
 var rect := Rect2(width - 330, 112, 304, 46)
 _panel(rect)
 draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), ACCENT)
 _draw_spaced("COINS", rect.position + Vector2(22, 29), 13, MUTED, _small(), 2.5)
 # The text grows a little for a moment when a coin is taken
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
 # Same height on screen as the objective box (centred next to it)
 # Bottom centre. If an [E] prompt is showing, the message sits just above it.
 var y := height - 112 if prompt.is_empty() else height - 176
 var rect := Rect2(width / 2 - (text_width + 64) / 2, y, text_width + 64, 52)
 _panel(rect)
 _triangle(rect.position + Vector2(20, 20))
 _draw_text(text, rect.position + Vector2(42, 35), 24, TEXT, _big())

func _draw_prompt(width: float, height: float) -> void:
 # "[E]  Pick up access card": the key in amber, the rest in white
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

# --------------------
# HELPERS
# --------------------
func _panel(rect: Rect2) -> void:
 # Flat, square panel like the menu (no rounded corners)
 draw_rect(rect, BG)
 draw_rect(rect, EDGE, false, 1.0)

func _triangle(at: Vector2) -> void:
 # The same small amber arrow as in front of the menu buttons
 draw_colored_polygon(PackedVector2Array([at, at + Vector2(0, 12), at + Vector2(10, 6)]), ACCENT)

func _draw_text(value: String, at: Vector2, font_size: int, color: Color, with_font: Font) -> void:
 draw_string(with_font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## Draws text with a little extra space between the letters,
## like "A STEALTH GAME" in the menu. spacing = extra pixels per letter.
func _draw_spaced(value: String, at: Vector2, font_size: int, color: Color, with_font: Font, spacing: float) -> void:
 var x := at.x
 for letter in value:
  draw_string(with_font, Vector2(x, at.y), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
  x += with_font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + spacing

func _big() -> Font:
 return font if font else ThemeDB.fallback_font

func _small() -> Font:
 return small_font if small_font else ThemeDB.fallback_font
