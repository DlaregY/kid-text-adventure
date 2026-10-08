extends RefCounted
# Regression checks for M04, the menu portion of M06, and N07.
func run(suite, game) -> void:
	game._clear_save()
	game._clear_progress()
	game._show_menu()
	await suite.start_dragon(game)
	game.current_scene_id = "hall"
	await game._render_scene()
	var open_box: Array[String] = ["open", "box"]
	await suite.apply(game, open_box)
	game._record_ending(game.loaded_story_path, "win")
	game._save_settings()
	var saved := FileAccess.get_file_as_string(game.SAVE_PATH)
	var progress := FileAccess.get_file_as_string(game.PROGRESS_PATH)
	var settings := FileAccess.get_file_as_string(game.SETTINGS_PATH)
	game._show_menu()
	var dragon_path: String = game.loaded_story_path
	var new_path: String = game.discovered_stories[1].path
	var new_title: String = game.discovered_stories[1].display_name
	suite.check(game.resume_button.text.contains("The Lost Dragon Egg"), "CONTINUE names the saved story")
	suite.check(game.play_button.text == "START NEW", "Fresh start is explicit")
	game.card_buttons[1].pressed.emit()
	game.play_button.pressed.emit()
	suite.check(game.new_story_dialog.visible and not game.has_active_story, "Different story requires confirmation")
	suite.check(game.loaded_story_path == dragon_path and FileAccess.get_file_as_string(game.SAVE_PATH) == saved, "Opening confirmation does not load or overwrite")
	var message: Label = game.new_story_dialog.get_node("Center/Panel/Box/Message")
	suite.check(message.text.contains(new_title) and message.text.contains("The Lost Dragon Egg"), "Confirmation names both stories")
	var keep: Button = game.new_story_dialog.get_node("Center/Panel/Box/KeepSave")
	suite.check(keep.has_focus(), "Safe option has default focus")
	game.card_buttons[2].pressed.emit()
	game.about_button.pressed.emit()
	game.resume_button.pressed.emit()
	game.play_button.pressed.emit()
	suite.check(game.selected_story_path == new_path and game.pending_new_story_path == new_path and not game.about_dialog.visible and not game.has_active_story, "Underlying menu actions are blocked")
	await suite.settle()
	var panel: Control = game.new_story_dialog.get_node("Center/Panel")
	var bounds: Rect2 = panel.get_global_rect()
	suite.check(bounds.position.x >= 0 and bounds.end.x <= suite.root.size.x and bounds.position.y >= 0 and bounds.end.y <= suite.root.size.y, "Replacement dialog fits the test viewport")
	keep.pressed.emit()
	suite.check(not game.new_story_dialog.visible and game.pending_new_story_path.is_empty() and FileAccess.get_file_as_string(game.SAVE_PATH) == saved, "KEEP preserves the complete checkpoint")
	game._confirm_new_story()
	suite.check(not game.has_active_story, "Late confirmation after cancel does nothing")
	game.play_button.pressed.emit()
	game._notification(game.NOTIFICATION_WM_GO_BACK_REQUEST)
	suite.check(not game.new_story_dialog.visible and FileAccess.get_file_as_string(game.SAVE_PATH) == saved, "Android Back cancels without overwriting")
	game.resume_button.pressed.emit()
	await suite.settle()
	suite.check(game.loaded_story_path == dragon_path and game.current_scene_id == "hall" and game.flags.get("box_open", false), "Resume restores original story and flags after cancellation")
	game._show_menu()
	game.play_button.pressed.emit()
	suite.check(game.new_story_dialog.visible, "Same-story restart also asks")
	game._cancel_new_story()
	game.card_buttons[1].pressed.emit()
	game.play_button.pressed.emit()
	# Even a programmatic selection change must not change the captured request.
	game._set_selected_story(2)
	var confirm: Button = game.new_story_dialog.get_node("Center/Panel/Box/StartNew")
	confirm.pressed.emit()
	await suite.settle()
	suite.check(game.loaded_story_path == new_path and game._read_save().story_path == new_path, "Confirm starts the story named in the dialog")
	suite.check(FileAccess.get_file_as_string(game.PROGRESS_PATH) == progress and FileAccess.get_file_as_string(game.SETTINGS_PATH) == settings, "Restart preserves endings and preferences")
	game._show_menu()
	game._clear_save()
	game.play_button.pressed.emit()
	await suite.settle()
	suite.check(game.has_active_story and not game.new_story_dialog.visible, "No-save start needs no confirmation")
	game._show_menu()

	# Test every ending's menu cleanup, not just the friend ending.
	for entry in game.discovered_stories:
		suite.check(game._load_story(entry.path), "Load for ending cleanup: " + entry.path)
		for scene_id in game.scenes:
			if not game.scenes[scene_id].has("ending"):
				continue
			await game._start_story()
			game.current_scene_id = scene_id
			await game._render_scene()
			suite.check(game.ending_badge.visible, "Ending badge shown: " + scene_id)
			game._show_menu()
			suite.check(not game.ending_badge.visible and game.ending_label.text.is_empty(), "Menu removes ending UI: " + scene_id)

	await suite.start_dragon(game)
	game.slot1.set_tile("look", "look")
	var payload := {"token": "take", "label": "take"}
	for state in ["dialog", "transition", "executing", "menu"]:
		game.stop_dialog.visible = state == "dialog"
		game.is_transitioning = state == "transition"
		game.is_executing_command = state == "executing"
		game.has_active_story = state != "menu"
		suite.check(not game.slot1._can_drop_data(Vector2.ZERO, payload), "Blocked drop hover: " + state)
		game.slot1._drop_data(Vector2.ZERO, payload)
		suite.check(game.slot1.token == "look" and game.slot1.label.text == "look" and game.command_timer.is_stopped(), "Blocked drop leaves input unchanged: " + state)
	game.stop_dialog.visible = false
	game.is_transitioning = false
	game.is_executing_command = false
	game.has_active_story = true
	for invalid in [null, {}, {"token": ""}, {"token": 42}]:
		game.slot1._drop_data(Vector2.ZERO, invalid)
		suite.check(game.slot1.token == "look", "Malformed drop ignored")
	game.slot1.clear()
	var tile = game.action_tray.get_child(0)
	var holds: Array = []
	tile.long_pressed.connect(func() -> void: holds.append(true))
	tile.button_down.emit()
	# set_drag_preview requires an active viewport drag; a direct virtual call alone is invalid.
	tile.force_drag({"token": tile.token, "label": tile.text}, null)
	suite.check(suite.root.gui_is_dragging(), "Drag test owns a real viewport drag")
	tile._get_drag_data(Vector2.ZERO)
	await suite.create_timer(0.6).timeout
	suite.check(holds.is_empty() and tile._hold_timer.is_stopped(), "Drag cancels long-press speech")
	suite.root.gui_cancel_drag()
	await suite.process_frame
	suite.check(not suite.root.gui_is_dragging(), "Drag preview is released on cancellation")
	tile.button_up.emit()
	tile.pressed.emit()
	suite.check(game.slot1.token.is_empty(), "Drag release does not place a second tile")
	tile.button_down.emit()
	tile.button_up.emit()
	tile.pressed.emit()
	suite.check(game.slot1.token == tile.token, "Next ordinary press still places a tile")
	game.slot1.clear()
	game.slot2.clear()
	game._reset_hints()
	game.idle_timer.wait_time = 0.2
	game._restart_idle_timer()
	game._show_stop_dialog()
	await suite.create_timer(0.3).timeout
	suite.check(not game.hint_button.visible and game.idle_timer.is_stopped(), "Stop suspends idle help")
	game._hide_stop_dialog()
	await suite.create_timer(0.3).timeout
	suite.check(game.hint_button.visible, "Idle help resumes after KEEP PLAYING without another command")
	game.idle_timer.wait_time = game.IDLE_HINT_SECONDS
	game._show_menu()
	game._clear_save()
	game._clear_progress()
	print("Checked save replacement, ending cleanup, blocked drops, drag holds, and idle help")
