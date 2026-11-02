extends Node

const TIMEOUT := 180.0
const MAX_ROOMS := 40

var _failed := false
var _boss_rooms_seen := 0


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

	await _die_in_a_run()
	await _wait(2.5)
	_expect_scene("WaitingRoom")

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
	_check(scene.is_cleared, "floor can be cleared")
	_check(_boss_rooms_seen >= 2, "both bosses showed a boss bar")


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
