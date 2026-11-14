class_name FloorMapView
extends Control

signal opened_changed(is_open: bool)

# The floor's name sits on the row above it, at the top of the screen.
const NAME_FONT := 9
# A long name is written smaller over the mini map, but never below this.
const MIN_NAME_FONT := 7
const NAME_BASELINE := 10.0
const NAME_COLOR := Color("ece9e0")
# The small map is a scrap of the big map's paper: rooms, corridors and exit stubs in ink, the room he
# stands in outlined in the stamp's red. Its rooms are 12x8, too small for a 9 px sign at 1x, so each
# sign shows as a dot of colour (MINI_DOTS) in the room's middle, or past a stub's end. The big map's key
# shows each sign's dot beside it. The Crossroads is a whole room here, with its own dot: drawn smaller,
# its corridors were as wide as it and the four of them read as a plus.
const MINI_RECT := Rect2(528, 13, 108, 58)
const CROSSROADS_SCALE := 0.65
const MINI_SPACING := Vector2(15, 11)
const MINI_DOT := 4
const MINI_STUB_DASH := 1
# Each sign's dot by its letter. Every two dots, and each dot against the paper, the room floor, the ink,
# the pencil and the stamp's red, are at least 23 apart in CIEDE2000, and each dot reads on the paper
# (contrast 3 or more). A plain fight room ("C") stays blank.
const MINI_DOTS := {
	"v": Color("008d68"), "+": Color("004849"), "I": Color("386dfd"), "H": Color("f3007a"),
	"$": Color("0d5202"), "T": Color("738500"), "?": Color("52526f"), "A": Color("1606d4"),
	"S": Color("c70aff"), "V": Color("0d89a0"), "M": Color("c46100"), "B": Color("810059"),
}
# The big map is a floor plan on a sheet of the case file's paper (MapPaper), over the dimmed game: a
# manila tab, the floor's name over an ink rule, the run's sets, the plan on graph paper, and a key.
const SHEET := Rect2(48, 22, 544, 324)
const TAB := Rect2(64, 8, 96, 16)
const TAB_TEXT := "FLOOR PLAN"
const NAME_BOX := Rect2(64, 28, 416, 18)
# The close prompt's room, right of the name.
const HINT_WIDTH := 92.0
const RULE_Y := 48.0
const SETS_BOX := Rect2(64, 51, 512, 9)
const BIG_AREA := Rect2(64, 62, 512, 226)
const GRID_STEP := 16
const BIG_SPACING := Vector2(60, 46)
const ROOM_FILL := 0.8
# How far an exit stub reaches past the gap into the next cell, and its dashes' length.
const STUB_REACH := 3
const STUB_DASH := 2
const STAMP_TEXT := "YOU ARE HERE"
# The stamp is pressed over the current room's corner by this much.
const STAMP_OVERLAP := 4.0
# The key lists only the signs of the rooms on this floor, in this order. A plain fight room has no
# sign and shows as an empty square; the Crossroads is a smaller one, as on the plan.
const KEY_RECT := Rect2(64, 292, 512, 48)
const KEY_TITLE := "KEY"
const KEY_TITLE_WIDTH := 30.0
const KEY_COLUMNS := 6
const KEY_ROWS := 3
const KEY_ROW_HEIGHT := 14.0
# Room for an entry's dot swatch (MINI_DOT) and a pixel's gap after it.
const KEY_SWATCH_ROOM := 6.0
const KEY_ORDER := ["v", "+", "C", "I", "H", "$", "T", "?", "A", "S", "V", "M", "B"]
const KEY_LABELS := {
	"v": "Stairs", "+": "Crossroads", "C": "Fight", "I": "Item", "H": "Healing", "$": "Shop", "T": "Treasure",
	"?": "Unknown", "A": "Arcade", "S": "Secret", "V": "Vault", "M": "Mini boss", "B": "Boss",
}
const CLOSE_HINT := "Close"
# A boss's name in the key's spare row (no clear spot on the plan), so it never reads as a key entry.
const KEY_NAME_FORMATS := {"B": "Boss: %s", "M": "Mini boss: %s"}
const KEY_NAME_GAP := 12.0
# Pickups left behind in a walked room (leftovers), each kind once, in this order. The big map draws up to
# LEFTOVER_SLOTS small ink pictures in the room's box, beside its sign; with more kinds than slots, the
# last slot holds dots (LEFTOVER_MORE), never a plus, which would read as a cross. The small map marks
# such a room with one ink dot in its top right corner (mini_leftover_rect). The key explains the
# pictures on a "Left here" line, only while some room has leftovers.
const LEFTOVER_ORDER: Array[String] = ["potion", "item", "reel", "key", "bomb", "heal"]
const LEFTOVER_MORE := "more"
const LEFTOVER_SLOTS := 4
const LEFTOVER_ICON := Vector2(5, 6)
# The game's own pictures, simplified to ink at 1x: the HUD's flask (a cork, a neck, a round belly), the
# item room's star, the reel slot's holed disc, the HUD Slip's ruled paper, the HUD Thermos as a narrower
# straight-sided cylinder under a flat lid, and the healing sign's pill set upright. 'x' is ink, 's'
# pencil, '.' bare.
const LEFTOVER_ICONS := {
	"potion": [".xxx.", "..x..", ".xxx.", "xxxxx", "xxxxx", ".xxx."],
	"item": ["..x..", ".xxx.", "xxxxx", ".xxx.", ".x.x.", "x...x"],
	"reel": [".xxx.", "x.x.x", "xxxxx", "xx.xx", ".xxx."],
	"key": ["xxxxx", "xss.x", "x...x", "xss.x", "x...x", "xxxxx"],
	"bomb": ["xxxx", "x..x", "xxxx", "xxxx", "xxxx", "xxxx"],
	"heal": [".x.", "x.x", "x.x", "xxx", "xxx", ".x."],
	"more": ["x.x.x"],
}
const LEFTOVER_LABELS := {"potion": "Potion", "item": "Item", "reel": "Reel", "key": "Slip", "bomb": "Thermos", "heal": "Heal"}
const LEFTOVER_TITLE := "Left here:"
const LEFTOVER_GAP := 8.0
# Rooms the Floor Plan never gives away, since finding them is the point.
const HIDDEN_TYPES := [RoomLayout.TYPE_SECRET, RoomLayout.TYPE_VAULT]
const BOSS_TYPES := [RoomLayout.TYPE_FLOOR_BOSS, RoomLayout.TYPE_MINI_BOSS]

var enabled := true
# The frame the big map last closed on, so the Esc that closed it never also pauses.
var closed_frame := -1
var _opened_frame := -1
# The Night Vision option: secret rooms show, as outlines with a "?", before they are found.
var show_secrets := false
var _map: FloorMap
var _progress: FloorProgress
var _current_id := -1
var _is_big := false
var _floor_name := ""
# What the big map last drew, for marks laid over it later: each shown room's box by id (the Crossroads'
# smaller one), and the "YOU ARE HERE" stamp. A room's sign sits in room_sign_rect of its box.
var big_room_rects := {}
var big_stamp_rect := Rect2()
# The corridors' and stubs' footprints, and the boss names' patches, as last drawn.
var big_link_rects: Array[Rect2] = []
var big_name_rects: Array[Rect2] = []
# Each room the small map last drew, by id, as its box there (a whole room, the Crossroads too). A
# room's dot sits in mini_dot_rect of its box, which leaves each corner inside its edge clear.
var mini_room_rects := {}
# The run's formed sets, listed on the paused big map as its run summary.
var set_names := PackedStringArray():
	set(value):
		set_names = value
		queue_redraw()
# The Floor Plan: every room but the hidden ones shows from the start, as an outline until visited.
var show_plan := false:
	set(value):
		show_plan = value
		queue_redraw()
# The Fortune Teller's Card: room type -> the name of the boss who waits there. Boss rooms then show
# before they are found, and the big map names them.
var boss_names := {}:
	set(value):
		boss_names = value
		queue_redraw()


# The rooms the map shows: every visited room, and with show_secrets every secret room as well. With
# the Floor Plan every room but the secret ones and vaults shows, and with boss names every boss room.
static func shown_ids(map: FloorMap, progress: FloorProgress, with_secrets: bool, with_plan := false, with_bosses := false) -> Array[int]:
	var ids: Array[int] = []
	ids.append_array(progress.visited_ids())
	for room in map.rooms:
		if ids.has(room.id):
			continue
		var secret := room.room_type == RoomLayout.TYPE_SECRET
		if (with_secrets and secret) or (with_plan and not HIDDEN_TYPES.has(room.room_type)) or (with_bosses and BOSS_TYPES.has(room.room_type)):
			ids.append(room.id)
	return ids


# Who waits in this floor's boss rooms, by room type, for the Fortune Teller's Card.
static func boss_names_for(floor_def: FloorDef) -> Dictionary:
	var names := {}
	if floor_def == null:
		return names
	if floor_def.floor_boss != null:
		names[RoomLayout.TYPE_FLOOR_BOSS] = floor_def.floor_boss.display_name
	if floor_def.mini_boss != null:
		names[RoomLayout.TYPE_MINI_BOSS] = floor_def.mini_boss.display_name
	return names


# Whether a link between two rooms shows: between two visited rooms always, and with the Floor Plan
# between any two rooms it shows, as long as neither is hidden.
static func link_shown(a: FloorRoom, b: FloorRoom, progress: FloorProgress, with_plan: bool) -> bool:
	if progress.is_visited(a.id) and progress.is_visited(b.id):
		return true
	return with_plan and not HIDDEN_TYPES.has(a.room_type) and not HIDDEN_TYPES.has(b.room_type)


# Whether the big map draws a corridor between two shown rooms: wherever link_shown says, and from a
# walked room through its door into any room the map shows but he has not walked into (a boss room the
# Fortune Teller's Card shows, a Floor Plan room), so that door never vanishes. Never into a hidden room
# not yet found.
static func corridor_shown(a: FloorRoom, b: FloorRoom, progress: FloorProgress, with_plan: bool) -> bool:
	if link_shown(a, b, progress, with_plan):
		return true
	if HIDDEN_TYPES.has(a.room_type) or HIDDEN_TYPES.has(b.room_type):
		return false
	return (progress.is_visited(a.id) and a.side_towards(b.id) != Vector2i.ZERO) or (progress.is_visited(b.id) and b.side_towards(a.id) != Vector2i.ZERO)


# Whether he has seen this room's door sign: a walked room has a door into it.
static func sign_seen(map: FloorMap, progress: FloorProgress, room: FloorRoom) -> bool:
	for other in map.rooms:
		if progress.is_visited(other.id) and other.side_towards(room.id) != Vector2i.ZERO:
			return true
	return false


# The mark the big map draws in a shown room, as a key letter, or "" for none:
# - a walked room's own sign ("C" for a plain fight room and "+" for the Crossroads, drawn as their blank boxes);
# - Night Vision's secret not yet walked into, as a "?" (the key's "Unknown");
# - a room he has not walked into but whose door sign he saw from a walked room;
# - a boss room the Fortune Teller's Card names.
# A Floor Plan room otherwise says nothing of what is in it.
static func drawn_sign(map: FloorMap, progress: FloorProgress, room: FloorRoom, with_bosses: bool) -> String:
	var mark := RoomRules.door_icon(room.room_type)
	if progress.is_visited(room.id):
		return mark
	if room.room_type == RoomLayout.TYPE_SECRET:
		return "?"
	if HIDDEN_TYPES.has(room.room_type) or not DoorSign.has_sign(mark):
		return ""
	if sign_seen(map, progress, room) or (with_bosses and BOSS_TYPES.has(room.room_type)):
		return mark
	return ""


# The exits of walked rooms into rooms the map does not show yet: one per such door, ending in the sign
# of the room behind it ("?" for a room with none, a plain fight room). A secret or a vault is never
# given away: it shows only once found, and then it is a room on the map, not a stub.
static func exit_stubs(map: FloorMap, progress: FloorProgress, shown: Array) -> Array[Dictionary]:
	var stubs: Array[Dictionary] = []
	for room_id: int in shown:
		if not progress.is_visited(room_id):
			continue
		var room := map.room(room_id)
		for side: Vector2i in room.doors:
			var target_id: int = room.doors[side]
			if shown.has(target_id) or HIDDEN_TYPES.has(map.room(target_id).room_type):
				continue
			var icon := RoomRules.door_icon(map.room(target_id).room_type)
			stubs.append({"from": room_id, "side": side, "icon": icon if DoorSign.has_sign(icon) else "?"})
	return stubs


# The signs the key lists: only the marks drawn on the sheet (drawn_sign of each shown room, and each
# stub's sign), in KEY_ORDER, so the key never tells of a room not yet found.
static func key_icons(map: FloorMap, progress: FloorProgress, shown: Array, stubs: Array[Dictionary], with_bosses: bool) -> Array[String]:
	var present := {}
	for room_id: int in shown:
		var mark := drawn_sign(map, progress, map.room(room_id), with_bosses)
		if not mark.is_empty():
			present[mark] = true
	for stub in stubs:
		present[stub["icon"]] = true
	var icons: Array[String] = []
	for icon: String in KEY_ORDER:
		if present.has(icon):
			icons.append(icon)
	return icons


static func key_column_width() -> float:
	return floorf((KEY_RECT.size.x - KEY_TITLE_WIDTH - 4.0) / KEY_COLUMNS)


# The room a key entry's label has, right of its sign and the swatch of its small-map dot.
static func key_label_width() -> float:
	return key_column_width() - DoorSign.SIZE - 5.0 - KEY_SWATCH_ROOM


# Where key entry i starts: its sign's top left.
static func key_entry_at(i: int) -> Vector2:
	return KEY_RECT.position + Vector2(KEY_TITLE_WIDTH + (i % KEY_COLUMNS) * key_column_width(), 5.0 + floorf(i / float(KEY_COLUMNS)) * KEY_ROW_HEIGHT)


# The swatch of a key entry's small-map dot, between its sign and its label, level with the sign's middle.
static func key_swatch_rect(at: Vector2) -> Rect2:
	return Rect2(at + Vector2(DoorSign.SIZE + 2.0, floorf((DoorSign.SIZE - MINI_DOT) / 2.0)), Vector2(MINI_DOT, MINI_DOT))


# The floor's name heads the sheet in capitals, large when it fits, else in the small size.
static func heading_text(floor_name: String) -> String:
	return floor_name.to_upper()


static func heading_size(floor_name: String) -> int:
	if MapPaper.text_width(heading_text(floor_name), HudStyle.LARGE) <= NAME_BOX.size.x:
		return HudStyle.LARGE
	return HudStyle.SMALL


# tr() outside a node: TranslationServer, as the first-run tips do.
static func sets_line(names: PackedStringArray) -> String:
	return TranslationServer.translate("Sets: %s") % ", ".join(names)


# The sets line as it fits `width` in the small font: every name, or the first ones and how many more.
static func sets_text(names: PackedStringArray, width: float) -> String:
	var line := sets_line(names)
	var count := names.size() - 1
	while count >= 1 and MapPaper.text_width(line, HudStyle.SMALL) > width:
		line = TranslationServer.translate("%s and %d more") % [sets_line(names.slice(0, count)), names.size() - count]
		count -= 1
	if MapPaper.text_width(line, HudStyle.SMALL) > width:
		line = TranslationServer.translate("Sets: %d") % names.size()
	return line


# How long an exit stub is: across the gap between cells and a little into the next one.
static func stub_length(side: Vector2i, spacing: Vector2) -> int:
	var gap := spacing - room_size(spacing)
	return int(gap.x if side.x != 0 else gap.y) + STUB_REACH


# A stub's sign is a size smaller than a walked room's, so it never reads as a room.
static func stub_sign_scale(room: Vector2) -> int:
	return maxi(1, MapPaper.sign_scale(room) - 1)


# The whole of a stub from a room drawn at from_rect: its walls and the sign past its end.
static func stub_box(from_rect: Rect2, side: Vector2i, spacing: Vector2) -> Rect2:
	var room := room_size(spacing)
	var length := stub_length(side, spacing)
	var walls := MapPaper.corridor_box(MapPaper.edge_mid(from_rect, side), side, length, MapPaper.corridor_half(room))
	var sign_rect := MapPaper.stub_sign_rect(MapPaper.stub_end(from_rect, side, length), side, stub_sign_scale(room))
	return walls.merge(sign_rect.grow(1.0))


# The spot a room's door sign takes in the middle of its box on the big map, whether or not the room
# has a sign (a plain fight room's middle is left clear too).
static func room_sign_rect(rect: Rect2, room: Vector2) -> Rect2:
	var size := float(DoorSign.SIZE * MapPaper.sign_scale(room))
	return Rect2((rect.get_center() - Vector2(size, size) / 2.0).floor(), Vector2(size, size))


# Where the "YOU ARE HERE" stamp goes: over a corner of the current room, on whichever corner covers the
# least of the rest of the plan (busy), and always inside the plan's area.
static func stamp_rect(here: Rect2, size: Vector2, busy: Array[Rect2]) -> Rect2:
	var o := STAMP_OVERLAP
	var tries: Array[Vector2] = [
		Vector2(here.end.x - o, here.position.y - size.y + o),
		Vector2(here.position.x - size.x + o, here.position.y - size.y + o),
		Vector2(here.end.x - o, here.end.y - o),
		Vector2(here.position.x - size.x + o, here.end.y - o),
	]
	var best := Rect2()
	var best_cover := INF
	for at in tries:
		var x := clampf(at.x, BIG_AREA.position.x, BIG_AREA.end.x - size.x)
		var y := clampf(at.y, BIG_AREA.position.y, BIG_AREA.end.y - size.y)
		var rect := Rect2(Vector2(x, y).floor(), size)
		var cover := 0.0
		for other in busy:
			cover += rect.intersection(other).get_area()
		if cover < best_cover:
			best = rect
			best_cover = cover
	return best


# Where a boss's name goes (the Fortune Teller's Card): a patch the size of its words, as near its room
# as it can be while it covers no room, corridor or stub (busy). First the gap under the room, then the
# gap over it, each slid sideways while it still overlaps the room's width; then the middle of the next
# row down or up. Inside the plan always; when every spot covers something, the one covering least.
static func name_rect(room: Rect2, size: Vector2, spacing: Vector2, busy: Array[Rect2]) -> Rect2:
	var gap := spacing.y - room_size(spacing).y
	var center_x := floorf(room.get_center().x - size.x / 2.0)
	var rows: Array[float] = [
		room.end.y + floorf((gap - size.y) / 2.0),
		room.position.y - gap + floorf((gap - size.y) / 2.0),
		room.end.y + gap + floorf((room.size.y - size.y) / 2.0),
		room.position.y - gap - room.size.y + floorf((room.size.y - size.y) / 2.0),
	]
	var shifts: Array[float] = [0.0]
	var step := 2.0
	while step < size.x / 2.0 + room.size.x / 2.0:
		shifts.append(step)
		shifts.append(-step)
		step += 2.0
	var best := Rect2()
	var best_cover := INF
	for y in rows:
		for shift in shifts:
			var x := clampf(center_x + shift, BIG_AREA.position.x, BIG_AREA.end.x - size.x)
			var rect := Rect2(Vector2(x, clampf(y, BIG_AREA.position.y, BIG_AREA.end.y - size.y)).floor(), size)
			var cover := 0.0
			for other in busy:
				cover += rect.intersection(other).get_area()
			if cover == 0.0:
				return rect
			if cover < best_cover:
				best = rect
				best_cover = cover
	return best


# A room's place on the map is its grid cell, counted from the floor's top left, whatever its size.
static func map_position(map: FloorMap, room: FloorRoom) -> Vector2:
	return Vector2(room.cell - map.bounds().position)


static func room_size(spacing: Vector2) -> Vector2:
	return (spacing * ROOM_FILL).floor()


static func room_rect(at: Vector2, origin: Vector2, spacing: Vector2) -> Rect2:
	return Rect2(origin + at * spacing, room_size(spacing))


# As roomy as the panel allows while the whole floor fits, with a stable picture as rooms are found.
static func big_spacing(extent: Vector2i) -> Vector2:
	var fit := (BIG_AREA.size / Vector2(extent)).floor()
	return Vector2(minf(fit.x, BIG_SPACING.x), minf(fit.y, BIG_SPACING.y))


static func big_origin(extent: Vector2i, spacing: Vector2) -> Vector2:
	var used := Vector2(extent) * spacing - (spacing - room_size(spacing))
	return BIG_AREA.position + ((BIG_AREA.size - used) / 2.0).floor()


# The small map keeps the current room in the middle, since a whole floor won't fit in the corner.
static func mini_origin(current_at: Vector2) -> Vector2:
	return MINI_RECT.get_center() - current_at * MINI_SPACING - room_size(MINI_SPACING) / 2.0


# Where the small map draws: inside the scrap's edge with a pixel clear. A room, corridor or stub that
# would not lie wholly inside is left off, as a room off the scrap is.
static func mini_area() -> Rect2:
	return MINI_RECT.grow(-2.0)


# A room's dot on the small map, in the middle of its box.
static func mini_dot_rect(rect: Rect2) -> Rect2:
	var center := rect.position + (rect.size / 2.0).floor()
	return Rect2(center - Vector2(MINI_DOT, MINI_DOT) / 2.0, Vector2(MINI_DOT, MINI_DOT))


# A stub's dot on the small map: a pixel past its end, as wide as its walls.
static func mini_stub_dot(from_rect: Rect2, side: Vector2i) -> Rect2:
	var end := MapPaper.stub_end(from_rect, side, stub_length(side, MINI_SPACING))
	var center := end + Vector2(side) * (MINI_DOT / 2.0 + 1.0)
	return Rect2((center - Vector2(MINI_DOT, MINI_DOT) / 2.0).floor(), Vector2(MINI_DOT, MINI_DOT))


# The Crossroads is a smaller square in its cell, so it reads as the little room it is.
static func crossroads_rect(cell_rect: Rect2) -> Rect2:
	var size := (cell_rect.size * CROSSROADS_SCALE).floor()
	return Rect2(cell_rect.get_center() - size / 2.0, size)


# The pickups left behind in each walked room, by room id: the kinds of LEFTOVER_ORDER lying there, each
# once, in that order. They are read from the room's saved state (FloorProgress.state_of), the very state
# that lays them out again when he walks back in, after a Save and Quit too, so the map never tells of
# something that is not there. A room with none is left out, and so is the Crossroads, which the
# checkpoint never keeps.
static func leftovers(map: FloorMap, progress: FloorProgress) -> Dictionary:
	var out := {}
	for room_id: int in progress.visited_ids():
		if map.room(room_id).room_type == RoomLayout.TYPE_CROSSROADS:
			continue
		var present := {}
		for entry in progress.state_of(room_id).get("keep", []):
			if entry is Dictionary:
				present[leftover_kind(entry)] = true
		var kinds: Array[String] = []
		for kind in LEFTOVER_ORDER:
			if present.has(kind):
				kinds.append(kind)
		if not kinds.is_empty():
			out[room_id] = kinds
	return out


# What the maps call a thing a saved room keeps (RoomView.snapshot), or "" for one he cannot simply come
# back for: shop wares, closed chests and recipes.
static func leftover_kind(entry: Dictionary) -> String:
	match str(entry.get("kind", "")):
		RoomView.KEEP_POTION:
			return "potion"
		RoomView.KEEP_ITEM, RoomView.KEEP_FREE:
			return "item"
		RoomView.KEEP_REEL:
			return "reel"
		RoomView.KEEP_DROP:
			match str(entry.get("drop", "")):
				RoomRules.DROP_KEY:
					return "key"
				RoomRules.DROP_BOMB:
					return "bomb"
				RoomRules.DROP_HEAL:
					return "heal"
	return ""


# Where a walked room's leftover pictures go on the big map, in the order they fill: beside the sign's spot
# (room_sign_rect), a pixel clear of it, of the outline and of each other, and off the corners the stamp
# presses on (STAMP_OVERLAP). Two a side, at the top and the bottom, or all on one side when the other is
# too narrow. Fewer only when even that does not fit, which no room the big map draws comes to.
static func leftover_slots(rect: Rect2, room: Vector2) -> Array[Rect2]:
	var icon := LEFTOVER_ICON
	var inside := rect.grow(-float(MapPaper.outline_width(room) + 1))
	var sign_spot := room_sign_rect(rect, room).grow(1.0)
	var o := STAMP_OVERLAP
	var corners: Array[Rect2] = [Rect2(rect.position, Vector2(o, o)), Rect2(rect.end.x - o, rect.position.y, o, o),
			Rect2(rect.position.x, rect.end.y - o, o, o), Rect2(rect.end - Vector2(o, o), Vector2(o, o))]
	var columns: Array[Rect2] = []
	for column: Rect2 in [Rect2(inside.position.x, inside.position.y, sign_spot.position.x - inside.position.x, inside.size.y),
			Rect2(sign_spot.end.x, inside.position.y, inside.end.x - sign_spot.end.x, inside.size.y)]:
		if column.size.x >= icon.x:
			columns.append(column)
	var per_column := 0 if columns.is_empty() else ceili(LEFTOVER_SLOTS / float(columns.size()))
	var stacks: Array = []
	for column in columns:
		var x := column.position.x + floorf((column.size.x - icon.x) / 2.0)
		var top := column.position.y
		var bottom := column.end.y - icon.y
		for corner in corners:
			if Rect2(x, top, icon.x, icon.y).intersects(corner):
				top = corner.end.y
			if Rect2(x, bottom, icon.x, icon.y).intersects(corner):
				bottom = corner.position.y - icon.y
		var stack: Array[Rect2] = []
		var count := mini(per_column, floori((bottom - top) / (icon.y + 1.0)) + 1)
		for i in count:
			var y := top if count == 1 else top + roundf(i * (bottom - top) / (count - 1))
			stack.append(Rect2(x, y, icon.x, icon.y))
		stacks.append(stack)
	# Reading order: across the top row of the columns first, then down.
	var slots: Array[Rect2] = []
	for i in per_column:
		for stack: Array[Rect2] in stacks:
			if i < stack.size() and slots.size() < LEFTOVER_SLOTS:
				slots.append(stack[i])
	return slots


# The marks drawn in a room's slots: each kind, or with more kinds than slots, all but the last slot's
# worth and LEFTOVER_MORE there.
static func leftover_marks(kinds: Array[String], slots: int) -> Array[String]:
	var marks: Array[String] = []
	for kind in kinds:
		marks.append(kind)
	if marks.size() > slots:
		marks.resize(maxi(slots - 1, 0))
		if slots > 0:
			marks.append(LEFTOVER_MORE)
	return marks


# A leftover picture's top left in its slot: centred, on whole pixels.
static func leftover_origin(slot: Rect2, mark: String) -> Vector2:
	var rows: Array = LEFTOVER_ICONS[mark]
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	return slot.position + ((LEFTOVER_ICON - Vector2(width, rows.size())) / 2.0).floor()


# The small map's mark for a room with leftovers: a 1 px ink dot in its top right corner, a pixel clear of
# the outline and of the room's colour dot (mini_dot_rect) on every side, so it reads as a dot and not as
# a thicker corner. A 12x8 room has no spot that leaves a 2 px dot clear all round.
static func mini_leftover_rect(rect: Rect2) -> Rect2:
	return Rect2(rect.end.x - 3.0, rect.position.y + 2.0, 1.0, 1.0)


func setup(map: FloorMap, progress: FloorProgress, is_big: bool, floor_name := "") -> void:
	_map = map
	_progress = progress
	_is_big = is_big
	_floor_name = floor_name
	queue_redraw()


func floor_name() -> String:
	return _floor_name


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _is_big:
		visible = false
		# It has to hear the key while the game is paused.
		process_mode = Node.PROCESS_MODE_ALWAYS


func set_current(room_id: int) -> void:
	_current_id = room_id
	queue_redraw()


func is_open() -> bool:
	return _is_big and visible


func set_open(open: bool) -> void:
	if not _is_big or open == visible:
		return
	visible = open
	if open:
		_opened_frame = Engine.get_process_frames()
	if not open:
		closed_frame = Engine.get_process_frames()
	get_tree().paused = open
	queue_redraw()
	opened_changed.emit(open)


# Esc, or B on a pad, closes the big map as the map key does. It runs while the game is paused.
func _process(_delta: float) -> void:
	if is_open() and Engine.get_process_frames() != _opened_frame and (Input.is_action_just_pressed("pause") or Input.is_action_just_pressed(PadInput.BACK_ACTION)):
		set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if _is_big and event.is_action_pressed("map") and (enabled or visible):
		set_open(not visible)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if is_open():
		get_tree().paused = false


func _draw() -> void:
	if _map == null or _progress == null or _current_id == -1:
		return
	if _is_big:
		paint_big(self)
		return
	paint_mini(self)
	_draw_floor_name()


# The small map, on a CanvasItem (itself, in play) or into an Image (the tests): a scrap of paper with
# the rooms round the one he stands in, their corridors and the exit stubs, drawn as the big map draws
# them (the same shown rooms, corridors and stubs, and only the marks drawn_sign allows), each sign as
# its dot. A room, corridor or stub not wholly on the scrap is left off.
func paint_mini(canvas: Object) -> void:
	MapPaper.fill(canvas, MINI_RECT, MapPaper.PAPER)
	MapPaper.frame(canvas, MINI_RECT, 1, MapPaper.PAPER_EDGE)
	var spacing := MINI_SPACING
	var origin := mini_origin(map_position(_map, _map.room(_current_id)))
	var half := MapPaper.corridor_half(room_size(spacing))
	var area := mini_area()
	var with_bosses := not boss_names.is_empty()
	var shown := shown_ids(_map, _progress, show_secrets, show_plan, with_bosses)
	mini_room_rects.clear()
	for room_id: int in shown:
		var rect := _rect_of(_map.room(room_id), origin, spacing)
		if area.encloses(rect):
			mini_room_rects[room_id] = rect
	var gaps := {}
	for link: Array in _links(shown):
		if not mini_room_rects.has(link[0]) or not mini_room_rects.has(link[1]):
			continue
		var side: Vector2i = _map.room(link[1]).cell - _map.room(link[0]).cell
		(gaps.get_or_add(link[0], []) as Array).append(side)
		(gaps.get_or_add(link[1], []) as Array).append(-side)
		var known: bool = link[2]
		MapPaper.corridor(canvas, mini_room_rects[link[0]], mini_room_rects[link[1]], half, 1, MapPaper.INK if known else MapPaper.PENCIL)
	for stub in exit_stubs(_map, _progress, shown):
		if not mini_room_rects.has(stub["from"]):
			continue
		var from_rect: Rect2 = mini_room_rects[stub["from"]]
		var side: Vector2i = stub["side"]
		var length := stub_length(side, spacing)
		var dot := mini_stub_dot(from_rect, side)
		if not area.encloses(MapPaper.corridor_box(MapPaper.edge_mid(from_rect, side), side, length, half).merge(dot)):
			continue
		(gaps.get_or_add(stub["from"], []) as Array).append(side)
		MapPaper.stub(canvas, from_rect, side, length, half, 1, MINI_STUB_DASH, MapPaper.INK)
		MapPaper.fill(canvas, dot, MINI_DOTS[stub["icon"]])
	for room_id: int in mini_room_rects:
		_paint_mini_room(canvas, _map.room(room_id), mini_room_rects[room_id], gaps.get(room_id, []), half, with_bosses)
	# A room with pickups left behind: one ink dot in its corner, never a colour a room's dot could have.
	var left := leftovers(_map, _progress)
	for room_id: int in mini_room_rects:
		if left.has(room_id):
			MapPaper.fill(canvas, mini_leftover_rect(mini_room_rects[room_id]), MapPaper.INK)


# A room on the small map: a walked room's floor in an ink outline (the stamp's red for the room he
# stands in), a room shown but not walked into as a pencil outline on bare paper, with door gaps where
# its corridors and stubs open; and the dot of its drawn_sign, if it has one.
func _paint_mini_room(canvas: Object, room: FloorRoom, rect: Rect2, gaps: Array, half: int, with_bosses: bool) -> void:
	var width := MapPaper.outline_width(room_size(MINI_SPACING))
	if _progress.is_visited(room.id):
		MapPaper.fill(canvas, rect, MapPaper.ROOM_FILL)
		MapPaper.outline(canvas, rect, width, MapPaper.STAMP if room.id == _current_id else MapPaper.INK, gaps, half)
	else:
		MapPaper.fill(canvas, rect, MapPaper.PAPER)
		MapPaper.outline(canvas, rect, width, MapPaper.PENCIL, gaps, half)
	var mark := drawn_sign(_map, _progress, room, with_bosses)
	if MINI_DOTS.has(mark):
		MapPaper.fill(canvas, mini_dot_rect(rect), MINI_DOTS[mark])


# The big map, on a CanvasItem (itself, in play) or into an Image (the tests): the sheet and its tab,
# the heading, the plan (corridors, exit stubs, rooms, boss names, the stamp) and the key.
func paint_big(canvas: Object) -> void:
	MapPaper.fill(canvas, Rect2(Vector2.ZERO, CaseFile.VIEW), CaseFile.DESK)
	MapPaper.sheet(canvas, SHEET)
	MapPaper.fill(canvas, TAB, CaseFile.MANILA)
	MapPaper.frame(canvas, TAB, 1, CaseFile.MANILA_EDGE)
	MapPaper.text_in(canvas, TAB, tr(TAB_TEXT), HudStyle.SMALL, MapPaper.INK)
	_paint_heading(canvas)
	MapPaper.grid(canvas, BIG_AREA, GRID_STEP)
	var extent := _map.bounds().size
	var spacing := big_spacing(extent)
	var origin := big_origin(extent, spacing)
	var room := room_size(spacing)
	var half := MapPaper.corridor_half(room)
	var shown := shown_ids(_map, _progress, show_secrets, show_plan, not boss_names.is_empty())
	var stubs := exit_stubs(_map, _progress, shown)
	var links := _links(shown)
	var with_bosses := not boss_names.is_empty()
	big_room_rects.clear()
	big_link_rects.clear()
	for room_id: int in shown:
		big_room_rects[room_id] = _drawn_rect(_map.room(room_id), origin, spacing)
		# The grid stops a pixel short of every room, so no grid line runs on past a room's corner.
		MapPaper.fill(canvas, (big_room_rects[room_id] as Rect2).grow(1.0), MapPaper.PAPER)
	# Which sides of each room open onto a corridor or a stub, for its door gaps.
	var gaps := {}
	var busy: Array[Rect2] = []
	for link: Array in links:
		var a := _map.room(link[0])
		var b := _map.room(link[1])
		var a_rect := _drawn_rect(a, origin, spacing)
		var side: Vector2i = b.cell - a.cell
		(gaps.get_or_add(a.id, []) as Array).append(side)
		(gaps.get_or_add(b.id, []) as Array).append(-side)
		var known: bool = link[2]
		var b_rect := _drawn_rect(b, origin, spacing)
		MapPaper.corridor(canvas, a_rect, b_rect, half, 1, MapPaper.INK if known else MapPaper.PENCIL)
		var from := MapPaper.edge_mid(a_rect, side)
		big_link_rects.append(MapPaper.corridor_box(from, side, int(absf((MapPaper.edge_mid(b_rect, -side) - from).dot(Vector2(side)))), half))
	for stub in stubs:
		var from_rect := _drawn_rect(_map.room(stub["from"]), origin, spacing)
		var side: Vector2i = stub["side"]
		(gaps.get_or_add(stub["from"], []) as Array).append(side)
		var end := MapPaper.stub(canvas, from_rect, side, stub_length(side, spacing), half, 1, STUB_DASH, MapPaper.INK)
		var sign_rect := MapPaper.stub_sign_rect(end, side, stub_sign_scale(room))
		MapPaper.fill(canvas, sign_rect.grow(1.0), MapPaper.PAPER)
		MapPaper.ink_sign(canvas, sign_rect.get_center(), stub["icon"], stub_sign_scale(room))
		big_link_rects.append(stub_box(from_rect, side, spacing))
	busy.append_array(big_link_rects)
	for room_id: int in shown:
		_paint_room(canvas, _map.room(room_id), origin, spacing, gaps.get(room_id, []), with_bosses)
		busy.append(big_room_rects[room_id])
	# Pickups left behind, after the rooms and before the names and the stamp, which then keep clear of
	# them where they can and are pressed over them where they cannot.
	var left := leftovers(_map, _progress)
	var left_kinds: Array[String] = []
	for room_id: int in left:
		if big_room_rects.has(room_id):
			busy.append_array(_paint_leftovers(canvas, big_room_rects[room_id], room, left[room_id]))
		for kind: String in left[room_id]:
			if not left_kinds.has(kind):
				left_kinds.append(kind)
	var kinds_in_order: Array[String] = []
	for kind in LEFTOVER_ORDER:
		if left_kinds.has(kind):
			kinds_in_order.append(kind)
	var icons := key_icons(_map, _progress, shown, stubs, with_bosses)
	big_name_rects.clear()
	var key_names: Array[String] = []
	for room_id: int in shown:
		if not _paint_boss_name(canvas, _map.room(room_id), spacing, busy, key_has_name_row(icons.size(), not kinds_in_order.is_empty())):
			key_names.append(RoomRules.door_icon(_map.room(room_id).room_type))
	busy.append_array(big_name_rects)
	var here: Rect2 = big_room_rects[_current_id]
	var words := tr(STAMP_TEXT)
	big_stamp_rect = stamp_rect(here, MapPaper.stamp_size(words, HudStyle.SMALL), busy)
	MapPaper.stamp(canvas, big_stamp_rect, words, HudStyle.SMALL)
	_paint_key(canvas, icons, key_names, kinds_in_order)


# A walked room's pickups left behind: each kind's ink picture in its own slot beside the sign's spot, or
# with more kinds than slots, dots in the last. Returns the slots drawn in.
func _paint_leftovers(canvas: Object, rect: Rect2, room: Vector2, kinds: Array[String]) -> Array[Rect2]:
	var slots := leftover_slots(rect, room)
	var marks := leftover_marks(kinds, slots.size())
	var drawn: Array[Rect2] = []
	for i in marks.size():
		MapPaper.ink_picture(canvas, leftover_origin(slots[i], marks[i]), LEFTOVER_ICONS[marks[i]])
		drawn.append(slots[i])
	return drawn


# The floor's name, the close prompt right of it, an ink rule under both, and the run's sets.
func _paint_heading(canvas: Object) -> void:
	var size := heading_size(_floor_name)
	MapPaper.text(canvas, Vector2(NAME_BOX.position.x, MapPaper.baseline_in(NAME_BOX, size)), heading_text(_floor_name), size, MapPaper.INK)
	var hint := close_hint(true, ActiveDevice.family) if ActiveDevice.using_pad else KeyBindings.with_key("map", CLOSE_HINT)
	var hint_x := SHEET.end.x - 16.0 - MapPaper.text_width(hint, HudStyle.SMALL)
	MapPaper.text(canvas, Vector2(hint_x, MapPaper.baseline_in(NAME_BOX, HudStyle.SMALL)), hint, HudStyle.SMALL, CaseFile.INK_DIM)
	MapPaper.fill(canvas, Rect2(NAME_BOX.position.x, RULE_Y, SHEET.end.x - 16.0 - NAME_BOX.position.x, 1.0), MapPaper.INK)
	if not set_names.is_empty():
		MapPaper.text(canvas, Vector2(SETS_BOX.position.x, MapPaper.baseline_in(SETS_BOX, HudStyle.SMALL)), sets_text(set_names, SETS_BOX.size.x), HudStyle.SMALL, MapPaper.INK)


# Each corridor the maps draw, once: [room id, room id, walked (ink) or planned (pencil)], pencil first so
# a walked corridor is drawn last.
func _links(shown: Array[int]) -> Array:
	var ink: Array = []
	var pencil: Array = []
	var seen := {}
	for room_id in shown:
		var room := _map.room(room_id)
		for side: Vector2i in room.doors:
			var other_id: int = room.doors[side]
			var key := Vector2i(mini(room_id, other_id), maxi(room_id, other_id))
			if seen.has(key) or not shown.has(other_id) or not corridor_shown(room, _map.room(other_id), _progress, show_plan):
				continue
			seen[key] = true
			var known := _progress.is_visited(room_id) and _progress.is_visited(other_id)
			(ink if known else pencil).append([room_id, other_id, known])
	return pencil + ink


# The room as the big map draws it: the Crossroads is a smaller square in its cell, placed so the middle
# of each of its sides (MapPaper.edge_mid) lines up with the full cell's, and corridors meet its door gaps.
func _drawn_rect(room: FloorRoom, origin: Vector2, spacing: Vector2) -> Rect2:
	var rect := _rect_of(room, origin, spacing)
	if room.room_type != RoomLayout.TYPE_CROSSROADS:
		return rect
	var size := crossroads_rect(rect).size.floor()
	return Rect2(rect.position + (rect.size / 2.0).floor() - (size / 2.0).floor(), size)


# A walked room: its floor, an ink outline with door gaps, and its door's sign in ink (none for a plain
# fight room or the Crossroads). A room shown but not walked into is a pencil outline holding its
# drawn_sign: in ink when he saw it (a door sign from a walked room, Night Vision's "?"), in pencil when
# only the Fortune Teller's Card tells it.
func _paint_room(canvas: Object, room: FloorRoom, origin: Vector2, spacing: Vector2, gaps: Array, with_bosses: bool) -> void:
	var rect := _drawn_rect(room, origin, spacing)
	var size := room_size(spacing)
	var half := MapPaper.corridor_half(size)
	var sign_icon := RoomRules.door_icon(room.room_type)
	var scale := MapPaper.sign_scale(size)
	if _progress.is_visited(room.id):
		MapPaper.fill(canvas, rect, MapPaper.ROOM_FILL)
		# The room he stands in is outlined in the stamp's red, so the stamp's room is never in doubt.
		MapPaper.outline(canvas, rect, MapPaper.outline_width(size), MapPaper.STAMP if room.id == _current_id else MapPaper.INK, gaps, half)
		if room.room_type != RoomLayout.TYPE_CROSSROADS:
			MapPaper.ink_sign(canvas, room_sign_rect(rect, size).get_center(), sign_icon, scale)
		return
	MapPaper.fill(canvas, rect, MapPaper.PAPER)
	MapPaper.outline(canvas, rect, 1, MapPaper.PENCIL, gaps, half)
	var mark := drawn_sign(_map, _progress, room, with_bosses)
	if mark.is_empty():
		return
	var center := room_sign_rect(rect, size).get_center()
	if room.room_type == RoomLayout.TYPE_SECRET or sign_seen(_map, _progress, room):
		MapPaper.ink_sign(canvas, center, mark, scale)
	else:
		MapPaper.ink_sign(canvas, center, mark, scale, MapPaper.PENCIL, MapPaper.PENCIL)


# The Fortune Teller's Card: the boss's name in ink on a patch the size of its words, near the boss room
# where name_rect finds a clear spot. With none clear (a crowded Floor Plan) and a free row in the key,
# it returns false and the key writes the name beside the boss's sign instead; with no free row either,
# it takes the spot covering least. The patch joins big_name_rects.
func _paint_boss_name(canvas: Object, room: FloorRoom, spacing: Vector2, busy: Array[Rect2], key_free: bool) -> bool:
	if not boss_names.has(room.room_type):
		return true
	var words: String = boss_names[room.room_type]
	var size := Vector2(MapPaper.text_width(words, HudStyle.SMALL) + 2.0, MapPaper.glyph_height(HudStyle.SMALL)).ceil()
	var taken: Array[Rect2] = []
	taken.append_array(busy)
	taken.append_array(big_name_rects)
	var patch := name_rect(big_room_rects[room.id], size, spacing, taken)
	if cover(patch, taken) > 0.0 and key_free:
		return false
	MapPaper.fill(canvas, patch, MapPaper.PAPER)
	MapPaper.text(canvas, Vector2(patch.position.x + 1.0, patch.position.y + MapPaper.ascent(HudStyle.SMALL)), words, HudStyle.SMALL, MapPaper.INK)
	big_name_rects.append(patch)
	return true


# How much of the plan a rect would cover.
static func cover(rect: Rect2, busy: Array[Rect2]) -> float:
	var area := 0.0
	for other in busy:
		area += rect.intersection(other).get_area()
	return area


# A boss's name as the key's spare row writes it, after the boss's sign: "Boss: <name>".
static func key_name_text(icon: String, boss_name: String) -> String:
	return TranslationServer.translate(KEY_NAME_FORMATS[icon]) % boss_name


# The key's name row: each boss as key_name_text writes it, or, when the whole row would not fit, each
# name's part before its comma ("Boss: Mortimer Grimsby"), as the small map shortens a long floor name.
static func key_name_row(icons: Array[String], boss_names_in_order: Array[String]) -> PackedStringArray:
	var texts := PackedStringArray()
	for i in icons.size():
		texts.append(key_name_text(icons[i], boss_names_in_order[i]))
	if key_name_row_width(texts) <= key_name_room():
		return texts
	texts.clear()
	for i in icons.size():
		texts.append(key_name_text(icons[i], boss_names_in_order[i].get_slice(",", 0).strip_edges()))
	return texts


# How wide the name row draws: each name after its sign, with a gap before the next.
static func key_name_row_width(texts: PackedStringArray) -> float:
	var width := 0.0
	for words in texts:
		width += DoorSign.SIZE + 2.0 + MapPaper.text_width(words, HudStyle.SMALL) + 2.0 + KEY_NAME_GAP
	return width


static func key_name_room() -> float:
	return KEY_RECT.size.x - KEY_TITLE_WIDTH - 4.0


# Whether the key has a row left under its entries, for boss names that found no clear spot. The Left
# here line, when there is one, takes the first row under the entries before them.
static func key_has_name_row(entries: int, with_leftovers := false) -> bool:
	return ceili(entries / float(KEY_COLUMNS)) + (1 if with_leftovers else 0) < KEY_ROWS


# Where the key's Left here line starts (its first picture's row top): on the row under the entries, or
# with every row taken, after the last entry.
static func leftover_line_at(entries: int) -> Vector2:
	var rows := ceili(entries / float(KEY_COLUMNS))
	if rows < KEY_ROWS:
		return KEY_RECT.position + Vector2(KEY_TITLE_WIDTH, 5.0 + rows * KEY_ROW_HEIGHT)
	return key_entry_at(entries)


# How wide the Left here line draws: its title, then each kind's picture and name.
static func leftover_line_width(kinds: Array[String]) -> float:
	var width := MapPaper.text_width(TranslationServer.translate(LEFTOVER_TITLE), HudStyle.SMALL)
	for kind in kinds:
		width += LEFTOVER_GAP + LEFTOVER_ICON.x + 2.0 + MapPaper.text_width(TranslationServer.translate(LEFTOVER_LABELS[kind]), HudStyle.SMALL)
	return ceilf(width)


# The key's Left here line: "Left here:", then each kind lying in some walked room, as its picture and
# its name.
func _paint_leftover_line(canvas: Object, at: Vector2, kinds: Array[String]) -> void:
	var baseline := at.y + 1.0 + MapPaper.ascent(HudStyle.SMALL)
	var title := tr(LEFTOVER_TITLE)
	MapPaper.text(canvas, Vector2(at.x, baseline), title, HudStyle.SMALL, MapPaper.INK)
	var x := at.x + MapPaper.text_width(title, HudStyle.SMALL)
	for kind in kinds:
		x += LEFTOVER_GAP
		var box := Rect2(x, at.y + floorf((DoorSign.SIZE - LEFTOVER_ICON.y) / 2.0), LEFTOVER_ICON.x, LEFTOVER_ICON.y)
		MapPaper.ink_picture(canvas, leftover_origin(box, kind), LEFTOVER_ICONS[kind])
		x += LEFTOVER_ICON.x + 2.0
		var label := tr(String(LEFTOVER_LABELS[kind]))
		MapPaper.text(canvas, Vector2(x, baseline), label, HudStyle.SMALL, MapPaper.INK)
		x += MapPaper.text_width(label, HudStyle.SMALL)


# The key, a printed box under the plan: each sign drawn on this floor with its name, the Left here line
# when some room has pickups left behind, and on the next row the bosses the Fortune Teller's Card names
# (by their signs) when the plan had no room for them.
func _paint_key(canvas: Object, icons: Array[String], named: Array[String], left_kinds: Array[String]) -> void:
	var ascent := MapPaper.ascent(HudStyle.SMALL)
	MapPaper.frame(canvas, KEY_RECT, 1, MapPaper.INK)
	MapPaper.text(canvas, KEY_RECT.position + Vector2(6, 5 + ascent), tr(KEY_TITLE), HudStyle.SMALL, MapPaper.INK)
	for i in icons.size():
		var at := key_entry_at(i)
		var box := Rect2(at, Vector2(DoorSign.SIZE, DoorSign.SIZE))
		match icons[i]:
			"C":
				MapPaper.frame(canvas, box, 1, MapPaper.INK)
			"+":
				MapPaper.frame(canvas, box.grow(-1.0), 1, MapPaper.INK)
			_:
				MapPaper.ink_sign(canvas, box.get_center(), icons[i], 1)
		if MINI_DOTS.has(icons[i]):
			MapPaper.fill(canvas, key_swatch_rect(at), MINI_DOTS[icons[i]])
		MapPaper.text(canvas, at + Vector2(DoorSign.SIZE + 3.0 + KEY_SWATCH_ROOM, 1.0 + ascent), tr(String(KEY_LABELS[icons[i]])), HudStyle.SMALL, MapPaper.INK)
	var rows := ceilf(icons.size() / float(KEY_COLUMNS))
	if not left_kinds.is_empty():
		_paint_leftover_line(canvas, leftover_line_at(icons.size()), left_kinds)
		rows += 1.0
	var at := KEY_RECT.position + Vector2(KEY_TITLE_WIDTH, 5.0 + rows * KEY_ROW_HEIGHT)
	var full: Array[String] = []
	for icon in named:
		full.append(boss_names[RoomLayout.TYPE_FLOOR_BOSS if icon == "B" else RoomLayout.TYPE_MINI_BOSS])
	var texts := key_name_row(named, full)
	for i in named.size():
		var icon := named[i]
		var words := texts[i]
		MapPaper.ink_sign(canvas, Rect2(at, Vector2(DoorSign.SIZE, DoorSign.SIZE)).get_center(), icon, 1)
		var patch := Rect2(at + Vector2(DoorSign.SIZE + 2.0, 0.0), Vector2(MapPaper.text_width(words, HudStyle.SMALL) + 2.0, MapPaper.glyph_height(HudStyle.SMALL)))
		MapPaper.text(canvas, Vector2(patch.position.x + 1.0, at.y + 1.0 + ascent), words, HudStyle.SMALL, MapPaper.INK)
		big_name_rects.append(patch)
		at.x = patch.end.x + KEY_NAME_GAP


# The close prompt in the top right. On a pad it names the back button (B, or Circle), which closes
# every panel, rather than the map's own View or Create button, whose name reads as an action.
static func close_hint(pad: bool, family: String) -> String:
	if pad:
		return "%s: %s" % [PadInput.button_name(JOY_BUTTON_B, family), CLOSE_HINT]
	return KeyBindings.with_device("map", CLOSE_HINT, false, family)


func _draw_floor_name() -> void:
	var font := ThemeDB.fallback_font
	var shown := mini_name(_floor_name)
	var text: String = shown[0]
	var size: int = shown[1]
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := Vector2(MINI_RECT.end.x - width, NAME_BASELINE)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color.BLACK)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, NAME_COLOR)


# What the mini map writes over itself, and at what size: the whole name when it fits the map's
# width, else smaller, else the part before its comma, so it never runs left over the potion slot
# beside it. Returns [text, font size]. The big map always shows the whole name.
static func mini_name(full: String) -> Array:
	var font := ThemeDB.fallback_font
	var short := full.get_slice(",", 0).strip_edges()
	var tries: Array = [[full, NAME_FONT], [full, NAME_FONT - 1], [short, NAME_FONT], [short, NAME_FONT - 1], [full, MIN_NAME_FONT], [short, MIN_NAME_FONT]]
	for attempt: Array in tries:
		if font.get_string_size(attempt[0], HORIZONTAL_ALIGNMENT_LEFT, -1, attempt[1]).x <= MINI_RECT.size.x:
			return attempt
	return [short, MIN_NAME_FONT]


func _rect_of(room: FloorRoom, origin: Vector2, spacing: Vector2) -> Rect2:
	return room_rect(map_position(_map, room), origin, spacing)
