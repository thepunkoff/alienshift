extends Node3D
class_name ShipEnrichment


var liquid_tween: Tween
var hose_tween: Tween
@onready var _mesh: MeshInstance3D = $ship_enrichment2/ship_enrichment
@onready var _particles: GPUParticles3D = $GPUParticles3D


func drain_liquid():
	if liquid_tween:
		liquid_tween.kill()
	_particles.emitting = true
	liquid_tween = create_tween()
	liquid_tween.tween_property(_mesh, "blend_shapes/liquid", 1, Helpers.duration(3))
	await liquid_tween.finished
	_particles.emitting = false


func prepare_hose():
	if hose_tween:
		hose_tween.kill()
	hose_tween = create_tween()
	hose_tween.tween_property(_mesh, "blend_shapes/hose", 1, Helpers.duration(1))
	await hose_tween.finished
