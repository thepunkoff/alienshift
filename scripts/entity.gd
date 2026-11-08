## Класс, контролирующий все взаимодействия и анимации сущности. Сам по себе эта нода нематериальна, поэтому она должна иметь одну или несколько зависимых сцен, которыми будет дуправлять.
## Например, если эволюция сущности предполагает появление дополнительных объектов на экране (а не только главного), то их все все равно контролирует этот скрипт Entity, т.к. отвечает за одну эволюционную ветку.
@abstract
extends Node
class_name Entity

## Ключ - уровень, при достижении которого, считается, что сущность приобритает состояние под этим ключом.
## Значение - состояние, которое приобритает сущность по достижении уровня, равному ключу.
## Уровень 0 - состояние, когда сущность еще не была ни разу активирована.
## Уровень 1 - состояние сразу после первого появления.
var _states: Dictionary[int, State] = {
	0: State.DEFAULT,
}


## Текущий уровень сущности.
var level: int = 0


## Текущее состояние сущности.
var state: State = State.DEFAULT


## Регистрирует состояния сущности. [br]
## [param states]: Слоарь состояний. Ключ - уровень, при достижении которого, считается, что сущность приобритает состояние под этим ключом. Значение - состояние, которое приобритает сущность по достижении уровня, равному ключу.
## Уровень 0 (его регистрировать не надо) - состояние, когда сущность еще не была ни разу активирована.
## Уровень 1 - состояние сразу после первого появления. Всегда должен существовать и быть первым состоянием.
func register_states(states: Dictionary[int, State]):
	assert(states.keys()[0] == 1, "First registered state should have level 1.")

	_states.merge(states)

## Поднять уровень сущности и возможно изменить ее состояние.
func level_up():
	var old_level: int = level
	level = level + 1

	var old_state: State = state
	var new_state: State = null
	for key in _states:
		var s: State = _states[key]
		if level >= key:
			new_state = s
		else:
			break

	state = new_state

	var new_state_nullable: State = new_state if old_state.name != new_state.name else null
	var state_string: String = " New state: %s" % [new_state.name] if new_state_nullable != null else ""
	print("%s leveled up (%d -> %d)." % [name, old_level, level] + state_string)
	await run_level_up(level, new_state_nullable)


func get_level_by_name(n: String):
	for lvl in _states:
		var s: State = _states[lvl]
		if s.name == n:
			return lvl

	push_error("level by name '%s' not found in entity '%s'" % [n, name])
	return NAN # проваливает все проверки


@abstract func run_level_up(new_lvl: int, new_state: State)
@abstract func run_synergies()