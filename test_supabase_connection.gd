extends Node

## Test Supabase Connection
## Run this script in Godot to verify your .env setup is working

func _ready():
	print("=== Testing Supabase Connection ===")
	test_connection()

func test_connection():
	# Wait for managers to load
	await get_tree().create_timer(2.0).timeout

	if not SupabaseService:
		print("ERROR: SupabaseService not found!")
		return

	print("1. Testing fetch_top_10_today()...")
	var leaderboard = await SupabaseService.fetch_top_10_today()

	if leaderboard == null:
		print("   ❌ FAILED: Could not fetch leaderboard")
		print("   Check your .env file and Supabase credentials")
		return

	print("   ✅ SUCCESS: Fetched leaderboard")
	print("   Found " + str(leaderboard.size()) + " entries")

	if leaderboard.size() > 0:
		print("   Sample entry: " + str(leaderboard[0]))

	print("\n2. Testing submit_score()...")
	var success = await SupabaseService.submit_score("TST", 9999, 60.0, 1)

	if success:
		print("   ✅ SUCCESS: Score submitted")
	else:
		print("   ❌ FAILED: Could not submit score")
		print("   Check your Supabase table permissions")

	print("\n=== Test Complete ===")
	print("You can now close this test scene")
