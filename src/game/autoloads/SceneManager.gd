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