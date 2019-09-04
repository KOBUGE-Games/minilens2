extends CanvasLayer

const Level = preload("res://world/level.gd")
const EditorCamera = preload("res://world/editor_camera.gd")

onready var parts_container = $parts/middle/left_panel/v_box_container/parts
onready var erase_button = $parts/middle/left_panel/v_box_container/modes/erase
onready var replace_button = $parts/middle/left_panel/v_box_container/modes/replace
onready var tile_editor_container = $parts/middle/left_panel/v_box_container/tile_editor
onready var level_name = $parts/top_bar/h_box_container/level_name
onready var level := get_tree().current_scene as Level
onready var modes_group := erase_button.group as ButtonGroup
onready var camera := preload("res://world/editor_camera.tscn").instance() as EditorCamera
var parts_group : ButtonGroup

var default_tile_button: Button
var air_tile_button: Button
var tile_editor: Control = null

func _ready():
	if level == self or level == null:
		level = preload("res://world/level.tscn").instance() as Level
		get_tree().root.call_deferred("add_child", level)
	
	level.add_child(camera)
	camera.call_deferred("make_current")
	
	for tile_type in level.TileScenes:
		var button = preload("res://world/level_editor_part.tscn").instance()
		button.text = tile_type.capitalize()
		button.name = tile_type
		parts_container.add_child(button)
		
		if level.TileScenes[tile_type] == "":
			air_tile_button = button
			button.connect("pressed", self, "select_erase")
		else:
			if default_tile_button == null:
				default_tile_button = button
			button.connect("pressed", self, "select_nonerase")
		
		button.connect("pressed", self, "set_tile_editor", [level.TilePropertyEditors.get(tile_type)])
	
	air_tile_button.pressed = true
	parts_group = air_tile_button.group
	level_name.text = level.level_name
	get_tree().paused = true

func play_toggled(state):
	get_tree().paused = not state
	parts_container.get_focus_owner().release_focus()

func select_erase():
	air_tile_button.pressed = true
	erase_button.pressed = true

func select_nonerase():
	if air_tile_button.pressed:
		default_tile_button.pressed = true
	if erase_button.pressed:
		replace_button.pressed = true

func set_tile_editor(tile_editor_scene):
	if tile_editor_scene == null:
		if tile_editor != null:
			tile_editor.queue_free()
			tile_editor = null
			tile_editor_container.hide()
	else:
		if tile_editor == null or tile_editor.filename != tile_editor_scene:
			if tile_editor != null:
				tile_editor.queue_free()
			tile_editor = (load(tile_editor_scene) as PackedScene).instance()
			tile_editor_container.add_child(tile_editor)
			tile_editor_container.show()

func apply_tile(pos: Vector2):
	if modes_group.get_pressed_button().name != "add":
		level.clear_tile(pos)
	if modes_group.get_pressed_button().name != "erase":
		if tile_editor != null:
			var properties = tile_editor.call("get_tile_properties")
			level.add_tile(pos, parts_group.get_pressed_button().name, properties)
		else:
			level.add_tile(pos, parts_group.get_pressed_button().name)

func process_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseButton
			apply_tile((transformed.position / level.tile_map.cell_size).floor())
			return
	if event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseMotion
			var start := (transformed.position / level.tile_map.cell_size).floor()
			var end := ((transformed.position + transformed.relative) / level.tile_map.cell_size).floor()
			var delta := end - start
			var steps := ceil(delta.length() + 1)
			for i in range(steps):
				apply_tile(start + i * (delta / steps))
			return
	camera.handle_input(event)


func open_level_dialog():
	var dialog := FileDialog.new()
	dialog.mode = FileDialog.MODE_OPEN_FILE
	if OS.has_feature("debug"):
		dialog.access = FileDialog.ACCESS_RESOURCES
	else:
		dialog.access = FileDialog.ACCESS_USERDATA
	dialog.filters = ["*.level", "*.pack"]
	add_child(dialog)
	dialog.popup_centered_ratio()
	yield(dialog, "popup_hide")
	var file: String = dialog.current_path
	dialog.queue_free()
	if file == "": return
	
	# TODO: Add logic for reading packs
	level.load_from_file(file)
	level_name.text = level.level_name


func save_level_dialog():
	var dialog := FileDialog.new()
	dialog.mode = FileDialog.MODE_SAVE_FILE
	if OS.has_feature("debug"):
		dialog.access = FileDialog.ACCESS_RESOURCES
	else:
		dialog.access = FileDialog.ACCESS_USERDATA
	dialog.filters = ["*.level", "*.pack"]
	add_child(dialog)
	dialog.popup_centered_ratio()
	yield(dialog, "popup_hide")
	var file: String = dialog.current_path
	dialog.queue_free()
	if file == "": return
	
	# TODO: Add logic for saving packs
	level.save_to_file(file, level_name.text)
