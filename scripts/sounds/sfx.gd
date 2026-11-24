extends Node2D

@export var sounds: Array[Sound] = []

func play(sound_name: StringName) -> void:
	for sound_entry in sounds:
		if sound_entry != null and sound_entry.name_sound == sound_name:
			if sound_entry.sound == null:
				return

			var player := AudioStreamPlayer.new()
			player.stream = sound_entry.sound
			player.finished.connect(player.queue_free)
			add_child(player)
			player.play()
			return
