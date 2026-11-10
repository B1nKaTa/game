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
# Reads the bank's Pension. Set by the scene; tests wire it to the kit.
var pension_balance := Callable()
# Listeners for tests and probes. Each gets the same arguments as the call it is named after.
var on_notice := Callable()
var on_fx := Callable()
var on_sound := Callable()
var on_drop := Callable()
# Tests answer fetch_pickup and copy_pickup through these; in play the room does.
var fetcher := Callable()
var copier := Callable()
var on_slow_time := Callable()
# Where enemies come from when there is no room in the tree, as in tests: returns an Array of Enemy.
var enemy_source := Callable()
# Set by the full-loop check, whose fight checks count every pill a hit costs and every pill a heal
# gives: while it is set, items neither block, soften, nor soak a hit, heal, nor drop a heal. Each of
# those rules has its own unit test.
var counting_pills := false
# Set by the full loop too, whose checks count Pension, Slips, damage and Thermos fuses exactly: while
# it is set, items pay nothing, keep no Slip, change no damage, fuse, shop or Arcade table, and lay no
# burning puddle. Each of those rules has its own unit test.
var counting_exact := false
# Set by the full loop too, whose checks count pills with him standing in and beside enemies: while it
# is set, walking into a body costs nothing. Its own contact check clears it. See ContactRule.
var contact_off := false
# Where he stood on walking into the room he is in, by its door. FloorScene sets it on every arrival.
var arrival := Vector2.ZERO
var has_arrival := false
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
	if state != null and pills > 0 and not counting_pills:
		state.health.heal(pills)


# Half a pill. Two halves make a pill; a half left over waits for the next.
func heal_half() -> void:
	var state := run()
	if state != null and not counting_pills:
		state.health.heal_half()


# Tells every held item that something happened, as a BINGO (RunEffects.EVENT_BINGO).
func event(event_name: String) -> void:
	var state := run()
	if state != null:
		state.effects.event(event_name)


# Pension straight into the save, counted as the run's earnings, as a coin would be.
func pay(amount: int) -> void:
	if amount > 0 and not counting_exact and pay_pension.is_valid():
		pay_pension.call(amount)


# Takes Pension from the save. Never below zero: false when he cannot cover it.
func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if spend_pension.is_valid():
		return bool(spend_pension.call(amount))
	return false


# The Pension this run brought in and still has: the bank above what it held when the run began, never
# below zero or above the bank. "Pension you carry" on an item means this.
func purse() -> int:
	var state := run()
	if state == null or not pension_balance.is_valid():
		return 0
	var balance := maxi(int(pension_balance.call()), 0)
	return clampi(balance - state.pension_at_start, 0, balance)


func spend_from_purse(amount: int) -> bool:
	if amount <= 0:
		return true
	if purse() < amount:
		return false
	return spend(amount)


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


# Holds an enemy still for a while, stars over its head.
func stun(enemy: Enemy, seconds: float) -> void:
	if enemy != null and is_instance_valid(enemy):
		enemy.stun(seconds)


# A small pickup lying in the room: one of RoomRules.DROP_KEY, DROP_BOMB, DROP_POTION, DROP_COIN or
# DROP_HEAL. For a coin, amount is its Pension; for a heal, its pills.
func drop(kind: String, at: Vector2, amount := 1, id := "") -> void:
	if counting_pills and kind == RoomRules.DROP_HEAL:
		return
	if counting_exact and kind == RoomRules.DROP_COIN:
		return
	if on_drop.is_valid():
		on_drop.call(kind, at)
	if has_room():
		room.drop_for_item(kind, at, amount, id)


# A free item lying in the room at a spot (Lottery Scratcher's rare prize), promised so nothing else
# offers it. Listeners hear it as the kind "item".
func drop_item(item: ItemDef, at: Vector2) -> void:
	if on_drop.is_valid():
		on_drop.call("item", at)
	if has_room():
		room.drop_free_item(item, at)


# Calls the nearest waiting coin, Slip or Thermos to him (Racing Pigeon). Returns whether one came.
func fetch_pickup() -> bool:
	if fetcher.is_valid():
		return bool(fetcher.call())
	return has_room() and room.fetch_nearest_pickup(feet())


# Lays a copy of the waiting pickup nearest him (Photocopier). Returns whether one was copied.
func copy_pickup() -> bool:
	if copier.is_valid():
		return bool(copier.call())
	return has_room() and room.copy_nearest_pickup(feet())


# Half a pill off him (Unpaid Bill), never his last. Nothing while the full loop counts pills.
func lose_half() -> bool:
	var state := run()
	if state == null or counting_pills:
		return false
	return state.health.lose_half(true)


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


# Puts him back where he walked into this room, by its door, and makes the room's doors wait until he
# steps off them again, so standing on one does not walk him through it.
func return_to_door() -> void:
	if has_player() and has_arrival:
		player.global_position = arrival
		player.end_push()
	if has_room():
		room.rearm_doors()


func is_landing() -> bool:
	return is_instance_valid(room) and room.room_type() == RoomLayout.TYPE_LANDING
