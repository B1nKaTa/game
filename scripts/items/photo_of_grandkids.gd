extends ItemEffect

# Photo of the Grandkids: on his last pill, every hit of his deals MULT times as much, with an "x2" over
# what it lands on now and then. The full loop measures damage exactly, so there it hits as usual.

const MULT := 2.0
const COLOR := Color("ff4f8b")
const TEXT := "x2"
# The "x2" shows at most this often, so a sweep through a crowd is not a cloud of words.
const POP_EVERY := 0.35

var _time := 0.0
var _next_pop := 0.0


func tick(_ctx: EffectContext, delta: float) -> void:
	_time += delta


static func on_last_pill(ctx: EffectContext) -> bool:
	var run := ctx.run()
	return run != null and run.health.pills == 1 and not run.health.is_dead()


func hit_damage(ctx: EffectContext, enemy: Enemy, amount: float, source: String) -> float:
	if ctx.counting_exact or not RunEffects.is_his_hit(source) or not on_last_pill(ctx):
		return amount
	if _time >= _next_pop:
		_next_pop = _time + POP_EVERY
		ctx.add_fx(ItemFx.make_pop(TEXT, COLOR), enemy.global_position)
	return amount * MULT
