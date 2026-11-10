extends TestCase

# Item icons are drawn wherever an item shows once the art pass drops a PNG at its path; until then
# every place keeps its old look.


func _icon() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.ORANGE)
	return ImageTexture.create_from_image(image)


func _item(id: String, item_name: String) -> ItemDef:
	var item := ItemDef.new()
	item.id = id
	item.display_name = item_name
	return item


func test_an_icon_path_names_the_item() -> void:
	assert_eq(ItemIcons.path("tea_urn"), "res://art/icons/items/tea_urn.png")
	assert_eq(CaseFileData.ITEM_ICON_DIR, ItemIcons.DIR)


func test_no_png_means_no_icon_and_a_test_icon_is_used() -> void:
	ItemIcons.clear_test()
	assert_true(ItemIcons.texture("no_such_item_anywhere") == null)
	assert_true(ItemIcons.texture("") == null)
	var icon := _icon()
	ItemIcons.set_for_test("tea_urn", icon)
	assert_eq(ItemIcons.texture("tea_urn"), icon)
	ItemIcons.clear_test()


func test_a_pickup_draws_its_icon_only_when_there_is_one() -> void:
	ItemIcons.clear_test()
	var pickup := Pickup.new()
	# A made-up id: real icons are arriving in art/icons/items/ (LESSONS 2026-11-09).
	pickup.icon_id = "no_icon_test_item"
	assert_false(pickup.draws_icon(), "no PNG: the disc stays")
	ItemIcons.set_for_test("no_icon_test_item", _icon())
	assert_true(pickup.draws_icon())
	pickup.free()
	ItemIcons.clear_test()


func test_room_item_pickups_and_wares_name_their_icon() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	var mark := source.substr(source.find("func _mark_item"), 200)
	assert_true(mark.contains("pickup.icon_id = item.id"), "every item pickup and item ware goes through _mark_item")


func test_the_item_row_keeps_names_until_an_icon_exists() -> void:
	ItemIcons.clear_test()
	var items: Array[ItemDef] = [_item("test_a", "Alpha"), _item("test_b", "Beta"), _item("test_c", "Gamma"), _item("test_d", "Delta")]
	var entries := Hud.item_row_entries(items)
	assert_eq(entries.size(), Hud.ITEMS_SHOWN)
	assert_eq(entries[0]["name"], "Delta", "newest first")
	assert_true(entries[0]["icon"] == null)
	var icon := _icon()
	ItemIcons.set_for_test("test_c", icon)
	entries = Hud.item_row_entries(items)
	var pieces := ItemRow.pieces(items.size(), entries)
	assert_eq(pieces[0], ["text", "Items: 4   "])
	assert_eq(pieces[1], ["text", "Delta, "])
	assert_eq(pieces[2], ["icon", icon])
	assert_eq(pieces[3], ["text", "Beta"])
	ItemIcons.clear_test()


func test_the_case_file_takes_its_item_icons_from_item_icons() -> void:
	ItemIcons.clear_test()
	var item := _item("no_icon_test_item", "Test Item")
	var cell := CaseFileData.item_cell(item, true, 1)
	assert_true(CaseFile.cell_texture(cell) == null)
	var icon := _icon()
	ItemIcons.set_for_test("no_icon_test_item", icon)
	assert_eq(CaseFile.cell_texture(cell), icon)
	ItemIcons.clear_test()
