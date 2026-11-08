class_name TitleRoom
extends Node2D

# The title screen's waiting room: the afterlife's queue, lamp-lit and animated, drawn in layers in the
# depth look's style. The room is drawn in room pixels at 3x (ROOM_SCALE) so its people stand at the
# size of the approved concept; text that must be read (bubbles, the menu) is drawn by the view at 1x.
# Back to front: the wall and floor, the lamps' pools on the wall, the NOW SERVING board, the lamps, the
# TAKE 1 machine, the brass plaque, the chairs, Harold and the ghosts, the lamps' cones and dust, and a
# dark edge round the view. TitleRoom runs the room: whose turn it is to talk (GhostChatter), who
# fidgets, who changes seats, and the left lamp's flicker. It names no autoload; the title screen hands
# it Harold's look.

const ROOM_SCALE := 3.0
# The room's 216 px wall is 648 view px, so it sits 4 px left to centre on the 640 px view.
const OFFSET := Vector2(-4, 0)
const FLOOR_Y := 106.0
# The chairs along the back wall, by their middles; the gap at 93 is the machine's and the ticket
# strip's. The last chair stands half out of the view, so nobody sits in it (OPEN_SEATS).
const SEATS: Array[float] = [14.0, 44.0, 122.0, 152.0, 182.0, 210.0]
const HAROLD_SEAT := 4
const OPEN_SEATS: Array[int] = [0, 1, 2, 3]
const GHOST_SEATS: Array[int] = [0, 2, 3]
# The sitters' ids in seats: the ghosts by index, Harold after them.
const HAROLD_ID := 100
# Each chair's seat anchor stands on its seat line, CHAIR_FEET_ROW - CHAIR_SEAT_ROW over the floor.
const SEAT_Y := FLOOR_Y - (TitleFrames.CHAIR_FEET_ROW - TitleFrames.CHAIR_SEAT_ROW)
const GHOST_ART: Array[String] = ["ghost_a", "ghost_b", "ghost_a"]
const GHOST_TINTS: Array[Color] = [Color.WHITE, Color.WHITE, Color(0.86, 1.0, 0.9)]
const CHAIR_HALF := 20.0
const MACHINE_AT := Vector2(77, 42)
const BOARD_AT := Vector2(6, 32)
const PLAQUE_TOP := 3.0
# Each lamp: where its shade hangs (the art's top-left) and how wide its cone spreads at the floor.
const LAMPS: Array[Dictionary] = [
	{"at": Vector2(22, -4), "spread": 20.0},
	{"at": Vector2(170, -4), "spread": 30.0},
]
const BULB_IN_ART := Vector2(16, 23)
# The left lamp flickers; Harold's lamp only hums.
const FLICKER_LAMP := 0
const CHAT_MIN := 2.6
const CHAT_MAX := 4.8
const TALK_TIME := 2.6
const FIDGET_MIN := 3.0
const FIDGET_MAX := 6.0
const MOVE_MIN := 8.0
const MOVE_MAX := 13.0
const VIGNETTE_BANDS: Array[float] = [0.42, 0.28, 0.16, 0.07]

var serving := NowServing.new(TitleBrand.HAROLD_TICKET)
var seats := TitleSeats.new(TitleRoom.seat_anchors())
var chatter := GhostChatter.new()
var harold: TitleHarold
var ghosts: Array[TitleGhost] = []
var bubbles: Array[TitleBubble] = []
var _look: Dictionary = SeatedLook.describe({})
var _room: Node2D
var _back_light: TitleLights
var _front_light: TitleLights
var _board: TitleBoard
var _chat_wait := 1.2
var _fidget_wait := 2.0
var _move_wait := 6.0
var _flicker: Array[float] = []
var _flicker_wait := 3.0
var _time := 0.0
var _rng := RandomNumberGenerator.new()


static func to_view(room_point: Vector2) -> Vector2:
	return room_point * ROOM_SCALE + OFFSET


# Each chair's seat anchor, in room pixels: its middle across, on its seat line.
static func seat_anchors() -> Array[Vector2]:
	var anchors: Array[Vector2] = []
	for x in SEATS:
		anchors.append(Vector2(x, SEAT_Y))
	return anchors


# The machine's slot, where the ticket strip comes out, in room pixels.
static func slot() -> Vector2:
	return MACHINE_AT + Vector2(16, 37)


func set_look(seated: Dictionary) -> void:
	_look = seated
	if harold != null:
		harold.apply_look(seated)


func _ready() -> void:
	_rng.randomize()
	_room = Node2D.new()
	_room.scale = Vector2(ROOM_SCALE, ROOM_SCALE)
	_room.position = OFFSET
	_room.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_room)
	_add_sprite("wall", Vector2.ZERO)
	_back_light = _make_lights(false)
	_board = TitleBoard.new()
	_board.position = BOARD_AT
	_board.serving = serving
	_room.add_child(_board)
	for lamp in LAMPS:
		_add_sprite("lamp", lamp["at"])
	_add_sprite("machine", MACHINE_AT)
	var panel := Node2D.new()
	panel.position = MACHINE_AT
	panel.draw.connect(_draw_machine_panel.bind(panel))
	_room.add_child(panel)
	var plaque := TitlePlaque.new()
	plaque.position = Vector2(round(216.0 / 2.0), PLAQUE_TOP)
	plaque.chain_length = PLAQUE_TOP + 1.0
	_room.add_child(plaque)
	# The whole chair behind, its sitter over it, so nothing of the chair ever covers a sitter's legs or
	# Harold's cane.
	for x in SEATS:
		_add_sprite("chair", Vector2(x - CHAIR_HALF, FLOOR_Y - TitleFrames.CHAIR_FEET_ROW))
	harold = TitleHarold.new()
	seats.claim(HAROLD_SEAT, HAROLD_ID)
	harold.position = seats.anchors[HAROLD_SEAT]
	harold.look = _look
	_room.add_child(harold)
	for i in GHOST_SEATS.size():
		var ghost := TitleGhost.new()
		var art := GHOST_ART[i]
		ghost.setup(load("res://art/title/%s.png" % art), GHOST_TINTS[i], art)
		ghost.seat = GHOST_SEATS[i]
		seats.claim(ghost.seat, i)
		ghost.position = seats.anchors[ghost.seat]
		_room.add_child(ghost)
		ghosts.append(ghost)
	_front_light = _make_lights(true)
	var vignette := Node2D.new()
	vignette.draw.connect(_draw_vignette.bind(vignette))
	_room.add_child(vignette)
	for ghost in ghosts:
		var bubble := TitleBubble.new()
		bubble.visible = false
		add_child(bubble)
		bubbles.append(bubble)
	for i in LAMPS.size():
		_flicker.append(1.0)


func _add_sprite(art: String, at: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load("res://art/title/%s.png" % art)
	sprite.centered = false
	sprite.position = at
	_room.add_child(sprite)
	return sprite


func _make_lights(front: bool) -> TitleLights:
	var lights := TitleLights.new()
	lights.front = front
	for lamp in LAMPS:
		lights.lamps.append({"bulb": lamp["at"] + BULB_IN_ART, "spread": lamp["spread"], "floor": FLOOR_Y + 4.0})
	_room.add_child(lights)
	return lights


func _process(delta: float) -> void:
	_time += delta
	_update_flicker(delta)
	_chat_wait -= delta
	if _chat_wait <= 0.0:
		_chat_wait = _rng.randf_range(CHAT_MIN, CHAT_MAX) + TALK_TIME * 0.5
		_chat()
	_fidget_wait -= delta
	if _fidget_wait <= 0.0:
		_fidget_wait = _rng.randf_range(FIDGET_MIN, FIDGET_MAX)
		_fidget()
	_move_wait -= delta
	if _move_wait <= 0.0:
		_move_wait = _rng.randf_range(MOVE_MIN, MOVE_MAX)
		_move()
	for i in ghosts.size():
		bubbles[i].position = to_view(ghosts[i].head_top()).round()


func _chat() -> void:
	var able: Array[int] = []
	var seats := {}
	for i in ghosts.size():
		if ghosts[i].is_free() and not bubbles[i].visible:
			able.append(i)
			seats[i] = ghosts[i].position.x
	var speaker := chatter.pick_speaker(able)
	if speaker < 0:
		return
	var listener := GhostChatter.listener_for(speaker, seats)
	var toward := 0
	if listener >= 0:
		toward = 1 if ghosts[listener].position.x > ghosts[speaker].position.x else -1
		ghosts[listener].face(-toward)
	chatter.note_turn(speaker, listener)
	ghosts[speaker].talk(TALK_TIME, toward)
	bubbles[speaker].say(chatter.pick_line(), TALK_TIME)
	# The listener turns back to the front once the line is said.
	if listener >= 0:
		get_tree().create_timer(TALK_TIME + 0.8).timeout.connect(_face_front.bind(listener))


func _face_front(index: int) -> void:
	if index < ghosts.size() and ghosts[index].is_free():
		ghosts[index].face(0)


func _fidget() -> void:
	var free: Array[TitleGhost] = []
	for i in ghosts.size():
		if ghosts[i].is_free() and not bubbles[i].visible:
			free.append(ghosts[i])
	if not free.is_empty():
		free[_rng.randi() % free.size()].fidget()


# A free ghost gets up for a free chair: it claims the chair as it sets off (letting go of its own), so
# no other ghost can head for it, and lands on that chair's seat anchor.
func _move() -> void:
	var free_ghosts: Array[int] = []
	for i in ghosts.size():
		if ghosts[i].is_free() and not bubbles[i].visible:
			free_ghosts.append(i)
	var open := seats.open_seats(OPEN_SEATS)
	if free_ghosts.is_empty() or open.is_empty():
		return
	var index := free_ghosts[_rng.randi() % free_ghosts.size()]
	var target := open[_rng.randi() % open.size()]
	if seats.claim(target, index):
		ghosts[index].move_to(seats.anchors[target].x, target)


func _update_flicker(delta: float) -> void:
	# Harold's lamp hums a little; the other one now and then stutters twice and comes back.
	for i in _flicker.size():
		_flicker[i] = 0.94 + 0.06 * sin(_time * (5.0 + i * 1.3))
	_flicker_wait -= delta
	var pattern := TitleRoom.flicker_level(-_flicker_wait)
	if _flicker_wait < -1.0:
		_flicker_wait = _rng.randf_range(3.0, 8.0)
	_flicker[FLICKER_LAMP] *= pattern
	_back_light.set_levels(_flicker)
	_front_light.set_levels(_flicker)


# The flickering lamp's level t seconds into a stutter (on outside it): off, on, off, on.
static func flicker_level(t: float) -> float:
	if t < 0.0:
		return 1.0
	if t < 0.07:
		return 0.0
	if t < 0.15:
		return 0.7
	if t < 0.3:
		return 0.05
	if t < 0.38:
		return 0.5
	return 1.0


func _draw_machine_panel(panel: Node2D) -> void:
	# The cream label says TAKE over a big 1, and a chevron points down to the slot.
	var cream := Color("bdb39a")
	var ink := Color("6a1a14")
	panel.draw_rect(Rect2(8, 8, 16, 16), cream)
	PixelGlyphs.draw_text(panel, PixelGlyphs.SMALL, "TAKE", Vector2(9, 10), ink)
	PixelGlyphs.draw_text(panel, PixelGlyphs.SMALL, "1", Vector2(14, 17), ink)
	var tip := Vector2(16, 26)
	for step in 3:
		panel.draw_rect(Rect2(tip.x - 3 + step, tip.y + step, 1, 1), Color("e0b040"))
		panel.draw_rect(Rect2(tip.x + 2 - step, tip.y + step, 1, 1), Color("e0b040"))


func _draw_vignette(node: Node2D) -> void:
	var view := Vector2(216, 120)
	for band in VIGNETTE_BANDS.size():
		var color := Color(0.02, 0.01, 0.04, VIGNETTE_BANDS[band])
		var w := 3.0
		var inset := band * w
		node.draw_rect(Rect2(inset, 0, w, view.y), color)
		node.draw_rect(Rect2(view.x - inset - w, 0, w, view.y), color)
		node.draw_rect(Rect2(inset + w, inset, view.x - 2.0 * (inset + w), w), color)
		node.draw_rect(Rect2(inset + w, view.y - inset - w, view.x - 2.0 * (inset + w), w), color)


func debug_ghost_count() -> int:
	return ghosts.size()
