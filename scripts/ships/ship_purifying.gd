extends Node3D
class_name ShipPurifying

var ray_tween: Tween


func enable_ray():
	if ray_tween:
		ray_tween.kill()
	ray_tween = create_tween()
	ray_tween.tween_property(self, "blend_shapes/ray", 1, 1)
	await ray_tween.finished
