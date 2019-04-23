extends Node2D

const TileMapEntity = preload("res://objects/shared/tile_map_entity.gd")
const TileScenes = {
	air = "",
	solid = "tile",
	ladder = "tile",
	acid = "tile",
	minilens = "res://objects/minilens/minilens.tscn",
	barrel = "res://objects/barrel/barrel.tscn",
	flower = "res://objects/flower/flower.tscn",
	bomb = "res://objects/bomb/bomb_pickup.tscn",
	primed_bomb = "res://objects/bomb/bomb.tscn",
	unstable = "res://objects/unstable_ground/unstable_ground.tscn",
}

onready var tile_map := $tile_map as TileMapEntity

func _ready():
	load_from_file("res://levels/test.level")

func clear():
	while get_child_count() > 2:
		var child_to_remove := get_child(1) # Do not remove child 0, it is the tilemap
		remove_child(child_to_remove)
		child_to_remove.queue_free()
	tile_map.clear()

func clear_tile(pos: Vector2):
	if tile_map.get_cellv(pos) != -1:
		tile_map.set_cellv(pos, -1)
		tile_map.update_positions()
	for child in get_children():
		if child.has_method("get_grid_position"):
			if child.get_grid_position().distance_squared_to(pos) < 0.01:
				child.queue_free()
		elif child is Node2D and not (child is TileMap):
			if child.position.distance_squared_to(tile_map.map_to_world(pos)) < 0.01:
				child.queue_free()
			

func add_tile(pos: Vector2, type: String):
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
		add_child(instance)

func load_from_file(path: String, level_name: String = "") -> void:
	var file := File.new()
	file.open(path, File.READ)
	while not file.eof_reached():
		var line := file.get_line()
		if line.begins_with("[level ") and line.ends_with("]"):
			var found_level_name := line.substr(7, line.length() - 8)
			if found_level_name == level_name or level_name == "":
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
	
	# Build level
	for y in range(map_lines.size()):
		for x in range(map_lines[y].length()):
			if not definitions.has(map_lines[y][x]):
				push_error("Unknown tile: " + map_lines[y][x])
				continue
			
			for definition in definitions[map_lines[y][x]]:
				add_tile(Vector2(x, y), definition)
	
	tile_map._update_positions()
