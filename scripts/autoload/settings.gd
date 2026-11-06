extends Node

# The live settings and everything that applies them: the window, the audio buses, the adjustment
# layer and the language. The rules live on GameSettings, which tests reach. The full loop (--smoke)
# and test runs (--script) read nothing and write nothing, so they always play on the defaults.

signal changed

const PATH := "user://settings.cfg"

var current := GameSettings.new()
var _adjust: AdjustLayer


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
	return GameSettings.resolutions_for(DisplayServer.screen_get_size())


# The window size the settings ask for: the chosen one if it still fits, otherwise the best fit.
func window_size(settings: GameSettings) -> Vector2i:
	var choices := resolution_choices()
	var wanted := GameSettings.parse_resolution(settings.value(GameSettings.VIDEO, "resolution"))
	return wanted if choices.has(wanted) else choices[-1]


func _apply_video(settings: GameSettings) -> void:
	# A mouse mode already set by a scene is kept, only its confinement follows the option.
	var hidden := Input.mouse_mode == Input.MOUSE_MODE_HIDDEN or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN
	Input.mouse_mode = cursor_mode(hidden)
	var root := get_tree().root
	root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER if settings.value(GameSettings.VIDEO, "pixel_perfect") else Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.value(GameSettings.VIDEO, "vsync") else DisplayServer.VSYNC_DISABLED)
	if settings.value(GameSettings.VIDEO, "fullscreen"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var size := window_size(settings)
	if DisplayServer.window_get_size() != size:
		DisplayServer.window_set_size(size)
		var screen := DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() - size) / 2
		DisplayServer.window_set_position(screen)
