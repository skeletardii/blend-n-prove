extends Node

func _ready():
	# Ensure BooleanExpression is loaded and its class_name is registered
	load("res://src/game/expressions/BooleanExpression.gd")
	var test_script = load("res://devtools/test/test_tutorials.gd").new()
	add_child(test_script)
