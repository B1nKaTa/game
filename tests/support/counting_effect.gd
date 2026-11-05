extends ItemEffect

# A test effect that counts every hook and notes each call, tagged, through ctx.notice, so a test can
# read the order effects were called in.

@export var tag := ""
@export var block_to := -1
@export var saves := false
@export var bonus := 0.0
var counts := {}


func _note(hook: String, ctx: EffectContext) -> void:
	counts[hook] = int(counts.get(hook, 0)) + 1
	ctx.notice("%s:%s" % [tag, hook])


func on_gain(ctx: EffectContext) -> void:
	_note("gain", ctx)


func on_floor_start(ctx: EffectContext) -> void:
	_note("floor_start", ctx)


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_note("room_enter", ctx)


func on_room_clear(ctx: EffectContext, _room: Node, damage_taken_here: int) -> void:
	_note("room_clear", ctx)
	counts["damage_seen"] = damage_taken_here


func hit_damage(ctx: EffectContext, _enemy: Enemy, amount: float, _source: String) -> float:
	_note("hit_damage", ctx)
	return amount + bonus


func on_hit(ctx: EffectContext, _enemy: Enemy, _amount: float, source: String) -> void:
	_note("hit", ctx)
	counts["last_source"] = source


func on_kill(ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	_note("kill", ctx)


func on_dodge(ctx: EffectContext, _direction: Vector2) -> void:
	_note("dodge", ctx)


func on_dodge_end(ctx: EffectContext) -> void:
	_note("dodge_end", ctx)


func on_close_call(ctx: EffectContext) -> void:
	_note("close_call", ctx)


func on_hurt(ctx: EffectContext, pills: int, _source: String) -> int:
	_note("hurt", ctx)
	return block_to if block_to >= 0 else pills


func on_lethal(ctx: EffectContext) -> bool:
	_note("lethal", ctx)
	return saves


func on_throw(ctx: EffectContext) -> void:
	_note("throw", ctx)


func on_bite(ctx: EffectContext, _enemy: Enemy) -> void:
	_note("bite", ctx)


func on_charge_release(ctx: EffectContext, _full: bool) -> void:
	_note("charge_release", ctx)


func on_bomb(ctx: EffectContext, _at: Vector2) -> void:
	_note("bomb", ctx)


func accepts_pickup(ctx: EffectContext, _kind: String) -> bool:
	_note("accepts_pickup", ctx)
	return false


func on_pickup(ctx: EffectContext, _kind: String, amount: int) -> int:
	_note("pickup", ctx)
	return amount * 2


func on_shop_open(ctx: EffectContext, _stock: Array[Dictionary]) -> void:
	_note("shop_open", ctx)


func tick(ctx: EffectContext, _delta: float) -> void:
	_note("tick", ctx)


func on_swing(ctx: EffectContext, _swing: SwingAttack) -> void:
	_note("swing", ctx)


func on_swing_end(ctx: EffectContext, _swing: SwingAttack) -> void:
	_note("swing_end", ctx)


func on_glue_tick(ctx: EffectContext, _enemy: Enemy) -> void:
	_note("glue_tick", ctx)


func on_event(ctx: EffectContext, _event: String) -> void:
	_note("event", ctx)
