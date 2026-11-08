## Keeps the 3D view framed like the UI on any screen shape.
## The UI uses stretch mode canvas_items + aspect "expand", which scales by
## min(width / base_width, height / base_height). This camera matches that:
## wide screens keep the vertical view, tall (portrait) screens keep the
## horizontal view, so the planet always fits and UI stays aligned with it.
extends Camera3D

## Vertical FOV at the project's base resolution.
@export var base_fov: float = 75.0

var _base_aspect: float


func _ready() -> void:
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	_base_aspect = float(w) / float(h)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.y <= 0.0:
		return
	if size.x / size.y >= _base_aspect:
		keep_aspect = Camera3D.KEEP_HEIGHT
		fov = base_fov
	else:
		# In KEEP_WIDTH mode fov is horizontal: use the base resolution's
		# horizontal FOV so the scene keeps the same width on screen.
		keep_aspect = Camera3D.KEEP_WIDTH
		fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov) * 0.5) * _base_aspect))
