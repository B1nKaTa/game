extends TestCase


func test_nothing_is_served_before_its_time() -> void:
	var queue := TitleQueue.new(41)
	assert_false(queue.tick(TitleQueue.SERVE_TIME - 0.1))
	assert_eq(queue.now_serving, 41)


func test_serving_ticks_the_sign_and_moves_the_line_up() -> void:
	var queue := TitleQueue.new(41)
	var front: int = queue.souls[0]
	var second: int = queue.souls[1]
	assert_true(queue.tick(TitleQueue.SERVE_TIME + 0.01))
	assert_eq(queue.now_serving, 42)
	assert_eq(queue.souls[0], second, "everyone steps forward")
	assert_eq(queue.souls[-1], front, "the one served takes a number again at the back")
	assert_eq(queue.souls.size(), TitleQueue.LINE_LENGTH)


func test_the_shuffle_plays_out_after_a_serve() -> void:
	var queue := TitleQueue.new(1)
	assert_near(queue.shuffle(), 1.0, "standing still at the start")
	queue.tick(TitleQueue.SERVE_TIME + 0.01)
	assert_true(queue.shuffle() < 0.1, "a step has just begun")
	queue.tick(TitleQueue.SHUFFLE_TIME)
	assert_near(queue.shuffle(), 1.0)


func test_grandpa_stands_in_the_line() -> void:
	var queue := TitleQueue.new(1)
	assert_true(queue.souls.has(TitleQueue.GRANDPA))
	assert_true(queue.souls.find(TitleQueue.GRANDPA) > 0, "not at the very front")


func test_every_soul_holds_a_ticket_in_line_order() -> void:
	var queue := TitleQueue.new(10)
	for i in queue.souls.size() - 1:
		assert_true(queue.ticket_of(queue.souls[i]) < queue.ticket_of(queue.souls[i + 1]))
	assert_eq(queue.ticket_of(queue.souls[0]), 10, "the front soul's number is the one served")
	queue.tick(TitleQueue.SERVE_TIME + 0.01)
	assert_eq(queue.ticket_of(queue.souls[0]), 11)
	assert_eq(queue.ticket_of(queue.souls[-1]), 10 + TitleQueue.LINE_LENGTH, "a new number from the machine")
