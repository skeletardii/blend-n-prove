class_name BooleanExpression
extends RefCounted

var expression_string: String
var is_valid: bool = false
var normalized_string: String = ""

func _init(expr: String):
	expression_string = expr.strip_edges()
	parse_expression()

func parse_expression():
	if expression_string.is_empty():
		is_valid = false
		return

	normalized_string = expression_string
	# CRITICAL: Replace longer patterns FIRST to avoid partial matches
	normalized_string = normalized_string.replace("<->", "↔")
	normalized_string = normalized_string.replace("<=>", "↔")
	normalized_string = normalized_string.replace("->", "→")
	normalized_string = normalized_string.replace("=>", "→")
	normalized_string = normalized_string.replace("&&", "∧")
	normalized_string = normalized_string.replace("&", "∧")
	normalized_string = normalized_string.replace("||", "∨")
	normalized_string = normalized_string.replace("|", "∨")
	normalized_string = normalized_string.replace("XOR", "⊕")
	normalized_string = normalized_string.replace("xor", "⊕")
	normalized_string = normalized_string.replace("^", "⊕")
	normalized_string = normalized_string.replace("~", "¬")
	normalized_string = normalized_string.replace("!", "¬")

	is_valid = validate_expression()

func validate_expression() -> bool:
	if normalized_string.is_empty():
		return false

	var paren_count = 0
	for i in range(normalized_string.length()):
		var c = normalized_string[i]
		if c == '(':
			paren_count += 1
		elif c == ')':
			paren_count -= 1
			if paren_count < 0:
				return false

	if paren_count != 0:
		return false

	if "(" in normalized_string and ")" in normalized_string:
		for i in range(normalized_string.length() - 1):
			if normalized_string[i] == '(' and normalized_string[i + 1] == ')':
				return false

	var operators = ["∧", "∨", "⊕", "→", "↔"]
	for i in range(normalized_string.length() - 1):
		var current = normalized_string[i]
		var next = normalized_string[i + 1]
		if current in operators and next in operators:
			return false

	if normalized_string.length() > 0:
		var first_char = normalized_string[0]
		var last_char = normalized_string[normalized_string.length() - 1]

		if first_char in ["∧", "∨", "⊕", "→", "↔"]:
			return false

		if last_char in ["∧", "∨", "⊕", "→", "↔", "¬"]:
			return false

	var tokens = tokenize_expression()
	for token in tokens:
		if not is_valid_token(token):
			return false

	return true

func tokenize_expression() -> Array:
	var tokens = []
	var current_token = ""
	var operators = ["∧", "∨", "⊕", "→", "↔", "¬", "(", ")", " "]

	for i in range(normalized_string.length()):
		var c = normalized_string[i]
		if c in operators:
			if not current_token.is_empty():
				tokens.append(current_token)
				current_token = ""
			if c != " ":
				tokens.append(c)
		else:
			current_token += c

	if not current_token.is_empty():
		tokens.append(current_token)

	return tokens

func is_valid_token(token: String) -> bool:
	if token.is_empty():
		return false

	if token in ["∧", "∨", "⊕", "→", "↔", "¬", "(", ")"]:
		return true

	if token in ["TRUE", "FALSE", "true", "false"]:
		return true

	if token.length() == 1 and ((token >= "A" and token <= "Z") or (token >= "a" and token <= "z")):
		return true

	if token.length() > 1:
		var first_char = token[0]
		if (first_char >= "A" and first_char <= "Z") or (first_char >= "a" and first_char <= "z"):
			for i in range(1, token.length()):
				var c = token[i]
				if not ((c >= "A" and c <= "Z") or (c >= "a" and c <= "z") or (c >= "0" and c <= "9")):
					return false
			return true

	return false

func _get_top_level_operator() -> String:
	# Returns the main operator at parenthesis depth 0
	# Checks operators in precedence order (lowest to highest): ↔, →, ⊕, ∨, ∧
	# This ensures we identify the "top-level" operator that splits the expression

	if not is_valid or normalized_string.is_empty():
		return ""

	# Check for each operator type, starting with lowest precedence
	var operators_to_check = ["↔", "→", "⊕", "∨", "∧"]

	for op in operators_to_check:
		var paren_depth = 0
		for i in range(normalized_string.length()):
			var c = normalized_string[i]
			if c == '(':
				paren_depth += 1
			elif c == ')':
				paren_depth -= 1
			elif paren_depth == 0:
				# Check if we found this operator at depth 0
				if normalized_string.substr(i, op.length()) == op:
					return op

	# Check for negation as top-level operator
	if normalized_string.begins_with("¬"):
		return "¬"

	# No operator found - this is an atomic expression (variable or constant)
	return ""

func equals(other: BooleanExpression) -> bool:
	if not is_valid or not other.is_valid:
		return false
	return normalized_string == other.normalized_string

func is_negation_of(other: BooleanExpression) -> bool:
	if not is_valid or not other.is_valid:
		return false
	return (normalized_string.begins_with("¬") and normalized_string.substr(1).strip_edges() == other.normalized_string) or (other.normalized_string.begins_with("¬") and other.normalized_string.substr(1).strip_edges() == normalized_string)

func is_implication() -> bool:
	return "→" in normalized_string

func get_implication_parts() -> Dictionary:
	if not is_implication():
		return {"valid": false}

	var str = normalized_string

	if str.begins_with("(") and str.ends_with(")"):
		var paren_count = 0
		var can_strip = true
		for i in range(1, str.length() - 1):
			if str[i] == '(':
				paren_count += 1
			elif str[i] == ')':
				paren_count -= 1
				if paren_count < 0:
					can_strip = false
					break
		if can_strip and paren_count == 0:
			str = str.substr(1, str.length() - 2).strip_edges()

	var paren_depth = 0
	for i in range(str.length()):
		if str[i] == '(':
			paren_depth += 1
		elif str[i] == ')':
			paren_depth -= 1
		elif str[i] == '→' and paren_depth == 0:
			var ante_str = str.substr(0, i).strip_edges()
			var cons_str = str.substr(i + 1).strip_edges()
			if not ante_str.is_empty() and not cons_str.is_empty():
				return {
					"valid": true,
					"antecedent": BooleanExpression.new(ante_str),
					"consequent": BooleanExpression.new(cons_str)
				}

	return {"valid": false}

func is_biconditional() -> bool:
	return _get_top_level_operator() == "↔"

func get_biconditional_parts() -> Dictionary:
	if not is_biconditional():
		return {"valid": false}

	var str = normalized_string

	if str.begins_with("(") and str.ends_with(")"):
		var paren_count = 0
		var can_strip = true
		for i in range(1, str.length() - 1):
			if str[i] == '(':
				paren_count += 1
			elif str[i] == ')':
				paren_count -= 1
				if paren_count < 0:
					can_strip = false
					break
		if can_strip and paren_count == 0:
			str = str.substr(1, str.length() - 2).strip_edges()

	var paren_depth = 0
	for i in range(str.length()):
		if str[i] == '(':
			paren_depth += 1
		elif str[i] == ')':
			paren_depth -= 1
		elif str[i] == '↔' and paren_depth == 0:
			var left_str = str.substr(0, i).strip_edges()
			var right_str = str.substr(i + 1).strip_edges()
			if not left_str.is_empty() and not right_str.is_empty():
				return {
					"valid": true,
					"left": BooleanExpression.new(left_str),
					"right": BooleanExpression.new(right_str)
				}

	return {"valid": false}

func is_xor() -> bool:
	return _get_top_level_operator() == "⊕"

func get_xor_parts() -> Dictionary:
	if not is_xor():
		return {"valid": false}

	var str = normalized_string

	if str.begins_with("(") and str.ends_with(")"):
		var paren_count = 0
		var can_strip = true
		for i in range(1, str.length() - 1):
			if str[i] == '(':
				paren_count += 1
			elif str[i] == ')':
				paren_count -= 1
				if paren_count < 0:
					can_strip = false
					break
		if can_strip and paren_count == 0:
			str = str.substr(1, str.length() - 2).strip_edges()

	var paren_depth = 0
	for i in range(str.length()):
		if str[i] == '(':
			paren_depth += 1
		elif str[i] == ')':
			paren_depth -= 1
		elif str[i] == '⊕' and paren_depth == 0:
			var left_str = str.substr(0, i).strip_edges()
			var right_str = str.substr(i + 1).strip_edges()
			if not left_str.is_empty() and not right_str.is_empty():
				return {
					"valid": true,
					"left": BooleanExpression.new(left_str),
					"right": BooleanExpression.new(right_str)
				}

	return {"valid": false}

func is_conjunction() -> bool:
	return _get_top_level_operator() == "∧"

func get_conjunction_parts() -> Dictionary:
	if not is_conjunction():
		return {"valid": false}

	var str = normalized_string

	if str.begins_with("(") and str.ends_with(")"):
		var paren_count = 0
		var can_strip = true
		for i in range(1, str.length() - 1):
			if str[i] == '(':
				paren_count += 1
			elif str[i] == ')':
				paren_count -= 1
				if paren_count < 0:
					can_strip = false
					break
		if can_strip and paren_count == 0:
			str = str.substr(1, str.length() - 2).strip_edges()

	var paren_depth = 0
	for i in range(str.length()):
		if str[i] == '(':
			paren_depth += 1
		elif str[i] == ')':
			paren_depth -= 1
		elif str[i] == '∧' and paren_depth == 0:
			var left_str = str.substr(0, i).strip_edges()
			var right_str = str.substr(i + 1).strip_edges()
			if not left_str.is_empty() and not right_str.is_empty():
				return {
					"valid": true,
					"left": BooleanExpression.new(left_str),
					"right": BooleanExpression.new(right_str)
				}

	return {"valid": false}

func is_disjunction() -> bool:
	return _get_top_level_operator() == "∨"

func get_disjunction_parts() -> Dictionary:
	if not is_disjunction():
		return {"valid": false}

	var str = normalized_string

	if str.begins_with("(") and str.ends_with(")"):
		var paren_count = 0
		var can_strip = true
		for i in range(1, str.length() - 1):
			if str[i] == '(':
				paren_count += 1
			elif str[i] == ')':
				paren_count -= 1
				if paren_count < 0:
					can_strip = false
					break
		if can_strip and paren_count == 0:
			str = str.substr(1, str.length() - 2).strip_edges()

	var paren_depth = 0
	for i in range(str.length()):
		if str[i] == '(':
			paren_depth += 1
		elif str[i] == ')':
			paren_depth -= 1
		elif str[i] == '∨' and paren_depth == 0:
			var left_str = str.substr(0, i).strip_edges()
			var right_str = str.substr(i + 1).strip_edges()
			if not left_str.is_empty() and not right_str.is_empty():
				return {
					"valid": true,
					"left": BooleanExpression.new(left_str),
					"right": BooleanExpression.new(right_str)
				}

	return {"valid": false}
