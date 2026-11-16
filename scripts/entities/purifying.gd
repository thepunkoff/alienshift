extends Entity
class_name Purifying

@export var core: Core

const STATE_RADIATION_CLEANSING := "radiation_cleansing"

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

func cleanse_with_radiation() -> void:
	print("Огромный корабль-пушка прилетает и облучает планету радиацией")

func cleanse_core() -> void:
	print("Огромный корабль-пушка облучает ядро")
	
