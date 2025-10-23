extends Panel

signal popup_closed()

# UI References
@onready var hint_title: Label = $MarginContainer/VBoxContainer/HintTitle
@onready var hint_text: RichTextLabel = $MarginContainer/VBoxContainer/HintScrollContainer/HintText
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	hide()

func show_hint(solution_text: String) -> void:
	hint_text.bbcode_enabled = true
	hint_text.text = "[color=yellow][b]Solution:[/b][/color]\n" + solution_text
	show()

func _on_close_button_pressed() -> void:
	hide()
	popup_closed.emit()
