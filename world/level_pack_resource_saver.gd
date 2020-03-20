extends ResourceFormatSaver
class_name LevelPackFormatSaver

func get_recognized_extensions(resource: Resource) -> PoolStringArray:
	return PoolStringArray(["level", "pack"] if recognize(resource) else [])

func recognize(resource: Resource) -> bool:
	return resource is LevelPack

func save(path: String, resource: Resource, _flags: int) -> int:
	var pack = resource as LevelPack
	var file := File.new()
	var err := file.open(path, File.WRITE)
	if err != OK:
		return err
	
	for level in pack.levels:
		file.store_line("[level " + level.name + "]")
		_save_tiles(file, level.tiles)
		
		file.store_line("")
	
	file.close()
	return OK

func _save_tiles(file: File, tiles: Dictionary) -> void:
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

func pick_letter(objects: PoolStringArray, used: Dictionary) -> String:
	# HACK: Can't access autoload singletons at parse time
	var Objects = (Engine.get_main_loop() as SceneTree).get_root().get_node("/root/Objects")
	var scored_letters := {}
	
	for object in objects:
		var properties = Array(object.split(":"))
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
