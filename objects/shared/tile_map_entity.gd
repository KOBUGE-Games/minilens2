extends TileMap

onready var ladder_tile = tile_set.find_tile_by_name("ladder")
onready var acid_tile = tile_set.find_tile_by_name("acid")

func _ready():
	update_positions()

func _exit_tree() -> void:
	Grid.remove_entity(self)

func update_positions():
	Grid.remove_entity(self)
	for pos in get_used_cells():
		var grid_pos = (to_global(map_to_world(pos)) / Grid.GRID_SIZE).round()
		var flag = Grid.Flag.NONE
		match get_cellv(pos):
			ladder_tile:
				flag = Grid.Flag.LADDER
			acid_tile:
				flag = Grid.Flag.ACID
		Grid.add_entity_position(self, grid_pos, flag)

func move(_direction: Vector2, _stength: float, _speed: float = 0.0) -> float:
	return -INF
