## MapData.gd
## Gestiona el diccionario de celdas del mapa multicapa.
## Clave: Vector3i(x, layer, z) donde layer es el índice de capa (y).

class_name MapData
extends RefCounted

## Diccionario principal: Vector3i -> MapTileResource
var _cells: Dictionary = {}

## Señal emitida cuando una celda cambia.
signal cell_changed(pos: Vector3i, resource: MapTileResource)


## Coloca o reemplaza un tile en la posición dada.
## pos.y es el índice de capa (0 = suelo, positivo = arriba, negativo = sótano).
func set_tile(pos: Vector3i, resource: MapTileResource) -> void:
	_cells[pos] = resource
	cell_changed.emit(pos, resource)


## Obtiene el tile en la posición dada. Devuelve null si no existe.
func get_tile(pos: Vector3i) -> MapTileResource:
	return _cells.get(pos, null)


## Elimina el tile en la posición dada.
func remove_tile(pos: Vector3i) -> void:
	if _cells.has(pos):
		_cells.erase(pos)
		cell_changed.emit(pos, null)


## Verifica si existe un tile en la posición dada.
func has_tile(pos: Vector3i) -> bool:
	return _cells.has(pos)


## Devuelve todas las posiciones ocupadas.
func get_all_positions() -> Array:
	return _cells.keys()


## Devuelve todos los tiles como pares [Vector3i, MapTileResource].
func get_all_tiles() -> Array:
	var result: Array = []
	for pos in _cells:
		result.append([pos, _cells[pos]])
	return result


## Devuelve las posiciones de una capa específica.
func get_tiles_at_layer(layer: int) -> Array:
	var result: Array = []
	for pos in _cells:
		if pos.y == layer:
			result.append(pos)
	return result


## Limpia todo el mapa.
func clear() -> void:
	_cells.clear()


## Exporta el mapa a un diccionario serializable.
func serialize() -> Dictionary:
	var data: Dictionary = {}
	for pos in _cells:
		var key := "%d,%d,%d" % [pos.x, pos.y, pos.z]
		data[key] = _cells[pos].id
	return data
