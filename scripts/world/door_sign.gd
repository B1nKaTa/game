class_name DoorSign
extends RefCounted

# The small plaque hung in a door's opening (DoorOpening) that says what lies beyond: a money bag for the
# shop, a skull for a boss, a chest for treasure and so on, in place of the old room letter. A plain fight
# room shows none. The pictures are pixel maps here, so they stay crisp at any size the game shows.
# Keys are the room letters of RoomRules.ICONS; '#' is the outline, 'o' the main colour, 'w' a highlight
# and 'd' a darker shade.
const PLATE := Color("3a2a1e")
const PLATE_LIGHT := Color("6b5238")
const PLATE_EDGE := Color(0.02, 0.02, 0.03)
const CHAIN := Color("8a8478")
const SIZE := 9
# No sign for these: a plain fight room, and the way back.
const NONE := ["C", "<"]
const PICTURES := {
	"$": ["..##.##..", "...#d#...", "..#ooo#..", ".#oowoo#.", "#oowwwoo#", "#ooowooo#", "#oowwwoo#", ".#ooooo#.", "..#####.."],
	"B": [".#######.", "#ooooooo#", "#owoooow#", "#o##o##o#", "#o##o##o#", "#ooo#ooo#", ".#ooooo#.", "..#o#o#..", "..#####.."],
	"M": [".........", "..#####..", ".#ooooo#.", ".#o#o#o#.", ".#o#o#o#.", ".#oo#oo#.", "..#ooo#..", "..#o#o#..", "..#####.."],
	"T": [".#######.", "#ooooooo#", "#owwwwwo#", "#########", "#ddd#w#d#", "#ooo###o#", "#ooooooo#", "#ddddddd#", "#########"],
	"I": ["....#....", "...#w#...", "####w####", "#owwwwwo#", ".#ooooo#.", "..#ooo#..", ".#oo#oo#.", ".#o#.#o#.", ".##...##."],
	# A pill, as the HUD counts health: the old medical plus read as a cross at 1x.
	"H": [".........", ".........", ".#######.", "#ooo#ddd#", "#owo#ddd#", "#ooo#ddd#", ".#######.", ".........", "........."],
	"?": ["..#####..", ".#ooooo#.", "#oo###oo#", ".##..#oo#", "....#oo#.", "...#oo#..", "...####..", "...#oo#..", "...####.."],
	"S": [".........", "..#####..", ".#ooooo#.", "#oo###oo#", "#o#d#w#o#", "#oo###oo#", ".#ooooo#.", "..#####..", "........."],
	"V": ["..#####..", ".#o###o#.", ".#o#.#o#.", "#########", "#ooooooo#", "#ooo#ooo#", "#ooo#ooo#", "#ooooooo#", "#########"],
	# A signpost with its board pointing on from the top of the post: a post running through the board read
	# as a cross at 1x (tests/test_art_direction.gd checks every sign).
	"+": ["#######..", "#ooooo##.", "#oooooo##", "#ooooo##.", "#o#####..", "#o#......", "#o#......", "#o#......", "###......"],
	"v": ["#########", "#ooo#####", "#ooo#####", "####ooo##", "####ooo##", "#######oo", "#######oo", "#########", "........."],
}
const COLORS := {
	"$": Color("e2b33c"), "B": Color("ece9e0"), "M": Color("d8c7a0"), "T": Color("a8692f"), "I": Color("ffd65c"),
	"H": Color("ece9e0"), "?": Color("b9c2d6"), "S": Color("9fb7a8"), "V": Color("8fa3b8"), "+": Color("c9a25a"),
	"v": Color("9a8f80"),
}


static func has_sign(icon: String) -> bool:
	return not NONE.has(icon) and (PICTURES.has(icon) or icon == RoomRules.ARCADE_ICON)


# Draws the plaque with its middle at `at`, hanging on two short chains.
static func draw(canvas: CanvasItem, at: Vector2, icon: String) -> void:
	if not has_sign(icon):
		return
	var half := (SIZE + 4) / 2.0
	var plate := Rect2((at - Vector2(half, half)).floor(), Vector2(SIZE + 4, SIZE + 4))
	canvas.draw_rect(Rect2(plate.position + Vector2(2, -4), Vector2(1, 4)), CHAIN)
	canvas.draw_rect(Rect2(plate.position + Vector2(plate.size.x - 3, -4), Vector2(1, 4)), CHAIN)
	canvas.draw_rect(plate.grow(1), PLATE_EDGE)
	canvas.draw_rect(plate, PLATE)
	canvas.draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), PLATE_LIGHT)
	if icon == RoomRules.ARCADE_ICON:
		ArcadeTable.draw_die(canvas, plate.get_center(), 9.0)
		return
	var main: Color = COLORS[icon]
	var rows: Array = PICTURES[icon]
	var origin := plate.position + Vector2(2, 2)
	for y in rows.size():
		var row: String = rows[y]
		for x in mini(row.length(), SIZE):
			var c := row[x]
			var color := Color.TRANSPARENT
			match c:
				"#":
					color = PLATE_EDGE
				"o":
					color = main
				"w":
					color = main.lightened(0.45)
				"d":
					color = main.darkened(0.35)
			if color.a > 0.0:
				canvas.draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)
