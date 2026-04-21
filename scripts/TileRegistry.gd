## TileRegistry.gd
## Registro centralizado de todos los MapTileResource disponibles.
## Proporciona acceso por ID y la lista ordenada para la UI.

class_name TileRegistry
extends RefCounted

## Diccionario id -> MapTileResource.
var _tiles: Dictionary = {}

## Lista ordenada de IDs para la UI.
var tile_ids: Array = []


func _init() -> void:
	_register_defaults()


func _register_defaults() -> void:
	register(MapTileResource.create_stone_floor())
	register(MapTileResource.create_wood_wall())
	register(MapTileResource.create_torch())


## Registra un nuevo tile en el registro.
func register(resource: MapTileResource) -> void:
	_tiles[resource.id] = resource
	if not tile_ids.has(resource.id):
		tile_ids.append(resource.id)


## Obtiene un tile por su ID. Devuelve null si no existe.
func get_tile(id: String) -> MapTileResource:
	return _tiles.get(id, null)


## Devuelve todos los recursos registrados.
func get_all() -> Array:
	var result: Array = []
	for id in tile_ids:
		result.append(_tiles[id])
	return result
