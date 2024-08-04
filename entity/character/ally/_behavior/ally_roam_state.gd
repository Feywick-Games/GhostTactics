class_name AllyRoamState
extends State

var _ally: Ally
var _encounter_starting := false

func enter() -> void:
	_ally = state_machine.state_owner as Ally
	EventBus.encounter_started.connect(_on_encounter_started)
	GameState.add_to_ally_order(_ally, _ally.follow_order)


func update(_delta: float) -> State:
	if _encounter_starting:
		return CharacterCombatBeginState.new()

	return

func _on_encounter_started(_group: String) -> void:
	_encounter_starting = true
