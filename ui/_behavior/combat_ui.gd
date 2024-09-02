class_name CombatUI
extends CanvasLayer

@onready
var skill_label: Label = %SkillLabel

func _ready() -> void:
	skill_label.hide()


func display_skill_text(skill_text: String) -> void:
	skill_label.show()
	skill_label.text = skill_text
	await get_tree().create_timer(2).timeout
	skill_label.hide()
