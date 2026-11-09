extends SceneTree
# Opens a real window and saves shots of the room rules and flashbacks into OUT:
# - announce: the rule card mid-drop and at rest, the icon under the minimap, and its pulse, with the
#   HUD full (counters, potion, reel, items);
# - audit_north / audit_side: VIOLATION, the AUDIT flash at the door he came in by and the Auditor
#   walking in; then his clipboard windup and swing, the FINED stamp in flight and its ink blot;
# - reel: GOOD CONDUCT, the reel on the floor, the reel in the HUD slot (keys, Xbox and PlayStation
#   labels), "Memory ready" with the sepia glow, the sepia flicker, each era's idle, walk, kick or
#   punch, dodge and throw, and the return to old Harold in his hat and cardigan;
# - options: the title screen, and the Options Input tab scrolled to its last rows.
# A 4x crop sits beside the shots of small things. Run only from an exported copy whose config/name is
# renamed. Args after --: announce | audit_north | audit_side | reel | options | all

const OUT := "D:/grandpa-verify/rules-shots/"
const WALL_LIMIT_MS := 300000
const CROP := Vector2i(120, 80)
const FIGHTS := [RoomLayout.TYPE_COMBAT]

var _start := 0
var scene
var player: Player
var progress
var aim := Vector2.RIGHT
# Actions held down, pressed again before every physics step (a window lets go of them after a frame).
var held: Array[String] = []
# Pinned every frame while the pad shots run, since mouse motion would hand prompts back to the keys.
var pad_family := ""


func _initialize() -> void:
	if str(ProjectSettings.get_setting("application/config/name")) == "Grandpa":
		print("rules_look.gd: refusing to run against the real save folder; use an exported copy with a renamed config/name.")
		quit(2)
		return
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	physics_frame.connect(func() -> void:
		for action in held:
			Input.action_press(action))
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player) and player.run != null:
		player.run.health.heal(99)
	if not pad_family.is_empty():
		ActiveDevice.using_pad = true
		ActiveDevice.family = pad_family
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


# Waits until cond is true (by state, not time), up to limit seconds. Returns whether it came true.
func _until(cond: Callable, limit := 5.0) -> bool:
	var began := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - began > limit * 1000.0:
			return false
		await process_frame
	return true


# The whole 640x360 view at 2x, and, with at, a 4x crop round that screen point.
func _shot(shot_name: String, at: Variant = null, whole := true) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if at != null:
		var middle: Vector2i
		if at is Node2D:
			middle = Vector2i((at as Node2D).get_global_transform_with_canvas().origin)
		else:
			middle = Vector2i(at)
		var corner := (middle - CROP / 2).clamp(Vector2i.ZERO, image.get_size() - CROP)
		var crop := image.get_region(Rect2i(corner, CROP))
		crop.resize(CROP.x * 4, CROP.y * 4, Image.INTERPOLATE_NEAREST)
		crop.save_png(OUT + shot_name + "_x4.png")
	if whole:
		image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
		image.save_png(OUT + shot_name + ".png")
	print("shot %s (%s)" % [shot_name, image.get_size()])


func _press(action: String) -> void:
	held.append(action)
	Input.action_press(action)


func _release(action: String) -> void:
	held.erase(action)
	Input.action_release(action)


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	await physics_frame
	Input.action_release(action)


func _move_feet_to(at: Vector2) -> void:
	player.global_position += at - player.feet().global_position
	player.velocity = Vector2.ZERO


func _hold_aim() -> void:
	player.aim_source = func() -> Vector2: return player.global_position + aim * 60.0


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://rules_look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.pension = 99999
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["announce", "audit_north", "audit_side", "reel", "options"]:
		if which == "all" or which == part:
			print("== " + part)
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


# --- Shared set-up ---

func _floor() -> void:
	pad_family = ""
	ActiveDevice.reset()
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.5)
	scene = current_scene
	player = scene.player
	_hold_aim()
	scene.debug_choose_path(0)
	await _wait(0.4)
	_hold_aim()
	print("floor %s" % scene.debug_floor_def().id)


# Every counter high, the potion slot and the reel slot filled, and a row of items.
func _fill_hud(with_reel: bool) -> void:
	var run: RunState = player.run
	run.health.raise_max(10)
	run.health.heal(99)
	run.keys = 99
	run.bombs = 99
	run.potion = load("res://data/potions/healing_tonic.tres")
	if with_reel and run.held_reel.is_empty():
		run.give_reel(Eras.BUS)
	var added := 0
	for item in Content.items():
		if added >= 5:
			break
		if not run.items.has(item):
			run.add_item(item)
			added += 1
	run.changed.emit()
	scene._hud.set_pension(99999)


func _enemies(view: RoomView) -> Array:
	var out := []
	for child in view.get_children():
		if child is Enemy and not child.is_queued_for_deletion() and not child.is_dead():
			out.append(child)
	return out


func _clear_room() -> void:
	for enemy in _enemies(scene.debug_room_view()):
		enemy.take_damage(INF, Vector2.ZERO)
	await _wait(0.4)


# A plain fight room with a door on side whose neighbour there is no boss room, as [room, neighbour].
func _room_with_door(side: Vector2i) -> Array:
	var map: FloorMap = scene.debug_map()
	for room in map.rooms:
		if not FIGHTS.has(room.room_type) or scene.debug_progress().is_visited(room.id):
			continue
		if not room.doors.has(side):
			continue
		var other: FloorRoom = map.room(room.doors[side])
		if [RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_MINI_BOSS].has(other.room_type):
			continue
		return [room.id, other.id]
	return []


# Walks into the rule room from its neighbour on side, with the rule given, and returns the room's view.
func _enter_rule_room(side: Vector2i, rule: String) -> RoomView:
	var pair := _room_with_door(side)
	if pair.is_empty():
		print("NO ROOM WITH A DOOR ON %s" % side)
		return null
	var rules: RuleKeeper = scene._rules
	rules._rule_rooms.clear()
	rules._rule_rooms.append(pair[0])
	rules.set_watch(pair[0], RuleWatch.new(rule))
	scene._enter_room(pair[1])
	await _wait(0.2)
	await _clear_room()
	scene._enter_room(pair[0])
	var view: RoomView = scene.debug_room_view()
	var door: Door = view.door_to(pair[1])
	print("rule room %d entered from %d by the door on %s at %s" % [pair[0], pair[1], door.side() if door else "?", door.position if door else "?"])
	return view


# --- 1, 2: the announcement, the icon and its pulse ---

func _announce() -> void:
	await _floor()
	_fill_hud(true)
	await _wait(0.2)
	var view := await _enter_rule_room(Vector2i(1, 0), RoomRule.NO_HORSEPLAY)
	if view == null:
		return
	var stamp: RuleStamp = scene._hud._rule_stamp
	await _until(func() -> bool: return stamp._total - stamp._left >= 0.07)
	await _shot("01_announce_mid_drop")
	await _until(func() -> bool: return stamp._total - stamp._left >= 0.8)
	await _shot("01_announce_card")
	await _until(func() -> bool: return stamp._total - stamp._left >= RuleStamp.ANNOUNCE_TIME + 0.15)
	await _shot("01_announce_shrinking")
	await _until(func() -> bool: return not stamp.is_showing())
	await _wait(0.1)
	await _shot("01_icon_after_shrink", RuleIcon.AT + Vector2(14, 14))
	# Every other rule's card and icon, for the pictograms at 1x (crosses, plus shapes).
	for rule in RoomRule.ALL:
		scene._hud.announce_rule(rule)
		await _until(func() -> bool: return stamp._total - stamp._left >= 0.8)
		await _shot("01_card_%s" % rule, Vector2(320, 150))
		await _until(func() -> bool: return not stamp.is_showing())
		await _wait(0.05)
		await _shot("01_icon_%s" % rule, RuleIcon.AT + Vector2(14, 14), false)
	scene._hud.show_rule(RoomRule.NO_HORSEPLAY)
	# The pulse: the dodge held while he can't dodge (his own physics held), which is the pulse a player
	# sees through a dodge's cooldown or a buffered dodge.
	player.set_physics_process(false)
	_press("dodge")
	var icon: RuleIcon = scene._hud._rule_icon
	await _until(func() -> bool: return icon._pulse)
	var phase_hi := func() -> bool: return sin(icon._time * RuleIcon.PULSE_SPEED) > 0.85
	var phase_lo := func() -> bool: return sin(icon._time * RuleIcon.PULSE_SPEED) < -0.85
	await _until(phase_hi)
	await _shot("02_icon_pulse_bright", RuleIcon.AT + Vector2(14, 14))
	await _until(phase_lo)
	await _shot("02_icon_pulse_dim", RuleIcon.AT + Vector2(14, 14), false)
	_release("dodge")
	player.set_physics_process(true)
	print("pulse seen=%s" % icon._pulse)


# --- 3, 4: VIOLATION, AUDIT at the door, the Auditor and his attacks ---

func _audit_north() -> void:
	await _audit(Vector2i(0, -1), "north")


func _audit_side() -> void:
	await _audit(Vector2i(-1, 0), "west")


func _audit(side: Vector2i, tag: String) -> void:
	await _floor()
	_fill_hud(true)
	var view := await _enter_rule_room(side, RoomRule.NO_HORSEPLAY)
	if view == null:
		return
	var stamp: RuleStamp = scene._hud._rule_stamp
	await _until(func() -> bool: return not stamp.is_showing())
	# All regulars but one go, and that one is frozen far off, so the Auditor's walk-in is clear to see.
	var regulars := _enemies(view)
	for i in range(1, regulars.size()):
		regulars[i].dismiss()
	await _wait(0.2)
	var last: Enemy = regulars[0] if not regulars.is_empty() else null
	if last != null:
		last.set_physics_process(false)
	# He stands two cells into the room from the door, then dodges: the whistle.
	var door: Door = view.door_to(scene._arrived_from)
	var inward := -Vector2(door.side())
	_move_feet_to(door.global_position + inward * 80.0)
	await _wait(0.1)
	player.start_dodge(Vector2(-inward.y, inward.x))
	await _until(func() -> bool: return stamp.is_showing() and stamp._kind == RuleStamp.KIND_VIOLATION)
	await _wait(0.15)
	await _shot("03_%s_violation" % tag, RuleIcon.AT + Vector2(14, 14))
	var flash_of := func() -> AuditFlash:
		for child in view.get_children():
			if child is AuditFlash:
				return child
		return null
	await _until(func() -> bool: return flash_of.call() != null, 4.0)
	var flash: AuditFlash = flash_of.call()
	await _wait(0.12)
	if flash != null and is_instance_valid(flash):
		await _shot("03_%s_audit_flash" % tag, flash)
	var auditor: Enemy = null
	for enemy in _enemies(view):
		if enemy.def.id == RoomView.AUDITOR_ID:
			auditor = enemy
	if auditor == null:
		print("NO AUDITOR")
		return
	# Harold steps back so the Auditor walks in towards him.
	_move_feet_to(door.global_position + inward * 150.0)
	await _wait(0.6)
	await _shot("03_%s_auditor_arrives" % tag, auditor)
	await _until(func() -> bool: return auditor._wake_left <= 0.0, 3.0)
	await _wait(0.4)
	await _shot("03_%s_auditor_walking" % tag, auditor)
	if tag != "north":
		return
	# His clipboard swing: Harold within reach, the windup, then the swing itself.
	var behavior = auditor._behavior
	behavior._throw_cooldown = 99.0
	behavior._swing_cooldown = 0.0
	_move_feet_to(auditor.global_position + Vector2(26, 6))
	await _until(func() -> bool: return behavior._swing.is_active(), 3.0)
	await _wait(0.25)
	await _shot("04_auditor_windup", auditor)
	await _until(func() -> bool: return not behavior._swing.is_active(), 2.0)
	await _frames(2)
	await _shot("04_auditor_swing", auditor)
	# The FINED stamp: Harold out of reach, in view.
	behavior._swing_cooldown = 99.0
	behavior._throw_cooldown = 0.0
	_move_feet_to(auditor.global_position + Vector2(110, 0))
	auditor.set_physics_process(true)
	await _until(func() -> bool: return behavior._throw.is_active(), 3.0)
	await _wait(0.3)
	await _shot("04_auditor_throw_windup", auditor)
	var shot_of := func() -> Projectile:
		for child in view.get_children():
			if child is Projectile and child.look == Projectile.LOOK_FINED and not child.is_queued_for_deletion():
				return child
		return null
	await _until(func() -> bool: return shot_of.call() != null, 3.0)
	# Harold steps aside so the stamp flies on to land on the floor.
	_move_feet_to(player.feet().global_position + Vector2(0, 60))
	await _wait(0.2)
	var stamp_shot: Projectile = shot_of.call()
	if stamp_shot != null:
		await _shot("04_fined_in_flight", stamp_shot)
	var blot_of := func() -> InkBlot:
		for child in view.get_children():
			if child is InkBlot:
				return child
		return null
	await _until(func() -> bool: return blot_of.call() != null, 4.0)
	await _wait(0.2)
	var blot: InkBlot = blot_of.call()
	if blot != null:
		await _shot("04_ink_blot", blot)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


# --- 5, 6, 7: GOOD CONDUCT, the reel, Memory ready, the flicker, the eras and the return ---

func _reel() -> void:
	await _floor()
	_fill_hud(false)
	player.run.look = {
		CosmeticDef.SLOT_HAT: CosmeticDef.find("captains_hat", CosmeticDef.all()),
		CosmeticDef.SLOT_CARDIGAN: CosmeticDef.find("power_tie", CosmeticDef.all()),
	}
	player.refresh_look()
	var view := await _enter_rule_room(Vector2i(1, 0), RoomRule.TEETH_IN)
	if view == null:
		return
	var rules: RuleKeeper = scene._rules
	var stamp: RuleStamp = scene._hud._rule_stamp
	await _until(func() -> bool: return not stamp.is_showing())
	await _clear_room()
	await _until(func() -> bool: return stamp.is_showing() and stamp._kind == RuleStamp.KIND_GOOD, 2.0)
	await _shot("05_good_conduct")
	var reel: Pickup = null
	for child in view.get_children():
		if child is Pickup and child.art_id == RoomView.ART_REEL and not child.is_queued_for_deletion():
			reel = child
	if reel == null:
		print("NO REEL")
		return
	_move_feet_to(reel.global_position + Vector2(-50, 0))
	await _until(func() -> bool: return not stamp.is_showing())
	await _shot("05_reel_on_floor", reel)
	_move_feet_to(reel.global_position)
	await _until(func() -> bool: return not player.run.held_reel.is_empty(), 2.0)
	await _wait(0.1)
	await _shot("05_reel_in_slot_keys", ReelSlot.AT + Vector2(32, 6))
	print("reel %s label '%s' notice '%s'" % [player.run.held_reel, scene._hud.reel_label(), scene._hud._notice.text])
	for family in [PadInput.XBOX, PadInput.PLAYSTATION]:
		pad_family = family
		await _wait(0.15)
		await _shot("05_reel_in_slot_%s" % family.to_lower(), ReelSlot.AT + Vector2(32, 6))
		print("pad %s label '%s'" % [family, scene._hud.reel_label()])
	pad_family = ""
	ActiveDevice.using_pad = false
	await _wait(0.1)
	var first: String = player.run.held_reel
	await _play_era(view, "a")
	# The other era next: a reel handed over as a kept room's would be.
	var other: String = Eras.BUS if first == Eras.FOOTBALL else Eras.FOOTBALL
	rules._reel_taken(other)
	await _play_era(scene.debug_room_view(), "b")


# From the cleared room he stands in (or a neighbour), readies the reel at a door into an unvisited
# fight room, walks through, shoots the era's moves, clears the room and shoots the return.
func _play_era(_view: RoomView, tag: String) -> void:
	var rules: RuleKeeper = scene._rules
	var pair := await _door_pair()
	if pair.is_empty():
		print("NO DOOR PAIR")
		return
	var view: RoomView = scene.debug_room_view()
	var door: Door = view.door_to(pair[1])
	var inward := -Vector2(door.side())
	_move_feet_to(door.global_position + inward * 34.0)
	aim = -inward
	await _wait(0.2)
	await _tap("flashback")
	await _until(func() -> bool: return rules.readied_door() == pair[1], 1.0)
	await _wait(0.2)
	print("readied %d glow %s notice '%s'" % [rules.readied_door(), player.has_sepia_glow(), scene._hud._notice.text])
	await _shot("06%s_memory_ready" % tag, player)
	var era: String = player.run.held_reel
	_move_feet_to(door.global_position)
	var flicker_of := func() -> SepiaFlicker:
		for child in scene.get_children():
			if child is SepiaFlicker and not child.is_queued_for_deletion():
				return child
		return null
	await _until(func() -> bool: return flicker_of.call() != null, 2.0)
	var flicker: SepiaFlicker = flicker_of.call()
	if flicker != null:
		await _until(func() -> bool: return not is_instance_valid(flicker) or flicker._left <= SepiaFlicker.TIME * 0.5, 1.0)
		await _shot("06%s_sepia_flicker_%s" % [tag, era])
	await _wait(0.6)
	view = scene.debug_room_view()
	print("era %s player era %s room %d" % [player.run.era, player.era(), scene._current_id])
	# Everyone held still and set aside, and one foe frozen east of him for the kick or punch.
	var middle := _middle(view)
	_move_feet_to(middle + Vector2(-50, 0))
	var foes := _enemies(view)
	for i in foes.size():
		foes[i].set_physics_process(false)
		foes[i].global_position = middle + Vector2(-120 + 40 * i, 90)
	aim = Vector2.RIGHT
	await _wait(0.4)
	await _shot("07%s_%s_idle" % [tag, era], player)
	_press("move_right")
	for i in 4:
		await _wait(0.1)
		await _shot("07%s_%s_walk_%d" % [tag, era, i], player, false)
	_release("move_right")
	await _wait(0.3)
	var foe := _first_alive(foes)
	if foe != null:
		foe.global_position = player.global_position + Vector2(30, 0)
	await _wait(0.1)
	_press("attack")
	await physics_frame
	await physics_frame
	_release("attack")
	var lock: float = player._era_moves.lock_time if player._era_moves != null else 0.2
	for i in 4:
		await _shot("07%s_%s_attack_%d" % [tag, era, i], player, i == 1)
		await _wait(lock / 4.0)
	await _wait(0.5)
	# The dodge: a spin turn or a shoulder barge, mid-way.
	foe = _first_alive(foes)
	if foe != null:
		foe.global_position = player.global_position + Vector2(60, 0)
	player.start_dodge(Vector2.RIGHT)
	await _frames(3)
	await _shot("07%s_%s_dodge" % [tag, era], player)
	await _wait(0.6)
	# The throw: the football or the ticket line, in flight and after.
	_move_feet_to(middle + Vector2(-80, -20))
	aim = Vector2(1, 0.15).normalized()
	await _wait(0.2)
	await _tap("throw")
	await _wait(0.12)
	var thrown: Node2D = null
	for child in scene.get_children():
		if child is EraBall or child is TicketLine:
			thrown = child
	await _shot("07%s_%s_throw" % [tag, era], thrown if thrown != null else player)
	await _wait(0.45)
	if thrown != null and is_instance_valid(thrown):
		await _shot("07%s_%s_throw_late" % [tag, era], thrown)
	# The fight cleared: the era ends, the flicker, the line, old Harold in his hat and cardigan.
	for other in foes:
		if is_instance_valid(other):
			other.set_physics_process(true)
	await _clear_room()
	await _wait(0.4)
	aim = Vector2.RIGHT
	await _shot("07%s_return" % tag, player)
	print("after: era '%s' player era '%s' line '%s' notice '%s' look visible %s" % [
		player.run.era, player.era(), player.last_line, scene._hud._notice.text, player._look.visible if player._look != null else "none"])


func _first_alive(foes: Array) -> Enemy:
	for foe in foes:
		if is_instance_valid(foe) and not foe.is_queued_for_deletion() and not foe.is_dead():
			return foe
	return null


func _middle(view: RoomView) -> Vector2:
	var layout: RoomLayout = scene.debug_map().room(scene._current_id).layout
	var size := layout.size_in_cells()
	return view.to_global(RoomBackdrop.cell_center(layout.nearest_floor_cell(Vector2i(size.x / 2, size.y / 2))))


# A door from here (or from a neighbour he is walked into) into an unvisited fight room.
func _door_pair() -> Array:
	var map: FloorMap = scene.debug_map()
	var visited: FloorProgress = scene.debug_progress()
	var here: int = scene._current_id
	for target in map.room(here).doors.values():
		if not visited.is_visited(target) and FIGHTS.has(map.room(target).room_type):
			return [here, target]
	for mid in map.room(here).doors.values():
		if [RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_MINI_BOSS].has(map.room(mid).room_type):
			continue
		for target in map.room(mid).doors.values():
			if target != here and not visited.is_visited(target) and FIGHTS.has(map.room(target).room_type):
				scene._enter_room(mid)
				await _wait(0.2)
				await _clear_room()
				return [mid, target]
	# Anywhere on the map: an unseen fight room and a neighbour of it he is walked into.
	for room in map.rooms:
		if visited.is_visited(room.id) or not FIGHTS.has(room.room_type):
			continue
		for mid in room.doors.values():
			if [RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_MINI_BOSS].has(map.room(mid).room_type):
				continue
			scene._enter_room(mid)
			await _wait(0.2)
			await _clear_room()
			return [mid, room.id]
	return []


# --- 8, 9: the title screen and the Options Input tab ---

func _options() -> void:
	root.gui_disable_input = true
	change_scene_to_file("res://scenes/title.tscn")
	await _wait(1.2)
	var title = current_scene
	await _shot("09_title")
	title._choose("options")
	await _wait(0.4)
	var options = title.get("_overlay")
	options._show_tab(GameSettings.INPUT)
	await _wait(0.3)
	await _shot("08_options_input")
	var rows: VBoxContainer = options._rows
	var last: Control = rows.get_child(rows.get_child_count() - 1)
	print("input rows %d, rows rect %s, last row rect %s" % [rows.get_child_count(), rows.get_global_rect(), last.get_global_rect()])
	for row in rows.get_children():
		var label := ""
		for child in row.get_children():
			if child is Label or child is Button:
				label += "[%s] " % child.text
		print("  row %s %s" % [row.get_global_rect(), label])
	# A pad's labels in the same rows.
	pad_family = PadInput.PLAYSTATION
	options._show_tab(GameSettings.INPUT)
	await _wait(0.3)
	await _shot("08_options_input_pad")
	pad_family = ""
	title._close_overlay()
	await _wait(0.3)
	root.gui_disable_input = false
