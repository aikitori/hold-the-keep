class_name Board
extends RefCounted
## Spielfeld-Logik: welche Zelle frei ist, wo Türme stehen und welchen Weg die Gegner nehmen.
## Gegner laufen vom Friedhof zur Burg, auch schräg, aber nicht zwischen zwei Türmen hindurch
## (keine Ecken schneiden). Ein Turm darf den Weg nie ganz versperren.

signal changed

enum BuildCheck { OK, NOT_GRASS, OCCUPIED, ENEMY_THERE, BLOCKS_PATH }

var map: MapData
var towers: Dictionary = {}  # Vector2i -> Tower (oder true in Tests)
var _astar := AStarGrid2D.new()


func _init(map_data: MapData) -> void:
	map = map_data
	_astar.region = Rect2i(Vector2i.ZERO, map.size)
	_astar.cell_size = Vector2.ONE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()
	for y in map.size.y:
		for x in map.size.x:
			var at := Vector2i(x, y)
			_astar.set_point_solid(at, not walkable_terrain(at))


func walkable_terrain(at: Vector2i) -> bool:
	return map.cell(at) != MapData.Cell.BLOCKED


func walkable(at: Vector2i) -> bool:
	return walkable_terrain(at) and not towers.has(at)


## Weg als Zellenliste von `from` bis zur Burg; leer, wenn es keinen gibt.
func path_from(from: Vector2i) -> Array[Vector2i]:
	if not walkable(from):
		from = nearest_walkable(from)
	return _astar.get_id_path(from, map.keep)


func path_length(path: Array[Vector2i]) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += Vector2(path[i] - path[i - 1]).length()
	return total


func nearest_walkable(at: Vector2i) -> Vector2i:
	if walkable(at):
		return at
	for radius in range(1, 4):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var other := at + Vector2i(dx, dy)
				if walkable(other):
					return other
	return map.spawn


## Darf hier gebaut werden? `enemy_cells`: Zellen, auf denen gerade Gegner stehen.
func check_build(at: Vector2i, enemy_cells: Array[Vector2i] = []) -> BuildCheck:
	if map.cell(at) != MapData.Cell.GRASS:
		return BuildCheck.NOT_GRASS
	if towers.has(at):
		return BuildCheck.OCCUPIED
	if enemy_cells.has(at):
		return BuildCheck.ENEMY_THERE
	_astar.set_point_solid(at, true)
	var ok := not _astar.get_id_path(map.spawn, map.keep).is_empty()
	# Auch kein Gegner darf eingesperrt werden.
	for cell in enemy_cells:
		if not ok:
			break
		ok = not _astar.get_id_path(cell, map.keep).is_empty()
	_astar.set_point_solid(at, false)
	return BuildCheck.OK if ok else BuildCheck.BLOCKS_PATH


func place(at: Vector2i, tower: Variant) -> void:
	towers[at] = tower
	_astar.set_point_solid(at, true)
	changed.emit()


func remove(at: Vector2i) -> void:
	towers.erase(at)
	_astar.set_point_solid(at, not walkable_terrain(at))
	changed.emit()


static func cell_of(world: Vector3) -> Vector2i:
	return Vector2i(roundi(world.x), roundi(world.z))


static func world_of(at: Vector2i, height := 0.0) -> Vector3:
	return Vector3(at.x, height, at.y)
