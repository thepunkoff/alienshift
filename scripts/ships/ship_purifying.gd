extends Node3D
class_name ShipPurifying

var ray_tween: Tween

@onready var _mesh: MeshInstance3D = $ship_purifying2/ship_purifying

func enable_ray():
	if ray_tween:
		ray_tween.kill()
	ray_tween = create_tween()
	ray_tween.tween_property(_mesh, "blend_shapes/ray", 1, Helpers.duration(.1))
	await ray_tween.finished


func disable_ray():
	if ray_tween:
		ray_tween.kill()
	ray_tween = create_tween()
	ray_tween.tween_property(_mesh, "blend_shapes/ray", 0, Helpers.duration(.1))
	await ray_tween.finished
