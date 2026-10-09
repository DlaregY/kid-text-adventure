extends RefCounted
# Static rendering fixtures are independently checked against reachable paths in Python.
func run(suite, game) -> bool:
	var f := FileAccess.open("res://tests/original_states.json", FileAccess.READ)
	if f == null:
		suite.check(false, "Original capture fixtures are available")
		return false
	var fixtures: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	game._show_menu()
	suite.check(game._load_story("res://stories/spider_hero.json"), "Load original story for captures")
	await game._start_story()
	for sid in fixtures:
		var fixture: Dictionary = fixtures[sid]
		game.current_scene_id = sid
		game.inventory.clear()
		for token in fixture.inventory:
			game.inventory[str(token)] = true
		game.flags = fixture.flags.duplicate()
		await game._render_scene()
		game._finish_reveal()
		await suite.shot("original_" + sid)
		if game.layout.size.y > game.scroll_container.size.y:
			game.scroll_container.scroll_vertical = 100000
			await suite.shot("original_" + sid + "_choices")
	game._show_menu()
	game._clear_save()
	game._clear_progress()
	return true
