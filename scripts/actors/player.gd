class_name Player
extends CharacterBody2D

signal died
signal swing_landed(heavy: bool, finisher: bool)
signal swing_missed(heavy: bool)
signal teeth_thrown
signal teeth_bit
signal teeth_caught
signal hurt
signal bomb_requested(at: Vector2)
signal potion_drunk(potion: PotionDef)

const ATTACK_REACH := 44.0
const ATTACK_ANGLE := 60.0
const CHARGE_REACH := 56.0
const CHARGE_ANGLE := 75.0
const ATTACK_PUSH := 60.0
const DODGE_SPEED := 300.0
const CHARGE_SLOWDOWN := 0.4
# Bunion Pads: how far across a prop's corner a dodge may step, and how near an axis a dodge must run
# to count as straight at it.
const DODGE_CORNER_REACH := 8.0
const DODGE_STRAIGHT_DOT := 0.96
const HURT_COLOR := Color("e4524f")
const SPRITE_FRAME_WIDTH := 60
const SPRITE_FEET_Y := 23.0
const FEET_BOX_SIZE := Vector2(14, 12)
const FEET_OFFSET := Vector2(0, 17)
const CROSSHAIR_GAP := 3.0
const CROSSHAIR_REACH := 8.0
const CROSSHAIR_COLOR := Color(1.0, 0.9, 0.55, 0.95)
const GHOST_EVERY := 0.05
const SLOW_COLOR := Color(0.62, 0.86, 1.0, 0.9)
const CANE_COLOR := Color("a8692f")
const MOVE_AIM_REACH := 40.0
const SWING_COLOR := Color("ffe58a")
# How often his feet crunch while he wades through sand.
const SAND_STEP_TIME := 0.34
# The Spare Set: how far apart, in degrees, the two sets of dentures fly.
const SPARE_SPREAD := 14.0
# Grandma's Rolling Pin and The Reaper's Other Scythe draw their swings in these. The pin itself is an
# ItemFx drawn over bodies.
const PIN_FLOUR := Color("f6ecd6")
const SWEEP_FILL := Color(0.62, 0.52, 0.95, 0.2)
const SWEEP_EDGE := Color("8f7ce0")
const SWEEP_BLADE := Color("e8ecf4")
# How quickly the Telescope Cane's look ahead follows his aim, per second.
const LOOK_EASE := 4.0

var run: RunState
var show_crosshair := false
# Set by the full-loop check and balance probes, which have no mouse to aim with.
var aim_source := Callable()
# The Game tab's Mouse aim. Off, he aims the way he last walked, MOVE_AIM_REACH ahead of him.
var mouse_aim := true
var _last_move := Vector2.RIGHT
var _ghost_left := 0.0
# True while his feet stand on a wet floor, where he slides.
var on_wet := false
var _slow := SlowEffect.new()
var _combo := CaneCombo.new()
var _charge := ChargeSwing.new()
# His false teeth, the thrown attack. The cane itself never leaves his hand.
var _teeth := DentureThrow.new()
var _thrown_teeth: ThrownDentures
# The Spare Set's second set in flight. It has its own throw state, and never holds back a throw.
var _spare_teeth: Array[ThrownDentures] = []
var _dodge := DodgeTimer.new()
var _aim := Vector2.RIGHT
var _dodge_direction := Vector2.RIGHT
var _active_swing: SwingAttack
var _visual: SpriteVisual
# What he wears, drawn over the sprite. Made only once he wears something.
var _look: GrandpaLook
var _feet: Marker2D
# A gust that shoves him along for a while, as the bellows do. A dodge breaks free of it.
var _push := Vector2.ZERO
var _push_left := 0.0
# Whether the next fire hit that would land is shrugged off, with the coal shovel. Only a fire hit
# that lands sets it, and only a shrugged one clears it.
var _fire_shrug_next := false
# Red tape holds him a moment when he walks into it. See RedTapeRule.
var _tape := RedTapeRule.new()
var _was_taped := false
# The charge's sounds, each once a hold: the hum as it starts to build, the glint once it is full.
var _hum_played := false
var _ready_played := false
# Time to his next step's crunch while he wades through sand.
var _sand_step_left := 0.0
# Whether this dodge has had its close call yet, and whether he was dodging last frame, for the items.
var _close_call_spent := false
var _was_dodging := false
# The Polyester Suit's spark: while it runs he can neither walk, dodge, swing nor throw.
var _self_stun_left := 0.0
# The Telescope Cane: how far ahead of his feet the camera looks, eased toward where he aims.
var _look_ahead := Vector2.ZERO


static func arrival_position(cell: Vector2i) -> Vector2:
	return RoomBackdrop.cell_center(cell) - FEET_OFFSET


static func crosshair_lines(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		points.append(center + direction * CROSSHAIR_GAP)
		points.append(center + direction * CROSSHAIR_REACH)
	return points


func setup(run_state: RunState) -> void:
	run = run_state


# Doors and pickups use this point, because it is where he stands in the room.
func feet() -> Node2D:
	return _feet


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	# Departures, Terminal Zero: a raised queue barrier stops him, and nothing else.
	collision_mask = 1 | Hole.LAYER | QueueBarrier.LAYER
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = FEET_BOX_SIZE
	shape.shape = rect
	shape.position = FEET_OFFSET
	add_child(shape)
	_feet = Marker2D.new()
	_feet.position = FEET_OFFSET
	add_child(_feet)
	_visual = SpriteVisual.new()
	add_child(_visual)
	_visual.setup("grandpa", Vector2(20, 28), Color("7d9a5c"), SPRITE_FRAME_WIDTH)
	if not run.look.is_empty():
		refresh_look()
	run.health.died.connect(died.emit)


# Redraws what he wears from run.look, as after a change at the Decor Office.
func refresh_look() -> void:
	if _look == null:
		_look = GrandpaLook.new()
		add_child(_look)
	_look.setup(run.look)


# The HURT_ id of the last hit that landed, read by the balance bot to tell touches from attacks.
var last_hurt_source := ""


# Every hit on him comes through here. source is one of RunEffects' HURT_ ids, for the items that care
# what hurt him. Items may lower the amount (0 shrugs it off), and may save him from a finishing hit
# once any Life Jacket is spent, leaving one pill.
func take_hit(amount: int, source := RunEffects.HURT_ENEMY) -> bool:
	if _dodge.is_active():
		if not _close_call_spent and amount > 0 and not run.health.is_dead():
			_close_call_spent = true
			run.effects.close_call()
		return false
	if run.health.is_dead() or run.health.is_invulnerable():
		return false
	amount = run.effects.hurt(amount, source)
	if amount <= 0:
		run.health.shrug_off()
		return false
	var saved := false
	if amount >= run.health.pills and run.health.lethal_saves <= 0 and run.effects.lethal():
		saved = true
		amount = run.health.pills - 1
	var landed := run.health.hit(amount)
	# After the hit, so an item that brings him back (Eternal Warranty) has the last word.
	if saved:
		run.effects.saved()
	if landed:
		last_hurt_source = source
		if _visual != null:
			_visual.flash(HURT_COLOR, HurtLook.RED_TIME)
		hurt.emit()
	return landed


# A hit from fire: vents, burns and steam. With the coal shovel memento every second fire hit that
# would land is shrugged off instead, and a shrugged hit returns false like any other that misses.
func take_fire_hit(amount: int) -> bool:
	if not run.has_perk(Mementos.FIRE_PERK):
		return take_hit(amount, RunEffects.HURT_FIRE)
	var would_land := not _dodge.is_active() and not run.health.is_dead() and not run.health.is_invulnerable()
	if would_land and _fire_shrug_next:
		_fire_shrug_next = false
		run.health.shrug_off()
		return false
	var landed := take_hit(amount, RunEffects.HURT_FIRE)
	if landed:
		_fire_shrug_next = true
	return landed


# Walking into an enemy's body costs what it says (ContactRule) and shoves his feet back out of it,
# through push, so the Gravity Boots and the anchor's halving hold for it as for every other shove. A
# dodge passes through, and the grace after a hit keeps one touch from costing more. Returns whether a
# touch counted, landed or shrugged off by an item.
func touch_bodies() -> bool:
	if run == null or _feet == null or not is_inside_tree() or run.effects.ctx.contact_off:
		return false
	if _dodge.is_active() or run.health.is_dead() or run.health.is_invulnerable():
		return false
	var box := ContactRule.feet_box(_feet.global_position, FEET_BOX_SIZE)
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if not ContactRule.touches(enemy.body_rect(), box):
			continue
		var cost := enemy.contact_damage()
		if cost <= 0:
			continue
		take_hit(cost, RunEffects.HURT_CONTACT)
		# A touch an item shrugged off shoves him out too, so he is never left standing in a body.
		if run.health.is_invulnerable():
			push(ContactRule.shove(enemy.global_position, _feet.global_position, _aim, enemy.body_rect(), FEET_BOX_SIZE), ContactRule.SHOVE_TIME)
			return true
		return false
	return false


# A sedative takes some of his speed for a while. The strongest slow running counts.
func slow(fraction: float, seconds: float) -> void:
	_slow.apply(fraction, seconds)
	queue_redraw()


# Every push goes through here, so the ship's anchor halves them all: gusts, foghorns, rings and pulls.
func push(shove: Vector2, seconds: float) -> void:
	var share := run.slide_mult() if run != null else 1.0
	# Gravity Boots: nothing shoves him at all.
	if share <= 0.0:
		return
	_push = shove * share
	_push_left = seconds


func is_pushed() -> bool:
	return _push_left > 0.0


# A gust from the room he just left stays there.
func end_push() -> void:
	_push_left = 0.0


func slow_factor() -> float:
	return _slow.speed_factor()


func is_slowed() -> bool:
	return _slow.is_active()


func is_dodging() -> bool:
	return _dodge.is_active()


func is_taped() -> bool:
	return _tape.is_holding()


# The Polyester Suit's spark holds him for a moment: no walking, dodging, swinging or throwing.
func stun_self(seconds: float) -> void:
	_self_stun_left = maxf(_self_stun_left, seconds)
	cancel_charge()


func is_self_stunned() -> bool:
	return _self_stun_left > 0.0


# Where the camera centres on him: his feet, and with the Telescope Cane a little ahead of where he aims.
# FloorScene, the Waiting Room and Enemy.target_in_view all read this, so what counts as on screen is
# what the camera shows.
func camera_focus() -> Vector2:
	var at := _feet.global_position if _feet != null else global_position + FEET_OFFSET
	return at + _look_ahead


# Eases the look ahead toward where he aims, so a turn swings the view over instead of jumping it. The
# full loop checks where the camera rests, so there it stays on his feet.
func ease_look_ahead(delta: float) -> void:
	var wanted := Vector2.ZERO if run.effects.ctx.counting_exact else _aim * run.stats.look_ahead
	_look_ahead = _look_ahead.lerp(wanted, minf(LOOK_EASE * delta, 1.0))
# Whether his feet stand in a sand bunker, where he wades slower and cannot dodge.
func is_in_sand() -> bool:
	return _feet != null and is_inside_tree() and SandTrap.is_sand_at(get_tree(), _feet.global_position)


func _physics_process(delta: float) -> void:
	_combo.tick(delta)
	_charge.tick(delta)
	_dodge.tick(delta)
	if _was_dodging and not _dodge.is_active():
		run.effects.dodge_end()
	_was_dodging = _dodge.is_active()
	_slow.tick(delta)
	_push_left = maxf(_push_left - delta, 0.0)
	_self_stun_left = maxf(_self_stun_left - delta, 0.0)
	run.health.tick(delta)
	run.tick_buff(delta)
	_advance_swing(delta)
	run.effects.tick(delta)
	var to_mouse := _aim_point() - global_position
	if not to_mouse.is_zero_approx():
		_aim = to_mouse.normalized()
	_visual.set_facing_left(_aim.x < 0.0)
	if _look != null:
		_look.set_facing(_aim.x)
	_visual.set_alpha(HurtLook.alpha_for(_dodge.is_active(), run.health.invulnerability_left()))
	ease_look_ahead(delta)
	_handle_attacks()
	_handle_bomb()
	_handle_potion()
	_handle_movement()
	touch_bodies()
	_leave_dodge_ghosts(delta)
	_charge_sounds()
	queue_redraw()


func _charge_sounds() -> void:
	if not _charge.is_holding():
		_hum_played = false
		_ready_played = false
		return
	if _charge.is_charging() and not _hum_played:
		_hum_played = true
		Sfx.play("charge_hum")
	if _charge.progress() >= 1.0 and not _ready_played:
		_ready_played = true
		Sfx.play("charge_ready")


func _aim_point() -> Vector2:
	if aim_source.is_valid():
		return aim_source.call()
	if ActiveDevice.using_pad:
		var stick := Vector2(Input.get_joy_axis(ActiveDevice.pad_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(ActiveDevice.pad_id, JOY_AXIS_RIGHT_Y))
		return pad_aim_point(global_position, stick, _aim, mouse_aim, _last_move)
	if not mouse_aim:
		return move_aim_point(global_position, _last_move)
	return get_global_mouse_position()


# Where a pad aims: the right stick while it is held, whatever Mouse aim says. Resting, the aim stays
# where it was, or with Mouse aim off follows the way he last walked.
static func pad_aim_point(from: Vector2, stick: Vector2, aim: Vector2, aim_by_stick: bool, last_move: Vector2) -> Vector2:
	if PadInput.stick_dir(stick) == Vector2.ZERO and not aim_by_stick:
		return move_aim_point(from, last_move)
	return PadInput.aim_point(from, stick, aim)


# Where he aims with Mouse aim off: a point ahead of him the way he last walked.
static func move_aim_point(from: Vector2, last_move: Vector2) -> Vector2:
	var way := last_move.normalized() if not last_move.is_zero_approx() else Vector2.RIGHT
	return from + way * MOVE_AIM_REACH


func _leave_dodge_ghosts(delta: float) -> void:
	if not _dodge.is_active():
		_ghost_left = 0.0
		return
	_ghost_left -= delta
	if _ghost_left > 0.0 or get_parent() == null:
		return
	_ghost_left = GHOST_EVERY
	var ghost := _visual.make_ghost()
	if ghost != null:
		get_parent().add_child(ghost)
		ghost.global_position = global_position


# Spending is left to whoever can place it, so the practice room never wastes one.
func _handle_bomb() -> void:
	if Input.is_action_just_pressed("bomb") and bomb_requested.get_connections().size() > 0 and run.use_bomb():
		bomb_requested.emit(_feet.global_position)


func _handle_potion() -> void:
	if not Input.is_action_just_pressed("potion"):
		return
	var drunk := run.potion
	if run.drink_potion():
		Sfx.play("potion_drink")
		if _visual != null:
			_visual.flash(drunk.color, 0.25)
		potion_drunk.emit(drunk)


# The teeth only hold back another throw. His cane never leaves his hand, so a swing, the combo and
# the charge never wait for them to come back.
static func can_throw(teeth: DentureThrow) -> bool:
	return teeth.is_held()


static func can_swing(_teeth: DentureThrow) -> bool:
	return true


func has_teeth() -> bool:
	return _teeth.is_held()


# Where he aims, as a unit vector.
func aim_direction() -> Vector2:
	return _aim


# The dodge is ready again at once (Reading Glasses on a Chain, the Pogo Cane).
func refund_dodge() -> void:
	_dodge.clear_cooldown()


# A still copy of how he looks this frame, for the Afterimage. Null before the art is loaded.
func afterimage_sprite() -> Sprite2D:
	return _visual.copy_frame() if _visual != null else null


func dodge_cooldown_left() -> float:
	return _dodge.cooldown_left()


# The dentures in flight or lying in the room, the Spare Set's too.
func teeth_out() -> Array[ThrownDentures]:
	var out: Array[ThrownDentures] = []
	if is_instance_valid(_thrown_teeth):
		out.append(_thrown_teeth)
	for spare in _spare_teeth:
		if is_instance_valid(spare):
			out.append(spare)
	return out


func _handle_attacks() -> void:
	if is_self_stunned():
		return
	if Input.is_action_just_pressed("throw") and can_throw(_teeth):
		_throw_teeth()
	if not can_swing(_teeth):
		_charge.cancel()
		return
	if Input.is_action_just_pressed("attack"):
		# The Heavy Head and Lightweight options change the pace, so it is read at every swing.
		_combo.lock_time = CaneCombo.LOCK_TIME / run.swing_speed()
		var damage := _combo.try_attack()
		if damage > 0:
			_swing(damage, ATTACK_REACH, ATTACK_ANGLE, ATTACK_PUSH, false, damage == CaneCombo.DAMAGE[-1])
		# The Golf Glove charges it faster, so its time is read at every press.
		_charge.charge_time = ChargeSwing.CHARGE_TIME * run.stats.charge_time_mult
		_charge.start()
	if Input.is_action_just_released("attack"):
		if _charge.release():
			_swing(ChargeSwing.DAMAGE * run.charge_damage_mult(), CHARGE_REACH, CHARGE_ANGLE, ChargeSwing.KNOCKBACK, true, false)
			run.effects.charge_release(true)


func _throw_teeth() -> void:
	var parent := get_parent()
	if parent == null:
		return
	# Denture Adhesive's last level shortens the wait, so the delay is read at every throw.
	_teeth.return_delay = run.stats.teeth_return_delay
	if not _teeth.try_throw():
		return
	var spawn := global_position + _aim * ThrownDentures.SPAWN_AHEAD
	# His upper body can overlap a wall now, so the wall check starts from where he stands.
	var query := PhysicsRayQueryParameters2D.create(_feet.global_position, spawn, ThrownDentures.BLOCKED_BY)
	var wall := get_world_2d().direct_space_state.intersect_ray(query)
	if not wall.is_empty():
		var collider: Object = wall.get("collider")
		if collider is BreakableBlock:
			collider.hit_by(BreakableBlock.SOURCE_CANE)
		spawn = wall["position"] + wall["normal"] * ThrownDentures.WALL_BACKOFF
	var sets := maxi(run.stats.teeth_sets, 1)
	var way := _aim.rotated(-deg_to_rad(SPARE_SPREAD) / 2.0) if sets > 1 else _aim
	_thrown_teeth = _make_teeth(_teeth, way)
	_thrown_teeth.caught.connect(teeth_caught.emit)
	parent.add_child(_thrown_teeth)
	_thrown_teeth.global_position = spawn
	# A spare still out from the last throw goes, so every set in the room is one the room can recall.
	_free_spares()
	for i in sets - 1:
		var spare_state := DentureThrow.new(run.stats.teeth_return_delay)
		spare_state.try_throw()
		var spare := _make_teeth(spare_state, _aim.rotated(deg_to_rad(SPARE_SPREAD) * (0.5 + i)))
		spare.spare = true
		parent.add_child(spare)
		spare.global_position = spawn
		_spare_teeth.append(spare)
		if not wall.is_empty():
			spare_state.drop()
	teeth_thrown.emit()
	run.effects.throw()
	if not wall.is_empty():
		_teeth.drop()


func _make_teeth(state: DentureThrow, way: Vector2) -> ThrownDentures:
	var teeth := ThrownDentures.new()
	teeth.setup(state, self, way, run.bite_damage_mult(), run.stats.bite_range, run.stats.bites_per_throw)
	teeth.wounded_mult = run.stats.wounded_damage_mult
	teeth.boss_mult = run.boss_damage_mult()
	teeth.effects = run.effects
	teeth.glue_time = run.stats.teeth_glue_time
	teeth.boomerang = run.stats.teeth_boomerang
	teeth.floor_bite = run.stats.teeth_floor_bite
	teeth.hit_enemy.connect(teeth_bit.emit)
	return teeth


func cancel_charge() -> void:
	_charge.cancel()


func recall_teeth() -> void:
	if is_instance_valid(_thrown_teeth):
		_thrown_teeth.queue_free()
	_thrown_teeth = null
	_free_spares()
	_teeth.catch_teeth()


func _free_spares() -> void:
	for spare in _spare_teeth:
		if is_instance_valid(spare):
			spare.queue_free()
	_spare_teeth.clear()


func _exit_tree() -> void:
	if is_instance_valid(_thrown_teeth):
		_thrown_teeth.queue_free()
	_free_spares()


func _swing(damage: float, reach: float, angle: float, push: float, heavy: bool, finisher: bool) -> void:
	_finish_swing()
	var swing_damage := damage * run.damage_mult()
	# The Lucky Tee: now and then a swing does double.
	if run.stats.lucky_swing_chance > 0.0:
		swing_damage = PlayerStats.lucky_damage(swing_damage, run.stats.lucky_swing_chance, randf())
	# Walker Tennis Balls knock enemies further.
	_active_swing = SwingAttack.new(_aim, reach, angle, swing_damage, push * run.stats.swing_push_mult, heavy, finisher)
	# Items may reshape the swing before it hits: what they change is also what is drawn.
	run.effects.swing(_active_swing)
	Sfx.play("charged_swing" if heavy else "cane_swing")
	_visual.play_once("attack", CaneCombo.LOCK_TIME)
	_strike_enemies()


func _advance_swing(delta: float) -> void:
	if _active_swing == null:
		return
	_active_swing.tick(delta)
	if _active_swing.is_active():
		_strike_enemies()
	else:
		_finish_swing()


func _strike_enemies() -> void:
	var swing := _active_swing
	var had_landed := swing.has_landed()
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.is_queued_for_deletion() or enemy.submerged:
			continue
		if swing.try_hit(global_position, enemy.get_instance_id(), enemy.body_rect()):
			var damage := PlayerStats.strike_damage(swing.damage, enemy.hp / maxf(enemy.max_hp(), 1.0), run.stats.wounded_damage_mult)
			damage = PlayerStats.boss_damage(damage, enemy.def.is_boss, run.boss_damage_mult())
			if not run.effects.land(enemy, damage, swing_source(swing.heavy, swing.finisher), swing.push_toward(global_position, enemy.global_position), global_position - enemy.global_position):
				swing.mark_blocked()
	for block: BreakableBlock in get_tree().get_nodes_in_group("breakable"):
		if block.is_queued_for_deletion() or not block.can_break_by(BreakableBlock.SOURCE_CANE):
			continue
		if swing.try_hit(global_position, block.get_instance_id(), block.body_rect()):
			block.hit_by(BreakableBlock.SOURCE_CANE)
	if swing.has_landed() and not had_landed:
		swing_landed.emit(swing.heavy, swing.finisher)


# The hit source the items hear for a swing: a charged one, the combo's third, or a plain swing.
static func swing_source(heavy: bool, finisher: bool) -> String:
	if heavy:
		return RunEffects.CHARGE
	return RunEffects.COMBO_3 if finisher else RunEffects.SWING


func _finish_swing() -> void:
	if _active_swing == null:
		return
	if not _active_swing.has_reached_something():
		swing_missed.emit(_active_swing.heavy)
	var ended := _active_swing
	_active_swing = null
	run.effects.swing_end(ended)


func _handle_movement() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		_last_move = input
	# Feet sunk in a sand bunker cannot dodge, and wade slower (Fairway's End).
	var sunk := is_in_sand()
	if Input.is_action_just_pressed("dodge") and SandRule.can_dodge(sunk):
		start_dodge(input.normalized() if input != Vector2.ZERO else _aim)
	_step_in_sand(sunk and input != Vector2.ZERO)
	on_wet = _feet != null and WetFloor.is_wet_at(get_tree() if is_inside_tree() else null, _feet.global_position)
	# Orthopedic Slippers keep his feet on a wet floor.
	var slides := on_wet and not run.stats.wet_grip
	# Walking into red tape holds him a moment, and a dodge cuts through it instead.
	var on_tape := _feet != null and RedTape.touch(get_tree() if is_inside_tree() else null, _feet.global_position, _dodge.is_active())
	var taped := _tape.step(on_tape, _dodge.is_active(), get_physics_process_delta_time())
	if taped and not _was_taped:
		Sfx.play("tape_snag")
	_was_taped = taped
	if _dodge.is_active():
		# A dodge goes where it is aimed, wet floor or not, and breaks free of any gust.
		_push_left = 0.0
		velocity = _dodge_direction * DODGE_SPEED
		# Bunion Pads: a dodge straight at a prop's corner steps round it, as a walk does.
		if run.stats.dodge_rounds_corners:
			velocity = _round_corners(velocity, straightened(_dodge_direction), DODGE_SPEED, DODGE_CORNER_REACH)
	else:
		# Support Stockings: no slow takes him below their share of his speed.
		var speed := run.move_speed() * maxf(SandRule.slowed(_slow.speed_factor(), sunk), run.stats.min_slow_factor)
		# The Hover Round keeps his full walk while he charges.
		if _charge.is_charging() and not run.stats.charge_full_speed:
			speed *= CHARGE_SLOWDOWN
		# What he carries onto the wet is never more than a walk, so a dodge does not fling him.
		velocity = SlideRule.velocity(velocity.limit_length(speed), input * speed, slides, get_physics_process_delta_time())
		if not slides:
			velocity = _round_corners(velocity, input, speed)
		# An escalator strip carries him on top of his walk. A dodge goes where it is aimed instead.
		if _feet != null and is_inside_tree():
			velocity += ConveyorStrip.carry_at(get_tree(), _feet.global_position)
			# A rolling deck slides him too. A dodge holds him where it is aimed instead.
			velocity += ShipDeck.slide_at(get_tree(), _feet.global_position) * run.slide_mult()
		if taped or is_self_stunned():
			velocity = Vector2.ZERO
		if not _visual.is_playing_once():
			_visual.play("walk" if input != Vector2.ZERO else "idle")
	if _push_left > 0.0:
		velocity += _push
	move_and_slide()


# A crunch for each step while he wades through a bunker.
func _step_in_sand(wading: bool) -> void:
	if not wading:
		_sand_step_left = 0.0
		return
	_sand_step_left -= get_physics_process_delta_time()
	if _sand_step_left <= 0.0:
		_sand_step_left = SAND_STEP_TIME
		Sfx.play("sand_step")


# Starts a dodge that way if the cooldown allows, and tells the items. Returns whether it started.
func start_dodge(direction: Vector2) -> bool:
	# The Polyester Suit's spark holds him, dodge and all.
	if is_self_stunned():
		return false
	# Velcro Shoes give a second dodge, so the count is read at every start.
	_dodge.charges = run.stats.dodge_charges
	if not _dodge.try_start(run.stats.dodge_cooldown, DodgeTimer.DURATION * run.stats.dodge_length):
		return false
	_dodge_direction = direction
	_close_call_spent = false
	Sfx.play("dodge")
	run.effects.dodge(direction)
	return true


# Walking straight into a corner by a pixel or two steps him round it, sideways only, and only when

# both the step and the walk on from there are clear, so he never slips into a wall or through one.
func _round_corners(wanted: Vector2, input: Vector2, speed: float, reach := CornerSlide.REACH) -> Vector2:
	if not is_inside_tree() or input.is_zero_approx() or (absf(input.x) > 0.01 and absf(input.y) > 0.01):
		return wanted
	var delta := get_physics_process_delta_time()
	var ahead := input.normalized() * speed * delta
	var hit := move_and_collide(ahead, true)
	if hit == null:
		return wanted
	var obstacle := _rect_of(hit.get_collider_shape())
	if not obstacle.has_area():
		return wanted
	var step := CornerSlide.nudge(Rect2(_feet.global_position - FEET_BOX_SIZE / 2.0, FEET_BOX_SIZE), obstacle, input, reach)
	if step == Vector2.ZERO:
		return wanted
	var clear := step + step.normalized() * 0.5
	if test_move(global_transform, clear) or test_move(global_transform.translated(clear), ahead):
		return wanted
	return step.normalized() * minf(speed, clear.length() / delta)


# A way that runs nearly along an axis, snapped onto it, so a dodge aimed a hair off straight still counts
# as straight at a corner. Any other way is left as it is.
static func straightened(way: Vector2) -> Vector2:
	for axis: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		if way.normalized().dot(axis) >= DODGE_STRAIGHT_DOT:
			return axis
	return way


func _rect_of(shape_owner: Object) -> Rect2:
	var holder := shape_owner as CollisionShape2D
	if holder == null or not holder.shape is RectangleShape2D:
		return Rect2()
	var size: Vector2 = (holder.shape as RectangleShape2D).size
	return Rect2(holder.global_position - size / 2.0, size)


func _draw() -> void:
	var has_art := _visual.has_art()
	if _dodge.is_active() and not has_art:
		draw_line(-_dodge_direction * 6.0, -_dodge_direction * 26.0, Color(1.0, 1.0, 1.0, 0.35), 8.0)
	var swinging := _active_swing != null
	var pointing := _active_swing.direction if swinging else _aim
	# A cane skin draws the placeholder cane even over the sprite, so the skin shows until the art pass.
	if not has_art or run.look.has(CosmeticDef.SLOT_CANE):
		# A dark edge under a skin, so a pale cane still reads on the Mall's white tile.
		if run.look.has(CosmeticDef.SLOT_CANE):
			draw_line(-pointing, pointing * 21.0, GrandpaLook.OUTLINE, 5.0)
		draw_line(Vector2.ZERO, pointing * 20.0, GrandpaLook.cane_color(run.look, CANE_COLOR), 3.0)
		if GrandpaLook.has_stripes(run.look):
			for i in 3:
				var band := pointing * (7.0 + i * 5.0)
				draw_line(band - pointing, band + pointing, GrandpaLook.STRIPE_BAND, 3.0)
	if show_crosshair:
		var at_mouse := (mouse_aim or aim_source.is_valid()) and not ActiveDevice.using_pad
		var lines := crosshair_lines(get_local_mouse_position() if at_mouse else to_local(_aim_point()))
		draw_multiline(lines, Color.BLACK, 3.0)
		draw_multiline(lines, CROSSHAIR_COLOR, 1.0)
	if swinging:
		_draw_swing(_active_swing)
	if _charge.is_charging():
		draw_arc(Vector2.ZERO, 22.0, -PI / 2.0, -PI / 2.0 + TAU * _charge.progress(), 24, Color("f4c542"), 2.0)
	if _slow.is_active():
		_draw_slowed()
	if _tape.is_holding():
		RedTape.draw_hold(self, FEET_OFFSET)


# The swing as it hits: its arc (behind him too when it reaches both ways), the Rolling Pin's flour arcs,
# or the Scythe's sweep. Whatever is drawn here is what the swing hits, for as long as it shows.
func _draw_swing(swing: SwingAttack) -> void:
	var center := swing.direction.angle()
	var half_angle := deg_to_rad(swing.half_angle_deg)
	var points := maxi(12, ceili(swing.half_angle_deg / 6.0))
	if swing.style == SwingAttack.STYLE_SWEEP:
		_draw_sweep(swing)
		return
	var color := GrandpaLook.arc_color(run.look, SWING_COLOR)
	var width := 3.0
	if swing.style == SwingAttack.STYLE_PIN:
		color = PIN_FLOUR
		width = 5.0
	var sides := [center, center + PI] if swing.both_ways else [center]
	# A swing an item has widened gets a dark edge, so its pale arc still reads on the Mall's white tile.
	var edged := swing.style == SwingAttack.STYLE_PIN or swing.both_ways or swing.half_angle_deg >= 90.0
	for side: float in sides:
		if edged:
			draw_arc(Vector2.ZERO, swing.reach, side - half_angle, side + half_angle, points, Color(Color.BLACK, 0.8), width + 3.0)
		draw_arc(Vector2.ZERO, swing.reach, side - half_angle, side + half_angle, points, color, width)


# The scythe's spin: the whole circle it hits, lit faintly, and the blade going once round.
func _draw_sweep(swing: SwingAttack) -> void:
	draw_circle(Vector2.ZERO, swing.reach, SWEEP_FILL)
	draw_arc(Vector2.ZERO, swing.reach, 0.0, TAU, 48, Color(Color.BLACK, 0.6), 4.0)
	draw_arc(Vector2.ZERO, swing.reach, 0.0, TAU, 48, SWEEP_EDGE, 2.0)
	var blade := swing.direction.angle() + TAU * swing.progress()
	draw_arc(Vector2.ZERO, swing.reach - 6.0, blade - 1.8, blade, 18, Color(SWEEP_BLADE, 0.45), 6.0)
	var tip := Vector2.from_angle(blade) * swing.reach
	draw_line(Vector2.ZERO, tip, Color.BLACK, 5.0)
	draw_line(Vector2.ZERO, tip, Color("5b4636"), 3.0)
	draw_arc(Vector2.ZERO, swing.reach - 3.0, blade - 0.55, blade, 10, Color.BLACK, 7.0)
	draw_arc(Vector2.ZERO, swing.reach - 3.0, blade - 0.55, blade, 10, SWEEP_BLADE, 4.0)


# A pale blue ring at his feet and drowsy bubbles over his head while a sedative holds him.
func _draw_slowed() -> void:
	draw_set_transform(FEET_OFFSET, 0.0, Vector2(1.0, 0.45))
	draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 20, SLOW_COLOR, 2.0)
	draw_set_transform(Vector2.ZERO)
	var bob := sin(Time.get_ticks_msec() / 180.0) * 1.5
	for i in 3:
		var at := Vector2(6.0 + i * 4.0, -24.0 - i * 5.0 + bob)
		draw_arc(at, 1.5 + i * 0.7, 0.0, TAU, 10, SLOW_COLOR, 1.0)
