extends Node2D

export var teleport_speed := 1768.0
export var group = 1
export var target_group = 1
var _blocked := 1

func _enter_tree() -> void:
	add_to_group(str("teleport_", group))
	get_tree().call_group(str("teleport_", group), "update_display")
	
	var grid_pos = get_grid_position()
	global_position = (grid_pos + Vector2(0.5, 0.5)) * Grid.GRID_SIZE

func _exit_tree() -> void:
	get_tree().call_group(str("teleport_", group), "update_display")
	Grid.remove_entity(self)

func update_display() -> Array:
	if not is_inside_tree():
		return []
	var valid_targets = []
	var connection_points = []
	for target in get_tree().get_nodes_in_group(str("teleport_", target_group)):
		if target != self and Grid.get_entity_at_position(target.get_grid_position()) == null:
			valid_targets.push_back(target)
			connection_points.push_back(Vector2(0, 0))
			var offset = target.get_grid_position() - get_grid_position()
			offset -= offset.normalized()
			connection_points.push_back(offset * Grid.GRID_SIZE)
	$subnode/connections.points = connection_points
	
	$subnode/disabled.visible = (_blocked > 1 or valid_targets.size() == 0)
	
	return valid_targets

func _physics_process(_delta):
	var grid_pos = get_grid_position()
	var over_entity = Grid.get_entity_at_position(grid_pos)
	var valid_targets := update_display()
	if over_entity != null:
		if valid_targets.size() > 0 and _blocked <= 0:
			var target = valid_targets[randi() % valid_targets.size()]
			if over_entity.move(target.get_grid_position() - get_grid_position(), PhysicsEntity.Priority.TELEPORT, teleport_speed) > 0.0:
				target._blocked = 2
	else:
		_blocked -= 1
	

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func get_tile_properties():
	return [str(group), str(target_group)]

func set_tile_properties(object_properties: Array):
	group = int(object_properties[0]) if object_properties.size() > 0 else 1
	target_group = int(object_properties[1]) if object_properties.size() > 1 else group
