extends Node

enum State {
	SPAWN_IN,   # objects spawn, no input, no ball physics
	START,      # player input + ball physics enabled
	GAME_OVER
}

signal state_changed(new_state: State)
signal lives_changed(new_lives: int)
signal score_changed(new_score: int)
signal game_over

var state: State = State.SPAWN_IN
var lives := 100
var score := 0

func reset() -> void:
	lives = 100
	score = 0
	lives_changed.emit(lives)
	score_changed.emit(score)
	set_state(State.SPAWN_IN)

func set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)

func lose_life() -> void:
	lives -= 1
	lives_changed.emit(lives)
	if lives <= 0:
		game_over.emit()
		set_state(State.GAME_OVER)

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
