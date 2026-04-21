## UI.gd
## Interfaz de usuario: selector de tiles y botón de cambio de modo.

class_name UI
extends CanvasLayer

## Referencia al GameManager.
var _game_manager: GameManager = null

## Referencia al contenedor del selector de tiles.
@onready var tile_selector: HBoxContainer = $TileSelector
@onready var mode_button: Button = $ModeButton
@onready var layer_label: Label = $LayerLabel
@onready var instructions_label: Label = $InstructionsLabel


func setup(registry: TileRegistry, game_manager: GameManager) -> void:
	_game_manager = game_manager
	_build_tile_selector(registry)


func _ready() -> void:
	mode_button.pressed.connect(_on_mode_button_pressed)


func _build_tile_selector(registry: TileRegistry) -> void:
	# Limpiar botones anteriores.
	for child in tile_selector.get_children():
		child.queue_free()

	for tile in registry.get_all():
		var btn := Button.new()
		btn.text = tile.id.replace("_", " ").capitalize()
		btn.custom_minimum_size = Vector2(100, 40)
		var tile_id: String = tile.id  # Captura para la lambda.
		btn.pressed.connect(func(): _game_manager.select_tile(tile_id))
		tile_selector.add_child(btn)


func _on_mode_button_pressed() -> void:
	if _game_manager != null:
		_game_manager._toggle_mode()


## Actualiza la UI cuando cambia el modo.
func on_mode_changed(mode: GameManager.GameMode) -> void:
	match mode:
		GameManager.GameMode.BUILD:
			mode_button.text = "▶  Explorar  (T)"
			tile_selector.visible = true
			layer_label.visible = true
			instructions_label.text = "LMB: Colocar  |  RMB: Borrar  |  Rueda: Zoom  |  Clic Medio: Pan  |  Q/E: Capa"
		GameManager.GameMode.EXPLORE:
			mode_button.text = "🔨  Construir  (T)"
			tile_selector.visible = false
			layer_label.visible = false
			instructions_label.text = "WASD: Mover  |  Space: Saltar  |  T: Volver al editor  |  Esc: Liberar ratón"


## Actualiza la etiqueta de la capa activa.
func set_layer_label(layer: int) -> void:
	layer_label.text = "Capa: %d" % layer
