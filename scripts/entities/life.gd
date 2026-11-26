extends Entity
class_name Life

@export var summon: Summon
@export var planet: Planet

const STATE_SOW_SEEDS := "sow_seeds"

@onready var _ship: ShipLife = $Path3D/PathFollow3D/ShipLife
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D

var _added_water_life: bool = false

func _ready() -> void:
	register_states({
		1: State.create(STATE_SOW_SEEDS)
	})

	_ship_path_follow.progress_ratio = 0

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SOW_SEEDS:
			await sow_seeds()

func run_synergies() -> void:
	if _added_water_life:
		return

	if state.name == STATE_SOW_SEEDS and summon.state.name == Summon.STATE_WATER_SPREAD_ACCROSS_PLANET:
		await add_water_life()

	_added_water_life = true


func run_after_evolve() -> void:
	pass


func sow_seeds() -> void:
	print("Человечки в скафандрах засеивают планету семенами жизни")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(2))
	await tween.finished

	tween = create_tween()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, Helpers.aligned_to_planet(_ship)), Helpers.duration(1))
	await tween.finished

	await _ship.extend_needle()
	await _ship.drain_liquid()
	await planet.wobble()

	tween = create_tween()
	tween.tween_interval(Helpers.duration(.5))
	tween.tween_callback(func(): _ship.retract_needle())
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween.parallel()
	tween.tween_property(_ship, "rotation:z", 0, Helpers.duration(1))
	await tween.finished


func add_water_life() -> void:
	print("Появляются водные существа")
	await planet.add_fish()
