class_name PotionDef
extends Resource

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


func is_for_sale() -> bool:
	return price > 0


func has_buff() -> bool:
	return duration > 0.0 and (speed_bonus != 0.0 or damage_bonus != 0.0)
