extends Node

## ManagerBootstrap
##
## Core bootstrap system that loads manager implementations from PCK
## and injects them into proxy autoloads.
##
## This stays in the base APK and initializes the manager system after
## the content PCK is loaded.

signal managers_ready()
signal manager_load_failed(manager_name: String, error: String)

## Mapping of manager names to their implementation script paths in the PCK
## Note: SceneManager, AudioManager, and AppConstants are full autoloads (not proxied)
const MANAGER_PATHS = {
	"GameManager": "res://src/managers/GameManagerImpl.gd",
	"BooleanLogicEngine": "res://src/managers/BooleanLogicEngineImpl.gd",
	"TutorialManager": "res://src/managers/TutorialManagerImpl.gd",
	"ProgressTracker": "res://src/managers/ProgressTrackerImpl.gd",
	"TutorialDataManager": "res://src/managers/TutorialDataManagerImpl.gd",
	"UpdateCheckerService": "res://src/managers/UpdateCheckerServiceImpl.gd",
}

## Order in which managers are loaded (respects dependencies)
## Note: SceneManager, AudioManager, and AppConstants remain full autoloads
const MANAGER_LOAD_ORDER = [
	"ProgressTracker",        # No dependencies
	"BooleanLogicEngine",     # No dependencies
	"TutorialDataManager",    # Depends on ProgressTracker
	"UpdateCheckerService",   # Depends on AppConstants (full autoload)
	"TutorialManager",        # No hard dependencies
	"GameManager",            # Depends on AudioManager (full autoload), ProgressTracker, BooleanLogicEngine, TutorialDataManager
]

## Loaded manager instances (keyed by manager name)
var _managers: Dictionary = {}

## Whether managers have been fully loaded and initialized
var _managers_ready: bool = false

## Whether we're currently loading managers
var _loading: bool = false


## Check if all managers are loaded and ready
func is_ready() -> bool:
	return _managers_ready


## Get a manager implementation by name
##
## @param name: Manager name (e.g., "GameManager")
## @return: Manager instance or null if not loaded
func get_service(name: String) -> Node:
	return _managers.get(name)


## Load all manager implementations from the PCK
##
## This function:
## 1. Loads each manager implementation script from the PCK
## 2. Instantiates the implementation
## 3. Injects it into the corresponding proxy autoload
## 4. Calls _ready() manually if needed
## 5. Emits managers_ready() signal when complete
func load_managers() -> void:
	if _managers_ready:
		print("ManagerBootstrap: Managers already loaded")
		return

	if _loading:
		print("ManagerBootstrap: Already loading managers")
		return

	_loading = true
	print("ManagerBootstrap: Starting manager load sequence...")

	# Verify PCK is loaded by checking if a manager implementation exists
	if not ResourceLoader.exists(MANAGER_PATHS["GameManager"]):
		push_error("ManagerBootstrap: PCK not loaded! Cannot find manager implementations.")
		manager_load_failed.emit("ALL", "PCK not loaded")
		_loading = false
		return

	var load_errors: Array[String] = []

	# Load each manager in dependency order
	for manager_name in MANAGER_LOAD_ORDER:
		var success = _load_manager(manager_name)
		if not success:
			load_errors.append(manager_name)

	_loading = false

	if load_errors.is_empty():
		_managers_ready = true
		print("ManagerBootstrap: All managers loaded successfully!")
		managers_ready.emit()
	else:
		push_error("ManagerBootstrap: Failed to load managers: " + str(load_errors))
		manager_load_failed.emit("MULTIPLE", "Failed: " + str(load_errors))



## Load a single manager implementation
##
## @param manager_name: Name of the manager to load
## @return: true if loaded successfully, false otherwise
func _load_manager(manager_name: String) -> bool:
	print("ManagerBootstrap: Loading ", manager_name, "...")

	# Get the implementation script path
	var script_path = MANAGER_PATHS.get(manager_name)
	if not script_path:
		push_error("ManagerBootstrap: No path defined for manager: ", manager_name)
		manager_load_failed.emit(manager_name, "No path defined")
		return false

	# Check if the script exists
	if not ResourceLoader.exists(script_path):
		push_error("ManagerBootstrap: Manager implementation not found: ", script_path)
		manager_load_failed.emit(manager_name, "Script not found: " + script_path)
		return false

	# Load the script
	var script = load(script_path)
	if not script:
		push_error("ManagerBootstrap: Failed to load script: ", script_path)
		manager_load_failed.emit(manager_name, "Failed to load script")
		return false

	# Instantiate the manager
	var instance = script.new()
	if not instance:
		push_error("ManagerBootstrap: Failed to instantiate manager: ", manager_name)
		manager_load_failed.emit(manager_name, "Failed to instantiate")
		return false

	# Set the instance name
	instance.name = manager_name + "Impl"

	# Add to scene tree (makes it a proper node)
	add_child(instance)

	# Store the instance
	_managers[manager_name] = instance

	# Get the proxy autoload
	var proxy_path = "/root/" + manager_name
	var proxy = get_node_or_null(proxy_path)

	if not proxy:
		push_error("ManagerBootstrap: Proxy autoload not found: ", proxy_path)
		manager_load_failed.emit(manager_name, "Proxy not found")
		return false

	# Check if proxy has the _set_impl method
	if not proxy.has_method("_set_impl"):
		push_error("ManagerBootstrap: Proxy missing _set_impl() method: ", manager_name)
		manager_load_failed.emit(manager_name, "Proxy missing _set_impl()")
		return false

	# Inject implementation into proxy
	proxy._set_impl(instance)

	print("ManagerBootstrap: ✓ ", manager_name, " loaded and injected into proxy")
	return true


## Called when the bootstrap loads (before managers)
func _ready() -> void:
	print("ManagerBootstrap: Bootstrap ready. Waiting for load_managers() call...")
	# Don't auto-load here - let MainMenu trigger it after PCK check
