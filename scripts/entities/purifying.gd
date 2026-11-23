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

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_RADIATION_CLEANSING:
			await cleanse_with_radiation()

func run_synergies():
	if _core_interaction_processed :
		return

	_core_interaction_processed = true
	if core.state.name == Core.STATE_CRACKED or core.state.name == Core.STATE_TAKEN_OUT:
		await cleanse_core()
		if  core.state.name == Core.STATE_TAKEN_OUT:
			await core.core_dimmed()

	await _fly_away();

func cleanse_with_radiation() -> void:
	print("Огромный корабль-пушка прилетает и облучает планету радиацией")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, 3)
	await tween.finished

	await _ship.enable_ray()
	await get_tree().create_timer(2).timeout


func cleanse_core() -> void:
	print("Огромный корабль-пушка облучает ядро")
	await _ship.disable_ray()

	var tween: Tween = create_tween()
	tween.tween_property(_ship, "global_position", _core_purifying_position.global_position, .5)
	tween.tween_property(_ship, "rotation", _core_purifying_position.rotation, .5)
	await tween.finished

	await _ship.enable_ray()
	await core.core_purified()


func _fly_away():
	await _ship.disable_ray()

	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress", _path.curve.get_closest_offset(_path.curve.get_point_position(3)), .5)
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, 3)
	tween.parallel()
	tween.tween_property(_ship, "rotation", Vector3.ONE, .5)
	await tween.finished
