class_name ItemDef
extends StatEffect

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
# Above zero, the item needs its recipe found and crafted before it joins the rotation.
@export var craft_price: int = 0


func needs_recipe() -> bool:
	return craft_price > 0
