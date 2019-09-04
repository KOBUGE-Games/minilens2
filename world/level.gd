extends Node2D

const TileMapEntity = preload("res://objects/shared/tile_map_entity.gd")
const TileScenes = {
	air = "",
	solid = "tile",
	ladder = "tile",
	acid = "tile",
	minilens = "res://objects/minilens/minilens.tscn",
	barrel = "res://objects/barrel/barrel.tscn",
	box = "res://objects/box/box.tscn",
	flower = "res://objects/flower/flower.tscn",
	bomb = "res://objects/bomb/bomb_pickup.tscn",
	primed_bomb = "res://objects/bomb/bomb.tscn",
	unstable = "res://objects/unstable_ground/unstable_ground.tscn",
	teleport = "res://objects/teleport/teleport.tscn",
}
const TilePropertyEditors = {
	teleport = "res://objects/teleport/teleport_editor.tscn",
}
const TileLetters = { # Lists of characters in order of how well they represent the tile
	air = ".\'",
	solid = "#@$%?S",
	ladder = "=%\'\"|L",
	acid = "~\\/xX",
	minilens = "M><RmPp",
	barrel = "BbA[{}]HNR",
	box = "X$@#&",
	flower = "*Ff",
	bomb = "!%b",
	primed_bomb = "@",
	unstable = "^@%?",
	"teleport:1:1": "1A",
	"teleport:2:2": "2B",
	"teleport:3:3": "3C",
	"teleport:4:4": "4D",
}

onready var tile_map := $tile_map as TileMapEntity
var SceneTiles := {}
var level_name := "Unnamed"

func _ready():
	for tile in TileScenes:
		SceneTiles[TileScenes[tile]] = tile
	pass #load_from_file("res://levels/test.level")

func clear():
	for child in get_children():
		if child.has_method("get_grid_position"):
			remove_child(child)
			child.queue_free()
	tile_map.clear()

func clear_tile(pos: Vector2):
	if tile_map.get_cellv(pos) != -1:
		tile_map.set_cellv(pos, -1)
		tile_map.update_positions()
	for child in get_children():
		if child.has_method("get_grid_position"):
			if child.get_grid_position().distance_squared_to(pos) < 0.01:
				child.queue_free()

func add_tile(pos: Vector2, type: String, properties: Array = []):
	if not TileScenes.has(type):
		push_error("Unknown tile type: " + type)
		return
	
	var scene_path := TileScenes[type] as String
	if scene_path == "":
		pass
	elif scene_path == "tile":
		if type == "solid":
			tile_map.set_cellv(pos, 0)
		elif type == "acid":
			tile_map.set_cellv(pos, tile_map.acid_tile)
		elif type == "ladder":
			tile_map.set_cellv(pos, tile_map.ladder_tile)
		tile_map.update_positions()
	else:
		var scene := load(scene_path) as PackedScene
		var instance := scene.instance() as Node2D
		instance.position = (pos + Vector2(0.5, 0.5)) * tile_map.cell_size
		if instance.has_method("set_tile_properties"):
			instance.call("set_tile_properties", properties)
		add_child(instance)

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
				var tile = properties.pop_front()
				add_tile(Vector2(x, y), tile, properties)
	
	tile_map._update_positions()

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
		var filename = child.filename
		if filename == "" or !SceneTiles.has(filename):
			continue
		
		var cell := Vector2()
		if child.has_method("get_grid_position"):
			cell = child.get_grid_position().round()
		elif child is Node2D and not (child is TileMap):
			cell = tile_map.world_to_map(child.position)
		else:
			continue
		
		if !tiles.has(cell):
			tiles[cell] = ""
		else:
			tiles[cell] += " + "
		tiles[cell] += SceneTiles[filename]
		
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
		if !TileLetters.has(tile):
			continue
		var letters := TileLetters[tile] as String
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
