extends Node2D

# The Waiting Room is a small floor of departments, built from the same rooms, doors and camera as the
# run floors, with nothing to fight. What stands in each department comes from Departments.

const FLOOR_DEF_PATH := "res://data/floors/waiting_room.tres"
const KEY_BOARD := "key_board"
const CRAFTER := "crafter"
const TROPHY_WALL := "trophy_wall"
const FORMS_COUNTER := "forms_counter"
const BOUNTY_BOARD := "bounty_board"
const DEPUTY_DOLORES := "deputy_dolores"
const ITEM_RACK := "item_rack"
const COACH_BERTRAM := "coach_bertram"
const DECOR_COUNTER := "decor_counter"
const TICKET_MACHINE := "ticket_machine"
const NOTICEBOARD := "noticeboard"
const EMPLOYEE_PLAQUE := "employee_plaque"
const MERCHANT_PROMPT := "Trade"
const RUN_DOOR_ICON := ">"
# A number that is not called shows the old 666 on the lobby's ticket line.
const NOT_CALLED := LobbyText.NOT_CALLED

var player: Player
var _hud: Hud
var _camera: Camera2D
var _map: FloorMap
var _progress: FloorProgress
var _floor_def: FloorDef
# The Waiting Room's own run, which only Grandpa's stats here and the Training Yard use. Items tried in
# the yard can never reach a real run: Game.begin_run() changes scene, and floor_scene makes a fresh run.
var _run: RunState
var _rng := RandomNumberGenerator.new()
var _room_view: RoomView
var _current_id := -1
# Each department's RoomView, kept while the scene lives, made on first entry.
var _views := {}
# Every station made so far, by id.
var _stations := {}
var _open_merchants: Array = []
# Every department NPC made so far, by Departments.NPCS id.
var _npcs := {}
# The Bounty Office's cork board, once that department has been entered.
var _poster_board: PosterBoard
# The moment Deputy Dolores speaks to once the bounty panel closes, or "".
var _dolores_next := ""
# The lobby's decor, rebuilt whenever a panel closes, since the Decor Office may have sold some.
var _lobby_decor: LobbyDecor
var _panel: CanvasLayer
# The frame a panel last closed on, so the press that closed it never opens it again at once.
var _panel_closed_frame := -1
# Arrival lines still to show, one every Hud.NOTICE_TIME.
var _notices: Array[String] = []
var _notice_wait := 0.0
# The lobby's ticket line and DEV hint, on the HUD's layer so the camera never scrolls them away.
var _lobby_text: LobbyText


func _ready() -> void:
	_rng.randomize()
	_floor_def = load(FLOOR_DEF_PATH)
	_open_merchants = MerchantRules.open_ones(Departments.MERCHANTS, Progress.data)
	_run = Progress.make_run()
	player = Player.new()
	player.setup(_run)
	player.mouse_aim = Settings.game("mouse_aim")
	Settings.changed.connect(_apply_game_settings)
	add_child(player)
	Input.mouse_mode = Settings.cursor_mode(false)
	player.add_child(Lighting.make_light(Color(1.0, 0.85, 0.6), 0.7, 0.8))
	_map = Departments.build_map(Departments.load_layouts())
	_progress = FloorProgress.new(_map)
	_camera = Camera2D.new()
	add_child(_camera)
	_hud = Hud.new()
	_hud.setup(null)
	_hud.show_condolences = true
	add_child(_hud)
	_hud.set_pension(Progress.data.pension)
	Progress.pension_changed.connect(_hud.set_pension)
	_hud.set_condolences(Progress.data.condolences)
	Progress.condolences_changed.connect(_hud.set_condolences)
	_add_dev_profile_label()
	_lobby_text = LobbyText.new()
	_hud.add_child(_lobby_text)
	_enter_department(_map.start_id)
	player.global_position = Player.arrival_position(Departments.RUN_DOOR_CELL + Vector2i.LEFT)
	_follow_player()
	_hud.show_message(Progress.notice)
	# A save-damage notice shows first, and the news of new departments waits its turn.
	_notice_wait = Hud.NOTICE_TIME if not Progress.notice.is_empty() else 0.0
	Progress.notice = ""
	_announce_new_departments()
	_call_ticket()
	_refresh_lobby_text()
	_refresh_noticeboard()


# After the department news: the last run's ticket, if it was a called number, then any letter waiting.
func _call_ticket() -> void:
	var event := Progress.call_ticket()
	var number := Progress.data.run_count
	if event == TicketRules.CLERK_DEAL:
		_notices.append("Number %d! The clerk slips you a deal on %s." % [number, TicketPanel.form_name(Progress.data.clerk_deal, Content.upgrades())])
	elif event == TicketRules.NEW_ARRIVAL:
		var line := TicketRules.arrival_line(Departments.open_ids(Progress.data), _rng.randf())
		if not line.is_empty():
			_notices.append(line)
	elif event == TicketRules.CURSED_OFFER:
		_notices.append("Number %d! A cursed ticket is on offer at the machine." % number)
	if not LetterBook.unread(Progress.data).is_empty():
		_notices.append("A letter has arrived on the noticeboard.")


# The noticeboard says NEW while any letter waits unread.
func _refresh_noticeboard() -> void:
	var board := station(NOTICEBOARD)
	if board != null:
		board.badge = NoticeboardPanel.NEW_MARK if not LetterBook.unread(Progress.data).is_empty() else ""


# The number on the lobby's sign: this visit's, once its ticket has been called and something came of
# it, or the old 666.
static func now_serving(data: ProgressData) -> int:
	return data.run_count if data.ticket_was_called() else NOT_CALLED


func _announce_new_departments() -> void:
	var opened := Departments.newly_opened(Progress.data)
	if opened.is_empty():
		return
	_notices.append_array(Departments.opening_notices(opened))
	for id in opened:
		var line: String = Departments.entry(id)["arrival"]
		if not line.is_empty():
			_notices.append(line)
	Progress.mark_departments_seen(opened)


# The Game tab's options that matter here, read again whenever Options is changed.
func _apply_game_settings() -> void:
	player.mouse_aim = Settings.game("mouse_aim")


func _process(delta: float) -> void:
	_follow_player()
	_show_queued_notices(delta)
	var nearest := _station_in_range()
	for each: WaitingStation in _stations.values():
		if is_instance_valid(each):
			each.highlighted = each == nearest and _panel == null
	if _panel == null and Engine.get_process_frames() != _panel_closed_frame and Input.is_action_just_pressed("interact"):
		if nearest != null:
			_open_station(nearest)


func _show_queued_notices(delta: float) -> void:
	_notice_wait -= delta
	if _notice_wait > 0.0 or _notices.is_empty():
		return
	_hud.show_notice(_notices.pop_front())
	_notice_wait = Hud.NOTICE_TIME


# While the dev Waiting Room's throwaway profile is on (F4), every department says so in the bottom
# right corner of the screen, clear of the lobby's dev hint on the left.
func _add_dev_profile_label() -> void:
	if not Progress.is_dev_run():
		return
	var label := LobbyText.make_label(LobbyText.PROFILE_AT, LobbyText.PROFILE_SIZE, LobbyText.DEV_COLOR)
	label.text = DevStart.PROFILE_LABEL
	_hud.add_child(label)


# Debug builds only, and never while a panel is open, since the key settings panel listens for keys.
func _unhandled_input(event: InputEvent) -> void:
	if not DevStart.is_available() or _panel != null:
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var start_depth := DevStart.depth_for_key(key.physical_keycode)
	if start_depth > 0:
		get_viewport().set_input_as_handled()
		Game.begin_dev_run(start_depth)
	elif key.physical_keycode == DevStart.WAITING_KEY:
		get_viewport().set_input_as_handled()
		Game.toggle_dev_waiting_room()


func _follow_player() -> void:
	if _camera == null or _current_id == -1:
		return
	var room_size := Vector2(_map.room(_current_id).layout.size_in_cells()) * RoomBackdrop.TILE
	_camera.position = RoomCamera.center_for(room_size, player.feet().global_position, RoomBackdrop.VIEW_SIZE)


func _enter_department(target_id: int) -> void:
	player.recall_teeth()
	var from_id := _current_id
	if _room_view != null:
		_room_view.clear_passing_effects()
		remove_child(_room_view)
	_progress.enter(target_id)
	_current_id = target_id
	MusicPlayer.play(MusicRules.waiting_room(Departments.id_of(target_id)))
	_room_view = _views.get(target_id)
	var is_new := _room_view == null
	if is_new:
		_room_view = _make_view(_map.room(target_id))
		_views[target_id] = _room_view
	add_child(_room_view)
	move_child(_room_view, 0)
	if is_new:
		_furnish(_room_view, _map.room(target_id))
	_room_view.refresh_doors()
	_set_yard_rules(Departments.id_of(target_id) == Departments.TRAINING_YARD)
	_refresh_lobby_text()
	player.global_position = Player.arrival_position(_progress.arrival_cell(target_id, from_id))
	_follow_player()


# In the Training Yard a Thermos can be thrown, from a supply topped up after every throw, and a hit from
# one costs Grandpa nothing, since he heals in full at once. Leaving by any door drops the items tried
# there and puts his Thermoses back to a run's start.
func _set_yard_rules(in_yard: bool) -> void:
	if in_yard and not player.bomb_requested.is_connected(_on_yard_bomb):
		player.bomb_requested.connect(_on_yard_bomb)
		player.hurt.connect(_on_yard_hurt)
		# Forms filed or refiled earlier in this visit count in the yard.
		_run.refresh_stats()
		_run.bombs = RunState.YARD_SUPPLY
		_run.changed.emit()
		_refresh_coach()
	elif not in_yard and player.bomb_requested.is_connected(_on_yard_bomb):
		player.bomb_requested.disconnect(_on_yard_bomb)
		player.hurt.disconnect(_on_yard_hurt)
		_run.clear_items()
		_run.bombs = RunState.STARTING_BOMBS + _run.stats.bonus_bombs
		_run.changed.emit()


func _on_yard_bomb(at: Vector2) -> void:
	_room_view.place_bomb(at)
	_run.bombs = RunState.YARD_SUPPLY
	_run.changed.emit()


func _on_rack_taken(item: ItemDef) -> void:
	if not _run.has_item(item.id):
		_run.add_item(item)
	_refresh_coach()


# The coach's lines follow what Grandpa holds, or the basics until he has been met.
func _refresh_coach() -> void:
	var coach: Variant = _npcs.get(COACH_BERTRAM)
	if is_instance_valid(coach):
		var npc := coach as Npc
		var opener := CoachTips.opener(npc.def, Progress.last_run, Progress.data.run_count)
		npc.set_lines(CoachTips.lines_for(_run.items, not Progress.data.coach_met, opener))


func _on_coach_talked(_line: String) -> void:
	Progress.mark_coach_met()


func _on_yard_hurt() -> void:
	_run.health.heal(_run.health.max_pills)


func _make_view(room: FloorRoom) -> RoomView:
	var view := RoomView.new()
	view.setup(room, _map, _floor_def, _run, player, _rng, _progress, Progress)
	view.door_entered.connect(func(id: int): _enter_department.call_deferred(id))
	view.notice.connect(_hud.show_notice)
	# Only the Back Room has card tables to ask for.
	view.arcade_game_wanted.connect(_open_card_table)
	return view


# Run once a department's view is in the tree, so its doors exist: chains the doors to closed
# departments, names every door, and puts up the department's stations.
func _furnish(view: RoomView, room: FloorRoom) -> void:
	var layout := room.layout
	var room_width := float(layout.size_in_cells().x * RoomBackdrop.TILE)
	for side: Vector2i in room.doors:
		var target_id: int = room.doors[side]
		var target := Departments.id_of(target_id)
		var is_open := Departments.is_open(target, Progress.data)
		if not is_open:
			view.chain_door(target_id)
		var sign_node := DepartmentSign.new()
		# One cell in from the door, towards the middle, so the sign never leaves the room.
		sign_node.position = RoomBackdrop.cell_center(layout.door_cell(side) - side)
		sign_node.setup(Departments.entry(target)["name"], not is_open, Departments.closed_hint(target), room_width)
		view.add_child(sign_node)
	var department := Departments.id_of(room.id)
	# Before the stations, so every station and its prompt draws over the decor.
	if department == Departments.LOBBY:
		_lobby_decor = LobbyDecor.new()
		view.add_child(_lobby_decor)
		_lobby_decor.setup(Progress.data.cosmetics_owned)
	for merchant: Dictionary in _open_merchants:
		if merchant["department"] == department:
			var entry := merchant.duplicate()
			entry["prompt"] = MERCHANT_PROMPT
			entry["is_merchant"] = true
			_add_station(view, entry)
	for entry: Dictionary in Departments.STATIONS:
		if entry["department"] == department:
			_add_station(view, entry)
	for entry: Dictionary in Departments.NPCS:
		if entry["department"] == department:
			_add_npc(view, entry)
	if department == Departments.BOUNTY_OFFICE:
		_poster_board = PosterBoard.new()
		_poster_board.position = RoomBackdrop.cell_center(Departments.station_entry(BOUNTY_BOARD)["cell"])
		view.add_child(_poster_board)
		# Under the station, so the station's prompt draws over the board.
		view.move_child(_poster_board, (_stations[BOUNTY_BOARD] as Node).get_index())
		_refresh_poster_board()
	if department == Departments.TRAINING_YARD:
		var dummy := view.spawn_fixture(load(Departments.TRAINING_DUMMY) as EnemyDef, Departments.DUMMY_CELL)
		var numbers := TrainingDummy.new()
		numbers.position = dummy.position
		view.add_child(numbers)
		numbers.watch(dummy)
	if department == Departments.BACK_ROOM:
		# The Arcade's own tables and odds. The loadout bench's cells stay plain floor.
		view.add_arcade_tables(Departments.BACK_ROOM_GAMES, load(Departments.BACK_ROOM_DEALER) as NpcDef)
	if department == Departments.LOBBY:
		_add_run_door(view)
		var wall := TrophyWall.new()
		wall.position = Vector2(Departments.TROPHY_WALL_X, Departments.TROPHY_WALL_Y)
		wall.setup(Progress.data)
		view.add_child(wall)


func _add_station(view: RoomView, entry: Dictionary) -> void:
	var made := WaitingStation.new()
	made.setup(entry, player.feet())
	made.position = RoomBackdrop.cell_center(entry["cell"])
	view.add_child(made)
	_stations[made.id] = made


func _add_npc(view: RoomView, entry: Dictionary) -> void:
	var npc := Npc.new()
	npc.setup(load(entry["def"]) as NpcDef, player, Progress.data.run_count)
	npc.position = RoomBackdrop.cell_center(entry["cell"])
	view.add_child(npc)
	_npcs[entry["id"]] = npc
	if entry["id"] == DEPUTY_DOLORES:
		npc.talked.connect(_on_dolores_talked)
	elif entry["id"] == COACH_BERTRAM:
		npc.talked.connect(_on_coach_talked)
	# The deep floors' keepers greet him with a word on the run just played, if they have one.
	if entry.get("greets", false):
		npc.say_moment(npc.def.greeting_key(Progress.last_run))


# She says her line either way, and with a poster ready to collect she opens the board's panel too.
func _on_dolores_talked(_line: String) -> void:
	if _panel != null:
		return
	for def in BountyBoard.showing(Progress.data):
		if BountyBoard.can_collect(def, Progress.data):
			_open_bounty_panel(Departments.station_entry(BOUNTY_BOARD).get("title", ""))
			return


func _open_bounty_panel(title: String) -> void:
	var bounties := BountyPanel.new()
	bounties.setup(title)
	bounties.paid.connect(_hud.show_notice)
	bounties.paid.connect(func(_text: String) -> void: _dolores_next = "paid")
	bounties.taken.connect(func(def: BountyDef) -> void: _dolores_next = "take:" + def.id)
	_show_panel(bounties)


func _refresh_poster_board() -> void:
	if not is_instance_valid(_poster_board):
		return
	var posters := BountyBoard.showing(Progress.data)
	var taken := -1
	for i in posters.size():
		if BountyBoard.is_taken(posters[i], Progress.data):
			taken = i
	_poster_board.show_posters(posters.size(), taken)


func _add_run_door(view: RoomView) -> void:
	var door := Door.new()
	door.setup(0, RUN_DOOR_ICON, player.feet())
	door.locked = false
	door.position = RoomBackdrop.cell_center(Departments.RUN_DOOR_CELL)
	door.entered.connect(func(_id: int): Game.begin_run())
	view.add_child(door)


# The nearest station in reach in the department Grandpa stands in, or null.
func _station_in_range() -> WaitingStation:
	var best: WaitingStation = null
	var best_distance := INF
	for each: WaitingStation in _stations.values():
		if not is_instance_valid(each) or each.get_parent() != _room_view or not each.is_near():
			continue
		var distance := each.distance_to_feet()
		if distance < best_distance:
			best = each
			best_distance = distance
	return best


func _open_station(opened: WaitingStation) -> void:
	var entry := opened.entry
	if entry.get("is_merchant", false):
		if entry.get("kind", "") == "potions":
			var potions := PotionPanel.new()
			potions.setup(entry["title"])
			_show_panel(potions)
		else:
			var wares := MerchantPanel.new()
			wares.setup(entry["title"], entry["id"])
			_show_panel(wares)
		return
	match opened.id:
		KEY_BOARD:
			var options := OptionsPanel.new()
			options.setup(GameSettings.INPUT)
			_show_panel(options)
		CRAFTER:
			var craft := CraftPanel.new()
			craft.setup(opened.title)
			_show_panel(craft)
		FORMS_COUNTER:
			var refile := RefilePanel.new()
			refile.setup(opened.title)
			_show_panel(refile)
		TROPHY_WALL:
			_show_lines(Mementos.wall_lines(Progress.data))
		EMPLOYEE_PLAQUE:
			var clears := Progress.data.clears_of_path(Departments.entry(Departments.EXECUTIVE_SUITE)["opens_on"])
			_show_lines(PackedStringArray([Departments.plaque_text(clears)]))
		BOUNTY_BOARD:
			_open_bounty_panel(opened.title)
		ITEM_RACK:
			var rack := ItemRackPanel.new()
			rack.setup(opened.title, _run)
			rack.taken.connect(_on_rack_taken)
			_show_panel(rack)
		DECOR_COUNTER:
			var decor := DecorPanel.new()
			decor.setup(opened.title)
			_show_panel(decor)
		TICKET_MACHINE:
			var ticket := TicketPanel.new()
			ticket.setup(opened.title)
			ticket.cursed_taken.connect(_hud.show_notice)
			_show_panel(ticket)
		NOTICEBOARD:
			var letters := NoticeboardPanel.new()
			letters.setup(opened.title)
			_show_panel(letters)


# A Back Room table opens the Arcade's card-table overlay, as floor_scene does: never on the frame a
# panel closed on, so the press that closes it never opens it again, and with the mouse shown for its
# buttons. Bets come from Pension and wins go to it, through the room's bank, which is Progress.
func _open_card_table(table: ArcadeTable) -> void:
	if _panel != null or Engine.get_process_frames() == _panel_closed_frame or not is_instance_valid(table):
		return
	var cards := CardTablePanel.new()
	cards.setup(table, _room_view, _rng)
	_show_panel(cards)
	Input.mouse_mode = Settings.cursor_mode(false)


# Shows the first line now and the rest one after another, ahead of whatever was waiting. Arrival news
# is already marked seen when it is queued, so it must still show after these.
func _show_lines(lines: PackedStringArray) -> void:
	_notices = Hud.lines_in_front(lines, _notices)
	_notice_wait = 0.0


func _show_panel(panel: CanvasLayer) -> void:
	_panel = panel
	# Every Waiting Room panel has a closed signal, though CanvasLayer itself does not.
	_panel.connect("closed", _close_panel)
	add_child(_panel)
	player.cancel_charge()
	player.set_physics_process(false)
	_hud.show_message("")


func _close_panel() -> void:
	if _panel == null:
		return
	_panel.queue_free()
	_panel = null
	_panel_closed_frame = Engine.get_process_frames()
	player.set_physics_process(true)
	_dolores_has_her_word()
	_refresh_poster_board()
	_refresh_noticeboard()
	if is_instance_valid(_lobby_decor):
		_lobby_decor.setup(Progress.data.cosmetics_owned)
	# What he wears may have changed at the Decor Office, and he wears it here as in runs.
	_run.look = RunState.look_from(Progress.data.cosmetics_worn, CosmeticDef.all())
	player.refresh_look()
	_refresh_run_stats()


# A poster taken or paid while the bounty panel was up gets Deputy Dolores's word once it is down.
func _dolores_has_her_word() -> void:
	if not _dolores_next.is_empty() and is_instance_valid(_npcs.get(DEPUTY_DOLORES)):
		(_npcs[DEPUTY_DOLORES] as Npc).say_moment(_dolores_next)
	_dolores_next = ""


# A panel may have filed or refiled a form, so his stats are worked out again, keeping any yard items.
# Outside the yard his Thermoses follow the forms as at a run's start. In it the supply stays full.
func _refresh_run_stats() -> void:
	_run.refresh_stats()
	if not _in_yard():
		_run.bombs = RunState.STARTING_BOMBS + _run.stats.bonus_bombs
		_run.changed.emit()


func _in_yard() -> bool:
	return player.bomb_requested.is_connected(_on_yard_bomb)


func _exit_tree() -> void:
	# Departments Grandpa has left are out of the tree, so nothing else frees them.
	for view: RoomView in _views.values():
		if is_instance_valid(view) and not view.is_inside_tree():
			view.free()


# The ticket line and the DEV hint show only in the lobby, fixed on screen wherever the camera is.
func _refresh_lobby_text() -> void:
	if _lobby_text == null:
		return
	_lobby_text.visible = Departments.id_of(_current_id) == Departments.LOBBY
	var hint := ""
	if DevStart.is_available():
		hint = "%s   %s" % [DevStart.HINT, DevStart.WAITING_HINT_ON if Progress.is_dev_run() else DevStart.WAITING_HINT]
	_lobby_text.show_text(Progress.data.run_count, now_serving(Progress.data), hint)


# What the full-loop check reads and drives.
func open_merchant_ids() -> Array:
	return _open_merchants.map(func(entry: Dictionary): return entry["id"])


func open_department_ids() -> Array[String]:
	return Departments.open_ids(Progress.data)


func current_department() -> String:
	return Departments.id_of(_current_id)


func debug_enter_department(id: String) -> void:
	var target := Departments.index_of(id)
	if target >= 0:
		_enter_department(target)


func station(id: String) -> WaitingStation:
	var found: Variant = _stations.get(id)
	return found if is_instance_valid(found) else null


# Opens what pressing interact beside that station would, if it stands in the department he is in.
func use_station(id: String) -> void:
	var found := station(id)
	if found != null and _panel == null and found.get_parent() == _room_view:
		_open_station(found)


func open_panel() -> CanvasLayer:
	return _panel


func debug_room_view() -> RoomView:
	return _room_view


func debug_card_panel() -> CardTablePanel:
	return _panel as CardTablePanel


func debug_map() -> FloorMap:
	return _map


func debug_current_id() -> int:
	return _current_id


func lobby_text() -> LobbyText:
	return _lobby_text


func lobby_decor() -> LobbyDecor:
	return _lobby_decor if is_instance_valid(_lobby_decor) else null
