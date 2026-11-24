@tool
extends Entity
class_name Relief

const STATE_BOMBS_CREATED_RELIEF: String = "bombs_created_relief"

@export var planet: Planet

@onready var _ship: ShipRelief = $Path3D/PathFollow3D/ShipRelief
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D

@onready var _ship_2: ShipRelief = $Path3D2/PathFollow3D/ShipRelief
@onready var _ship_path_follow_2: PathFollow3D = $Path3D2/PathFollow3D

func _align_ship_to_sphere() -> void:
	_ship.global_basis = Helpers.aligned_to_planet(_ship)
	_ship_2.global_basis = Helpers.aligned_to_planet(_ship_2)

@export_tool_button("Align Ship To Planet")
var align_houses_action: Callable = _align_ship_to_sphere

func _ready():
	register_states({
		1: State.create(STATE_BOMBS_CREATED_RELIEF)
	})

	_ship_path_follow.progress_ratio = 0
	_ship_path_follow_2.progress_ratio = 0


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_BOMBS_CREATED_RELIEF:
			await bombs_created_relief()
		_:
			push_error("PlanetCore state not expected: '%s'." % [new_state.name])


func run_synergies() -> void:
	pass


func run_after_evolve() -> void:
	pass


func bombs_created_relief():
	print("Сбрасывают атомные бомбы, появляются впадины и горы")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(3))
	tween.parallel()
	tween.tween_property(_ship_path_follow_2, "progress_ratio", 1, Helpers.duration(3))
	await tween.finished

	tween = create_tween()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, Helpers.aligned_to_planet(_ship)), Helpers.duration(1))
	tween.parallel()
	tween.tween_property(_ship_2, "quaternion", Helpers.local_quaternion(_ship_2, Helpers.aligned_to_planet(_ship_2)), Helpers.duration(1))
	await tween.finished

	_ship.bomb_dropped.connect(planet.change_landscape)
	_ship.drop_bomb()
	await get_tree().create_timer(Helpers.duration(0.8)).timeout
	_ship_2.drop_bomb()
	await planet.landscape_changed

	tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(3))
	tween.parallel()
	tween.tween_property(_ship_path_follow_2, "progress_ratio", 0, Helpers.duration(3))
	tween.parallel()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, Basis.IDENTITY), Helpers.duration(1))
	tween.parallel()
	tween.tween_property(_ship_2, "quaternion", Helpers.local_quaternion(_ship_2, Basis.IDENTITY), Helpers.duration(1))
	await tween.finished
