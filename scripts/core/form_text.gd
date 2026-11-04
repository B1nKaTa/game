class_name FormText
extends RefCounted

# The words on a form row and a refile row. Pure, so the panels and the tests share one wording.

const STAMP_FILED := "[FILED]"
const STAMP_EMPTY := "[ ]"
const FILED_IN_FULL := "Filed in full"
const FREE := "Free"


# One stamp per level, filed or still empty, e.g. "[FILED] [FILED] [ ]".
static func stamps(def: UpgradeDef, level: int) -> String:
	var marks := PackedStringArray()
	for i in def.max_level():
		marks.append(STAMP_FILED if i < level else STAMP_EMPTY)
	return " ".join(marks)


# The form's name, its stamps, the option it runs with if any, and what the next filing costs.
static func row(def: UpgradeDef, level: int, price: int, choice: String) -> String:
	var parts := PackedStringArray([def.display_name, stamps(def, level)])
	if not choice.is_empty():
		parts.append(def.option_name(choice))
	parts.append(FILED_IN_FULL if price < 0 else "%d Pension" % price)
	return "  ".join(parts)


static func price_text(price: int) -> String:
	return FREE if price == 0 else "%d Pension" % price


# "<form>: <current option> -> <other option>  <price>".
static func refile_row(def: UpgradeDef, choice: String, price: int) -> String:
	var other := UpgradeDef.OPTION_B if choice == UpgradeDef.OPTION_A else UpgradeDef.OPTION_A
	return "%s: %s -> %s  %s" % [def.display_name, def.option_name(choice), def.option_name(other), price_text(price)]
