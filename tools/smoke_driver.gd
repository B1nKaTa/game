extends Node

const TIMEOUT := 240.0
const MAX_STEPS := 150
const VIEW := Vector2(640, 360)
const AIM_TOLERANCE := 1.5

var _failed := false
var _boss_rooms_seen := 0
var _crafted_id := ""
var _cleared_rooms := {}
var _sizes_seen := {}
var _followed_a_big_room := false
var _checked_block_memory := false
var _saw_shop := false
var _checked_props := false
var _pickups_off_solids := 0


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

	Progress.add_pension(500)
	var upgrade: UpgradeDef = Content.upgrades()[0]
	var spent_ok: bool = Progress.buy(upgrade)
	_check(spent_ok, "can buy an upgrade")
	var pension_before: int = Progress.data.pension

	await _clear_whole_floor()
	_check(Progress.data.pension > pension_before, "Pension was earned during the run")
	await _wait(2.5)
	_expect_scene("WaitingRoom")

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

	await _die_in_a_run()
	await _wait(2.5)
	_expect_scene("WaitingRoom")
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
	_check(Progress.data.level_of(upgrade.id) == 1, "upgrade survives a reload")

	if not _failed:
		print("SMOKE PASS rooms of sizes %s, big room view checked: %s, block memory checked: %s, props checked: %s, pickups off solids: %d" % [str(_sizes_seen.keys()), str(_followed_a_big_room), str(_checked_block_memory), str(_checked_props), _pickups_off_solids])
		get_tree().quit(0)


# Explores every room through its real door, secret room included, and leaves the boss for last.
func _clear_whole_floor() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	var starting_pills: int = scene.player.run.stats.max_pills
	_check(starting_pills >= 4, "run starts with pills")
	var map: FloorMap = scene.debug_map()
	var walked_back := false
	var guard := 0
	while not scene.is_cleared and not _failed and guard < MAX_STEPS:
		guard += 1
		await _clear_room(scene)
		if scene.is_cleared:
			break
		await _check_camera(scene)
		await _check_big_room_view(scene)
		if not _checked_props:
			await _check_props_room(scene)
		var at: int = scene.debug_current_id()
		if not walked_back and at != map.start_id:
			walked_back = true
			await _walk_back_and_return(scene, at)
		if map.room(at).room_type == RoomLayout.TYPE_SHOP and not _saw_shop:
			_check_shop(scene)
		if at != map.start_id:
			await _check_a_broken_block_stays_broken(scene, at)
		var next: int = map.next_step(at, _next_goal(scene, map))
		await _walk_through_door(scene, next)
	_check(scene.is_cleared, "floor can be cleared")
	_check(walked_back, "the check walked back through a door")
	_check(_saw_shop, "the shop was checked")
	_check(_boss_rooms_seen >= 2, "both bosses showed a boss bar")
	for room in map.rooms:
		_check(scene.debug_progress().is_visited(room.id), "room %d (%s) was explored" % [room.id, room.room_type])


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
	var rest: Vector2 = scene.debug_camera().position
	scene.debug_feedback().on_hurt()
	var shook := false
	for i in 5:
		await get_tree().process_frame
		shook = shook or not scene.debug_camera().offset.is_zero_approx()
		await _check_camera(scene)
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
	block.take_blast()
	await _wait(0.1)
	var blocks_left := _plain_block_count()
	var map: FloorMap = scene.debug_map()
	await _walk_through_door(scene, map.next_step(here_id, map.start_id))
	await _walk_through_door(scene, here_id)
	_check(_plain_block_count() == blocks_left, "a broken block stays broken on return")


func _plain_block() -> BreakableBlock:
	for block in get_tree().get_nodes_in_group("breakable"):
		if not block is SecretWall and not block is RetirementStation and not block.is_queued_for_deletion():
			return block
	return null


func _plain_block_count() -> int:
	var count := 0
	for block in get_tree().get_nodes_in_group("breakable"):
		if not block is SecretWall and not block is RetirementStation and not block.is_queued_for_deletion():
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
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.take_damage(INF, Vector2.ZERO)
	await _wait(0.1)
	if boss_here:
		_check(not hud.is_boss_bar_visible(), "boss bar is hidden after the boss falls")
	_check_pickups_off_solids(scene, room_id)
	for pickup in get_tree().get_nodes_in_group("pickups"):
		# Walking onto a pickup near a door can leave the room, and then the rest are out of reach.
		if scene.is_over or scene.debug_current_id() != room_id:
			return
		if not is_instance_valid(pickup) or not pickup.is_inside_tree():
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


func _die_in_a_run() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	if not _crafted_id.is_empty():
		_check(scene.player.run.has_item(_crafted_id), "the crafted item starts the next run")
	scene.player.run.health.hit(999)
	await _wait(0.1)
	_check(scene.is_over, "death ends the run")


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
	# Shots and the thrown cane ask layer 1: rocks and barrels stop them, holes do not.
	var space: PhysicsDirectSpaceState2D = scene.player.get_world_2d().direct_space_state
	var across_rock := _ray(space, rocks[0].global_position, 1)
	var across_hole := _ray(space, holes[0].global_position, 1)
	var across_hole_layer := _ray(space, holes[0].global_position, Hole.LAYER)
	_check(not across_rock.is_empty(), "a rock stops shots and the thrown cane")
	_check(across_hole.is_empty(), "shots and the thrown cane fly over a hole")
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
