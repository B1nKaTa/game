extends TestCase


func test_the_layer_sits_above_everything_and_lets_clicks_through() -> void:
	var layer := AdjustLayer.new()
	layer._ready()
	assert_eq(layer.layer, AdjustLayer.LAYER)
	assert_true(AdjustLayer.LAYER >= 100, "above every panel")
	assert_eq(layer.rect().mouse_filter, Control.MOUSE_FILTER_IGNORE)
	layer.free()


func test_neutral_levels_hide_the_layer() -> void:
	var layer := AdjustLayer.new()
	layer._ready()
	layer.set_levels(0, 0, 0)
	assert_false(layer.visible)
	layer.set_levels(10, 0, 0)
	assert_true(layer.visible)
	var material := layer.rect().material as ShaderMaterial
	assert_near(material.get_shader_parameter("brightness"), GameSettings.brightness_offset(10))
	assert_near(material.get_shader_parameter("contrast"), 1.0)
	assert_near(material.get_shader_parameter("gamma"), 1.0)
	layer.free()


func test_the_buses_exist_once() -> void:
	GameSettings.ensure_buses()
	GameSettings.ensure_buses()
	for bus: String in GameSettings.BUSES:
		var index := AudioServer.get_bus_index(bus)
		assert_true(index > 0, bus)
		assert_eq(String(AudioServer.get_bus_send(index)), "Master", bus)
	var count := 0
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == "Effects":
			count += 1
	assert_eq(count, 1)
