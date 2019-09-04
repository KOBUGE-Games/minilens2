extends Node2D

class_name PhysicsEntity

enum Priority {
	NONE,
	MOVE,
	FALL,
	TELEPORT,
	IN_MOVE = 100
}
const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)
const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)

var node_to_move: Node2D
var tween: Tween
var _moving_priority: int = Priority.NONE
var _moving_direction: Vector2
var _moving_speed: float
var _deferred_grid_registration := false

func _enter_tree() -> void:
	tween = Tween.new()
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	add_child(tween)
	var grid_pos = get_grid_position()
	global_position = (grid_pos + Vector2(0.5, 0.5)) * Grid.GRID_SIZE
	
	if !Grid.has_entity_at_position(grid_pos):
		Grid.add_entity_position(self, grid_pos)
	else:
		_deferred_grid_registration = true

func _exit_tree() -> void:
	Grid.remove_entity(self)

func _physics_process(_delta):
	if _deferred_grid_registration:
		var grid_pos = get_grid_position()
		if !Grid.has_entity_at_position(grid_pos):
			Grid.add_entity_position(self, grid_pos)
			_deferred_grid_registration = false
	if _moving_priority != Priority.IN_MOVE:
		calculate_move()

func calculate_move() -> void: pass

func get_mass() -> float:
	return 1.0

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func move(direction: Vector2, priority: int, speed: float, strength: float = -1.0) -> float:
	"""
	Moves the node in the specified direction.
	Returns the speed of the movement, or -INF if unable to move.
	"""
	
	if _moving_priority == Priority.IN_MOVE and _moving_direction == direction:
		return _moving_speed
	
	if _moving_priority >= priority:
		return -INF
	
	if strength == -1.0:
		strength = get_mass()
	
	strength -= get_mass()
	if strength < 0:
		return -INF
	
	var entity_ahead = Grid.get_entity_at_position(get_grid_position() + direction)
	if entity_ahead != null:
		speed = entity_ahead.move(direction, priority, speed, strength)
		if speed <= 0.0:
			return speed
	
	if _moving_priority == Priority.NONE:
		call_deferred("_finish_move")
	
	_moving_priority = priority
	_moving_direction = direction
	_moving_speed = speed
	
	return speed

func confirm_move(direction: Vector2) -> float:
	if _moving_direction == direction:
		return _moving_speed
	return -INF

func _finish_move() -> void:
	var entity_ahead = Grid.get_entity_at_position(get_grid_position() + _moving_direction)
	if entity_ahead != null and entity_ahead.has_method("confirm_move"):
		_moving_speed = entity_ahead.confirm_move(_moving_direction)
		if _moving_speed <= 0.0:
			_moving_priority = Priority.NONE
			return
	
	_moving_priority = Priority.IN_MOVE
	
	var old_position = get_grid_position()
	global_position += _moving_direction * Grid.GRID_SIZE
	
	Grid.add_entity_position(self, get_grid_position())
	node_to_move.position = -_moving_direction * Grid.GRID_SIZE
	
	tween.interpolate_property(
		node_to_move, "position",
		node_to_move.position, Vector2(),
		(_moving_direction * Grid.GRID_SIZE).length() / _moving_speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	
	_moving_priority = Priority.NONE
	Grid.remove_entity_position(self, old_position)
#	calculate_move()
