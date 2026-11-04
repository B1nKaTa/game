extends SceneTree

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	var ran := 0
	var failed := 0
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	# `-- --only=name` runs only the test files whose names hold that text, for a quick check.
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
			continue
		if not only.is_empty() and not file.contains(only):
			continue
		var script: GDScript = load(TEST_DIR + file)
		if script == null or not script.can_instantiate():
			print("FAIL %s: could not load" % file)
			failed += 1
			continue
		var instance = script.new()
		for method in instance.get_method_list():
			var method_name: String = method["name"]
			if not method_name.begins_with("test_"):
				continue
			instance.failures.clear()
			instance.call(method_name)
			ran += 1
			if instance.failures.is_empty():
				continue
			failed += 1
			print("FAIL %s.%s" % [file, method_name])
			for failure in instance.failures:
				print("  " + failure)
	print("%d tests, %d failed" % [ran, failed])
	quit(1 if failed > 0 or ran == 0 else 0)
