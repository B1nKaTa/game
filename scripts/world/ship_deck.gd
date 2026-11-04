class_name ShipDeck
extends Node2D

# The rolling deck of one room on the cruise. Every nine seconds or so the ship's horn sounds and a big
# arrow shows the side, then for two seconds everyone on the deck slides that way: Grandpa, every
# walker and every loose pickup. It never hurts anyone. A dodge holds Grandpa where he is, a running
# charge holds its lane, and bosses never slide. The deck beside each door stays steady, so nobody is
# ever carried through a door or arrives sliding. A floor boss can order a harder roll, which sounds
# its own horn first, as the ship's roll does. The deck lies at the room's origin and draws its warning
# high above the room, over the dark and every prop.
const GROUP := "ship_decks"
# Within this far of a door cell's middle the deck holds steady.
const DOOR_CALM := 80.0
# The arrow stands this far above Grandpa's feet, so it is on screen wherever he is.
const ARROW_ABOVE := 62.0
const ARROW_LENGTH := 44.0
const ARROW_WIDTH := 26.0
const HORN_TEXT := "HOOONK!"
const CHEVRON_EVERY := 4
const CHEVRON_SIZE := 7.0
const ARROW := Color("fff6d8")
const ARROW_EDGE := Color("1b2a3a")
const ARROW_HARD := Color("ff9a3c")
const CHEVRON := Color(1.0, 0.96, 0.85, 0.3)

var _layout: RoomLayout
var _player: Node2D
var _clear_spot: Callable
var _seed := 0
var _roll := ShipRoll.new()
var _time := 0.0
var _crawl := 0.0
# A boss's order: its own horn, then a harder slide that way.
var _forced_side := Vector2.ZERO
var _forced_horn := 0.0
var _was_warning := false
var _forced_left := 0.0
var _forced_speed := 0.0
var _forced_horn_time := 1.0


# What the decks under a point add to a walk there, from a list of decks, so tests need no tree.
static func slide_from(decks: Array, point: Vector2) -> Vector2:
	var total := Vector2.ZERO
	for deck in decks:
		if is_instance_valid(deck):
			total += deck.slide_at_point(point)
	return total


static func slide_at(tree: SceneTree, point: Vector2) -> Vector2:
	if tree == null:
		return Vector2.ZERO
	return slide_from(tree.get_nodes_in_group(GROUP), point)


# Every rolling deck in the room, so a boss can order a harder roll.
static func decks_in(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(GROUP) if tree != null else []


# The layout's door cells keep the deck steady, the seed sets when and which way it rolls, and
# clear_spot, when given, says where a sliding pickup may come to rest: a spot it returns unchanged.
func setup(layout: RoomLayout, seed_value: int, clear_spot := Callable(), player: Node2D = null) -> void:
	_layout = layout
	_seed = seed_value
	_clear_spot = clear_spot
	_player = player
	_roll = ShipRoll.new(ShipRoll.PERIOD, ShipRoll.HORN_TIME, ShipRoll.SLIDE_TIME, fposmod(float(seed_value) * 0.37, ShipRoll.PERIOD))


func _ready() -> void:
	add_to_group(GROUP)
	z_index = Enemy.WARNING_Z


func _physics_process(delta: float) -> void:
	advance(delta)
	var warning := is_warning()
	if warning and not _was_warning:
		Sfx.play("ship_horn")
	_was_warning = warning
	_slide_pickups(delta)
	queue_redraw()


# Moves the deck's own clock on, and a boss's order with it.
func advance(delta: float) -> void:
	_time += delta
	if _forced_left > 0.0:
		_forced_left = maxf(_forced_left - delta, 0.0)
		_forced_horn = maxf(_forced_horn - delta, 0.0)
	var current := slide()
	if not current.is_zero_approx():
		_crawl = fposmod(_crawl + current.length() * delta, float(RoomBackdrop.TILE * CHEVRON_EVERY))


# A boss's order: the horn sounds for `horn` seconds, then everyone slides `side` at `speed` for
# `seconds`. While it runs it stands in for the ship's own roll.
func force_roll(side: Vector2, horn: float, seconds: float, speed: float) -> void:
	_forced_side = side.normalized() if not side.is_zero_approx() else Vector2.LEFT
	_forced_horn = maxf(horn, 0.0)
	_forced_horn_time = maxf(horn, 0.01)
	_forced_left = _forced_horn + maxf(seconds, 0.0)
	_forced_speed = speed


func is_forced() -> bool:
	return _forced_left > 0.0


func state() -> int:
	if _forced_left > 0.0:
		return ShipRoll.HORN if _forced_horn > 0.0 else ShipRoll.SLIDE
	return _roll.state_at(_time)


func is_warning() -> bool:
	return state() == ShipRoll.HORN


func side() -> Vector2:
	if _forced_left > 0.0:
		return _forced_side
	return ShipRoll.side_for(_roll.roll_index(_time), _seed)


func speed() -> float:
	return _forced_speed if _forced_left > 0.0 else ShipRoll.SPEED


# How far the horn's warning has filled, from 0 to 1.
func horn_progress() -> float:
	if _forced_left > 0.0:
		return clampf(1.0 - _forced_horn / _forced_horn_time, 0.0, 1.0) if _forced_horn > 0.0 else 0.0
	return _roll.horn_progress(_time)


func slide() -> Vector2:
	return ShipRoll.slide_velocity(state(), side(), speed())


# What the deck adds to a walk at a point in the room, which is nothing beside a door.
func slide_at_point(point: Vector2) -> Vector2:
	var current := slide()
	if current.is_zero_approx() or near_a_door(point):
		return Vector2.ZERO
	return current


func near_a_door(point: Vector2) -> bool:
	if _layout == null:
		return false
	var local := point - position
	for door_side in RoomLayout.SIDES:
		if local.distance_to(RoomBackdrop.cell_center(_layout.door_cell(door_side))) < DOOR_CALM:
			return true
	return false


# Whether a sliding pickup may come to rest at a point: open floor, and never on or beside a door
# cell, since Grandpa arrives standing on a door and would take it unseen.
func pickup_can_rest(point: Vector2) -> bool:
	if _layout == null:
		return true
	var cell := Vector2i(floori(point.x / RoomBackdrop.TILE), floori(point.y / RoomBackdrop.TILE))
	if _layout.touches_a_door(cell):
		return false
	if _clear_spot.is_valid():
		var spot: Vector2 = _clear_spot.call(point)
		return spot.is_equal_approx(point)
	return not _layout.is_solid_at(cell)


# Coins, Slips and the like that lie loose slide too. A chest, a ware for sale or a coin already flying
# to Grandpa stays where it is.
func _slide_pickups(delta: float) -> void:
	var current := slide()
	if current.is_zero_approx() or get_parent() == null:
		return
	for child in get_parent().get_children():
		var pickup := child as Pickup
		if pickup == null or pickup is Chest or pickup.requires_interact or pickup.is_flying() or pickup.is_queued_for_deletion():
			continue
		var next := pickup.position + current * delta
		if pickup_can_rest(next):
			pickup.position = next


func _draw() -> void:
	var now := state()
	if now == ShipRoll.QUIET or _layout == null:
		return
	var way := side()
	var hard := is_forced()
	_draw_chevrons(way, now == ShipRoll.SLIDE)
	if not is_instance_valid(_player):
		return
	var feet: Vector2 = _player.feet().global_position if _player.has_method("feet") else _player.global_position
	var at := feet - position + Vector2(0.0, -ARROW_ABOVE)
	var grow := 1.0
	if now == ShipRoll.HORN:
		grow = 0.8 + 0.2 * horn_progress() + 0.08 * sin(_time * 18.0)
	_draw_arrow(at, way, grow * (1.25 if hard else 1.0), ARROW_HARD if hard else ARROW)
	if now == ShipRoll.HORN:
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(HORN_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var text_at := at + Vector2(-width / 2.0, -ARROW_WIDTH * 0.75)
		draw_string_outline(font, text_at, HORN_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 4, ARROW_EDGE)
		draw_string(font, text_at, HORN_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ARROW_HARD if hard else ARROW)


# A big block arrow pointing the way the deck tips, outlined dark so it reads on the palest planks.
func _draw_arrow(at: Vector2, way: Vector2, scale_by: float, color: Color) -> void:
	var length := ARROW_LENGTH * scale_by
	var width := ARROW_WIDTH * scale_by
	var shape := PackedVector2Array([
		Vector2(-length / 2.0, -width * 0.2), Vector2(length * 0.1, -width * 0.2), Vector2(length * 0.1, -width / 2.0),
		Vector2(length / 2.0, 0.0),
		Vector2(length * 0.1, width / 2.0), Vector2(length * 0.1, width * 0.2), Vector2(-length / 2.0, width * 0.2)])
	draw_set_transform(at, way.angle())
	draw_colored_polygon(shape, color)
	draw_polyline(shape + PackedVector2Array([shape[0]]), ARROW_EDGE, 3.0)
	draw_set_transform(Vector2.ZERO)


# Faint chevrons across the whole deck, still while the horn sounds and drifting with the slide.
func _draw_chevrons(way: Vector2, moving: bool) -> void:
	var size := _layout.size_in_cells()
	var tile := float(RoomBackdrop.TILE)
	var shift := (_crawl if moving else 0.0) * signf(way.x)
	for row in range(2, size.y - 1, CHEVRON_EVERY):
		for column in range(1, size.x, CHEVRON_EVERY):
			var x := fposmod(column * tile + shift, size.x * tile)
			if x < tile or x > (size.x - 1) * tile:
				continue
			var at := Vector2(x, row * tile + tile / 2.0)
			var tip := at + way * CHEVRON_SIZE
			var back := at - way * CHEVRON_SIZE
			var across := way.orthogonal() * CHEVRON_SIZE
			draw_polyline(PackedVector2Array([back + across, tip, back - across]), CHEVRON, 2.0)
