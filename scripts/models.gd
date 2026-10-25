class_name Models
extends RefCounted
## Lädt die Kenney-Modelle (assets/models/<paket>/<name>.glb) und baut daraus Türme und Gelände.

static var _scenes: Dictionary = {}
static var _meshes: Dictionary = {}
static var _faded_materials: Dictionary = {}  # Material -> durchsichtige Kopie


static func scene(key: String) -> PackedScene:
	if not _scenes.has(key):
		_scenes[key] = load("res://assets/models/%s.glb" % key)
	return _scenes[key]


static func make(key: String) -> Node3D:
	return scene(key).instantiate()


## Erstes Mesh des Modells samt seiner Lage im Modell (für MultiMesh bei vielen gleichen Kacheln).
static func mesh(key: String) -> Array:
	if not _meshes.has(key):
		var root := make(key)
		var found: MeshInstance3D = null
		for node in root.find_children("*", "MeshInstance3D", true, false):
			found = node
			break
		var local := Transform3D.IDENTITY
		var node: Node = found
		while node != null and node != root:
			local = (node as Node3D).transform * local
			node = node.get_parent()
		_meshes[key] = [found.mesh, local]
		root.free()
	return _meshes[key]


## Höhe eines Modells (oberste Kante), um Teile aufeinanderzustapeln.
static func height(node: Node3D) -> float:
	var top := 0.0
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var box := mi.get_aabb()
		var t := _relative(mi, node)
		top = maxf(top, (t * box.end).y)
		top = maxf(top, (t * box.position).y)
	return top


static func _relative(child: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var node: Node = child
	while node != null and node != root:
		t = (node as Node3D).transform * t
		node = node.get_parent()
	return t


## Alle Flächen eines Modells durchscheinend einfärben (Bauvorschau).
static func tint(root: Node3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for child in root.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).material_override = material
		(child as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Modell halb durchsichtig zeigen oder zurückstellen. Über material_override, weil die Durchsichtigkeit
## je Instanz im Compatibility-Renderer nicht wirkt.
static func fade(root: Node3D, on: bool) -> void:
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if not on:
			if mi.has_meta("unfaded"):
				mi.material_override = mi.get_meta("unfaded")
				mi.remove_meta("unfaded")
			continue
		if mi.has_meta("unfaded") or mi.mesh == null:
			continue
		var original := mi.material_override if mi.material_override != null else mi.get_active_material(0)
		if not original is BaseMaterial3D:
			continue
		mi.set_meta("unfaded", mi.material_override)
		if not _faded_materials.has(original):
			var faded := (original as BaseMaterial3D).duplicate() as BaseMaterial3D
			faded.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			faded.albedo_color.a *= 0.3
			_faded_materials[original] = faded
		mi.material_override = _faded_materials[original]
