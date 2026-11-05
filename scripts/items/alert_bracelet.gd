extends ItemEffect

# Medical Alert Bracelet: the moment he drops to his last pill an alarm stuns everything near him,
# once a room.

const REACH := 96.0
const STUN_TIME := 1.5
const POP := "BEEP BEEP!"
const COLOR := Color("e4524f")

var _last_pills := -1
var _used := false


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_used = false
	_last_pills = ctx.run().health.pills if ctx.run() != null else -1


func tick(ctx: EffectContext, _delta: float) -> void:
	var run := ctx.run()
	if run == null:
		return
	var pills := run.health.pills
	if pills == 1 and _last_pills > 1 and not _used:
		sound_alarm(ctx)
	_last_pills = pills


func sound_alarm(ctx: EffectContext) -> void:
	_used = true
	for enemy in ctx.enemies_near(ctx.feet(), REACH):
		ctx.stun(enemy, STUN_TIME)
	ctx.add_fx(ItemFx.make_shockwave(REACH, COLOR), ctx.feet())
	ctx.add_fx(ItemFx.make_pop(POP, COLOR), ctx.feet())
	ctx.play_sound("alarm")
