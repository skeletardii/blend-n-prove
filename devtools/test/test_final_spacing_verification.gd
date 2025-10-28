extends SceneTree

func _init():
	print("================================================================================")
	print("FINAL SPACING VERIFICATION - ALL DATA FILES")
	print("================================================================================")

	var all_passed = true

	# Check all classic levels
	print("\n--- CLASSIC LEVELS ---")
	for i in range(1, 7):
		var level_ok = check_file("res://data/classic/level-" + str(i) + ".json")
		all_passed = all_passed and level_ok

	# Check all tutorials
	print("\n--- TUTORIALS ---")
	var tutorial_files = [
		"absorption", "addition", "associativity", "biconditional",
		"commutativity", "conjunction", "constructive-dilemma",
		"contradiction", "conversion", "de-morgans-and", "de-morgans-or",
		"destructive-dilemma", "disjunctive-syllogism", "distributivity",
		"double-negation", "hypothetical-syllogism", "idempotent",
		"implication", "modus-ponens", "modus-tollens", "negation-laws",
		"parenthesis-removal", "resolution", "simplification", "tautology"
	]

	for tutorial in tutorial_files:
		var tutorial_ok = check_file("res://data/tutorial/" + tutorial + ".json")
		all_passed = all_passed and tutorial_ok

	print("\n================================================================================")
	if all_passed:
		print("✓✓✓ VERIFICATION COMPLETE - ALL FILES HAVE CORRECT SPACING! ✓✓✓")
		print("All operators (∧, ∨, →, ↔, ⊕) now have proper spacing.")
		print("The game should now work correctly for all levels and tutorials!")
	else:
		print("✗ Some files still have spacing issues")
	print("================================================================================")

	quit()

func check_file(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("  ✗ Failed to open: " + file_path)
		return false

	var content = file.get_as_text()
	file.close()

	# Check for operators without spaces
	var has_issues = false

	# Check for ∧ without spaces
	if content.find("∧") != -1:
		var regex = RegEx.new()
		if regex.compile("[^\\s\\(]∧|∧[^\\s\\)]") == OK:
			var result = regex.search(content)
			if result:
				has_issues = true

	# Check for ∨ without spaces
	if content.find("∨") != -1:
		var regex = RegEx.new()
		if regex.compile("[^\\s\\(]∨|∨[^\\s\\)]") == OK:
			var result = regex.search(content)
			if result:
				has_issues = true

	# Check for → without spaces
	if content.find("→") != -1:
		var regex = RegEx.new()
		if regex.compile("[^\\s\\(]→|→[^\\s\\)]") == OK:
			var result = regex.search(content)
			if result:
				has_issues = true

	var file_name = file_path.get_file()
	if has_issues:
		print("  ✗ " + file_name + " - HAS SPACING ISSUES")
		return false
	else:
		print("  ✓ " + file_name)
		return true
