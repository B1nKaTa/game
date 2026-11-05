class_name CutsceneSteps
extends RefCounted

# The steps a CutscenePlayer plays, as plain dictionaries, and how long a list of them lasts. Every
# ending is a list of these in scripts/content/endings/<id>.gd. Positions are in stage units: the
# stage is VIEW wide and high and drawn at SCALE, so it fills the 640x360 screen. An actor's position
# is where his feet are.

const VIEW := Vector2(320, 180)
const SCALE := 2.0
const CENTER := Vector2(160, 90)
# The line the actors stand on, on most stages. The text box covers the screen below about y = 143.
const GROUND_Y := 128.0
# A line waits this long, plus a little for each letter, unless a press moves it on.
const SAY_TIME := 2.0
const SAY_PER_CHAR := 0.045
const CARD_TIME := 2.4
const CARD_PER_CHAR := 0.04
const WALK_SPEED := 40.0
# How long each one-shot takes.
const ANIM_TIME := {
	"swing": 0.4, "fall": 0.6, "sit_up": 0.6, "shake_fist": 0.8, "faint": 0.6, "float": 1.2,
	"hop": 0.4, "bow": 0.8, "lie": 0.0, "stand": 0.0,
}
const OPS: Array[String] = [
	"stage", "actor", "walk", "face", "anim", "say", "card", "wait", "shake", "zoom", "fade_out",
	"fade_in", "sound", "hide", "tint", "hat", "look",
]
const ENDINGS_DIR := "res://scripts/content/endings/"


static func stage(stage_name: String) -> Dictionary:
	return {"op": "stage", "name": stage_name}


# Places an actor, or moves one already there. facing is 1 for right, -1 for left.
static func actor(id: String, at: Vector2, facing := 1) -> Dictionary:
	return {"op": "actor", "id": id, "at": at, "facing": facing}


# Walks an actor to a point, turned that way. With wait false the next step starts at once.
static func walk(id: String, to: Vector2, speed := WALK_SPEED, wait_for := true) -> Dictionary:
	return {"op": "walk", "id": id, "to": to, "speed": speed, "wait": wait_for}


static func face(id: String, dir: int) -> Dictionary:
	return {"op": "face", "id": id, "dir": dir}


static func anim(id: String, anim_name: String, wait_for := true) -> Dictionary:
	return {"op": "anim", "id": id, "name": anim_name, "wait": wait_for}


static func say(id: String, text: String) -> Dictionary:
	return {"op": "say", "id": id, "text": text}


static func card(text: String) -> Dictionary:
	return {"op": "card", "text": text}


static func wait(seconds: float) -> Dictionary:
	return {"op": "wait", "seconds": seconds}


# Shakes and zooms run behind the steps that follow them.
static func shake(amount: float, seconds: float) -> Dictionary:
	return {"op": "shake", "amount": amount, "seconds": seconds}


static func zoom(factor: float, seconds: float, at := CENTER) -> Dictionary:
	return {"op": "zoom", "factor": factor, "seconds": seconds, "at": at}


static func fade_out(seconds: float) -> Dictionary:
	return {"op": "fade_out", "seconds": seconds}


static func fade_in(seconds: float) -> Dictionary:
	return {"op": "fade_in", "seconds": seconds}


# Plays a sound effect by its SoundBank name, at once. Built in two lines so the sound test, which reads
# what a function named for a sound returns, never takes the step's keys for sound names;
# test_ending_scripts checks the names the scenes use instead.
static func sound(sound_name: String) -> Dictionary:
	var step := {"op": "sound"}
	step["name"] = sound_name
	return step


static func hide(id: String) -> Dictionary:
	return {"op": "hide", "id": id}


# Colours an actor, as a green-tinged or sunburnt Harold. White puts him back.
static func tint(id: String, color: Color) -> Dictionary:
	return {"op": "tint", "id": id, "color": color}


# Puts a hat on an actor's head: any GrandpaLook hat shape, or "" to take it off.
static func hat(id: String, shape: String, color := Color.WHITE) -> Dictionary:
	return {"op": "hat", "id": id, "shape": shape, "color": color}


# Changes how a drawn actor looks, as Gerald down to his vest. "" puts him back.
static func look(id: String, state: String) -> Dictionary:
	return {"op": "look", "id": id, "state": state}


static func say_time(text: String) -> float:
	return SAY_TIME + text.length() * SAY_PER_CHAR


static func card_time(text: String) -> float:
	return CARD_TIME + text.length() * CARD_PER_CHAR


# How long a list of steps lasts with nothing pressed: the steps that wait add their time, and a walk
# its distance from where the actor stands over its speed.
static func duration_of(steps: Array) -> float:
	var total := 0.0
	var at := {}
	for step: Dictionary in steps:
		match step["op"]:
			"actor":
				at[step["id"]] = step["at"]
			"walk":
				var from: Vector2 = at.get(step["id"], step["to"])
				var time := from.distance_to(step["to"]) / maxf(float(step["speed"]), 1.0)
				at[step["id"]] = step["to"]
				if step["wait"]:
					total += time
			"anim":
				if step["wait"]:
					total += float(ANIM_TIME.get(step["name"], 0.0))
			"say":
				total += say_time(step["text"])
			"card":
				total += card_time(step["text"])
			"wait", "fade_out", "fade_in":
				total += float(step["seconds"])
	return total


# An ending's steps, from its script. variant picks Repeat Customer's quick death or Augustine's
# short scene.
static func for_ending(id: String, variant := 0) -> Array:
	var path := ENDINGS_DIR + id + ".gd"
	if not ResourceLoader.exists(path):
		return []
	var script: GDScript = load(path)
	return script.steps(variant)
