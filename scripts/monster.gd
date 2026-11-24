extends Node3D
class_name Monster

signal eaten
signal started_eating

@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _slime: GPUParticles3D = $Slime

func sniff():
	_animation_tree.set("parameters/Transition/transition_request", "state_0")
	_animation_tree.active = true
	await _animation_tree.animation_finished
	_slime.emitting = true
	_animation_tree.active = false


func eat():
	_animation_tree.set("parameters/Transition/transition_request", "state_1")
	_animation_tree.active = true
	get_tree().create_timer(Helpers.duration(1.38)).timeout.connect(started_eating.emit)
	await _animation_tree.animation_finished
	_animation_tree.active = false
	eaten.emit()
