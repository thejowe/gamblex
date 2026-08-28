# Art Pipeline — Casino Pixel

Cómo se produce, valida e implementa cada asset. `CasinoArtDirector`
sigue este documento al pie de la letra para cada asset que toca.

## Jerarquía de herramientas (obligatoria)

1. **PixelLab MCP** (`mcp__pixellab__*`) — generación y edición de pixel
   art. Herramienta principal y preferente para todo asset nuevo.
2. **Código/procedimientos del proyecto** — para elementos repetitivos
   matemáticamente definidos (variantes de color de fichas, celdas de
   ruleta, estados de botón) cuando componerlos por código desde un
   master ya validado es más preciso que regenerar con IA.
3. **Herramientas de edición existentes** — ajustes técnicos (recorte,
   cuantización de paleta, empaquetado en atlas).
4. Otra herramienta de imagen — únicamente si PixelLab no puede resolver
   esa tarea concreta. Debe justificarse por escrito en el registro.

No cambiar de herramienta por conveniencia.

## Estructura de carpetas de trabajo

```text
assets/pixels/_masters/          # NUEVO — fuente de cada MASTER, no se
                                  # importa al juego directamente
    CARD_MASTER.png
    CARD_BACK_MASTER.png
    SUIT_HEART.png / SUIT_DIAMOND.png / SUIT_CLUB.png / SUIT_SPADE.png
    RANK_A.png … RANK_K.png
    CHIP_MASTER.png
    BUTTON_MASTER.png
    PANEL_MASTER.png
    MINES_CELL_MASTER.png
    ROULETTE_CELL_MASTER.png
    LOBBY_CARD_MASTER.png
    ICON_MASTER.png
    BACKGROUND_MASTER.png        # si el usuario confirma que aplica

assets/pixels/<categoria>/<asset>/<asset>.png   # ya existe, 112 carpetas
```

`_masters/` no se ha creado todavía — `CasinoArtDirector` la crea al
empezar FASE 2, no antes (regla: no tocar estructura de carpetas hasta
que haga falta).

## Antes de generar cualquier asset

1. Leer `ART_DIRECTION.md`.
2. Leer `ART_ASSET_PLAN.md` — confirmar fase y master requerido.
3. Consultar `ASSET_REGISTRY.md` — ¿ya existe DRAFT/APPROVED? No
   regenerar sin autorización.
4. Buscar el master relacionado en `assets/pixels/_masters/` — si no
   existe y el asset lo requiere, crear el master primero (regla
   master-first, sin excepción).
5. Buscar referencia visual en `docs/superpowers/specs/references/`.
6. Determinar resolución (tabla en `ART_DIRECTION.md`), paleta,
   transparencia, orientación, escala.
7. Decidir método: generar desde cero / derivar de master vía PixelLab
   image-to-image o inpainting / construir por código.

## Uso de PixelLab

- Pasar siempre el master (o la referencia, si aún no hay master) como
  imagen de referencia/entrada cuando la herramienta lo soporte
  (`image_to_pixelart`, `edit_image`, `inpaint_image`, `create_object_state`,
  variantes de personaje/objeto).
- Para sets de estado (botones, celdas de Mines, fichas) usar las
  herramientas de "state"/variantes del MCP en vez de N llamadas de
  generación independientes con prompts distintos — eso es exactamente
  lo que la regla "no generar assets repetitivos independientemente"
  prohíbe.
- Para animaciones (`crash_rocket`) usar `animate_object`/`animate_image`
  y extraer los frames que el motor necesite (`idle`, `launch`, `flame`).
- Cuantizar/reducir colores al final (`reduce_colors`) contra la paleta
  de `ART_DIRECTION.md` si el resultado se desvía.

## Import a Godot

Cada `.png` final necesita, al importarlo por primera vez en el editor
(o generando el `.import` a mano si se automatiza):

```ini
compress/mode=0          ; Lossless
mipmaps/generate=false
detect_3d/compress_to=1  ; Disabled
process/fix_alpha_border=false   ; pixel art: no difuminar bordes
```

Y en el nodo/`TextureRect`/`Sprite2D` que lo consuma: `texture_filter =
TEXTURE_FILTER_NEAREST` (o `CanvasItem.texture_filter` heredado si el
proyecto define un filtro global — comprobar antes de asumir).

`CasinoArtDirector` no marca un asset `FINAL` sin confirmar que el
`.import` generado cumple esto.

## Flujo de estado por asset

```text
PLANNED → REFERENCE → GENERATE → EDIT → VALIDATE → REVIEW → APPROVED
        → IMPLEMENT → FINAL
```

Nunca saltar `VALIDATE`. Nunca marcar `FINAL` sin `IMPLEMENT` confirmado
en el repo real (archivo presente, `.import` correcto, nada roto).

## Registro obligatorio (`ASSET_REGISTRY.md`)

Cada asset generado registra: `Asset`, `Master`, `Tool`, `Generation
method`, `Reference`, `Resolution`, `Palette`, `Status`,
`Implementation`. Si PixelLab MCP devuelve un `job_id`/identificador de
generación, se guarda ahí para poder reproducir o iterar el asset sin
regenerar desde cero.

## Gotcha conocido: `no_background=true` con rellenos claros (pixflux)

Detectado generando `CARD_MASTER`/`CARD_BACK_MASTER`/`CHIP_MASTER` en
FASE 2: `create_image_pixflux` con `no_background=true` **borra
regiones grandes de relleno claro/casi blanco** (ivory, off-white) junto
con el fondo real — el resultado sale prácticamente en blanco/vacío
(un PNG de ~100 bytes). Pasa con rellenos claros; los rellenos oscuros
(navy, verde oscuro, madera) no tienen este problema.

Mitigación que funcionó: generar esos assets con `no_background=false`
sobre un fondo plano oscuro de contraste explícito en el prompt ("on a
plain flat dark charcoal/black background"), y recortar la transparencia
real en el paso de implementación/derivación (edición manual o
`edit_image`/`inpaint_image` sobre el resultado ya correcto), nunca en
la misma llamada que define el relleno claro.

Regla: si un asset nuevo tiene un relleno mayoritariamente claro
(ivory, blanco, crema), generarlo primero opaco sobre fondo oscuro de
contraste, validar el relleno, y solo después extraer transparencia.

## Consistencia

Si un resultado de PixelLab contradice paleta, pixel density,
iluminación, estilo, escala, materiales o el master correspondiente:
**no se aprueba**. Se corrige por edición/regeneración antes de seguir a
la siguiente fase.
