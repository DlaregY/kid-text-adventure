extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func run() -> void:
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.discovered_stories.size() == 6, "Expected all six stories in menu")
	var total_scenes := 0
	for entry in game.discovered_stories:
		check(game._load_story(entry.path), "Failed to load " + entry.path)
		var valid: Dictionary = game.story.duplicate(true)
		var start: String = valid.start_scene
		var rules: Array = valid.scenes[start].commands
		check(not rules.is_empty(), "Start scene needs commands")
		for field in ["requirements", "effects"]:
			var bad: Dictionary = valid.duplicate(true)
			bad.scenes[start].commands[0][field] = "invalid"
			check(not game._validate_story(bad).ok, "Accepted invalid " + field)
		for scene_id in game.scenes:
			game.current_scene_id = scene_id
			await game._render_scene()
			check(not game.story_text.text.is_empty(), "Empty scene " + scene_id)
			total_scenes += 1
		print("PASS load/validate/render: ", entry.display_name, " (", game.scenes.size(), " scenes)")
	game.inventory.clear()
	game.flags.clear()
	check(not game._requirements_pass({"inventory_has": ["key"]}), "Missing key passed")
	game._apply_effects({"inventory_add": ["key"], "flags_set": {"opened": true}})
	check(game._requirements_pass({"inventory_has": ["key"], "flags_true": ["opened"]}), "Acquired requirements failed")
	game._apply_effects({"inventory_remove": ["key"], "flags_set": {"opened": false}})
	check(not game._requirements_pass({"inventory_has": ["key"]}), "Consumed key remained")
	check(not game._requirements_pass({"flags_true": ["opened"]}), "Cleared flag remained")
	for failure in failures:
		printerr("FAIL: ", failure)
	print("Rendered ", total_scenes, " scenes; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
