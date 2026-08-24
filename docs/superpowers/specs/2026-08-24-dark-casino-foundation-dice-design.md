# Ampliación v1.4a: fundación de casino oscuro + reskin de Dice

**Fecha:** 2026-08-24
**Estado:** aprobado por el usuario, listo para plan de implementación
**Referencias visuales:** `dice.png`, `rulette.png`, `crash.png`, `mines.png`,
`plinko.png` (raíz del repo) — capturas de un casino online real (ACEBET)
en estilo panel oscuro. Las 5 comparten el mismo panel lateral de apuesta
casi pixel a pixel (monto, botones 1/2 / x2 / Máx, botón verde "Hacer
apuesta") — esa es la fundación de este plan. El resto de cada pantalla
(rueda, gráfico de Crash, grid de Mines, tablero de Plinko) es específico
de cada juego y no se construye aquí, salvo el de Dice (slider), que sirve
de primer caso de uso completo del patrón — mismo criterio que "Dice
primero" en la Ampliación v1.1.

## Contexto

Plan 14 ya dejó un sistema de componentes procedurales para Blackjack
(`scripts/ui/casino/`), pero esa estética es "mesa de fieltro con cartas" —
no encaja con Ruleta/Dice/Crash/Mines/Plinko, que en las referencias del
usuario siguen un lenguaje visual totalmente distinto: panel lateral
oscuro con controles de apuesta + panel principal oscuro con la
visualización del juego, estilo app de casino moderna (navy oscuro, acento
verde, sin fieltro ni madera). Se reutiliza `CasinoTheme` como archivo de
paleta (se le añaden constantes nuevas, no se duplica), pero los
componentes de Blackjack (`FeltTablePanel`, `PlayingCard`, `CasinoChip`)
no se tocan ni se reutilizan aquí — no aplican a este lenguaje visual.

Dice hoy es completamente funcional pero visualmente en blanco: un
`Label` de texto plano y dos `SpinBox`/`Button` sueltos
(`scenes/dice_table_net.tscn`). Toda la lógica que la UI necesita ya
existe y no cambia: `DiceTableState.win_chance(threshold, direction)`,
`DiceTableState.multiplier(threshold, direction)`, `to_dict()` ya expone
`balance`/`last_round` por jugador. **Este plan es 100% visual — cero
cambios en `scripts/dice/`.**

## Diseño

### Paleta (extiende `scripts/ui/casino/casino_theme.gd`, no la reemplaza)

Añade constantes nuevas al `CasinoTheme` existente (Plan 14 ya lo dejó
como el sitio central de color del proyecto):

```gdscript
const PANEL_NAVY_DARK := Color("131b26")   # fondo del panel principal
const PANEL_NAVY_MID := Color("1c2733")    # fondo de la barra lateral / inputs
const PANEL_NAVY_LIGHT := Color("28374a")  # bordes, separadores
const ACCENT_GREEN := Color("4caf6e")      # botón principal, zona de victoria
const ACCENT_RED := Color("d9534f")        # zona de pérdida
const TEXT_LIGHT := Color("e8edf2")        # texto principal sobre navy
const TEXT_MUTED := Color("7c8a9a")        # texto secundario/etiquetas
```

### `BetSidebarPanel` — componente compartido (`scripts/ui/casino/bet_sidebar_panel.gd` + escena)

La pieza reutilizable real. `Control`/`PanelContainer` con:
- Label "Monto de la apuesta".
- Un `LineEdit` numérico estilizado (fondo `PANEL_NAVY_MID`, texto
  `TEXT_LIGHT`) + 3 `CasinoButton` pequeños en fila: **1/2** (divide el
  monto entre 2, mínimo 1), **x2** (duplica, tope `max_amount`), **Máx**
  (pone `max_amount`).
- Un `CasinoButton` grande, variante `POSITIVE`, texto "Hacer apuesta",
  ocupando el ancho del panel, al fondo.

Propiedades exportadas: `amount: int = 10` (clamped a `[1, max_amount]`
en el setter), `max_amount: int = 500`. Señal `bet_pressed(amount: int)`.
Métodos `get_amount() -> int` / `set_max_amount(value: int) -> void`. No
sabe nada de dados, ruleta ni de ningún juego — cualquiera de las 4 mesas
siguientes lo instancia igual.

### `DiceThresholdSlider` — específico de Dice (`scripts/ui/casino/dice_threshold_slider.gd` + escena)

`Control` que dibuja una barra horizontal partida en verde/rojo según
`direction` y `threshold`, con un tirador circular arrastrable:
- `direction == UNDER`: verde a la izquierda del umbral (gana si el
  resultado cae ahí), rojo a la derecha.
- `direction == OVER`: rojo a la izquierda, verde a la derecha.
- Arrastrar el tirador (o clicar en la barra) cambia `threshold` (clamp
  1-99) y emite `threshold_changed(value: int)`.

Propiedades exportadas: `threshold: int = 50`, `direction: int =
DiceTableState.Direction.UNDER`. Las etiquetas 0/25/50/75/100 y el valor
numérico del umbral bajo el tirador son `Label`s normales posicionados en
la escena, no se dibujan a mano — más simple y suficiente para esta fase.

### Reconstrucción de `scenes/dice_table_net.tscn` / `.gd`

Layout (panel principal oscuro `PANEL_NAVY_DARK` de fondo en todo
`DiceTableNet`, `BetSidebarPanel` anclado a la izquierda, resto del
espacio para Dice):

- `BetSidebarPanel` (izquierda) — sustituye a `AmountSpinBox` y a los dos
  botones de apostar actuales. Su `bet_pressed(amount)` dispara
  `table_controller.roll(threshold, direction, amount)` usando el
  `threshold`/`direction` actuales del slider.
- Dos `CasinoButton` pequeños arriba del slider: "Mayor que" / "Menor
  que" (variante `NEUTRAL`, resaltado el activo con variante `POSITIVE`)
  — **eligen la dirección, no disparan la tirada** (cambio de modelo de
  interacción respecto a hoy, necesario porque ahora hay un único botón
  de apostar en la barra lateral, como en la referencia). Sustituyen a
  `ThresholdSpinBox` en su rol de control de dirección; el umbral ahora se
  controla arrastrando el `DiceThresholdSlider`.
- Tres cajas de estadística ("Multiplicador", "Probabilidad", en
  labels ya recalculados con `DiceTableState.multiplier()`/`win_chance()`
  cada vez que cambia `threshold`/`direction`) sobre el slider, estilo
  caja oscura con borde `PANEL_NAVY_LIGHT`.
- `DiceThresholdSlider` centrado, con las etiquetas 0/25/50/75/100.
- Zona de resultado: al recibir `state_changed` con un `last_round` nuevo
  para el jugador local, flash verde/rojo breve (`modulate` pulse, sin
  partículas — más sobrio que Blackjack, acorde a la referencia) sobre el
  panel de estadísticas, según `last_round["win"]`.
- El listado de "quién tiró qué" que hoy vive en `PlayersLabel` se
  conserva como un `Label` simple debajo del slider, restyleado
  (`TEXT_MUTED`), no es parte de la referencia pero es información real
  que ya existía y no hay que perder.

## Fuera de alcance

- Cualquier cambio a `scripts/dice/` — la lógica ya es correcta y
  suficiente.
- Ruleta, Crash, Mines, Plinko — fases siguientes (Planes 17-20),
  reutilizan `BetSidebarPanel` y la paleta extendida de `CasinoTheme`,
  cada una con su propia visualización central.
- Blackjack / `FeltTablePanel` / `PlayingCard` / `CasinoChip` — lenguaje
  visual distinto, no se tocan.
- Modo Batalla / pozo compartido — ya resuelto en Plan 15, sin relación
  con este plan.

## Testing

Mismo criterio que Plan 14: componentes de dibujo puro (`DiceThresholdSlider`)
se cubren con pruebas de humo (instancia sin error, propiedades
exportadas correctas, `threshold_changed` se emite con el valor esperado
tras simular un drag) — no se valida contenido de píxeles. `BetSidebarPanel`
sí es testeable con más precisión (los quick-buttons son aritmética pura:
1/2, x2, clamp a `max_amount`). Verificación visual manual final con el
usuario, mismo patrón que cerró Plan 14.
