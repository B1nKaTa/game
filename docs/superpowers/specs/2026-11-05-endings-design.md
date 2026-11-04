# Endings design

Approved in conversation on 2026-11-05. It builds on `deep-floors`, which has floors 4 and 5, the
Chairman of the Board as the final boss, and a one-off `EndingCard`. This spec replaces that card.
Every earlier spec's ground rules still apply. Art stays code-drawn placeholder until the art pass.

## Ground rules

- **Other games:** never name one in any file, comment, asset name or commit message.
- **Dependencies:** none new.
- **Saves:** old saves load. Every new save field is optional and has a fallback. A save with
  `ending_seen = true` counts the Briefly Alive ending (#1) as found.
- **Housekeeping:** keep the project runnable after every commit, and keep `LESSONS.md` up to date.
- **Tone:** dark comedy, in the voice of the opening (`scripts/scenes/opening.gd`). The scene texts
  below are drafts, so tighten them, but keep every joke.

## 1. The story

Harold, 87, died falling down the stairs, and he wants to go back to finish his 40-year feud with his
neighbour, **Gerald**. Beating the Chairman sends Harold back to life. Life kills him again soon
after, and he lands back in the Waiting Room queue. That is why runs go on after an ending.

## 2. The ten endings

The ending is chosen the moment the Chairman (`chairman_of_the_board`) falls, from what the run did.

| # | id | Title | Condition (checked in this order) |
|---|---|---|---|
| 10 | `eternal_feud` | Eternal Feud | 5 or more of endings 2 to 9 found, and this ending not found yet |
| 2 | `new_management` | Under New Management | no pill lost in the Chairman's room |
| 3 | `crashing_the_funeral` | Crashing the Funeral | the run's play time is at most `FAST_RUN_SECONDS` (start at 2100, to tune by testing) |
| 4 | `fortune_and_glory` | Fortune and Glory | Pension earned this run is at least `FORTUNE_PENSION` (start at 2500, to tune by testing) |
| 5 | `excess_baggage` | Excess Baggage | holding at least `BAGGAGE_ITEMS` items (start at 12) |
| 6 | `house_always_wins` | The House Always Wins | won at least one game on at least 3 Arcade or Back Room visits this run |
| 7 | `literally` | Back from the Dead (Literally) | this run is on a cursed ticket |
| 8 | `by_a_thread` | By a Thread | exactly 1 pill left when the Chairman falls |
| 9 | `scenic_route` | The Scenic Route | the run took the east path at every depth (cemetery, furnace_works, golden_years_mall, fairways_end, head_office) |
| 1 | `briefly_alive` | Briefly Alive | otherwise |

**Choosing among several.** Collect every ending whose condition holds and pick the first **not yet
found**, in the table's order. If every one that holds is already found, pick the first in the table's
order. Briefly Alive is always eligible, so there is always an answer. Eternal Feud plays once, when it
first becomes due. After that it counts as found and drops out of the choosing.

**`EndingRules`** is a pure `RefCounted` with static functions. It takes a small snapshot of the run
and the found set, and returns an id. Test it headless for every condition, for the order, for the
unfound-first rule and for Eternal Feud's count.

**The run snapshot** needs these values. Add any that `RunState` doesn't track yet as run-only
fields, never saved in Progress:
- **Pills:** pills left, and whether a pill was lost in the boss room.
- **Run time:** play time, counted only while the run is unpaused and in a floor.
- **Pension and items:** Pension earned this run, and the items held.
- **Arcade visits won:** each visit counts once, and only if at least one game on it paid out more
  than its bet.
- **The ticket:** whether it is cursed.
- **The path taken at each depth.**

## 3. The scenes

Each ending is a short **in-engine scene played like a puppet show**:
- a small stage drawn in code;
- Harold played by his real sprite and animations (`art/sprites/grandpa`, walk and idle);
- Gerald and any other actors drawn in code like the NPCs;
- text boxes along the bottom;
- simple camera moves and fades.

Each scene lasts 25 to 45 seconds. Any key or click moves the current text on. Holding interact for
1 second skips the whole scene. The first time an ending plays, the skip is offered only after the
first text box.

**A scene script system.** `CutscenePlayer`, a node, plays a list of steps, and every ending is a
data list of steps in `scripts/content/endings/<id>.gd` (or `.tres`, whichever reads more simply).
The steps are:

| Step | Meaning |
|---|---|
| `stage(name)` | show a stage set: `stairs_home`, `fence`, `funeral`, `hospital`, `garage`, `gerald_house`, `airport_home`, `office_top`, `waiting_room` |
| `actor(id, at)` | place an actor (`harold`, `gerald`, `dealer`, `chairman`, `doctor`, `exterminator`, `mourners`) |
| `walk(id, to, speed)` | walk an actor to a point, playing his walk animation |
| `face(id, dir)` | turn |
| `anim(id, name)` | a one-shot: `swing`, `fall`, `sit_up`, `shake_fist`, `faint`, `float` |
| `say(id, text)` | a text box with the speaker's name; waits for a press or `SAY_TIME` |
| `card(text)` | full-width caption text, as in the opening |
| `wait(seconds)` | |
| `shake(amount, seconds)` | |
| `zoom(factor, seconds)` | |
| `fade_out(seconds)` / `fade_in(seconds)` | |
| `sound(name)` | optional, for later music and effects |

Gerald's placeholder:
- a thin old man in a tan cardigan with a comb-over and a scowl;
- clearly unlike Harold in colour and outline;
- drawn in code (`scripts/world/actor_look.gd`), so the art pass can swap in a sprite.

**Every scene ends the same way:**
- a `card` with the cause of death;
- a fade;
- the Waiting Room arrival with the notice "Welcome back. Please take a number."

The causes of death, by ending:

| Ending | Cause of death |
|---|---|
| 1 | "Cause of death: stairs. Again." |
| 2 | "Cause of death: paperwork." |
| 3 | "Cause of death: his own funeral." |
| 4 | "Cause of death: property tax." |
| 5 | "Cause of death: none. Status: haunting." |
| 6 | "Cause of death: the house." |
| 7 | "Cause of death: pest control." |
| 8 | "Cause of death: grapes." |
| 9 | "Cause of death: jet lag." |
| 10 | "Cause of death: Gerald." |

**Draft scripts** (each about 4 to 8 beats):

1. **Briefly Alive.** At the foot of the stairs at home, Harold wakes. Gerald, at the fence: "Harold?!
   They said you were dead!" Harold: "They were wrong." He walks to the fence and rings Gerald's
   ear with the cane. Gerald: "OW!" Harold turns, walks home, climbs the stairs, and falls.
2. **Under New Management.** At the top of the office, the Chairman bows: "Nobody has ever... I'm
   retiring." He hands over a gold gavel. Harold sits in the big chair. A file slides in: "GERALD,
   APPLICATION FOR ETERNAL REST." Harold stamps it: REST DENIED. He laughs, then slips off the swivel
   chair.
3. **Crashing the Funeral.** At the funeral, Gerald is at the lectern: "Harold was... adequate."
   The coffin lid creaks. Harold sits up: "ADEQUATE?!" The mourners faint. Harold climbs out, trips
   over the wreath, and falls back in. The lid shuts.
4. **Fortune and Glory.** At Gerald's house, Harold waves a cheque: "Sold!" Gerald is carried out
   by movers, protesting. Harold, inside: "Mine. All mine." A letter drops through the slot:
   "PROPERTY TAX: $41,000." Harold reads it and keels over.
5. **Excess Baggage.** At the return door in the Waiting Room, Harold, carrying every item, is stuck
   halfway. A clerk: "Sir, there's a weight limit." With a pop, Harold floats out as a ghost at
   Gerald's house. Gerald is in the bathroom. A spooky "Hello, Gerald." Gerald screams. The card
   reads "Harold now haunts Gerald's toilet. Forever."
6. **The House Always Wins.** In the garage, now a neon casino, Harold deals cards to Gerald.
   Gerald loses his shirt. The Dealer appears behind Harold: "Nice place. I'll take it from here."
   Harold is ushered out. The Dealer: "The house always wins." The garage door comes down on
   Harold.
7. **Back from the Dead (Literally).** At the fence, a green-tinged Harold lurches: "Braaains...
   and the lawnmower you borrowed in 1986." Gerald: "PEST CONTROL!" An exterminator arrives. Harold
   bites him. The exterminator sprays. Harold collapses.
8. **By a Thread.** In hospital, the doctor: "You were clinically dead for three minutes, Mr...
   Harold." Gerald walks in with grapes: "Get well soon." He sits and eats every grape, one by one.
   Harold, offended, chokes on the last one Gerald throws at him.
9. **The Scenic Route.** At the arrivals gate, Harold, sunburnt, in a novelty hat, carries
   souvenirs. At the fence he shows Gerald his photos. Gerald: "...I've never been anywhere."
   Harold: "I know." Jet lag hits, mid-gloat, and he falls asleep forever.
10. **Eternal Feud.** At the fence, Harold gloats. Gerald goes red: "You... you..." He clutches
    his chest and falls. Cut to the Waiting Room queue. A new soul takes a ticket: Gerald, number 1.
    Harold, behind him with number 2: "Finally." Gerald: "Oh, NO." The card: "Some feuds are eternal.
    Please take a number."

**The Augustine side ending** (Departures, `augustine`) is not one of the ten. On every win over
Augustine:
1. a short scene: he stamps a boarding pass, "ETERNAL REST. ONE WAY.";
2. Harold tears it up: "I'm not resting. I have business.";
3. "FLOOR CLEARED", and back to the Waiting Room.

Skippable as above, and shown in full only the first time. Later wins show just the stamp and the
tear.

## 4. After the true ending: Gerald in the Waiting Room

- **Where he stands:** once `eternal_feud` is found, Gerald stands in the Lobby as an NPC. Use the
  NpcDef opener rotation and moments: `died` and `boss_win`.
- **His lines:** he insults Harold's runs, takes credit for Harold's wins and complains about the
  forms. Write 12 to 15 lines in his voice, petty and proud.
- **Placement:** obey every Waiting Room placement rule (door cells, wall cells, lanterns, the HUD
  row, the trophy frames).

## 5. The Ending Archive

- **Where:** a filing cabinet station in the Executive Suite: "Ending Archive. Files 27B-1 to 27B-10".
- **The panel:** a list of the 10 endings.
  - A found ending shows its number, title and cause of death, with a Replay button.
  - A missing one shows "???" and its hint.
  - The panel has an opaque backing, fits 640x360, and scrolls if needed.
- **Hints** (one per ending, in the bureaucracy's voice):

  | # | Hint |
  |---|---|
  | 2 | "Applicant was not harmed during the interview." |
  | 3 | "Applicant arrived before his paperwork." |
  | 4 | "Applicant attempted to pay in cash." |
  | 5 | "Applicant arrived with too much luggage." |
  | 6 | "Applicant was seen at the tables. Often." |
  | 7 | "Applicant's ticket was cursed." |
  | 8 | "Applicant was hanging on by a thread." |
  | 9 | "Applicant took the long way round." |
  | 10 | "Find five other files." |

- **Replay** plays the scene, then returns to the panel, not to the Waiting Room arrival.
- **The Trophy Wall:** add a small "Endings found: N/10" line to the Trophy Wall's caption.

## 6. Rewards

- **Each new ending:** `ENDING_CONDOLENCES` (15) the first time it is found.
- **The true ending:** also unlocks a cosmetic, **Gerald's Hat**, a terrible bucket hat for Harold's
  hat slot. It is owned at once, ready to wear at the Decor Office.

## 7. Save

New optional fields in `ProgressData`: `endings_found: Dictionary` (id → true). Migration:
- `ending_seen` true and no `endings_found` means `endings_found = {"briefly_alive": true}`;
- keep `ending_seen` readable for old builds.

Run-only tracking lives in `RunState` and is never saved in Progress.

## 8. Replacing the EndingCard

`EndingCard` (`scripts/ui/ending_card.gd`) and its smoke check `_check_ending_card` become:
- the ending choice through `EndingRules`;
- the scene through `CutscenePlayer`;
- the arrival notice.

The smoke driver checks:
- beating the Chairman plays an ending scene, which it skips;
- a forced fast run plays Crashing the Funeral;
- the found set grows by one, and a second identical run picks Briefly Alive as already found;
- the run then returns to the Waiting Room.

## 9. Build order

1. `EndingRules` and the run snapshot tracking, with tests.
2. `CutscenePlayer` and the step list, with tests for the step timing and the skip.
3. Stages, actors (Gerald's look) and the ten scripts, plus Augustine's side scene.
4. The Ending Archive, the Trophy Wall count, the rewards and Gerald in the Waiting Room.
5. The full loop updated. Screenshots of every scene in a real window at its busiest moment, each
   opened and looked at. Then an independent review.

## Testing

- **Headless tests** for every rule, as above.
- **The full loop** passes, run in copies on D: with their own `config/name`.
- **Screenshots in a real window:**
  - every scene at its busiest moment;
  - Gerald next to Harold;
  - the archive, both empty and full;
  - the Waiting Room with Gerald in the Lobby.
- **The real save's MD5** is unchanged across every session.
