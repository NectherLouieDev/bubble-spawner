class_name Ball
extends CharacterBody2D

@export var size := 40.0            # radius
@export var min_size := 10.0
@export var speed := 150.0
@export var color := Color(0.2, 0.8, 1.0)

signal popped(body: Ball)

var frozen := false

# --- color toggle (mirrors Player's pattern) ---
@export var color_on := false:
	set(value):
		color_on = value
		#if is_node_ready():
		refresh_color()

# --- pop intro ---
@export var pop_intro := false
@export var pop_intro_duration := 0.25

# --- directional stretch ---
@export var ball_stretch := false
@export var stretch_amount := 1.1
@export var squash_amount := 0.65
@export var stretch_duration := 0.1
@export var rotate_duration := 0.01

# --- collision wobble ---
@export var collision_wobble := true
@export var wobble_amount := 1.15
@export var wobble_duration := 0.06

# --- child speed scaling ---
@export var child_speed_multiplier := 1.5
@export var max_speed := 600.0

# --- colors ---
var white_color := Color(1, 1, 1, 1)
var base_color := Color(0.8, 0.2, 0.2, 1.0)

@onready var visual: BallVisual = $Visual
@onready var trail: BallTrail = $BallTrail

var _scale_tween: Tween        # owns visual.scale exclusively
var _wobbling := false         # true while a collision wobble is playing

@export var proj_trail := false
 
func _ready() -> void:
	$CollisionShape2D.shape.radius = size
	visual.set_radius(size)
	visual.set_color(get_base_color())

	velocity = Vector2(
		[ -1, 1 ].pick_random(),
		[ -1, 1 ].pick_random()
	).normalized() * speed

# --- pop intro ---

func play_pop_intro(delay: float = 0.0) -> void:
	if pop_intro:
		_play_pop_intro(delay)

func _play_pop_intro(delay: float) -> void:
	visual.scale = Vector2.ZERO
	var was_frozen := frozen
	frozen = true

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(visual, "scale", Vector2.ONE, pop_intro_duration).set_delay(delay)

	tw.finished.connect(func() -> void:
		frozen = was_frozen
	)

# --- frozen state ---

func set_frozen(value: bool) -> void:
	frozen = value
	if frozen:
		velocity = Vector2.ZERO
	else:
		velocity = Vector2(
			[ -1, 1 ].pick_random(),
			[ -1, 1 ].pick_random()
		).normalized() * speed

# --- physics ---

func _physics_process(delta: float) -> void:
	if frozen:
		return

	trail.visible = proj_trail
	
	# 1. Rotate the visual to face the direction of travel (continuous).
	_face_velocity_direction(delta)

	# 2. Move and handle collision.
	var collision := move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		if collision_wobble:
			_kick_collision_wobble()
		# Re-face after bounce, since velocity flipped.
		_face_velocity_direction(delta)

# --- direction handling ---

func _face_velocity_direction(delta: float) -> void:
	if not ball_stretch:
		return
	
	if velocity.length_squared() < 0.01:
		return

	var target_angle := velocity.angle()

	# Pick the shortest angular path to avoid 359°→1° spins.
	var current := visual.rotation
	var diff := wrapf(target_angle - current, -PI, PI)

	# Smoothly rotate toward the target.
	var step = diff * min(delta / rotate_duration, 1.0)
	visual.rotation = current + step

	# Apply directional stretch on top of rotation (only when not wobbling).
	if ball_stretch and not _wobbling:
		var target_scale := Vector2(stretch_amount, squash_amount)
		# Only re-tween when the scale is meaningfully different.
		if visual.scale.distance_to(target_scale) > 0.01:
			_tween_scale(target_scale, stretch_duration)

func _tween_scale(target: Vector2, duration: float) -> void:
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(visual, "scale", target, duration)

# --- collision wobble ---

func _kick_collision_wobble() -> void:
	if not ball_stretch:
		return
		
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()

	_wobbling = true
	# Preserve current rotation; wobble only affects scale.
	# "Opposing" scale pulse: x goes up, y goes down, then swaps, then settles.
	var up := Vector2(wobble_amount, 2.0 - wobble_amount)   # e.g. (1.15, 0.85)
	var down := Vector2(2.0 - wobble_amount, wobble_amount) # e.g. (0.85, 1.15)

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_scale_tween.tween_property(visual, "scale", up, wobble_duration)
	_scale_tween.tween_property(visual, "scale", down, wobble_duration)
	_scale_tween.tween_property(visual, "scale", Vector2.ONE, wobble_duration)
	_scale_tween.finished.connect(func() -> void:
		_wobbling = false
	)

# --- pop / split ---

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
	child.trail.width = new_size * 1.25

	var new_speed = min(speed * child_speed_multiplier, max_speed)
	child.speed = new_speed

	var random_radians = deg_to_rad(randi_range(-45, 45))
	child.velocity = current_velocity.rotated(random_radians).normalized() * new_speed

	# Inherit toggles
	child.color_on = color_on
	child.ball_stretch = ball_stretch
	child.pop_intro = pop_intro
	child.proj_trail = proj_trail

	return child

# --- color ---

func refresh_color() -> void:
	visual.set_color(get_base_color())

func get_base_color() -> Color:
	return base_color if color_on else white_color
