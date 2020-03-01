extends CanvasLayer

const Level = preload("res://world/level.gd")
const EditorCamera = preload("res://world/editor_camera.gd")

onready var ui_root = $parts
onready var tiles_container = $parts/middle/left_panel/v_box_container/tiles
onready var entities_container = $parts/middle/left_panel/v_box_container/entities
onready var erase_button = $parts/middle/left_panel/v_box_container/modes/erase
onready var replace_button = $parts/middle/left_panel/v_box_container/modes/replace
onready var pick_button = $parts/middle/left_panel/v_box_container/modes/pick
onready var redo_button = $parts/top_bar/h_box_container/redo
onready var undo_button = $parts/top_bar/h_box_container/undo
onready var current_action_label = $parts/top_bar/h_box_container/current_action
onready var play_button = $parts/top_bar/h_box_container/play
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
	
	undo_redo.connect("version_changed", self, "update_undo_redo")
	
	for tile_type in range(Objects.TileType.COUNT):
		var button = preload("res://world/level_editor_part.tscn").instance()
		if Objects.TileData[tile_type].has("label"):
			button.text = Objects.TileData[tile_type].label
		else:
			button.text = Objects.TileData[tile_type].name.capitalize()
		button.name = Objects.TileData[tile_type].name
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
		button.name = Objects.EntityData[entity_type].name
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

var state_before_play = {}

func play_toggled(play_pressed):
	if play_pressed:
		state_before_play = level.get_state()
		redo_button.disabled = true
		undo_button.disabled = true
	elif not level.are_states_equal(state_before_play, level.get_state()):
		undo_redo.create_action("Play level", UndoRedo.MERGE_DISABLE)
		undo_redo.add_undo_method(level, "set_state", state_before_play)
		undo_redo.add_do_method(level, "set_state", level.get_state(), true)
		undo_redo.commit_action()
	else:
		update_undo_redo()
	
	for button in parts_group.get_buttons():
		button.disabled = play_pressed
	for button in modes_group.get_buttons():
		button.disabled = play_pressed
	level_name.editable = not play_pressed
	ui_root.modulate.a = 0.3 if play_pressed else 1
	pick_button.disabled = play_pressed
	
	if tiles_container.get_focus_owner():
		tiles_container.get_focus_owner().release_focus()
	
	get_tree().paused = not play_pressed

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
		default_entity_button.emit_signal("pressed")

# called when clicking on undo button
func undo():
	undo_redo.undo()

# called when clicking on redo button
func redo():
	undo_redo.redo()

func update_undo_redo():
	current_action_label.text = undo_redo.get_current_action_name()
	redo_button.disabled = not undo_redo.has_redo()
	undo_button.disabled = not undo_redo.has_undo()

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
	if play_button.pressed:
		pass
	elif pick_button.pressed:
		if not is_drag:
			pick(pos)
			pick_button.pressed = false
	elif modes_group.get_pressed_button().name == "add":
		var properties: Array 
		if entity_editor:
			properties = entity_editor.call("get_tile_properties")
		add_entity(pos, is_drag, selected_object, properties)
	elif modes_group.get_pressed_button().name == "erase":
		erase(pos, is_drag)
	elif modes_group.get_pressed_button().name == "replace":
		if selected_object_type == Objects.ObjectType.TILE:
			replace_tile(pos, is_drag, selected_object)
		elif selected_object_type == Objects.ObjectType.ENTITY:
			var properties: Array 
			if entity_editor:
				properties = entity_editor.call("get_tile_properties")
			replace_entity(pos, is_drag, selected_object, properties)


func pick(pos: Vector2) -> void:
	var result: Dictionary = level.get_pos(pos)
	if result.entities.size() > 0:
		var entity_name = Objects.EntityData[result.entities[-1]].name
		if entities_container.has_node(entity_name):
			var button = entities_container.get_node(entity_name)
			button.pressed = true
			button.emit_signal("pressed")
			
			if entity_editor != null and entity_editor.has_method("set_tile_properties"):
				entity_editor.set_tile_properties(result.entities_properties[-1])
	else:
		var tile_name = Objects.TileData[result.tile].name
		if tiles_container.has_node(tile_name):
			var button = tiles_container.get_node(tile_name)
			button.pressed = true
			button.emit_signal("pressed")


func add_entity(pos: Vector2, is_drag: bool, selected_object: int, properties: Array) -> void:
	var undo_redo_merge_mode : int = UndoRedo.MERGE_DISABLE
	if is_drag:
		undo_redo_merge_mode = UndoRedo.MERGE_ALL
	undo_redo.create_action("Add %s" % Objects.EntityData[selected_object].name, undo_redo_merge_mode)
	undo_redo.add_do_method(self, "do_add_entity", pos, selected_object, properties)
	undo_redo.add_undo_method(self, "undo_add_entity", pos, selected_object, properties)
	undo_redo.commit_action()

func do_add_entity(pos: Vector2, selected_object: int, properties: Array) -> void:
	level.add_entity(pos, selected_object, properties)

func undo_add_entity(pos: Vector2, selected_object: int, properties: Array) -> void:
	level.remove_entity(pos, selected_object, properties)


func erase(pos: Vector2, is_drag: bool) -> void:
	var undo_redo_merge_mode : int = UndoRedo.MERGE_DISABLE
	if is_drag :
		undo_redo_merge_mode = UndoRedo.MERGE_ALL
	undo_redo.create_action("Erase", undo_redo_merge_mode)
	
	undo_redo.add_do_method(self, "do_erase", pos)
	
	var result: Dictionary = level.get_pos(pos)
	var tile: int = result.tile
	var entities: Array = result.entities
	var entities_properties = result.entities_properties
	undo_redo.add_undo_method(self, "undo_erase", pos, tile, entities, entities_properties)
	
	undo_redo.commit_action()

func do_erase(pos: Vector2) -> void:
	level.clear_pos(pos)

func undo_erase(pos: Vector2, tile: int, entities: Array, entities_properties: Array) -> void:
	level.add_tile(pos, tile)
	for i in entities.size():
		level.add_entity(pos, entities[i], entities_properties[i])


func replace_entity(pos: Vector2, is_drag: bool, selected_object: int, properties: Array) -> void:
	var undo_redo_merge_mode : int = UndoRedo.MERGE_DISABLE
	if is_drag:
		undo_redo_merge_mode = UndoRedo.MERGE_ALL
	undo_redo.create_action("Set to %s" % Objects.EntityData[selected_object].name, undo_redo_merge_mode)
	
	undo_redo.add_do_method(self, "do_replace_entity", pos, selected_object, properties)
	
	var result: Dictionary = level.get_pos(pos)
	var tile: int = result.tile
	var entities: Array = result.entities
	var entities_properties = result.entities_properties
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
	var undo_redo_merge_mode : int = UndoRedo.MERGE_DISABLE
	if is_drag:
		undo_redo_merge_mode = UndoRedo.MERGE_ALL
	undo_redo.create_action("Set to %s" % Objects.TileData[selected_object].name, undo_redo_merge_mode)
	
	undo_redo.add_do_method(self, "do_replace_tile", pos, selected_object)
	
	var result: Dictionary = level.get_pos(pos)
	var tile: int = result.tile
	var entities: Array = result.entities
	var entities_properties = result.entities_properties
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
		if event.pressed and event.button_index == BUTTON_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseButton
			var pos := level.world_pos_to_grid_pos( transformed.position )
			apply(pos, false)
			if event.control:
				pick_button.pressed = true
			current_drag_positions = {pos: true}
			return
	
	if event is InputEventMouseMotion:
		if event.button_mask & BUTTON_MASK_LEFT:
			var transformed := level.tile_map.make_input_local(event) as InputEventMouseMotion
			var start := level.world_pos_to_grid_pos( transformed.position - transformed.relative )
			var end := level.world_pos_to_grid_pos( transformed.position )
			var delta := end - start
			var steps := ceil(delta.length() + 1)
			for i in range(steps):
				var pos = (start + i * (delta / steps)).floor()
				if not current_drag_positions.has(pos):
					apply(pos, true)
					current_drag_positions[pos] = true
			return
	
	camera.handle_input(event)

func _unhandled_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_CONTROL:
			pick_button.pressed = event.pressed

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
	dialog.connect("popup_hide", dialog, "queue_free")
	var file: String = yield(dialog, "file_selected")
	
	# TODO: Add logic for reading packs
	if level.load_from_file(file):
		level_name.text = level.level_name
		
		undo_redo.clear_history()
		undo_button.disabled = true
		redo_button.disabled = true

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
	dialog.connect("popup_hide", dialog, "queue_free")
	var file: String = yield(dialog, "file_selected")
	
	# TODO: Add logic for saving packs
	level.level_name = level_name.text
	level.save_to_file(file)
