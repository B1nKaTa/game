class_name ItemDef
extends StatEffect

const COMMON := "common"
const RARE := "rare"
const LEGENDARY := "legendary"
# What tags may name. They group items for the combos and the Coach's tips.
const TAGS := ["cane", "bite", "dodge", "defence", "money", "thermos", "vision", "room", "boss"]

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# Above zero, the item needs its recipe found and crafted before it joins the rotation.
@export var craft_price: int = 0
# A wanted poster's reward: it joins the rotation only once its poster is collected.
@export var from_bounty: bool = false
# A path id: the item joins the rotation once that path's floor boss has first fallen.
@export var first_clear_path: String = ""
# common, rare or legendary. Sources roll a rarity first, then pick an item of it.
@export var rarity: String = COMMON
# A strong effect with a real drawback, which its description always names.
@export var cursed: bool = false
@export var tags: PackedStringArray = PackedStringArray()
# What the item does at moments of play, if anything beyond its stats.
@export var effect: ItemEffect


func needs_recipe() -> bool:
	return craft_price > 0


func has_tag(tag: String) -> bool:
	return tags.has(tag)
