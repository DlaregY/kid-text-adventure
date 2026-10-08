extends SceneTree
# Walks the UI and saves PNGs for visual review. Needs a display (real or Xvfb):
#   LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a -s "-screen 0 540x960x24" godot4 --path . \
#     --rendering-method gl_compatibility --rendering-driver opengl3 --resolution 540x960 \
#     --script res://tests/screenshots.gd
# Output dir: $IKE_SHOTS_DIR or exports/shots/ (git-ignored).
var out_dir: String = OS.get_environment("IKE_SHOTS_DIR")
func _initialize() -> void: call_deferred("run")
func settle(n: int = 6) -> void:
	for i in range(n): await process_frame
func shot(name: String) -> void:
	await settle(3)
	var img: Image = root.get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)
func tap(game, token: String) -> void:
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			if tile.token == token:
				game._on_tile_pressed(tile); return
func run() -> void:
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("res://exports/shots")
	DirAccess.make_dir_recursive_absolute(out_dir)
	root.size = Vector2i(540, 960)
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	game._clear_save()
	game._show_menu()
	await settle(10)
	await shot("1_menu")
	game.about_button.pressed.emit()
	await shot("2_about")
	game.about_close.pressed.emit()
	game.card_buttons[2].pressed.emit()
	game._on_start_pressed()
	await settle(12)
	await shot("3_bigfoot_camp")
	tap(game, "look"); tap(game, "bushes")
	await create_timer(0.25).timeout
	await shot("4_debounce_timer_bar")
	await create_timer(0.5).timeout
	await shot("5_success_flag")
	tap(game, "go"); tap(game, "tent")
	await create_timer(0.8).timeout
	await shot("6_fallback_fail")
	tap(game, "take"); tap(game, "snack")
	await create_timer(0.8).timeout
	await shot("7_inventory")
	game.home_button.pressed.emit()
	await shot("8_stop_dialog")
	game.stop_menu_button.pressed.emit()
	await settle(10)
	await shot("9_menu_continue")
	game._clear_save()
	quit(0)
