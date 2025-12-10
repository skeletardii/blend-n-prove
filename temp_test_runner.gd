extends SceneTree

func _init():
	print("--- Running BooleanLogicEngineImpl tests ---")
	var BooleanLogicEngineImpl = load("res://src/managers/BooleanLogicEngineImpl.gd").new()
	var success = BooleanLogicEngineImpl.test_logic_engine()
	BooleanLogicEngineImpl.free()
	print("\n--- Tests finished ---")
	if success:
		print("✅ ALL IMPROVEMENTS VERIFIED!")
	else:
		print("❌ Some tests failed")
	quit()
