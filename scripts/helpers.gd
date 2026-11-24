extends Node

static func aligned_to_planet(node: Node3D) -> Basis:
	var b := node.global_basis
	var z := b.z.normalized()
	var dir := -node.global_position

	# keep only the part of dir that lies in the node's XY plane
	dir -= z * dir.dot(z)
	if dir.length_squared() < 1e-8:
		return b  # target is on the Z axis, roll is undefined

	var angle := (-b.y).signed_angle_to(dir.normalized(), z)
	return b.rotated(z, angle)  # roll around the node's own Z


func duration(d: float) -> float:
	var game := get_tree().current_scene as Game
	return 0. if game and game.skip_animations else d
