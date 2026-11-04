class_name UpgradeDef
extends StatEffect

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var prices: PackedInt32Array = []
@export var merchant: String = "black_market"

const OPTION_A := "a"
const OPTION_B := "b"

@export_group("Form")
# The level whose filing asks for a choice between two options. Zero means the form has no choice.
@export var milestone_level: int = 0
@export var option_a_name: String = ""
@export var option_a_text: String = ""
# Plain StatEffects, never UpgradeDefs, so the stats' per-form special cases ignore them.
@export var option_a: StatEffect
@export var option_b_name: String = ""
@export var option_b_text: String = ""
@export var option_b: StatEffect


func has_choice() -> bool:
	return milestone_level > 0 and option_a != null and option_b != null


func option(choice: String) -> StatEffect:
	return option_b if choice == OPTION_B else option_a


func option_name(choice: String) -> String:
	return option_b_name if choice == OPTION_B else option_a_name


func option_text(choice: String) -> String:
	return option_b_text if choice == OPTION_B else option_a_text


func max_level() -> int:
	return prices.size()


func price_at(level: int) -> int:
	if level < 0 or level >= prices.size():
		return -1
	return prices[level]
