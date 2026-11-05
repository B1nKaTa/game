extends TestCase

# The items' key moments make a sound through ctx.play_sound, which CombatFeedback sends to the Sounds
# autoload, and every name an item asks for is one the game can play.

# A sound each of these items must ask for at its key moment (batches 3 and 4).
const KEY_SOUNDS := {
	"kettle_whistle": "steam_hiss",
	"rubber_stamps": "form_filed",
	"pension_statement": "coin",
	"inheritance_letter": "coin",
	"lottery_scratcher": "slot_win",
	"tax_refund": "coin",
	"expired_coupon": "ui_ching",
	"forged_signature": "slip_pickup",
	"eternal_warranty": "lethal_save",
	"bureaucrats_stamp": "form_filed",
	"complaint_form": "ticket_ding",
	"lawyers_card": "shield_block",
	"fortune_card": "card_flip",
	"polyester_suit": "small_blast",
	"harmonica": "pill_heal",
	"family_visit": "pill_heal",
	"grief_counselor": "coin",
	"bingo_hall_pass": "bingo",
	"moving_boxes": "thermos_pickup",
	"early_bird_special": "charge_ready",
	"magnifying_glass": "chime",
}


func _sounds_in(path: String) -> Array[String]:
	var found: Array[String] = []
	var regex := RegEx.new()
	regex.compile("play_sound\\(\"([a-z_0-9]+)\"\\)")
	for match in regex.search_all(FileAccess.get_file_as_string(path)):
		found.append(match.get_string(1))
	return found


func test_every_item_sound_is_one_the_game_can_play() -> void:
	var dir := "res://scripts/items/"
	var checked := 0
	for file in DirAccess.get_files_at(dir):
		if not file.ends_with(".gd"):
			continue
		for sound in _sounds_in(dir + file):
			assert_true(SoundBank.can_play(sound), "%s asks for '%s', which nothing plays" % [file, sound])
			checked += 1
	assert_true(checked >= KEY_SOUNDS.size(), "the items ask for their sounds")


func test_the_key_moments_of_batches_three_and_four_have_sounds() -> void:
	for id: String in KEY_SOUNDS:
		var sounds := _sounds_in("res://scripts/items/%s.gd" % id)
		assert_true(sounds.has(KEY_SOUNDS[id]), "%s plays %s, got %s" % [id, KEY_SOUNDS[id], str(sounds)])


func test_paying_items_ring_the_coin() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["inheritance_letter", "grief_counselor", "tax_refund"])
	assert_eq(kit.sounds, ["coin"] as Array[String], "the letter pays on taking it")
	run.effects.room_clear(null)
	assert_eq(kit.sounds.size(), 2, "a flawless room pays the counselor")
	run.effects.effect_of("tax_refund").leave_shop(run.effects.ctx, 2, 0)
	assert_eq(kit.sounds, ["coin", "coin", "coin"] as Array[String])


func test_the_stamps_sound_like_stamps() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["rubber_stamps"])
	run.effects.slip_spent(false)
	assert_eq(kit.sounds, ["form_filed"] as Array[String])
	var stamp := FileAccess.get_file_as_string("res://scripts/items/bureaucrats_stamp.gd")
	assert_false(stamp.contains("play_sound(\"stamp\")"), "no sound is named stamp")


func test_the_warranty_sounds_its_save() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["eternal_warranty"])
	assert_true(run.effects.lethal())
	run.effects.saved()
	assert_true(kit.sounds.has("lethal_save"))


func test_a_free_shop_rings_the_till_once() -> void:
	var kit := ItemKit.new()
	var run := kit.run_with(["expired_coupon"])
	var stock: Array[Dictionary] = [{"kind": ShopRules.KIND_HEAL, "price": 20}]
	run.effects.shop_open(stock)
	run.effects.shop_open(stock)
	assert_eq(kit.sounds, ["ui_ching"] as Array[String])


func test_item_sounds_reach_the_sounds_autoload() -> void:
	var ctx := FileAccess.get_file_as_string("res://scripts/core/effect_context.gd")
	var play := ctx.substr(ctx.find("func play_sound"), 300)
	assert_true(play.contains("feedback.play(sound_name)"))
	var feedback := FileAccess.get_file_as_string("res://scripts/world/combat_feedback.gd")
	assert_true(feedback.contains("Sfx.play(sound_name)"))
