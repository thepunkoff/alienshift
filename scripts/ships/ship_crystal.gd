extends Node3D
class_name ShipCrystal

var drops_tween: Tween


func drop_crystals():
	if drops_tween:
		drops_tween.kill()
	drops_tween = create_tween()
	drops_tween.tween_property(self, "blend_shapes/crystals_drop", 1, 1)
	await drops_tween.finished
