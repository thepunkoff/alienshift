extends Node

@onready var _buttons_parent: Node = $CanvasLayer/HBoxContainer
@onready var _game_over_label: Label = $CanvasLayer/GameOverLabel
@onready var _entities: Array[Node] = get_tree().get_nodes_in_group("entity")

@onready var _planet_core_button: EntityButton = $CanvasLayer/HBoxContainer/Core
@onready var _planet_core: PlanetCore = $PlanetCore

@onready var _fossils_button: EntityButton = $CanvasLayer/HBoxContainer/Crystal
@onready var _fossils: Fossils = $Fossils

@onready var _landscape_button: EntityButton = $CanvasLayer/HBoxContainer/Relief
@onready var _landscape: Landscape = $Landscape

var _current_button_order: int = 1


func _ready() -> void:
	_planet_core_button.pressed.connect(planet_core, CONNECT_ONE_SHOT)
	_fossils_button.pressed.connect(fossils, CONNECT_ONE_SHOT)
	_landscape_button.pressed.connect(landscape, CONNECT_ONE_SHOT)


# func _input(event: InputEvent) -> void:
# 	if event is InputEventKey and event.keycode == KEY_SPACE and event.pressed == true:
# 		_end_game()


func planet_core():
	_planet_core_button.set_pressed_order(_current_button_order)
	_current_button_order += 1
	_planet_core_button.disabled = true
	await _planet_core.level_up()
	await _evolve_except(_planet_core)
	await _try_end_game()


func fossils():
	_fossils_button.set_pressed_order(_current_button_order)
	_current_button_order += 1
	_fossils_button.disabled = true
	await _fossils.level_up()
	await _evolve_except(_fossils)
	await _try_end_game()


func landscape():
	_landscape_button.set_pressed_order(_current_button_order)
	_current_button_order += 1
	_landscape_button.disabled = true
	await _landscape.level_up()
	await _evolve_except(_landscape)
	await _try_end_game()


func _evolve_except(except: Entity):
	var to_evolve: Array[Node] =  _entities.filter(func(x: Entity): return x != except)

	for entity: Entity in to_evolve:
		if entity.level > 0:
			await entity.level_up()

	for entity: Entity in to_evolve:
		await entity.run_synergies()


func _try_end_game():
	for b: EntityButton in _buttons_parent.get_children():
		if not b.disabled:
			return

	await _end_game()


func _end_game():
	var tween: Tween = create_tween()
	tween.tween_property(_game_over_label, "visible_ratio", 1, 2)
	await tween.finished

	var i: int = 0
	for b: EntityButton in _buttons_parent.get_children():
		b.disabled = false
		b.enable_score(i * 0.1)
		i += 1
