class_name ItemEffect
extends Resource

# What an item does at moments of play, on top of its stats. Every hook is empty here, and an item's own
# script overrides only those it needs. RunEffects calls them on every held item, in pickup order, and
# gives each run its own copy of the effect, so plain member variables are safe for counters.
#
# Each effect is written for one copy of its item. Reach the game only through ctx (EffectContext),
# whose player, room and HUD may all be null in tests, so check them before use.


# Once, the moment the item is taken.
func on_gain(_ctx: EffectContext) -> void:
	pass


# A floor or a landing is entered.
func on_floor_start(_ctx: EffectContext) -> void:
	pass


# Grandpa enters a room, the first time or again.
func on_room_enter(_ctx: EffectContext, _room: Node) -> void:
	pass


# Grandpa is about to leave this room for another (Moving Boxes). ctx.room is still the room he leaves.
func on_room_leave(_ctx: EffectContext, _room: Node) -> void:
	pass


# What his walking speed is multiplied by at this moment (Early Bird Special). 1.0 for no change.
func move_pace(_ctx: EffectContext) -> float:
	return 1.0


# What his swing pace is multiplied by at this moment: above 1 the combo swings come quicker (Early Bird
# Special, Dentures in a Glass). 1.0 for no change.
func swing_pace(_ctx: EffectContext) -> float:
	return 1.0


# A fight room's last enemy falls. damage_taken_here counts the pills he lost since he walked in.
func on_room_clear(_ctx: EffectContext, _room: Node, _damage_taken_here: int) -> void:
	pass


# Before one of his hits lands: return what it should deal. source is one of RunEffects' hit sources.
func hit_damage(_ctx: EffectContext, _enemy: Enemy, amount: float, _source: String) -> float:
	return amount


# One of his hits has landed.
func on_hit(_ctx: EffectContext, _enemy: Enemy, _amount: float, _source: String) -> void:
	pass


# An enemy has died to one of his hits.
func on_kill(_ctx: EffectContext, _enemy: Enemy, _source: String) -> void:
	pass


func on_dodge(_ctx: EffectContext, _direction: Vector2) -> void:
	pass


func on_dodge_end(_ctx: EffectContext) -> void:
	pass


# Something that would have hurt him met him mid-dodge. At most once per dodge.
func on_close_call(_ctx: EffectContext) -> void:
	pass


# He is about to lose pills. Return how many he loses: fewer blocks some, and 0 shrugs the hit off.
func on_hurt(_ctx: EffectContext, pills: int, _source: String) -> int:
	return pills


# A hit would finish him and no Life Jacket is left. Return true and he is left on one pill.
func on_lethal(_ctx: EffectContext) -> bool:
	return false


# The hit that this effect's on_lethal saved him from has landed, leaving him on one pill. Only the
# effect that saved him hears it, so it can finish its rescue (Eternal Warranty).
func on_saved(_ctx: EffectContext) -> void:
	pass


# A Slip is about to be handed over. Return true and it stays in his pocket (Forged Signature).
func keeps_slip(_ctx: EffectContext) -> bool:
	return false


# A Slip has been handed over to open something. kept says whether it stayed in his pocket.
func on_slip_spent(_ctx: EffectContext, _kept: bool) -> void:
	pass


# The dentures leave his mouth.
func on_throw(_ctx: EffectContext) -> void:
	pass


# The dentures bite an enemy, after the bite's on_hit.
func on_bite(_ctx: EffectContext, _enemy: Enemy) -> void:
	pass


# A fully charged swing is let go.
func on_charge_release(_ctx: EffectContext, _full: bool) -> void:
	pass


# A swing of the cane starts, before it hits anything. Its damage, push, reach, angle, duration,
# both_ways and style may be changed in place; whatever is changed is also what Player draws.
func on_swing(_ctx: EffectContext, _swing: SwingAttack) -> void:
	pass


# A swing has finished. swing.landed_count() says how many it landed on.
func on_swing_end(_ctx: EffectContext, _swing: SwingAttack) -> void:
	pass


# The dentures have stayed glued to an enemy for one more whole second (Denture Glue Gun).
func on_glue_tick(_ctx: EffectContext, _enemy: Enemy) -> void:
	pass


# Something an item made happen that other items listen for, such as RunEffects.EVENT_BINGO.
func on_event(_ctx: EffectContext, _event: String) -> void:
	pass


# One of his Thermoses goes off at this spot.
func on_bomb(_ctx: EffectContext, _at: Vector2) -> void:
	pass


# Whether a pickup he would otherwise be refused may be taken, as a heal at full health.
func accepts_pickup(_ctx: EffectContext, _kind: String) -> bool:
	return false


# Pension, a heal, a Slip or a Thermos is collected. Return the amount it should give.
func on_pickup(_ctx: EffectContext, _kind: String, amount: int) -> int:
	return amount


# A shop's stock has been rolled. Entries are ShopRules dictionaries, and may be changed in place.
func on_shop_open(_ctx: EffectContext, _stock: Array[Dictionary]) -> void:
	pass


# Every physics frame while he plays. Use it sparingly, for timers.
func tick(_ctx: EffectContext, _delta: float) -> void:
	pass


# --- the new item list ---

# Whether an active may be used now (Harmonica waits for a missing pill). Only an active's effect is asked.
func can_use(_ctx: EffectContext) -> bool:
	return true


# The active is used. Return true when it did something, which spends its charge; false keeps it.
func use(_ctx: EffectContext) -> bool:
	return false


# What pets' hits are multiplied by at this moment (Dinner Bell, Tin of Pet Food). 1.0 for no change.
func pet_damage_scale(_ctx: EffectContext) -> float:
	return 1.0


# One of his Thermos blasts landed on count enemies (Tea Break).
func on_blast_hits(_ctx: EffectContext, _at: Vector2, _count: int) -> void:
	pass


# A room rule has just been broken. Return true to let it off with a warning: no Auditor (Fine Print).
func excuses_rule_break(_ctx: EffectContext) -> bool:
	return false


# Whether the Auditor a broken rule sends fights for Harold instead (Clipboard of Your Own).
func sides_with_you(_ctx: EffectContext) -> bool:
	return false


# The Auditor has walked into the room (Repeat Offender, Brown Envelope).
func on_auditor(_ctx: EffectContext, _auditor: Enemy) -> void:
	pass


# A potion's lasting part is dropped once this is true.
func is_spent() -> bool:
	return false


# A potion's lasting part, the moment it is drunk.
func on_drink(_ctx: EffectContext) -> void:
	pass


# --- a resumed run ---

# What of this copy's run a checkpoint must keep, as plain values (a once-a-run flag, a per-floor flag,
# a counter, a recharge). Per-room state needs nothing, since a resumed run walks into its room again.
func save_state() -> Dictionary:
	return {}


# Puts back what save_state kept, on a resumed run's fresh copy, which never hears on_gain again. Called
# on every held effect when a run is resumed, with {} when nothing was kept.
func load_state(_state: Dictionary) -> void:
	pass


# save_state's usual body: these members by name.
func state_of(names: Array) -> Dictionary:
	var state := {}
	for name: String in names:
		state[name] = get(name)
	return state


# load_state's usual body: each named member found in state, read as the type it already has, since a
# JSON file gives every number back as a float.
func load_members(state: Dictionary, names: Array) -> void:
	for name: String in names:
		if not state.has(name):
			continue
		var value: Variant = state[name]
		match typeof(get(name)):
			TYPE_BOOL:
				set(name, bool(value))
			TYPE_INT:
				set(name, int(value))
			TYPE_FLOAT:
				set(name, float(value))
