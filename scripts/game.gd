extends Node

@onready var _buttons_parent: Node = $CanvasLayer/HBoxContainer
@onready var _game_over_label: Label = $CanvasLayer/GameOverLabel

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
var _game_over_started := false
var _current_button_order: int = 1

func _ready() -> void:
	for button in _button_entities:
		button.pressed.connect(_activate.bind(button))
	_summon.planet_eaten.connect(_end_game)
	_game_over_label.visible_ratio = 0


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed == true:
		_end_game()


func _activate(button: EntityButton) -> void:
	button.set_pressed_order(_current_button_order)
	_current_button_order += 1
	button.disabled = true
	var entity: Entity = _button_entities[button]
	await entity.level_up()
	await _evolve(entity)
	await _try_end_game()


func _evolve(except: Entity) -> void:
	##сначала взаимодействия, потом в самом конце апаем уровни, чтобы к следующему клику у нас они были нужного уровня для работы с взаимодейстиями
	for entity: Entity in _entities:
		if entity.level > 0:
			await entity.run_synergies()

	for entity: Entity in _entities:
		if entity != except and entity.level > 0:
			await entity.level_up()

func _try_end_game():
	for b: EntityButton in _buttons_parent.get_children():
		if not b.disabled:
			return

	await _end_game()


func _end_game():
	if _game_over_started:
		return
	_game_over_started = true

	var tween: Tween = create_tween()
	tween.tween_property(_game_over_label, "visible_ratio", 1, 2)
	await tween.finished

	var i: int = 0
	for b: EntityButton in _buttons_parent.get_children():
		b.disabled = false
		b.enable_score(i * 0.1)
		i += 1
	_game_over_started = false
