extends Node

enum Flag {
	SOLID = 0
	LADDER = 1
	ACID = 2
}

const GRID_SIZE = Vector2(96, 96)

var _entities = {} # entity => [position:flags]
var _positions = {} # position:flags => entity

func _get_key(position: Vector2, flag: int):
	return Vector3(position.x, position.y, flag)

func add_entity_position(entity: Object, position: Vector2, flag: int = Flag.SOLID) -> void:
	var key = _get_key(position, flag)
	if key in _positions:
		if entity != _positions[key]:
			var other_entity = _positions[key]
			_entities[other_entity].erase(key)
			if _entities[other_entity].size() == 0:
				_entities.erase(other_entity)
	
	_positions[key] = entity
	
	if not (entity in _entities):
		_entities[entity] = []
	_entities[entity].push_back(key)

func remove_entity_position(entity: Object, position: Vector2, flag: int = Flag.SOLID) -> void:
	var key = _get_key(position, flag)
	if not (entity in _entities):
		return
	
	if entity != _positions.get(key, null):
		return
	
	_positions.erase(key)
	_entities[entity].erase(key)
	if _entities[entity].size() == 0:
		_entities.erase(entity)

func get_entity_at_position(position: Vector2, flag: int = Flag.SOLID) -> Object:
	var key = _get_key(position, flag)
	return _positions.get(key, null)

func has_entity_at_position(position: Vector2, flag: int = Flag.SOLID) -> bool:
	var key = _get_key(position, flag)
	return _positions.get(key, null) != null

func remove_entity(entity) -> void:
	if entity in _entities:
		for key in _entities[entity]:
			_positions.erase(key)
		_entities.erase(entity)
