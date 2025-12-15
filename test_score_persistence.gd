extends SceneTree

func _init():
	print("Starting Score Persistence Test...")
	
	# Wait for singletons to be ready
	await process_frame
	await process_frame
	
	test_score_persistence()
	quit()

func test_score_persistence():
	print("Testing if score persists after game over...")
	
	# 1. Start a new game (resets stats)
	GameManager.start_new_game()
	
	# Verify initial state
	if GameManager.current_score != 0:
		print("FAILURE: Score should be 0 at start, but is ", GameManager.current_score)
		return
		
	# 2. Simulate gameplay - add score
	GameManager.add_score(150)
	
	if GameManager.current_score != 150:
		print("FAILURE: Score should be 150 after adding, but is ", GameManager.current_score)
		return
		
	print("Score set to 150. Forcing game over...")
	
	# 3. Force game over (calls complete_progress_session)
	GameManager.force_game_over()
	
	# 4. Check if score persisted
	if GameManager.current_score == 150:
		print("SUCCESS: Score persisted after game over! Current score: ", GameManager.current_score)
	else:
		print("FAILURE: Score was reset prematurely! Current score: ", GameManager.current_score)
		
	# 5. Verify reset happens on next game
	print("Starting next game...")
	GameManager.start_new_game()
	
	if GameManager.current_score == 0:
		print("SUCCESS: Score reset correctly on new game start.")
	else:
		print("FAILURE: Score NOT reset on new game start! Current score: ", GameManager.current_score)
