# Especificación Técnica: Creador de Mapas Multicapa 2D/3D para Godot

## Objetivo
Desarrollar un sistema de edición de mapas en Godot Engine utilizando una grilla bidimensional que permita la construcción de estructuras multicapa (estilo Calabozos y Dragones). El sistema debe ser capaz de proyectar estas capas en un espacio 3D, permitiendo la navegación tanto en vista aérea (editor) como en primera persona (gameplay).

## Requerimientos del Sistema

### 1. Sistema de Recursos (TileResource)
Cada elemento del mapa debe heredar de un `Resource` personalizado para facilitar la extensibilidad.
- **Clase:** `MapTileResource`
- **Propiedades:**
    - `id`: String (identificador único).
    - `texture_albedo`: Texture2D.
    - `texture_normal`: Texture2D (opcional).
    - `tile_type`: Enum { FLOOR, WALL, DECORATION, LIGHT_SOURCE }.
    - `mesh_override`: Mesh (opcional, si se quiere usar un modelo específico).
    - `is_emissive`: Boolean.
    - `light_energy`: Float (para antorchas/lámparas).

### 2. Gestor de Grilla Multicapa (GridManager)
El mapa se basa en una estructura de datos que soporte múltiples niveles.
- **Estructura:** Un Diccionario o Array 3D donde la clave sea `Vector3i(x, y, z)`.
    - `x, z`: Coordenadas de la grilla plana.
    - `y`: El índice de capa (Layer).
- **Lógica de Construcción:**
    - **Capa 0:** Nivel del suelo.
    - **Capas Positivas:** Construcción hacia arriba (paredes altas, techos, segundos pisos).
    - **Capas Negativas:** Profundidad (sótanos, fosas).
- **Dimensiones de Tiles:**
    - **Floor Tile:** Ocupa el tamaño total de la celda (ej. 2x2 unidades).
    - **Wall Tile:** Debe permitir un grosor de 1/4 del ancho de la celda, pero mantener el largo total de la celda para alinearse a los bordes.

### 3. Visualización y Renderizado 3D
El sistema debe instanciar nodos 3D basados en la grilla:
- Cada capa `y` añade un offset en el eje Y global del motor.
- Los Tiles de tipo `WALL` deben colocarse en los bordes de las celdas o ocupar celdas específicas según la lógica de diseño.
- Implementar un sistema de "ocultamiento de capas superiores" para facilitar la edición de interiores.

### 4. Iluminación Dinámica
- **Sol:** Nodo `DirectionalLight3D` controlado por un ciclo día/noche simple o rotación manual.
- **Objetos de Luz:** Si un `MapTileResource` tiene `tile_type = LIGHT_SOURCE`, el sistema debe instanciar un nodo `OmniLight3D` o `SpotLight3D` en esa posición de la grilla.

### 5. Sistema de Cámaras y Navegación
Implementar dos modos de cámara:
1.  **Modo Editor (Vista Sinoidal/Aérea):**
    - Cámara ortográfica o de perspectiva lejana.
    - Movimiento mediante mouse (pan/zoom) para colocar tiles.
2.  **Modo Jugador (Primera Persona):**
    - Al activar este modo, instanciar un `CharacterBody3D`.
    - Control WASD para movimiento.
    - Tecla `Space` para saltar.
    - Control de cámara mediante el ratón (Look-at).
    - Colisiones automáticas generadas a partir de los tiles colocados.

## Instrucciones para la IA (Pasos de Implementación)

### Paso 1: Definir los Recursos
Crea el script `MapTileResource.gd` y configura algunos ejemplos (Suelo de piedra, Pared de madera, Antorcha).

### Paso 2: El Core del Mapa
Crea un script `MapData.gd` que gestione el diccionario de celdas. Debe incluir funciones para `set_tile(pos, resource)` y `get_tile(pos)`.

### Paso 3: Generador de Mallas (Mesh Library Dinámica)
Escribe la lógica para leer `MapData` y generar los nodos `MeshInstance3D` y `StaticBody3D` correspondientes. Asegúrate de que las paredes de "1/4 de ancho" se posicionen correctamente en los bordes.

### Paso 4: Controlador de Primera Persona
Configura un `CharacterBody3D` estándar con una `Camera3D` y lógica de movimiento en GDScript.

### Paso 5: Interfaz de Usuario (UI) básica
Un selector de tiles y un botón para alternar entre "Modo Construcción" y "Modo Exploración".

## Restricciones Técnicas
- **Motor:** Godot 4.x
- **Lenguaje:** GDScript
- **Nodo Principal:** `Node3D`
- **Rendimiento:** Utilizar `MultiMeshInstance3D` si el mapa es muy extenso, de lo contrario, instancias simples están bien para prototipado.
