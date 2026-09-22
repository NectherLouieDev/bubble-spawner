class_name ColorToggle
extends Node

## Attach as a child of any node that implements `apply_color(c: Color)`.
## The parent is responsible for interpreting the color (ColorRect, _draw, etc.).

signal toggled(value: bool)

@export var color_on := false:
	set(value):
		color_on = value
		if is_node_ready():
			_apply()

@export var base_color := Color.WHITE
@export var alt_color := Color(1, 0.3, 0.3, 0.25)

func _ready() -> void:
	_apply()

func _apply() -> void:
	var c := alt_color if color_on else base_color
	var parent := get_parent()
	if parent.has_method("apply_color"):
		parent.apply_color(c)
	else:
		push_warning("%s has no apply_color() method" % parent.name)
	toggled.emit(color_on)
