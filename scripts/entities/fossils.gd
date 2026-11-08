extends Entity
class_name Fossils

const STATE_FOSSILS_BURIED: String = "fossils_buried"
const STATE_FOSSILS_BLOOMED: String = "fossils_bloomed"


func _ready():
	register_states({
		1: State.create(STATE_FOSSILS_BURIED),
		3: State.create(STATE_FOSSILS_BLOOMED)
	})


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_FOSSILS_BURIED:
			await bury_fossils()
		STATE_FOSSILS_BLOOMED:
			await bloom()
		_:
			push_error("Fossils state not expected: '%s'." % [new_state.name])


func run_synergies():
	pass


func bury_fossils():
	print("Astronauts bury fossils.")
	pass


func bloom():
	print("Fossils bloom into crystals.")
	pass