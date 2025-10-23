extends SceneTree

func _init() -> void:
	print("=== Testing Pause Feature ===")

	# Test 1: Load GameplayScene
	print("Test 1: Loading GameplayScene...")
	var scene_path: String = "res://src/scenes/GameplayScene.tscn"
	var packed_scene = load(scene_path) as PackedScene

	if packed_scene == null:
		print("❌ FAILED: Could not load GameplayScene")
		quit(1)
		return

	print("✓ GameplayScene loaded successfully")

	# Test 2: Instantiate the scene
	print("\nTest 2: Instantiating GameplayScene...")
	var scene_instance = packed_scene.instantiate()

	if scene_instance == null:
		print("❌ FAILED: Could not instantiate GameplayScene")
		quit(1)
		return

	print("✓ GameplayScene instantiated successfully")

	# Test 3: Check for pause button node
	print("\nTest 3: Checking for pause button...")
	var pause_button = scene_instance.get_node_or_null("UI/MainContainer/TopBar/TopBarContainer/PauseButton")

	if pause_button == null:
		print("❌ FAILED: Pause button not found")
		scene_instance.free()
		quit(1)
		return

	print("✓ Pause button found: " + str(pause_button))

	# Test 4: Check for pause overlay
	print("\nTest 4: Checking for pause overlay...")
	var pause_overlay = scene_instance.get_node_or_null("PauseOverlay")

	if pause_overlay == null:
		print("❌ FAILED: Pause overlay not found")
		scene_instance.free()
		quit(1)
		return

	print("✓ Pause overlay found: " + str(pause_overlay))

	# Test 5: Check for resume button
	print("\nTest 5: Checking for resume button...")
	var resume_button = scene_instance.get_node_or_null("PauseOverlay/PauseMenu/MenuContainer/ResumeButton")

	if resume_button == null:
		print("❌ FAILED: Resume button not found")
		scene_instance.free()
		quit(1)
		return

	print("✓ Resume button found: " + str(resume_button))

	# Test 6: Check for quit button
	print("\nTest 6: Checking for quit button...")
	var quit_button = scene_instance.get_node_or_null("PauseOverlay/PauseMenu/MenuContainer/QuitButton")

	if quit_button == null:
		print("❌ FAILED: Quit button not found")
		scene_instance.free()
		quit(1)
		return

	print("✓ Quit button found: " + str(quit_button))

	# Test 7: Verify pause overlay is initially hidden
	print("\nTest 7: Checking pause overlay initial visibility...")
	if pause_overlay.visible == true:
		print("❌ FAILED: Pause overlay should be hidden initially")
		scene_instance.free()
		quit(1)
		return

	print("✓ Pause overlay is initially hidden")

	# Cleanup
	scene_instance.free()

	print("\n=== All Tests Passed! ===")
	print("Pause feature implementation verified successfully!")
	quit(0)
