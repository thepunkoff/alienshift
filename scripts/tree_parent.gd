@tool
extends Node3D

func _align_trees_to_planet() -> void:
	for tree: Node3D in get_children():
		tree.transform.basis = _aligned_to_planet(tree)

@export_tool_button("Align Trees To Planet")
var align_trees_action: Callable = _align_trees_to_planet


func _randomize_trees_scale() -> void:
	for tree: Node3D in get_children():
		tree.scale = Vector3.ONE * randf_range(0.1, 0.3)

@export_tool_button("Randomize Trees Scale")
var randomize_trees_scale_action: Callable = _randomize_trees_scale


func _aligned_to_planet(node: Node3D) -> Basis:
	var up := (node.global_position - Vector3.ZERO).normalized()
	var current_up := node.global_basis.y.normalized()
	var q := Quaternion(current_up, up)
	return Basis(q) * node.global_basis
