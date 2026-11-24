extends Node3D
class_name ShipLife

@onready var _mesh: MeshInstance3D = $ship_live2/ship_live


var needle_tween: Tween
var liquid_tween: Tween


func extend_needle():
	if needle_tween:
		needle_tween.kill()
	needle_tween = create_tween()
	needle_tween.tween_property(_mesh, "blend_shapes/niddle", 1, Helpers.duration(1))
	await needle_tween.finished


func retract_needle():
	if needle_tween:
		needle_tween.kill()
	needle_tween = create_tween()
	needle_tween.tween_property(_mesh, "blend_shapes/niddle", 0, Helpers.duration(1))
	await needle_tween.finished


func drain_liquid():
	if liquid_tween:
		liquid_tween.kill()
	liquid_tween = create_tween()
	liquid_tween.tween_property(_mesh, "blend_shapes/liquid", 1, Helpers.duration(1))
	await liquid_tween.finished
