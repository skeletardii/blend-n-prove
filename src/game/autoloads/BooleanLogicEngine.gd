extends Node

## BooleanLogicEngine Proxy - Delegates to implementation loaded from PCK
## The implementation contains all boolean logic operations and expression handling

# Implementation reference
var _impl: Node = null

func _set_impl(impl: Node) -> void:
	_impl = impl

func _ready() -> void:
	pass  # Wait for impl injection

# Property forwarding - allows direct access to impl properties/classes
func _get(property: StringName) -> Variant:
	if _impl:
		return _impl.get(property)
	return null

func _set(property: StringName, value: Variant) -> bool:
	if _impl:
		_impl.set(property, value)
		return true
	return false

# Method forwarding - all methods delegate to implementation
func create_expression(expr_string: String) -> BooleanExpression:
	if _impl: return _impl.create_expression(expr_string)
	return null

func create_negation_expression(expr: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_negation_expression(expr)
	return null

func create_conjunction_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_conjunction_expression(left, right)
	return null

func create_disjunction_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_disjunction_expression(left, right)
	return null

func create_implication_expression(antecedent: BooleanExpression, consequent: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_implication_expression(antecedent, consequent)
	return null

func create_biconditional_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_biconditional_expression(left, right)
	return null

func create_xor_expression(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.create_xor_expression(left, right)
	return null

func apply_modus_ponens(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_modus_ponens(premises)
	return null

func apply_modus_tollens(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_modus_tollens(premises)
	return null

func apply_hypothetical_syllogism(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_hypothetical_syllogism(premises)
	return null

func apply_disjunctive_syllogism(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_disjunctive_syllogism(premises)
	return null

func apply_simplification(premises: Array, extract_right: bool = false) -> BooleanExpression:
	if _impl: return _impl.apply_simplification(premises, extract_right)
	return null

func apply_simplification_both(premises: Array) -> Array:
	if _impl: return _impl.apply_simplification_both(premises)
	return []

func apply_conjunction(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_conjunction(premises)
	return null

func apply_addition(premises: Array, additional_expr: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_addition(premises, additional_expr)
	return null

func apply_constructive_dilemma(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_constructive_dilemma(premises)
	return null

func apply_destructive_dilemma(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_destructive_dilemma(premises)
	return null

func apply_de_morgan_and(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_de_morgan_and(premise)
	return null

func apply_de_morgan_or(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_de_morgan_or(premise)
	return null

func apply_double_negation(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_double_negation(premise)
	return null

func apply_xor_elimination(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_xor_elimination(premise)
	return null

func apply_xor_introduction(left: BooleanExpression, right: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_xor_introduction(left, right)
	return null

func apply_xor_elimination_both(premise: BooleanExpression) -> Array:
	if _impl: return _impl.apply_xor_elimination_both(premise)
	return []

func apply_biconditional_to_implications(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_biconditional_to_implications(premise)
	return null

func apply_biconditional_to_equivalence(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_biconditional_to_equivalence(premise)
	return null

func apply_biconditional_to_equivalence_both(premise: BooleanExpression) -> Array:
	if _impl: return _impl.apply_biconditional_to_equivalence_both(premise)
	return []

func apply_biconditional_to_implications_both(premise: BooleanExpression) -> Array:
	if _impl: return _impl.apply_biconditional_to_implications_both(premise)
	return []

func apply_biconditional_introduction(left_to_right: BooleanExpression, right_to_left: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_biconditional_introduction(left_to_right, right_to_left)
	return null

func apply_distributivity(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_distributivity(premise)
	return null

func apply_reverse_distributivity(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_reverse_distributivity(premise)
	return null

func apply_commutativity(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_commutativity(premise)
	return null

func apply_associativity(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_associativity(premise)
	return null

func apply_idempotent(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_idempotent(premise)
	return null

func apply_absorption(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_absorption(premise)
	return null

func apply_negation_laws(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_negation_laws(premise)
	return null

func apply_tautology_laws(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_tautology_laws(premise)
	return null

func apply_contradiction_laws(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_contradiction_laws(premise)
	return null

func apply_resolution(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_resolution(premises)
	return null

func apply_equivalence(premises: Array) -> BooleanExpression:
	if _impl: return _impl.apply_equivalence(premises)
	return null

func detect_contradiction(expressions: Array) -> bool:
	if _impl: return _impl.detect_contradiction(expressions)
	return false

func create_contradiction() -> BooleanExpression:
	if _impl: return _impl.create_contradiction()
	return null

func get_applicable_single_operations(premise: BooleanExpression) -> Array:
	if _impl: return _impl.get_applicable_single_operations(premise)
	return []

func apply_addition_auto(premise: BooleanExpression, add_var_name: String = "Q") -> BooleanExpression:
	if _impl: return _impl.apply_addition_auto(premise, add_var_name)
	return null

func apply_implication_conversion(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_implication_conversion(premise)
	return null

func apply_contrapositive(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_contrapositive(premise)
	return null

func apply_parenthesis_removal(premise: BooleanExpression) -> BooleanExpression:
	if _impl: return _impl.apply_parenthesis_removal(premise)
	return null

func test_logic_engine() -> bool:
	if _impl: return _impl.test_logic_engine()
	return false
