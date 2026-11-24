extends Node


@export var target: Node3D
@export var radius: float = 0.3
@export var max_rotation_weight: float = 0.2

var last_pos: Vector3
var last_pos_ready: bool = false
var _last_wobble: Basis = Basis.IDENTITY

func _ready() -> void:
	while true:
		var x: float = randf_range(-radius, radius)
		var y: float = randf_range(-radius, radius)
		var z: float = randf_range(-radius, radius)
		var pos = Vector3(x, y, z).normalized() * pow(randf(), 1. / 3.) * radius
		await _hover_to(pos)

func _hover_to(pos: Vector3):
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(target, "position", pos, 2)
	await tween.finished


func _process(delta: float) -> void:
	if not last_pos_ready:
		last_pos = target.position
		last_pos_ready = true
		return

	var disp: Vector3 = (target.position - last_pos)
	var vel: Vector3 = disp / delta
	var weight: float = max_rotation_weight * vel.x / (PI / 2 / radius)
	var wobble := Basis(Vector3.BACK, -weight * PI / 2)
	target.basis = target.basis * _last_wobble.inverse() * wobble
	_last_wobble = wobble
	last_pos = target.position
