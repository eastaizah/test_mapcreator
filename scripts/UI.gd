## UI.gd
## Interfaz de usuario: panel lateral de tiles (izquierda) y control de capa (derecha).

class_name UI
extends CanvasLayer

## Referencia al GameManager.
var _game_manager: GameManager = null

@onready var mode_button: Button = $ModeButton
@onready var tile_panel: PanelContainer = $TilePanel
@onready var tile_grid: GridContainer = $TilePanel/TileGrid
@onready var layer_panel: VBoxContainer = $LayerPanel
@onready var layer_label: Label = $LayerPanel/LayerLabel
@onready var layer_up_btn: Button = $LayerPanel/LayerUpBtn
@onready var layer_down_btn: Button = $LayerPanel/LayerDownBtn
@onready var instructions_label: Label = $InstructionsLabel


func setup(registry: TileRegistry, game_manager: GameManager) -> void:
	_game_manager = game_manager
	_build_tile_selector(registry)
	layer_up_btn.pressed.connect(func(): _game_manager.change_layer(1))
	layer_down_btn.pressed.connect(func(): _game_manager.change_layer(-1))


func _ready() -> void:
	mode_button.pressed.connect(_on_mode_button_pressed)


func _build_tile_selector(registry: TileRegistry) -> void:
	for child in tile_grid.get_children():
		child.queue_free()

	for tile in registry.get_all():
		var btn := Button.new()
		btn.text = tile.id.replace("_", " ").capitalize()
		btn.custom_minimum_size = Vector2(95, 80)
		btn.size_flags_horizontal = Control.SIZE_FILL
		var tile_id: String = tile.id
		btn.pressed.connect(func(): _game_manager.select_tile(tile_id))
		tile_grid.add_child(btn)


func _on_mode_button_pressed() -> void:
	if _game_manager != null:
		_game_manager._toggle_mode()


## Actualiza la UI cuando cambia el modo.
func on_mode_changed(mode: GameManager.GameMode) -> void:
	match mode:
		GameManager.GameMode.BUILD:
			mode_button.text = "▶  Explorar  (T)"
			tile_panel.visible = true
			layer_panel.visible = true
			instructions_label.text = "LMB: Colocar  |  RMB: Borrar  |  Rueda: Zoom  |  Clic Medio: Pan  |  Q/E: Capa"
		GameManager.GameMode.EXPLORE:
			mode_button.text = "🔨  Construir  (T)"
			tile_panel.visible = false
			layer_panel.visible = false
			instructions_label.text = "WASD: Mover  |  Space: Saltar  |  T: Volver al editor  |  Esc: Liberar ratón"


## Actualiza la etiqueta de la capa activa.
func set_layer_label(layer: int) -> void:
	layer_label.text = "Capa: %d" % layer
