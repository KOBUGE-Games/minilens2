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

func are_states_equal(state_a: Dictionary, state_b: Dictionary) -> bool:
	if state_a.name != state_b.name: return false
	if state_a.tiles.size() != state_b.tiles.size(): return false
	
	for cell in state_a.tiles:
		if not state_b.tiles.has(cell): return false
		if state_a.tiles[cell] != state_b.tiles[cell]: return false
	
	return true


func save_to_file(path: String) -> bool:
	var state = get_state()
	var name_in_pack = state.name
	var tiles = state.tiles
	
	# Assign letters to tiles (can be combined with next pass)
	
	var bounds := Rect2()
	var definitions := {"air": "."}
	var characters_used := {".": true}
	for pos in tiles:
		var key = PoolStringArray(tiles[pos]).join(" + ")
		if not definitions.has(key):
			var picked_letter = pick_letter(tiles[pos], characters_used)
			characters_used[picked_letter] = true
			definitions[key] = picked_letter
		if bounds == Rect2():
			bounds = Rect2(pos, Vector2(0, 0))
		else:
			bounds = bounds.expand(pos)
	
	# Write everything out
	
	# TODO: Add logic for appending/replacing in pack
	var file := File.new()
	if file.open(path, File.WRITE) != OK:
		push_error("Couldn't open file '" + path + "'")
		return false
	file.store_line("[level " + name_in_pack + "]")
	
	for y in range(bounds.position.y, bounds.end.y + 1):
		var line = ""
		for x in range(bounds.position.x, bounds.end.x + 1):
			var pos = Vector2(x, y)
			if tiles.has(pos):
				line += definitions[PoolStringArray(tiles[pos]).join(" + ")]
			else:
				line += definitions["air"]
		file.store_line(line)
	
	file.store_line("")
	
	for definition in definitions:
		var line = definitions[definition] + " = " + definition
		file.store_line(line)
	
	file.close()
	return true

func load_from_file(path: String, name_in_pack: String = "") -> bool:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		push_error("Couldn't open file '" + path + "'")
		return false
	
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with("[level ") and line.ends_with("]"):
			var found_level_name := line.substr(7, line.length() - 8)
			if found_level_name == name_in_pack or name_in_pack == "":
				name_in_pack = found_level_name
				break
	
	# At level's tilemap now, continue parsing
	var raw_tiles := {}
	var size := Vector2()
	var y = 0
	while not file.eof_reached():
		var line := file.get_line()
		if (y > 0 and line.length() == 0) or line.find(" ") != -1:
			break
		if line != "":
			var x = 0
			for definition in line:
				raw_tiles[Vector2(x, y)] = definition
				x += 1
			y += 1
			size = Vector2(max(size.x, x), y)
	
	# At level's tile definitions now
	var definitions := {}
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "": continue
		if line[0] == "[" and (line[1] != " " or line[1] != "="): break
		
		var split_pos := line.find("=", 1)
		var tile := line[0]
		var definition := line.substr(split_pos + 1, line.length() - split_pos - 1).split("+")
		for i in range(definition.size()):
			definition[i] = definition[i].strip_edges()
		definitions[tile] = definition
	
	# Read what we needed to, close the file
	file.close()
	
	# Apply definitions to tiles
	var tiles := {}
	var offset := -(size / 2).floor()
	for cell in raw_tiles:
		if not definitions.has(raw_tiles[cell]):
			push_error("Unknown tile: " + raw_tiles[cell])
			continue
		tiles[cell + offset] = definitions[raw_tiles[cell]]
	
	set_state({tiles = tiles, name = name_in_pack})
	return true

func _position_sort(a: Node, b: Node) -> bool:
	if a is Node2D and b is Node2D:
		return a.global_position.y < b.global_position.y or (a.global_position.y == b.global_position.y and a.global_position.x < b.global_position.x)
	else:
		return int(a is Node2D) < int(b is Node2D)

func pick_letter(tiles: PoolStringArray, used: Dictionary) -> String:
	var scored_letters := {}
	
	for tile in tiles:
		var properties = Array(tile.split(":"))
		var object_name: String = properties.pop_front()
		var letters: String
		if Objects.is_tile_name(object_name):
			var id: int = Objects.TileByName[object_name]
			letters = Objects.TileData[id].letters
		else:
			var id: int = Objects.EntityByName[object_name]
			letters = Objects.EntityData[id].letters
			
		for i in range(letters.length()):
			var letter := letters[i]
			if !scored_letters.has(letter):
				scored_letters[letter] = 0
			scored_letters[letter] += letters.length() - i
	
	var best_letter_score := 0
	var best_letter := ""
	for letter in scored_letters:
		if !used.has(letter) and best_letter_score < scored_letters[letter]:
			best_letter = letter
			best_letter_score = scored_letters[letter]
	
	if best_letter != "":
		return best_letter
	
	for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz":
		if !used.has(letter):
			return letter
	
	assert(false)
	return " "
