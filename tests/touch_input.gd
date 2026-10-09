extends SceneTree

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	if not preload("res://tests/qa_guard.gd").enter():
		quit(2)
		return
	Input.emulate_touch_from_mouse = true
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: ", message)

func settle() -> void:
	for i in range(8):
		await process_frame

func motion(pos: Vector2, relative: Vector2, down := false) -> void:
	var e := InputEventMouseMotion.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = pos
	e.global_position = pos
	e.relative = relative
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(e, true)

func button(pos: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.device = InputEvent.DEVICE_ID_EMULATION
	e.position = pos
	e.global_position = pos
	e.button_index = MOUSE_BUTTON_LEFT
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	e.pressed = down
	root.push_input(e, true)

func swipe(pos: Vector2, delta: Vector2) -> void:
	motion(pos, Vector2.ZERO)
	button(pos, true)
	await process_frame
	for i in range(1, 11):
		motion(pos + delta * float(i) / 10.0, delta / 10.0, true)
		await create_timer(0.02).timeout
	button(pos + delta, false)
	await create_timer(0.5).timeout
	if root.gui_is_dragging():
		root.gui_cancel_drag()

func finger(pos: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = down
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func finger_move(pos: Vector2, delta: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = pos
	e.relative = delta
	Input.parse_input_event(e)
	Input.flush_buffered_events()

func click_at(pos: Vector2) -> void:
	motion(pos, Vector2.ZERO)
	button(pos, true)
	await process_frame
	button(pos, false)
	await settle()

func tile_for(game, token: String) -> Control:
	for tray in [game.action_tray, game.thing_tray, game.inventory_tray]:
		for tile in tray.get_children():
			if tile.token == token:
				return tile
	return null

func drag_to(tile: Control, slot: Control, hold: float) -> void:
	var start := tile.get_global_rect().get_center()
	var end := slot.get_global_rect().get_center()
	motion(start, Vector2.ZERO)
	button(start, true)
	await create_timer(hold).timeout
	for i in range(1, 9):
		motion(start.lerp(end, float(i) / 8.0), (end - start) / 8.0, true)
		await process_frame
	check(root.gui_is_dragging(), "Deliberate held touch starts a tile drag")
	button(end, false)
	await settle()
	check(not root.gui_is_dragging(), "Release finishes the drag")

func run() -> void:
	create_timer(90).timeout.connect(func(): printerr("FAIL: Touch suite timed out"); quit(1))
	var game = load("res://Game.tscn").instantiate()
	root.add_child(game)
	await settle()
	print("touch available=", DisplayServer.is_touchscreen_available())
	check(DisplayServer.is_touchscreen_available(), "Native touch scrolling enabled for viewport event test")
	var card: Control = game.card_buttons[1]
	var before: int = game.selected_story_index
	await swipe(card.get_global_rect().get_center(), Vector2(0, -130))
	check(game.scroll_container.scroll_vertical > 40, "Swipe beginning on story card scrolls the picker")
	check(game.selected_story_index == before, "Swipe does not select a story")
	game.scroll_container.scroll_vertical = 0
	await settle()
	await swipe(game.menu_screen.get_node("Logo").get_global_rect().get_center(), Vector2(0, -100))
	check(game.scroll_container.scroll_vertical > 40, "Swipe beginning on portrait scrolls the picker")
	game._load_story("res://stories/bigfoot_campout.json")
	await game._start_story()
	game.current_scene_id = "bigfoot_meeting"
	game.inventory = {"lantern": true, "snack": true, "camera": true, "berries": true, "pinecone": true}
	await game._render_scene()
	game._finish_reveal()
	game.scroll_container.scroll_vertical = 0
	await settle()
	await swipe(game.story_text.get_global_rect().get_center(), Vector2(0, -100))
	check(game.scroll_container.scroll_vertical > 40, "Swipe beginning on story text scrolls the story")
	game.scroll_container.ensure_control_visible(game.action_tray)
	await settle()
	var tile: Control = game.action_tray.get_child(0)
	var offset: int = game.scroll_container.scroll_vertical
	print("tile rect=",tile.get_global_rect(), " offset=",offset," max=",game.scroll_container.get_v_scroll_bar().max_value)
	await swipe(tile.get_global_rect().get_center(), Vector2(0, 120))
	check(game.scroll_container.scroll_vertical < offset - 30, "Swipe beginning on tile scrolls, not drags")
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "Swipe does not place a tile")
	# A raw ScreenTouch/ScreenDrag stream exercises Godot's touch-to-mouse bridge.
	game._show_menu()
	game.scroll_container.scroll_vertical = 0
	await settle()
	var point: Vector2 = game.card_buttons[1].get_global_rect().get_center()
	var selected: int = game.selected_story_index
	finger(point, true)
	await process_frame
	for i in range(1, 9):
		finger_move(point + Vector2(0, -20 * i), Vector2(0, -20))
		await create_timer(0.02).timeout
	finger(point + Vector2(0, -160), false)
	await create_timer(0.5).timeout
	check(game.scroll_container.scroll_vertical > 40, "Raw finger events scroll through the actual input bridge")
	check(game.selected_story_index == selected, "Raw finger swipe does not select a card")

	# Reach the last story and come back, swiping on cards rather than blank margins.
	for direction in [-1, 1]:
		for n in range(8):
			var view: Rect2 = game.scroll_container.get_global_rect()
			var visible_card: Control = null
			for c in game.card_buttons:
				var overlap: Rect2 = c.get_global_rect().intersection(view)
				if overlap.size.y > 60:
					visible_card = c
			if visible_card == null:
				break
			var hit: Rect2 = visible_card.get_global_rect().intersection(view)
			await swipe(hit.get_center(), Vector2(0, 180 * direction))
		var bar: VScrollBar = game.scroll_container.get_v_scroll_bar()
		if direction == -1:
			check(game.scroll_container.scroll_vertical >= bar.max_value - bar.page - 2, "Repeated card swipes reach the last story and Parent corner")
		else:
			check(game.scroll_container.scroll_vertical <= 2, "Reverse swipes return to the top")
		check(game.selected_story_index == selected, "Scrolling the list never changes the selected story")
	await click_at(game.card_buttons[1].get_global_rect().get_center())
	check(game.selected_story_index == 1, "A real tap still selects a story after scrolling")

	game._load_story("res://stories/dragon_egg.json")
	await game._start_story()
	game._finish_reveal()
	await settle()
	var look: Control = tile_for(game, "look")
	var door: Control = tile_for(game, "door")
	await drag_to(look, game.slot1, 0.4)
	check(game.slot1.token == "look" and game.slot2.token.is_empty(), "Held action drop fills only the first slot")
	game.slot1.clear()
	await drag_to(look, game.slot2, 0.4)
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "Action cannot be dropped into the thing slot")
	await drag_to(door, game.slot1, 0.4)
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "An ordinary thing cannot be dropped into the action/item slot")
	await click_at(look.get_global_rect().get_center())
	check(game.slot1.token == "look", "A tap selects without needing a hold")
	var slot_point: Vector2 = game.slot1.get_global_rect().get_center()
	await click_at(slot_point)
	check(game.slot1.token.is_empty(), "A tap on a filled slot still clears it on release")

	# Full inventory scene: swipe on a slot must not clear it, and swiping/pause
	# on a tile must never turn the already-started scroll into a late drag.
	game._load_story("res://stories/bigfoot_campout.json")
	await game._start_story()
	game.current_scene_id = "bigfoot_meeting"
	game.inventory = {"lantern": true, "snack": true, "camera": true, "berries": true, "pinecone": true}
	await game._render_scene()
	game._finish_reveal()
	game.scroll_container.ensure_control_visible(game.slot1)
	await settle()
	game.slot1.set_tile("look", "look")
	var old_scroll: int = game.scroll_container.scroll_vertical
	await swipe(game.slot1.get_global_rect().get_center(), Vector2(0, -90))
	check(game.scroll_container.scroll_vertical > old_scroll + 25 and game.slot1.token == "look", "Swipe on a filled command slot scrolls without clearing it")
	game.slot1.clear()
	game.scroll_container.ensure_control_visible(game.action_tray)
	await settle()
	point = game.action_tray.get_child(0).get_global_rect().get_center()
	motion(point, Vector2.ZERO)
	button(point, true)
	motion(point + Vector2(0, -35), Vector2(0, -35), true)
	await create_timer(0.5).timeout
	motion(point + Vector2(0, -80), Vector2(0, -45), true)
	check(not root.gui_is_dragging(), "Pausing during a swipe does not arm a late tile drag")
	button(point + Vector2(0, -80), false)
	await create_timer(0.5).timeout
	check(game.slot1.token.is_empty() and game.slot2.token.is_empty(), "Swipe/pause places no command")

	# Roles are recomputed from game state, including forged/stale payloads.
	for data in [{"token": "go", "category": "thing"}, {"token": "not_here", "category": "inventory"}]:
		check(not game.slot2._can_drop_data(Vector2.ZERO, data), "Thing slot rejects action/unavailable token despite claimed category")
		game.slot2._drop_data(Vector2.ZERO, data)
		check(game.slot2.token.is_empty(), "Rejected drop leaves slot untouched")
	check(not game.slot1._can_drop_data(Vector2.ZERO, {"token": "bigfoot", "category": "inventory"}), "First slot rejects a disguised ordinary thing")
	for slot in [game.slot1, game.slot2]:
		check(slot._can_drop_data(Vector2.ZERO, {"token": "camera"}), "Collected camera works in either slot")
		check(slot._can_drop_data(Vector2.ZERO, {"token": "snack"}), "Collected snack works in either slot")
	game.slot1._drop_data(Vector2.ZERO, {"token": "camera", "label": "wrong label", "category": "thing"})
	check(game.slot1.token == "camera" and game.slot1.label.text == game._tile_text("camera"), "Drop display comes from the current vocabulary, not payload")
	game.slot2._drop_data(Vector2.ZERO, {"token": "bigfoot"})
	await create_timer(0.7).timeout
	check(game.pending_scene_id == "ending_photo", "CAMERA BIGFOOT retains the existing item-first ending")
	game._show_menu()
	game._clear_save()
	game._clear_progress()
	game.queue_free()
	await process_frame
	print("Touch assertions=", checks)
	print("Touch input suite completed; failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
