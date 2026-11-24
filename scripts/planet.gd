@tool
extends Node3D
class_name Planet

signal landscape_changed

@export var _planet_radius: float = 2.

@onready var _planet = $planet/planet
@onready var _grass: MeshInstance3D = $grass/grass
@onready var _crystals: Node3D = $crystals
@onready var _water: Node3D = $water
@onready var _steam_1: GPUParticles3D = $water/Steam
@onready var _steam_2: GPUParticles3D = $water/Steam2
@onready var _dirt_base = $dirt
@onready var _sludge_base = $sludge_new
@onready var _sludge_animation_tree: AnimationTree = $sludge_new/AnimationTree
@onready var _dirt_sub = $dirt/dirt_baked
@onready var _dirt_animation_player: AnimationPlayer = $dirt/AnimationPlayer2
@onready var _fish_particles_1: GPUParticles3D = $Fish1
@onready var _fish_particles_2: GPUParticles3D = $Fish2


func _align_houses_to_sphere() -> void:
	for house: Node3D in get_tree().get_nodes_in_group("house"):
		_align_to_planet(house)
		house.position = house.position.normalized() * _planet_radius


@export_tool_button("Align Houses To Planet")
var align_houses_action: Callable = _align_houses_to_sphere


func _ready() -> void:
	if not Engine.is_editor_hint():
		for house: Node3D in get_tree().get_nodes_in_group("house"):
			house.position = house.position.normalized() # топим внутри планеты

		_sludge_animation_tree.active = false
		_sludge_base.scale = Vector3.ONE * 0.85

func change_landscape():
	var tween: Tween = create_tween()
	tween.tween_property(_planet, "blend_shapes/relief", 1, Helpers.duration(3))
	await tween.finished
	landscape_changed.emit()


func grow_grass():
	var tween: Tween = create_tween()
	tween.tween_property(_grass, "blend_shapes/growing", 0, Helpers.duration(1.5))
	tween.parallel()
	tween.tween_property(_grass, "scale", Vector3.ONE, Helpers.duration(1.5))
	await tween.finished


func die_grass():
	var tween: Tween = create_tween()
	var mat: StandardMaterial3D = _grass.mesh.get("surface_0/material") as StandardMaterial3D
	var dup: Resource = mat.duplicate()
	_grass.mesh.set("surface0/material", dup)
	tween.tween_property(dup, "albedo_color", Color.html("#df6e27"), Helpers.duration(2))
	await tween.finished


func grow_crystals():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_crystals, "scale", Vector3.ONE, Helpers.duration(1))
	await tween.finished


func add_dirt():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_dirt_base, "scale", 1, Helpers.duration(1))
	tween.parallel()
	_dirt_animation_player.play("dirt_wobble")
	tween.tween_property(_dirt_sub, "blend_shapes/wobble_big", -1, Helpers.duration(1))
	tween.tween_property(_dirt_sub, "blend_shapes/wobble_big", 0.4, Helpers.duration(1))
	await tween.finished


func add_sludge():
	var tween: Tween = create_tween()
	tween.tween_property(_sludge_base, "scale", Vector3.ONE, Helpers.duration(1))
	await tween.finished
	_sludge_animation_tree.active = true
	await get_tree().create_timer(Helpers.duration(1)).timeout
	_sludge_animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	await _sludge_animation_tree.animation_finished
	_sludge_animation_tree.active = false


func add_water():
	var tween: Tween = create_tween()
	tween.tween_property(_water, "scale", Vector3.ONE, Helpers.duration(1))
	await tween.finished


func evaporate_water():
	var tween: Tween = create_tween()
	tween.tween_property(_water, "scale", Vector3.ONE * 0.9, Helpers.duration(3))
	_steam_1.emitting = true
	_steam_2.emitting = true
	await tween.finished
	_steam_1.emitting = false
	_steam_2.emitting = false


func open_mountain():
	var tween: Tween = create_tween()
	tween.tween_property(_planet, "blend_shapes/relief", 0, Helpers.duration(3))
	tween.parallel()
	tween.tween_property(_planet, "blend_shapes/pvo_lid", 1, Helpers.duration(3))
	await tween.finished


func add_fish():
	_fish_particles_1.emitting = true
	_fish_particles_2.emitting = true


## Возвращает ссылку на домик, откуда будет выбегать чел.
func grow_houses() -> House:
	var last_tween: Tween
	var chel_house: House

	var i: int = 0
	for house: Node3D in get_tree().get_nodes_in_group("house"):
		_align_to_planet(house)
		last_tween = create_tween()
		var target: Vector3 = house.position.normalized() * _planet_radius
		last_tween.tween_property(house, "position", target, Helpers.duration(1 + (i * 0.1)))
		if house.has_meta("chel_house"):
			chel_house = house
		i += 1
	await last_tween.finished

	return chel_house


func _random_point_on_sphere(radius: float = 1.0) -> Vector3:
	var v := Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0))
	return v.normalized() * radius


func _align_to_planet(node: Node3D) -> void:
	var up := (node.global_position - Vector3.ZERO).normalized()
	var current_up := node.global_basis.y.normalized()
	var q := Quaternion(current_up, up)
	node.global_basis = Basis(q) * node.global_basis