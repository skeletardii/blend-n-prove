extends Control

@onready var back_button: Button = $MainContainer/BackButton

func _ready() -> void:
	AudioManager.start_menu_music()
	
	# Connect back button
	if not back_button.pressed.is_connected(_on_back_button_pressed):
		back_button.pressed.connect(_on_back_button_pressed)
	
	# Connect all grid buttons
	for i in range(1, 19):
		var button = $MainContainer/ButtonGrid.get_node("Button" + str(i)) as Button
		if button and not button.pressed.is_connected(_on_grid_button_pressed):
			button.pressed.connect(_on_grid_button_pressed.bind(i))

func _on_back_button_pressed() -> void:
	AudioManager.play_button_click()
	SceneManager.change_scene("res://scenes/MainMenu.tscn")

func _on_grid_button_pressed(button_number: int) -> void:
	AudioManager.play_button_click()
	print("Grid button pressed: ", button_number)
