extends RefCounted
# M05 and the story portion of M06. The caller has entered the isolated QA guard.

func execute(suite, game, first: String, second: String) -> void:
	var command: Array[String] = [first, second]
	# Use actual tile routing + debounce for the newly advertised commands.
	suite.tap(game, first)
	suite.tap(game, second)
	suite.check(game.slot1.token == first and game.slot2.token == second, "Story command routes into both slots: " + " ".join(command))
	await suite.create_timer(0.65).timeout
	if game.is_transitioning:
		await suite.continue_story(game)

func run(suite, game) -> void:
	# Arrive with the key that the preceding city scene supplies. Python's path
	# audit also walks the complete prefix from the bedroom to this inventory.
	for exit_word in ["open", "key"]:
		game._show_menu()
		suite.check(game._load_story("res://stories/spider_hero.json"), "Load library story")
		await game._start_story()
		game.current_scene_id = "library"
		game.inventory = {"note": true, "web": true, "key": true}
		await game._render_scene()
		await execute(suite, game, exit_word, "door")
		suite.check(game.current_scene_id == "library" and game.inventory.has("key"), "Door stays locked until the book is read")
		game.hint_index = 2
		game._on_hint_pressed()
		var hint: String = game.feedback_text.text
		var rx := RegEx.new()
		rx.compile("\\b(LOOK|TAKE|OPEN) (SHELF|BOOK|DOOR)\\b")
		var steps: Array[RegExMatch] = rx.search_all(hint)
		suite.check(steps.size() == 4 and hint.contains("OPEN BOOK"), "Final library hint includes all four steps")
		for i in range(steps.size()):
			var first := steps[i].get_string(1).to_lower()
			var second := steps[i].get_string(2).to_lower()
			if i == steps.size() - 1:
				first = exit_word
			await execute(suite, game, first, second)
		suite.check(game.current_scene_id == "basement" and bool(game.flags.get("read_book", false)), "Following the library hint reaches the basement")
		suite.check(not game.inventory.has("key") and game.inventory.has("book"), "Library exit consumes the key but retains the book")

	for verb in ["go", "open"]:
		game._show_menu()
		suite.check(game._load_story("res://stories/phone_trap.json"), "Load Phone Trap for bed alias")
		await game._start_story()
		game.current_scene_id = "landing"
		await game._render_scene()
		suite.check(game._label_for("bed") == "Bed" and game.EMOJI.get("bed", "") == "🛏️", "Bed has its label and symbol")
		await execute(suite, game, verb, "bed")
		suite.check(game.current_scene_id == "home" and game.ending_badge.visible, "Bed alias reaches the existing ending: " + verb)
		suite.check(not FileAccess.file_exists(game.SAVE_PATH), "Bed ending clears the active save")

	# Start with the old save's said_hello flag. Repeated chat must still stay put.
	await suite.start_bigfoot_meeting(game, true, true)
	game.inventory["lantern"] = true
	game.inventory["pinecone"] = true
	game.inventory["berries"] = true
	game.flags["said_hello"] = true
	await game._render_scene()
	game._save_progress()
	game._show_menu()
	game._on_resume_pressed()
	await suite.settle()
	suite.check(game.current_scene_id == "bigfoot_meeting" and bool(game.flags.get("said_hello", false)), "Legacy hello flag resumes unchanged")
	var before: Dictionary = game.inventory.duplicate()
	for i in range(3):
		await execute(suite, game, "talk", "bigfoot")
		await execute(suite, game, "look", "bigfoot")
		suite.check(game.current_scene_id == "bigfoot_meeting" and not game.is_transitioning, "Repeated conversation and LOOK remain non-terminal")
	suite.check(game.inventory == before and FileAccess.file_exists(game.SAVE_PATH), "Exploring keeps every item and the checkpoint")
	await execute(suite, game, "tell", "bigfoot")
	suite.check(game.current_scene_id == "bigfoot_meeting" and not game.feedback_text.text.contains("say hello"), "TELL uses its own fallback, not TALK's")
	await execute(suite, game, "look", "joke")
	suite.check(game.feedback_text.text.contains("ends your visit") and not game.is_transitioning, "Inspecting the joke explains the ending without choosing it")
	await execute(suite, game, "tell", "joke")
	suite.check(game.current_scene_id == "ending_goofy" and game.ending_label.text.contains("Pinecone Socks"), "Explicit goodbye joke reaches the existing goofy ending")
	suite.check(game.inventory == before, "Goodbye joke does not consume optional items")
	game._show_menu()
	suite.check(not game.ending_badge.visible and not game.resume_button.visible, "Goofy ending cleans up normally")
	game._clear_save()
	game._clear_progress()
	print("Checked library hint, bed aliases, and deliberate Bigfoot goodbye")
