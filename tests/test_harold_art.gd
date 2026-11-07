extends TestCase

# Harold's strips, built by tools/art/harold_strips.py: one frame width for all three, his feet on the
# bottom of his feet box in every frame, a little shorter than the NPCs, and a swing that shows the cane
# out while it hits.

const DIR := "res://art/sprites/grandpa/"
const ANIMS := ["idle", "walk", "attack"]


func _image(anim: String) -> Image:
	var texture: Texture2D = load(DIR + anim + ".png")
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


# Each frame's used rect, in the frame's own pixels.
func _frames(anim: String) -> Array[Rect2i]:
	var image := _image(anim)
	var width := Player.SPRITE_FRAME_WIDTH
	var out: Array[Rect2i] = []
	for i in image.get_width() / width:
		out.append(image.get_region(Rect2i(i * width, 0, width, image.get_height())).get_used_rect())
	return out


func test_every_strip_is_a_row_of_square_frames_one_width() -> void:
	for anim in ANIMS:
		var image := _image(anim)
		assert_eq(image.get_height(), Player.SPRITE_FRAME_WIDTH, anim)
		assert_eq(image.get_width() % Player.SPRITE_FRAME_WIDTH, 0, anim)
	assert_eq(SpriteVisual.frame_count(_image("idle").get_width(), Player.SPRITE_FRAME_WIDTH), 4, "a 4-frame breath")
	assert_eq(SpriteVisual.frame_count(_image("walk").get_width(), Player.SPRITE_FRAME_WIDTH), 8, "the hobble")
	assert_eq(SpriteVisual.frame_count(_image("attack").get_width(), Player.SPRITE_FRAME_WIDTH), 4, "the swing")


func test_his_feet_land_on_the_bottom_of_his_feet_box_in_every_frame() -> void:
	# The sprite is centred on his origin, so a frame's bottom edge is half a frame below it.
	for anim in ANIMS:
		var frames := _frames(anim)
		for i in frames.size():
			var feet := frames[i].end.y - Player.SPRITE_FRAME_WIDTH / 2.0
			assert_near(feet, Player.SPRITE_FEET_Y, "%s frame %d" % [anim, i])
	assert_near(Player.FEET_OFFSET.y + Player.FEET_BOX_SIZE.y / 2.0, Player.SPRITE_FEET_Y)


func test_he_stands_a_little_shorter_than_the_npcs() -> void:
	var tallest := 0
	for rect in _frames("idle") + _frames("walk"):
		tallest = maxi(tallest, rect.size.y)
	var gerald := NpcSprite.new()
	assert_true(gerald.setup("gerald"))
	assert_true(tallest < gerald.height, "Harold %d px, Gerald %d px" % [tallest, gerald.height])
	assert_true(tallest >= gerald.height - 8.0, "only a little shorter")
	gerald.free()


func test_the_cane_is_out_while_the_swing_hits() -> void:
	# The attack plays once over the combo's lock; the swing hits for its own duration from the start.
	var frames := _frames("attack")
	var rest := _frames("idle")[0].end.x
	var hit_frames := ceili(SwingAttack.DURATION / CaneCombo.LOCK_TIME * frames.size())
	var widest := 0
	for i in hit_frames:
		widest = maxi(widest, frames[SpriteVisual.once_frame(i * CaneCombo.LOCK_TIME / frames.size(), CaneCombo.LOCK_TIME, frames.size())].end.x)
	assert_true(widest >= rest + 8, "the cane reaches out in front while the arc shows")
	assert_true(frames[-1].end.x <= rest + 2, "and is back by his side when the swing ends")


func test_the_head_anchor_sits_on_his_head() -> void:
	var top := Player.SPRITE_FRAME_WIDTH
	for rect in _frames("idle"):
		top = mini(top, rect.position.y)
	var hair_top := top - Player.SPRITE_FRAME_WIDTH / 2.0
	# Every hat's crown starts 5 or 6 px above HEAD, so it sits on the hair rather than above it.
	assert_true(GrandpaLook.HEAD.y - 6.0 <= hair_top + 1.0 and GrandpaLook.HEAD.y - 5.0 >= hair_top - 1.0, str(hair_top))
	assert_eq(CutsceneActor.HAROLD_HEAD, CutsceneActor.HAROLD_SPRITE_OFFSET + GrandpaLook.HEAD)
	assert_eq(CutsceneActor.HAROLD_SPRITE_OFFSET, -Player.FEET_OFFSET)


func test_his_anchors_mirror_when_he_faces_left() -> void:
	assert_eq(GrandpaLook.mirrored(Vector2(3, -1), -1.0), Vector2(-3, -1))
	assert_eq(GrandpaLook.mirrored(Vector2(3, -1), 1.0), Vector2(3, -1))


# Every cardigan has its own outfit of his strips (tools/art/harold_outfits.py): the same frames, the
# same outline and pixels everywhere but the cardigan, which is redrawn, and nothing drawn in code.
func test_every_cardigan_has_an_outfit_on_his_own_frames() -> void:
	var cardigans := 0
	for def in CosmeticDef.all():
		if def.slot != CosmeticDef.SLOT_CARDIGAN or def.shape == "tie":
			continue
		cardigans += 1
		var outfit := GrandpaLook.outfit_art({CosmeticDef.SLOT_CARDIGAN: def})
		assert_eq(outfit, "grandpa_" + def.id, def.id)
		for anim in ANIMS:
			var own := _image(anim)
			var texture: Texture2D = load(SpriteVisual.art_path(outfit, anim))
			var worn := texture.get_image()
			if worn.is_compressed():
				worn.decompress()
			assert_eq(worn.get_size(), own.get_size(), "%s %s" % [def.id, anim])
			var changed := 0
			var moved := 0
			for y in own.get_height():
				for x in own.get_width():
					var a := own.get_pixel(x, y)
					var b := worn.get_pixel(x, y)
					if not is_equal_approx(a.a, b.a):
						moved += 1
					elif not a.is_equal_approx(b):
						changed += 1
			assert_eq(moved, 0, "%s %s keeps his outline" % [def.id, anim])
			assert_true(changed > 300, "%s %s redraws the cardigan (%d px)" % [def.id, anim, changed])
	assert_true(cardigans >= 3, str(cardigans))


func test_no_cardigan_or_a_tie_wears_his_own_art() -> void:
	assert_eq(GrandpaLook.outfit_art({}), GrandpaLook.ART_ID)
	var tie := CosmeticDef.find("power_tie", CosmeticDef.all())
	assert_eq(GrandpaLook.outfit_art({CosmeticDef.SLOT_CARDIGAN: tie}), GrandpaLook.ART_ID)


func test_a_change_of_art_keeps_the_anim_playing() -> void:
	var visual := SpriteVisual.new()
	visual.setup(GrandpaLook.ART_ID, Vector2(20, 28), Color.WHITE, Player.SPRITE_FRAME_WIDTH)
	visual.play("walk")
	visual.set_art("grandpa_mustard_cardigan")
	assert_eq(visual.art_id(), "grandpa_mustard_cardigan")
	assert_eq(visual.anim(), "walk")
	assert_eq(visual.sprite().texture.resource_path, SpriteVisual.art_path("grandpa_mustard_cardigan", "walk"))
	assert_eq(visual.sprite().hframes, 8)
	visual.free()
