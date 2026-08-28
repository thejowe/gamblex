extends GutTest

func _make_view():
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	add_child_autofree(instance)
	return instance

func test_seat_anchor_oval_distributes_around_ellipse() -> void:
	var instance = _make_view()
	# PokerTableNet fuerza su tamano contra el viewport real en _ready()
	# (mismo gotcha que Blackjack, Plan 14 — anchors full-rect no
	# resuelven bien bajo el Node2D de CasinoFloor), asi que usamos
	# instance.size ya resuelto en vez de un valor fijo.
	var anchors: Array[Vector2] = []
	for i in 6:
		anchors.append(instance.seat_anchor_oval(i, 6))
	# Los 6 puntos deben ser distintos entre si (sin dos asientos superpuestos)
	for i in 6:
		for j in range(i + 1, 6):
			assert_gt(anchors[i].distance_to(anchors[j]), 30.0)
	# Todos dentro del area visible
	for a in anchors:
		assert_between(a.x, 0.0, instance.size.x)
		assert_between(a.y, 0.0, instance.size.y)
