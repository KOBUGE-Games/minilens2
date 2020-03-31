extends CenterContainer

onready var pack_select = $layout/selection/pack
onready var editor_toggle = $layout/selection/editor
onready var level_list = $layout/level_list
export var level_button_size = 150
var packs := []
var uncategorized_levels := []

func _ready():
	pack_select.clear()
	
	var directory := Directory.new()
	directory.open("res://levels")
	if directory.list_dir_begin(true, true) == OK:
		while true:
			var file_name := directory.get_next()
			if file_name == "":
				break
			
			var path := directory.get_current_dir().plus_file(file_name)
			match path.get_extension():
				"pack":
					pack_select.add_item(file_name.get_basename().capitalize())
					packs.push_back(path)
				"level":
					uncategorized_levels.push_back(path)
		directory.list_dir_end()
	pack_select.add_item("Others")
	pack_selected(0)
	_resized()
	get_viewport().connect("size_changed", self, "_resized")

func _resized():
	level_list.columns = (get_viewport_rect().size.x - 100) / level_button_size

func pack_selected(id: int):
	for child in level_list.get_children():
		level_list.remove_child(child)
		child.queue_free()
	if id < packs.size():
		var path = packs[id]
		var pack = ResourceLoader.load(path)
		_add_pack_levels(pack, true)
	else:
		for path in uncategorized_levels:
			var level = ResourceLoader.load(path)
			_add_pack_levels(level, false)


func _add_pack_levels(pack: LevelPack, write_indices: bool):
	var i = 0
	for level in pack.levels:
		var button = preload("res://menu/level_button.tscn").instance()
		if write_indices:
			button.text = "%d: %s" % [level_list.get_child_count() + 1, level.name]
		else:
			button.text = level.name
		button.connect("pressed", self, "level_selected", [pack, i])
		level_list.add_child(button)
		
		i += 1

func level_selected(pack: LevelPack, level_idx: int):
	var base_scene: PackedScene
	if editor_toggle.pressed:
		base_scene = load("res://editor/level_editor.tscn")
	else:
		base_scene = load("res://game/level_player.tscn")
	
	var base := base_scene.instance()
	
	base.select_level(pack, level_idx)
	
	get_tree().root.add_child(base)
	get_tree().current_scene = base
	
	queue_free()
