class_name GolfProps
extends RefCounted

# What a Fairway's End room lays out from its layout, called once from RoomView._create_props: the sand
# bunkers in the fairway, flag pins, ball washers, hedges and parked carts. It keeps the golf course's
# own pieces out of the shared room code, and hands each broken prop to the room's own handlers, so
# drops and coins follow the room's rules: a ball washer drops as a barrel does, a hedge or a parked
# cart can hide a coin at the furniture rate, and a flag pin holds nothing.


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_SAND):
		var sand := SandTrap.new()
		sand.palette = palette
		sand.position = RoomBackdrop.cell_center(cell)
		view.add_child(sand)
	for cell in layout.cells_of(RoomLayout.SYMBOL_FLAG):
		var flag := FlagPin.new()
		flag.palette = palette
		view._place_prop(flag, cell)
		flag.broken.connect(view._on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_BALL_WASHER):
		var washer := BallWasher.new()
		washer.palette = palette
		view._place_prop(washer, cell)
		washer.broken.connect(view._on_barrel_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_HEDGE):
		var solid: RockBlock
		if is_parked_cart(layout, cell):
			solid = ParkedCart.new()
		else:
			solid = Hedge.new()
		solid.palette = palette
		solid.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
		view._place_prop(solid, cell)
		solid.broken.connect(view._on_rock_broken.bind(solid.hides_coin, cell))


# A hedge cell with no hedge beside it, above, below or to either side, is a cart parked on its own.
static func is_parked_cart(layout: RoomLayout, cell: Vector2i) -> bool:
	if layout.symbol_at(cell) != RoomLayout.SYMBOL_HEDGE:
		return false
	for side in RoomLayout.SIDES:
		if layout.symbol_at(cell + side) == RoomLayout.SYMBOL_HEDGE:
			return false
	return true


# The golf course's lingering effects, which a stored room clears when Grandpa leaves. RoomView's own
# is_passing_effect asks this too.
static func is_passing_effect(child: Node) -> bool:
	return child is BunkerPatch or child is PuttRoll or child is SprinklerSweep
