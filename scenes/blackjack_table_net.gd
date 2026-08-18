extends Control

@onready var table_controller: TableController = $TableController
@onready var seats_label: Label = $SeatsLabel
@onready var dealer_label: Label = $DealerLabel
@onready var sit_button: Button = $SitButton
@onready var bet_button: Button = $BetButton
@onready var hit_button: Button = $HitButton
@onready var stand_button: Button = $StandButton

var my_seat_index: int = -1

func _ready() -> void:
    table_controller.state_changed.connect(_on_state_changed)
    sit_button.pressed.connect(_on_sit_pressed)
    bet_button.pressed.connect(_on_bet_pressed)
    hit_button.pressed.connect(_on_hit_pressed)
    stand_button.pressed.connect(_on_stand_pressed)

func _on_sit_pressed() -> void:
    # Sentarse siempre en el primer asiento libre visible en pantalla; suficiente para
    # la verificación manual de este plan — un selector de asiento por UI queda fuera
    # de alcance aquí.
    table_controller.sit(0)
    my_seat_index = 0

func _on_bet_pressed() -> void:
    table_controller.bet(my_seat_index, 50)

func _on_hit_pressed() -> void:
    table_controller.hit(my_seat_index)

func _on_stand_pressed() -> void:
    table_controller.stand(my_seat_index)

func _on_state_changed(state: Dictionary) -> void:
    dealer_label.text = "Banca: %d" % state["dealer_value"]
    var lines: Array[String] = []
    for i in range(state["seats"].size()):
        var seat = state["seats"][i]
        if seat == null:
            lines.append("Asiento %d: libre" % i)
        else:
            lines.append("Asiento %d: jugador %d — fichas %d — apuesta %d — mano %d" % [
                i, seat["player_id"], seat["balance"], seat["bet"], seat["hand_value"]
            ])
    seats_label.text = "\n".join(lines)
