extends Entity
class_name Landscape

const STATE_ADDED: String = "added"
const STATE_GREW: String = "grew"


@onready var _mountain_animation_player: AnimationPlayer = $Mountain/AnimationPlayer


func _ready():
	register_states({
		1: State.create(STATE_ADDED),
		2: State.create(STATE_GREW)
	})


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_ADDED:
			await change()
		STATE_GREW:
			await grow()
		_:
			push_error("PlanetCore state not expected: '%s'." % [new_state.name])


func run_synergies():
	pass


func change():
	_mountain_animation_player.play("appear")
	await _mountain_animation_player.animation_finished
	print("Landscape changed.")
	pass


func grow():
	_mountain_animation_player.play("grow")
	await _mountain_animation_player.animation_finished
	print("Landscape grew.")
	pass
