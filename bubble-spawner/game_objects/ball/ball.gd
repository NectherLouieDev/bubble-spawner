class_name Ball
extends CharacterBody2D

@export var size := 40.0            # radius
@export var min_size := 10.0
@export var speed := 150.0
@export var color := Color(0.2, 0.8, 1.0)

signal popped(body: Ball)

var frozen:= false

# --- color toggle (mirrors Player's pattern) ---
@export var color_on := false:
	set(value):
		color_on = value
		if is_node_ready():
			refresh_color()


# --- pop intro ---
@export var pop_intro := false
@export var pop_intro_duration := 0.25

var white_color := Color(1, 1, 1, 1)
var base_color := Color(0.2, 0.8, 1.0)

func _ready() -> void:
	$CollisionShape2D.shape.radius = size
	velocity = Vector2(
		[ -1, 1 ].pick_random(),
		[ -1, 1 ].pick_random()
	).normalized() * speed
	
	refresh_color()


func play_pop_intro(delay: float):
	if pop_intro:
		_play_pop_intro(delay)


func _play_pop_intro(delay: float) -> void:
	# Start tiny and grow to full size; freeze physics while playing.
	scale = Vector2.ZERO
	var was_frozen := frozen
	frozen = true

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, pop_intro_duration).set_delay(delay)

	tw.finished.connect(func() -> void:
		frozen = was_frozen
	)


func set_frozen(value: bool) -> void:
	frozen = value
	if frozen:
		velocity = Vector2.ZERO
	else:
		# Give it a fresh random direction when unfrozen
		velocity = Vector2(
			[ -1, 1 ].pick_random(),
			[ -1, 1 ].pick_random()
		).normalized() * speed

func _physics_process(delta: float) -> void:
	if frozen: 
		return
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, size, get_base_color())

func pop() -> void:
	popped.emit(self)
	queue_free()

func check_size() -> bool:
	return size > min_size + 5

func spawn_child() -> Ball:
	var new_size := size * 0.6
	var current_velocity := velocity
	var spawn_pos := position
	var spawner := get_tree().current_scene.get_node("BallSpawner")
	
	var child: Ball = spawner.spawn_ball_at(spawn_pos, new_size)
	var random_radians = deg_to_rad(randi_range(-45, 45))
	child.velocity = current_velocity.rotated(random_radians)
	child.color_on = color_on
	
	return child

func refresh_color() -> void:
	queue_redraw()

func get_base_color() -> Color:
	return base_color if color_on else white_color
