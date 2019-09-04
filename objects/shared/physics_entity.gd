extends Node2D

const LEFT = Vector2(-1, 0)
const RIGHT = Vector2(1, 0)
const UP = Vector2(0, -1)
const DOWN = Vector2(0, 1)

export var fall_speed := 768.0 # pixels/sec
export var walk_speed := 192.0 # pixels/sec

var node_to_move: Node2D
var tween: Tween
var _moving := false
var _moving_direction : Vector2
var _moving_speed : float
var _moved_last_frame := false
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
	if !_moving:
		call_deferred("calculate_move")

func calculate_move() -> void: pass

func get_mass() -> float:
	return 1.0

func get_grid_position() -> Vector2:
	return (global_position / Grid.GRID_SIZE - Vector2(0.5, 0.5)).round()

func move(direction: Vector2, stength: float, speed: float = 0.0) -> float:
	"""
	Moves the node in the specified direction.
	Returns the speed of the movement, or -INF if unable to move.
	"""
	if _moving:
		if _moving_direction.normalized().dot(direction.normalized()) > 0.9 and not _moved_last_frame:
			return _moving_speed
		return -INF
	
	stength -= get_mass()
	if stength < 0:
		return -INF
	
	if speed == 0.0: # Default value
		speed = abs(direction.x * walk_speed) + abs(direction.y * fall_speed)
	
	var entity_ahead = Grid.get_entity_at_position(get_grid_position() + direction)
	if entity_ahead != null:
		speed = entity_ahead.move(direction, stength, speed)
		if speed <= 0.0:
			return speed
	
	var old_position = get_grid_position()
	global_position += direction * Grid.GRID_SIZE
	Grid.add_entity_position(self, get_grid_position())
	_animate_move(direction, speed, old_position)
	
	return speed

func _animate_move(direction: Vector2, speed: float, position_to_remove: Vector2):
	_moving = true
	_moved_last_frame = true
	_moving_direction = direction
	_moving_speed = speed
	
	node_to_move.position = -direction * Grid.GRID_SIZE
	tween.interpolate_property(
		node_to_move, "position",
		node_to_move.position, Vector2(),
		(direction * Grid.GRID_SIZE).length() / speed, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
	yield(tween, "tween_completed")
	
	Grid.remove_entity_position(self, position_to_remove)
	_moving = false
	
	call_deferred("calculate_move")
	
	yield(get_tree(), "physics_frame")
	_moved_last_frame = false
