extends SceneTree

func _init():
	print("=== Debug Test 4 ===")

	var engine = load("res://src/game/autoloads/BooleanLogicEngine.gd").new()

	var test = engine.create_expression("((P ∧ Q) ∧ R)")
	print("Input: ", test.expression_string)
	print()

	# Manually check the inner string
	var normalized = test.normalized_string
	print("Normalized: ", normalized)
	print("Begins with (: ", normalized.begins_with("("))
	print("Ends with ): ", normalized.ends_with(")"))
	print()

	if normalized.begins_with("(") and normalized.ends_with(")"):
		var inner = normalized.substr(1, normalized.length() - 2).strip_edges()
		print("Inner string: '", inner, "'")
		print("Inner begins with (: ", inner.begins_with("("))
		print("Inner ends with ): ", inner.ends_with(")"))
		print()

		var has_binary_op = engine._has_top_level_binary_operator(inner)
		print("Has top-level binary op: ", has_binary_op)

		var inner_has_outer_parens = inner.begins_with("(") and inner.ends_with(")")
		print("Inner has outer parens: ", inner_has_outer_parens)
		print()

		print("Should remove? ", not has_binary_op or inner_has_outer_parens)

	quit()
