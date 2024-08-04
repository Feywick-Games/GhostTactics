class_name BattleTimer
extends TextureProgressBar

var _running: float = 0

func _ready() -> void:
	EventBus.turn_started.connect(_on_turn_started)
	GameState.battle_timer = self
	EventBus.encounter_started.connect(_on_encounter_started)
	EventBus.encounter_ended.connect(_on_encounter_ended)
	value = 0
	EventBus.timer_stopped.connect(_on_timer_stopped)
	hide()


func _on_timer_stopped() -> void:
	_running = false


func _on_encounter_started(group: String) -> void:
	show()


func _on_encounter_ended() -> void:
	hide()


func _on_turn_started(_unit: Character) -> void:
	value = 0
	_running = true
	
	
func _on_turn_ended() -> void:
	_running = false
	
	
func _process(delta: float) -> void:
	if _running:
		value += delta
		
	if value == max_value:
		EventBus.timed_out.emit()
		_running = false
