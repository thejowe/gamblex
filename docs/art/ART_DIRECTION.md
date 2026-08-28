# Art Direction — Casino Pixel (Style Bible)

Fuente única de verdad visual del proyecto. Cualquier asset nuevo, humano
o generado por PixelLab, se valida contra este documento antes de pasar
de `DRAFT` a `APPROVED`. Ver `.claude/agents/CasinoArtDirector.md` para
quién hace cumplir esto y cómo.

## Auditoría de partida (2026-08-28)

- **Motor:** Godot 4.7, renderer `GL Compatibility` (`project.godot`).
- **Viewport base:** 900×1080, `window/stretch/mode="canvas_items"`,
  `aspect="expand"` — la ventana escala, no hay resolución de píxel fija
  impuesta por el motor.
- **Estado visual actual:** las 7 mesas + lobby + menús de la Ampliación
  v1.7 están dibujados **por código** con `CasinoTheme`
  (`scripts/ui/casino/casino_theme.gd`) — rectángulos/paneles/paletas
  procedurales, sin ningún PNG de arte real todavía. Este sistema de
  assets sustituye ese dibujo procedural, no lo acompaña indefinidamente.
- **Estructura de carpetas ya creada por el usuario:** `assets/pixels/`
  tiene 112 carpetas (una por asset final, `.gitkeep` dentro, ninguna con
  imagen todavía), documentadas en `assets/pixels/ASSETS.md`. Esa
  estructura es la fuente de verdad de *qué* assets existen — no la
  reinventamos, `ART_ASSET_PLAN.md` la absorbe y le añade fases y masters.
- **Referencias visuales del usuario:** `docs/superpowers/specs/references/`
  — `blackjack-evolution-reference.png`, `crash-acebet-reference.png`,
  `dice-acebet-reference.png`, `mines-acebet-reference.png`,
  `plinko-acebet-reference.png`, `roulette-acebet-reference.png`,
  `poker-reference.webp`. Son la referencia principal de composición para
  Crash/Dice/Mines/Plinko/Ruleta/Póker (estilo "Ace Bet") y Blackjack.
- **Duplicados sueltos en la raíz del repo** (`crash.png`, `dice.png`,
  `mines.png`, `plinko.png`, `poker.webp`, `rulette.png`, `reference.png`):
  hash idéntico byte a byte a los ficheros de
  `docs/superpowers/specs/references/`. Son copias sobrantes, no assets
  nuevos — no se tocan/borran sin que el usuario lo confirme (regla 32,
  "no eliminar assets"), pero `CasinoArtDirector` no debe usarlos como
  fuente: usa siempre la copia en `docs/superpowers/specs/references/`.

## Estética

Casino clásico + arcade 16-bit años 80/90.

- Retro arcade, casino clásico, elegante pero juguetón.
- Pixel art limpio, alta legibilidad, formas reconocibles.
- Detalle suficiente para transmitir material sin caer en fotorrealismo.
- Aspecto premium — nunca genérico ni plano.

## Paleta

`CasinoTheme` (`scripts/ui/casino/casino_theme.gd`) ya define los colores
que el 100% de la UI procedural usa hoy. **Esta es la paleta real y
obligatoria** — no la paleta genérica sugerida en el prompt original, que
queda solo como referencia de tono. Cualquier asset nuevo debe poder
sustituir el dibujo procedural sin choque de color.

### Familia "Fieltro" (Blackjack, Póker — mesa ovalada de fieltro+madera)

| Token | Hex | Uso |
|---|---|---|
| `FELT_GREEN_LIGHT` | `#2F8F5B` | tapete, luz |
| `FELT_GREEN_DARK` | `#1C5C3A` | tapete, sombra |
| `WOOD_BROWN_LIGHT` | `#8A5A34` | riel de madera, luz |
| `WOOD_BROWN_DARK` | `#5C3A20` | riel de madera, sombra |
| `GOLD_ACCENT` | `#E8C468` | ribetes, highlights |
| `CARD_WHITE` | `#F5F5F0` | cuerpo de carta |
| `CARD_RED` | `#C0392B` | tinta roja |
| `CARD_BLACK` | `#1A1A1A` | tinta negra |
| `TEXT_CREAM` | `#F0E6D2` | texto sobre fieltro |

### Familia "Panel oscuro" (Ruleta, Dice, Crash, Mines, Plinko — panel lateral de apuesta)

| Token | Hex | Uso |
|---|---|---|
| `PANEL_NAVY_DARK` | `#131B26` | fondo de panel |
| `PANEL_NAVY_MID` | `#1C2733` | panel, capa media |
| `PANEL_NAVY_LIGHT` | `#28374A` | panel, borde/luz |
| `ACCENT_GREEN` | `#4CAF6E` | estado positivo/ganar |
| `ACCENT_RED` | `#D9534F` | estado negativo/perder |
| `TEXT_LIGHT` | `#E8EDF2` | texto principal |
| `TEXT_MUTED` | `#7C8A9A` | texto secundario |

### Fichas (`CasinoTheme.CHIP_COLORS`, denominaciones reales)

| Denominación | Hex |
|---|---|
| 1 | `#E8E8E8` |
| 5 | `#C0392B` |
| 10 | `#2E6DA4` |
| 25 | `#2F8F5B` |
| 50 | `#E07B1F` |
| 100 | `#1A1A1A` |

Oro/madera/fieltro comparten familia cálida con la paleta genérica
sugerida en el prompt original (`#9A6B25`/`#D6A43A`/`#F4D477` dorados,
`#3A2118`/`#70432A` maderas, `#0E4A3A`/`#1D7657` verdes) —úsala como
paso intermedio de sombreado/highlight dentro de cada hex de
`CasinoTheme`, nunca como sustituto de los tokens de arriba.

## Dos familias visuales, una sola dirección de arte

El proyecto tiene **dos ambientaciones de mesa coexistiendo a propósito**
(decisión ya tomada en Plan 14/16, no la reabras):

1. **Fieltro clásico** — Blackjack, Póker. Madera + fieltro verde + oro,
   mesa ovalada físicaa. Ver `docs/superpowers/specs/references/blackjack-evolution-reference.png`.
2. **Panel oscuro moderno** — Ruleta, Dice, Crash, Mines, Plinko. Fondo
   navy, panel lateral de apuesta compartido (`BetSidebarPanel`), estética
   "app de casino online" tipo Ace Bet. Ver las 5 referencias
   `*-acebet-reference.png`.

Ambas familias comparten: misma paleta de oro/acento, misma tipografía,
mismo lenguaje de iconografía HUD, mismos botones. Lobby, HUD, menús y
pantallas de resultado son neutrales — no pertenecen a ninguna de las dos
mesas, deben verse bien junto a cualquiera.

## Materiales

### Madera (riel de mesa de fieltro)
Caoba/marrón oscuro, vetas pixeladas, sombras profundas, highlights
cálidos. Base: `WOOD_BROWN_DARK` → `WOOD_BROWN_LIGHT`.

### Terciopelo/fieltro
Verde casino oscuro, textura muy sutil, variaciones de valor pequeñas.
Base: `FELT_GREEN_DARK` → `FELT_GREEN_LIGHT`.

### Oro
Oro oscuro → oro principal → highlight crema. Base: `GOLD_ACCENT` con
paso oscuro/claro derivado.

### Cartas
Marfil (`CARD_WHITE`), borde oscuro, sombra, tinta negra/roja
(`CARD_BLACK`/`CARD_RED`).

### Metal (fichas, marcos, iconos HUD)
Bronce/dorado oscuro con highlights duros. Reutiliza familia Oro.

### Panel oscuro (Ruleta/Dice/Crash/Mines/Plinko)
Navy mate, sin textura de madera/fieltro — superficies lisas con bordes
duros y acentos verde/rojo de estado. Base: familia `PANEL_NAVY_*`.

## Iluminación

- Cálida, contraste medio/alto, sombras duras, highlights localizados.
- Predominio de luces doradas sobre la familia fieltro.
- Ambiente oscuro (fondo siempre oscuro, nunca fondos claros/blancos).
- Familia panel oscuro: luz más fría/neutra, acentos verde/rojo como
  único color saturado — el navy se mantiene apagado.

## Reglas de pixel art (obligatorias)

- Sin anti-aliasing, bordes duros.
- Pixel clusters limpios, evitar ruido innecesario.
- Sin gradientes suaves ni texturas fotográficas.
- Escala de píxel consistente dentro de cada asset (ver grid abajo).
- Sin líneas de 1px inconsistentes que rompan el grid definido.
- Evitar exceso de colores — cuantizar al finalizar.

## Resolución y pixel density (decisión documentada)

`ASSETS.md` (creado por el usuario antes de este sistema) ya fija
**grid base 32px** para los assets pequeños (fichas, iconos, casillas).
Este documento la adopta y la extiende al resto de categorías:

```text
Unidad de grid: 32px (1 "celda" de pixel art)

Fichas (chip_*):            32×32   (1×1 celda)
Iconos HUD (icon_*):        32×32   (1×1 celda)
Casillas Mines:             32×32   (1×1 celda)
Celdas de ruleta:           32×32   (1×1 celda)
Botones (button_*):         96×32   (3×1 celdas)
Cartas (card_*):            64×96   (2×3 celdas)
Fichas de lobby (card_*):   192×256 (6×8 celdas)
Fondos de pantalla completa: 220×264 lienzo base → escalado ×4 nearest
                             a 880×1056 dentro de 900×1080 (mantiene el
                             aspecto 5:6 real del viewport, pixel size
                             real = 4px; 225×270 original descartado —
                             PixelLab exige lados divisibles por 4 en
                             este rango de tamaño)

Filtrado: Nearest Neighbor (Godot import: Filter=Off, Mipmaps=Off)
Anti-aliasing: desactivado para todo asset pixel art
Formato: PNG-8/PNG-32 con canal alfa donde el asset lo necesite
```

Esta tabla es la que usa `ART_ASSET_PLAN.md` por categoría. Si un asset
concreto necesita un tamaño distinto (p. ej. `roulette_wheel`, que es
circular y grande), se documenta como excepción ahí mismo, nunca en
silencio.

## Decisiones que requieren confirmación del usuario

- Tamaño exacto de `roulette_wheel` (probablemente >1 celda, pendiente
  de ver la referencia a escala real en la mesa).
- Si los 7 fondos de pantalla completa (`lobby_bg`, `loading_bg`,
  `victory_bg`, `defeat_bg`, `settings_bg`, `pause_bg`, `credits_bg`,
  `help_bg`) comparten un único "master de composición" (misma
  estructura de vignette/marco, cambia solo motivo central) o son libres.
  Propuesta por defecto: comparten master, igual que las 7 tarjetas de
  lobby — se documenta en `ART_ASSET_PLAN.md` como `BACKGROUND_MASTER`.
