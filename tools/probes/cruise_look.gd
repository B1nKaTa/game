extends SceneTree
# Opens a real window and saves screenshots of the Last Resort Cruise: its rooms, the rolling deck,
# each prop, each enemy, Lorraine and the Commodore with every attack at mid-windup and as it lands,
# the lingering effects and the HUD over the planks of a large room.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | roll | props | enemies | lorraine | commodore | effects | all

const OUT := "D:/grandpa-look-cruise/shots/"
const WALL_LIMIT_MS := 280000
const CRUISE := 0
const F := "res://data/rooms/last_resort_cruise/%s.tres"

var _start := 0
var scene
var view: RoomView
var player: Player
var progress
# Called every frame while set, to hold a boss between the attacks the probe starts itself.
var _hold := Callable()
var _allow_summon := false


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
	if _hold.is_valid():
		_hold.call()
	return false


# Waits in real time, measured by the clock, never by counting frames.
func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


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
	progress.data.floors_cleared = 3
	progress.data.record_floor_cleared(1, "floor_1")
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["rooms", "roll", "props", "enemies", "lorraine", "commodore", "effects"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = 4
	scene.debug_choose_path(CRUISE)
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


func _enter(rows: PackedStringArray, rolls := false) -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = rows
	layout.ship_rolls = rolls
	await _enter_layout(layout)
	return layout


# A real layout with its props and its deck, but entered as a quiet room so nothing of its own spawns.
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


func _deck() -> ShipDeck:
	var decks := _of(ShipDeck)
	return decks[0] if not decks.is_empty() else null


func _middle(layout: RoomLayout) -> Vector2:
	var size := layout.size_in_cells()
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2)))


func _floor_near(layout: RoomLayout, at: Vector2) -> Vector2:
	return RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))))


func _freeze_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)


# --- rooms of each size, with their enemies in them ---

func _show_room(file: String, shot_name: String, at_middle := false) -> void:
	var source: RoomLayout = load(file)
	await _enter_layout(source)
	if at_middle:
		_stand(_middle(source))
	else:
		_stand(RoomBackdrop.cell_center(source.door_cell(RoomLayout.SOUTH)))
	await _wait(0.2)
	_freeze_enemies()
	await _wait(0.5)
	await _shot(shot_name)
	await _clear()


func _rooms() -> void:
	await _new_run()
	await _shot("00_cruise_start_room")
	for entry: Array in [["combat_small_01", false], ["combat_01", false], ["combat_04", false], ["combat_large_01", false], ["combat_large_01", true], ["combat_large_02", true]]:
		await _show_room(F % entry[0], "01_room_%s%s" % [entry[0], "_middle" if entry[1] else ""], entry[1])


# --- the rolling deck: the horn's arrow, the slide, and the Commodore's harder roll ---

func _roll() -> void:
	await _new_run()
	var layout := await _enter_quiet(F % "combat_large_01")
	_stand(_cell(14, 8))
	var deck := _deck()
	if deck == null:
		print("ERROR no deck")
		return
	await _until(func(): return deck.is_warning() and deck.horn_progress() > 0.5, 12.0)
	await _shot("10_roll_horn_arrow")
	await _until(func(): return deck.state() == ShipRoll.SLIDE, 3.0)
	await _wait(0.8)
	await _shot("11_roll_sliding")
	await _until(func(): return deck.state() == ShipRoll.QUIET, 4.0)
	_stand(_cell(20, 10))
	deck.force_roll(Vector2.LEFT, ShipRoll.HORN_TIME, 2.5, ShipRoll.SPEED * 2.2)
	await _wait(0.8)
	await _shot("12_roll_forced_horn")
	await _wait(1.3)
	await _shot("13_roll_forced_sliding")
	await _until(func(): return deck.state() == ShipRoll.QUIET, 4.0)
	# Grandpa beside a door: the deck there holds steady, but the arrow still shows.
	_stand(RoomBackdrop.cell_center(layout.door_cell(RoomLayout.WEST)) + Vector2(48, 0))
	await _until(func(): return deck.is_warning() and deck.horn_progress() > 0.5, 12.0)
	await _shot("14_roll_horn_near_west_door")


# --- each prop, the sleeping Sunbather among real chairs, and the wet patch beside the planks ---

func _props() -> void:
	await _new_run()
	var rows := _rows(20, 11)
	for x in [3, 5, 7, 9]:
		_put(rows, Vector2i(x, 2), "b")
	for x in [12, 13, 14]:
		_put(rows, Vector2i(x, 2), "0")
	for x in [3, 4, 5]:
		for y in [5, 6]:
			_put(rows, Vector2i(x, y), "1")
	for y in [5, 6]:
		_put(rows, Vector2i(9, y), "2")
		_put(rows, Vector2i(11, y), "2")
	await _enter(rows)
	_stand(_cell(10, 9))
	var sun := _spawn("sunburnt_sunbather", _cell(11, 2))
	var palette: RoomPalette = view.room_palette()
	var cells: Array[Vector2i] = []
	for x in range(14, 17):
		for y in range(5, 8):
			cells.append(Vector2i(x, y))
	var splash := WetSplash.new()
	splash.setup(cells, 30.0, palette)
	view.add_child(splash)
	await _wait(0.5)
	await _shot("20_props_chairs_trays_pool_davits_wet")
	print("sunbather asleep %s" % sun._behavior.is_asleep())
	# Close to him: he snaps the chair.
	_stand(_cell(11, 3) + Vector2(0, 14))
	await _until(func(): return _warned(sun, 0.4), 3.0)
	await _shot("21_sunbather_snap")
	await _wait(0.5)
	await _shot("22_sunbather_awake")
	await _clear()
	# As a room starts, before anyone's first tick: he must already lie as a chair.
	_stand(_cell(10, 9))
	var fresh := _spawn("sunburnt_sunbather", _cell(11, 2))
	fresh.wait_for_room_start()
	await _wait(0.15)
	await _shot("23_sunbather_as_the_room_starts")
	await _clear()


# --- each enemy ---

func _enemies() -> void:
	await _new_run()
	await _enter(_rows(20, 11), false)
	# The Early Bird Diners: the bell lanes on all three, then the rush.
	_stand(_cell(4, 8))
	var diners: Array[Enemy] = []
	for i in 3:
		var d := _spawn("early_bird_diner", _cell(13 + i, 3))
		if i > 0:
			d.is_group_follower = true
		diners.append(d)
	await _until(func(): return diners.any(func(d): return _warned(d, 0.5)), 6.0)
	await _shot("30_diners_bell_lanes")
	await _until(func(): return diners.all(func(d): return not is_instance_valid(d) or d._warning == null), 2.0)
	await _wait(0.2)
	await _shot("31_diners_rush")
	await _clear()
	# The Shuffleboard Shark: the puck's whole way, a bounce off the wall, then the slide.
	_stand(_cell(3, 8))
	var shark := _spawn("shuffleboard_shark", _cell(9, 5))
	await _until(func(): return _of(ShuffleboardPuck).size() > 0, 4.0)
	shark.set_physics_process(false)
	await _wait(0.35)
	shark.set_physics_process(true)
	await _shot("32_shark_puck_lanes_bounce")
	await _wait(0.6)
	await _shot("33_shark_puck_sliding")
	await _clear()
	# A puck off a davit.
	var rows := _rows(20, 11)
	_put(rows, Vector2i(4, 5), "2")
	_put(rows, Vector2i(4, 6), "2")
	await _enter(rows)
	_stand(_cell(8, 5))
	_spawn("shuffleboard_shark", _cell(14, 5))
	await _until(func(): return _of(ShuffleboardPuck).size() > 0, 4.0)
	await _wait(0.35)
	await _shot("34_shark_puck_off_davit")
	await _clear()
	# The whole roster side by side, then awake.
	_stand(_cell(3, 8))
	var ids := ["early_bird_diner", "shuffleboard_shark", "sunburnt_sunbather", "cruise_orderly", "cruise_stoker"]
	for i in ids.size():
		_spawn(ids[i], _cell(5 + i * 3, 4))
	await _wait(0.1)
	_freeze_enemies()
	await _wait(0.1)
	await _shot("35_cruise_roster")
	await _clear()
	# The Orderly and the Stoker at work on the planks.
	_stand(_cell(5, 6))
	var orderly := _spawn("cruise_orderly", _cell(9, 6))
	var stoker := _spawn("cruise_stoker", _cell(15, 3))
	await _until(func(): return _warned(orderly, 0.5) or _warned(stoker, 0.5), 8.0)
	await _shot("36_orderly_stoker_warning")
	await _wait(1.0)
	await _shot("37_orderly_stoker_later")
	await _clear()


# --- Lorraine, Cruise Director ---

func _lorraine() -> void:
	await _new_run()
	var layout := await _enter_quiet(F % "mini_boss_01")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-120, 30)))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/lorraine.tres"), center, true)
	var b = boss._behavior
	_allow_summon = false
	_hold = func():
		if is_instance_valid(boss):
			b._cooldown = 99.0
			if not _allow_summon:
				b._summon_timer = 99.0
	await _wait(0.1)
	boss.global_position = center
	b._cooldown = 99.0
	b._begin(boss, CruiseDirectorBehavior.Attack.CONGA)
	await _wait(CruiseDirectorBehavior.CONGA_WINDUP * 0.5)
	await _shot("40_lorraine_conga_windup")
	await _wait(CruiseDirectorBehavior.CONGA_WINDUP * 0.5 + CruiseDirectorBehavior.CONGA_WARNING * 0.5)
	b._cooldown = 99.0
	await _shot("41_lorraine_conga_lanes_gap")
	await _wait(CruiseDirectorBehavior.CONGA_WARNING * 0.5 + 0.6)
	b._cooldown = 99.0
	await _shot("42_lorraine_conga_dancing")
	await _wait(1.6)
	b._cooldown = 99.0
	boss.global_position = center
	_stand(center + Vector2(-90, 10))
	await _wait(0.1)
	b._begin(boss, CruiseDirectorBehavior.Attack.KARAOKE)
	await _wait(CruiseDirectorBehavior.KARAOKE_WINDUP * 0.5)
	await _shot("43_lorraine_karaoke_cone")
	await _wait(CruiseDirectorBehavior.KARAOKE_WINDUP * 0.5 + 0.06)
	b._cooldown = 99.0
	await _shot("44_lorraine_karaoke_burst")
	await _wait(0.8)
	b._cooldown = 99.0
	boss.global_position = center
	_stand(center + Vector2(-110, 40))
	await _wait(0.1)
	b._begin(boss, CruiseDirectorBehavior.Attack.QUOITS)
	await _wait((QuoitRing.WARNING + CruiseDirectorBehavior.QUOIT_WINDUP) * 0.5)
	await _shot("45_lorraine_quoits_falling")
	await _until(func(): return _of(QuoitRing).any(func(q): return q.is_lying()), 2.0)
	await _wait(0.05)
	b._cooldown = 99.0
	await _shot("46_lorraine_quoits_landed")
	var quoits := _of(QuoitRing)
	if not quoits.is_empty():
		_stand(quoits[0].global_position)
	await _wait(0.6)
	b._cooldown = 99.0
	await _shot("47_lorraine_quoits_lying_slowed")
	await _wait(2.6)
	_allow_summon = true
	b._summon_timer = 0.0
	await _wait(0.5)
	await _shot("48_lorraine_summon_marks")
	await _wait(1.2)
	b._cooldown = 99.0
	_freeze_enemies()
	await _shot("49_lorraine_diners")
	_hold = Callable()
	await _clear()


# --- Commodore Wellington ---

func _commodore() -> void:
	await _new_run()
	var layout := await _enter_quiet(F % "floor_boss_01")
	var center := _middle(layout)
	_stand(_floor_near(layout, center + Vector2(-120, 40)))
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/commodore_wellington.tres"), center, true)
	var b = boss._behavior
	var deck := _deck()
	_hold = func():
		if is_instance_valid(boss):
			b._cooldown = 99.0
			b._wet_timer = 99.0
			b._next = CommodoreBehavior.Attack.NONE
	await _wait(0.1)
	boss.global_position = center
	b._last = CommodoreBehavior.Attack.NONE
	b._begin(boss, CommodoreBehavior.Attack.ANCHOR, false)
	var anchor_fill := func(share: float) -> bool:
		return _of(AnchorDrop).any(func(a): return not a._landed and a.fill() >= share)
	await _until(anchor_fill.bind(0.25), 2.0)
	await _shot("50_commodore_anchor_early")
	await _until(anchor_fill.bind(0.5), 2.0)
	await _shot("51_commodore_anchor_mid")
	await _until(anchor_fill.bind(0.85), 2.0)
	await _shot("52_commodore_anchor_late")
	await _until(func(): return _of(AnchorDrop).any(func(a): return a._landed), 2.0)
	await _shot("53_commodore_anchor_landed")
	await _wait(0.8)
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-150, 20)))
	await _wait(0.1)
	b._begin(boss, CommodoreBehavior.Attack.FOGHORN, false)
	await _until(func(): return _warned(boss, 0.5), 2.0)
	await _shot("54_commodore_foghorn_lane")
	await _until(func(): return _of(FoghornBlast).size() > 0, 2.0)
	await _shot("55_commodore_foghorn_blast")
	await _wait(0.8)
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 40)))
	await _until(func(): return deck.state() == ShipRoll.QUIET and not deck.is_forced(), 8.0)
	b._begin(boss, CommodoreBehavior.Attack.PORT, false)
	await _wait(CommodoreBehavior.PORT_WINDUP * 0.5)
	await _shot("56_commodore_port_windup")
	await _until(func(): return deck.is_forced() and deck.horn_progress() > 0.5, 3.0)
	await _shot("57_commodore_port_horn")
	await _until(func(): return deck.is_forced() and deck.state() == ShipRoll.SLIDE, 3.0)
	await _wait(0.6)
	await _shot("58_commodore_port_sliding")
	await _until(func(): return not deck.is_forced(), 4.0)
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-100, 30)))
	await _wait(0.1)
	b._begin(boss, CommodoreBehavior.Attack.BUOYS, false)
	await _wait((CommodoreBehavior.BUOY_WINDUP + CommodoreBehavior.BUOY_WARNING) * 0.5)
	await _shot("59_commodore_buoy_lanes")
	await _until(func(): return _of(DeckLane).any(func(l): return l.is_moving()), 2.0)
	await _wait(0.6)
	await _shot("60_commodore_buoys_rolling")
	await _until(func(): return _of(DeckLane).is_empty(), 5.0)
	# The second phase: the decks swabbed, then the anchor twice.
	boss.hp = boss.max_hp() * 0.4
	boss.global_position = center
	_stand(_floor_near(layout, center + Vector2(-110, 30)))
	_hold = func():
		if is_instance_valid(boss):
			b._cooldown = 99.0
	b._wet_timer = 0.0
	await _until(func(): return _of(GroundStrike).any(func(s): return s.fill() > 0.5), 3.0)
	await _shot("61_commodore_swab_jets")
	await _until(func(): return _of(WetFloor).size() > 0, 3.0)
	b._wet_timer = 99.0
	await _wait(0.3)
	await _shot("62_commodore_wet_patches")
	await _wait(0.3)
	b._wet_timer = 99.0
	# The followup must run, so only the first anchor is started by hand.
	_hold = func():
		if is_instance_valid(boss) and b._next == CommodoreBehavior.Attack.NONE and b._attack != CommodoreBehavior.Attack.ANCHOR:
			b._cooldown = 99.0
		if is_instance_valid(boss):
			b._wet_timer = 99.0
	boss.global_position = center
	b._last = CommodoreBehavior.Attack.NONE
	b._cooldown = 99.0
	b._begin(boss, CommodoreBehavior.Attack.ANCHOR, true)
	await _until(anchor_fill.bind(0.5), 2.0)
	await _shot("63_commodore_phase2_anchor_one")
	await _until(func(): return b._anchors_in_a_row == 2, 3.0)
	await _until(anchor_fill.bind(0.5), 2.0)
	await _shot("64_commodore_phase2_anchor_again")
	await _until(func(): return _of(AnchorDrop).any(func(a): return a._landed), 2.0)
	await _shot("65_commodore_phase2_anchor_again_landed")
	_hold = Callable()
	await _clear()


# --- the lingering effects and the HUD over the planks of a large room ---

func _effects() -> void:
	await _new_run()
	await _enter(_rows(30, 17), true)
	var center := _cell(15, 8)
	_stand(center)
	# A boss keeps its marks alive and puts its bar up; it stands still off to one side.
	var boss: Enemy = view._spawn_enemy(load("res://data/enemies/commodore_wellington.tres"), _cell(26, 4), true)
	await _wait(0.1)
	boss.set_physics_process(false)
	var palette: RoomPalette = view.room_palette()
	var cells: Array[Vector2i] = []
	for x in range(9, 12):
		for y in range(9, 12):
			cells.append(Vector2i(x, y))
	var splash := WetSplash.new()
	splash.setup(cells, 30.0, palette)
	view.add_child(splash)
	for spot in [center + Vector2(90, 30), center + Vector2(140, 60)]:
		var quoit := QuoitRing.new()
		quoit.setup(boss, 0.05, 30.0)
		view.add_child(quoit)
		quoit.global_position = spot
	var mark := SafeSpotMark.new()
	mark.setup(30.0)
	view.add_child(mark)
	mark.global_position = center + Vector2(-60, -70)
	var anchor := AnchorDrop.new()
	anchor.setup(boss, 2.0)
	view.add_child(anchor)
	anchor.global_position = center + Vector2(60, -60)
	await _wait(1.0)
	await _shot("70_effects_on_planks_hud")
	var deck := _deck()
	if deck != null:
		await _until(func(): return deck.is_warning() and deck.horn_progress() > 0.5, 12.0)
		await _shot("71_effects_with_horn")
	await _clear()
