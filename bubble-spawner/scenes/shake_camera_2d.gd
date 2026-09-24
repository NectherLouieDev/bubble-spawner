class_name ShakeCamera2D
extends Camera2D

## Trauma-based shake. Each call adds to trauma, which decays over time.
## Actual offset = max_offset * trauma^2 * noise, giving a smooth falloff.

@export var decay_rate := 1.5          # trauma lost per second
@export var max_offset := Vector2(12, 12)   # pixels at full trauma
@export var max_rotation := 0.05       # radians at full trauma
@export var noise_speed := 40.0        # how fast the noise wiggles

var trauma := 0.0                      # 0..1

var _noise := FastNoiseLite.new()
var _noise_y := 0

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5
	_noise_y = randi() % 10000

func _process(delta: float) -> void:
	if trauma <= 0.0:
		# Fully settled; skip work.
		offset = Vector2.ZERO
		rotation = 0.0
		return

	# Decay trauma
	trauma = maxf(trauma - decay_rate * delta, 0.0)

	# Amplitude scales with trauma squared (fast falloff at low trauma)
	var amount := trauma * trauma

	# Sample noise at increasing time so the shake is continuous
	var t := Time.get_ticks_msec() / 1000.0 * noise_speed
	offset.x = max_offset.x * amount * _noise.get_noise_2d(t, 0)
	offset.y = max_offset.y * amount * _noise.get_noise_2d(0, t + _noise_y)
	rotation = max_rotation * amount * _noise.get_noise_2d(t, t)

## Public API — call from anywhere.
## amount: 0..1 (trauma to add). Values > 1 get clamped.
func shake(amount: float = 0.5) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
