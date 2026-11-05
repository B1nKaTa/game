extends ItemEffect

# Shark Tooth Implant: every bite starts a bleed of HITS small hits, one every EVERY seconds. Bleeds
# stack: each bite adds its own. They end with the room.

const HITS := 3
const EVERY := 1.0
const DAMAGE := 5.0

# Each bleed: [WeakRef to the enemy, hits left, seconds to the next].
var _bleeds: Array = []
# Instance id -> WeakRef to the drops it shows.
var _looks := {}


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_bleeds.clear()
	_looks.clear()


func bleeds_on(enemy: Enemy) -> int:
	var count := 0
	for bleed in _bleeds:
		if bleed[0].get_ref() == enemy:
			count += 1
	return count


func on_bite(ctx: EffectContext, enemy: Enemy) -> void:
	if enemy.is_dead():
		return
	_bleeds.append([weakref(enemy), HITS, EVERY])
	var key := enemy.get_instance_id()
	var ref: WeakRef = _looks.get(key)
	var look = ref.get_ref() if ref != null else null
	if look != null:
		look.keep_for(HITS * EVERY + 0.1)
		return
	var placed := ctx.add_fx(ItemFx.make_bleed(enemy, HITS * EVERY + 0.1), enemy.global_position)
	if placed != null:
		_looks[key] = weakref(placed)


func tick(ctx: EffectContext, delta: float) -> void:
	if _bleeds.is_empty():
		return
	var run := ctx.run()
	var damage := DAMAGE * (run.bite_damage_mult() if run != null else 1.0)
	var going: Array = []
	for bleed in _bleeds:
		var enemy := bleed[0].get_ref() as Enemy
		if enemy == null or enemy.is_dead():
			continue
		bleed[2] -= delta
		if bleed[2] <= 0.0:
			bleed[2] += EVERY
			bleed[1] -= 1
			ctx.hit_enemy(enemy, damage)
			ctx.add_fx(ItemFx.make_sparks(ItemFx.BLOOD_COLOR, 10.0), enemy.global_position)
		if bleed[1] > 0 and not enemy.is_dead():
			going.append(bleed)
	_bleeds = going
