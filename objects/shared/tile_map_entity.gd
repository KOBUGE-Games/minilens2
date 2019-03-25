extends TileMap

func _ready():
	update_positions()

func _exit_tree() -> void:
	Grid.remove_entity(self)

func update_positions():
	Grid.remove_entity(self)
	for pos in get_used_cells():
		var grid_pos = (to_global(map_to_world(pos)) / Grid.GRID_SIZE).round()
		Grid.add_entity_position(self, grid_pos)

func move(_direction: Vector2, _stength: float, _speed: float = 0.0) -> float:
	return -INF
