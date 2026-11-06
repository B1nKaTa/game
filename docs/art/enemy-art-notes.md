# Enemy Art Notes

The decisions made while wiring the enemy art, with a verdict for each enemy. The user handed every decision to the agent doing the work. The hooks and strip conventions are in `art-inventory.md` section 1.9.

## 2026-11-06: the redraws

Seven enemies from the second batch's "For regeneration" list were drawn again in PixelLab and replaced their exports. Each old export is kept in `D:\grandpa-art\enemies\_old\<id>\`, and `ids.txt` names the new characters. This closes the Mortimer, Senior Adjuster and small-bodied items on that list. lost_luggage is still open.

| Enemy | PixelLab id | Canvas | What changed |
|---|---|---|---|
| mortimer_grimsby | ecdd4150-5775-49af-a85d-ccc46067c957 | 88 | A slate-grey frock coat in place of the black one |
| senior_adjuster | 2ed1eb0b-f0db-4a30-b1fd-01b769c8fe86 | 64 | A grey hooded robe in place of the crimson one |
| tour_group | fbcebc57-2d75-461b-aae2-c48f1961ad43 | 36 | Smaller, matching its 14x18 body |
| seasonal_temp | 712e5aa5-563d-4bf1-a33b-13b6b56330bc | 32 | Smaller, now a grey hoodie with lime trim |
| yes_man | 49639c5b-76d8-4fb0-a8b9-5ec5d4a6ecc5 | 36 | Smaller |
| weeping_mourner | b3ddde62-bd91-4390-8620-b626002eb8cd | 36 | Smaller, now in a mauve veil |
| early_bird_diner | 15ccfd24-e992-4559-8ae6-e0fa3dbfe8f3 | 36 | Smaller |

### Anims

- Every one has an east idle (breathing-idle), walk (walking-6-frames) and attack (v3 custom, 8 frames), the same set as its old export. Mortimer also has `embalming_spray` and `conduct` (v3 custom), as before.
- Each attack was described from the behavior:
  - Mortimer: arms raised and slammed down, for the casket.
  - Senior Adjuster: a wide sweep.
  - Tour Group: a braced crouch, then a rush.
  - Seasonal Temp: a hunch, then a lunging swipe.
  - Yes-Man: a crouch, then a lunge with the clipboard out.
  - Weeping Mourner: a wail, then a lunge with the arms out.
  - Early Bird Diner: a hunch over the tray, then a rush.
- Mortimer's first `conduct` turned him toward the viewer and drew stray blue props, so it was rerolled once. Nothing else needed a reroll.
- The cuts were picked again from labelled sheets of each attack and keyed to the new hashes in `CUTS`.

### Height

Each enemy's idle height in px, against Harold's 40:

| Enemy | Before | After |
|---|---|---|
| seasonal_temp | 44 | 29 |
| tour_group | 43 | 33 |
| yes_man | 43 | 35 |
| weeping_mourner | 45 | 28 |
| early_bird_diner | 41 | 32 |

The look probe now shoots these five beside Harold too (`BESIDE_HAROLD`).

### Luminance

Measured with the look probe. Shots are in `D:\grandpa-shots-r9\`.

| Enemy | Floor | Lift | Body luminance |
|---|---|---|---|
| mortimer_grimsby | Parlour | none | 0.29 |
| mortimer_grimsby | Parlour | 1.5 on 230 ±20 | 0.37 |
| mortimer_grimsby | Parlour | 1.75 on 230 ±20 | 0.45, but the coat washed to lavender |
| mortimer_grimsby | Parlour | **1.6 on 230 ±20 (kept)** | 0.40 and 0.42 in two runs |
| senior_adjuster | Records | **none (kept)** | 0.45 and 0.42 |
| seasonal_temp | Records | none | 0.48 |
| tour_group | Terminal | none | 0.55 |
| yes_man | Head Office | none | 0.62 |
| weeping_mourner | Parlour | none | 0.43 |
| early_bird_diner | Cruise | none | 0.61 |

- **Mortimer.** The slate coat is saturated enough (about 0.2) for a lift to work, unlike the black one. At 1.6 it reads as a grey coat under a dark hat on the red floor.
- **Senior Adjuster.** He needs no lift, so his 330 hue band went too.

### Variants

- **airport_weeping_mourner.** The new mauve veil sits near hue 290, outside the old 240 ±25 band, so the airport swap did nothing. It now swaps 290 to 200 ±25 and keeps no value lift (0.86, pale blue).
- **parlour_seasonal_temp and shores_seasonal_temp.** Both still find the lime trim at hue 90. They read cyan and violet (0.45 and 0.52), with less coloured area than before, since the hoodie is grey.

### Verdicts

| Enemy | Verdict |
|---|---|
| mortimer_grimsby | Good: a slate coat and a white baton. The casket slam, spray and conduct all read. |
| senior_adjuster | Good: a grey hooded robe on the grey Records floor. The outline carries it. |
| tour_group | Good: shorter than Harold. The rush reads. |
| seasonal_temp | Good: the smallest of the five |
| yes_man | Good: clearly shorter than Harold |
| weeping_mourner | Good: mauve on the red Parlour floor |
| early_bird_diner | Good: the tray rush reads |

## 2026-11-06: the second batch

38 new exports went in from `D:\grandpa-art\enemies\`, and the regenerated Regional Reaper replaced his first export. Every enemy outside the Mall and Fairway's End now has art. The Training Yard dummy is the only one without.

### Ids

- Every export folder matches a `data/enemies/<id>.tres` whose `id` is the same, so no id needed fixing.
- Every PixelLab id in `ids.txt` matches the character id in its folder's `metadata.json`. That includes the Resident, `1185e217-3e8e-46a6-9a28-ffc4b580ffd3`, so it has no typo.

### Decisions

- **Cuts.** Each windup and attack was picked off a labelled contact sheet of the attack, one cell per frame. The windup is the lead-in and the attack opens on the strike. All of them are listed in `CUTS` in `tools/art/enemy_strips.py`, keyed to the hash of each export's frames. Two of them are unusual:
  - **Burnt-Out Auditor.** His windup is his lit-fuse crawl (attack frames 3 to 8). His blast is code, and he is gone after it, so his attack is one frame.
  - **Head Groundskeeper and Shuffleboard Shark.** Each attack is the one release frame (8). Everything before it is the wind-up.
- **Mimic.** Its export opens the lid in the idle, but the attack barely moves. A sleeping mimic must look like a shut chest, so it works like this:
  - Its idle keeps only the shut frames (0 to 3, 7 and 8).
  - Its windup cracks the lid (idle 3 and 4).
  - Its lunge shows the lid wide open (idle 5, 6, 5).
  - These cuts carry a `replace` flag, so they win over the export's own windup and attack.
- **Objects that never turn.** The mimic, the Lost Luggage and the steam valve were drawn facing south, so `art_flips = false` keeps them from being mirrored. The tool reads `south/` when an anim has no `east/`. The paper shredder is drawn facing east and mirrors like the rest.
- **Bosses' own anims.** A boss calls `enemy.play_anim(name, windup + EnemyAnim.ATTACK_TIME)` right after it sets its warning. Each one starts on this move:

  | Boss | Anim | Move |
  |---|---|---|
  | Tired Undertaker | wreath_throw | wreath volleys |
  | Tired Undertaker | point | open graves |
  | Matron Mercy | lights_out | lights out |
  | Matron Mercy | charge | gurney dash (plays as the dash starts, for as long as it runs) |
  | Mortimer Grimsby | embalming_spray | spray |
  | Mortimer Grimsby | conduct | crescendo |
  | Commodore Wellington | foghorn_blast | foghorn |
  | Commodore Wellington | buoy_call | man overboard |
  | Augustine | runway_signal | runway |
  | Augustine | gate_change | gate change |

  - The driver lets an anim started this way run through the windup and the hit, in place of the plain windup and attack.
  - Nothing waits on these anims, and no timing changed.
  - None of the first ten exports has an anim of its own beyond the Mall Cop's whistle, so no play_anim calls were added for them.
- **Luminance.** Bodies were measured with the look probe, which compares the shot with the sprite hidden against the shot with it shown and leaves out the outline. Lighting moves between runs, because a room's decor seed follows the order it is entered in, so read these numbers to about ±0.05.
  - Lifts are `art_value` on each enemy's main hue band, with the hue kept the same.
  - After its lift, each enemy measured:

  | Enemy | Lift | Body luminance after |
  |---|---|---|
  | Tired Undertaker | 1.5 on 230 ±15 | 0.42 |
  | Foreman Klaus | 1.2 on 210 ±15 | 0.43 |
  | Mimic | 1.35 on 25 ±15 | 0.42 |
  | Commodore Wellington | 1.5 on 230 ±20 | 0.39 |
  | Pallbearer | 1.5 on 215 ±15 | 0.44 |
  | Senior Adjuster | 1.3 on 330 ±20 | 0.25, see below |
  | Mortimer Grimsby | 2.2 on 230 ±20 | 0.20, see below |

  - **Senior Adjuster.** He reads clearly in the shot, as a saturated crimson robe. A 1.5 lift turned the robe pink, so the lift stayed at 1.3.
- **Regional Reaper.** The regenerated robe is pale lavender. With the old 1.5 lift it washed out to near white, so the lift and its hue band were removed. His body measures 0.54.
- **Warning red (#e4524f).** The probe now prints the share of saturated body pixels within 12 degrees of the red's hue. Skin also falls inside that band, so judge the shot alongside the number.
  - **Activities Coordinator.** Her stripes were at hue 0. They now turn to 24 (tangerine, a band 8 wide), and her red share fell from 0.49 to 0.07.
  - **Sunburnt Sunbather.** His sunburn moved 10 degrees toward salmon (4 to 14, a band 10 wide). Awake, he reads clearly apart from the warning ring. His remaining red share is mostly the deck chair he hides under. That chair is code, with the stripe colour `d9576b` set in `SunbatherBehavior`, and was left as it was.
- **Variants.** Each variant takes its base's art and swaps its main colour toward the variant's own placeholder colour:

  | Variant | Base art | Hue swap |
  |---|---|---|
  | airport_weeping_mourner | weeping_mourner | 240 to 200 ±25, value 1.25 (pale airport blue) |
  | cruise_orderly | orderly | 175 to 220 ±25 (navy steward) |
  | furnace_burnt_out_auditor | burnt_out_auditor | 5 to 210 ±12, value 1.15 (sooty blue suit) |
  | office_florist | florist | 110 to 170 ±20 (teal) |
  | parlour_plot_holder | plot_holder | 5 to 40 ±12 (ochre) |
  | parlour_seasonal_temp | seasonal_temp | 90 to 185 ±20 (cyan) |
  | shores_seasonal_temp | seasonal_temp | 90 to 265 ±20, value 1.25 (violet) |
  | shores_denial_officer | denial_officer | 215 to 75 ±22 (olive) |

  - **The auditor's first swap.** It went to khaki, which still read orange under the furnace light, so it moved to blue.
  - **airport_mall_cop** keeps its green swap (215 to 150), off red.
  - **cruise_stoker** keeps its base's look.
  - **Left without art.** office_perfume_sprayer has none, because its base (perfume_sprayer) is Mall content with no export. golf_* and mall_* were left alone for the branch replacing those floors.

### Per-enemy verdict

Shots are in `D:\grandpa-shots-r8\`, each on its own floor. "Good" means the shape, the colour and the feet all read in the floor's light, and the windup and strike are caught.

| Enemy | Floor | Verdict |
|---|---|---|
| filing_clerk | Records | Good (0.43) |
| debt_ghost | Records | Good: the mint ghost reads well (0.65) |
| seasonal_temp | Records | Good colour (0.45). It is drawn as tall as Harold over a 13x15 body. |
| notary_public | Records | Good (0.36 by the number, reads clearly in purple) |
| burnt_out_auditor | Records | Good: the fuse crawl shows over the blast warning (0.43) |
| denial_officer | Records | Good. The shield arc still draws over him (0.59). |
| senior_adjuster | Records | Fair: crimson robe, lifted to 1.3. It reads, but its luminance stays low (0.25). |
| regional_reaper | Records | Good after the lift was removed (0.54) |
| plot_holder | Cemetery | Good: the mound, then the emerge and lunge |
| head_groundskeeper | Cemetery | Good (0.48) |
| tired_undertaker | Cemetery | Good after the lift (0.42). Point and wreath throw both read. |
| orderly | Sunset Shores | Good (0.51) |
| cart_nurse | Sunset Shores | Good (0.61) |
| bingo_caller | Sunset Shores | Good (0.51) |
| resident | Sunset Shores | Good (0.71) |
| activities_coordinator | Sunset Shores | Good once her red moved to orange (0.54) |
| matron_mercy | Sunset Shores | Good (0.68). Charge and lights-out both read. |
| mimic | Sunset Shores | Good: shut while asleep, lid open on the lunge (0.42 after the lift) |
| soot_ghost | Furnace | Good: smoke, then a beige body in the furnace light |
| foreman_klaus | Furnace | Good (0.43 after the lift) |
| steam_valve | Furnace | Good: the wheel turns over the vent warning (0.42) |
| weeping_mourner | Parlour | Good (0.55) |
| florist | Parlour | Good (0.50) |
| pallbearer | Parlour | Fair: small and dark-suited on red, 0.44 after the lift |
| reverend | Parlour | Good (0.66) |
| mortimer_grimsby | Parlour | Poor: a black coat on the red floor, 0.20 even at a 2.2 lift. He reads only as an outline with white gloves and shirt. **Regenerate.** |
| early_bird_diner | Cruise | Good (0.68). She is drawn large for a 16x20 body. |
| shuffleboard_shark | Cruise | Good (0.61) |
| sunburnt_sunbather | Cruise | Good. He hides under the code deck chair until he wakes (0.63). |
| lorraine | Cruise | Good (0.50) |
| commodore_wellington | Cruise | Good after the lift (0.39). The navy reads on the deck. |
| tour_group | Terminal | Good (0.58). It is drawn large for a 14x18 body. |
| baggage_handler | Terminal | Good (0.58) |
| lost_luggage | Terminal | Good: it never flips (0.66). It grins while "asleep", since there is no lying-asleep anim. |
| sergeant_wanda | Terminal | Good (0.45) |
| augustine | Terminal | Good (0.45). Runway signal and gate change both read. |
| yes_man | Head Office | Good (0.52) |
| paper_shredder | Head Office | Good: it mirrors as it walks west (0.74) |
| doreen | Head Office | Good (0.80) |

The variants all read in their own colour: airport mourner 0.66, cruise orderly 0.43, furnace auditor 0.39, office florist 0.75, parlour temp 0.44, shores temp 0.45, shores officer 0.64. The parlour plot holder showed as a mound in its idle shot; its emerged frames read ochre.

### For regeneration

- **mortimer_grimsby (must).** Redo him in a charcoal or slate-grey frock coat instead of black. Keep the top hat black, so the body clears 0.4 under the parlour's red light. He needs the same anims: attack, embalming_spray, conduct, idle and walk.
- **senior_adjuster (should).** A lighter, less saturated robe would let him pass 0.4 without the lift turning it pink.
- **Small-bodied enemies drawn full size (could).** These were all made on a 48 px canvas, so they stand as tall as Harold:
  - seasonal_temp (13x15 body)
  - tour_group (14x18)
  - yes_man, weeping_mourner and early_bird_diner (16x20)

  The inventory planned C32 or C36 canvases for them. They read well as they are, but their bodies are far smaller than they look. Regenerate them at 32 to 36 px if that matters in play.
- **lost_luggage (could).** A lying-asleep idle (eyes shut) for its LYING state would need a behavior play_anim or a state anim.

### Earlier enemies, re-measured in passing

old_smokey (0.30) and chairman_of_the_board (0.30) from the first batch are also under 0.4. They were not changed here.
