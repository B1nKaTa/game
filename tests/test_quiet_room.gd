extends TestCase

# A floor's first room is quiet (playtest 9, note 8): its combat layout spawns no enemies, its doors are
# open from the start, and it pays nothing for a clear it never had.

const LAYOUT := "res://data/rooms/floor_1/combat_01.tres"


# Room 0 (the one built) beside room 1, so the view has a door to lock or not.
func _view(quiet: bool) -> Dictionary:
	var map := FloorMap.new()
	for i in 2:
		var room := FloorRoom.new()
		room.id = i
		room.room_type = RoomLayout.TYPE_COMBAT
		room.layout = load(LAYOUT)
		room.cell = Vector2i(i, 0)
		map.rooms.append(room)
	map.join(map.room(0), map.room(1))
	map.room(0).quiet = quiet
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var view := RoomView.new()
	view.setup(map.room(0), map, load("res://data/floors/floor_1.tres"), run, player, rng, FloorProgress.new(map), null)
	var paid: Array[int] = []
	view.pension_earned.connect(func(amount: int): paid.append(amount))
	view._ready()
	return {"view": view, "player": player, "run": run, "map": map, "paid": paid}


func _free(parts: Dictionary) -> void:
	for key in ["view", "player"]:
		if is_instance_valid(parts[key]):
			parts[key].free()


func _loose_pickups(view: RoomView) -> int:
	var count := 0
	for child in view.get_children():
		if child is Pickup and not child is Chest:
			count += 1
	return count


func test_the_layout_fights_when_the_room_is_not_quiet() -> void:
	var parts := _view(false)
	var view: RoomView = parts["view"]
	assert_true(view.debug_alive() > 0, "the layout has enemy cells")
	assert_true(view.is_fighting())
	assert_true(view.door_to(1).locked, "a fight shuts the doors")
	_free(parts)


func test_a_quiet_room_spawns_no_enemies_and_plays_no_fight() -> void:
	var parts := _view(true)
	var view: RoomView = parts["view"]
	assert_eq(view.debug_alive(), 0)
	assert_false(view.is_fighting())
	assert_true(view.is_finished(), "nothing to clear, so it is done from the start")
	_free(parts)


func test_a_quiet_rooms_doors_are_open_from_the_start() -> void:
	var parts := _view(true)
	var view: RoomView = parts["view"]
	assert_eq(view.doors().size(), 1)
	assert_false(view.door_to(1).locked)
	_free(parts)


func test_a_quiet_room_pays_no_clear_pension_and_drops_nothing() -> void:
	var parts := _view(true)
	assert_eq(parts["paid"], [] as Array[int], "no clear Pension")
	assert_eq(_loose_pickups(parts["view"]), 0, "no clear drop")
	_free(parts)


func test_a_quiet_room_saves_as_cleared() -> void:
	var parts := _view(true)
	var shot: Dictionary = parts["view"].snapshot()
	assert_true(shot["cleared"])
	_free(parts)


# F there keeps the reel and says why (Task 7's rule: the reel plays only while a fight is on).
func test_f_in_a_quiet_room_saves_the_reel_for_a_fight() -> void:
	var parts := _view(true)
	var run: RunState = parts["run"]
	var hud := Hud.new()
	hud.setup(run)
	hud._ready()
	var keeper := RuleKeeper.new()
	keeper.setup(parts["player"], hud, run, Callable())
	keeper.plan_floor(parts["map"], 1, "seed", FloorProgress.new(parts["map"]))
	keeper.on_room_entered(parts["view"], parts["map"].room(0), true)
	run.give_reel(Eras.FOOTBALL)
	assert_false(keeper.try_play_reel())
	assert_eq(hud._notice.text, RuleKeeper.SAVE_NOTICE)
	assert_eq(run.held_reel, Eras.FOOTBALL, "the reel is kept")
	assert_eq(run.era, "")
	keeper.free()
	hud.free()
	_free(parts)
