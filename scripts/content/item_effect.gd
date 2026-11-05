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
