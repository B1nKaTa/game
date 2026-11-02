class_name TestCase
extends RefCounted

var failures: PackedStringArray = []


func assert_true(value: bool, message := "") -> void:
	if not value:
		failures.append("expected true: %s" % message)


func assert_false(value: bool, message := "") -> void:
	if value:
		failures.append("expected false: %s" % message)


func assert_eq(actual: Variant, expected: Variant, message := "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected %s, got %s: %s" % [str(expected), str(actual), message])


func assert_near(actual: float, expected: float, message := "") -> void:
	if absf(actual - expected) > 0.001:
		failures.append("expected about %f, got %f: %s" % [expected, actual, message])
