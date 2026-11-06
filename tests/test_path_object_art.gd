extends TestCase

# The Cinema's and the Seance Hotline's thrown things and cards wear their art
# (res://art/props/<id>.png, D:/grandpa-art/newpaths/objects), each keeping its drawing as a fallback.

const OBJECTS := ["planchette", "popcorn_tub", "kernel", "pie", "tumbleweed", "crystal_ball", "stapler",
	"mug", "fax_machine", "tarot_card_back", "tarot_tower", "tarot_death", "tarot_wheel", "tarot_star"]


func test_every_object_has_its_art() -> void:
	for id in OBJECTS:
		var art := PropArt.texture(id)
		assert_true(art != null, id + " has art")
		if art == null:
			continue
		var wanted := Vector2(32, 48) if id.begins_with("tarot_") else Vector2(32, 32)
		assert_eq(art.get_size(), wanted, id)
		var settings := FileAccess.get_file_as_string("res://art/props/%s.png.import" % id)
		assert_true(settings.contains("mipmaps/generate=false") and settings.contains("compress/mode=0"), id + " imported sharp")


func test_each_card_shows_the_art_of_the_side_up() -> void:
	assert_eq(TarotCard.art_id_of(0, false), "tarot_card_back")
	for card in TarotCard.ART_IDS.size():
		var id := TarotCard.art_id_of(card, true)
		assert_true(OBJECTS.has(id), id)
	assert_eq(Vector2(PropArt.texture("tarot_card_back").get_size()), TarotCard.SIZE, "the art replaces the drawing one to one")


func test_thrown_things_name_art_that_exists() -> void:
	for look: String in Projectile.LOOK_ART:
		var id: String = Projectile.LOOK_ART[look][0]
		assert_true(PropArt.texture(id) != null, "%s wears %s" % [look, id])
	assert_true(Projectile.LOOK_ART.has(Projectile.LOOK_STAPLER) and Projectile.LOOK_ART.has(Projectile.LOOK_KERNEL))
	assert_false(Projectile.LOOK_ART.has(Projectile.LOOK_STAR), "the critic's star has no art yet and stays drawn")
	for look in [ReelLane.LOOK_PIE, ReelLane.LOOK_TUMBLEWEED]:
		assert_true(PropArt.texture(look) != null, look)
	assert_true(PropArt.texture(OuijaPlanchette.ART_ID) != null)
	assert_true(PropArt.texture(CrystalBall.ART_ID) != null)
