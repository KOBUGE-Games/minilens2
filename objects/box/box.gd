extends Node2D

var _deferred_grid_registration := false

func _enter_tree() -> void:
	var grid_pos := get_grid_position()
	global_position = (grid_pos + Vector2(0.5, 0.5)) * Grid.GRID_SIZE
	
	if !Grid.has_entity_at_position(grid_pos):
		Grid.add_entity_position(self, grid_pos)
	else:
		_deferred_grid_registration = true

func _physics_process(_delta):
	if !_deferred_grid_registration:
		set_physics_process(false)
	
	var grid_pos = get_grid_position()
	if !Grid.has_entity_at_position(grid_pos):
		Grid.add_entity_position(self, grid_pos)
		_deferred_grid_registration = false

func _exit_tree() -> void:
	Grid.remove_entity(self)

func move(_direction: Vector2, _priority: int, _speed: float, _strength: float = -1.0) -> float:
	return -INF

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func explode() -> void:
	queue_free()
