extends ItemEffect

# Bingo Dabber: his hits dab a mark on an enemy, and the fifth mark bursts for a big hit with a BINGO.

const MARKS := 5
const BURST := 30.0
const POP := "BINGO!"
# Only his own blows dab: the cane and the bite, never an item's hit.
const SOURCES := [RunEffects.SWING, RunEffects.CHARGE, RunEffects.COMBO_3, RunEffects.BITE]

# Instance id -> marks so far, and -> a WeakRef to the dots it wears.
var _marks := {}
var _dabs := {}


func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	_marks.clear()
	_dabs.clear()


func marks_on(enemy: Enemy) -> int:
	return int(_marks.get(enemy.get_instance_id(), 0))


func on_hit(ctx: EffectContext, enemy: Enemy, _amount: float, source: String) -> void:
	if not SOURCES.has(source) or enemy.is_dead():
		return
	var key := enemy.get_instance_id()
	var count := marks_on(enemy) + 1
	if count < MARKS:
		_marks[key] = count
		_show(ctx, enemy, count)
		return
	_marks.erase(key)
	_show(ctx, enemy, 0)
	var run := ctx.run()
	ctx.add_fx(ItemFx.make_pop(POP, ItemFx.DAB_COLOR), enemy.global_position)
	ctx.play_sound("bingo")
	ctx.hit_enemy(enemy, BURST * (run.damage_mult() if run != null else 1.0))
	ctx.event(RunEffects.EVENT_BINGO)


func _show(ctx: EffectContext, enemy: Enemy, count: int) -> void:
	var key := enemy.get_instance_id()
	var ref: WeakRef = _dabs.get(key)
	var dabs = ref.get_ref() if ref != null else null
	if dabs != null:
		if count <= 0:
			dabs.queue_free()
			_dabs.erase(key)
		else:
			dabs.count = count
		return
	if count <= 0:
		return
	var placed := ctx.add_fx(ItemFx.make_dabs(enemy, count), enemy.global_position)
	if placed != null:
		_dabs[key] = weakref(placed)
