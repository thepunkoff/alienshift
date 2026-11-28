@tool
extends Entity
class_name Core

const STATE_TAKEN_OUT: String = "taken_out"
const STATE_CRACKED: String = "cracked"
const STATE_PUT_INSIDE: String = "put_inside"

@export var planet: Planet

@onready var _ship: ShipCore = $Path3D/PathFollow3D/ShipCore
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D

@onready var _core: MeshInstance3D = $Core  # нода самого ядра
@onready var _core_animation_player: AnimationPlayer = $Core/AnimationPlayer


func _align_ship_to_sphere() -> void:
	_ship.transform.basis = _aligned_to_planet(_ship)

func _extend_drill() -> void:
	_ship.extend_drill()

func _remove_drill() -> void:
	_ship.remove_drill()

@export_tool_button("Align Ship To Planet")
var align_houses_action: Callable = _align_ship_to_sphere

@export_tool_button("Extend Drill")
var extend_drill_action: Callable = _extend_drill

@export_tool_button("Remove Drill")
var remove_drill_action: Callable = _remove_drill


func _ready():
	if Engine.is_editor_hint():
		return

	register_states({
		1: State.create(STATE_TAKEN_OUT), # первое состояние - всегда уровень 1!
		2: State.create(STATE_CRACKED),
		5: State.create(STATE_PUT_INSIDE)
	})

	_ship_path_follow.progress_ratio = 0


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_TAKEN_OUT:
			await take_out() # анимации и движения всегда ждем
		STATE_CRACKED:
			await crack()
		STATE_PUT_INSIDE:
			await put_inside()
		_:
			push_error("PlanetCore state not expected: '%s'." % [new_state.name])


func run_synergies() -> void:
	pass


func run_after_evolve() -> void:
	pass


func take_out():
	print("Прилетает большой космический корабль, бурит скважину и достает ядро из планеты и зависает с ним")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(2))
	tween.tween_interval(Helpers.duration(0.5))
	await tween.finished

	tween = create_tween()
	tween.tween_property(_ship, "quaternion", Helpers.local_quaternion(_ship, _aligned_to_planet(_ship)), Helpers.duration(0.5))
	SFX.play("drill")
	await tween.finished

	await _ship.extend_drill()

	tween = create_tween()
	tween.tween_callback(_ship.enable_dust)
	tween.tween_interval(Helpers.duration(0.2))
	var init: Vector3 = _ship.position
	var target: Vector3 = _ship.position - _ship.transform.basis.y * 0.6
	tween.tween_property(_ship, "position", target, Helpers.duration(2))
	tween.tween_interval(Helpers.duration(0.5))
	tween.tween_property(_ship, "position", init, Helpers.duration(2))
	tween.tween_callback(_ship.disable_dust)
	await tween.finished

	await _ship.remove_drill()
	await _ship.enable_light()

	_core_animation_player.play("take_out")
	await get_tree().create_timer(1).timeout
	planet.add_dirt()

	SFX.play("core_light")
	await _core_animation_player.animation_finished

	_core_animation_player.play("bob")

	planet.entities_with_ships_near.append(self)


func escape_monster():
	_ship.disable_light()
	_core_animation_player.play_backwards("take_out")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween.parallel()
	tween.tween_property(_ship, "quaternion", Quaternion.IDENTITY, Helpers.duration(0.7))
	await tween.finished


func crack():
	print("Ядро трескается")
	SFX.play("crack")
	var mat := _core.get_active_material(0).duplicate() as ShaderMaterial
	_core.set_surface_override_material(0, mat)
	var tween: Tween = create_tween()
	tween.tween_property(mat, "shader_parameter/crack_amount", 1.0, 2.0)
	await tween.finished


func put_inside():
	print("Корабль возвращает ядро обратно")
	SFX.play("core_light")
	_core_animation_player.play_backwards("take_out")
	await _core_animation_player.animation_finished

	await _ship.disable_light()

	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(2))
	tween.parallel()
	tween.tween_property(_ship, "quaternion", Quaternion.IDENTITY, Helpers.duration(0.7))
	await tween.finished


func core_purified():
	var mat := _core.get_active_material(0)
	var tween: Tween = create_tween()
	tween.tween_property(mat, "shader_parameter/crack_amount", 0, 2.0)
	tween.parallel()
	tween.tween_property(mat, "shader_parameter/tint", Color.WHITE, 2.0)
	await tween.finished


func core_dimmed():
	print("Очищение рано сработало на ядро, ядро тускнеет")
	var mat := _core.get_active_material(0)
	var tween: Tween = create_tween()
	tween.tween_property(mat, "shader_parameter/desaturate", 0.8, 2.0)
	tween.parallel()
	tween.tween_property(mat, "shader_parameter/brightness", 0.5, 2.0)
	await tween.finished


func _aligned_to_planet(node: Node3D) -> Basis:
	var up := (node.global_position - Vector3.ZERO).normalized()
	var current_up := node.global_basis.y.normalized()
	var q := Quaternion(current_up, up)
	return Basis(q) * node.global_basis
