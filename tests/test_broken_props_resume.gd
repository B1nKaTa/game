extends TestCase

# Props broken before a save and quit stay broken when the run is resumed (playtest 9).

const BARREL := Vector2i(3, 3)
const ROCK := Vector2i(5, 3)
const VASE := Vector2i(7, 3)
const BLOCK := Vector2i(9, 3)


func _layout() -> RoomLayout:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_COMBAT
	var rows := ["####################"]
	for y in range(1, 10):
		rows.append("#..................#")
	rows.append("####################")
	rows[3] = "#..Q.O.f.X.........#"
	layout.rows = PackedStringArray(rows)
	return layout


func _view(restore: Dictionary, seed_value := 5) -> RoomView:
	var room := FloorRoom.new()
	room.layout = _layout()
	room.room_type = RoomLayout.TYPE_COMBAT
	room.decor_seed = 4
	var no_upgrades: Array[UpgradeDef] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var view := RoomView.new()
	var def: FloorDef = load("res://data/floors/floor_1.tres")
	view.setup(room, null, def, RunState.new(no_upgrades, {}), null, rng, null, null)
	view.restore = restore
	view._ready()
	return view


func _props_at(view: RoomView, cell: Vector2i) -> int:
	var count := 0
	for child in view.get_children():
		if child is BreakableBlock and view._cell_of(child.position) == cell:
			count += 1
	return count


func test_snapshot_lists_the_broken_cells_sorted() -> void:
	var view := _view({})
	view._mark_broken(VASE)
	view._mark_broken(BARREL)
	view._mark_broken(Vector2i(3, 1))
	assert_eq(view.snapshot()["broken"], [[3, 1], [3, 3], [7, 3]])
	view.free()


func test_a_fresh_room_lists_nothing_broken() -> void:
	var view := _view({})
	assert_eq(view.snapshot()["broken"], [])
	view.free()


func test_a_restored_room_has_no_prop_on_a_broken_cell_and_the_cell_is_open() -> void:
	var shot := {"cleared": true, "keep": [], "broken": [[BARREL.x, BARREL.y], [VASE.x, VASE.y], [BLOCK.x, BLOCK.y]]}
	var view := _view(shot)
	assert_eq(_props_at(view, BARREL), 0)
	assert_eq(_props_at(view, VASE), 0)
	assert_eq(_props_at(view, BLOCK), 0)
	assert_eq(_props_at(view, ROCK), 1, "the unbroken rock stays")
	assert_true(view._walk_grid.is_open(BARREL))
	assert_true(view._walk_grid.is_open(BLOCK))
	assert_false(view._walk_grid.is_open(ROCK))
	assert_eq(view.snapshot()["broken"], [[3, 3], [7, 3], [9, 3]], "and it saves them again")
	view.free()


func test_an_old_snapshot_without_the_key_restores_every_prop() -> void:
	var view := _view({"cleared": true, "keep": []})
	for cell in [BARREL, ROCK, VASE, BLOCK]:
		assert_eq(_props_at(view, cell), 1)
	view.free()


func test_breaking_props_on_resume_leaves_the_rng_where_it_was() -> void:
	var whole := _view({"cleared": true, "keep": []})
	var cut := _view({"cleared": true, "keep": [], "broken": [[BARREL.x, BARREL.y], [ROCK.x, ROCK.y], [VASE.x, VASE.y]]})
	assert_eq(cut._rng.randi(), whole._rng.randi())
	whole.free()
	cut.free()
