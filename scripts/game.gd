extends Node
class_name Game

@export var skip_animations: bool = false

@onready var _buttons_parent: Node = $CanvasLayer/HBoxContainer
@onready var _game_over_label: Label = $CanvasLayer/GameOverLabel
@onready var _try_again_button: Button = $CanvasLayer/TryAgainButton
@onready var _dark: ColorRect = $CanvasLayer/ColorRect
@onready var game_over_pictures: Control = $CanvasLayer/GameOverPictures

@onready var _entities: Array[Node] = get_tree().get_nodes_in_group("entity")

@onready var _planet_core_button: EntityButton = $CanvasLayer/HBoxContainer/Core
@onready var _planet_core: Core = $Core

@onready var _crystal_button: EntityButton = $CanvasLayer/HBoxContainer/Crystal
@onready var _crystal: Crystal = $Crystal

@onready var _relief_button: EntityButton = $CanvasLayer/HBoxContainer/Relief
@onready var _relief: Relief = $Relief

@onready var _climate_button: EntityButton = $CanvasLayer/HBoxContainer/Climate
@onready var _climate: Climate = $Climate

@onready var _construction_button: EntityButton = $CanvasLayer/HBoxContainer/Construction
@onready var _construction: Construction = $Construction

@onready var _enrichment_button: EntityButton = $CanvasLayer/HBoxContainer/Enrichment
@onready var _enrichment: Enrichment = $Enrichment

@onready var _purifying_button: EntityButton = $CanvasLayer/HBoxContainer/Purifying
@onready var _purifying: Purifying = $Purifying

@onready var _pvo_button: EntityButton = $CanvasLayer/HBoxContainer/Pvo
@onready var _pvo: Pvo = $Pvo

@onready var _life_button: EntityButton = $CanvasLayer/HBoxContainer/Life
@onready var _life: Life = $Life

@onready var _summon_button: EntityButton = $CanvasLayer/HBoxContainer/Summon
@onready var _summon: Summon = $Summon

@onready var _button_entities: Dictionary[EntityButton, Entity] = {
	_planet_core_button: _planet_core,
	_crystal_button: _crystal,
	_relief_button: _relief,
	_climate_button: _climate,
	_construction_button: _construction,
	_enrichment_button: _enrichment,
	_purifying_button: _purifying,
	_pvo_button: _pvo,
	_life_button: _life,
	_summon_button: _summon,
}

@export var correct_order: Array[EntityButton] = []

var _end_game_started := false
var _current_button_order: int = 1

func _ready() -> void:
	for button in _button_entities:
		button.pressed.connect(_activate.bind(button))
	_summon.planet_eaten.connect(_end_game)
	_game_over_label.visible_ratio = 0
	_try_again_button.self_modulate.a = 0
	_try_again_button.pressed.connect(get_tree().reload_current_scene)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed == true:
		_end_game()
	if event is InputEventKey and event.keycode == KEY_0 and event.pressed == true:
		_end_game_test(true)	
	if event is InputEventKey and event.keycode == KEY_1 and event.pressed == true:
		_end_game_test(false)		


func _activate(button: EntityButton) -> void:
	if _end_game_started:
		return

	button.set_pressed_order(_current_button_order)
	_current_button_order += 1

	button.set_meta("used", true)
	for b in _button_entities:
		b.disabled = true
	var entity: Entity = _button_entities[button]
	await entity.level_up()
	if _end_game_started:
		return
	await _evolve(entity)
	if _end_game_started:
		return
	if not await _try_end_game():
		for b in _button_entities:
			b.disabled = b.get_meta("used", false)


func _evolve(except: Entity) -> void:
	for entity: Entity in _entities:
		if entity != except and entity.level > 0:
			await entity.level_up()
			if _end_game_started:
				return

	for entity: Entity in _entities:
		if entity.level > 0:
			await entity.run_synergies()
			if _end_game_started:
				return

	for entity: Entity in _entities:
		if entity.level > 0:
			await entity.run_after_evolve()
			if _end_game_started:
				return


func _try_end_game():
	for b: EntityButton in _buttons_parent.get_children():
		if not b.get_meta("used", false):
			return false

	await _end_game()
	return true


func _end_game():
	if _end_game_started:
		return
	_end_game_started = true

	var is_win = _is_order_correct()

	if is_win:
		print("win")
		_game_over_label.text = "You Win!"

	game_over_pictures.play_game_over(is_win)

	var i: int = 0
	for b: EntityButton in _buttons_parent.get_children():
		b.disabled = false
		b.button.disabled = true
		b.enable_score(i * 0.1)
		i += 1

	var tween: Tween = create_tween()
	tween.tween_property(_game_over_label, "visible_ratio", 1, 2)
	tween.parallel()
	tween.tween_property(_dark, "color", Color.html("#00000040"), 0.7)
	tween.tween_property(_try_again_button, "self_modulate:a", 1, 0.7)
	await tween.finished

	_end_game_started = false

func _end_game_test(is_win: bool):
	if _end_game_started:
		return
	_end_game_started = true

	if is_win:
		print("win")
		_game_over_label.text = "You Win!"

	game_over_pictures.play_game_over(is_win)

	var i: int = 0
	for b: EntityButton in _buttons_parent.get_children():
		b.disabled = false
		b.button.disabled = true
		b.enable_score(i * 0.1)
		i += 1

	var tween: Tween = create_tween()
	tween.tween_property(_game_over_label, "visible_ratio", 1, 2)
	tween.parallel()
	tween.tween_property(_dark, "color", Color.html("#00000040"), 0.7)
	tween.tween_property(_try_again_button, "self_modulate:a", 1, 0.7)
	await tween.finished

	_end_game_started = false

func _is_order_correct() -> bool:
	for press in correct_order.size():
		if correct_order[press].get_meta("order", -1) != press + 1:
			return false
	return true
