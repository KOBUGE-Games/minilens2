extends Node

const Level = preload("res://world/level.gd")
const EditorCamera = preload("res://editor/editor_camera.gd")

onready var level := $level as Level
onready var camera := $editor_camera as EditorCamera

var undo_redo := UndoRedo.new()

var current_pack: LevelPack
var current_level_idx: int

var previous_state = null
var turn_count := 0

func _ready():
	select_level(current_pack, current_level_idx)
	undo_redo.connect("version_changed", self, "update_undo_redo")
	update_undo_redo()
	
	get_tree().paused = false

func set_level_state(new_state: Dictionary, new_turn_count: int = 0):
	get_tree().paused = false
	turn_count = new_turn_count
	previous_state = new_state
	if !undo_redo.is_commiting_action():
		level.set_state(new_state)
		for minilens in get_tree().get_nodes_in_group("minilens"):
			minilens.connect("moved", self, "do_turn")

func _process(_delta):
	var minilenses = get_tree().get_nodes_in_group("minilens")
	if minilenses.size() <= 0:
		get_tree().paused = true
		$gui/died_popup.popup_centered_ratio(0.5)
		return
	if Goals.get_total_goals_left() <= 0:
		get_tree().paused = true
		$gui/finished_popup.popup_centered_ratio(0.5)
		$gui/finished_popup/layout/congratulations/turns.text = str(turn_count)
		$gui/finished_popup/layout/stars/star3/star.visible = false
	
	var bombs = 0
	for minilens in minilenses:
		bombs += minilens.bombs_available
		
	$gui/counts/bombs/value.text = str(bombs)
	$gui/counts/turns/value.text = str(turn_count)
	$gui/counts/flowers/value.text = str(Goals.get_goal_count_left(Goals.GoalType.FLOWER))
	$gui/counts/barrels/value.text = str(Goals.get_goal_count_left(Goals.GoalType.BARREL))

func do_turn():
	undo_redo.create_action("Move")
	undo_redo.add_do_method(self, "set_level_state", level.get_state(), turn_count + 1)
	undo_redo.add_undo_method(self, "set_level_state", previous_state, turn_count)
	undo_redo.commit_action()

func undo():
	$gui/died_popup.hide()
	undo_redo.undo()

func redo():
	undo_redo.redo()

func update_undo_redo():
	$gui/actions_panel/buttons/redo.disabled = not undo_redo.has_redo()
	$gui/actions_panel/buttons/undo.disabled = not undo_redo.has_undo()

func retry():
	select_level(current_pack, current_level_idx)

func next():
	select_level(current_pack, current_level_idx + 1)

func menu():
	get_tree().paused = false
	get_tree().change_scene("res://menu/main_menu.tscn")

func process_input(event: InputEvent):
	camera.handle_input(event)

func select_level(pack: LevelPack, level_idx: int):
	current_pack = pack
	current_level_idx = level_idx
	if is_inside_tree():
		$gui/died_popup.hide()
		$gui/finished_popup.hide()
		if current_level_idx < current_pack.levels.size():
			set_level_state(current_pack.levels[current_level_idx])
			$gui/level_name.text = level.level_name
		else:
			menu()
