extends Entity
class_name Climate

const STATE_DOMES_INSTALLED := "domes_installed"
const STATE_ATMOSPHERE_FORMED := "atmosphere_formed"
const STATE_CLIMATE_STABILIZED := "climate_stabilized"

@onready var _ship_1_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _ship_1: ShipClimate = $Path3D/PathFollow3D/ShipClimate

@onready var _ship_2_path_follow: PathFollow3D = $Path3D2/PathFollow3D
@onready var _ship_2: ShipClimate = $Path3D2/PathFollow3D/ShipClimate

@onready var _atmosphere: Node3D = $Atmosphere

@export var dome_approach: float = 1.7
@export var dome_scale: float = 1.43


func _ready() -> void:
	register_states({
		1: State.create(STATE_DOMES_INSTALLED),
		3: State.create(STATE_ATMOSPHERE_FORMED),
		5: State.create(STATE_CLIMATE_STABILIZED),
	})

	_ship_1_path_follow.progress_ratio = 0
	_ship_2_path_follow.progress_ratio = 0


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_DOMES_INSTALLED:
			await install_domes()
		STATE_ATMOSPHERE_FORMED:
			await form_atmosphere()
		STATE_CLIMATE_STABILIZED:
			await remove_domes()


func run_synergies() -> void:
	pass


func run_after_evolve() -> void:
	pass


func install_domes() -> void:
	print("Корабли прилетают и устанавливают купола")
	var tween_1: Tween = create_tween()
	tween_1.tween_property(_ship_1_path_follow, "progress_ratio", 1, Helpers.duration(1))

	await get_tree().create_timer(Helpers.duration(0.3)).timeout

	var tween_2: Tween = create_tween()
	tween_2.tween_property(_ship_2_path_follow, "progress_ratio", 1, Helpers.duration(1))

	await tween_1.finished
	await tween_2.finished

	var align: Tween = create_tween()
	align.tween_property(_ship_1, "quaternion", Helpers.local_quaternion(_ship_1, Helpers.aligned_to_planet(_ship_1)), Helpers.duration(0.5))
	align.parallel()
	align.tween_property(_ship_2, "quaternion", Helpers.local_quaternion(_ship_2, Helpers.aligned_to_planet(_ship_2)), Helpers.duration(0.5))
	await align.finished

	await _approach(dome_approach, dome_scale)

	_ship_1.enable_dome()
	await get_tree().create_timer(Helpers.duration(0.1)).timeout
	await _ship_2.enable_dome()

func form_atmosphere() -> void:
	print("Корабли закачивают дым в купола")
	var tween: Tween = create_tween()
	tween.tween_property(_atmosphere, "scale", 5 * Vector3.ONE, Helpers.duration(1))
	await tween.finished


func remove_domes() -> void:
	print("Корабли снимают купола, атмосфера остаётся")
	_ship_1.remove_dome()
	await get_tree().create_timer(Helpers.duration(0.1)).timeout
	await _ship_2.remove_dome()

	await _approach(0, 1)
	await get_tree().create_timer(Helpers.duration(0.5)).timeout

	var mat: StandardMaterial3D = _atmosphere.get("surface_material_override/0") as StandardMaterial3D
	var dup: Resource = mat.duplicate()
	var tween: Tween = create_tween()
	tween.tween_property(dup, "albedo_color:a", 30, Helpers.duration(1))
	await tween.finished

	var tween_1: Tween = create_tween()
	tween_1.tween_property(_ship_1_path_follow, "progress_ratio", 0, Helpers.duration(1))
	tween_1.parallel()
	tween_1.tween_property(_ship_1, "rotation:z", 0, Helpers.duration(1))

	await get_tree().create_timer(Helpers.duration(0.3)).timeout

	var tween_2: Tween = create_tween()
	tween_2.tween_property(_ship_2_path_follow, "progress_ratio", 0, Helpers.duration(1))
	tween_2.parallel()
	tween_2.tween_property(_ship_2, "rotation:z", 0, Helpers.duration(1))

	await tween_1.finished
	await tween_2.finished


func _approach(distance: float, scale_mult: float) -> void:
	var tween: Tween = create_tween().set_parallel()
	for ship: ShipClimate in [_ship_1, _ship_2]:
		if not ship.has_meta("base_scale"):
			ship.set_meta("base_scale", ship.scale)
		tween.tween_property(ship, "scale", ship.get_meta("base_scale") * scale_mult, Helpers.duration(1))
	for follow: PathFollow3D in [_ship_1_path_follow, _ship_2_path_follow]:
		var slot := follow.get_parent().curve.sample_baked(follow.get_parent().curve.get_baked_length()) as Vector3
		var inward := -Vector2(slot.x, slot.y).normalized() * distance
		tween.tween_property(follow, "h_offset", inward.x, Helpers.duration(1))
		tween.tween_property(follow, "v_offset", inward.y, Helpers.duration(1))
	await tween.finished
