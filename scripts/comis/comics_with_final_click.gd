extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

const GAME_SCENE = "res://scenes/game.tscn"

var _animations_end = false

var _animations = [
	"frame1_show",
	"frame2_show",
	"frame3_show",
	"frame4_show",
	"final_text_show",
]

func _ready() -> void:
	for animation in _animations:
		animation_player.play(animation)
		await animation_player.animation_finished
	_animations_end = true

func _input(event: InputEvent) -> void:
	if !_animations_end: 
		return 
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_tree().change_scene_to_file(GAME_SCENE)	
