extends TestCase

# What the third and fourth item batches show works with a controller: the map items' changes are
# drawn on maps the pad opens and closes, and the shop's new wares are pickups his interact takes.


func test_the_map_items_show_on_a_map_the_pad_opens_and_closes() -> void:
	assert_true(PadInput.default_event("map") is InputEventJoypadButton, "the map has a pad button")
	var view := FileAccess.get_file_as_string("res://scripts/ui/floor_map_view.gd")
	assert_true(view.contains("Input.is_action_just_pressed(PadInput.BACK_ACTION)"), "B closes the big map")
	assert_false(view.contains("InputEventMouse"), "nothing on the map waits for a mouse")
	assert_false(view.contains("Button.new()"), "and nothing on it needs focus")
	var scene := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	assert_true(scene.contains("_run.changed.connect(_refresh_map_items)"), "an item taken mid-floor redraws the maps")
	var driver := FileAccess.get_file_as_string("res://tools/smoke_driver.gd")
	assert_true(driver.contains("await _check_pad_map(scene, player)"), "the full loop opens the map with a pad")


func test_the_map_tags_follow_the_items_on_both_maps() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd")
	var refresh := source.substr(source.find("func _refresh_map_items"), 500)
	assert_true(refresh.contains("for view: FloorMapView in [_mini_map, _big_map]"))
	assert_true(refresh.contains("view.show_plan = _run.stats.shows_floor_plan"))
	assert_true(refresh.contains("view.boss_names = names"))


func test_every_shop_ware_is_a_pickup_with_the_shop_prompt() -> void:
	var room := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var entry := room.substr(room.find("func _add_shop_entry"), 2600)
	assert_true(entry.contains("pickup.prompt = SHOP_PROMPT"), "the interact prompt names the pad's button")
	var shop := room.substr(room.find("func _create_shop()"), 700)
	assert_true(shop.contains("_add_shop_entry(RoomBackdrop.cell_center(cells[i]), stock[i])"), "an extra ware is laid out as the others")
