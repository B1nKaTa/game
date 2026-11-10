extends PetEffect

# Polly the Parrot: DELAY after a cane swing lands, she repeats it: each enemy the swing hit, if still alive,
# takes SHARE of that hit as a pet hit. Only cane swings are copied. Her echo never kills a boss: it stops
# at one health, so the last blow is always his.

const DELAY := 1.0
const SHARE := 0.5
const SWINGS := [RunEffects.SWING, RunEffects.CHARGE, RunEffects.COMBO_3]
# This swing's hits: [WeakRef to the enemy, the damage].
var _hits: Array = []
# Each echo: [seconds left, its hits].
var _echoes: Array = []


func on_swing(_ctx: EffectContext, _swing: SwingAttack) -> void:
	_hits = []


func on_hit(_ctx: EffectContext, enemy: Enemy, amount: float, source: String) -> void:
	if SWINGS.has(source):
		_hits.append([weakref(enemy), amount])


func on_swing_end(_ctx: EffectContext, _swing: SwingAttack) -> void:
	if not _hits.is_empty():
		_echoes.append([DELAY, _hits])
	_hits = []


func on_room_enter(ctx: EffectContext, room: Node) -> void:
	super(ctx, room)
	_hits = []
	_echoes = []


func tick(ctx: EffectContext, delta: float) -> void:
	var due: Array = []
	for echo in _echoes:
		echo[0] -= delta
		if echo[0] <= 0.0:
			due.append(echo)
	for echo in due:
		_echoes.erase(echo)
		for hit in echo[1]:
			var enemy := hit[0].get_ref() as Enemy
			if enemy != null and not enemy.is_dead():
				var base: float = float(hit[1]) * SHARE
				if enemy.def.is_boss:
					base = minf(base, (enemy.hp - 1.0) / maxf(mult(ctx), 0.01))
				if base > 0.0:
					strike(ctx, enemy, base)
