class_name Sfx
extends RefCounted

# The one way the game asks for a sound: Sfx.play("coin"). It reaches the Sounds autoload through
# the tree, so any script can call it, including those that tests load, and nothing happens when no
# Sounds node is there. Names are SoundBank.NAMES.

const NODE := "Sounds"


static func pool() -> SfxPool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(NODE) as SfxPool


static func play(sound_name: String, pitch := 1.0) -> void:
	var sounds := pool()
	if sounds != null:
		sounds.play(sound_name, pitch)


static func play_later(sound_name: String, delay: float, pitch := 1.0) -> void:
	var sounds := pool()
	if sounds != null:
		sounds.play_later(sound_name, delay, pitch)


static func cancel_later() -> void:
	var sounds := pool()
	if sounds != null:
		sounds.cancel_later()


static func blip(voice_id: String) -> void:
	var sounds := pool()
	if sounds != null:
		sounds.blip(voice_id)
