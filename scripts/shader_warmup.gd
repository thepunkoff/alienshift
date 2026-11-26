## Прогрев шейдеров. В вебе (WebGL2 / GL Compatibility) шейдер компилируется синхронно в момент,
## когда объект с этим материалом впервые реально рисуется. Все корабли, монстр и частицы до
## первого использования находятся за кадром / с нулевым масштабом / скрыты, поэтому компиляция
## происходила посреди анимации и вызывала фриз.
##
## Этот узел на пару кадров ставит перед камерой копии всех мешей и частиц сцены (под непрозрачной
## заглушкой), чтобы все шейдеры скомпилировались заранее, а потом удаляет копии.
## Узлы, которые во время игры создают новые варианты материалов, могут реализовать метод
## [code]get_shader_warmup_nodes() -> Array[Node3D][/code] и вернуть готовые копии для прогрева.
extends Node
class_name ShaderWarmup

const WARMUP_FRAMES := 3
const OVERLAY_COLOR := Color(0.075, 0.055, 0.13, 1)
const FADE_DURATION := 0.2

## Скомпилированные программы живут в GL-контексте до перезагрузки страницы,
## поэтому после "Try again" повторный прогрев не нужен.
static var _done := false

## Корень сцены, который нужно прогреть.
var scene_root: Node


func _ready() -> void:
	if _done or scene_root == null:
		queue_free()
		return
	_done = true
	_run()


func _run() -> void:
	var overlay_layer := CanvasLayer.new()
	overlay_layer.layer = 128
	var overlay := ColorRect.new()
	overlay.color = OVERLAY_COLOR
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_layer.add_child(overlay)
	add_child(overlay_layer)

	var warm_root := Node3D.new()
	add_child(warm_root)
	var camera := get_viewport().get_camera_3d()
	if camera:
		warm_root.global_transform = camera.global_transform.translated_local(Vector3(0, 0, -2))

	var count := _populate(warm_root)
	print("Shader warm-up: %d instances" % count)

	for i in WARMUP_FRAMES:
		await RenderingServer.frame_post_draw

	warm_root.queue_free()

	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	queue_free()


func _populate(warm_root: Node3D) -> int:
	var seen := {}
	var count := 0
	for node in _all_descendants(scene_root):
		if node.has_method("get_shader_warmup_nodes"):
			for extra: Node3D in node.get_shader_warmup_nodes():
				_place(warm_root, extra)
				count += 1

		if not node is GeometryInstance3D:
			continue

		if node is MeshInstance3D:
			var mi := node as MeshInstance3D
			if mi.mesh == null:
				continue
			var key := _mesh_key(mi)
			if seen.has(key):
				continue
			seen[key] = true

			_place(warm_root, _wrap_skeleton(mi, _clone(mi) as MeshInstance3D))
			count += 1
			# Отдельный вариант с ненулевыми blend shapes (дрель, свет, рельеф и т.п.).
			if mi.get_blend_shape_count() > 0:
				var blended := _clone(mi) as MeshInstance3D
				for i in mi.get_blend_shape_count():
					blended.set_blend_shape_value(i, 0.5)
				_place(warm_root, _wrap_skeleton(mi, blended))
				count += 1
		else:
			var dup := _clone(node)
			if dup is GPUParticles3D or dup is CPUParticles3D:
				dup.set("one_shot", false)
				dup.set("emitting", true)
			_place(warm_root, dup)
			count += 1
	return count


## Копия узла без скриптов, групп, сигналов и детей.
func _clone(node: Node) -> Node3D:
	var dup := node.duplicate(0) as Node3D
	for child in dup.get_children():
		dup.remove_child(child)
		child.free()
	return dup


## Скиннинговым мешам нужен скелет, иначе не скомпилируется вариант шейдера со скиннингом.
func _wrap_skeleton(original: MeshInstance3D, dup: MeshInstance3D) -> Node3D:
	var skeleton := original.get_node_or_null(original.skeleton) as Skeleton3D
	if skeleton == null:
		return dup
	var skel_dup := _clone(skeleton) as Skeleton3D
	skel_dup.add_child(dup)
	dup.skeleton = NodePath("..")
	return skel_dup


func _place(warm_root: Node3D, node: Node3D) -> void:
	node.transform = Transform3D.IDENTITY
	node.visible = true
	warm_root.add_child(node)


func _mesh_key(mi: MeshInstance3D) -> String:
	var ids: Array = [
		mi.mesh.get_instance_id(),
		_id(mi.material_override),
		_id(mi.material_overlay),
		_id(mi.skin),
		mi.transparency > 0.0,
	]
	for i in mi.get_surface_override_material_count():
		ids.append(_id(mi.get_surface_override_material(i)))
	return str(ids)


func _id(obj: Object) -> int:
	return obj.get_instance_id() if obj else 0


func _all_descendants(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == self:
			continue
		result.append(n)
		stack.append_array(n.get_children())
	return result
