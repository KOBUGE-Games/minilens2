extends Node2D

const TileMapEntity = preload("res://objects/shared/tile_map_entity.gd")

onready var tile_map := $tile_map as TileMapEntity
onready var level_acid := $acid
var level_name := "Unnamed"

func _ready() -> void:
	pass #load_from_file("res://levels/test.level")

func clear() -> void:
	for child in get_children():
		if child.has_method("get_grid_position"):
			remove_child(child)
			child.queue_free()
	tile_map.clear()
	tile_map._update_positions()
	level_acid._update_acid()
	level_name = "Unnamed"

func clear_pos(pos: Vector2) -> void:
	if tile_map.get_cellv(pos) != -1:
		tile_map.set_cellv(pos, -1)
		tile_map.update_positions()
	level_acid.update_acid()
	
	for child in get_children():
		if child.has_method("get_grid_position"):
			if child.get_grid_position().distance_squared_to(pos) < 0.01:
				child.queue_free()

func get_pos(pos: Vector2) -> Dictionary:
	var result := {
		"tile": tile_map.get_cellv(pos) + 1, # +1 because IDs start at 0 but tile map starts at -1
		"entities": [],
		"entities_properties": []
	}
	
	for child in get_children():
		if child.has_method("get_grid_position"):
			if child.get_grid_position().distance_squared_to(pos) < 0.01:
				var child_filename: String = child.filename
				var entity_id: int = Objects.EntityByScenePath[child_filename]
				result.entities.push_back(entity_id)
				
				var properties := []
				if child.has_method("get_tile_properties"):
					properties = child.get_tile_properties()
				result.entities_properties.push_back(properties)
	
	return result

func add_tile(pos: Vector2, type: int) -> void:
	tile_map.set_cellv(pos, type - 1) # -1 because IDs start at 0 but tile map starts at -1
	tile_map.update_positions()
	level_acid.update_acid()

func add_entity(pos: Vector2, type: int, properties: Array = []) -> void:
	var scene_path: String = Objects.EntityData[type].scene_path
	
	var scene := load(scene_path) as PackedScene
	var instance := scene.instance() as Node2D
	instance.position = (pos + Vector2(0.5, 0.5)) * tile_map.cell_size
	if instance.has_method("set_tile_properties"):
		instance.call("set_tile_properties", properties)
	add_child(instance)
	assert(instance.get_grid_position().distance_squared_to(pos) < 0.01)
	level_acid.update_acid()

func remove_entity(pos: Vector2, type: int, properties: Array = []) -> void:
	for child in get_children():
		if child.has_method("get_grid_position"):
			if child.get_grid_position().distance_squared_to(pos) < 0.01:
				var filename: String = child.filename
				var scene_path: String = Objects.EntityData[type].scene_path
				var entity_properties: Array = []
				if child.has_method("get_tile_properties"):
					entity_properties = child.get_tile_properties()
				if scene_path == filename && entity_properties == properties:
					child.queue_free()


func get_bounds(ignore_acid: bool = false) -> Rect2:
	var bounds := Rect2()
	for cell in tile_map.get_used_cells():
		if ignore_acid and tile_map.get_cellv(cell) == tile_map.acid_tile:
			continue
		if bounds == Rect2():
			bounds = Rect2(cell, Vector2(0, 0))
		else:
			bounds = bounds.expand(cell)
	
	for child in get_children():
		var cell := Vector2()
		if child.has_method("get_grid_position"):
			cell = child.get_grid_position().round()
		elif child is Node2D and child.get_owner() != self:
			cell = tile_map.world_to_map(child.position)
		else:
			continue
		
		if bounds == Rect2():
			bounds = Rect2(cell, Vector2(0, 0))
		else:
			bounds = bounds.expand(cell)
	return bounds

func world_pos_to_grid_pos(pos: Vector2) -> Vector2:
	return (pos / tile_map.cell_size).floor()


func get_state() -> Dictionary:
	var tiles := {}
	
	# Collect information from the level
	
	for cell in tile_map.get_used_cells():
		var tile := tile_map.get_cellv(cell)
		if not tiles.has(cell):
			tiles[cell] = []
			
		if tile == tile_map.acid_tile:
			tiles[cell].push_back("acid")
		elif tile == tile_map.ladder_tile:
			tiles[cell].push_back("ladder")
		else:
			tiles[cell].push_back("solid")
	
	var children = get_children()
	children.sort_custom(self, "_position_sort")
	
	for child in children:
		if child.has_method("get_grid_position"):
			var cell: Vector2 = child.get_grid_position().round()
		
			if child.filename == "" or not Objects.EntityByScenePath.has(child.filename):
				print(child, child.filename)
				continue
			
			var entity_id: int = Objects.EntityByScenePath[child.filename]
			var definition := Objects.EntityData[entity_id].name as String
			
			if child.has_method("get_tile_properties"):
				for property in child.get_tile_properties():
					definition += ":" + property
			
			if not tiles.has(cell):
				tiles[cell] = []
			
			tiles[cell].push_back(definition)
	
	return {tiles = tiles, name = level_name}

func set_state(state: Dictionary, skip_equal: bool = false):
	if skip_equal and are_states_equal(get_state(), state):
		return
	clear()
	level_name = state.name
	var tiles = state.tiles
	for cell in tiles:
		for definition in tiles[cell]:
			var properties = Array(definition.split(":"))
			var object_name: String = properties.pop_front()
			if Objects.is_tile_name(object_name):
				add_tile(cell, Objects.TileByName[object_name])
			else:
				add_entity(cell, Objects.EntityByName[object_name], properties)
	
	tile_map._update_positions()
	level_acid._update_acid()

static func are_states_equal(state_a: Dictionary, state_b: Dictionary) -> bool:
	if state_a.name != state_b.name: return false
	if state_a.tiles.size() != state_b.tiles.size(): return false
	
	for cell in state_a.tiles:
		if not state_b.tiles.has(cell): return false
		if state_a.tiles[cell] != state_b.tiles[cell]: return false
	
	return true


func _position_sort(a: Node, b: Node) -> bool:
	if a is Node2D and b is Node2D:
		return a.global_position.y < b.global_position.y or (a.global_position.y == b.global_position.y and a.global_position.x < b.global_position.x)
	else:
		return int(a is Node2D) < int(b is Node2D)

