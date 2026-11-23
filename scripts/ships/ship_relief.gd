extends Node3D
class_name ShipRelief

signal bomb_dropped

@onready var _mesh: MeshInstance3D = $ship_relief2/ship_relief
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _bomb: Node3D = $Bomb

func drop_bomb():
	_animation_player.play("drop_bomb")
	await _animation_player.animation_finished
	_bomb.hide()
	bomb_dropped.emit()

	var tween: Tween = create_tween()
	tween.tween_property(_mesh, "blend_shapes/clouds", 1, 0.6)
	tween.tween_property(_mesh, "blend_shapes/clouds2", 1, 0.6)
	await tween.finished
	_mesh.set_blend_shape_value(_mesh.find_blend_shape_by_name("clouds"), 0)
	_mesh.set_blend_shape_value(_mesh.find_blend_shape_by_name("clouds2"), 0)
