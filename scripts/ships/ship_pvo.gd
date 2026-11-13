extends Node3D
class_name ShipPvo

var pvo_tween: Tween


func drop_pvo():
	if pvo_tween:
		pvo_tween.kill()
	pvo_tween = create_tween()
	pvo_tween.tween_property(self, "blend_shapes/pvo", 1, 1)
	await pvo_tween.finished
