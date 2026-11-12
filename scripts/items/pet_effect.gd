class_name PetEffect
extends ItemEffect

# What every pet's effect shares: it places the pet's body (Pet) by Harold in every room he enters, finds
# what the pet goes for, and lands its hits through the run's hooks as pet hits, scaled by the pet
# multiplier (RunState.pet_damage_mult). Each pet's own script says what it does. slot is set by
# RunEffects in pickup order.

@export var look := ""
@export var color := Color.WHITE
var slot := 0
var _pet: WeakRef


# Taken mid-room, the body stands by him at once; before there is a player and a room (tests, a resumed
# run's restore, which never calls this) it waits for the next room.
func on_gain(ctx: EffectContext) -> void:
	if ctx.has_player() and ctx.has_room():
		_place(ctx)


func on_room_enter(ctx: EffectContext, _room: Node) -> void:
	_place(ctx)


# Puts this pet's body (or bodies) by his feet. The one placement, for a room entered and for a pet taken.
func _place(ctx: EffectContext) -> void:
	_pet = null
	var body := Pet.make(look, color, slot, base_speed() * (1.0 + _speed_bonus(ctx)))
	body.follow = ctx.player if ctx.has_player() else null
	setup_pet(ctx, body)
	var placed := ctx.add_fx(body, ctx.feet() + Pet.slot_offset(slot))
	_pet = weakref(placed) if placed != null else null


# The body this room, or null (always null in tests, where the room frees it at once).
func pet() -> Pet:
	return _pet.get_ref() as Pet if _pet != null else null


# A pet that guards or circles sets its body up here.
func setup_pet(_ctx: EffectContext, _body: Pet) -> void:
	pass


func base_speed() -> float:
	return Pet.SPEED


func mult(ctx: EffectContext) -> float:
	var run := ctx.run()
	return run.pet_damage_mult() if run != null else 1.0


func nearest(ctx: EffectContext, reach: float, regular_only := false) -> Enemy:
	return nearest_where(ctx, reach, func(enemy: Enemy) -> bool: return not (regular_only and enemy.def.is_boss))


# The enemy nearest his feet within reach that wanted says yes to, or null.
func nearest_where(ctx: EffectContext, reach: float, wanted: Callable) -> Enemy:
	var best: Enemy = null
	var best_distance := reach
	for enemy in ctx.enemies_near(ctx.feet(), reach):
		if not bool(wanted.call(enemy)):
			continue
		var distance := enemy.global_position.distance_to(ctx.feet())
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best


# One pet hit of base damage, times the pet multiplier. Nothing while the full loop counts damage.
func strike(ctx: EffectContext, enemy: Enemy, base: float) -> bool:
	if enemy == null or ctx.counting_exact:
		return false
	var body := pet()
	if body != null:
		body.lunge_to(enemy.global_position)
	return ctx.hit_enemy(enemy, base * mult(ctx), RunEffects.PET)


func _speed_bonus(ctx: EffectContext) -> float:
	var run := ctx.run()
	return run.stats.pet_speed_bonus if run != null else 0.0
