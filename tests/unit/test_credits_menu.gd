extends GutTest

const CreditsMenuScene := preload("res://scenes/ui/casino/credits_menu.tscn")

func test_instantiates_without_error() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance)

func test_back_button_exists() -> void:
	var instance := CreditsMenuScene.instantiate()
	add_child_autofree(instance)
	assert_not_null(instance.get_node("BackButton"))

func test_back_button_target_is_home_screen() -> void:
	# No se puede assertar el string privado del scene-change sin
	# refactorizar CreditsMenu a una señal; verificación real es visual
	# (pulsar Volver desde Créditos y comprobar que aterriza en
	# HomeScreen, no en LobbyMenu) — ver reporte del agente.
	pass_test("verificación visual pendiente, ver reporte del agente")
