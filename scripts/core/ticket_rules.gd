class_name TicketRules
extends RefCounted

# Grandpa's queue ticket is his run count. Every fifth number is called on his next return, and the
# events take turns: a clerk's deal, a new arrival's line, then a cursed ticket on offer. Pure rules,
# reading only what they are given, so the tests need no autoload.

const CALL_EVERY := 5
const CLERK_DEAL := "clerk_deal"
const NEW_ARRIVAL := "new_arrival"
const CURSED_OFFER := "cursed_offer"
const EVENTS: Array[String] = [CLERK_DEAL, NEW_ARRIVAL, CURSED_OFFER]
# A cursed run's enemies are tougher and pay better, and each floor cleared in it pays Condolences.
const CURSED_HEALTH_MULT := 1.25
const CURSED_PENSION_MULT := 1.5

# Placeholder one-liners for a new arrival, each prefixed by who says it, with the department each
# speaker stands in at the same index.
const ARRIVAL_LINES: Array[String] = [
	"Black Market: Psst. New stock. Same old you.",
	"Dr. Squint: Your eyes look tired. Or dead. Hard to say.",
	"Agnes: I knitted you something. Then I unknitted it.",
	"Deputy Dolores: Your file has grown a second file.",
	"Coach Bertram: Drop and give me twenty. Pills, I mean.",
	"The Purser: I've packed you a sandwich. It's mostly bag.",
	"Duffy: New gloves in. Same old swing, I expect.",
	"Ingrid: Duty Free has a sale. Everything must go. So must you.",
	"Mr. Hollis: Your severance has been processed. You haven't.",
]
# Departments ids, written out so these rules load nothing else. test_tickets_and_letters pins them.
const ARRIVAL_DEPARTMENTS: Array[String] = [
	"lobby",
	"lobby",
	"lobby",
	"bounty_office",
	"training_yard",
	"pursers_office",
	"pro_shop",
	"duty_free",
	"executive_suite",
]


# The event a ticket calls, or "" for a number that is not called.
static func event_for(ticket: int) -> String:
	if ticket <= 0 or ticket % CALL_EVERY != 0:
		return ""
	return EVENTS[(ticket / CALL_EVERY - 1) % EVENTS.size()]


# One form not yet filed in full, picked by roll in [0, 1), or "" when every form is.
static func deal_form(upgrades: Array[UpgradeDef], data: ProgressData, roll: float) -> String:
	var open: Array[String] = []
	for def in upgrades:
		if def.price_at(data.level_of(def.id)) >= 0:
			open.append(def.id)
	if open.is_empty():
		return ""
	return open[clampi(int(roll * open.size()), 0, open.size() - 1)]


# A line from someone whose department is open, picked by roll in [0, 1).
static func arrival_line(open_department_ids: Array, roll: float) -> String:
	var lines: Array[String] = []
	for i in ARRIVAL_LINES.size():
		if open_department_ids.has(ARRIVAL_DEPARTMENTS[i]):
			lines.append(ARRIVAL_LINES[i])
	if lines.is_empty():
		return ""
	return lines[clampi(int(roll * lines.size()), 0, lines.size() - 1)]
