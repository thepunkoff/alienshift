extends Node3D
class_name Hammer

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _dust_particles: GPUParticles3D = $Dust
@onready var _hammer: Node3D = $Hammer


func _ready() -> void:
	_animation_player.root_node = _animation_player.get_path_to(_hammer)

func emit_building_dust():
	var puff := _dust_particles.duplicate() as GPUParticles3D
	add_child(puff)
	puff.finished.connect(puff.queue_free)
	puff.emitting = true

func enable_building():
	_animation_player.play("hit")


func disable_building():
	_animation_player.stop()
