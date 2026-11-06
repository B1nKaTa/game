extends TestCase

# Enemy art (tools/art/enemy_strips.py, SpriteVisual, EnemyAnim): the anim fallbacks, the flip, the
# feet on the body box bottom in every strip, a floor variant wearing its base's art, the placeholder
# for an enemy with none, and the order bodies are drawn in.

const ART_DIR := "res://art/sprites/"
const ARTED := ["intern_reaper", "stoker", "mall_cop", "hr_representative", "regional_reaper",
	"old_smokey", "chairman_of_the_board",
	# The Cinema's and the Seance Hotline's (D:/grandpa-art/newpaths).
	"usher", "popcorn_vendor", "film_reel", "extra", "crabtree", "projectionist",
	"phone_psychic", "crystal_gazer", "poltergeist", "ectoplasm", "celestine", "madame_zara"]
# Art whose own enemy is retired, and the enemy who wears it now.
const WORN_BY := {"mall_cop": "airport_mall_cop"}
# Objects drawn facing south, which never turn and so are never mirrored.
const UNFLIPPED := ["film_reel", "ectoplasm"]
# The new paths' regulars, whose windup and attack are cut from their attack export.
const CUT_REGULARS := ["usher", "popcorn_vendor", "extra", "phone_psychic", "crystal_gazer", "poltergeist"]
# A boss's own anims, each played by its behavior through Enemy.play_anim: id -> [behavior, anims].
const BOSS_ANIMS := {
	"crabtree": ["crabtree_behavior.gd", ["star_rating", "thumbs_down", "attack"]],
	"projectionist": ["projectionist_behavior.gd", ["reel_change", "splice", "attack"]],
	"celestine": ["celestine_behavior.gd", ["deal_cards", "attack"]],
	"madame_zara": ["madame_zara_behavior.gd", ["tether_call", "possession", "attack"]],
}


# Every anim strip in an art folder.
func _anims(id: String) -> Array[String]:
	var names: Array[String] = []
	for file in DirAccess.get_files_at(ART_DIR + id):
		if file.ends_with(".png"):
			names.append(file.get_basename())
	return names


func _has(names: Array) -> Callable:
	return func(anim: String) -> bool: return names.has(anim)


func _image(path: String) -> Image:
	var texture: Texture2D = load(path)
	var image := texture.get_image()
	if image.is_compressed():
		image.decompress()
	return image


func _enemy(id: String) -> Enemy:
	var enemy := Enemy.new()
	enemy.setup(load("res://data/enemies/%s.tres" % id), null, 0.5)
	enemy._ready()
	return enemy


func test_missing_anims_fall_back_to_the_idle() -> void:
	var only_idle := _has(["idle"])
	assert_eq(SpriteVisual.resolve("windup", only_idle), "idle")
	assert_eq(SpriteVisual.resolve("attack", only_idle), "idle")
	assert_eq(SpriteVisual.resolve("walk", only_idle), "idle")
	assert_eq(SpriteVisual.resolve("idle", only_idle), "idle")


func test_an_anim_that_exists_shows_itself() -> void:
	var all := _has(["idle", "walk", "windup", "attack", "whistle"])
	for anim in ["idle", "walk", "windup", "attack", "whistle"]:
		assert_eq(SpriteVisual.resolve(anim, all), anim)


func test_a_behaviors_own_anim_falls_back_to_the_attack_then_the_idle() -> void:
	assert_eq(SpriteVisual.resolve("summon", _has(["idle", "attack"])), "attack")
	assert_eq(SpriteVisual.resolve("summon", _has(["idle"])), "idle")


func test_with_no_idle_nothing_shows_and_the_placeholder_draws() -> void:
	assert_eq(SpriteVisual.resolve("walk", _has([])), "")
	assert_eq(SpriteVisual.resolve("summon", _has(["walk"])), "")
	var visual := SpriteVisual.new()
	visual.setup("no_such_art", Vector2(20, 24), Color.WHITE, 0)
	visual.play("walk")
	assert_false(visual.has_art())
	assert_eq(visual.shown_anim(), "")
	visual.free()


func test_the_driver_picks_windup_walk_and_idle() -> void:
	assert_eq(EnemyAnim.pick(true, Vector2(60, 0)), EnemyAnim.WINDUP, "the windup wins over the walk")
	assert_eq(EnemyAnim.pick(false, Vector2(60, 0)), EnemyAnim.WALK)
	assert_eq(EnemyAnim.pick(false, Vector2(1, 0)), EnemyAnim.IDLE, "a crawl is standing")
	assert_eq(EnemyAnim.pick(false, Vector2.ZERO), EnemyAnim.IDLE)


func test_it_faces_harold_when_busy_or_still_and_its_walk_otherwise() -> void:
	var harold_left := Vector2(-1, 0)
	assert_true(EnemyAnim.faces_left(false, true, Vector2(60, 0), harold_left), "winding up, it faces Harold")
	assert_false(EnemyAnim.faces_left(true, false, Vector2(60, 0), harold_left), "walking east, it faces east")
	assert_true(EnemyAnim.faces_left(false, false, Vector2.ZERO, harold_left), "standing, it faces Harold")
	assert_true(EnemyAnim.faces_left(true, false, Vector2(0, 60), Vector2(1, 0)), "walking straight down keeps its way")
	assert_false(EnemyAnim.faces_left(false, false, Vector2.ZERO, Vector2(0, 1)), "Harold straight below keeps its way")


func test_a_real_enemy_walks_winds_up_strikes_and_flips() -> void:
	var enemy := _enemy("intern_reaper")
	var visual := enemy.visual()
	assert_true(visual.has_art())
	assert_eq(visual.shown_anim(), "idle")
	enemy.desired_velocity = Vector2(-enemy.def.speed, 0)
	enemy._update_anim(0.016)
	assert_eq(visual.shown_anim(), "walk")
	assert_true(visual.is_facing_left(), "walking west, the east-drawn art is mirrored")
	enemy.desired_velocity = Vector2(enemy.def.speed, 0)
	enemy._update_anim(0.016)
	assert_false(visual.is_facing_left())
	enemy.desired_velocity = Vector2.ZERO
	var telegraph := Telegraph.new()
	telegraph.start(0.45)
	enemy.set_warning(telegraph, 40.0)
	enemy._update_anim(0.016)
	assert_eq(visual.shown_anim(), "windup")
	assert_true(visual.is_playing_once(), "the windup plays once over the warning and holds its last frame")
	telegraph.tick(1.0)
	enemy.clear_warning()
	enemy._update_anim(0.016)
	assert_eq(visual.shown_anim(), "attack", "the attack starts the frame the windup ends, when the hit lands")
	for i in 30:
		enemy._update_anim(0.016)
	assert_eq(visual.shown_anim(), "idle", "after ATTACK_TIME it stands again")
	enemy.free()


func test_without_an_attack_strip_the_windup_end_goes_back_to_walking() -> void:
	var enemy := _enemy("airport_mall_cop")
	assert_false(SpriteVisual.has_anim("mall_cop", "attack"), "his export is a whistle")
	var telegraph := Telegraph.new()
	telegraph.start(0.4)
	enemy.set_warning(telegraph, 20.0)
	enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "idle", "no windup strip: the idle")
	telegraph.tick(1.0)
	enemy.clear_warning()
	enemy.desired_velocity = Vector2(300, 0)
	enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "walk", "his charge walks")
	enemy.play_anim("whistle", 0.6)
	assert_eq(enemy.visual().shown_anim(), "whistle")
	enemy.free()


# An object drawn from one side only, as the Ectoplasm's blob, never mirrors, whichever way it goes.
func test_an_object_that_never_flips_keeps_its_one_look() -> void:
	assert_false((load("res://data/enemies/ectoplasm.tres") as EnemyDef).flips)
	assert_true((load("res://data/enemies/intern_reaper.tres") as EnemyDef).flips, "people turn")
	# Worn on art that exists, so the anim driver runs.
	var def: EnemyDef = (load("res://data/enemies/ectoplasm.tres") as EnemyDef).duplicate()
	def.art_id = "intern_reaper"
	var enemy := Enemy.new()
	enemy.setup(def, null, 0.5)
	enemy._ready()
	enemy.desired_velocity = Vector2(-60, 0)
	enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "walk")
	assert_false(enemy.visual().is_facing_left(), "going west, it is not mirrored")
	enemy.free()


func test_objects_drawn_facing_south_are_never_mirrored() -> void:
	for id in UNFLIPPED:
		var enemy := _enemy(id)
		assert_false(enemy.def.flips, id)
		assert_true(enemy.visual().has_art(), id)
		enemy.desired_velocity = Vector2(-enemy.def.speed, 0)
		enemy._update_anim(0.016)
		assert_eq(enemy.visual().shown_anim(), "walk", id)
		assert_false(enemy.visual().is_facing_left(), id + " walking west stays as drawn")
		enemy.free()


func test_the_new_paths_regulars_have_a_cut_windup_and_attack() -> void:
	for id in CUT_REGULARS:
		assert_true(SpriteVisual.has_anim(id, "windup") and SpriteVisual.has_anim(id, "attack"), id)


func test_each_new_boss_plays_its_own_anims() -> void:
	for id: String in BOSS_ANIMS:
		var source := FileAccess.get_file_as_string("res://scripts/actors/behaviors/" + BOSS_ANIMS[id][0])
		for anim: String in BOSS_ANIMS[id][1]:
			assert_true(SpriteVisual.has_anim(id, anim), "%s has %s" % [id, anim])
			assert_true(source.contains("enemy.play_anim(\"%s\"" % anim) or source.contains("_anim(enemy, \"%s\"" % anim), "%s plays %s" % [id, anim])
	# Names the art has no strip for are not played.
	for pair in [["usher_behavior.gd", "shush"], ["crabtree_behavior.gd", "review"], ["projectionist_behavior.gd", "crank"]]:
		var text := FileAccess.get_file_as_string("res://scripts/actors/behaviors/" + pair[0])
		assert_false(text.contains("\"%s\"" % pair[1]), pair[0] + " no longer plays " + pair[1])


func test_a_behaviors_own_anim_plays_through_the_windup_and_the_hit() -> void:
	var enemy := _enemy("madame_zara")
	var telegraph := Telegraph.new()
	telegraph.start(0.6)
	enemy.set_warning(telegraph, 40.0)
	enemy.play_anim("tether_call", 0.9)
	enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "tether_call", "not the plain windup")
	telegraph.tick(1.0)
	enemy.clear_warning()
	enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "tether_call", "not the plain attack")
	for i in 70:
		enemy._update_anim(0.016)
	assert_eq(enemy.visual().shown_anim(), "idle")
	enemy.free()
	# Without its own anim, the plain windup and attack still play.
	var usher := _enemy("usher")
	telegraph = Telegraph.new()
	telegraph.start(0.6)
	usher.set_warning(telegraph, 40.0)
	usher._update_anim(0.016)
	assert_eq(usher.visual().shown_anim(), "windup")
	telegraph.tick(1.0)
	usher.clear_warning()
	usher._update_anim(0.016)
	assert_eq(usher.visual().shown_anim(), "attack")
	usher.free()


func test_every_strip_is_square_frames_with_the_feet_on_one_row() -> void:
	for id in ARTED:
		var size := -1
		var row := -1
		for anim in _anims(id):
			var path := ART_DIR + "%s/%s.png" % [id, anim]
			if not ResourceLoader.exists(path):
				continue
			var image := _image(path)
			if size < 0:
				size = image.get_height()
			assert_eq(image.get_height(), size, "%s %s: one canvas per actor" % [id, anim])
			assert_eq(image.get_width() % image.get_height(), 0, "%s %s: square frames" % [id, anim])
			for i in image.get_width() / size:
				var used := image.get_region(Rect2i(i * size, 0, size, size)).get_used_rect()
				if row < 0:
					row = used.end.y
				assert_eq(used.end.y, row, "%s %s frame %d: feet on one row" % [id, anim, i])
				assert_true(used.position.y > 0, "%s %s frame %d: room above the head" % [id, anim, i])
		assert_true(size > 0, id + " has art")
		assert_true(SpriteVisual.has_anim(id, "idle") and SpriteVisual.has_anim(id, "walk"), id)


func test_every_strip_puts_the_feet_on_the_body_box_bottom() -> void:
	for id in ARTED:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % WORN_BY.get(id, id))
		var visual := SpriteVisual.new()
		visual.set_feet(def.body_size.y / 2.0)
		visual.setup(def.art(), def.body_size, def.color, def.frame_width)
		for anim in _anims(id):
			if not SpriteVisual.has_anim(id, anim):
				continue
			visual.play(anim)
			var sprite := visual.sprite()
			var texture := sprite.texture
			assert_eq(sprite.hframes, texture.get_width() / texture.get_height(), "%s %s frames" % [id, anim])
			# The strip's lowest row, end exclusive, from the enemy's origin.
			var feet := visual.position.y + sprite.position.y + sprite.offset.y - texture.get_height() / 2.0 + SpriteVisual.feet_row(texture)
			assert_near(feet, def.body_size.y / 2.0)
		visual.free()


func test_a_floor_variant_wears_its_bases_art_recoloured() -> void:
	for pair in [["furnace_intern_reaper", "intern_reaper"], ["cinema_intern_reaper", "intern_reaper"], ["cruise_stoker", "stoker"], ["airport_mall_cop", "mall_cop"]]:
		var def: EnemyDef = load("res://data/enemies/%s.tres" % pair[0])
		assert_eq(def.art(), pair[1], pair[0])
	var base: EnemyDef = load("res://data/enemies/intern_reaper.tres")
	assert_eq(base.art(), "intern_reaper", "an empty art_id is its own id")
	var enemy := _enemy("furnace_intern_reaper")
	assert_true(enemy.visual().has_art())
	assert_true(enemy.visual().recolor().y > 0.0, "the furnace reaper turns its robe's hue")
	enemy.free()


func test_an_enemy_without_art_keeps_its_placeholder_and_marks() -> void:
	var enemy := _enemy("filing_clerk")
	assert_false(enemy.visual().has_art())
	assert_false(enemy._marks.art_shown)
	enemy.free()
	var arted := _enemy("stoker")
	assert_true(arted._marks.art_shown, "art draws its own shovel")
	arted.free()


func test_bodies_stand_on_their_feet_for_the_room_sort() -> void:
	var enemy := _enemy("regional_reaper")
	assert_true(enemy.y_sort_enabled)
	assert_near(enemy.visual().position.y, enemy.def.body_size.y / 2.0)
	enemy.free()
	var source := FileAccess.get_file_as_string("res://scripts/world/room_view.gd")
	assert_true(source.contains("y_sort_enabled = true"), "the room sorts")
	assert_true(FileAccess.get_file_as_string("res://scripts/scenes/floor_scene.gd").contains("y_sort_enabled = true"), "Harold's scene sorts")


# Harold behind an NPC and in front of an enemy: what the sort compares is each look's feet.
func test_the_sort_key_is_the_feet() -> void:
	var enemy := _enemy("intern_reaper")
	enemy.position = Vector2(100, 100)
	var enemy_feet := enemy.position.y + enemy.def.body_size.y / 2.0
	assert_near(enemy.position.y + enemy.visual().position.y, enemy_feet)
	var harold_feet_behind := enemy_feet - 6.0
	var harold_feet_front := enemy_feet + 6.0
	# His look stands at his origin + SPRITE_FEET_Y, the bottom of his feet box.
	var harold_origin := harold_feet_behind - Player.SPRITE_FEET_Y
	assert_true(harold_origin + Player.SPRITE_FEET_Y < enemy.position.y + enemy.visual().position.y, "behind: drawn first")
	harold_origin = harold_feet_front - Player.SPRITE_FEET_Y
	assert_true(harold_origin + Player.SPRITE_FEET_Y > enemy.position.y + enemy.visual().position.y, "in front: drawn last")
	# Without the feet anchor his origin sits 23 px above his soles and the enemy's 12 px above its
	# own, so he would be drawn behind an enemy whose feet are above his.
	assert_true(harold_feet_front - Player.SPRITE_FEET_Y < enemy.position.y, "the old origin order was wrong here")
	enemy.free()


func test_the_player_look_stands_on_his_feet_below_his_own_drawing() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/actors/player.gd")
	assert_true(source.contains("_visual.set_feet(SPRITE_FEET_Y)"))
	assert_true(source.contains("_visual.z_index = -1"), "his sprite at z 0 among the bodies")
	assert_true(source.contains("z_index = 1"), "his swing and cane over every body")


func test_flat_floor_things_sit_under_the_bodies() -> void:
	var hole := Hole.new()
	hole._ready()
	assert_true(hole.z_index < 0)
	hole.free()
	var pool := PoolWater.new()
	pool._ready()
	assert_true(pool.z_index < 0)
	pool.free()
