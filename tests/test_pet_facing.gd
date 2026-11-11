extends TestCase

# A pet faces the way it last moved sideways: right to start, left after a leftward walk or lunge, and a
# purely vertical move keeps whichever way it faced.


func _pet_following(at: Vector2, pet_at: Vector2) -> Array:
	var owner_node := Node2D.new()
	owner_node.global_position = at
	var pet := Pet.make("rex", Color("8a5a2b"), 0)
	pet.follow = owner_node
	pet.global_position = pet_at
	return [pet, owner_node]


func _free_all(nodes: Array) -> void:
	for node: Node in nodes:
		node.free()


func test_a_new_pet_faces_right() -> void:
	var pet := Pet.make("rex", Color.WHITE, 0)
	assert_eq(pet.facing, 1)
	pet.free()


func test_a_pet_walking_right_faces_right_and_left_faces_left() -> void:
	var nodes := _pet_following(Vector2(300, 100), Vector2(100, 100) + Pet.slot_offset(0))
	var pet: Pet = nodes[0]
	pet._process(0.1)
	assert_eq(pet.facing, 1, "it walked right")
	nodes[1].global_position = Vector2(-300, 100)
	pet._process(0.1)
	assert_eq(pet.facing, -1, "it walked left")
	_free_all(nodes)


func test_a_purely_vertical_move_keeps_the_facing() -> void:
	var nodes := _pet_following(Vector2(100, 100), Vector2(100, 100) + Pet.slot_offset(0))
	var pet: Pet = nodes[0]
	pet.facing = -1
	var home_spot := pet.home()
	pet.global_position = home_spot + Vector2(0, 80)
	pet._process(0.1)
	assert_true(pet.global_position.y < home_spot.y + 80.0, "it moved up")
	assert_near(pet.global_position.x, home_spot.x)
	assert_eq(pet.facing, -1, "still facing left")
	pet.facing = 1
	pet.global_position = home_spot - Vector2(0, 80)
	pet._process(0.1)
	assert_eq(pet.facing, 1, "still facing right")
	_free_all(nodes)


func test_a_lunge_to_the_left_turns_it() -> void:
	var nodes := _pet_following(Vector2(200, 100), Vector2(200, 100))
	var pet: Pet = nodes[0]
	pet.global_position = Vector2(200, 100)
	pet.lunge_to(Vector2(120, 100))
	assert_eq(pet.facing, -1, "turns at once")
	pet.lunge_to(Vector2(260, 100))
	assert_eq(pet.facing, 1, "and back")
	_free_all(nodes)

func test_an_orbiting_pet_faces_its_circle_not_his_steps() -> void:
	var nodes := _pet_following(Vector2(100, 100), Vector2(100, 100))
	var pet: Pet = nodes[0]
	pet.orbit_speed = 2.0
	pet.orbit_angle = 0.2
	pet._process(0.016)
	assert_eq(pet.facing, -1, "low on the right of its circle it is moving left")
	var turns := 0
	var was := pet.facing
	for i in 20:
		# He steps 2 px left and right in turn, against and with the circle: the moth must not follow that.
		nodes[1].global_position.x += 2.0 if i % 2 == 0 else -2.0
		pet._process(0.016)
		if pet.facing != was:
			turns += 1
			was = pet.facing
	assert_eq(turns, 0, "his steps never flip it within a third of a second")
	pet.orbit_angle = PI + 0.2
	pet._process(0.016)
	assert_eq(pet.facing, 1, "on the far side of the circle it moves right")
	_free_all(nodes)
