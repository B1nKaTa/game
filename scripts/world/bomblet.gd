class_name Bomblet
extends Node2D

# Second Brew's little bombs: COUNT fly out SPREAD px from a blast, evenly round it, and each bursts
# DELAY later for SHARE of the Thermos's damage at RADIUS. They hurt enemies only (no props, walls,
# chests or Harold), make no bomblets, and are no Thermos to the other items.

const COUNT := 3
const SPREAD := 40.0
const DELAY := 0.35
const RADIUS := 26.0
const SHARE := 0.5
const PUSH := 80.0
const COLOR := Color("ffb23a")

var ctx: EffectContext
var damage := 0.0
var _left := DELAY
var _burst := false


static func spots(at: Vector2, first_angle: float) -> Array[Vector2]:
	var list: Array[Vector2] = []
	for i in COUNT:
		list.append(at + Vector2.from_angle(first_angle + TAU * i / COUNT) * SPREAD)
	return list


# Hits every enemy within radius of at, as Thermos hits. Returns how many it hit.
static func burst(context: EffectContext, at: Vector2, amount: float, radius := RADIUS) -> int:
	var hit := 0
	for enemy in context.enemies_near(at, radius):
		if context.hit_enemy(enemy, amount, RunEffects.THERMOS, at.direction_to(enemy.global_position) * PUSH):
			hit += 1
	return hit


static func make(context: EffectContext, at: Vector2, amount: float) -> Bomblet:
	var bomblet := Bomblet.new()
	bomblet.ctx = context
	bomblet.damage = amount
	bomblet.position = at
	return bomblet


func _init() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


func _process(delta: float) -> void:
	if _burst:
		return
	_left -= delta
	queue_redraw()
	if _left > 0.0:
		return
	_burst = true
	# The full loop counts exact damage, so a bomblet then bursts for show only.
	if ctx != null and not ctx.counting_exact:
		burst(ctx, global_position, damage)
		ctx.add_fx(ItemFx.make_blast(RADIUS), global_position)
		ctx.play_sound("small_blast")
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 3.0, COLOR)
	draw_arc(Vector2.ZERO, 3.0, 0.0, TAU, 10, Color.BLACK, 1.0)
