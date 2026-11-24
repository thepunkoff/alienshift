extends Entity
class_name Enrichment

@export var crystal: Crystal
@export var planet: Planet

const STATE_SLIME_ABSORBED := "slime_absorbed"
const STATE_VEGETATION_GROWN := "vegetation_grown"

@onready var _ship: ShipEnrichment = $Path3D/PathFollow3D/ShipEnrichment
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D

func _ready() -> void:
	register_states({
		1: State.create(STATE_SLIME_ABSORBED),
		3: State.create(STATE_VEGETATION_GROWN),
	})


var _died_vegetation: bool = false

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SLIME_ABSORBED:
			await enrich_soil()
		STATE_VEGETATION_GROWN:
			await grow_vegetation()

func run_synergies() -> void:
	if _died_vegetation:
		return

	if state.name == STATE_VEGETATION_GROWN and crystal.state.name != Crystal.STATE_MINERALIZATION_OCCURRED:
		await died_vegetation()
		_died_vegetation = true


func run_after_evolve() -> void:
	pass


func enrich_soil() -> void:
	print("Прилетают машины со шлангами, льют розовую густую капающую жижу на планету, и она впитывается")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(6))
	tween.tween_interval(Helpers.duration(.7))
	await tween.finished

	await _ship.prepare_hose()
	await get_tree().create_timer(Helpers.duration(.5)).timeout

	planet.add_sludge()
	await _ship.drain_liquid()

	tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(6))
	await tween.finished


func grow_vegetation() -> void:
	print("Почва зеленеет, травка, цветочки")
	await planet.grow_grass()


func died_vegetation() -> void:
	print("Почва становится осенней, гнилой")
	await planet.die_grass()
