extends Entity
class_name Climate

const STATE_DOMES_INSTALLED := "domes_installed"
const STATE_ATMOSPHERE_FORMED := "atmosphere_formed"
const STATE_CLIMATE_STABILIZED := "climate_stabilized"

func _ready() -> void:
	register_states({
		1: State.create(STATE_DOMES_INSTALLED),
		3: State.create(STATE_ATMOSPHERE_FORMED),
		5: State.create(STATE_CLIMATE_STABILIZED),
	})

func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_DOMES_INSTALLED:
			await install_domes()
		STATE_ATMOSPHERE_FORMED:
			await form_atmosphere()
		STATE_CLIMATE_STABILIZED:
			await remove_domes()

func run_synergies() -> void:
	pass

func install_domes() -> void:
	print("Корабли прилетают и устанавливают купола")
	SFX.play("hit")
	pass

func form_atmosphere() -> void:
	print("Корабли закачивают дым в купола")
	pass

func remove_domes() -> void:
	print("Корабли снимают купола, атмосфера остаётся")
	pass
