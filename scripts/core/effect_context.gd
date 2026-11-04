class_name EffectContext
extends RefCounted

# The one window item effects have on the game. FloorScene and the Waiting Room fill in what they have;
# tests leave the nodes null and listen through the on_ callables instead. The run is held weakly,
# since the run owns its RunEffects, which owns this, and a strong hold would close a reference cycle.

var player: Player
# The room Grandpa stands in. FloorScene sets it on every room entered.
var room: RoomView
var hud: Hud
var feedback: CombatFeedback
# What pays Pension into the save and counts it as earned by the run, and what spends it. Set by the
# scene. pay_pension takes an int; spend_pension takes an int and returns whether it was spent.
var pay_pension := Callable()
var spend_pension := Callable()
# Listeners for tests and probes. Each gets the same arguments as the call it is named after.
var on_notice := Callable()
var on_fx := Callable()
var on_sound := Callable()
var on_drop := Callable()
var on_slow_time := Callable()
# Where enemies come from when there is no room in the tree, as in tests: returns an Array of Enemy.
var enemy_source := Callable()
var _run_ref: WeakRef


func _init(run_state: RunState = null) -> void:
	_run_ref = weakref(run_state) if run_state != null else null


func run() -> RunState:
	return _run_ref.get_ref() if _run_ref != null else null


func has_player() -> bool:
	return is_instance_valid(player) and player.is_inside_tree()


func has_room() -> bool:
	return is_instance_valid(room) and room.is_inside_tree()


func notice(text: String) -> void:
	if is_instance_valid(hud):
		hud.show_notice(text)
	if on_notice.is_valid():
		on_notice.call(text)


func heal(pills: int) -> void:
	var state := run()
	if state != null and pills > 0:
		state.health.heal(pills)


# Pension straight into the save, counted as the run's earnings, as a coin would be.
func pay(amount: int) -> void:
	if amount > 0 and pay_pension.is_valid():
		pay_pension.call(amount)


# Takes Pension from the save. Never below zero: false when he cannot cover it.
func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if spend_pension.is_valid():
		return bool(spend_pension.call(amount))
	return false


# Every living enemy in the room.
func enemies() -> Array[Enemy]:
	var found: Array[Enemy] = []
	var raw: Array = []
	if enemy_source.is_valid():
		raw = enemy_source.call()
	elif has_player():
		raw = player.get_tree().get_nodes_in_group("enemies")
	for node in raw:
		var enemy := node as Enemy
		if enemy != null and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_dead():
			found.append(enemy)
	return found


func enemies_near(at: Vector2, radius: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for enemy in enemies():
		if enemy.global_position.distance_to(at) <= radius:
			found.append(enemy)
	return found


# A hit of his own from an item. It runs through the same hooks as a swing, one level deep.
func hit_enemy(enemy: Enemy, amount: float, source := RunEffects.ITEM, push := Vector2.ZERO) -> bool:
	var state := run()
	if state == null or enemy == null:
		return false
	return state.effects.land(enemy, amount, source, push)


func stun(enemy: Enemy, seconds: float) -> void:
	if enemy != null and is_instance_valid(enemy):
		enemy.daze(seconds)


# A small pickup lying in the room: one of RoomRules.DROP_KEY, DROP_BOMB, DROP_POTION or DROP_COIN.
func drop(kind: String, at: Vector2, amount := 1) -> void:
	if on_drop.is_valid():
		on_drop.call(kind, at)
	if has_room():
		room.drop_for_item(kind, at, amount)


# Puts an ItemFx node (or any effect node) into the room at a spot. Without a room the node is freed,
# after any listener has seen it. Returns the node when it was placed.
func add_fx(node: Node2D, at: Vector2) -> Node2D:
	if on_fx.is_valid():
		on_fx.call(node)
	var parent: Node = room if has_room() else (player.get_parent() if has_player() else null)
	if parent == null:
		node.free()
		return null
	parent.add_child(node)
	node.global_position = at
	return node


# Where his feet stand, or the origin when he is not in a scene.
func feet() -> Vector2:
	if has_player():
		return player.feet().global_position
	return Vector2.ZERO


# Game time runs at this share for so many real seconds.
func slow_time(time_share: float, real_seconds: float) -> void:
	if on_slow_time.is_valid():
		on_slow_time.call(time_share, real_seconds)
	if is_instance_valid(feedback):
		feedback.slow_time(time_share, real_seconds)


func play_sound(sound_name: String) -> void:
	if on_sound.is_valid():
		on_sound.call(sound_name)
	if is_instance_valid(feedback):
		feedback.play(sound_name)


func is_landing() -> bool:
	return is_instance_valid(room) and room.room_type() == RoomLayout.TYPE_LANDING
