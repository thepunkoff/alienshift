@tool
extends Node3D
class_name ShipCore

var drill_tween: Tween
var light_tween: Tween

@onready var _mesh: MeshInstance3D = $ship_core2/ship_core
@onready var _dust: GPUParticles3D = $GPUParticles3D


func extend_drill():
	if drill_tween:
		drill_tween.kill()
	drill_tween = create_tween()
	drill_tween.tween_property(_mesh, "blend_shapes/drill", 1, Helpers.duration(1))
	await drill_tween.finished


func enable_dust():
	_dust.emitting = true


func disable_dust():
	_dust.emitting = false


func remove_drill():
	if drill_tween:
		drill_tween.kill()
	drill_tween = create_tween()
	drill_tween.tween_property(_mesh, "blend_shapes/drill", 0, Helpers.duration(1))
	await drill_tween.finished


func enable_light():
	if light_tween:
		light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property(_mesh, "blend_shapes/light", 1, Helpers.duration(1))
	await light_tween.finished


func disable_light():
	if light_tween:
		light_tween.kill()
	light_tween = create_tween()
	light_tween.tween_property(_mesh, "blend_shapes/light", 0, Helpers.duration(1))
	await light_tween.finished
