extends Node2D

var previous_entity = null

func _enter_tree() -> void:
	var grid_pos = get_grid_position()
	global_position = (get_grid_position() + Vector2(0.5, 0.5)) * Grid.GRID_SIZE
	Grid.add_entity_position(self, grid_pos)

func _exit_tree() -> void:
	Grid.remove_entity(self)

func try_break(entity: Object) -> bool:
	if entity is preload("res://objects/minilens/minilens.gd"):
		queue_free()
		return true
	else:
		return false

func _physics_process(_delta):
	var entity = Grid.get_entity_at_position(get_grid_position() + Vector2(0, -1))
	if previous_entity != entity:
		if previous_entity != null:
			if try_break(previous_entity):
				set_physics_process(false)
		previous_entity = entity

func move(_direction: Vector2, _stength: float, _speed: float = 0.0) -> float:
	return -INF

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()
