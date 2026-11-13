extends Node3D
class_name ShipEnrichment


var liquid_tween: Tween
var hose_tween: Tween


func drain_liquid():
	if liquid_tween:
		liquid_tween.kill()
	liquid_tween = create_tween()
	liquid_tween.tween_property(self, "blend_shapes/liquid", 1, 1)
	await liquid_tween.finished


func prepare_hose():
	if hose_tween:
		hose_tween.kill()
	hose_tween = create_tween()
	hose_tween.tween_property(self, "blend_shapes/hose", 1, 1)
	await hose_tween.finished
