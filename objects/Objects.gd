extends Reference

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
		"id": TileType.AIR,
		"name": "air",
		"label": "Air",
		"letters": ".\'"
	},
	{
		"id": TileType.SOLID,
		"name": "solid",
		"label": "Solid",
		"letters": "#@$%?S"
	},
	{
		"id": TileType.LADDER,
		"name": "ladder",
		"label": "Ladder",
		"letters": "=%\'\"|L"
	},
	{
		"id": TileType.ACID,
		"name": "acid",
		"label": "Acid",
		"letters": "~\\/xX"
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
		"id": EntityType.MINILENS,
		"name": "minilens",
		"label": "Minilens",
		"scene_path": "res://objects/minilens/minilens.tscn",
		"letters": "M><RmPp"
	},
	{
		"id": EntityType.BARREL,
		"name": "barrel",
		"label": "Barrel",
		"scene_path": "res://objects/barrel/barrel.tscn",
		"letters": "BbA[{}]HNR"
	},
	{
		"id": EntityType.BOX,
		"name": "box",
		"label": "Box",
		"scene_path": "res://objects/box/box.tscn",
		"letters": "X$@#&"
	},
	{
		"id": EntityType.FLOWER,
		"name": "flower",
		"label": "Flower",
		"scene_path": "res://objects/flower/flower.tscn",
		"letters": "*Ff"
	},
	{
		"id": EntityType.BOMB,
		"name": "bomb",
		"label": "Bomb",
		"scene_path": "res://objects/bomb/bomb_pickup.tscn",
		"letters": "!%b"
	},
	{
		"id": EntityType.PRIMED_BOMB,
		"name": "primed_bomb",
		"label": "Primed Bomb",
		"scene_path": "res://objects/bomb/bomb.tscn",
		"letters": "@"
	},
	{
		"id": EntityType.UNSTABLE,
		"name": "unstable",
		"label": "Unstable",
		"scene_path": "res://objects/unstable_ground/unstable_ground.tscn",
		"letters": "^@%?"
	},
	{
		"id": EntityType.TELEPORT,
		"name": "teleport",
		"label": "Teleport",
		"scene_path": "res://objects/teleport/teleport.tscn",
		"letters": "123456789",
		"property_editor_scene_path": "res://objects/teleport/teleport_editor.tscn"
	},
]
const EntityByName := {
	"minilens": EntityType.MINILENS,
	"barrel": EntityType.BARREL,
	"box": EntityType.BOX,
	"flower": EntityType.FLOWER,
	"bomb": EntityType.BOMB,
	"primed_bomb": EntityType.PRIMED_BOMB,
	"unstable": EntityType.UNSTABLE,
	"teleport": EntityType.TELEPORT,
}
const EntityByScenePath := {
	"res://objects/minilens/minilens.tscn": EntityType.MINILENS,
	"res://objects/barrel/barrel.tscn": EntityType.BARREL,
	"res://objects/box/box.tscn": EntityType.BOX,
	"res://objects/flower/flower.tscn": EntityType.FLOWER,
	"res://objects/bomb/bomb_pickup.tscn": EntityType.BOMB,
	"res://objects/bomb/bomb.tscn": EntityType.PRIMED_BOMB,
	"res://objects/unstable_ground/unstable_ground.tscn": EntityType.UNSTABLE,
	"res://objects/teleport/teleport.tscn": EntityType.TELEPORT,
}

static func get_object_type_by_name( object_name: String ) -> int:
	var object_type : int = ObjectType.ENTITY
	if TileByName.has(object_name):
		object_type = ObjectType.TILE
	return object_type
static func is_tile_name( object_name : String ) -> bool:
	return TileByName.has(object_name)
static func is_entity_name( object_name : String ) -> bool:
	return EntityByName.has(object_name)