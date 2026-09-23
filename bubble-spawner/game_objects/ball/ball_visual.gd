class_name BallVisual
extends Node2D

var radius := 40.0
var color := Color(0.2, 0.8, 1.0, 0.25)

func set_radius(r: float) -> void:
	radius = r
	queue_redraw()

func set_color(c: Color) -> void:
	color = c
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
