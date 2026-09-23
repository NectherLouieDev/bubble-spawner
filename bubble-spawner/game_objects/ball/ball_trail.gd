class_name BallTrail
extends Line2D

@export var max_points := 12
@export var min_distance := 3.0   # only push a point if moved this far

var _last_point := Vector2.INF

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO   # points are absolute; node pos doesn't matter
	points = PackedVector2Array()
	
	if not gradient:
		var g := Gradient.new()
		g.set_color(0, Color(0.2, 0.8, 1.0, 0.9))
		g.set_color(1, Color(0.2, 0.8, 1.0, 0.0))
		gradient = g

func _physics_process(_delta: float) -> void:
	var target = get_parent().global_position

	# Avoid pushing duplicate points (spams the buffer when the ball is slow)
	if _last_point != Vector2.INF and target.distance_to(_last_point) < min_distance:
		return

	_last_point = target
	# Insert at the front so point[0] = newest
	add_point(target, 0)

	# Trim the tail
	while points.size() > max_points:
		remove_point(points.size() - 1)
