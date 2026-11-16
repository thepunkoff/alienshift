extends Entity
class_name Enrichment

@export var crystal: Сrystal

const STATE_SLIME_ABSORBED := "slime_absorbed"
const STATE_VEGETATION_GROWN := "vegetation_grown"

func _ready() -> void:
	register_states({
		1: State.create(STATE_SLIME_ABSORBED),
		3: State.create(STATE_VEGETATION_GROWN),
	})

var _died_vegetation = false

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SLIME_ABSORBED:
			await enrich_soil()
		STATE_VEGETATION_GROWN:
			await grow_vegetation()

func run_synergies() -> void:
	if _died_vegetation:
		return
		
	if state.name == STATE_VEGETATION_GROWN and crystal.state.name != Сrystal.STATE_MINERALIZATION_OCCURRED:
		await died_vegetation()
		_died_vegetation = true

func enrich_soil() -> void:
	print("Прилетают машины со шлангами, льют розовую густую капающую жижу на планету, и она впитывается")
	pass

func grow_vegetation() -> void:
	print("Почва зеленеет, травка, цветочки")
	pass
	
func died_vegetation() -> void:
	print("Почва становится осенней, гнилой")
	pass	
