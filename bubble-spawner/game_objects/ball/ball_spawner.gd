class_name BallSpawner
extends Node2D

const BALL_SCENE := preload("res://game_objects/ball/ball.tscn")

func spawn_ball_at(pos: Vector2, size: float) -> Ball:
	var ball := BALL_SCENE.instantiate()
	ball.position = pos
	ball.size = size
	add_child(ball)
	return ball
