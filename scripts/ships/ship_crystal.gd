extends Node3D
class_name ShipCrystal

@onready var _mesh: MeshInstance3D =	$ship_crystal2/ship_crystal


func drop_crystals():
	var tween: Tween
	for i in range(2):
		tween = create_tween()
		tween.tween_property(_mesh, "blend_shapes/crystals_drop", 1, .5)
		await tween.finished
		_mesh.set_blend_shape_value(_mesh.find_blend_shape_by_name("crystals_drop"), 0)

