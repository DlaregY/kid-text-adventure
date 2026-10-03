extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)

func settle() -> void:
	for i in range(12):
		await process_frame

func apply(game, command: Array[String]) -> bool:
	return await game._apply_command(command)

func tap(game, token: String) -> void:
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			if not tile.is_queued_for_deletion() and tile.token == token:
				game._on_tile_pressed(tile)
				return
	check(false, "Missing tile: " + token)

func start_dragon(game) -> void:
	check(game._load_story("res://stories/dragon_egg.json"), "Load Dragon Egg")
	await game._start_story()
	await settle()

func continue_story(game) -> void:
	while not game.continue_button.visible:
		await process_frame
	game.continue_button.pressed.emit()
	while game.is_transitioning:
		await process_frame

func test_menu(game) -> void:
	for i in range(game.story_picker.item_count):
		game.story_picker.select(i)
		game._on_story_selected(i)
		await settle()
		var rect: Rect2 = game.story_picker.get_global_rect()
		check(rect.position.x >= 0 and rect.end.x <= root.size.x,
			"Story picker must fit the 540px viewport: " + game.story_picker.get_item_text(i))
	print("Checked menu bounds for every story")

func test_command_delay(game) -> void:
	await start_dragon(game)
	tap(game, "look")
	tap(game, "door")
	await create_timer(0.2).timeout
	tap(game, "key")
	await create_timer(0.36).timeout
	check(game.feedback_text.text.is_empty(), "Replacing a tile must restart the full command delay")
	check(game.slot1.token == "look" and game.slot2.token == "key", "Pending replacement must remain in slots")
	await create_timer(0.3).timeout
	check(game.feedback_text.text == "You don't see a key anywhere in this room.", "Execute only the latest selected command")
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "Clear completed command slots")

	# Drag-and-drop uses the same debounce as tapping.
	game.feedback_text.text = ""
	game.slot1._drop_data(Vector2.ZERO, {"token": "look", "label": "look"})
	game.slot2._drop_data(Vector2.ZERO, {"token": "door", "label": "door"})
	await create_timer(0.2).timeout
	game.slot2._drop_data(Vector2.ZERO, {"token": "key", "label": "key"})
	await create_timer(0.36).timeout
	check(game.feedback_text.text.is_empty(), "Replacing a dropped tile must restart the delay")
	await create_timer(0.3).timeout
	check(game.feedback_text.text == "You don't see a key anywhere in this room.", "Dropped command must execute after its own delay")

	# Returning to the same scene ID in a new game must cancel old input.
	tap(game, "look")
	tap(game, "key")
	await create_timer(0.2).timeout
	game._show_menu()
	await start_dragon(game)
	tap(game, "look")
	tap(game, "door")
	await create_timer(0.32).timeout
	check(game.feedback_text.text.is_empty(), "A previous game must not execute a new game's command")
	await create_timer(0.3).timeout
	check(not game.feedback_text.text.is_empty(), "New game command should still execute")
	print("Checked tap, drag, and restart command delays")

func test_hints(game) -> void:
	await start_dragon(game)
	game.current_scene_id = "hall"
	await game._render_scene()
	for i in range(5):
		await apply(game, ["take", "key"])
	check(not game.hint_button.visible, "Do not show hints before six attempts without progress")
	await apply(game, ["take", "key"])
	check(game.fail_count == 6 and game.hint_button.visible, "Blocked commands must unlock hints after six attempts")
	game._on_hint_pressed()
	await apply(game, ["take", "key"])
	check(game.hint_button.visible and game.hint_index == 1, "Another blocked command must preserve hint progression")
	await apply(game, ["open", "box"])
	check(game.fail_count == 0 and game.hint_index == 0 and not game.hint_button.visible, "Actual puzzle progress must reset hints")
	for i in range(6):
		await apply(game, ["open", "box"])
	check(game.hint_button.visible, "Repeating a completed action must not suppress hints")
	await apply(game, ["take", "key"])
	await continue_story(game)
	check(game.fail_count == 0 and not game.hint_button.visible, "New scene must reset hints")
	for i in range(6):
		await apply(game, ["go", "key"])
	check(game.hint_button.visible, "Unmatched commands must still unlock hints")
	game._show_menu()
	check(game.fail_count == 0 and not game.hint_button.visible, "Menu must reset hints")
	# A rule can have effects without actually changing existing state.
	check(game._load_story("res://stories/crystal_cave.json"), "Load Crystal Cave")
	await game._start_story()
	game.current_scene_id = "locked_door"
	game.flags["box_opened"] = true
	await game._render_scene()
	await apply(game, ["take", "key"])
	check(game.inventory.has("key") and game.fail_count == 0, "New inventory must count as progress")
	for i in range(6):
		await apply(game, ["take", "key"])
	check(game.hint_button.visible, "Re-adding the same item must not count as progress")
	print("Checked blocked actions, progress, repeated actions, and hint resets")

func test_inventory(game) -> void:
	await start_dragon(game)
	game.current_scene_id = "dragon"
	game.inventory["egg"] = true
	await game._render_scene()
	check(game.inventory_label.visible and game.inventory_tray.visible, "Show a carried item")
	await apply(game, ["give", "egg"])
	await continue_story(game)
	await settle()
	check(game.current_scene_id == "treasure" and game.inventory.is_empty(), "Giving the egg must consume the last item")
	check(game.inventory_tray.get_child_count() == 0, "Consumed inventory must have no tiles")
	check(not game.inventory_label.visible and not game.inventory_tray.visible, "Hide inventory after consuming its last item")
	game.current_scene_id = "bridge"
	game.inventory = {"rope": true, "egg": true}
	await game._render_scene()
	await apply(game, ["rope", "bridge"])
	await settle()
	check(game.inventory_label.visible and game.inventory_tray.get_child_count() == 1, "Keep inventory visible when another item remains")
	print("Checked inventory visibility after consumption")

func run() -> void:
	create_timer(60).timeout.connect(func():
		printerr("FAIL: Regression suite timed out")
		quit(1)
	)
	root.size = Vector2i(540, 960)
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	await settle()
	await test_menu(game)
	await test_command_delay(game)
	await test_hints(game)
	await test_inventory(game)
	print("Game regression checks=", checks, "; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
