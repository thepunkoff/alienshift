extends Node3D
class_name ShipSummon

@onready var animation_tree: AnimationTree = $AnimationTree


func summon_monster():
	animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	await animation_tree.animation_finished
