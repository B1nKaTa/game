class_name BeadedCurtain
extends Node2D

# A beaded curtain hung across a gap in a hotline room: a rail and strands of warm and cool beads. It
# blocks nothing and never breaks; anyone walks straight through, and the strands part round Grandpa as
# he does. It lies flat under the bodies, faint enough that nothing behind it hides. Its picture is
# 48x64, a little wider and taller than its cell.
const ART_SIZE := Vector2(48, 64)
const STRANDS := 7
const TOP := -28.0
const BOTTOM := 26.0
# How near his feet must come, across and along, for the strands to part, and how far they swing.
const NEAR := Vector2(26, 34)
const PART := 9.0
const ALPHA := 0.8

var palette: RoomPalette
var toucher: Node2D
var _parted_at := INF


# How far a strand at strand_x swings aside for something passing at toucher_x: away from it, most for
# the strands nearest, and not at all for a strand more than a third of the curtain away.
static func strand_shift(strand_x: float, toucher_x: float) -> float:
	var gap := strand_x - toucher_x
	var reach := ART_SIZE.x / 3.0
	if absf(gap) >= reach:
		return 0.0
	var away := 1.0 if gap >= 0.0 else -1.0
	return away * PART * (1.0 - absf(gap) / reach)


static func is_near(offset: Vector2) -> bool:
	return absf(offset.x) < NEAR.x and absf(offset.y) < NEAR.y


func art_id() -> String:
	return "beaded_curtain"


func _ready() -> void:
	z_index = Hole.FLOOR_Z
	queue_redraw()


func _process(_delta: float) -> void:
	var parted := INF
	if toucher != null and is_instance_valid(toucher) and toucher.is_inside_tree():
		var offset := toucher.global_position - global_position
		if is_near(offset):
			parted = offset.x
	if parted != _parted_at:
		_parted_at = parted
		queue_redraw()


func _draw() -> void:
	var p := palette if palette != null else RoomPalette.new()
	var half := ART_SIZE.x / 2.0 - 2.0
	draw_rect(Rect2(-half, TOP - 3, half * 2.0, 3), p.desk_wood)
	for strand in STRANDS:
		var x := -half + 3.0 + strand * (half * 2.0 - 6.0) / (STRANDS - 1)
		var shift := 0.0 if _parted_at == INF else strand_shift(x, _parted_at)
		var bead := 0
		var y := TOP
		while y < BOTTOM:
			var sway := shift * (y - TOP) / (BOTTOM - TOP)
			var color := p.beads_warm if (bead + strand) % 2 == 0 else p.beads_cool
			draw_rect(Rect2(x + sway - 1.0, y, 2, 3), Color(color, ALPHA))
			y += 5.0
			bead += 1
