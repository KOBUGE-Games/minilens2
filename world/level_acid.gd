extends Node2D

const Level = preload("res://world/level.gd")

export var size = Vector2(5, 2)
onready var texture_rect := $texture_rect as TextureRect
var update_queued = false

func _ready():
	update_acid()

func _exit_tree() -> void:
	Grid.remove_entity(self)

func update_acid():
	if not update_queued:
		update_queued = true
		call_deferred("_update_acid")

func _update_acid():
	var level := get_owner() as Level
	var bounds := level.get_bounds()
	global_position = (Vector2(bounds.position.x - size.x, bounds.end.y + 1 + size.y)) * Grid.GRID_SIZE
	texture_rect.rect_size = Vector2(bounds.size.x + 1 + size.x * 2, 1) * Grid.GRID_SIZE
	
	Grid.remove_entity(self)
	for x in range(bounds.position.x - size.x, bounds.end.x + 1 + size.x):
		Grid.add_entity_position(self, Vector2(x, bounds.end.y + 1 + size.y), Grid.Flag.ACID)
	
	update_queued = false

func move(_direction: Vector2, _priority: int, _speed: float, _strength: float = -1.0) -> float:
	return -INF
