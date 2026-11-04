class_name CruiseProps
extends RefCounted

# What a room of the Last Resort Cruise builds beyond the usual props: the rolling deck in a room whose
# layout rolls. RoomView calls build once, from _create_props, so its own code stays as it was.


static func build(view: RoomView, layout: RoomLayout, _palette: RoomPalette) -> void:
	if layout.ship_rolls:
		var deck := ShipDeck.new()
		deck.setup(layout, view._room.decor_seed, view.clear_spot, view._player)
		view.add_child(deck)


# Anything a cruise attack leaves in the room for a while, which a stored room must clear.
static func is_passing_effect(_child: Node) -> bool:
	return false
