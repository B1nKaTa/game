class_name PotionActions
extends RefCounted

# What the new list's potions do when drunk. A potion that would change nothing waits in its slot, as a
# heal waits at full pills.

const CASH_PER := 10


static func can_drink(run: RunState, def: PotionDef) -> bool:
	match def.action:
		PotionDef.ACTION_DOUBLE_BOMBS:
			return run.bombs > 0 and run.bombs < RunState.MAX_CONSUMABLE
		PotionDef.ACTION_DOUBLE_SLIPS:
			return run.keys > 0 and run.keys < RunState.MAX_CONSUMABLE
		PotionDef.ACTION_SWAP:
			return run.keys != run.bombs
		PotionDef.ACTION_CASH_IN:
			return run.keys + run.bombs > 0
		PotionDef.ACTION_PET_FOOD:
			return run.pet_count() > 0
	return true


static func apply(run: RunState, def: PotionDef) -> void:
	match def.action:
		PotionDef.ACTION_DOUBLE_BOMBS:
			run.add_bombs(run.bombs)
		PotionDef.ACTION_DOUBLE_SLIPS:
			run.add_keys(run.keys)
		PotionDef.ACTION_SWAP:
			run.swap_slips_and_thermoses()
		PotionDef.ACTION_CASH_IN:
			run.effects.ctx.pay(CASH_PER * (run.scaled_keys() + run.scaled_bombs()))
	if def.effect != null:
		run.effects.add_lasting(def.id, def.effect.duplicate())
