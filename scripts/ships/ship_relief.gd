extends Node3D
class_name ShipRelief

var tween: Tween


func drop_bomb():
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "blend_shapes/bomb", 1, 0.6)
	tween.tween_property(self, "blend_shapes/clouds", 1, 0.6)
	tween.tween_property(self, "blend_shapes/clouds2", 1, 0.6)
	await tween.finished
