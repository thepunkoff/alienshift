extends Entity
class_name PlanetCore

# Выносим названия состояний в константы, чтобы можно было проверять эти состояния в синергиях.
const STATE_TAKEN_OUT: String = "taken_out"
const STATE_CRACKED: String = "cracked"
const STATE_PUT_INSIDE: String = "put_inside"

# Другие сущности для синергий
@export var fossils: Fossils
@export var landscape: Landscape

# Префабы нод для спавна (также их можно просто зашить в сцену игры и прятать)
# @export var core_prefab: PackedScene # сцена самого ядра
# @export var core_spaceship_prefab: PackedScene # сцена корабля, достающего ядро

# Зависимые сцены для управления и анимациий.
@onready var _core: MeshInstance3D = $Core  # нода самого ядра
@onready var _core_animation_player: AnimationPlayer = $Core/AnimationPlayer
# var _core_spaceship: CoreSpaceship # нода корабля, достающего ядро

var _shined: bool

func _ready():
	register_states({
		1: State.create(STATE_TAKEN_OUT), # первое состояние - всегда уровень 1!
		3: State.create(STATE_CRACKED),
		5: State.create(STATE_PUT_INSIDE)
	})


func run_level_up(new_lvl: int, new_state: State):
	# Тут простой левелап - достигли состояния, запускаем анимацию.
	# Для более сложных и интересных левелапов тут прокинут new_level - например можно будет просто менять цвет в промежуточных левелапах и анимировать без зависимости от состояния, а чисто для визуала.
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


func run_synergies():
	if _shined:
		return

	if fossils.state.name == Fossils.STATE_FOSSILS_BLOOMED and landscape.level >= landscape.get_level_by_name(Landscape.STATE_ADDED):
		await shine() # анимации и движения всегда ждем
		_shined = true


func shine():
	print("Planet core is shining.")


func take_out():
	_core_animation_player.play("take_out")
	await _core_animation_player.animation_finished
	print("Planet core taken out.")
	pass


func crack():
	var mat := _core.get_active_material(0).duplicate() as StandardMaterial3D
	_core.set_surface_override_material(0, mat)
	var tween: Tween = create_tween()
	tween.tween_property(mat, "albedo_color", Color.RED, 1.0)
	await tween.finished
	print("Planet core cracked.")
	pass


func put_inside():
	_core_animation_player.play_backwards("take_out")
	await _core_animation_player.animation_finished
	print("Planet core put back inside.")
	pass
