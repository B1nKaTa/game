class_name TerminalProps
extends RefCounted

# Builds what only the departure hall of Departures, Terminal Zero lays out: its luggage trolleys
# (broken like barrels), rows of departure seats (like rocks, and they can hide a coin at the furniture
# rate), stacks of suitcases (like grass), and its queue barrier lines. The room calls this once from
# _create_props, so the room itself only gains one line, and every broken prop goes through the
# room's own handlers, as every other floor's do.


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_LUGGAGE_TROLLEY):
		var trolley := LuggageTrolley.new()
		trolley.palette = palette
		view._place_prop(trolley, cell)
		trolley.broken.connect(view._on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_SEATS):
		var seats := DepartureSeats.new()
		seats.palette = palette
		seats.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
		view._place_prop(seats, cell)
		seats.broken.connect(view._on_rock_broken.bind(seats.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_SUITCASES):
		var stack := SuitcaseStack.new()
		stack.palette = palette
		view._place_prop(stack, cell)
		stack.broken.connect(view._on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_BARRIER):
		var across := layout.barrier_runs_across(cell)
		var before := cell + (Vector2i.UP if across else Vector2i.LEFT)
		var after := cell + (Vector2i.DOWN if across else Vector2i.RIGHT)
		var barrier := QueueBarrier.new()
		barrier.setup(cell, across, free_for_grandpa(layout, before), free_for_grandpa(layout, after))
		barrier.position = RoomBackdrop.cell_center(cell)
		view.add_child(barrier)


# Somewhere a rising rope may push Grandpa: open floor that is not another rope.
static func free_for_grandpa(layout: RoomLayout, cell: Vector2i) -> bool:
	return not layout.is_solid_at(cell) and layout.symbol_at(cell) != RoomLayout.SYMBOL_BARRIER
