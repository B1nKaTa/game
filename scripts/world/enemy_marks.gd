class_name EnemyMarks
extends Node2D

# Signs drawn over an enemy's body, so its type and its shield read without any art.
const SHIELD_COLOR := Color("dfe9f5")
const SHIELD_FLASH := Color("ffd24a")
const SHIELD_FLASH_TIME := 0.15
const SHIELD_GAP := 5.0
const SHIELD_WIDTH := 4.0
const STAMP_COLOR := Color("f3eaff")
const FUSE_COLOR := Color("1c1208")
const SPARK_COLOR := Color("ffe58a")
const TEETH_COLOR := Color("20240f")
const DIRT_COLOR := Color("4a3a24")
const SPADE_HANDLE := Color("6b4a2a")
const SPADE_BLADE := Color("c9cdd6")
const HAT_COLOR := Color("15131a")
const HAT_BAND := Color("7a2f3a")
const SYRINGE_COLOR := Color("dff3ff")
const CAP_COLOR := Color("fbf7ef")
const CAP_BAND := Color("d9576b")
const CARD_COLOR := Color("fff6d8")
const CARD_DOT := Color("d9576b")
const LANYARD_COLOR := Color("3b7dd8")
const BADGE_COLOR := Color("fff6d8")
const SHOVEL_HANDLE := Color("5a3b22")
const SHOVEL_BLADE := Color("9aa0a8")
const COAL_COLOR := Color("1a1513")
const VALVE_WHEEL := Color("d9453b")
const VALVE_HUB := Color("e8e2d6")
const SOOT_EYES := Color("ffb347")
const HARD_HAT := Color("f2c230")
const HAT_BRIM := Color("8a6a12")
const STOVEPIPE := Color("2a2426")
const STOVEPIPE_BAND := Color("ff8a2a")
const JAW_LID := Color("c9884a")
const JAW_MOUTH := Color("3a1418")
const JAW_TEETH := Color("f4f1e6")
const JAW_TONGUE := Color("e07a8a")
const JAW_LOCK := Color("e2b33c")
const VEIL := Color(0.08, 0.06, 0.1, 0.75)
const TEAR := Color("8fd0ff")
const STEM := Color("3f6b34")
const BLOOMS: Array[Color] = [Color("d9576b"), Color("f2e6c8"), Color("e6a3c8")]
const GLOVE := Color("f4f1e6")
const COLLAR := Color("15131a")
const COLLAR_TAB := Color("fbf7ef")
const BOOK := Color("4a1c24")
const BOOK_EDGE := Color("e2b33c")
const DIRECTOR_HAT := Color("15131a")
const DIRECTOR_BAND := Color("7a2f3a")
const CARNATION := Color("fbf7ef")
const SWEATBAND := Color("f4f1e6")
const SNEAKER := Color("fbfbff")
const COP_CAP := Color("1c2340")
const COP_PEAK := Color("0c1020")
const COP_BADGE := Color("e2c25a")
const WHISTLE := Color("c9cdd6")
const PERFUME_GLASS := Color(0.85, 0.95, 1.0, 0.85)
const PERFUME_BULB := Color("d9576b")
const TIARA := Color("e8e4f0")
const TIARA_GEM := Color("6fd6ff")
const PEARL := Color("fbf7ef")
const PURSE := Color("8a2f6a")
const SANTA_RED := Color("c4161c")
const SANTA_WHITE := Color("fbfbff")
const SANTA_BELT := Color("15131a")
const ELF_HAT := Color("1f7a34")

var _def: EnemyDef
var _facing := Vector2.RIGHT
var _flash_left := 0.0


func setup(def: EnemyDef) -> void:
	_def = def


func show_facing(facing: Vector2) -> void:
	if _def.shield_half_angle > 0.0 and not facing.is_equal_approx(_facing):
		_facing = facing
		queue_redraw()


func flash_shield() -> void:
	_flash_left = SHIELD_FLASH_TIME
	queue_redraw()


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		queue_redraw()


func _draw() -> void:
	if _def == null:
		return
	var half := _def.body_size / 2.0
	match _def.mark:
		"stamp":
			draw_rect(Rect2(-half.x + 3.0, -half.y + 3.0, half.x * 2.0 - 6.0, 7.0), STAMP_COLOR)
			draw_rect(Rect2(-2.0, -half.y + 10.0, 4.0, 5.0), STAMP_COLOR)
		"fuse":
			draw_line(Vector2(0.0, -half.y), Vector2(5.0, -half.y - 6.0), FUSE_COLOR, 2.0)
			draw_circle(Vector2(5.0, -half.y - 7.0), 2.5, SPARK_COLOR)
		"teeth":
			for x in [-3.0, 1.0]:
				draw_rect(Rect2(x, -1.0, 2.0, 3.0), TEETH_COLOR)
		"dirt":
			for x in [-half.x + 2.0, -2.0, half.x - 5.0]:
				draw_rect(Rect2(x, half.y - 6.0, 4.0, 6.0), DIRT_COLOR)
		"spade":
			draw_line(Vector2(half.x + 3.0, -half.y), Vector2(half.x + 3.0, half.y - 8.0), SPADE_HANDLE, 2.0)
			draw_rect(Rect2(half.x, half.y - 9.0, 7.0, 9.0), SPADE_BLADE)
		"top_hat":
			draw_rect(Rect2(-half.x * 0.6, -half.y - 10.0, half.x * 1.2, 12.0), HAT_COLOR)
			draw_rect(Rect2(-half.x * 0.85, -half.y + 1.0, half.x * 1.7, 3.0), HAT_COLOR)
			draw_rect(Rect2(-half.x * 0.6, -half.y - 2.0, half.x * 1.2, 2.0), HAT_BAND)
		"syringe":
			draw_rect(Rect2(-half.x + 2.0, -3.0, half.x * 2.0 - 8.0, 5.0), SYRINGE_COLOR)
			draw_rect(Rect2(-half.x + 2.0, -3.0, half.x * 2.0 - 8.0, 5.0), Color.BLACK, false, 1.0)
			draw_line(Vector2(half.x - 6.0, -0.5), Vector2(half.x + 2.0, -0.5), SYRINGE_COLOR, 1.0)
		"nurse_cap":
			draw_rect(Rect2(-half.x * 0.7, -half.y - 5.0, half.x * 1.4, 6.0), CAP_COLOR)
			draw_rect(Rect2(-half.x * 0.7, -half.y - 2.0, half.x * 1.4, 2.0), CAP_BAND)
		"card":
			draw_rect(Rect2(-6.0, -4.0, 12.0, 12.0), CARD_COLOR)
			for i in 3:
				draw_rect(Rect2(-4.0 + i * 3.0, -2.0 + (i % 2) * 4.0, 2.0, 2.0), CARD_DOT)
		"lanyard":
			draw_polyline(PackedVector2Array([Vector2(-6.0, -half.y + 3.0), Vector2(0.0, 2.0), Vector2(6.0, -half.y + 3.0)]), LANYARD_COLOR, 2.0)
			draw_rect(Rect2(-4.0, 2.0, 8.0, 6.0), BADGE_COLOR)
		"matron_cap":
			draw_rect(Rect2(-half.x * 0.6, -half.y - 8.0, half.x * 1.2, 9.0), CAP_COLOR)
			draw_rect(Rect2(-half.x * 0.6, -half.y - 4.0, half.x * 1.2, 3.0), CAP_BAND)
			draw_rect(Rect2(-2.0, -half.y - 7.0, 4.0, 3.0), CAP_BAND)
		"shovel":
			draw_line(Vector2(half.x + 2.0, -half.y + 2.0), Vector2(half.x + 2.0, half.y - 7.0), SHOVEL_HANDLE, 2.0)
			draw_rect(Rect2(half.x - 1.0, half.y - 8.0, 7.0, 7.0), SHOVEL_BLADE)
			draw_circle(Vector2(half.x + 2.5, half.y - 6.0), 2.0, COAL_COLOR)
		"valve":
			draw_arc(Vector2.ZERO, half.x * 0.6, 0.0, TAU, 16, VALVE_WHEEL, 2.0)
			draw_line(Vector2(-half.x * 0.6, 0.0), Vector2(half.x * 0.6, 0.0), VALVE_WHEEL, 2.0)
			draw_line(Vector2(0.0, -half.x * 0.6), Vector2(0.0, half.x * 0.6), VALVE_WHEEL, 2.0)
			draw_circle(Vector2.ZERO, 2.5, VALVE_HUB)
		"soot":
			draw_circle(Vector2(-3.5, -half.y + 7.0), 2.0, SOOT_EYES)
			draw_circle(Vector2(3.5, -half.y + 7.0), 2.0, SOOT_EYES)
		"hard_hat":
			draw_rect(Rect2(-half.x * 0.6, -half.y - 6.0, half.x * 1.2, 7.0), HARD_HAT)
			draw_rect(Rect2(-half.x * 0.85, -half.y, half.x * 1.7, 2.0), HAT_BRIM)
		"stovepipe":
			draw_rect(Rect2(-half.x * 0.45, -half.y - 14.0, half.x * 0.9, 15.0), STOVEPIPE)
			draw_rect(Rect2(-half.x * 0.45, -half.y - 4.0, half.x * 0.9, 2.0), STOVEPIPE_BAND)
			draw_rect(Rect2(-half.x * 0.7, -half.y, half.x * 1.4, 3.0), STOVEPIPE)
		"chest_jaw":
			# The lid gapes over a row of teeth and a tongue, with the gold lock still on it.
			draw_rect(Rect2(-half.x, -half.y, half.x * 2.0, 5.0), JAW_LID)
			draw_rect(Rect2(-half.x, -half.y + 5.0, half.x * 2.0, 4.0), JAW_MOUTH)
			for i in 5:
				draw_rect(Rect2(-half.x + 2.0 + i * (half.x * 2.0 - 4.0) / 5.0, -half.y + 5.0, 2.5, 2.5), JAW_TEETH)
			draw_rect(Rect2(-3.0, -half.y + 7.0, 6.0, 2.0), JAW_TONGUE)
			draw_rect(Rect2(-2.0, -half.y + 1.0, 4.0, 3.0), JAW_LOCK)
		"veil":
			# A black veil over the head, with a tear running from under it.
			draw_rect(Rect2(-half.x, -half.y - 2.0, half.x * 2.0, half.y * 0.8), VEIL)
			draw_circle(Vector2(-3.0, -half.y * 0.1), 1.5, TEAR)
			draw_line(Vector2(-3.0, -half.y * 0.1), Vector2(-3.0, half.y * 0.2), TEAR, 1.0)
		"bouquet":
			draw_line(Vector2(half.x - 2.0, half.y - 4.0), Vector2(half.x + 3.0, -2.0), STEM, 2.0)
			for i in BLOOMS.size():
				draw_circle(Vector2(half.x + 1.0 + i * 2.5, -4.0 + (i % 2) * 2.0), 2.5, BLOOMS[i])
		"white_gloves":
			draw_rect(Rect2(-half.x - 2.0, 0.0, 4.0, 4.0), GLOVE)
			draw_rect(Rect2(half.x - 2.0, 0.0, 4.0, 4.0), GLOVE)
		"collar":
			# A clerical collar and a hymn book held to one side.
			draw_rect(Rect2(-half.x * 0.5, -half.y + 8.0, half.x, 4.0), COLLAR)
			draw_rect(Rect2(-2.0, -half.y + 8.0, 4.0, 4.0), COLLAR_TAB)
			draw_rect(Rect2(half.x - 4.0, 0.0, 9.0, 11.0), BOOK)
			draw_rect(Rect2(half.x - 4.0, 0.0, 9.0, 11.0), BOOK_EDGE, false, 1.0)
		"carnation_hat":
			# A tall black hat with a burgundy band, and a white carnation in the lapel.
			draw_rect(Rect2(-half.x * 0.5, -half.y - 14.0, half.x, 15.0), DIRECTOR_HAT)
			draw_rect(Rect2(-half.x * 0.5, -half.y - 4.0, half.x, 3.0), DIRECTOR_BAND)
			draw_rect(Rect2(-half.x * 0.8, -half.y, half.x * 1.6, 3.0), DIRECTOR_HAT)
			draw_circle(Vector2(-half.x * 0.45, -half.y * 0.3), 3.0, CARNATION)
		"headband":
			# A sweatband round the head and white sneakers.
			draw_rect(Rect2(-half.x, -half.y + 3.0, half.x * 2.0, 3.0), SWEATBAND)
			draw_rect(Rect2(-half.x + 1.0, half.y - 3.0, 5.0, 3.0), SNEAKER)
			draw_rect(Rect2(half.x - 6.0, half.y - 3.0, 5.0, 3.0), SNEAKER)
		"cop_cap":
			# A peaked cap with a badge, and a whistle on a cord.
			draw_rect(Rect2(-half.x * 0.7, -half.y - 5.0, half.x * 1.4, 6.0), COP_CAP)
			draw_rect(Rect2(-half.x * 0.9, -half.y, half.x * 1.8, 2.0), COP_PEAK)
			draw_rect(Rect2(-1.5, -half.y - 4.0, 3.0, 3.0), COP_BADGE)
			draw_line(Vector2(-3.0, -half.y + 9.0), Vector2(2.0, 2.0), COP_BADGE, 1.0)
			draw_rect(Rect2(1.0, 1.0, 5.0, 3.0), WHISTLE)
		"perfume":
			# A cut-glass bottle with a squeeze bulb, held out to one side.
			draw_rect(Rect2(half.x - 1.0, -4.0, 7.0, 9.0), PERFUME_GLASS)
			draw_rect(Rect2(half.x - 1.0, -4.0, 7.0, 9.0), Color.BLACK, false, 1.0)
			draw_line(Vector2(half.x + 2.5, -4.0), Vector2(half.x + 2.5, -8.0), Color.BLACK, 1.0)
			draw_circle(Vector2(half.x + 2.5, -10.0), 3.0, PERFUME_BULB)
		"tiara":
			# A sparkling tiara, a string of pearls and a purse of wishing-well coins.
			var points := PackedVector2Array([Vector2(-half.x * 0.6, -half.y + 1.0), Vector2(-half.x * 0.35, -half.y - 5.0), Vector2(-half.x * 0.15, -half.y - 1.0), Vector2(0.0, -half.y - 8.0), Vector2(half.x * 0.15, -half.y - 1.0), Vector2(half.x * 0.35, -half.y - 5.0), Vector2(half.x * 0.6, -half.y + 1.0)])
			draw_polyline(points, TIARA, 2.0)
			draw_circle(Vector2(0.0, -half.y - 8.0), 2.0, TIARA_GEM)
			for i in 5:
				draw_circle(Vector2(-half.x * 0.4 + i * half.x * 0.2, -half.y * 0.35 + absf(i - 2.0) * -1.5), 1.5, PEARL)
			draw_rect(Rect2(half.x - 3.0, 2.0, 9.0, 8.0), PURSE)
			draw_circle(Vector2(half.x + 1.5, 2.0), 2.0, Projectile.COIN_GOLD)
		"santa_hat":
			# A floppy red hat with white trim and a bobble, and a big white beard.
			var hat := PackedVector2Array([Vector2(-half.x * 0.6, -half.y + 2.0), Vector2(half.x * 0.6, -half.y + 2.0), Vector2(half.x * 0.7, -half.y - 12.0)])
			draw_colored_polygon(hat, SANTA_RED)
			draw_rect(Rect2(-half.x * 0.7, -half.y, half.x * 1.4, 4.0), SANTA_WHITE)
			draw_circle(Vector2(half.x * 0.7, -half.y - 12.0), 3.5, SANTA_WHITE)
			draw_colored_polygon(PackedVector2Array([Vector2(-half.x * 0.5, -half.y * 0.45), Vector2(half.x * 0.5, -half.y * 0.45), Vector2(0.0, half.y * 0.15)]), SANTA_WHITE)
			draw_rect(Rect2(-half.x, half.y * 0.2, half.x * 2.0, 4.0), SANTA_BELT)
			draw_rect(Rect2(-3.0, half.y * 0.2, 6.0, 4.0), Projectile.COIN_GOLD)
		"elf_hat":
			# A pointed green hat with a bell.
			draw_colored_polygon(PackedVector2Array([Vector2(-half.x * 0.8, -half.y + 2.0), Vector2(half.x * 0.8, -half.y + 2.0), Vector2(half.x * 1.2, -half.y - 9.0)]), ELF_HAT)
			draw_circle(Vector2(half.x * 1.2, -half.y - 9.0), 2.0, Projectile.COIN_GOLD)
			draw_rect(Rect2(-half.x * 0.8, -half.y + 1.0, half.x * 1.6, 2.0), SANTA_RED)
		# Fairway's End's marks, drawn in their own file.
		"caddie_bib", "golf_cap", "gopher_teeth", "pro_visor", "boater":
			GolfMarks.draw_mark(self, _def.mark, half)
	if _def.shield_half_angle > 0.0:
		var reach := maxf(half.x, half.y) + SHIELD_GAP
		var half_arc := deg_to_rad(_def.shield_half_angle)
		var color := SHIELD_FLASH if _flash_left > 0.0 else SHIELD_COLOR
		draw_arc(Vector2.ZERO, reach, _facing.angle() - half_arc, _facing.angle() + half_arc, 16, Color.BLACK, SHIELD_WIDTH + 2.0)
		draw_arc(Vector2.ZERO, reach, _facing.angle() - half_arc, _facing.angle() + half_arc, 16, color, SHIELD_WIDTH)
