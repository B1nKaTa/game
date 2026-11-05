extends SceneTree
# Opens a real window and saves screenshots of the Flashback Cinema: small, medium and large rooms with
# their enemies, the screen at two moments of its flicker (and cut to black, flashed and burning, as
# the Projectionist will drive it), a lobby card's line near the top of a room and lower down, and the
# projector's beam in an empty room at both ends of a large one.
# Run only from an exported copy whose config/name is renamed.
# Args after --: rooms | screen | signs | beam | all

const OUT := "D:/grandpa-shots-pr/"
const WALL_LIMIT_MS := 240000
const DIR := "res://data/rooms/flashback_cinema/%s.tres"

var _start := 0
var scene
var view: RoomView
var player: Player
var progress


func _initialize() -> void:
	_start = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(OUT)
	_main.call_deferred()


func _process(_d: float) -> bool:
	if Time.get_ticks_msec() - _start > WALL_LIMIT_MS:
		print("PROBE TIMEOUT")
		quit(3)
	if player != null and is_instance_valid(player):
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _shot(shot_name: String) -> Image:
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	var big := image.duplicate()
	big.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + "cinema_" + shot_name + ".png")
	print("shot " + shot_name)
	return image


# The screen alone, enlarged, cut from a shot.
func _crop_screen(image: Image, shot_name: String) -> void:
	var screen := CinemaScreen.in_room(view)
	if screen == null:
		print("no screen to crop")
		return
	var rect := screen.picture_rect().grow(10.0)
	var canvas := view.get_viewport().get_canvas_transform()
	var on_screen := Rect2(canvas * rect.position, rect.size * canvas.get_scale())
	var scale_x := float(image.get_width()) / RoomBackdrop.VIEW_SIZE.x
	var region := Rect2i(Vector2i(on_screen.position * scale_x), Vector2i(on_screen.size * scale_x)).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var crop := image.get_region(region)
	crop.resize(crop.get_width() * 4, crop.get_height() * 4, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + "cinema_" + shot_name + ".png")
	print("crop " + shot_name)


func _stand(at: Vector2) -> void:
	player.global_position = at - Player.FEET_OFFSET


func _cell(x: int, y: int) -> Vector2:
	return RoomBackdrop.cell_center(Vector2i(x, y))


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	await _new_run()
	for part in ["rooms", "screen", "signs", "beam"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run() -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = 3
	for index in 2:
		if scene._path_defs()[index].id == "flashback_cinema":
			scene.debug_choose_path(index)
	await _wait(0.2)
	view = scene.debug_room_view()
	print("floor %s" % scene.debug_floor_def().display_name)
	await _clear()


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _freeze_all() -> void:
	for e in get_nodes_in_group("enemies"):
		e.set_physics_process(false)


func _enter(file: String, type: String, seed_value := 7) -> RoomLayout:
	var source: RoomLayout = load(DIR % file)
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(90 + room.id, 90)
	room.room_type = type
	room.layout = source
	room.decor_seed = seed_value + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()
	return source


func _show_room(file: String, shot_name: String, stand_side := RoomLayout.SOUTH) -> void:
	var source := await _enter(file, RoomLayout.TYPE_COMBAT)
	_stand(RoomBackdrop.cell_center(source.door_cell(stand_side)) + Vector2(0, -8 if stand_side == RoomLayout.SOUTH else 8))
	await _wait(0.75)
	_freeze_all()
	await _shot(shot_name)
	await _clear()


# --- rooms with their enemies ---

func _rooms() -> void:
	await _show_room("combat_small_01", "room_small")
	await _show_room("combat_small_02", "room_small_pillars")
	await _show_room("combat_01", "room_medium")
	await _show_room("combat_04", "room_medium_pillars")
	await _show_room("combat_large_01", "room_large_south")
	await _show_room("combat_large_03", "room_large_north", RoomLayout.NORTH)
	await _show_room("floor_boss_large_01", "room_boss_large_north", RoomLayout.NORTH)


# --- the screen ---

func _screen() -> void:
	await _enter("combat_02", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(10, 6))
	await _wait(0.5)
	var first := await _shot("screen_medium_a")
	_crop_screen(first, "screen_crop_a")
	await _wait(3.3)
	var second := await _shot("screen_medium_b")
	_crop_screen(second, "screen_crop_b")
	var screen := CinemaScreen.in_room(view)
	screen.flash()
	await _wait(0.05)
	_crop_screen(await _shot("screen_flash"), "screen_crop_flash")
	screen.cut_to_black(1.5)
	await _wait(0.4)
	await _shot("screen_cut_to_black")
	await _wait(1.6)
	screen.set_burning(0.45)
	await _wait(0.2)
	_crop_screen(await _shot("screen_burning"), "screen_crop_burning")
	screen.set_burning(0.0)
	await _enter("combat_small_03", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(7, 5))
	await _wait(0.4)
	_crop_screen(await _shot("screen_small"), "screen_crop_small")


# --- the lobby cards ---

func _sign_in(file: String, shot_name: String) -> void:
	var own: RoomLayout = load(DIR % file)
	var layout := await _enter(file, own.room_type)
	await _clear()
	var card := layout.cells_of(RoomLayout.SYMBOL_LIFE_SIGN)[0]
	_stand(RoomBackdrop.cell_center(card) + Vector2(14, 22))
	await _wait(0.5)
	var shown := ""
	for child in view.get_children():
		if child is LifeSign:
			shown = child.showing_text()
	print("card %s shows: %s" % [file, shown])
	await _shot(shot_name)


func _signs() -> void:
	await _sign_in("combat_01", "sign_near_the_top")
	await _sign_in("combat_large_02", "sign_low_in_a_large_room")
	await _sign_in("healing_small_01", "sign_small_room_east")
	await _sign_in("vault_large_01", "sign_large_room_corner")
	# Walking away hides it again.
	_stand(_cell(10, 8))
	await _wait(0.4)
	await _shot("sign_walked_away")
	print("seen in the save: %s" % str(progress.data.life_signs_seen))


# --- the beam ---

func _beam() -> void:
	await _enter("combat_03", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(17, 9))
	await _wait(0.6)
	await _shot("beam_medium_empty")
	await _enter("combat_large_02", RoomLayout.TYPE_COMBAT)
	await _clear()
	_stand(_cell(6, 14))
	await _wait(0.6)
	await _shot("beam_large_south")
	_stand(_cell(6, 3))
	await _wait(0.8)
	await _shot("beam_large_north")
