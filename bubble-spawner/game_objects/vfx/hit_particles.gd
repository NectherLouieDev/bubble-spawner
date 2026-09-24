class_name HitParticle
extends Node2D

@onready var particles: GPUParticles2D = $Particles

## Call right after instantiate(), before add_child()
func configure(color: Color, amount: int = 12, lifetime: float = 0.5) -> void:
	# Get the node directly — works before _ready()
	var particles := $Particles as GPUParticles2D
	particles.modulate = color
	particles.amount = amount
	particles.lifetime = lifetime

func _ready() -> void:
	# Start emitting on spawn
	var particles := $Particles as GPUParticles2D
	particles.emitting = true

	var total := particles.lifetime + 0.2
	await get_tree().create_timer(total).timeout
	queue_free()
