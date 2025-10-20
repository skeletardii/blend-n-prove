extends Node

# Test script to verify JSON loading works correctly

func _ready() -> void:
	print("=== Testing JSON Loading ===\n")
	test_tutorial_json_loading()
	test_classic_json_loading()
	print("\n=== All Tests Complete ===")
	get_tree().quit()

func test_tutorial_json_loading() -> void:
	print("Testing Tutorial JSON Loading...")

	var test_file: String = "res://data/tutorial/modus-ponens.json"

	if not FileAccess.file_exists(test_file):
		print("✗ Test file not found: ", test_file)
		return

	var file: FileAccess = FileAccess.open(test_file, FileAccess.READ)
	if not file:
		print("✗ Failed to open test file")
		return

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(content)

	if error != OK:
		print("✗ JSON parse error: ", json.get_error_message())
		return

	var data: Dictionary = json.data

	# Verify structure
	if not data.has("rule_name"):
		print("✗ Missing rule_name field")
		return

	if not data.has("problems"):
		print("✗ Missing problems field")
		return

	var problems: Array = data.get("problems", [])
	if problems.size() == 0:
		print("✗ No problems found")
		return

	var first_problem: Dictionary = problems[0]
	if not first_problem.has("premises") or not first_problem.has("conclusion") or not first_problem.has("solution"):
		print("✗ Problem missing required fields")
		return

	print("✓ Tutorial JSON structure valid")
	print("  - Rule: ", data.get("rule_name"))
	print("  - Problems: ", problems.size())
	print("  - First problem premises: ", first_problem.get("premises"))
	print("  - First problem conclusion: ", first_problem.get("conclusion"))
	print("  - First problem solution: ", first_problem.get("solution"))

func test_classic_json_loading() -> void:
	print("\nTesting Classic JSON Loading...")

	var test_file: String = "res://data/classic/level-1.json"

	if not FileAccess.file_exists(test_file):
		print("✗ Test file not found: ", test_file)
		return

	var file: FileAccess = FileAccess.open(test_file, FileAccess.READ)
	if not file:
		print("✗ Failed to open test file")
		return

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(content)

	if error != OK:
		print("✗ JSON parse error: ", json.get_error_message())
		return

	var data: Dictionary = json.data

	# Verify structure
	if not data.has("level"):
		print("✗ Missing level field")
		return

	if not data.has("problems"):
		print("✗ Missing problems field")
		return

	var problems: Array = data.get("problems", [])
	if problems.size() == 0:
		print("✗ No problems found")
		return

	var first_problem: Dictionary = problems[0]
	if not first_problem.has("premises") or not first_problem.has("conclusion") or not first_problem.has("expected_operations") or not first_problem.has("solution"):
		print("✗ Problem missing required fields")
		return

	print("✓ Classic JSON structure valid")
	print("  - Level: ", data.get("level"))
	print("  - Description: ", data.get("description"))
	print("  - Problems: ", problems.size())
	print("  - First problem premises: ", first_problem.get("premises"))
	print("  - First problem conclusion: ", first_problem.get("conclusion"))
	print("  - First problem operations: ", first_problem.get("expected_operations"))
	print("  - First problem solution: ", first_problem.get("solution"))
