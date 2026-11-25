extends Entity
class_name Summon

signal planet_eaten

@export var core: Core
@export var climate: Climate
@export var planet: Planet

const STATE_MONSTER_SUMMONED := "monster_summoned"
const STATE_WATER_SPREAD_ACCROSS_PLANET := "water_spread_across_planet"

var _water_vaporated: bool = false
var _monster_waiting: bool = false

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


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_MONSTER_SUMMONED:
			await summon_monster()
		STATE_WATER_SPREAD_ACCROSS_PLANET:
			await water_spread_accross_planet()


func run_synergies() -> void:
	if not _water_vaporated and state.name == STATE_WATER_SPREAD_ACCROSS_PLANET and climate.level == 0:
		await water_evaporated()
		_water_vaporated = true


func summon_monster() -> void:
	print("Чуваки-шаманы призывают огромного космического монстра, и тот рыгает зеленую жижу на землю лужами")
	SFX.play("monster_summon")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(3))
	await tween.finished

	await _ship.summon_monster()
	create_tween().tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(3))
	tween = create_tween()
	tween.tween_property(_monster_path_follow, "progress_ratio", 1, Helpers.duration(2))
	await tween.finished

	await _monster_visit()
	# _monster_waiting = true


func run_after_evolve() -> void:
	pass
	# if _monster_waiting:
	# 	await _monster_visit()
	# 	_monster_waiting = false


func _monster_visit() -> void:
	if core.state.name != Core.STATE_PUT_INSIDE:
		print("Монстр съедает планету")
		SFX.play("monster_roar")
		_monster.eat()
		await _monster.started_eating
		var tween: Tween = create_tween()
		tween.tween_property(_monster, "position", _monster.position + Vector3(0, -2, 0), Helpers.duration(0.2))
		tween.parallel()
		tween.tween_property(planet, "scale", Vector3.ONE * 0.001, Helpers.duration(0.2))
		await tween.finished
		await _monster.eaten
		planet_eaten.emit()
	else:
		await _monster.sniff()
		await get_tree().create_timer(Helpers.duration(1)).timeout
		var tween: Tween = create_tween()
		tween.tween_property(_monster_path_follow, "progress_ratio", 0, Helpers.duration(2))
		await tween.finished


func water_spread_accross_planet() -> void:
	print("Вода распространилась по планете")
	SFX.play("water")
	await planet.add_water()


func water_evaporated() -> void:
	print("Вода испаряется, т.к. климат плохой")
	SFX.play("evaporation")
	await planet.evaporate_water()
