# CLAUDE.md — gamblex

Casino multijugador pixel art (Godot 4.7). Dos sistemas de orquestación
por sesión pilar, cada uno con su propio dominio — no los mezcles:

- **Código/gameplay/red:** `.claude/agents/pilar.md` + `todo_agents.md`.
- **Arte/assets visuales:** `.claude/agents/CasinoArtDirector.md` +
  `docs/art/` (`ART_DIRECTION.md`, `ART_ASSET_PLAN.md`,
  `ART_PIPELINE.md`, `ART_NAMING_CONVENTIONS.md`, `ART_VALIDATION.md`,
  `ASSET_REGISTRY.md`).

## Reglas de arte (obligatorias para cualquier trabajo con `assets/pixels/`)

1. **Master-first.** Nunca generar una variante (carta, ficha, botón,
   casilla, celda, tarjeta de lobby, icono) sin que su MASTER esté
   `APPROVED` primero. Ver `docs/art/ART_ASSET_PLAN.md`.
2. **PixelLab MCP** es la herramienta principal para generar/editar pixel
   art. Código/composición solo para derivar variantes de un master ya
   aprobado. Ver jerarquía completa en `docs/art/ART_PIPELINE.md`.
3. **Paleta real = `scripts/ui/casino/casino_theme.gd`.** Cualquier asset
   nuevo tiene que poder sustituir el dibujo procedural actual sin
   choque de color. `ART_DIRECTION.md` documenta los hex exactos.
4. **No sobrescribir/borrar assets existentes** en `assets/pixels/` sin
   inspeccionarlos primero. Las 112 carpetas ya creadas por el usuario
   (`assets/pixels/ASSETS.md`) son la estructura fija — no se reinventan.
5. **`docs/art/ASSET_REGISTRY.md` es la fuente de verdad de qué asset
   está en qué estado** (`PLANNED`/`DRAFT`/`REVIEW`/`APPROVED`/`FINAL`).
   Se actualiza en cada cambio, nunca de memoria.
6. Nunca marcar un asset `FINAL` sin pasar el checklist de
   `docs/art/ART_VALIDATION.md` (técnica + visual + gameplay + import).

Para cualquier otra tarea (motor, gameplay, red, Steam, tests), sigue lo
que ya diga `pilar.md`/`todo_agents.md` — este archivo no repite esas
reglas, solo señala dónde viven.
