extends SceneTree

func _init():
	print("================================================================================")
	print("FIXING SPACING IN ALL LEVEL FILES")
	print("================================================================================")

	var files = [
		"res://data/classic/level-2.json",
		"res://data/classic/level-3.json",
		"res://data/classic/level-4.json",
		"res://data/classic/level-5.json",
		"res://data/classic/level-6.json"
	]

	for file_path in files:
		fix_spacing_in_file(file_path)

	print("\n================================================================================")
	print("SPACING FIX COMPLETE")
	print("================================================================================")

	quit()

func fix_spacing_in_file(file_path: String):
	print("\nProcessing: " + file_path)

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("  ✗ Failed to open file")
		return

	var content = file.get_as_text()
	file.close()

	var original_content = content

	# Fix spacing around operators in conclusion strings
	# Pattern: "conclusion": "...∧..." or "conclusion": "...∨..."
	# We need to add spaces around ∧ and ∨ operators

	# This regex will match operators that don't have spaces around them
	content = fix_operator_spacing(content, "∧")
	content = fix_operator_spacing(content, "∨")
	content = fix_operator_spacing(content, "→")
	content = fix_operator_spacing(content, "↔")
	content = fix_operator_spacing(content, "⊕")

	if content != original_content:
		# Write back to file
		var write_file = FileAccess.open(file_path, FileAccess.WRITE)
		if write_file:
			write_file.store_string(content)
			write_file.close()
			print("  ✓ Fixed spacing issues")
		else:
			print("  ✗ Failed to write file")
	else:
		print("  ✓ No spacing issues found")

func fix_operator_spacing(text: String, operator: String) -> String:
	var result = text

	# Add space before operator if missing (but not at start of string or after space/paren)
	var regex_before = RegEx.new()
	var pattern_before = "([^\\s\\(])" + operator
	if regex_before.compile(pattern_before) == OK:
		result = regex_before.sub(result, "$1 " + operator, true)

	# Add space after operator if missing (but not at end of string or before space/paren)
	var regex_after = RegEx.new()
	var pattern_after = operator + "([^\\s\\)])"
	if regex_after.compile(pattern_after) == OK:
		result = regex_after.sub(result, operator + " $1", true)

	return result
