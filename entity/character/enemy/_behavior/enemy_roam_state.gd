class_name EnemyRoamState
extends State

var _enemy: Enemy
var _encounter_starting := false

func enter() -> void:
	_enemy = state_machine.state_owner as Enemy
	EventBus.encounter_started.connect(_on_encounter_started)
	

func update(_delta: float) -> State:
	if _encounter_starting:
		return CharacterCombatBeginState.new()

	return

func _on_encounter_started() -> void:
	_encounter_starting = true
