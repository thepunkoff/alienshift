extends PanelContainer

@onready var volume_slider: HSlider = $HBoxContainer/VolumeSlider
@onready var mute_button: Button = $HBoxContainer/MuteButton

const ICON_MUTE = preload("uid://dwol28fowafaw")
const ICON_SPEAKER = preload("uid://bklc7afb3rab1")
const MASTER_BUS_NAME := "Master"
const DEFAULT_VOLUME := 70.0
const MAX_VOLUME := 100.0

var muted := false


func _ready() -> void:
	volume_slider.value = DEFAULT_VOLUME

	mute_button.icon = ICON_SPEAKER
	mute_button.pressed.connect(_toggle_mute)
	volume_slider.value_changed.connect(_change_volume)

	_change_volume(volume_slider.value)


func _change_volume(value: float) -> void:
	var bus_index := AudioServer.get_bus_index(MASTER_BUS_NAME)
		
	_set_muted(value == 0.0)

	if value > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value / MAX_VOLUME))

func _toggle_mute() -> void:
	if is_zero_approx(volume_slider.value) && muted == true:
		return
	_set_muted(not muted)

func _set_muted(value: bool) -> void:
	muted = value
	var bus_index := AudioServer.get_bus_index(MASTER_BUS_NAME)
	AudioServer.set_bus_mute(bus_index, muted)
	mute_button.icon = ICON_MUTE if muted else ICON_SPEAKER
