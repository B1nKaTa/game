class_name RunEffects
extends RefCounted

# The run's item effects, in pickup order, then the effects of its combos in the order they formed.
# Game code calls these methods, never an ItemEffect directly. Each held item gets its own copy of its
# effect, so one run's counters never reach another's.

signal combo_formed(combo: ComboDef)

# Where one of his hits came from.
const SWING := "swing"
const CHARGE := "charge"
const COMBO_3 := "combo_3"
const BITE := "bite"
const THERMOS := "thermos"
const ITEM := "item"
# What a pickup was.
const PENSION := "pension"
const HEAL := "heal"
const SLIP := "slip"
const BOMB := "thermos"
# What hurt him.
const HURT_ENEMY := "enemy"
const HURT_FIRE := "fire"
const HURT_BLAST := "blast"
const HURT_PROJECTILE := "projectile"
const HURT_OWN_BLAST := "own_blast"
# What items tell each other through event(): a BINGO from the card or the dabber.
const EVENT_BINGO := "bingo"
# Item hits that set off item hits stop this deep, so two effects can never feed each other forever.
const MAX_HIT_DEPTH := 2

var ctx: EffectContext
var _run_ref: WeakRef
# Each entry is [item id, its ItemEffect copy].
var _entries: Array = []
var _combo_defs: Array[ComboDef] = []
var _combos: Array[ComboDef] = []
var _combo_effects: Array[ItemEffect] = []
var _hit_depth := 0
# The effect whose on_lethal said yes to the hit landing now.
var _saver: ItemEffect
var _damage_this_room := 0


func _init(run_state: RunState = null) -> void:
	_run_ref = weakref(run_state) if run_state != null else null
	ctx = EffectContext.new(run_state)


func _run() -> RunState:
	return _run_ref.get_ref() if _run_ref != null else null


# --- the held items and combos ---

func add(item: ItemDef) -> void:
	if item.effect != null:
		var copy: ItemEffect = item.effect.duplicate()
		_entries.append([item.id, copy])
		copy.on_gain(ctx)
	_form_combos()


func clear() -> void:
	_entries.clear()
	_combos.clear()
	_combo_effects.clear()


# The effect copy this run holds for an item, or null.
func effect_of(item_id: String) -> ItemEffect:
	for entry in _entries:
		if entry[0] == item_id:
			return entry[1]
	return null


# The combos this run can form. Progress.make_run gives it every shipped one.
func set_combos(defs: Array[ComboDef]) -> void:
	_combo_defs = defs
	_form_combos()


func active_combos() -> Array[ComboDef]:
	return _combos


func has_combo(id: String) -> bool:
	for combo in _combos:
		if combo.id == id:
			return true
	return false


func combo_names() -> PackedStringArray:
	var names := PackedStringArray()
	for combo in _combos:
		names.append(combo.display_name)
	return names


func _form_combos() -> void:
	var run := _run()
	if run == null:
		return
	for combo in _combo_defs:
		if _combos.has(combo) or not run.has_item(combo.item_a) or not run.has_item(combo.item_b):
			continue
		_combos.append(combo)
		if combo.effect != null:
			var copy: ItemEffect = combo.effect.duplicate()
			_combo_effects.append(copy)
			copy.on_gain(ctx)
		combo_formed.emit(combo)


func _all() -> Array[ItemEffect]:
	var list: Array[ItemEffect] = []
	for entry in _entries:
		list.append(entry[1])
	list.append_array(_combo_effects)
	return list


# --- his hits ---

# Lands one of his hits through the hooks. With to_attacker a Vector2 it is a strike a shield can stop
# (Enemy.take_strike); otherwise it is plain damage. Returns whether it landed.
func land(enemy: Enemy, amount: float, source: String, push := Vector2.ZERO, to_attacker: Variant = null) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.is_dead():
		return false
	var hooks := _hit_depth < MAX_HIT_DEPTH
	_hit_depth += 1
	if hooks:
		amount = hit_damage(enemy, amount, source)
	var run := _run()
	enemy.harmless_death = run != null and run.stats.clean_kills
	var landed := true
	if to_attacker is Vector2:
		landed = enemy.take_strike(amount, push, to_attacker)
	else:
		enemy.take_damage(amount, push)
	if not enemy.is_dead():
		enemy.harmless_death = false
	if landed and hooks:
		hit(enemy, amount, source)
		if enemy.is_dead():
			kill(enemy, source)
	_hit_depth -= 1
	return landed


func hit_damage(enemy: Enemy, amount: float, source: String) -> float:
	for effect in _all():
		amount = effect.hit_damage(ctx, enemy, amount, source)
	return amount


func hit(enemy: Enemy, amount: float, source: String) -> void:
	for effect in _all():
		effect.on_hit(ctx, enemy, amount, source)


func kill(enemy: Enemy, source: String) -> void:
	for effect in _all():
		effect.on_kill(ctx, enemy, source)


# --- moments ---

func floor_start() -> void:
	for effect in _all():
		effect.on_floor_start(ctx)


func room_enter(room: Node) -> void:
	_damage_this_room = 0
	for effect in _all():
		effect.on_room_enter(ctx, room)


func room_leave(room: Node) -> void:
	for effect in _all():
		effect.on_room_leave(ctx, room)


# What his walk and his swings are sped up by. The full loop times both, so there they stay as they are.
func move_pace() -> float:
	var pace := 1.0
	if ctx.counting_exact:
		return pace
	for effect in _all():
		pace *= effect.move_pace(ctx)
	return pace


func swing_pace() -> float:
	var pace := 1.0
	if ctx.counting_exact:
		return pace
	for effect in _all():
		pace *= effect.swing_pace(ctx)
	return pace


func room_clear(room: Node) -> void:
	for effect in _all():
		effect.on_room_clear(ctx, room, _damage_this_room)


func damage_this_room() -> int:
	return _damage_this_room


func dodge(direction: Vector2) -> void:
	for effect in _all():
		effect.on_dodge(ctx, direction)


func dodge_end() -> void:
	for effect in _all():
		effect.on_dodge_end(ctx)


func close_call() -> void:
	for effect in _all():
		effect.on_close_call(ctx)


# Each effect may lower what the last one left. The result is what he loses, never below zero.
func hurt(pills: int, source: String) -> int:
	if ctx.counting_pills:
		_damage_this_room += pills
		return pills
	for effect in _all():
		pills = maxi(effect.on_hurt(ctx, pills, source), 0)
	_damage_this_room += pills
	return pills


# The first effect that saves him is the only one asked, and the only one told once the hit lands.
func lethal() -> bool:
	_saver = null
	for effect in _all():
		if effect.on_lethal(ctx):
			_saver = effect
			return true
	return false


# The hit lethal() saved him from has landed.
func saved() -> void:
	var saver := _saver
	_saver = null
	if saver != null:
		saver.on_saved(ctx)


# Whether the Slip about to be handed over stays in his pocket. Never while the full loop counts.
func keeps_slip() -> bool:
	if ctx.counting_exact:
		return false
	for effect in _all():
		if effect.keeps_slip(ctx):
			return true
	return false


func slip_spent(kept: bool) -> void:
	for effect in _all():
		effect.on_slip_spent(ctx, kept)


func throw() -> void:
	for effect in _all():
		effect.on_throw(ctx)


func bite(enemy: Enemy) -> void:
	for effect in _all():
		effect.on_bite(ctx, enemy)


func charge_release(full: bool) -> void:
	for effect in _all():
		effect.on_charge_release(ctx, full)


func swing(attack: SwingAttack) -> void:
	for effect in _all():
		effect.on_swing(ctx, attack)


func swing_end(attack: SwingAttack) -> void:
	for effect in _all():
		effect.on_swing_end(ctx, attack)


func glue_tick(enemy: Enemy) -> void:
	for effect in _all():
		effect.on_glue_tick(ctx, enemy)


func event(event_name: String) -> void:
	for effect in _all():
		effect.on_event(ctx, event_name)


func bomb(at: Vector2) -> void:
	for effect in _all():
		effect.on_bomb(ctx, at)


func accepts_pickup(kind: String) -> bool:
	for effect in _all():
		if effect.accepts_pickup(ctx, kind):
			return true
	return false


func pickup(kind: String, amount: int) -> int:
	if kind == HEAL and ctx.counting_pills:
		return amount
	for effect in _all():
		amount = effect.on_pickup(ctx, kind, amount)
	return amount


func shop_open(stock: Array[Dictionary]) -> void:
	for effect in _all():
		effect.on_shop_open(ctx, stock)


func tick(delta: float) -> void:
	for entry in _entries:
		entry[1].tick(ctx, delta)
	for effect in _combo_effects:
		effect.tick(ctx, delta)
