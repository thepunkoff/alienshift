extends Node

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func play_game_over(is_win: bool) -> void:
	var up := "up_win" if is_win else "up_loss"
	var loop := "win" if is_win else "loss"

	animation_player.play(up)
	await animation_player.animation_finished
	animation_player.play(loop)
