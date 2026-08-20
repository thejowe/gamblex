extends GutTest

func test_roll_returns_queued_result_in_order():
	var roller = CrashRoller.new()
	var queued: Array[float] = [1.50, 3.20, 1.00]
	roller.results = queued
	assert_eq(roller.roll(), 1.50)
	assert_eq(roller.roll(), 3.20)
	assert_eq(roller.roll(), 1.00)

func test_crash_point_for_known_r_values():
	# r=0.5 -> 100*0.99/0.5 = 198 -> floor/100 = 1.98
	assert_almost_eq(CrashRoller.crash_point_for(0.5), 1.98, 0.001)
	# r=0.0 -> 100*0.99/1.0 = 99 -> floor/100 = 0.99 -> clamp a 1.00
	assert_almost_eq(CrashRoller.crash_point_for(0.0), 1.00, 0.001)
	# r=0.9 -> 100*0.99/0.1 = 990 -> floor/100 = 9.90
	assert_almost_eq(CrashRoller.crash_point_for(0.9), 9.90, 0.001)
	# r=0.99 -> 100*0.99/0.01 = 9900 -> floor/100 = 99.00 (IEEE754: 1.0-0.99 != 0.01 exactly, yields 98.99)
	assert_almost_eq(CrashRoller.crash_point_for(0.99), 98.99, 0.001)

func test_roll_without_queue_never_returns_below_one():
	var roller = CrashRoller.new()
	for i in range(200):
		assert_true(roller.roll() >= 1.00)

func test_roll_without_queue_always_returns_finite_value():
	# roll() debe excluir tanto r=0.0 como r=1.0 antes de llamar a
	# crash_point_for(). r=1.0 es el caso peligroso: 1.0 - r = 0.0, y
	# crash_point_for(1.0) daria INF (division por cero no lanza error en
	# GDScript). No podemos forzar randf() a devolver exactamente 1.0 aqui,
	# asi que esta es una comprobacion estadistica de la invariante que
	# roll() debe mantener siempre: el resultado nunca es infinito ni NaN.
	var roller = CrashRoller.new()
	for i in range(500):
		var result = roller.roll()
		assert_true(is_finite(result), "roll() devolvio un valor no finito: %s" % result)

func test_crash_point_for_boundary_r_values_documents_the_danger():
	# r=0.0 es inofensivo: max(1.00, ...) lo recorta.
	assert_almost_eq(CrashRoller.crash_point_for(0.0), 1.00, 0.001)
	# r=1.0 (que randf() SI puede devolver, ~1 en 33 millones en esta build)
	# anula el divisor 1.0 - r y produce INF. Por eso roll() debe excluir
	# r >= 1.0 en su guarda antes de llamar a crash_point_for().
	assert_true(is_inf(CrashRoller.crash_point_for(1.0)))

func test_roll_distribution_median_matches_expected_house_edge():
	# Validación estadística de la fórmula pedida en la tarea del agente: no
	# basta un caso suelto, hay que ver la forma de la distribución sobre
	# muchas rondas. r es uniforme en [0,1); la mediana de crash_point debe
	# rondar 1.98x (r=0.5), y la fracción de rondas por debajo de 2x debe
	# rondar el 50% dentro de un margen estadístico razonable.
	var below_2x := 0
	var total := 5000
	var sum_min := INF
	for i in range(total):
		var cp: float = CrashRoller.crash_point_for(randf())
		sum_min = min(sum_min, cp)
		if cp < 2.0:
			below_2x += 1
	var ratio := float(below_2x) / float(total)
	assert_true(ratio > 0.45 and ratio < 0.55, "ratio bajo 2x fue %f, se esperaba ~0.5" % ratio)
	assert_true(sum_min >= 1.00)
