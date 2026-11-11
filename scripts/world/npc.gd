class_name Npc
extends Node2D

signal talked(line: String)

# Someone standing in a room for Grandpa to talk to. Not solid and in no group that anything attacks,
# so canes, blasts and enemies pass through, and he can never be boxed in by one.
const TALK_RADIUS := 40.0
const PROMPT := "Talk"
const FONT_SIZE := 10
const NAME_COLOR := Color("ece9e0")
const PROMPT_COLOR := Color("ffd24a")
const SKIN_COLOR := Color("e8b48a")
const APRON_COLOR := Color("efe4c8")
const SHADOW_COLOR := Color(0, 0, 0, 0.3)
const BUBBLE_COLOR := Color("fff6d8")
const BUBBLE_TEXT_COLOR := Color("2b2218")
const BUBBLE_PAD := Vector2(5, 3)
# A bubble that would reach into the HUD's top rows (Hud.BAND_BOTTOM on screen) hangs below him instead,
# and every bubble stays inside the screen's sides.
const BUBBLE_GAP := 18.0
const BUBBLE_SIDE_MARGIN := 4.0
# Hung below him, the bubble clears the Talk prompt under his feet.
const BUBBLE_BELOW_GAP := 28.0
# Speech draws above the room's props and pickups.
const BUBBLE_Z := 50
# A name over art sits this far above the top of his head, so hair and hats clear its letters.
const ART_NAME_GAP := 6.0

var def: NpcDef
var _talk: NpcTalk
var _player: Node2D
var _near := false
var _bubble: Node2D
# How many letters of the bubble had typed out last frame, so each new one can blip.
var _typed := 0
# His art, standing on the bottom of his body box, or null when he has none.
var _art: NpcSprite
# Someone with no art but a look of his own, as Gerald was, is drawn by an ActorLook on his feet.
var _actor_look: ActorLook


# start is the run count, so each run he opens on his next line.
func setup(npc_def: NpcDef, player: Node2D, start := 0) -> void:
	def = npc_def
	_player = player
	_talk = NpcTalk.new(npc_def.lines, start)


func _ready() -> void:
	add_to_group("npcs")
	# His art stands on his feet, so the room sorts him by them.
	y_sort_enabled = true
	if def != null:
		var art := NpcSprite.new()
		if art.setup(def.art()):
			_art = art
			_art.position = Vector2(0, def.body_size.y / 2.0)
			add_child(_art)
		else:
			art.free()
	if def != null and _art == null and not def.look.is_empty():
		_actor_look = ActorLook.new()
		_actor_look.id = def.look
		_actor_look.position = Vector2(0, def.body_size.y / 2.0)
		add_child(_actor_look)
	_bubble = BubbleLayer.new()
	_bubble.npc = self
	_bubble.z_index = BUBBLE_Z
	add_child(_bubble)
	if def != null and (_art != null or _actor_look != null):
		ContactShadow.add_to(self, def.body_size.x, Vector2(0.0, def.body_size.y / 2.0))


class BubbleLayer extends Node2D:
	var npc: Npc

	func _draw() -> void:
		npc._draw_bubble(self)


func is_near() -> bool:
	return _near


func has_art() -> bool:
	return _art != null


func art() -> NpcSprite:
	return _art


# How far above his origin the top of what is drawn reaches: his head with art, his box without.
func head_top() -> float:
	if def == null:
		return 0.0
	var box_top := -def.body_size.y / 2.0
	if _art != null:
		return minf(box_top, def.body_size.y / 2.0 - _art.height)
	return box_top


func showing() -> String:
	return _talk.showing() if _talk != null else ""


func talk() -> String:
	var line := _talk.talk()
	talked.emit(line)
	return line


# Replaces what he says, starting again at the first line.
func set_lines(lines: Array[String]) -> void:
	_talk = NpcTalk.new(lines)


# Says his line for a moment, if he has one, without a press.
func say_moment(key: String) -> void:
	if def != null and _talk != null:
		_talk.say(def.moment(key))


func _process(delta: float) -> void:
	_talk.tick(delta)
	_blip_new_letters()
	queue_redraw()
	if _bubble != null:
		_bubble.queue_redraw()
	if not is_instance_valid(_player):
		return
	if _art != null:
		# He turns to Harold while Harold is in reach or a line is up, and stands facing out otherwise.
		if _near or not showing().is_empty():
			_art.face(_player.global_position - global_position)
		else:
			_art.set_facing(NpcSprite.SOUTH)
	if _actor_look != null:
		var facing := -1 if _player.global_position.x < global_position.x else 1
		if facing != _actor_look.facing:
			_actor_look.facing = facing
			_actor_look.queue_redraw()
	_near = NpcTalk.answers(_feet().distance_to(global_position), TALK_RADIUS, _rival_distances())
	if _near and Input.is_action_just_pressed("interact"):
		FirstRunTips.interacted(self)
		talk()


# A blip for each letter as the line types out. The pool's shared blip gap keeps it to about twelve
# a second however fast the letters come.
func _blip_new_letters() -> void:
	var typed := _talk.revealed_count()
	if typed > _typed and def != null:
		var letter := _talk.showing().substr(typed - 1, 1)
		if letter.strip_edges() != "":
			Sfx.blip(def.id)
	_typed = typed


func _feet() -> Vector2:
	return _player.feet().global_position if _player.has_method("feet") else _player.global_position


# How near the other things are that would answer the same press: wares and free items waiting to
# be taken, and the Retirement Plan. Only those in their own reach count.
func _rival_distances() -> Array[float]:
	var rivals: Array[float] = []
	var feet := _feet()
	for node in get_tree().get_nodes_in_group("pickups"):
		var pickup := node as Pickup
		if pickup == null or not pickup.requires_interact or pickup.is_flying():
			continue
		if pickup.can_take.is_valid() and not pickup.can_take.call():
			continue
		if pickup.global_position.distance_to(_player.global_position) <= Pickup.COLLECT_RADIUS:
			rivals.append(pickup.global_position.distance_to(feet))
	for node in get_parent().get_children():
		var station := node as RetirementStation
		if station != null and station.global_position.distance_to(feet) <= RetirementStation.USE_RADIUS:
			rivals.append(station.global_position.distance_to(feet))
		var table := node as ArcadeTable
		if table != null and table.plays_left > 0 and table.global_position.distance_to(feet) <= ArcadeTable.USE_RADIUS:
			rivals.append(table.global_position.distance_to(feet))
	return rivals


func _draw() -> void:
	if def == null:
		return
	var size := def.body_size
	var top := -size.y / 2.0
	if _art != null:
		draw_set_transform(Vector2(0, size.y / 2.0), 0.0, Vector2(1.0, 0.35))
		draw_circle(Vector2.ZERO, size.x * 0.6, SHADOW_COLOR)
		draw_set_transform(Vector2.ZERO)
	if _actor_look != null or _art != null:
		_draw_centered(self, def.display_name, Vector2(0, head_top() - (ART_NAME_GAP if _art != null else 4.0)), NAME_COLOR)
		if _near:
			_draw_centered(self, KeyBindings.with_key("interact", PROMPT), Vector2(0, size.y / 2.0 + 12.0), PROMPT_COLOR)
		return
	# A shopkeeper's look: a flat cap, a pale apron over his coat, and a moustache.
	draw_set_transform(Vector2(0, size.y / 2.0), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, size.x * 0.6, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO)
	var coat := Rect2(-size.x / 2.0, top + size.y * 0.35, size.x, size.y * 0.65)
	draw_rect(coat, def.color)
	draw_rect(Rect2(-size.x * 0.3, coat.position.y + 2.0, size.x * 0.6, coat.size.y - 2.0), APRON_COLOR)
	draw_rect(coat, Color.BLACK, false, 1.0)
	var head := Vector2(0, top + size.y * 0.2)
	var head_radius := size.x * 0.32
	draw_circle(head, head_radius, SKIN_COLOR)
	draw_arc(head, head_radius, 0.0, TAU, 16, Color.BLACK, 1.0)
	draw_rect(Rect2(head.x - head_radius - 1.0, head.y - head_radius - 1.0, head_radius * 2.0 + 4.0, 4.0), def.color.darkened(0.3))
	draw_circle(head + Vector2(-2.5, -0.5), 1.0, Color.BLACK)
	draw_circle(head + Vector2(2.5, -0.5), 1.0, Color.BLACK)
	draw_line(head + Vector2(-3.5, 2.5), head + Vector2(3.5, 2.5), Color("5a3a28"), 2.0)
	_draw_centered(self, def.display_name, Vector2(0, top - 4.0), NAME_COLOR)
	if _near:
		_draw_centered(self, KeyBindings.with_key("interact", PROMPT), Vector2(0, size.y / 2.0 + 12.0), PROMPT_COLOR)


func _draw_bubble(layer: Node2D) -> void:
	var line := showing()
	if line.is_empty() or def == null:
		return
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var box_size := Vector2(text_size.x, FONT_SIZE) + BUBBLE_PAD * 2.0
	var screen := layer.get_global_transform_with_canvas()
	var box := bubble_box(screen.origin, screen.get_scale(), def.body_size.y, box_size, Vector2(RoomBackdrop.VIEW_SIZE), -head_top())
	var below := box.position.y > 0.0
	var tail_y := box.position.y if below else box.end.y
	var tail_tip := Vector2(0, tail_y - 5.0 if below else tail_y + 5.0)
	layer.draw_colored_polygon(PackedVector2Array([Vector2(-4, tail_y), Vector2(4, tail_y), tail_tip]), BUBBLE_COLOR)
	layer.draw_rect(box, BUBBLE_COLOR)
	layer.draw_rect(box, Color.BLACK, false, 1.0)
	# The bubble is sized for the whole line, and the words type into it.
	layer.draw_string(font, box.position + Vector2(BUBBLE_PAD.x, BUBBLE_PAD.y + FONT_SIZE - 2.0), _talk.revealed(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, BUBBLE_TEXT_COLOR)


# Where the bubble's box goes, in the speaker's own space: above his head, or below his feet when above
# would reach into the HUD's band at the top of the screen. at is the speaker's spot on screen and
# scale the canvas's zoom. head, when given, is how far his drawn head rises above his origin, which
# his art takes higher than his body box. The box slides sideways to stay inside the screen.
static func bubble_box(at: Vector2, scale: Vector2, body_height: float, box_size: Vector2, view: Vector2, head := -1.0) -> Rect2:
	var zoom := scale.y if scale.y > 0.0 else 1.0
	var above_y := -maxf(body_height / 2.0, head) - BUBBLE_GAP - box_size.y
	var y := above_y
	if at.y + above_y * zoom < Hud.BAND_BOTTOM:
		y = body_height / 2.0 + BUBBLE_BELOW_GAP
	var x := -box_size.x / 2.0
	var left := (BUBBLE_SIDE_MARGIN - at.x) / zoom
	var right := (view.x - BUBBLE_SIDE_MARGIN - at.x) / zoom - box_size.x
	if right >= left:
		x = clampf(x, left, right)
	return Rect2(Vector2(x, y), box_size)


static func _draw_centered(canvas: CanvasItem, text: String, at: Vector2, color: Color) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var spot := at - Vector2(width / 2.0, 0)
	canvas.draw_string_outline(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, 3, Color.BLACK)
	canvas.draw_string(font, spot, text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
