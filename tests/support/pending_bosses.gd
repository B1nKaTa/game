class_name PendingBosses
extends RefCounted

# TEMPORARY, for tests only. Task 5 of the Cinema and Seance plan deletes this file when the Seance
# Hotline's floor boss lands (the Cinema's bosses and Sister Celestine are in). Until then the Seance
# Hotline still runs the golf club's floor boss, while his poster and memento already name the boss
# that replaces him, so the tests that match a floor's boss to its poster or memento read the floor's
# boss through here.

const BY_OLD := {"thaddeus_fairweather": "madame_zara"}


static func id_of(boss_id: String) -> String:
	return str(BY_OLD.get(boss_id, boss_id))
