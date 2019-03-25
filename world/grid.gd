extends Node

const GRID_SIZE = Vector2(96, 96)

var _entities = {} # entity => [position]
var _positions = {} # position => entity

func add_entity_position(entity: Object, position: Vector2):
	if position in _positions:
		if entity != _positions[position]:
			var other_entity = _positions[position]
			_entities[other_entity].erase(position)
			if _entities[other_entity].size() == 0:
				_entities.erase(other_entity)
	
	_positions[position] = entity
	
	if not (entity in _entities):
		_entities[entity] = []
	_entities[entity].push_back(position)

func remove_entity_position(entity: Object, position: Vector2):
	if not (entity in _entities):
		return
	
	if entity != _positions.get(position, null):
		return
	
	_positions.erase(position)
	_entities[entity].erase(position)
	if _entities[entity].size() == 0:
		_entities.erase(entity)

func get_entity_at_position(position: Vector2):
	return _positions.get(position, null)

func remove_entity(entity):
	if entity in _entities:
		for position in _entities[entity]:
			_positions.erase(position)
		_entities.erase(entity)
