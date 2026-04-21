## MapRenderer.gd
## Lee MapData y genera los nodos MeshInstance3D y StaticBody3D correspondientes.
## Cada capa (layer) tiene un offset en el eje Y global del motor.
##
## Dimensiones:
##   CELL_SIZE = 2.0 unidades  (tamaño total de una celda en X y Z)
##   CELL_HEIGHT = 2.0 unidades (altura de una capa)
##   WALL_THICKNESS = CELL_SIZE / 4.0 = 0.5 unidades

class_name MapRenderer
extends Node3D

const CELL_SIZE: float = 2.0
const CELL_HEIGHT: float = 2.0
const WALL_THICKNESS: float = CELL_SIZE / 4.0

## Referencia al MapData que se va a renderizar.
var map_data: MapData = null

## Nodo contenedor de todos los tiles instanciados.
var _tile_root: Node3D = null

## Diccionario Vector3i -> Node3D (nodo instanciado para cada celda).
var _tile_nodes: Dictionary = {}

## Índice de la capa máxima visible (para ocultamiento de capas superiores).
var max_visible_layer: int = 0


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


## Elimina el nodo correspondiente a una posición.
func _remove_tile_node(pos: Vector3i) -> void:
	if _tile_nodes.has(pos):
		_tile_nodes[pos].queue_free()
		_tile_nodes.erase(pos)


## Convierte una posición de grilla a posición en el mundo 3D.
func _grid_to_world(pos: Vector3i, tile_type: MapTileResource.TileType) -> Vector3:
	var x := pos.x * CELL_SIZE
	var z := pos.z * CELL_SIZE
	var y := pos.y * CELL_HEIGHT
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
	# La pared ocupa el largo completo de la celda (CELL_SIZE) pero solo
	# WALL_THICKNESS de ancho, alineada al centro de la celda.
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "WallMesh"

	if resource.mesh_override != null:
		mesh_instance.mesh = resource.mesh_override
	else:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE, CELL_HEIGHT, WALL_THICKNESS)
		mesh_instance.mesh = box

	# Elevar la pared para que su base esté en y=0 del contenedor.
	mesh_instance.position.y = CELL_HEIGHT / 2.0

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


## Cambia la capa máxima visible (para facilitar edición de interiores).
func set_max_visible_layer(layer: int) -> void:
	max_visible_layer = layer
	_update_layer_visibility()
