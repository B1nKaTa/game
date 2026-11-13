class_name Pickup
extends Node2D

signal collected

const COLLECT_RADIUS := 18.0
const MAGNET_RADIUS := 64.0
const ARRIVE_RADIUS := 6.0
const FLY_START_SPEED := 120.0
const FLY_ACCELERATION := 700.0
const FLY_MAX_SPEED := 420.0
const PROMPT_TEXT := "Take"
const SWAP_PROMPT := "Swap"
const ICON_SIZE := 20.0
# A named pickup shows its name only while it is the nearest one within this far of his feet.
const NAME_RADIUS := 64.0
# Bone white, so the skull stands out from the cursed name's purple on any floor.
const SKULL_COLOR := Color("ece9e0")

var requires_interact := false
# A pickup that needs the press only at times (a potion on the floor while the slot is full): returns true
# while it does. Empty for one that never does.
var press_when := Callable()
# The frame whose press is not his to use here: a pickup laid by that press must not take it too.
var ignore_press_frame := -1
# How near his feet must come to take it. A heal under the Pill Crusher wants him nearer.
var collect_radius := COLLECT_RADIUS
var can_take := Callable()
var flies := false
# How near a flying coin must be to set off toward him. The Penny Jar widens it.
var magnet_radius := MAGNET_RADIUS
var prompt := PROMPT_TEXT
# When set, returns the prompt's words as they stand now (a potion ware reads Swap while one is carried).
var prompt_when := Callable()
# What the name is drawn in, and whether a skull sits before it, as a cursed item's does.
var label_color := Color.WHITE
var skull := false
# Items, wares, potions, reels and recipes: the name is drawn only up close (see NAME_RADIUS). Coins, slips,
# thermoses and heals draw theirs always, as before.
var names_near_only := false
var _name_shown := false
# A small pickup the Moving Boxes may carry to the next room: its RoomRules.DROP_ kind and amount, or ""
# for anything that stays (coins, items, shop wares).
var carry_kind := ""
var carry_amount := 1
# Which potion a carried potion is, so the next room lays down the same one. "" for any other pickup.
var carry_id := ""
# What a Racing Pigeon may fetch ("coin", "key" or "bomb") and what a Photocopier may copy ("coin", "key",
# "bomb", "heal" or "potion"), with a copy's amount and potion. "" for neither.
var fetch_kind := ""
var copy_kind := ""
var copy_amount := 1
var copy_potion: PotionDef
# Its picture in res://art/props/ (PropArt), such as pickup_coin, or "" to draw the coloured disc. The
# name label is still drawn in code over it.
var art_id := ""
# An item's id, whose icon (ItemIcons) is drawn instead of the disc once its PNG exists. "" for none.
var icon_id := ""
var _label := ""
var _color := Color.WHITE
var _player: Node2D
var _done := false
var _paid := false
var _flying := false
var _fly_time := 0.0
var _prompt_shown := false
# The button the prompt was drawn with, so it is drawn again when the device changes.
var _prompt_label := ""
var _prompt_words := ""


static func should_collect(needs_interact: bool, in_range: bool, interact_pressed: bool) -> bool:
	return in_range and (interact_pressed or not needs_interact)


# Which of the spots is nearest his feet and within radius: its index, or -1 when none is. The first wins a tie.
static func nearest_index(spots: Array[Vector2], feet: Vector2, radius: float) -> int:
	var best := -1
	var best_distance := radius
	for i in spots.size():
		var distance := spots[i].distance_to(feet)
		if distance <= best_distance and (best == -1 or distance < best_distance):
			best = i
			best_distance = distance
	return best


static func should_magnet(can_fly: bool, distance: float, reach := MAGNET_RADIUS) -> bool:
	return can_fly and distance <= reach


static func fly_speed(time: float) -> float:
	return minf(FLY_START_SPEED + FLY_ACCELERATION * time, FLY_MAX_SPEED)


static func fly_step(from: Vector2, to: Vector2, speed: float, delta: float) -> Vector2:
	var offset := to - from
	var step := speed * delta
	if offset.length() <= step:
		return to
	return from + offset.normalized() * step


func setup(label: String, color: Color, player: Node2D, needs_interact := false) -> void:
	_label = label
	_color = color
	_player = player
	requires_interact = needs_interact


# New words only, keeping the colours.
func set_text(label: String) -> void:
	_label = label
	queue_redraw()


func set_label(label: String, color: Color) -> void:
	_label = label
	_color = color
	queue_redraw()


func _ready() -> void:
	add_to_group("pickups")
	_add_shadow()
	queue_redraw()


# A contact shadow the width of its picture under its bottom row, or of the disc without one.
func _add_shadow() -> void:
	var art := shadow_art()
	if art != null:
		ContactShadow.add_to(self, art.get_width() * 0.9, Vector2(0.0, art.get_height() / 2.0 - 1.0))
	else:
		ContactShadow.add_to(self, 14.0, Vector2(0.0, 7.0))


func shadow_art() -> Texture2D:
	return PropArt.texture(art_id) if not art_id.is_empty() else null


func is_flying() -> bool:
	return _flying


func current_prompt() -> String:
	if prompt_when.is_valid():
		return str(prompt_when.call())
	return prompt


func needs_press() -> bool:
	return requires_interact or (press_when.is_valid() and bool(press_when.call()))


# Whether its name is drawn now.
func shows_name() -> bool:
	return not names_near_only or _name_shown


# Of the peers (the "pickups" group), only the nearest named one waiting within NAME_RADIUS shows its name.
func update_name(peers: Array) -> void:
	if not names_near_only:
		return
	var spots: Array[Vector2] = []
	var mine := -1
	for peer in peers:
		if not is_instance_valid(peer) or not peer.names_near_only or not peer.is_waiting():
			continue
		if peer == self:
			mine = spots.size()
		spots.append(peer.global_position)
	var shown := mine != -1 and nearest_index(spots, _player.global_position, NAME_RADIUS) == mine
	if shown != _name_shown:
		_name_shown = shown
		queue_redraw()


func _process(delta: float) -> void:
	if _done or not is_instance_valid(_player):
		return
	if _flying:
		_fly_toward_player(delta)
		return
	if names_near_only and is_inside_tree():
		update_name(get_tree().get_nodes_in_group("pickups"))
	var distance := global_position.distance_to(_player.global_position)
	if should_magnet(flies, distance, magnet_radius):
		fly()
		return
	var in_range := distance <= collect_radius
	if can_take.is_valid() and not can_take.call():
		in_range = false
	var needs := needs_press()
	var show_prompt := needs and in_range
	var words := current_prompt()
	if show_prompt != _prompt_shown or (show_prompt and (KeyBindings.prompt_label("interact") != _prompt_label or words != _prompt_words)):
		_prompt_shown = show_prompt
		_prompt_words = words
		_prompt_label = KeyBindings.prompt_label("interact")
		queue_redraw()
	var pressed := Input.is_action_just_pressed("interact") and Engine.get_process_frames() != ignore_press_frame
	if should_collect(needs, in_range, pressed):
		if needs:
			FirstRunTips.interacted(self)
		collect()


func _fly_toward_player(delta: float) -> void:
	_fly_time += delta
	global_position = fly_step(global_position, _player.global_position, fly_speed(_fly_time), delta)
	if global_position.distance_to(_player.global_position) <= ARRIVE_RADIUS:
		collect()


# The reward is paid when the coin starts flying, so leaving the room, dying or
# ending the run mid-flight can never lose it. The flight is only for show.
# Whether it still lies in the room, untaken.
func is_waiting() -> bool:
	return not _done and not _flying and not is_queued_for_deletion()


func fly() -> void:
	if _done or _flying or is_queued_for_deletion():
		return
	_flying = true
	queue_redraw()
	_pay()


func collect() -> void:
	if _done or is_queued_for_deletion():
		return
	_done = true
	_pay()
	queue_free()


func _pay() -> void:
	if _paid:
		return
	_paid = true
	collected.emit()


func _draw() -> void:
	_draw_body()
	if _flying:
		return
	# Centred and outlined, as people's names are, so they read on the palest floors and long names
	# never run into the next ware.
	if not shows_name():
		if _prompt_shown:
			Npc._draw_centered(self, KeyBindings.with_key("interact", current_prompt()), Vector2(0, 22), Color("ffd24a"))
		return
	Npc._draw_centered(self, _label, Vector2(0, -12), label_color)
	if skull:
		var width := ThemeDB.fallback_font.get_string_size(_label, HORIZONTAL_ALIGNMENT_LEFT, -1, Npc.FONT_SIZE).x
		draw_skull(self, Vector2(-width / 2.0 - 8.0, -16.0), SKULL_COLOR)
	if _prompt_shown:
		Npc._draw_centered(self, KeyBindings.with_key("interact", current_prompt()), Vector2(0, 22), Color("ffd24a"))


# A small skull, drawn in code: a round head, a jaw, two dark eyes. It marks a cursed item's name.
static func draw_skull(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(at + Vector2(-3.5, 2.0), Vector2(7, 4)), Color.BLACK)
	canvas.draw_circle(at, 5.5, Color.BLACK)
	canvas.draw_circle(at, 4.5, color)
	canvas.draw_rect(Rect2(at + Vector2(-2.5, 2.5), Vector2(5, 2.5)), color)
	canvas.draw_circle(at + Vector2(-1.8, -0.2), 1.3, Color.BLACK)
	canvas.draw_circle(at + Vector2(1.8, -0.2), 1.3, Color.BLACK)
	canvas.draw_line(at + Vector2(-1.0, 3.0), at + Vector2(-1.0, 5.0), Color.BLACK, 1.0)
	canvas.draw_line(at + Vector2(1.0, 3.0), at + Vector2(1.0, 5.0), Color.BLACK, 1.0)



# A plain coloured disc. Pickups with a shape of their own, such as chests, draw that instead.

func draws_icon() -> bool:
	return ItemIcons.texture(icon_id) != null


func _draw_body() -> void:
	var icon := ItemIcons.texture(icon_id)
	if icon != null:
		draw_texture_rect(icon, Rect2(Vector2(-ICON_SIZE, -ICON_SIZE) / 2.0, Vector2(ICON_SIZE, ICON_SIZE)), false)
		return
	var art := PropArt.texture(art_id) if not art_id.is_empty() else null
	if art != null:
		PropArt.draw(self, art)
		return
	draw_circle(Vector2.ZERO, 8.0, _color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 16, Color.BLACK, 1.0)
