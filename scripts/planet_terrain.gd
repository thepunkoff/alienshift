## Owns the procedural terrain settings for a planet mesh and pushes them into
## its ShaderMaterial and every next_pass (e.g. the outline), so all passes
## displace the terrain identically. Works live in the editor (@tool).
@tool
extends MeshInstance3D
class_name PlanetTerrain

@export_group("Terrain")
@export var terrain_enabled: bool = true:
	set(v): terrain_enabled = v; _apply()
@export var terrain_seed: int = 0:
	set(v): terrain_seed = v; _apply()
@export_range(0.0, 2.0, 0.005) var terrain_height: float = 0.5:
	set(v): terrain_height = v; _apply()
@export_range(0.1, 10.0, 0.005) var terrain_scale: float = 1.8:
	set(v): terrain_scale = v; _apply()
@export_range(0.0, 1.0, 0.001) var sea_level: float = 0.45:
	set(v): sea_level = v; _apply()
@export_range(0.05, 6.0, 0.005) var mountain_sharpness: float = 1.5:
	set(v): mountain_sharpness = v; _apply()
@export_range(1, 8) var terrain_octaves: int = 5:
	set(v): terrain_octaves = v; _apply()
@export_range(0.0, 1.0, 0.001) var seabed_relief: float = 0.15:
	set(v): seabed_relief = v; _apply()

@export_group("Normals (coloring)")
@export_range(0.0, 8.0, 0.001) var normal_strength: float = 1.0:
	set(v): normal_strength = v; _apply()
@export_range(0.0005, 0.1, 0.0005) var normal_epsilon: float = 0.02:
	set(v): normal_epsilon = v; _apply()
@export_range(1, 8) var normal_octaves: int = 2:
	set(v): normal_octaves = v; _apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if mesh == null:
		return
	var params := {
		"terrain_enabled": terrain_enabled,
		"terrain_seed": terrain_seed,
		"terrain_height": terrain_height,
		"terrain_scale": terrain_scale,
		"sea_level": sea_level,
		"mountain_sharpness": mountain_sharpness,
		"terrain_octaves": terrain_octaves,
		"seabed_relief": seabed_relief,
		"normal_strength": normal_strength,
		"normal_epsilon": normal_epsilon,
		"normal_octaves": normal_octaves,
	}
	var mat: Material = material_override if material_override else get_active_material(0)
	while mat != null:
		if mat is ShaderMaterial:
			for key in params:
				mat.set_shader_parameter(key, params[key])
		mat = mat.next_pass
