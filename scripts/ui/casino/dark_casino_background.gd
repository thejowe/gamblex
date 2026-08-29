class_name DarkCasinoBackground
extends Control

# Fondo compartido de las mesas de "panel oscuro" (Ruleta/Dice/Crash/Mines/
# Plinko, fundación de Plan 16) — sin esto, detrás de esas mesas se veía el
# gris por defecto del viewport de Godot porque su escena no tenía ningún
# nodo de fondo (a diferencia de Blackjack/Poker, que sí traen su propio
# `FeltBackground`).

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	show_behind_parent = true
	resized.connect(queue_redraw)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, CasinoTheme.PANEL_NAVY_DARK)
	var gradient_steps := 24
	for i in range(gradient_steps):
		var t: float = float(i) / float(gradient_steps - 1)
		var y := size.y * t
		var band_height := size.y / float(gradient_steps) + 1.0
		var color: Color = CasinoTheme.PANEL_NAVY_DARK.lerp(CasinoTheme.PANEL_NAVY_MID, t * 0.5)
		draw_rect(Rect2(Vector2(0.0, y), Vector2(size.x, band_height)), color)
	var center := size / 2.0
	var glow_radius: float = min(size.x, size.y) * 0.55
	draw_circle(center, glow_radius, Color(CasinoTheme.PANEL_NAVY_LIGHT, 0.18))
