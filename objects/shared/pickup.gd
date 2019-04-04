extends Node2D

func _enter_tree() -> void:
	global_position = (get_grid_position() + Vector2(0.5, 0.5)) * Grid.GRID_SIZE

func _physics_process(delta):
	var entity = Grid.get_entity_at_position(get_grid_position())
	if entity != null:
		if try_pickup(entity):
			set_physics_process(false)

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func try_pickup(entity: Object) -> bool:
	return true
