class_name DebugPanel
extends PanelContainer

## Emitted whenever a toggle changes.
## toggle_name: a stable string key (e.g. "player_color")
## value:       the new boolean state
signal toggle_changed(toggle_name: String, value: bool)

@onready var color_toggle: CheckButton = $VBoxContainer/ColorToggle

func _ready() -> void:
	# Wire each toggle here. Add more lines as you add CheckButtons.
	color_toggle.toggled.connect(_on_color_toggled)

func _on_color_toggled(pressed: bool) -> void:
	toggle_changed.emit("debug_colors", pressed)
