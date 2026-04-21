# Creador de Mapas Multicapa 2D/3D — Godot 4.x

Sistema de edición de mapas estilo Calabozos y Dragones construido en Godot Engine 4.x con GDScript.

## Características

- **Grilla multicapa** (Vector3i): capa 0 = suelo, capas positivas = pisos superiores, capas negativas = sótanos.
- **Recursos de tile** (`MapTileResource`): Suelo de piedra, Pared de madera, Antorcha — extensibles.
- **Renderizado 3D** dinámico: `MeshInstance3D` + `StaticBody3D` generados a partir de los datos del mapa.
- **Iluminación dinámica**: `OmniLight3D` instanciado automáticamente en tiles de tipo `LIGHT_SOURCE`.
- **Sol** con `DirectionalLight3D` y skybox procedural.
- **Dos modos de cámara**:
  - **Modo Constructor** — Vista aérea con pan/zoom y colocación de tiles con el ratón.
  - **Modo Exploración** — Primera persona con WASD + Space + ratón.
- **UI básica**: selector de tiles en la barra inferior y botón de cambio de modo.

## Controles

### Modo Constructor
| Acción | Control |
|---|---|
| Colocar tile | Clic izquierdo |
| Borrar tile | Clic derecho |
| Pan de cámara | Clic medio + arrastrar |
| Zoom | Rueda del ratón |
| Subir capa | E |
| Bajar capa | Q |
| Cambiar a Exploración | T |

### Modo Exploración
| Acción | Control |
|---|---|
| Moverse | WASD |
| Saltar | Espacio |
| Mirar | Ratón |
| Liberar ratón | Escape |
| Volver al editor | T |

## Estructura del Proyecto

```
project.godot
icon.svg
scenes/
  main.tscn          # Escena principal con GameManager, Sun, UI
  player.tscn        # CharacterBody3D con cámara de primera persona
scripts/
  MapTileResource.gd # Recurso base para tiles (FLOOR, WALL, DECORATION, LIGHT_SOURCE)
  MapData.gd         # Diccionario multicapa Vector3i -> MapTileResource
  MapRenderer.gd     # Genera MeshInstance3D y StaticBody3D desde MapData
  EditorCamera.gd    # Cámara aérea con pan/zoom y detección de celdas
  FirstPersonController.gd  # CharacterBody3D con WASD, salto y ratón
  TileRegistry.gd    # Registro centralizado de recursos de tiles
  GameManager.gd     # Orquestador principal + mapa demo
  UI.gd              # Selector de tiles + botón de modo
```

## Cómo Ejecutar

1. Abre Godot 4.x y selecciona "Importar Proyecto".
2. Navega hasta la carpeta raíz del repositorio y abre `project.godot`.
3. Pulsa F5 o el botón "Ejecutar" para iniciar.

El proyecto arranca directamente en **Modo Constructor** con un mapa de demostración de 5×5 celdas de suelo y paredes perimetrales con antorchas en las esquinas.
