extends Node


@export var target: Node3D
@export var radius: float = 0.3
@export var max_rotation_weight: float = 0.2

var last_pos: Vector3
var last_pos_ready: bool = false

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
	vel = Vector3(vel.x, 0, vel.z)
	var dir: Vector3 = vel.normalized() if vel.length() > 0 else Vector3.BACK
	var quat: Quaternion = Quaternion(Vector3.UP, dir)
	var weight = max_rotation_weight * vel.length() / (PI / 2 / radius)
	quat = Quaternion.IDENTITY.slerp(quat, weight)
	target.basis = Basis(quat)
	last_pos = target.position
