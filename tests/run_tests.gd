extends SceneTree

const TEST_DIR := "res://tests/"


func _initialize() -> void:
	var ran := 0
	var failed := 0
	var files := DirAccess.get_files_at(TEST_DIR)
	files.sort()
	for file in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")):
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
