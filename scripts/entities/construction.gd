extends Entity
class_name Construction

@export var life : Life
@export var planet : Planet

const STATE_HOUSES_LOWERED := "houses_lowered"

@onready var _ship: ShipConstruction = $Path3D/PathFollow3D/ShipConstruction
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D

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
	if _added_people:
		return

	if life.state.name == Life.STATE_SOW_SEEDS:
		await added_people()

	_added_people = true


func run_after_evolve() -> void:
	pass


func lower_houses() -> void:
	print("Спускаются дома на краниках")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(4))
	tween.tween_interval(Helpers.duration(0.5))
	tween.tween_property(_ship, "position:y", _ship.position.y - 0.6, Helpers.duration(2))
	await tween.finished
	_chel_house = await planet.grow_houses()

	tween = create_tween()
	tween.tween_interval(Helpers.duration(0.5))
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(4))
	await tween.finished


func added_people() -> void:
	print("Людишки выбегают из прилетевших домиков")
	await _chel_house.release_chel()
