extends TestCase


# Old Harold's three-swing combo, read from the combo itself.
func _old_combo() -> float:
	var total := 0.0
	for d in CaneCombo.DAMAGE:
		total += d
	return total


func _player_source() -> String:
	return FileAccess.get_file_as_string("res://scripts/actors/player.gd")


func test_old_harold_has_no_era_moves() -> void:
	assert_true(EraMoves.for_era("") == null)
	assert_true(EraMoves.for_era("moon_landing_1969") == null)


func test_each_era_plays_differently() -> void:
	var kick := EraMoves.for_era(Eras.FOOTBALL)
	var punch := EraMoves.for_era(Eras.BUS)
	assert_eq(kick.combo_damage.size(), 3, "a three-kick combo")
	assert_eq(punch.combo_damage.size(), 1, "one heavy punch")
	assert_true(kick.reach < Player.ATTACK_REACH, "short kicks")
	assert_true(punch.reach > Player.ATTACK_REACH, "a long punch")
	assert_true(punch.push > Player.ATTACK_PUSH * 1.5, "strong knockback")
	assert_true(kick.lock_time < CaneCombo.LOCK_TIME and punch.lock_time > CaneCombo.LOCK_TIME)
	assert_true(kick.dodge_hit_damage > 0.0 and punch.dodge_hit_damage > 0.0, "the spin and the barge both hit")
	assert_true(punch.dodge_stun > 0.0 and kick.dodge_stun == 0.0, "only the barge knocks them down")


# The same damage per second within 15%, before the bot checks it in play.
func test_era_damage_per_second_is_close_to_old_harolds() -> void:
	var old := _old_combo() / (CaneCombo.LOCK_TIME * CaneCombo.DAMAGE.size())
	for id in Eras.STARTING:
		var moves := EraMoves.for_era(id)
		var total := 0.0
		for d in moves.combo_damage:
			total += d
		var dps := total / (moves.lock_time * moves.combo_damage.size())
		assert_true(absf(dps / old - 1.0) <= 0.15, "%s at %.1f vs %.1f" % [id, dps, old])


func test_the_football_bounces_three_times_then_rests() -> void:
	var ball := EraBall.new()
	for i in 3:
		assert_true(ball.bounce(Vector2.UP))
	assert_false(ball.bounce(Vector2.UP), "a fourth wall stops it")
	assert_true(ball.is_resting())
	ball.free()


func test_the_football_holds_back_the_next_throw_until_picked_up() -> void:
	var moves := EraMoves.for_era(Eras.FOOTBALL)
	assert_true(moves.throw_ready())
	var ball := moves.make_throw(Vector2.RIGHT)
	assert_true(ball is EraBall)
	assert_false(moves.throw_ready(), "one ball at a time")
	moves.tick(10.0)
	assert_false(moves.throw_ready(), "time alone never brings it back")
	ball.free()
	assert_true(moves.throw_ready(), "picked up (freed), he can kick it again")
	# A new era (or old Harold) builds new moves, so a ball left behind never blocks the next throw.
	var again := EraMoves.for_era(Eras.FOOTBALL)
	again.make_throw(Vector2.RIGHT).free()
	assert_true(EraMoves.for_era(Eras.FOOTBALL).throw_ready())


func test_the_ticket_roll_waits_its_cooldown() -> void:
	var moves := EraMoves.for_era(Eras.BUS)
	assert_true(moves.throw_ready())
	var line := moves.make_throw(Vector2.RIGHT)
	assert_true(line is TicketLine)
	assert_false(moves.throw_ready())
	moves.tick(EraMoves.TICKET_ROLL_COOLDOWN - 0.1)
	assert_false(moves.throw_ready())
	moves.tick(0.2)
	assert_true(moves.throw_ready())
	line.free()


func test_the_ticket_line_nips_only_what_crosses_it() -> void:
	var length := TicketLine.LENGTH
	assert_true(TicketLine.crosses(Vector2(40, 3), Vector2.RIGHT, length))
	assert_false(TicketLine.crosses(Vector2(-4, 0), Vector2.RIGHT, length), "behind where it starts")
	assert_false(TicketLine.crosses(Vector2(40, TicketLine.WIDTH + 1.0), Vector2.RIGHT, length), "beside it")
	assert_false(TicketLine.crosses(Vector2(60, 0), Vector2.RIGHT, 30.0), "past the unrolled end")
	assert_true(TicketLine.crosses(Vector2(0, 40), Vector2.DOWN, length))


func test_the_ticket_line_nips_an_enemy_once_per_tick() -> void:
	var line := TicketLine.new()
	assert_true(line.take_nip(7, 0.0))
	assert_false(line.take_nip(7, TicketLine.TICK - 0.01), "not again within a tick")
	assert_true(line.take_nip(8, 0.1), "another enemy is its own")
	assert_true(line.take_nip(7, TicketLine.TICK))
	line.free()


func test_era_leftovers_are_passing_effects() -> void:
	var ball := EraBall.new()
	var line := TicketLine.new()
	assert_true(RoomView.is_passing_effect(ball))
	assert_true(RoomView.is_passing_effect(line))
	ball.free()
	line.free()


func test_an_era_throw_still_counts_as_a_throw_for_the_rules() -> void:
	var source := _player_source()
	var era_throw := source.substr(source.find("func _era_throw("), 800)
	assert_true(era_throw.contains("teeth_thrown.emit()"))
	assert_false(era_throw.contains("run.effects.throw()"), "the denture items never hear it")
	# They live beside him, as his teeth do, so a room change (recall_teeth) clears them with the teeth.
	var recall := source.substr(source.find("func recall_teeth("), 300)
	assert_true(recall.contains("_free_era_thrown()"))


func test_era_kicks_and_dodges_go_through_the_rule_signals() -> void:
	var source := _player_source()
	var attacks := source.substr(source.find("func _handle_attacks("), 1400)
	assert_true(attacks.contains("_swing(_era_moves.combo_damage["), "a kick is a swing")
	assert_true(attacks.contains("_era_throw()"))
	var dodge := source.substr(source.find("func start_dodge("), 1100)
	assert_true(dodge.contains("dodge_started.emit()") and dodge.contains("_era_dodge_hits.clear()"), "a spin or barge is a dodge")


func test_cane_items_stay_off_the_era_moves() -> void:
	var source := _player_source()
	var swing := source.substr(source.find("func _swing("), 1300)
	assert_true(swing.contains("from_era := false"))
	assert_true(swing.contains("if not from_era:"), "the Lucky Tee and the cane items skip a kick")
	var strike := source.substr(source.find("func _strike_enemies("), 1300)
	assert_true(strike.contains("ERA_HIT if swing.from_era"), "a kick lands as an era hit")
	var finish := source.substr(source.find("func _finish_swing("), 500)
	assert_true(finish.contains("from_era"), "nor do they hear a kick end")
	var hit := source.substr(source.find("func era_hit("), 700)
	assert_true(hit.contains("run.effects.land(enemy, amount, ERA_HIT"))
	assert_true(hit.contains("run.damage_mult()"), "stat items apply")


func test_the_barge_never_knocks_down_a_boss() -> void:
	var source := _player_source()
	var strike := source.substr(source.find("func _era_dodge_strike("), 900)
	assert_true(strike.contains("not enemy.def.is_boss"))


func test_the_cane_is_hidden_in_an_era() -> void:
	var source := _player_source()
	var draw := source.substr(source.find("func _draw("), 700)
	assert_true(draw.contains("_era.is_empty()"))


func test_set_era_changes_his_moves_but_not_the_run() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	player._visual = SpriteVisual.new()
	player.add_child(player._visual)
	player.set_era(Eras.BUS)
	assert_eq(player.era(), Eras.BUS)
	assert_eq(run.era, "", "RuleKeeper owns run.era")
	assert_true(player._era_moves != null and player._era_moves.era == Eras.BUS)
	if SpriteVisual.has_anim(Eras.art_id(Eras.BUS), "idle"):
		assert_eq(player._visual.art_id(), Eras.art_id(Eras.BUS), "his own 1975 art")
		assert_eq(player._visual._tint, Color.WHITE)
	else:
		assert_eq(player._visual._tint, Player.BUS_TINT, "no era art yet: old Harold, tinted")
	player.set_era("")
	assert_eq(player.era(), "")
	assert_true(player._era_moves == null)
	assert_eq(player._visual._tint, Color.WHITE)
	player.free()


# The Rolling Pin and Rubber Ferrule (cane pace) and Walker Tennis Balls (cane push) change old Harold's
# swing, never a younger Harold's kick or punch.
func test_cane_pace_and_push_items_leave_the_era_moves_alone() -> void:
	var kit := ItemKit.new()
	var bare := Player.new()
	bare.setup(kit.make_run())
	var caned := Player.new()
	caned.setup(kit.run_with(["rolling_pin", "rubber_ferrule", "walker_tennis_balls"]))
	assert_true(caned.run.swing_speed() != bare.run.swing_speed(), "the items do change the cane's pace")
	assert_true(caned.run.stats.swing_push_mult > 1.0)
	assert_true(caned.era_lock_time() != bare.era_lock_time(), "old Harold's pace follows them")
	assert_true(caned.swing_push(100.0, false) > bare.swing_push(100.0, false), "old Harold's push too")
	for id in Eras.STARTING:
		bare.set_era(id)
		caned.set_era(id)
		var moves := EraMoves.for_era(id)
		assert_near(caned.era_lock_time(), moves.lock_time)
		assert_near(caned.era_lock_time(), bare.era_lock_time())
		assert_near(caned.swing_push(moves.push, true), moves.push)
		assert_near(caned.swing_push(moves.push, true), bare.swing_push(moves.push, true))
	var source := _player_source()
	var attacks := source.substr(source.find("func _handle_attacks("), 1400)
	assert_true(attacks.contains("_combo.lock_time = era_lock_time()"), "the era's combo is paced by era_lock_time")
	var swing := source.substr(source.find("func _swing("), 1300)
	assert_true(swing.contains("swing_push(push, from_era)"))
	bare.free()
	caned.free()


func test_a_held_charge_never_crosses_into_or_out_of_an_era() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	player._charge.start()
	player._charge.tick(ChargeSwing.HOLD_DELAY + 0.1)
	assert_true(player._charge.is_charging())
	player.set_era(Eras.BUS)
	assert_false(player._charge.is_holding(), "held through the reel door, it is dropped")
	player._charge.start()
	player.set_era("")
	assert_false(player._charge.is_holding(), "and on the way back")
	player.free()


func test_a_kick_or_punch_plays_over_its_own_lock() -> void:
	var source := _player_source()
	var swing := source.substr(source.find("func _swing("), 1600)
	assert_true(swing.contains("_visual.play_once(\"attack\", _era_moves.lock_time if from_era"))


func test_a_ball_he_cannot_reach_goes_by_itself() -> void:
	var ball := EraBall.new()
	assert_false(ball.rest_tick(EraBall.REST_TIME + 1.0), "never while it flies")
	while ball.bounce(Vector2.UP):
		pass
	assert_true(ball.is_resting())
	assert_false(ball.rest_tick(EraBall.REST_TIME - 0.5))
	assert_true(ball.rest_tick(0.6), "after REST_TIME at rest it goes, and the throw comes back")
	var source := FileAccess.get_file_as_string("res://scripts/actors/era_ball.gd")
	var physics := source.substr(source.find("func _physics_process("), 400)
	assert_true(physics.contains("if rest_tick(delta) or"), "it frees itself when rest_tick says so")
	ball.free()
