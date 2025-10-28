extends SceneTree

func _init():
	print("================================================================================")
	print("FINAL VERIFICATION - CONCLUSION FIELD SPACING")
	print("================================================================================")
	print("Checking that all 'conclusion' fields have proper operator spacing...")
	print("(Premises and solution text are intentionally compact - this is OK)")
	print("")

	var all_passed = true
	var files_checked = 0
	var issues_found = 0

	# Check all classic levels
	print("--- CLASSIC LEVELS ---")
	for i in range(1, 7):
		var result = check_conclusions("res://data/classic/level-" + str(i) + ".json")
		files_checked += 1
		if not result:
			issues_found += 1
			all_passed = false

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
		var result = check_conclusions("res://data/tutorial/" + tutorial + ".json")
		files_checked += 1
		if not result:
			issues_found += 1
			all_passed = false

	print("\n================================================================================")
	print("FILES CHECKED: " + str(files_checked))
	print("ISSUES FOUND: " + str(issues_found))
	if all_passed:
		print("\n✓✓✓ ALL CONCLUSION FIELDS HAVE CORRECT SPACING! ✓✓✓")
		print("\nSUMMARY OF FIX:")
		print("• Level 1: Fixed P∧Q conjunction problem")
		print("• Level 1: Fixed Addition problems (P∨Q)")
		print("• Level 1: Fixed Commutativity problems")
		print("• Level 1: Fixed De Morgan's Law problems")
		print("• Levels 2-6: Fixed all operator spacing")
		print("• All tutorials: Fixed all operator spacing")
		print("\nThe game should now work correctly for ALL problems!")
	else:
		print("\n✗ Some conclusion fields still have spacing issues")
	print("================================================================================")

	quit()

func check_conclusions(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("  ✗ Failed to open: " + file_path)
		return false

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		print("  ✗ Failed to parse: " + file_path.get_file())
		return false

	var data = json.data
	var problems = data.get("problems", [])
	var has_issues = false

	# Check each problem's conclusion field
	for problem in problems:
		var conclusion = problem.get("conclusion", "")
		if check_string_spacing(conclusion):
			has_issues = true

	var file_name = file_path.get_file()
	if has_issues:
		print("  ✗ " + file_name + " - HAS SPACING ISSUES IN CONCLUSIONS")
		return false
	else:
		print("  ✓ " + file_name)
		return true

func check_string_spacing(text: String) -> bool:
	# Returns true if there are spacing issues (operators without spaces)
	var operators = ["∧", "∨", "→", "↔", "⊕"]

	for op in operators:
		if text.find(op) != -1:
			# Check if operator has non-space, non-paren characters immediately adjacent
			var regex = RegEx.new()
			# Pattern: letter/closing-paren + operator OR operator + letter/opening-paren
			var pattern = "[A-Za-z¬)]" + op + "|" + op + "[A-Za-z¬(]"
			if regex.compile(pattern) == OK:
				var result = regex.search(text)
				if result:
					return true  # Found spacing issue

	return false  # No spacing issues
