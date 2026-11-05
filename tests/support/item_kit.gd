class_name ItemKit
extends RefCounted

# Helpers for item tests: a run holding real shipped items, with its EffectContext's listeners
# recording what effects did. Keep the kit alive for the whole test (a local is enough), since the
# context's callables point at its methods and do not keep it alive themselves.

const ENEMY_DIR := "res://data/enemies/"

var notices: Array[String] = []
# Each fx an effect placed: {"script": its class, "text": a pop's words}. Out of a room the node
# itself is freed at once, so only this is kept.
var fx: Array[Dictionary] = []
var sounds: Array[String] = []
var drops: Array = []
var slows: Array = []
var paid := 0
var spent := 0
# What spend can take from, as the save's Pension.
var pension := 0
# The enemies effects see through ctx.enemies(). Free them with free_enemies() at the end.
var enemies: Array = []


# A run with no forms, wired to this kit.
func make_run() -> RunState:
	var none: Array[UpgradeDef] = []
	var run := RunState.new(none, {})
	wire(run)
	return run


# A run holding the shipped items with these ids, taken in this order.
func run_with(ids: Array) -> RunState:
	var run := make_run()
	for id: String in ids:
		run.add_item(item(id))
	return run


static func item(id: String) -> ItemDef:
	for def in Content.items():
		if def.id == id:
			return def
	push_error("No shipped item %s" % id)
	return null


func wire(run: RunState) -> void:
	var ctx := run.effects.ctx
	ctx.on_notice = _on_notice
	ctx.on_fx = _on_fx
	ctx.on_sound = _on_sound
	ctx.on_drop = _on_drop
	ctx.on_slow_time = _on_slow
	ctx.pay_pension = _on_pay
	ctx.spend_pension = _on_spend
	ctx.enemy_source = _enemy_list


# An enemy out of the tree, as tests use them. hp overrides its health when above zero.
func enemy(def_id := "intern_reaper", hp := 0.0) -> Enemy:
	var made := Enemy.new()
	made.setup(load(ENEMY_DIR + def_id + ".tres"), null, 0.5)
	if hp > 0.0:
		made.hp = hp
	enemies.append(made)
	return made


func free_enemies() -> void:
	for made in enemies:
		if is_instance_valid(made):
			made.free()
	enemies.clear()


# The fx placed of one ItemFx class, such as ItemFx.FxPop.
func fx_of(kind: Script) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry in fx:
		if entry["script"] == kind:
			found.append(entry)
	return found


func _enemy_list() -> Array:
	return enemies


func _on_notice(text: String) -> void:
	notices.append(text)


func _on_fx(node: Node2D) -> void:
	fx.append({"script": node.get_script(), "text": str(node.get("text")) if "text" in node else ""})


func _on_sound(sound_name: String) -> void:
	sounds.append(sound_name)


func _on_drop(kind: String, at: Vector2) -> void:
	drops.append([kind, at])


func _on_slow(share: float, seconds: float) -> void:
	slows.append([share, seconds])


func _on_pay(amount: int) -> void:
	paid += amount


func _on_spend(amount: int) -> bool:
	if pension < amount:
		return false
	pension -= amount
	spent += amount
	return true
