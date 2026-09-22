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

func _ready() -> void:
	destroy_timer.timeout.connect(on_destroy_timer_complete)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	body_entered.connect(_on_body_entered)
	refresh_color()

func _on_body_entered(body: Node2D) -> void:
	if body is Ball:
		body.call_deferred("pop")
		queue_free()
		
func _physics_process(delta: float) -> void:
	position.y -= speed * delta  # travel straight up

func on_destroy_timer_complete() -> void:
	queue_free()

# --- color toggle ---
func refresh_color() -> void:
	color_rect.modulate = get_base_color()

func get_base_color() -> Color:
	return base_color if color_on else white_color
