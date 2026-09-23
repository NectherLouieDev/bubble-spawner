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

func _ready() -> void:
	# Connect GameManager
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_over.connect(_on_game_over)

	# Connect player
	player.died.connect(_on_player_died)
	
	# Timer connects
	start_timer.timeout.connect(on_start_timer_completed)
	
	# Connect debugs
	#debug_panel.toggle_changed.connect(_on_debug_toggle_changed)
	debug_menu.toggle_changed.connect(_on_debug_toggle_changed)

	# Initialize
	GameManager.reset()
	_enter_spawn_in()

func _on_debug_toggle_changed(toggle_name: String, value: bool) -> void:
	match toggle_name:
		"all_colors":
			player.color_on = value
			
			for b in balls:
				b.color_on = value
		"pop_intro":
			player.pop_intro = value
			for b in balls:
				b.pop_intro = value
		_:
			push_warning("Unknown debug toggle: %s" % toggle_name)


# --- State entry ---

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
	
	_spawn_all()
	_freeze_physics(true)
	_set_player_input(false)
	
	start_timer.start()

var count = 3;
func on_start_timer_completed() -> void:
	start_time_label.text = str(count)
	count -= 1
	#start_time_label.visible = false;
	#_freeze_physics(false)
	#_set_player_input(true)

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
	player.play_pop_intro(0)
	player.velocity = Vector2.ZERO

	# Balls at configured markers
	for i in range(BALL_SPAWNS.size()):
		var entry = BALL_SPAWNS[i]
		var marker: Marker2D = spawn_points.get_node(entry["marker"])
		# Spawn a ball
		var ball = spawner.spawn_ball_at(marker.global_position, entry["size"])
		ball.popped.connect(on_ball_popped)
		balls.append(ball)
	
	for i in range(balls.size()):
		var ball = balls[i]
		ball.pop_intro = get_toggle_value("pop_intro")
		var delay = (i + 1) * 0.15
		ball.play_pop_intro(delay)
	
	print("before ", balls.size())

func on_ball_popped(body: Ball) -> void:
	body.popped.disconnect(on_ball_popped)
	
	GameManager.add_score(floor(body.size * 10))
	
	var ballIndex := balls.find(body)
	if body.check_size():
		for i in 2:
			var ball_child = body.spawn_child()
			ball_child.popped.connect(on_ball_popped)
			ball_child.play_pop_intro(0)
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

func _on_player_died() -> void:
	if GameManager.state == GameManager.State.START:
		GameManager.lose_life()

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "Lives: %d" % new_lives

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

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
