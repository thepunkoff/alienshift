extends Node3D
class_name ShipPvo

var pvo_tween: Tween

@onready var _mesh: MeshInstance3D = $ship_pvo2/ship_pvo

func drop_pvo():
	if pvo_tween:
		pvo_tween.kill()
	pvo_tween = create_tween()
	pvo_tween.tween_property(_mesh, "blend_shapes/pvo", 1, 1)
	await pvo_tween.finished
	_mesh.set_blend_shape_value(_mesh.find_blend_shape_by_name("pvo"), 0)
