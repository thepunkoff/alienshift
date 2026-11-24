extends Entity
class_name Pvo

@export var relief: Relief
@export var life: Life
@export var planet: Planet

const STATE_SHIPS_APPROACHING := "ships_approaching"

@onready var _ship: ShipPvo = $Path3D/PathFollow3D/ShipPvo
@onready var _ship_path_follow: PathFollow3D = $Path3D/PathFollow3D
@onready var _meteor_path_follow: PathFollow3D = $Path3D2/PathFollow3D
@onready var _pvo: Node3D = $Pvo
@onready var _meteor: Node3D = $Path3D2/PathFollow3D/Meteor
@onready var _bullet1_path_follow: PathFollow3D = $Path3D3/PathFollow3D
@onready var _bullet2_path_follow: PathFollow3D = $Path3D4/PathFollow3D
@onready var _bullet3_path_follow: PathFollow3D = $Path3D5/PathFollow3D
@onready var _explosion: Node3D = $Path3D2/PathFollow3D/Meteor/Explosion
@onready var _explosion_base: GPUParticles3D = $Path3D2/PathFollow3D/Meteor/Explosion/Base
@onready var _explosion_white: GPUParticles3D = $Path3D2/PathFollow3D/Meteor/Explosion/White

var _pvo_decided := false
var _pvo_installed := false
var _meteorites_shot := false
var _exploded := false


func _ready() -> void:
	register_states({
		1: State.create(STATE_SHIPS_APPROACHING),
	})


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SHIPS_APPROACHING:
			await ship_appear()


func run_synergies() -> void:
	if level == 0:
		return

	if not _pvo_decided:
		if relief.state.name == Relief.STATE_BOMBS_CREATED_RELIEF:
			await pvo_installed()
			_pvo_installed = true
		else:
			await pvo_flew_away()
		_pvo_decided = true

	if _pvo_installed and life.level == 1 and not _meteorites_shot:
		await throw_meteor()
		_meteorites_shot = true


func run_after_evolve() -> void:
	pass


func ship_appear() -> void:
	print("Корабли c ПВО системами подлетают к планете")
	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 1, Helpers.duration(3))
	await tween.finished


func pvo_installed() -> void:
	print("ПВО приземляются на горы, горы открываются как крышки, и ПВО устанавливаются в них")
	await planet.open_mountain()
	await _ship.drop_pvo()
	_pvo.show()

	var tween: Tween = create_tween()
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(3))
	await tween.finished


func pvo_flew_away() -> void:
	print("ПВО улетают, т.к. не находят гор, на которые можно приземлиться")
	var tween: Tween = create_tween()
	tween.tween_property(_ship, "rotation:y", deg_to_rad(40), Helpers.duration(.5))
	tween.tween_interval(Helpers.duration(.5))
	tween.tween_property(_ship, "rotation:y", deg_to_rad(-40), Helpers.duration(.5))
	tween.tween_interval(Helpers.duration(.5))
	tween.tween_property(_ship, "rotation:y", 0, Helpers.duration(.5))
	tween.tween_property(_ship_path_follow, "progress_ratio", 0, Helpers.duration(3))
	await tween.finished


func throw_meteor() -> void:
	print("Пролетает метеорит, ПВО его сбивает")

	const meteor_time: int = 6
	const bullet_time_base: int = 1
	var i: int = 0
	for pf: PathFollow3D in [_bullet1_path_follow, _bullet2_path_follow, _bullet3_path_follow]:
		var bullet: Node3D = pf.get_node("Bullet")
		var bullet_time: float = bullet_time_base + (2 - i) * 0.5
		var tween_bullet: Tween = create_tween()
		var delay: float = meteor_time - bullet_time
		tween_bullet.tween_interval(Helpers.duration(delay))
		tween_bullet.tween_callback(bullet.show)
		tween_bullet.tween_property(pf, "progress_ratio", 1, Helpers.duration(bullet_time))
		tween_bullet.tween_callback(bullet.hide)
		i += 1

	var tween: Tween = create_tween()
	tween.tween_property(_meteor_path_follow, "progress_ratio", 1, Helpers.duration(meteor_time))
	await tween.finished
	_explode()


func _look_at(a: Node3D, b: Node3D):
	var dst: Vector3 = a.global_position - b.global_position
	var rot: Quaternion = Quaternion(a.global_basis.y, dst)
	a.global_basis = a.global_basis * Basis(rot)


func _explode():
	var gpos: Vector3 = _explosion.global_position
	_meteor.remove_child(_explosion)
	add_child(_explosion)
	_explosion.global_position = gpos
	_meteor.hide()
	for bullet: Node3D in get_tree().get_nodes_in_group("bullet"):
		bullet.hide()

	_explosion_base.emitting = true
	_explosion_white.emitting = true
	set_process(false)
	_exploded = true
