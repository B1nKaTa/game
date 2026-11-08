class_name CinemaScenes
extends RefCounted

# The films the Flashback Cinema's screens play: still scenes of Harold's everyday life in a sepia
# old-film style, each a landscape strip of FRAMES frames that the screen cross-fades between
# (CinemaScreen). None shows how his story ends, or his house as somewhere to get back to.
#
# Art: res://art/cinema/scenes/<id>.png is one horizontal strip of FRAMES frames (up to MAX_FRAMES),
# each FRAME_SIZE (160x64 px), side by side with no gaps, so the 2-frame strips are 320x64. The frames
# are the same still with a small change, since they fade slowly into one another. The screen shows a
# frame at 1:1 across, trimming a few rows top and bottom to fit its wall (CinemaScreen), and adds its
# own sepia, grain, scratches and flicker. Until a file exists, the screen paints a placeholder from
# placeholder_image.
const FRAME_SIZE := Vector2i(160, 64)
const FRAMES := 2
const MAX_FRAMES := 3
const ART_DIR := "res://art/cinema/scenes/"
# The room types whose north wall holds a screen.
const SCREEN_ROOMS: Array[String] = [RoomLayout.TYPE_COMBAT, RoomLayout.TYPE_MINI_BOSS, RoomLayout.TYPE_FLOOR_BOSS]

const ALL: Array[Dictionary] = [
	{"id": "hedge_1974", "title": "The hedge, 1974",
		"description": "Harold and Gerald stand either side of a waist-high privet hedge in two back gardens, each holding garden shears and glaring, a tape measure stretched over the hedge between them. In the next frame Gerald points at the tape and Harold folds his arms."},
	{"id": "biscuit_walk", "title": "Walking Biscuit",
		"description": "Harold in a flat cap and raincoat walks a scruffy little terrier on a lead along a park path, past a bench where one fat pigeon sits. Biscuit strains towards the pigeon; in the next frame the pigeon has not moved an inch."},
	{"id": "first_car", "title": "His first car",
		"description": "A young Harold in shirtsleeves polishes a small round-backed saloon car at the kerb with a chamois, beaming. The front bumper has a dent; in the next frame he has noticed it."},
	{"id": "works_do", "title": "The works do",
		"description": "The bus depot canteen strung with paper chains: Harold in a paper hat holds a pint and a sausage roll beside a trestle table, colleagues in overalls around him. In the next frame he is mid-laugh and the sausage roll is gone."},
	{"id": "family_christmas", "title": "A family Christmas",
		"description": "Harold in a lopsided paper crown carves a turkey at a crowded dinner table, a tinsel tree behind. A small child pulls a cracker with him; in the next frame it has snapped and both are holding the wrong half."},
	{"id": "fence_fix", "title": "Fixing the fence",
		"description": "Harold in a garden, a hammer in one hand and nails between his lips, holds up a wooden fence panel that leans badly. In the next frame the panel beside it has quietly fallen over."},
	{"id": "retirement_cake", "title": "The retirement cake",
		"description": "Harold in his good suit at the depot, before a slab cake iced with a clock face and the words NEVER LATE, colleagues clapping behind him. In the next frame the clock on the wall above them reads ten past."},
	{"id": "seaside_day", "title": "A day at the seaside",
		"description": "Harold on a striped deckchair on a pebble beach, trousers rolled to the knee and a knotted handkerchief on his head, an ice cream melting down his hand, the pier behind. In the next frame a gull has the cone."},
	{"id": "lost_umbrella", "title": "The lost umbrella",
		"description": "Harold at a bus stop in pouring rain, soaked, watching a bus pull away; through its back window his umbrella hangs from a seat. In the next frame the bus is smaller and he is still pointing."},
	{"id": "dance_lesson", "title": "Learning to dance",
		"description": "A young Harold in a dance hall, stiff as a post, treads on his partner's foot while chalk footprints of the lesson mark the floor around them. In the next frame they are both laughing."},
	{"id": "burnt_roast", "title": "The burnt Sunday roast",
		"description": "Harold in oven gloves opens a kitchen oven and a cloud of smoke rolls out over a blackened joint, the family at the table behind waving tea towels. In the next frame he is holding it up as if it were meant."},
	{"id": "pigeon_bench", "title": "The pigeon on the bench",
		"description": "Harold in a flat cap sits hunched on a park bench under a lamp post, a paper bag of crumbs at his feet, while a pigeon perches on the next bench along and keeps its distance. In the next frame it is still eyeing the bag."},
	{"id": "shed_painting", "title": "Painting the shed",
		"description": "Harold in overalls stands at a ladder against the garden shed with a brush, painting its boards, a wheelbarrow by the fence behind him. In the next frame he leans in for one more stroke."},
	{"id": "bike_lesson", "title": "The bike lesson",
		"description": "Harold cycles slowly down a terraced street beside a small child on a little bicycle, ready to steady the handlebars. In the next frame the child is still upright and pedalling."},
	{"id": "bus_route", "title": "The number 12",
		"description": "Harold in his peaked depot cap at the wheel of a double-decker, waving from the cab as he pulls up at a stop where a queue waits with shopping bags. In the next frame his hand is back on the wheel and the first passenger steps up."},
	{"id": "wedding_day", "title": "The wedding",
		"description": "A young Harold in a borrowed suit and his laughing bride come down the church steps under a shower of confetti, guests clapping either side. In the next frame the wind has taken his hat."},
	{"id": "prize_marrow", "title": "The prize marrow",
		"description": "Harold and Gerald in flat caps stand side by side behind a trestle table at the village show, each beside an enormous marrow, one wearing a rosette, glaring at each other under the bunting. In the next frame Harold leans over his marrow to measure it."},
	{"id": "fishing_trip", "title": "The fishing trip",
		"description": "Harold in a flat cap and wellingtons sits on a folding stool under a willow on a quiet riverbank, his rod out over the water and a flask of tea beside him. In the next frame the rod bends and he lands an old boot."},
	{"id": "caravan_holiday", "title": "The caravan holiday",
		"description": "A small caravan in a field in pouring rain, the children's faces at its window, while Harold in a hooded raincoat wrestles a striped windbreak. In the next frame the wind has it."},
]


static func ids() -> Array[String]:
	var found: Array[String] = []
	for scene in ALL:
		found.append(scene["id"])
	return found


static func scene(id: String) -> Dictionary:
	for each in ALL:
		if each["id"] == id:
			return each
	return {}


static func shows_screen(room_type: String) -> bool:
	return SCREEN_ROOMS.has(room_type)


# A room's film from its own seed: the same seed always picks the same scene.
static func pick(seed_value: int) -> String:
	return ALL[_start(seed_value)]["id"]


static func _start(seed_value: int) -> int:
	var n := seed_value * 1103515245 + 12345
	n = n ^ (n >> 15)
	n = (n * 2654435761) & 0x7fffffff
	return posmod(n >> 7, ALL.size())


# Every screen room's film on a floor: each room takes its own pick, or the next scene along that no
# other room on the floor shows yet, so each lobby card has its film's lines to itself (LifeSigns). On
# a floor with more screens than films, a film may come round again, but never in a room next door,
# through any door. Rooms are taken in id order, so the floor always gets the same films.
static func assign(map: FloorMap) -> Dictionary:
	var chosen := {}
	for room in map.rooms:
		if not shows_screen(room.room_type):
			continue
		var start := _start(room.decor_seed)
		var pick_id: String = ALL[start]["id"]
		var fallback := ""
		for step in ALL.size():
			var id: String = ALL[(start + step) % ALL.size()]["id"]
			if _shown_next_door(map, room, id, chosen):
				continue
			if fallback.is_empty():
				fallback = id
			if not chosen.values().has(id):
				pick_id = id
				fallback = ""
				break
		if not fallback.is_empty():
			pick_id = fallback
		chosen[room.id] = pick_id
	return chosen


static func _shown_next_door(map: FloorMap, room: FloorRoom, id: String, chosen: Dictionary) -> bool:
	for side in room.doors:
		var other: int = room.doors[side]
		if chosen.get(other, "") == id:
			return true
	return false


static func art_path(id: String) -> String:
	return ART_DIR + id + ".png"


# --- the drawn stand-in, until the art exists ---

const SKY := Color(0.86, 0.74, 0.56)
const GROUND := Color(0.5, 0.38, 0.24)
const FIGURE := Color(0.16, 0.11, 0.07)
const PROP := Color(0.3, 0.21, 0.13)
const PALE := Color(0.95, 0.88, 0.72)


# A strip of FRAMES sepia frames: a sky-to-ground gradient, Harold's dark silhouette and one prop for
# the scene, with his arm up in one frame and down in the others, so the cross-fade shows.
static func placeholder_image(id: String) -> Image:
	var image := Image.create(FRAME_SIZE.x * FRAMES, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	var index := maxi(ids().find(id), 0)
	for frame in FRAMES:
		var left := frame * FRAME_SIZE.x
		for y in FRAME_SIZE.y:
			var shade := SKY.lerp(GROUND, smoothstep(0.35, 1.0, float(y) / FRAME_SIZE.y))
			image.fill_rect(Rect2i(left, y, FRAME_SIZE.x, 1), shade)
		image.fill_rect(Rect2i(left, 40, FRAME_SIZE.x, 1), GROUND.darkened(0.2))
		_paint_prop(image, left, index, frame)
		_paint_harold(image, left + 58 + (frame % 2), frame == 1)
	return image


static func _paint_harold(image: Image, x: int, arm_up: bool) -> void:
	_disc(image, Vector2i(x + 5, 19), 4, FIGURE)
	image.fill_rect(Rect2i(x + 1, 13, 9, 3), FIGURE)
	image.fill_rect(Rect2i(x + 1, 24, 9, 12), FIGURE)
	image.fill_rect(Rect2i(x + 2, 36, 2, 7), FIGURE)
	image.fill_rect(Rect2i(x + 7, 36, 2, 7), FIGURE)
	if arm_up:
		image.fill_rect(Rect2i(x + 10, 17, 2, 9), FIGURE)
	else:
		image.fill_rect(Rect2i(x + 10, 25, 2, 9), FIGURE)
	# His cane, always.
	image.fill_rect(Rect2i(x - 2, 28, 1, 15), FIGURE)


static func _paint_prop(image: Image, left: int, index: int, frame: int) -> void:
	var x := left + 86
	match index % 7:
		0:
			# A hedge or a fence, with a second figure beyond it.
			image.fill_rect(Rect2i(x, 26, 40, 16), PROP)
			_disc(image, Vector2i(x + 50, 19), 4, FIGURE)
			image.fill_rect(Rect2i(x + 46, 24, 9, 18), FIGURE)
		1:
			# A dog, a car, a bicycle: something on wheels or legs beside him.
			image.fill_rect(Rect2i(x, 28, 34, 10), PROP)
			_disc(image, Vector2i(x + 6, 39), 4, FIGURE)
			_disc(image, Vector2i(x + 28, 39), 4, FIGURE)
		2:
			# A table, with something steaming on it.
			image.fill_rect(Rect2i(x, 30, 44, 4), PROP)
			image.fill_rect(Rect2i(x + 4, 34, 3, 9), PROP)
			image.fill_rect(Rect2i(x + 37, 34, 3, 9), PROP)
			image.fill_rect(Rect2i(x + 16, 24, 12, 6), PROP)
			image.fill_rect(Rect2i(x + 20, 14 - frame * 2, 3, 8), PALE)
		3:
			# The sea, the sun and a deckchair.
			image.fill_rect(Rect2i(left, 33, FRAME_SIZE.x, 4), PALE.darkened(0.25))
			_disc(image, Vector2i(x + 40, 10), 6, PALE)
			image.fill_rect(Rect2i(x, 30, 16, 3), PROP)
		4:
			# Rain, and a bus going away.
			for drop in 22:
				image.fill_rect(Rect2i(left + (drop * 37 + frame * 5) % FRAME_SIZE.x, (drop * 11) % 30, 1, 4), PALE.darkened(0.1))
			image.fill_rect(Rect2i(x + frame * 3, 18, 40, 22), PROP)
		5:
			# A second figure to dance with.
			_disc(image, Vector2i(x + 4, 19), 4, FIGURE)
			image.fill_rect(Rect2i(x, 24, 9, 18), FIGURE)
			image.fill_rect(Rect2i(x - 4, 42, 30, 1), PALE)
		_:
			# A riverbank and a rod.
			image.fill_rect(Rect2i(left + 100, 36, 60, 5), PALE.darkened(0.3))
			for step in 30:
				image.fill_rect(Rect2i(x - 14 + step, 26 - step / 2 + (frame % 2), 1, 1), FIGURE)


static func _disc(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var at := center + Vector2i(dx, dy)
				if at.x >= 0 and at.y >= 0 and at.x < image.get_width() and at.y < image.get_height():
					image.set_pixelv(at, color)
