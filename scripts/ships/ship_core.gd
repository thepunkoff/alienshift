extends Node3D
class_name ShipCore

var drill_tween: Tween
var light_tween: Tween


func extend_drill():
	if drill_tween:
		drill_tween.kill()
	drill_tween = create_tween()
	drill_tween.tween_property(self, "blend_shapes/drill", 1, 1)
	await drill_tween.finished


func enable_light():
	if light_tween:
		light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property(self, "blend_shapes/light", 1, 1)
	await light_tween.finished
