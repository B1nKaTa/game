extends Node

const TIMEOUT := 180.0
const MAX_ROOMS := 40

var _failed := false
var _boss_rooms_seen := 0
var _crafted_id := ""


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
		print("SMOKE PASS")
		get_tree().quit(0)


func _clear_whole_floor() -> void:
	Game.begin_run()
	await _wait(0.5)
	_expect_scene("FloorScene")
	var scene := get_tree().current_scene
	var starting_pills: int = scene.player.run.stats.max_pills
	_check(starting_pills >= 4, "run starts with pills")
	var guard := 0
	while not scene.is_cleared and guard < MAX_ROOMS:
		guard += 1
		await _clear_room(scene)
		if scene.is_cleared:
			break
		scene.debug_take_first_exit()
		await _wait(0.2)
		if guard == 1:
			await _clear_room(scene)
			await _walk_back_and_return(scene)
	_check(scene.is_cleared, "floor can be cleared")
	_check(_boss_rooms_seen >= 2, "both bosses showed a boss bar")


func _walk_back_and_return(scene: Node) -> void:
	await _wait(0.5)
	var pension_before: int = Progress.data.pension
	scene.debug_go_back()
	await _wait(0.2)
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "a cleared room stays clear when walking back")
	_check(Progress.data.pension == pension_before, "walking back earns no Pension")
	var big_map: FloorMapView = scene.debug_big_map()
	big_map.set_open(true)
	_check(get_tree().paused, "the big map pauses the game")
	big_map.set_open(false)
	_check(not get_tree().paused, "closing the big map resumes the game")
	scene.debug_take_first_exit()
	await _wait(0.2)
	_check(get_tree().get_nodes_in_group("enemies").is_empty(), "a cleared room stays clear when returning")
	_check(Progress.data.pension == pension_before, "returning earns no Pension")


func _clear_room(scene: Node) -> void:
	await _wait(0.1)
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
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and not scene.is_over:
			if pickup.requires_interact:
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
