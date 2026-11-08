class_name TitleFrames
extends RefCounted

# Written by tools/art/title_art.py; do not edit by hand. The title screen's strips in art/title/:
# seated Harold (64 px frames, facing south-west) with the first frame and length of each idle, the
# head anchor a hat is drawn round (GrandpaLook.draw_hat) and the Power Tie's knot (draw_tie), both
# from the frame's top-left; and the ghosts' 64 px frames.

const HAROLD_SIZE := 64
const HAROLD_FRAMES := 25
const HAROLD_REST := 0
const HAROLD_ANIMS := {"cane_tap": [1, 8], "ticket_check": [9, 8], "sigh": [17, 8]}
const HAROLD_FEET_ROW := 53
const HAROLD_HEAD: Array[Vector2] = [Vector2(33, 22), Vector2(33, 22), Vector2(34, 21), Vector2(35, 21), Vector2(35, 20), Vector2(35, 20), Vector2(35, 20), Vector2(35, 20), Vector2(35, 20), Vector2(32.5, 23), Vector2(34, 20), Vector2(35, 20), Vector2(35, 20), Vector2(35, 20), Vector2(34, 20), Vector2(34.5, 21), Vector2(34, 21), Vector2(32, 22), Vector2(33.5, 21), Vector2(36, 20), Vector2(37, 20), Vector2(37, 20), Vector2(35, 20), Vector2(34, 21), Vector2(33, 22)]
const HAROLD_TIE: Array[Vector2] = [Vector2(30, 31), Vector2(30, 31), Vector2(31, 30), Vector2(30.5, 30), Vector2(32, 29), Vector2(32, 29), Vector2(32, 29), Vector2(32, 29), Vector2(32, 29), Vector2(30.5, 34), Vector2(32, 29), Vector2(30.5, 29), Vector2(30.5, 29), Vector2(31.5, 29), Vector2(32, 29), Vector2(31, 30), Vector2(31.5, 30), Vector2(29.5, 31), Vector2(30.5, 30), Vector2(32.5, 30), Vector2(33.5, 31), Vector2(33, 30), Vector2(32, 30), Vector2(31.5, 30), Vector2(30.5, 31)]
# Where he sits in each frame: across, his body's middle; down, the underside of his thighs. TitleRoom puts this
# point on his chair's seat line in every frame.
const HAROLD_SIT: Array[Vector2] = [Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 45), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 46), Vector2(33, 45), Vector2(33, 45), Vector2(33, 47), Vector2(33, 47), Vector2(33, 47), Vector2(33, 47), Vector2(33, 45), Vector2(33, 45)]
# Cardigans drawn as outfits of the seated strip, as GrandpaLook.outfit_art builds them for play.
const OUTFITS: Array[String] = ["bingo_teal", "burgundy_cardigan", "mustard_cardigan"]

const GHOST_SIZE := 64
const GHOST_FRONT := 0
const GHOST_TURNED := 1
const GHOST_ANIMS := {"talk": [2, 8], "cross_legs": [10, 8], "shift": [18, 8], "stand_up": [26, 8]}
const GHOST_HOVER := 34
const GHOST_DRIFT := 35
const GHOST_FRAMES := 36
# Each ghost's top row and lowest row in its seated front frame (its head and dangling feet).
const GHOST_ROWS := {"ghost_a": Vector2i(12, 49), "ghost_b": Vector2i(12, 53)}
# Where each ghost sits in each frame: the middle of the bottom of its body, above its hanging legs.
const GHOST_SIT := {"ghost_a": [Vector2(31, 45), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(32, 46), Vector2(31, 46), Vector2(32.5, 47), Vector2(32, 47), Vector2(32.5, 46), Vector2(32, 46), Vector2(32, 46), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(35, 47), Vector2(34.5, 47), Vector2(35, 47), Vector2(35, 47), Vector2(31, 45), Vector2(30.5, 46), Vector2(31, 45), Vector2(31, 41), Vector2(31, 41), Vector2(31, 41), Vector2(31, 41), Vector2(31, 45), Vector2(32.5, 45), Vector2(31.5, 45)], "ghost_b": [Vector2(32, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(35, 46), Vector2(34.5, 46), Vector2(35, 46), Vector2(33.5, 46), Vector2(30.5, 44), Vector2(31.5, 44), Vector2(32.5, 44), Vector2(32.5, 45), Vector2(32.5, 45), Vector2(34.5, 46), Vector2(35, 45), Vector2(35, 44), Vector2(34, 44), Vector2(37, 46), Vector2(38, 46), Vector2(34.5, 45), Vector2(35, 46), Vector2(32, 45), Vector2(32, 44), Vector2(32, 42), Vector2(32, 41), Vector2(32, 40), Vector2(32, 42), Vector2(32, 42), Vector2(32, 44), Vector2(32, 46), Vector2(30.5, 45)]}

# The chair (art/title/chair.png, its legs cut by LEG_CUT): the row its sitters sit on, and its feet.
const CHAIR_SEAT_ROW := 27
const CHAIR_FEET_ROW := 35
