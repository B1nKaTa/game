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
