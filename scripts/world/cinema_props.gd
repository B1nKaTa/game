class_name CinemaProps
extends RefCounted

# What a Flashback Cinema room lays out from its layout, called once from RoomView._create_props: the
# rows of seats, the pillars and the aisle lights at the ends of the rows. It keeps the picture house's
# own pieces out of the shared room code, and hands each broken seat to the room's own handlers, so a
# seat hides a coin at the furniture rate as a pew does. Pillars never break.
# Aisle lights stand at the open ends of seat rows, at most this many to a room.
const MAX_AISLE_LIGHTS := 8
# How far from its cell's middle an aisle light sits, towards the row it lights, and down to its foot.
const AISLE_LIGHT_INSET := 11.0
const AISLE_LIGHT_DROP := 9.0


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_SEAT):
		var seat := CinemaSeat.new()
		seat.palette = palette
		seat.joins_west = layout.symbol_at(cell + RoomLayout.WEST) == RoomLayout.SYMBOL_SEAT
		seat.joins_east = layout.symbol_at(cell + RoomLayout.EAST) == RoomLayout.SYMBOL_SEAT
		seat.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
		view._place_prop(seat, cell)
		seat.broken.connect(view._on_rock_broken.bind(seat.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_PILLAR):
		var pillar := CinemaPillar.new()
		pillar.palette = palette
		pillar.position = RoomBackdrop.cell_center(cell)
		view.add_child(pillar)
	for spot in aisle_light_spots(layout):
		var light := AisleLight.new()
		light.palette = palette
		light.position = spot
		view.add_child(light)
	for cell in layout.cells_of(RoomLayout.SYMBOL_LIFE_SIGN):
		var card := LifeSign.new()
		card.position = RoomBackdrop.cell_center(cell)
		card.setup(view._player, func() -> String: return take_life_sign(view))
		view.add_child(card)
	if palette.screen and view._room != null and CinemaScenes.shows_screen(view._room.room_type):
		add_screen(view, layout, palette, scene_for(view._map, view._room), view._room.decor_seed)


# A lobby card's line, the first time it shows: picked by the floor's seed, never one this run has
# shown, and saved as seen at once (Progress.take_life_sign).
static func take_life_sign(view: RoomView) -> String:
	var shown: Array[String] = []
	if view._run != null:
		shown = view._run.life_signs_shown
	var seed_text := life_sign_seed(view._run, view._room)
	if view._bank != null and view._bank.has_method("take_life_sign"):
		return view._bank.take_life_sign(seed_text, shown)
	return LifeSigns.take(seed_text, null, shown)


# The run's seed for its lobby cards: the seed the floor was built from, which the run keeps for its
# checkpoint, so a resumed run picks its lines in the same order.
static func life_sign_seed(run: RunState, room: FloorRoom) -> String:
	if run != null and not run.seeds.is_empty():
		return run.seeds[-1]
	return str(room.decor_seed) if room != null else ""


# The film a room shows: its own pick, kept apart from the rooms next door on its floor.
static func scene_for(map: FloorMap, room: FloorRoom) -> String:
	if map == null:
		return CinemaScenes.pick(room.decor_seed)
	return CinemaScenes.assign(map).get(room.id, CinemaScenes.pick(room.decor_seed))


# The screen on the north wall and the projector's beam up to it, both drawn at the room's origin.
static func add_screen(view: Node2D, layout: RoomLayout, palette: RoomPalette, scene_id: String, room_seed: int) -> CinemaScreen:
	var screen := CinemaScreen.new()
	screen.palette = palette
	screen.setup(layout, scene_id, room_seed)
	view.add_child(screen)
	var beam := CinemaBeam.new()
	beam.palette = palette
	beam.setup(screen, CinemaScreen.picture_rect_for(CinemaScreen.wall_rect(layout)), Vector2(layout.size_in_cells() * RoomBackdrop.TILE))
	view.add_child(beam)
	return screen


# The plain floor cell just past each end of a seat row, as {cell, toward}: toward is the way to the
# row's end. Cells touching a door are skipped, so a doorway stays dark and plain.
static func aisle_light_cells(layout: RoomLayout) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for cell in layout.cells_of(RoomLayout.SYMBOL_SEAT):
		for side: Vector2i in [RoomLayout.WEST, RoomLayout.EAST]:
			var beyond := cell + side
			if layout.symbol_at(beyond) != RoomLayout.SYMBOL_FLOOR or layout.touches_a_door(beyond):
				continue
			found.append({"cell": beyond, "toward": -side})
	return found


# Where the aisle lights stand in the room, spread evenly over the row ends when there are too many.
static func aisle_light_spots(layout: RoomLayout) -> Array[Vector2]:
	var ends := aisle_light_cells(layout)
	var spots: Array[Vector2] = []
	if ends.is_empty():
		return spots
	var count := mini(ends.size(), MAX_AISLE_LIGHTS)
	for i in count:
		var end: Dictionary = ends[i * ends.size() / count]
		var toward: Vector2i = end["toward"]
		spots.append(RoomBackdrop.cell_center(end["cell"]) + Vector2(toward) * AISLE_LIGHT_INSET + Vector2(0, AISLE_LIGHT_DROP))
	return spots
