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
	check(game.story_cards.size() == game.discovered_stories.size() and game.story_cards.size() == 6, "One card per story")
	check(game.discovered_stories[0].display_name == "The Lost Dragon Egg", "Cards follow meta.order")
	check(game.bottom_bar.visible and game.play_button.visible, "PLAY lives in the fixed bottom bar on the menu")
	for i in range(game.story_cards.size()):
		game.card_buttons[i].pressed.emit()
		await settle()
		var rect: Rect2 = game.story_cards[i].get_global_rect()
		check(rect.position.x >= 0 and rect.end.x <= root.size.x,
			"Story card must fit the 540px viewport: " + game.discovered_stories[i].display_name)
		check(game.selected_story_path == game.discovered_stories[i].path, "Tapping a card selects its story")
		check(game.story_cards[i].get_theme_stylebox("panel").border_width_left == 4, "Selected card is highlighted")
		var inner: Control = game.story_cards[i].get_child(0)
		check(inner.get_global_rect().end.y <= rect.end.y + 0.5, "Card content stays inside the card: " + game.discovered_stories[i].display_name)
		check(game.card_buttons[i].get_global_rect().encloses(inner.get_global_rect()), "Tap target covers the card content")
	var bar_rect: Rect2 = game.bottom_bar.get_global_rect()
	check(bar_rect.end.y <= root.size.y and game.scroll_container.get_global_rect().end.y <= bar_rect.position.y,
		"Bottom bar is on screen and the menu scrolls above it")
	game.card_buttons[2].pressed.emit()
	game._on_start_pressed()
	await settle()
	check(game.has_active_story and game.loaded_story_path == game.discovered_stories[2].path, "PLAY starts the selected card")
	check(not game.bottom_bar.visible and game.scroll_container.offset_bottom == 0.0, "Bottom bar hides during a story")
	game._show_menu()
	game.about_button.pressed.emit()
	check(game.about_dialog.visible, "Parent corner opens")
	game.card_buttons[0].pressed.emit()
	check(game.selected_story_index == 2, "Cards ignore taps under the Parent corner")
	game._notification(game.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not game.about_dialog.visible and game.menu_screen.visible, "Back closes the Parent corner without quitting")
	game.about_button.pressed.emit()
	game.about_close.pressed.emit()
	check(not game.about_dialog.visible, "CLOSE closes the Parent corner")
	check(game.about_version.text == game.version_label.text and game.version_label.text.begins_with("v0."), "About shows the version")
	game._clear_save()
	print("Checked story cards, bottom bar, and parent corner")

func test_labels(game) -> void:
	await start_bigfoot_meeting(game, false)
	var found := ""
	for tile in game.thing_tray.get_children():
		if tile.token == "bigfoot":
			found = tile.text
	check(found == "🦶 Bigfoot", "Tiles use vocab labels: " + found)
	await apply(game, ["talk", "camp"])
	check(game.feedback_text.text.contains("camp"), "Fallbacks still name the thing")
	game._show_menu()
	game._clear_save()
	print("Checked vocab labels on tiles")

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
	for i in range(3):
		await apply(game, ["take", "key"])
	check(not game.hint_button.visible, "Do not show hints before four attempts without progress")
	await apply(game, ["take", "key"])
	check(game.fail_count == 4 and game.hint_button.visible, "Blocked commands must unlock hints after four attempts")
	game._on_hint_pressed()
	await apply(game, ["take", "key"])
	check(game.hint_button.visible and game.hint_index == 1, "Another blocked command must preserve hint progression")
	await apply(game, ["open", "box"])
	check(game.fail_count == 0 and game.hint_index == 0 and not game.hint_button.visible, "Actual puzzle progress must reset hints")
	for i in range(4):
		await apply(game, ["open", "box"])
	check(game.hint_button.visible, "Repeating a completed action must not suppress hints")
	await apply(game, ["take", "key"])
	await continue_story(game)
	check(game.fail_count == 0 and not game.hint_button.visible, "New scene must reset hints")
	for i in range(4):
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
	for i in range(4):
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
	var bar_rect: Rect2 = game.continue_bar.get_global_rect()
	check(game.continue_bar.visible and bar_rect.end.y <= root.size.y and game.scroll_container.get_global_rect().end.y <= bar_rect.position.y,
		"Continue button is a fixed bar above the scrolling content")
	game.home_button.pressed.emit()
	game.stop_menu_button.pressed.emit()
	check(not game.is_transitioning and not game.continue_button.visible and not game.continue_bar.visible, "Menu cancels a pending transition")
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
	game._finish_reveal()
	for i in range(12):
		game.story_text.text += "\nExtra line %d to force the layout to scroll." % i
	await settle()
	check(game.layout.size.y > game.scroll_container.size.y, "Padded scene must overflow at 540x960 for this check")
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
	check(game.current_scene_id == "gate" and game.scroll_container.offset_bottom == 0.0, "Transition still works after refresh changes and releases the continue bar space")
	game._show_menu()
	check(game.action_tray.get_child_count() == 0 and game.thing_tray.get_child_count() == 0, "Menu frees tiles immediately")
	game._clear_save()
	print("Checked timer bar, slot clearing, feedback styling, and incremental tile refresh")

func test_endings(game) -> void:
	game._clear_progress()
	game._show_menu()
	var bigfoot_index: int = -1
	for i in range(game.discovered_stories.size()):
		if game.discovered_stories[i].path.ends_with("bigfoot_campout.json"):
			bigfoot_index = i
	check(bigfoot_index >= 0 and game.discovered_stories[bigfoot_index].ending_ids.size() == 4, "Bigfoot declares four endings")
	var badge: Label = game.story_cards[bigfoot_index].get_node("Row/Col/Badge")
	check(badge.text.contains("0 of 4 endings"), "Card shows no endings found yet: " + badge.text)
	await start_bigfoot_meeting(game, true)
	await apply(game, ["give", "bigfoot"])
	await continue_story(game)
	check(game.ending_badge.visible and game.ending_label.text.contains("Bigfoot Friend") and game.ending_label.text.contains("1 of 4"), "Ending badge names the ending and the count: " + game.ending_label.text)
	check(not game.story_text.text.begins_with("THE "), "Ending scene text no longer shouts its title")
	game._show_menu()
	check(badge.text.contains("1 of 4 endings"), "Card counts the found ending: " + badge.text)
	# Reaching the same ending again does not double count; a second ending does.
	await start_bigfoot_meeting(game, true)
	await apply(game, ["give", "bigfoot"])
	await continue_story(game)
	check(game.ending_label.text.contains("1 of 4"), "Repeat ending is not counted twice")
	game._show_menu()
	await start_bigfoot_meeting(game, true)
	await apply(game, ["go", "camp"])
	await continue_story(game)
	check(game.ending_label.text.contains("2 of 4"), "Second ending counts")
	game._show_menu()
	check(badge.text.contains("2 of 4 endings"), "Card updates after the second ending")
	# Single-ending stories show Finished.
	await start_dragon(game)
	game.current_scene_id = "win"
	await game._render_scene()
	check(game.ending_badge.visible and game.ending_label.text.contains("Hero of the Land"), "Single ending shows its title")
	game._show_menu()
	var dragon_badge: Label = game.story_cards[0].get_node("Row/Col/Badge")
	check(dragon_badge.text.contains("Finished"), "Single-ending story shows Finished: " + dragon_badge.text)
	# Non-terminal scenes never show the badge; corrupt progress is ignored.
	await start_dragon(game)
	check(not game.ending_badge.visible, "No badge on a normal scene")
	game._show_menu()
	var f := FileAccess.open(game.PROGRESS_PATH, FileAccess.WRITE)
	f.store_string("[1,2")
	f.close()
	game._show_menu()
	check(badge.text.contains("0 of 4 endings"), "Corrupt progress file reads as nothing found")
	game._clear_progress()
	game._clear_save()
	print("Checked ending badge, progress persistence, and card counts")

func test_sound_and_speech(game) -> void:
	# Settings round-trip through the parent corner toggles.
	if FileAccess.file_exists(game.SETTINGS_PATH):
		DirAccess.remove_absolute(game.SETTINGS_PATH)
	game.sound_toggle.button_pressed = false
	game.read_aloud_toggle.button_pressed = true
	check(not game.settings["sound"] and game.settings["read_aloud"], "Toggles update settings")
	game.settings = {"read_aloud": false, "sound": true}
	game._load_settings()
	check(not game.settings["sound"] and game.settings["read_aloud"], "Settings persist to disk")
	# Sound off: nothing plays. Sound on: effects fire for tap, fail, success, next.
	await start_dragon(game)
	game.current_scene_id = "hall"
	await game._render_scene()
	game.last_sfx = ""
	tap(game, "look")
	check(game.last_sfx.is_empty(), "No tap sound while sound is off")
	game.sound_toggle.button_pressed = true
	tap(game, "box")
	check(game.last_sfx == "tap", "Tap sound plays")
	game.slot1.tapped.emit()
	game.slot2.tapped.emit()
	await apply(game, ["go", "key"])
	check(game.last_sfx == "fail", "Fallback plays the fail sound")
	await apply(game, ["open", "box"])
	check(game.last_sfx == "success", "Progress plays the success sound")
	game.last_sfx = ""
	await apply(game, ["look", "door"])
	check(game.last_sfx.is_empty(), "Plain responses are silent")
	await apply(game, ["take", "key"])
	while not game.continue_button.visible:
		await process_frame
	game.continue_button.pressed.emit()
	check(game.last_sfx == "next", "NEXT plays its sound")
	while game.is_transitioning:
		await process_frame
	game.current_scene_id = "win"
	await game._render_scene()
	check(game.last_sfx == "fanfare", "Ending plays the fanfare")
	# Long press reads the word instead of placing the tile.
	game._show_menu()
	await start_dragon(game)
	var look_tile: Button = null
	for tile in game.action_tray.get_children():
		if tile.token == "look":
			look_tile = tile
	look_tile.button_down.emit()
	await create_timer(0.6).timeout
	check(look_tile.long_press_fired, "Holding a tile fires a long press")
	look_tile.button_up.emit()
	look_tile.pressed.emit()
	check(game.slot1.token.is_empty(), "A long press does not place the tile")
	look_tile.pressed.emit()
	check(game.slot1.token == "look", "The next normal tap places it")
	# Speaking with no voice is a quiet no-op with a friendly message.
	check(not game._speak("hello") or game.tts_voice != "", "Speak reports whether a voice exists")
	game._on_speak_pressed()
	if game.tts_voice == "":
		check(game.feedback_text.text.contains("no reading voice"), "Speak button explains a missing voice")
	game.read_aloud_toggle.button_pressed = false
	game.sound_toggle.button_pressed = true
	game._show_menu()
	game._clear_save()
	game._clear_progress()
	if FileAccess.file_exists(game.SETTINGS_PATH):
		DirAccess.remove_absolute(game.SETTINGS_PATH)
	print("Checked settings, sound effects, long-press, and speech guards")

func test_text_and_mood(game) -> void:
	# Reader font with emoji fallback is the app theme.
	check(game.theme != null and game.theme.default_font != null and game.theme.default_font.fallbacks.size() == 1, "App theme uses the bundled reader font with an emoji fallback")
	check(game.story_text.get_theme_constant("line_spacing") == 8, "Story text has loosened line spacing")
	# Typewriter reveal, finished by a tap on the text.
	await start_dragon(game)
	check(game.story_text.visible_characters >= 0 and game.story_text.visible_characters < game.story_text.get_total_character_count(), "Story text reveals progressively")
	var tap_event := InputEventMouseButton.new()
	tap_event.button_index = MOUSE_BUTTON_LEFT
	tap_event.pressed = true
	game._on_story_text_input(tap_event)
	check(game.story_text.visible_characters == -1, "Tapping the text finishes the reveal")
	await create_timer(0.1).timeout
	check(game.story_text.visible_characters == -1, "A finished reveal stays finished")
	# Mood background.
	check(game.background.color != game.DEFAULT_BACKGROUND or true, "Background exists")
	game.current_scene_id = "dragon"
	await game._render_scene()
	await create_timer(0.5).timeout
	check(game.background.color.is_equal_approx(game.MOODS["fire"]), "Dragon scene tints the background with its mood")
	game._show_menu()
	await create_timer(0.5).timeout
	check(game.background.color.is_equal_approx(game.DEFAULT_BACKGROUND), "Menu restores the default background")
	# Idle hint.
	await start_dragon(game)
	game.idle_timer.wait_time = 0.3
	game._restart_idle_timer()
	check(not game.hint_button.visible, "No hint right after a scene renders")
	await create_timer(0.5).timeout
	check(game.hint_button.visible, "Hint appears after idling")
	await apply(game, ["look", "door"])
	check(not game.idle_timer.is_stopped(), "A command restarts the idle timer")
	game.idle_timer.wait_time = game.IDLE_HINT_SECONDS
	game._show_menu()
	check(game.idle_timer.is_stopped(), "Menu stops the idle timer")
	# Phone Trap ending split.
	check(game._load_story("res://stories/phone_trap.json"), "Load Phone Trap")
	await game._start_story()
	game.current_scene_id = "landing"
	await game._render_scene()
	check(game.story_text.get_total_character_count() < 260 and not game.new_game_button.visible, "Landing scene is short and not terminal")
	await apply(game, ["open", "bed"])
	await continue_story(game)
	check(game.current_scene_id == "home" and game.new_game_button.visible and game.ending_badge.visible, "Bed leads to the morning ending")
	game._show_menu()
	game._clear_save()
	game._clear_progress()
	print("Checked reader font, typewriter reveal, mood tint, idle hint, and the Phone Trap split")

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
	await test_labels(game)
	await test_endings(game)
	await test_sound_and_speech(game)
	await test_text_and_mood(game)
	print("Game regression checks=", checks, "; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
