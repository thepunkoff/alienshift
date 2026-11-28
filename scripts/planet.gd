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
@onready var _sludge_animation_player: AnimationPlayer = $sludge_new/AnimationPlayer2
@onready var _dirt_sub = $dirt/dirt_baked
@onready var _dirt_animation_player: AnimationPlayer = $dirt/AnimationPlayer2
@onready var _fish_particles_1: GPUParticles3D = $Fish1
@onready var _fish_particles_2: GPUParticles3D = $Fish2
@onready var _house_parent: Node3D = $HouseParent
@onready var _tree_parent: Node3D = $TreeParent

const WOBBLE_TIMES: Array[float] = [0.0, 0.2, 0.4, 0.6333333, 0.8333333, 1.0666667, 1.2666667]
const WOBBLE_KEYS: Array[Basis] = [
	Basis.IDENTITY,
	Basis(Vector3(1.2, 0.42, 0), Vector3(0.4, 1.1, -0.697), Vector3(0, 0, 1)),
	Basis(Vector3(1.2, 0, 0), Vector3(-0.811, 1.107, 1.277), Vector3(-1.036, 0, 1)),
	Basis.IDENTITY,
	Basis(Vector3(1.2, 0.453, 0), Vector3(0.43, 1.1, -0.697), Vector3(0, 0, 1)),
	Basis(Vector3(1.2, 0, 0), Vector3(-0.811, 1.107, 1.277), Vector3(-1.036, 0, 1)),
	Basis.IDENTITY,
]


var entities_with_ships_near: Array[Entity] = []
var _has_soil: bool

var _rest_basis: Basis = Basis.IDENTITY


func _align_houses_to_sphere() -> void:
	for house: Node3D in get_tree().get_nodes_in_group("house"):
		_align_to_planet(house)
		house.position = house.position.normalized() * _planet_radius


@export_tool_button("Align Houses To Planet")
var align_houses_action: Callable = _align_houses_to_sphere


func _align_hammers_to_houses() -> void:
	for house: Node3D in get_tree().get_nodes_in_group("house"):
		var hammer = house.get("hammer")
		if hammer is NodePath:
			hammer = house.get_node_or_null(hammer)
		if not hammer is Node3D:
			push_warning("%s has no hammer linked" % house.name)
			continue
		hammer.global_transform = house.global_transform
		var player := hammer.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if player:
			player.root_node = NodePath("../Hammer")

	if Engine.is_editor_hint():
		var editor: Object = Engine.get_singleton("EditorInterface")
		if editor:
			editor.mark_scene_as_unsaved()


@export_tool_button("Align Hammers To Houses")
var align_hammers_action: Callable = _align_hammers_to_houses


func _ready() -> void:
	_sludge_base.show()
	_sludge_animation_tree.active = false
	_sludge_base.scale = Vector3.ONE * 0.85

	_grass.set_blend_shape_value(_grass.find_blend_shape_by_name("growing"), 1)
	_grass.scale = Vector3.ONE * 0.95
	_planet.set_blend_shape_value(_planet.find_blend_shape_by_name("relief"), 0)
	_planet.set_blend_shape_value(_planet.find_blend_shape_by_name("pvo_lid"), 0)
	_house_parent.scale = Vector3.ONE * 0.7
	_tree_parent.scale = Vector3.ONE * 0.6
	_water.scale = Vector3.ONE * 0.9


func add_all():
	change_landscape()
	grow_grass()
	add_full_water()
	grow_trees()
	add_fish()
	add_soil()
	await grow_houses()


func change_landscape():
	var tween: Tween = create_tween()
	tween.tween_property(_planet, "blend_shapes/relief", 1, Helpers.duration(3))
	await tween.finished
	landscape_changed.emit()


func grow_grass():
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_grass, "blend_shapes/growing", 0, Helpers.duration(1.5))
	tween.tween_property(_grass, "scale", Vector3.ONE, Helpers.duration(1.5))
	tween.tween_property(_house_parent, "scale", _house_parent.scale + Vector3.ONE * 0.030, Helpers.duration(1.5))
	tween.tween_property(_tree_parent, "scale", _tree_parent.scale + Vector3.ONE * 0.030, Helpers.duration(1.5))
	await tween.finished


func _make_dead_grass_material() -> StandardMaterial3D:
	var mat := _grass.get_active_material(0).duplicate() as StandardMaterial3D
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mat.emission = Color.WHITE
	return mat


## Для ShaderWarmup: die_grass() создает новый вариант шейдера травы прямо во время игры.
func get_shader_warmup_nodes() -> Array[Node3D]:
	var grass := _grass.duplicate(0) as MeshInstance3D
	grass.set_surface_override_material(0, _make_dead_grass_material())
	return [grass]


func die_grass():
	var mat := _make_dead_grass_material()
	_grass.set_surface_override_material(0, mat)

	var dead := Color.html("#df6e27")
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(mat, "albedo_color", dead, Helpers.duration(2))
	tween.tween_property(mat, "emission", dead, Helpers.duration(2))
	await tween.finished


func become_blue():
	var planet_mat := _planet.get_active_material(0).duplicate() as ShaderMaterial
	_planet.set_surface_override_material(0, planet_mat)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(planet_mat, "shader_parameter/a_c0", Color.html("3e515b"), Helpers.duration(1))
	tween.parallel()
	tween.tween_property(planet_mat, "shader_parameter/a_c1", Color.html("101e39"), Helpers.duration(1))
	tween.parallel()
	tween.tween_property(planet_mat, "shader_parameter/a_c2", Color.html("66858c"), Helpers.duration(1))
	tween.parallel()
	tween.tween_property(planet_mat, "shader_parameter/a_c3", Color.html("7cb4cf"), Helpers.duration(1))
	tween.tween_interval(1)
	await tween.finished


func reset_color():
	var planet_mat := _planet.get_active_material(0).duplicate() as ShaderMaterial
	_planet.set_surface_override_material(0, planet_mat)

	var tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)

	if not _has_soil:
		tween.tween_property(planet_mat, "shader_parameter/a_c0", Color.html("535b63"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c1", Color.html("401c52"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c2", Color.html("8c8c8c"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c3", Color.html("c0a1cf"), Helpers.duration(1))
	else:
		tween.tween_property(planet_mat, "shader_parameter/a_c0", Color.html("342007"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c1", Color.html("271201"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c2", Color.html("493511"), Helpers.duration(1))
		tween.tween_property(planet_mat, "shader_parameter/a_c3", Color.html("6c4615"), Helpers.duration(1))

	await tween.finished


func add_soil():
	var planet_mat := _planet.get_active_material(0).duplicate() as ShaderMaterial
	_planet.set_surface_override_material(0, planet_mat)

	var water_mat := _water.get_node("water").get_active_material(0).duplicate() as ShaderMaterial
	_water.get_node("water").set_surface_override_material(0, water_mat)

	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(planet_mat, "shader_parameter/a_c0", Color.html("342007"), Helpers.duration(2))
	tween.tween_property(planet_mat, "shader_parameter/a_c1", Color.html("271201"), Helpers.duration(2))
	tween.tween_property(planet_mat, "shader_parameter/a_c2", Color.html("493511"), Helpers.duration(2))
	tween.tween_property(planet_mat, "shader_parameter/a_c3", Color.html("6c4615"), Helpers.duration(2))
	tween.tween_property(water_mat, "shader_parameter/foam_color", Color.html("6f6cff"), Helpers.duration(2))
	tween.tween_property(water_mat, "shader_parameter/line_color", Color.html("0d1c73"), Helpers.duration(2))
	tween.tween_property(water_mat, "shader_parameter/fresnel_color", Color.html("b2c5ff"), Helpers.duration(2))
	await tween.finished

	_has_soil = true


func grow_crystals():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_crystals, "scale", Vector3.ONE, Helpers.duration(1))
	await tween.finished


func add_dirt():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(_dirt_base, "scale", Vector3.ONE, Helpers.duration(2))
	tween.parallel()
	_dirt_animation_player.play("dirt_wobble")
	tween.tween_property(_dirt_sub, "blend_shapes/wobble_big", 0, Helpers.duration(2))
	await tween.finished


func remove_dirt():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(_dirt_base, "scale", Vector3.ONE * 0.8, Helpers.duration(2))
	await tween.finished


func add_sludge(need_sink_houses: bool):
	var tween: Tween = create_tween()
	tween.tween_property(_sludge_base, "scale", Vector3.ONE, Helpers.duration(1))
	await tween.finished
	_sludge_animation_tree.active = true
	await get_tree().create_timer(Helpers.duration(1)).timeout
	_sludge_animation_tree.set("parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if need_sink_houses:
		var t: Tween = create_tween()
		t.tween_property(_house_parent, "scale", Vector3.ONE * 0.7, _sludge_animation_player.get_animation("absorb").length)

	await _sludge_animation_tree.animation_finished
	_sludge_animation_tree.active = false


func add_partial_water():
	var tween: Tween = create_tween()
	tween.tween_property(_water, "scale", Vector3.ONE * 0.95, Helpers.duration(1))
	await tween.finished


func add_full_water():
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
	tween.set_trans(Tween.TRANS_SPRING)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_planet, "blend_shapes/pvo_lid", 0.7, Helpers.duration(1))
	await tween.finished


func close_mountain():
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_planet, "blend_shapes/pvo_lid", 0, Helpers.duration(1))
	await tween.finished


func add_fish():
	_fish_particles_1.emitting = true
	_fish_particles_2.emitting = true


## Возвращает ссылку на домик, откуда будет выбегать чел.
func grow_houses() -> House:
	var houses := get_tree().get_nodes_in_group("house")
	var chel_house_idx := houses.find_custom(func(x: Node): return x.has_meta("chel_house"))

	var hammers := get_tree().get_nodes_in_group("hammer")
	var j: int = 0
	for hammer: Hammer in hammers:
		var offset: Vector3 = (global_position - hammer.global_position).normalized()
		hammer.position += offset
		hammer.show()

		var t: Tween = create_tween()
		t.tween_property(hammer, "position", hammer.position - offset, 0.05 * j)
		await t.finished

		j += 1


	var tweens: Array[Tween] = []
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_house_parent, "scale", _house_parent.scale + Vector3.ONE * 0.3, Helpers.duration(2.8))
	tweens.append(tween)

	var i: int = 0
	for house: House in houses:
		var t: Tween = create_tween()
		t.tween_interval(i * 0.2)
		t.tween_callback(house.enable_building)
		t.tween_interval(3.3)
		t.tween_callback(house.disable_building)
		tweens.append(t)
		i += 1

	for t in tweens:
		await t.finished

	j = 0
	for hammer: Hammer in hammers:
		var offset: Vector3 = (global_position - hammer.global_position).normalized()

		var t: Tween = create_tween()
		t.tween_property(hammer, "position", hammer.position + offset, 0.05 * j)
		await t.finished
		hammer.hide()

		j += 1

	return houses[chel_house_idx] if chel_house_idx != -1 else null


func grow_trees():
	var tween: Tween = create_tween()
	tween.tween_property(_tree_parent, "scale", _tree_parent.scale + Vector3.ONE * 0.4, Helpers.duration(1.5))
	await tween.finished


func wobble():
	_rest_basis = basis
	var length: float = WOBBLE_TIMES[-1]
	var tween: Tween = create_tween()
	tween.tween_method(_apply_wobble, 0.0, length, Helpers.duration(length))
	await tween.finished
	basis = _rest_basis


# тут буквально зашиты keyframes из animationplayer'а: он не работает в текущем годоте для анимации Basis
func _apply_wobble(t: float) -> void:
	var last: int = WOBBLE_TIMES.size() - 1
	var i: int = 0
	while i < last - 1 and t > WOBBLE_TIMES[i + 1]:
		i += 1
	var pre: int = maxi(i - 1, 0)
	var next: int = i + 1
	var post: int = mini(i + 2, last)

	var t0: float = WOBBLE_TIMES[i]
	var span: float = WOBBLE_TIMES[next] - t0
	var pre_t: float = WOBBLE_TIMES[pre] - t0
	var post_t: float = WOBBLE_TIMES[post] - t0
	var w: float = clampf((t - t0) / span, 0.0, 1.0)

	var a: Basis = WOBBLE_KEYS[i]
	var b: Basis = WOBBLE_KEYS[next]
	var pa: Basis = WOBBLE_KEYS[pre]
	var pb: Basis = WOBBLE_KEYS[post]
	var key := Basis(
		a.x.cubic_interpolate_in_time(b.x, pa.x, pb.x, w, span, pre_t, post_t),
		a.y.cubic_interpolate_in_time(b.y, pa.y, pb.y, w, span, pre_t, post_t),
		a.z.cubic_interpolate_in_time(b.z, pa.z, pb.z, w, span, pre_t, post_t),
	)
	basis = _rest_basis * key


func _random_point_on_sphere(radius: float = 1.0) -> Vector3:
	var v := Vector3(randfn(0.0, 1.0), randfn(0.0, 1.0), randfn(0.0, 1.0))
	return v.normalized() * radius


func _align_to_planet(node: Node3D) -> void:
	var up := (node.global_position - Vector3.ZERO).normalized()
	var current_up := node.global_basis.y.normalized()
	var q := Quaternion(current_up, up)
	node.global_basis = Basis(q) * node.global_basis
