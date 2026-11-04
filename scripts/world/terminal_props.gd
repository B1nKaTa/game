class_name TerminalProps
extends RefCounted

# Builds what only the departure hall of Departures, Terminal Zero lays out: its queue barrier lines.
# The room calls this once from _create_props, so the room itself only gains one line.


static func build(view: RoomView, layout: RoomLayout, _palette: RoomPalette) -> void:
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
