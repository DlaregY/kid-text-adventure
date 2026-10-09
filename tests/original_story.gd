extends SceneTree
# Full path through the real engine, plus one legacy checkpoint; never normal player data.
var game
var failures: Array[String] = []
var checks: int = 0
var visited: Array[String] = []

func _initialize() -> void:
	if not preload("res://tests/qa_guard.gd").enter():
		quit(2)
		return
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func settle() -> void:
	for i in range(8):
		await process_frame

func tap_label(label: String) -> void:
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			if game._label_for(tile.token).to_lower() == label.to_lower():
				check(tile.text.contains(game._label_for(tile.token)), "Tile displays its vocabulary label")
				game._on_tile_pressed(tile)
				return
	check(false, "Missing displayed tile: " + label)

func execute(first: String, second: String) -> void:
	tap_label(first)
	tap_label(second)
	check(game.slot1.token != "" and game.slot2.token != "", "Both slots filled for " + first + " " + second)
	await create_timer(0.65).timeout
	if game.is_transitioning:
		while not game.continue_button.visible:
			await process_frame
		game.continue_button.pressed.emit()
		while game.is_transitioning:
			await process_frame
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "Command consumed both selected tiles")
	if game.current_scene_id not in visited:
		visited.append(game.current_scene_id)

func run() -> void:
	create_timer(100).timeout.connect(func() -> void:
		printerr("FAIL: Original story suite timed out")
		quit(1)
	)
	root.size = Vector2i(540, 960)
	game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	await settle()
	game._clear_save()
	game._clear_progress()
	check(game._load_story("res://stories/spider_hero.json"), "Stable story path loads")
	await game._start_story()
	visited.append(game.current_scene_id)
	check(game.story.meta.title == "Tess and the Cloud Machine", "Original title loaded")
	var route := [
		["look", "window"], ["open", "window"], ["take", "note"],
		["go", "workshop"], ["talk", "Tess"], ["take", "tongs"],
		["talk", "Bea"], ["take", "key"], ["go", "library"],
		["look", "shelf"], ["take", "book"], ["open", "book"], ["open", "door"],
		["take", "ice"], ["take", "mallet"], ["go", "tunnel"],
		["tongs", "lamp"], ["go", "bridge"], ["go", "bridge"],
		["ice", "door"], ["tongs", "stairs"], ["climb", "stairs"],
	]
	for step in route:
		await execute(str(step[0]), str(step[1]))
	check(game.current_scene_id == "battle", "Full path reached the repair")
	await execute("mallet", "gear")
	check(game.current_scene_id == "battle" and game.inventory.has("hammer"), "Repair blocked without preparation")
	await execute("look", "gear")
	await execute("mallet", "gear")
	check(game.current_scene_id == "battle", "Finding the tooth is not enough; Tess must stop the machine")
	await execute("talk", "Tess")
	await execute("mallet", "gear")
	check(game.current_scene_id == "victory" and not game.inventory.has("hammer"), "Gentle repair frees Puff and hands back mallet")
	await execute("talk", "Puff")
	await execute("go", "home")
	check(game.current_scene_id == "win" and game.ending_badge.visible, "Cloud Crew ending rendered")
	check(game.ending_label.text.contains("Cloud Crew"), "Original ending title displayed")
	check(visited.size() == 13, "Full route visits all thirteen scenes")
	check("win" in game._found_endings("res://stories/spider_hero.json"), "Existing ending ID recorded")
	check(not FileAccess.file_exists(game.SAVE_PATH), "Completion clears checkpoint")

	# Legacy data retains old internal names; the UI must use the new labels/icons.
	game._show_menu()
	var f := FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "story_path": "res://stories/spider_hero.json",
		"scene": "battle", "inventory": ["web", "hammer", "book"],
		"flags": {"saw_weakness": true, "spidey_ready": true}}))
	f.close()
	game._show_menu()
	check(game.resume_button.text.contains("Tess and the Cloud Machine"), "Legacy save resumes under current title")
	game._on_resume_pressed()
	await settle()
	check(game.current_scene_id == "battle" and game.inventory.has("web"), "Legacy checkpoint preserved")
	check(game._icon_for("spiderdude") == "👩‍🔧" and game._icon_for("ghost") == "☁️", "Original character icons override old keys")
	check(game._icon_for("web") == "🗜️" and game._label_for("web") == "tongs", "Legacy tool displays as tongs")
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			check(not tile.text.contains("🕷") and not tile.text.contains("🕸") and not tile.text.contains("Skull"), "No retired identity on resumed tiles")
	await execute("mallet", "gear")
	check(game.current_scene_id == "victory", "Old preparation flags still permit repair")
	game._show_menu()
	check(game._load_story("res://stories/dragon_egg.json"), "Other story still loads")
	check(game._icon_for("dragon") == game.EMOJI["dragon"], "Other stories retain global icons")
	game.story["vocab"]["dragon"] = {"label": "dragon", "icon": 4}
	check(game._icon_for("dragon") == game.EMOJI["dragon"], "Malformed optional icon safely falls back")
	game._clear_save()
	game._clear_progress()
	print("Original story assertions=", checks)
	print("Original story checks; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
