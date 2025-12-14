extends Control

signal popup_closed()
signal skip_requested()

# UI References
@onready var hint_title: Label = $Panel/MarginContainer/VBoxContainer/HintTitle
@onready var hint_text: RichTextLabel = $Panel/MarginContainer/VBoxContainer/HintScrollContainer/HintText
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var skip_button: Button = $Panel/MarginContainer/VBoxContainer/ButtonContainer/SkipButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	skip_button.pressed.connect(_on_skip_button_pressed)
	hide()

func show_hint(solution_text: String) -> void:
	hint_text.bbcode_enabled = true
	hint_text.text = "[color=black][b]Solution:[/b][/color]\n" + solution_text
	show()

func _on_close_button_pressed() -> void:
	hide()
	popup_closed.emit()

func _on_skip_button_pressed() -> void:
	hide()
	skip_requested.emit()
