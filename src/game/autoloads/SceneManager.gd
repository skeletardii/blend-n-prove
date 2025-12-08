extends Node

signal scene_changing(from_scene: String, to_scene: String)
signal scene_changed(scene_path: String)

var current_scene_path: String = ""
var is_changing_scene: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tree := get_tree()
	if tree.current_scene:
		current_scene_path = tree.current_scene.scene_file_path

func change_scene(scene_path: String) -> void:
	print("SceneManager.change_scene called with: ", scene_path)

	if is_changing_scene:
		print("Scene change already in progress")
		return

	is_changing_scene = true
	var old_scene_path := current_scene_path
	current_scene_path = scene_path

	print("Emitting scene_changing signal from ", old_scene_path, " to ", scene_path)
	scene_changing.emit(old_scene_path, scene_path)

	# Use call_deferred to ensure the change happens at a safe time
	print("Calling _change_scene_deferred...")
	call_deferred("_change_scene_deferred", scene_path)

func _change_scene_deferred(scene_path: String) -> void:
	print("_change_scene_deferred called with: ", scene_path)
	var result := get_tree().change_scene_to_file(scene_path)
	print("Scene change result: ", result)
	if result == OK:
		print("✅ Scene change successful!")
		scene_changed.emit(scene_path)
	else:
		print("❌ Failed to change scene to: ", scene_path, " Error code: ", result)

	is_changing_scene = false

func reload_current_scene() -> void:
	if current_scene_path.is_empty():
		print("No current scene to reload")
		return

	change_scene(current_scene_path)

func get_current_scene_name() -> String:
	if current_scene_path.is_empty():
		return ""

	return current_scene_path.get_file().get_basename()

func change_scene_with_loading(target_scene_path: String) -> void:
	"""Change scene with a loading screen in between"""
	print("SceneManager.change_scene_with_loading called with: ", target_scene_path)

	if is_changing_scene:
		print("Scene change already in progress")
		return

	is_changing_scene = true
	var old_scene_path := current_scene_path

	# First, change to loading screen
	print("Loading screen first, then will load: ", target_scene_path)
	scene_changing.emit(old_scene_path, "res://src/ui/LoadingScreen.tscn")

	# Store target scene for loading screen to use
	var loading_scene = load("res://src/ui/LoadingScreen.tscn")
	if loading_scene:
		var result := get_tree().change_scene_to_packed(loading_scene)
		if result == OK:
			# Wait for loading screen to be ready
			await get_tree().process_frame
			await get_tree().process_frame

			# Get the loading screen instance and set target
			var loading_screen = get_tree().current_scene
			if loading_screen and loading_screen.has_method("set_target_scene"):
				loading_screen.set_target_scene(target_scene_path)
				current_scene_path = "res://src/ui/LoadingScreen.tscn"
			else:
				print("❌ Failed to get loading screen instance")
				is_changing_scene = false
		else:
			print("❌ Failed to load loading screen, error: ", result)
			is_changing_scene = false
	else:
		print("❌ Failed to load LoadingScreen.tscn")
		is_changing_scene = false

	is_changing_scene = false
