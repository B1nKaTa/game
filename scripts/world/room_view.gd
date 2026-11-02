class_name RoomView
extends Node2D

signal door_entered(target_id: int)
signal floor_cleared
signal pension_earned(amount: int)
signal boss_spawned(boss: Enemy)
signal enemy_died(at: Vector2, is_boss: bool)
signal doors_opened
signal bomb_exploded
signal consumable_taken

const HEAL_AMOUNT := 2
const BACK_ICON := "<"
const KEY_COLOR := Color("ece9e0")
const BOMB_COLOR := Color("ff9a3c")
const CHEST_COLOR := Color("a8692f")
const CHEST_LABEL := "Locked Chest"
const CHEST_PROMPT := "E: Use Slip"
const PENSION_COLOR := Color("ffd24a")
const ITEM_COLOR := Color("7dd3fc")
const HEAL_COLOR := Color("e4524f")
const COIN_SCATTER := 10.0

var _room: FloorRoom
var _map: FloorMap
var _floor_def: FloorDef
var _run: RunState
var _player: Player
var _rng: RandomNumberGenerator
var _progress: FloorProgress
var _alive := 0
var _finished := false
var _had_enemies := false
var _doors: Array[Door] = []
var _coins: Array[Pickup] = []
var _last_death_at := Vector2.ZERO


func setup(room: FloorRoom, map: FloorMap, floor_def: FloorDef, run: RunState, player: Player, rng: RandomNumberGenerator, progress: FloorProgress) -> void:
	_room = room
	_map = map
	_floor_def = floor_def
	_run = run
	_player = player
	_rng = rng
	_progress = progress


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(_room.layout.rows)
	add_child(backdrop)
	Lighting.add_room_mood(self)
	_create_doors()
	_create_blocks()
	_create_rewards()
	_spawn_enemies()
	if _alive == 0:
		_finish_room()


# Call each time the player arrives, because choosing a route can seal doors in rooms visited earlier.
func refresh_doors() -> void:
	for door in _doors:
		door.rearm()
		door.sealed = _progress.is_sealed(door.target_id())


# The room stays alive while the player is away, so remembered pickups keep their place.
# Effects and shots in flight don't belong in that memory.
func clear_passing_effects() -> void:
	for child in get_children():
		var is_flying_coin: bool = child is Pickup and child.is_flying()
		if child is Projectile or child is DeathBurst or child is Thermos or is_flying_coin:
			child.queue_free()


func place_bomb(at: Vector2) -> void:
	var thermos := Thermos.new()
	thermos.setup(_player)
	thermos.position = at
	thermos.exploded.connect(bomb_exploded.emit)
	add_child(thermos)


func _create_doors() -> void:
	var back_id := _progress.back_target(_room.id)
	if back_id != -1:
		_add_door(back_id, BACK_ICON, RoomLayout.ENTRY)
	if _room.is_detour():
		return
	for i in _room.exits.size():
		var target := _map.room(_room.exits[i])
		_add_door(target.id, RoomRules.door_icon(target.room_type), RoomLayout.EXIT_CELLS[i])
	if _room.side_id != -1:
		_add_door(_room.side_id, RoomRules.door_icon(RoomLayout.TYPE_SIDE), RoomLayout.SIDE_DOOR)
	if _room.treasure_id != -1:
		_add_treasure_door()


func _add_treasure_door() -> void:
	var door := _add_door(_room.treasure_id, RoomRules.door_icon(RoomLayout.TYPE_TREASURE), RoomLayout.TREASURE_DOOR)
	door.requires_key = true
	door.has_key = func(): return _run.keys > 0
	door.key_spent.connect(_on_treasure_door_unlocked)


func _on_treasure_door_unlocked() -> void:
	_run.use_key()
	doors_opened.emit()


func _add_door(target_id: int, icon: String, cell: Vector2i) -> Door:
	var door := Door.new()
	door.setup(target_id, icon, _player.feet())
	door.position = RoomBackdrop.cell_center(cell)
	door.entered.connect(func(id: int): door_entered.emit(id))
	add_child(door)
	_doors.append(door)
	return door


func _create_blocks() -> void:
	for cell in _room.layout.cells_of(RoomLayout.SYMBOL_BLOCK):
		var block := BreakableBlock.new()
		block.position = RoomBackdrop.cell_center(cell)
		block.broken.connect(_on_block_broken)
		add_child(block)


func _on_block_broken(at: Vector2) -> void:
	var drop := RoomRules.block_drop(_rng.randf())
	if drop == RoomRules.DROP_COIN:
		_drop_coin(at, _floor_def.treasure_pension)
		if _finished:
			_coins[-1].fly()
	else:
		_drop_consumable(at, drop)


func _spawn_enemies() -> void:
	for cell in _room.layout.cells_of("E"):
		var options := _floor_def.enemies
		var def: EnemyDef = options[_rng.randi_range(0, options.size() - 1)]
		_spawn_enemy(def, RoomBackdrop.cell_center(cell))
	for cell in _room.layout.cells_of("B"):
		var boss := _floor_def.mini_boss if _room.room_type == RoomLayout.TYPE_MINI_BOSS else _floor_def.floor_boss
		_spawn_enemy(boss, RoomBackdrop.cell_center(cell))


func _spawn_enemy(def: EnemyDef, at: Vector2) -> void:
	var enemy := Enemy.new()
	enemy.setup(def, _player, _run.stats.warning_fraction, _run.stats.reveals_enemy_health)
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.summon_requested.connect(_spawn_summon)
	_alive += 1
	_had_enemies = true
	add_child(enemy)
	if def.is_boss:
		boss_spawned.emit(enemy)


func _spawn_summon(def: EnemyDef, at: Vector2) -> void:
	var tile := RoomBackdrop.TILE
	var cell := Vector2i(floori(at.x / tile), floori(at.y / tile))
	var floor_cell := _room.layout.nearest_floor_cell(cell)
	if floor_cell != cell:
		at = RoomBackdrop.cell_center(floor_cell)
	_spawn_enemy(def, at)


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive -= 1
	DeathBurst.spawn(self, enemy.position, enemy.def.color, enemy.def.is_boss)
	enemy_died.emit(enemy.position, enemy.def.is_boss)
	_drop_coin(enemy.position, enemy.def.pension_drop)
	_last_death_at = enemy.position
	if _room.room_type == RoomLayout.TYPE_MINI_BOSS and enemy.def.is_boss:
		_drop_consumable(enemy.position, RoomRules.DROP_KEY)
	if enemy.def.is_boss:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.get_parent() == self:
				other.take_damage(INF, Vector2.ZERO)
	if _alive == 0:
		_finish_room()


func _drop_coin(at: Vector2, base_amount: int) -> void:
	var amount := _run.pension_amount(base_amount)
	var coin := _add_pickup(at + Vector2(_rng.randf_range(-COIN_SCATTER, COIN_SCATTER), _rng.randf_range(-COIN_SCATTER, COIN_SCATTER)), "+%d" % amount, PENSION_COLOR, func(): pension_earned.emit(amount))
	coin.flies = true
	_coins.append(coin)


func _drop_consumable(at: Vector2, kind: String) -> void:
	match kind:
		RoomRules.DROP_KEY:
			var slip := _add_pickup(at, RoomRules.KEY_NAME, KEY_COLOR, func(): _take_consumable(_run.add_key))
			slip.can_take = _run.can_add_key
		RoomRules.DROP_BOMB:
			var thermos := _add_pickup(at, RoomRules.BOMB_NAME, BOMB_COLOR, func(): _take_consumable(_run.add_bomb))
			thermos.can_take = _run.can_add_bomb


func _take_consumable(add: Callable) -> void:
	add.call()
	consumable_taken.emit()


func _add_pickup(at: Vector2, label: String, color: Color, on_take: Callable, needs_interact := false) -> Pickup:
	var pickup := Pickup.new()
	pickup.setup(label, color, _player.feet(), needs_interact)
	pickup.position = at
	pickup.collected.connect(on_take)
	add_child(pickup)
	return pickup


func _create_rewards() -> void:
	var cells := _room.layout.cells_of("I")
	if not cells.is_empty():
		_create_item_choice(cells)
	for cell in _room.layout.cells_of("H"):
		var heal := _add_pickup(RoomBackdrop.cell_center(cell), "Heal", HEAL_COLOR, func(): _run.health.heal(HEAL_AMOUNT))
		heal.can_take = func(): return _run.health.pills < _run.health.max_pills
	for cell in _room.layout.cells_of("T"):
		_create_treasure(cell)
	for cell in _room.layout.cells_of("C"):
		_create_chest(cell)


func _create_chest(cell: Vector2i) -> void:
	var chest := _add_pickup(RoomBackdrop.cell_center(cell), CHEST_LABEL, CHEST_COLOR, func(): _open_chest(cell), true)
	chest.prompt = CHEST_PROMPT
	chest.can_take = func(): return _run.keys > 0


func _open_chest(cell: Vector2i) -> void:
	if _run.use_key():
		_create_treasure(cell)


func _create_item_choice(cells: Array[Vector2i]) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, cells.size(), _rng)
	var choices: Array[Pickup] = []
	for i in picked.size():
		var item := picked[i]
		var choice := _add_item_pickup(RoomBackdrop.cell_center(cells[i]), item)
		choices.append(choice)
	for choice in choices:
		choice.collected.connect(func(): _remove_others(choices, choice))
	if picked.is_empty():
		_drop_coin(RoomBackdrop.cell_center(cells[0]), _floor_def.treasure_pension)


func _remove_others(choices: Array[Pickup], taken: Pickup) -> void:
	for choice in choices:
		if choice != taken and is_instance_valid(choice):
			choice.queue_free()


func _create_treasure(cell: Vector2i) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng)
	if picked.is_empty() or _rng.randf() < 0.5:
		_drop_coin(RoomBackdrop.cell_center(cell), _floor_def.treasure_pension)
		# A coin in a walled-off pocket must not fly out through the blocks for free.
		if not _room.layout.is_open_without_breaking(cell):
			var coin: Pickup = _coins.pop_back()
			coin.flies = false
		return
	_add_item_pickup(RoomBackdrop.cell_center(cell), picked[0])


# A left-behind item may be found again elsewhere before the player returns for it.
func _add_item_pickup(at: Vector2, item: ItemDef) -> Pickup:
	var pickup := _add_pickup(at, item.display_name, ITEM_COLOR, func(): _run.add_item(item), true)
	pickup.can_take = func(): return not _run.has_item(item.id)
	return pickup


func _finish_room() -> void:
	if _finished:
		return
	_finished = true
	for door in _doors:
		door.locked = false
	if _had_enemies:
		doors_opened.emit()
	for coin in _coins:
		if is_instance_valid(coin):
			coin.fly()
	if _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_SIDE]:
		pension_earned.emit(_run.pension_amount(_floor_def.clear_pension))
	if _had_enemies and _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_SIDE]:
		_drop_consumable(_last_death_at, RoomRules.clear_drop(_rng.randf()))
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS:
		floor_cleared.emit()
