extends Entity
class_name Relief

const STATE_BOMBS_CREATED_RELIEF: String = "bombs_created_relief"

@onready var _mountain_animation_player: AnimationPlayer = $Mountain/AnimationPlayer

func _ready():
	register_states({
		1: State.create(STATE_BOMBS_CREATED_RELIEF)
	})


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_BOMBS_CREATED_RELIEF:
			await bombs_created_relief()
		_:
			push_error("PlanetCore state not expected: '%s'." % [new_state.name])


func run_synergies():
	pass


func bombs_created_relief():
	_mountain_animation_player.play("appear")
	await _mountain_animation_player.animation_finished
	print("Сбрасывают атомные бомбы, появляются впадины и горы")
	pass
