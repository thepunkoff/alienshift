extends Node

@onready var _entities: Array[Node] = get_tree().get_nodes_in_group("entity")

@onready var _planet_core_button: Button = $PlanetCore/Button
@onready var _planet_core: PlanetCore = $PlanetCore

@onready var _fossils_button: Button = $Fossils/Button
@onready var _fossils: Fossils = $Fossils

@onready var _landscape_button: Button = $Landscape/Button
@onready var _landscape: Landscape = $Landscape


func _ready() -> void:
	_planet_core_button.pressed.connect(planet_core)
	_fossils_button.pressed.connect(fossils)
	_landscape_button.pressed.connect(landscape)


func planet_core():
	_planet_core_button.disabled = true
	await _planet_core.level_up()
	await evolve_except(_planet_core)


func fossils():
	_fossils_button.disabled = true
	await _fossils.level_up()
	await evolve_except(_fossils)


func landscape():
	_landscape_button.disabled = true
	await _landscape.level_up()
	await evolve_except(_landscape)


func evolve_except(except: Entity):
	var to_evolve: Array[Node] =  _entities.filter(func(x: Entity): return x != except)

	for entity: Entity in to_evolve:
		if entity.level > 0:
			await entity.level_up()

	for entity: Entity in to_evolve:
		await entity.run_synergies()
