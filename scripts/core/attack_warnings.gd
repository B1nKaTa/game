class_name AttackWarnings
extends RefCounted

# Whether regular enemies draw their attack warnings (the red circles, lanes, cones and ground marks).
# Off by default: a regular enemy's tell is its windup pose and a brief pale flash as it starts
# (Enemy.WINDUP_CUE), and only bosses and mini bosses show shapes on the floor. The Game tab's "Attack
# warnings" setting turns them back on (Settings.apply sets this). Timing, range and damage never change;
# only the drawing does.
static var shown := false


static func drawn_for(def: EnemyDef) -> bool:
	return def != null and (def.is_boss or shown)


# Whether a world attack (a lobbed tub, a cord's band, a puck's path) draws the warning shapes of the
# enemy that started it. As with a ground strike, a source that is gone leaves its shapes drawn. Typed
# Variant, since a freed enemy cannot be passed as an Enemy.
static func drawn_by(source: Variant) -> bool:
	if not is_instance_valid(source) or not (source as Object).has_method("shows_warnings"):
		return true
	return source.shows_warnings()
