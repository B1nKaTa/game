class_name BountyDef
extends Resource

# A wanted poster in the Bounty Office. Its id is the wanted boss's EnemyDef id, which
# ProgressData.record_boss_beaten relies on to mark the poster won.

const EXTRA_ITEM := "item"
const EXTRA_RECIPE := "recipe"
const EXTRA_COSMETIC := "cosmetic"

@export var id: String = ""
@export var boss_name: String = ""
# The FloorDef id of the floor the boss is found on.
@export var floor_id: String = ""
@export var depth: int = 1
# A floor boss, rather than the floor's mini boss.
@export var floor_boss: bool = false
@export var pension: int = 0
@export var condolences: int = 0
# What else the poster pays: one of the EXTRA_ kinds, and the id of that item, recipe or cosmetic.
@export var extra_kind: String = ""
@export var extra_id: String = ""
