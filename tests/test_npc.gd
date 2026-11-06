extends TestCase

const MERCHANT_PATH := "res://data/npcs/shop_merchant.tres"


func _lines(texts: Array) -> Array[String]:
	var lines: Array[String] = []
	lines.assign(texts)
	return lines


func _shops() -> Array[RoomLayout]:
	var shops: Array[RoomLayout] = []
	for folder in ["floor_1", "cemetery", "sunset_shores"]:
		for layout in RoomCatalog.load_valid("res://data/rooms/%s/" % folder):
			if layout.room_type == RoomLayout.TYPE_SHOP:
				shops.append(layout)
	return shops


# --- talking ---

func test_each_press_says_the_next_line_and_goes_round_again() -> void:
	var talk := NpcTalk.new(_lines(["One.", "Two.", "Three."]))
	assert_eq(talk.showing(), "", "nothing until he is asked")
	assert_eq(talk.talk(), "One.")
	assert_eq(talk.showing(), "One.")
	assert_eq(talk.talk(), "Two.", "a press while a line shows moves on")
	assert_eq(talk.talk(), "Three.")
	assert_eq(talk.talk(), "One.", "after the last comes the first")


func test_a_line_fades_after_a_few_seconds() -> void:
	var talk := NpcTalk.new(_lines(["Hello."]))
	talk.talk()
	talk.tick(NpcTalk.SHOW_TIME - 0.1)
	assert_eq(talk.showing(), "Hello.")
	talk.tick(0.2)
	assert_eq(talk.showing(), "")
	assert_true(NpcTalk.SHOW_TIME >= 2.0 and NpcTalk.SHOW_TIME <= 5.0, "a few seconds")


func test_someone_with_nothing_to_say_says_nothing() -> void:
	var talk := NpcTalk.new(_lines([]))
	assert_eq(talk.talk(), "")
	assert_eq(talk.showing(), "")


func test_talking_needs_him_in_reach() -> void:
	var none: Array[float] = []
	assert_true(NpcTalk.answers(30.0, 40.0, none))
	assert_false(NpcTalk.answers(41.0, 40.0, none))


func test_the_nearest_thing_answers_the_interact_key() -> void:
	var ware_near: Array[float] = [10.0]
	var ware_far: Array[float] = [35.0]
	assert_false(NpcTalk.answers(20.0, 40.0, ware_near), "a ware nearer than him takes the press")
	assert_true(NpcTalk.answers(20.0, 40.0, ware_far), "he is nearer than the ware")


# --- the merchant ---

func test_the_merchant_is_a_plain_placeholder_with_three_lines() -> void:
	var def: NpcDef = load(MERCHANT_PATH)
	assert_eq(def.id, "shop_merchant")
	assert_eq(def.display_name, "Shopkeeper")
	assert_eq(def.lines.size(), 3)
	for line in def.lines:
		assert_false(line.is_empty())
	assert_true(def.body_size.x > 0.0 and def.body_size.y > 0.0)
	assert_true(def.color.get_luminance() >= 0.3, "bright enough to read in a dim room")


func test_nothing_can_hit_the_merchant_or_bump_into_him() -> void:
	var npc := Npc.new()
	npc.setup(load(MERCHANT_PATH), null)
	npc._ready()
	# An Npc is a Node2D, never a body, so only its children could be solid.
	assert_false(npc.is_in_group("enemies"))
	assert_false(npc.is_in_group("breakable"))
	for child in npc.get_children():
		assert_false(child is CollisionObject2D or child is CollisionShape2D, "nothing solid")
	npc.free()


func test_the_merchant_talks_through_his_lines() -> void:
	var def: NpcDef = load(MERCHANT_PATH)
	var npc := Npc.new()
	npc.setup(def, null)
	assert_eq(npc.talk(), def.lines[0])
	assert_eq(npc.showing(), def.lines[0])
	assert_eq(npc.talk(), def.lines[1])
	npc.free()


# --- where he stands ---

func test_every_shop_has_a_spot_for_the_merchant_clear_of_everything_else() -> void:
	var shops := _shops()
	assert_true(shops.size() >= 3)
	for layout in shops:
		var cell := layout.merchant_cell()
		var placed: Array[Vector2i] = [cell]
		var rewards := layout.plan_reward_cells(ProgressData.RETIREMENT_TIERS.size(), placed)
		var name := layout.resource_path
		assert_eq(rewards.size(), ProgressData.RETIREMENT_TIERS.size(), "%s: every tier still has a spot" % name)
		assert_true(cell != Vector2i(-1, -1), name)
		assert_eq(layout.symbol_at(cell), RoomLayout.SYMBOL_FLOOR, name)
		var others: Array[Vector2i] = layout.cells_of("S")
		others.append_array(layout.cells_of("P"))
		others.append_array(rewards)
		for other in others:
			assert_true(maxi(absi(cell.x - other.x), absi(cell.y - other.y)) >= RoomLayout.PICKUP_SPACING, "%s: %s too near %s" % [name, str(cell), str(other)])
		for side in RoomLayout.SIDES:
			var offset := cell - layout.door_cell(side)
			assert_true(maxi(absi(offset.x), absi(offset.y)) > RoomLayout.MERCHANT_DOOR_CLEARANCE, "%s: too near a door" % name)


func test_reward_spots_keep_clear_of_whatever_they_must_avoid() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray([
		"############",
		"#..........#",
		"#.....P....#",
		"#..........#",
		"#..........#",
		"#..........#",
		"#..........#",
		"############"])
	var plain := layout.plan_reward_cells(1)
	var avoid: Array[Vector2i] = [plain[0]]
	var moved := layout.plan_reward_cells(1, avoid)
	assert_true(maxi(absi(moved[0].x - plain[0].x), absi(moved[0].y - plain[0].y)) >= RoomLayout.PICKUP_SPACING, str(moved))


func test_his_reach_never_meets_a_ware_the_plan_or_a_reward() -> void:
	# Three cells apart, his talk reach and any other press-to-use reach never overlap.
	var apart := RoomLayout.PICKUP_SPACING * RoomBackdrop.TILE
	assert_true(apart > Npc.TALK_RADIUS + RetirementStation.USE_RADIUS, "the plan")
	assert_true(apart > Npc.TALK_RADIUS + Pickup.COLLECT_RADIUS + absf(Player.FEET_OFFSET.y), "a ware or a reward")


func test_the_merchant_stands_near_the_middle_of_his_wares() -> void:
	var layout := RoomLayout.new()
	layout.rows = PackedStringArray([
		"################",
		"#..............#",
		"#..S.......S...#",
		"#..............#",
		"#..............#",
		"#..............#",
		"#.............P#",
		"################"])
	var cell := layout.merchant_cell()
	assert_true(cell.x >= 5 and cell.x <= 9, str(cell))


# --- a new line each run, and lines for moments ---

const TALKERS := [
	"res://data/npcs/dealer.tres",
	"res://data/npcs/dealer_back_room.tres",
	"res://data/npcs/deputy_dolores.tres",
	"res://data/npcs/coach_bertram.tres",
	"res://data/npcs/shop_merchant.tres",
]
# The bubble is one line of 10 pixel text, centred on him, on a 640 pixel wide screen.
const LONGEST_LINE := 80


func test_each_run_opens_on_the_next_line_and_goes_round() -> void:
	var lines := _lines(["One.", "Two.", "Three."])
	assert_eq(NpcTalk.new(lines, 0).talk(), "One.")
	assert_eq(NpcTalk.new(lines, 1).talk(), "Two.")
	assert_eq(NpcTalk.new(lines, 5).talk(), "Three.", "round the list")
	var talk := NpcTalk.new(lines, 2)
	talk.talk()
	assert_eq(talk.talk(), "One.", "a second press carries on in order")
	assert_eq(NpcTalk.new(_lines([]), 7).talk(), "", "no lines, no trouble")


func test_a_moment_line_shows_without_moving_the_order_on() -> void:
	var talk := NpcTalk.new(_lines(["One.", "Two."]))
	talk.say("Well done.")
	assert_eq(talk.showing(), "Well done.")
	assert_eq(talk.talk(), "One.", "the order is where it was")
	talk.say("")
	assert_eq(talk.showing(), "One.", "an empty moment says nothing")


func test_every_line_fits_its_bubble() -> void:
	for path in TALKERS:
		var def: NpcDef = load(path)
		assert_false(def.lines.is_empty(), path)
		for line in def.lines:
			assert_true(line.length() <= LONGEST_LINE, "%s: %s" % [path, line])
		for key in def.moments:
			assert_true(def.moment(key).length() <= LONGEST_LINE, "%s: %s" % [path, key])


func test_both_dealers_have_a_word_for_each_result() -> void:
	for path in ["res://data/npcs/dealer.tres", "res://data/npcs/dealer_back_room.tres"]:
		var def: NpcDef = load(path)
		for key in [CardTablePanel.RESULT_WIN, CardTablePanel.RESULT_LOSS, CardTablePanel.RESULT_OUT]:
			assert_false(def.moment(key).is_empty(), "%s %s" % [path, key])


func test_a_game_is_a_win_a_loss_or_even() -> void:
	assert_eq(CardTablePanel.result_of(20, 10, false), CardTablePanel.RESULT_WIN)
	assert_eq(CardTablePanel.result_of(0, 10, true), CardTablePanel.RESULT_WIN, "a prize is a win")
	assert_eq(CardTablePanel.result_of(0, 10, false), CardTablePanel.RESULT_LOSS)
	assert_eq(CardTablePanel.result_of(10, 10, false), "", "money back is even")


func test_dolores_has_a_word_for_every_poster_and_for_paying() -> void:
	var dolores: NpcDef = load("res://data/npcs/deputy_dolores.tres")
	assert_false(dolores.moment("paid").is_empty())
	for def in BountyBoard.all():
		assert_false(dolores.moment("take:" + def.id).is_empty(), def.id)
	assert_eq(dolores.moment("take:nobody"), "")


# --- the deep floors' keepers ---

const KEEPERS := ["res://data/npcs/purser.tres", "res://data/npcs/esme.tres", "res://data/npcs/duty_free_clerk.tres", "res://data/npcs/severance_clerk.tres"]


func test_each_keeper_has_a_rotation_of_short_openers_and_a_word_for_each_run() -> void:
	for path in KEEPERS:
		var def: NpcDef = load(path)
		assert_true(def.lines.size() >= 6 and def.lines.size() <= 10, path)
		for line in def.lines:
			assert_true(line.length() <= 80, line)
		assert_false(def.moment(NpcDef.DIED).is_empty(), path)
		assert_false(def.moment(NpcDef.BOSS_WIN).is_empty(), path)


func test_a_keeper_greets_a_death_before_a_boss_and_says_nothing_after_a_quiet_run() -> void:
	var def: NpcDef = load(KEEPERS[0])
	assert_eq(def.greeting_key({"died": true, "bosses": 2}), NpcDef.DIED)
	assert_eq(def.greeting_key({"died": false, "bosses": 1}), NpcDef.BOSS_WIN)
	assert_eq(def.greeting_key({"died": false, "bosses": 0}), "")
	assert_eq(def.greeting_key({}), "", "no run played yet")
	var merchant: NpcDef = load(MERCHANT_PATH)
	assert_eq(merchant.greeting_key({"died": true}), "", "no line, no greeting")


# A bubble over someone near the top wall ran into the HUD's top rows. It hangs below him instead
# whenever above would reach into the band, and slides in from the screen's sides.
func test_a_bubble_never_reaches_into_the_huds_band_or_off_the_sides() -> void:
	var view := Vector2(640, 360)
	var box := Vector2(120, 16)
	var body := 28.0
	for y in range(0, 361, 6):
		for x in [0.0, 30.0, 320.0, 610.0, 640.0]:
			var at := Vector2(x, y)
			var rect := Npc.bubble_box(at, Vector2.ONE, body, box, view)
			var on_screen := Rect2(at + rect.position, rect.size)
			assert_true(on_screen.position.y >= Hud.BAND_BOTTOM or on_screen.position.y > at.y, "the bubble at %s reaches into the HUD" % str(at))
			assert_true(on_screen.position.x >= Npc.BUBBLE_SIDE_MARGIN - 0.01 and on_screen.end.x <= view.x - Npc.BUBBLE_SIDE_MARGIN + 0.01, "the bubble at %s leaves the screen" % str(at))
	var high := Npc.bubble_box(Vector2(320, 60), Vector2.ONE, body, box, view)
	assert_true(high.position.y > 0.0, "near the top it hangs below him")
	var low := Npc.bubble_box(Vector2(320, 200), Vector2.ONE, body, box, view)
	assert_true(low.end.y < 0.0, "further down it sits over his head")


# A boss's words over his head ran into the HUD's rows near the top wall, as the bubbles did.
func test_a_bosss_words_never_reach_into_the_huds_band() -> void:
	var view := Vector2(640, 360)
	for y in range(0, 361, 8):
		for x in [0.0, 320.0, 640.0]:
			var at := Vector2(x, y)
			var spot := Enemy.say_spot(at, 1.0, 52.0, 90.0, view)
			var text_top := at.y + spot.y - Enemy.SAY_SIZE
			assert_true(text_top >= Hud.BAND_BOTTOM or spot.y > 0.0, "words at %s reach into the HUD" % str(at))
			assert_true(at.x + spot.x >= Enemy.SAY_MARGIN - 0.01 and at.x + spot.x + 90.0 <= view.x - Enemy.SAY_MARGIN + 0.01, "words at %s leave the screen" % str(at))
	assert_true(Enemy.say_spot(Vector2(320, 200), 1.0, 52.0, 90.0, view).y < 0.0, "further down they stay over his head")


func test_a_bubble_hung_below_clears_the_talk_prompt() -> void:
	var body := 28.0
	var rect := Npc.bubble_box(Vector2(320, 40), Vector2.ONE, body, Vector2(120, 16), Vector2(640, 360))
	# The prompt's baseline is 12 px under his feet, and its text rises about 10 px above that.
	assert_true(rect.position.y >= body / 2.0 + 12.0 + 4.0, "the bubble starts under the prompt")


# --- their art ---

func _npc_defs() -> Array[NpcDef]:
	var defs: Array[NpcDef] = []
	for file in DirAccess.get_files_at("res://data/npcs/"):
		if file.ends_with(".tres"):
			defs.append(load("res://data/npcs/" + file))
	return defs


# NPCs drawn as a placeholder until the art pass reaches them.
const AWAITING_ART := []


func test_every_npc_with_art_loads_his_idle_loop_and_rotations() -> void:
	var with_art := 0
	for def in _npc_defs():
		if not NpcSprite.has_art(def.art()):
			continue
		with_art += 1
		var sprite := NpcSprite.new()
		assert_true(sprite.setup(def.art()), def.id)
		assert_eq(sprite.idle_frames(), 4, "%s idles in four frames" % def.id)
		assert_eq(sprite.rotation_frames(), NpcSprite.DIRECTIONS, "%s turns eight ways" % def.id)
		assert_true(sprite.height >= 36.0 and sprite.height <= NpcSprite.FRAME, "%s stands about Harold's height" % def.id)
		sprite.free()
	assert_eq(with_art, _npc_defs().size() - AWAITING_ART.size(), "everyone has art but those still waiting, the back room's Dealer the Dealer's")
	for id in AWAITING_ART:
		assert_false(NpcSprite.has_art(id), "%s's art has come, so the list can lose him" % id)


func test_npc_art_is_imported_sharp() -> void:
	for def in _npc_defs():
		if AWAITING_ART.has(def.art()):
			continue
		for path in [NpcSprite.idle_path(def.art()), NpcSprite.rotations_path(def.art())]:
			var settings := FileAccess.get_file_as_string(path + ".import")
			assert_true(settings.contains("mipmaps/generate=false"), path)
			assert_true(settings.contains("compress/mode=0"), path)


func test_an_npc_with_art_stands_his_feet_on_his_body_box() -> void:
	var def: NpcDef = load("res://data/npcs/gerald.tres")
	var npc := Npc.new()
	npc.setup(def, null)
	npc._ready()
	assert_true(npc.has_art(), "Gerald wears his art, not his drawn look")
	assert_eq(npc.art().position, Vector2(0, def.body_size.y / 2.0), "feet on the box's bottom")
	assert_eq(def.body_size, Vector2(16, 48), "his reach is as it was")
	assert_true(npc.head_top() <= -def.body_size.y / 2.0, "his name goes over his head")
	npc.free()


func test_an_npc_with_no_art_falls_back_to_his_drawn_look() -> void:
	var def := NpcDef.new()
	def.id = "nobody_drawn_yet"
	def.display_name = "Nobody"
	assert_false(NpcSprite.has_art(def.art()))
	var npc := Npc.new()
	npc.setup(def, null)
	npc._ready()
	assert_false(npc.has_art(), "no art, the colour box")
	assert_eq(npc.head_top(), -def.body_size.y / 2.0)
	for child in npc.get_children():
		assert_false(child is NpcSprite)
	npc.free()
	var sprite := NpcSprite.new()
	assert_false(sprite.setup("nobody_drawn_yet"), "missing art says no rather than failing")
	assert_false(sprite.setup(""))
	sprite.free()
	var gerald: NpcDef = load("res://data/npcs/gerald.tres").duplicate()
	gerald.art_id = "nobody_drawn_yet"
	var drawn := Npc.new()
	drawn.setup(gerald, null)
	drawn._ready()
	assert_false(drawn.has_art())
	var looks := 0
	for child in drawn.get_children():
		if child is ActorLook:
			looks += 1
	assert_eq(looks, 1, "Gerald without art keeps his drawn look")
	drawn.free()


func test_the_back_rooms_dealer_wears_the_dealers_art() -> void:
	var def: NpcDef = load("res://data/npcs/dealer_back_room.tres")
	assert_eq(def.art(), "dealer")
	assert_eq((load("res://data/npcs/dealer.tres") as NpcDef).art(), "dealer")


func test_an_npc_turns_the_eight_ways_toward_harold() -> void:
	assert_eq(NpcSprite.direction(Vector2(0, 10)), 0, "south")
	assert_eq(NpcSprite.direction(Vector2(10, 10)), 1, "south-east")
	assert_eq(NpcSprite.direction(Vector2(10, 0)), 2, "east")
	assert_eq(NpcSprite.direction(Vector2(10, -10)), 3, "north-east")
	assert_eq(NpcSprite.direction(Vector2(0, -10)), 4, "north")
	assert_eq(NpcSprite.direction(Vector2(-10, -10)), 5, "north-west")
	assert_eq(NpcSprite.direction(Vector2(-10, 0)), 6, "west")
	assert_eq(NpcSprite.direction(Vector2(-10, 10)), 7, "south-west")
	assert_eq(NpcSprite.direction(Vector2.ZERO), NpcSprite.SOUTH)


func test_the_idle_loop_runs_at_about_eight_frames_a_second() -> void:
	var frame_ms := 1000.0 / NpcSprite.IDLE_FPS
	assert_true(frame_ms >= 100.0 and frame_ms <= 150.0)
	assert_eq(NpcSprite.idle_frame(0.0, 4), 0)
	assert_eq(NpcSprite.idle_frame(0.13, 4), 1)
	assert_eq(NpcSprite.idle_frame(0.5, 4), 0, "and round again")
	var sprite := NpcSprite.new()
	sprite.setup("dealer")
	sprite._process(0.13)
	assert_eq(sprite.frame(), 1)
	sprite.face(Vector2(10, 0))
	assert_eq(sprite.frame(), 2, "facing east holds the east rotation")
	assert_eq(sprite.texture().get_width(), NpcSprite.FRAME * NpcSprite.DIRECTIONS)
	sprite.set_facing(NpcSprite.SOUTH)
	assert_eq(sprite.texture().get_width(), NpcSprite.FRAME * 4, "facing out, he idles again")
	sprite.free()


func test_a_bubble_over_art_clears_his_head() -> void:
	var rect := Npc.bubble_box(Vector2(320, 200), Vector2.ONE, 30.0, Vector2(120, 16), Vector2(640, 360), 40.0)
	assert_true(rect.end.y <= -40.0 - Npc.BUBBLE_GAP + 0.01)
