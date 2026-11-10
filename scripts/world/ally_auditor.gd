class_name AllyAuditor
extends Node2D

# Clipboard of Your Own: the Auditor on Harold's side for the rest of a room. He walks to the enemy nearest
# him and swings his clipboard at it every SWING_EVERY for DAMAGE, an ally hit. He cannot be hurt and is
# no enemy, so the room clears without him; it frees him then (RoomView), and leaving the room clears him.
# Drawn in code, a grey suit with a clipboard, until art exists.

const SPEED := 90.0
const REACH := 36.0
const SWING_EVERY := 1.2
const DAMAGE := 12.0
const PUSH := 80.0
const SUIT := Color("4a4f5c")
const SKIN := Color("e0b48c")
const CLIPBOARD := Color("b48a5a")
const PAPER := Color("efe6cf")
const LABEL_TIME := 1.5

var ctx: EffectContext
var _cooldown := 0.0
var _age := 0.0


static func make(context: EffectContext) -> AllyAuditor:
	var ally := AllyAuditor.new()
	ally.ctx = context
	return ally


static func pick_target(from: Vector2, enemies: Array[Enemy]) -> Enemy:
	var best: Enemy = null
	for enemy in enemies:
		if best == null or enemy.global_position.distance_to(from) < best.global_position.distance_to(from):
			best = enemy
	return best


func _init() -> void:
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z


# One step of his fight: walk, or swing once his clipboard is ready.
func step(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if ctx == null:
		return
	var target := pick_target(global_position, ctx.enemies())
	if target == null:
		return
	if global_position.distance_to(target.global_position) > REACH:
		global_position = Pet.step_toward(global_position, target.global_position, SPEED, delta)
	elif _cooldown <= 0.0 and not ctx.counting_exact:
		_cooldown = SWING_EVERY
		ctx.hit_enemy(target, DAMAGE, RunEffects.ALLY, global_position.direction_to(target.global_position) * PUSH)


func _process(delta: float) -> void:
	_age += delta
	step(delta)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-6, -8, 12, 16), SUIT)
	draw_circle(Vector2(0, -12), 4.0, SKIN)
	draw_rect(Rect2(5, -4, 7, 9), CLIPBOARD)
	draw_rect(Rect2(6, -2, 5, 6), PAPER)
	if _age < LABEL_TIME:
		Npc._draw_centered(self, tr("ON YOUR SIDE"), Vector2(0, -22), Color("7fe0a0"))
