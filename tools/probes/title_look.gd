extends SceneTree
# Opens a real window on the animated title screen and saves shots of it into OUT:
# - a timed sequence of the room (ghosts talking, fidgeting and changing seats, Harold's idles, the board
#   and the lamp), for a contact sheet;
# - the ticket menu with each ticket selected, and a ticket torn off;
# - Options opened from the title (each tab) and from the pause menu, and the Credits;
# - Harold's chair at 4x in every seated frame, bare and dressed, and his rest frame in every hat,
#   cardigan and cane.
# Harold's look comes from Progress.data.cosmetics_worn set in memory here, never from a saved file.
# Classes whose scripts name autoloads are loaded by path, never named. Run only from an exported copy
# whose config/name is renamed:
#   Godot --path <copy> --script res://tools/probes/title_look.gd

const OUT := "D:/grandpa-shots-ad/title/v2/"
const WALL_LIMIT_MS := 240000
const SEQUENCE := 14
const STEP := 0.75
const DRESSED := {"hat": "flat_cap", "cardigan": "mustard_cardigan", "cane": "candy_stripe"}
# Harold's chair, in view pixels, for the 4x close-ups.
const CHAIR_CROP := Rect2i(482, 186, 120, 144)
const LOOKS: Array[Dictionary] = [
	{"hat": "aviator_sunglasses"}, {"hat": "captains_hat"}, {"hat": "fountain_tiara"}, {"hat": "geralds_hat"},
	{"hat": "golf_visor"}, {"hat": "party_hat"}, {"hat": "reaper_hood"},
	{"cardigan": "bingo_teal"}, {"cardigan": "burgundy_cardigan"}, {"cardigan": "power_tie"},
	{"cane": "polished_oak"}, {"cane": "sooty_cane"},
]

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


func _shot(shot_name: String, crop := Rect2i(), zoom := 1) -> void:
	await process_frame
	var image := root.get_texture().get_image()
	if crop.has_area():
		image = image.get_region(crop)
	if zoom > 1:
		image.resize(image.get_width() * zoom, image.get_height() * zoom, Image.INTERPOLATE_NEAREST)
	image.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _title(worn: Dictionary) -> Node:
	progress.data.cosmetics_worn = worn.duplicate()
	change_scene_to_file("res://scenes/title.tscn")
	await process_frame
	await process_frame
	return current_scene


func _room(title: Node) -> Node:
	for child in title.get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("title_room.gd"):
			return child
	return null


# Holds Harold on one frame (his idles paused) and shoots his chair at 4x.
func _harold_frames(title: Node, prefix: String) -> void:
	var harold = _room(title).harold
	harold.set_process(false)
	for frame in 25:
		harold._show(frame)
		await process_frame
		await _shot("%s_%02d" % [prefix, frame], CHAIR_CROP, 4)
	harold.set_process(true)


func _main() -> void:
	root.size = Vector2i(1280, 720)
	# Real keys and clicks never reach the menu while it shoots (a keypress meant for another window once
	# chose New Game mid-sequence); the probe moves focus and presses tickets itself.
	root.gui_disable_input = true
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
	# Every ticket selected in turn.
	var tickets: Array = []
	for child in title.get("_menu").get_children():
		tickets.append(child)
	for ticket in tickets:
		ticket.grab_focus()
		await _wait(0.35)
		await _shot("menu_%s" % ticket.menu_id)
	await _shot("menu_close", Rect2i(200, 200, 160, 160), 3)
	# Options from the title, every tab.
	title._choose("options")
	await _wait(0.4)
	var options = title.get("_overlay")
	for tab in ["video", "audio", "game", "input"]:
		options._show_tab(tab)
		await _wait(0.2)
		await _shot("options_title_%s" % tab)
	title._close_overlay()
	await _wait(0.3)
	# The Credits ticket torn off, then the Credits.
	var credits = null
	for ticket in title.get("_menu").get_children():
		if ticket.menu_id == "credits":
			credits = ticket
	credits.grab_focus()
	await _wait(0.3)
	credits.emit_signal("pressed")
	await _wait(0.12)
	await _shot("tear_1")
	await _wait(0.15)
	await _shot("tear_2")
	await _wait(0.6)
	await _shot("credits_1")
	await _wait(2.5)
	await _shot("credits_2")
	title._close_overlay()
	await _wait(0.3)
	# The pause menu over the title, and Options opened from it.
	var pause = load("res://scripts/ui/pause_menu.gd").new()
	pause.setup(true)
	root.add_child(pause)
	await _wait(0.4)
	await _shot("pause_menu")
	pause._open_options()
	await _wait(0.4)
	await _shot("options_from_pause")
	pause.queue_free()
	await _wait(0.2)
	# Harold's chair, every seated frame, bare and dressed.
	await _harold_frames(title, "harold_bare")
	title = await _title(DRESSED)
	await _wait(0.6)
	await _shot("dressed_room")
	await _harold_frames(title, "harold_dressed")
	# His rest frame in every other hat, cardigan and cane.
	for look in LOOKS:
		title = await _title(look)
		await _wait(0.3)
		var harold = _room(title).harold
		harold.set_process(false)
		harold._show(0)
		await process_frame
		await _shot("look_%s" % str(look.values()[0]), CHAIR_CROP, 4)
	progress.data.cosmetics_worn = {}
	print("PROBE DONE")
	quit(0)
