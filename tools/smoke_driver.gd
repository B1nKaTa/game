extends Node

# Two runs down all five depths take far longer than the old three. Raise it again as paths get their
# real content, if a run's time comes near it.
const TIMEOUT := 1800.0
const MAX_STEPS := 150
const VIEW := Vector2(640, 360)
const AIM_TOLERANCE := 1.5
const RECORDS_PATH := 0
const CEMETERY_PATH := 1
# The second Crossroads lists its paths the same way: the open one west, the locked one east.
const OPEN_DEEP_PATH := 0
const LOCKED_DEEP_PATH := 1
# A mimic's base pay, so "pays well" means at least the base before any floor multiplier.
const MIMIC_PAY_AT_LEAST := 5
# Pension lent to the Arcade checks so every bet is covered, and taken back after.
const ARCADE_SPARE := 200
# The Waiting Room checks: Pension lent to file the forms, the poster taken at the start, and
# Condolences lent to the Decor Office, enough for the fern and the flat cap.
const FORMS_SPARE := 1000
const FIRST_POSTER := "senior_adjuster"
const DECOR_SPARE := 50

var _failed := false
var _walked_departments := false
var _checked_departments := false
var _checked_forms := false
var _checked_bounty := false
var _checked_yard := false
var _checked_decor := false
var _checked_back_room := false
var _checked_tickets := false
# Set once the cursed ticket is taken, so the next run checks it is cursed.
var _expect_cursed_run := false
var _mini_bosses_beaten := 0
var _boss_rooms_seen := 0
var _crafted_id := ""
var _cleared_rooms := {}
var _sizes_seen := {}
var _followed_a_big_room := false
var _checked_block_memory := false
var _saw_shop := false
var _talked_to_merchant := false
var _checked_props := false
var _pickups_off_solids := 0
var _checked_fight := false
var _opened_a_vault := false
var _checked_vault_room := false
var _checked_stone_memory := false
var _checked_potions := false
var _checked_fuel := false
var _checked_graveyard := false
var _checked_care_home := false
var _checked_furnace := false
var _paths_cleared := 0
var _boss_choice_count := -1
var _boss_choices_checked := 0
var _landings_reached := 0
# The deepest depth, read from the floor scene on the first run, so the walk follows its PATHS_BY_DEPTH.
var _last_depth := 0
var _checked_chests := false
var _mimics_beaten_in_loop := 0
var _checked_arcade := false
# Arcade Rooms the floors rolled whose games the loop played, by room view.
var _arcades_played := {}
# Set for the run that beats the Chairman, so it is a fast run that lost a pill in his room, which
# makes Crashing the Funeral the ending.
var _force_fast_run := false
var _checked_augustine := false
var _checked_ending := false


func _ready() -> void:
	get_tree().create_timer(TIMEOUT).timeout.connect(func(): _fail("timed out"))
	_run()


func _run() -> void:
	await _wait(0.5)
	_expect_scene("Opening")
	Game.finish_opening()
	await _wait(0.5)
	_expect_scene("WaitingRoom")
	_check(Progress.data.opening_seen, "opening is remembered")
	_check(Progress.data.floors_cleared == 0, "a fresh save has cleared nothing")
	_check(get_tree().current_scene.open_merchant_ids() == ["black_market", "optometrist"], "only the first two merchants wait at the start")

	await _check_departments_at_start()
	# The Reinforced Cane, filed to its milestone through the Black Market's own buttons.
	var upgrade := _upgrade("reinforced_cane")
	await _check_forms(upgrade)
	_take_first_bounty()
	var pension_before: int = Progress.data.pension

	# The open (west) path of every depth: the Records Basement, Sunset Shores, the Funeral Parlour and
	# so on down to the last depth.
	await _clear_every_depth(OPEN_DEEP_PATH)
	_check(Progress.data.pension > pension_before, "Pension was earned during the run")
	_check(_checked_chests, "every kind of chest was opened in the chest room")
	_check(_checked_arcade, "every Arcade game was played through its overlay")
	await _wait(2.5)
	_expect_scene("WaitingRoom")
	_check(Progress.data.floors_cleared == 1, "clearing the first floor is counted")
	for depth in range(2, _last_depth + 1):
		_check(Progress.data.clears_at(depth) == 1, "clearing a floor at depth %d is counted apart" % depth)
	for depth: int in ProgressData.FIRST_PATH_BY_DEPTH:
		_check(Progress.data.has_cleared_path(ProgressData.FIRST_PATH_BY_DEPTH[depth]), "every cleared path is remembered, depth %d" % depth)
	_check(Progress.data.legacy_clears == 0, "a fresh save keeps no old clears")
	var ids: Array = get_tree().current_scene.open_merchant_ids()
	_check(ids.has("potion_merchant") and not ids.has("bomb_merchant"), "a second-floor clear brings the potion merchant, not the bomb merchant")
	await _check_bounty_collected(get_tree().current_scene)
	await _check_decor(get_tree().current_scene)
	Progress.reload()
	_check(Progress.data.floors_cleared == 1 and _deep_clears_all_are(1) and not Progress.data.has_cleared_path("furnace_works"), "clears come back from the save as it was written")
	# A Furnace Works clear made up in memory only. Arriving saves the Boiler Room as seen, which writes
	# the made-up clear too, so the save is put back as it was afterwards.
	var save_text := FileAccess.get_file_as_string(Progress.SMOKE_PATH)
	Progress.data.record_floor_cleared(2, "furnace_works")
	Game.return_to_waiting()
	await _wait(0.5)
	ids = get_tree().current_scene.open_merchant_ids()
	_check(ids.has("potion_merchant") and ids.has("bomb_merchant"), "clearing both second-floor paths brings the bomb merchant too")
	var file := FileAccess.open(Progress.SMOKE_PATH, FileAccess.WRITE)
	file.store_string(save_text)
	file.close()
	Progress.reload()
	_check(not Progress.data.has_cleared_path("furnace_works"), "the made-up clear is gone once the save is put back")

	# The first clears opened the locked (east) path of each depth: the Cemetery, the Furnace Works, the
	# Mall and so on down.
	var pension_before_second: int = Progress.data.pension
	var found_before: int = Progress.data.endings_found.size()
	_force_fast_run = true
	await _clear_every_depth(LOCKED_DEEP_PATH)
	_force_fast_run = false
	_check(Progress.data.pension > pension_before_second, "the locked paths earn Pension too")
	await _check_ending_scene(found_before)
	await _wait(0.5)
	_expect_scene("WaitingRoom")
	_check(Progress.data.floors_cleared == 2, "clearing the second first-floor path is counted too")
	for depth in range(2, _last_depth + 1):
		_check(Progress.data.clears_at(depth) == 2, "clearing the second path at depth %d is counted too" % depth)
	for depth: int in ProgressData.PATHS_AT_DEPTH:
		for id: String in ProgressData.PATHS_AT_DEPTH[depth]:
			_check(Progress.data.has_cleared_path(id), "%s's clear is remembered" % id)
	_check(_paths_cleared == 2 * _last_depth, "every path of every depth was cleared, got %d" % _paths_cleared)
	_check(_checked_care_home, "the care home fights were checked")
	_check(_checked_furnace, "the boiler hall fights were checked")
	_check(_landings_reached == 2 * (_last_depth - 1), "both runs took every stairwell to its landing, got %d" % _landings_reached)
	ids = get_tree().current_scene.open_merchant_ids()
	_check(ids.has("potion_merchant") and ids.has("bomb_merchant"), "clearing both second-floor paths for real brings the bomb merchant")
	await _walk_every_department(get_tree().current_scene)
	await _check_training_yard(get_tree().current_scene)
	_check_condolences_earned()
	await _check_ticket_and_letters()

	Progress.add_pension(60)
	var reached: int = Progress.retirement_deposit(60)
	_check(reached == 2, "a deposit reports the tiers it reached")
	_check(not Progress.data.can_release_retirement(), "the plan is locked in the run it was paid into")

	var recipe: ItemDef = Content.recipes()[0]
	# The floor run above collects whatever recipes it happens to find, possibly this one.
	Progress.data.recipes_found.erase(recipe.id)
	Progress.add_pension(recipe.craft_price)
	_check(not Progress.craft(recipe), "crafting needs the recipe")
	Progress.find_recipe(recipe.id)
	_check(Progress.craft(recipe), "a found recipe can be crafted")
	_crafted_id = recipe.id

	# A brew bought now waits in the slot for the next run, and only one can wait.
	Progress.add_pension(100)
	var tea: PotionDef = Content.potion("swift_tea")
	var pension_before_brew: int = Progress.data.pension
	_check(Progress.brew(tea), "a brew can be bought")
	_check(Progress.data.pension == pension_before_brew - tea.price, "a brew costs its price")
	_check(not Progress.brew(Content.potion("healing_tonic")), "only one brew waits at a time")
	Progress.reload()
	_check(Progress.data.brewed_potion == "swift_tea", "the brew survives a reload")

	await _die_in_a_run()
	await _wait(2.5)
	_expect_scene("WaitingRoom")
	_check(Progress.data.brewed_potion.is_empty(), "the brew is used up by one run")
	_check(Progress.data.crafted_for_next_run.is_empty(), "the crafted item is used up by one run")
	_check(Progress.data.is_unlocked(recipe.id), "the crafted item stays in rotation")
	_check(Progress.make_run().can_offer(recipe), "new runs can offer the crafted item")
	_check(Progress.data.can_release_retirement(), "the plan opens in a later run")
	Progress.reload()
	_check(Progress.data.retirement_balance == 60, "the plan survives a reload")
	var before_release: int = Progress.data.pension
	_check(Progress.release_retirement() == 60, "cashing out pays the balance")
	_check(Progress.data.pension == before_release + 60, "cashing out adds to Pension")

	var pension_saved: int = Progress.data.pension
	Progress.reload()
	_check(Progress.data.pension == pension_saved, "Pension survives a reload")
	_check(Progress.data.level_of(upgrade.id) == 2, "the cane's two filed levels survive a reload")
	_check(Progress.data.choice_of(upgrade) == UpgradeDef.OPTION_B, "the cane's refiled option survives a reload")

	await _check_dev_start()

	_check(_checked_departments and _checked_forms and _checked_bounty and _checked_decor, "the Waiting Room checks of the first visits ran")
	_check(_walked_departments and _checked_back_room and _checked_yard and _checked_tickets, "the Waiting Room checks after every floor ran")
	_check(_checked_augustine and _checked_ending, "Augustine's scene and the ending scene were checked")
	if not _failed:
		print("SMOKE PASS paths cleared: %d, landings reached: %d, boss choices checked: %d, rooms of sizes %s, big room view checked: %s, block memory checked: %s, props checked: %s, fight checked: %s, graveyard checked: %s, care home checked: %s, furnace checked: %s, vault opened: %s, potions checked: %s, fuel checked: %s, pickups off solids: %d, chests checked: %s, mimics beaten on the way: %d, arcade checked: %s, arcade rooms played on the way: %d" % [_paths_cleared, _landings_reached, _boss_choices_checked, str(_sizes_seen.keys()), str(_followed_a_big_room), str(_checked_block_memory), str(_checked_props), str(_checked_fight), str(_checked_graveyard), str(_checked_care_home), str(_checked_furnace), str(_opened_a_vault), str(_checked_potions), str(_checked_fuel), _pickups_off_solids, str(_checked_chests), _mimics_beaten_in_loop, str(_checked_arcade), _arcades_played.size()])
		print("SMOKE PASS waiting room: departments checked at start: %s, forms checked: %s, bounty collected: %s, decor checked: %s, departments walked: %s, back room played: %s, yard checked: %s, tickets and letters checked: %s, mini bosses beaten: %d, Condolences: %d" % [str(_checked_departments), str(_checked_forms), str(_checked_bounty), str(_checked_decor), str(_walked_departments), str(_checked_back_room), str(_checked_yard), str(_checked_tickets), _mini_bosses_beaten, Progress.data.condolences])
		get_tree().quit(0)


# Whether every depth below the first has been cleared exactly count times.
func _deep_clears_all_are(count: int) -> bool:
	for depth in range(2, _last_depth + 1):
		if Progress.data.clears_at(depth) != count:
			return false
	return true


# One run down every depth the floor scene lists, taking the path at path_index (0 west, 1 east) from
# each Crossroads: at each depth the Crossroads and its signs, the whole floor, the boss's items and the
# stairwell to the next landing, which _take_the_stairwell checks for its name and its heal. The last
# depth's floor boss ends the run. A new path is covered here as soon as PATHS_BY_DEPTH lists it.
func _clear_every_depth(path_index: int) -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	_last_depth = scene.LAST_DEPTH
	_check(scene.PATHS_BY_DEPTH.size() == _last_depth, "every depth down to the last lists its paths")
	var starting_pills: int = scene.player.run.stats.max_pills
	_check(starting_pills >= 4, "run starts with pills")
	# Once the Purser's Office is open, the Bon Voyage Bag may put a potion in the slot.
	var bag: String = scene.debug_bon_voyage()
	_check(bag.is_empty() != BonVoyage.is_packed(Progress.data), "the Bon Voyage Bag is packed only while the Purser's Office is open, got '%s'" % bag)
	var bag_potion := not bag.is_empty() and bag != BonVoyage.THERMOS
	if bag_potion:
		_check(scene.player.run.potion != null and scene.player.run.potion.id == bag, "the bag's potion is in the slot")
	else:
		_check(scene.player.run.potion == null, "a run starts with an empty slot when nothing was brewed")
	if not _checked_potions:
		await _check_potion_drinking(scene)
	for depth in range(1, _last_depth + 1):
		_check(scene.debug_depth() == depth, "the run has reached depth %d, got %d" % [depth, scene.debug_depth()])
		await _check_crossroads(scene)
		await _walk_a_path(scene, path_index)
		if _force_fast_run and depth == _last_depth:
			scene.player.run.play_time = 0.0
			scene.player.run.boss_room_pill_lost = true
		await _clear_whole_floor(scene, path_index)
		if _failed:
			return
		if depth == _last_depth:
			break
		_check(not scene.is_over, "a floor boss at depth %d does not end the run" % depth)
		await _take_the_stairwell(scene)
		if _failed:
			return
	await _wait(0.1)
	_check(scene.is_over, "a floor boss at the last depth, %d, ends the run" % _last_depth)
	if scene.debug_floor_def().floor_boss.id == EndingRules.AUGUSTINE:
		await _check_augustine_scene(scene)
	_check(_hud_message(scene) == "FLOOR CLEARED", "the run ends with FLOOR CLEARED, got '%s'" % _hud_message(scene))


# Explores every room through its real door, secret room included, and leaves the boss for last.
func _clear_whole_floor(scene: Node, path_index: int) -> void:
	# Each floor checks all of this for itself, whatever the last one saw.
	_boss_rooms_seen = 0
	_cleared_rooms = {}
	_saw_shop = false
	_talked_to_merchant = false
	_opened_a_vault = false
	_checked_vault_room = false
	_checked_stone_memory = false
	_checked_block_memory = false
	_followed_a_big_room = false
	var map: FloorMap = scene.debug_map()
	var depth: int = scene.debug_depth()
	var choices_before := _boss_choices_checked
	if depth == 1 and path_index == CEMETERY_PATH and not _checked_graveyard:
		await _check_graveyard_fights(scene)
	if depth == 2 and path_index == OPEN_DEEP_PATH and not _checked_care_home:
		await _check_care_home_fights(scene)
	if depth == 2 and path_index == LOCKED_DEEP_PATH and not _checked_furnace:
		await _check_furnace_fights(scene)
	var walked_back := false
	var guard := 0
	while not scene.is_cleared and not _failed and guard < MAX_STEPS:
		guard += 1
		if map.room(scene.debug_current_id()).room_type == RoomLayout.TYPE_VAULT and not _checked_vault_room:
			await _check_vault_room(scene)
		await _clear_room(scene)
		if scene.is_cleared:
			break
		await _check_stone_memory(scene)
		await _check_camera(scene)
		await _check_big_room_view(scene)
		if not _checked_props:
			await _check_props_room(scene)
		if not _checked_fight:
			await _check_fight_room(scene)
		var at: int = scene.debug_current_id()
		if not walked_back and at != map.start_id:
			walked_back = true
			await _walk_back_and_return(scene, at)
		if map.room(at).room_type == RoomLayout.TYPE_SHOP:
			await _check_merchant(scene)
		if map.room(at).room_type == RoomLayout.TYPE_ARCADE and not _arcades_played.has(scene.debug_room_view().get_instance_id()):
			_arcades_played[scene.debug_room_view().get_instance_id()] = true
			await _play_each_table(scene, scene.debug_room_view(), null)
		if map.room(at).room_type == RoomLayout.TYPE_SHOP and not _saw_shop:
			_check_shop(scene)
		if at != map.start_id:
			await _check_a_broken_block_stays_broken(scene, at)
		var next: int = map.next_step(at, _next_goal(scene, map))
		await _walk_through_door(scene, next)
	_check(scene.is_cleared, "floor can be cleared")
	_check(scene.debug_depth() == depth, "nothing took him down before the floor was done")
	_check(_boss_choices_checked == choices_before + 1, "the floor boss's item choice was checked")
	_check(walked_back, "the check walked back through a door")
	_check(_saw_shop, "the shop was checked")
	_check(_talked_to_merchant, "the shop's merchant was talked to")
	_check(_boss_rooms_seen >= 2, "both bosses showed a boss bar")
	var has_vault := false
	for room in map.rooms:
		has_vault = has_vault or room.room_type == RoomLayout.TYPE_VAULT
	_check(_opened_a_vault == has_vault, "a floor with a vault had it opened with a max level Thermos")
	_check(_checked_vault_room == has_vault, "a floor with a vault had its vault room checked")
	_check(_checked_stone_memory == has_vault, "a floor with a vault checked its broken stone staying broken")
	for room in map.rooms:
		_check(scene.debug_progress().is_visited(room.id), "room %d (%s) was explored" % [room.id, room.room_type])
	if scene.is_cleared:
		_paths_cleared += 1


func _next_goal(scene: Node, map: FloorMap) -> int:
	var at: int = scene.debug_current_id()
	var best: int = map.boss_id
	var best_steps := 1000
	for room in map.rooms:
		if room.id == map.boss_id or scene.debug_progress().is_visited(room.id):
			continue
		var steps := _steps_between(map, at, room.id)
		if steps < best_steps:
			best = room.id
			best_steps = steps
	return best


func _steps_between(map: FloorMap, from_id: int, to_id: int) -> int:
	var steps := 0
	var cursor := from_id
	while cursor != to_id and steps < map.rooms.size():
		cursor = map.next_step(cursor, to_id)
		steps += 1
	return steps


func _walk_through_door(scene: Node, target_id: int) -> void:
	var map: FloorMap = scene.debug_map()
	var from_id: int = scene.debug_current_id()
	var target := map.room(target_id)
	if target.room_type == RoomLayout.TYPE_SECRET and scene.debug_room_view().door_to(target_id) == null:
		await _open_secret_crack(scene, target_id)
	if target.room_type == RoomLayout.TYPE_VAULT and scene.debug_room_view().door_to(target_id) == null:
		await _open_vault_stone(scene, target_id)
	var door: Door = scene.debug_room_view().door_to(target_id)
	_check(door != null, "room %d has a door to room %d" % [from_id, target_id])
	if door == null:
		return
	await _step_away_from(scene, door, map.room(from_id))
	if target.room_type == RoomLayout.TYPE_TREASURE and door.requires_key:
		await _unlock_treasure_door(scene, door, from_id)
	# Spending the Slip while standing on the door walks him through it at once.
	if scene.debug_current_id() == from_id:
		_stand_on(scene, door)
		await _wait(0.15)
	_check(scene.debug_current_id() == target_id, "walking onto a door enters room %d" % target_id)
	_check_arrival(scene, map, target_id, from_id)
	await _wait(0.2)
	_check(scene.debug_current_id() == target_id, "arriving on a door does not bounce him back")


func _check_arrival(scene: Node, map: FloorMap, room_id: int, from_id: int) -> void:
	var room := map.room(room_id)
	var side := room.side_towards(from_id)
	_check(side == map.room(from_id).side_towards(room_id) * -1, "the door he arrives on faces where he came from")
	var feet: Vector2 = scene.player.feet().global_position
	var expected := RoomBackdrop.cell_center(room.layout.door_cell(side))
	_check(feet.distance_to(expected) < Door.ENTER_RADIUS, "he arrives standing on the door of room %d (%s), feet %s, door %s" % [room_id, room.layout.resource_path, str(feet), str(expected)])
	_sizes_seen[room.layout.size_class()] = true


func _unlock_treasure_door(scene: Node, door: Door, from_id: int) -> void:
	var run: RunState = scene.player.run
	while run.keys > 0:
		run.use_key()
	_stand_on(scene, door)
	await _wait(0.15)
	_check(scene.debug_current_id() == from_id, "the treasure door stays shut without a Slip")
	run.add_key()
	await get_tree().process_frame
	Input.action_press("interact")
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release("interact")
	await _wait(0.05)
	_check(not door.requires_key, "a Slip opens the treasure door")
	_check(run.keys == 0, "opening the treasure door spends the Slip")


func _open_secret_crack(scene: Node, target_id: int) -> void:
	var view: RoomView = scene.debug_room_view()
	var room: FloorRoom = scene.debug_map().room(scene.debug_current_id())
	var side := room.side_towards(target_id)
	var cell := room.layout.door_cell(side)
	_check(view.door_to(target_id) == null, "a secret room shows no door until the crack opens")
	var pills_before: int = scene.player.run.health.pills
	# Far enough that the blast can't reach him, as in play.
	scene.player.global_position = Player.arrival_position(room.layout.nearest_floor_cell(cell - side * 4))
	view.place_bomb(RoomBackdrop.cell_center(cell))
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(view.door_to(target_id) != null, "a Thermos by the crack opens the secret door")
	_check(scene.player.run.health.pills == pills_before, "the blast did not reach him")


func _step_away_from(scene: Node, door: Door, room: FloorRoom) -> void:
	var side := room.side_towards(door.target_id())
	var cell := room.layout.nearest_floor_cell(room.layout.door_cell(side) - side * 3)
	scene.player.global_position = Player.arrival_position(cell)
	await _wait(0.05)


func _stand_on(scene: Node, door: Door) -> void:
	scene.player.global_position = door.global_position - Player.FEET_OFFSET


func _check_camera(scene: Node) -> void:
	await get_tree().process_frame
	var camera: Camera2D = scene.debug_camera()
	var cells: Vector2i = scene.debug_map().room(scene.debug_current_id()).layout.size_in_cells()
	var room_size := Vector2(cells) * RoomBackdrop.TILE
	var view_rect := Rect2(camera.position - VIEW / 2.0, VIEW)
	for axis in 2:
		if room_size[axis] <= VIEW[axis]:
			_check(is_equal_approx(camera.position[axis], roundf(room_size[axis] / 2.0)), "a room that fits stays centered")
		else:
			_check(view_rect.position[axis] >= 0.0 and view_rect.end[axis] <= room_size[axis], "the camera stops at the room's edges")
	# Aiming reads the mouse through the camera, so it must land where the view is now.
	var mouse_on_screen: Vector2 = scene.get_viewport().get_mouse_position()
	var expected_mouse: Vector2 = view_rect.position + camera.offset + mouse_on_screen
	var aim_error: float = scene.player.get_global_mouse_position().distance_to(expected_mouse)
	_check(aim_error <= AIM_TOLERANCE, "aiming follows the camera, off by %f" % aim_error)


# In a room too big for the view, the camera must track him to the corners, keep
# shaking and aiming correct as it moves, and leave the HUD where it is.
func _check_big_room_view(scene: Node) -> void:
	var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
	if layout.size_class() != RoomLayout.SIZE_LARGE or _followed_a_big_room:
		return
	_followed_a_big_room = true
	var size := layout.size_in_cells()
	var positions_seen := {}
	var spots: Array[Vector2i] = [Vector2i(1, 1), Vector2i(size.x - 2, 1), Vector2i(1, size.y - 2), size - Vector2i(2, 2), size / 2]
	for spot in spots:
		scene.player.global_position = Player.arrival_position(layout.nearest_floor_cell(spot))
		await _wait(0.05)
		await _check_camera(scene)
		positions_seen[scene.debug_camera().position] = true
	_check(positions_seen.size() >= 4, "the camera follows him around a big room")
	# He is held still while the screen shakes, since a rolling deck, a ring or an escalator would
	# carry him and the camera with him.
	scene.player.set_physics_process(false)
	await get_tree().process_frame
	var rest: Vector2 = scene.debug_camera().position
	scene.debug_feedback().on_hurt()
	var shook := false
	for i in 5:
		await get_tree().process_frame
		shook = shook or not scene.debug_camera().offset.is_zero_approx()
		await _check_camera(scene)
	scene.player.set_physics_process(true)
	_check(shook, "the screen still shakes in a big room")
	_check(scene.debug_camera().position == rest, "shaking does not move where the camera rests")
	var hud := _find_hud(scene)
	_check(not hud.follow_viewport_enabled and hud.offset == Vector2.ZERO, "the HUD stays put")


func _walk_back_and_return(scene: Node, here_id: int) -> void:
	await _wait(0.5)
	var map: FloorMap = scene.debug_map()
	var pension_before: int = Progress.data.pension
	var pickups_here := _resting_pickups()
	var back_id: int = map.next_step(here_id, map.start_id)
	await _walk_through_door(scene, back_id)
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "a cleared room stays clear when walking back")
	_check(Progress.data.pension == pension_before, "walking back earns no Pension")
	var big_map: FloorMapView = scene.debug_big_map()
	big_map.set_open(true)
	_check(get_tree().paused, "the big map pauses the game")
	big_map.set_open(false)
	_check(not get_tree().paused, "closing the big map resumes the game")
	await _walk_through_door(scene, here_id)
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "a cleared room stays clear when returning")
	_check(Progress.data.pension == pension_before, "returning earns no Pension")
	_check(_resting_pickups() == pickups_here, "a room remembers pickups left behind")


# Once per run, in the first room with a plain block, since not every room has one.
func _check_a_broken_block_stays_broken(scene: Node, here_id: int) -> void:
	if _checked_block_memory:
		return
	var block := _plain_block()
	if block == null:
		return
	_checked_block_memory = true
	_check_a_thermos_left_behind_comes_back(scene)
	block.take_blast()
	await _wait(0.1)
	var blocks_left := _plain_block_count()
	var map: FloorMap = scene.debug_map()
	await _walk_through_door(scene, map.next_step(here_id, map.start_id))
	await _walk_through_door(scene, here_id)
	_check(_plain_block_count() == blocks_left, "a broken block stays broken on return")


func _check_a_thermos_left_behind_comes_back(scene: Node) -> void:
	var run: RunState = scene.player.run
	var view: RoomView = scene.debug_room_view()
	var before := run.bombs
	view.place_bomb(scene.player.global_position)
	view.clear_passing_effects()
	_check(run.bombs == before + 1, "a Thermos left with its fuse burning goes back in the pocket")
	run.use_bomb()


func _plain_block() -> BreakableBlock:
	for block in get_tree().get_nodes_in_group("breakable"):
		if not block is SecretWall and not block is ReinforcedRock and not block is RetirementStation and not block is ArcadeTable and not block.is_queued_for_deletion():
			return block
	return null


func _plain_block_count() -> int:
	var count := 0
	for block in get_tree().get_nodes_in_group("breakable"):
		if not block is SecretWall and not block is ReinforcedRock and not block is RetirementStation and not block is ArcadeTable and not block.is_queued_for_deletion():
			count += 1
	return count


func _check_shop(scene: Node) -> void:
	var view: RoomView = scene.debug_room_view()
	var stations := 0
	for child in view.get_children():
		if child is RetirementStation:
			stations += 1
	_check(stations == 1, "the shop holds the Retirement Plan")
	var stock := 0
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.prompt == RoomView.SHOP_PROMPT:
			stock += 1
	# Heal, Slip and Thermos are always sold. Items already found this run are not, so up to two may be missing.
	_check(stock >= 3 and stock <= 5, "the shop shows its stock, found %d" % stock)
	_saw_shop = true


# Every shop visited has one merchant, and each press of interact beside him brings his next line.
func _check_merchant(scene: Node) -> void:
	var view: RoomView = scene.debug_room_view()
	var merchants: Array[Npc] = []
	for child in view.get_children():
		if child is Npc:
			merchants.append(child as Npc)
	_check(merchants.size() == 1, "a shop has one merchant, found %d" % merchants.size())
	if merchants.size() != 1:
		return
	var merchant := merchants[0]
	var lines := merchant.def.lines
	_put_feet(scene, merchant.global_position + Vector2(0, 8))
	await _wait(0.1)
	_check(merchant.is_near(), "beside the merchant Grandpa is offered a talk")
	# A shop visited again carries on where he left off.
	await _press("interact")
	var said := lines.find(merchant.showing())
	_check(said >= 0, "a press says one of his lines, '%s'" % merchant.showing())
	await _press("interact")
	_check(merchant.showing() == lines[(said + 1) % lines.size()], "the next press says his next line, '%s'" % merchant.showing())
	_talked_to_merchant = true


func _resting_pickups() -> int:
	var count := 0
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not pickup.is_flying() and not pickup.is_queued_for_deletion():
			count += 1
	return count


func _clear_room(scene: Node) -> void:
	await _wait(0.1)
	var room_id: int = scene.debug_current_id()
	if _cleared_rooms.has(room_id):
		return
	_cleared_rooms[room_id] = true
	var cells: Vector2i = scene.debug_map().room(room_id).layout.size_in_cells()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		_check(enemy.room_cells == cells, "enemies clamp to the room's real size")
	var hud := _find_hud(scene)
	var boss_here := false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.def.is_boss:
			boss_here = true
	if boss_here:
		_boss_rooms_seen += 1
		_check(hud.is_boss_bar_visible(), "boss bar is visible during a boss fight")
	var view: RoomView = scene.debug_room_view()
	var map: FloorMap = scene.debug_map()
	var is_floor_boss_room: bool = map.room(room_id).room_type == RoomLayout.TYPE_FLOOR_BOSS
	var pool_before := _offerable_items(scene.player.run)
	_boss_choice_count = -1
	if is_floor_boss_room:
		view.boss_choice_dropped.connect(_on_boss_choice_dropped)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.take_damage(INF, Vector2.ZERO)
	await _wait(0.1)
	if boss_here:
		_check(not hud.is_boss_bar_visible(), "boss bar is hidden after the boss falls")
	if is_floor_boss_room:
		await _check_boss_choice(scene, view, pool_before)
	_check_pickups_off_solids(scene, room_id)
	await _beat_mimics_first()
	var stairs: Door = view.stairwell()
	for pickup in get_tree().get_nodes_in_group("pickups"):
		# Walking onto a pickup near a door can leave the room, and then the rest are out of reach.
		if scene.is_over or scene.debug_current_id() != room_id or scene.debug_map() != map:
			return
		if not is_instance_valid(pickup) or not pickup.is_inside_tree():
			continue
		# The stairwell is taken on purpose later, never by walking onto a coin beside it.
		if stairs != null and pickup.global_position.distance_to(stairs.global_position) < Door.ENTER_RADIUS * 3.0:
			continue
		if pickup.requires_interact:
			# Buying could spend the Pension this check expects to see earned.
			if pickup.prompt != RoomView.SHOP_PROMPT:
				pickup.collect()
				await _wait(0.05)
			continue
		scene.player.global_position = pickup.global_position
		await _wait(0.05)


func _find_hud(scene: Node) -> Hud:
	for child in scene.get_children():
		if child is Hud:
			return child
	return null


# The big centered line the run ends on.
func _hud_message(scene: Node) -> String:
	var hud := _find_hud(scene)
	return hud._message.text if hud != null else ""


func _die_in_a_run() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	if _expect_cursed_run:
		_expect_cursed_run = false
		_check(scene.player.run.cursed, "the run after taking the cursed ticket is cursed")
		_check(not Progress.data.cursed_next_run, "a cursed ticket lasts one run")
		_check(is_equal_approx(scene.player.run.enemy_health_mult(), TicketRules.CURSED_HEALTH_MULT), "a cursed run's enemies are tougher")
	await _walk_a_path(scene, RECORDS_PATH)
	if not _crafted_id.is_empty():
		_check(scene.player.run.has_item(_crafted_id), "the crafted item starts the next run")
	var carried: PotionDef = scene.player.run.potion
	_check(carried != null and carried.id == "swift_tea", "the brewed potion starts the next run in the slot")
	# A Life Jacket would leave him a pill, so its saves are spent first.
	scene.player.run.health.lethal_saves = 0
	scene.player.run.health.hit(999)
	await _wait(0.1)
	_check(scene.is_over, "death ends the run")


# Each debug shortcut (F3, F5, F6) lands on its depth's landing with everything bought and both of
# that depth's paths open, and leaves the save exactly as it was however the run ends.
func _check_dev_start() -> void:
	var depths: Array = DevStart.START_KEYS.values()
	depths.sort()
	_check(depths == [3, 4, 5], "the dev runs start at floors 3, 4 and 5, got %s" % str(depths))
	for start_depth: int in depths:
		await _check_dev_start_at(start_depth)
		if _failed:
			return


func _check_dev_start_at(start_depth: int) -> void:
	var save_text := FileAccess.get_file_as_string(Progress.SMOKE_PATH)
	var pension_before: int = Progress.data.pension
	Game.begin_dev_run(start_depth)
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	_check(Progress.is_dev_run(), "the shortcut starts a dev run")
	_check(Progress.dev_start_depth == start_depth, "the dev run carries its start depth %d" % start_depth)
	_check(scene.debug_depth() == start_depth, "the dev run starts at depth %d, got %d" % [start_depth, scene.debug_depth()])
	_check(scene.debug_floor_def().id == "landing_%d" % start_depth, "the dev run starts on the Floor %d landing" % start_depth)
	_check(scene.debug_floor_def().display_name == "Floor %d" % start_depth, "the landing says Floor %d" % start_depth)
	_check(Progress.data.clears_at(start_depth) == 1, "the dev profile counts one clear at depth %d" % start_depth)
	for def: UpgradeDef in Content.upgrades():
		_check(Progress.data.level_of(def.id) == def.max_level(), "%s is at its top level" % def.id)
	var run: RunState = scene.player.run
	_check(run.keys == DevStart.KEYS and run.bombs == DevStart.BOMBS and run.items.size() >= DevStart.ITEMS.size(), "the dev kit is carried")
	_check(run.potion != null and run.potion.id == DevStart.BREWED_POTION, "the dev brew is in the slot")
	var map: FloorMap = scene.debug_map()
	var landing: FloorRoom = map.room(scene.debug_current_id())
	_check(landing.room_type == RoomLayout.TYPE_LANDING, "he stands on the landing")
	await _walk_through_door(scene, landing.doors.values()[0])
	_check(map.room(scene.debug_current_id()).room_type == RoomLayout.TYPE_CROSSROADS, "the landing leads to its depth's Crossroads")
	Progress.add_pension(123)
	# The locked east path opens as after a clear at its depth.
	var east: String = ProgressData.PATHS_AT_DEPTH[start_depth][LOCKED_DEEP_PATH]
	scene.debug_choose_path(LOCKED_DEEP_PATH)
	await _wait(0.3)
	_check(scene.debug_floor_def().id == east, "%s can be entered from the dev run, got %s" % [east, scene.debug_floor_def().id])
	run.health.lethal_saves = 0
	run.health.hit(999)
	await _wait(0.1)
	_check(scene.is_over, "death ends the dev run")
	await _wait(2.5)
	_expect_scene("WaitingRoom")
	_check(not Progress.is_dev_run(), "the dev run is over in the Waiting Room")
	_check(Progress.dev_start_depth == DevStart.START_DEPTH, "the start depth falls back to floor 3")
	_check(Progress.data.pension == pension_before, "Pension from the dev run is not kept")
	_check(FileAccess.get_file_as_string(Progress.SMOKE_PATH) == save_text, "the save file is untouched by the dev run")
	_check(not FileAccess.file_exists(Progress.DEV_PATH), "the dev run's file is thrown away")


# --- The Waiting Room: departments, forms, the bounty, decor, the yard, tickets and letters ---

func _upgrade(id: String) -> UpgradeDef:
	for def: UpgradeDef in Content.upgrades():
		if def.id == id:
			return def
	return null


func _poster(id: String) -> BountyDef:
	for def: BountyDef in BountyBoard.all():
		if def.id == id:
			return def
	return null


# Every Control under a node, leaving out rows a panel has already thrown away on a rebuild.
func _controls_in(node: Node) -> Array:
	var found := []
	for child in node.get_children():
		if child.is_queued_for_deletion():
			continue
		if child is Control:
			found.append(child)
		found.append_array(_controls_in(child))
	return found


func _button_named(panel: Node, text: String) -> Button:
	for control in _controls_in(panel):
		if control is Button and control.text == text:
			return control
	return null


func _button_starting(panel: Node, prefix: String) -> Button:
	for control in _controls_in(panel):
		if control is Button and control.text.begins_with(prefix):
			return control
	return null


# The button on the same row as the label that starts with prefix, as a form or a decor row has.
func _row_button(panel: Node, prefix: String) -> Button:
	for control in _controls_in(panel):
		if control is Label and control.text.begins_with(prefix):
			for sibling in control.get_parent().get_children():
				if sibling is Button and not sibling.is_queued_for_deletion():
					return sibling
	return null


# Opens a station's panel as pressing interact beside it would, in the department he stands in.
func _open_station(scene: Node, id: String) -> CanvasLayer:
	scene.use_station(id)
	await _wait(0.1)
	var panel: CanvasLayer = scene.open_panel()
	_check(panel != null, "the %s opens its panel" % id)
	return panel


# Closes the open panel by its Leave button, the way a player does.
func _leave_panel(scene: Node) -> void:
	var panel: CanvasLayer = scene.open_panel()
	if panel == null:
		return
	var leave := _button_named(panel, "Leave")
	_check(leave != null, "the panel has a Leave button")
	if leave != null:
		leave.pressed.emit()
	await _wait(0.1)
	_check(scene.open_panel() == null, "Leave closes the panel")


func _walk_to_department(scene: Node, id: String) -> void:
	var map: FloorMap = scene.debug_map()
	var target := Departments.index_of(id)
	var guard := 0
	while scene.debug_current_id() != target and not _failed and guard < map.rooms.size():
		guard += 1
		await _walk_through_door(scene, map.next_step(scene.debug_current_id(), target))
	_check(scene.current_department() == id, "walked to the %s, stands in the %s" % [id, scene.current_department()])


# A fresh save opens the lobby and the corridors only. The hallway's door walks him there, and the
# Bounty Office's chained door keeps him in the lobby, and out of the annexe beyond it.
func _check_departments_at_start() -> void:
	var scene := get_tree().current_scene
	_check(str(scene.open_department_ids()) == str(Departments.corridor_ids()), "only the lobby and the corridors are open at the start, got %s" % str(scene.open_department_ids()))
	_check(scene.current_department() == Departments.LOBBY, "he starts in the lobby")
	await _walk_to_department(scene, Departments.HALLWAY)
	await _walk_to_department(scene, Departments.LOBBY)
	var door: Door = scene.debug_room_view().door_to(Departments.index_of(Departments.BOUNTY_OFFICE))
	_check(door != null and door.chained, "the Bounty Office's door is chained")
	if door != null:
		await _step_away_from(scene, door, scene.debug_map().room(scene.debug_current_id()))
		_stand_on(scene, door)
		await _wait(0.3)
		_check(scene.current_department() == Departments.LOBBY, "a chained door keeps him in the lobby")
		await _step_away_from(scene, door, scene.debug_map().room(scene.debug_current_id()))
	_checked_departments = true


# Files the cane's first level and its milestone with Lightweight through the Black Market's buttons,
# then refiles at the forms counter: free once, then the fee.
func _check_forms(cane: UpgradeDef) -> void:
	var scene := get_tree().current_scene
	_check(cane != null, "the Reinforced Cane form exists")
	if cane == null:
		return
	Progress.add_pension(FORMS_SPARE)
	var panel := await _open_station(scene, "black_market")
	_check(panel is MerchantPanel, "the Black Market opens its forms")
	if not panel is MerchantPanel:
		return
	var first_level := _row_button(panel, cane.display_name)
	_check(first_level != null and first_level.text == "File" and not first_level.disabled, "the cane's first level can be filed")
	if first_level == null:
		return
	first_level.pressed.emit()
	await _wait(MerchantPanel.STAMP_TIME + 0.3)
	_check(Progress.data.level_of(cane.id) == 1, "filing stamps the cane's first level")
	var lightweight := _button_named(panel, "File: %s" % cane.option_name(UpgradeDef.OPTION_B))
	_check(lightweight != null and not lightweight.disabled, "the milestone offers %s to file" % cane.option_name(UpgradeDef.OPTION_B))
	if lightweight == null:
		return
	lightweight.pressed.emit()
	await _wait(MerchantPanel.STAMP_TIME + 0.3)
	_check(Progress.data.level_of(cane.id) == 2 and Progress.data.choice_of(cane) == UpgradeDef.OPTION_B, "filing the milestone stores option b")
	_check(Progress.make_run().stats.swing_speed > 1.0, "Lightweight swings faster")
	await _leave_panel(scene)
	_check(Progress.data.refile_price(cane) == 0, "the first refile is free")
	var pension: int = Progress.data.pension
	panel = await _open_station(scene, "forms_counter")
	_check(panel is RefilePanel, "the forms counter opens the refile panel")
	if not panel is RefilePanel:
		return
	var refile := _button_starting(panel, cane.display_name + ":")
	_check(refile != null and not refile.disabled, "the cane can be refiled")
	if refile == null:
		return
	refile.pressed.emit()
	await _wait(0.1)
	_check(Progress.data.choice_of(cane) == UpgradeDef.OPTION_A and Progress.data.pension == pension, "the free refile switches to option a and costs nothing")
	refile = _button_starting(panel, cane.display_name + ":")
	_check(refile != null and not refile.disabled, "the cane can be refiled again")
	if refile == null:
		return
	refile.pressed.emit()
	await _wait(0.1)
	_check(Progress.data.choice_of(cane) == UpgradeDef.OPTION_B and Progress.data.pension == pension - ProgressData.REFILE_FEE, "the second refile costs %d" % ProgressData.REFILE_FEE)
	await _leave_panel(scene)
	_checked_forms = true


# The rules let a reachable poster be taken before its office opens, so this checks only the rules.
func _take_first_bounty() -> void:
	_check(not Departments.is_open(Departments.BOUNTY_OFFICE, Progress.data), "the Bounty Office is closed at the start")
	var poster := _poster(FIRST_POSTER)
	_check(poster != null and Progress.take_bounty(poster), "a reachable poster can be taken")
	Progress.reload()
	_check(Progress.data.bounty_taken == FIRST_POSTER, "the taken poster survives a reload")


# The first run cleared the open path of every depth: the Records Basement, Sunset Shores, the Funeral
# Parlour, the Last Resort Cruise and Departures, which open the Bounty Office, the Apothecary Wing, the
# Decor Office, the Purser's Office and Duty Free. The poster is collected at the board.
func _check_bounty_collected(scene: Node) -> void:
	var wanted := [Departments.LOBBY, Departments.HALLWAY, Departments.BOUNTY_OFFICE, Departments.APOTHECARY_WING, Departments.DECOR_OFFICE,
		Departments.ANNEXE, Departments.UPPER_LANDING, Departments.PURSERS_OFFICE, Departments.DUTY_FREE]
	_check(str(scene.open_department_ids()) == str(wanted), "the first clears open exactly their departments, got %s" % str(scene.open_department_ids()))
	_check(Progress.data.bounty_won, "beating the %s won the taken poster" % FIRST_POSTER)
	var poster := _poster(FIRST_POSTER)
	if poster == null:
		return
	scene.debug_enter_department(Departments.BOUNTY_OFFICE)
	await _wait(0.2)
	_check(scene.current_department() == Departments.BOUNTY_OFFICE, "the Bounty Office can be entered")
	var had_recipe: bool = Progress.data.has_recipe(poster.extra_id)
	var pension: int = Progress.data.pension
	var condolences: int = Progress.data.condolences
	var panel := await _open_station(scene, "bounty_board")
	_check(panel is BountyPanel, "the board opens the wanted posters")
	if panel is BountyPanel:
		var collect := _button_named(panel, BountyPanel.COLLECT)
		_check(collect != null and not collect.disabled, "the won poster can be collected")
		if collect != null:
			collect.pressed.emit()
			await _wait(0.1)
		var again := roundi(poster.pension * BountyBoard.FOUND_RECIPE_SHARE) if had_recipe else 0
		_check(Progress.data.pension == pension + poster.pension + again, "the poster pays its Pension, %d to %d" % [pension, Progress.data.pension])
		_check(Progress.data.condolences == condolences + poster.condolences, "the poster pays its Condolences")
		_check(Progress.data.has_recipe(poster.extra_id), "Agnes has the poster's recipe")
		_check(Progress.data.bounty_taken.is_empty() and Progress.data.bounties_retired.has(poster.id), "the collected poster is retired")
		await _leave_panel(scene)
	scene.debug_enter_department(Departments.LOBBY)
	await _wait(0.2)
	_checked_bounty = true


# Only the purchases are under test, so the Condolences are lent rather than earned.
func _check_decor(scene: Node) -> void:
	scene.debug_enter_department(Departments.DECOR_OFFICE)
	await _wait(0.2)
	_check(scene.current_department() == Departments.DECOR_OFFICE, "the Decor Office can be entered")
	Progress.add_condolences(DECOR_SPARE)
	var condolences: int = Progress.data.condolences
	var fern := CosmeticDef.find("potted_fern", CosmeticDef.all())
	var cap := CosmeticDef.find("flat_cap", CosmeticDef.all())
	var panel := await _open_station(scene, "decor_counter")
	_check(panel is DecorPanel, "the counter opens the Decor Office's panel")
	if not panel is DecorPanel or fern == null or cap == null:
		return
	var buy_fern := _row_button(panel, fern.display_name)
	_check(buy_fern != null and not buy_fern.disabled, "the fern is for sale")
	if buy_fern != null:
		buy_fern.pressed.emit()
		await _wait(0.1)
	_check(Progress.data.owns_cosmetic(fern.id) and Progress.data.condolences == condolences - fern.price, "the fern costs its Condolences")
	var tab := _button_named(panel, DecorPanel.TAB_GRANDPA)
	_check(tab != null, "the panel has a tab for Grandpa")
	if tab != null:
		tab.pressed.emit()
		await _wait(0.1)
	var buy_cap := _row_button(panel, cap.display_name)
	_check(buy_cap != null and not buy_cap.disabled, "the flat cap is for sale")
	if buy_cap != null:
		buy_cap.pressed.emit()
		await _wait(0.1)
	var wear := _row_button(panel, cap.display_name)
	_check(wear != null and wear.text == DecorPanel.WEAR, "a bought cap can be worn")
	if wear != null:
		wear.pressed.emit()
		await _wait(0.1)
	_check(Progress.data.cosmetics_worn.get(CosmeticDef.SLOT_HAT, "") == cap.id, "the flat cap is worn")
	await _leave_panel(scene)
	var decor: LobbyDecor = scene.lobby_decor()
	_check(decor != null and decor.has_decor(fern.id), "the lobby has the fern once the panel closes")
	var look: Dictionary = Progress.make_run().look
	_check(look.has(CosmeticDef.SLOT_HAT) and (look[CosmeticDef.SLOT_HAT] as CosmeticDef).id == cap.id, "a new run wears the flat cap")
	_check(scene.player.run.look.has(CosmeticDef.SLOT_HAT), "he wears it in the Waiting Room too")
	scene.debug_enter_department(Departments.LOBBY)
	await _wait(0.2)
	_checked_decor = true


# With every floor cleared, every department is open. He walks to each through its doors, and each has
# what Departments says stands there.
func _walk_every_department(scene: Node) -> void:
	_check(scene.open_department_ids().size() == Departments.ALL.size(), "every department is open after every floor, got %s" % str(scene.open_department_ids()))
	for each: Dictionary in Departments.ALL:
		var id: String = each["id"]
		await _walk_to_department(scene, id)
		if _failed:
			return
		_check_stations_in(scene, id)
		if id == Departments.BACK_ROOM:
			await _check_back_room(scene)
	_check(Mementos.hung(Progress.data).size() == Mementos.ALL.size(), "the trophy wall shows every memento")
	await _walk_to_department(scene, Departments.LOBBY)
	_walked_departments = true


func _check_stations_in(scene: Node, id: String) -> void:
	var view: RoomView = scene.debug_room_view()
	var expected: Array = Departments.MERCHANTS.duplicate()
	expected.append_array(Departments.STATIONS)
	for entry: Dictionary in expected:
		if entry["department"] != id:
			continue
		var found: WaitingStation = scene.station(entry["id"])
		_check(found != null and found.get_parent() == view, "%s stands in the %s" % [entry["id"], id])
	for entry: Dictionary in Departments.NPCS:
		if entry["department"] != id:
			continue
		var met := false
		for child in view.get_children():
			met = met or (child is Npc and child.def.id == entry["id"])
		# Gerald waits on the true ending, which the loop never reaches.
		var stands := Departments.npc_stands(entry, Progress.data)
		_check(met == stands, "%s %s in the %s" % [entry["id"], "stands" if stands else "is not yet", id])


# The Back Room: the Dealer and two card tables, each played once through the Arcade's overlay for
# exactly its rule's payout, and both full again on the next visit.
func _check_back_room(scene: Node) -> void:
	var view: RoomView = scene.debug_room_view()
	var tables: Array[ArcadeTable] = view.arcade_tables()
	_check(tables.size() == Departments.BACK_ROOM_GAMES.size(), "the Back Room holds a table per game, got %d" % tables.size())
	for i in mini(tables.size(), Departments.BACK_ROOM_GAMES.size()):
		_check(tables[i].game == Departments.BACK_ROOM_GAMES[i], "Back Room table %d is the %s" % [i, Departments.BACK_ROOM_GAMES[i]])
	var dealers := 0
	for child in view.get_children():
		if child is Npc and child.def.display_name == "The Dealer":
			dealers += 1
	_check(dealers == 1, "the Dealer keeps the Back Room")
	var seeded := RandomNumberGenerator.new()
	seeded.seed = 47
	await _play_each_table(scene, view, seeded)
	scene.debug_enter_department(Departments.LOBBY)
	await _wait(0.1)
	scene.debug_enter_department(Departments.BACK_ROOM)
	await _wait(0.1)
	for table in tables:
		_check(table.plays_left == ArcadeTable.plays_per_visit(table.game), "a new visit fills the Back Room's %s again" % table.game)
	_checked_back_room = true


# A found recipe from the rack, a swing and a Thermos at the dummy, and nothing kept on leaving.
func _check_training_yard(scene: Node) -> void:
	await _walk_to_department(scene, Departments.TRAINING_YARD)
	var run: RunState = scene.player.run
	var rack := ItemRackPanel.rack_items(Progress.data)
	_check(not rack.is_empty(), "the rack holds at least the poster's recipe")
	if rack.is_empty():
		return
	var item: ItemDef = rack[0]
	var panel := await _open_station(scene, "item_rack")
	_check(panel is ItemRackPanel, "the rack opens its panel")
	if panel is ItemRackPanel:
		var take := _button_named(panel, "Try %s" % item.display_name)
		_check(take != null and not take.disabled, "the rack offers %s" % item.display_name)
		if take != null:
			take.pressed.emit()
			await _wait(0.1)
		_check(run.has_item(item.id), "taking from the rack equips the item in the yard")
		await _leave_panel(scene)
	var view: RoomView = scene.debug_room_view()
	var dummy: Enemy = null
	var numbers: TrainingDummy = null
	for child in view.get_children():
		if child is Enemy and child.def.id == "training_dummy":
			dummy = child
		if child is TrainingDummy:
			numbers = child
	_check(dummy != null and numbers != null, "the yard has its dummy and its hit numbers")
	if dummy == null or numbers == null:
		return
	scene.player.global_position = dummy.global_position + Vector2(-RoomBackdrop.TILE + 4.0, 0)
	await _wait(0.1)
	await _swing_at(scene, dummy)
	# Cleared before he leaves, so nothing aims at a dummy out of the tree.
	scene.player.aim_source = Callable()
	_check(is_instance_valid(dummy) and not dummy.is_queued_for_deletion() and dummy.hp > 0.0, "the dummy never falls")
	_check(numbers.numbers_showing() > 0, "a hit on the dummy shows its damage")
	await _press("bomb")
	await _wait(0.1)
	_check(run.bombs == RunState.YARD_SUPPLY, "a Thermos thrown in the yard leaves %d, got %d" % [RunState.YARD_SUPPLY, run.bombs])
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(is_instance_valid(dummy) and dummy.hp > 0.0, "the dummy outlasts a Thermos")
	await _walk_to_department(scene, Departments.LOBBY)
	_check(run.items.is_empty(), "leaving the yard drops the items tried there")
	_check(run.bombs == RunState.STARTING_BOMBS + run.stats.bonus_bombs, "leaving the yard puts his Thermoses back")
	_checked_yard = true


# Every floor's first beat pays Condolences once. The loop fights every mini boss on its way, but only
# the floor bosses are certain, so the mini bosses are counted rather than demanded.
func _check_condolences_earned() -> void:
	_check(Progress.data.condolences > 0, "Condolences were earned")
	_mini_bosses_beaten = 0
	for depth: int in ProgressData.PATHS_AT_DEPTH:
		for path: String in ProgressData.PATHS_AT_DEPTH[depth]:
			var def: FloorDef = load("res://data/floors/%s.tres" % path)
			_check(Progress.data.bosses_beaten.has(def.floor_boss.id), "%s's first beat is recorded" % def.floor_boss.id)
			if Progress.data.bosses_beaten.has(def.mini_boss.id):
				_mini_bosses_beaten += 1


# A ticket that calls a cursed offer, taken at the machine, then the noticeboard's six letters.
func _check_ticket_and_letters() -> void:
	var called := maxi(TicketRules.CALL_EVERY * TicketRules.EVENTS.size(), ceili(Progress.data.run_count / 15.0) * 15)
	Progress.data.run_count = called
	Progress.data.ticket_called = called - 1
	Game.return_to_waiting()
	await _wait(0.5)
	_expect_scene("WaitingRoom")
	var scene := get_tree().current_scene
	_check(TicketRules.event_for(called) == TicketRules.CURSED_OFFER, "ticket %d is a cursed offer's number" % called)
	_check(Progress.data.cursed_offer, "ticket %d puts a cursed ticket on offer" % called)
	_check(scene.now_serving(Progress.data) == called, "the lobby's sign calls number %d" % called)
	var panel := await _open_station(scene, "ticket_machine")
	_check(panel is TicketPanel, "the ticket machine opens its panel")
	if panel is TicketPanel:
		var take := _button_named(panel, TicketPanel.TAKE_CURSED)
		_check(take != null, "the machine offers the cursed ticket")
		if take != null:
			take.pressed.emit()
			await _wait(0.1)
		_check(Progress.data.cursed_next_run and not Progress.data.cursed_offer, "taking the cursed ticket curses the next run")
		await _leave_panel(scene)
	_expect_cursed_run = Progress.data.cursed_next_run
	var arrived := LetterBook.arrived(Progress.data).size()
	_check(arrived == LetterBook.LETTERS.size(), "a letter arrived for every path, got %d" % arrived)
	var board: WaitingStation = scene.station("noticeboard")
	_check(board != null and board.badge == NoticeboardPanel.NEW_MARK, "the noticeboard marks unread letters")
	panel = await _open_station(scene, "noticeboard")
	_check(panel is NoticeboardPanel, "the noticeboard opens its letters")
	if panel is NoticeboardPanel:
		var listed := (panel as NoticeboardPanel).letters_listed()
		_check(listed == arrived, "the noticeboard lists every letter, got %d" % listed)
		var unread := LetterBook.unread(Progress.data).size()
		var letter := _button_starting(panel, NoticeboardPanel.NEW_MARK)
		_check(letter != null, "an unread letter is marked NEW")
		if letter != null:
			letter.pressed.emit()
			await _wait(0.1)
		_check(LetterBook.unread(Progress.data).size() == unread - 1, "reading a letter marks it read")
		await _leave_panel(scene)
	_checked_tickets = true


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _expect_scene(expected: String) -> void:
	var scene := get_tree().current_scene
	_check(scene != null and scene.name == expected, "expected scene %s" % expected)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_fail(label)


func _fail(label: String) -> void:
	if _failed:
		return
	_failed = true
	print("SMOKE FAIL: " + label)
	get_tree().quit(1)



# --- Stage 2: rocks, barrels, holes, piles, grass and bosses breaking things ---

func _props_layout() -> RoomLayout:
	var rows := ["#".repeat(20)]
	for y in range(1, 10):
		rows.append("#" + ".".repeat(18) + "#")
	rows.append("#".repeat(20))
	var changes := {Vector2i(4, 3): "O", Vector2i(6, 3): "Q", Vector2i(8, 3): "Z", Vector2i(12, 3): "g", Vector2i(14, 3): "X", Vector2i(16, 3): "O", Vector2i(10, 7): "V", Vector2i(4, 7): "Q"}
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _props_in(view: Node, script: Script) -> Array:
	var found := []
	for child in view.get_children():
		if child.get_script() == script and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _check_props_room(scene: Node) -> void:
	_checked_props = true
	var map: FloorMap = scene.debug_map()
	var back_id: int = scene.debug_current_id()
	var layout := _props_layout()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(60 + room.id, 60)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 3
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.2)
	var view: RoomView = scene.debug_room_view()
	var rocks := _props_in(view, RockBlock)
	var barrels := _props_in(view, Barrel)
	var piles := _props_in(view, BonePile)
	var holes := _props_in(view, Hole)
	var crates := _props_in(view, BreakableBlock)
	_check(rocks.size() == 2 and barrels.size() == 2 and piles.size() == 1 and holes.size() == 1 and crates.size() == 1, "the props room built every prop")
	if _failed:
		return
	# Shots and thrown dentures ask layer 1: rocks and barrels stop them, holes do not.
	var space: PhysicsDirectSpaceState2D = scene.player.get_world_2d().direct_space_state
	var across_rock := _ray(space, rocks[0].global_position, 1)
	var across_hole := _ray(space, holes[0].global_position, 1)
	var across_hole_layer := _ray(space, holes[0].global_position, Hole.LAYER)
	_check(not across_rock.is_empty(), "a rock stops shots and thrown dentures")
	_check(across_hole.is_empty(), "shots and thrown dentures fly over a hole")
	_check(not across_hole_layer.is_empty(), "a hole sits on its own layer")
	# Grandpa cannot walk across the hole, nor dodge across it.
	var hole_x: float = holes[0].global_position.x
	scene.player.global_position = Vector2(hole_x - 120.0, holes[0].global_position.y) - Player.FEET_OFFSET
	Input.action_press("move_right")
	await _wait(0.9)
	_check(scene.player.feet().global_position.x < hole_x, "Grandpa cannot walk across a hole")
	Input.action_press("dodge")
	await get_tree().process_frame
	Input.action_release("dodge")
	await _wait(0.4)
	Input.action_release("move_right")
	_check(scene.player.feet().global_position.x < hole_x, "a dodge does not cross a hole")
	# The cane breaks barrels and piles, but not rocks or crates.
	_check(not rocks[0].hit_by(BreakableBlock.SOURCE_CANE) and not crates[0].hit_by(BreakableBlock.SOURCE_CANE), "the cane leaves rocks and crates alone")
	_check(piles[0].hit_by(BreakableBlock.SOURCE_CANE), "the cane scatters a pile")
	_check(barrels[0].hit_by(BreakableBlock.SOURCE_CANE), "the cane breaks a barrel")
	# A boss sweep breaks rocks, barrels and crates it reaches.
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	var boss: Enemy = _spawn_summoned(view, floor_def.floor_boss, rocks[0].global_position + Vector2(24, 0))
	boss._behavior._attack = 1
	boss._behavior._finish_attack(boss, false)
	await _wait(0.1)
	_check(_gone(rocks[0]), "the floor boss sweep breaks a rock")
	boss.take_damage(INF, Vector2.ZERO)
	var mini: Enemy = _spawn_summoned(view, floor_def.mini_boss, crates[0].global_position + Vector2(-28, 0))
	scene.player.global_position = crates[0].global_position + Vector2(-60, 0) - Player.FEET_OFFSET
	var waited := 0.0
	while not _gone(crates[0]) and waited < 4.0 and is_instance_valid(mini):
		await _wait(0.1)
		waited += 0.1
	_check(_gone(crates[0]), "the mini boss attack breaks a crate")
	if is_instance_valid(mini):
		mini.take_damage(INF, Vector2.ZERO)
	scene.player.run.health.heal(99)
	await _wait(0.1)
	# Whatever broke stays broken when he leaves and returns.
	var left := _props_in(view, Barrel).size() + _props_in(view, RockBlock).size() + _props_in(view, BonePile).size()
	scene._enter_room(back_id)
	await _wait(0.2)
	scene._enter_room(room.id)
	await _wait(0.2)
	var after := _props_in(view, Barrel).size() + _props_in(view, RockBlock).size() + _props_in(view, BonePile).size()
	_check(after == left, "broken props stay broken on return, %d vs %d" % [after, left])
	_check(_props_in(view, Barrel).size() == 1 and _props_in(view, RockBlock).size() == 1, "the unbroken ones are still standing")
	scene._enter_room(back_id)
	await _wait(0.2)


func _ray(space: PhysicsDirectSpaceState2D, through: Vector2, mask: int) -> Dictionary:
	return space.intersect_ray(PhysicsRayQueryParameters2D.create(through + Vector2(-40, 0), through + Vector2(40, 0), mask))


func _spawn_summoned(view: RoomView, def: EnemyDef, at: Vector2) -> Enemy:
	view._spawn_enemy(def, at, true)
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.def == def and enemy.position.distance_to(at) < 1.0:
			return enemy
	_check(false, "spawned the boss for the props check")
	return null


# Nothing may be dropped onto a standing rock, barrel, crate, hole or wall.
func _check_pickups_off_solids(scene: Node, room_id: int) -> void:
	var layout: RoomLayout = scene.debug_map().room(room_id).layout
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(pickup) or pickup.is_queued_for_deletion() or pickup.is_flying() or not pickup.is_inside_tree():
			continue
		_pickups_off_solids += 1
		var at: Vector2 = pickup.global_position
		var cell := Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))
		_check(not RoomLayout.WALL_LIKE.contains(layout.symbol_at(cell)), "a pickup sits in a wall at %s" % str(cell))
		for hole in get_tree().get_nodes_in_group("holes"):
			var hole_cell := Vector2i(floori(hole.global_position.x / RoomBackdrop.TILE), floori(hole.global_position.y / RoomBackdrop.TILE))
			_check(hole_cell != cell, "a pickup sits over a hole at %s" % str(cell))
		for block in get_tree().get_nodes_in_group("breakable"):
			if block.is_solid() and not block.is_queued_for_deletion():
				_check(not block.body_rect().has_point(at), "a pickup sits inside a standing block at %s" % str(cell))


func _gone(node) -> bool:
	return not is_instance_valid(node) or node.is_queued_for_deletion()


# --- Stage 3: new enemies, blasts, shields and boss patterns ---

func _fight_layout(width: int, height: int, changes: Dictionary) -> RoomLayout:
	var rows := ["#".repeat(width)]
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	for cell: Vector2i in changes:
		var row: String = rows[cell.y]
		rows[cell.y] = row.substr(0, cell.x) + changes[cell] + row.substr(cell.x + 1)
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = PackedStringArray(rows)
	return layout


func _enter_made_room(scene: Node, layout: RoomLayout) -> RoomView:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(80 + room.id, 80)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 5
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.1)
	return scene.debug_room_view()


func _enemy_def(id: String) -> EnemyDef:
	return load("res://data/enemies/%s.tres" % id)


func _put_feet(scene: Node, at: Vector2) -> void:
	scene.player.global_position = at - Player.FEET_OFFSET


func _dismiss_all() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.05)


func _check_fight_room(scene: Node) -> void:
	_checked_fight = true
	var back_id: int = scene.debug_current_id()
	var health: Health = scene.player.run.health
	# The check is about the rules, so stray hits must not end the run.
	var pills_before := health.max_pills
	health.raise_max(pills_before + 30)
	await _check_room_start(scene)
	await _check_blast(scene)
	await _check_shield(scene)
	await _check_dentures(scene)
	await _check_chests(scene)
	await _check_arcade(scene)
	await _check_boss_moves(scene)
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	await _check_far_boss_waits(scene, floor_def.floor_boss)
	await _check_boss_seen_from_a_corner(scene, floor_def.floor_boss)
	await _check_walks_around_a_wall(scene, _enemy_def("intern_reaper"))
	await _check_walks_around_a_wall(scene, floor_def.floor_boss)
	await _check_thermos_fuel(scene)
	await _dismiss_all()
	scene.player.aim_source = Callable()
	scene._enter_room(back_id)
	await _wait(0.1)
	health.pills = pills_before
	health.raise_max(pills_before)


# Enemies of a room hold still as he walks in, then come for him.
func _check_room_start(scene: Node) -> void:
	var layout := _fight_layout(20, 11, {Vector2i(8, 8): "E", Vector2i(12, 8): "E"})
	await _enter_made_room(scene, layout)
	var enemies := get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() >= 2, "a room's enemy cells spawn enemies")
	var was: Vector2 = enemies[0].position
	await _wait(Enemy.ROOM_WAKE_TIME * 0.6)
	_check(not _gone(enemies[0]) and enemies[0].position == was and enemies[0]._warning == null, "enemies wait as he walks in")
	await _dismiss_all()


func _check_blast(scene: Node) -> void:
	var cell_at := func(c: Vector2i) -> Vector2: return RoomBackdrop.cell_center(c)
	var layout := _fight_layout(20, 11, {Vector2i(5, 4): "Q", Vector2i(7, 4): "O", Vector2i(12, 3): "#", Vector2i(12, 4): "#", Vector2i(12, 5): "#", Vector2i(12, 6): "#"})
	var view := await _enter_made_room(scene, layout)
	var barrels := _props_in(view, Barrel)
	var rocks := _props_in(view, RockBlock)
	var auditor := view._spawn_enemy(_enemy_def("burnt_out_auditor"), cell_at.call(Vector2i(6, 5)))
	var neighbor := view._spawn_enemy(_enemy_def("intern_reaper"), cell_at.call(Vector2i(6, 6)))
	neighbor.set_physics_process(false)
	var neighbor_hp: float = neighbor.hp
	_put_feet(scene, cell_at.call(Vector2i(16, 8)))
	auditor._behavior._rushed = 99.0
	await _wait(0.2)
	_check(auditor._warning != null, "a lit auditor shows its warning")
	var health: Health = scene.player.run.health
	var pills: int = health.pills
	await _wait(1.0)
	_check(_gone(auditor), "the auditor goes off when its fuse ends")
	_check(_gone(barrels[0]) and _gone(rocks[0]), "the blast breaks barrels and rocks")
	_check(neighbor.hp < neighbor_hp, "the blast hurts other enemies")
	_check(health.pills == pills, "a far player is not hurt")
	await _wait(0.9)
	# A wall stands between the next blast and Grandpa.
	var walled := view._spawn_enemy(_enemy_def("burnt_out_auditor"), cell_at.call(Vector2i(11, 4)) + Vector2(8, 0))
	var beyond := view._spawn_enemy(_enemy_def("intern_reaper"), cell_at.call(Vector2i(13, 4)) + Vector2(-6, 0))
	beyond.set_physics_process(false)
	var beyond_hp: float = beyond.hp
	_put_feet(scene, cell_at.call(Vector2i(13, 4)) + Vector2(-6, 8))
	walled._behavior._rushed = 99.0
	await _wait(0.2)
	var walled_pills: int = health.pills
	# No props are left in reach here, since a broken barrel or rock can hold a coin.
	var pension_before: int = Progress.data.pension
	walled.set_physics_process(true)
	var waited := 0.0
	while not _gone(walled) and waited < 2.0:
		await _wait(0.1)
		waited += 0.1
	_check(_gone(walled), "the walled auditor went off")
	_check(health.pills == walled_pills, "a wall stops the blast reaching Grandpa")
	_check(Progress.data.pension == pension_before, "an auditor that blows itself up pays nothing")
	_check(is_equal_approx(beyond.hp, beyond_hp), "a wall stops the blast reaching an enemy")
	# Killing a lit one still sets it off, and an unlit one dies quietly.
	var quiet := view._spawn_enemy(_enemy_def("burnt_out_auditor"), cell_at.call(Vector2i(3, 8)))
	var near_quiet := view._spawn_enemy(_enemy_def("intern_reaper"), cell_at.call(Vector2i(4, 8)))
	near_quiet.set_physics_process(false)
	var near_hp: float = near_quiet.hp
	await _wait(0.05)
	quiet.take_damage(INF, Vector2.ZERO)
	await _wait(0.05)
	_check(is_equal_approx(near_quiet.hp, near_hp), "an unlit auditor dies without a blast")
	await _dismiss_all()


func _swing_at(scene: Node, enemy: Enemy) -> void:
	scene.player.aim_source = func() -> Vector2: return enemy.global_position
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_press("attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("attack")
	await _wait(0.3)


func _check_shield(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var center := RoomBackdrop.cell_center(Vector2i(10, 6))
	var officer := view._spawn_enemy(_enemy_def("denial_officer"), center)
	officer.set_physics_process(false)
	officer.facing = Vector2.RIGHT
	var body := center + Vector2(34, 0)
	_put_feet(scene, body + Player.FEET_OFFSET)
	var hp: float = officer.hp
	var blocks := [0]
	officer.hit_blocked.connect(func(): blocks[0] += 1)
	await _swing_at(scene, officer)
	_check(blocks[0] == 1 and is_equal_approx(officer.hp, hp), "a swing from the front is blocked, blocks %d" % blocks[0])
	_put_feet(scene, center + Vector2(-34, 0) + Player.FEET_OFFSET)
	await _swing_at(scene, officer)
	_check(officer.hp < hp, "a swing from behind lands")
	var after_swing: float = officer.hp
	_put_feet(scene, center + Vector2(100, 0) + Player.FEET_OFFSET)
	await get_tree().physics_frame
	await get_tree().process_frame
	Input.action_press("throw")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("throw")
	await _wait(0.5)
	_check(officer.hp < after_swing, "thrown dentures go over the shield")
	scene.player.recall_teeth()
	scene.player.aim_source = Callable()
	await _dismiss_all()


# The teeth fly, bite, lie chattering and come back, and the cane swings the whole time they are away.
func _check_dentures(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var player: Player = scene.player
	var run: RunState = player.run
	player.recall_teeth()
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(4, 5)))
	var far: Enemy = view._spawn_enemy(_enemy_def("intern_reaper"), RoomBackdrop.cell_center(Vector2i(8, 5)) - Player.FEET_OFFSET, true)
	far.set_physics_process(false)
	var near: Enemy = view._spawn_enemy(_enemy_def("intern_reaper"), player.global_position + Vector2(-30, 0), true)
	near.set_physics_process(false)
	var far_hp: float = far.hp
	var near_hp: float = near.hp
	var expected := ThrownDentures.bite_damage(run.bite_damage_mult())
	player.aim_source = func() -> Vector2: return far.global_position
	await _press("throw")
	var thrown_at := Time.get_ticks_msec()
	_check(not player.has_teeth(), "the throw key sends the teeth out")
	await _wait(0.6)
	_check(absf((far_hp - far.hp) - expected) < 0.01, "the teeth bite for %f, did %f" % [expected, far_hp - far.hp])
	# The cane never left his hand, so it swings while the teeth lie by the far enemy.
	await _swing_at(scene, near)
	_check(not player.has_teeth(), "the teeth are still away during the swing")
	_check(near.hp < near_hp, "a swing lands while the teeth are away")
	var waited := 0.0
	while not player.has_teeth() and waited < run.stats.teeth_return_delay + 2.0:
		await _wait(0.1)
		waited += 0.1
	var away := (Time.get_ticks_msec() - thrown_at) / 1000.0
	_check(player.has_teeth(), "the teeth come back on their own, away %f s" % away)
	_check(away >= run.stats.teeth_return_delay, "and not before their delay, away %f s" % away)
	# Aim must not point at an enemy about to be freed, or the aim reads a dead body every frame.
	player.aim_source = Callable()
	await _dismiss_all()
	# Extra Strong Dentures let one throw bite through two enemies in a row.
	var bites_before: int = run.stats.bites_per_throw
	run.stats.bites_per_throw = 2
	var first: Enemy = view._spawn_enemy(_enemy_def("intern_reaper"), RoomBackdrop.cell_center(Vector2i(7, 5)) - Player.FEET_OFFSET, true)
	var second: Enemy = view._spawn_enemy(_enemy_def("intern_reaper"), RoomBackdrop.cell_center(Vector2i(9, 5)) - Player.FEET_OFFSET, true)
	first.set_physics_process(false)
	second.set_physics_process(false)
	var first_hp: float = first.hp
	var second_hp: float = second.hp
	player.aim_source = func() -> Vector2: return second.global_position
	await _press("throw")
	await _wait(0.7)
	_check(first.hp < first_hp and second.hp < second_hp, "with the item one throw bites both enemies in a row")
	run.stats.bites_per_throw = bites_before
	player.recall_teeth()
	player.aim_source = Callable()
	await _dismiss_all()


# Every kind of chest, laid out in one room whatever the floors happened to roll: what opens each,
# what that costs and what comes out. The mimic wakes into a fight that keeps the warning rules.
func _check_chests(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var player: Player = scene.player
	var run: RunState = player.run
	var floor_def: FloorDef = scene.debug_floor_def()
	# The probe runs on the first floor, which names no mimic, so it lends that floor one while it runs.
	var mimic_before: EnemyDef = floor_def.mimic
	floor_def.mimic = _enemy_def("mimic")
	var keys_before := run.keys
	while run.keys > 0:
		run.use_key()
	# A lunchbox opens with the key alone and pays a little.
	var lunch: Chest = view._create_chest(Vector2i(4, 3), ChestRules.LUNCHBOX)
	var pension: int = Progress.data.pension
	_put_feet(scene, lunch.global_position)
	await _wait(0.1)
	await _press("interact")
	await _wait(0.2)
	_check(_gone(lunch), "a lunchbox opens with the interact key and no Slip")
	_check(Progress.data.pension >= pension + ChestRules.lunchbox_pension(floor_def.treasure_pension), "a lunchbox pays a little Pension")
	# A locked chest waits for its one Slip and spends it.
	var locked: Chest = view._create_chest(Vector2i(8, 3), ChestRules.LOCKED)
	_put_feet(scene, locked.global_position)
	await _wait(0.1)
	await _press("interact")
	await _wait(0.1)
	_check(not _gone(locked), "a locked chest stays shut without a Slip")
	run.add_key()
	await _press("interact")
	await _wait(0.2)
	_check(_gone(locked) and run.keys == 0, "one Slip opens the locked chest and is spent")
	# A gilded urn wants two Slips, then lays out two items of which only one can be taken.
	var urn: Chest = view._create_chest(Vector2i(12, 3), ChestRules.URN)
	var offer := mini(ChestRules.URN_CHOICES, _offerable_items(run))
	var lying_before := _item_pickups(view)
	run.add_key()
	_put_feet(scene, urn.global_position)
	await _wait(0.1)
	await _press("interact")
	await _wait(0.1)
	_check(not _gone(urn) and run.keys == 1, "one Slip is not enough for the urn")
	run.add_key()
	await _press("interact")
	await _wait(0.2)
	_check(_gone(urn) and run.keys == 0, "two Slips open the urn and are spent")
	var offered := _item_pickups(view).filter(func(p: Pickup) -> bool: return not lying_before.has(p))
	_check(offered.size() == offer, "the urn lays out %d items, found %d" % [offer, offered.size()])
	if offered.size() >= 2:
		offered[0].collect()
		await _wait(0.1)
		_check(_gone(offered[1]), "taking one of the urn's items clears the other away")
	# A safe ignores Slips and an Auditor's blast, and only the player's Thermos bursts it.
	var safe: Chest = view._create_chest(Vector2i(15, 8), ChestRules.SAFE)
	run.add_key()
	_put_feet(scene, safe.global_position)
	await _wait(0.1)
	await _press("interact")
	await _wait(0.1)
	_check(not _gone(safe) and run.keys == 1, "a Slip does nothing to a safe deposit box")
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(3, 8)))
	EnemyBlast.go(view, safe.position, 80.0, 10.0, 0.0, player, 0)
	await _wait(0.2)
	_check(not _gone(safe), "an Auditor's blast leaves the safe shut")
	pension = Progress.data.pension
	view.place_bomb(safe.position)
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(_gone(safe), "the player's Thermos bursts the safe")
	_check(Progress.data.pension >= pension + ChestRules.safe_pension(floor_def.treasure_pension), "the safe pays a big pile of Pension")
	# A mimic sleeps as a locked chest until touched, then warns before every lunge, pays and drops a Slip.
	var mimic_chest: Chest = view._create_chest(Vector2i(4, 8), ChestRules.MIMIC)
	_check(mimic_chest.requires_interact and mimic_chest.prompt == ChestRules.prompt_for(ChestRules.LOCKED), "a mimic asks for a Slip like a locked chest")
	_put_feet(scene, mimic_chest.global_position + Vector2(64, 0))
	await _wait(0.2)
	_check(not _gone(mimic_chest), "a mimic sleeps until it is touched")
	_put_feet(scene, mimic_chest.global_position)
	await _wait(0.1)
	_check(_gone(mimic_chest), "touching the mimic wakes it")
	var mimic: Enemy = null
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.def.id == "mimic":
			mimic = enemy
	_check(mimic != null, "the woken chest is an enemy")
	if mimic != null:
		var pills: int = run.health.pills
		var warned := false
		var waited := 0.0
		while waited < 2.5 and not warned:
			await get_tree().physics_frame
			waited += get_physics_process_delta_time()
			warned = mimic._warning != null
			_check(warned or run.health.pills == pills, "the mimic never bites before its warning")
		_check(warned, "the mimic shows a warning before it lunges")
		var keys := run.keys
		pension = Progress.data.pension
		mimic.take_damage(INF, Vector2.ZERO)
		await _wait(0.2)
		_check(Progress.data.pension >= pension + MIMIC_PAY_AT_LEAST, "a beaten mimic pays well")
		_check(run.keys > keys or _slip_lying(view), "a beaten mimic drops a Slip")
	await _dismiss_all()
	while run.keys > 0:
		run.use_key()
	for i in keys_before:
		run.add_key()
	floor_def.mimic = mimic_before
	_checked_chests = true


# --- The Arcade Room: the Dealer, the tables and the card-table overlay ---

# A made Arcade Room, so the check runs every time whatever the floors rolled: three tables in order and
# the Dealer, each game played once through the overlay for exactly its rule's payout, a bet he cannot
# cover refused, a hand left mid-play finished rather than lost, and every table full again next visit.
func _check_arcade(scene: Node) -> void:
	var layout: RoomLayout = load(FloorBuilder.ARCADE_DIR + "arcade_01.tres")
	var view := await _enter_made_room(scene, layout)
	var player: Player = scene.player
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "nothing waits to fight in the Arcade Room")
	var tables: Array[ArcadeTable] = view.arcade_tables()
	_check(tables.size() == ArcadeTable.GAMES.size(), "the Arcade Room holds a table for each game, got %d" % tables.size())
	if tables.size() < ArcadeTable.GAMES.size():
		return
	for i in tables.size():
		_check(tables[i].game == ArcadeTable.GAMES[i], "table %d is the %s" % [i, ArcadeTable.GAMES[i]])
	var dealers := 0
	for child in view.get_children():
		if child is Npc and child.def.id == "dealer":
			dealers += 1
	_check(dealers == 1, "the Dealer stands in the Arcade Room")
	var seeded := RandomNumberGenerator.new()
	seeded.seed = 31
	await _play_each_table(scene, view, seeded)
	# A pull he cannot cover is refused and costs nothing.
	var panel := await _open_table(scene, tables[0])
	if panel != null:
		var saved: int = Progress.data.pension
		var pulls: int = tables[0].plays_left
		Progress.spend(saved)
		_check(not panel.pull() and Progress.data.pension == 0 and tables[0].plays_left == pulls, "a pull he cannot cover is refused")
		Progress.add_pension(saved)
		await _close_table(scene)
	# Coming back fills every table, and walking away mid-hand stands for him and pays what the hand earned.
	view.refresh_doors()
	for table in tables:
		_check(table.plays_left == ArcadeTable.plays_per_visit(table.game), "a new visit fills the %s again" % table.game)
	Progress.add_pension(ARCADE_SPARE)
	panel = await _open_table(scene, tables[1])
	if panel != null:
		var pension: int = Progress.data.pension
		_check(panel.bet(Blackjack.BETS[0]), "a blackjack bet can be placed")
		var hand: Blackjack = panel.blackjack()
		await _close_table(scene)
		_check(hand.is_over, "walking away mid-hand finishes the hand")
		_check(Progress.data.pension == pension - Blackjack.BETS[0] + Blackjack.payout(hand.outcome(), Blackjack.BETS[0]), "and pays what it earned")
	Progress.spend(mini(ARCADE_SPARE, Progress.data.pension))
	_check(player.is_physics_processing(), "closing the overlay lets Grandpa move again")
	_checked_arcade = true


# Plays every table of an Arcade Room once through its overlay, opened and closed by the real key, and
# checks Pension moves by exactly what each game's rules pay. A seeded generator makes the hands the same
# every run. Spare Pension covers the bets and is taken back after.
func _play_each_table(scene: Node, view: RoomView, seeded: RandomNumberGenerator) -> void:
	var player: Player = scene.player
	Progress.add_pension(ARCADE_SPARE)
	for table in view.arcade_tables():
		if table.plays_left <= 0:
			continue
		var panel := await _open_table(scene, table)
		if panel == null:
			break
		_check(not player.is_physics_processing(), "the overlay holds Grandpa still")
		if seeded != null:
			panel.use_rng(seeded)
		var pension: int = Progress.data.pension
		var plays: int = table.plays_left
		match table.game:
			ArcadeTable.SLOT:
				_check(panel.pull(), "a pull can be made")
				var won := SlotMachine.payout(panel.last_reels(), SlotMachine.BET)
				_check(Progress.data.pension == pension - SlotMachine.BET + int(won["pension"]), "a pull pays exactly its rule's payout, reels %s" % str(panel.last_reels()))
			ArcadeTable.BLACKJACK:
				_check(panel.bet(Blackjack.BETS[0]), "a blackjack bet can be placed")
				var hand: Blackjack = panel.blackjack()
				while panel.state() == CardTablePanel.PLAYING and Blackjack.hand_value(hand.player) < ArcadeOdds.PLAYER_STANDS_ON:
					panel.hit()
				panel.stand()
				_check(panel.state() == CardTablePanel.DONE, "the blackjack hand is settled")
				_check(Progress.data.pension == pension - Blackjack.BETS[0] + Blackjack.payout(hand.outcome(), Blackjack.BETS[0]), "blackjack pays exactly its rule's payout, %s" % hand.outcome())
				_check(not panel.bet(Blackjack.BETS[0]), "blackjack plays one hand a visit")
			ArcadeTable.POKER:
				_check(panel.bet(DrawPoker.BETS[0]), "a poker bet can be placed")
				var holds := ArcadeOdds.simple_holds(panel.poker().hand)
				for i in holds.size():
					if holds[i]:
						panel.toggle_hold(i)
				panel.draw_cards()
				var hand_name := DrawPoker.rank_hand(panel.poker().hand)
				_check(Progress.data.pension == pension - DrawPoker.BETS[0] + DrawPoker.payout(hand_name, DrawPoker.BETS[0]), "draw poker pays exactly its rule's payout, %s" % hand_name)
		_check(table.plays_left == plays - 1, "a play uses one of the visit's plays at the %s" % table.game)
		await _close_table(scene)
	Progress.spend(mini(ARCADE_SPARE, Progress.data.pension))


# Stands Grandpa just below a table and presses the real interact key.
func _open_table(scene: Node, table: ArcadeTable) -> CardTablePanel:
	_put_feet(scene, table.global_position + Vector2(0, RoomBackdrop.TILE))
	await _wait(0.1)
	await _press("interact")
	await _wait(0.1)
	var panel: CardTablePanel = scene.debug_card_panel()
	_check(panel != null and panel.game() == table.game, "the interact key opens the %s overlay" % table.game)
	return panel


func _close_table(scene: Node) -> void:
	await _press("interact")
	await _wait(0.2)
	_check(scene.debug_card_panel() == null, "the interact key closes the overlay, and does not open it again")


# Mimics a room rolled are woken and beaten before its pickups are gathered, so walking onto a coin
# beside one can never leave a live enemy behind in a room that counts as clear.
func _beat_mimics_first() -> void:
	var woke := false
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup is Chest and pickup.kind == ChestRules.MIMIC and not pickup.is_queued_for_deletion():
			pickup.collect()
			woke = true
	if not woke:
		return
	await _wait(0.05)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.def.id == "mimic":
			_mimics_beaten_in_loop += 1
			enemy.take_damage(INF, Vector2.ZERO)
	await _wait(0.05)


func _item_pickups(view: RoomView) -> Array:
	var found := []
	for child in view.get_children():
		if child is Pickup and not child is Chest and child.requires_interact and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _slip_lying(view: RoomView) -> bool:
	for child in view.get_children():
		if child is Pickup and child._label == RoomRules.KEY_NAME and not child.is_queued_for_deletion():
			return true
	return false


func _check_boss_moves(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {Vector2i(8, 5): "O", Vector2i(11, 7): "Q"}))
	var rocks := _props_in(view, RockBlock)
	var barrels := _props_in(view, Barrel)
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(2, 5)))
	var reaper: Enemy = view._spawn_enemy(floor_def.floor_boss, RoomBackdrop.cell_center(Vector2i(15, 5)), true)
	await _wait(0.05)
	reaper._behavior._begin(reaper, reaper._behavior.Attack.DASH, false)
	_check(reaper._lane_length > 0.0, "the dash shows a lane first")
	var from: Vector2 = reaper.global_position
	await _wait(1.8)
	_check(reaper.global_position.distance_to(from) > 150.0, "the dash crosses the room, moved %f" % reaper.global_position.distance_to(from))
	_check(_gone(rocks[0]), "the dash breaks a rock in its path")
	reaper.global_position = RoomBackdrop.cell_center(Vector2i(10, 3))
	reaper._behavior._cooldown = 99.0
	reaper._behavior._next = reaper._behavior.Attack.NONE
	reaper._behavior._begin(reaper, reaper._behavior.Attack.RING, false)
	await _wait(reaper._behavior.windup_for(reaper._behavior.Attack.RING, false) + 0.1)
	var shots := 0
	for child in view.get_children():
		if child is Projectile:
			shots += 1
	_check(shots == reaper._behavior.ring_count(false), "the ring fires all its shots, %d" % shots)
	reaper._behavior._cooldown = 99.0
	reaper._behavior._next = reaper._behavior.Attack.NONE
	reaper._behavior._begin(reaper, reaper._behavior.Attack.SUMMON, false)
	await _wait(reaper._behavior.windup_for(reaper._behavior.Attack.SUMMON, false) + 0.1)
	var marks := 0
	for child in view.get_children():
		if child is SummonMark:
			marks += 1
	_check(marks == reaper._behavior.SUMMON_COUNT, "summons are marked before they come, %d" % marks)
	var before: int = get_tree().get_nodes_in_group("enemies").size()
	await _wait(BossMoves.SUMMON_WARNING + 0.05)
	var enemies := get_tree().get_nodes_in_group("enemies")
	_check(enemies.size() == before + marks, "each mark becomes a summon")
	for enemy: Enemy in enemies:
		if enemy != reaper:
			_check(enemy.is_summon and enemy.coin_value() == 0, "a summon pays nothing")
			_check(not view._room.layout.is_solid_at(view._cell_of(enemy.position)), "summons land on open floor")
	await _dismiss_all()
	# The mini boss charges through props too.
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(5, 7)))
	var mini: Enemy = view._spawn_enemy(floor_def.mini_boss, RoomBackdrop.cell_center(Vector2i(16, 7)), true)
	await _wait(0.05)
	mini._behavior._begin(mini, mini._behavior.Attack.CHARGE)
	_check(mini._lane_length > 0.0, "the charge shows a lane first")
	await _wait(1.6)
	_check(_gone(barrels[0]), "the charge breaks a barrel in its path")
	await _dismiss_all()


# In a big room a boss far from Grandpa walks over, and starts nothing he cannot see.
func _check_far_boss_waits(scene: Node, boss_def: EnemyDef) -> void:
	var view := await _enter_made_room(scene, _fight_layout(30, 17, {}))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(2, 2)))
	var boss: Enemy = view._spawn_enemy(boss_def, RoomBackdrop.cell_center(Vector2i(27, 14)), true)
	boss._behavior._cooldown = 0.0
	var started_far := false
	var came_near := false
	var waited := 0.0
	while waited < 6.0:
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
		if boss.target_in_view():
			came_near = true
			break
		if boss._warning != null:
			started_far = true
	_check(not started_far, "a far %s starts no attack from beyond the screen" % boss_def.id)
	_check(came_near, "a far %s comes into view" % boss_def.id)
	await _dismiss_all()


# In a room the screen holds whole, a boss across it from Grandpa in a corner is on screen, so it attacks.
func _check_boss_seen_from_a_corner(scene: Node, boss_def: EnemyDef) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(1, 1)))
	var boss: Enemy = view._spawn_enemy(boss_def, RoomBackdrop.cell_center(Vector2i(17, 8)), true)
	await get_tree().physics_frame
	_check(boss.target_in_view(), "a %s across a whole-screen room counts as seen" % boss_def.id)
	await _dismiss_all()


# A wall straight between them is walked around through its gap, not pushed into.
func _check_walks_around_a_wall(scene: Node, def: EnemyDef) -> void:
	var wall := {}
	for y in range(1, 8):
		wall[Vector2i(8, y)] = "#"
	var view := await _enter_made_room(scene, _fight_layout(20, 11, wall))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(13, 3)))
	var walker: Enemy = view._spawn_enemy(def, RoomBackdrop.cell_center(Vector2i(4, 3)), true)
	var start_x := walker.global_position.x
	var crossed := false
	var waited := 0.0
	# A boss stops to attack on the way, so it gets longer.
	var limit := 16.0 if def.is_boss else 8.0
	while waited < limit and is_instance_valid(walker):
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
		if walker.global_position.x > RoomBackdrop.cell_center(Vector2i(8, 1)).x:
			crossed = true
			break
	_check(crossed, "a %s gets round a wall from x %d" % [def.id, roundi(start_x)])
	scene.player.run.health.heal(99)
	await _dismiss_all()


# --- Stage 4: potions, the Thermos fuel, reinforced stones and vaults ---

func _press(action: String) -> void:
	await get_tree().process_frame
	Input.action_press(action)
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release(action)
	await get_tree().physics_frame


# The real key drinks the potion, healing waits until it helps and a buff runs out.
func _check_potion_drinking(scene: Node) -> void:
	_checked_potions = true
	var run: RunState = scene.player.run
	var health: Health = run.health
	await _press("potion")
	_check(run.potion == null and run.buff == null, "the potion key does nothing with an empty slot")
	run.give_potion(Content.potion("healing_tonic"))
	await _press("potion")
	_check(run.potion != null, "a healing potion is kept while his pills are full")
	health.hit(2)
	var hurt: int = health.pills
	await _press("potion")
	_check(run.potion == null and health.pills == mini(hurt + 2, health.max_pills), "the potion key heals and empties the slot")
	health.heal(99)
	var base_speed: float = run.stats.move_speed
	run.give_potion(Content.potion("swift_tea"))
	await _press("potion")
	_check(run.buff != null and absf(run.move_speed() - base_speed * 1.4) < 0.01, "the potion key starts a buff")
	var hud := _find_hud(scene)
	await get_tree().process_frame
	_check(hud._potion_slot != null and hud._potion_slot._buff_label.text.begins_with("Swift"), "the HUD shows the running buff")
	run.tick_buff(99.0)
	_check(run.buff == null and absf(run.move_speed() - base_speed) < 0.01, "a buff runs out")


# The vault stone shrugs off everything but a max level Thermos.
func _open_vault_stone(scene: Node, target_id: int) -> void:
	var view: RoomView = scene.debug_room_view()
	var room: FloorRoom = scene.debug_map().room(scene.debug_current_id())
	var side := room.side_towards(target_id)
	var door_cell := room.layout.door_cell(side)
	var wall_at := RoomBackdrop.cell_center(room.layout.wall_cell(side))
	var stones := _props_in(view, ReinforcedRock)
	_check(stones.size() == 1 and stones[0].global_position == wall_at, "a vault door hides behind one stone in the wall, like the secret crack")
	_check(view.door_to(target_id) == null, "a vault shows no door until its stone breaks")
	if stones.size() != 1:
		return
	var stone: ReinforcedRock = stones[0]
	var run: RunState = scene.player.run
	var pills: int = run.health.pills
	var far := Player.arrival_position(room.layout.nearest_floor_cell(door_cell - side * 4))
	scene.player.global_position = far
	# An Auditor blast, a boss attack and the cane all leave it be.
	EnemyBlast.go(view, RoomBackdrop.cell_center(door_cell), 80.0, 10.0, 0.0, scene.player, 0)
	await _wait(0.1)
	_check(not _gone(stone), "an Auditor blast does not break the stone")
	BreakableBlock.smash(get_tree(), RoomBackdrop.cell_center(door_cell), 80.0, BreakableBlock.SOURCE_BOSS)
	await _wait(0.1)
	_check(not _gone(stone), "a boss attack does not break the stone")
	_check(not stone.hit_by(BreakableBlock.SOURCE_CANE), "the cane does not break the stone")
	# A Thermos below the needed level only makes it resist, and says so.
	var told := [0]
	view.notice.connect(func(_text: String): told[0] += 1)
	for level in [0, 2]:
		scene.player.global_position = far
		run.stats.thermos_level = level
		view.place_bomb(RoomBackdrop.cell_center(door_cell))
		await _wait(Thermos.FUSE_TIME + 0.3)
		_check(not _gone(stone), "a level %d Thermos does not break the stone" % level)
	_check(told[0] >= 2, "a stone that resists says so")
	_check(view.door_to(target_id) == null, "no door while the stone stands")
	# The level the floor asks for breaks it, and the blast still costs him nothing at a distance.
	var floor_def: FloorDef = scene.debug_floor_def()
	run.stats.thermos_level = floor_def.vault_stone_level
	scene.player.global_position = far
	view.place_bomb(RoomBackdrop.cell_center(door_cell))
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(_gone(stone), "a max level Thermos breaks the stone")
	_check(view.door_to(target_id) != null, "a broken stone opens the vault door on the same side")
	_check(run.health.pills == pills, "the blasts did not reach him")
	run.stats.thermos_level = 0
	_opened_a_vault = true


func _check_vault_room(scene: Node) -> void:
	_checked_vault_room = true
	var run: RunState = scene.player.run
	var names := {}
	var choices := 0
	var potion: Pickup = null
	for pickup in get_tree().get_nodes_in_group("pickups"):
		names[pickup._label] = true
		if pickup.requires_interact:
			choices += 1
		if pickup._label == RoomRules.POTION_NAME:
			potion = pickup
	_check(names.has(RoomRules.POTION_NAME) and names.has(RoomRules.BOMB_NAME) and names.has(RoomRules.KEY_NAME), "a vault holds a potion, a Thermos and a Slip in the open, found %s in %s" % [str(names.keys()), scene.debug_map().room(scene.debug_current_id()).layout.resource_path])
	# This check takes every item it passes, where a player takes one of each choice, so by a late vault
	# the run may have few left to offer. The vault must still lay out all it can, up to its three.
	var can_offer := 0
	for item in Content.items():
		if run.can_offer(item) and not run.has_item(item.id) and not run.is_promised(item.id):
			can_offer += 1
	_check(choices >= mini(3, can_offer), "a vault offers a choice of items, found %d interactive pickups with %d items left to offer" % [choices, can_offer])
	if potion == null:
		return
	# A small potion fills the slot, and stays on the floor while the slot is full.
	run.potion = null
	run.give_potion(Content.potion("swift_tea"))
	_put_feet(scene, potion.global_position)
	await _wait(0.25)
	_check(not _gone(potion), "a full slot leaves the small potion on the floor")
	_check(run.potion.id == "swift_tea", "and keeps the potion it has")
	run.potion = null
	run.changed.emit()
	await _wait(0.25)
	_check(run.potion != null and run.potion.id == RoomRules.SMALL_POTION_ID, "an empty slot takes the small potion")
	_check(_gone(potion), "and the pickup is gone")
	run.potion = null
	run.changed.emit()


# A stone that was broken stays broken when the room is left and entered again.
func _check_stone_memory(scene: Node) -> void:
	if _checked_stone_memory:
		return
	var map: FloorMap = scene.debug_map()
	var here: FloorRoom = map.room(scene.debug_current_id())
	for side: Vector2i in here.doors:
		var vault_id: int = here.doors[side]
		if map.room(vault_id).room_type != RoomLayout.TYPE_VAULT or not scene.debug_progress().is_visited(vault_id):
			continue
		_checked_stone_memory = true
		var view: RoomView = scene.debug_room_view()
		_check(_props_in(view, ReinforcedRock).is_empty(), "the broken stone is still gone after coming back")
		_check(view.door_to(vault_id) != null, "and its vault door is still there")
		var away: int = vault_id if here.id == map.start_id else map.next_step(here.id, map.start_id)
		await _walk_through_door(scene, away)
		await _walk_through_door(scene, here.id)
		_check(_props_in(scene.debug_room_view(), ReinforcedRock).is_empty(), "the broken stone stays broken after leaving and returning")
		return


# The fuel upgrade hits enemies harder, never Grandpa.
func _check_thermos_fuel(scene: Node) -> void:
	_checked_fuel = true
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var run: RunState = scene.player.run
	var health: Health = run.health
	var floor_def: FloorDef = load("res://data/floors/floor_1.tres")
	var at := RoomBackdrop.cell_center(Vector2i(14, 3))
	var foe: Enemy = view._spawn_enemy(floor_def.floor_boss, at, true)
	foe.set_physics_process(false)
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(3, 8)))
	var hp: float = foe.hp
	view.place_bomb(at)
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(absf((hp - foe.hp) - Thermos.DAMAGE) < 0.01, "a plain Thermos does its base damage, did %f" % (hp - foe.hp))
	run.stats.thermos_damage_mult = 1.9
	hp = foe.hp
	view.place_bomb(at)
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(absf((hp - foe.hp) - Thermos.DAMAGE * 1.9) < 0.01, "a fueled Thermos hurts enemies more, did %f" % (hp - foe.hp))
	# Standing in the blast costs one pill, however strong the Thermos is.
	_put_feet(scene, at)
	await _wait(0.1)
	var pills: int = health.pills
	view.place_bomb(at)
	await _wait(Thermos.FUSE_TIME + 0.3)
	_check(health.pills == pills - Thermos.PLAYER_DAMAGE, "a fueled blast still costs Grandpa exactly %d pill" % Thermos.PLAYER_DAMAGE)
	run.stats.thermos_damage_mult = 1.0
	await _dismiss_all()


# --- Stage 5: the Crossroads and the second path ---

func _check_crossroads(scene: Node) -> void:
	var view: CrossroadsView = scene.debug_room_view()
	var depth: int = scene.debug_depth()
	var cleared: int = Progress.data.clears_at(depth)
	var home: FloorDef = scene.debug_floor_def()
	var home_name := "The Crossroads" if depth == 1 else "Floor %d" % depth
	var map: FloorMap = scene.debug_map()
	var here: FloorRoom = map.room(scene.debug_current_id())
	_check(here.room_type == RoomLayout.TYPE_CROSSROADS, "each depth's paths start from a Crossroads")
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "nothing waits to fight in the Crossroads")
	_check(scene.debug_mini_map().floor_name() == home_name, "the mini map names the Crossroads' floor, depth %d" % depth)
	_check(scene.debug_big_map().floor_name() == home_name, "the big map names the Crossroads' floor, depth %d" % depth)
	_check(scene.debug_progress().is_visited(here.id), "the Crossroads shows on the map")
	var south := RoomBackdrop.cell_center(here.layout.door_cell(RoomLayout.SOUTH))
	_put_feet(scene, south)
	await _wait(0.1)
	# Between the signs neither says anything, and walking over to one brings up its details.
	_check(not view.sign_of_path(RECORDS_PATH).is_showing_details() and not view.sign_of_path(CEMETERY_PATH).is_showing_details(), "a sign shows nothing from afar")
	for index in [RECORDS_PATH, CEMETERY_PATH]:
		var path_sign := view.sign_of_path(index)
		_put_feet(scene, path_sign.global_position + Vector2(0, 16))
		await _wait(0.1)
		_check(path_sign.is_showing_details(), "standing near a sign shows its details, path %d" % index)
	_check(not view.sign_of_path(RECORDS_PATH).is_chained(), "the first path is never chained")
	var cemetery_door: Door = view.door_to(CEMETERY_PATH)
	var should_be_closed := cleared < 1
	_check(view.sign_of_path(CEMETERY_PATH).is_chained() == should_be_closed, "the second path sign is chained only before the first clear, clears %d" % cleared)
	_check(cemetery_door.chained == should_be_closed, "the second path door is chained only before the first clear, clears %d" % cleared)
	if should_be_closed:
		_stand_on(scene, cemetery_door)
		await _wait(0.3)
		_check(scene.debug_current_id() == here.id and scene.debug_floor_def() == home, "walking into the closed path does nothing")
		_check(scene.debug_map() == map, "and builds no floor")
		# Asking the scene outright is refused too, so the rule lives in more than the door.
		scene.debug_choose_path(CEMETERY_PATH)
		await get_tree().process_frame
		_check(scene.debug_floor_def() == home, "a closed path cannot be chosen at all")
	# A door he arrives standing on waits until he has stepped away.
	var records_door: Door = view.door_to(RECORDS_PATH)
	_stand_on(scene, records_door)
	view.refresh_doors()
	await _wait(0.15)
	_check(scene.debug_floor_def() == home, "a door he stands on waits until he steps away")
	_put_feet(scene, south)
	await _wait(0.05)


# Walks out by the real door, so arming and arrival are the real ones.
func _walk_a_path(scene: Node, index: int) -> void:
	var view: CrossroadsView = scene.debug_room_view()
	var door: Door = view.door_to(index)
	_check(door != null and not door.chained, "the chosen path door is open")
	if door == null:
		return
	_stand_on(scene, door)
	await _wait(0.15)
	var def: FloorDef = scene.debug_floor_def()
	var wanted: FloorDef = load(scene.PATHS_BY_DEPTH[scene.debug_depth()][index])
	_check(def == wanted, "walking out by a door enters its floor, got %s" % def.id)
	var map: FloorMap = scene.debug_map()
	_check(scene.debug_current_id() == map.start_id, "a path leads to the start room of its floor")
	_check(scene.debug_mini_map().floor_name() == wanted.display_name, "the mini map names the floor")
	_check(scene.debug_big_map().floor_name() == wanted.display_name, "the big map names the floor")
	var crossroads: FloorRoom = null
	for room in map.rooms:
		if room.room_type == RoomLayout.TYPE_CROSSROADS:
			crossroads = room
	_check(crossroads != null and scene.debug_progress().is_visited(crossroads.id), "the Crossroads stays on the map as its own room")
	if crossroads == null:
		return
	var start: FloorRoom = map.room(map.start_id)
	var side := crossroads.cell - start.cell
	_check(absi(side.x) + absi(side.y) == 1, "the Crossroads sits right beside the start room")
	_check(not start.doors.has(side), "no door leads back to the Crossroads")
	var feet: Vector2 = scene.player.feet().global_position
	_check(feet.distance_to(RoomBackdrop.cell_center(start.layout.door_cell(side))) < Door.ENTER_RADIUS, "he arrives on the side facing the Crossroads")
	await _wait(0.2)
	_check(scene.debug_current_id() == map.start_id, "arriving from the Crossroads does not walk him onward")


func _strikes_in(view: Node) -> Array:
	var found := []
	for child in view.get_children():
		if child is GroundStrike and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _check_graveyard_fights(scene: Node) -> void:
	_checked_graveyard = true
	var back_id: int = scene.debug_current_id()
	var health: Health = scene.player.run.health
	var pills_before := health.max_pills
	health.raise_max(pills_before + 30)
	await _check_plot_holder(scene, health)
	await _check_groundskeeper(scene, health)
	await _check_undertaker(scene, health)
	var def: FloorDef = scene.debug_floor_def()
	await _check_far_boss_waits(scene, def.mini_boss)
	await _check_far_boss_waits(scene, def.floor_boss)
	await _dismiss_all()
	scene._enter_room(back_id)
	await _wait(0.1)
	health.pills = pills_before
	health.raise_max(pills_before)


func _check_plot_holder(scene: Node, health: Health) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var center := RoomBackdrop.cell_center(Vector2i(10, 5))
	_put_feet(scene, center)
	var holder: Enemy = view._spawn_enemy(_enemy_def("plot_holder"), RoomBackdrop.cell_center(Vector2i(3, 2)))
	var waited := 0.0
	while not holder.submerged and waited < 1.0:
		await _wait(0.05)
		waited += 0.05
	_check(holder.submerged, "a Plot Holder digs in")
	var hp: float = holder.hp
	holder.take_damage(20.0, Vector2.ZERO)
	_check(is_equal_approx(holder.hp, hp), "nothing hurts a Plot Holder underground")
	var pills: int = health.pills
	waited = 0.0
	while holder._warning == null and waited < 2.0:
		await _wait(0.02)
		waited += 0.02
	_check(holder._warning != null, "a rise shows a warning first")
	_check(holder.submerged and health.pills == pills, "the warning comes before anything is up")
	_check(holder.global_position.distance_to(center) <= 30.0, "the warning lies under him, off by %f" % holder.global_position.distance_to(center))
	waited = 0.0
	while holder.submerged and waited < 2.0:
		await _wait(0.02)
		waited += 0.02
	_check(not holder.submerged, "it rises when the warning ends")
	_check(waited >= 0.7, "the warning shows long enough to step out, %f" % waited)
	_check(health.pills == pills - holder.def.damage, "staying on the warning costs a hit")
	holder.take_damage(1.0, Vector2.ZERO)
	_check(holder.hp < hp, "up in the open it can be hit")
	# Next time he steps off as soon as the warning shows.
	waited = 0.0
	while holder._warning == null and waited < 6.0:
		await _wait(0.05)
		waited += 0.05
	_check(holder._warning != null, "it comes around again")
	await _wait(0.3)
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(3, 2)) if holder.global_position.x > 200.0 else RoomBackdrop.cell_center(Vector2i(17, 8)))
	var pills_off: int = health.pills
	waited = 0.0
	while holder.submerged and waited < 2.0:
		await _wait(0.02)
		waited += 0.02
	_check(health.pills == pills_off, "stepping off the warning avoids the hit")
	await _dismiss_all()
	# A summoned one pays nothing, and dismissing one underground still clears it.
	var summoned: Enemy = view._spawn_enemy(_enemy_def("plot_holder"), center, true)
	_check(summoned.coin_value() == 0, "a summoned Plot Holder pays nothing")
	await _wait(0.3)
	_check(summoned.submerged, "the summoned one digs in")
	summoned.dismiss()
	await _wait(0.05)
	_check(_gone(summoned), "dismissing one underground clears it")


func _check_groundskeeper(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {Vector2i(9, 5): "A", Vector2i(14, 8): "Y"}))
	var graves := _props_in(view, Gravestone)
	var trees := _props_in(view, DeadTree)
	_check(graves.size() == 1 and trees.size() == 1, "the made room built the graveyard props")
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(3, 5)))
	var gus: Enemy = view._spawn_enemy(def.mini_boss, RoomBackdrop.cell_center(Vector2i(16, 5)), true)
	gus._behavior._summon_timer = 99.0
	gus._behavior._cooldown = 99.0
	await _wait(0.05)
	var pills: int = health.pills
	# The furrow shows a lane, marks its line, and breaks the grave standing on that line.
	gus._behavior._begin(gus, gus._behavior.Attack.FURROW)
	_check(gus._lane_length > 0.0, "the furrow shows a lane first")
	_check(_strikes_in(view).is_empty(), "no strike lands without its windup")
	await _wait(gus._behavior.FURROW_WINDUP + 0.05)
	_check(_strikes_in(view).size() >= 3, "the furrow marks its line, %d" % _strikes_in(view).size())
	_check(health.pills == pills, "marks hurt nothing yet")
	await _wait(1.4)
	_check(_gone(graves[0]), "the furrow breaks a gravestone on its line")
	_check(_strikes_in(view).is_empty(), "every strike has landed")
	# Clippings land on him and around him, and each mark shows first.
	gus._behavior._cooldown = 99.0
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(4, 8)))
	await _wait(0.05)
	pills = health.pills
	gus._behavior._begin(gus, gus._behavior.Attack.CLIPPINGS)
	await _wait(gus._behavior.CLIPPINGS_WINDUP + 0.05)
	var marks := _strikes_in(view)
	_check(marks.size() >= 2, "clippings mark the ground, %d" % marks.size())
	_check(health.pills == pills, "and hurt nothing yet")
	await _wait(gus._behavior.CLIPPINGS_WARNING + 0.1)
	_check(health.pills == pills - gus.def.damage, "standing on the clipping meant for him costs a hit, %d to %d" % [pills, health.pills])
	# A slam breaks what it reaches, and a summon is marked and pays nothing.
	gus.global_position = trees[0].global_position + Vector2(40, 0)
	gus._behavior._cooldown = 99.0
	gus._behavior._begin(gus, gus._behavior.Attack.SLAM)
	await _wait(gus._behavior.SLAM_WINDUP + 0.1)
	_check(_gone(trees[0]), "the slam breaks a dead tree")
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(4, 2)))
	gus._behavior._cooldown = 99.0
	gus._behavior._summon_timer = 0.0
	gus.global_position = RoomBackdrop.cell_center(Vector2i(10, 2))
	await _wait(0.1)
	var summon_marks := 0
	for child in view.get_children():
		if child is SummonMark:
			summon_marks += 1
	_check(summon_marks == gus._behavior.SUMMON_COUNT, "summons are marked first, %d" % summon_marks)
	await _wait(BossMoves.SUMMON_WARNING + 0.1)
	var helpers := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != gus:
			helpers += 1
			_check(enemy.is_summon and enemy.coin_value() == 0, "the groundskeeper summons pay nothing")
			_check(enemy.def.id == "plot_holder", "he summons Plot Holders")
	_check(helpers == summon_marks, "each mark becomes a summon")
	await _dismiss_all()


func _check_undertaker(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var view := await _enter_made_room(scene, _fight_layout(30, 17, {Vector2i(16, 8): "A"}))
	var graves := _props_in(view, Gravestone)
	var at := RoomBackdrop.cell_center(Vector2i(22, 8))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(12, 8)))
	var boss: Enemy = view._spawn_enemy(def.floor_boss, at, true)
	await _wait(0.05)
	var behavior = boss._behavior
	# Rows of plots: all marked, nearest first, each row with its gap.
	behavior._cooldown = 99.0
	behavior._begin(boss, behavior.Attack.ROWS, false)
	_check(boss._warning != null, "the rows show a windup")
	_check(_strikes_in(view).is_empty(), "no row lands before its windup ends")
	await _wait(behavior.ROWS_WINDUP + 0.05)
	var rows: int = behavior.row_count(false)
	var marked := _strikes_in(view).size()
	_check(marked >= (behavior.ROW_SPOTS - 1) * rows - rows * 2, "every row is marked at once, %d" % marked)
	await _wait(behavior.ROW_WARNING + behavior.ROW_STEP * rows + 0.2)
	_check(_gone(graves[0]), "a row breaks a gravestone it reaches")
	await _wait(0.3)
	# Open graves follow him, then lock in, so stepping off in time saves him.
	var health_at := health.pills
	behavior._cooldown = 99.0
	behavior._next = behavior.Attack.NONE
	behavior._begin(boss, behavior.Attack.PITS, false)
	await _wait(behavior.PITS_WINDUP + 0.05)
	var pits := _strikes_in(view)
	_check(pits.size() == behavior.pit_count(false), "each open grave is marked, %d" % pits.size())
	if pits.size() == behavior.pit_count(false):
		_check(pits[0].is_following(), "the first grave follows him")
		var moved_to := RoomBackdrop.cell_center(Vector2i(6, 4))
		_put_feet(scene, moved_to)
		await _wait(0.1)
		_check(pits[0].global_position.distance_to(moved_to) < 20.0, "and keeps up with his feet")
		_check(health.pills == health_at, "following hurts nothing")
		await _wait(behavior.PIT_FOLLOW)
		_check(not pits[0].is_following(), "then it locks in")
		var locked: Vector2 = pits[0].global_position
		var away := RoomBackdrop.cell_center(Vector2i(14, 12))
		_put_feet(scene, away)
		_check(locked.distance_to(away) > behavior.PIT_RADIUS, "the check really stepped off")
		await _wait(behavior.PIT_WARNING)
		_check(health.pills == health_at, "stepping off a locked grave avoids it")
	# The later graves are still following him, so let them all land before going on.
	await _wait(behavior.PIT_STEP * behavior.pit_count(false) + behavior.PIT_WARNING + behavior.PIT_FOLLOW)
	# Wreaths are a warned fan of shots, in more than one volley.
	behavior._cooldown = 99.0
	behavior._next = behavior.Attack.NONE
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(12, 8)))
	await _wait(0.05)
	behavior._begin(boss, behavior.Attack.WREATHS, false)
	_check(boss._warning != null and boss._lane_length > 0.0, "the wreaths show a lane first")
	await _wait(behavior.WREATHS_WINDUP + 0.1)
	var shots := 0
	for child in view.get_children():
		if child is Projectile:
			shots += 1
	_check(shots == behavior.WREATH_SHOTS, "a volley is a fan of wreaths, %d" % shots)
	await _wait(behavior.VOLLEY_GAP + 0.05)
	shots = 0
	for child in view.get_children():
		if child is Projectile:
			shots += 1
	_check(shots > behavior.WREATH_SHOTS, "a second volley follows, %d" % shots)
	await _wait(0.5)
	# Its summons are marked and pay nothing.
	behavior._cooldown = 99.0
	behavior._next = behavior.Attack.NONE
	behavior._begin(boss, behavior.Attack.SUMMON, false)
	await _wait(behavior.SUMMON_WINDUP + 0.1)
	var summon_marks := 0
	for child in view.get_children():
		if child is SummonMark:
			summon_marks += 1
	_check(summon_marks == behavior.SUMMON_COUNT, "its summons are marked first, %d" % summon_marks)
	await _wait(BossMoves.SUMMON_WARNING + 0.1)
	var helpers := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != boss:
			helpers += 1
			_check(enemy.is_summon and enemy.coin_value() == 0, "the undertaker summons pay nothing")
	_check(helpers == summon_marks, "each mark becomes a summon, %d" % helpers)
	await _dismiss_all()
	# Nothing it set going outlives it.
	var last: Enemy = view._spawn_enemy(def.floor_boss, at, true)
	last.set_physics_process(false)
	var pills_now := health.pills
	last.strike_ground(scene.player.feet().global_position, 40.0, 0.3)
	last.take_damage(INF, Vector2.ZERO)
	await _wait(0.5)
	_check(health.pills == pills_now, "a strike comes to nothing once its boss has fallen")
	_check(_strikes_in(view).is_empty(), "and leaves no mark behind")


# --- The second floor: the boss's items, the stairwell, the landing ---

func _offerable_items(run: RunState) -> int:
	var count := 0
	for item in Content.items():
		if run.can_offer(item) and not run.has_item(item.id) and not run.is_promised(item.id):
			count += 1
	return count


func _on_boss_choice_dropped(count: int) -> void:
	_boss_choice_count = count


func _choice_pickups(view: RoomView) -> Array:
	var found := []
	for cell in view._choice_cells:
		for child in view.get_children():
			if child is Pickup and not child.is_queued_for_deletion() and child.global_position.distance_to(view.to_global(RoomBackdrop.cell_center(cell))) < 1.0:
				found.append(child)
	return found


# Two free items lie where the floor boss fell, fewer only when the run's pool has run that low.
# Taking one clears the other away.
func _check_boss_choice(scene: Node, view: RoomView, pool_before: int) -> void:
	var expected := mini(RoomView.BOSS_CHOICE_COUNT, pool_before)
	_check(_boss_choice_count == expected, "a floor boss lays out %d items to choose from, got %d (pool %d)" % [expected, _boss_choice_count, pool_before])
	var choices := _choice_pickups(view)
	_check(choices.size() == _boss_choice_count, "each offered item lies in the room, found %d" % choices.size())
	_boss_choices_checked += 1
	if choices.size() < 2:
		return
	var run: RunState = scene.player.run
	var items_before := run.items.size()
	choices[0].collect()
	await _wait(0.05)
	_check(run.items.size() == items_before + 1, "taking one of the boss's items adds it")
	_check(_gone(choices[1]), "taking one of the boss's items clears the other away")


func _take_the_stairwell(scene: Node) -> void:
	var view: RoomView = scene.debug_room_view()
	var stairs: Door = view.stairwell()
	var depth_above: int = scene.debug_depth()
	var floor_below := "Floor %d" % (depth_above + 1)
	_check(stairs != null, "a fallen floor boss above the last depth opens a stairwell, depth %d" % depth_above)
	if stairs == null:
		return
	for cell in view._choice_cells:
		_check(stairs.position.distance_to(RoomBackdrop.cell_center(cell)) >= RoomBackdrop.TILE * RoomLayout.PICKUP_SPACING, "the stairwell keeps clear of the boss's items")
	var run: RunState = scene.player.run
	var health: Health = run.health
	# He comes down hurt, so the landing's heal shows.
	health.pills = maxi(1, health.max_pills - 3)
	var pills_before := health.pills
	var missing := health.max_pills - pills_before
	# Once the bedpan hangs, the first heal of a run restores one more, and it may not be spent yet.
	var bonus := health.first_heal_bonus + health.heal_bonus
	var items_before := run.items.size()
	var keys_before := run.keys
	var layout: RoomLayout = scene.debug_map().room(scene.debug_current_id()).layout
	var stair_cell := Vector2i(floori(stairs.position.x / RoomBackdrop.TILE), floori(stairs.position.y / RoomBackdrop.TILE))
	var wanted: Array[Vector2i] = [stair_cell + Vector2i(0, 3)]
	var taken: Array[Vector2i] = [stair_cell]
	var away := layout.open_spots_near(wanted, taken)
	_put_feet(scene, RoomBackdrop.cell_center(away[0]) if not away.is_empty() else stairs.global_position + Vector2(0, 80))
	await _wait(0.1)
	_check(scene.debug_depth() == depth_above, "the stairwell waits until he walks onto it")
	_stand_on(scene, stairs)
	await _wait(0.2)
	_check(scene.debug_depth() == depth_above + 1, "walking onto the stairwell takes him down a floor")
	var map: FloorMap = scene.debug_map()
	var landing: FloorRoom = map.room(scene.debug_current_id())
	_check(landing.room_type == RoomLayout.TYPE_LANDING, "the stairwell leads to the landing")
	_check(scene.debug_floor_def().display_name == floor_below, "the landing is %s, got %s" % [floor_below, scene.debug_floor_def().display_name])
	_check(scene.debug_mini_map().floor_name() == floor_below and scene.debug_big_map().floor_name() == floor_below, "both maps name %s" % floor_below)
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "nothing waits to fight on the landing")
	# With the boarding pass hung, landing_heal is one more than LANDING_HEAL.
	_check(health.pills == pills_before + mini(scene.landing_heal() + bonus, missing), "the landing heals him, %d to %d" % [pills_before, health.pills])
	_check(run.items.size() == items_before and run.keys == keys_before, "his items and Slips come down with him")
	_check(not scene.is_cleared, "the new floor is not cleared yet")
	_landings_reached += 1
	await _wait(0.2)
	_check(scene.debug_current_id() == landing.id, "arriving on the landing does not walk him onward")
	_check(landing.doors.size() == 1, "the landing has one way on")
	if landing.doors.is_empty():
		return
	await _walk_through_door(scene, landing.doors.values()[0])
	_check(map.room(scene.debug_current_id()).room_type == RoomLayout.TYPE_CROSSROADS, "the landing leads to the next Crossroads")


# --- Sunset Shores: wet floors, sedatives, the care home's staff and bosses ---

func _check_care_home_fights(scene: Node) -> void:
	_checked_care_home = true
	var back_id: int = scene.debug_current_id()
	var health: Health = scene.player.run.health
	var pills_before := health.max_pills
	health.raise_max(pills_before + 30)
	await _check_wet_floor(scene)
	await _check_orderly(scene, health)
	await _check_cart_nurse(scene)
	await _check_bingo_caller(scene, health)
	await _check_barbara(scene, health)
	await _check_matron(scene, health)
	var def: FloorDef = scene.debug_floor_def()
	await _check_far_boss_waits(scene, def.mini_boss)
	await _check_far_boss_waits(scene, def.floor_boss)
	await _dismiss_all()
	scene._enter_room(back_id)
	await _wait(0.1)
	health.pills = pills_before
	health.raise_max(pills_before)


func _walk_and_let_go(scene: Node, from: Vector2) -> float:
	_put_feet(scene, from)
	await get_tree().physics_frame
	Input.action_press("move_right")
	await _wait(0.35)
	Input.action_release("move_right")
	await get_tree().physics_frame
	var let_go: float = scene.player.feet().global_position.x
	await _wait(0.15)
	return scene.player.feet().global_position.x - let_go


# On a wet floor he keeps moving after letting go, and on a dry one he stops at once.
func _check_wet_floor(scene: Node) -> void:
	var changes := {}
	for x in range(5, 15):
		changes[Vector2i(x, 3)] = "W"
	var view := await _enter_made_room(scene, _fight_layout(20, 11, changes))
	_check(_props_in(view, WetFloor).size() == 10, "the made room laid its wet floor")
	_check(_props_in(view, WetSign).size() == 1, "a wet patch gets one caution sign")
	var dry := await _walk_and_let_go(scene, RoomBackdrop.cell_center(Vector2i(5, 7)))
	var wet := await _walk_and_let_go(scene, RoomBackdrop.cell_center(Vector2i(5, 3)))
	_check(scene.player.on_wet, "his feet on the wet floor count as wet")
	_check(dry < 2.0, "on a dry floor he stops when he lets go, slid %f" % dry)
	_check(wet > 8.0, "on a wet floor he slides on, slid %f" % wet)
	var caution: WetSign = _props_in(view, WetSign)[0]
	_check(caution.hit_by(BreakableBlock.SOURCE_CANE), "the caution sign can be knocked over")


func _check_orderly(scene: Node, health: Health) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(4, 5)))
	var orderly: Enemy = view._spawn_enemy(_enemy_def("orderly"), RoomBackdrop.cell_center(Vector2i(12, 5)) - Player.FEET_OFFSET)
	orderly.set_physics_process(false)
	var pills: int = health.pills
	var behavior = orderly._behavior
	behavior._aim = orderly.direction_to_target()
	behavior._telegraph.start(behavior.WINDUP)
	orderly.set_warning(behavior._telegraph, behavior.WARNING_RADIUS)
	orderly.set_warning_lane(behavior._aim, behavior.LANE_LENGTH, behavior.LANE_WIDTH, false)
	_check(orderly._lane_length > 0.0, "the orderly shows a lane first")
	orderly.set_physics_process(true)
	var waited := 0.0
	while health.pills == pills and waited < 3.0:
		await _wait(0.05)
		waited += 0.05
	_check(health.pills == pills - 1, "a dart costs one pill, %d to %d" % [pills, health.pills])
	_check(scene.player.is_slowed() and is_equal_approx(scene.player.slow_factor(), 0.5), "a dart slows him by half")
	await _wait(1.6)
	_check(not scene.player.is_slowed(), "the slow wears off")
	await _dismiss_all()


func _check_cart_nurse(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {Vector2i(9, 5): "J"}))
	var chairs := _props_in(view, Wheelchair)
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(16, 9)))
	var nurse: Enemy = view._spawn_enemy(_enemy_def("cart_nurse"), RoomBackdrop.cell_center(Vector2i(13, 5)))
	await _wait(0.05)
	var behavior = nurse._behavior
	behavior._cooldown = 99.0
	behavior._direction = Vector2.LEFT
	behavior._charge_left = behavior.CHARGE_TIME * 3.0
	var waited := 0.0
	while not nurse.is_dazed() and waited < 3.0:
		await _wait(0.05)
		waited += 0.05
	_check(_gone(chairs[0]), "the nurse's cart smashes a wheelchair in her way")
	_check(nurse.is_dazed(), "running into the wall stuns her")
	var hp: float = nurse.hp
	nurse.take_damage(5.0, Vector2.ZERO)
	_check(is_equal_approx(nurse.hp, hp - 10.0), "a stunned nurse takes double damage")
	await _wait(behavior.STUN_TIME + 0.1)
	hp = nurse.hp
	nurse.take_damage(5.0, Vector2.ZERO)
	_check(is_equal_approx(nurse.hp, hp - 5.0), "and normal damage once she recovers")
	await _dismiss_all()


func _check_bingo_caller(scene: Node, health: Health) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var center := RoomBackdrop.cell_center(Vector2i(6, 5))
	_put_feet(scene, center)
	var caller: Enemy = view._spawn_enemy(_enemy_def("bingo_caller"), RoomBackdrop.cell_center(Vector2i(15, 5)))
	caller._behavior._wait = 0.0
	var waited := 0.0
	while _strikes_in(view).is_empty() and waited < 2.0:
		await _wait(0.02)
		waited += 0.02
	var marks := _strikes_in(view)
	_check(marks.size() == BingoCallerBehavior.MARKS, "the caller marks three spots, %d" % marks.size())
	for mark in marks:
		_check(mark.global_position.distance_to(center) <= BingoCallerBehavior.MARK_REACH + 1.0, "each mark lies near him")
	var pills: int = health.pills
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(6, 9)) + Vector2(0, 8))
	await _wait(BingoCallerBehavior.MARK_WARNING + 0.1)
	_check(health.pills == pills, "walking away from the marks avoids them")
	await _dismiss_all()


func _check_barbara(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var view := await _enter_made_room(scene, _fight_layout(30, 17, {}))
	var center := RoomBackdrop.cell_center(Vector2i(10, 8))
	_put_feet(scene, center)
	var barbara: Enemy = view._spawn_enemy(def.mini_boss, RoomBackdrop.cell_center(Vector2i(18, 8)), true)
	var behavior = barbara._behavior
	behavior._summon_timer = 99.0
	await _wait(0.05)
	behavior._cooldown = 99.0
	behavior._begin(barbara, ActivitiesCoordinatorBehavior.Attack.BINGO)
	_check(_strikes_in(view).is_empty(), "the grid waits for its windup")
	await _wait(behavior.BINGO_WINDUP + 0.05)
	behavior._cooldown = 99.0
	var tiles := _strikes_in(view)
	_check(tiles.size() == 12, "the bingo grid marks 12 tiles, %d" % tiles.size())
	var safe_x: float = ActivitiesCoordinatorBehavior.column_x(center, behavior._safe_column)
	for tile in tiles:
		_check(absf(tile.global_position.x - safe_x) > 1.0, "no tile lies in the safe column")
	var pills: int = health.pills
	_put_feet(scene, Vector2(safe_x, center.y))
	await _wait(ActivitiesCoordinatorBehavior.TILE_WARNING + ActivitiesCoordinatorBehavior.ROW_STEP * 4 + 0.2)
	_check(health.pills == pills, "standing in the safe column avoids the whole grid")
	behavior._cooldown = 99.0
	behavior._begin(barbara, ActivitiesCoordinatorBehavior.Attack.CAGE)
	_check(barbara._lane_length > 0.0, "the ball cage shows a lane first")
	await _wait(behavior.CAGE_WINDUP + 0.05)
	var balls := 0
	for child in view.get_children():
		if child is Projectile:
			balls += 1
	_check(balls == ActivitiesCoordinatorBehavior.BALLS, "the cage fires five balls, %d" % balls)
	behavior._cooldown = 99.0
	behavior._summon_timer = 0.0
	await _wait(BossMoves.SUMMON_WARNING + 0.2)
	var residents := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != barbara:
			residents += 1
			_check(enemy.is_summon and enemy.coin_value() == 0, "residents pay nothing")
			_check(enemy.def.id == "resident", "she wakes residents")
	_check(residents == ActivitiesCoordinatorBehavior.SUMMON_COUNT, "she wakes two, %d" % residents)
	await _dismiss_all()


func _check_matron(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var view := await _enter_made_room(scene, _fight_layout(30, 17, {Vector2i(14, 8): "K"}))
	var chairs := _props_in(view, Armchair)
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(12, 8)) + Vector2(0, 17))
	var mercy: Enemy = view._spawn_enemy(def.floor_boss, RoomBackdrop.cell_center(Vector2i(18, 8)), true)
	var behavior = mercy._behavior
	await _wait(0.05)
	_check(absf(mercy.max_hp() - 1500.0) < 0.5, "Matron Mercy ends with 1500 health, %f" % mercy.max_hp())
	# The gurney charge shows a lane, breaks the armchair in its way and costs two pills.
	var pills: int = health.pills
	behavior._cooldown = 99.0
	behavior._begin(mercy, MatronBehavior.Attack.GURNEY, false)
	_check(mercy._lane_length > 0.0, "the gurney shows a lane first")
	await _wait(behavior.GURNEY_WINDUP + 1.0)
	_check(_gone(chairs[0]), "the gurney breaks an armchair in its way")
	_check(health.pills == pills - Enemy.HEAVY_DAMAGE, "the gurney costs two pills, %d to %d" % [pills, health.pills])
	await _wait(1.0)
	# Visiting Hours never brings a third Orderly.
	for i in 2:
		mercy.global_position = RoomBackdrop.cell_center(Vector2i(18, 8))
		behavior._cooldown = 99.0
		behavior._next = MatronBehavior.Attack.NONE
		behavior._begin(mercy, MatronBehavior.Attack.VISITING, false)
		await _wait(behavior.VISITING_WINDUP + BossMoves.SUMMON_WARNING + 0.2)
	var visitors := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != mercy:
			visitors += 1
			_check(enemy.is_summon and enemy.coin_value() == 0 and enemy.def.id == "orderly", "she calls Orderlies who pay nothing")
	_check(visitors == MatronBehavior.MAX_VISITORS, "at most %d Orderlies come, %d" % [MatronBehavior.MAX_VISITORS, visitors])
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != mercy:
			enemy.dismiss()
	await _wait(0.1)
	# Lights Out: a warning, then dark, with only syringes thrown and every warning drawn above it.
	behavior._cooldown = 99.0
	behavior._next = MatronBehavior.Attack.NONE
	behavior._begin(mercy, MatronBehavior.Attack.LIGHTS_OUT, false)
	await _wait(behavior.LIGHTS_OUT_WINDUP + 0.1)
	var dark: Array = _props_in(view, LightsOut)
	_check(dark.size() == 1, "Lights Out darkens the room")
	if dark.is_empty():
		return
	_check(not dark[0].is_dark(), "it warns before going dark")
	await _wait(behavior.LIGHTS_OUT_WARNING)
	_check(dark[0].is_dark(), "then the room goes dark")
	behavior._cooldown = 0.0
	var waited := 0.0
	while mercy._warning == null and waited < 2.0:
		await _wait(0.05)
		waited += 0.05
	_check(behavior._attack == MatronBehavior.Attack.SEDATIVE, "in the dark she only throws syringes")
	_check(mercy._warning_layer.z_index + mercy.z_index > LightsOut.Z, "her warning draws above the dark")
	var probe := GroundStrike.new()
	probe.setup(mercy, 10.0, 0.5)
	_check(probe.z_index > LightsOut.Z, "ground marks draw above the dark")
	probe.free()
	await _wait(behavior.LIGHTS_OUT_TIME + LightsOut.FADE_OUT + 0.2)
	_check(_props_in(view, LightsOut).is_empty(), "the lights come back on")
	# The dark lifts at once when she falls.
	behavior._since_lights_out = 99.0
	behavior._cooldown = 99.0
	behavior._next = MatronBehavior.Attack.NONE
	behavior._begin(mercy, MatronBehavior.Attack.LIGHTS_OUT, false)
	await _wait(behavior.LIGHTS_OUT_WINDUP + 0.3)
	mercy.take_damage(INF, Vector2.ZERO)
	await _wait(LightsOut.FADE_OUT + 0.2)
	_check(_props_in(view, LightsOut).is_empty(), "the dark ends when she falls")
	await _dismiss_all()


# --- The Furnace Works: vents, burning ground, the boiler hall's staff and bosses ---

func _check_furnace_fights(scene: Node) -> void:
	_checked_furnace = true
	var health: Health = scene.player.run.health
	var pills_before := health.max_pills
	health.raise_max(pills_before + 30)
	var back_id: int = scene.debug_current_id()
	await _check_vents(scene, health)
	await _check_stoker(scene, health)
	await _check_steam_valve(scene, health)
	await _check_soot_ghost(scene)
	await _check_klaus(scene, health)
	await _check_old_smokey(scene, health)
	await _check_corner_slide(scene)
	var def: FloorDef = scene.debug_floor_def()
	await _check_far_boss_waits(scene, def.mini_boss)
	await _check_far_boss_waits(scene, def.floor_boss)
	await _dismiss_all()
	scene._enter_room(back_id)
	await _wait(0.1)
	health.pills = pills_before
	health.raise_max(pills_before)


func _wait_for(check: Callable, limit: float) -> bool:
	var waited := 0.0
	while not check.call() and waited < limit:
		await get_tree().physics_frame
		waited += get_physics_process_delta_time()
	return check.call()


# A flare costs Grandpa a pill and hurts an enemy on a vent, but never a boss.
func _check_vents(scene: Node, health: Health) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {Vector2i(8, 5): "U", Vector2i(12, 5): "U"}))
	var vents: Array = _props_in(view, FloorVent)
	_check(vents.size() == 2, "the made room laid its vents")
	var mine: FloorVent = vents[0] if vents[0].position.x < vents[1].position.x else vents[1]
	var theirs: FloorVent = vents[1] if mine == vents[0] else vents[0]
	_put_feet(scene, mine.global_position)
	var reaper: Enemy = view._spawn_enemy(_enemy_def("furnace_intern_reaper"), theirs.global_position)
	reaper.set_physics_process(false)
	var boss: Enemy = view._spawn_enemy(scene.debug_floor_def().floor_boss, RoomBackdrop.cell_center(Vector2i(16, 8)), true)
	boss.set_physics_process(false)
	mine.force_flare(0.2, 0.3)
	theirs.force_flare(0.2, 0.3)
	var pills: int = health.pills
	var hp: float = reaper.hp
	await _wait(0.2 + 0.15)
	_check(health.pills == pills - FloorVent.PLAYER_DAMAGE, "a flare costs him a pill, %d to %d" % [pills, health.pills])
	_check(is_equal_approx(reaper.hp, hp - FloorVent.ENEMY_DAMAGE), "a flare hurts an enemy on it too")
	_put_feet(scene, boss.global_position)
	var boss_vent := FloorVent.new()
	boss_vent.position = boss.global_position
	view.add_child(boss_vent)
	var boss_hp: float = boss.hp
	boss_vent.force_flare(0.05, 0.2)
	await _wait(0.3)
	_check(is_equal_approx(boss.hp, boss_hp), "a boss never feels the vents")
	await _dismiss_all()


# Coal lands on a warned mark and leaves fire that keeps hurting whoever stands in it.
func _check_stoker(scene: Node, health: Health) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var spot := RoomBackdrop.cell_center(Vector2i(6, 5))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(6, 8)))
	var stoker: Enemy = view._spawn_enemy(_enemy_def("stoker"), RoomBackdrop.cell_center(Vector2i(14, 5)))
	stoker.set_physics_process(false)
	var reaper: Enemy = view._spawn_enemy(_enemy_def("furnace_intern_reaper"), spot)
	reaper.set_physics_process(false)
	StokerBehavior.throw_coal(stoker, spot, StokerBehavior.COAL_WARNING, StokerBehavior.BURN_TIME)
	var strikes := _strikes_in(view)
	_check(strikes.size() == 1 and strikes[0].fill() < 0.2, "the coal's spot is marked first")
	await _wait(StokerBehavior.COAL_WARNING + 0.1)
	_check(strikes[0].is_burning(), "the coal leaves burning ground")
	var hp: float = reaper.hp
	await _wait(GroundStrike.BURN_EVERY + 0.1)
	_check(reaper.hp < hp, "the fire hurts an enemy standing in it")
	var pills: int = health.pills
	_put_feet(scene, spot)
	await _wait(Health.INVULN_TIME + 0.2)
	_check(health.pills < pills, "the fire hurts him when he steps in")
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(6, 8)))
	await _wait(StokerBehavior.BURN_TIME)
	_check(_strikes_in(view).is_empty(), "the fire burns out")
	await _dismiss_all()


# A valve starts beside a wall, a hit never moves it, and its steam costs a pill down its lane.
func _check_steam_valve(scene: Node, health: Health) -> void:
	var layout := _fight_layout(20, 11, {Vector2i(9, 5): "E", Vector2i(12, 7): "E"})
	var floor_def := FloorDef.new()
	floor_def.enemies = [_enemy_def("steam_valve")]
	for entry in EnemyPlan.plan(layout, floor_def, 0, RandomNumberGenerator.new()):
		_check(EnemyPlan.beside_a_wall(layout, entry["cell"]), "a valve starts beside a wall, at %s" % str(entry["cell"]))
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(10, 4)))
	var valve: Enemy = view._spawn_enemy(_enemy_def("steam_valve"), RoomBackdrop.cell_center(Vector2i(10, 1)))
	await _wait(0.1)
	var at: Vector2 = valve.global_position
	valve.take_damage(1.0, Vector2(400, 0))
	await _wait(0.2)
	_check(valve.global_position.distance_to(at) < 0.5, "a hit never moves a valve")
	var behavior = valve._behavior
	behavior._lane = Vector2.RIGHT
	behavior._cooldown = 0.0
	var pills: int = health.pills
	var warned := await _wait_for(func(): return valve._warning != null, 2.0)
	_check(warned and valve.warning_lane_direction().is_equal_approx(Vector2.DOWN), "it turns to its next lane and warns it first")
	_check(valve.warning_lane_length() > 0.0, "the steam shows its lane")
	await _wait(SteamValveBehavior.WINDUP + 0.2)
	_check(health.pills == pills - 1, "the steam costs a pill down its lane, %d to %d" % [pills, health.pills])
	await _dismiss_all()


# In the smoke nothing reaches it, but it always comes back out beside him, and goes in again.
func _check_soot_ghost(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {}))
	var feet := RoomBackdrop.cell_center(Vector2i(6, 5))
	_put_feet(scene, feet)
	var ghost: Enemy = view._spawn_enemy(_enemy_def("soot_ghost"), RoomBackdrop.cell_center(Vector2i(15, 5)))
	await _wait(0.2)
	_check(ghost.submerged, "it starts in the smoke")
	var hp: float = ghost.hp
	ghost.take_damage(30.0, Vector2.ZERO)
	_check(is_equal_approx(ghost.hp, hp), "nothing reaches it in the smoke")
	var out := await _wait_for(func(): return not ghost.submerged, SootGhostBehavior.FIRST_SMOKE + SootGhostBehavior.RISE_WINDUP + 0.5)
	_check(out, "it comes out of the smoke")
	_check(ghost.global_position.distance_to(feet) <= SootGhostBehavior.SWIPE_RANGE + 2.0, "beside him")
	ghost.take_damage(5.0, Vector2.ZERO)
	_check(ghost.hp < hp, "out in the open it can be hit")
	var back := await _wait_for(func(): return ghost.submerged, SootGhostBehavior.OPEN_TIME + 0.5)
	_check(back, "it fades into the smoke again")
	var again := await _wait_for(func(): return not ghost.submerged, SootGhostBehavior.SMOKE_TIME + SootGhostBehavior.RISE_WINDUP + 0.5)
	_check(again, "and always comes back out")
	await _dismiss_all()


func _jets_in(view: Node) -> Array:
	var found := []
	for child in view.get_children():
		if child is SteamJet and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _check_klaus(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var view := await _enter_made_room(scene, _fight_layout(30, 17, {}))
	var center := RoomBackdrop.cell_center(Vector2i(18, 8))
	_put_feet(scene, center + Vector2(-100, 0))
	var klaus: Enemy = view._spawn_enemy(def.mini_boss, center, true)
	_check(absf(klaus.max_hp() - 500.0) < 0.5, "Klaus ends with 500 health, %f" % klaus.max_hp())
	var behavior = klaus._behavior
	behavior._summon_timer = 99.0
	await _wait(0.05)
	klaus.global_position = center
	# The ring rolls out to him at 100 px and costs a pill.
	behavior._cooldown = 99.0
	var pills: int = health.pills
	behavior._begin(klaus, ForemanBehavior.Attack.SLAM)
	_check(_props_in(view, Shockwave).size() == 1, "the slam shows the ring's reach first")
	await _wait(ForemanBehavior.SLAM_WINDUP + ForemanBehavior.RING_TIME + 0.1)
	_check(health.pills == pills - 1, "the ring costs a pill as it passes, %d to %d" % [pills, health.pills])
	await _wait(Health.INVULN_TIME)
	# Standing inside the hollow, past the slam but short of where the ring starts, is safe from the ring.
	behavior._cooldown = 99.0
	klaus.global_position = center
	_put_feet(scene, center + Vector2(0, 140 + 30))
	pills = health.pills
	behavior._begin(klaus, ForemanBehavior.Attack.SLAM)
	await _wait(ForemanBehavior.SLAM_WINDUP + ForemanBehavior.RING_TIME + 0.1)
	_check(health.pills == pills, "beyond the ring's reach is safe")
	# Steam lines: three lanes, and the clear one is safe.
	behavior._cooldown = 99.0
	behavior._across = Vector2.DOWN
	behavior._gap = -1
	_put_feet(scene, RoomBackdrop.cell_center(Vector2i(10, 8)))
	behavior._begin(klaus, ForemanBehavior.Attack.STEAM)
	await _wait(ForemanBehavior.STEAM_WINDUP + 0.05)
	behavior._cooldown = 99.0
	var jets := _jets_in(view)
	_check(jets.size() == 3 and jets[0].is_warning(), "three steam lanes are warned, %d" % jets.size())
	var lanes := ForemanBehavior.steam_lanes(ForemanBehavior.room_rect(klaus.room_cells), Vector2.RIGHT, -1, scene.player.feet().global_position)
	var clear: Rect2 = lanes[behavior._gap]
	_put_feet(scene, clear.get_center())
	pills = health.pills
	await _wait(ForemanBehavior.STEAM_WARNING + SteamJet.BLOW_TIME)
	_check(health.pills == pills, "the clear lane is safe")
	# Two Stokers, who pay nothing.
	behavior._cooldown = 99.0
	behavior._summon_timer = 0.0
	await _wait(BossMoves.SUMMON_WARNING + 0.2)
	var stokers := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy != klaus:
			stokers += 1
			_check(enemy.is_summon and enemy.coin_value() == 0 and enemy.def.id == "stoker", "he calls Stokers who pay nothing")
	_check(stokers == ForemanBehavior.SUMMON_COUNT, "he calls two, %d" % stokers)
	await _dismiss_all()


func _check_old_smokey(scene: Node, health: Health) -> void:
	var def: FloorDef = scene.debug_floor_def()
	var changes := {}
	for x in range(4, 26):
		changes[Vector2i(x, 5)] = "U"
		changes[Vector2i(x, 11)] = "U"
	var view := await _enter_made_room(scene, _fight_layout(30, 17, changes))
	var center := RoomBackdrop.cell_center(Vector2i(18, 8))
	_put_feet(scene, center + Vector2(-80, 0))
	var smokey: Enemy = view._spawn_enemy(def.floor_boss, center, true)
	_check(absf(smokey.max_hp() - 1500.0) < 0.5, "Old Smokey ends with 1500 health, %f" % smokey.max_hp())
	var behavior = smokey._behavior
	await _wait(0.05)
	smokey.global_position = center
	# Fire breath: a warned cone, then two pills.
	behavior._cooldown = 99.0
	var pills: int = health.pills
	behavior._begin(smokey, ChiefStokerBehavior.Attack.BREATH, false)
	_check(smokey.warning_cone_length() > 0.0, "the breath shows its cone first")
	await _wait(ChiefStokerBehavior.BREATH_WINDUP + 0.1)
	_check(health.pills == pills - Enemy.HEAVY_DAMAGE, "the breath costs two pills, %d to %d" % [pills, health.pills])
	behavior._cooldown = 99.0
	await _wait(Health.INVULN_TIME)
	# Bellows: a warned lane, then a pull toward him that costs nothing.
	behavior._cooldown = 99.0
	behavior._next = ChiefStokerBehavior.Attack.NONE
	smokey.global_position = center
	_put_feet(scene, center + Vector2(-180, 0))
	pills = health.pills
	behavior._begin(smokey, ChiefStokerBehavior.Attack.BELLOWS, false)
	_check(smokey.warning_lane_length() > 0.0, "the bellows show a lane first")
	var was: float = scene.player.feet().global_position.distance_to(center)
	await _wait(ChiefStokerBehavior.BELLOWS_WINDUP + 0.05)
	_check(scene.player.is_pushed(), "the bellows pull him")
	await _wait(ChiefStokerBehavior.BELLOWS_TIME)
	_check(scene.player.feet().global_position.distance_to(center) < was - 60.0, "toward the fire")
	_check(health.pills == pills, "the pull itself costs nothing")
	# Vent grid: every vent but a way through flares, and none under him.
	behavior._cooldown = 99.0
	behavior._next = ChiefStokerBehavior.Attack.NONE
	var feet_cell := Vector2i(10, 5)
	_put_feet(scene, RoomBackdrop.cell_center(feet_cell))
	behavior._begin(smokey, ChiefStokerBehavior.Attack.GRID, false)
	await _wait(ChiefStokerBehavior.GRID_WINDUP + 0.05)
	behavior._cooldown = 99.0
	behavior._next = ChiefStokerBehavior.Attack.NONE
	var warning := 0
	var all := 0
	for vent: FloorVent in _props_in(view, FloorVent):
		all += 1
		warning += 1 if vent.is_warning() else 0
		if vent.position.distance_to(RoomBackdrop.cell_center(feet_cell)) < 1.0:
			_check(not vent.is_warning(), "the vent under him stays cold")
	_check(warning * 2 >= all, "most vents flare in the grid, %d of %d" % [warning, all])
	await _wait(ChiefStokerBehavior.GRID_WARN + ChiefStokerBehavior.GRID_FLARE + 0.1)
	# Coal rain: five burning marks.
	behavior._cooldown = 99.0
	behavior._next = ChiefStokerBehavior.Attack.NONE
	_put_feet(scene, center + Vector2(-90, 60))
	behavior._begin(smokey, ChiefStokerBehavior.Attack.RAIN, false)
	await _wait(ChiefStokerBehavior.RAIN_WINDUP + 0.05)
	behavior._cooldown = 99.0
	var marks := _strikes_in(view)
	_check(marks.size() >= 4, "coal rains on five marks, %d landed on open ground" % marks.size())
	_check(marks.size() > 0 and is_equal_approx(marks[0].linger(), ChiefStokerBehavior.RAIN_BURN), "each mark leaves fire")
	# The second phase makes the room's vents flare more often.
	smokey.take_damage(smokey.max_hp() * 0.55, Vector2.ZERO)
	await _wait(0.1)
	var vents: Array = _props_in(view, FloorVent)
	_check(not vents.is_empty() and is_equal_approx(vents[0].cycle.period, FloorVent.PERIOD * ChiefStokerBehavior.PHASE_TWO_VENT_PERIOD), "below half health the vents flare faster")
	await _dismiss_all()


# Walking straight past a prop that clips his feet by a few pixels slides him round its corner, but
# a real overlap still stops him.
func _check_corner_slide(scene: Node) -> void:
	var view := await _enter_made_room(scene, _fight_layout(20, 11, {Vector2i(10, 5): "O"}))
	var rocks: Array = _props_in(view, RockBlock)
	_check(rocks.size() == 1, "the made room has its rock")
	if rocks.is_empty():
		return
	var rect: Rect2 = rocks[0].body_rect()
	for entry in [[3.0, true], [9.0, false]]:
		var overlap: float = entry[0]
		_put_feet(scene, Vector2(rect.position.x - Player.FEET_BOX_SIZE.x / 2.0 - 20.0, rect.end.y + Player.FEET_BOX_SIZE.y / 2.0 - overlap))
		await get_tree().physics_frame
		Input.action_press("move_right")
		await _wait(0.7)
		Input.action_release("move_right")
		await get_tree().physics_frame
		var passed: bool = scene.player.feet().global_position.x > rect.end.x
		if entry[1]:
			_check(passed, "clipping a corner by %d px slides him round it" % overlap)
		else:
			_check(not passed, "a %d px overlap still blocks him" % overlap)


# The second run ended on Head Office, whose Chairman fell for the first time, so the ending card
# shows after the run's last message and before the Waiting Room, and a press closes it.
# Beating Augustine plays his scene before FLOOR CLEARED, the whole of it the first time, and the loop
# skips it as a player would.
func _check_augustine_scene(scene: Node) -> void:
	var cut: CutscenePlayer = scene.debug_cutscene()
	_check(cut != null, "beating Augustine plays his scene")
	if cut == null:
		return
	_check(_hud_message(scene) != "FLOOR CLEARED", "his scene comes before FLOOR CLEARED")
	await _wait(0.5)
	_check(not cut.can_skip(), "the first time, the skip waits for the first text box")
	await _skip_cutscene(cut)
	await _wait(0.3)
	_check(not is_instance_valid(cut), "holding interact skips his scene")
	_checked_augustine = true


# Beating the Chairman in a forced fast run plays Crashing the Funeral, saves it found with its
# Condolences, and the loop skips it; the same run again would now be Briefly Alive, as Crashing the
# Funeral is found; and the Waiting Room welcomes him back.
func _check_ending_scene(found_before: int) -> void:
	var scene := get_tree().current_scene
	await _wait(scene.MESSAGE_TIME + 0.4)
	var cut: CutscenePlayer = scene.debug_cutscene() if scene.has_method("debug_cutscene") else null
	_check(cut != null, "beating the Chairman plays an ending scene")
	_check(scene.debug_ending_id() == EndingRules.CRASHING_THE_FUNERAL, "a fast run plays Crashing the Funeral, got %s" % scene.debug_ending_id())
	_check(Progress.data.endings_found.size() == found_before + 1, "the found set grows by one")
	_check(Progress.data.endings_found.has(EndingRules.CRASHING_THE_FUNERAL), "the ending is saved found")
	_check(int(Progress.last_run.get("ending_paid", 0)) == ProgressData.ENDING_CONDOLENCES, "a new ending pays its Condolences")
	# The loop's run also carries many items and much Pension, so another ending may hold as well: the
	# same run again never repeats the one now found, and is Briefly Alive when nothing else holds.
	var snapshot: Dictionary = scene.debug_ending_snapshot()
	var found: Dictionary = Progress.data.endings_found
	var again := EndingRules.choose(snapshot, found)
	var others_hold := false
	for id in EndingRules.FEUD_COUNTS:
		if id != EndingRules.CRASHING_THE_FUNERAL and EndingRules.holds(id, snapshot, found) and not found.has(id):
			others_hold = true
	_check(again != EndingRules.CRASHING_THE_FUNERAL, "a second identical run does not repeat a found ending")
	_check(others_hold or again == EndingRules.BRIEFLY_ALIVE, "a second identical run picks Briefly Alive when nothing else holds, got %s" % again)
	var fast_only := snapshot.duplicate()
	fast_only.merge({"pills": 3, "pension_earned": 0, "items": 0, "arcade_visits_won": 0, "cursed": false, "paths": {}}, true)
	_check(EndingRules.choose(fast_only, found) == EndingRules.BRIEFLY_ALIVE, "the same fast run, with nothing else, is now Briefly Alive")
	print("SMOKE NOTE the same run again would be %s (pills %d, items %d, Pension %d, table visits %d)" % [again, snapshot["pills"], snapshot["items"], snapshot["pension_earned"], snapshot["arcade_visits_won"]])
	if cut == null:
		return
	await _skip_cutscene(cut)
	await _wait(0.6)
	_expect_scene("WaitingRoom")
	var room := get_tree().current_scene
	_check(_hud_message(room) == "Welcome back. Please take a number.", "the Waiting Room welcomes him back, got '%s'" % _hud_message(room))
	_checked_ending = true


# Skips a scene as a player would: the first time the skip waits for the first text box, so that box is
# pressed on once it has shown, then interact is held.
func _skip_cutscene(cut: CutscenePlayer) -> void:
	var guard := 0
	while is_instance_valid(cut) and not cut.can_skip() and guard < 300:
		guard += 1
		if not cut.current_text().is_empty():
			await _wait(CutscenePlayer.MIN_SHOW_TIME + 0.1)
			await _press("interact")
		else:
			await _wait(0.1)
	_check(is_instance_valid(cut) and cut.can_skip(), "the skip is offered once the first text box has gone")
	Input.action_press("interact")
	await _wait(CutscenePlayer.SKIP_HOLD + 0.4)
	Input.action_release("interact")
