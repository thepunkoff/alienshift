@tool
extends Control
class_name EntityButton

signal pressed

@onready var texture_rect: TextureRect = $Panel/MarginContainer/Button/TextureRect
@onready var button: Button = $Panel/MarginContainer/Button
@onready var panel: Panel = $Panel
@onready var score_label: Label = $Panel/Score

@onready var initial_button_pos_y: float = position.y

var hover_tween: Tween


@export var texture: Texture2D:
	set(value):
		texture = value
		if texture_rect:
			texture_rect.texture = value


var disabled: bool:
	get: return disabled
	set(value):
		disabled = value
		button.disabled = value
		panel.modulate = Color.GRAY if true else Color.WHITE


func enable_score(delay: float):
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(panel, "size:y", 115, 0.2)
	tween.parallel()
	tween.tween_property(panel, "position:y", -35, 0.2)
	tween.parallel()
	tween.tween_property(score_label, "self_modulate", Color.WHITE, 0.2)
	await tween.finished


func _ready() -> void:
	texture_rect.texture = texture
	button.pressed.connect(pressed.emit)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	var pos_y: float = position.y
	hover_tween.tween_property(self, "position:y", pos_y - 5, 0.1)


func _on_mouse_exited():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "position:y", initial_button_pos_y, 0.1)
