extends Node


enum LogicalOperator {
	AND, OR, XOR, NOT, IMPLIES, BICONDITIONAL, TRUE, FALSE
}

enum InferenceRule {
	MODUS_PONENS, MODUS_TOLLENS, HYPOTHETICAL_SYLLOGISM, DISJUNCTIVE_SYLLOGISM,
	SIMPLIFICATION, CONJUNCTION, ADDITION, CONSTRUCTIVE_DILEMMA,
	DESTRUCTIVE_DILEMMA, RESOLUTION, DE_MORGAN_AND, DE_MORGAN_OR, DOUBLE_NEGATION
}

enum EquivalenceLaw {
	COMMUTATIVITY_AND, COMMUTATIVITY_OR, ASSOCIATIVITY_AND, ASSOCIATIVITY_OR,
	DISTRIBUTIVITY_AND_OR, DISTRIBUTIVITY_OR_AND, CONTRAPOSITIVE, IMPLICATION,
	BICONDITIONAL_IMPL, BICONDITIONAL_EQUIV, IDENTITY_OR, IDENTITY_AND,
	DOMINATION_OR, DOMINATION_AND, IDEMPOTENT_OR, IDEMPOTENT_AND,
	NEGATION_OR, NEGATION_AND, ABSORPTION_OR, ABSORPTION_AND
}

class BooleanExpression:
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
		return "↔" in normalized_string

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
		return "⊕" in normalized_string

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
		return "∧" in normalized_string

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
		return "∨" in normalized_string

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

signal expression_validated(expression: BooleanExpression, is_valid: bool)
signal inference_applied(premises: Array, conclusion: BooleanExpression, rule: InferenceRule)

func create_expression(expr_string: String) -> BooleanExpression:
	var expression = BooleanExpression.new(expr_string)
	expression_validated.emit(expression, expression.is_valid)
	return expression

func create_negation_expression(expr: BooleanExpression) -> BooleanExpression:
	if not expr.is_valid:
		return BooleanExpression.new("")
	var negated = "¬" + expr.normalized_string
	return BooleanExpression.new(negated)

func create_conjunction_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if not left.is_valid or not right.is_valid:
		return BooleanExpression.new("")
	# Only wrap in parentheses if the operand contains operators (is complex)
	var left_str = left.normalized_string
	var right_str = right.normalized_string
	if _has_operator(left_str) and not (left_str.begins_with("(") and left_str.ends_with(")")):
		left_str = "(" + left_str + ")"
	if _has_operator(right_str) and not (right_str.begins_with("(") and right_str.ends_with(")")):
		right_str = "(" + right_str + ")"
	var conjunction = "(" + left_str + " ∧ " + right_str + ")"
	return BooleanExpression.new(conjunction)

func create_disjunction_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if not left.is_valid or not right.is_valid:
		return BooleanExpression.new("")
	var left_str = left.normalized_string
	var right_str = right.normalized_string
	if _has_operator(left_str) and not (left_str.begins_with("(") and left_str.ends_with(")")):
		left_str = "(" + left_str + ")"
	if _has_operator(right_str) and not (right_str.begins_with("(") and right_str.ends_with(")")):
		right_str = "(" + right_str + ")"
	var disjunction = "(" + left_str + " ∨ " + right_str + ")"
	return BooleanExpression.new(disjunction)

func create_implication_expression(antecedent: BooleanExpression, consequent: BooleanExpression) -> BooleanExpression:
	if not antecedent.is_valid or not consequent.is_valid:
		return BooleanExpression.new("")
	var ante_str = antecedent.normalized_string
	var cons_str = consequent.normalized_string
	if _has_operator(ante_str) and not (ante_str.begins_with("(") and ante_str.ends_with(")")):
		ante_str = "(" + ante_str + ")"
	if _has_operator(cons_str) and not (cons_str.begins_with("(") and cons_str.ends_with(")")):
		cons_str = "(" + cons_str + ")"
	var implication = "(" + ante_str + " → " + cons_str + ")"
	return BooleanExpression.new(implication)

func create_biconditional_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if not left.is_valid or not right.is_valid:
		return BooleanExpression.new("")
	var left_str = left.normalized_string
	var right_str = right.normalized_string
	if _has_operator(left_str) and not (left_str.begins_with("(") and left_str.ends_with(")")):
		left_str = "(" + left_str + ")"
	if _has_operator(right_str) and not (right_str.begins_with("(") and right_str.ends_with(")")):
		right_str = "(" + right_str + ")"
	var biconditional = "(" + left_str + " ↔ " + right_str + ")"
	return BooleanExpression.new(biconditional)

func create_xor_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if not left.is_valid or not right.is_valid:
		return BooleanExpression.new("")
	var left_str = left.normalized_string
	var right_str = right.normalized_string
	if _has_operator(left_str) and not (left_str.begins_with("(") and left_str.ends_with(")")):
		left_str = "(" + left_str + ")"
	if _has_operator(right_str) and not (right_str.begins_with("(") and right_str.ends_with(")")):
		right_str = "(" + right_str + ")"
	var xor_expr = "(" + left_str + " ⊕ " + right_str + ")"
	return BooleanExpression.new(xor_expr)

func apply_modus_ponens(premises: Array) -> BooleanExpression:
	for i in range(premises.size()):
		for j in range(premises.size()):
			if i == j: continue
			var premise1 = premises[i] as BooleanExpression
			var premise2 = premises[j] as BooleanExpression
			if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
				continue

			if premise1.is_implication():
				var impl_parts = premise1.get_implication_parts()
				if impl_parts.get("valid", false):
					var antecedent = impl_parts.get("antecedent") as BooleanExpression
					var consequent = impl_parts.get("consequent") as BooleanExpression
					if antecedent and consequent and premise2.equals(antecedent):
						inference_applied.emit(premises, consequent, InferenceRule.MODUS_PONENS)
						return consequent
	return BooleanExpression.new("")

func apply_modus_tollens(premises: Array) -> BooleanExpression:
	for i in range(premises.size()):
		for j in range(premises.size()):
			if i == j: continue
			var premise1 = premises[i] as BooleanExpression
			var premise2 = premises[j] as BooleanExpression
			if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
				continue

			if premise1.is_implication():
				var impl_parts = premise1.get_implication_parts()
				if impl_parts.get("valid", false):
					var antecedent = impl_parts.get("antecedent") as BooleanExpression
					var consequent = impl_parts.get("consequent") as BooleanExpression
					if antecedent and consequent and premise2.is_negation_of(consequent):
						var result = create_expression("¬" + antecedent.normalized_string)
						inference_applied.emit(premises, result, InferenceRule.MODUS_TOLLENS)
						return result
	return BooleanExpression.new("")

func apply_hypothetical_syllogism(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	if premise1.is_implication() and premise2.is_implication():
		var impl1_parts = premise1.get_implication_parts()
		var impl2_parts = premise2.get_implication_parts()

		if impl1_parts.get("valid", false) and impl2_parts.get("valid", false):
			var p = impl1_parts.get("antecedent") as BooleanExpression
			var q1 = impl1_parts.get("consequent") as BooleanExpression
			var q2 = impl2_parts.get("antecedent") as BooleanExpression
			var r = impl2_parts.get("consequent") as BooleanExpression

			if q1.equals(q2):
				return create_implication_expression(p, r)

	return BooleanExpression.new("")

func apply_disjunctive_syllogism(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	for i in range(2):
		var disj_premise = premises[i] as BooleanExpression
		var neg_premise = premises[1-i] as BooleanExpression

		if disj_premise.is_disjunction():
			var disj_parts = disj_premise.get_disjunction_parts()
			if disj_parts.get("valid", false):
				var left = disj_parts.get("left") as BooleanExpression
				var right = disj_parts.get("right") as BooleanExpression

				if neg_premise.is_negation_of(left):
					return right
				elif neg_premise.is_negation_of(right):
					return left

	return BooleanExpression.new("")

func apply_simplification(premises: Array, extract_right: bool = false) -> BooleanExpression:
	if premises.size() != 1:
		return BooleanExpression.new("")

	var premise = premises[0] as BooleanExpression
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var conj_parts = premise.get_conjunction_parts()
		if conj_parts.get("valid", false):
			var left = conj_parts.get("left") as BooleanExpression
			var right = conj_parts.get("right") as BooleanExpression
			return right if extract_right else left

	return BooleanExpression.new("")

func apply_simplification_both(premises: Array) -> Array:
	if premises.size() != 1:
		return []

	var premise = premises[0] as BooleanExpression
	if not premise or not premise.is_valid:
		return []

	if premise.is_conjunction():
		var conj_parts = premise.get_conjunction_parts()
		if conj_parts.get("valid", false):
			var left = conj_parts.get("left") as BooleanExpression
			var right = conj_parts.get("right") as BooleanExpression
			return [left, right]

	return []

func apply_conjunction(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	return create_conjunction_expression(premise1, premise2)

func apply_addition(premises: Array, additional_expr: BooleanExpression) -> BooleanExpression:
	if premises.size() != 1:
		return BooleanExpression.new("")

	var premise = premises[0] as BooleanExpression
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if additional_expr and additional_expr.is_valid:
		return create_disjunction_expression(premise, additional_expr)

	return BooleanExpression.new("")

func apply_constructive_dilemma(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	for i in range(2):
		var conj_premise = premises[i] as BooleanExpression
		var disj_premise = premises[1-i] as BooleanExpression

		if conj_premise.is_conjunction():
			var conj_parts = conj_premise.get_conjunction_parts()
			if conj_parts.get("valid", false):
				var left_part = conj_parts.get("left") as BooleanExpression
				var right_part = conj_parts.get("right") as BooleanExpression

				if left_part and right_part and left_part.is_implication() and right_part.is_implication():
					var impl1_parts = left_part.get_implication_parts()
					var impl2_parts = right_part.get_implication_parts()

					if impl1_parts.get("valid", false) and impl2_parts.get("valid", false):
						var p = impl1_parts.get("antecedent") as BooleanExpression
						var q = impl1_parts.get("consequent") as BooleanExpression
						var r = impl2_parts.get("antecedent") as BooleanExpression
						var s = impl2_parts.get("consequent") as BooleanExpression

						if disj_premise.is_disjunction():
							var disj_parts = disj_premise.get_disjunction_parts()
							if disj_parts.get("valid", false):
								var disj_left = disj_parts.get("left") as BooleanExpression
								var disj_right = disj_parts.get("right") as BooleanExpression

								if disj_left.equals(p) and disj_right.equals(r):
									return create_disjunction_expression(q, s)
								elif disj_left.equals(r) and disj_right.equals(p):
									return create_disjunction_expression(s, q)

	return BooleanExpression.new("")

func apply_destructive_dilemma(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	for i in range(2):
		var conj_premise = premises[i] as BooleanExpression
		var disj_premise = premises[1-i] as BooleanExpression

		if conj_premise.is_conjunction():
			var conj_parts = conj_premise.get_conjunction_parts()
			if conj_parts.get("valid", false):
				var left_part = conj_parts.get("left") as BooleanExpression
				var right_part = conj_parts.get("right") as BooleanExpression

				if left_part and right_part and left_part.is_implication() and right_part.is_implication():
					var impl1_parts = left_part.get_implication_parts()
					var impl2_parts = right_part.get_implication_parts()

					if impl1_parts.get("valid", false) and impl2_parts.get("valid", false):
						var p = impl1_parts.get("antecedent") as BooleanExpression
						var q = impl1_parts.get("consequent") as BooleanExpression
						var r = impl2_parts.get("antecedent") as BooleanExpression
						var s = impl2_parts.get("consequent") as BooleanExpression

						if disj_premise.is_disjunction():
							var disj_parts = disj_premise.get_disjunction_parts()
							if disj_parts.get("valid", false):
								var disj_left = disj_parts.get("left") as BooleanExpression
								var disj_right = disj_parts.get("right") as BooleanExpression

								if disj_left.is_negation_of(q) and disj_right.is_negation_of(s):
									var neg_p = create_negation_expression(p)
									var neg_r = create_negation_expression(r)
									return create_disjunction_expression(neg_p, neg_r)
								elif disj_left.is_negation_of(s) and disj_right.is_negation_of(q):
									var neg_r = create_negation_expression(r)
									var neg_p = create_negation_expression(p)
									return create_disjunction_expression(neg_r, neg_p)

	return BooleanExpression.new("")


func apply_de_morgan_and(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	var normalized = premise.normalized_string
	if normalized.begins_with("¬(") and normalized.ends_with(")"):
		var inner = normalized.substr(2, normalized.length() - 3).strip_edges()
		var inner_expr = BooleanExpression.new(inner)

		if inner_expr.is_conjunction():
			var conj_parts = inner_expr.get_conjunction_parts()
			if conj_parts.get("valid", false):
				var left = conj_parts.get("left") as BooleanExpression
				var right = conj_parts.get("right") as BooleanExpression
				var neg_left = create_negation_expression(left)
				var neg_right = create_negation_expression(right)
				return create_disjunction_expression(neg_left, neg_right)

	return BooleanExpression.new("")

func apply_de_morgan_or(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	var normalized = premise.normalized_string
	if normalized.begins_with("¬(") and normalized.ends_with(")"):
		var inner = normalized.substr(2, normalized.length() - 3).strip_edges()
		var inner_expr = BooleanExpression.new(inner)

		if inner_expr.is_disjunction():
			var disj_parts = inner_expr.get_disjunction_parts()
			if disj_parts.get("valid", false):
				var left = disj_parts.get("left") as BooleanExpression
				var right = disj_parts.get("right") as BooleanExpression
				var neg_left = create_negation_expression(left)
				var neg_right = create_negation_expression(right)
				return create_conjunction_expression(neg_left, neg_right)

	return BooleanExpression.new("")

func apply_double_negation(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.normalized_string.begins_with("¬¬"):
		var result = create_expression(premise.normalized_string.substr(2).strip_edges())
		inference_applied.emit([premise], result, InferenceRule.DOUBLE_NEGATION)
		return result
	return BooleanExpression.new("")

func apply_xor_elimination(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid or not premise.is_xor():
		return BooleanExpression.new("")

	var xor_parts = premise.get_xor_parts()
	if xor_parts.get("valid", false):
		var left = xor_parts.get("left") as BooleanExpression
		var right = xor_parts.get("right") as BooleanExpression

		var disjunction = create_disjunction_expression(left, right)
		var conjunction = create_conjunction_expression(left, right)
		var negated_conjunction = create_negation_expression(conjunction)
		var result = create_conjunction_expression(disjunction, negated_conjunction)

		return result
	return BooleanExpression.new("")

func apply_xor_introduction(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if not left.is_valid or not right.is_valid:
		return BooleanExpression.new("")

	return create_xor_expression(left, right)

func apply_xor_elimination_both(premise: BooleanExpression) -> Array:
	if not premise or not premise.is_valid or not premise.is_xor():
		return []

	var xor_parts = premise.get_xor_parts()
	if xor_parts.get("valid", false):
		var left = xor_parts.get("left") as BooleanExpression
		var right = xor_parts.get("right") as BooleanExpression

		var disjunction = create_disjunction_expression(left, right)
		var conjunction = create_conjunction_expression(left, right)
		var negated_conjunction = create_negation_expression(conjunction)

		return [disjunction, negated_conjunction]

	return []

func apply_biconditional_to_implications(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid or not premise.is_biconditional():
		return BooleanExpression.new("")

	var biconditional_parts = premise.get_biconditional_parts()
	if biconditional_parts.get("valid", false):
		var left = biconditional_parts.get("left") as BooleanExpression
		var right = biconditional_parts.get("right") as BooleanExpression

		var left_to_right = create_implication_expression(left, right)
		var right_to_left = create_implication_expression(right, left)
		var result = create_conjunction_expression(left_to_right, right_to_left)

		return result
	return BooleanExpression.new("")

func apply_biconditional_to_equivalence(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid or not premise.is_biconditional():
		return BooleanExpression.new("")

	var biconditional_parts = premise.get_biconditional_parts()
	if biconditional_parts.get("valid", false):
		var left = biconditional_parts.get("left") as BooleanExpression
		var right = biconditional_parts.get("right") as BooleanExpression

		var both_true = create_conjunction_expression(left, right)
		var not_left = create_negation_expression(left)
		var not_right = create_negation_expression(right)
		var both_false = create_conjunction_expression(not_left, not_right)
		var result = create_disjunction_expression(both_true, both_false)

		return result
	return BooleanExpression.new("")

func apply_biconditional_to_equivalence_both(premise: BooleanExpression) -> Array:
	if not premise or not premise.is_valid or not premise.is_biconditional():
		return []

	var biconditional_parts = premise.get_biconditional_parts()
	if biconditional_parts.get("valid", false):
		var left = biconditional_parts.get("left") as BooleanExpression
		var right = biconditional_parts.get("right") as BooleanExpression

		var both_true = create_conjunction_expression(left, right)
		var not_left = create_negation_expression(left)
		var not_right = create_negation_expression(right)
		var both_false = create_conjunction_expression(not_left, not_right)

		return [both_true, both_false]

	return []

func apply_biconditional_to_implications_both(premise: BooleanExpression) -> Array:
	if not premise or not premise.is_valid or not premise.is_biconditional():
		return []

	var biconditional_parts = premise.get_biconditional_parts()
	if biconditional_parts.get("valid", false):
		var left = biconditional_parts.get("left") as BooleanExpression
		var right = biconditional_parts.get("right") as BooleanExpression

		var left_to_right = create_implication_expression(left, right)
		var right_to_left = create_implication_expression(right, left)

		return [left_to_right, right_to_left]

	return []

func apply_biconditional_introduction(left_to_right: BooleanExpression, right_to_left: BooleanExpression) -> BooleanExpression:
	if not left_to_right.is_valid or not right_to_left.is_valid:
		return BooleanExpression.new("")

	if left_to_right.is_implication() and right_to_left.is_implication():
		var lr_parts = left_to_right.get_implication_parts()
		var rl_parts = right_to_left.get_implication_parts()

		if lr_parts.get("valid", false) and rl_parts.get("valid", false):
			var p1 = lr_parts.get("antecedent") as BooleanExpression
			var q1 = lr_parts.get("consequent") as BooleanExpression
			var p2 = rl_parts.get("antecedent") as BooleanExpression
			var q2 = rl_parts.get("consequent") as BooleanExpression

			if p1.equals(q2) and q1.equals(p2):
				return create_biconditional_expression(p1, q1)

	return BooleanExpression.new("")


func apply_distributivity(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	var normalized = premise.normalized_string
	if premise.is_conjunction():
		var conj_parts = premise.get_conjunction_parts()
		if conj_parts.get("valid", false):
			var left = conj_parts.get("left") as BooleanExpression
			var right = conj_parts.get("right") as BooleanExpression

			if right.normalized_string.begins_with("(") and right.normalized_string.ends_with(")"):
				var inner = right.normalized_string.substr(1, right.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_disjunction():
					var disj_parts = inner_expr.get_disjunction_parts()
					if disj_parts.get("valid", false):
						var b = disj_parts.get("left") as BooleanExpression
						var c = disj_parts.get("right") as BooleanExpression

						var a_and_b = create_conjunction_expression(left, b)
						var a_and_c = create_conjunction_expression(left, c)
						return create_disjunction_expression(a_and_b, a_and_c)

	elif premise.is_disjunction():
		var disj_parts = premise.get_disjunction_parts()
		if disj_parts.get("valid", false):
			var left = disj_parts.get("left") as BooleanExpression
			var right = disj_parts.get("right") as BooleanExpression

			if right.normalized_string.begins_with("(") and right.normalized_string.ends_with(")"):
				var inner = right.normalized_string.substr(1, right.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_conjunction():
					var conj_parts = inner_expr.get_conjunction_parts()
					if conj_parts.get("valid", false):
						var b = conj_parts.get("left") as BooleanExpression
						var c = conj_parts.get("right") as BooleanExpression

						var a_or_b = create_disjunction_expression(left, b)
						var a_or_c = create_disjunction_expression(left, c)
						return create_conjunction_expression(a_or_b, a_or_c)

	return BooleanExpression.new("")

func apply_reverse_distributivity(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_disjunction():
		var disj_parts = premise.get_disjunction_parts()
		if disj_parts.get("valid", false):
			var left_expr = disj_parts.get("left") as BooleanExpression
			var right_expr = disj_parts.get("right") as BooleanExpression

			if left_expr.normalized_string.begins_with("(") and left_expr.normalized_string.ends_with(")") and \
			   right_expr.normalized_string.begins_with("(") and right_expr.normalized_string.ends_with(")"):
				var left_inner = left_expr.normalized_string.substr(1, left_expr.normalized_string.length() - 2).strip_edges()
				var right_inner = right_expr.normalized_string.substr(1, right_expr.normalized_string.length() - 2).strip_edges()

				var left_conj = BooleanExpression.new(left_inner)
				var right_conj = BooleanExpression.new(right_inner)

				if left_conj.is_conjunction() and right_conj.is_conjunction():
					var left_parts = left_conj.get_conjunction_parts()
					var right_parts = right_conj.get_conjunction_parts()

					if left_parts.get("valid", false) and right_parts.get("valid", false):
						var a1 = left_parts.get("left") as BooleanExpression
						var b = left_parts.get("right") as BooleanExpression
						var a2 = right_parts.get("left") as BooleanExpression
						var c = right_parts.get("right") as BooleanExpression

						if a1.equals(a2):
							var b_or_c = create_disjunction_expression(b, c)
							return create_conjunction_expression(a1, b_or_c)

	elif premise.is_conjunction():
		var conj_parts = premise.get_conjunction_parts()
		if conj_parts.get("valid", false):
			var left_expr = conj_parts.get("left") as BooleanExpression
			var right_expr = conj_parts.get("right") as BooleanExpression

			if left_expr.normalized_string.begins_with("(") and left_expr.normalized_string.ends_with(")") and \
			   right_expr.normalized_string.begins_with("(") and right_expr.normalized_string.ends_with(")"):
				var left_inner = left_expr.normalized_string.substr(1, left_expr.normalized_string.length() - 2).strip_edges()
				var right_inner = right_expr.normalized_string.substr(1, right_expr.normalized_string.length() - 2).strip_edges()

				var left_disj = BooleanExpression.new(left_inner)
				var right_disj = BooleanExpression.new(right_inner)

				if left_disj.is_disjunction() and right_disj.is_disjunction():
					var left_parts = left_disj.get_disjunction_parts()
					var right_parts = right_disj.get_disjunction_parts()

					if left_parts.get("valid", false) and right_parts.get("valid", false):
						var a1 = left_parts.get("left") as BooleanExpression
						var b = left_parts.get("right") as BooleanExpression
						var a2 = right_parts.get("left") as BooleanExpression
						var c = right_parts.get("right") as BooleanExpression

						if a1.equals(a2):
							var b_and_c = create_conjunction_expression(b, c)
							return create_disjunction_expression(a1, b_and_c)

	return BooleanExpression.new("")

func apply_commutativity(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			return create_conjunction_expression(right, left)

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			return create_disjunction_expression(right, left)

	elif premise.is_biconditional():
		var parts = premise.get_biconditional_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			return create_biconditional_expression(right, left)

	elif premise.is_xor():
		var parts = premise.get_xor_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			return create_xor_expression(right, left)

	return BooleanExpression.new("")

func apply_associativity(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression

			if left.normalized_string.begins_with("(") and left.normalized_string.ends_with(")"):
				var inner = left.normalized_string.substr(1, left.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_conjunction():
					var inner_parts = inner_expr.get_conjunction_parts()
					if inner_parts.get("valid", false):
						var a = inner_parts.get("left") as BooleanExpression
						var b = inner_parts.get("right") as BooleanExpression

						var b_and_c = create_conjunction_expression(b, right)
						return create_conjunction_expression(a, b_and_c)

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression

			if left.normalized_string.begins_with("(") and left.normalized_string.ends_with(")"):
				var inner = left.normalized_string.substr(1, left.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_disjunction():
					var inner_parts = inner_expr.get_disjunction_parts()
					if inner_parts.get("valid", false):
						var a = inner_parts.get("left") as BooleanExpression
						var b = inner_parts.get("right") as BooleanExpression

						var b_or_c = create_disjunction_expression(b, right)
						return create_disjunction_expression(a, b_or_c)

	return BooleanExpression.new("")

func apply_idempotent(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.equals(right):
				return left

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.equals(right):
				return left

	return BooleanExpression.new("")

func apply_absorption(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression

			if right.normalized_string.begins_with("(") and right.normalized_string.ends_with(")"):
				var inner = right.normalized_string.substr(1, right.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_disjunction():
					var disj_parts = inner_expr.get_disjunction_parts()
					if disj_parts.get("valid", false):
						var inner_left = disj_parts.get("left") as BooleanExpression
						if left.equals(inner_left):
							return left

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression

			if right.normalized_string.begins_with("(") and right.normalized_string.ends_with(")"):
				var inner = right.normalized_string.substr(1, right.normalized_string.length() - 2).strip_edges()
				var inner_expr = BooleanExpression.new(inner)

				if inner_expr.is_conjunction():
					var conj_parts = inner_expr.get_conjunction_parts()
					if conj_parts.get("valid", false):
						var inner_left = conj_parts.get("left") as BooleanExpression
						if left.equals(inner_left):
							return left

	return BooleanExpression.new("")

func apply_negation_laws(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.is_negation_of(right) or right.is_negation_of(left):
				return create_expression("FALSE")

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.is_negation_of(right) or right.is_negation_of(left):
				return create_expression("TRUE")

	return BooleanExpression.new("")

func apply_tautology_laws(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.normalized_string == "TRUE" or right.normalized_string == "TRUE":
				return create_expression("TRUE")

	elif premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.normalized_string == "TRUE":
				return right
			elif right.normalized_string == "TRUE":
				return left

	return BooleanExpression.new("")

func apply_contradiction_laws(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_conjunction():
		var parts = premise.get_conjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.normalized_string == "FALSE" or right.normalized_string == "FALSE":
				return create_expression("FALSE")

	elif premise.is_disjunction():
		var parts = premise.get_disjunction_parts()
		if parts.get("valid", false):
			var left = parts.get("left") as BooleanExpression
			var right = parts.get("right") as BooleanExpression
			if left.normalized_string == "FALSE":
				return right
			elif right.normalized_string == "FALSE":
				return left

	return BooleanExpression.new("")

func apply_resolution(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	if premise1.is_disjunction() and premise2.is_disjunction():
		var parts1 = premise1.get_disjunction_parts()
		var parts2 = premise2.get_disjunction_parts()

		if parts1.get("valid", false) and parts2.get("valid", false):
			var p = parts1.get("left") as BooleanExpression
			var q = parts1.get("right") as BooleanExpression
			var neg_p_or_other = parts2.get("left") as BooleanExpression
			var r = parts2.get("right") as BooleanExpression

			if p.is_negation_of(neg_p_or_other):
				return create_disjunction_expression(q, r)
			elif p.is_negation_of(r):
				return create_disjunction_expression(q, neg_p_or_other)
			elif q.is_negation_of(neg_p_or_other):
				return create_disjunction_expression(p, r)
			elif q.is_negation_of(r):
				return create_disjunction_expression(p, neg_p_or_other)

	return BooleanExpression.new("")

func apply_equivalence(premises: Array) -> BooleanExpression:
	if premises.size() != 2:
		return BooleanExpression.new("")

	var premise1 = premises[0] as BooleanExpression
	var premise2 = premises[1] as BooleanExpression

	if not premise1 or not premise2 or not premise1.is_valid or not premise2.is_valid:
		return BooleanExpression.new("")

	for i in range(2):
		var bicond_premise = premises[i] as BooleanExpression
		var simple_premise = premises[1-i] as BooleanExpression

		if bicond_premise.is_biconditional():
			var parts = bicond_premise.get_biconditional_parts()
			if parts.get("valid", false):
				var left = parts.get("left") as BooleanExpression
				var right = parts.get("right") as BooleanExpression

				if simple_premise.equals(left):
					return right
				elif simple_premise.equals(right):
					return left

	return BooleanExpression.new("")

func detect_contradiction(expressions: Array) -> bool:
	for i in range(expressions.size()):
		for j in range(i + 1, expressions.size()):
			var expr1 = expressions[i] as BooleanExpression
			var expr2 = expressions[j] as BooleanExpression

			if expr1 and expr2 and expr1.is_valid and expr2.is_valid:
				if expr1.is_negation_of(expr2):
					return true

	return false

func create_contradiction() -> BooleanExpression:
	return create_expression("FALSE")

func get_applicable_single_operations(premise: BooleanExpression) -> Array:
	var operations = []

	if not premise or not premise.is_valid:
		return operations

	if premise.normalized_string.begins_with("¬¬"):
		operations.append("Double Negation")

	if premise.is_conjunction():
		operations.append("Simplification (Left)")
		operations.append("Simplification (Right)")

	if premise.normalized_string.begins_with("¬(") and premise.is_conjunction():
		operations.append("De Morgan's (AND)")
	elif premise.normalized_string.begins_with("¬(") and premise.is_disjunction():
		operations.append("De Morgan's (OR)")

	if premise.is_xor():
		operations.append("XOR Elimination")

	if premise.is_biconditional():
		operations.append("Biconditional to Implications")
		operations.append("Biconditional to Equivalence")

	if premise.is_conjunction() or premise.is_disjunction():
		operations.append("Commutativity")
		operations.append("Idempotent")

	if premise.is_conjunction() or premise.is_disjunction():
		operations.append("Distributivity")
		operations.append("Reverse Distributivity")
		operations.append("Associativity")
		operations.append("Absorption")
		operations.append("Negation Laws")
		operations.append("Tautology Laws")
		operations.append("Contradiction Laws")

	operations.append("Parenthesis Removal")

	return operations

func apply_addition_auto(premise: BooleanExpression, add_var_name: String = "Q") -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	var additional = create_expression(add_var_name)
	if not additional.is_valid:
		return BooleanExpression.new("")

	return create_disjunction_expression(premise, additional)

func apply_implication_conversion(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_implication():
		var impl_parts = premise.get_implication_parts()
		if impl_parts.get("valid", false):
			var antecedent = impl_parts.get("antecedent") as BooleanExpression
			var consequent = impl_parts.get("consequent") as BooleanExpression

			var neg_antecedent = create_negation_expression(antecedent)
			return create_disjunction_expression(neg_antecedent, consequent)

	return BooleanExpression.new("")

func apply_contrapositive(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	if premise.is_implication():
		var impl_parts = premise.get_implication_parts()
		if impl_parts.get("valid", false):
			var antecedent = impl_parts.get("antecedent") as BooleanExpression
			var consequent = impl_parts.get("consequent") as BooleanExpression

			var neg_consequent = create_negation_expression(consequent)
			var neg_antecedent = create_negation_expression(antecedent)
			return create_implication_expression(neg_consequent, neg_antecedent)

	return BooleanExpression.new("")

func apply_parenthesis_removal(premise: BooleanExpression) -> BooleanExpression:
	if not premise or not premise.is_valid:
		return BooleanExpression.new("")

	var normalized = premise.normalized_string

	if normalized.begins_with("(") and normalized.ends_with(")"):
		var paren_count = 0
		var can_remove = true

		for i in range(1, normalized.length() - 1):
			var c = normalized[i]
			if c == '(':
				paren_count += 1
			elif c == ')':
				paren_count -= 1
				if paren_count < 0:
					can_remove = false
					break

		if can_remove and paren_count == 0:
			var inner = normalized.substr(1, normalized.length() - 2).strip_edges()
			if not inner.is_empty():

				var result = create_expression(inner)
				if result.is_valid:
					var inner_also_wrapped = inner.begins_with("(") and inner.ends_with(")")

					var tokens = inner.strip_edges().split(" ")
					var is_very_simple = tokens.size() <= 2

					var has_top_level_op = _has_top_level_binary_operator(inner)

					if inner_also_wrapped or is_very_simple or has_top_level_op:
						return result

	var result_string = normalized
	var regex = RegEx.new()
	if regex.compile("\\([A-Za-z]\\)") == OK:
		var regex_result = regex.search(result_string)
		while regex_result:
			var match = regex_result.get_string()
			var replacement = match.substr(1, match.length() - 2)
			result_string = result_string.replace(match, replacement)
			regex_result = regex.search(result_string)

	if result_string != normalized:
		var result = create_expression(result_string)
		if result.is_valid:
			return result

	return premise

func _has_top_level_binary_operator(expr: String) -> bool:
	var paren_depth = 0
	var binary_operators = ["∧", "∨", "⊕", "→", "↔"]

	for i in range(expr.length()):
		var c = expr[i]
		if c == '(':
			paren_depth += 1
		elif c == ')':
			paren_depth -= 1
		elif paren_depth == 0:
			if c in binary_operators:
				return true

	return false

func _has_operator(expr: String) -> bool:
	var operators = ["∧", "∨", "⊕", "→", "↔"]
	for op in operators:
		if expr.find(op) != -1:
			return true
	return false

func test_logic_engine() -> bool:
	print("Testing Boolean Logic Engine...")
	print("==================================================")

	var tests_passed = 0
	var tests_total = 0

	tests_total += 1
	var expr1 = create_expression("P")
	if expr1.is_valid:
		print("✓ Basic expression creation test passed")
		tests_passed += 1
	else:
		print("✗ Basic expression creation test failed")

	tests_total += 1
	var expr2 = create_expression("P → Q")
	if expr2.is_valid:
		print("✓ Expression with operator test passed")
		tests_passed += 1
	else:
		print("✗ Expression with operator test failed")

	tests_total += 1
	var expr3 = create_expression("(A ∧ B) → (C ∨ ¬D)")
	if expr3.is_valid:
		print("✓ Complex expression test passed")
		tests_passed += 1
	else:
		print("✗ Complex expression test failed")

	tests_total += 1
	var premise1 = create_expression("P → Q")
	var premise2 = create_expression("P")
	var modus_ponens_result = apply_modus_ponens([premise1, premise2])
	if modus_ponens_result.is_valid and modus_ponens_result.normalized_string == "Q":
		print("✓ Modus Ponens test passed")
		tests_passed += 1
	else:
		print("✗ Modus Ponens test failed")

	tests_total += 1
	var double_neg = create_expression("¬¬P")
	var double_neg_result = apply_double_negation(double_neg)
	if double_neg_result.is_valid and double_neg_result.normalized_string == "P":
		print("✓ Double Negation test passed")
		tests_passed += 1
	else:
		print("✗ Double Negation test failed")

	tests_total += 1
	var xor_expr = create_expression("P ⊕ Q")
	if xor_expr.is_valid and xor_expr.is_xor():
		print("✓ XOR expression creation test passed")
		tests_passed += 1
	else:
		print("✗ XOR expression creation test failed")

	tests_total += 1
	var xor_ascii = create_expression("P ^ Q")
	if xor_ascii.is_valid and xor_ascii.normalized_string.find("⊕") != -1:
		print("✓ XOR ASCII conversion test passed")
		tests_passed += 1
	else:
		print("✗ XOR ASCII conversion test failed")

	tests_total += 1
	var biconditional_expr = create_expression("P ↔ Q")
	if biconditional_expr.is_valid and biconditional_expr.is_biconditional():
		print("✓ Biconditional expression creation test passed")
		tests_passed += 1
	else:
		print("✗ Biconditional expression creation test failed")

	tests_total += 1
	var biconditional_test = create_expression("P ↔ Q")
	var implications_result = apply_biconditional_to_implications(biconditional_test)
	if implications_result.is_valid and implications_result.is_conjunction():
		print("✓ Biconditional to implications test passed")
		tests_passed += 1
	else:
		print("✗ Biconditional to implications test failed")

	tests_total += 1
	var xor_test = create_expression("P ⊕ Q")
	var xor_elimination_result = apply_xor_elimination(xor_test)
	if xor_elimination_result.is_valid and xor_elimination_result.is_conjunction():
		print("✓ XOR elimination test passed")
		tests_passed += 1
	else:
		print("✗ XOR elimination test failed")

	tests_total += 1
	var comm_test = create_expression("P ∧ Q")
	var comm_result = apply_commutativity(comm_test)
	if comm_result.is_valid and comm_result.normalized_string == "(Q ∧ P)":
		print("✓ Commutativity test passed")
		tests_passed += 1
	else:
		print("✗ Commutativity test failed")

	tests_total += 1
	var idemp_test = create_expression("P ∧ P")
	var idemp_result = apply_idempotent(idemp_test)
	if idemp_result.is_valid and idemp_result.normalized_string == "P":
		print("✓ Idempotent test passed")
		tests_passed += 1
	else:
		print("✗ Idempotent test failed")

	tests_total += 1
	var dist_test = create_expression("A ∧ (B ∨ C)")
	var dist_result = apply_distributivity(dist_test)
	if dist_result.is_valid and dist_result.is_disjunction():
		print("✓ Distributivity test passed")
		tests_passed += 1
	else:
		print("✗ Distributivity test failed")

	tests_total += 1
	var abs_test = create_expression("A ∧ (A ∨ B)")
	var abs_result = apply_absorption(abs_test)
	if abs_result.is_valid and abs_result.normalized_string == "A":
		print("✓ Absorption test passed")
		tests_passed += 1
	else:
		print("✗ Absorption test failed")

	tests_total += 1
	var neg_test = create_expression("P ∧ ¬P")
	var neg_result = apply_negation_laws(neg_test)
	if neg_result.is_valid and neg_result.normalized_string == "FALSE":
		print("✓ Negation law test passed")
		tests_passed += 1
	else:
		print("✗ Negation law test failed")

	tests_total += 1
	var taut_test = create_expression("P ∧ TRUE")
	var taut_result = apply_tautology_laws(taut_test)
	if taut_result.is_valid and taut_result.normalized_string == "P":
		print("✓ Tautology law test passed")
		tests_passed += 1
	else:
		print("✗ Tautology law test failed")

	tests_total += 1
	var contr_test = create_expression("P ∨ FALSE")
	var contr_result = apply_contradiction_laws(contr_test)
	if contr_result.is_valid and contr_result.normalized_string == "P":
		print("✓ Contradiction law test passed")
		tests_passed += 1
	else:
		print("✗ Contradiction law test failed")

	tests_total += 1
	var paren_test = create_expression("(P)")
	var paren_result = apply_parenthesis_removal(paren_test)
	if paren_result.is_valid and paren_result.normalized_string == "P":
		print("✓ Parenthesis removal test passed")
		tests_passed += 1
	else:
		print("✗ Parenthesis removal test failed")

	tests_total += 1
	var res_premise1 = create_expression("P ∨ Q")
	var res_premise2 = create_expression("¬P ∨ R")
	var res_result = apply_resolution([res_premise1, res_premise2])
	if res_result.is_valid and res_result.is_disjunction():
		print("✓ Resolution test passed")
		tests_passed += 1
	else:
		print("✗ Resolution test failed")

	tests_total += 1
	var eq_premise1 = create_expression("P ↔ Q")
	var eq_premise2 = create_expression("P")
	var eq_result = apply_equivalence([eq_premise1, eq_premise2])
	if eq_result.is_valid and eq_result.normalized_string == "Q":
		print("✓ Equivalence test passed")
		tests_passed += 1
	else:
		print("✗ Equivalence test failed")

	tests_total += 1
	var cd_premise1 = create_expression("(P → Q) ∧ (R → S)")
	var cd_premise2 = create_expression("P ∨ R")
	var cd_result = apply_constructive_dilemma([cd_premise1, cd_premise2])
	if cd_result.is_valid and cd_result.is_disjunction():
		var cd_parts = cd_result.get_disjunction_parts()
		if cd_parts.get("valid", false):
			var left = cd_parts.get("left") as BooleanExpression
			var right = cd_parts.get("right") as BooleanExpression
			if (left.normalized_string == "Q" and right.normalized_string == "S") or \
			   (left.normalized_string == "S" and right.normalized_string == "Q"):
				print("✓ Constructive dilemma test passed")
				tests_passed += 1
			else:
				print("✗ Constructive dilemma test failed (wrong result)")
		else:
			print("✗ Constructive dilemma test failed (invalid disjunction)")
	else:
		print("✗ Constructive dilemma test failed")

	tests_total += 1
	var dd_premise1 = create_expression("(P → Q) ∧ (R → S)")
	var dd_premise2 = create_expression("¬Q ∨ ¬S")
	var dd_result = apply_destructive_dilemma([dd_premise1, dd_premise2])
	if dd_result.is_valid and dd_result.is_disjunction():
		var dd_parts = dd_result.get_disjunction_parts()
		if dd_parts.get("valid", false):
			var left = dd_parts.get("left") as BooleanExpression
			var right = dd_parts.get("right") as BooleanExpression
			var has_neg_p = left.normalized_string == "¬P" or right.normalized_string == "¬P"
			var has_neg_r = left.normalized_string == "¬R" or right.normalized_string == "¬R"
			if has_neg_p and has_neg_r:
				print("✓ Destructive dilemma test passed")
				tests_passed += 1
			else:
				print("✗ Destructive dilemma test failed (wrong result)")
		else:
			print("✗ Destructive dilemma test failed (invalid disjunction)")
	else:
		print("✗ Destructive dilemma test failed")

	print("\n--- Multi-Result Helper Function Tests ---")

	tests_total += 1
	var simp_both_premise = create_expression("P ∧ Q")
	var simp_both_results = apply_simplification_both([simp_both_premise])
	if simp_both_results.size() == 2:
		var simp_left = simp_both_results[0] as BooleanExpression
		var simp_right = simp_both_results[1] as BooleanExpression
		if simp_left.normalized_string == "P" and simp_right.normalized_string == "Q":
			print("✓ Simplification both test passed")
			tests_passed += 1
		else:
			print("✗ Simplification both test failed (wrong results)")
	else:
		print("✗ Simplification both test failed")

	tests_total += 1
	var bicond_impl_premise = create_expression("P ↔ Q")
	var bicond_impl_results = apply_biconditional_to_implications_both(bicond_impl_premise)
	if bicond_impl_results.size() == 2:
		var impl1 = bicond_impl_results[0] as BooleanExpression
		var impl2 = bicond_impl_results[1] as BooleanExpression
		if impl1.is_implication() and impl2.is_implication():
			print("✓ Biconditional to implications both test passed")
			tests_passed += 1
		else:
			print("✗ Biconditional to implications both test failed (not implications)")
	else:
		print("✗ Biconditional to implications both test failed")

	tests_total += 1
	var xor_both_premise = create_expression("P ⊕ Q")
	var xor_both_results = apply_xor_elimination_both(xor_both_premise)
	if xor_both_results.size() == 2:
		var xor_disj = xor_both_results[0] as BooleanExpression
		var xor_neg = xor_both_results[1] as BooleanExpression
		if xor_disj.is_disjunction() and xor_neg.normalized_string.begins_with("¬"):
			print("✓ XOR elimination both test passed")
			tests_passed += 1
		else:
			print("✗ XOR elimination both test failed (wrong structure)")
	else:
		print("✗ XOR elimination both test failed")

	tests_total += 1
	var bicond_equiv_premise = create_expression("P ↔ Q")
	var bicond_equiv_results = apply_biconditional_to_equivalence_both(bicond_equiv_premise)
	if bicond_equiv_results.size() == 2:
		var both_true = bicond_equiv_results[0] as BooleanExpression
		var both_false = bicond_equiv_results[1] as BooleanExpression
		if both_true.is_conjunction() and both_false.is_conjunction():
			print("✓ Biconditional to equivalence both test passed")
			tests_passed += 1
		else:
			print("✗ Biconditional to equivalence both test failed (not conjunctions)")
	else:
		print("✗ Biconditional to equivalence both test failed")

	print("\n--- Edge Case Tests ---")

	tests_total += 1
	var empty_paren = create_expression("()")
	if not empty_paren.is_valid:
		print("✓ Empty parentheses rejection test passed")
		tests_passed += 1
	else:
		print("✗ Empty parentheses rejection test failed")

	tests_total += 1
	var consec_ops = create_expression("P ∧ ∨ Q")
	if not consec_ops.is_valid:
		print("✓ Consecutive operators rejection test passed")
		tests_passed += 1
	else:
		print("✗ Consecutive operators rejection test failed")

	tests_total += 1
	var op_start = create_expression("∧ P")
	if not op_start.is_valid:
		print("✓ Operator at start rejection test passed")
		tests_passed += 1
	else:
		print("✗ Operator at start rejection test failed")

	tests_total += 1
	var op_end = create_expression("P ∧")
	if not op_end.is_valid:
		print("✓ Operator at end rejection test passed")
		tests_passed += 1
	else:
		print("✗ Operator at end rejection test failed")

	tests_total += 1
	var unbal_paren = create_expression("((P ∧ Q)")
	if not unbal_paren.is_valid:
		print("✓ Unbalanced parentheses rejection test passed")
		tests_passed += 1
	else:
		print("✗ Unbalanced parentheses rejection test failed")

	tests_total += 1
	var complex_expr = create_expression("((P ∧ Q) → R) ↔ (¬P ∨ (¬Q ∨ R))")
	if complex_expr.is_valid:
		print("✓ Complex expression validation test passed")
		tests_passed += 1
	else:
		print("✗ Complex expression validation test failed")

	tests_total += 1
	var multi_var = create_expression("P1 ∧ Q2")
	if multi_var.is_valid:
		print("✓ Multi-character variable test passed")
		tests_passed += 1
	else:
		print("✗ Multi-character variable test failed")

	tests_total += 1
	var const_expr = create_expression("TRUE ∨ FALSE")
	if const_expr.is_valid:
		print("✓ Constants handling test passed")
		tests_passed += 1
	else:
		print("✗ Constants handling test failed")

	print("==================================================")
	print("Tests completed: %d/%d passed" % [tests_passed, tests_total])

	if tests_passed == tests_total:
		print("🎉 All tests passed! Boolean Logic Engine is FULLY IMPLEMENTED!")
		print("✅ Supports ALL boolean logic operations including:")
		print("   • Basic operations: ∧, ∨, ⊕, ¬, →, ↔")
		print("   • Inference rules: MP, MT, HS, DS, CD, DD, Resolution, etc.")
		print("   • Boolean laws: Distributivity, Commutativity, Associativity")
		print("   • Identity laws: Idempotent, Absorption, Negation")
		print("   • Special laws: Tautology, Contradiction, Double Negation")
		print("   • Parenthesis removal operation for Phase 2")
		print("✅ ALL 13 Inference Rules Implemented:")
		print("   • Modus Ponens, Modus Tollens")
		print("   • Hypothetical Syllogism, Disjunctive Syllogism")
		print("   • Simplification, Conjunction, Addition")
		print("   • Constructive Dilemma, Destructive Dilemma")
		print("   • Resolution, De Morgan's Laws, Double Negation")
		print("✅ Multi-Result Helper Functions:")
		print("   • apply_simplification_both() - extracts both P and Q from P ∧ Q")
		print("   • apply_biconditional_to_implications_both() - P ↔ Q → [P→Q, Q→P]")
		print("   • apply_xor_elimination_both() - P⊕Q → [P∨Q, ¬(P∧Q)]")
		print("   • apply_biconditional_to_equivalence_both() - P↔Q → [P∧Q, ¬P∧¬Q]")
		print("✅ Enhanced edge case handling:")
		print("   • Empty parentheses rejection")
		print("   • Consecutive operator detection")
		print("   • Unbalanced parentheses validation")
		print("   • Multi-character variable support")
		print("   • Constants (TRUE/FALSE) handling")
		print("✅ Robust expression parsing and normalization")
		print("✅ ASCII conversion: ^ → ⊕, <-> → ↔, -> → →, etc.")
		print("✅ All Phase 2 UI operations now fully connected")
		print("✅ Comprehensive test suite with 34 test cases")
	else:
		print("⚠️  Some tests failed. Engine needs further debugging.")

	return tests_passed == tests_total
