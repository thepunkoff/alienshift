extends Entity
class_name Summon

signal planet_eaten

@export var core: Core
@export var climate: Climate
@export var planet: Planet

const STATE_MONSTER_SUMMONED := "monster_summoned"
const STATE_WATER_SPREAD_ACCROSS_PLANET := "water_spread_across_planet"

var _water_vaporated: bool = false

@onready var _ship: ShipSummon = $Path3D/PathFollow3D/ShipSummon
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _monster: Monster = $Path3D2/PathFollow3D/Monster
@onready var _monster_path_follow: PathFollow3D = $Path3D2/PathFollow3D


func _ready() -> void:
	register_states({
		1: State.create(STATE_MONSTER_SUMMONED),
		2: State.create(STATE_WATER_SPREAD_ACCROSS_PLANET),
	})

	_ship_path_follow.progress_ratio = 0
	_monster_path_follow.progress_ratio = 0

	summon_monster()


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_MONSTER_SUMMONED:
			await summon_monster()
		STATE_WATER_SPREAD_ACCROSS_PLANET:
			await water_spread_accross_planet()


func run_synergies() -> void:
	if _water_vaporated:
		return

	if 	state.name == STATE_WATER_SPREAD_ACCROSS_PLANET and climate.level == 0:
		await water_evaporated()
		_water_vaporated = true


func summon_monster() -> void:
	print("Чуваки-шаманы призывают огромного космического монстра, и тот рыгает зеленую жижу на землю лужами")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, 3)
	await tween.finished

	await _ship.summon_monster()
	tween = create_tween()
	tween.tween_property(_monster_path_follow, "progress_ratio", 1, 2)
	tween.parallel()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, 3)
	await tween.finished

	if core.state.name == Core.STATE_PUT_INSIDE:
		print("Монстр съедает планету")
		_monster.eat()
		await _monster.started_eating
		tween = create_tween()
		tween.tween_property(_monster, "position", _monster.position + Vector3(0, -2, 0), 0.2)
		tween.parallel()
		tween.tween_property(planet, "scale", Vector3.ZERO, 0.2)
		await tween.finished
		await _monster.eaten
		planet_eaten.emit()
	else:
		await _monster.sniff()
		tween = create_tween()
		tween.tween_property(_monster_path_follow, "progress_ratio", 0, 2)
		await tween.finished


func water_spread_accross_planet() -> void:
	print("Вода распространилась по планете")
	await planet.add_water()


func water_evaporated() -> void:
	print("Вода испаряется, т.к. климат плохой")
	await planet.evaporate_water()
