class_name LetterBook
extends RefCounted

# Letters from the living world, one for each floor's first clear, pinned to the lobby's noticeboard.
# They come from paths_cleared, so an old save receives its letters at once. Placeholder text, to be
# written later. Pure rules, reading only ProgressData.

# In floor order: {"path", "from", "text"}. A letter's id is its path id.
const LETTERS: Array[Dictionary] = [
	{"path": "floor_1", "from": "Your neighbour", "text": "Your hedge is finally mine. Rest in peace, you old goat."},
	{"path": "cemetery", "from": "The parish", "text": "Your plot is paid for. Please stop leaving it."},
	{"path": "sunset_shores", "from": "Sunset Shores", "text": "Your room has been let. We kept the slippers."},
	{"path": "furnace_works", "from": "The crematorium", "text": "Re: your booking. Postponed until further notice."},
	{"path": "funeral_parlour", "from": "Your son", "text": "Dad, the service was lovely. Mum said you'd have hated it."},
	{"path": "golden_years_mall", "from": "Your granddaughter", "text": "Grandpa, I walked your dog at the mall. He waited by the bench."},
	{"path": "last_resort_cruise", "from": "Your travel agent", "text": "Your cruise deposit is non-refundable. So, it turns out, are you."},
	{"path": "fairways_end", "from": "The golf club", "text": "Your locker has been cleared. Eleven years of tees and one sandwich."},
	{"path": "terminal_zero", "from": "Your airline", "text": "We regret your flight was cancelled. Please accept 500 miles for your trouble."},
	{"path": "head_office", "from": "Your old firm", "text": "Your retirement papers are finally filed. Effective last Tuesday. Well done."},
]


static func arrived(data: ProgressData) -> Array[Dictionary]:
	var letters: Array[Dictionary] = []
	for letter in LETTERS:
		if data.has_cleared_path(letter["path"]):
			letters.append(letter)
	return letters


static func unread(data: ProgressData) -> Array[Dictionary]:
	var letters: Array[Dictionary] = []
	for letter in arrived(data):
		if not is_read(letter, data):
			letters.append(letter)
	return letters


static func is_read(letter: Dictionary, data: ProgressData) -> bool:
	return data.letters_read.has(letter["path"])
