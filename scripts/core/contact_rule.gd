class_name ContactRule
extends RefCounted

# Walking into an enemy's body costs Grandpa a pill, and a small shove carries his feet back out of it.
# Bodies never block him (enemies stay off his collision mask), so he can never be boxed in, and a dodge
# passes through freely. A touch tests what is drawn: the enemy's whole body (Enemy.body_rect, its
# body_size) against his feet box, where every enemy hit on him lands. The hit after it keeps one touch
# from costing more than one pill.
#
# A touch costs nothing from:
# - a ghost (the Soot Ghosts, the Debt Collector Ghost, the Weeping Mourners), unless its def sets
#   ghost_contact;
# - a def whose contact_damage is 0: the Training Yard's dummy, and the Mall Walkers, whose line hurts on
#   touch by its own clock;
# - an enemy that is dead, dying, dismissed or queued to go;
# - one still waiting out the room's start, which is also how a mimic that has just woken out of its chest
#   gets its moment, since it waits as a room's enemies do;
# - one underground or hidden in smoke (submerged);
# - an ambusher still asleep: the Sunbather in his chair and Lost Luggage lying on the carpet.
# NPCs, summon marks and a mimic still passing for a chest are no enemies at all, so they never touch.

# The shove out of a body: about 30 px, enough to clear any body's edge from its middle.
const SHOVE := 180.0
const SHOVE_TIME := 0.16


# Whether an enemy is a ghost. Mothball Pockets keep the same ones off. Bosses never count as ghosts.
static func is_ghost(enemy_def: EnemyDef) -> bool:
	if enemy_def == null or enemy_def.is_boss:
		return false
	return enemy_def.id.contains("ghost") or enemy_def.id.contains("mourner")


# What touching this kind of enemy costs, before anything about its moment.
static func damage_of(enemy_def: EnemyDef) -> int:
	if enemy_def == null:
		return 0
	if is_ghost(enemy_def) and not enemy_def.ghost_contact:
		return 0
	return maxi(enemy_def.contact_damage, 0)


# What touching it costs right now. gone: dead, dying, dismissed or queued to go. waiting: still holding
# still at the room's start. hidden: underground or in smoke. asleep: an ambusher not yet woken.
static func damage(enemy_def: EnemyDef, gone: bool, waiting: bool, hidden: bool, asleep: bool) -> int:
	if gone or waiting or hidden or asleep:
		return 0
	return damage_of(enemy_def)


# His feet box, centred where he stands.
static func feet_box(feet: Vector2, size: Vector2) -> Rect2:
	return Rect2(feet - size / 2.0, size)


static func touches(body: Rect2, feet: Rect2) -> bool:
	return body.intersects(feet)


# The shove that carries his feet out of a body: straight away from its middle, or, standing right on it,
# back the way he faces.
static func shove(body_center: Vector2, feet: Vector2, facing: Vector2) -> Vector2:
	var away := body_center.direction_to(feet)
	if away.is_zero_approx():
		away = -facing.normalized() if not facing.is_zero_approx() else Vector2.DOWN
	return away * SHOVE
