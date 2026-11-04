class_name CruiseProps
extends RefCounted

# What a room of the Last Resort Cruise builds beyond the usual props: deck chairs that break like
# barrels, buffet trays that break like grass, lifeboat davits that break like rocks and can hide a coin
# as furniture does, the pool's water, and the rolling deck in a room whose layout rolls. RoomView calls
# build once, from _create_props, and hands each break back to its own handlers, so a broken cruise prop
# frees its cell and drops what the same kind of prop drops anywhere else.


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_DECK_CHAIR):
		var chair := DeckChair.new()
		chair.palette = palette
		view._place_prop(chair, cell)
		chair.broken.connect(view._on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_BUFFET_TRAY):
		var tray := BuffetTray.new()
		tray.palette = palette
		view._place_prop(tray, cell)
		tray.broken.connect(view._on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_DAVIT):
		var davit := LifeboatDavit.new()
		davit.palette = palette
		davit.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
		view._place_prop(davit, cell)
		davit.broken.connect(view._on_rock_broken.bind(davit.hides_coin, cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_POOL):
		var water := PoolWater.new()
		water.palette = palette
		water.position = RoomBackdrop.cell_center(cell)
		view.add_child(water)
	if layout.ship_rolls:
		var deck := ShipDeck.new()
		deck.setup(layout, view._room.decor_seed, view.clear_spot, view._player)
		view.add_child(deck)


# Anything a cruise attack leaves in the room for a while, which a stored room must clear.
static func is_passing_effect(child: Node) -> bool:
	return (child is ShuffleboardPuck or child is DeckLane or child is QuoitRing or child is AnchorDrop
		or child is FoghornBlast)
