class_name LoadingIndicator
extends Control

const DOT_COUNT := 3
const DOT_SPACING := 20.0
const DOT_RADIUS := 5.0

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	for i in DOT_COUNT:
		var phase := fmod(_t * 2.0 - i * 0.3, 1.0)
		var alpha := 0.3 + 0.7 * absf(sin(phase * PI))
		var x := center.x + (i - 1) * DOT_SPACING
		draw_circle(Vector2(x, center.y), DOT_RADIUS, Color(CasinoTheme.TEXT_LIGHT, alpha))
