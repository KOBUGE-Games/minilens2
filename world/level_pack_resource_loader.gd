extends ResourceFormatLoader
class_name LevelPackFormatLoader

func get_recognized_extensions() -> PoolStringArray:
	return PoolStringArray(["level", "pack"])

func get_resource_type(path: String) -> String:
	if path.get_extension() in get_recognized_extensions():
		return "Resource"
	return ""

func handles_type(typename: String) -> bool:
	return typename == "Resource"

func load(path: String, original_path: String):
	var pack = LevelPack.new()
	pack.resource_path = original_path
	
	var file := File.new()
	var err := file.open(path, File.READ)
	if err != OK:
		return err
	
	var line := file.get_line()
	while not file.eof_reached():
		if line.begins_with("[level ") and line.ends_with("]"):
			var level_name := line.substr(7, line.length() - 8)
			# Parse tilemap
			var raw_tiles := {}
			var size := Vector2()
			var y = 0
			while not file.eof_reached():
				line = file.get_line()
				if (y > 0 and line.length() == 0) or line.find(" ") != -1:
					break
				if line != "":
					var x = 0
					for definition in line:
						raw_tiles[Vector2(x, y)] = definition
						x += 1
					y += 1
					size = Vector2(max(size.x, x), y)
			
			# Parse tile definitions (without overstepping into next level)
			var definitions := {}
			while not file.eof_reached():
				line = file.get_line().strip_edges()
				if line == "": continue
				if line[0] == "[" and (line[1] != " " or line[1] != "="): break
				
				var split_pos := line.find("=", 1)
				var tile := line[0]
				var definition := line.substr(split_pos + 1, line.length() - split_pos - 1).split("+")
				for i in range(definition.size()):
					definition[i] = definition[i].strip_edges()
				definitions[tile] = definition
			
			# Apply definitions to tiles
			var tiles := {}
			var offset := -(size / 2).floor()
			for cell in raw_tiles:
				if not definitions.has(raw_tiles[cell]):
					push_error("Unknown tile: " + raw_tiles[cell])
					continue
				tiles[cell + offset] = definitions[raw_tiles[cell]]
			
			pack.levels.push_back({tiles = tiles, name = level_name})
		else:
			line = file.get_line()
	
	file.close()
	return pack
	
