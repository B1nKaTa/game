class_name EnemyAnim
extends RefCounted

# Which of an enemy's anims shows, and which way it faces. Every enemy's art is drawn facing east and
# mirrored. It shows the windup while its warning runs (Enemy.is_winding_up), the attack once for
# ATTACK_TIME as the windup ends (when every enemy's hit lands), the walk while its own walk moves it,
# and the idle otherwise. A behavior can play one of its own by name (Enemy.play_anim). A missing
# strip falls back as SpriteVisual.resolve says, and without an idle the placeholder draws.

const IDLE := "idle"
const WALK := "walk"
const WINDUP := "windup"
const ATTACK := "attack"
# How long the attack shows once the windup ends. Strips are cut to open on the strike, since the hit
# lands at once (tools/art/enemy_strips.py).
const ATTACK_TIME := 0.3
# Its own walk must move it this fast (px/s) to show the walk, and this fast across to turn it.
const WALK_SPEED := 4.0
const TURN_SPEED := 4.0


# The looping anim for its state when nothing plays once.
static func pick(winding: bool, own_velocity: Vector2) -> String:
	if winding:
		return WINDUP
	if own_velocity.length() >= WALK_SPEED:
		return WALK
	return IDLE


# Whether it faces left (mirrored). Busy winding up or attacking, or standing, it faces Harold (to_target);
# walking, it faces the way it walks. Straight up or down it keeps the way it faced.
static func faces_left(was_left: bool, busy: bool, own_velocity: Vector2, to_target: Vector2) -> bool:
	if not busy and own_velocity.length() >= WALK_SPEED:
		if absf(own_velocity.x) < TURN_SPEED:
			return was_left
		return own_velocity.x < 0.0
	if absf(to_target.x) < 0.5:
		return was_left
	return to_target.x < 0.0
