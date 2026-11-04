class_name GolfProps
extends RefCounted

# What a Fairway's End room lays out from its layout, called once from RoomView._create_props: the sand
# bunkers in the fairway. It keeps the golf course's own pieces out of the shared room code.


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_SAND):
		var sand := SandTrap.new()
		sand.palette = palette
		sand.position = RoomBackdrop.cell_center(cell)
		view.add_child(sand)


# The golf course's lingering effects, which a stored room clears when Grandpa leaves. RoomView's own
# is_passing_effect asks this too.
static func is_passing_effect(child: Node) -> bool:
	return child is BunkerPatch or child is PuttRoll or child is SprinklerSweep
