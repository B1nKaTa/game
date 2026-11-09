extends Node

# The live settings and everything that applies them: the window, the audio buses, the adjustment
# layer and the language. The rules live on GameSettings, which tests reach. The full loop (--smoke)
# and test runs (--script) read nothing and write nothing, so they always play on the defaults.

signal changed
# F11 or Alt+Enter while something (the Options panel) listens: it changes its own draft instead.
signal fullscreen_asked

const PATH := "user://settings.cfg"

var current := GameSettings.new()
var _adjust: AdjustLayer
# The window keys last applied (GameSettings.window_keys), and the window's mode and size last logged.
var _window_keys: Array = []
var _logged_window := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_quiet():
		current.load_from(PATH)
	_adjust = AdjustLayer.new()
	add_child(_adjust)
	apply(current)


# The full loop and test runs never touch settings.cfg or the window.
static func is_quiet() -> bool:
	return OS.get_cmdline_user_args().has("--smoke") or RunMode.is_script_run()


# Applies settings without saving them, as the Options panel does while it is open.
func apply(settings: GameSettings) -> void:
	GameSettings.apply_volumes(settings)
	_adjust.set_levels(settings.value(GameSettings.VIDEO, "brightness"), settings.value(GameSettings.VIDEO, "contrast"), settings.value(GameSettings.VIDEO, "gamma"))
	TranslationServer.set_locale(settings.value(GameSettings.GAME, "language"))
	PadRumble.enabled = settings.value(GameSettings.GAME, "vibration")
	AttackWarnings.shown = settings.value(GameSettings.GAME, "attack_warnings")
	if not is_quiet() and DisplayServer.get_name() != "headless":
		_apply_video(settings)
	changed.emit()


# Keeps the settings for good: applied, and written to settings.cfg.
func commit(settings: GameSettings) -> void:
	current = settings.duplicate_settings()
	apply(current)
	if not is_quiet():
		current.save_to(PATH)


# Puts the kept settings back, as closing Options without OK does.
func revert() -> void:
	apply(current)


func game(key: String) -> Variant:
	return current.value(GameSettings.GAME, key)


# The mouse mode for a scene that shows or hides the cursor, confined to the window when the option is on.
func cursor_mode(hidden: bool) -> Input.MouseMode:
	if current.value(GameSettings.VIDEO, "confine_mouse"):
		return Input.MOUSE_MODE_CONFINED_HIDDEN if hidden else Input.MOUSE_MODE_CONFINED
	return Input.MOUSE_MODE_HIDDEN if hidden else Input.MOUSE_MODE_VISIBLE


func resolution_choices() -> Array[Vector2i]:
	return GameSettings.resolutions_for(window_room())


# The screen the window is on right now. Asking for "the" screen size reads the main screen, which on a
# PC with two screens, or with Windows display scaling, can be bigger than the one the game shows on.
func current_screen() -> int:
	return DisplayServer.window_get_current_screen()


# The room a window can take on its screen: the area outside the taskbar, less the title bar and borders.
# Fullscreen covers the taskbar, so there the whole screen is the room: a 2560x1440 screen offers 2560x1440.
func window_room() -> Vector2i:
	var screen := current_screen()
	if DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		return DisplayServer.screen_get_size(screen)
	var room := DisplayServer.screen_get_usable_rect(screen).size
	if room.x <= 0 or room.y <= 0:
		room = DisplayServer.screen_get_size(screen)
	var frame := DisplayServer.window_get_size_with_decorations() - DisplayServer.window_get_size()
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED or frame.x < 0 or frame.y < 0:
		frame = Vector2i(16, 40)
	return room - frame


# The window size the settings ask for: the chosen one if it still fits, otherwise the best fit.
func window_size(settings: GameSettings) -> Vector2i:
	var choices := resolution_choices()
	var wanted := GameSettings.parse_resolution(settings.value(GameSettings.VIDEO, "resolution"))
	return wanted if choices.has(wanted) else choices[-1]


func _apply_video(settings: GameSettings) -> void:
	# A mouse mode already set by a scene is kept, only its confinement follows the option.
	var hidden := Input.mouse_mode == Input.MOUSE_MODE_HIDDEN or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = cursor_mode(hidden)
	var vsync := DisplayServer.VSYNC_ENABLED if settings.value(GameSettings.VIDEO, "vsync") else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vsync:
		DisplayServer.window_set_vsync_mode(vsync)
	# The window itself is set up only when its own keys change (GameSettings.WINDOW_KEYS), never on a
	# slider tick, so a window the player dragged stays where it is.
	var keys := GameSettings.window_keys(settings)
	if keys == _window_keys:
		return
	_window_keys = keys
	var root := get_tree().root
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if settings.value(GameSettings.VIDEO, "pixel_perfect") else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	var screen := current_screen()
	if settings.value(GameSettings.VIDEO, "fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		_log_display_if_changed.call_deferred()
		return
	var was_windowed := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
	if not was_windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := window_size(settings)
	var resized := DisplayServer.window_get_size() != size
	if resized:
		DisplayServer.window_set_size(size)
	# Placed only when it changed size or just left fullscreen: centred in the screen's free area and never
	# pushed past its top-left corner, so a window that is still too big loses its bottom-right edge, not
	# the HUD on its left.
	if resized or not was_windowed:
		var area := DisplayServer.screen_get_usable_rect(screen)
		if area.size.x <= 0 or area.size.y <= 0:
			area = Rect2i(DisplayServer.screen_get_position(screen), DisplayServer.screen_get_size(screen))
		var corner := area.position + (area.size - DisplayServer.window_get_size_with_decorations()) / 2
		DisplayServer.window_set_position(Vector2i(maxi(corner.x, area.position.x), maxi(corner.y, area.position.y)))
	_log_display_if_changed.call_deferred()


# F11 or Alt+Enter switches between fullscreen and a window at any time, and keeps the choice.
func _input(event: InputEvent) -> void:
	if is_quiet() or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if GameSettings.is_window_key(key):
		get_viewport().set_input_as_handled()
		# An open Options panel takes the switch into its draft, so OK keeps it and Esc undoes it.
		if not fullscreen_asked.get_connections().is_empty():
			fullscreen_asked.emit()
			return
		var next := current.duplicate_settings()
		next.set_value(GameSettings.VIDEO, "fullscreen", not current.value(GameSettings.VIDEO, "fullscreen"))
		commit(next)


# Writes the display log at startup and whenever the window's mode or size has really changed since.
func _log_display_if_changed() -> void:
	var now := "%d %s" % [DisplayServer.window_get_mode(), DisplayServer.window_get_size()]
	if now == _logged_window:
		return
	_logged_window = now
	_log_display()


# What the game saw of the screens, so a display problem on another PC can be read back from
# user://display_log.txt.
func _log_display() -> void:
	var file := FileAccess.open("user://display_log.txt", FileAccess.WRITE)
	if file == null:
		return
	file.store_line(BuildInfo.label())
	var screen := current_screen()
	file.store_line("screens: %d  current: %d  primary: %d" % [DisplayServer.get_screen_count(), screen, DisplayServer.get_primary_screen()])
	for i in DisplayServer.get_screen_count():
		file.store_line("screen %d: size %s  usable %s  position %s  scale %.2f  dpi %d" % [i, DisplayServer.screen_get_size(i), DisplayServer.screen_get_usable_rect(i), DisplayServer.screen_get_position(i), DisplayServer.screen_get_scale(i), DisplayServer.screen_get_dpi(i)])
	file.store_line("window: mode %d  size %s  with frame %s  position %s" % [DisplayServer.window_get_mode(), DisplayServer.window_get_size(), DisplayServer.window_get_size_with_decorations(), DisplayServer.window_get_position()])
	file.store_line("content scale factor %.2f  choices %s" % [get_tree().root.content_scale_factor, resolution_choices()])
