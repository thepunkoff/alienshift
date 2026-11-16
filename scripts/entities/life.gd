extends Entity
class_name Life

@export var summon: Summon

const STATE_SOW_SEEDS := "sow_seeds"

var _added_water_life = false

func _ready() -> void:
	register_states({
		1: State.create(STATE_SOW_SEEDS)
	})

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SOW_SEEDS:
			await sow_seeds()

func run_synergies() -> void:
	if _added_water_life:
		return
		
	if state.name == STATE_SOW_SEEDS and summon.state.name == Summon.STATE_WATER_SPREAD_ACCROSS_PLANET:
		await added_water_life()
		
	_added_water_life = true

func sow_seeds() -> void:
	print("Человечки в скафандрах засеивают планету семенами жизни")
	pass
	
func added_water_life() -> void:
	print("Появляются водные существа")
	pass	
