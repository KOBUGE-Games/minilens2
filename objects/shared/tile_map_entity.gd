extends TileMap

onready var ladder_tile := tile_set.find_tile_by_name("ladder")
onready var acid_tile := tile_set.find_tile_by_name("acid")

var update_queued = false

func _ready():
	update_positions()

func _exit_tree() -> void:
	Grid.remove_entity(self)

func update_positions():
	if not update_queued:
		update_queued = true
		call_deferred("_update_positions")

func _update_positions():
	Grid.remove_entity(self)
	for pos in get_used_cells():
		var grid_pos = (to_global(map_to_world(pos)) / Grid.GRID_SIZE).round()
		var flag = Grid.Flag.SOLID
		match get_cellv(pos):
			ladder_tile:
				flag = Grid.Flag.LADDER
			acid_tile:
				flag = Grid.Flag.ACID
		Grid.add_entity_position(self, grid_pos, flag)
	update_queued = false

func move(_direction: Vector2, _priority: int, _speed: float, _strength: float = -1.0) -> float:
	return -INF
