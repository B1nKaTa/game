class_name PendingBosses
extends RefCounted

# TEMPORARY, for tests only. Tasks 4 and 5 of the Cinema and Seance plan delete this file when the new
# bosses land. Until then the Flashback Cinema and the Seance Hotline still run the Mall's and the
# golf club's bosses, while their posters and mementos already name the bosses that replace them, so
# the tests that match a floor's boss to its poster or memento read the floor's boss through here.

const BY_OLD := {"gloria": "crabtree", "mall_santa": "projectionist", "chip": "celestine", "thaddeus_fairweather": "madame_zara"}


static func id_of(boss_id: String) -> String:
	return str(BY_OLD.get(boss_id, boss_id))
