class_name QueueBarrier
extends Node2D

# One cell of a queue barrier line in the departure hall. Down, it is a taped line on the carpet with
# the bases of its posts. On the room's timer it chimes, its line flashes, and then the posts rise
# with a rope between them. While up it blocks Grandpa and his thrown dentures only: its body sits on
# LAYER, which only they test, so enemies and their shots pass under the rope ("staff duck under it")
# and the walk grid never changes. A rope rising under Grandpa pushes him to the nearest free side and
# never hurts. A floor boss can raise or drop every barrier at once, after the same chime.
const GROUP := "queue_barriers"
# Grandpa's collision mask and the dentures' wall test include this layer. Nothing else does.
const LAYER := 16
const PERIOD := 10.0
const UP_TIME := 3.0
const CHIME := 1.0
# A floor boss's gate change holds every rope where it put it this long, then the room's timer
# starts again from the beginning, down, so the next rise always chimes first.
const GATE_HOLD := 5.0
# The rope's body is thinner than a cell, so standing beside it on the same cell is fine.
const ROPE_THICKNESS := 10.0
const FLASH_EVERY := 0.15
const TAPE := Color("e8c04a")
const TAPE_FLASH := Color("fff6d8")
const POST := Color("c9cdd6")
const POST_EDGE := Color("3c4048")
const ROPE := Color("c4161c")
const ROPE_EDGE := Color("4a0a0e")
const GLOW := Color(1.0, 0.95, 0.6, 0.35)

enum { RISE, DROP }

var _cell := Vector2i.ZERO
var _across := true
var _before_open := true
var _after_open := true
var _cycle := BarrierCycle.new(PERIOD, UP_TIME, CHIME)
var _time := 0.0
var _pending := -1
var _pending_left := 0.0
var _forced := -1
var _forced_left := 0.0
var _was_up := false
var _was_chiming := false
var _body: StaticBody2D


static func barriers_in(tree: SceneTree) -> Array:
	return tree.get_nodes_in_group(GROUP) if tree != null else []


# The rope's body around a cell's middle, as a rectangle in the room.
static func rope_rect(center: Vector2, across: bool) -> Rect2:
	var size := Vector2(RoomBackdrop.TILE, ROPE_THICKNESS) if across else Vector2(ROPE_THICKNESS, RoomBackdrop.TILE)
	return Rect2(center - size / 2.0, size)


# before_open and after_open say whether Grandpa may be pushed to the cell above (or left of) it and
# below (or right of) it.
func setup(cell: Vector2i, across: bool, before_open := true, after_open := true) -> void:
	_cell = cell
	_across = across
	_before_open = before_open
	_after_open = after_open


func _ready() -> void:
	add_to_group(GROUP)
	z_index = -8
	_body = StaticBody2D.new()
	_body.collision_layer = 0
	_body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = rope_rect(Vector2.ZERO, _across).size
	shape.shape = rect
	_body.add_child(shape)
	add_child(_body)
	_set_solid(is_up())


func _physics_process(delta: float) -> void:
	advance(delta)
	var chiming := is_chiming()
	if chiming and not _was_chiming:
		Sfx.play("barrier_chime")
	_was_chiming = chiming
	queue_redraw()


# Moves the barrier's own clock on, and any boss order with it.
func advance(delta: float) -> void:
	_time += delta
	if _pending_left > 0.0:
		_pending_left -= delta
		if _pending_left <= 0.0:
			_forced = _pending
			_forced_left = GATE_HOLD
			_pending = -1
	elif _forced_left > 0.0:
		_forced_left -= delta
		if _forced_left <= 0.0:
			_forced = -1
			_time = 0.0
	var up := is_up()
	if up != _was_up:
		_was_up = up
		_set_solid(up)
		if up:
			_push_grandpa_clear()


# A floor boss's gate change: the barrier chimes first, then rises or drops and holds there a while.
func take_control(kind: int) -> void:
	_pending = kind
	_pending_left = CHIME


# The second phase of a floor boss: the room's timer runs twice as fast, chime kept whole. It starts
# again down, so the change never raises a rope unwarned.
func cycle_faster(times: float) -> void:
	_cycle = BarrierCycle.faster(BarrierCycle.new(PERIOD, UP_TIME, CHIME), times)
	if _forced < 0:
		_time = 0.0


func cycle() -> BarrierCycle:
	return _cycle


func is_up() -> bool:
	if _forced >= 0:
		return _forced == RISE
	return _cycle.is_up_at(_time)


func is_chiming() -> bool:
	return _pending_left > 0.0 or (_forced < 0 and _cycle.is_chiming(_time))


func is_held() -> bool:
	return _forced >= 0


func runs_across() -> bool:
	return _across


func cell() -> Vector2i:
	return _cell


func _set_solid(up: bool) -> void:
	if _body != null:
		_body.collision_layer = LAYER if up else 0


# A rope rising under his feet moves him just clear of it, to the open side nearer his feet.
func _push_grandpa_clear() -> void:
	if not is_inside_tree():
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.feet() == null:
		return
	var feet := Rect2(player.feet().global_position - Player.FEET_BOX_SIZE / 2.0, Player.FEET_BOX_SIZE)
	var shift := BarrierCycle.push_out(feet, rope_rect(global_position, _across), _across, _before_open, _after_open)
	if not shift.is_zero_approx():
		player.global_position += shift


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	var way := Vector2.RIGHT if _across else Vector2.DOWN
	var flashing := is_chiming() and posmod(floori(_time / FLASH_EVERY), 2) == 0
	if is_up():
		# Two chrome posts and a sagging red rope between them.
		var sag := Vector2(0.0, 3.0) if _across else Vector2(2.0, 0.0)
		draw_polyline(PackedVector2Array([-way * (half - 3.0), sag, way * (half - 3.0)]), ROPE_EDGE, 5.0)
		draw_polyline(PackedVector2Array([-way * (half - 3.0), sag, way * (half - 3.0)]), ROPE, 3.0)
		for end in [-1.0, 1.0]:
			var at: Vector2 = way * (half - 3.0) * end
			draw_circle(at, 4.0, POST_EDGE)
			draw_circle(at, 3.0, POST)
			draw_line(at, at + Vector2(0.0, -6.0), POST, 2.0)
			draw_circle(at + Vector2(0.0, -7.0), 2.0, POST)
		return
	# Down: a taped line between two post bases, flashing while it chimes.
	var tape := TAPE_FLASH if flashing else TAPE
	if flashing:
		draw_rect(rope_rect(Vector2.ZERO, _across).grow(3.0), GLOW)
	for dash in 3:
		var from := -way * half + way * (2.0 + dash * 10.0)
		draw_line(from, from + way * 6.0, tape, 3.0)
	for end in [-1.0, 1.0]:
		var at: Vector2 = way * (half - 3.0) * end
		draw_circle(at, 3.0, POST_EDGE)
		draw_arc(at, 3.0, 0.0, TAU, 10, tape if flashing else POST, 1.0)
