## MapTileResource.gd
## Recurso base para cada elemento del mapa.
## Hereda de Resource para permitir serialización y extensibilidad.

class_name MapTileResource
extends Resource

enum TileType {
	FLOOR,
	WALL,
	DECORATION,
	LIGHT_SOURCE
}

@export var id: String = ""
@export var texture_albedo: Texture2D = null
@export var texture_normal: Texture2D = null
@export var tile_type: TileType = TileType.FLOOR
@export var mesh_override: Mesh = null
@export var is_emissive: bool = false
@export var light_energy: float = 1.0

func _init(p_id: String = "", p_type: TileType = TileType.FLOOR) -> void:
	id = p_id
	tile_type = p_type


## Crea un recurso de suelo de piedra por defecto.
static func create_stone_floor() -> MapTileResource:
	var res := MapTileResource.new("stone_floor", TileType.FLOOR)
	res.is_emissive = false
	return res


## Crea un recurso de pared de madera por defecto.
static func create_wood_wall() -> MapTileResource:
	var res := MapTileResource.new("wood_wall", TileType.WALL)
	res.is_emissive = false
	return res


## Crea un recurso de antorcha (fuente de luz).
static func create_torch() -> MapTileResource:
	var res := MapTileResource.new("torch", TileType.LIGHT_SOURCE)
	res.is_emissive = true
	res.light_energy = 2.0
	return res
