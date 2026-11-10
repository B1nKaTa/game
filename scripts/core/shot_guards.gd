class_name ShotGuards
extends RefCounted

# Whatever stops an enemy's shot (a Projectile) short of Harold: Joey the Budgie, Shelley, the moths, a big
# Pet Rock, Loose Paperwork's sheets and the Walking Frame. Each is a node in GROUP with
# blocks_shot(at) -> bool, which spends what it had when it says yes. Ground strikes, blasts and lanes
# are no shots, so nothing here stops them.

const GROUP := "shot_guards"


# counting_pills is the full loop's switch (EffectContext.counting_pills): while it is set nothing blocks
# and nothing is spent, so no guard needs to check it itself.
static func try_block(tree: SceneTree, at: Vector2, counting_pills := false) -> bool:
	if tree == null:
		return false
	return try_block_in(tree.get_nodes_in_group(GROUP), at, counting_pills)


# The same for these nodes (a test hands it its own, since its root is not in a started tree).
static func try_block_in(nodes: Array, at: Vector2, counting_pills := false) -> bool:
	if counting_pills:
		return false
	for node: Node in nodes:
		if node.is_queued_for_deletion() or not node.has_method("blocks_shot"):
			continue
		if node.blocks_shot(at):
			return true
	return false
