extends Entity
class_name Pvo

@export var relief: Relief
@export var life: Life

const STATE_SHIPS_APPROACHING := "ships_approaching"

func _ready() -> void:
	register_states({
		1: State.create(STATE_SHIPS_APPROACHING),
	})

var _pvo_decided := false
var _pvo_installed := false
var _meteorites_shot := false


func run_level_up(new_lvl: int, new_state: State):
	if new_state == null:
		return

	match new_state.name:
		STATE_SHIPS_APPROACHING:
			await deploy_defense_ships()

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
		await shoot_meteorites()
		_meteorites_shot = true

func deploy_defense_ships() -> void:
	print("Корабли c ПВО системами подлетают к планете")
	pass
	
func pvo_installed() -> void:
	print("ПВО приземляются на горы, горы открываются как крышки, и ПВО устанавливаются в них")
	pass	
	
func pvo_flew_away() -> void:
	print("ПВО улетают, т.к. не находят гор, на которые можно приземлиться")
	pass

func shoot_meteorites() -> void:
	print("Пролетает метеорит, ПВО его сбивает")
