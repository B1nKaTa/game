extends TestCase

const S := preload("res://scripts/core/cutscene_steps.gd")
const AUGUSTINE := "augustine"
const AUGUSTINE_STAMP := "ETERNAL REST. ONE WAY."
const AUGUSTINE_TEAR := "I'm not resting. I have business."
const LINE_WIDTH := CutscenePlayer.BOX.size.x - 20.0
const CARD_WIDTH := CutscenePlayer.SCREEN.x - 120.0


# Every scene: Repeat Customer once per quick death.
func _scenes() -> Array[Dictionary]:
	var scenes: Array[Dictionary] = []
	for entry: Dictionary in EndingRules.ALL:
		if entry["id"] == EndingRules.REPEAT_CUSTOMER:
			for n in range(1, EndingRules.REPEAT_DEATHS + 1):
				scenes.append({"name": "repeat %d" % n, "steps": S.for_ending(entry["id"], n), "cause": EndingRules.repeat_cause(n), "quick": true})
		else:
			scenes.append({"name": entry["id"], "steps": S.for_ending(entry["id"]), "cause": entry["cause"], "quick": false})
	return scenes


static func _lines_needed(text: String, width: float, font_size: int) -> int:
	var font := ThemeDB.fallback_font
	var lines := 1
	var current := ""
	for word in text.split(" "):
		var attempt := word if current.is_empty() else current + " " + word
		if font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width and not current.is_empty():
			lines += 1
			current = word
		else:
			current = attempt
	return lines


func test_every_ending_has_a_scene() -> void:
	for scene in _scenes():
		assert_false((scene["steps"] as Array).is_empty(), scene["name"])


func test_every_scene_uses_only_known_steps_stages_and_actors() -> void:
	var all := _scenes()
	all.append({"name": "augustine", "steps": S.for_ending(AUGUSTINE, 0)})
	all.append({"name": "augustine short", "steps": S.for_ending(AUGUSTINE, 1)})
	for scene in all:
		var placed := {}
		for step: Dictionary in scene["steps"]:
			var op: String = step["op"]
			assert_true(S.OPS.has(op), "%s: %s" % [scene["name"], op])
			if op == "stage":
				assert_true(CutsceneStage.STAGES.has(step["name"]), "%s: stage %s" % [scene["name"], step["name"]])
			if op == "actor":
				assert_true(ActorLook.is_known(step["id"]), "%s: actor %s" % [scene["name"], step["id"]])
				placed[step["id"]] = true
			if op == "anim":
				assert_true(S.ANIM_TIME.has(step["name"]), "%s: anim %s" % [scene["name"], step["name"]])
			if op in ["walk", "face", "anim", "tint", "hat", "hide", "look"]:
				assert_true(placed.has(step["id"]), "%s: %s before %s is placed" % [scene["name"], op, step["id"]])
			if op == "hide":
				placed.erase(step["id"])
			if op == "say" and not ActorLook.display_name(step["id"]).is_empty():
				assert_true(placed.has(step["id"]), "%s: %s speaks before he is placed" % [scene["name"], step["id"]])


func test_every_scene_lasts_as_long_as_it_should() -> void:
	for scene in _scenes():
		var length := S.duration_of(scene["steps"])
		if scene["quick"]:
			assert_true(length >= 5.0 and length <= 8.0, "%s lasts %.1f s" % [scene["name"], length])
		else:
			assert_true(length >= 25.0 and length <= 45.0, "%s lasts %.1f s" % [scene["name"], length])


func test_every_scene_opens_on_a_stage_and_ends_on_its_cause_and_a_fade() -> void:
	for scene in _scenes():
		var steps: Array = scene["steps"]
		assert_eq(steps[0]["op"], "stage", scene["name"])
		assert_eq(steps[steps.size() - 1]["op"], "fade_out", "%s ends in a fade" % scene["name"])
		var last_card := ""
		for step: Dictionary in steps:
			if step["op"] == "card":
				last_card = step["text"]
		assert_eq(last_card, scene["cause"], "%s's last card" % scene["name"])
		assert_eq(steps[steps.size() - 2]["op"], "card", "%s: the cause comes just before the fade" % scene["name"])


func test_every_line_fits_its_box() -> void:
	var all := _scenes()
	all.append({"name": "augustine", "steps": S.for_ending(AUGUSTINE, 0)})
	for scene in all:
		for step: Dictionary in scene["steps"]:
			if step["op"] == "say":
				assert_true(_lines_needed(step["text"], LINE_WIDTH, CutscenePlayer.TEXT_SIZE) <= 2, "%s: %s" % [scene["name"], step["text"]])
			elif step["op"] == "card":
				assert_true(_lines_needed(step["text"], CARD_WIDTH, CutscenePlayer.CARD_SIZE) <= 4, "%s: %s" % [scene["name"], step["text"]])


func test_a_quick_death_has_no_story_and_no_gerald() -> void:
	for n in range(1, EndingRules.REPEAT_DEATHS + 1):
		for step: Dictionary in S.for_ending(EndingRules.REPEAT_CUSTOMER, n):
			assert_true(step.get("id", "") != "gerald", "death %d" % n)
			assert_true(step["op"] != "say", "death %d has no lines" % n)


func test_augustines_scene_stamps_and_tears_and_the_short_one_only_that() -> void:
	var full := _texts(S.for_ending(AUGUSTINE, 0))
	var short := _texts(S.for_ending(AUGUSTINE, 1))
	for texts in [full, short]:
		assert_true(texts.has(AUGUSTINE_STAMP), "the stamp")
		assert_true(texts.has(AUGUSTINE_TEAR), "the tear")
	assert_eq(short.size(), 2, "the short scene is just the stamp and the tear")
	assert_true(full.size() > short.size())
	assert_true(S.duration_of(S.for_ending(AUGUSTINE, 1)) < S.duration_of(S.for_ending(AUGUSTINE, 0)))


func test_the_eternal_feud_ends_on_its_own_card_first() -> void:
	var texts := _texts(S.for_ending(EndingRules.ETERNAL_FEUD))
	assert_true(texts.has("Some feuds are eternal. Please take a number."))


func _texts(steps: Array) -> Array:
	var texts := []
	for step: Dictionary in steps:
		if step["op"] == "say" or step["op"] == "card":
			texts.append(step["text"])
	return texts
