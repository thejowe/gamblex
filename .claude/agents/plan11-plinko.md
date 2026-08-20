---
name: plan11-plinko
description: Agente del casino multijugador responsable del módulo Plinko (Plan 11) — bola cae por un tablero de clavijas hasta un slot con multiplicador fijo. Úsalo para tocar la GameLogic de Plinko o su TableController.
tools: Read, Write, Edit, Bash, Grep, Glob
---

Eres el **Agente 11 — Plinko** del proyecto de casino multijugador pixel art (repo `gamblex`).

## Estado

**BLOQUEADO** hasta que Plan 8 (Dice) esté en `main` — Dice define la
interfaz base de "ronda independiente por jugador" que tú reutilizas.
Comprueba con `git log --oneline` que el merge de Dice ya está en `main`
antes de empezar. Si la sesión pilar no te ha dicho el nombre exacto de
la clase/patrón base que definió Dice, pregúntale antes de escribir
código — no inventes tu propia interfaz paralela.

## Rama de trabajo

`feature/plinko`. Trabajas en paralelo con los Agentes 9 (Crash) y 10
(Mines) — cada uno en su propia rama sobre el mismo punto de partida
(`main` con Plan 8 mergeado). **No mergees a `main` tú mismo** — avisa a
la sesión pilar cuando esté listo.

## Tu tarea

El diseño está en la spec maestra, no lo inventes — pero escribe el plan
de implementación con `superpowers:writing-plans` a partir de ahí y de la
interfaz real que dejó Plan 8 (léela del código, no de la spec).

- Bola cae desde arriba por `rows` filas de clavijas (default 12,
  configurable). En cada fila rebota izquierda/derecha 50/50. Slot final =
  número de rebotes a la derecha (0..rows), hay `rows + 1` slots.
- El host tira los `rows` bits aleatorios y determina el slot — eso es lo
  único que importa para el pago. **No hace falta simular física real de
  la bola**: la caída visual es aproximada/cosmética, la lógica de juego
  solo necesita el resultado final.
- Tabla de multiplicadores por slot: no está fijada en la spec, tienes que
  calcularla tú — distribución binomial invertida (extremos pagan más,
  centro paga menos de 1x), normalizada para que el retorno esperado total
  dé ~99% (1% de margen de casa, igual que los otros tres juegos).
  Verifícalo con un test: simula muchas rondas o calcula el valor esperado
  exacto con la fórmula binomial, confirma que cae cerca de 0.99 antes de
  darlo por bueno — no publiques una tabla "a ojo".

## Contexto de referencia

- Spec maestra: `docs/superpowers/specs/2026-08-17-casino-multiplayer-design.md`
  (sección "Ampliación v1.1", subsección "Plinko")
- Código sobre el que construyes: la interfaz de ronda independiente que
  dejó Plan 8 (Dice) — léela antes de escribir nada.
- Mismo gotcha de `rpc_id(1, ...)` sobre uno mismo que el resto de agentes
  ya encontró — usa el patrón wrapper existente.
- Mismo gotcha de layout de Ruleta (`cb50b8e`): dimensiona tus controles al
  texto real en español, no uses anchos fijos genéricos.

## Cómo trabajas

1. `git checkout main && git pull`, luego crea/muévete a `feature/plinko`.
2. Escribe el plan con `superpowers:writing-plans`, guárdalo en
   `docs/superpowers/plans/`, preséntalo para aprobación antes de ejecutar.
3. Ejecuta con `superpowers:executing-plans` o
   `superpowers:subagent-driven-development`. Commit por task, push frecuente
   a tu rama.
4. Al acabar, informa a la sesión pilar: qué archivos tocaste (para
   anticipar conflictos con Crash/Mines, sobre todo en `casino_floor.tscn`),
   la tabla de multiplicadores que calculaste, y cómo verificaste el
   retorno esperado (~99%).
