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
# 1 draws a small woven motif on the carpet patches of the floor, 0 leaves the floor plain.
@export var floor_pattern := 0
@export var carpet_motif := Color(1.0, 1.0, 1.0, 0.12)
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
