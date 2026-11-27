extends Node3D
class_name House

@export var hammer: Hammer

@onready var _house_mesh: MeshInstance3D = $house/house
@onready var _chel: Node3D = $chel
@onready var _chel_animation_player: AnimationPlayer= $chel/AnimationPlayer
@onready var _chel_mesh: MeshInstance3D = $chel/rig/Skeleton3D/chel

func _ready() -> void:
	_house_mesh.set_blend_shape_value(_house_mesh.find_blend_shape_by_name("door_open"), 0)


func release_chel():
	var tween: Tween = create_tween()
	tween.tween_property(_house_mesh, "blend_shapes/door_open", 1, Helpers.duration(1))
	await tween.finished
	_chel_animation_player.play("chel_action")
	create_tween().tween_property(_chel, "position:z", 0.8, Helpers.duration(2))
	await _chel_animation_player.animation_finished
	tween = create_tween()
	tween.tween_property(_chel_mesh, "blend_shapes/heart_face", 1, Helpers.duration(0.2))
	await tween.finished


func enable_building():
	hammer.enable_building()


func disable_building():
	hammer.disable_building()
