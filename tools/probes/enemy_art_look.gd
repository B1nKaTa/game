extends SceneTree
# The enemy art pass's look probe. Run only from an exported copy whose config/name is renamed.
# Args after --: audit | shots | sort | all
#  audit  lists what stands at z 0 in every room of every floor (headless is fine), since the room
#         now sorts by y and a flat floor thing at z 0 would cover feet.
#  shots  opens each art enemy on its own floor: idle, walking, winding up and attacking, with Harold
#         beside each boss, and prints the lit luminance of its body pixels and its visible width
#         against its body box.
#  sort   Harold behind and in front of an NPC and an enemy.

const OUT := "D:/grandpa-shots-r9/"
const WALL_LIMIT_MS := 1500000
const CROP := Vector2i(160, 120)
const WARNING_RED := Color("e4524f")
# floor id -> [depth, path index].
const FLOORS := {
	"floor_1": [1, 0], "cemetery": [1, 1], "sunset_shores": [2, 0], "furnace_works": [2, 1],
	"flashback_cinema": [3, 1], "funeral_parlour": [3, 0], "last_resort_cruise": [4, 0],
	"seance_hotline": [4, 1], "terminal_zero": [5, 0], "head_office": [5, 1],
}
# enemy id -> its floor.
const ENEMIES := [
	["intern_reaper", "floor_1"], ["regional_reaper", "floor_1"],
	["stoker", "furnace_works"], ["old_smokey", "furnace_works"], ["furnace_intern_reaper", "furnace_works"],
	["cinema_intern_reaper", "flashback_cinema"],
	["cruise_stoker", "last_resort_cruise"], ["airport_mall_cop", "terminal_zero"],
	["hr_representative", "head_office"], ["chairman_of_the_board", "head_office"],
	# The second batch (2026-11-06).
	["filing_clerk", "floor_1"], ["debt_ghost", "floor_1"], ["seasonal_temp", "floor_1"], ["notary_public", "floor_1"],
	["burnt_out_auditor", "floor_1"], ["denial_officer", "floor_1"], ["senior_adjuster", "floor_1"],
	["plot_holder", "cemetery"], ["head_groundskeeper", "cemetery"], ["tired_undertaker", "cemetery"],
	["orderly", "sunset_shores"], ["cart_nurse", "sunset_shores"], ["bingo_caller", "sunset_shores"], ["resident", "sunset_shores"],
	["activities_coordinator", "sunset_shores"], ["matron_mercy", "sunset_shores"], ["mimic", "sunset_shores"],
	["shores_seasonal_temp", "sunset_shores"], ["shores_denial_officer", "sunset_shores"],
	["soot_ghost", "furnace_works"], ["foreman_klaus", "furnace_works"], ["steam_valve", "furnace_works"],
	["furnace_burnt_out_auditor", "furnace_works"],
	["weeping_mourner", "funeral_parlour"], ["florist", "funeral_parlour"], ["pallbearer", "funeral_parlour"],
	["reverend", "funeral_parlour"], ["mortimer_grimsby", "funeral_parlour"], ["parlour_plot_holder", "funeral_parlour"],
	["parlour_seasonal_temp", "funeral_parlour"],
	["early_bird_diner", "last_resort_cruise"], ["shuffleboard_shark", "last_resort_cruise"],
	["sunburnt_sunbather", "last_resort_cruise"], ["lorraine", "last_resort_cruise"],
	["commodore_wellington", "last_resort_cruise"], ["cruise_orderly", "last_resort_cruise"],
	["tour_group", "terminal_zero"], ["baggage_handler", "terminal_zero"], ["lost_luggage", "terminal_zero"],
	["sergeant_wanda", "terminal_zero"], ["augustine", "terminal_zero"], ["airport_weeping_mourner", "terminal_zero"],
	["yes_man", "head_office"], ["paper_shredder", "head_office"], ["doreen", "head_office"], ["office_florist", "head_office"],
]
# A boss's own anims, shot by playing each once (the behaviors' play_anim calls are tested).
const OWN_ANIMS := {
	"tired_undertaker": ["wreath_throw", "point"], "matron_mercy": ["charge", "lights_out"],
	"mortimer_grimsby": ["embalming_spray", "conduct"], "commodore_wellington": ["foghorn_blast", "buoy_call"],
	"augustine": ["runway_signal", "gate_change"],
}

# Small-bodied enemies redrawn on 32 to 36 px canvases (2026-11-06), shot beside Harold like the bosses.
const BESIDE_HAROLD := ["seasonal_temp", "tour_group", "yes_man", "weeping_mourner", "early_bird_diner"]

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
	if player != null and is_instance_valid(player) and player.run != null:
		player.run.health.heal(99)
	return false


func _wait(seconds: float) -> void:
	var began := Time.get_ticks_msec()
	while Time.get_ticks_msec() - began < seconds * 1000.0:
		await process_frame


func _main() -> void:
	await process_frame
	progress = root.get_node("Progress")
	progress._store = SaveStore.new("user://look_save.json")
	progress._store.delete_all()
	progress.reload()
	progress.data.floors_cleared = 1
	progress.data.record_floor_cleared(2, "sunset_shores")
	progress.data.record_floor_cleared(3, "funeral_parlour")
	progress.data.record_floor_cleared(4, "last_resort_cruise")
	progress.data.record_floor_cleared(5, "terminal_zero")
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	for part in ["audit", "shots", "sort"]:
		if which == "all" or which == part:
			await call("_" + part)
	progress._store.delete_all()
	print("LOOK DONE")
	quit(0)


func _new_run(floor_id: String) -> void:
	change_scene_to_file("res://scenes/floor.tscn")
	await _wait(0.3)
	scene = current_scene
	player = scene.player
	scene._depth = FLOORS[floor_id][0]
	scene.debug_choose_path(FLOORS[floor_id][1])
	await _wait(0.2)
	view = scene.debug_room_view()
	var got: String = scene.debug_floor_def().id
	if got != floor_id:
		print("WRONG FLOOR %s for %s" % [got, floor_id])
	await _clear()


func _clear() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.dismiss()
	await _wait(0.1)


func _rows(width: int, height: int) -> PackedStringArray:
	var rows := PackedStringArray(["#".repeat(width)])
	for y in range(1, height - 1):
		rows.append("#" + ".".repeat(width - 2) + "#")
	rows.append("#".repeat(width))
	return rows


func _enter_layout(layout: RoomLayout) -> void:
	var map: FloorMap = scene.debug_map()
	var room := FloorRoom.new()
	room.id = map.rooms.size()
	room.cell = Vector2i(70 + room.id, 70)
	room.room_type = layout.room_type
	room.layout = layout
	room.decor_seed = 7 + room.id
	map.rooms.append(room)
	scene._enter_room(room.id)
	await _wait(0.15)
	view = scene.debug_room_view()


func _enter_open() -> void:
	var layout := RoomLayout.new()
	layout.room_type = RoomLayout.TYPE_HEALING
	layout.rows = _rows(20, 11)
	await _enter_layout(layout)


func _cell(x: int, y: int) -> Vector2:
	return RoomBackdrop.cell_center(Vector2i(x, y))


# Stands Harold with his soles on feet.
func _stand(feet: Vector2) -> void:
	player.global_position = feet - Vector2(0.0, Player.SPRITE_FEET_Y)
	player.velocity = Vector2.ZERO


func _spawn(id: String, at: Vector2) -> Enemy:
	return view._spawn_enemy(load("res://data/enemies/%s.tres" % id), at, true)


func _image() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _save(image: Image, shot_name: String, at: Vector2) -> void:
	var middle := Vector2i(at)
	var corner := (middle - CROP / 2).clamp(Vector2i.ZERO, image.get_size() - CROP)
	var crop := image.get_region(Rect2i(corner, CROP))
	crop.resize(CROP.x * 4, CROP.y * 4, Image.INTERPOLATE_NEAREST)
	crop.save_png(OUT + shot_name + "_x4.png")
	var whole := image.duplicate()
	whole.resize(image.get_width() * 2, image.get_height() * 2, Image.INTERPOLATE_NEAREST)
	whole.save_png(OUT + shot_name + ".png")
	print("shot " + shot_name)


func _screen(node: Node2D) -> Vector2:
	return node.get_global_transform_with_canvas().origin


# ---- audit ----

func _audit() -> void:
	var seen := {}
	for floor_id: String in FLOORS:
		await _new_run(floor_id)
		var folder := "res://data/rooms/%s/" % floor_id
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".tres"):
				continue
			var source: RoomLayout = load(folder + file)
			var layout: RoomLayout = source.duplicate()
			layout.room_type = RoomLayout.TYPE_HEALING
			await _enter_layout(layout)
			_list_sorted(view, 0, seen, floor_id)
			await _clear()
	var names := seen.keys()
	names.sort()
	for key in names:
		print("AUDIT z0 %s  (%s)" % [key, seen[key]])


func _list_sorted(node: Node, z: int, seen: Dictionary, floor_id: String) -> void:
	for child in node.get_children():
		if not child is CanvasItem or child is CanvasLayer:
			continue
		var item := child as CanvasItem
		var child_z := item.z_index + (z if item.z_as_relative else 0)
		if child_z == 0 and item.visible:
			var script: Script = item.get_script()
			var key: String = script.get_global_name() if script != null and not script.get_global_name().is_empty() else item.get_class()
			if script != null and script.get_global_name().is_empty():
				key = script.resource_path.get_file()
			if not seen.has(key):
				seen[key] = floor_id
		if item.y_sort_enabled:
			_list_sorted(item, child_z, seen, floor_id)


# ---- shots ----

func _shots() -> void:
	var current := ""
	var args := OS.get_cmdline_user_args()
	var only: String = args[1] if args.size() > 1 else ""
	for entry: Array in ENEMIES:
		var id: String = entry[0]
		var floor_id: String = entry[1]
		# Only these floors or enemy ids, comma separated.
		if not only.is_empty() and not only.split(",").has(floor_id) and not only.split(",").has(id):
			continue
		if floor_id != current:
			await _new_run(floor_id)
			current = floor_id
		await _enter_open()
		await _shoot_enemy(id, floor_id)
		await _clear()


func _shoot_enemy(id: String, floor_id: String) -> void:
	var def: EnemyDef = load("res://data/enemies/%s.tres" % id)
	var boss := def.is_boss
	_stand(_cell(4, 8) + Vector2(0, 14))
	var enemy := _spawn(id, _cell(10, 5))
	await _wait(0.3)
	enemy.set_physics_process(false)
	enemy.global_position = _cell(10, 5)
	enemy.desired_velocity = Vector2.ZERO
	await _wait(0.4)
	var tag := "%s_%s" % [floor_id, id]
	var lit := await _image()
	enemy.visual().visible = false
	var dark := await _image()
	enemy.visual().visible = true
	_measure(id, def, lit, dark, _screen(enemy))
	_save(lit, tag + "_idle", _screen(enemy))
	enemy.desired_velocity = Vector2(-enemy.def.speed, 0.0)
	await _wait(0.25)
	_save(await _image(), tag + "_walk_a", _screen(enemy))
	await _wait(0.2)
	_save(await _image(), tag + "_walk_b", _screen(enemy))
	enemy.desired_velocity = Vector2(enemy.def.speed, 0.0)
	await _wait(0.25)
	_save(await _image(), tag + "_walk_east", _screen(enemy))
	enemy.desired_velocity = Vector2.ZERO
	if boss or BESIDE_HAROLD.has(id):
		# Harold beside him, both soles on one row.
		var feet := enemy.global_position + Vector2(0.0, def.body_size.y / 2.0)
		_stand(feet + Vector2(-def.body_size.x / 2.0 - 16.0, 0.0))
		await _wait(0.3)
		_save(await _image(), tag + "_with_harold", _screen(enemy) + Vector2(-20, 0))
	# Winding up and striking, near Harold, for real.
	_stand(enemy.global_position + Vector2(-44.0 if not boss else -70.0, def.body_size.y / 2.0))
	enemy.set_physics_process(true)
	var began := Time.get_ticks_msec()
	var wound := false
	var struck := false
	var whistled := false
	while Time.get_ticks_msec() - began < 9000 and not (wound and struck) and is_instance_valid(enemy):
		await process_frame
		if not is_instance_valid(enemy):
			break
		if not whistled and enemy.visual().anim() == "whistle":
			whistled = true
			await _wait(0.2)
			_save(await _image(), tag + "_whistle", _screen(enemy))
		var shown: String = enemy.visual().shown_anim()
		if not wound and enemy.is_winding_up() and enemy._warning.warning_progress(enemy._warning_share()) > 0.5:
			wound = true
			_save(await _image(), tag + "_windup_%s" % shown, _screen(enemy))
		elif wound and not struck and enemy.visual().anim() == EnemyAnim.ATTACK:
			struck = true
			await _wait(0.05)
			_save(await _image(), tag + "_attack_%s" % enemy.visual().shown_anim(), _screen(enemy))
	print("ACT %s wound=%s struck=%s" % [id, wound, struck])
	if OWN_ANIMS.has(id) and is_instance_valid(enemy):
		enemy.set_physics_process(false)
		enemy.desired_velocity = Vector2.ZERO
		await _wait(0.6)
		for anim: String in OWN_ANIMS[id]:
			enemy.play_anim(anim, 1.6)
			await _wait(0.5)
			_save(await _image(), tag + "_own_%s_a" % anim, _screen(enemy))
			await _wait(0.6)
			_save(await _image(), tag + "_own_%s_b" % anim, _screen(enemy))
			await _wait(0.6)


# Prints the lit luminance of the pixels that change when the sprite hides, and how wide they are at
# the body box's rows against the box.
func _measure(id: String, def: EnemyDef, lit: Image, dark: Image, at: Vector2) -> void:
	var lums: Array[float] = []
	var top := 1 << 20
	var bottom := -1
	var box_left := 1 << 20
	var box_right := -1
	var box_top := int(at.y - def.body_size.y / 2.0)
	var box_bottom := int(at.y + def.body_size.y / 2.0)
	var coloured := 0
	var reds := 0
	for y in range(maxi(int(at.y) - 90, 0), mini(int(at.y) + 40, lit.get_height())):
		for x in range(maxi(int(at.x) - 70, 0), mini(int(at.x) + 70, lit.get_width())):
			var a := lit.get_pixel(x, y)
			var b := dark.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.06:
				continue
			lums.append(a.get_luminance())
			# Reads as the warning red (#e4524f): its hue within 12 degrees, and as saturated.
			if a.s >= 0.45 and a.v >= 0.25:
				coloured += 1
				if absf(fposmod(a.h * 360.0 - WARNING_RED.h * 360.0 + 180.0, 360.0) - 180.0) <= 12.0:
					reds += 1
			top = mini(top, y)
			bottom = maxi(bottom, y)
			if y >= box_top and y < box_bottom:
				box_left = mini(box_left, x)
				box_right = maxi(box_right, x)
	if lums.is_empty():
		print("MEASURE %s no sprite pixels" % id)
		return
	lums.sort()
	var above := 0
	# The body without its black outline, which lights to near 0.
	var body: Array[float] = []
	for l in lums:
		if l >= 0.08:
			body.append(l)
	if body.is_empty():
		body.append(0.0)
	for l in body:
		if l >= 0.4:
			above += 1
	print("MEASURE %s px=%d body_median_lum=%.3f p75=%.3f body_share>=0.4=%.2f height=%d feet_row=%d box_bottom=%d width_in_box=%d box=%d phys=%d" % [
		id, lums.size(), body[body.size() / 2], lums[lums.size() * 3 / 4], float(above) / body.size(),
		bottom - top + 1, bottom + 1, box_bottom, box_right - box_left + 1, int(def.body_size.x), int(def.body_size.x * 0.8)])
	print("RED %s warning_red_share=%.2f of %d saturated px" % [id, float(reds) / maxi(coloured, 1), coloured])


# ---- y-sort ----

func _sort() -> void:
	await _new_run("floor_1")
	await _enter_open()
	var npc := Npc.new()
	npc.setup(RoomView.MERCHANT, player, 1)
	npc.position = _cell(8, 5)
	view.add_child(npc)
	await _wait(0.3)
	var npc_feet := npc.global_position + Vector2(0.0, RoomView.MERCHANT.body_size.y / 2.0)
	# Behind: his soles 6 px above the NPC's, overlapping.
	_stand(npc_feet + Vector2(6.0, -6.0))
	await _wait(0.3)
	_save(await _image(), "sort_harold_behind_npc", _screen(npc))
	_stand(npc_feet + Vector2(6.0, 6.0))
	await _wait(0.3)
	_save(await _image(), "sort_harold_in_front_of_npc", _screen(npc))
	npc.queue_free()
	# An enemy's body shoves him off when their boxes touch, so he stands just clear of its box: soles
	# above its top to be behind (its head then covers his legs), feet box below its bottom in front.
	for id in ["intern_reaper", "regional_reaper"]:
		var enemy := _spawn(id, _cell(10, 5))
		enemy.set_physics_process(false)
		await _wait(0.3)
		enemy.global_position = _cell(10, 5)
		var half := enemy.def.body_size.y / 2.0
		_stand(enemy.global_position + Vector2(6.0, -half - 2.0))
		await _wait(0.3)
		_save(await _image(), "sort_harold_behind_%s" % id, _screen(enemy))
		_stand(enemy.global_position + Vector2(6.0, half + Player.FEET_BOX_SIZE.y + 2.0))
		await _wait(0.3)
		_save(await _image(), "sort_harold_in_front_of_%s" % id, _screen(enemy))
		await _clear()
