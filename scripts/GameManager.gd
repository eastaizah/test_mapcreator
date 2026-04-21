## GameManager.gd
## Nodo principal que orquesta el mapa, el renderizador, las cámaras y la UI.
## Gestiona el cambio entre "Modo Constructor" y "Modo Exploración".

class_name GameManager
extends Node3D

enum GameMode {
	BUILD,
	EXPLORE
}

@export var initial_mode: GameMode = GameMode.BUILD

## Referencias a nodos hijos (asignadas en _ready).
@onready var map_renderer: MapRenderer = $MapRenderer
@onready var editor_camera: EditorCamera = $EditorCamera
@onready var player: FirstPersonController = $Player
@onready var sun: DirectionalLight3D = $Sun
@onready var ui: CanvasLayer = $UI

## Datos del mapa.
var map_data: MapData = null

## Registro de tiles disponibles.
var tile_registry: TileRegistry = null

## Tile actualmente seleccionado en el editor.
var selected_tile_id: String = "stone_floor"

## Modo actual.
var current_mode: GameMode = GameMode.BUILD


func _ready() -> void:
	map_data = MapData.new()
	tile_registry = TileRegistry.new()

	map_renderer.setup(map_data)
	editor_camera.tile_clicked.connect(_on_editor_tile_clicked)

	# Pasar el registro a la UI para que construya el selector.
	if ui.has_method("setup"):
		ui.setup(tile_registry, self)

	_set_mode(initial_mode)
	_populate_demo_map()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mode"):
		_toggle_mode()

	if current_mode == GameMode.BUILD:
		if event.is_action_pressed("layer_up"):
			_change_layer(1)
		elif event.is_action_pressed("layer_down"):
			_change_layer(-1)


func _toggle_mode() -> void:
	if current_mode == GameMode.BUILD:
		_set_mode(GameMode.EXPLORE)
	else:
		_set_mode(GameMode.BUILD)


## Mueve la capa activa en delta pasos y actualiza el renderizador y la UI.
func _change_layer(delta: int) -> void:
	editor_camera.current_layer += delta
	map_renderer.set_max_visible_layer(editor_camera.current_layer)
	_update_layer_label()


func _set_mode(mode: GameMode) -> void:
	current_mode = mode

	match mode:
		GameMode.BUILD:
			editor_camera.visible = true
			editor_camera.current = true
			player.deactivate()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			map_renderer.set_grid_visible(true)

		GameMode.EXPLORE:
			editor_camera.visible = false
			# Colocar al jugador en la posición inicial del mapa.
			player.global_position = _find_spawn_position()
			player.activate()
			map_renderer.set_grid_visible(false)

	if ui.has_method("on_mode_changed"):
		ui.on_mode_changed(mode)


func _on_editor_tile_clicked(grid_pos: Vector3i, is_erase: bool) -> void:
	if is_erase:
		map_data.remove_tile(grid_pos)
	else:
		var resource := tile_registry.get_tile(selected_tile_id)
		if resource != null:
			map_data.set_tile(grid_pos, resource)


## Selecciona el tile activo en el editor (llamado desde la UI).
func select_tile(tile_id: String) -> void:
	selected_tile_id = tile_id


## Busca una posición de spawn válida (primer tile FLOOR en la capa 0).
func _find_spawn_position() -> Vector3:
	for pos in map_data.get_tiles_at_layer(0):
		var tile := map_data.get_tile(pos)
		if tile != null and tile.tile_type == MapTileResource.TileType.FLOOR:
			return Vector3(
				pos.x * MapRenderer.CELL_SIZE,
				MapRenderer.CELL_HEIGHT,
				pos.z * MapRenderer.CELL_SIZE
			)
	return Vector3(0.0, 2.0, 0.0)


func _update_layer_label() -> void:
	if ui.has_method("set_layer_label"):
		ui.set_layer_label(editor_camera.current_layer)


## Crea un mapa de demostración pequeño para mostrar la funcionalidad.
func _populate_demo_map() -> void:
	var floor_tile := tile_registry.get_tile("stone_floor")
	var wall_tile := tile_registry.get_tile("wood_wall")
	var torch_tile := tile_registry.get_tile("torch")
	var stairs_tile := tile_registry.get_tile("stairs")

	# Suelo 5x5 en la capa 0.
	for x in range(-2, 3):
		for z in range(-2, 3):
			map_data.set_tile(Vector3i(x, 0, z), floor_tile)

	# Paredes en el perímetro (capa 1 → base en y=0 gracias al ajuste de Y).
	for i in range(-2, 3):
		map_data.set_tile(Vector3i(i, 1, -2), wall_tile)
		map_data.set_tile(Vector3i(i, 1,  2), wall_tile)
		map_data.set_tile(Vector3i(-2, 1, i), wall_tile)
		map_data.set_tile(Vector3i( 2, 1, i), wall_tile)

	# Antorchas en las esquinas.
	map_data.set_tile(Vector3i(-2, 1, -2), torch_tile)
	map_data.set_tile(Vector3i( 2, 1, -2), torch_tile)
	map_data.set_tile(Vector3i(-2, 1,  2), torch_tile)
	map_data.set_tile(Vector3i( 2, 1,  2), torch_tile)

	# Escalera de demostración en el interior de la sala (asciende hacia +Z).
	map_data.set_tile(Vector3i(0, 1, 1), stairs_tile)
