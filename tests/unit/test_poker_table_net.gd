extends GutTest

func _make_view():
	var container := Control.new()
	container.size = Vector2(900, 1080)
	add_child_autofree(container)
	var scene := load("res://scenes/poker_table_net.tscn")
	var instance = scene.instantiate()
	container.add_child(instance)
	return instance

func test_seat_anchor_oval_distributes_around_ellipse() -> void:
	var instance = _make_view()
	var anchors: Array[Vector2] = []
	for i in 6:
		anchors.append(instance.seat_anchor_oval(i, 6))
	# Los 6 puntos deben ser distintos entre si (sin dos asientos superpuestos)
	for i in 6:
		for j in range(i + 1, 6):
			assert_gt(anchors[i].distance_to(anchors[j]), 30.0)
	# Todos dentro del area visible
	for a in anchors:
		assert_between(a.x, 0.0, 900.0)
		assert_between(a.y, 0.0, 1080.0)
