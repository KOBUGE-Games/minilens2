extends Node

enum ObjectType {
	TILE,
	ENTITY,
	COUNT
}


enum TileType {
	AIR,
	SOLID,
	LADDER,
	ACID,
	COUNT
}

const TileData := [
	{
		id = TileType.AIR,
		name = "air",
		letters = ".\'"
	},
	{
		id = TileType.SOLID,
		name = "solid",
		letters = "#@$%?S"
	},
	{
		id = TileType.LADDER,
		name = "ladder",
		letters = "=%\'\"|L"
	},
	{
		id = TileType.ACID,
		name = "acid",
		letters = "~\\/xX"
	}
]

const TileByName := {
	"air": TileType.AIR,
	"solid": TileType.SOLID,
	"ladder": TileType.LADDER,
	"acid": TileType.ACID,
}

enum EntityType {
	MINILENS,
	BARREL,
	BOX,
	FLOWER,
	BOMB,
	PRIMED_BOMB,
	UNSTABLE,
	TELEPORT,
	COUNT
}

const EntityData := [
	{
		id = EntityType.MINILENS,
		name = "minilens",
		scene_path = "res://objects/minilens/minilens.tscn",
		letters = "M><RmPp",
		property_editor_scene_path = "res://objects/minilens/minilens_editor.tscn"
	},
	{
		id = EntityType.BARREL,
		name = "barrel",
		scene_path = "res://objects/barrel/barrel.tscn",
		letters = "BbA[{}]HNR"
	},
	{
		id = EntityType.BOX,
		name = "box",
		scene_path = "res://objects/box/box.tscn",
		letters = "X$@#&"
	},
	{
		id = EntityType.FLOWER,
		name = "flower",
		scene_path = "res://objects/flower/flower.tscn",
		letters = "*Ff"
	},
	{
		id = EntityType.BOMB,
		name = "bomb",
		scene_path = "res://objects/bomb/bomb_pickup.tscn",
		letters = "!%b"
	},
	{
		id = EntityType.PRIMED_BOMB,
		name = "primed_bomb",
		scene_path = "res://objects/bomb/bomb.tscn",
		letters = "@"
	},
	{
		id = EntityType.UNSTABLE,
		name = "unstable",
		scene_path = "res://objects/unstable_ground/unstable_ground.tscn",
		letters = "^@%?"
	},
	{
		id = EntityType.TELEPORT,
		name = "teleport",
		scene_path = "res://objects/teleport/teleport.tscn",
		letters = "123456789",
		property_editor_scene_path = "res://objects/teleport/teleport_editor.tscn"
	},
]

# Not const, since there is no way to mark _build_lookup_table const
var EntityByName := _build_lookup_table(EntityData, "name", "id")

var EntityByScenePath := _build_lookup_table(EntityData, "scene_path", "id")

func get_object_type_by_name(object_name: String) -> int:
	var object_type: int = ObjectType.ENTITY
	if TileByName.has(object_name):
		object_type = ObjectType.TILE
	return object_type

func is_tile_name(object_name: String) -> bool:
	return TileByName.has(object_name)

func is_entity_name(object_name: String) -> bool:
	return EntityByName.has(object_name)

func _build_lookup_table(data: Array, lookup_property: String, id_property: String) -> Dictionary:
	var result := {}
	for item in data:
		if item.has(lookup_property) and item.has(id_property):
			result[item[lookup_property]] = item[id_property]
	return result
