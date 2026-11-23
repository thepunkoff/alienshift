@tool
extends Control
class_name EntityButton

signal pressed

@export var tip_text: String = ""

@onready var texture_rect: TextureRect = $Panel/MarginContainer/Button/TextureRect
@onready var button: Button = $Panel/MarginContainer/Button
@onready var panel: Panel = $Panel
@onready var score_label: Label = $Panel/Score
@onready var order_label: Label = $Panel/MarginContainer/Button/Order
@onready var tip_label: Label = $Tip
@onready var initial_button_pos_y: float = position.y

var hover_tween: Tween


@export var texture: Texture2D:
	set(value):
		texture = value
		if texture_rect:
			texture_rect.texture = value


var disabled: bool = false:
	get: return disabled
	set(value):
		disabled = value
		if button and panel and texture_rect:
			button.disabled = value
			panel.self_modulate = Color.GRAY if value else Color.WHITE
			texture_rect.self_modulate = Color.GRAY if value else Color.WHITE


func enable_score(delay: float):
	order_label.text = str(get_meta("order", ""))
	var tween: Tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_property(panel, "size:y", 115, 0.2)
	tween.parallel()
	tween.tween_property(panel, "position:y", -35, 0.2)
	tween.parallel()
	tween.tween_property(score_label, "self_modulate:a", 1, 0.2)
	tween.parallel()
	tween.tween_property(order_label, "self_modulate:a", 1, 0.2)
	tween.parallel()
	tween.tween_property(texture_rect, "self_modulate:a", 0.5, 0.2)
	await tween.finished


func set_pressed_order(order: int):
	set_meta("order", order)


func _ready() -> void:
	score_label.self_modulate.a = 0;
	order_label.self_modulate.a = 0;
	texture_rect.texture = texture
	button.pressed.connect(pressed.emit)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	tip_label.hide()
	tip_label.text = tip_text


func _on_mouse_entered():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	var pos_y: float = position.y
	hover_tween.tween_property(self, "position:y", pos_y - 5, 0.1)
	tip_label.show()


func _on_mouse_exited():
	if hover_tween:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "position:y", initial_button_pos_y, 0.1)
	tip_label.hide()
