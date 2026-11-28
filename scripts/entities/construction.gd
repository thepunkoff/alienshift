extends Entity
class_name Construction

@export var core: Core
@export var crystal: Crystal
@export var purifying: Purifying
@export var relief: Relief
@export var climate: Climate
@export var pvo: Pvo
@export var summon: Summon
@export var enrichment: Enrichment
@export var life : Life
@export var planet : Planet

const STATE_HOUSES_LOWERED := "houses_lowered"

@onready var _ship: ShipConstruction = $Path3D/PathFollow3D/ShipConstruction
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _camera: Camera3D = get_viewport().get_camera_3d()
@onready var _chel_camera_position: Marker3D = $ChelCameraPosition
@onready var _initial_camera_position: Marker3D = $InitialCameraPosition

var _added_people: bool = false
var _chel_house: House


func _ready() -> void:
	register_states({
		1: State.create(STATE_HOUSES_LOWERED),
	})

	_ship_path_follow.progress_ratio = 0


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	if new_state.name == STATE_HOUSES_LOWERED:
		await lower_houses()


func run_synergies() -> void:
	pass

func run_after_evolve() -> void:
	if _added_people:
		return

	print("core: %s" % [core.state.name == Core.STATE_PUT_INSIDE])
	print("crystal: %s" % [crystal.state.name == Crystal.STATE_MINERALIZATION_OCCURRED])
	print("purifying: %s" % [purifying.state.name == Purifying.STATE_RADIATION_CLEANSING])
	print("relief: %s" % [relief.state.name == Relief.STATE_BOMBS_CREATED_RELIEF])
	print("climate: %s" % [climate.state.name == Climate.STATE_CLIMATE_STABILIZED])
	print("pvo: %s" % [pvo.state.name == Pvo.STATE_SHIPS_APPROACHING])
	print("summon: %s" % [summon.state.name == Summon.STATE_WATER_SPREAD_ACCROSS_PLANET])
	print("enrichment: %s" % [enrichment.state.name == Enrichment.STATE_VEGETATION_GROWN])
	print("life: %s" % [life.added_water_life])

	if (
			core.state.name == Core.STATE_PUT_INSIDE \
			and crystal.state.name == Crystal.STATE_MINERALIZATION_OCCURRED \
			and purifying.state.name == Purifying.STATE_RADIATION_CLEANSING \
			and relief.state.name == Relief.STATE_BOMBS_CREATED_RELIEF \
			and climate.state.name == Climate.STATE_CLIMATE_STABILIZED \
			and pvo.state.name == Pvo.STATE_SHIPS_APPROACHING \
			and summon.state.name == Summon.STATE_WATER_SPREAD_ACCROSS_PLANET \
			and enrichment.state.name == Enrichment.STATE_VEGETATION_GROWN \
			and life.added_water_life
	):
		await added_people()

	_added_people = true


func lower_houses() -> void:
	print("Спускаются дома на краниках")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(2))
	await tween.finished

	tween = create_tween()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, Helpers.aligned_to_planet(_ship)), Helpers.duration(0.5))
	await tween.finished

	var init: Vector3 = _ship.position
	tween = create_tween()
	tween.tween_property(_ship, "position", init - _ship.transform.basis.y.normalized() * 0.6, Helpers.duration(2))
	await tween.finished
	_chel_house = await planet.grow_houses()

	tween = create_tween()
	tween.tween_interval(Helpers.duration(0.5))
	tween.tween_property(_ship, "position", init, Helpers.duration(1))
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween.parallel()
	tween.tween_property(_ship, "rotation:z", 0, Helpers.duration(1))
	await tween.finished


func added_people() -> void:
	print("Людишки выбегают из прилетевших домиков")
	var tween: Tween = create_tween()
	tween.tween_property(_camera, "position", _chel_camera_position.position, 4)
	tween.parallel()
	tween.tween_property(_camera, "size", 4.1, 3)
	await _chel_house.release_chel()
	if tween.is_running():
		await tween.finished

	tween= create_tween()
	tween.tween_property(_camera, "position", _initial_camera_position.position, 4)
	tween.parallel()
	tween.tween_property(_camera, "size", 9.35, 3)
	await tween.finished
