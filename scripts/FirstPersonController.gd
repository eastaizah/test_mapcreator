## FirstPersonController.gd
## CharacterBody3D con control en primera persona.
## WASD para moverse, Space para saltar, ratón para mirar.

class_name FirstPersonController
extends CharacterBody3D

const MOVE_SPEED: float = 5.0
const JUMP_VELOCITY: float = 5.0
const MOUSE_SENSITIVITY: float = 0.003
const GRAVITY: float = 9.8

@onready var camera: Camera3D = $Camera3D

var _pitch: float = 0.0


func _ready() -> void:
	# La cámara del jugador comienza desactivada; se activa en modo jugador.
	if camera != null:
		camera.current = false


func activate() -> void:
	if camera != null:
		camera.current = true
	visible = true
	set_process(true)
	set_physics_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func deactivate() -> void:
	if camera != null:
		camera.current = false
	visible = false
	set_process(false)
	set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseMotion:
		_rotate_camera(event as InputEventMouseMotion)

	# Salir del modo captura con Escape.
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if not visible:
		return

	# Gravedad.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Salto.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Dirección de movimiento horizontal basada en la orientación de la cámara.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, MOVE_SPEED)
		velocity.z = move_toward(velocity.z, 0.0, MOVE_SPEED)

	move_and_slide()


func _rotate_camera(event: InputEventMouseMotion) -> void:
	# Rotación horizontal del cuerpo (yaw).
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

	# Rotación vertical de la cámara (pitch), limitada a ±89°.
	_pitch = clamp(_pitch - event.relative.y * MOUSE_SENSITIVITY, -PI / 2.0 + 0.05, PI / 2.0 - 0.05)
	if camera != null:
		camera.rotation.x = _pitch
