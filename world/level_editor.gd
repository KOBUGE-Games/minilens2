extends CanvasLayer

const Level = preload("res://world/level.gd")
const EditorCamera = preload("res://world/editor_camera.gd")

onready var tiles_container = $parts/middle/left_panel/v_box_container/tiles
onready var entities_container = $parts/middle/left_panel/v_box_container/entities
onready var erase_button = $parts/middle/left_panel/v_box_container/modes/erase
onready var replace_button = $parts/middle/left_panel/v_box_container/modes/replace
onready var entity_editor_container = $parts/middle/left_panel/v_box_container/entity_editor
onready var level_name = $parts/top_bar/h_box_container/level_name
onready var level := get_tree().current_scene as Level
onready var modes_group := erase_button.group as ButtonGroup
onready var camera := preload("res://world/editor_camera.tscn").instance() as EditorCamera
var parts_group: ButtonGroup

var default_tile_button: Button
var default_entity_button: Button
var air_tile_button: Button
var entity_editor: Control = null

var undo_redo: UndoRedo = UndoRedo.new()

var selected_object_type: int
var selected_object: int


func _ready():
	if level == self or level == null:
		level = preload("res://world/level.tscn").instance() as Level
		get_tree().root.call_deferred("add_child", level)
	
	get_tree().root.call_deferred("add_child", camera)
	camera.call_deferred("make_current")
	
	for tile_type in range(Objects.TileType.COUNT):
		var button = preload("res://world/level_editor_part.tscn").instance()
		if Objects.TileData[tile_type].has("label"):
			button.text = Objects.TileData[tile_type].label
		else:
			button.text = Objects.TileData[tile_type].name.capitalize()
		tiles_container.add_child(button)
		
		# Air tile is associated with erase button
		if tile_type == Objects.TileType.AIR:
			air_tile_button = button
			button.connect("pressed", self, "select_erase")
		# Solid is default tile
		elif tile_type == Objects.TileType.SOLID:
			default_tile_button = button
		
		# Any non air tile selection cancels the erase mode
		if tile_type != Objects.TileType.AIR:
			button.connect("pressed", self, "select_nonerase")
		
		# any tile selection resets the entity editor
		button.connect("pressed", self, "reset_entity_editor")

		button.connect("pressed", self, "set_selected_tile", [tile_type])
	
	for entity_type in range(Objects.EntityType.COUNT):
		var button = preload("res://world/level_editor_part.tscn").instance()
		if Objects.EntityData[entity_type].has("label"):
			button.text = Objects.EntityData[entity_type].label
		else:
			button.text = Objects.EntityData[entity_type].name.capitalize()
		entities_container.add_child(button)
		
		# Minilens is default entity 
		if entity_type == Objects.EntityType.MINILENS:
			default_entity_button = button
		
		# selecting an entity with an entity editor triggers the display of the associated entity editor
		if Objects.EntityData[entity_type].has("property_editor_scene_path"):
			button.connect("pressed", self, "set_entity_editor", [Objects.EntityData[entity_type].property_editor_scene_path])
		# otherwise, any entity selection without entity editor resets the entity editor
		else:
			button.connect("pressed", self, "reset_entity_editor")
			
		button.connect("pressed", self, "set_selected_entity", [entity_type])
	
		# any entity selection cancels the erase mode
		button.connect("pressed", self, "select_nonerase")
	
	air_tile_button.pressed = true
	parts_group = air_tile_button.group
	
	level_name.text = level.level_name
	
	get_tree().paused = true


func play_toggled(state):
	get_tree().paused = not state
	tiles_container.get_focus_owner().release_focus()

# called when clicking on erase or air button
func select_erase():
	air_tile_button.pressed = true
	erase_button.pressed = true

# called when click on any non air tile or entity, or when clicking on replace button
func select_nonerase():
	if air_tile_button.pressed:
		default_tile_button.pressed = true
	if erase_button.pressed:
		replace_button.pressed = true

# called when clicking on add button
func select_add():
	if selected_object_type == Objects.ObjectType.TILE:
		default_entity_button.pressed = true

# called when clicking on undo button
func undo():
	undo_redo.undo()

# called when clicking on redo button
func redo():
	undo_redo.redo()

# called when clicking any entity with an entity editor
func set_entity_editor(entity_editor_scene: String) -> void:
	if entity_editor == null or entity_editor.filename != entity_editor_scene:
		reset_entity_editor()
		
		entity_editor = (load(entity_editor_scene) as PackedScene).instance()
		entity_editor_container.add_child(entity_editor)
		entity_editor_container.show()

# called when clicking any entity without an entity editor
func reset_entity_editor():
	if entity_editor != null:
		entity_editor.queue_free()
		entity_editor = null
		entity_editor_container.hide()
	
# called when clicking on any tile
func set_selected_tile(tile_type):
	selected_object_type = Objects.ObjectType.TILE
	selected_object = tile_type
	if modes_group.get_pressed_button().name == "add":
		replace_button.pressed = true

# called when clicking on any entity
func set_selected_entity(entity_type):
	selected_object_type = Objects.ObjectType.ENTITY
	selected_object = entity_type

# called when clicking on the grid
func apply(pos: Vector2, is_drag: bool) -> void:
	if modes_group.get_pressed_button().name == "add":
		var properties: Array 
		if(entity_editor):
			properties  = entity_editor.call("get_tile_properties")
		add_entity(pos, is_drag, selected_object, properties)
	elif modes_group.get_pressed_button().name == "erase":
		erase(pos, is_drag)
	elif modes_group.get_pressed_button().name == "replace":
		if selected_object_type == Objects.ObjectType.TILE:
			replace_tile(pos, is_drag, selected_object)
		elif selected_object_type == Objects.ObjectType.ENTITY:
			var properties: Array 
			if(entity_editor):
				properties = entity_editor.call("get_tile_properties")
			replace_entity(pos, is_drag, selected_object, properties)


func add_entity(pos: Vector2, is_drag: bool, selected_object: int, properties: Array) -> void:
	undo_redo.create_action("add_entity", UndoRedo.MERGE_ALL if is_drag else UndoRedo.MERGE_DISABLE)
	undo_redo.add_do_method(self, "do_add_entity", pos, selected_object, properties)
	undo_redo.add_undo_method(self, "undo_add_entity", pos, selected_object, properties)
	undo_redo.commit_action()

func do_add_entity(pos: Vector2, selected_object: int, properties: Array) -> void:
	level.add_entity(pos, selected_object, properties)

func undo_add_entity(pos: Vector2, selected_object: int, properties: Array) -> void:
	level.remove_entity(pos, selected_object, properties)

func erase(pos: Vector2, is_drag: bool) -> void:
	undo_redo.create_action("erase", UndoRedo.MERGE_ALL if is_drag else UndoRedo.MERGE_DISABLE)
	undo_redo.add_do_method(self, "do_erase", pos)
	var r: Dictionary = level.get_pos(pos)
	var tile: int = r.tile
	var entities: Array = r.entities
	var entities_properties = r.entities_properties
	undo_redo.add_undo_method(self, "undo_erase", pos, tile, entities, entities_properties)
	undo_redo.commit_action()

func do_erase(pos: Vector2) -> void:
	level.clear_pos(pos)

func undo_erase(pos: Vector2, tile: int, entities: Array, entities_properties: Array) -> void:
	level.add_tile(pos, tile)
	for i in entities.size():
		level.add_entity(pos, entities[i], entities_properties[i])
	
func replace_entity(pos: Vector2, is_drag: bool, selected_object: int, properties: Array) -> void:
	undo_redo.create_action("replace_entity", UndoRedo.MERGE_ALL if is_drag else UndoRedo.MERGE_DISABLE)
	undo_redo.add_do_method(self, "do_replace_entity", pos, selected_object, properties)
	var r: Dictionary = level.get_pos(pos)
	var tile: int = r.tile
	var entities: Array = r.entities
	var entities_properties = r.entities_properties
	undo_redo.add_undo_method(self, "undo_replace_entity", pos, tile, entities, entities_properties)
	undo_redo.commit_action()

func do_replace_entity(pos: Vector2, selected_object: int, properties: Array) -> void:
	level.clear_pos(pos)
	level.add_entity(pos, selected_object, properties)

func undo_replace_entity(pos: Vector2, tile: int, entities: Array, entities_properties: Array) -> void:
	level.clear_pos(pos)
	level.add_tile(pos, tile)
	for i in entities.size():
		level.add_entity(pos, entities[i], entities_properties[i])


func replace_tile(pos: Vector2, is_drag: bool, selected_object: int) -> void:
	undo_redo.create_action("replace_tile", UndoRedo.MERGE_ALL if is_drag else UndoRedo.MERGE_DISABLE)
	undo_redo.add_do_method(self, "do_replace_tile", pos, selected_object)
	var r: Dictionary = level.get_pos(pos)
	var tile: int = r.tile
	var entities: Array = r.entities
	var entities_properties = r.entities_properties
	undo_redo.add_undo_method(self, "undo_replace_tile", pos, tile, entities, entities_properties)
	undo_redo.commit_action()

func do_replace_tile(pos: Vector2, selected_object: int) -> void:
	level.clear_pos(pos)
	level.add_tile(pos, selected_object)

func undo_replace_tile(pos: Vector2, tile: int, entities: Array, entities_properties: Array) -> void:
	level.clear_pos(pos)
	level.add_tile(pos, tile)
	for i in entities.size():
		level.add_entity(pos, entities[i], entities_properties[i])


var current_drag_positions := {}
func process_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == BUTTON_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseButton
			var pos = (transformed.position / level.tile_map.cell_size).floor()
			apply(pos, false)
			current_drag_positions = {pos: true}
			return
	
	if event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseMotion
			var start := ((transformed.position - transformed.relative) / level.tile_map.cell_size).floor()
			var end := (transformed.position / level.tile_map.cell_size).floor()
			var delta := end - start
			var steps := ceil(delta.length() + 1)
			for i in range(steps):
				var pos = (start + i * (delta / steps)).floor()
				if not current_drag_positions.has(pos):
					apply(pos, true)
					current_drag_positions[pos] = true
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


