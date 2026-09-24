class_name Main
extends Node2D

# --- Spawn configuration ---
# Each entry: { "position": Vector2, "size": float }
const BALL_SPAWNS: Array[Dictionary] = [
	{ "marker": "BallSpawnPoint1", "size": 40.0 },
	{ "marker": "BallSpawnPoint2", "size": 40.0 },
	{ "marker": "BallSpawnPoint3", "size": 40.0 },
]

@onready var player: Player = $Player
@onready var balls: Array[Ball] = []

@onready var spawner: BallSpawner = $BallSpawner
@onready var spawn_points: Node2D = $SpawnPoints
@onready var lives_label: Label = $CanvasHUD/ScoreHUD/LivesLabel
@onready var score_label: Label = $CanvasHUD/ScoreHUD/ScoreLabel
@onready var start_prompt: CenterContainer = $CanvasHUD/StartContainer
@onready var start_timer: Timer = $StartTimer
@onready var start_time_label: Label = $CanvasHUD/OverlayContainer/StartTimeLabel

@onready var debug_panel: DebugPanel = $CanvasHUD/DebugPanel
@onready var debug_menu: DebugMenu = $CanvasHUD/DebugMenu

@export var color_on = false
@export var pop_intro_delay: bool = false
@export var count_pop: bool = false
@export var ball_stretch: bool = false

@export var proj_trail: bool = false
@export var hit_particles: bool = false
@export var ui_count: bool = false
@export var sfx_on: bool = false
@export var bgm_on: bool = false
@export var camera_shake: bool = false

func _ready() -> void:
	# Connect GameManager
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_over.connect(_on_game_over)

	# Connect player
	player.shoot_signal.connect(_on_player_shoot)
	player.died.connect(_on_player_died)
	
	# Timer connects
	start_timer.timeout.connect(on_start_timer_completed)
	
	# Connect debugs
	#debug_panel.toggle_changed.connect(_on_debug_toggle_changed)
	debug_menu.toggle_changed.connect(_on_debug_toggle_changed)

	# Initialize
	GameManager.reset()
	color_on = false
	_enter_spawn_in()

func _on_debug_toggle_changed(toggle_name: String, value: bool) -> void:
	match toggle_name:
		"all_colors":
			player.color_on = value
			color_on = value
		"pop_intro":
			player.pop_intro = value
			for b in balls:
				b.pop_intro = value
		"pop_intro_delay":
			pop_intro_delay = value
		"count_pop":
			count_pop = value
		"player_stretch":
			player.player_stretch = value
		"ball_stretch":
			ball_stretch = value
		"proj_wobble":
			player.proj_wobble = value
		"proj_trail":
			proj_trail = value
		"hit_particles":
			hit_particles = value
		"ui_count":
			ui_count = value
		"sfx_on":
			sfx_on = value
		"bgm_on":
			bgm_on = value
		"camera_shake_on":
			camera_shake = value
		_:
			push_warning("Unknown debug toggle: %s" % toggle_name)


# --- State entry ---
const BGM_SOUND = preload("res://audio/bgm.mp3")
func _enter_spawn_in() -> void:
	_clear_all()
	#_spawn_all()
	_freeze_physics(true)
	_set_player_input(false)
	start_prompt.visible = true
	start_time_label.visible = false;

func _enter_start() -> void:
	start_prompt.visible = false
	start_time_label.visible = true;
	
	if bgm_on:
		var p := $Audio/AudioStreamPlayer2DBGM
		p.stream = BGM_SOUND
		p.volume_linear = 0.35
		p.play()
	
	_spawn_all()
	_freeze_physics(true)
	_set_player_input(false)
	
	start_timer.start()

var count = 3;
func on_start_timer_completed() -> void:
	count -= 1
	start_time_label.text = str(count)
	
	if count_pop: 
		start_time_label.pivot_offset = start_time_label.size * 0.5
		start_time_label.scale = Vector2.ZERO
		
		var tw := create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(start_time_label, "scale", Vector2.ONE, 0.25)
	
	if count <= 0:
		start_timer.stop()
		start_time_label.visible = false;
		_freeze_physics(false)
		_set_player_input(true)

func get_toggle_value(toggle_name: String) -> bool:
	return debug_menu.toggles_value[toggle_name] or false
	
# --- Input handling ---

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state == GameManager.State.SPAWN_IN:
		if event.is_action_pressed("jump"):  # Space
			GameManager.set_state(GameManager.State.START)

# --- Updates ---
#func _process(delta):
	#start_time_label.text = str(int(start_timer.time_left))
	
# --- Spawn helpers ---

func _clear_all() -> void:
	for child in spawner.get_children():
		child.queue_free()

func _spawn_all() -> void:
	# Player at its spawn point
	var player_spawn: Marker2D = spawn_points.get_node("PlayerSpawnPoint")
	player.global_position = player_spawn.global_position
	player.pop_intro = get_toggle_value("pop_intro")
	player.play_pop_intro(0 if pop_intro_delay else 0)
	player.velocity = Vector2.ZERO

	# Balls at configured markers
	for i in range(BALL_SPAWNS.size()):
		var entry = BALL_SPAWNS[i]
		var marker: Marker2D = spawn_points.get_node(entry["marker"])
		# Spawn a ball
		var ball = spawner.spawn_ball_at(marker.global_position, entry["size"])
		ball.color_on = color_on
		ball.ball_stretch = ball_stretch
		ball.proj_trail = proj_trail
		ball.sfx_on = sfx_on
		ball.popped.connect(on_ball_popped)
		balls.append(ball)
	
	for i in range(balls.size()):
		var ball = balls[i]
		ball.pop_intro = get_toggle_value("pop_intro")
		var delay = (i + 1) * 0.15
		ball.play_pop_intro(delay if pop_intro_delay else 0)
	
	print("before ", balls.size())

const HIT_SOUND = preload("res://audio/explosionCrunch_000.ogg")
func on_ball_popped(body: Ball) -> void:
	body.popped.disconnect(on_ball_popped)
	
	if sfx_on:
		var p := $Audio/AudioStreamPlayer2D3
		p.stream = HIT_SOUND
		p.volume_linear = 1
		p.play()
	
	shake_camera(1.5)
	spawn_hit_particles(body.global_position, Color.ORANGE_RED, 8)
	
	GameManager.add_score(floor(body.size * 10))
	
	var ballIndex := balls.find(body)
	if body.check_size():
		for i in 2:
			var ball_child = body.spawn_child()
			ball_child.popped.connect(on_ball_popped)
			ball_child.play_pop_intro(0)
			ball_child._kick_collision_wobble()
			balls.append(ball_child)
	
	balls.remove_at(ballIndex)
	print("after ", balls.size())
	

# --- State helpers ---

func _freeze_physics(frozen: bool) -> void:
	# Balls freeze by pausing their _physics_process
	for ball in spawner.get_children():
		if ball is Ball:
			ball.set_frozen(frozen)

func _set_player_input(enabled: bool) -> void:
	player.input_enabled = enabled
	if not enabled:
		player.velocity.x = 0

# --- Signal handlers ---

const SHOOT_SOUNDS := [
	preload("res://audio/laserSmall_000.ogg"),
	preload("res://audio/laserSmall_001.ogg"),
	preload("res://audio/laserSmall_002.ogg"),
	preload("res://audio/laserSmall_003.ogg")
]
const SPLODE_SOUND := preload("res://audio/impactPunch_medium_000.ogg")

func _on_player_shoot() -> void:
	if sfx_on:
		var p := $Audio/AudioStreamPlayer2D1
		p.stream = SHOOT_SOUNDS.pick_random()
		p.play()

func _on_player_died() -> void:
	
	if sfx_on:
		var p := $Audio/AudioStreamPlayer2D2
		p.stream = SPLODE_SOUND
		p.volume_db = 2.0
		p.play()
	
	shake_camera(5)
	spawn_hit_particles(player.global_position, Color.CADET_BLUE)
	if GameManager.state == GameManager.State.START:
		GameManager.lose_life()

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "Lives: %d" % new_lives


var _displayed_score := 0
var _score_tween: Tween
var _scale_tween: Tween

const SCALE_POP := 1.25     # how big while rolling
const SCALE_POP_TIME := 0.1 # time to reach pop size
const SCALE_SETTLE_TIME := 0.25

func _on_score_changed(new_score: int) -> void:
	if ui_count:
		count_up_score(new_score)
	else:
		_set_displayed_score(new_score)

func count_up_score(new_score: int) -> void:
	if new_score == _displayed_score:
		return
		
	# --- Count-up tween ---
	if _score_tween and _score_tween.is_valid():
		_score_tween.kill()

	var gap = abs(new_score - _displayed_score)
	var duration := clampf(gap / 200.0, 0.15, 0.6)

	_score_tween = create_tween()
	_score_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_score_tween.tween_method(_set_displayed_score, _displayed_score, new_score, duration)
	_score_tween.finished.connect(_on_score_tween_finished)

	# --- Scale pop tween ---
	# Pivot at center so it grows from the middle
	score_label.pivot_offset = score_label.size * 0.5

	# Cancel any settle-back that was queued
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Only scale UP if we're not already at full pop size.
	# If the label is mid-settle (currently < SCALE_POP), jump it back up.
	if score_label.scale.x < SCALE_POP:
		_scale_tween.tween_property(score_label, "scale", Vector2.ONE * SCALE_POP, SCALE_POP_TIME)

	# Hold at pop size while the count runs, then settle back.
	# We DON'T schedule the settle here — the count tween's `finished`
	# callback triggers it, so stacking counts extends the hold naturally.
	_scale_tween.tween_callback(_queue_settle_scale) \
		.set_delay(duration + 0.01)

func _set_displayed_score(value: int) -> void:
	_displayed_score = value
	score_label.text = "Score: %d" % _displayed_score

func _on_score_tween_finished() -> void:
	# Small grace period so a rapid follow-up pop can re-kick before settling.
	await get_tree().create_timer(0.05).timeout
	# If nothing new kicked in, settle back to 1.0.
	if _score_tween and _score_tween.is_running():
		return
	_settle_scale()

func _queue_settle_scale() -> void:
	# Wrapper so we can call it from a tween callback
	_settle_scale()

func _settle_scale() -> void:
	if _scale_tween and _scale_tween.is_valid():
		_scale_tween.kill()

	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(score_label, "scale", Vector2.ONE, SCALE_SETTLE_TIME)

func _on_state_changed(new_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.SPAWN_IN:
			_enter_spawn_in()
		GameManager.State.START:
			_enter_start()
		GameManager.State.GAME_OVER:
			pass  # handled by _on_game_over

func _on_game_over() -> void:
	get_tree().paused = true
	lives_label.text = "GAME OVER"
	start_prompt.visible = false

const HIT_PARTICLES := preload("res://game_objects/vfx/hit_particles.tscn")

func spawn_hit_particles(pos: Vector2, color: Color, amount: int = 12) -> void:
	if not hit_particles:
		return
	
	var hp := HIT_PARTICLES.instantiate()
	hp.configure(color, amount)
	hp.global_position = pos
	add_child(hp)


@onready var camera: ShakeCamera2D = $ShakeCamera2D

func shake_camera(amount: float = 0.5) -> void:
	if not camera_shake:
		return
		
	camera.shake(amount)
