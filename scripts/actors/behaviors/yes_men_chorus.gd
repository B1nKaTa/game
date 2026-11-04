class_name YesMenChorus
extends RefCounted

# Three Yes-Men agree with one another. Whenever one of them starts a warned lunge, the chorus hears
# of it once, and every other member starts the same warned lunge half a beat later, each down its own
# lane toward Grandpa. An echo never leads another, so one lunge is never copied twice.
const META := &"yes_men_chorus"
const SIZE := 3
# Yes-Men this close that have no chorus yet join one, as summoned ones do.
const GATHER_REACH := 160.0
const ECHO_DELAY := 0.3

var members: Array[Enemy] = []
# Each lead counts up once, so every member sees each exactly once.
var leads := 0
# Who led the last lunge, by instance id, so a leader that has since fallen is never touched.
var last_leader_id := 0


# How long after a lunge starts a member starts its own: at once for the one who led, half a beat
# later for the rest.
static func echo_delay(is_leader: bool) -> float:
	return 0.0 if is_leader else ECHO_DELAY


# A chorus around a Yes-Man that has none yet: itself and the nearest of its kind with no chorus
# either, up to SIZE in all.
static func gather(enemy: Enemy) -> YesMenChorus:
	var chorus := YesMenChorus.new()
	chorus.members.append(enemy)
	enemy.set_meta(META, chorus)
	if not enemy.is_inside_tree():
		return chorus
	var near: Array = []
	for other: Enemy in enemy.get_tree().get_nodes_in_group("enemies"):
		if other == enemy or other.is_dead() or other.def != enemy.def or other.has_meta(META):
			continue
		var distance := other.global_position.distance_to(enemy.global_position)
		if distance <= GATHER_REACH:
			near.append([distance, other])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for entry: Array in near:
		if chorus.members.size() >= SIZE:
			break
		var joining: Enemy = entry[1]
		chorus.members.append(joining)
		joining.set_meta(META, chorus)
	return chorus


# A member starts a lunge of its own. The others will copy it.
func lead(enemy: Enemy) -> void:
	leads += 1
	last_leader_id = enemy.get_instance_id()


func place_of(enemy: Enemy) -> int:
	return maxi(members.find(enemy), 0)


func living() -> int:
	var count := 0
	for member in members:
		if is_instance_valid(member) and not member.is_dead():
			count += 1
	return count
