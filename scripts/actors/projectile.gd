class_name Projectile
extends Node2D

const HIT_RADIUS := 12.0
const LIFETIME := 5.0
# Shots fly above the dark of Lights Out, so one is never unseen.
const SHOT_Z := 55
const DART_BARREL := Color("dff3ff")
const DART_PLUNGER := Color("7fb7d8")
const DART_NEEDLE := Color("f4f4f4")
# What a plain shot looks like: a sheet of paper, unless its look says otherwise.
const LOOK_PAPER := ""
# Head Office: a note of hold music, a black quaver.
const LOOK_NOTE := "note"
const NOTE_INK := Color("15131a")
const NOTE_GLOW := Color(1.0, 0.95, 0.75, 0.8)
# The Flashback Cinema: a popped kernel from a burst tub, and a critic's gold star.
const LOOK_KERNEL := "kernel"
const KERNEL := Color("fff4c0")
const KERNEL_HULL := Color("c9a24a")
const LOOK_STAR := "star"
const STAR_GOLD := Color("ffd24a")
# The Seance Hotline: a Poltergeist on Hold hurls the office. Each art (stapler.png, mug.png,
# fax_machine.png) is a 32x32 canvas to be shown at 0.75, so each placeholder fills the 24x24 its art
# will: the stapler about 20x16, the mug 15x16 and the fax machine 20x18.
const LOOK_STAPLER := "stapler"
const LOOK_MUG := "mug"
const LOOK_FAX := "fax"
const OBJECT_ART_SIZE := 24.0
const OBJECT_GLOW := Color(1.0, 0.95, 0.85, 0.4)
# Each look's art, res://art/props/<id>.png (32x32), and the size it is drawn at: the office at 0.75,
# a kernel at 0.5. A look without art keeps its drawing.
const LOOK_ART := {LOOK_KERNEL: ["kernel", 16.0], LOOK_STAPLER: ["stapler", OBJECT_ART_SIZE],
	LOOK_MUG: ["mug", OBJECT_ART_SIZE], LOOK_FAX: ["fax_machine", OBJECT_ART_SIZE]}
# A chrome arm over a dark base: a grey arm vanished on the hotline's violet carpet in the real window.
const STAPLER_DARK := Color("231929")
const STAPLER_GREY := Color("bdb8c8")
const STAPLER_SHINE := Color("f2f0f6")
const MUG := Color("e1ddb6")
const MUG_SHADE := Color("a8a27e")
const MUG_LOGO := Color("4a1775")
const COFFEE := Color("3a2416")
const FAX := Color("3a3741")
const FAX_TOP := Color("b29782")
const FAX_PAPER := Color("ecddbd")
const FAX_KEY := Color("f5f3d9")

# A sedative dart slows Grandpa by this much for this long when it lands. Zero means a plain shot.
var slow_fraction := 0.0
var slow_time := 0.0
var look := LOOK_PAPER
var _velocity := Vector2.ZERO
var _target: Node2D
var _damage := 1
var _age := 0.0


func setup(direction: Vector2, speed: float, target: Node2D, damage: int) -> void:
	_velocity = direction.normalized() * speed
	_target = target
	_damage = damage
	z_index = SHOT_Z


func make_dart(fraction: float, seconds: float) -> void:
	slow_fraction = fraction
	slow_time = seconds
	rotation = _velocity.angle()
	queue_redraw()


func is_dart() -> bool:
	return slow_fraction > 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME or not is_instance_valid(_target):
		queue_free()
		return
	var next := global_position + _velocity * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, next, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	global_position = next
	if global_position.distance_to(_target.global_position) <= HIT_RADIUS:
		var landed: bool = _target.take_hit(_damage, RunEffects.HURT_PROJECTILE)
		if landed and is_dart() and _target.has_method("slow"):
			_target.slow(slow_fraction, slow_time)
		queue_free()


func _draw() -> void:
	if is_dart():
		draw_rect(Rect2(-7, -2.5, 10, 5), DART_BARREL)
		draw_rect(Rect2(-7, -2.5, 10, 5), Color.BLACK, false, 1.0)
		draw_rect(Rect2(-10, -1.5, 3, 3), DART_PLUNGER)
		draw_line(Vector2(3, 0), Vector2(9, 0), DART_NEEDLE, 1.0)
		return
	if LOOK_ART.has(look):
		var art := PropArt.texture(LOOK_ART[look][0])
		if art != null:
			var size: float = LOOK_ART[look][1]
			# The office art is dark grey and black, so it flies on a faint pale glow, as the note does.
			if look != LOOK_KERNEL:
				draw_circle(Vector2.ZERO, size * 0.45, OBJECT_GLOW)
			draw_texture_rect(art, Rect2(-size / 2.0, -size / 2.0, size, size), false)
			return
	if look == LOOK_NOTE:
		# A pale glow behind, so a black note reads on dark carpet as well as pale.
		draw_circle(Vector2(0.0, 1.0), 6.0, NOTE_GLOW)
		draw_circle(Vector2(-1.0, 3.0), 3.0, NOTE_INK)
		draw_line(Vector2(1.5, 3.0), Vector2(1.5, -6.0), NOTE_INK, 1.5)
		draw_line(Vector2(1.5, -6.0), Vector2(5.0, -3.0), NOTE_INK, 1.5)
		return
	if look == LOOK_KERNEL:
		draw_circle(Vector2.ZERO, 4.5, Color.BLACK)
		draw_circle(Vector2(-1.0, -0.5), 3.0, KERNEL)
		draw_circle(Vector2(1.5, 0.5), 2.5, KERNEL)
		draw_circle(Vector2(0.5, 2.0), 1.2, KERNEL_HULL)
		return
	if look == LOOK_STAR:
		var star := PackedVector2Array()
		for i in 10:
			star.append(Vector2.from_angle(-PI / 2.0 + TAU * i / 10.0) * (6.5 if i % 2 == 0 else 2.8))
		draw_colored_polygon(star, STAR_GOLD)
		star.append(star[0])
		draw_polyline(star, Color.BLACK, 1.0)
		return
	if look == LOOK_STAPLER:
		# Side on: a dark base, the grey arm over it and the hinge at the back.
		draw_rect(Rect2(-10, 2, 20, 5), STAPLER_DARK)
		draw_colored_polygon(PackedVector2Array([Vector2(-10, 1), Vector2(9, -5), Vector2(10, -2), Vector2(-9, 3)]), STAPLER_GREY)
		draw_line(Vector2(-8, 0), Vector2(8, -5), STAPLER_SHINE, 1.0)
		draw_circle(Vector2(-9, 2), 2.5, STAPLER_DARK)
		draw_rect(Rect2(-10, -5, 20, 12), Color.BLACK, false, 1.0)
		return
	if look == LOOK_MUG:
		# A cream mug with a purple logo band, its handle out to the side and coffee at the top.
		draw_arc(Vector2(6, 0), 4.0, -PI / 2.0, PI / 2.0, 10, MUG_SHADE, 2.5)
		draw_rect(Rect2(-7, -7, 13, 15), MUG)
		draw_rect(Rect2(-7, -1, 13, 4), MUG_LOGO)
		draw_rect(Rect2(-7, -7, 13, 2), COFFEE)
		draw_rect(Rect2(-7, -7, 13, 15), Color.BLACK, false, 1.0)
		return
	if look == LOOK_FAX:
		# A dark machine with a tan top, a sheet of paper curling out and a row of pale keys.
		draw_rect(Rect2(-6, -10, 12, 6), FAX_PAPER)
		draw_rect(Rect2(-10, -5, 20, 13), FAX)
		draw_rect(Rect2(-10, -5, 20, 4), FAX_TOP)
		for i in 4:
			draw_rect(Rect2(-7 + i * 4, 2, 2, 2), FAX_KEY)
		draw_rect(Rect2(-10, -5, 20, 13), Color.BLACK, false, 1.0)
		return
	draw_rect(Rect2(-4, -5, 8, 10), Color("efe8d2"))
	draw_rect(Rect2(-4, -5, 8, 10), Color.BLACK, false, 1.0)
