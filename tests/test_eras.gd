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


# An earned reward, so better: the bot (v12) holds each era about 15% above old Harold's damage per
# second in play. On paper the kicks sit 0-20% over the cane. In play every self swings about once a
# second between approaches and dodges, so the punch's weight per swing counts more than its slow lock:
# it is set under the cane on paper (75-100%) and stays heavier than any single cane hit.
func test_era_damage_per_second_is_above_old_harolds() -> void:
	var old := _old_combo() / (CaneCombo.LOCK_TIME * CaneCombo.DAMAGE.size())
	var kick := EraMoves.for_era(Eras.FOOTBALL)
	var kick_dps := _combo_total(kick) / (kick.lock_time * kick.combo_damage.size())
	assert_true(kick_dps >= old and kick_dps <= old * 1.2, "kicks at %.1f vs %.1f" % [kick_dps, old])
	var punch := EraMoves.for_era(Eras.BUS)
	var punch_dps := _combo_total(punch) / (punch.lock_time * punch.combo_damage.size())
	assert_true(punch_dps < old and punch_dps >= old * 0.75, "punch at %.1f vs %.1f" % [punch_dps, old])
	assert_true(punch.combo_damage[0] > float(CaneCombo.DAMAGE.max()), "a punch outweighs any cane hit")


func _combo_total(moves: EraMoves) -> float:
	var total := 0.0
	for d in moves.combo_damage:
		total += d
	return total


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
	var strike := source.substr(source.find("func _era_dodge_strike("), 1300)
	assert_true(strike.contains("not enemy.def.is_boss"))


# The bot found a barge that cleared the room ending the era mid-strike and the next line reading a null
# _era_moves.
func test_a_barge_that_ends_the_era_stops_the_strike() -> void:
	var source := _player_source()
	var strike := source.substr(source.find("func _era_dodge_strike("), 1300)
	assert_true(strike.contains("var moves := _era_moves"), "the moves are held for the strike")
	assert_true(strike.contains("if _era_moves != moves:"), "the strike stops once the era ends")
	assert_false(strike.contains("_era_moves.dodge_stun"), "no read of _era_moves after a hit")


func test_the_cane_is_hidden_in_an_era() -> void:
	var source := _player_source()
	var draw := source.substr(source.find("func _draw("), 700)
	assert_true(draw.contains("_era.is_empty()"))


func test_ending_the_era_clears_what_he_threw() -> void:
	var run := RunState.new([] as Array[UpgradeDef], {})
	var player := Player.new()
	player.setup(run)
	player.set_era(Eras.FOOTBALL)
	var ball := Node2D.new()
	player.add_child(ball)
	player._era_thrown.append(ball)
	player.set_era(Eras.FOOTBALL)
	assert_true(is_instance_valid(ball) and not ball.is_queued_for_deletion(), "same era keeps it")
	player.set_era("")
	assert_true(ball.is_queued_for_deletion())
	assert_eq(player._era_thrown.size(), 0)
	player.free()


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
		assert_eq(player._visual._tint, Eras.tint(Eras.BUS), "no era art yet: old Harold, tinted")
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


func test_the_new_eras_play_unlike_the_old_ones() -> void:
	var spin := EraMoves.for_era(Eras.DANCE)
	var spade := EraMoves.for_era(Eras.ALLOTMENT)
	var kick := EraMoves.for_era(Eras.FOOTBALL)
	var punch := EraMoves.for_era(Eras.BUS)
	assert_near(spin.angle, 180.0, "the spin hits all round")
	assert_true(spin.reach < kick.reach, "close round him")
	assert_true(spin.combo_damage[0] < kick.combo_damage[-1], "weaker a hit than the kick combo's finisher")
	assert_true(spin.lock_time < CaneCombo.LOCK_TIME, "quick")
	assert_true(spade.reach > Player.ATTACK_REACH * 1.4 and spade.reach > punch.reach, "reaches well past the cane")
	assert_true(spade.angle < 20.0, "a thrust, not a sweep")
	assert_true(spade.lock_time > punch.lock_time, "slow")
	assert_true(spade.combo_damage[0] > punch.combo_damage[0], "the heaviest hit")
	assert_near(spin.dodge_length, 1.3, "the slide runs long")
	assert_true(spade.dodge_push > Player.ATTACK_PUSH, "the handle shove pushes")


func test_the_new_eras_sit_in_the_damage_bands() -> void:
	var old := _old_combo() / (CaneCombo.LOCK_TIME * CaneCombo.DAMAGE.size())
	var spin := EraMoves.for_era(Eras.DANCE)
	var spin_dps := _combo_total(spin) / (spin.lock_time * spin.combo_damage.size())
	assert_true(spin_dps >= old and spin_dps <= old * 1.2, "spin at %.1f vs %.1f" % [spin_dps, old])
	var spade := EraMoves.for_era(Eras.ALLOTMENT)
	var spade_dps := _combo_total(spade) / (spade.lock_time * spade.combo_damage.size())
	assert_true(spade_dps < old and spade_dps >= old * 0.75, "spade at %.1f vs %.1f" % [spade_dps, old])
	assert_true(spade.combo_damage[0] > float(CaneCombo.DAMAGE.max()))


func test_the_record_and_the_marrow_wait_their_cooldowns() -> void:
	for id in [Eras.DANCE, Eras.ALLOTMENT]:
		var moves := EraMoves.for_era(id)
		assert_true(moves.throw_ready())
		var shot := moves.make_throw(Vector2.RIGHT)
		assert_true(shot is EraShot, id)
		assert_false(moves.throw_ready())
		moves.tick(moves.throw_cooldown - 0.1)
		assert_false(moves.throw_ready())
		moves.tick(0.2)
		assert_true(moves.throw_ready())
		shot.free()
	assert_near(EraMoves.for_era(Eras.DANCE).throw_cooldown, EraMoves.DISC_COOLDOWN)
	assert_near(EraMoves.for_era(Eras.ALLOTMENT).throw_cooldown, EraMoves.MARROW_COOLDOWN)


func test_the_record_passes_through_and_the_marrow_splashes() -> void:
	var disc := EraShot.for_disc()
	assert_true(disc.pierce and disc.splash_radius == 0.0)
	var marrow := EraShot.for_marrow()
	assert_false(marrow.pierce)
	assert_near(marrow.splash_radius, 24.0)
	var bodies := [Rect2(100, 0, 10, 10), Rect2(118, 0, 10, 10), Rect2(200, 0, 10, 10)]
	assert_eq(EraShot.splash_targets(Vector2(105, 5), bodies, marrow.splash_radius), [0, 1], "the two within 24 px")
	disc.free()
	marrow.free()


func test_an_era_without_art_shows_old_harold_tinted() -> void:
	for id in Eras.STARTING:
		if not SpriteVisual.has_anim(Eras.art_id(id), "idle"):
			assert_true(Eras.tint(id) != Color.WHITE, "%s is told apart by a tint" % id)
	assert_eq(Eras.tint(""), Color.WHITE)


func test_the_new_shots_are_cleared_with_the_room_and_hit_enemies_only() -> void:
	var shot := EraShot.for_disc()
	assert_true(RoomView.is_passing_effect(shot))
	shot.free()
	var source := FileAccess.get_file_as_string("res://scripts/actors/era_shot.gd")
	assert_true(source.contains("get_nodes_in_group(\"enemies\")"))
	assert_false(source.contains("take_hit"), "never the player")
