class_name StatEffect
extends Resource

@export var bonus_pills: int = 0
@export var move_speed_bonus: float = 0.0
@export var dodge_cooldown_cut: float = 0.0
# Cane damage only. The thrown dentures have their own bonus below.
@export var damage_bonus: float = 0.0
# Extra bite damage for the thrown dentures, as a fraction of their base.
@export var bite_damage_bonus: float = 0.0
# Pixels added to how far the dentures fly.
@export var bite_range_bonus: float = 0.0
# How many enemies one throw can bite through. Zero leaves the usual one.
@export var bites_through: int = 0
@export var pension_bonus: float = 0.0
@export var warning_bonus: float = 0.0
@export var reveals_enemy_health: bool = false
# Extra damage a Thermos blast does to enemies, never to Grandpa.
@export var thermos_damage_bonus: float = 0.0
# The form options' effects. Each is a fraction of the base unless noted.
# How much faster the cane combo swings. Negative swings slower.
@export var swing_speed_bonus: float = 0.0
# How much longer a dodge lasts.
@export var dodge_length_bonus: float = 0.0
# Pills added to every heal that restores anything.
@export var heal_bonus: int = 0
# Extra Pension from regular enemies, on top of the general pension_bonus.
@export var enemy_pension_bonus: float = 0.0
# Extra Pension from chests, treasure and bosses, on top of the general pension_bonus.
@export var reward_pension_bonus: float = 0.0
# Extra cane damage to enemies below half health.
@export var wounded_damage_bonus: float = 0.0
# Whether secret rooms show on the map before they are found.
@export var reveals_secrets: bool = false
# How much wider a Thermos blast reaches.
@export var blast_radius_bonus: float = 0.0
# Thermoses added at the start of each run.
@export var bonus_bombs: int = 0
# Seconds cut from how long the thrown dentures lie before coming back.
@export var teeth_return_cut: float = 0.0
# The Waiting Room's deep-floor forms and the deep floors' poster rewards.
# How much quicker a charged swing charges, as a fraction of its usual time.
@export var charge_time_cut: float = 0.0
# Extra damage a charged swing does, as a fraction of its base.
@export var charge_damage_bonus: float = 0.0
# How much cheaper everything in a run's shop is, as a fraction of its price.
@export var shop_discount: float = 0.0
# Extra Pension from bosses, on top of the general and reward bonuses.
@export var boss_pension_bonus: float = 0.0
# The chance that a swing does double damage.
@export var lucky_swing_chance: float = 0.0
# How many hits that would finish him leave him one pill instead, once more on every floor.
@export var floor_lethal_saves: int = 0
# The share of a run's Pension paid again when he dies in it.
@export var death_pension_bonus: float = 0.0
# The hundred items' always-on rules. Whether a wet floor never slides him.
@export var wet_grip: bool = false
# The least share of his speed any slow leaves him (sedatives, sticky trails, quoits, paper). Zero for none.
@export var min_slow_factor: float = 0.0
# Whether enemies he finishes skip their harmful last acts, such as a death blast.
@export var clean_kills: bool = false
# Whether arrows at the screen's edge point to enemies off screen.
@export var shows_offscreen_enemies: bool = false
# How much further his swings knock enemies back, as a fraction of their push.
@export var swing_push_bonus: float = 0.0
# Seconds the thrown dentures stay glued to the first enemy they bite, biting on. Zero for none.
@export var teeth_glue_time: float = 0.0
# Whether the thrown dentures fly back by themselves, biting on the way.
@export var teeth_boomerang: bool = false
# Whether the dentures lying on the floor bite whatever walks over them.
@export var teeth_floor_bite: bool = false
# Sets of dentures thrown at once. Zero leaves the usual one.
@export var teeth_sets: int = 0
# Dodges he can make back to back, on top of the usual one (Velcro Shoes).
@export var bonus_dodge_charges: int = 0
# Whether charging a swing leaves his walk at full speed (Levitation Slippers).
@export var charge_full_speed: bool = false
# How much further sleeping enemies notice him, and how much sooner a room's enemies stop waiting, as a
# fraction (Squeaky Shoes).
@export var notice_bonus: float = 0.0
# Whether a dodge steps round a prop's corner as a walk does (Bunion Pads).
@export var dodge_rounds_corners: bool = false
# Whether slides and pushes leave him where he stands (Gravity Boots).
@export var steady_feet: bool = false
# How much nearer he must stand to a heal on the floor to take it, as a fraction (Pill Crusher).
@export var heal_reach_cut: float = 0.0
# The third batch. The most pills he may hold, whatever else adds them. Zero for no cap (Do Not
# Resuscitate Bracelet).
@export var max_pills_cap: int = 0
# Seconds added to a Thermos's fuse (Pressure Cooker).
@export var fuse_bonus: float = 0.0
# Items a shop sells on top of its usual ones (Ticket Stub Book).
@export var shop_extra_items: int = 0
# How much dearer everything in a shop is, as a fraction of its price (Lucky Seat Ticket).
@export var shop_markup: float = 0.0
# How much more an Arcade win pays of its winnings, as a fraction, at every table (Lucky Seat Ticket) and
# at the poker table alone (Card Shark).
@export var arcade_win_bonus: float = 0.0
@export var poker_win_bonus: float = 0.0
# How much further coins fly to him, as a fraction of their usual reach (Penny Jar).
@export var coin_reach_bonus: float = 0.0
# How much further the light around him reaches in the dark, as a fraction (Night Light), and whether
# rooms never go dark at all (Night Shift).
@export var dark_light_bonus: float = 0.0
@export var never_dark: bool = false
# The fourth batch. Whether the map shows every room of a floor on arrival, not what is in them (Floor
# Plan), and whether it shows the boss rooms and their bosses' names (Fortune Teller's Card).
@export var shows_floor_plan: bool = false
@export var names_bosses: bool = false
# Pixels the camera looks ahead of him, the way he aims (Telescope Cane).
@export var look_ahead_bonus: float = 0.0
