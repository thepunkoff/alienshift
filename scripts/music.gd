extends Node

@onready var player: AudioStreamPlayer = $BackgroundMusic

func play() -> void:
	if not player.playing:
		player.play()
