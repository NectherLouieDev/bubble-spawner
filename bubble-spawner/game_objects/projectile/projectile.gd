class_name Projectile
extends Area2D

@export var speed := 600.0
@export var lifetime := 2.0

@onready var destroy_timer: Timer = $DestroyTimer
@onready var color_rect: ColorRect = $ColorRect

# --- color toggle ---
@export var color_on := false:
	set(value):
		color_on = value
		if is_node_ready():
			refresh_color()

var white_color := Color(1, 1, 1, 1)
var base_color := Color(1, 0.9, 0.3, 1.0)   # yellow

@export var proj_wobble := false
@export var proj_trail := false

var _stretch_tween: Tween
var _wobble_tween: Tween

func _ready() -> void:
	destroy_timer.wait_time = lifetime
	destroy_timer.one_shot = true
	destroy_timer.timeout.connect(on_destroy_timer_complete)
	destroy_timer.start()

	body_entered.connect(_on_body_entered)
	refresh_color()

	if proj_wobble:
		tween_stretch()

func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		body.call_deferred("pop")
		queue_free()

func _physics_process(delta: float) -> void:
	position.y -= speed * delta

func on_destroy_timer_complete() -> void:
	queue_free()

# --- color toggle ---
func refresh_color() -> void:
	color_rect.modulate = get_base_color()

func get_base_color() -> Color:
	return base_color if color_on else white_color

# --- tweens ---

func tween_stretch() -> void:
	if _stretch_tween and _stretch_tween.is_valid():
		_stretch_tween.kill()

	var cr := color_rect
	cr.pivot_offset = cr.size * 0.5

	_stretch_tween = create_tween().set_loops()
	_stretch_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_stretch_tween.tween_property(cr, "scale", Vector2(0.25, 2.5), 0.15)
	_stretch_tween.tween_property(cr, "scale", Vector2(1.0, 1.0), 0.15)

func tween_wobble() -> void:
	if _wobble_tween and _wobble_tween.is_valid():
		_wobble_tween.kill()

	var cr := color_rect
	cr.pivot_offset = cr.size * 0.5

	_wobble_tween = create_tween().set_loops()
	_wobble_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_wobble_tween.tween_property(cr, "rotation", deg_to_rad(6.0), 0.2)
	_wobble_tween.tween_property(cr, "rotation", deg_to_rad(-6.0), 0.4)
	_wobble_tween.tween_property(cr, "rotation", 0.0, 0.2)
