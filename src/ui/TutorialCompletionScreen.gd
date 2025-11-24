extends Control
class_name TutorialCompletionScreen

## Completion screen shown after finishing the first-time tutorial

signal return_to_menu_requested

@onready var return_button: Button = $Panel/MarginContainer/VBoxContainer/ReturnButton


func _ready() -> void:
	return_button.pressed.connect(_on_return_button_pressed)


func _on_return_button_pressed() -> void:
	return_to_menu_requested.emit()
