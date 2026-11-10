class_name RoomView
extends Node2D

signal door_entered(target_id: int)
signal floor_cleared
# The room's fight is over, or it never had one. The floor scene writes the run checkpoint on it.
signal finished
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
# A game at one of its tables paid back more than its bet, for the endings' table visits.
signal arcade_won
# A prop broke; by_harold says whether it counts against him (his cane or his Thermos).
signal prop_broken(by_harold: bool)

const HEAL_AMOUNT := 2
# The meta a pickup or chest carries when the run checkpoint keeps it, and the kinds it can be.
const KEEP := "keep"
const KEEP_ITEM := "item"
const KEEP_FREE := "free"
const KEEP_SHOP := "shop"
const KEEP_RECIPE := "recipe"
const KEEP_CHEST := "chest"
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
# Decor the depth look leaves out, since none of it can be named at 1x, and decor it keeps only as a
# light (_create_decor).
const DEPTH_LEFT_OUT := [RoomDecor.PUDDLE, RoomDecor.CRACK, RoomDecor.BONES, RoomDecor.MOSS, RoomDecor.COAL_DUST]
const DEPTH_UNSEEN := [RoomDecor.FLUORESCENT]
const FREE_COLOR := Color("67f0d0")
const KEY_COLOR := Color("ece9e0")
const BOMB_COLOR := Color("ff9a3c")
const MIMIC_SHOUT := "Surprise!"
const MIMIC_SHOUT_TIME := 1.2
# Where a Gilded Urn's two items wait, in cells from the urn: one each side, a row lower.
const URN_CHOICE_OFFSETS: Array[Vector2i] = [Vector2i(-2, 1), Vector2i(2, 1)]
const PENSION_COLOR := Color("ffd24a")
# Pickup pictures in res://art/props/ (Pickup.art_id). Items have none yet and keep the rarity disc.
const ART_COIN := "pickup_coin"
const ART_SLIP := "pickup_slip"
const ART_THERMOS := "pickup_thermos"
const ART_POTION := "pickup_potion"
const ART_PILL := "pickup_pill"
const ART_RECIPE := "pickup_recipe"
# The film reel a kept rule leaves (RuleKeeper); film_reel is the Cinema's enemy.
const ART_REEL := "memory_reel"
const REEL_COLOR := Color("d9a441")
const SHOP_ART := {ShopRules.KIND_HEAL: ART_PILL, ShopRules.KIND_KEY: ART_SLIP, ShopRules.KIND_BOMB: ART_THERMOS,
		ShopRules.KIND_POTION: ART_POTION}
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
# A small potion has no shop price, so the Moving Boxes count it dearer than a Slip.
const POTION_WORTH := 30
# A broken room rule sends the Auditor: he walks in this long after the whistle, and now and then
# leaves an item. The floor scene hands his def over, since room code names no enemy data.
const AUDIT_DELAY := 2.0
const AUDIT_ITEM_CHANCE := 0.25
const AUDITOR_ID := "auditor"

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
# Wares bought here, for the Tax Refund, which pays only for a shop left without buying.
var shop_purchases := 0
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
# What the run checkpoint kept of this room, from snapshot(). Set before the room enters the tree, it
# rebuilds the room cleared: no enemies, open doors, and only the kept items, stock and closed chests.
var restore := {}
# Choice groups put back from a checkpoint, kept here since a Callable holds no reference to them.
var _restored_groups := {}
# The floor's depth look, or null when its rooms keep the flat tiles (DepthLook, FloorDef.art_style).
var _depth: DepthLook
# The palette the room was built with, for the doors' jambs and the floor beyond them.
var _palette: RoomPalette
# The Auditor on his way: his def, the door he comes in by (or null), the time left until he walks in
# (negative when none is coming), and whether one was ever called here, since only one ever comes.
var _audit_def: EnemyDef
var _audit_door: Door
var _audit_left := -1.0
var _audited := false
var _ally_left := -1.0
var _ally_door: Door


# The room's id on its floor's map.
func room_id() -> int:
	return _room.id


func room_type() -> String:
	return _room.room_type if _room != null else ""


# A small pickup an item lays in the room: a Slip, a Thermos, a small potion or a coin of amount.
func drop_for_item(kind: String, at: Vector2, amount := 1, id := "") -> void:
	var spot := clear_spot(at)
	if kind == RoomRules.DROP_COIN:
		_drop_coin(spot, amount)
	elif kind == RoomRules.DROP_HEAL:
		_add_heal(spot, amount)
	elif kind == RoomRules.DROP_POTION and Content.potion(id) != null:
		_drop_potion(spot, Content.potion(id))
	else:
		_drop_consumable(spot, kind)


func drop_free_item(item: ItemDef, at: Vector2) -> void:
	_run.promise(item)
	_add_free_item(clear_spot(at), item)


static func nearest_pickup(pickups: Array, at: Vector2, kinds: Array) -> Pickup:
	var best: Pickup = null
	for node in pickups:
		var pickup := node as Pickup
		if pickup == null or not pickup.is_waiting() or not kinds.has(pickup.fetch_kind):
			continue
		if pickup.can_take.is_valid() and not pickup.can_take.call():
			continue
		if best == null or pickup.global_position.distance_to(at) < best.global_position.distance_to(at):
			best = pickup
	return best


static func nearest_copyable(pickups: Array, at: Vector2) -> Pickup:
	var best: Pickup = null
	for node in pickups:
		var pickup := node as Pickup
		if pickup == null or not pickup.is_waiting() or pickup.copy_kind.is_empty():
			continue
		if best == null or pickup.global_position.distance_to(at) < best.global_position.distance_to(at):
			best = pickup
	return best


func fetch_nearest_pickup(at: Vector2) -> bool:
	var pickup := nearest_pickup(get_children(), at, ["coin", "key", "bomb"])
	if pickup == null:
		return false
	pickup.fly()
	return true


# Lays a copy of the nearest copyable pickup a cell beside it. A potion stays the same potion.
func copy_nearest_pickup(at: Vector2) -> bool:
	var pickup := nearest_copyable(get_children(), at)
	if pickup == null:
		return false
	var spot := clear_spot(pickup.position + Vector2(RoomBackdrop.TILE, 0))
	match pickup.copy_kind:
		"coin":
			_place_coin(spot, pickup.copy_amount)
		"key":
			_drop_consumable(spot, RoomRules.DROP_KEY)
		"bomb":
			_drop_consumable(spot, RoomRules.DROP_BOMB)
		"heal":
			_add_heal(spot, pickup.copy_amount)
		"potion":
			_drop_potion(spot, pickup.copy_potion)
	return true


# Where the room's last enemy fell, for what an item leaves after a clear.
func last_death_spot() -> Vector2:
	return _last_death_at


func note_prop_broken(by_harold: bool) -> void:
	prop_broken.emit(by_harold)


# For Do Not Touch the Exhibits: whether anything Harold could break stands in the room.
func has_breakables() -> bool:
	for child in get_children():
		if child is BreakableBlock and not child.is_queued_for_deletion() and child.can_break_by(BreakableBlock.SOURCE_CANE):
			return true
	return false


# The room's enemies wait while its rule is announced.
func hold_enemies(seconds: float) -> void:
	for child in get_children():
		if child is Enemy and not child.is_queued_for_deletion():
			child.hold(seconds)


# The whistle has blown. He is counted from now, so the room cannot clear before he walks in.
func call_auditor(def: EnemyDef, from_door: Door) -> void:
	if _audited or _finished or def == null:
		return
	_audited = true
	_audit_def = def
	_audit_door = from_door
	_audit_left = AUDIT_DELAY
	_alive += 1


# Runs only while the room is in the tree, so leaving the room pauses his walk-in.
func _physics_process(delta: float) -> void:
	_tick_audit(delta)
	if _tick_ally(delta):
		_spawn_ally()


# Clipboard of Your Own: the Auditor walks in on his side after the same wait, and the room stays his to clear.
func call_ally_auditor(from_door: Door) -> void:
	if _audited or _finished:
		return
	_audited = true
	_ally_door = from_door
	_ally_left = AUDIT_DELAY


# Counts the ally Auditor's walk-in down. True on the one frame he is due.
func _tick_ally(delta: float) -> bool:
	if _ally_left < 0.0:
		return false
	_ally_left -= delta
	if _ally_left > 0.0:
		return false
	_ally_left = -1.0
	return true


func _spawn_ally() -> void:
	var ally := AllyAuditor.make(_run.effects.ctx)
	add_child(ally)
	ally.global_position = summon_spot(_audit_spot_for(_ally_door))
	finished.connect(ally.queue_free, CONNECT_ONE_SHOT)
	Sfx.play("door_open")


func _tick_audit(delta: float) -> void:
	if _audit_left < 0.0:
		return
	_audit_left -= delta
	if _audit_left > 0.0:
		return
	_audit_left = -1.0
	var at := summon_spot(_audit_spot())
	var auditor := _spawn_enemy(_audit_def, at)
	if auditor._behavior is AuditorBehavior:
		(auditor._behavior as AuditorBehavior).tempo = AuditorBehavior.cooldown_mult(_floor_def.depth if _floor_def != null else 1)
	_run.effects.auditor(auditor)
	# His reserved place becomes him.
	_alive -= 1
	auditor.wait_for_room_start()
	Sfx.play("door_open")
	# AUDIT, stamped over the door he walks in by.
	var flash := AuditFlash.new()
	flash.position = at
	add_child(flash)
	Sfx.play("rule_stamp")


# The door he comes in by, else where the last enemy fell, else the room's middle.
func _audit_spot() -> Vector2:
	return _audit_spot_for(_audit_door)


func _audit_spot_for(door: Door) -> Vector2:
	if is_instance_valid(door):
		return door.position
	if _last_death_at != Vector2.ZERO:
		return _last_death_at
	return Vector2(_room.layout.size_in_cells()) * RoomBackdrop.TILE / 2.0


# For tests.
func debug_alive() -> int:
	return _alive


# For tests.
func debug_set_alive(count: int) -> void:
	_alive = count


# The secret walls still standing in the room, for the Magnifying Glass's glint.
func secret_walls() -> Array[SecretWall]:
	var walls: Array[SecretWall] = []
	for child in get_children():
		if child is SecretWall and not child.is_queued_for_deletion():
			walls.append(child)
	return walls


# What the Moving Boxes value each small pickup at, to carry the cheapest: its shop price.
static func carry_worth(kind: String) -> int:
	match kind:
		RoomRules.DROP_HEAL:
			return ShopRules.HEAL_PRICE
		RoomRules.DROP_BOMB:
			return ShopRules.BOMB_PRICE
		RoomRules.DROP_KEY:
			return ShopRules.KEY_PRICE
	return POTION_WORTH


# The cheapest of these small pickups still lying untaken, or null. Ties go to the first laid out.
static func cheapest_waiting(pickups: Array) -> Pickup:
	var best: Pickup = null
	for node in pickups:
		var pickup := node as Pickup
		if pickup == null or pickup.carry_kind.is_empty() or not pickup.is_waiting():
			continue
		if best == null or carry_worth(pickup.carry_kind) < carry_worth(best.carry_kind):
			best = pickup
	return best


# Takes the cheapest small pickup left on the floor away with him (Moving Boxes): it is gone from this
# room, and the result says what to lay out in the next, {"kind", "amount"}, or is empty.
func take_leftover() -> Dictionary:
	var best := cheapest_waiting(get_children())
	if best == null:
		return {}
	var taken := carry_record(best)
	best.queue_free()
	return taken


# What the next room lays out for a carried pickup: {"kind", "amount", "id"}; id names a potion.
static func carry_record(pickup: Pickup) -> Dictionary:
	return {"kind": pickup.carry_kind, "amount": pickup.carry_amount, "id": pickup.carry_id}


# Two cells into the room from where he stands, toward its middle, on open floor clear of the doors,
# for a pickup he brought along.
func spot_inside(from: Vector2) -> Vector2:
	var middle := Vector2(_room.layout.size_in_cells()) * RoomBackdrop.TILE / 2.0
	var at := from + from.direction_to(middle) * RoomBackdrop.TILE * 2.0
	var cell := _room.layout.nearest_floor_cell(_cell_of(at))
	for i in 4:
		if not _room.layout.touches_a_door(cell):
			break
		at += from.direction_to(middle) * RoomBackdrop.TILE
		cell = _room.layout.nearest_floor_cell(_cell_of(at))
	return RoomBackdrop.cell_center(cell)


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
	# Everything at z 0 here is drawn in order of its y, with Harold among them (his scene sorts too):
	# bodies stand on their feet (SpriteVisual.set_feet, NpcSprite), props on their middles. Flat floor
	# things sit at a z below the bodies, so they never cover a foot.
	y_sort_enabled = true
	_walk_grid = WalkGrid.from_layout(_room.layout)
	var backdrop := RoomBackdrop.new()
	var palette := _floor_def.room_palette()
	# Props, doors, chests and pickups look in the path's own art folder first (PropArt).
	PropArt.art_set = _floor_def.art()
	# On a screen wider than 16:9, the bars beside the picture take this area's dark wall tone.
	SideBars.show_for(palette)
	# An Arcade Room keeps its neon patterns, so it never passes for one of the floor's own rooms.
	var tile_set := _floor_def.art()
	_depth = DepthLook.for_floor(_floor_def)
	if _room.room_type == RoomLayout.TYPE_ARCADE:
		palette = arcade_palette(palette)
		tile_set = ""
		_depth = null
	_palette = palette
	DepthLook.active = _depth != null
	if _depth != null:
		child_entered_tree.connect(_on_child_entered)
	backdrop.setup(_room.layout.rows, palette, _room.decor_seed, tile_set, _depth)
	add_child(backdrop)
	Lighting.add_room_mood(self, _room.layout.size_in_cells(), palette, _depth, _room.layout.rows)
	_create_decor(palette)
	if _room.room_type == RoomLayout.TYPE_LANDING:
		_add_floor_sign()
	_create_doors()
	_create_blocks()
	_create_props(palette)
	if not restore.is_empty():
		_restore_contents()
		return
	_create_rewards()
	_spawn_enemies()
	if _alive == 0:
		_finish_room()


# A stored room comes back into the tree when he returns; the depth look's switch follows the room.
func _enter_tree() -> void:
	if _floor_def != null and is_node_ready():
		DepthLook.active = _depth != null


# Shots, ground marks and warnings added to a depth room keep their full colour in its dark. Their z is
# set in their own _ready, so the check waits a frame's moment.
func _on_child_entered(node: Node) -> void:
	DepthLook.keep_vivid.call_deferred(node)


# Call each time the player arrives, so the door he stands on waits until he steps away.
# Whether this room's fight is on: enemies still standing in a room not yet cleared.
func is_fighting() -> bool:
	return _alive > 0 and not _finished


func refresh_doors() -> void:
	rearm_doors()
	# Each Arcade game plays once per visit, so coming back fills them again.
	for table in _tables:
		table.refill()


# Every door waits until he has stepped off it, as on arriving.
func rearm_doors() -> void:
	for door in _doors:
		door.rearm()


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
		if child is ThrownThermos:
			_run.add_bomb()
		if is_passing_effect(child) or is_flying_coin:
			child.queue_free()


# Anything an attack or a blast leaves in the room for a while. A new one must be added here, or it
# freezes mid-way in a stored room and goes on when Grandpa comes back.
# Each path adds its own on a line at the end: Departures, Terminal Zero added XRaySweep and RunwayLane.
static func is_passing_effect(child: Node) -> bool:
	# The Last Resort Cruise
	if CruiseProps.is_passing_effect(child):
		return true
	# The items' shared visuals
	if ItemFx.is_passing_effect(child):
		return true
	# The Flashback Cinema
	if child is PopcornTub or child is FilmTrail or child is LensBeam or child is SpliceLane or child is ReelLane or child is ReelChange or child is BurnRing:
		return true
	# The Seance Hotline
	if SeanceProps.is_passing_effect(child):
		return true
	# Room rules: the Auditor's stamp ink (his stamp itself is a Projectile) and his AUDIT door flash
	if child is InkBlot or child is AuditFlash:
		return true
	# Flashbacks: the 1960 football and the 1975 ticket line
	if child is EraBall or child is TicketLine:
		return true

	return (child is Projectile or child is DeathBurst or child is Thermos or child is EnemyBlast
		or child is SummonMark or child is GroundStrike or child is LightsOut or child is SteamJet
		or child is Shockwave or child is FlameBurst or child is PipeRing or child is CollectionPlate
		or child is ProcessionLane or child is SafeSpotMark or child is PerfumeCloud or child is WetSplash
		or child is DroppedCoffin
		or child is TapeSpread or child is PaperTrail or child is WriteUpMark or child is LaneDrop or child is HoldMusic
		or child is TakeoverTether
		# Departures, Terminal Zero
		or child is XRaySweep or child is RunwayLane)


func place_bomb(at: Vector2) -> void:
	# The Overarm Bowler throws it; the full loop places and times its Thermoses as they are.
	if _run.stats.throws_thermos and not _run.effects.ctx.counting_exact:
		var wanted := ThrownThermos.landing(at, _player.aim_point())
		var query := PhysicsRayQueryParameters2D.create(at, wanted, 1)
		var wall := get_world_2d().direct_space_state.intersect_ray(query)
		var thrown := ThrownThermos.new()
		thrown.from = at
		thrown.to = wall["position"] - (wanted - at).normalized() * 6.0 if not wall.is_empty() else wanted
		thrown.room = self
		add_child(thrown)
		return
	var fuse := Thermos.FUSE_TIME
	if not _run.effects.ctx.counting_exact:
		fuse += _run.stats.fuse_bonus
	_place_thermos(at, fuse)


# A thrown Thermos has landed: it bursts there, after the Pressure Cooker's extra fuse if he has one.
func land_thrown_bomb(at: Vector2) -> void:
	_place_thermos(at, maxf(_run.stats.fuse_bonus, 0.01))


func _place_thermos(at: Vector2, fuse: float) -> void:
	var thermos := Thermos.new()
	thermos.setup(_player)
	thermos.level = _run.stats.thermos_level
	thermos.damage_mult = _run.stats.thermos_damage_mult
	thermos.radius = _run.stats.blast_radius
	thermos.fuse_time = fuse
	thermos.position = at
	thermos.exploded.connect(bomb_exploded.emit)
	thermos.exploded.connect(_run.effects.bomb.bind(at))
	add_child(thermos)


func doors() -> Array[Door]:
	return _doors


# The film reel a kept rule leaves where the last enemy fell, or as near as its long name fits between the
# walls, off the doors. Picking it up always succeeds; the keeper decides whether a held reel wastes it.
func drop_reel(at: Vector2, era: String, on_take: Callable) -> Pickup:
	var taken: Array[Vector2i] = []
	for child in get_children():
		if child is Pickup and child.art_id != ART_COIN and not child.is_queued_for_deletion():
			taken.append(_cell_of(child.position))
	var spot := RoomBackdrop.cell_center(_room.layout.label_spot_near(_cell_of(at), taken))
	var pickup := _add_pickup(spot, tr("Reel: %s") % tr(Eras.title(era)), REEL_COLOR, on_take, false, "item_fanfare")
	pickup.art_id = ART_REEL
	return pickup


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
		# A resumed run finds the way to a room it already reached open: no crack, stone or lock.
		if not restore.is_empty() and _progress.is_visited(target.id):
			_add_door(target.id, RoomRules.door_icon(target.room_type), side)
			continue
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
	Sfx.play("secret_reveal")
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
	Sfx.play("secret_reveal")
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


# The way down from a fallen floor boss's room: a cage lift standing against the north wall
# (RoomLayout.lift_cell), clear of the boss's items. It waits until he has stepped off it, as any
# door he arrives on does.
func add_stairwell() -> void:
	if stairwell() != null:
		return
	var cell := _room.layout.lift_cell(_choice_cells)
	var door := Door.new()
	door.setup(STAIRWELL_ID, STAIRWELL_ICON, _player.feet())
	door.locked = false
	# The way down is the cage lift, its gates folding open as it appears (Door.lift).
	door.lift = true
	door.lift_opens_on_arrival = true
	door.position = RoomBackdrop.cell_center(cell)
	door.entered.connect(func(_id: int): stairwell_entered.emit())
	add_child(door)
	door.rearm()
	_doors.append(door)
	Sfx.play("stairwell_appear")
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
	door.palette = _palette
	door.depth = _depth
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
	for symbol: String in [RoomLayout.SYMBOL_ARMCHAIR, RoomLayout.SYMBOL_BED, RoomLayout.SYMBOL_PEW]:
		for cell in layout.cells_of(symbol):
			var furniture: RockBlock
			match symbol:
				RoomLayout.SYMBOL_ARMCHAIR:
					furniture = Armchair.new()
				RoomLayout.SYMBOL_PEW:
					furniture = ChapelPew.new()
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
	for cell in layout.cells_of(RoomLayout.SYMBOL_HYMN_CART):
		var cart := HymnCart.new()
		cart.palette = palette
		_place_prop(cart, cell)
		cart.broken.connect(_on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_VASE):
		var vase := FlowerVase.new()
		vase.palette = palette
		_place_prop(vase, cell)
		vase.broken.connect(_on_vase_broken.bind(cell))
	for symbol: String in [RoomLayout.SYMBOL_WREATH, RoomLayout.SYMBOL_CANDLE]:
		for cell in layout.cells_of(symbol):
			var stand: BreakableBlock
			match symbol:
				RoomLayout.SYMBOL_WREATH:
					stand = WreathStand.new()
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
	# The Last Resort Cruise: its deck props and, in a room that rolls, the rolling deck.
	CruiseProps.build(self, layout, palette)
	_create_office_props(layout, palette)
	# Departures, Terminal Zero: its stock and its queue barriers.
	TerminalProps.build(self, layout, palette)
	# The Flashback Cinema: seat rows, pillars and aisle lights.
	CinemaProps.build(self, layout, palette)
	# The Seance Hotline: cubicle partitions, desks, seance tables, lava lamps and beaded curtains.
	SeanceProps.build(self, layout, palette)


func _place_prop(prop: BreakableBlock, cell: Vector2i) -> void:
	prop.position = RoomBackdrop.cell_center(cell)
	add_child(prop)


func _create_decor(palette: RoomPalette) -> void:
	var items := RoomDecor.plan(_room.layout, palette, _room.decor_seed)
	# The depth look lays its own cracks into the ground, so the code puddles and cracks stay out, and
	# so do the little bone scatters, too small to name at 1x, and the moss and coal dust, which read as
	# dark blobs.
	if _depth != null:
		var kept: Array[Dictionary] = []
		var papers := 0
		for item in items:
			if DEPTH_LEFT_OUT.has(item["kind"]):
				continue
			# Its grass is paper here: half as many stacks, so fewer, clearer things lie about.
			if item["kind"] == RoomDecor.GRASS:
				papers += 1
				if papers % 2 == 0:
					continue
			kept.append(item)
		items = kept
	var layer := DecorLayer.new()
	layer.setup(items, palette)
	# A fluorescent panel's glare on the floor is a pale strip no one can name; in the depth look only
	# its light is left.
	if _depth != null:
		layer.unseen = DEPTH_UNSEEN
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
	enemy.notice_mult = _run.stats.notice_mult
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
	_run.note_met(def.id)
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
	_run.note_kill(enemy.def.id)
	DeathBurst.spawn(self, enemy.position, enemy.def.color, enemy.def.is_boss)
	enemy_died.emit(enemy.position, enemy.def.is_boss)
	var spot := clear_spot(enemy.position)
	if enemy.coin_value() > 0:
		_drop_coin(spot, enemy.coin_value(), RunState.PENSION_BOSS if enemy.def.is_boss else RunState.PENSION_ENEMY)
	_last_death_at = spot
	if enemy.def.drops_key and not enemy.is_summon:
		_drop_consumable(spot, RoomRules.DROP_KEY)
	if _room.room_type == RoomLayout.TYPE_MINI_BOSS and enemy.def.is_boss:
		_drop_consumable(spot, RoomRules.DROP_KEY)
		if _rng.randf() < RoomRules.MINI_BOSS_RECIPE_CHANCE:
			_drop_recipe(spot + Vector2(-RoomBackdrop.TILE, RoomBackdrop.TILE))
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS and enemy.def.is_boss and not enemy.is_summon:
		_drop_boss_choice(spot)
	if enemy.def.id == AUDITOR_ID and (enemy.leaves_item or _rng.randf() < AUDIT_ITEM_CHANCE):
		_drop_audit_item(spot)
	if enemy.def.is_boss:
		for other in get_tree().get_nodes_in_group("enemies"):
			if other != enemy and other.get_parent() == self:
				other.dismiss()
	if _alive == 0:
		_finish_room()


# source is a RunState.PENSION_* id, or "" for Pension that only the general rate touches.
func _drop_coin(at: Vector2, base_amount: int, source := "") -> void:
	_place_coin(at, _run.pension_amount(base_amount, source))


# A coin of this Pension (already worked out) lying at a spot.
func _place_coin(at: Vector2, amount: int) -> Pickup:
	var coin := _add_pickup(at + Vector2(_rng.randf_range(-COIN_SCATTER, COIN_SCATTER), _rng.randf_range(-COIN_SCATTER, COIN_SCATTER)), "+%d" % amount, PENSION_COLOR, func(): _collect_pension(amount))
	coin.art_id = ART_COIN
	# A coin lying in a pocket only a bomb opens would fly out through the stones, so it is neither
	# fetched nor copied either.
	if not _room.layout.coin_can_fly_from(_cell_of(at)):
		return coin
	coin.fetch_kind = "coin"
	coin.copy_kind = "coin"
	coin.copy_amount = amount
	coin.flies = true
	# The Penny Jar calls coins from further off.
	coin.magnet_radius = Pickup.MAGNET_RADIUS * _run.stats.coin_reach_mult
	_coins.append(coin)
	if _finished:
		coin.fly()
	return coin


func _drop_consumable(at: Vector2, kind: String) -> void:
	match kind:
		RoomRules.DROP_KEY:
			var slip := _add_pickup(at, RoomRules.KEY_NAME, KEY_COLOR, func(): _take_consumable(_run.add_key, RunEffects.SLIP), false, "slip_pickup")
			slip.can_take = _run.can_add_key
			slip.carry_kind = kind
			slip.fetch_kind = "key"
			slip.copy_kind = "key"
			slip.art_id = ART_SLIP
		RoomRules.DROP_BOMB:
			var thermos := _add_pickup(at, RoomRules.BOMB_NAME, BOMB_COLOR, func(): _take_consumable(_run.add_bomb, RunEffects.BOMB), false, "thermos_pickup")
			thermos.can_take = _run.can_add_bomb
			thermos.carry_kind = kind
			thermos.fetch_kind = "bomb"
			thermos.copy_kind = "bomb"
			thermos.art_id = ART_THERMOS
		RoomRules.DROP_POTION:
			_drop_potion(at, PotionPool.roll(Content.potions(), _rng.randf(), _rng.randf()))


# A potion lying in the room. It fills the potion slot, and waits on the floor while the slot is full.
func _drop_potion(at: Vector2, def: PotionDef) -> Pickup:
	if def == null:
		def = Content.potion(RoomRules.SMALL_POTION_ID)
	var potion := _add_pickup(at, def.display_name, def.color, func(): _take_consumable(func(): _run.give_potion(def)), false, "pill_heal")
	potion.can_take = _run.can_take_potion
	potion.carry_kind = RoomRules.DROP_POTION
	potion.carry_id = def.id
	potion.copy_kind = "potion"
	potion.copy_potion = def
	potion.art_id = ART_POTION
	return potion


# kind is the RunEffects pickup kind the items hear, or "" for one they do not. The items may make one
# pickup more than one (In Triplicate); each still respects the hold cap.
func _take_consumable(add: Callable, kind := "") -> void:
	var amount := 1
	if not kind.is_empty():
		amount = maxi(_run.effects.pickup(kind, 1), 0)
	for i in amount:
		add.call()
	consumable_taken.emit()


# A coin's Pension, as the items change it (the Lucky Bingo Card's fifth coin pays five times).
func _collect_pension(amount: int) -> void:
	pension_earned.emit(_run.effects.pickup(RunEffects.PENSION, amount))


# A heal of so many pills. The items hear it first, so a Pill Organizer can store one taken at full.
func _take_heal(amount: int) -> void:
	_run.health.heal(_run.effects.pickup(RunEffects.HEAL, amount))


# Heals wait on the floor while he is at full health, unless the Game tab's option takes them then, or
# an item wants them.
func _can_take_heal() -> bool:
	return _run.can_take_heal() or _run.effects.accepts_pickup(RunEffects.HEAL)


# A heal of so many pills lying on the floor. The Pill Crusher's crumbs must be stood nearer to take.
func _add_heal(at: Vector2, pills: int) -> Pickup:
	var heal := _add_pickup(at, "Heal", HEAL_COLOR, func(): _take_heal(pills), false, "pill_heal")
	heal.can_take = _can_take_heal
	heal.collect_radius = Pickup.COLLECT_RADIUS * _run.stats.heal_reach_mult
	heal.carry_kind = RoomRules.DROP_HEAL
	heal.carry_amount = pills
	heal.copy_kind = "heal"
	heal.copy_amount = pills
	heal.art_id = ART_PILL
	return heal


# sound is what taking it sounds like, or "" for one that makes its own (coins, wares).
func _add_pickup(at: Vector2, label: String, color: Color, on_take: Callable, needs_interact := false, sound := "") -> Pickup:
	var pickup := Pickup.new()
	pickup.setup(label, color, _player.feet(), needs_interact)
	pickup.position = at
	pickup.collected.connect(on_take)
	if not sound.is_empty():
		pickup.collected.connect(func(): Sfx.play(sound))
	add_child(pickup)
	return pickup


func _create_rewards() -> void:
	var cells := _room.layout.cells_of("I")
	# The last reel memento lays one more item out in a treasure room, on open floor near the others.
	if _room.room_type == RoomLayout.TYPE_TREASURE and not cells.is_empty() and _run.has_perk(Mementos.TREASURE_CHOICE_PERK):
		var extra := _room.layout.open_spots_near(cells, cells)
		for i in mini(Mementos.TREASURE_EXTRA, extra.size()):
			cells.append(extra[i])
	if not cells.is_empty():
		_create_item_choice(cells)
	for cell in _room.layout.cells_of("H"):
		_add_heal(RoomBackdrop.cell_center(cell), HEAL_AMOUNT)
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


# A finished game: a win is one that paid back more than its bet.
func arcade_settled(payout: int, bet_amount: int) -> void:
	if payout > bet_amount:
		arcade_won.emit()


# How much more a win at this game pays of its winnings: the Lucky Seat Ticket, and Card Shark at the poker
# table. Never while the full loop counts every payout.
func arcade_win_bonus(game: String) -> float:
	if _run == null or _run.effects.ctx.counting_exact:
		return 0.0
	return ArcadeOdds.win_bonus(game, _run.stats.arcade_win_bonus, _run.stats.poker_win_bonus)


# Winnings go straight into his Pension, exactly as the game's rules pay them.
func arcade_pay(amount: int) -> void:
	if amount > 0:
		_bank.add_pension(amount)


# Three skulls: a free item from the run's usual pool, lying by the table. With nothing left to offer,
# it pays what a shop would ask for one instead.
func arcade_item_win(table: ArcadeTable) -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng, ItemRarity.ARCADE)
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
	var stock := ShopRules.stock(Content.items(), _run, _rng, _floor_def.pension_mult, Content.potions())
	_run.effects.shop_open(stock)
	var cells := _room.layout.cells_of("S")
	# A Ticket Stub Book's extra ware lies on open floor near the others.
	var extra := extra_shop_cells(_room.layout, stock.size() - cells.size())
	cells.append_array(extra)
	for i in mini(stock.size(), cells.size()):
		_add_shop_entry(RoomBackdrop.cell_center(cells[i]), stock[i])
	_create_shop_keeper(extra)


# The merchant and the Retirement Plan's station, which a resumed shop needs as well as its stock.
# The merchant stands first, so the plan's reward spots keep clear of him and of any extra ware.
func _create_shop_keeper(extra: Array[Vector2i] = []) -> void:
	var merchant_at := _add_merchant()
	merchant_at.append_array(extra)
	_reward_cells = _room.layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size(), merchant_at)
	var station := RetirementStation.new()
	station.setup(_bank, _player.feet())
	station.position = RoomBackdrop.cell_center(_room.layout.cells_of(RoomLayout.SYMBOL_PLAN)[0])
	station.deposit_wanted.connect(_on_deposit_wanted)
	station.blasted.connect(_on_plan_blasted)
	add_child(station)


# Spots for wares beyond a shop's own S cells: plain floor nearest the last of them, off the doors,
# spaced from every ware, the merchant and the plan, clear of the plan's own text, and far enough from
# the side walls for a long name and price to fit.
static func extra_shop_cells(layout: RoomLayout, count: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	var wares := layout.cells_of("S")
	if count <= 0 or wares.is_empty():
		return found
	var taken: Array[Vector2i] = wares.duplicate()
	var plans := layout.cells_of(RoomLayout.SYMBOL_PLAN)
	taken.append_array(plans)
	if layout.merchant_cell() != Vector2i(-1, -1):
		taken.append(layout.merchant_cell())
	for i in count:
		var wanted := wares[wares.size() - 1 - (i % wares.size())]
		# The full label spacing first; a crowded shop settles for the plan's loose one.
		var best := Vector2i(-1, -1)
		for loose in [false, true]:
			var best_distance := INF
			for cell in layout.cells_of(RoomLayout.SYMBOL_FLOOR):
				if not shop_label_fits(layout, cell) or layout.touches_a_door(cell):
					continue
				if not (layout._spaced_loosely(cell, taken) if loose else layout._spaced_from(cell, taken)):
					continue
				if not plans.is_empty() and not RoomLayout.clear_of_the_plan_text(cell, plans[0]):
					continue
				var distance := Vector2(cell - wanted).length_squared()
				if distance < best_distance:
					best_distance = distance
					best = cell
			if best != Vector2i(-1, -1):
				break
		if best == Vector2i(-1, -1):
			break
		taken.append(best)
		found.append(best)
	return found


# A ware's name and price are drawn centred over it, so it keeps LABEL_CELLS from either side wall and
# off the HUD's row.
static func shop_label_fits(layout: RoomLayout, cell: Vector2i) -> bool:
	return layout._label_fits(cell) and cell.x >= RoomLayout.LABEL_CELLS


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
			color = ItemRarity.color_of(item.rarity)
			give = func(): _run.add_item(item)
			allowed = func(): return not _run.has_item(item.id)
		ShopRules.KIND_HEAL:
			label = "Heal"
			color = HEAL_COLOR
			give = func(): _take_heal(HEAL_AMOUNT)
			allowed = _can_take_heal
		ShopRules.KIND_KEY:
			label = RoomRules.KEY_NAME
			color = KEY_COLOR
			give = func(): _take_consumable(_run.add_key, RunEffects.SLIP)
			allowed = _run.can_add_key
		ShopRules.KIND_BOMB:
			label = RoomRules.BOMB_NAME
			color = BOMB_COLOR
			give = func(): _take_consumable(_run.add_bomb, RunEffects.BOMB)
			allowed = _run.can_add_bomb
		ShopRules.KIND_POTION:
			var potion: PotionDef = entry["potion"]
			label = potion.display_name
			color = potion.color
			give = func(): _run.give_potion(potion)
			allowed = _run.can_take_potion
	var text := "%s: %d" % [label, price]
	if price <= 0:
		text = "Free: %s" % label
	elif entry.get("half", false):
		text = "%s: %d, half" % [label, price]
	var pickup := _add_pickup(at, text, color, func(): _buy(price, give), true)
	pickup.prompt = SHOP_PROMPT
	pickup.art_id = SHOP_ART.get(entry["kind"], "")
	var item_id: String = entry["item"].id if entry.get("item") != null else (entry["potion"].id if entry.get("potion") != null else "")
	pickup.set_meta(KEEP, {"kind": KEEP_SHOP, "shop": entry["kind"], "price": price, "id": item_id,
			"half": entry.get("half", false)})
	if entry["kind"] == ShopRules.KIND_ITEM:
		_mark_item(pickup, entry["item"])
	pickup.can_take = func(): return _bank.data.pension >= price and allowed.call()


func _buy(price: int, give: Callable) -> void:
	if price <= 0 or _bank.spend(price):
		Sfx.play("ui_ching")
		shop_purchases += 1
		give.call()


func _on_deposit_wanted(amount: int) -> void:
	var before: int = _bank.data.pension
	var reached: int = _bank.retirement_deposit(amount)
	if _bank.data.pension < before:
		Sfx.play("plan_deposit")
	for i in reached:
		_award_plan_reward()


# Rewards last for this run only. Each tier's item lies on its own spot beside the station.
func _award_plan_reward() -> void:
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng, ItemRarity.ITEM_ROOM)
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
		Sfx.play("plan_withdraw")
		consumable_taken.emit()
		notice.emit("Cashed out %d Pension from your Retirement Plan" % amount)
	elif data.retirement_balance > 0:
		notice.emit("Your Retirement Plan is locked until your next run")


func _add_free_item(at: Vector2, item: ItemDef) -> Pickup:
	var pickup := _add_item_pickup(at, item)
	pickup.set_text("Free: %s" % item.display_name)
	pickup.get_meta(KEEP)["kind"] = KEEP_FREE
	return pickup


# The Auditor now and then leaves an item from an item room's pool, a cell beside where he fell, on
# open floor off the doors.
func _drop_audit_item(at: Vector2) -> void:
	var items := RoomRules.pick_items(Content.items(), _run, 1, _rng, ItemRarity.ITEM_ROOM)
	if items.is_empty():
		return
	var wanted: Array[Vector2i] = [_cell_of(at) + Vector2i(1, 0)]
	var cells := _room.layout.open_spots_near(wanted, _choice_cells)
	if cells.is_empty():
		return
	_add_free_item(RoomBackdrop.cell_center(cells[0]), items[0])


# A floor boss leaves two free items from the run's usual pool, one each side of where it fell.
# Taking one clears the other away. A pool down to one item shows one, and an empty pool none.
func _drop_boss_choice(at: Vector2) -> void:
	if not _choice_cells.is_empty():
		return
	var picked := RoomRules.pick_items(Content.items(), _run, BOSS_CHOICE_COUNT, _rng, ItemRarity.BOSS)
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
		pickup.get_meta(KEEP)["group"] = "boss"
	boss_choice_dropped.emit(_choice_cells.size())


# One chest of the given kind on a C cell. ChestRules holds what each kind costs and pays.
func _create_chest(cell: Vector2i, kind: String) -> Chest:
	var chest := Chest.new()
	chest.kind = kind
	chest.setup(ChestRules.display_name(kind), PENSION_COLOR, _player.feet(), kind != ChestRules.SAFE)
	chest.prompt = ChestRules.prompt_for(kind, _run.stats.slip_cost_cut)
	chest.position = RoomBackdrop.cell_center(cell)
	chest.set_meta(KEEP, {"kind": KEEP_CHEST, "chest": kind})
	match kind:
		ChestRules.LUNCHBOX:
			chest.collected.connect(_open_lunchbox.bind(cell))
		ChestRules.URN:
			chest.can_take = func(): return ChestRules.can_open(kind, _run.keys, _run.stats.slip_cost_cut)
			chest.collected.connect(_open_urn.bind(cell))
		ChestRules.SAFE:
			chest.blasted_open.connect(_open_safe)
		ChestRules.MIMIC:
			# It shows a Locked Chest's prompt rules, so nothing gives it away but its breathing.
			chest.can_take = func(): return ChestRules.can_open(ChestRules.LOCKED, _run.keys, _run.stats.slip_cost_cut)
			chest.woke.connect(_wake_mimic)
		_:
			chest.can_take = func(): return ChestRules.can_open(ChestRules.LOCKED, _run.keys, _run.stats.slip_cost_cut)
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
	if _spend_slips(ChestRules.slips_for(ChestRules.LOCKED, _run.stats.slip_cost_cut)):
		_create_treasure(cell)
		_pay_chest_condolences()


# Two Slips buy a pick of two items from the run's usual pool. Taking one clears the other away.
func _open_urn(cell: Vector2i) -> void:
	if not _spend_slips(ChestRules.slips_for(ChestRules.URN, _run.stats.slip_cost_cut)):
		return
	var picked := RoomRules.pick_items(Content.items(), _run, ChestRules.URN_CHOICES, _rng, ItemRarity.URN)
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
		pickup.get_meta(KEEP)["group"] = "urn%d" % _urn_groups.size()
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
	var picked := RoomRules.pick_items(Content.items(), _run, cells.size(), _rng, _item_source())
	var choices: Array[Pickup] = []
	for i in picked.size():
		var item := picked[i]
		var choice := _add_item_pickup(RoomBackdrop.cell_center(cells[i]), item)
		choices.append(choice)
	for choice in choices:
		choice.collected.connect(func(): _remove_others(choices, choice))
		choice.get_meta(KEEP)["group"] = "room"
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
	_add_recipe_pickup(RoomBackdrop.cell_center(cell), item)
	return true


func _add_recipe_pickup(at: Vector2, item: ItemDef) -> Pickup:
	var pickup := _add_pickup(at, "Recipe: %s" % item.display_name, RECIPE_COLOR, func(): _take_recipe(item), true, "slip_pickup")
	pickup.art_id = ART_RECIPE
	pickup.prompt = RECIPE_PROMPT
	pickup.set_meta(KEEP, {"kind": KEEP_RECIPE, "id": item.id})
	return pickup


func _take_recipe(item: ItemDef) -> void:
	_bank.find_recipe(item.id)
	consumable_taken.emit()
	notice.emit("Recipe found: %s. Take it to the Waiting Room." % item.display_name)


func _create_treasure(cell: Vector2i) -> void:
	if _rng.randf() < RoomRules.TREASURE_RECIPE_CHANCE and _drop_recipe(RoomBackdrop.cell_center(cell)):
		return
	var picked := RoomRules.pick_items(Content.items(), _run, 1, _rng, _item_source(true))
	if picked.is_empty() or _rng.randf() < 0.5:

		_drop_coin(RoomBackdrop.cell_center(cell), _floor_def.treasure_pension, RunState.PENSION_REWARD)
		return
	_add_item_pickup(RoomBackdrop.cell_center(cell), picked[0])


# A left-behind item may be found again elsewhere before the player returns for it.
# Its pedestal shows its rarity's colour, and its name that colour too, or purple with a skull when it
# is cursed.
func _add_item_pickup(at: Vector2, item: ItemDef) -> Pickup:
	var pickup := _add_pickup(at, item.display_name, ItemRarity.color_of(item.rarity), func(): _run.add_item(item), true, "item_fanfare")
	pickup.can_take = func(): return not _run.has_item(item.id)
	pickup.set_meta(KEEP, {"kind": KEEP_ITEM, "id": item.id})
	_mark_item(pickup, item)
	return pickup


# A swapped-out active, a cell beside him, waiting to be taken back with the charge it had.
func drop_active(item: ItemDef, charge: int, at: Vector2) -> Pickup:
	var spot := clear_spot(at + Vector2(RoomBackdrop.TILE, 0))
	var pickup := _add_pickup(spot, item.display_name, ItemRarity.color_of(item.rarity), func(): _run.add_item(item, charge), true, "item_fanfare")
	pickup.can_take = func(): return not _run.has_item(item.id)
	pickup.set_meta(KEEP, {"kind": KEEP_ITEM, "id": item.id, "charge": charge})
	_mark_item(pickup, item)
	return pickup


func _mark_item(pickup: Pickup, item: ItemDef) -> void:
	pickup.label_color = ItemRarity.name_color(item)
	pickup.skull = item.cursed
	pickup.icon_id = item.id


# Which rarity table this room's item rewards roll on: a vault's, a treasure room's, else an item
# room's. A treasure chest anywhere rolls at least as a treasure room does.
func _item_source(treasure := false) -> String:
	if _room.room_type == RoomLayout.TYPE_VAULT:
		return ItemRarity.VAULT
	if treasure or _room.room_type == RoomLayout.TYPE_TREASURE:
		return ItemRarity.TREASURE
	return ItemRarity.ITEM_ROOM


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
	if _had_enemies:
		_run.effects.room_clear(self)
	if _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_SIDE]:
		pension_earned.emit(_run.pension_amount(_floor_def.clear_pension))
	if _had_enemies and _room.room_type in [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_SIDE]:
		_drop_consumable(_last_death_at, RoomRules.clear_drop(_rng.randf()))
	if _room.room_type == RoomLayout.TYPE_FLOOR_BOSS:
		floor_cleared.emit()
	finished.emit()


func is_finished() -> bool:
	return _finished


# What the run checkpoint keeps of this room: whether it was cleared, and the items, stock, recipes and
# closed chests still waiting in it, each on its cell. Loose coins, heals and consumables are left out.
func snapshot() -> Dictionary:
	var keep := []
	for child in get_children():
		if not child.has_meta(KEEP) or child.is_queued_for_deletion():
			continue
		if child is Chest and child.is_open():
			continue
		var entry: Dictionary = child.get_meta(KEEP).duplicate()
		var cell := _cell_of(child.position)
		entry["cell"] = [cell.x, cell.y]
		keep.append(entry)
	var shot := {"cleared": _finished, "keep": keep}
	if _room.room_type == RoomLayout.TYPE_SHOP:
		shot["purchases"] = shop_purchases
	return shot


# The cells of a snapshot's wares that lie off the shop's own S cells (a Ticket Stub Book's extra ware),
# so a resumed shop's plan rewards keep clear of them as they did before.
static func restored_extra_cells(layout: RoomLayout, shot: Dictionary) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var wares := layout.cells_of("S")
	for entry in shot.get("keep", []):
		if not entry is Dictionary or str(entry.get("kind", "")) != KEEP_SHOP:
			continue
		var raw: Array = entry.get("cell", [0, 0])
		var cell := Vector2i(int(raw[0]), int(raw[1]))
		if not wares.has(cell):
			cells.append(cell)
	return cells


# Builds a cleared room again from its snapshot. The floor scene only restores rooms that were cleared.
func _restore_contents() -> void:
	if _room.room_type == RoomLayout.TYPE_SHOP:
		_create_shop_keeper(restored_extra_cells(_room.layout, restore))
		shop_purchases = int(restore.get("purchases", 0))
	if _room.room_type == RoomLayout.TYPE_ARCADE:
		_create_arcade()
	for entry: Dictionary in restore.get("keep", []):
		_restore_entry(entry)
	_finished = true
	for door in _doors:
		door.locked = false


func _restore_entry(entry: Dictionary) -> void:
	var raw_cell: Array = entry.get("cell", [0, 0])
	var cell := Vector2i(int(raw_cell[0]), int(raw_cell[1]))
	var at := RoomBackdrop.cell_center(cell)
	var item := _item_by_id(str(entry.get("id", "")))
	match str(entry.get("kind", "")):
		KEEP_ITEM, KEEP_FREE:
			if item == null:
				return
			if entry.has("charge") and item.is_active():
				drop_active(item, int(entry["charge"]), at - Vector2(RoomBackdrop.TILE, 0))
				return
			var pickup := _add_free_item(at, item) if entry["kind"] == KEEP_FREE else _add_item_pickup(at, item)
			var group_id := str(entry.get("group", ""))
			if group_id.is_empty():
				return
			pickup.get_meta(KEEP)["group"] = group_id
			if not _restored_groups.has(group_id):
				_restored_groups[group_id] = ChoiceGroup.new()
			var group: ChoiceGroup = _restored_groups[group_id]
			group.add(pickup)
			pickup.collected.connect(group.take.bind(pickup))
			if group_id == "boss":
				_choice_cells.append(cell)
		KEEP_SHOP:
			var kind := str(entry.get("shop", ""))
			if kind == ShopRules.KIND_ITEM and item == null:
				return
			var shop_potion: PotionDef = null
			if kind == ShopRules.KIND_POTION:
				shop_potion = Content.potion(str(entry.get("id", "")))
				if shop_potion == null:
					return
			_add_shop_entry(at, {"kind": kind, "price": int(entry.get("price", 0)), "item": item,
					"potion": shop_potion, "half": bool(entry.get("half", false))})
		KEEP_RECIPE:
			if item != null:
				_add_recipe_pickup(at, item)
		KEEP_CHEST:
			var kind := str(entry.get("chest", ""))
			if kind == ChestRules.MIMIC and _floor_def.mimic == null:
				return
			_create_chest(cell, kind)


func _item_by_id(id: String) -> ItemDef:
	if id.is_empty():
		return null
	for item in Content.items():
		if item.id == id:
			return item
	return null


# Head Office: red tape strung across lanes, each cell running the way its strand runs, water
# coolers that break like barrels, cubicle walls that break like furniture and can hide a coin, and
# in-trays that break to anything.
func _create_office_props(layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_RED_TAPE):
		var tape := RedTape.new()
		tape.across = RedTape.runs_across(layout, cell)
		tape.position = RoomBackdrop.cell_center(cell)
		add_child(tape)
	for cell in layout.cells_of(RoomLayout.SYMBOL_WATER_COOLER):
		var cooler := WaterCooler.new()
		cooler.palette = palette
		_place_prop(cooler, cell)
		cooler.broken.connect(_on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_CUBICLE):
		var partition := CubicleWall.new()
		partition.palette = palette
		partition.hides_coin = RoomRules.furniture_hides_coin(_prop_coin_roll())
		_place_prop(partition, cell)
		partition.broken.connect(_on_rock_broken.bind(partition.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_IN_TRAY):
		var tray := InTray.new()
		tray.palette = palette
		_place_prop(tray, cell)
		tray.broken.connect(_on_vase_broken.bind(cell))
