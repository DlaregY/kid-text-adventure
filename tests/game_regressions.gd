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

func test_save_resume(game) -> void:
	game._clear_save()
	game._show_menu()
	check(not game.resume_button.visible, "No CONTINUE button without a save")
	check(not game.top_bar.visible, "Home bar hidden on the menu")
	await start_dragon(game)
	check(game.top_bar.visible, "Home bar visible during a story")
	check(FileAccess.file_exists(game.SAVE_PATH), "Starting a story writes a save")
	game.current_scene_id = "hall"
	await game._render_scene()
	await apply(game, ["open", "box"])
	await apply(game, ["take", "key"])
	await continue_story(game)
	check(game.current_scene_id == "gate" and game.inventory.has("key"), "Reached the gate with the key")
	game._show_menu()
	check(game.resume_button.visible, "CONTINUE appears when a save exists")
	check(game.inventory.is_empty(), "Menu clears live state")
	game._on_resume_pressed()
	await settle()
	check(game.has_active_story and game.current_scene_id == "gate", "Resume lands on the saved scene")
	check(game.inventory.has("key") and game.flags.get("box_open", false), "Resume restores inventory and flags")
	check(game.inventory_tray.get_child_count() == 1, "Resumed inventory renders a tile")
	# PLAY always starts fresh.
	game._show_menu()
	game._on_start_pressed()
	await settle()
	check(game.current_scene_id == "room" and game.inventory.is_empty(), "PLAY starts from the beginning")
	# Reaching an ending clears the save.
	game.current_scene_id = "win"
	await game._render_scene()
	check(not FileAccess.file_exists(game.SAVE_PATH), "Terminal scene clears the save")
	game._show_menu()
	check(not game.resume_button.visible, "No CONTINUE after an ending")
	# A corrupt save is ignored.
	var f := FileAccess.open(game.SAVE_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	game._show_menu()
	check(not game.resume_button.visible, "Corrupt save is ignored")
	game._clear_save()
	print("Checked save, resume, fresh start, and ending cleanup")

func test_stop_dialog(game) -> void:
	await start_dragon(game)
	game._notification(game.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(game.stop_dialog.visible, "Back opens the stop dialog during a story")
	game.keep_button.pressed.emit()
	check(not game.stop_dialog.visible and game.has_active_story, "KEEP PLAYING closes the dialog and keeps the story")
	game.home_button.pressed.emit()
	check(game.stop_dialog.visible, "Home button opens the stop dialog")
	game._notification(game.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game.stop_dialog.visible and game.has_active_story, "Back while the dialog is open dismisses it")
	game.home_button.pressed.emit()
	game.stop_menu_button.pressed.emit()
	check(not game.has_active_story and game.menu_screen.visible and not game.stop_dialog.visible, "GO TO MENU returns to the menu")
	check(game.resume_button.visible, "Progress survives stopping")
	# Stopping mid-transition must not let the old transition finish later.
	await start_dragon(game)
	game.current_scene_id = "hall"
	game.flags["box_open"] = true
	await game._render_scene()
	await apply(game, ["take", "key"])
	while not game.continue_button.visible:
		await process_frame
	game.home_button.pressed.emit()
	game.stop_menu_button.pressed.emit()
	check(not game.is_transitioning and not game.continue_button.visible, "Menu cancels a pending transition")
	await start_dragon(game)
	game.continue_button.pressed.emit()
	await settle()
	await create_timer(0.5).timeout
	check(game.current_scene_id == "room", "A stale transition must not change the new game's scene")
	check(game.transition_overlay.color.a == 0.0, "Overlay stays clear")
	game._show_menu()
	game._clear_save()
	print("Checked back button, home button, and stop dialog")

func start_bigfoot_meeting(game, with_snack: bool) -> void:
	check(game._load_story("res://stories/bigfoot_campout.json"), "Load Bigfoot")
	await game._start_story()
	game.current_scene_id = "bigfoot_meeting"
	if with_snack:
		game.inventory["snack"] = true
	await game._render_scene()

func test_bigfoot_meeting(game) -> void:
	# LOOK and TALK must not end the story on the first use.
	await start_bigfoot_meeting(game, true)
	await apply(game, ["look", "bigfoot"])
	await apply(game, ["talk", "bigfoot"])
	await settle()
	check(game.current_scene_id == "bigfoot_meeting" and not game.is_transitioning, "First LOOK and TALK are safe in the meeting")
	# Tapping the snack tile then Bigfoot must reach the friend ending.
	tap(game, "snack")
	tap(game, "bigfoot")
	check(game.slot1.token == "snack" and game.slot2.token == "bigfoot", "Inventory tile routes to the action slot")
	await create_timer(0.6).timeout
	await continue_story(game)
	check(game.current_scene_id == "ending_friend" and not game.inventory.has("snack"), "snack + bigfoot gives the snack")
	game._show_menu()
	# Every other ending is a deliberate choice.
	var routes := {
		"ending_goofy": [["talk", "bigfoot"], ["talk", "bigfoot"]],
		"ending_cautious": [["go", "forest"]],
		"ending_missed": [["go", "camp"]],
		"ending_friend": [["give", "bigfoot"]],
	}
	for ending in routes.keys():
		await start_bigfoot_meeting(game, true)
		for step in routes[ending]:
			var cmd: Array[String] = [str(step[0]), str(step[1])]
			await apply(game, cmd)
		await continue_story(game)
		check(game.current_scene_id == ending, "Reach " + ending)
		game._show_menu()
	# Without the snack, GIVE explains the problem instead of ending anything.
	await start_bigfoot_meeting(game, false)
	await apply(game, ["give", "bigfoot"])
	await settle()
	check(game.current_scene_id == "bigfoot_meeting" and game.feedback_text.text.contains("empty"), "GIVE without a snack is explained")
	# Camp will not let you leave without the snack.
	game.current_scene_id = "camp"
	await game._render_scene()
	await apply(game, ["look", "bushes"])
	await apply(game, ["go", "forest"])
	await settle()
	check(game.current_scene_id == "camp" and game.feedback_text.text.contains("snack"), "Leaving camp requires the snack")
	await apply(game, ["take", "snack"])
	await apply(game, ["go", "forest"])
	await continue_story(game)
	check(game.current_scene_id == "forest_edge" and game.inventory.has("snack"), "Leave camp with the snack")
	game._show_menu()
	game._clear_save()
	print("Checked Bigfoot meeting safety, routing, and endings")

func test_stop_dialog_suspends_commands(game) -> void:
	await start_bigfoot_meeting(game, true)
	tap(game, "talk")
	tap(game, "bigfoot")
	await create_timer(0.2).timeout
	game.home_button.pressed.emit()
	await create_timer(0.6).timeout
	check(game.stop_dialog.visible and game.feedback_text.text.is_empty() and not game.is_transitioning,
		"A command in its debounce window must not fire behind the stop dialog")
	check(game.slot1.token == "talk" and game.slot2.token == "bigfoot", "Pending tiles stay in the slots")
	tap(game, "look")
	check(game.slot1.token == "talk", "Tiles cannot be placed while the dialog is open")
	game.slot1._drop_data(Vector2.ZERO, {"token": "look", "label": "look"})
	check(game.command_timer.is_stopped(), "Dropping a tile while the dialog is open must not arm the timer")
	game.slot1.set_tile("talk", "talk")
	game.keep_button.pressed.emit()
	await create_timer(0.3).timeout
	check(game.feedback_text.text.is_empty(), "KEEP PLAYING restarts the full delay")
	await create_timer(0.35).timeout
	check(game.feedback_text.text.contains("hoot") and game.current_scene_id == "bigfoot_meeting", "The pending command executes after KEEP PLAYING")
	game._show_menu()
	game._clear_save()
	print("Checked the stop dialog suspends pending commands")

func test_pending_transition_save(game) -> void:
	# Item-adding transition interrupted before Continue.
	await start_dragon(game)
	game.current_scene_id = "hall"
	game.flags["box_open"] = true
	await game._render_scene()
	await apply(game, ["take", "key"])
	check(game.pending_scene_id == "gate", "Transition destination is pending until Continue")
	game.home_button.pressed.emit()
	game.stop_menu_button.pressed.emit()
	game._on_resume_pressed()
	await settle()
	check(game.current_scene_id == "gate" and game.inventory.has("key") and game.pending_scene_id.is_empty(),
		"Resume after stopping before Continue lands past the command with the new item")
	# Item-consuming transition interrupted before Continue.
	game._show_menu()
	await start_dragon(game)
	game.current_scene_id = "dragon"
	game.inventory["egg"] = true
	await game._render_scene()
	await apply(game, ["give", "egg"])
	game.home_button.pressed.emit()
	game.stop_menu_button.pressed.emit()
	game._on_resume_pressed()
	await settle()
	check(game.current_scene_id == "treasure" and not game.inventory.has("egg"), "Resume keeps the consumed item consumed and lands on the destination")
	# A completed transition clears the pending destination and saves normally.
	await apply(game, ["look", "treasure"])
	check(game.pending_scene_id.is_empty(), "No pending scene after a plain command")
	game._show_menu()
	game._clear_save()
	print("Checked pending-transition saves for added and consumed items")

func test_home_button_fixed(game) -> void:
	check(game._load_story("res://stories/phone_trap.json"), "Load Phone Trap")
	await game._start_story()
	game.current_scene_id = "home"
	await game._render_scene()
	await settle()
	check(game.layout.size.y > game.scroll_container.size.y, "Phone Trap home scene must overflow at 540x960 for this check")
	game.scroll_container.scroll_vertical = 100000
	await settle()
	var rect: Rect2 = game.home_button.get_global_rect()
	check(rect.position.y >= 0 and rect.end.y <= root.size.y and rect.end.x <= root.size.x, "Home button stays on screen after scrolling")
	check(game.scroll_container.get_global_rect().position.y >= rect.end.y, "Story content starts below the home bar")
	game._show_menu()
	check(game.scroll_container.offset_top == 0.0, "Menu reclaims the top bar space")
	game._clear_save()
	print("Checked the home button stays fixed while scrolling")

func test_command_bar_feel(game) -> void:
	await start_dragon(game)
	game.current_scene_id = "hall"
	await game._render_scene()
	# Timer bar shows only during the debounce.
	check(not game.timer_bar.visible, "Timer bar hidden when idle")
	tap(game, "look")
	tap(game, "box")
	await process_frame
	await process_frame
	check(game.timer_bar.visible and game.timer_bar.value < 1.0, "Timer bar visible and draining during the delay")
	# Tapping a filled slot clears it and cancels the command.
	game.slot2.tapped.emit()
	check(game.slot2.token.is_empty() and game.command_timer.is_stopped(), "Tapping a slot clears it and stops the timer")
	await create_timer(0.6).timeout
	check(game.feedback_text.text.is_empty() and not game.timer_bar.visible, "Cleared command never fires")
	game.slot1.tapped.emit()
	check(game.slot1.token.is_empty(), "Tapping the action slot clears it too")
	game.slot1.tapped.emit()
	check(game.slot1.token.is_empty(), "Tapping an empty slot is harmless")
	# Feedback colors: fallback is red-brown, progress is green, plain match is neutral.
	await apply(game, ["go", "key"])
	check(game.feedback_text.get_theme_color("font_color") == game.FEEDBACK_FAIL, "Fallback feedback uses the fail color")
	await apply(game, ["look", "door"])
	check(game.feedback_text.get_theme_color("font_color") == game.FEEDBACK_NEUTRAL, "Plain matched response uses the neutral color")
	var action_tiles_before: Array = game.action_tray.get_children()
	var story_font_before: int = game.story_text.get_theme_font_size("font_size")
	await apply(game, ["open", "box"])
	check(game.feedback_text.get_theme_color("font_color") == game.FEEDBACK_SUCCESS, "Progress uses the success color")
	check(game.feedback_text.text.contains("open") or not game.feedback_text.text.is_empty(), "Progress keeps its response visible")
	check(game.action_tray.get_children() == action_tiles_before, "Unchanged trays keep their tile nodes after progress")
	check(game.story_text.get_theme_font_size("font_size") == story_font_before, "Progress does not reset the story font")
	# Picking up an item moves exactly that tile to the inventory tray.
	var things_before: int = game.thing_tray.get_child_count()
	await apply(game, ["take", "key"])
	await continue_story(game)
	check(game.current_scene_id == "gate", "Transition still works after refresh changes")
	game._show_menu()
	check(game.action_tray.get_child_count() == 0 and game.thing_tray.get_child_count() == 0, "Menu frees tiles immediately")
	game._clear_save()
	print("Checked timer bar, slot clearing, feedback styling, and incremental tile refresh")

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
	await test_save_resume(game)
	await test_stop_dialog(game)
	await test_bigfoot_meeting(game)
	await test_stop_dialog_suspends_commands(game)
	await test_pending_transition_save(game)
	await test_home_button_fixed(game)
	await test_command_bar_feel(game)
	print("Game regression checks=", checks, "; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
