extends SceneTree

# Test win rate calculation after fixes

var tracker

func repeat_char(ch: String, count: int) -> String:
	var result = ""
	for i in range(count):
		result += ch
	return result

func _init():
	print("\n================================================================================")
	print("TESTING WIN RATE CALCULATION FIX")
	print("================================================================================\n")

	# Load the ProgressTracker
	tracker = load("res://src/game/autoloads/ProgressTracker.gd").new()

	run_tests()

	quit()

func run_tests():
	var passed = 0
	var failed = 0

	print("Test 1: Initial state - 0 games played")
	print(repeat_char("-", 80))
	if tracker.statistics.total_games_played == 0:
		print("  Games played: 0")
		print("  Success rate: " + str(tracker.statistics.success_rate))
		if tracker.statistics.success_rate == 0.0:
			print("  ✓ PASS - Success rate is 0.0 (not undefined)\n")
			passed += 1
		else:
			print("  ✗ FAIL - Success rate should be 0.0\n")
			failed += 1
	else:
		print("  ✗ FAIL - Starting with existing data\n")
		failed += 1

	print("Test 2: Record a WIN")
	print(repeat_char("-", 80))
	tracker.start_new_session(1)
	tracker.complete_current_session(100, 3, 5, "win")
	print("  Games played: " + str(tracker.statistics.total_games_played))
	print("  Successful games: " + str(tracker.statistics.total_successful_games))
	print("  Success rate: " + str(tracker.statistics.success_rate))
	if tracker.statistics.total_games_played == 1 and \
	   tracker.statistics.total_successful_games == 1 and \
	   tracker.statistics.success_rate == 1.0:
		print("  ✓ PASS - Win rate is 100% (1/1)\n")
		passed += 1
	else:
		print("  ✗ FAIL - Expected 1 game, 1 success, 100% rate\n")
		failed += 1

	print("Test 3: Record a LOSS")
	print(repeat_char("-", 80))
	tracker.start_new_session(1)
	tracker.complete_current_session(50, 0, 3, "loss")
	print("  Games played: " + str(tracker.statistics.total_games_played))
	print("  Successful games: " + str(tracker.statistics.total_successful_games))
	print("  Success rate: " + str(tracker.statistics.success_rate))
	var expected_rate = 1.0 / 2.0  # 1 win out of 2 games = 50%
	if tracker.statistics.total_games_played == 2 and \
	   tracker.statistics.total_successful_games == 1 and \
	   abs(tracker.statistics.success_rate - expected_rate) < 0.001:
		print("  ✓ PASS - Win rate is 50% (1/2)\n")
		passed += 1
	else:
		print("  ✗ FAIL - Expected 2 games, 1 success, 50% rate\n")
		failed += 1

	print("Test 4: Record another LOSS")
	print(repeat_char("-", 80))
	tracker.start_new_session(1)
	tracker.complete_current_session(25, 0, 2, "loss")
	print("  Games played: " + str(tracker.statistics.total_games_played))
	print("  Successful games: " + str(tracker.statistics.total_successful_games))
	print("  Success rate: " + str(tracker.statistics.success_rate))
	expected_rate = 1.0 / 3.0  # 1 win out of 3 games = 33.33%
	if tracker.statistics.total_games_played == 3 and \
	   tracker.statistics.total_successful_games == 1 and \
	   abs(tracker.statistics.success_rate - expected_rate) < 0.001:
		print("  ✓ PASS - Win rate is 33.33% (1/3)\n")
		passed += 1
	else:
		print("  ✗ FAIL - Expected 3 games, 1 success, 33.33% rate\n")
		failed += 1

	print("Test 5: Record two more WINS")
	print(repeat_char("-", 80))
	tracker.start_new_session(1)
	tracker.complete_current_session(150, 3, 8, "win")
	tracker.start_new_session(1)
	tracker.complete_current_session(200, 3, 10, "win")
	print("  Games played: " + str(tracker.statistics.total_games_played))
	print("  Successful games: " + str(tracker.statistics.total_successful_games))
	print("  Success rate: " + str(tracker.statistics.success_rate))
	expected_rate = 3.0 / 5.0  # 3 wins out of 5 games = 60%
	if tracker.statistics.total_games_played == 5 and \
	   tracker.statistics.total_successful_games == 3 and \
	   abs(tracker.statistics.success_rate - expected_rate) < 0.001:
		print("  ✓ PASS - Win rate is 60% (3/5)\n")
		passed += 1
	else:
		print("  ✗ FAIL - Expected 5 games, 3 successes, 60% rate\n")
		failed += 1

	print("Test 6: Test save/load cycle")
	print(repeat_char("-", 80))
	print("  Saving current stats...")
	var save_data = tracker.statistics.to_dict()
	print("  Saved: " + str(tracker.statistics.total_games_played) + " games, " + \
	      str(tracker.statistics.total_successful_games) + " wins")

	# Create new tracker and load data
	var tracker2 = load("res://src/game/autoloads/ProgressTracker.gd").new()
	tracker2.statistics.from_dict(save_data)

	print("  Loaded: " + str(tracker2.statistics.total_games_played) + " games, " + \
	      str(tracker2.statistics.total_successful_games) + " wins")
	print("  Recalculated rate: " + str(tracker2.statistics.success_rate))

	if tracker2.statistics.total_games_played == 5 and \
	   tracker2.statistics.total_successful_games == 3 and \
	   abs(tracker2.statistics.success_rate - 0.6) < 0.001:
		print("  ✓ PASS - Rate recalculated correctly after load\n")
		passed += 1
	else:
		print("  ✗ FAIL - Rate not recalculated correctly after load\n")
		failed += 1

	print("Test 7: Verify success_rate not saved to dict")
	print(repeat_char("-", 80))
	if not save_data.has("success_rate"):
		print("  ✓ PASS - success_rate is NOT saved (always recalculated)\n")
		passed += 1
	else:
		print("  ✗ FAIL - success_rate should not be in save data\n")
		failed += 1

	# Summary
	print(repeat_char("=", 80))
	print("SUMMARY: " + str(passed) + "/" + str(passed + failed) + " tests passed")
	print(repeat_char("=", 80))

	if failed == 0:
		print("\n✓✓✓ ALL WIN RATE TESTS PASSED! ✓✓✓")
		print("\nThe win rate bug is FIXED:")
		print("  - Correctly tracks wins AND losses")
		print("  - Calculates percentage properly")
		print("  - Always recalculates on load (not saved)")
		print("  - Handles edge cases (0 games = 0%)")
	else:
		print("\n✗✗✗ " + str(failed) + " TESTS FAILED ✗✗✗")

	print(repeat_char("=", 80))
