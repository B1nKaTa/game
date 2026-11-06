class_name SeanceProps
extends RefCounted

# What a Seance Hotline room lays out from its layout, called once from RoomView._create_props: the
# violet cubicle partitions, the psychics' desks, the seance tables, the lava lamps and the beaded
# curtains. Filing trays are Head Office's in-trays, which the room lays itself. It keeps the hotline's
# own pieces out of the shared room code, and hands each broken prop to the room's own handlers, so a
# partition, a desk or a table hides a coin at the furniture rate and a lava lamp holds nothing.
#
# Two desk cells side by side are one wide desk, paired from the west along a row, and four table cells
# in a square are one round table, so each piece's art (64x48 and 64x64) fits the cells it stands on.
# A desk cell left over at a row's end is a narrow desk, and a table cell with no square a small one.


static func build(view: RoomView, layout: RoomLayout, palette: RoomPalette) -> void:
	for cell in layout.cells_of(RoomLayout.SYMBOL_PARTITION):
		var partition := SeancePartition.new()
		partition.palette = palette
		partition.joins_west = layout.symbol_at(cell + RoomLayout.WEST) == RoomLayout.SYMBOL_PARTITION
		partition.joins_east = layout.symbol_at(cell + RoomLayout.EAST) == RoomLayout.SYMBOL_PARTITION
		partition.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
		view._place_prop(partition, cell)
		partition.broken.connect(view._on_rock_broken.bind(partition.hides_coin, cell))
	for cells: Array in desk_groups(layout):
		var desk := PsychicDesk.new()
		desk.wide = cells.size() == 2
		_place_piece(view, desk, cells, palette)
	for cells: Array in table_groups(layout):
		var table := SeanceTable.new()
		table.large = cells.size() == 4
		_place_piece(view, table, cells, palette)
	for cell in layout.cells_of(RoomLayout.SYMBOL_LAVA_LAMP):
		var lamp := LavaLamp.new()
		lamp.palette = palette
		view._place_prop(lamp, cell)
		lamp.broken.connect(view._on_vase_broken.bind(cell))
	for cell in layout.cells_of(RoomLayout.SYMBOL_BEADED_CURTAIN):
		var curtain := BeadedCurtain.new()
		curtain.palette = palette
		curtain.toucher = view._player
		curtain.position = RoomBackdrop.cell_center(cell)
		view.add_child(curtain)


# A piece over several cells stands at their middle, hides one coin at the furniture rate, and opens
# every cell it covers when it breaks.
static func _place_piece(view: RoomView, piece: RockBlock, cells: Array, palette: RoomPalette) -> void:
	piece.palette = palette
	piece.hides_coin = RoomRules.furniture_hides_coin(view._prop_coin_roll())
	piece.position = middle_of(cells)
	view.add_child(piece)
	piece.broken.connect(view._on_rock_broken.bind(piece.hides_coin, cells[0]))
	# One signal may hold a room handler only once, whatever it is bound to, so the other cells open
	# through one call that walks them.
	if cells.size() > 1:
		piece.broken.connect(_open_cells.bind(view, cells.slice(1)))


static func _open_cells(at: Vector2, view: RoomView, cells: Array) -> void:
	for cell: Vector2i in cells:
		view._on_vase_broken(at, cell)


static func middle_of(cells: Array) -> Vector2:
	var sum := Vector2.ZERO
	for cell: Vector2i in cells:
		sum += RoomBackdrop.cell_center(cell)
	return sum / cells.size()


# The desks of a room, each the cells it stands on: along each row, a run of desk cells pairs up from
# the west, and a cell left over at the run's east end is a narrow desk of its own.
static func desk_groups(layout: RoomLayout) -> Array[Array]:
	var groups: Array[Array] = []
	var size := layout.size_in_cells()
	for y in size.y:
		var x := 0
		while x < size.x:
			if layout.symbol_at(Vector2i(x, y)) != RoomLayout.SYMBOL_DESK:
				x += 1
				continue
			var cells: Array[Vector2i] = [Vector2i(x, y)]
			if layout.symbol_at(Vector2i(x + 1, y)) == RoomLayout.SYMBOL_DESK:
				cells.append(Vector2i(x + 1, y))
			groups.append(cells)
			x += cells.size()
	return groups


# The seance tables of a room: in reading order, a table cell with table cells east, south and
# south-east of it, none yet taken, is the top left of a round table over all four; any other is a
# small table of its own.
static func table_groups(layout: RoomLayout) -> Array[Array]:
	var groups: Array[Array] = []
	var taken := {}
	for cell in layout.cells_of(RoomLayout.SYMBOL_SEANCE_TABLE):
		if taken.has(cell):
			continue
		var square: Array[Vector2i] = [cell, cell + Vector2i(1, 0), cell + Vector2i(0, 1), cell + Vector2i(1, 1)]
		var whole := true
		for part in square:
			if layout.symbol_at(part) != RoomLayout.SYMBOL_SEANCE_TABLE or taken.has(part):
				whole = false
		var cells: Array[Vector2i] = [cell]
		if whole:
			cells = square
		for part in cells:
			taken[part] = true
		groups.append(cells)
	return groups


# The hotline's lingering effects, which a stored room clears when Grandpa leaves. RoomView's own
# is_passing_effect asks this too. Each attack of the floor adds its own here: the psychic's cord,
# the gazer's ball and the ectoplasm's trail (the poltergeist's objects are plain shots), then Sister
# Celestine's cards and what they do.
static func is_passing_effect(child: Node) -> bool:
	return (child is PhoneCordLash or child is CrystalBall or child is EctoplasmTrail
		or child is TarotCard or child is TowerTiles or child is ScytheSweep or child is WheelRing or child is StarFall)
