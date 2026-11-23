extends Node

const SOUNDS := {
	"hit": preload("res://assets/music/sfx/sound-hitting-metal.wav")
}

func play(sound_name: StringName) -> void:
	var stream: AudioStream = SOUNDS.get(sound_name)
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()
