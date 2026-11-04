extends SfxPool

# The game's one sound pool (Sfx reaches it by name), and the menus' own sounds: every button ticks
# as focus or the mouse comes to it and confirms when pressed, and a press on a disabled one is
# refused aloud. A button that makes its own sound sets the meta "sfx" to that sound, or to "" for
# none, and "sfx_denied" for its own refusal. The full loop and test runs play nothing.

const PRESS_META := "sfx"
const DENIED_META := "sfx_denied"


# Set at once, not in _ready, since test runs ask for sounds before the tree has started.
func _init() -> void:
	quiet = OS.get_cmdline_user_args().has("--smoke") or OS.get_cmdline_args().has("--script")


func _ready() -> void:
	super._ready()
	get_tree().node_added.connect(_on_node_added)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _on_node_added(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta(&"sfx_hooked"):
		return
	button.set_meta(&"sfx_hooked", true)
	button.pressed.connect(_on_pressed.bind(button))
	button.mouse_entered.connect(_on_hovered.bind(button))
	button.gui_input.connect(_on_button_input.bind(button))


func _on_focus_changed(control: Control) -> void:
	if control is BaseButton or control is Slider:
		play("ui_move")


func _on_hovered(button: BaseButton) -> void:
	if is_instance_valid(button) and not button.disabled:
		play("ui_move")


func _on_pressed(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return
	play(str(button.get_meta(PRESS_META, "ui_confirm")))


# A disabled button sends no pressed, so its click or key press is caught here.
func _on_button_input(event: InputEvent, button: BaseButton) -> void:
	if not is_instance_valid(button) or not button.disabled:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		play(str(button.get_meta(DENIED_META, "ui_denied")))
