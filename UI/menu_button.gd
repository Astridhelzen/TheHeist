extends Button

const SIZE_SELECTED := 40
const SIZE_NORMAL := 30

@onready var arrow: Label = $Arrow

func _ready() -> void:
	arrow.visible = false
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(grab_focus)

func _on_focus_entered() -> void:
	arrow.visible = true
	add_theme_font_size_override("font_size", SIZE_SELECTED)

func _on_focus_exited() -> void:
	arrow.visible = false
	add_theme_font_size_override("font_size", SIZE_NORMAL)
