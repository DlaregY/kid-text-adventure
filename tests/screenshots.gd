extends SceneTree
# Use python3 tests/run_checks.py --suite screenshots (requires a display or Xvfb).
# Captures are desktop QA evidence, not Android store screenshots.
var out_dir: String = OS.get_environment("IKE_SHOTS_DIR")
var failures: Array[String] = []
func _initialize() -> void:
	if not preload("res://tests/qa_guard.gd").enter():
		quit(2)
		return
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FAIL: ", message)
func settle(n: int = 6) -> void:
	for i in range(n): await process_frame
func shot(name: String) -> void:
	await settle(3)
	var img: Image = root.get_viewport().get_texture().get_image()
	check(img.save_png(out_dir.path_join(name + ".png")) == OK, "Save screenshot " + name)
	print("saved ", name)
func tap(game, token: String) -> void:
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			if tile.token == token:
				game._on_tile_pressed(tile)
				return
	check(false, "Missing screenshot input tile: " + token)
func run() -> void:
	create_timer(120).timeout.connect(func() -> void:
		printerr("FAIL: Screenshot suite timed out")
		quit(1)
	)
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://exports/shots")
	check(DirAccess.make_dir_recursive_absolute(out_dir) == OK, "Create screenshot directory")
	root.size = Vector2i(540, 960)
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game._clear_save()
	game._clear_progress()
	game._show_menu()
	await settle(10)
	await shot("1_menu")
	game.about_button.pressed.emit()
	await shot("2_about")
	game.about_close.pressed.emit()
	game.card_buttons[2].pressed.emit()
	game._on_start_pressed()
	await settle(12)
	game._finish_reveal()
	await shot("3_bigfoot_camp")
	tap(game, "look"); tap(game, "bushes")
	await create_timer(0.25).timeout
	await shot("4_debounce_timer_bar")
	await create_timer(0.5).timeout
	await shot("5_success_flag")
	tap(game, "go"); tap(game, "snack")
	await create_timer(0.8).timeout
	check(not game.feedback_text.text.is_empty() and game.feedback_text.get_theme_color("font_color") == game.FEEDBACK_FAIL, "Failed-command capture contains an actual fallback")
	await shot("6_fallback_fail")
	tap(game, "take"); tap(game, "snack")
	await create_timer(0.8).timeout
	await shot("7_inventory")
	game.home_button.pressed.emit()
	await shot("8_stop_dialog")
	game.stop_menu_button.pressed.emit()
	await settle(10)
	await shot("9_menu_continue")
	game.card_buttons[0].pressed.emit()
	game.play_button.pressed.emit()
	check(game.new_story_dialog.visible, "Replacement confirmation opens")
	await shot("9a_replace_save")
	game._cancel_new_story()
	game._clear_save()
	game._clear_progress()
	game._show_menu()
	game.card_buttons[2].pressed.emit()
	game._on_start_pressed()
	await settle(8)
	game.current_scene_id = "bigfoot_meeting"
	game.inventory["snack"] = true
	await game._render_scene()
	game._finish_reveal()
	var give: Array[String] = ["give", "bigfoot"]
	await game._apply_command(give)
	while not game.continue_button.visible:
		await process_frame
	await shot("10_transition_continue")
	game.continue_button.pressed.emit()
	while game.is_transitioning:
		await process_frame
	await settle(8)
	game._finish_reveal()
	await shot("11_ending_badge")
	game._show_menu()
	await settle(8)
	check(not game.ending_badge.visible, "Menu capture has no leftover ending badge")
	await shot("12_menu_endings")
	game._clear_progress()
	print("Screenshot checks; failures=", failures.size())
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
