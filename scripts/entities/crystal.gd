extends Entity
class_name Crystal

@export var summon: Summon
@export var planet: Planet

const STATE_FOSSILS_BURIED: String = "fossils_buried"
const STATE_MINERALIZATION_OCCURRED: String = "mineralization_occurred"

@onready var _ship: ShipCrystal = $Path3D/PathFollow3D/ShipCrystal
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _ship_path_follow_2: PathFollow3D = $"Path3D2/PathFollow3D"
@onready var _path: Path3D = $Path3D2
@onready var _particles: GPUParticles3D = $GPUParticles3D

var _fossils_bloomed: bool
var _align_ship_to_planet: bool

func _ready():
	register_states({
		1: State.create(STATE_FOSSILS_BURIED),
		7: State.create(STATE_MINERALIZATION_OCCURRED)
	})

	_ship_path_follow.progress_ratio = 0
	_ship_path_follow_2.progress_ratio = 0



func _process(delta: float) -> void:

	if _align_ship_to_planet:
		_ship.global_basis = Helpers.aligned_to_planet(_ship)


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_FOSSILS_BURIED:
			await bury_fossils()
		STATE_MINERALIZATION_OCCURRED:
			await mineralization_occurred()
		_:
			push_error("Fossils state not expected: '%s'." % [new_state.name])


func run_synergies() -> void:
	if _fossils_bloomed:
		return

	if summon.level > 0:
		await bloom()
		_fossils_bloomed = true


func run_after_evolve() -> void:
	pass


func bury_fossils():
	print("Высаживаются человечки и закапывают светящиеся кристаллы в землю")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(1.9))
	await tween.finished

	_ship_path_follow.remove_child(_ship)
	_ship_path_follow_2.add_child(_ship)
	tween = create_tween()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, Helpers.aligned_to_planet(_ship)), Helpers.duration(.5))
	await tween.finished
	_align_ship_to_planet = true

	await _ship.drop_crystals()

	tween = create_tween()
	tween.tween_property(_ship_path_follow_2, "progress", _path.curve.get_closest_offset(_path.curve.get_point_position(1)), Helpers.duration(2))
	await tween.finished
	await _ship.drop_crystals()

	tween = create_tween()
	tween.tween_property(_ship_path_follow_2, "progress", _path.curve.get_closest_offset(_path.curve.get_point_position(2)), Helpers.duration(2))

	await tween.finished
	await _ship.drop_crystals()

	tween = create_tween()
	tween.tween_property(_ship_path_follow_2, "progress", _path.curve.get_baked_length(), Helpers.duration(1))
	await tween.finished


	_ship_path_follow_2.remove_child(_ship)
	_ship_path_follow.add_child(_ship)
	_align_ship_to_planet = false
	tween = create_tween()
	tween.tween_property(_ship, "rotation:z", 0, Helpers.duration(1))

	tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(1.9))
	await tween.finished

func mineralization_occurred():
	print("Почва пригодна для жизни - нет текста в shuffle")
	_particles.emitting = true


func bloom():
	print("Минералы растут как грибы")
	await planet.grow_crystals()
	_particles.emitting = false
