extends Node2D

export var group = 1
export var target_group = 1
var _blocked = false

func _enter_tree() -> void:
	add_to_group(str("teleport_", group))
	
	var grid_pos = get_grid_position()
	global_position = (grid_pos + Vector2(0.5, 0.5)) * Grid.GRID_SIZE

func _exit_tree() -> void:
	Grid.remove_entity(self)

func _physics_process(_delta):
	var grid_pos = get_grid_position()
	
	var valid_targets = []
	for target in get_tree().get_nodes_in_group(str("teleport_", target_group)):
		if target != self and Grid.get_entity_at_position(target.get_grid_position()) == null:
			valid_targets.push_back(target)
	
	var over_entity = Grid.get_entity_at_position(grid_pos)
	if over_entity != null and over_entity.has_method("get_grid_position") and over_entity.has_method("get_mass"):
		$subnode/disabled.visible = true
		if valid_targets.size() > 0 and not _blocked:
			var target = valid_targets[randi() % valid_targets.size()]
			if over_entity.move(target.get_grid_position() - over_entity.get_grid_position(), over_entity.get_mass()) > 0.0:
				target._blocked = true
	else:
		_blocked = false
		$subnode/disabled.visible = (valid_targets.size() == 0)

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func get_tile_properties():
	return [str(group), str(target_group)]

func set_tile_properties(object_properties: Array):
	group = int(object_properties[0]) if object_properties.size() > 0 else 1
	target_group = int(object_properties[1]) if object_properties.size() > 1 else group
