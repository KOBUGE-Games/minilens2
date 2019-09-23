extends Node2D

const TileMapEntity = preload("res://objects/shared/tile_map_entity.gd")

const Objects = preload("res://objects/Objects.gd")

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

func add_tile(pos: Vector2, type: int) -> void:
	tile_map.set_cellv(pos, type-1)
	tile_map.update_positions()
	level_acid.update_acid()
	
func add_entity(pos: Vector2, type: int, properties: Array = []) -> void:
	var scene_path : String = Objects.EntityData[type].scene_path

	var scene := load(scene_path) as PackedScene
	var instance := scene.instance() as Node2D
	instance.position = (pos + Vector2(0.5, 0.5)) * tile_map.cell_size
	if instance.has_method("set_tile_properties"):
		instance.call("set_tile_properties", properties)
	add_child(instance)
	assert(instance.get_grid_position().distance_squared_to(pos) < 0.01)
	level_acid.update_acid()
	
	
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

func load_from_file(path: String, name_in_pack: String = "") -> void:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		return
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with("[level ") and line.ends_with("]"):
			var found_level_name := line.substr(7, line.length() - 8)
			if found_level_name == name_in_pack or name_in_pack == "":
				level_name = found_level_name
				break
	# At level's tilemap now, continue parsing
	var map_lines := []
	while not file.eof_reached():
		var line := file.get_line()
		if (map_lines.size() > 0 and line.length() == 0) or line.find(" ") != -1:
			break
		if line != "":
			map_lines.push_back(line)
	
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
	
	clear()
	
	# Build level
	for y in range(map_lines.size()):
		for x in range(map_lines[y].length()):
			if not definitions.has(map_lines[y][x]):
				push_error("Unknown tile: " + map_lines[y][x])
				continue
			
			for definition in definitions[map_lines[y][x]]:
				var properties = Array(definition.split(":"))
				var object_name : String = properties.pop_front()
				if Objects.is_tile_name(object_name) :
					add_tile(Vector2(x, y), Objects.TileByName[object_name] )
				else:
					add_entity(Vector2(x, y), Objects.EntityByName[object_name], properties)
	
	tile_map._update_positions()
	level_acid._update_acid()

func save_to_file(path: String, name_in_pack: String = "") -> void:
	if name_in_pack == "":
		name_in_pack = level_name
	else:
		level_name = name_in_pack
	
	var tiles := {}
	
	# Collect information from the level
	
	for cell in tile_map.get_used_cells():
		var tile := tile_map.get_cellv(cell)
		if !tiles.has(cell):
			tiles[cell] = ""
		else:
			tiles[cell] += " + "
		if tile == tile_map.acid_tile:
			tiles[cell] += "acid"
		elif tile == tile_map.ladder_tile:
			tiles[cell] += "ladder"
		else:
			tiles[cell] += "solid"
	
	var children = get_children()
	children.sort_custom(self, "_position_sort")
	
	for child in children:
		var filename : String = child.filename
		if filename == "" or Objects.EntityByScenePath.has(filename):
			continue
		
		var cell := Vector2()
		if child.has_method("get_grid_position"):
			cell = child.get_grid_position().round()
		elif child is Node2D and child.get_owner() != self:
			cell = tile_map.world_to_map(child.position)
		else:
			continue
		
		if !tiles.has(cell):
			tiles[cell] = ""
		else:
			tiles[cell] += " + "
		
		var entity_id : int = Objects.EntityByScenePath[filename]
		tiles[cell] += Objects.EntityData[entity_id].name as String
		
		if child.has_method("get_tile_properties"):
			for property in child.get_tile_properties():
				tiles[cell] += ":"
				tiles[cell] += property
	
	# Assign letters to tiles (can be combined with next pass)
	
	var bounds := Rect2()
	var definitions := {"air": "."}
	var characters_used := {".": true}
	for pos in tiles:
		if !definitions.has(tiles[pos]):
			var picked_letter = pick_letter(tiles[pos].split(" + "), characters_used)
			characters_used[picked_letter] = true
			definitions[tiles[pos]] = picked_letter
		if bounds == Rect2():
			bounds = Rect2(pos, Vector2(0, 0))
		else:
			bounds = bounds.expand(pos)
	
	# Write everything out
	
	# TODO: Add logic for appending/replacing in pack
	var file := File.new()
	if file.open(path, File.WRITE) != OK:
		return
	file.store_line("[level " + name_in_pack + "]")
	
	for y in range(bounds.position.y, bounds.end.y + 1):
		var line = ""
		for x in range(bounds.position.x, bounds.end.x + 1):
			var pos = Vector2(x, y)
			if tiles.has(pos):
				line += definitions[tiles[pos]]
			else:
				line += definitions["air"]
		file.store_line(line)
	
	file.store_line("")
	
	for definition in definitions:
		var line = definitions[definition] + " = " + definition
		file.store_line(line)
	
	file.close()

func _position_sort(a: Node, b: Node) -> bool:
	if a is Node2D and b is Node2D:
		return a.global_position.y < b.global_position.y or (a.global_position.y == b.global_position.y and a.global_position.x < b.global_position.x)
	else:
		return int(a is Node2D) < int(b is Node2D)

func pick_letter(tiles: PoolStringArray, used: Dictionary) -> String:
	var scored_letters := {}
	
	for tile in tiles:
		var properties = Array(tile.split(":"))
		var object_name : String = properties.pop_front()
		var letters : String
		if Objects.is_tile_name(object_name) :
			var id : int = Objects.TileByName[object_name]
			letters = Objects.TileData[id].letters
		else:
			var id : int = Objects.EntityByName[object_name]
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
