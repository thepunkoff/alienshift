extends Entity
class_name Construction

@export var life : Life

const STATE_HOUSES_LOWERED := "houses_lowered"

var _added_people = false

func _ready() -> void:
	register_states({
		1: State.create(STATE_HOUSES_LOWERED),
	})

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_HOUSES_LOWERED:
			await lower_houses()

func run_synergies() -> void:
	if _added_people:
		return 
		
	if life.state.name == Life.STATE_SOW_SEEDS:
		await added_people()
	
	_added_people = true		

func lower_houses() -> void:
	print("Спускаются дома на краниках")
	pass
	
func added_people() -> void:
	print("Людишки выбегают из прилетевших домиков")
	pass	
