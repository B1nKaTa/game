extends SceneTree
# Opens a real window on the animated title screen and saves a timed sequence of shots, so its motion
# can be judged: about 30 s of the room (ghosts talking, fidgeting and changing seats, Harold's idles,
# the board and the lamp), the menu's slide-out and tear-off, and seated Harold bare and dressed.
# Harold's look comes from Progress.data.cosmetics_worn set in memory here, never from a saved file.
# Run only from an exported copy whose config/name is renamed:
#   Godot --path <copy> --script res://tools/probes/title_look.gd

const OUT := "D:/grandpa-shots-ad/title/"
const WALL_LIMIT_MS := 180000
const SEQUENCE := 36
const STEP := 0.85
const DRESSED := {"hat": "flat_cap", "cardigan": "mustard_cardigan", "cane": "candy_stripe"}

var _start := 0
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String, crop := Rect2i()) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if crop.has_area():
		image = image.get_region(crop)
		image.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _title(worn: Dictionary) -> Node:
	progress.data.cosmetics_worn = worn.duplicate()
	change_scene_to_file("res://scenes/title.tscn")
	await process_frame
	await process_frame
	return current_scene


func _main() -> void:
	root.size = Vector2i(1280, 720)
	progress = root.get_node("Progress")
	print("worn before: ", progress.data.cosmetics_worn)
	var title := await _title({})
	await _wait(0.6)
	var t0 := Time.get_ticks_msec()
	for i in SEQUENCE:
		var target := t0 + int(i * STEP * 1000.0)
		while Time.get_ticks_msec() < target:
			await process_frame
		await _shot("seq_%02d_%04.1fs" % [i, (Time.get_ticks_msec() - t0) / 1000.0])
	# Harold, bare and in his own cardigan, close up.
	await _shot("harold_bare", Rect2i(462, 150, 160, 180))
	# The menu: the second ticket selected, then the Credits ticket torn off.
	var tickets: Array = []
	for child in title.get("_menu").get_children():
		tickets.append(child)
	tickets[1].grab_focus()
	await _wait(0.4)
	await _shot("menu_second_selected")
	var credits = null
	for ticket in tickets:
		if ticket.menu_id == "credits":
			credits = ticket
	credits.grab_focus()
	await _wait(0.4)
	await _shot("menu_credits_selected")
	credits.emit_signal("pressed")
	await _wait(0.08)
	await _shot("tear_1")
	await _wait(0.12)
	await _shot("tear_2")
	await _wait(0.12)
	await _shot("tear_3")
	await _wait(0.5)
	await _shot("tear_done_credits")
	# Dressed: a flat cap, the mustard cardigan and the candy-stripe cane.
	title = await _title(DRESSED)
	await _wait(1.0)
	await _shot("dressed_room")
	for i in 6:
		await _shot("harold_dressed_%d" % i, Rect2i(462, 150, 160, 180))
		await _wait(0.9)
	progress.data.cosmetics_worn = {}
	print("PROBE DONE")
	quit(0)
