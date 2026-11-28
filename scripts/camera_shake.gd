extends Camera3D

var _start_position: Vector3
var _start_rotation: Vector3
var _time_left := 0.0
var _duration := 0.0
var _strength := 0.0

func _ready() -> void:
	_start_position = position
	_start_rotation = rotation

func shake(duration: float = 0.3, strength: float = 0.2) -> void:
	_duration = maxf(duration, 0.001)
	_time_left = _duration
	_strength = strength

func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return

	_time_left = maxf(_time_left - delta, 0.0)
	var fade := _time_left / _duration

	position = _start_position + Vector3(
		randf_range(-_strength, _strength),
		randf_range(-_strength, _strength),
		0.0
	) * fade

	rotation = _start_rotation + Vector3(
		randf_range(-0.08, 0.08),
		randf_range(-0.08, 0.08),
		randf_range(-0.12, 0.12)
	) * fade

	if _time_left == 0.0:
		position = _start_position
		rotation = _start_rotation
