# Art Validation — Casino Pixel

Checklist que `CasinoArtDirector` corre antes de mover un asset de
`REVIEW` a `APPROVED`, y de `APPROVED` a `FINAL`. Ningún asset salta
pasos.

## Técnica (antes de `APPROVED`)

- [ ] Resolución correcta según la tabla de `ART_DIRECTION.md` (o
      excepción documentada).
- [ ] Transparencia correcta (alfa donde corresponde, sin halo de
      anti-aliasing en el borde).
- [ ] Formato correcto (PNG, sin compresión con pérdida).
- [ ] Nombre correcto según `ART_NAMING_CONVENTIONS.md`.
- [ ] Ubicación correcta (`assets/pixels/<categoria>/<asset>/<asset>.png`).
- [ ] Sin anti-aliasing, bordes duros, grid de píxel consistente.

## Visual (antes de `APPROVED`)

- [ ] Pixel density coherente con el resto de la fase.
- [ ] Paleta dentro de los tokens de `CasinoTheme` (o derivados de
      sombreado/highlight documentados en `ART_DIRECTION.md`).
- [ ] Iluminación coherente (cálida/dorada en familia fieltro, navy/fría
      en familia panel oscuro).
- [ ] Escala coherente con los demás assets de su categoría.
- [ ] Materiales reconocibles (madera/terciopelo/oro/marfil/metal según
      corresponda).
- [ ] Silueta legible a tamaño real de juego, no solo a zoom.
- [ ] Coherente con su MASTER (si tiene uno).

## Gameplay (antes de `APPROVED`)

- [ ] Legible a la escala real en pantalla (900×1080 con stretch
      `expand`, probar a tamaño de ventana pequeño también).
- [ ] Contraste suficiente contra el fondo real donde se coloca.
- [ ] No interfiere con texto/UI existente.
- [ ] Estados distinguibles entre sí sin ambigüedad (p. ej.
      `mines_cell_mine` vs `mines_cell_mine_dim`, `button_*_normal` vs
      `button_*_disabled`).

## Import (antes de `IMPLEMENT`/`FINAL`)

- [ ] `.import` generado con `compress/mode=0`, `mipmaps/generate=false`.
- [ ] Filtro nearest aplicado en el nodo que lo consume.
- [ ] El motor lo detecta sin error al abrir la escena que lo usa.
- [ ] No rompe ningún asset/test existente (correr
      `docs/superpowers/` tests relevantes si el asset toca una escena
      con test GUT).
- [ ] `ASSET_REGISTRY.md` actualizado con el estado final.

## Automatización disponible

`scripts_tools/validate_pixel_assets.ps1` (a crear en FASE 2 si el
volumen de assets lo justifica) comprobará por script: dimensiones
esperadas por categoría, PNGs sin `.import` correspondiente, archivos en
`assets/pixels/**/` que no coincidan con ninguna fila de
`ASSET_REGISTRY.md` (huérfanos), y carpetas del plan sin archivo
(`.gitkeep` sin imagen — pendiente real). Hasta que exista, la
comprobación es manual siguiendo esta lista.
