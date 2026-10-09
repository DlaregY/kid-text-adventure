extends RefCounted
# Focused desktop captures for this content batch; no independent player-data access.
func run(suite, game) -> void:
	game._show_menu()
	suite.check(game._load_story("res://stories/spider_hero.json"), "Load library capture")
	await game._start_story()
	game.current_scene_id = "library"
	game.inventory = {"note": true, "web": true, "key": true}
	await game._render_scene()
	game._finish_reveal()
	game.hint_index = 2
	game._on_hint_pressed()
	await suite.shot("13_library_final_hint")

	game._show_menu()
	suite.check(game._load_story("res://stories/phone_trap.json"), "Load bed capture")
	await game._start_story()
	game.current_scene_id = "landing"
	await game._render_scene()
	game._finish_reveal()
	await suite.shot("14_phone_landing")
	game.scroll_container.scroll_vertical = 100000
	await suite.settle()
	var bed_tile: Control = null
	for tile in game.thing_tray.get_children():
		if tile.token == "bed":
			bed_tile = tile
	suite.check(bed_tile != null, "Bed tile exists in the thing tray")
	if bed_tile != null:
		suite.check(game.scroll_container.get_global_rect().encloses(bed_tile.get_global_rect()), "Scrolling reveals the whole bed tile")
	await suite.shot("14a_phone_bed_choices")
	game.scroll_container.scroll_vertical = 0
	suite.tap(game, "go"); suite.tap(game, "bed")
	while not game.continue_button.visible:
		await suite.process_frame
	suite.check(game.pending_scene_id == "home", "Captured GO BED reaches home")
	await suite.shot("15_phone_go_bed")
	game.continue_button.pressed.emit()
	while game.is_transitioning:
		await suite.process_frame

	game._show_menu()
	suite.check(game._load_story("res://stories/bigfoot_campout.json"), "Load Bigfoot choices capture")
	await game._start_story()
	game.current_scene_id = "bigfoot_meeting"
	game.inventory = {"lantern": true, "snack": true, "camera": true, "pinecone": true, "berries": true}
	await game._render_scene()
	game._finish_reveal()
	await suite.shot("16_bigfoot_meeting")
	game.scroll_container.scroll_vertical = 100000
	await suite.shot("17_bigfoot_choices")
	game.scroll_container.scroll_vertical = 0
	var talk: Array[String] = ["talk", "bigfoot"]
	for i in range(3):
		await game._apply_command(talk)
	suite.check(game.current_scene_id == "bigfoot_meeting" and not game.is_transitioning, "Captured repeated chat stays in the meeting")
	await suite.shot("18_bigfoot_chat")
	var look: Array[String] = ["look", "joke"]
	await game._apply_command(look)
	await suite.shot("19_bigfoot_goodbye_choice")
	var joke: Array[String] = ["tell", "joke"]
	await game._apply_command(joke)
	while not game.continue_button.visible:
		await suite.process_frame
	game.continue_button.pressed.emit()
	while game.is_transitioning:
		await suite.process_frame
	game._finish_reveal()
	suite.check(game.current_scene_id == "ending_goofy", "Explicit goodbye capture reaches goofy ending")
	await suite.shot("20_bigfoot_goofy_ending")
	game._show_menu()
	suite.check(not game.ending_badge.visible, "Bigfoot ending does not leak into the menu")
	await suite.shot("21_bigfoot_menu")
	game._clear_save()
	game._clear_progress()
