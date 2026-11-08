class_name TitleBrand
extends RefCounted

# The game's name and the lines under it, in one place: the title screen's brass plaque reads these,
# so a change of name is a change here. NAME is drawn in the plaque's block letters (TitlePlaque.GLYPHS
# holds A to Z, 0 to 9 and a few marks); the subtitle and tagline use the pixel font.

const NAME := "RIP"
const SUBTITLE := "Retirement in Progress"
const TAGLINE := "Please take a number."
# The whole name in one line, as the credits show it.
const FULL_NAME := NAME + ": " + SUBTITLE
# Harold's ticket on the title screen. The NOW SERVING board never reaches it (NowServing).
const HAROLD_TICKET := 42
