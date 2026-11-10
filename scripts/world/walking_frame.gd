class_name WalkingFrame
extends Node2D

# The Walking Frame planted AHEAD of him, across his aim, for LIFE seconds: a solid body (collision layer 1)
# that stops enemies, and a shot guard that never runs out. Two uprights and a top rail, never crossing.

const AHEAD := 24.0
const SIZE := Vector2(40, 10)
const LIFE := 6.0
const METAL := Color("c9ced8")
const RUBBER := Color("3a3741")

var _age := 0.0

# Set by make; the full loop counts every pill a shot costs, so then the frame stops no shot.
var ctx: EffectContext


static func make(feet: Vector2, aim: Vector2, context: EffectContext = null) -> WalkingFrame:
	var frame := WalkingFrame.new()
	frame.ctx = context
	var way: Vector2 = aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
	frame.position = feet + way * AHEAD
	frame.rotation = way.angle() + PI / 2.0
	return frame


func _init() -> void:
	add_to_group(ShotGuards.GROUP)
	add_to_group(ItemFx.GROUP)
	z_index = ItemFx.Z
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func blocks_shot(at: Vector2) -> bool:
	if ctx != null and ctx.counting_pills:
		return false
	return Rect2(-SIZE / 2.0, SIZE).has_point(to_local(at))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


# A top rail with an upright at each end, each meeting the rail at its end (an open bracket), and a rubber
# foot under each upright. No stroke crosses another.
func _draw() -> void:
	var half := SIZE / 2.0
	draw_line(Vector2(-half.x, -half.y), Vector2(half.x, -half.y), METAL, 2.0)
	draw_line(Vector2(-half.x, -half.y), Vector2(-half.x, half.y), METAL, 2.0)
	draw_line(Vector2(half.x, -half.y), Vector2(half.x, half.y), METAL, 2.0)
	draw_circle(Vector2(-half.x, half.y), 1.5, RUBBER)
	draw_circle(Vector2(half.x, half.y), 1.5, RUBBER)
