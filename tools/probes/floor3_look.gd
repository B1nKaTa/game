extends SceneTree
# Opens a real window and saves screenshots of the third floor: the landing and Crossroads, the Arcade
# Room and its overlays, the Funeral Parlour and the Mall with their hazards, enemies and bosses.
# Run only from an exported copy whose config/name is renamed.
# Args after --: landing | arcade | parlour | reverend | mortimer | mall | gloria | santa | all

const OUT := "D:/grandpa-verify/shots/floor3/"
const WALL_LIMIT_MS := 280000
const PARLOUR := 0
const MALL := 1

var _start := 0
var scene
var view: RoomView
var player: Player
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET


func _cell(x: int, y: int) -> Vector2:
	return RoomBackdrop.cell_center(Vector2i(x, y))


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["pipes", "landing", "arcade", "parlour", "reverend", "mortimer", "mall", "gloria", "santa"]:
		if part == "pipes" and which != "pipes":
			continue
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(depth: int, path: int) -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = depth
	scene.debug_choose_path(path)
	await _wait(0.2)
	view = scene.debug_room_view()
	print("floor %s" % scene.debug_floor_def().display_name)
	await _clear()


func _rows(width: int, height: int) -> PackedStringArray:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	return rows


func _put(rows: PackedStringArray, cell: Vector2i, symbol: String) -> void:
	var row := rows[cell.y]
	rows[cell.y] = row.substr(0, cell.x) + symbol + row.substr(cell.x + 1)


func _enter_layout(layout: RoomLayout) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()


func _enter(rows: PackedStringArray, reverses := false) -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	layout.strips_reverse = reverses
	await _enter_layout(layout)


# A real layout with its pipes or strips, but entered as a quiet room so nothing of its own spawns.
func _enter_quiet(file: String) -> RoomLayout:
	var source: RoomLayout = load(file)
	var layout: RoomLayout = source.duplicate()
	layout.room_type = RoomLayout.TYPE_HEALING
	await _enter_layout(layout)
	await _clear()
	return layout


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _until(check: Callable, limit: float) -> bool:
	var began := Time.get_ticks_msec()
	while not check.call() and Time.get_ticks_msec() - began < limit * 1000.0:
		await process_frame
	return check.call()


func _spawn(id: String, at: Vector2) -> Enemy:
	return view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)


func _of(type) -> Array:
	var found := []
	_collect(view, type, found)
	return found


func _collect(node: Node, type, found: Array) -> void:
	for child in node.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			found.append(child)
		_collect(child, type, found)


func _warned(enemy: Enemy, share: float) -> bool:
	return is_instance_valid(enemy) and enemy._warning != null and enemy._warning.warning_progress(enemy._warning_share()) > share


func _middle(layout: RoomLayout) -> Vector2:
	var size := layout.size_in_cells()
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2)))


func _floor_near(layout: RoomLayout, at: Vector2) -> Vector2:
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))))


func _pipes() -> void:
	await _new_run(3, PARLOUR)
	var rows := _rows(20, 11)
	for x in [4, 8, 12, 16]:
		_put(rows, Vector2i(x, 0), "o")
	await _enter(rows)
	_stand(_cell(10, 6))
	var pipes := _of(OrganPipe)
	print("pipes found %d" % pipes.size())
	var ok := await _until(func(): return pipes.any(func(p): return p.state() == PipeBeat.GLOW and p.glow_progress() > 0.7), 5.0)
	print("glow seen %s" % ok)
	await _shot("dbg_pipe_glow")
	ok = await _until(func(): return _of(PipeRing).any(func(r): return r.radius_now() > 60.0), 3.0)
	var radii := []
	for r in _of(PipeRing):
		radii.append(r.radius_now())
	print("ring seen %s radii %s" % [ok, str(radii)])
	await _shot("dbg_pipe_ring")
	await _wait(0.15)
	await _shot("dbg_pipe_ring_later")


# --- the landing and the third Crossroads ---

func _landing() -> void:
	await _new_run(1, 0)
	scene._depth = 2
	scene._go_down()
	await _wait(0.6)
	view = scene.debug_room_view()
	await _shot("01_floor3_landing")
	var map: FloorMap = scene.debug_map()
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_CROSSROADS:
			scene._enter_room(room.id)
	await _wait(0.4)
	view = scene.debug_room_view()
	var crossroads: CrossroadsView = view
	var mall_sign = crossroads.sign_of_path(MALL)
	_stand(mall_sign.global_position + Vector2(0, 16))
	await _wait(0.4)
	await _shot("02_floor3_crossroads_mall_chained")
	var parlour_sign = crossroads.sign_of_path(PARLOUR)
	_stand(parlour_sign.global_position + Vector2(0, 16))
	await _wait(0.4)
	await _shot("03_floor3_crossroads_parlour_sign")


# --- the Arcade Room and its overlays ---

func _find_five_card_seed() -> int:
	for s in range(1, 5000):
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var deck := CardDeck.new(rng)
		deck.shuffle()
		var hand := Blackjack.new(deck)
		hand.deal()
		if hand.is_over:
			continue
		while not hand.is_over and hand.player.size() < 5 and Blackjack.hand_value(hand.player) < 19:
			hand.hit()
		if not hand.is_over and hand.player.size() == 5:
			return s
	return 1


func _arcade() -> void:
	await _new_run(3, PARLOUR)
	progress.add_pension(900)
	var layout: RoomLayout = load(FloorBuilder.ARCADE_DIR + "arcade_01.tres")
	await _enter_layout(layout)
	var tables: Array[ArcadeTable] = view.arcade_tables()
	_stand(RoomBackdrop.cell_center(layout.door_cell(RoomLayout.SOUTH)))
	await _wait(0.5)
	await _shot("10_arcade_room")
	_stand(tables[0].global_position + Vector2(0, RoomBackdrop.TILE))
	await _wait(0.3)
	await _shot("11_arcade_table_prompt")
	for table in tables:
		_stand(table.global_position + Vector2(0, RoomBackdrop.TILE))
		await _wait(0.1)
		scene._open_card_table(table)
		await _wait(0.2)
		var panel: CardTablePanel = scene.debug_card_panel()
		if panel == null:
			print("ERROR no panel for %s" % table.game)
			continue
		await _shot("12_overlay_%s_open" % table.game)
		match table.game:
			ArcadeTable.SLOT:
				panel.pull()
				await _wait(0.2)
				await _shot("13_overlay_slot_pulled")
			ArcadeTable.BLACKJACK:
				var rng := RandomNumberGenerator.new()
				rng.seed = _find_five_card_seed()
				panel.use_rng(rng)
				panel.bet(Blackjack.BETS[2])
				await _wait(0.1)
				await _shot("14_overlay_blackjack_dealt")
				while panel.state() == CardTablePanel.PLAYING and panel.blackjack().player.size() < 5:
					panel.hit()
				await _wait(0.1)
				await _shot("15_overlay_blackjack_five_cards")
				panel.stand()
				await _wait(0.1)
				await _shot("16_overlay_blackjack_settled")
			ArcadeTable.POKER:
				panel.bet(DrawPoker.BETS[2])
				var holds := ArcadeOdds.simple_holds(panel.poker().hand)
				for i in holds.size():
					if holds[i]:
						panel.toggle_hold(i)
				await _wait(0.1)
				await _shot("17_overlay_poker_held")
				panel.draw_cards()
				await _wait(0.1)
				await _shot("18_overlay_poker_drawn")
		panel.leave()
		await _wait(0.3)


# --- the Funeral Parlour ---

func _show_room(file: String, type: String, shot_name: String) -> void:
	var source: RoomLayout = load(file)
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = type
	room.layout = source
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()
	_stand(RoomBackdrop.cell_center(source.door_cell(RoomLayout.SOUTH)))
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	await _wait(0.6)
	await _shot(shot_name)
	await _clear()


func _parlour() -> void:
	await _new_run(3, PARLOUR)
	var f := "res://data/rooms/funeral_parlour/%s.tres"
	for entry: Array in [["combat_small_01", "combat"], ["combat_01", "combat"], ["combat_large_01", "combat"]]:
		await _show_room(f % entry[0], entry[1], "20_parlour_" + entry[0])
	# The organ pipes: glowing, then the ring of the chord.
	var rows := _rows(20, 11)
	for x in [4, 8, 12, 16]:
		_put(rows, Vector2i(x, 0), "o")
	await _enter(rows)
	_stand(_cell(10, 6))
	await _until(func(): return _of(OrganPipe).any(func(p): return p.state() == PipeBeat.GLOW), 5.0)
	await _wait(0.4)
	await _shot("21_pipes_glow")
	await _until(func(): return _of(PipeRing).any(func(r): return r.radius_now() > 60.0), 5.0)
	await _shot("22_pipes_ring")
	# The Weeping Mourners: a pack wails, then lunges.
	_stand(_cell(4, 5))
	var mourners: Array[Enemy] = []
	for i in 3:
		mourners.append(_spawn("weeping_mourner", _cell(13, 3 + i * 2)))
	await _until(func(): return mourners.any(func(m): return _warned(m, 0.5)), 8.0)
	await _shot("23_mourners_wail_warning")
	await _wait(0.5)
	await _shot("24_mourners_lunge")
	await _clear()
	# The Florist's wreath: the mark, then the thorns.
	_stand(_cell(5, 6))
	_spawn("florist", _cell(16, 6))
	await _until(func(): return _of(GroundStrike).any(func(s): return s.fill() > 0.5), 8.0)
	await _shot("25_florist_wreath_mark")
	_stand(_cell(4, 2))
	await _until(func(): return _of(GroundStrike).any(func(s): return s.is_burning()), 3.0)
	await _wait(0.2)
	await _shot("26_florist_thorns")
	await _clear()
	# The Pallbearers: their lanes, then the ram.
	_stand(_cell(4, 5))
	var lead := _spawn("pallbearer", _cell(14, 4))
	var follow := _spawn("pallbearer", _cell(14, 6))
	follow.is_group_follower = true
	await _until(func(): return _warned(lead, 0.5) or _warned(follow, 0.5), 10.0)
	await _shot("27_pallbearers_lane")
	await _wait(0.6)
	await _shot("28_pallbearers_ram")
	# One down: the coffin dropped.
	await _wait(0.6)
	_stand(_cell(17, 9))
	if is_instance_valid(follow):
		follow.take_damage(9999.0, Vector2.ZERO)
	await _wait(0.3)
	print("dropped coffins %d" % _of(DroppedCoffin).size())
	await _shot("29_pallbearer_coffin_dropped")
	await _clear()
	# The whole roster side by side.
	_stand(_cell(3, 7))
	var ids := ["weeping_mourner", "florist", "pallbearer", "parlour_plot_holder", "parlour_seasonal_temp"]
	for i in ids.size():
		var e := _spawn(ids[i], _cell(6 + i * 3, 4))
		e.set_physics_process(false)
	await _wait(0.1)
	await _shot("30_parlour_roster")
	await _clear()


func _reverend() -> void:
	await _new_run(3, PARLOUR)
	await _enter(_rows(30, 17))
	var center := _cell(16, 8)
	_stand(center + Vector2(-110, 20))
	var rev: Enemy = view._spawn_enemy(load("res://data/enemies/reverend.tres"), center, true)
	var b = rev._behavior
	b._summon_timer = 99.0
	await _wait(0.1)
	rev.global_position = center
	b._cooldown = 99.0
	b._begin(rev, ReverendBehavior.Attack.EULOGY)
	await _wait(ReverendBehavior.EULOGY_WINDUP * 0.7)
	await _shot("31_reverend_eulogy_lane")
	await _wait(ReverendBehavior.EULOGY_WINDUP * 0.3 + ReverendBehavior.WORD_STEP * 3)
	b._cooldown = 99.0
	await _shot("32_reverend_eulogy_words")
	await _wait(1.2)
	b._cooldown = 99.0
	rev.global_position = center
	_stand(center + Vector2(-120, -30))
	await _wait(0.1)
	b._begin(rev, ReverendBehavior.Attack.PLATE)
	await _wait(ReverendBehavior.PLATE_WINDUP * 0.7)
	await _shot("33_reverend_plate_warned")
	await _wait(ReverendBehavior.PLATE_WINDUP * 0.3 + 0.35)
	b._cooldown = 99.0
	await _shot("34_reverend_plate_flying")
	await _wait(1.0)
	b._cooldown = 99.0
	b._summon_timer = 0.0
	await _wait(0.4)
	await _shot("35_reverend_summon_marks")
	await _wait(1.0)
	b._cooldown = 99.0
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)
	await _shot("36_reverend_mourners")
	await _clear()


func _mortimer() -> void:
	await _new_run(3, PARLOUR)
	var layout := await _enter_quiet("res://data/rooms/funeral_parlour/floor_boss_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-110, 0)))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/mortimer_grimsby.tres"), center, true)
	var b = boss._behavior
	await _wait(0.1)
	boss.global_position = center
	b._cooldown = 99.0
	b._since_crescendo = -99.0
	b._begin(boss, FuneralDirectorBehavior.Attack.CASKET, false)
	await _wait(0.3)
	await _shot("40_mortimer_casket_early")
	await _wait(0.6)
	await _shot("41_mortimer_casket_late")
	await _wait(0.4)
	b._cooldown = 99.0
	b._next = FuneralDirectorBehavior.Attack.NONE
	await _shot("42_mortimer_casket_landed")
	await _wait(0.6)
	b._cooldown = 99.0
	b._begin(boss, FuneralDirectorBehavior.Attack.PROCESSION, false)
	await _wait(FuneralDirectorBehavior.PROCESSION_WINDUP + 0.5)
	b._cooldown = 99.0
	b._next = FuneralDirectorBehavior.Attack.NONE
	await _shot("43_mortimer_procession_warned")
	await _wait(0.65)
	await _shot("44_mortimer_procession_march")
	await _wait(1.0)
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-80, 10)))
	b._cooldown = 99.0
	b._begin(boss, FuneralDirectorBehavior.Attack.SPRAY, false)
	await _wait(FuneralDirectorBehavior.SPRAY_WINDUP * 0.7)
	await _shot("45_mortimer_spray_cone")
	await _wait(FuneralDirectorBehavior.SPRAY_WINDUP * 0.3 + 0.08)
	b._cooldown = 99.0
	b._next = FuneralDirectorBehavior.Attack.NONE
	await _shot("46_mortimer_spray")
	await _wait(0.8)
	b._cooldown = 99.0
	b._begin(boss, FuneralDirectorBehavior.Attack.CRESCENDO, false)
	await _wait(FuneralDirectorBehavior.CRESCENDO_WINDUP + 0.7)
	b._cooldown = 99.0
	await _shot("47_mortimer_crescendo_glow")
	await _until(func(): return _of(PipeRing).any(func(r): return r.radius_now() > 50.0), 3.0)
	await _wait(0.15)
	b._cooldown = 99.0
	b._next = FuneralDirectorBehavior.Attack.NONE
	await _shot("48_mortimer_crescendo_rings")
	await _wait(1.5)
	# The second phase: into the coffin, which charges down a warned lane.
	boss.hp = boss.max_hp() * 0.4
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-130, 0)))
	await _wait(0.3)
	b._cooldown = 99.0
	b._begin(boss, FuneralDirectorBehavior.Attack.CHARGE, true)
	await _wait(FuneralDirectorBehavior.CHARGE_WINDUP * 0.6)
	await _shot("49_mortimer_phase2_charge_lane")
	await _wait(FuneralDirectorBehavior.CHARGE_WINDUP * 0.4 + 0.25)
	await _shot("50_mortimer_phase2_charging")
	await _clear()


# --- the Golden Years Mall ---

func _mall() -> void:
	progress.data.record_floor_cleared(3, "funeral_parlour")
	await _new_run(3, MALL)
	var f := "res://data/rooms/golden_years_mall/%s.tres"
	for entry: Array in [["combat_small_01", "combat"], ["combat_01", "combat"], ["combat_large_01", "combat"]]:
		await _show_room(f % entry[0], entry[1], "60_mall_" + entry[0])
	# Strips that reverse: running, chiming, reversed.
	var rows := _rows(20, 11)
	for x in range(4, 16):
		_put(rows, Vector2i(x, 4), ">")
	for x in range(4, 16):
		_put(rows, Vector2i(x, 7), "<")
	for y in range(3, 9):
		_put(rows, Vector2i(17, y), "v")
	await _enter(rows, true)
	_stand(_cell(10, 6))
	await _wait(0.4)
	await _shot("61_strips_running")
	var strips: Array = _of(ConveyorStrip)
	await _until(func(): return strips.any(func(s): return s.is_chiming()), 7.0)
	await _wait(0.3)
	await _shot("62_strips_chiming")
	await _until(func(): return not strips.any(func(s): return s.is_chiming()), 2.0)
	await _wait(0.3)
	await _shot("63_strips_reversed")
	# The Mall Walkers: the whistle on every member.
	_stand(_cell(4, 9))
	var walkers: Array[Enemy] = []
	for i in 3:
		walkers.append(_spawn("mall_walker", _cell(12 + i, 2)))
	await _until(func(): return walkers.any(func(w): return _warned(w, 0.5)), 12.0)
	await _shot("64_walkers_whistle")
	await _wait(0.6)
	await _shot("65_walkers_break")
	await _clear()
	# The Mall Cop: the scooter lane, then the charge.
	_stand(_cell(4, 5))
	var cop := _spawn("mall_cop", _cell(14, 5))
	await _until(func(): return _warned(cop, 0.5), 8.0)
	await _shot("66_cop_lane")
	await _wait(0.5)
	await _shot("67_cop_charge")
	await _clear()
	# The Perfume Sprayer: the warned spot, the cloud, and the haze with his feet in it.
	_stand(_cell(5, 5))
	_spawn("perfume_sprayer", _cell(16, 5))
	await _until(func(): return _of(PerfumeCloud).any(func(c): return not c.has_landed()), 8.0)
	await _wait(0.5)
	await _shot("68_sprayer_cloud_warning")
	await _until(func(): return _of(PerfumeCloud).any(func(c): return c.has_landed()), 3.0)
	var cloud = _of(PerfumeCloud)[0] if not _of(PerfumeCloud).is_empty() else null
	if cloud != null:
		_stand(cloud.global_position)
	await _wait(0.8)
	await _shot("69_sprayer_haze")
	await _clear()
	_stand(_cell(3, 7))
	var ids := ["mall_walker", "mall_cop", "perfume_sprayer", "mall_intern_reaper", "mall_notary_public"]
	for i in ids.size():
		var e := _spawn(ids[i], _cell(6 + i * 3, 3))
		e.set_physics_process(false)
	await _wait(0.1)
	await _shot("70_mall_roster")
	await _clear()


func _gloria() -> void:
	progress.data.record_floor_cleared(3, "funeral_parlour")
	await _new_run(3, MALL)
	await _enter(_rows(30, 17))
	var center := _cell(16, 8)
	_stand(center + Vector2(-110, 10))
	var diva: Enemy = view._spawn_enemy(load("res://data/enemies/gloria.tres"), center, true)
	var b = diva._behavior
	b._summon_timer = 99.0
	await _wait(0.1)
	diva.global_position = center
	b._cooldown = 99.0
	b._begin(diva, FountainDivaBehavior.Attack.COINS)
	await _wait(FountainDivaBehavior.COIN_WINDUP * 0.7)
	await _shot("71_gloria_coin_lanes")
	await _wait(FountainDivaBehavior.COIN_WINDUP * 0.3 + 0.25)
	b._cooldown = 99.0
	await _shot("72_gloria_coins_flying")
	await _wait(1.0)
	b._cooldown = 99.0
	b._begin(diva, FountainDivaBehavior.Attack.SPLASH)
	await _until(func(): return _of(GroundStrike).any(func(s): return s.fill() > 0.5), 3.0)
	b._cooldown = 99.0
	await _shot("73_gloria_splash_marks")
	await _until(func(): return _of(WetFloor).size() > 0, 3.0)
	await _wait(0.3)
	b._cooldown = 99.0
	await _shot("74_gloria_wet_floor")
	await _wait(1.0)
	b._cooldown = 99.0
	b._summon_timer = 0.0
	await _wait(0.4)
	await _shot("75_gloria_summon_marks")
	await _wait(1.0)
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)
	await _shot("76_gloria_walkers")
	await _clear()


func _santa() -> void:
	progress.data.record_floor_cleared(3, "funeral_parlour")
	await _new_run(3, MALL)
	var layout := await _enter_quiet("res://data/rooms/golden_years_mall/floor_boss_01.tres")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-140, 0)))
	var santa: Enemy = view._spawn_enemy(load("res://data/enemies/mall_santa.tres"), center, true)
	var b = santa._behavior
	b._elf_timer = 99.0
	b._since_conveyor = -99.0
	await _wait(0.1)
	santa.global_position = center
	b._cooldown = 99.0
	b._begin(santa, MallSantaBehavior.Attack.SLEIGH, false)
	await _wait(0.3)
	await _shot("80_santa_sleigh_lane_early")
	await _wait(0.6)
	await _shot("81_santa_sleigh_lane_late")
	await _wait(0.45)
	await _shot("82_santa_sleigh_run")
	await _wait(1.0)
	b._cooldown = 99.0
	b._next = MallSantaBehavior.Attack.NONE
	santa.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 20)))
	await _wait(0.1)
	b._begin(santa, MallSantaBehavior.Attack.PRESENTS, false)
	await _wait(0.5)
	await _shot("83_santa_presents_warned")
	await _wait(0.55)
	b._cooldown = 99.0
	await _shot("84_santa_presents_burst")
	await _wait(1.0)
	b._cooldown = 99.0
	b._begin(santa, MallSantaBehavior.Attack.RING, false)
	await _wait(MallSantaBehavior.RING_WINDUP * 0.7)
	await _shot("85_santa_ring_warned")
	await _wait(MallSantaBehavior.RING_WINDUP * 0.3 + 0.7)
	b._cooldown = 99.0
	await _shot("86_santa_ring_closing")
	await _wait(0.6)
	await _shot("87_santa_ring_shut")
	await _wait(0.6)
	b._cooldown = 99.0
	b._begin(santa, MallSantaBehavior.Attack.CONVEYOR, false)
	await _wait(MallSantaBehavior.CONVEYOR_WINDUP + 0.4)
	b._cooldown = 99.0
	await _shot("88_santa_conveyor_chime")
	await _wait(1.0)
	await _shot("89_santa_conveyor_after")
	# The second phase: elves, then a sleigh run that chains into presents.
	santa.hp = santa.max_hp() * 0.4
	b._elf_timer = 0.0
	await _wait(0.5)
	b._cooldown = 99.0
	await _shot("90_santa_phase2_elf_marks")
	await _wait(1.0)
	b._cooldown = 99.0
	await _shot("91_santa_phase2_elves")
	for e in get_nodes_in_group("enemies"):
		if e != santa:
			e.dismiss()
	b._elf_timer = 99.0
	santa.global_position = center
	_stand(_floor_near(layout, center + Vector2(-140, 0)))
	await _wait(0.1)
	b._begin(santa, MallSantaBehavior.Attack.SLEIGH, true)
	await _wait(MallSantaBehavior.SLEIGH_WINDUP + 0.6)
	await _shot("92_santa_phase2_after_sleigh")
	await _wait(0.5)
	await _shot("93_santa_phase2_presents_followup")
	await _clear()
