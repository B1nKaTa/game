class_name RedTape
extends Node2D

# One cell of red tape strung across a Head Office lane: a red band with white diagonal hatching and a
# dark edge, a shape no floor pattern uses. Walking into it holds Grandpa for a moment (RedTapeRule),
# a dodge cuts it, and cut tape hangs slack until it is strung again CUT_TIME later. Enemies ignore it,
# and it never hurts. Whether a point is on tape is a plain rectangle test, as for a wet floor.
const GROUP := "red_tape"
const BAND := Color("d0212e")
const BAND_EDGE := Color("4a0910")
const HATCH := Color("fbf3e6")
const SLACK := Color(0.82, 0.13, 0.18, 0.55)
const WARN := Color("e4524f")
const BAND_WIDTH := 8.0
const HATCH_EVERY := 6.0
# The strung band's picture (art/props/red_tape.png, one cell along x, BAND_WIDTH tall), turned a
# quarter for a tape that runs down; the drawing stays for when it is missing.
const ART := "red_tape"
const HOLD_LOOPS := Color("d0212e")
const HOLD_RADIUS := 13.0
# The loop is seen at a slant, flattened like the ring a sedative leaves at his feet.
const HOLD_SQUASH := 0.45

# Strung left to right when true, top to bottom when false.
var across := true
var _cut_left := 0.0
# Tape laid by an attack is only a warning until it is strung. Tape a layout places starts strung.
var _strung := true
var _age := 0.0


# Whether any strung, uncut tape in a list covers a point, so tests need no scene tree.
static func any_holds(tapes: Array, point: Vector2) -> bool:
	for tape in tapes:
		if is_instance_valid(tape) and tape.holds_at(point):
			return true
	return false


# What Grandpa's feet meet this frame. Dodging through tape cuts every cell under them and is never
# held, so it says false. Walking, it says whether strung, uncut tape is under them.
static func touch_among(tapes: Array, point: Vector2, dodging: bool) -> bool:
	var found := false
	for tape in tapes:
		if not is_instance_valid(tape) or not tape.holds_at(point):
			continue
		if dodging:
			tape.cut()
		else:
			found = true
	return found


static func touch(tree: SceneTree, point: Vector2, dodging: bool) -> bool:
	if tree == null:
		return false
	return touch_among(tree.get_nodes_in_group(GROUP), point, dodging)


# Which way a layout's tape cell runs: along its row when a neighbour on the row is tape too, or when
# it stands alone, and down its column when only the cells above or below are tape.
static func runs_across(layout: RoomLayout, cell: Vector2i) -> bool:
	var symbol := RoomLayout.SYMBOL_RED_TAPE
	if layout.symbol_at(cell + Vector2i.LEFT) == symbol or layout.symbol_at(cell + Vector2i.RIGHT) == symbol:
		return true
	return not (layout.symbol_at(cell + Vector2i.UP) == symbol or layout.symbol_at(cell + Vector2i.DOWN) == symbol)


# A loop of tape round his ankles while he is held, drawn by whoever is held. It is wider than his
# legs, which are drawn over it, with a dark rim and pale hatching, so it shows over the red band he
# stands on.
static func draw_hold(canvas: CanvasItem, at: Vector2) -> void:
	canvas.draw_set_transform(at, 0.0, Vector2(1.0, HOLD_SQUASH))
	canvas.draw_arc(Vector2.ZERO, HOLD_RADIUS, 0.0, TAU, 24, BAND_EDGE, 5.0)
	canvas.draw_arc(Vector2.ZERO, HOLD_RADIUS, 0.0, TAU, 24, HOLD_LOOPS, 3.0)
	for i in 8:
		var angle := TAU * i / 8.0
		canvas.draw_line(Vector2.from_angle(angle) * (HOLD_RADIUS - 1.0), Vector2.from_angle(angle + 0.25) * (HOLD_RADIUS + 1.0), HATCH, 1.0)
	canvas.draw_set_transform(Vector2.ZERO)


func _ready() -> void:
	add_to_group(GROUP)
	# Above the floor and its scatter, under props and everyone standing on it.
	z_index = -8
	queue_redraw()


func covers(point: Vector2) -> bool:
	var half := RoomBackdrop.TILE / 2.0
	return Rect2(global_position - Vector2(half, half), Vector2(RoomBackdrop.TILE, RoomBackdrop.TILE)).has_point(point)


func holds_at(point: Vector2) -> bool:
	return _strung and _cut_left <= 0.0 and covers(point)


func is_cut() -> bool:
	return _cut_left > 0.0


func cut_left() -> float:
	return _cut_left


func cut() -> void:
	if _cut_left <= 0.0:
		Sfx.play("tape_cut")
	_cut_left = RedTapeRule.CUT_TIME
	queue_redraw()


func is_strung() -> bool:
	return _strung


func set_strung(value: bool) -> void:
	_strung = value
	queue_redraw()


# Moves the cut's clock on. True once, on the moment cut tape is strung again.
func advance(delta: float) -> bool:
	_age += delta
	if _cut_left <= 0.0:
		return false
	_cut_left = RedTapeRule.cut_left_after(_cut_left, delta)
	return _cut_left <= 0.0


func _physics_process(delta: float) -> void:
	var restrung := advance(delta)
	if restrung or not _strung:
		queue_redraw()


func _draw() -> void:
	var half := RoomBackdrop.TILE / 2.0
	if not across:
		draw_set_transform(Vector2.ZERO, PI / 2.0)
	if not _strung:
		# Laid by an attack and not yet strung: a red outline of the band, filling as it comes.
		# Only the Chairman lays it, so it follows the setting itself (AttackWarnings): otherwise a faint
		# dark band, pulsing.
		var pulse := 0.5 + 0.5 * sin(_age * 10.0)
		if AttackWarnings.shown:
			draw_rect(Rect2(-half, -BAND_WIDTH / 2.0, RoomBackdrop.TILE, BAND_WIDTH), Color(WARN, 0.15 + 0.25 * pulse))
			draw_rect(Rect2(-half, -BAND_WIDTH / 2.0, RoomBackdrop.TILE, BAND_WIDTH), WARN, false, 1.0)
		else:
			AttackWarnings.draw_cue_lane(self, Rect2(-half, -BAND_WIDTH / 2.0, RoomBackdrop.TILE, BAND_WIDTH), 0.8 + 0.2 * pulse)
		draw_set_transform(Vector2.ZERO)
		return
	if _cut_left > 0.0:
		# Two slack ends hang down from where it was cut.
		draw_line(Vector2(-half, 0.0), Vector2(-5.0, 5.0), SLACK, 3.0)
		draw_line(Vector2(half, 0.0), Vector2(5.0, 6.0), SLACK, 3.0)
		draw_set_transform(Vector2.ZERO)
		return
	var art := PropArt.texture(ART)
	if art != null:
		draw_texture(art, PropArt.centred(art))
		draw_set_transform(Vector2.ZERO)
		return
	var band := Rect2(-half, -BAND_WIDTH / 2.0, RoomBackdrop.TILE, BAND_WIDTH)
	draw_rect(band, BAND)
	var x := -half + 1.0
	while x < half - 2.0:
		draw_line(Vector2(x, BAND_WIDTH / 2.0 - 1.0), Vector2(x + 4.0, -BAND_WIDTH / 2.0 + 1.0), HATCH, 2.0)
		x += HATCH_EVERY
	draw_line(Vector2(-half, -BAND_WIDTH / 2.0), Vector2(half, -BAND_WIDTH / 2.0), BAND_EDGE, 1.0)
	draw_line(Vector2(-half, BAND_WIDTH / 2.0), Vector2(half, BAND_WIDTH / 2.0), BAND_EDGE, 1.0)
	draw_set_transform(Vector2.ZERO)
