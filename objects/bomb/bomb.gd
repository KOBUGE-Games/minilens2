extends "res://objects/shared/physics_entity.gd"

var exploding = false

func _ready():
	node_to_move = $subnode
	tween = $tween

func get_mass() -> float:
	return 1.0

func calculate_move():
	pass

func explode():
	if exploding:
		return
	
	exploding = true
	for d in [Vector2(), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]:
		var entity = Grid.get_entity_at_position(get_grid_position() + d)
		if entity != null and entity.has_method("explode"):
			entity.explode()
	queue_free()
