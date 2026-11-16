extends Entity
class_name Crystal

@export var summon: Summon

const STATE_FOSSILS_BURIED: String = "fossils_buried"
const STATE_MINERALIZATION_OCCURRED: String = "mineralization_occurred"

func _ready():
	register_states({
		1: State.create(STATE_FOSSILS_BURIED),
		7: State.create(STATE_MINERALIZATION_OCCURRED)
	})

var _fossils_bloomed: bool = false

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_FOSSILS_BURIED:
			await bury_fossils()
		STATE_MINERALIZATION_OCCURRED:
			await mineralization_occurred()
		_:
			push_error("Fossils state not expected: '%s'." % [new_state.name])


func run_synergies():
	if _fossils_bloomed:
		return

	if 	summon.level > 0:
		await bloom()
		_fossils_bloomed = true


func bury_fossils():
	print("Высаживаются человечки и закапывают светящиеся кристаллы в землю")
	pass

func mineralization_occurred():
	print("Почва пригодна для жизни - нет текста в shuffle")
	pass

func bloom():
	print("Минералы растут как грибы")
	pass
