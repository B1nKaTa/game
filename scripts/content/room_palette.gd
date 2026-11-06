class_name RoomPalette
extends Resource

# The one place room colors and scatter live. The defaults are the look of the office
# floor, and a FloorDef can carry its own palette to override any of them: a graveyard
# floor swaps the stone colors and leans the scatter towards grass, bones and torches.
@export_group("Room")
@export var floor_a := Color("6a6677")
@export var floor_b := Color("625e6f")
@export var floor_c := Color("6e6a75")
@export var floor_jitter := 0.025
@export var grout := Color(0.0, 0.0, 0.0, 0.12)
@export var speckle := Color(1.0, 1.0, 1.0, 0.06)
@export var wall := Color("3a3547")
@export var wall_line := Color(0.0, 0.0, 0.0, 0.18)
@export var darkness := Color(0.04, 0.03, 0.05)
@export var ambient := Color(0.32, 0.32, 0.48)
@export var torch := Color(1.0, 0.62, 0.3)
# Faint light spread through the room, so far corners never go black.
@export var fill_light := Color(0.75, 0.72, 0.9)
@export_group("Props")
@export var crate := Color("6b4a2a")
@export var crate_edge := Color("3a2614")
@export var rock := Color("7b7987")
@export var rock_edge := Color("34313f")
# Reinforced stone must never read as a plain rock: cold steel blue with glowing seams.
@export var reinforced := Color("33506e")
@export var reinforced_edge := Color("0d1a2b")
@export var reinforced_glow := Color("5fd8ff")
@export var barrel := Color("8a5a2b")
@export var barrel_band := Color("3a2614")
@export var hole := Color("0a0810")
@export var hole_rim := Color("2c2838")
@export var bones := Color("d9d2bc")
@export var gravestone := Color("8d9490")
@export var gravestone_edge := Color("2f3532")
@export var gravestone_moss := Color("5d7d45")
@export var dead_tree := Color("41352b")
@export var dead_tree_edge := Color("1d1712")
# Care home furniture. Wheelchairs and trolleys break like barrels, armchairs and beds like rocks.
@export var wheelchair := Color("5b6470")
@export var wheelchair_seat := Color("7a9cc6")
@export var tray := Color("d8d2c4")
@export var tray_frame := Color("8b8f96")
@export var tray_food := Color("d9a441")
@export var armchair := Color("a8637a")
@export var armchair_edge := Color("4a2532")
@export var bed := Color("9aa3ad")
@export var bed_sheet := Color("b9d4e6")
# Boiler hall stock. Coal sacks and crates break like barrels, coal heaps like rocks, and a pipe
# valve blocks nothing and breaks to anything, like grass.
@export var sack := Color("7a6a52")
@export var coal := Color("2a2524")
@export var coal_edge := Color("0e0c0c")
@export var coal_shine := Color("6a6268")
@export var pipe := Color("7c7f86")
@export var valve_wheel := Color("c8463c")
# Funeral parlour stock. Hymn-book carts break like barrels, chapel pews like rocks, and wreath and
# candle stands block nothing and break to anything, like grass.
@export var pew := Color("5a3423")
@export var pew_edge := Color("24130b")
@export var hymn_cart := Color("6b4a2a")
@export var hymn_book := Color("7a2f3a")
@export var wreath_leaf := Color("3f6b34")
@export var wreath_bloom := Color("e6e0d0")
@export var candle_wax := Color("efe6cf")
@export var candle_flame := Color("ffd27a")
@export var brass := Color("c9a25a")
@export var coffin_wood := Color("4a2a1c")
@export var coffin_lid := Color("6b3d26")
@export_group("Decor")
@export var grass := Color("557f48")
@export var grass_cut := Color("3f5f38")
@export var cobweb := Color(0.92, 0.92, 0.96, 0.55)
@export var puddle := Color(0.35, 0.48, 0.66, 0.5)
@export var floor_crack := Color(0.0, 0.0, 0.0, 0.38)
@export var lantern := Color("ffb347")
@export var lantern_light := Color(1.0, 0.78, 0.45)
@export var torch_flame := Color("ffd24a")
@export var stump := Color("5a4630")
@export var stump_top := Color("9a8460")
@export var moss := Color("4f6f3c")
@export var sapling := Color("3a2f25")
# A mopped floor shows as a pale sheen with bright streaks, beside a yellow caution sign.
@export var wet := Color(0.72, 0.88, 1.0, 0.3)
@export var wet_shine := Color(1.0, 1.0, 1.0, 0.55)
@export var caution := Color("f2c230")
@export var vase := Color("5f8fb5")
@export var vase_flower := Color("f08aa8")
@export var vase_leaf := Color("5c8a4a")
@export var plant_pot := Color("b0613f")
@export var plant_leaf := Color("5f9a52")
@export var iv_stand := Color("c7ccd4")
@export var iv_bag := Color(0.75, 0.9, 1.0, 0.85)
# Benches, food court tables and the fluorescent panels overhead, on the cruise, at the airport and in
# the office.
@export var bench := Color("7a5a3a")
@export var food_table := Color("e8e2d2")
@export var fluorescent := Color(0.85, 0.95, 1.0)
# 1 draws a small woven motif on the carpet patches of the floor, 2 lays iron grating on them, and 0
# leaves the floor plain. (3 was the retired Mall's polished tile.)
# 4 lays Head Office carpet tiles, a seam round each and flecks in the pile.
@export var floor_pattern := 0
@export var carpet_motif := Color(1.0, 1.0, 1.0, 0.12)
# 1 draws courses of brick on the walls, 2 upright wooden panels under a rail, 3 the slats of closed
# shop shutters, 0 a single line.
# 4 paints Head Office plaster over a darker dado, with a chair rail and a skirting board.
@export var wall_pattern := 0
@export var brick_line := Color(0.0, 0.0, 0.0, 0.3)
# How much every torch and lantern's light wobbles, as a share of its strength. 0 keeps it steady.
@export var flicker := 0.0
@export var gauge := Color("b8b2a4")
@export var gauge_needle := Color("c8463c")
@export var furnace := Color("2e2826")
@export var furnace_fire := Color("ff9a3a")
@export var coal_dust := Color(0.05, 0.04, 0.04, 0.35)
# How many free floor cells, as a fraction, get a piece of scatter, and how much each
# kind is wanted compared with the others. A kind left out of the weights never appears.
@export var decor_density := 0.07
@export var decor_weights := {
	"grass": 3.0,
	"bones": 2.0,
	"cobweb": 2.0,
	"puddle": 2.0,
	"crack": 3.0,
	"torch": 0.6,
	"lantern": 1.0,
}
# The most lanterns and torches the scatter adds to a room. Ones the layout places don't count.
@export var scatter_lights := 3
# Fairway's End. Sand bunkers are a pale bed of grains, dark ones and a few bright ones.
@export_group("Fairway's End")
@export var sand := Color("d9c48c")
@export var sand_grain := Color("8a7344")
@export var sand_shine := Color("fff4d2")
# The fairway's lighter mown stripe, laid over every other pair of columns (GolfLook.FAIRWAY).
@export var fairway_stripe := Color(1.0, 1.0, 0.85, 0.08)
# Flag pins break to anything, ball washers like barrels, hedges and parked carts like rocks.
@export var hedge := Color("2f6a32")
@export var hedge_leaf := Color("3f8a40")
@export var golf_cart := Color("ece8da")
@export var golf_cart_roof := Color("3f7a4a")
@export var flag_cloth := Color("d9453b")
@export var flag_pole := Color("f4f1e6")
@export var ball_washer := Color("3b6fb0")
# Thin ground fog (RoomDecor.FOG): faint flat wisps, kept see-through so nothing under them hides.
@export var fog := Color(0.75, 0.82, 0.95, 0.14)
# The Flashback Cinema. The carpet runners (CinemaLook.CARPET), the gold of the art-deco trim, the plum
# velvet seat rows, the pillars, the little aisle lights in the floor, and the screen on the north wall
# of every fighting room with the projector's beam from the south, when screen is on.
@export_group("The Flashback Cinema")
@export var carpet_runner := Color("23595c")
@export var deco_gold := Color("c9a24a")
@export var deco_gold_dim := Color(0.79, 0.64, 0.29, 0.55)
@export var seat_velvet := Color("6e3f7c")
@export var seat_velvet_dark := Color("3f2348")
@export var pillar := Color("3a3a52")
@export var pillar_edge := Color("17172a")
@export var aisle_light := Color("ffcf7a")
@export var screen_glow := Color(0.7, 0.8, 1.0)
@export var projector_beam := Color(1.0, 0.86, 0.62)
@export var screen := false
# The Seance Hotline. The wall trim (SeanceLook.STAR_WALL), the violet cubicle partitions in their teal
# frames, the psychics' desks with a phone whose display glows green and a crystal ball, the draped
# seance table, the lava lamps' glass, wax and soft light, the beaded curtains' two bead colours, and the
# ectoplasm, a deep dark green kept well away from the safe-spot mint.
@export_group("Seance Hotline")
@export var seance_trim := Color("4fa8a3")
@export var partition_fabric := Color("6b4d8f")
@export var partition_frame := Color("3e8c88")
@export var desk_wood := Color("54433a")
@export var desk_top := Color("6e5a4c")
@export var phone_glow := Color("8ce64d")
@export var crystal_ball := Color(0.76, 0.86, 1.0, 0.9)
@export var table_cloth := Color("3a1f4d")
@export var table_fringe := Color("c9a24a")
@export var lava_glass := Color(0.32, 0.72, 0.78, 0.85)
@export var lava_wax := Color("e85fc8")
@export var lava_light := Color(0.85, 0.5, 0.95)
@export var beads_warm := Color("e0a84a")
@export var beads_cool := Color("4fb3b0")
@export var ectoplasm := Color("1f6b45")


func weight_of(kind: String) -> float:
	return maxf(float(decor_weights.get(kind, 0.0)), 0.0)


# Patches of floor lean one way, and every cell wobbles a little, so it never reads as a checkerboard.
# Which of the three floor tones a cell's patch takes: 0 for floor_a, 1 for floor_b, 2 for floor_c.
func patch_of(cell: Vector2i, seed_value: int) -> int:
	var patch_roll := RoomDecor.noise(Vector2i(floori(cell.x / 3.0), floori(cell.y / 3.0)), seed_value + 101)
	if patch_roll >= 0.66:
		return 2
	return 1 if patch_roll >= 0.33 else 0


func floor_color(cell: Vector2i, seed_value: int) -> Color:
	var base: Color = [floor_a, floor_b, floor_c][patch_of(cell, seed_value)]
	var wobble := (RoomDecor.noise(cell, seed_value) - 0.5) * 2.0 * floor_jitter
	return Color(clampf(base.r + wobble, 0.0, 1.0), clampf(base.g + wobble, 0.0, 1.0), clampf(base.b + wobble, 0.0, 1.0))
