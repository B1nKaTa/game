class_name AttackWarnings
extends RefCounted

# Whether regular enemies draw their attack warnings (the red circles, lanes, cones and ground marks).
# Off by default: a regular enemy's tell is its windup pose and a brief pale flash as it starts
# (Enemy.WINDUP_CUE), and only bosses and mini bosses show shapes on the floor. The Game tab's "Attack
# warnings" setting turns them back on (Settings.apply sets this). Timing, range and damage never change;
# only the drawing does.
static var shown := false

# With the setting off, an attack that lands on the ground with nothing flying in to give it away (the
# bingo caller's marks, a steam lane, a cord's band) still shows a faint cue where it will hurt: a dark,
# neutral shadow, never red, at CUE_ALPHA rising to CUE_ALPHA_LATE, that grows over the last part of the
# warning (from CUE_GROW_FROM of it). It is meant to be easy to miss in a crowd, not invisible.
const CUE_COLOR := Color(0.05, 0.04, 0.05)
const CUE_ALPHA := 0.25
const CUE_ALPHA_LATE := 0.35
const CUE_GROW_FROM := 0.6


static func drawn_for(def: EnemyDef) -> bool:
	return def != null and (def.is_boss or shown)


# Whether a world attack (a lobbed tub, a cord's band, a puck's path) draws the warning shapes of the
# enemy that started it. As with a ground strike, a source that is gone leaves its shapes drawn. Typed
# Variant, since a freed enemy cannot be passed as an Enemy.
static func drawn_by(source: Variant) -> bool:
	if not is_instance_valid(source) or not (source as Object).has_method("shows_warnings"):
		return true
	return source.shows_warnings()


# How far the hidden cue has grown, 0 to 1, for a warning filled this far (0 to 1).
static func cue_growth(filled: float) -> float:
	return smoothstep(CUE_GROW_FROM, 1.0, filled)


# The hidden cue's colour for a warning filled this far.
static func cue_color(filled: float) -> Color:
	return Color(CUE_COLOR, lerpf(CUE_ALPHA, CUE_ALPHA_LATE, cue_growth(filled)))
