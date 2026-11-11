extends ItemEffect

# Bureaucrat's Stamp: once every RECHARGE seconds his next hit "files" the enemy it lands on. A filed
# enemy leaves for good, with no last act (no death blast, no split), and its room counts it as fallen
# as any kill, paying what that enemy pays and nothing more. A boss (or the Training Yard's dummy) is
# never filed: it loses BOSS_SHARE of its health instead, and never past the line into its next phase,
# so no phase is skipped.
# Item hits never set it off, and the full loop counts enemies and damage exactly, so there it waits.

const RECHARGE := 30.0
const BOSS_SHARE := 0.1
# Every boss changes phase at half health.
const PHASE_LINE := 0.5
const COLOR := Color("e0262f")
const FILED := "FILED"
const INKED := "STAMP INKED"

var ready := true
var left := 0.0


func recharge_time(_ctx: EffectContext) -> float:
	return RECHARGE


func tick(ctx: EffectContext, delta: float) -> void:
	if ready:
		return
	left -= delta
	if left <= 0.0:
		ready = true
		left = 0.0
		ctx.add_fx(ItemFx.make_pop(INKED, COLOR), ctx.feet())
		ctx.play_sound("charge_ready")


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if not ready or source == RunEffects.ITEM or ctx.counting_exact or enemy.is_dead() or enemy.def == null:
		return
	ready = false
	left = recharge_time(ctx)
	var at := enemy.global_position
	if is_never_filed(enemy):
		var chunk := boss_chunk(enemy.hp, enemy.max_hp())
		enemy.take_damage(chunk, Vector2.ZERO)
		ctx.add_fx(ItemFx.make_stamp("%s -%d%%" % [FILED, roundi(BOSS_SHARE * 100.0)]), at)
		ctx.play_sound("form_filed")
		var run := ctx.run()
		if enemy.is_dead() and run != null:
			run.effects.kill(enemy, RunEffects.ITEM)
		return
	enemy.dismiss()
	ctx.add_fx(ItemFx.make_stamp(FILED), at)
	ctx.play_sound("form_filed")


# A boss, or something that can never fall, such as the Training Yard's dummy.
static func is_never_filed(enemy: Enemy) -> bool:
	return enemy.def.is_boss or enemy.def.behavior_script == DummyBehavior


# What the stamp takes off a boss with so much health left: BOSS_SHARE of its whole health, but never
# past half health while it is above it, so it reaches its second phase and never skips it.
static func boss_chunk(hp: float, max_hp: float) -> float:
	var chunk := max_hp * BOSS_SHARE
	var line := max_hp * PHASE_LINE
	if hp > line:
		chunk = minf(chunk, hp - line)
	return maxf(chunk, 0.0)


# The stamp's recharge.
func save_state() -> Dictionary:
	return state_of(["ready", "left"])


func load_state(state: Dictionary) -> void:
	load_members(state, ["ready", "left"])
