## EditorCamera.gd
## Cámara para el modo editor (vista aérea/sinóptica).
## Soporta pan con clic medio, zoom con rueda del ratón y
## detección de celda bajo el cursor para colocar/borrar tiles.

class_name EditorCamera
extends Camera3D

const INT32_MAX: int = 2147483647
const PAN_SPEED: float = 0.05
const ZOOM_SPEED: float = 1.5
const ZOOM_MIN: float = 2.0
const ZOOM_MAX: float = 40.0

## Señal emitida cuando el usuario hace clic en una celda de la grilla.
signal tile_clicked(grid_pos: Vector3i, is_erase: bool)

var _panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO

## Referencia al plano de edición para raycasting.
var edit_plane: Plane = Plane(Vector3.UP, 0.0)

## Capa activa que se edita.
var current_layer: int = 0


func _ready() -> void:
	projection = Camera3D.PROJECTION_PERSPECTIVE
	fov = 60.0
	position = Vector3(0.0, 20.0, 10.0)
	rotation_degrees = Vector3(-60.0, 0.0, 0.0)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed
			_last_mouse_pos = event.position

		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				_zoom(-ZOOM_SPEED)

		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				_zoom(ZOOM_SPEED)

		MOUSE_BUTTON_LEFT:
			if event.pressed:
				var grid_pos := _mouse_to_grid(event.position)
				if grid_pos != Vector3i(INT32_MAX, INT32_MAX, INT32_MAX):
					tile_clicked.emit(grid_pos, false)

		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				var grid_pos := _mouse_to_grid(event.position)
				if grid_pos != Vector3i(INT32_MAX, INT32_MAX, INT32_MAX):
					tile_clicked.emit(grid_pos, true)


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _panning:
		var delta := event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		# Mover la cámara en el plano XZ local.
		var right := global_transform.basis.x
		var forward := Vector3(global_transform.basis.z.x, 0.0, global_transform.basis.z.z).normalized()
		position -= right * delta.x * PAN_SPEED
		position += forward * delta.y * PAN_SPEED


func _zoom(amount: float) -> void:
	position.y = clamp(position.y + amount, ZOOM_MIN, ZOOM_MAX)
	# Ajustar también la inclinación para mantener el foco.
	position.z = clamp(position.z + amount * 0.5, ZOOM_MIN * 0.5, ZOOM_MAX * 0.5)


## Convierte la posición del ratón en pantalla a una posición de grilla Vector3i.
func _mouse_to_grid(mouse_pos: Vector2) -> Vector3i:
	var viewport := get_viewport()
	var ray_origin := project_ray_origin(mouse_pos)
	var ray_dir := project_ray_normal(mouse_pos)

	# Intersección con el plano de edición (altura de la capa actual).
	var layer_plane := Plane(Vector3.UP, current_layer * MapRenderer.CELL_HEIGHT)
	var intersection: Variant = layer_plane.intersects_ray(ray_origin, ray_dir)

	if intersection == null:
		return Vector3i(INT32_MAX, INT32_MAX, INT32_MAX)

	var world_pos: Vector3 = intersection
	var grid_x := int(floor(world_pos.x / MapRenderer.CELL_SIZE + 0.5))
	var grid_z := int(floor(world_pos.z / MapRenderer.CELL_SIZE + 0.5))
	return Vector3i(grid_x, current_layer, grid_z)
