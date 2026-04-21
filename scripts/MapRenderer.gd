## MapRenderer.gd
## Lee MapData y genera los nodos MeshInstance3D y StaticBody3D correspondientes.
## Cada capa (layer) tiene un offset en el eje Y global del motor.
##
## Dimensiones:
##   CELL_SIZE = 2.0 unidades  (tamaño total de una celda en X y Z)
##   CELL_HEIGHT = 2.0 unidades (altura de una capa)
##   WALL_THICKNESS = CELL_SIZE / 4.0 = 0.5 unidades (reservado para referencias externas)

class_name MapRenderer
extends Node3D

const CELL_SIZE: float = 2.0
const CELL_HEIGHT: float = 2.0
const WALL_THICKNESS: float = CELL_SIZE / 4.0
const GRID_HALF: int = 20
const NUM_STEPS: int = 4

## Referencia al MapData que se va a renderizar.
var map_data: MapData = null

## Nodo contenedor de todos los tiles instanciados.
var _tile_root: Node3D = null

## Diccionario Vector3i -> Node3D (nodo instanciado para cada celda).
var _tile_nodes: Dictionary = {}

## Índice de la capa máxima visible (para ocultamiento de capas superiores).
var max_visible_layer: int = 0

## MeshInstance3D que muestra la rejilla de edición.
var _grid_mesh_instance: MeshInstance3D = null


func _ready() -> void:
	_tile_root = Node3D.new()
	_tile_root.name = "TileRoot"
	add_child(_tile_root)


## Asigna el MapData y conecta la señal de cambio de celda.
func setup(data: MapData) -> void:
	if map_data != null and map_data.cell_changed.is_connected(_on_cell_changed):
		map_data.cell_changed.disconnect(_on_cell_changed)
	map_data = data
	map_data.cell_changed.connect(_on_cell_changed)
	rebuild_all()


## Reconstruye todos los nodos a partir del MapData actual.
func rebuild_all() -> void:
	for child in _tile_root.get_children():
		child.queue_free()
	_tile_nodes.clear()

	if map_data == null:
		return

	for pos in map_data.get_all_positions():
		var resource: MapTileResource = map_data.get_tile(pos)
		if resource != null:
			_spawn_tile(pos, resource)

	_update_layer_visibility()
	draw_grid(max_visible_layer)


## Responde a cambios individuales de celdas.
func _on_cell_changed(pos: Vector3i, resource: MapTileResource) -> void:
	_remove_tile_node(pos)
	if resource != null:
		_spawn_tile(pos, resource)
	_update_layer_visibility()


## Instancia el nodo 3D para un tile en la posición dada.
func _spawn_tile(pos: Vector3i, resource: MapTileResource) -> void:
	var world_pos := _grid_to_world(pos, resource.tile_type)
	var container := Node3D.new()
	container.name = "Tile_%d_%d_%d" % [pos.x, pos.y, pos.z]
	container.position = world_pos
	_tile_root.add_child(container)
	_tile_nodes[pos] = container

	match resource.tile_type:
		MapTileResource.TileType.FLOOR:
			_build_floor(container, resource)
		MapTileResource.TileType.WALL:
			_build_wall(container, resource)
		MapTileResource.TileType.DECORATION:
			_build_decoration(container, resource)
		MapTileResource.TileType.LIGHT_SOURCE:
			_build_light_source(container, resource)
		MapTileResource.TileType.STAIRS:
			_build_stairs(container, resource)


## Elimina el nodo correspondiente a una posición.
func _remove_tile_node(pos: Vector3i) -> void:
	if _tile_nodes.has(pos):
		_tile_nodes[pos].queue_free()
		_tile_nodes.erase(pos)


## Convierte una posición de grilla a posición en el mundo 3D.
## Las paredes, escaleras y fuentes de luz tienen su base en (layer-1)*CELL_HEIGHT,
## de modo que al colocarse en la capa 1 arrancan al nivel del suelo (y=0).
func _grid_to_world(pos: Vector3i, tile_type: MapTileResource.TileType) -> Vector3:
	var x := pos.x * CELL_SIZE
	var z := pos.z * CELL_SIZE
	var y: float
	match tile_type:
		MapTileResource.TileType.WALL, \
		MapTileResource.TileType.STAIRS, \
		MapTileResource.TileType.LIGHT_SOURCE:
			y = (pos.y - 1) * CELL_HEIGHT
		_:
			y = pos.y * CELL_HEIGHT
	return Vector3(x, y, z)


# ---------------------------------------------------------------------------
# Constructores de geometría
# ---------------------------------------------------------------------------

func _build_floor(parent: Node3D, resource: MapTileResource) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "FloorMesh"

	if resource.mesh_override != null:
		mesh_instance.mesh = resource.mesh_override
	else:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, 0.1, CELL_SIZE)
		mesh_instance.mesh = box

	_apply_material(mesh_instance, resource)
	parent.add_child(mesh_instance)
	_add_static_body(parent, mesh_instance)


func _build_wall(parent: Node3D, resource: MapTileResource) -> void:
	# La pared ocupa toda la celda en X y Z (bloque sólido de CELL_SIZE × CELL_SIZE),
	# con altura CELL_HEIGHT, para que encaje perfectamente con los bordes del suelo.
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "WallMesh"

	if resource.mesh_override != null:
		mesh_instance.mesh = resource.mesh_override
	else:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, CELL_HEIGHT, CELL_SIZE)
		mesh_instance.mesh = box

	# La base de la pared queda en y=0 del contenedor (que ya está ajustado).
	mesh_instance.position.y = CELL_HEIGHT / 2.0

	_apply_material(mesh_instance, resource)
	parent.add_child(mesh_instance)
	_add_static_body(parent, mesh_instance)


func _build_stairs(parent: Node3D, resource: MapTileResource) -> void:
	# Escalera de NUM_STEPS peldaños que asciende en dirección Z dentro de la celda.
	# Cada peldaño es un BoxMesh más alto que el anterior.
	var step_z_width: float = CELL_SIZE / NUM_STEPS
	for i in range(NUM_STEPS):
		var step_height: float = CELL_HEIGHT * (i + 1.0) / NUM_STEPS
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "Step_%d" % i

		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, step_height, step_z_width)
		mesh_instance.mesh = box

		# Centro del peldaño en Y y en Z dentro del contenedor.
		mesh_instance.position.y = step_height / 2.0
		mesh_instance.position.z = (i + 0.5) * step_z_width - CELL_SIZE / 2.0

		_apply_material(mesh_instance, resource)
		parent.add_child(mesh_instance)
		_add_static_body(parent, mesh_instance)


func _build_decoration(parent: Node3D, resource: MapTileResource) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "DecoMesh"

	if resource.mesh_override != null:
		mesh_instance.mesh = resource.mesh_override
	else:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE * 0.4, CELL_SIZE * 0.8, CELL_SIZE * 0.4)
		mesh_instance.mesh = box

	mesh_instance.position.y = (CELL_SIZE * 0.8) / 2.0
	_apply_material(mesh_instance, resource)
	parent.add_child(mesh_instance)


func _build_light_source(parent: Node3D, resource: MapTileResource) -> void:
	# Pequeña malla decorativa para la fuente de luz.
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "LightMesh"
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_instance.mesh = sphere
	mesh_instance.position.y = CELL_HEIGHT * 0.75

	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2)
	mat.emission_energy_multiplier = resource.light_energy
	if resource.texture_albedo != null:
		mat.albedo_texture = resource.texture_albedo
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)

	# Luz omnidireccional.
	var omni := OmniLight3D.new()
	omni.name = "OmniLight"
	omni.omni_range = CELL_SIZE * 3.0
	omni.light_energy = resource.light_energy
	omni.light_color = Color(1.0, 0.7, 0.2)
	omni.position.y = CELL_HEIGHT * 0.75
	parent.add_child(omni)


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

func _apply_material(mesh_instance: MeshInstance3D, resource: MapTileResource) -> void:
	var mat := StandardMaterial3D.new()
	if resource.texture_albedo != null:
		mat.albedo_texture = resource.texture_albedo
	else:
		# Color por defecto según tipo de tile.
		match resource.tile_type:
			MapTileResource.TileType.FLOOR:
				mat.albedo_color = Color(0.55, 0.50, 0.45)  # Gris piedra
			MapTileResource.TileType.WALL:
				mat.albedo_color = Color(0.60, 0.45, 0.30)  # Marrón madera
			MapTileResource.TileType.STAIRS:
				mat.albedo_color = Color(0.52, 0.47, 0.42)  # Piedra escalera
			_:
				mat.albedo_color = Color(0.8, 0.8, 0.8)

	if resource.texture_normal != null:
		mat.normal_enabled = true
		mat.normal_texture = resource.texture_normal

	if resource.is_emissive:
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = resource.light_energy

	mesh_instance.material_override = mat


func _add_static_body(parent: Node3D, mesh_instance: MeshInstance3D) -> void:
	var static_body := StaticBody3D.new()
	static_body.name = "StaticBody"
	var col := CollisionShape3D.new()
	col.name = "CollisionShape"
	var shape := mesh_instance.mesh.create_trimesh_shape()
	col.shape = shape
	col.transform = mesh_instance.transform
	static_body.add_child(col)
	parent.add_child(static_body)


## Actualiza la visibilidad de las capas según max_visible_layer.
func _update_layer_visibility() -> void:
	for pos in _tile_nodes:
		var node: Node3D = _tile_nodes[pos]
		node.visible = (pos.y <= max_visible_layer)


## Cambia la capa máxima visible y redibuja la rejilla.
func set_max_visible_layer(layer: int) -> void:
	max_visible_layer = layer
	_update_layer_visibility()
	draw_grid(layer)


## Dibuja (o redibuja) la rejilla de edición a la altura de la capa dada.
func draw_grid(layer: int) -> void:
	if _grid_mesh_instance != null:
		_grid_mesh_instance.queue_free()
		_grid_mesh_instance = null

	# La rejilla se sitúa ligeramente por encima del plano de edición.
	var grid_y: float = layer * CELL_HEIGHT + 0.08

	var imesh := ImmediateMesh.new()
	imesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-GRID_HALF, GRID_HALF + 1):
		# Líneas paralelas al eje Z.
		imesh.surface_add_vertex(Vector3(i * CELL_SIZE, grid_y, -GRID_HALF * CELL_SIZE))
		imesh.surface_add_vertex(Vector3(i * CELL_SIZE, grid_y,  GRID_HALF * CELL_SIZE))
		# Líneas paralelas al eje X.
		imesh.surface_add_vertex(Vector3(-GRID_HALF * CELL_SIZE, grid_y, i * CELL_SIZE))
		imesh.surface_add_vertex(Vector3( GRID_HALF * CELL_SIZE, grid_y, i * CELL_SIZE))
	imesh.surface_end()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_grid_mesh_instance = MeshInstance3D.new()
	_grid_mesh_instance.name = "GridOverlay"
	_grid_mesh_instance.mesh = imesh
	_grid_mesh_instance.material_override = mat
	add_child(_grid_mesh_instance)


## Muestra u oculta la rejilla de edición.
func set_grid_visible(vis: bool) -> void:
	if _grid_mesh_instance != null:
		_grid_mesh_instance.visible = vis
