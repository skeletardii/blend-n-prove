extends Node

signal tutorial_step_completed(step_index: int)

var is_tutorial_mode: bool = false
var current_step: int = 0
var tutorial_steps: Array[String] = [
	"Welcome! You'll learn formal logic through puzzles.",
	"There are two types of problems:\n• Word Problems: Translate natural language to logic symbols (has Phase 1)\n• Direct Symbol Problems: Symbols already given, skip to Phase 2\n\nThis tutorial uses a Word Problem.",
	"Phase 1 (Word Problems Only): Translate the natural language statements into logical notation.",
	"Click the buttons (P, Q, operators) to build logical expressions that match the meaning of each sentence.",
	"Press 'Validate' when you've built a premise. It will be added to your premises list.",
	"Phase 2: Use inference rules to transform premises and reach the conclusion.",
	"Select premises with checkboxes, then click an inference rule to apply it.",
	"Complete the tutorial to finish your first puzzle!"
]

var tutorial_overlay: Control = null
var tutorial_label: Label = null
var next_button: Button = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_tutorial() -> void:
	is_tutorial_mode = true
	current_step = 0
	create_tutorial_overlay()
	show_tutorial_step(current_step)

func create_tutorial_overlay() -> void:
	if tutorial_overlay:
		return

	# Create overlay
	tutorial_overlay = Control.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background panel
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(600, 200)
	panel.position = Vector2(-300, -100)
	tutorial_overlay.add_child(panel)

	# Tutorial text
	tutorial_label = Label.new()
	tutorial_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_label.text = "Tutorial text here"
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(tutorial_label)

	# Next button
	next_button = Button.new()
	next_button.text = "Next"
	next_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	next_button.position = Vector2(-100, -50)
	next_button.size = Vector2(80, 40)
	next_button.pressed.connect(_on_next_tutorial_step)
	panel.add_child(next_button)

	# Add to scene tree
	get_tree().current_scene.add_child(tutorial_overlay)

func show_tutorial_step(step: int) -> void:
	if step >= tutorial_steps.size():
		end_tutorial()
		return

	if tutorial_label:
		tutorial_label.text = tutorial_steps[step]

	if next_button:
		if step == tutorial_steps.size() - 1:
			next_button.text = "Finish"
		else:
			next_button.text = "Next"

func _on_next_tutorial_step() -> void:
	current_step += 1
	tutorial_step_completed.emit(current_step - 1)

	if current_step >= tutorial_steps.size():
		end_tutorial()
	else:
		show_tutorial_step(current_step)

func end_tutorial() -> void:
	is_tutorial_mode = false
	if tutorial_overlay:
		tutorial_overlay.queue_free()
		tutorial_overlay = null
		tutorial_label = null
		next_button = null

func skip_tutorial() -> void:
	end_tutorial()