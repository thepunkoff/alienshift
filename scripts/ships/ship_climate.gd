extends Node3D
class_name ShipClimate

var dome_tween: Tween


func enable_dome():
	if dome_tween:
		dome_tween.kill()
	dome_tween = create_tween()
	dome_tween.tween_property(self, "blend_shapes/cupola", 1, 1)
	await dome_tween.finished
