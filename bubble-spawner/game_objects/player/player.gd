class_name Player
extends CharacterBody2D

@export var speed := 200.0
@export var jump_velocity := -400.0
@export var projectile_scene: PackedScene

var gravity := 980.0
var can_shoot := true

@onready var shoot_point: Marker2D = $ShootPoint
@onready var invuln_timer: Timer = $InvulnerableTimer
@onready var color_rect: ColorRect = $ColorRect
@onready var hurt_box: Area2D = $HurtBox

signal died

var input_enabled := true
@export var color_on := false:
	set(value):
		color_on = value
		if is_node_ready():
			refresh_color()

var white_color := Color(1, 1, 1, 1);
var hit_color := Color(1, 0.3, 0.3, 0.25)
var base_color := Color(0.278, 0.596, 0.294, 1.0)

@export var pop_intro := false:
	set(value):
		pop_intro = value
		if value:
			color_rect.scale = Vector2.ZERO
		else:
			color_rect.scale = Vector2.ONE
		
@export var pop_intro_duration := 0.25
@export var player_stretch = false

@export var proj_wobble := false:
	set(value):
		proj_wobble = value

func _ready() -> void:
	invuln_timer.timeout.connect(_on_invuln_end)
	hurt_box.body_entered.connect(_on_hurt)
	
	if pop_intro:
		color_rect.scale = Vector2.ZERO

func _on_hurt(body: Node2D) -> void:
	# Only react to balls (in case HurtBox ever overlaps something else)
	if body is Ball:
		take_hit()

var _last_dir := 0
func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	if input_enabled:
		# Horizontal input
		var dir := Input.get_axis("move_left", "move_right")
		velocity.x = dir * speed
		
		if sign(dir) != _last_dir and dir != 0:
			#tween_squeeze()
			tween_stretch()
		_last_dir = sign(dir)

		# Jump
		#if Input.is_action_just_pressed("jump") and is_on_floor():
			#velocity.y = jump_velocity

		# Shoot
		if Input.is_action_just_pressed("shoot") and can_shoot:
			shoot()
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		
	move_and_slide()

func shoot() -> void:
	if projectile_scene == null:
		return
	var proj:Projectile = projectile_scene.instantiate()
	proj.global_position = shoot_point.global_position
	proj.color_on = color_on
	proj.proj_wobble = proj_wobble
	refresh_color()
	get_tree().current_scene.add_child(proj)

func take_hit() -> void:
	if invuln_timer.time_left > 0:
		return
	invuln_timer.start()
	color_rect.modulate = get_hit_color()
	died.emit()  # GameManager listens and decrements lives

func get_hit_color() -> Color:
	return hit_color if color_on else white_color

func _on_invuln_end() -> void:
	color_rect.modulate = get_base_color()

func get_base_color() -> Color:
	return base_color if color_on else white_color

func is_invulnerable() -> bool:
	return invuln_timer.time_left > 0

func refresh_color() -> void:
	# While invulnerable, keep the hit flash; otherwise show base color
	if is_invulnerable():
		color_rect.modulate = get_hit_color()
	else:
		color_rect.modulate = get_base_color()


func play_pop_intro(delay: float):
	if pop_intro:
		color_rect.scale = Vector2.ZERO
		_play_pop_intro(delay)


func _play_pop_intro(delay: float) -> void:
	var cr := color_rect
	cr.pivot_offset = cr.size * 0.5   # scale from center
	cr.scale = Vector2.ZERO
	input_enabled = false

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cr, "scale", Vector2.ONE, pop_intro_duration).set_delay(delay)
	tw.finished.connect(func() -> void:
		# Only re-enable if the game state actually wants input
		# (Main will overwrite this anyway via _set_player_input)
		pass
	)

func tween_squeeze() -> void:
	if not player_stretch:
		return
		
	var cr := color_rect

	# Pivot at the visual's center so the squash reads symmetrically
	cr.pivot_offset = cr.size * 0.5

	# Direction-aware squash: wide + short when moving horizontally
	var squash := Vector2(1.25, 0.75)

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Squash in
	tw.tween_property(cr, "scale", squash, 0.08)
	# Snap back to normal
	tw.tween_property(cr, "scale", Vector2.ONE, 0.12)

func tween_stretch() -> void:
	if not player_stretch:
		return
		
	var cr := color_rect
	cr.pivot_offset = cr.size * 0.5
	var dir = sign(velocity.x)
	var stretch := Vector2(1.0 + 0.5 * abs(dir), 1.0 - 0.1 * abs(dir))
	
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(cr, "scale", stretch, 0.08 * 5)
	tw.tween_property(cr, "scale", Vector2.ONE, 0.12 * 2)
