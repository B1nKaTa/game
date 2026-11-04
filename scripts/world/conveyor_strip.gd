class_name ConveyorStrip
extends Area2D

# One cell of an escalator strip laid flat in the mall's floor. It carries Grandpa and enemies along
# its way, with moving arrows that show which way that is. In some rooms the strips reverse every few
# seconds, after a chime and flashing arrows, and a floor boss can reverse them or speed them up, again
# only after a chime. The strip never hurts anyone, and a dodge, a ghost or a mound ignores it.
# Whether a point is on a strip is a plain rectangle test, as for a wet floor.
const GROUP := "conveyor_strips"
const PERIOD := 6.0
const CHIME := 1.0
const BOOST := 1.5
const BOOST_TIME := 4.0
const ARROW_SPACING := 12.0
const FLASH_EVERY := 0.16
const BELT := Color("2b2d33")
const BELT_RIB := Color("3c3f47")
const RAIL := Color("a9b2bd")
const ARROW := Color("7fd6c8")
const ARROW_FLASH := Color("ffe46b")

enum { REVERSE, SPEED_UP }

var _way := Vector2.RIGHT
var _reverses := false
var _cycle := ConveyorCycle.new(PERIOD, CHIME)
var _time := 0.0
var _flip := 1
var _boost_left := 0.0
var _pending := -1
var _pending_left := 0.0
var _crawl := 0.0
var _was_chiming := false


# What the strip under a point adds to a walk there, from a list of strips, so tests need no tree.
static func carry_from(strips: Array, point: Vector2) -> Vector2:
	for strip in strips:
		if is_instance_valid(strip) and strip.covers(point):
			return strip.carry()
	return Vector2.ZERO


static func carry_at(tree: SceneTree, point: Vector2) -> Vector2:
	if tree == null:
		return Vector2.ZERO
	return carry_from(tree.get_nodes_in_group(GROUP), point)


# Every strip in a room, so a boss can take them over at once.
static func strips_in(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(GROUP) if tree != null else []


func setup(way: Vector2, reverses: bool) -> void:
	_way = way.normalized() if not way.is_zero_approx() else Vector2.RIGHT
	_reverses = reverses


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)
	shape.shape = rect
	add_child(shape)
	z_index = -9


func _physics_process(delta: float) -> void:
	advance(delta)
	var chiming := is_chiming()
	if chiming and not _was_chiming:
		Sfx.play("escalator_hum")
	_was_chiming = chiming
	queue_redraw()


# Moves the strip's own clock on, and any boss order with it.
func advance(delta: float) -> void:
	_time += delta
	_crawl = fposmod(_crawl + speed() * delta * float(_running_sign()), ARROW_SPACING)
	_boost_left = maxf(_boost_left - delta, 0.0)
	if _pending_left > 0.0:
		_pending_left -= delta
		if _pending_left <= 0.0:
			_apply(_pending)
			_pending = -1


# A boss's order: the strips chime first, then reverse or speed up.
func take_control(kind: int) -> void:
	_pending = kind
	_pending_left = CHIME


func _apply(kind: int) -> void:
	match kind:
		REVERSE:
			_flip = -_flip
		SPEED_UP:
			_boost_left = BOOST_TIME


func _running_sign() -> int:
	return _flip * (_cycle.direction_sign_at(_time) if _reverses else 1)


func direction() -> Vector2:
	return _way * _running_sign()


func speed() -> float:
	return ConveyorRule.SPEED * (BOOST if _boost_left > 0.0 else 1.0)


func is_chiming() -> bool:
	return _pending_left > 0.0 or (_reverses and _cycle.is_chiming(_time))


func is_boosted() -> bool:
	return _boost_left > 0.0


func carry() -> Vector2:
	return ConveyorRule.carry(direction(), speed())


func covers(point: Vector2) -> bool:
	var half := RoomBackdrop.TILE / 2.0
	return Rect2(global_position - Vector2(half, half), Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)).has_point(point)


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	draw_rect(Rect2(-half, -half, RoomBackdrop.TILE, RoomBackdrop.TILE), BELT)
	# Drawn as if the strip ran right, then turned to its way.
	draw_set_transform(Vector2.ZERO, direction().angle())
	for i in 5:
		var x := -half + fposmod(_crawl + i * 7.0, RoomBackdrop.TILE)
		draw_line(Vector2(x, -half + 3.0), Vector2(x, half - 3.0), BELT_RIB, 1.0)
	draw_line(Vector2(-half, -half + 1.0), Vector2(half, -half + 1.0), RAIL, 2.0)
	draw_line(Vector2(-half, half - 1.0), Vector2(half, half - 1.0), RAIL, 2.0)
	var flashing := is_chiming() and posmod(floori(_time / FLASH_EVERY), 2) == 0
	var color := ARROW_FLASH if flashing else ARROW
	if is_boosted():
		color = color.lightened(0.3)
	var count := int(RoomBackdrop.TILE / ARROW_SPACING) + 1
	for i in count:
		var x := -half + fposmod(_crawl + i * ARROW_SPACING, RoomBackdrop.TILE)
		if x > half - 5.0:
			continue
		draw_polyline(PackedVector2Array([Vector2(x, -6.0), Vector2(x + 5.0, 0.0), Vector2(x, 6.0)]), color, 2.0)
	draw_set_transform(Vector2.ZERO)
