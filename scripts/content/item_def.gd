class_name ItemDef
extends StatEffect

const COMMON := "common"
const RARE := "rare"
const LEGENDARY := "legendary"
const KIND_PASSIVE := "passive"
const KIND_PET := "pet"
const KIND_ACTIVE := "active"
# The builds of the new list. Sets count items by build; every new item's tags are [build].
const BUILDS := ["thermos", "slip", "pension", "pets", "bite", "cane", "dodge", "pills", "risk", "rules", "memory", "any"]
# What tags may name. They group items for the Coach's tips; the builds are tags too.
const TAGS := ["cane", "bite", "dodge", "defence", "money", "thermos", "vision", "room", "boss",
	"slip", "pension", "pets", "pills", "risk", "rules", "memory", "any"]

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
# The build it belongs to (BUILDS), and how it is held: a passive, a pet, or an active in the use slot.
@export var build: String = "any"
@export var kind: String = KIND_PASSIVE
# An active's recharge: fight rooms cleared to fill it, or once a floor when charge_per_floor is set.
@export var charge_rooms: int = 0
@export var charge_per_floor: bool = false
# What the item does at moments of play, if anything beyond its stats.
@export var effect: ItemEffect


func needs_recipe() -> bool:
	return craft_price > 0


func has_tag(tag: String) -> bool:
	return tags.has(tag)


func is_active() -> bool:
	return kind == KIND_ACTIVE


func is_pet() -> bool:
	return kind == KIND_PET


# Rules and memory passives only make sense on floors that post room rules (RunState.rules_posted). An
# active of the rules build (the Megaphone) works anywhere.
func needs_rules() -> bool:
	return (build == "rules" or build == "memory") and kind != KIND_ACTIVE
