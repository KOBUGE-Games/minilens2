extends CanvasLayer

const Level = preload("res://world/level.gd")
const EditorCamera = preload("res://world/editor_camera.gd")
const Objects = preload("res://objects/Objects.gd")

onready var tiles_container = $parts/middle/left_panel/v_box_container/tiles
onready var entities_container = $parts/middle/left_panel/v_box_container/entities
onready var erase_button = $parts/middle/left_panel/v_box_container/modes/erase
onready var replace_button = $parts/middle/left_panel/v_box_container/modes/replace
onready var entity_editor_container = $parts/middle/left_panel/v_box_container/entity_editor
onready var level_name = $parts/top_bar/h_box_container/level_name
onready var level := get_tree().current_scene as Level
onready var modes_group := erase_button.group as ButtonGroup
onready var camera := preload("res://world/editor_camera.tscn").instance() as EditorCamera
var parts_group : ButtonGroup

var default_tile_button: Button
var air_tile_button: Button
var entity_editor: Control = null

var selected_object_type : int
var selected_object : int

func _ready():
	if level == self or level == null:
		level = preload("res://world/level.tscn").instance() as Level
		get_tree().root.call_deferred("add_child", level)
	
	get_tree().root.call_deferred("add_child", camera)
	camera.call_deferred("make_current")
	
	for tile_type in range(Objects.TileType.COUNT):
		var button = preload("res://world/level_editor_part.tscn").instance()
		button.text = Objects.TileData[tile_type].label
		tiles_container.add_child(button)
		
		if tile_type == Objects.TileType.AIR:
			air_tile_button = button
			button.connect("pressed", self, "select_erase")
		elif tile_type == Objects.TileType.SOLID:
			default_tile_button = button
			button.connect("pressed", self, "select_nonerase")
		
		button.connect("pressed", self, "reset_entity_editor")
		button.connect("pressed", self, "set_selected_tile", [tile_type])
	
	for entity_type in range(Objects.EntityType.COUNT):
		var button = preload("res://world/level_editor_part.tscn").instance()
		button.text = Objects.EntityData[entity_type].label
		entities_container.add_child(button)
		
		if Objects.EntityData[entity_type].has("property_editor_scene_path") :
			button.connect("pressed", self, "set_entity_editor", [Objects.EntityData[entity_type].property_editor_scene_path])
		else:
			button.connect("pressed", self, "reset_entity_editor")
		button.connect("pressed", self, "set_selected_entity", [entity_type])
			
	
	air_tile_button.pressed = true
	parts_group = air_tile_button.group
	
	level_name.text = level.level_name
	
	get_tree().paused = true

func play_toggled(state):
	get_tree().paused = not state
	tiles_container.get_focus_owner().release_focus()

func select_erase():
	air_tile_button.pressed = true
	erase_button.pressed = true

func select_nonerase():
	if air_tile_button.pressed:
		default_tile_button.pressed = true
	if erase_button.pressed:
		replace_button.pressed = true

			
func set_entity_editor(entity_editor_scene):
	if entity_editor == null || ( entity_editor != null && entity_editor.filename != entity_editor_scene ):
		reset_entity_editor()
		
		entity_editor = (load(entity_editor_scene) as PackedScene).instance()
		entity_editor_container.add_child(entity_editor)
		entity_editor_container.show()

func reset_entity_editor():
	if entity_editor != null:
		entity_editor.queue_free()
		entity_editor = null
		entity_editor_container.hide()
func set_selected_tile(tile_type):
	selected_object_type = Objects.ObjectType.TILE
	selected_object = tile_type
	if modes_group.get_pressed_button().name == "add" :
		replace_button.pressed = true
func set_selected_entity(entity_type):
	selected_object_type = Objects.ObjectType.ENTITY
	selected_object = entity_type

func apply(pos: Vector2):
	if modes_group.get_pressed_button().name == "add":
		var properties : Array = entity_editor.call("get_tile_properties")
		level.add_entity(pos, selected_object, properties)
	elif modes_group.get_pressed_button().name == "erase":
		level.clear_pos(pos)
	elif modes_group.get_pressed_button().name == "replace":
		level.clear_pos(pos)
		if selected_object_type == Objects.ObjectType.TILE:
			level.add_tile(pos, selected_object)
		elif selected_object_type == Objects.ObjectType.ENTITY:
			var properties : Array 
			if( entity_editor):
				properties  = entity_editor.call("get_tile_properties")
			level.add_entity(pos, selected_object, properties)

func process_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseButton
			apply((transformed.position / level.tile_map.cell_size).floor())
			return
	if event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseMotion
			var start := (transformed.position / level.tile_map.cell_size).floor()
			var end := ((transformed.position + transformed.relative) / level.tile_map.cell_size).floor()
			var delta := end - start
			var steps := ceil(delta.length() + 1)
			for i in range(steps):
				apply((start + i * (delta / steps)).floor())
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
