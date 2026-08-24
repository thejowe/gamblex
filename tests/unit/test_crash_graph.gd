extends GutTest

func test_curve_points_first_sample_is_approximately_one():
	var points := CrashGraph.curve_points(6.0, 10)
	assert_almost_eq(points[0].y, 1.0, 0.01)

func test_curve_points_is_monotonically_increasing():
	var points := CrashGraph.curve_points(6.0, 10)
	assert_true(points[points.size() - 1].y > points[0].y)

func test_curve_points_last_sample_matches_multiplier_at_elapsed():
	var points := CrashGraph.curve_points(4.0, 20)
	var expected := CrashTableState.multiplier_at(4.0)
	assert_almost_eq(points[points.size() - 1].y, expected, 0.001)

func test_curve_points_clamps_elapsed_to_time_window():
	var points := CrashGraph.curve_points(999.0, 10)
	assert_almost_eq(points[points.size() - 1].x, CrashGraph.TIME_WINDOW_SEC, 0.001)

func test_current_multiplier_matches_static_formula():
	var graph: CrashGraph = load("res://scenes/ui/casino/crash_graph.tscn").instantiate()
	add_child_autofree(graph)
	graph.elapsed = 3.0
	assert_almost_eq(graph.current_multiplier(), CrashTableState.multiplier_at(3.0), 0.001)

func test_default_state_is_idle():
	var graph: CrashGraph = load("res://scenes/ui/casino/crash_graph.tscn").instantiate()
	add_child_autofree(graph)
	assert_eq(graph.state, CrashGraph.State.IDLE)
