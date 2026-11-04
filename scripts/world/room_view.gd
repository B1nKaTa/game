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
signal notice(text: String)
signal hit_blocked
# How many items a fallen floor boss laid out to choose from.
signal boss_choice_dropped(count: int)
signal stairwell_entered
# Grandpa asked to play at one of the Arcade Room's tables.
signal arcade_game_wanted(table: ArcadeTable)

const HEAL_AMOUNT := 2
const SHOP_PROMPT := "Buy"
# The same merchant keeps every shop on every floor.
const MERCHANT: NpcDef = preload("res://data/npcs/shop_merchant.tres")
# The same Dealer keeps every Arcade Room.
const DEALER: NpcDef = preload("res://data/npcs/dealer.tres")
# An Arcade Room's neon: a dark carpet with a loud pattern, lit magenta from the middle and cyan from
# the walls.
const ARCADE_FLOOR_A := Color("2a1838")
const ARCADE_FLOOR_B := Color("23143a")
const ARCADE_FLOOR_C := Color("301a33")
const ARCADE_WALL := Color("1c1226")
const ARCADE_WALL_LINE := Color(1.0, 0.35, 0.85, 0.5)
const ARCADE_MOTIF := Color(1.0, 0.85, 0.2, 0.45)
const ARCADE_MAGENTA := Color(1.0, 0.3, 0.85)
const ARCADE_CYAN := Color(0.3, 0.95, 1.0)
const RECIPE_COLOR := Color("ffd65c")
const RECIPE_PROMPT := "Take recipe"
const FREE_COLOR := Color("67f0d0")
const KEY_COLOR := Color("ece9e0")
const BOMB_COLOR := Color("ff9a3c")
const MIMIC_SHOUT := "Surprise!"
const MIMIC_SHOUT_TIME := 1.2
# Where a Gilded Urn's two items wait, in cells from the urn: one each side, a row lower.
const URN_CHOICE_OFFSETS: Array[Vector2i] = [Vector2i(-2, 1), Vector2i(2, 1)]
const PENSION_COLOR := Color("ffd24a")
const ITEM_COLOR := Color("7dd3fc")
const HEAL_COLOR := Color("e4524f")
const COIN_SCATTER := 10.0
# A fallen floor boss offers this many free items, and taking one clears the rest away.
const BOSS_CHOICE_COUNT := 2
# Where those items wait, in cells from where the boss fell: one each side, a row lower.
const BOSS_CHOICE_OFFSETS: Array[Vector2i] = [Vector2i(-2, 1), Vector2i(2, 1)]
# The stairwell is a door that leads to no room of this floor, so it carries no room id.
const STAIRWELL_ID := -2
const STAIRWELL_ICON := "v"
const FLOOR_SIGN_COLOR := Color("ece9e0")

var _room: FloorRoom
var _map: FloorMap
var _floor_def: FloorDef
var _run: RunState
var _player: Player
var _rng: RandomNumberGenerator
var _progress: FloorProgress
var _bank: Node
var _reward_cells: Array[Vector2i] = []
var _alive := 0
var _finished := false
var _had_enemies := false
var _doors: Array[Door] = []
var _coins: Array[Pickup] = []
var _last_death_at := Vector2.ZERO
var _broken_cells := {}
# Where enemies can walk. A broken prop opens its cell.
var _walk_grid: WalkGrid
var _spawned := 0
# The cells a floor boss's item choice was laid on, so later things placed in the room keep clear.
var _choice_cells: Array[Vector2i] = []
var _choice_group: ChoiceGroup
# Each opened Gilded Urn's pair of items. Kept here, since a signal alone would not keep a group alive.
var _urn_groups: Array[ChoiceGroup] = []
var _tables: Array[ArcadeTable] = []
var _dealer: Npc


# The floor's palette, for anything a boss lays down in the room later, such as a wet patch.
func room_palette() -> RoomPalette:
	return _floor_def.room_palette() if _floor_def != null else null


# The floor's palette, turned to neon for an Arcade Room. A copy, so the floor's own stays as it was.
static func arcade_palette(base: RoomPalette) -> RoomPalette:
	var neon := base.duplicate() as RoomPalette
	neon.floor_a = ARCADE_FLOOR_A
	neon.floor_b = ARCADE_FLOOR_B
	neon.floor_c = ARCADE_FLOOR_C
	neon.wall = ARCADE_WALL
	neon.wall_line = ARCADE_WALL_LINE
	neon.floor_pattern = 1
	neon.carpet_motif = ARCADE_MOTIF
	neon.fill_light = ARCADE_MAGENTA
	neon.torch = ARCADE_CYAN
	neon.lantern = ARCADE_CYAN
	neon.lantern_light = ARCADE_CYAN
	neon.ambient = Color(0.5, 0.42, 0.6)
	neon.decor_density = 0.0
	neon.flicker = 0.0
	return neon


func setup(room: FloorRoom, map: FloorMap, floor_def: FloorDef, run: RunState, player: Player, rng: RandomNumberGenerator, progress: FloorProgress, bank: Node) -> void:
	_room = room
	_map = map
	_floor_def = floor_def
	_run = run
	_player = player
	_rng = rng
	_progress = progress
	_bank = bank


func _ready() -> void:
	_walk_grid = WalkGrid.from_layout(_room.layout)
	var backdrop := RoomBackdrop.new()
	var palette := _floor_def.room_palette()
	if _room.room_type == RoomLayout.TYPE_ARCADE:
		palette = arcade_palette(palette)
	backdrop.setup(_room.layout.rows, palette, _room.decor_seed)
	add_child(backdrop)
	Lighting.add_room_mood(self, _room.layout.size_in_cells(), palette)
	_create_decor(palette)
	if _room.room_type == RoomLayout.TYPE_LANDING:
		_add_floor_sign()
	_create_doors()
	_create_blocks()
	_create_props(palette)
	_create_rewards()
	_spawn_enemies()
	if _alive == 0:
		_finish_room()


# Call each time the player arrives, so the door he stands on waits until he steps away.
func refresh_doors() -> void:
	for door in _doors:
		door.rearm()
	# Each Arcade game plays once per visit, so coming back fills them again.
	for table in _tables:
		table.refill()


func arcade_tables() -> Array[ArcadeTable]:
	return _tables


# The room stays alive while the player is away, so remembered pickups keep their place.
# Effects and shots in flight don't belong in that memory. A Thermos that never went off goes
# back in the pocket, so stepping through a door doesn't cost one.
func clear_passing_effects() -> void:
	for child in get_children():
		var is_flying_coin: bool = child is Pickup and child.is_flying()
		if child is Thermos and child.is_fuse_burning():
			_run.add_bomb()
		if is_passing_effect(child) or is_flying_coin:
			child.queue_free()


# Anything an attack or a blast leaves in the room for a while. A new one must be added here, or it
# freezes mid-way in a stored room and goes on when Grandpa comes back.
static func is_passing_effect(child: Node) -> bool:
	return (child is Projectile or child is DeathBurst or child is Thermos or child is EnemyBlast
		or child is SummonMark or child is GroundStrike or child is LightsOut or child is SteamJet
		or child is Shockwave or child is FlameBurst or child is PipeRing or child is CollectionPlate
		or child is ProcessionLane or child is SafeSpotMark or child is PerfumeCloud or child is WetSplash
		or child is DroppedCoffin or child is PresentDrop or child is ClosingRing
		or child is TapeSpread)


func place_bomb(at: Vector2) -> void:
	var thermos := Thermos.new()
	thermos.setup(_player)
	thermos.level = _run.stats.thermos_level
	thermos.damage_mult = _run.stats.thermos_damage_mult
	thermos.radius = _run.stats.blast_radius
	thermos.position = at
	thermos.exploded.connect(bomb_exploded.emit)
	add_child(thermos)


func door_to(target_id: int) -> Door:
	for door in _doors:
		if door.target_id() == target_id:
			return door
	return null


# Keeps the door to that room shut for good, as a closed Waiting Room department's door is.
func chain_door(target_id: int) -> void:
	var door := door_to(target_id)
	if door != null:
		door.chained = true


func _create_doors() -> void:
	for side in RoomLayout.SIDES:
		if not _room.doors.has(side):
			continue
		var target := _map.room(_room.doors[side])
		match target.room_type:
			RoomLayout.TYPE_SECRET:
				_add_secret_wall(side)
			RoomLayout.TYPE_VAULT:
				_add_vault_stone(side)
			RoomLayout.TYPE_TREASURE:
				_add_treasure_door(target.id, side)
			_:
				_add_door(target.id, RoomRules.door_icon(target.room_type), side)


# The crack sits in the wall on the side leading to the secret room.
func _add_secret_wall(side: Vector2i) -> void:
	var wall := SecretWall.new()
	wall.position = RoomBackdrop.cell_center(_room.layout.wall_cell(side))
	wall.broken.connect(_on_secret_wall_broken.bind(side))
	add_child(wall)


func _on_secret_wall_broken(_at: Vector2, side: Vector2i) -> void:
	var door := _add_door(_room.doors[side], RoomRules.door_icon(RoomLayout.TYPE_SECRET), side)
	door.locked = not _finished
	doors_opened.emit()
	notice.emit("You found a secret room!")


# A vault door hides behind a reinforced stone in the same wall cell a secret crack uses.
func _add_vault_stone(side: Vector2i) -> void:
	var stone := ReinforcedRock.new()
	stone.palette = _floor_def.room_palette()
	stone.needed_level = _floor_def.vault_stone_level
	stone.position = RoomBackdrop.cell_center(_room.layout.wall_cell(side))
	stone.broken.connect(_on_vault_stone_broken.bind(side))
	stone.resisted.connect(_on_vault_stone_resisted)
	add_child(stone)


func _on_vault_stone_broken(_at: Vector2, side: Vector2i) -> void:
	var door := _add_door(_room.doors[side], RoomRules.door_icon(RoomLayout.TYPE_VAULT), side)
	door.locked = not _finished
	doors_opened.emit()
	notice.emit("The reinforced stone crumbles. A vault!")


func _on_vault_stone_resisted() -> void:
	notice.emit("The stone doesn't even crack. It wants a much hotter Thermos.")


func _add_treasure_door(target_id: int, side: Vector2i) -> void:
	var door := _add_door(target_id, RoomRules.door_icon(RoomLayout.TYPE_TREASURE), side)
	door.requires_key = true
	door.has_key = func(): return _run.keys > 0
	door.key_spent.connect(_on_treasure_door_unlocked)


func _on_treasure_door_unlocked() -> void:
	_run.use_key()
	doors_opened.emit()


# The way down from a fallen floor boss's room, on open floor near the middle and clear of the
# boss's items. It waits until he has stepped off it, as any door he arrives on does.
func add_stairwell() -> void:
	if stairwell() != null:
		return
	var wanted: Array[Vector2i] = [_room.layout.size_in_cells() / 2]
	var spots := _room.layout.open_spots_near(wanted, _choice_cells)
	var cell: Vector2i = spots[0] if not spots.is_empty() else _room.layout.nearest_floor_cell(wanted[0])
	var door := Door.new()
	door.setup(STAIRWELL_ID, STAIRWELL_ICON, _player.feet())
	door.locked = false
	door.position = RoomBackdrop.cell_center(cell)
	door.entered.connect(func(_id: int): stairwell_entered.emit())
	add_child(door)
	door.rearm()
	_doors.append(door)
	notice.emit("A stairwell leads down.")


func stairwell() -> Door:
	return door_to(STAIRWELL_ID)


# The landing names the floor below on a plain sign by the far wall.
func _add_floor_sign() -> void:
	var sign_label := Label.new()
	sign_label.text = _floor_def.display_name
	sign_label.add_theme_font_size_override("font_size", 12)
	sign_label.add_theme_color_override("font_color", FLOOR_SIGN_COLOR)
	sign_label.add_theme_constant_override("outline_size", 4)
	sign_label.add_theme_color_override("font_outline_color", Color.BLACK)
	sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var width := float(_room.layout.size_in_cells().x * RoomBackdrop.TILE)
	sign_label.size = Vector2(width, 16)
	sign_label.position = Vector2(0, RoomBackdrop.TILE * 2.5)
	sign_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign_label.z_index = 5
	add_child(sign_label)


func _add_door(target_id: int, icon: String, side: Vector2i) -> Door:
	var door := Door.new()
	door.setup(target_id, icon, _player.feet(), side)
	door.position = RoomBackdrop.cell_center(_room.layout.door_cell(side))
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


# Rocks, barrels, holes and piles of bones. Anything that breaks leaves its cell free for good,
# because a broken thing is freed with the room kept alive, so it stays broken on return.
func _create_props(palette: RoomPalette) -> void:
	var layout := _room.layout
	for cell in layout.cells_of(RoomLayout.SYMBOL_ROCK):
		var rock := RockBlock.new()
		rock.palette = palette
		rock.hides_coin = RoomRules.rock_hides_coin(_prop_coin_roll())
		_place_prop(rock, cell)
		rock.broken.connect(_on_rock_broken.bind(rock.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_GRAVESTONE):
		var stone := Gravestone.new()
		stone.palette = palette
		stone.hides_coin = RoomRules.gravestone_hides_coin(_prop_coin_roll())
		_place_prop(stone, cell)
		stone.broken.connect(_on_rock_broken.bind(stone.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_DEAD_TREE):
		var tree := DeadTree.new()
		tree.palette = palette
		_place_prop(tree, cell)
		tree.broken.connect(_on_rock_broken.bind(false, cell))
	for symbol: String in [RoomLayout.SYMBOL_ARMCHAIR, RoomLayout.SYMBOL_BED, RoomLayout.SYMBOL_PEW, RoomLayout.SYMBOL_PLANTER, RoomLayout.SYMBOL_FOUNTAIN]:
		for cell in layout.cells_of(symbol):
			var furniture: RockBlock
			match symbol:
				RoomLayout.SYMBOL_ARMCHAIR:
					furniture = Armchair.new()
				RoomLayout.SYMBOL_PEW:
					furniture = ChapelPew.new()
				RoomLayout.SYMBOL_PLANTER:
					furniture = MallPlanter.new()
				RoomLayout.SYMBOL_FOUNTAIN:
					furniture = MallFountain.new()
				_:
					furniture = CareBed.new()
			furniture.palette = palette
			furniture.hides_coin = RoomRules.furniture_hides_coin(_prop_coin_roll())
			_place_prop(furniture, cell)
			furniture.broken.connect(_on_rock_broken.bind(furniture.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_COAL_HEAP):
		var heap := CoalHeap.new()
		heap.palette = palette
		heap.hides_coin = RoomRules.coal_heap_hides_coin(_prop_coin_roll())
		_place_prop(heap, cell)
		heap.broken.connect(_on_rock_broken.bind(heap.hides_coin, cell))
	for symbol: String in [RoomLayout.SYMBOL_BARREL, RoomLayout.SYMBOL_WHEELCHAIR, RoomLayout.SYMBOL_TROLLEY, RoomLayout.SYMBOL_COAL_SACK, RoomLayout.SYMBOL_CRATE]:
		for cell in layout.cells_of(symbol):
			var barrel: Barrel = Barrel.new()
			if symbol == RoomLayout.SYMBOL_WHEELCHAIR:
				barrel = Wheelchair.new()
			elif symbol == RoomLayout.SYMBOL_TROLLEY:
				barrel = FoodTrolley.new()
			elif symbol == RoomLayout.SYMBOL_COAL_SACK:
				barrel = CoalSack.new()
			elif symbol == RoomLayout.SYMBOL_CRATE:
				barrel = FurnaceCrate.new()
			barrel.palette = palette
			_place_prop(barrel, cell)
			barrel.broken.connect(_on_barrel_broken.bind(cell))
	for symbol: String in [RoomLayout.SYMBOL_HYMN_CART, RoomLayout.SYMBOL_CART, RoomLayout.SYMBOL_GUMBALL]:
		for cell in layout.cells_of(symbol):
			var cart: Barrel
			match symbol:
				RoomLayout.SYMBOL_CART:
					cart = ShoppingCart.new()
				RoomLayout.SYMBOL_GUMBALL:
					cart = GumballMachine.new()
				_:
					cart = HymnCart.new()
			cart.palette = palette
			_place_prop(cart, cell)
			cart.broken.connect(_on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_VASE):
		var vase := FlowerVase.new()
		vase.palette = palette
		_place_prop(vase, cell)
		vase.broken.connect(_on_vase_broken.bind(cell))
	for symbol: String in [RoomLayout.SYMBOL_WREATH, RoomLayout.SYMBOL_CANDLE, RoomLayout.SYMBOL_SALE_SIGN]:
		for cell in layout.cells_of(symbol):
			var stand: BreakableBlock
			match symbol:
				RoomLayout.SYMBOL_WREATH:
					stand = WreathStand.new()
				RoomLayout.SYMBOL_SALE_SIGN:
					stand = SaleSign.new()
				_:
					stand = CandleStand.new()
			stand.palette = palette
			_place_prop(stand, cell)
			stand.broken.connect(_on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_PIPE_VALVE):
		var stub := PipeValve.new()
		stub.palette = palette
		_place_prop(stub, cell)
		stub.broken.connect(_on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_PILE):
		var pile := BonePile.new()
		pile.palette = palette
		_place_prop(pile, cell)
		pile.broken.connect(_on_pile_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_HOLE):
		var hole := Hole.new()
		hole.palette = palette
		hole.position = RoomBackdrop.cell_center(cell)
		add_child(hole)
	for cell in layout.cells_of(RoomLayout.SYMBOL_WET):
		var wet := WetFloor.new()
		wet.palette = palette
		wet.position = RoomBackdrop.cell_center(cell)
		add_child(wet)
	for cell in WetFloor.sign_cells(layout):
		var caution := WetSign.new()
		caution.palette = palette
		_place_prop(caution, cell)
	for cell in layout.cells_of(RoomLayout.SYMBOL_VENT):
		var vent := FloorVent.new()
		vent.setup(cell)
		vent.position = RoomBackdrop.cell_center(cell)
		add_child(vent)
	for cell in layout.cells_of(RoomLayout.SYMBOL_ORGAN_PIPE):
		var pipe := OrganPipe.new()
		pipe.setup(cell, layout.inward_of(cell))
		pipe.position = RoomBackdrop.cell_center(cell)
		add_child(pipe)
	for symbol in RoomLayout.STRIP_SYMBOLS:
		for cell in layout.cells_of(symbol):
			var strip := ConveyorStrip.new()
			strip.setup(Vector2(RoomLayout.strip_direction(symbol)), layout.strips_reverse)
			strip.position = RoomBackdrop.cell_center(cell)
			add_child(strip)
	_create_office_props(layout, palette)


func _place_prop(prop: BreakableBlock, cell: Vector2i) -> void:
	prop.position = RoomBackdrop.cell_center(cell)
	add_child(prop)


func _create_decor(palette: RoomPalette) -> void:
	var items := RoomDecor.plan(_room.layout, palette, _room.decor_seed)
	var layer := DecorLayer.new()
	layer.setup(items, palette)
	add_child(layer)
	for item in items:
		var at: Vector2 = RoomBackdrop.cell_center(item["cell"]) + item["offset"]
		if item["kind"] == RoomDecor.GRASS:
			var tuft := GrassTuft.new()
			tuft.palette = palette
			tuft.variant = item["variant"]
			tuft.position = at
			add_child(tuft)
		elif RoomDecor.is_light(item["kind"]):
			Lighting.add_decor_light(self, item["kind"], at, palette)


func _on_block_broken(at: Vector2) -> void:
	_mark_broken(_cell_of(at))
	var drop := RoomRules.block_drop(_rng.randf())
	if drop == RoomRules.DROP_NONE and _bonus_coin(RoomRules.BLOCK_COIN_CHANCE):
		drop = RoomRules.DROP_COIN
	if drop == RoomRules.DROP_COIN:
		_drop_coin(at, _floor_def.prop_pension)
	else:
		_drop_consumable(at, drop)


func _on_rock_broken(at: Vector2, hides_coin: bool, cell: Vector2i) -> void:
	_mark_broken(cell)
	if hides_coin:
		_drop_coin(at, _floor_def.prop_pension)


func _on_barrel_broken(at: Vector2, cell: Vector2i) -> void:
	_mark_broken(cell)
	var drop := RoomRules.barrel_drop(_rng.randf())
	if drop == RoomRules.DROP_NONE and _bonus_coin(RoomRules.BARREL_COIN_CHANCE):
		drop = RoomRules.DROP_COIN
	if drop == RoomRules.DROP_COIN:
		_drop_coin(at, _floor_def.prop_pension)
	else:
		_drop_consumable(at, drop)


# A breakable's coin roll, which the bent shovel memento makes likelier: a roll under a coin chance
# hides a coin, so dividing the roll multiplies every such chance.
func _prop_coin_roll() -> float:
	return _rng.randf() / _run.prop_coin_mult()


# Blocks and barrels roll coins, keys and Thermoses on one roll, so the bent shovel adds its share of
# coins only where they would have dropped nothing, and leaves the other drops as they were.
func _bonus_coin(coin_chance: float) -> bool:
	var mult := _run.prop_coin_mult()
	return mult > 1.0 and _rng.randf() < coin_chance * (mult - 1.0)


func _mark_broken(cell: Vector2i) -> void:
	_broken_cells[cell] = true
	if _walk_grid != null:
		_walk_grid.open_cell(cell)


func _on_vase_broken(_at: Vector2, cell: Vector2i) -> void:
	_mark_broken(cell)


func _on_pile_broken(at: Vector2, cell: Vector2i) -> void:
	_mark_broken(cell)
	if RoomRules.pile_drops_coin(_prop_coin_roll()):
		_drop_coin(at, _floor_def.prop_pension)


func _cell_of(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / RoomBackdrop.TILE), floori(at.y / RoomBackdrop.TILE))


# Whatever is dropped lands on open floor. A ghost can die over a rock or a hole, and a
# solid cell that has been broken is open again.
func clear_spot(at: Vector2) -> Vector2:
	var cell := _cell_of(at)
	if not _room.layout.is_solid_at(cell) or _broken_cells.has(cell):
		return at
	return RoomBackdrop.cell_center(_room.layout.nearest_floor_cell(cell))


func _spawn_enemies() -> void:
	for entry in EnemyPlan.plan(_room.layout, _floor_def, _room.extra_enemies, _rng):
		var enemy := _spawn_enemy(entry["def"], RoomBackdrop.cell_center(entry["cell"]))
		enemy.is_group_follower = not entry["leader"]
		enemy.wait_for_room_start()
	for cell in _room.layout.cells_of("B"):
		var boss := _floor_def.mini_boss if _room.room_type == RoomLayout.TYPE_MINI_BOSS else _floor_def.floor_boss
		_spawn_enemy(boss, RoomBackdrop.cell_center(cell))


func _spawn_enemy(def: EnemyDef, at: Vector2, summoned := false) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(def, _player, _run.stats.warning_fraction, _run.stats.reveals_enemy_health)
	# A cursed run's tougher, better-paying enemies come on top of the floor's own numbers.
	enemy.apply_floor(_floor_def.health_mult * _run.enemy_health_mult(), _floor_def.pension_mult * _run.enemy_pension_mult())
	enemy.is_summon = summoned
	enemy.room_cells = _room.layout.size_in_cells()
	enemy.walk_grid = _walk_grid
	enemy.position = at
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.summon_requested.connect(_spawn_summon)
	enemy.hit_blocked.connect(hit_blocked.emit)
	enemy.blasted.connect(bomb_exploded.emit)
	enemy.summon_spot = summon_spot
	enemy.open_ground = is_open_ground
	enemy.spawn_index = _spawned
	_spawned += 1
	_alive += 1
	_had_enemies = true
	add_child(enemy)
	if def.is_boss:
		boss_spawned.emit(enemy)
	return enemy


# An enemy added after the room has finished, so its doors stay open. Only the Training Yard calls it,
# for its dummy, which keeps the Waiting Room's FloorDef free of enemies.
func spawn_fixture(def: EnemyDef, cell: Vector2i) -> Enemy:
	return _spawn_enemy(def, RoomBackdrop.cell_center(cell))


# Summons land on open floor, wherever the boss wanted them.
func summon_spot(at: Vector2) -> Vector2:
	return RoomBackdrop.cell_center(_room.layout.nearest_floor_cell(_cell_of(at)))


# Ground attacks need ground, so walls and holes take no mark.
func is_open_ground(at: Vector2) -> bool:
	return not RoomLayout.WALLS.contains(_room.layout.symbol_at(_cell_of(at)))


func _spawn_summon(def: EnemyDef, at: Vector2) -> void:
	_spawn_enemy(def, summon_spot(at), true)


func _on_enemy_defeated(enemy: Enemy) -> void:
	_alive -= 1
	DeathBurst.spawn(self, enemy.position, enemy.def.color, enemy.def.is_boss)
	enemy_died.emit(enemy.position, enemy.def.is_boss)
	var spot := clear_spot(enemy.position)
	if enemy.coin_value() > 0:
		_drop_coin(spot, enemy.coin_value(), RunState.PENSION_REWARD if enemy.def.is_boss else RunState.PENSION_ENEMY)
	_last_death_at = spot
	if enemy.def.drops_key and not enemy.is_summon:
		_drop_consumable(spot, RoomRules.DROP_KEY)
	if _room.room_type == RoomLayout.TYPE_MINI_BOSS and enemy.def.is_boss:
		_drop_consumable(spot, RoomRules.DROP_KEY)
		if _rng.randf() < RoomRules.MINI_BOSS_RECIPE_CHANCE:
			_drop_recipe(spot + Vector2(-RoomBackdrop.TILE, RoomBackdrop.TILE))
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS and enemy.def.is_boss and not enemy.is_summon:
		_drop_boss_choice(spot)
	if enemy.def.is_boss:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.get_parent() == self:
				other.dismiss()
	if _alive == 0:
		_finish_room()


# source is a RunState.PENSION_* id, or "" for Pension that only the general rate touches.
func _drop_coin(at: Vector2, base_amount: int, source := "") -> void:
	var amount := _run.pension_amount(base_amount, source)
	var coin := _add_pickup(at + Vector2(_rng.randf_range(-COIN_SCATTER, COIN_SCATTER), _rng.randf_range(-COIN_SCATTER, COIN_SCATTER)), "+%d" % amount, PENSION_COLOR, func(): pension_earned.emit(amount))
	# A coin lying in a pocket only a bomb opens would fly out through the stones.
	if not _room.layout.coin_can_fly_from(_cell_of(at)):
		return
	coin.flies = true
	_coins.append(coin)
	if _finished:
		coin.fly()


func _drop_consumable(at: Vector2, kind: String) -> void:
	match kind:
		RoomRules.DROP_KEY:
			var slip := _add_pickup(at, RoomRules.KEY_NAME, KEY_COLOR, func(): _take_consumable(_run.add_key))
			slip.can_take = _run.can_add_key
		RoomRules.DROP_BOMB:
			var thermos := _add_pickup(at, RoomRules.BOMB_NAME, BOMB_COLOR, func(): _take_consumable(_run.add_bomb))
			thermos.can_take = _run.can_add_bomb
		RoomRules.DROP_POTION:
			# It fills the potion slot, and waits on the floor while the slot is full.
			var small := Content.potion(RoomRules.SMALL_POTION_ID)
			var potion := _add_pickup(at, RoomRules.POTION_NAME, HEAL_COLOR, func(): _take_consumable(func(): _run.give_potion(small)))
			potion.can_take = _run.can_take_potion


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
	# The empty sack memento lays one more item out in a treasure room, on open floor near the others.
	if _room.room_type == RoomLayout.TYPE_TREASURE and not cells.is_empty() and _run.has_perk(Mementos.TREASURE_CHOICE_PERK):
		var extra := _room.layout.open_spots_near(cells, cells)
		for i in mini(Mementos.TREASURE_EXTRA, extra.size()):
			cells.append(extra[i])
	if not cells.is_empty():
		_create_item_choice(cells)
	for cell in _room.layout.cells_of("H"):
		var heal := _add_pickup(RoomBackdrop.cell_center(cell), "Heal", HEAL_COLOR, func(): _run.health.heal(HEAL_AMOUNT))
		heal.can_take = func(): return _run.health.pills < _run.health.max_pills
	for cell in _room.layout.cells_of("T"):
		_create_treasure(cell)
		_pay_chest_condolences()
	for cell in _room.layout.cells_of("C"):
		_create_chest(cell, ChestRules.roll(_floor_def.chest_odds(), _rng.randf()))
	if _room.room_type == RoomLayout.TYPE_SHOP:
		_create_shop()
	if _room.room_type == RoomLayout.TYPE_VAULT:
		_create_vault_extras()
	if _room.room_type == RoomLayout.TYPE_ARCADE:
		_create_arcade()


# The slot machine first, then blackjack, then draw poker, with the Arcade's own Dealer.
func _create_arcade() -> void:
	add_arcade_tables(ArcadeTable.GAMES, DEALER)


# The Dealer stands by his tables as the Shopkeeper does by his wares, and each game cell gets a table,
# taking the games in turn. The Waiting Room's Back Room calls it too, with its own games and Dealer.
func add_arcade_tables(games: Array[String], dealer_def: NpcDef) -> void:
	var cell := _room.layout.merchant_cell()
	if cell != Vector2i(-1, -1) and dealer_def != null:
		var dealer := Npc.new()
		dealer.setup(dealer_def, _player, _run_number())
		dealer.position = RoomBackdrop.cell_center(cell)
		add_child(dealer)
		_dealer = dealer
	if games.is_empty():
		return
	var cells := _room.layout.cells_of(RoomLayout.SYMBOL_GAME)
	for i in cells.size():
		var table := ArcadeTable.new()
		table.setup(games[i % games.size()], _player.feet())
		table.position = RoomBackdrop.cell_center(cells[i])
		table.play_wanted.connect(_on_table_wanted.bind(table))
		add_child(table)
		_tables.append(table)


func _on_table_wanted(_game: String, table: ArcadeTable) -> void:
	arcade_game_wanted.emit(table)


# The run count, which picks the line people here open with.
func _run_number() -> int:
	return int(_bank.data.run_count) if _bank != null and _bank.data != null else 0


# The card-table overlay has closed after a game: the Dealer has a word about how the last one went,
# and once every table is played out for this visit, he says so instead of commiserating.
func arcade_closed(last_result: String) -> void:
	if not is_instance_valid(_dealer) or last_result.is_empty():
		return
	var key := last_result
	if key != CardTablePanel.RESULT_WIN and not _tables.is_empty():
		var played_out := true
		for table in _tables:
			if table.plays_left > 0:
				played_out = false
		if played_out:
			key = CardTablePanel.RESULT_OUT
	_dealer.say_moment(key)


# --- what the card-table overlay asks of the room ---

func arcade_balance() -> int:
	return _bank.data.pension


# Bets come out of his Pension, and one he cannot cover is refused.
func arcade_bet(amount: int) -> bool:
	return amount > 0 and _bank.spend(amount)


# Winnings go straight into his Pension, exactly as the game's rules pay them.
func arcade_pay(amount: int) -> void:
	if amount > 0:
		_bank.add_pension(amount)


# Three skulls: a free item from the run's usual pool, lying by the table. With nothing left to offer,
# it pays what a shop would ask for one instead.
func arcade_item_win(table: ArcadeTable) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng)
	if picked.is_empty():
		arcade_pay(ArcadeOdds.ITEM_VALUE)
		return
	var table_cell := _cell_of(table.position)
	var wanted: Array[Vector2i] = [table_cell + Vector2i(0, 2)]
	var taken: Array[Vector2i] = _room.layout.cells_of(RoomLayout.SYMBOL_GAME)
	var dealer := _room.layout.merchant_cell()
	if dealer != Vector2i(-1, -1):
		taken.append(dealer)
	var spots := _room.layout.open_spots_near(wanted, taken)
	var cell: Vector2i = spots[0] if not spots.is_empty() else _room.layout.nearest_floor_cell(wanted[0])
	_run.promise(picked[0])
	_add_free_item(RoomBackdrop.cell_center(cell), picked[0])


# Three pills: every pill back.
func arcade_full_heal() -> void:
	_run.health.heal(_run.health.max_pills)


# A vault is the richest room: the usual choice of items and treasures, plus a potion, a Thermos
# and a Slip lying out in the open. It holds no Pension beyond a treasure's, so income stays put.
func _create_vault_extras() -> void:
	var kinds := [RoomRules.DROP_POTION, RoomRules.DROP_BOMB, RoomRules.DROP_KEY]
	var cells := _room.layout.vault_extra_cells(kinds.size())
	for i in cells.size():
		_drop_consumable(RoomBackdrop.cell_center(cells[i]), kinds[i])


func _create_shop() -> void:
	var stock := ShopRules.stock(Content.items(), _run, _rng)
	var cells := _room.layout.cells_of("S")
	for i in stock.size():
		_add_shop_entry(RoomBackdrop.cell_center(cells[i]), stock[i])
	# The merchant stands first, so the plan's reward spots keep clear of him.
	var merchant_at := _add_merchant()
	_reward_cells = _room.layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size(), merchant_at)
	var station := RetirementStation.new()
	station.setup(_bank, _player.feet())
	station.position = RoomBackdrop.cell_center(_room.layout.cells_of(RoomLayout.SYMBOL_PLAN)[0])
	station.deposit_wanted.connect(_on_deposit_wanted)
	station.blasted.connect(_on_plan_blasted)
	add_child(station)


# He stands near his wares, which stay on the floor, and talks when Grandpa asks. Returns his cell.
func _add_merchant() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell := _room.layout.merchant_cell()
	if cell == Vector2i(-1, -1):
		return cells
	var merchant := Npc.new()
	merchant.setup(MERCHANT, _player, _run_number())
	merchant.position = RoomBackdrop.cell_center(cell)
	add_child(merchant)
	cells.append(cell)
	return cells


func _add_shop_entry(at: Vector2, entry: Dictionary) -> void:
	var price: int = entry["price"]
	var label := ""
	var color := ITEM_COLOR
	var give := Callable()
	var allowed := Callable()
	match entry["kind"]:
		ShopRules.KIND_ITEM:
			var item: ItemDef = entry["item"]
			label = item.display_name
			give = func(): _run.add_item(item)
			allowed = func(): return not _run.has_item(item.id)
		ShopRules.KIND_HEAL:
			label = "Heal"
			color = HEAL_COLOR
			give = func(): _run.health.heal(HEAL_AMOUNT)
			allowed = func(): return _run.health.pills < _run.health.max_pills
		ShopRules.KIND_KEY:
			label = RoomRules.KEY_NAME
			color = KEY_COLOR
			give = func(): _take_consumable(_run.add_key)
			allowed = _run.can_add_key
		ShopRules.KIND_BOMB:
			label = RoomRules.BOMB_NAME
			color = BOMB_COLOR
			give = func(): _take_consumable(_run.add_bomb)
			allowed = _run.can_add_bomb
	var pickup := _add_pickup(at, "%s: %d" % [label, price], color, func(): _buy(price, give), true)
	pickup.prompt = SHOP_PROMPT
	pickup.can_take = func(): return _bank.data.pension >= price and allowed.call()


func _buy(price: int, give: Callable) -> void:
	if _bank.spend(price):
		give.call()


func _on_deposit_wanted(amount: int) -> void:
	var reached: int = _bank.retirement_deposit(amount)
	for i in reached:
		_award_plan_reward()


# Rewards last for this run only. Each tier's item lies on its own spot beside the station.
func _award_plan_reward() -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng)
	if picked.is_empty():
		_run.add_bomb()
		notice.emit("Retirement Plan bonus: a free %s" % RoomRules.BOMB_NAME)
		return
	var item := picked[0]
	_run.promise(item)
	_add_free_item(RoomBackdrop.cell_center(_next_reward_cell()), item)
	notice.emit("Retirement Plan bonus: a free item, beside the plan")


# Every tier has a spot. Should a spot ever be missing, the nearest floor below the station does.
func _next_reward_cell() -> Vector2i:
	if not _reward_cells.is_empty():
		return _reward_cells.pop_front()
	return _room.layout.nearest_floor_cell(_room.layout.cells_of(RoomLayout.SYMBOL_PLAN)[0] + Vector2i.DOWN)


func _on_plan_blasted() -> void:
	var data: ProgressData = _bank.data
	if data.can_release_retirement():
		var amount: int = _bank.release_retirement()
		consumable_taken.emit()
		notice.emit("Cashed out %d Pension from your Retirement Plan" % amount)
	elif data.retirement_balance > 0:
		notice.emit("Your Retirement Plan is locked until your next run")


func _add_free_item(at: Vector2, item: ItemDef) -> Pickup:
	var pickup := _add_item_pickup(at, item)
	pickup.set_label("Free: %s" % item.display_name, FREE_COLOR)
	return pickup


# A floor boss leaves two free items from the run's usual pool, one each side of where it fell.
# Taking one clears the other away. A pool down to one item shows one, and an empty pool none.
func _drop_boss_choice(at: Vector2) -> void:
	if not _choice_cells.is_empty():
		return
	var picked := RoomRules.pick_items(Content.items(), _run, BOSS_CHOICE_COUNT, _rng)
	var fell_at := _cell_of(at)
	var wanted: Array[Vector2i] = []
	for i in picked.size():
		wanted.append(fell_at + BOSS_CHOICE_OFFSETS[i])
	_choice_cells = _room.layout.open_spots_near(wanted)
	_choice_group = ChoiceGroup.new()
	for i in _choice_cells.size():
		var item := picked[i]
		_run.promise(item)
		var pickup := _add_free_item(RoomBackdrop.cell_center(_choice_cells[i]), item)
		_choice_group.add(pickup)
		pickup.collected.connect(_choice_group.take.bind(pickup))
	boss_choice_dropped.emit(_choice_cells.size())


# One chest of the given kind on a C cell. ChestRules holds what each kind costs and pays.
func _create_chest(cell: Vector2i, kind: String) -> Chest:
	var chest := Chest.new()
	chest.kind = kind
	chest.setup(ChestRules.display_name(kind), PENSION_COLOR, _player.feet(), kind != ChestRules.SAFE)
	chest.prompt = ChestRules.prompt_for(kind)
	chest.position = RoomBackdrop.cell_center(cell)
	match kind:
		ChestRules.LUNCHBOX:
			chest.collected.connect(_open_lunchbox.bind(cell))
		ChestRules.URN:
			chest.can_take = func(): return ChestRules.can_open(kind, _run.keys)
			chest.collected.connect(_open_urn.bind(cell))
		ChestRules.SAFE:
			chest.blasted_open.connect(_open_safe)
		ChestRules.MIMIC:
			# It shows a Locked Chest's prompt rules, so nothing gives it away but its breathing.
			chest.can_take = func(): return ChestRules.can_open(ChestRules.LOCKED, _run.keys)
			chest.woke.connect(_wake_mimic)
		_:
			chest.can_take = func(): return ChestRules.can_open(ChestRules.LOCKED, _run.keys)
			chest.collected.connect(_open_locked.bind(cell))
	add_child(chest)
	return chest


func _spend_slips(count: int) -> bool:
	if _run.keys < count:
		return false
	for i in count:
		_run.use_key()
	return true


# Free to open: a little Pension, and now and then a small potion or a Thermos.
func _open_lunchbox(cell: Vector2i) -> void:
	var at := RoomBackdrop.cell_center(cell)
	_drop_coin(at, ChestRules.lunchbox_pension(_floor_def.treasure_pension), RunState.PENSION_REWARD)
	var extra := ChestRules.lunchbox_extra(_rng.randf())
	if extra != RoomRules.DROP_NONE:
		_drop_consumable(at, extra)
	notice.emit("Someone's lunch. Still warm, somehow.")
	_pay_chest_condolences()


func _open_locked(cell: Vector2i) -> void:
	if _spend_slips(ChestRules.slips_needed(ChestRules.LOCKED)):
		_create_treasure(cell)
		_pay_chest_condolences()


# Two Slips buy a pick of two items from the run's usual pool. Taking one clears the other away.
func _open_urn(cell: Vector2i) -> void:
	if not _spend_slips(ChestRules.slips_needed(ChestRules.URN)):
		return
	var picked := RoomRules.pick_items(Content.items(), _run, ChestRules.URN_CHOICES, _rng)
	var wanted: Array[Vector2i] = []
	for i in picked.size():
		wanted.append(cell + URN_CHOICE_OFFSETS[i])
	var taken: Array[Vector2i] = [cell]
	var spots := _room.layout.open_spots_near(wanted, taken)
	if spots.is_empty():
		_drop_coin(RoomBackdrop.cell_center(cell), ChestRules.urn_fallback_pension(_floor_def.treasure_pension), RunState.PENSION_REWARD)
		_pay_chest_condolences()
		return
	var group := ChoiceGroup.new()
	_urn_groups.append(group)
	for i in spots.size():
		var item := picked[i]
		_run.promise(item)
		var pickup := _add_item_pickup(RoomBackdrop.cell_center(spots[i]), item)
		group.add(pickup)
		pickup.collected.connect(group.take.bind(pickup))
	notice.emit("The urn holds two things. Take one.")
	_pay_chest_condolences()


# Only the player's Thermos gets here. The box bursts into a pile of coins.
func _open_safe(at: Vector2) -> void:
	for amount in ChestRules.coin_split(ChestRules.safe_pension(_floor_def.treasure_pension), ChestRules.SAFE_COINS):
		_drop_coin(at, amount, RunState.PENSION_REWARD)
	notice.emit("The safe bursts open!")
	_pay_chest_condolences()


# A chest opening now and then pays a few Condolences on top of what it holds.
func _pay_chest_condolences() -> void:
	var condolences := RoomRules.chest_condolences(_rng.randf())
	if condolences > 0:
		_bank.add_condolences(condolences)
		notice.emit("+%d Condolences" % condolences)


# Touched, the chest was never a chest. It waits a moment, as any enemy does when a room starts,
# and its first lunge always shows its warning in full. It pays well and drops a Slip.
func _wake_mimic(at: Vector2) -> void:
	# The floor names what wakes. One that names nothing never rolls a mimic, so this is only a guard.
	if _floor_def.mimic == null:
		return
	var mimic := _spawn_enemy(_floor_def.mimic, at)
	mimic.wait_for_room_start()
	mimic.say(MIMIC_SHOUT, MIMIC_SHOUT_TIME)
	notice.emit("That chest has teeth!")


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
		_drop_coin(RoomBackdrop.cell_center(cells[0]), _floor_def.treasure_pension, RunState.PENSION_REWARD)


func _remove_others(choices: Array[Pickup], taken: Pickup) -> void:
	for choice in choices:
		if choice != taken and is_instance_valid(choice):
			choice.queue_free()


# Found recipes are saved at once, so dying later in the run never loses one.
func _drop_recipe(at: Vector2) -> bool:
	var item := RoomRules.pick_recipe(Content.items(), _bank.data.recipes_found, _run, _rng)
	if item == null:
		return false
	var tile := float(RoomBackdrop.TILE)
	var cell := _room.layout.nearest_floor_cell(Vector2i(floori(at.x / tile), floori(at.y / tile)))
	var pickup := _add_pickup(RoomBackdrop.cell_center(cell), "Recipe: %s" % item.display_name, RECIPE_COLOR, func(): _take_recipe(item), true)
	pickup.prompt = RECIPE_PROMPT
	return true


func _take_recipe(item: ItemDef) -> void:
	_bank.find_recipe(item.id)
	consumable_taken.emit()
	notice.emit("Recipe found: %s. Take it to the Waiting Room." % item.display_name)


func _create_treasure(cell: Vector2i) -> void:
	if _rng.randf() < RoomRules.TREASURE_RECIPE_CHANCE and _drop_recipe(RoomBackdrop.cell_center(cell)):
		return
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng)
	if picked.is_empty() or _rng.randf() < 0.5:
		_drop_coin(RoomBackdrop.cell_center(cell), _floor_def.treasure_pension, RunState.PENSION_REWARD)
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


# Head Office: red tape strung across lanes, each cell running the way its strand runs.
func _create_office_props(layout: RoomLayout, _palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_RED_TAPE):
		var tape := RedTape.new()
		tape.across = RedTape.runs_across(layout, cell)
		tape.position = RoomBackdrop.cell_center(cell)
		add_child(tape)
