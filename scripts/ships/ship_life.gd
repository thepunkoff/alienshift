extends Node3D
class_name ShipLife


var needle_tween: Tween
var liquid_tween: Tween


func extend_needle():
	if needle_tween:
		needle_tween.kill()
	needle_tween = create_tween()
	needle_tween.tween_property(self, "blend_shapes/niddle", 1, 1)
	await needle_tween.finished


func drain_liquid():
	if liquid_tween:
		liquid_tween.kill()
	liquid_tween = create_tween()
	liquid_tween.tween_property(self, "blend_shapes/liquid", 1, 1)
	await liquid_tween.finished
