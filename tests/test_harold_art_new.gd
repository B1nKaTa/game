extends TestCase

# Harold's strips from tools/art/harold_anims.py: hurt, death and dodge for old Harold and the eras, and
# the two new eras' own idle, walk and attack. A strip that is not there is skipped, so this is safe
# before the art lands. (test_harold_art.gd keeps old Harold's first three strips.)

const STRIPS := {
	"grandpa": ["hurt", "death", "dodge"],
	"harold_1960": ["dodge", "hurt"],
	"harold_1975": ["dodge", "hurt"],
	"harold_1962": ["idle", "walk", "attack", "dodge", "hurt"],
	"harold_1988": ["idle", "walk", "attack", "dodge", "hurt"],
}
# Frames each strip is cut to: the export's frames after its reference pose, but for the two swings,
# which are re-cut so the hit window shows the reach.
const FRAMES := {
	"grandpa/hurt": 4, "grandpa/death": 8, "grandpa/dodge": 6,
	"harold_1960/dodge": 6, "harold_1960/hurt": 4, "harold_1975/dodge": 6, "harold_1975/hurt": 4,
	"harold_1962/idle": 4, "harold_1962/walk": 8, "harold_1962/attack": 4, "harold_1962/dodge": 6, "harold_1962/hurt": 4,
	"harold_1988/idle": 4, "harold_1988/walk": 8, "harold_1988/attack": 8, "harold_1988/dodge": 6, "harold_1988/hurt": 4,
}
const ERAS_WITH_ART := ["", "football_1960", "bus_1975", "dance_hall_1962", "allotment_1988"]


func _strip_image(art: String, anim: String) -> Image:
	var image: Image = (load(SpriteVisual.art_path(art, anim)) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	return image


func _strip_rects(art: String, anim: String) -> Array[Rect2i]:
	var image := _strip_image(art, anim)
	var out: Array[Rect2i] = []
	for i in image.get_width() / Player.SPRITE_FRAME_WIDTH:
		out.append(image.get_region(Rect2i(i * Player.SPRITE_FRAME_WIDTH, 0, Player.SPRITE_FRAME_WIDTH, image.get_height())).get_used_rect())
	return out


# Every strip is whole 60 px frames, his feet on one row (as harold_strips.py places them).
func test_new_strips_share_his_frame_and_feet() -> void:
	var seen := 0
	for art: String in STRIPS:
		for anim: String in STRIPS[art]:
			if not SpriteVisual.has_anim(art, anim):
				continue
			seen += 1
			var image := _strip_image(art, anim)
			assert_eq(image.get_height(), Player.SPRITE_FRAME_WIDTH, "%s/%s height" % [art, anim])
			assert_eq(image.get_width() % Player.SPRITE_FRAME_WIDTH, 0, "%s/%s whole frames" % [art, anim])
			assert_eq(image.get_width() / Player.SPRITE_FRAME_WIDTH, FRAMES["%s/%s" % [art, anim]], "%s/%s frames" % [art, anim])
			var lowest := 0
			for rect in _strip_rects(art, anim):
				lowest = maxi(lowest, rect.end.y)
				assert_true(rect.position.y > 0, "%s/%s clear of the top" % [art, anim])
				# A dodge may hop one frame off the floor; everything else keeps its feet down.
				if anim != "dodge":
					assert_eq(rect.end.y - Player.SPRITE_FRAME_WIDTH / 2, int(Player.SPRITE_FEET_Y), "%s/%s every frame on the floor" % [art, anim])
			assert_eq(lowest - Player.SPRITE_FRAME_WIDTH / 2, int(Player.SPRITE_FEET_Y), "%s/%s lowest row is his feet" % [art, anim])
			assert_eq(SpriteVisual.feet_row(load(SpriteVisual.art_path(art, anim))), SpriteVisual.feet_row(load(SpriteVisual.art_path("grandpa", "idle"))), "%s/%s feet" % [art, anim])
	print("harold art strips present: %d" % seen)


# An era with any strip of its own has the idle too, or Player would mix his art with old Harold's.
func test_an_era_with_art_has_its_idle() -> void:
	for art in ["harold_1962", "harold_1988"]:
		for anim in ["walk", "attack", "dodge", "hurt"]:
			if SpriteVisual.has_anim(art, anim):
				assert_true(SpriteVisual.has_anim(art, "idle"), "%s has %s but no idle" % [art, anim])


# The cardigan outfits have the new strips too, so a hit, a fall or a dodge never flashes him to the
# default outfit.
func test_every_outfit_has_the_new_old_harold_strips() -> void:
	for outfit in ["grandpa_bingo_teal", "grandpa_burgundy_cardigan", "grandpa_mustard_cardigan"]:
		for anim in STRIPS["grandpa"]:
			assert_eq(SpriteVisual.has_anim(outfit, anim), SpriteVisual.has_anim("grandpa", anim), "%s/%s" % [outfit, anim])
			if SpriteVisual.has_anim(outfit, anim):
				assert_eq(_strip_image(outfit, anim).get_size(), _strip_image("grandpa", anim).get_size(), "%s/%s size" % [outfit, anim])


# The swing hits for SwingAttack.DURATION of its lock, and the strip plays once over the lock: the frames
# showing then are the ones that carry the reach.
func _hit_window(art: String, lock: float) -> Array[int]:
	var count := _strip_rects(art, "attack").size()
	var out: Array[int] = []
	for i in ceili(SwingAttack.DURATION / lock * count):
		out.append(SpriteVisual.once_frame(i * lock / count, lock, count))
	return out


func test_the_spin_is_widest_while_it_hits() -> void:
	if not SpriteVisual.has_anim("harold_1962", "attack"):
		return
	var rects := _strip_rects("harold_1962", "attack")
	var widest := 0
	for r in rects:
		widest = maxi(widest, r.size.x)
	var in_window := 0
	for i in _hit_window("harold_1962", EraMoves.for_era(Eras.DANCE).lock_time):
		in_window = maxi(in_window, rects[i].size.x)
	assert_eq(in_window, widest, "the arms-out frames play while the spin hits")
	assert_true(widest >= 36, "arms stretched wide, %d px" % widest)


func test_the_spade_is_out_while_the_thrust_hits() -> void:
	if not SpriteVisual.has_anim("harold_1988", "attack"):
		return
	var rects := _strip_rects("harold_1988", "attack")
	var furthest := 0
	for r in rects:
		furthest = maxi(furthest, r.end.x)
	var in_window := 0
	for i in _hit_window("harold_1988", EraMoves.for_era(Eras.ALLOTMENT).lock_time):
		in_window = maxi(in_window, rects[i].end.x)
	assert_eq(in_window, furthest, "full reach plays while the thrust hits")
	assert_true(furthest >= _strip_rects("harold_1988", "idle")[0].end.x + 8, "the blade reaches past him")


func _fresh_player(era := "") -> Player:
	var player := Player.new()
	player.setup(ItemKit.new().make_run())
	player._ready()
	if not era.is_empty():
		player.set_era(era)
	return player


# Steps the sprite as the engine would, in slices.
func _advance(player: Player, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var step := minf(left, 0.05)
		player._visual._process(step)
		left -= step


func test_a_hit_plays_his_hurt_strip_then_lets_him_go() -> void:
	var played := 0
	for era in ERAS_WITH_ART:
		var player := _fresh_player(era)
		var art: String = player._visual.art_id()
		if not SpriteVisual.has_anim(art, "hurt"):
			player.free()
			continue
		played += 1
		assert_true(player.take_hit(1), "%s lands" % art)
		assert_eq(player._visual.anim(), "hurt", art)
		assert_eq(player._visual.shown_anim(), "hurt", art)
		var count: int = player._visual.sprite().hframes
		assert_eq(count, 4, "%s hurt frames" % art)
		for step in 6:
			_advance(player, Player.HURT_ANIM_TIME / 6.0 * 0.95)
			var frame: int = player._visual.sprite().frame
			assert_true(frame >= 0 and frame < count, "%s frame %d in range" % [art, frame])
		_advance(player, 0.1)
		# Player's own step puts him back on idle or walk once this is false.
		assert_false(player._visual.is_playing_once(), "%s hurt is over, so he may go back to idle" % art)
		player.free()
	print("hurt strips played: %d" % played)


func test_his_death_strip_ends_flat_on_its_last_frame() -> void:
	var player := _fresh_player()
	if not SpriteVisual.has_anim("grandpa", "death"):
		player.free()
		return
	assert_true(player.death_anim_time() > 0.0)
	assert_true(player.take_hit(99))
	assert_true(player.run.health.is_dead())
	assert_eq(player._visual.anim(), "death")
	var count: int = player._visual.sprite().hframes
	assert_eq(count, 8)
	var seen_last := false
	var previous := -1
	for step in 30:
		_advance(player, Player.DEATH_ANIM_TIME / 20.0)
		var frame: int = player._visual.sprite().frame
		assert_true(frame >= previous and frame < count, "frames run forward and stay in range")
		previous = frame
		seen_last = seen_last or frame == count - 1
	assert_true(seen_last, "reaches the last frame")
	assert_eq(player._visual.sprite().frame, count - 1, "and holds it")
	var last := _strip_rects("grandpa", "death")[count - 1]
	assert_true(last.size.x > last.size.y, "lying flat")
	player.free()


func test_a_dodge_plays_his_dodge_strip_instead_of_the_ghosts() -> void:
	var played := 0
	for era in ERAS_WITH_ART:
		var player := _fresh_player(era)
		var art: String = player._visual.art_id()
		var has_strip := SpriteVisual.has_anim(art, "dodge")
		assert_eq(player.uses_dodge_ghosts(), not has_strip, art)
		if has_strip:
			played += 1
			assert_true(player.start_dodge(Vector2.RIGHT), "%s dodges" % art)
			assert_eq(player._visual.anim(), "dodge", art)
			var count: int = player._visual.sprite().hframes
			assert_eq(count, 6, "%s dodge frames" % art)
			for step in 40:
				_advance(player, 0.01)
				assert_true(player._visual.sprite().frame < count, "%s frame in range" % art)
			assert_false(player._visual.is_playing_once(), "%s dodge is over" % art)
		player.free()
	print("dodge strips played: %d" % played)


# --- The hooks with the real strips present: none of these can pass by skipping. ---

func test_the_real_strips_are_there() -> void:
	for outfit in ["grandpa", "grandpa_bingo_teal", "grandpa_burgundy_cardigan", "grandpa_mustard_cardigan"]:
		for anim in ["hurt", "death", "dodge"]:
			assert_true(SpriteVisual.has_anim(outfit, anim), "%s/%s" % [outfit, anim])
	for era_art in ["harold_1960", "harold_1975", "harold_1962", "harold_1988"]:
		for anim in ["hurt", "dodge"]:
			assert_true(SpriteVisual.has_anim(era_art, anim), "%s/%s" % [era_art, anim])


func _cosmetic(id: String) -> CosmeticDef:
	for def in CosmeticDef.all():
		if def.id == id:
			return def
	return null


func _player_in(look: Dictionary) -> Player:
	var run := ItemKit.new().make_run()
	run.look = look
	var player := Player.new()
	player.setup(run)
	player._ready()
	return player


func test_hurt_plays_on_a_landed_hit_and_leaves_a_swing_drawn() -> void:
	var player := _fresh_player()
	assert_true(player.take_hit(1))
	assert_eq(player._visual.anim(), "hurt")
	player.free()
	var swinging := _fresh_player()
	swinging._visual.play_once("attack", CaneCombo.LOCK_TIME)
	assert_true(swinging.take_hit(1))
	assert_eq(swinging._visual.anim(), "attack", "a hit in mid-swing keeps the swing drawn")
	assert_true(swinging._visual.is_playing_once())
	swinging.free()


func test_a_dodge_plays_its_strip_and_drops_the_ghosts() -> void:
	var player := _fresh_player()
	assert_false(player.uses_dodge_ghosts())
	assert_true(player.start_dodge(Vector2.RIGHT))
	assert_eq(player._visual.anim(), "dodge")
	assert_eq(player._visual.shown_anim(), "dodge")
	player.free()


func test_a_death_in_a_flashback_falls_in_old_harolds_art_untinted() -> void:
	var player := _fresh_player(Eras.DANCE)
	assert_eq(player._visual.art_id(), "harold_1962")
	assert_true(player.death_anim_time() > 0.0, "an era with no death strip still gets his fall")
	assert_true(player.take_hit(99))
	assert_eq(player._visual.art_id(), "grandpa")
	assert_eq(player._visual.anim(), "death")
	assert_eq(player._visual.shown_anim(), "death")
	assert_eq(player._visual._tint, Color.WHITE, "no sepia on the fall")
	assert_false(player.is_look_shown(), "no hat on a man lying down")
	player.free()


func test_the_hat_is_off_for_death_hurt_and_dodge_and_back_after() -> void:
	var player := _player_in({CosmeticDef.SLOT_HAT: _cosmetic("flat_cap")})
	assert_true(player._look != null)
	assert_true(player.is_look_shown(), "worn standing")
	assert_true(player.start_dodge(Vector2.RIGHT))
	assert_false(player.is_look_shown(), "off during the dodge")
	_advance(player, 1.0)
	player.sync_look()
	assert_true(player.is_look_shown(), "back after the dodge")
	player.free()
	player = _player_in({CosmeticDef.SLOT_HAT: _cosmetic("flat_cap")})
	assert_true(player.take_hit(1))
	assert_false(player.is_look_shown(), "off during the hurt")
	_advance(player, 1.0)
	player.sync_look()
	assert_true(player.is_look_shown(), "back after the hurt")
	# A one-shot replaced by another: a swing over a dodge shows it again.
	player._visual.play_once("dodge", 0.2)
	player.sync_look()
	assert_false(player.is_look_shown())
	player._visual.play_once("attack", 0.2)
	player.sync_look()
	assert_true(player.is_look_shown())
	# Era change and back never leaves it hidden.
	player.set_era(Eras.DANCE)
	assert_false(player.is_look_shown())
	player.set_era("")
	assert_true(player.is_look_shown())
	player.run.health.tick(5.0)
	assert_true(player.take_hit(99))
	assert_false(player.is_look_shown(), "off for good once he falls")
	_advance(player, 5.0)
	player.sync_look()
	assert_false(player.is_look_shown())
	player.free()


func test_an_outfit_wearer_gets_the_same_animations() -> void:
	for outfit in ["bingo_teal", "burgundy_cardigan", "mustard_cardigan"]:
		var player := _player_in({CosmeticDef.SLOT_CARDIGAN: _cosmetic(outfit)})
		var art: String = player._visual.art_id()
		assert_eq(art, "grandpa_" + outfit)
		assert_false(player.uses_dodge_ghosts(), art)
		assert_true(player.take_hit(1))
		assert_eq(player._visual.shown_anim(), "hurt", art)
		assert_eq(player._visual.art_id(), art, "he stays in his own outfit")
		player.run.health.tick(5.0)
		assert_true(player.take_hit(99))
		assert_eq(player._visual.shown_anim(), "death", art)
		assert_eq(player._visual.art_id(), art)
		player.free()
