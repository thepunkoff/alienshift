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
@onready var _rain: GPUParticles3D = $Rain


func _ready() -> void:
	register_states({
		1: State.create(STATE_DOMES_INSTALLED),
		3: State.create(STATE_ATMOSPHERE_FORMED),
		5: State.create(STATE_CLIMATE_STABILIZED),
	})

	_ship_1_path_follow.progress_ratio = 0
	_ship_2_path_follow.progress_ratio = 0

	_atmosphere.scale = Vector3.ONE


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_DOMES_INSTALLED:
			await install_domes()
		STATE_ATMOSPHERE_FORMED:
			await rain()
		STATE_CLIMATE_STABILIZED:
			await remove_domes()


func run_synergies() -> void:
	pass


func run_after_evolve() -> void:
	pass


func install_domes() -> void:
	print("Корабли прилетают и устанавливают купола")

	# прилетают
	var tween_1: Tween = create_tween()
	tween_1.tween_property(_ship_1_path_follow, "progress_ratio", 1, Helpers.duration(2))

	await get_tree().create_timer(Helpers.duration(0.3)).timeout

	var tween_2: Tween = create_tween()
	tween_2.tween_property(_ship_2_path_follow, "progress_ratio", 1, Helpers.duration(2))

	await tween_1.finished
	await tween_2.finished

	var align: Tween = create_tween()
	align.tween_property(_ship_1, "quaternion", Helpers.local_quaternion(_ship_1, Helpers.aligned_to_planet(_ship_1)), Helpers.duration(0.5))
	align.parallel()
	align.tween_property(_ship_2, "quaternion", Helpers.local_quaternion(_ship_2, Helpers.aligned_to_planet(_ship_2)), Helpers.duration(0.5))
	await align.finished

	_ship_1.enable_dome()
	await get_tree().create_timer(Helpers.duration(0.1)).timeout
	await _ship_2.enable_dome()

	# образуется атмосфера
	var tween: Tween = create_tween()
	tween.tween_property(_atmosphere, "scale", 5.8 * Vector3.ONE, Helpers.duration(1))
	await tween.finished

	# улетают
	_ship_1.remove_dome()
	await get_tree().create_timer(Helpers.duration(0.1)).timeout
	await _ship_2.remove_dome()

	await get_tree().create_timer(Helpers.duration(0.5)).timeout

	# var mat: StandardMaterial3D = _atmosphere.get("surface_material_override/0") as StandardMaterial3D
	# var dup: Resource = mat.duplicate()
	# var tween: Tween = create_tween()
	# tween.tween_property(dup, "albedo_color:a", 30, Helpers.duration(1))
	# await tween.finished

	tween_1= create_tween()
	tween_1.tween_property(_ship_1_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween_1.parallel()
	tween_1.tween_property(_ship_1, "rotation:z", 0, Helpers.duration(1))

	await get_tree().create_timer(Helpers.duration(0.3)).timeout

	tween_2 = create_tween()
	tween_2.tween_property(_ship_2_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween_2.parallel()
	tween_2.tween_property(_ship_2, "rotation:z", 0, Helpers.duration(1))

	await tween_1.finished
	await tween_2.finished


func rain() -> void:
	print("Корабли закачивают дым в купола")
	_rain.emitting = true


func remove_domes() -> void:
	print("Корабли снимают купола, атмосфера остаётся")
	_rain.emitting = false