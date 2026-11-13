class_name BuildInfo
extends RefCounted

# Which build this is, so a bug report can name it: the short commit and the day it was made. The game
# cannot ask git, so tools/stamp_build.ps1 writes res://build_info.txt before every export (it is
# gitignored and listed in export_presets.cfg's include_filter). In the editor, tests and probes the
# file is missing, and the build reads as "dev".

const PATH := "res://build_info.txt"
const DEV := "dev"
# Shown after the build id in a playtest export (the "Windows Playtest" preset's feature tag), so a
# build with the tester panel in it is never taken for a release.
const PLAYTEST_MARK := "PLAYTEST"

static var _label := ""


# The build id shown on the title screen, the pause menu and the first line of display_log.txt.
static func label() -> String:
	if _label.is_empty():
		_label = marked(read(PATH), OS.has_feature(DevStart.PLAYTEST_FEATURE))
	return _label


static func marked(label_text: String, playtest: bool) -> String:
	return "%s  %s" % [label_text, PLAYTEST_MARK] if playtest else label_text


static func read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return DEV
	return parse(FileAccess.get_file_as_string(path))


# Reads "commit=291126a" and "date=2026-11-08" lines, in any order, and gives "build 291126a (2026-11-08)".
# A missing or odd commit gives "dev"; a missing or odd date is left out. The pixel font has no middle
# dot, so the date goes in brackets.
static func parse(text: String) -> String:
	var commit := ""
	var date := ""
	for line in text.split("\n"):
		var parts := line.strip_edges().split("=", true, 1)
		if parts.size() != 2:
			continue
		var value := parts[1].strip_edges()
		match parts[0].strip_edges():
			"commit":
				commit = value.to_lower()
			"date":
				date = value
	if not _is_commit(commit):
		return DEV
	if not _is_date(date):
		return "build %s" % commit
	return "build %s (%s)" % [commit, date]


static func _is_commit(text: String) -> bool:
	if text.length() < 4 or text.length() > 40:
		return false
	for character in text:
		if not "0123456789abcdef".contains(character):
			return false
	return true


static func _is_date(text: String) -> bool:
	var parts := text.split("-")
	if text.length() != 10 or parts.size() != 3:
		return false
	for part in parts:
		if not part.is_valid_int():
			return false
	return parts[0].length() == 4 and parts[1].length() == 2 and parts[2].length() == 2
