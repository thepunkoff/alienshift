extends Node3D
class_name ShipClimate

var dome_tween: Tween

@onready var mesh: MeshInstance3D = $ship_climate2/ship_climate

func enable_dome():
	if dome_tween:
		dome_tween.kill()
	dome_tween = create_tween()
	dome_tween.tween_property(mesh, "blend_shapes/cupola", 1, Helpers.duration(1))
	await dome_tween.finished


func remove_dome():
	if dome_tween:
		dome_tween.kill()
	dome_tween = create_tween()
	dome_tween.tween_property(mesh, "blend_shapes/cupola", 0, Helpers.duration(1))
	await dome_tween.finished
