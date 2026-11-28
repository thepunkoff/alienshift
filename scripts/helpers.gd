extends Node

static func aligned_to_planet(node: Node3D) -> Basis:
	return aligned_to(node, Vector3.ZERO)


static func aligned_to(node: Node3D, target: Vector3, from: Vector3 = node.global_position) -> Basis:
	var b := node.global_basis
	var z := b.z.normalized()
	var dir := target - from

	dir -= z * dir.dot(z)
	if dir.length_squared() < 1e-8:
		return b

	var angle := (-b.y).signed_angle_to(dir.normalized(), z)
	return b.rotated(z, angle)


static func local_quaternion(node: Node3D, global_b: Basis) -> Quaternion:
	var parent := node.get_parent_node_3d()
	var b := global_b if parent == null else parent.global_basis.inverse() * global_b
	return b.get_rotation_quaternion()


func duration(d: float) -> float:
	var game := get_tree().current_scene as Game
	return 0. if game and game.skip_animations else d
