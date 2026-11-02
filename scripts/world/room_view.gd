class_name RoomView
extends Node2D

signal door_entered(target_id: int)
signal floor_cleared
signal pension_earned(amount: int)
signal room_finished(room_id: int)

const HEAL_AMOUNT := 2
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
var _already_cleared := false
var _side_open := false
var _alive := 0
var _finished := false
var _doors: Array[Door] = []
var _coins: Array[Pickup] = []


func setup(room: FloorRoom, map: FloorMap, floor_def: FloorDef, run: RunState, player: Player, rng: RandomNumberGenerator, already_cleared: bool, side_open: bool) -> void:
	_room = room
	_map = map
	_floor_def = floor_def
	_run = run
	_player = player
	_rng = rng
	_already_cleared = already_cleared
	_side_open = side_open


func _ready() -> void:
	var backdrop := RoomBackdrop.new()
	backdrop.setup(_room.layout.rows)
	add_child(backdrop)
	Lighting.add_room_mood(self)
	_create_doors()
	if not _already_cleared:
		_create_rewards()
		_spawn_enemies()
	if _alive == 0:
		_finish_room()


func _create_doors() -> void:
	if _room.room_type == RoomLayout.TYPE_SIDE:
		_add_door(_room.parent_id, "<", RoomLayout.EXIT_A)
	else:
		var cells := [RoomLayout.EXIT_A, RoomLayout.EXIT_B]
		for i in _room.exits.size():
			var target := _map.room(_room.exits[i])
			_add_door(target.id, RoomRules.door_icon(target.room_type), cells[i])
		if _room.side_id != -1 and _side_open:
			_add_door(_room.side_id, RoomRules.door_icon(RoomLayout.TYPE_SIDE), RoomLayout.SIDE_DOOR)


func _add_door(target_id: int, icon: String, cell: Vector2i) -> void:
	var door := Door.new()
	door.setup(target_id, icon, _player)
	door.position = RoomBackdrop.cell_center(cell)
	door.entered.connect(func(id: int): door_entered.emit(id))
	add_child(door)
	_doors.append(door)


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
	enemy.setup(def, _player, _run.stats.warning_fraction)
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.summon_requested.connect(_spawn_summon)
	_alive += 1
	add_child(enemy)


func _spawn_summon(def: EnemyDef, at: Vector2) -> void:
	var tile := RoomBackdrop.TILE
	var cell := Vector2i(floori(at.x / tile), floori(at.y / tile))
	var floor_cell := _room.layout.nearest_floor_cell(cell)
	if floor_cell != cell:
		at = RoomBackdrop.cell_center(floor_cell)
	_spawn_enemy(def, at)


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive -= 1
	_drop_coin(enemy.position, enemy.def.pension_drop)
	if enemy.def.is_boss:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.get_parent() == self:
				other.take_damage(INF, Vector2.ZERO)
	if _alive == 0:
		_finish_room()


func _drop_coin(at: Vector2, base_amount: int) -> void:
	var amount := _run.pension_amount(base_amount)
	var coin := _add_pickup(at + Vector2(_rng.randf_range(-COIN_SCATTER, COIN_SCATTER), _rng.randf_range(-COIN_SCATTER, COIN_SCATTER)), "+%d" % amount, PENSION_COLOR, func(): pension_earned.emit(amount))
	_coins.append(coin)


func _add_pickup(at: Vector2, label: String, color: Color, on_take: Callable, needs_interact := false) -> Pickup:
	var pickup := Pickup.new()
	pickup.setup(label, color, _player, needs_interact)
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


func _create_item_choice(cells: Array[Vector2i]) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, cells.size(), _rng)
	var choices: Array[Pickup] = []
	for i in picked.size():
		var item := picked[i]
		var choice := _add_pickup(RoomBackdrop.cell_center(cells[i]), item.display_name, ITEM_COLOR, func(): _run.add_item(item), true)
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
		return
	var item := picked[0]
	_add_pickup(RoomBackdrop.cell_center(cell), item.display_name, ITEM_COLOR, func(): _run.add_item(item), true)


func _finish_room() -> void:
	if _finished:
		return
	_finished = true
	for door in _doors:
		door.locked = false
	for coin in _coins:
		if is_instance_valid(coin):
			coin.collect()
	if not _already_cleared and _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_SIDE]:
		pension_earned.emit(_run.pension_amount(_floor_def.clear_pension))
	room_finished.emit(_room.id)
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS:
		floor_cleared.emit()
