extends Entity
class_name Summon

signal planet_eaten

@export var core: Core
@export var climate: Climate

const STATE_MONSTER_SUMMONED := "monster_summoned"
const STATE_WATER_SPREAD_ACCROSS_PLANET := "water_spread_across_planet"

var _water_vaporated: bool = false

@onready var _ship: ShipSummon = $Path3D/PathFollow3D/ShipSummon
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D


func _ready() -> void:
	register_states({
		1: State.create(STATE_MONSTER_SUMMONED),
		2: State.create(STATE_WATER_SPREAD_ACCROSS_PLANET),
	})

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
		await water_vaporated()
		_water_vaporated = true


func summon_monster() -> void:
	print("Чуваки-шаманы призывают огромного космического монстра, и тот рыгает зеленую жижу на землю лужами")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, 3)
	await tween.finished

	await _ship.summon_monster()

	if core.state.name != Core.STATE_PUT_INSIDE:
		await monster_eated_planet() ##вызываться конец игры

func water_spread_accross_planet() -> void:
	print("Вода распространилась по планете")
	pass

func monster_eated_planet() -> void:
	print("Монстр съедает планету")
	planet_eaten.emit()
	pass

func water_vaporated() -> void:
	print("Вода испаряется, т.к. климат хуевый")
	pass
