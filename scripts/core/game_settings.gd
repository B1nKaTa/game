class_name GameSettings
extends RefCounted

# The game's settings, one file for the whole game and outside every save slot. A missing or damaged
# file, a value of the wrong kind or an unknown key falls back to the default, and a slider out of its
# range is clamped. The Settings autoload holds the live copy and applies it, and the Options panel
# edits a duplicate until OK.

const VIDEO := "video"
const AUDIO := "audio"
const GAME := "game"
const INPUT := "input"
const SECTIONS: Array[String] = [VIDEO, AUDIO, GAME]
const VIEW := Vector2i(640, 360)
# Whole multiples of the view a window may take. The smallest is always offered.
const MULTIPLES: Array[int] = [2, 3, 4, 6]
# The languages the Language dropdown offers. Only English for now; every menu string goes through tr().
const LANGUAGES: Array[String] = ["en"]

# Each setting's default and kind: a bool is a switch, [default, min, max] is a slider, and a String is a
# choice whose rule is in _valid_text.
const DEFAULTS := {
	VIDEO: {
		"brightness": [0, -50, 50],
		"contrast": [0, -50, 50],
		"gamma": [0, -50, 50],
		# A 1080p window by default; a screen too small for it gets the biggest size that fits. "" is the
		# best fit for the screen, worked out when it is applied. F11 or Alt+Enter goes fullscreen.
		"resolution": "1920x1080",
		"fullscreen": false,
		"vsync": true,
		"confine_mouse": true,
		"pixel_perfect": true,
	},
	AUDIO: {
		"master": [100, 0, 100],
		"effects": [80, 0, 100],
		"music": [70, 0, 100],
		"ambience": [70, 0, 100],
	},
	GAME: {
		"screen_shake": true,
		"hit_stop": true,
		"vibration": true,
		"heal_at_full": false,
		"mouse_aim": true,
		"hide_minimap_in_combat": false,
		"minimap_opacity": [100, 20, 100],
		"run_timer": false,
		# Regular enemies' red attack warnings (AttackWarnings). Bosses always show theirs.
		"attack_warnings": false,
		"language": "en",
	},
}

var _values := {}


func _init() -> void:
	for section: String in SECTIONS:
		reset_section(section)


static func default_of(section: String, key: String) -> Variant:
	var spec: Variant = DEFAULTS[section][key]
	return spec[0] if spec is Array else spec


static func range_of(section: String, key: String) -> Vector2i:
	var spec: Variant = DEFAULTS[section][key]
	return Vector2i(spec[1], spec[2]) if spec is Array else Vector2i.ZERO


static func is_slider(section: String, key: String) -> bool:
	return DEFAULTS[section][key] is Array


func value(section: String, key: String) -> Variant:
	return _values[section][key]


# A value of the wrong kind is ignored, and a slider is clamped to its range.
func set_value(section: String, key: String, raw: Variant) -> void:
	if not DEFAULTS.has(section) or not DEFAULTS[section].has(key):
		return
	var spec: Variant = DEFAULTS[section][key]
	if spec is Array:
		if typeof(raw) == TYPE_INT or typeof(raw) == TYPE_FLOAT:
			_values[section][key] = clampi(int(raw), spec[1], spec[2])
	elif spec is bool:
		if typeof(raw) == TYPE_BOOL:
			_values[section][key] = raw
	elif typeof(raw) == TYPE_STRING and _valid_text(key, raw):
		_values[section][key] = raw


static func _valid_text(key: String, text: String) -> bool:
	if key == "language":
		return LANGUAGES.has(text)
	if key == "resolution":
		return text.is_empty() or parse_resolution(text) != Vector2i.ZERO
	return false


func reset_section(section: String) -> void:
	var fresh := {}
	for key: String in DEFAULTS[section]:
		fresh[key] = default_of(section, key)
	_values[section] = fresh


func duplicate_settings() -> GameSettings:
	var copy := GameSettings.new()
	for section: String in SECTIONS:
		copy._values[section] = _values[section].duplicate()
	return copy


# Whether two settings agree, everywhere or in one section.
func equals(other: GameSettings, section := "") -> bool:
	for each: String in SECTIONS:
		if not section.is_empty() and each != section:
			continue
		if _values[each] != other._values[each]:
			return false
	return true


# False when there was no file or it could not be read, which leaves the defaults.
func load_from(path: String) -> bool:
	for section: String in SECTIONS:
		reset_section(section)
	if not FileAccess.file_exists(path):
		return false
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return false
	for section: String in SECTIONS:
		if not file.has_section(section):
			continue
		for key: String in DEFAULTS[section]:
			if file.has_section_key(section, key):
				set_value(section, key, file.get_value(section, key))
	return true


func save_to(path: String) -> bool:
	var file := ConfigFile.new()
	for section: String in SECTIONS:
		for key: String in DEFAULTS[section]:
			file.set_value(section, key, _values[section][key])
	return file.save(path) == OK


# The window sizes offered on a screen of that size, smallest first.
static func resolutions_for(screen: Vector2i) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	for multiple in MULTIPLES:
		var size := VIEW * multiple
		if size.x <= screen.x and size.y <= screen.y:
			list.append(size)
	if list.is_empty():
		list.append(VIEW * MULTIPLES[0])
	return list


static func best_resolution(screen: Vector2i) -> Vector2i:
	return resolutions_for(screen)[-1]


# The video keys that set up the window itself. Settings changes the window's mode, size and place only
# when these differ from what it applied last, since Options applies its draft on every slider tick.
const WINDOW_KEYS: Array[String] = ["fullscreen", "resolution", "pixel_perfect"]


static func window_keys(settings: GameSettings) -> Array:
	var values := []
	for key in WINDOW_KEYS:
		values.append(settings.value(VIDEO, key))
	return values


static func resolution_text(size: Vector2i) -> String:
	return "%dx%d" % [size.x, size.y]


static func parse_resolution(text: String) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	var size := Vector2i(int(parts[0]), int(parts[1]))
	return size if size.x > 0 and size.y > 0 else Vector2i.ZERO


static func is_neutral(brightness: int, contrast: int, gamma: int) -> bool:
	return brightness == 0 and contrast == 0 and gamma == 0


# What the adjustment layer adds to every color: up to a fifth either way.
static func brightness_offset(level: int) -> float:
	return level / 250.0


# How far colors spread from the middle grey: half as far to half again.
static func contrast_factor(level: int) -> float:
	return 1.0 + level / 100.0


# The power the layer lifts colors by, as 1/gamma: 0.5 to 2, where above 1 brightens the darks.
static func gamma_power(level: int) -> float:
	return pow(2.0, level / 50.0)


# A bus's volume from its slider. Zero is silent.
static func bus_db(percent: int) -> float:
	if percent <= 0:
		return -80.0
	return linear_to_db(percent / 100.0)


# The small map shows unless the big map is open, or the option hides it while a room's fight is on.
static func minimap_visible(hide_in_combat: bool, fighting: bool, big_map_open: bool) -> bool:
	if big_map_open:
		return false
	return not (hide_in_combat and fighting)


# The buses every sound plays through, each sending to Master. Music and Ambience have nothing to play yet.
const BUSES: Array[String] = ["Effects", "Music", "Ambience"]


static func ensure_buses() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) != -1:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, "Master")


# Sets every bus's volume from the Audio tab.
static func apply_volumes(settings: GameSettings) -> void:
	ensure_buses()
	AudioServer.set_bus_volume_db(0, bus_db(settings.value(AUDIO, "master")))
	for bus in BUSES:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), bus_db(settings.value(AUDIO, bus.to_lower())))
