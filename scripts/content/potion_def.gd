class_name PotionDef
extends Resource

const ACTION_DOUBLE_BOMBS := "double_bombs"
const ACTION_DOUBLE_SLIPS := "double_slips"
const ACTION_SWAP := "swap"
const ACTION_CASH_IN := "cash_in"
const ACTION_SALTS := "salts"
const ACTION_COURAGE := "courage"
const ACTION_PET_FOOD := "pet_food"

# A potion fills the single potion slot. Healing acts at once, a buff lasts a short while.
@export var id: String = ""
@export var display_name: String = ""
# What the HUD shows beside the slot, so it must stay short.
@export var short_name: String = ""
@export var description: String = ""
@export var heal: int = 0
@export var speed_bonus: float = 0.0
@export var damage_bonus: float = 0.0
@export var duration: float = 0.0
# What a brew costs in Pension. Zero means the merchant doesn't sell it, as with a small potion found in a run.
@export var price: int = 0
@export var color := Color("e4524f")
# What drinking does beyond a heal or a timed buff (PotionActions), "" for none.
@export var action := ""
# common or rare: found in runs (PotionPool). "" for a potion no run finds or sells.
@export var run_rarity := ""
# What lasts after drinking (Smelling Salts, Dutch Courage, Tin of Pet Food): a copy joins the run's
# effects until it says it is spent.
@export var effect: ItemEffect


func is_for_sale() -> bool:
	return price > 0


func is_run_potion() -> bool:
	return not run_rarity.is_empty()


func has_buff() -> bool:
	return duration > 0.0 and (speed_bonus != 0.0 or damage_bonus != 0.0)
