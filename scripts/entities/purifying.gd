extends Entity
class_name Purifying

@export var core: Core

const STATE_RADIATION_CLEANSING := "radiation_cleansing"

@onready var _ship: ShipPurifying = $Path3D/PathFollow3D/ShipPurifying
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _path: Path3D = $Path3D
@onready var _core_purifying_position: Marker3D = $Marker3D

var _core_interaction_processed := false

func _ready() -> void:
	register_states({
		1: State.create(STATE_RADIATION_CLEANSING),
	})

	_ship_path_follow.progress_ratio = 0

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_RADIATION_CLEANSING:
			await cleanse_with_radiation()

func run_synergies() -> void:
	if _core_interaction_processed :
		return

	_core_interaction_processed = true
	if core.state.name == Core.STATE_CRACKED or core.state.name == Core.STATE_TAKEN_OUT:
		await cleanse_core()
		if  core.state.name == Core.STATE_TAKEN_OUT:
			await core.core_dimmed()

	await _fly_away();


func run_after_evolve() -> void:
	pass


func cleanse_with_radiation() -> void:
	print("Огромный корабль-пушка прилетает и облучает планету радиацией")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(2))
	await tween.finished

	tween = create_tween()
	tween.tween_property(_ship, "global_basis", Helpers.aligned_to_planet(_ship), Helpers.duration(.5))
	await tween.finished

	await _ship.enable_ray()
	await get_tree().create_timer(Helpers.duration(2)).timeout


func cleanse_core() -> void:
	print("Огромный корабль-пушка облучает ядро")
	await _ship.disable_ray()

	var tween: Tween = create_tween()
	var spot: Vector3 = _core_purifying_position.global_position
	var aim: Basis = Helpers.aligned_to(_ship, core.get_node("Core").global_position, spot)
	tween.tween_property(_ship, "global_position", spot, Helpers.duration(.5))
	tween.tween_property(_ship, "global_basis", aim, Helpers.duration(.5))
	await tween.finished

	await _ship.enable_ray()
	await core.core_purified()


func _fly_away():
	await _ship.disable_ray()

	var tween: Tween = create_tween()
	tween.tween_property(_ship, "position", Vector3.ZERO, Helpers.duration(.5))
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween.parallel()
	tween.tween_property(_ship, "rotation:z", 0, Helpers.duration(.5))
	await tween.finished
