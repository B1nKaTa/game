# Playtest-9 feedback

Real players' notes on build `0c234a7`, collected as they come in. Fix in batches, after reading them together.

## Player 1 (first 20 minutes, 2026-11-11)

1. **Enemies get stuck on objects.** A chasing enemy stood stuck against a crate beside the wall,
   swinging at nothing. Correction to the first note: enemies DO route around walls and props
   (`WalkGrid`, used by `Enemy.chase_direction`; 55 behaviour scripts use it). Only the shield enemy
   (`shield_behavior.gd`) walks straight at Harold. Likely causes, not yet reproduced: the shield
   enemy; or an enemy whose attack starts on distance alone, so it stands behind a prop and swings.
2. **The minimap hides part of the room.** The top-right minimap panel covers the room's corner, where
   pickups can sit. Wants it more transparent, or off the screen. Options already has Minimap
   opacity (20-100, default 100) and Hide minimap in combat (default off); the player did not find
   them.
3. **The big map does not show unexplored exits.** Visited rooms whose doors lead to rooms not yet
   seen give no sign of it, so the player cannot tell where is left to explore. Today the map draws a
   link only between two visited rooms.

## Player 1 (second set, 2026-11-11)

4. **A shop potion cannot be bought.** Standing on Topsy-Turvy Tonic (25) does nothing. Cause: a
   potion can only be taken with an empty potion slot (`RunState.can_take_potion`), and he carried one.
   The game gives no sign of why: no prompt, no message.
   **Decided (2026-11-11): swap.** With a potion already carried, a potion on the floor or in the shop
   shows "[E] Swap" when he stands at it. Pressing it takes the new one and lays the old one down
   where the new one was; in the shop he pays for the new one and the old one is not refunded. With a
   full slot the swap always needs the press, so walking over potions never swaps them back and
   forth.
5. **Brick blocks blend into the cobbled floor.** In a corner the bricks on the stone patch read as
   open floor; he walked in expecting a path and was nearly killed there. Art readability.
6. **The active item panel covers the top door's sign.** The `[R] Hearing Aid` panel at the top centre
   sits on the top door, so he could not tell what room lay behind it.
7. **Item names overlap.** Three items side by side in a treasure room print their names over each
   other ("Hospital B... Clipboard of Yo... Lightning Rod Cane"). His suggestion: show a name only
   when Harold stands next to the item.
8. **A run starts straight in a fight.** His suggestion: a safe first room with two or more doors.
   Today the floor's first room is the first room of the main path, a combat room
   (`FloorBuilder._try_build`, `map.start_id = map.main_path[0]`).
9. **Save and quit respawns broken props (exploit).** Continuing a run rebuilds every crate, barrel
   and block with fresh drops: unlimited coins, slips and thermoses. Cause: a room's checkpoint
   (`RoomView.snapshot`) keeps whether it was cleared and its items, stock and chests, but not which
   props were broken.
10. **A new pet appears only in the next room.** Cause: a pet's body is placed in `on_room_enter`
    only (`PetEffect`, and `moths.gd`); there is no `on_gain` placement.
11. **(The user, 2026-11-11) F does nothing when trying to start a reel.** `RuleKeeper.try_ready_reel`
    refuses silently in most cases: no reel held, an era already playing, a fight still on. The
    "Use a memory at a door to a room you haven't fought in" hint shows only once (`_hinted`), and every
    later miss says nothing.
    **Decided (2026-11-11): rework, not just messages.** The door step goes. F plays the held reel at
    once, anywhere in the room Harold stands in, also mid-fight ("walk in, see the danger, pop the
    reel"): sepia flicker, and he is the younger Harold on the spot. It lasts for that room only and
    ends as he leaves it. My additions, for the user to confirm: in a room with no fight left, F keeps
    the reel and says "Save it for a fight", so a stray press never wastes it; the Old Projector
    ("A flashback lasts one more room") stays the one way to carry it into the next room. Any other
    refusal (no reel, already remembering) says why, every time.

## Player 2 (first look, 2026-11-12; written in Bulgarian, translated)

"I liked the game at first look." Four small notes:

1. **The top HUD covers the walls, and in bigger rooms it covers enemies.** The same problem as
   Player 1's minimap note (2), for the whole top strip: Pension, items, active item, potion, minimap.
2. **Harold turns strangely.** "At the start, when you press A he faces ahead; then if you press D he
   doesn't turn, but he turns to look at the NPCs (I think he turns according to them)." Cause:
   with Mouse aim on (the default) Harold always faces the mouse cursor, not the way he walks
   (`Player._physics_process`, `_aim_point`). The player did not know he aims with the mouse; the
   cursor happened to sit near the NPCs.
3. **The lobby's portraits look scattered.** The ten boss portraits on the lobby's top wall
   (`TrophyWall`, name plates staggered on two heights) sit partly under the top HUD. His suggestion:
   make the room shorter so nothing lies under the HUD, and line the portraits up along the wall.
4. **The first boss spawns enemies quite fast** ("but that's on me, I'm slow"). "The first boss" is
   the first boss he met: the Senior Adjuster (mini boss) or the Regional Reaper (floor boss); both
   summon enemies. A feel note,
   not a bug. The user chose on 2026-11-11 to keep floor 1 as hard as it is, so no change unless
   other players say the same.

## Player 1 (third set, 2026-11-12: beat the game on the second run)

12. **Lightning Rod Cane shows no bolt.** The effect exists but is a pale blue disc 14 px across for
    0.3 s (`lightning_rod.gd`, `ItemFx.make_blast`), easy to miss under the hit flash. It needs a real
    bolt from above. Also confirm in a test that the bolt really lands (it depends on the charge flag
    still being set when the hit arrives).
13. **A door takes him into the boss room from far away (easy to repeat).** Holding only Left from a
    spot about 4 tiles up and right of the bottom (boss) door moved him into the boss room. A door
    enters at 18 px from its centre (`Door.ENTER_RADIUS`), and he stood about 60-100 px away, so the
    cause is not the radius alone. Not found from the code; reproduce it first. Highest priority of
    this set: it can drop a player into a boss fight unasked.
14. **The large item room is too empty.** Each floor has one item room at 30x17 cells
    (`data/rooms/*/item_large_01.tres`), with two items in a huge space. His suggestion: item rooms
    only in the smaller sizes. That means taking the ten large ones out of the item pool, not
    deleting them.
15. **Pet Rock text.** "Pet items make it bigger, and big enough it blocks shots." should read
    "Pet items make it bigger, and once big enough it blocks shots."
16. **Case file: "Shop discount" runs into its value** ("Shop discoun15%"). The label is too long for
    the stats column (`case_file_data.gd`). The labels need measuring against the column, as the map
    spec already asks.
17. **The ending's dialogue box looks cut off on the left** ("ugustine", "ETERNAL REST"), in the
    Departures ending. It may be the screenshot's crop; check that the box sits inside the screen.
18. **A charge carries into the next room.** "Not sure if it is intentional." It is not: the map, the
    case file, pause and the card table cancel a held charge (`floor_scene.gd`), but entering a room
    does not. Fix: cancel it in `_enter_room` too.
19. **Wants cheats for testers:** god mode, any item or potion, +99 slips and thermoses. "I wanna get
    wild with my testing."
20. **"Leave Canes at Reception" on floor 4: 15 enemies firing at him, so it was use the cane or die.**
    The no-cane rule can fall on any rule room, however many enemies it holds.
21. **Overall:** "fun as a whole but nothing phenomenal". Around floors 4-5 his build "got out of
    control and everything was too easy"; he beat the game on his second run (left paths only; the
    right paths were still locked). He tried the F flashbacks, saw them all, and "this was my favorite
    moment of the game".
