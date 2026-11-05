# The Flashback Cinema and the Séance Hotline

Date: 2026-11-06. Status: approved in brainstorming, awaiting spec review.

## Why

Eight of the ten paths are places in the business of death: records of the dead, a cemetery, a care home, a furnace, a funeral parlour, the last cruise, the final departures terminal and the head office of Eternity. Golden Years Mall at 7 a.m. (floor 3) and Fairway's End Golf Club at Midnight (floor 4) are ordinary retirement hobbies, with no afterlife angle, and they read as a different game. Both are replaced with new afterlife places.

## Decisions

- **Floor 3:** Golden Years Mall is replaced by **The Flashback Cinema**. It sits beside the Funeral Parlour, which stays.
- **Floor 4:** Fairway's End is replaced by **the Séance Hotline**. It sits beside the Last Resort Cruise, which stays.
- **No recycling:** the new paths are not reworded versions of existing places.
- **No endings in the content:** nothing in either path reveals or previews the endings. Harold's house, the place he is trying to get back to, never appears.
- **Life signs:** in the Cinema only.
- **Old items:** the 6 first-clear items of the two old paths keep their effects, but get new names and text for the new paths. The user can still change them in the item audit.
- **Old content is retired:** the old paths' unique enemies, bosses, rooms, props, palettes and music are removed. Shared enemies keep their base art.

## Ids and names

| Old id | New id | Display name |
|---|---|---|
| `golden_years_mall` | `flashback_cinema` | The Flashback Cinema, Last Showing |
| `fairways_end` | `seance_hotline` | Beyond Calling Psychic Hotline, Night Shift |

## Path 1: The Flashback Cinema (floor 3)

### Setting and look

An old art-deco picture house on its last night. Gold trim, deep teal carpet, plum velvet seat rows, and dust drifting in the projector beam.
- **No large red areas**, so warnings read (#e4524f) and the path stays distinct from the Parlour's wine red.
- **Lighting:** dim house lights, one warm projector beam, a cool glow from the screen, and small aisle lights in the floor.
- **Room features:**
  - Rows of seats are cover. They block movement and projectiles, like crates.
  - The screen wall is the north wall of every combat room.
  - Aisle carpet runners.
  - Pillars.

### The screen

- **What it shows:** every room's north wall holds a screen playing a looping "flashback" of Harold's everyday life. It is a still pixel-art scene in a sepia old-film style.
- **Drawn in code:** flicker, film grain, vertical scratches, a dust-filled projector beam from the south, and a slow cross-fade between 2 or 3 frames of the scene.
- **Purely decorative**, except during the Projectionist fight (below).
- **Scenes:** 12 to 15 of them, chosen per room from a pool. Each is a generic memory:
  - the hedge feud with Gerald, 1974;
  - walking Biscuit the dog;
  - his first car;
  - a works do;
  - a family Christmas;
  - fixing a fence badly;
  - his retirement cake;
  - a seaside day;
  - a lost umbrella;
  - learning to dance;
  - a burnt Sunday roast;
  - and so on.

  None shows the endings or his house as a goal.

### Life signs

- **What they are:** each Cinema room has one small framed lobby card on a wall or easel. Walking near it shows one line of text in the existing speech or notice style. Walking away hides it. It never pauses play.
- **The writing:** a pool of 40 lines, about the Gerald feud, Biscuit the dog, work, small wins and small failures. Examples:
  - "1974. The hedge went up. Gerald says it's on his side. It isn't."
  - "Biscuit, every morning at seven. Same bench. Same pigeon. Neither of them ever won."
  - "Forty-one years at the depot. One clock. He was never late. The clock was."
- **No repeats in a run:** each line is shown at most once per run, picked by the run seed.
- **Saved:** lines seen are kept in the save, as a new optional key with a default, so a later run favours unseen lines.

### Regular enemies

| id | Name | Body | Behaviour |
|---|---|---|---|
| `usher` | Usher | 20x26 | Patrols the aisles with a torch. A pale beam cone shows where he looks. If Harold stays in the cone for 0.6 s, he winds up ("Shh!") and charges along the beam's line. |
| `popcorn_vendor` | Popcorn Vendor | 18x24 | Keeps distance and lobs a popcorn tub in an arc at a marked spot. It bursts into a ring of 6 kernels. |
| `film_reel` | Runaway Film Reel | 18x18 | Rolls in a straight line and bounces off walls and seats. It leaves a film strip trail that slows Harold, like the existing wet or sticky floor, and the trail fades after 4 s. It turns 90 degrees toward Harold on each bounce. It is not a humanoid; its art is an object. |

**Shared:** `cinema_intern_reaper` and `cinema_notary_public` replace the Mall recolours.

**Summon:** `extra`, a grey black-and-white film extra who steps out of the screen. Fragile and quick, with a simple shove.

### Mini-boss: Cornelius Crabtree, Film Critic (`crabtree`, 32x40)

- **Star rating:** announces a rating of 1 to 5 and throws a fan of that many stars. Low ratings are a narrow fan; high ratings are wide but slower.
- **Thumbs down:** a windup, then a ground stomp ring.
- **Bad review:** summons 2 or 3 Extras as hecklers.

### Boss: the Projectionist (`projectionist`, 44x52)

- **Reel change:** the screen cuts to black with a warning tone and a flash on the screen. The next reel sets a room hazard for about 8 s:
  - **Rain reel:** the floor is slippery, using the existing wet-floor rules.
  - **Silent comedy:** pies are thrown down lanes, with the lanes warned first.
  - **Western:** tumbleweeds roll along lanes.

  It never repeats the same reel twice in a row.
- **Lens beam:** a projector beam sweeps across the room like a searchlight. The beam is a telegraphed lane that turns, and touching it hurts. It uses OverlapRoute so a safe route always exists.
- **Splice:** film strips mark 2 or 3 lanes, which snap shut after a warning.
- **Phase 2, below half health:** the film catches fire. A white burn ring grows slowly from the screen, while reel changes and splices continue at a faster pace.
- **Difficulty:** the Mall Santa's slot. The bot's win rate should be within about 20% of the Mall Santa's current number in the same session.

The reel genres are film genres, not Harold's memories.

## Path 2: The Séance Hotline (floor 4)

### Setting and look

"Beyond Calling", a psychic phone line on the night shift. Rows of cubicles, lava lamps, beaded curtains, ringing phones, crystal balls on desks, and green ectoplasm drips on violet carpet.
- **Lighting:** violet and teal ambient, candle-warm desk lights, and the green glow of phone displays.
- **No large green areas near the floor at the safe-spot mint (#7fe0a0).** Ectoplasm is a deeper, darker green.
- **Room features:** cubicle partitions as cover, desks, filing trays, and a séance table in large rooms.

### Regular enemies

| id | Name | Body | Behaviour |
|---|---|---|---|
| `phone_psychic` | Phone Psychic | 18x24 | "I sense you": a ring marks Harold's spot. After 0.7 s, a phone cord lashes in an arc across that spot. |
| `crystal_gazer` | Crystal Gazer | 18x24 | Releases a glowing crystal ball that slowly homes in on Harold for 3 s, then bursts in a small ring, or bursts sooner if it hits cover. |
| `poltergeist` | Poltergeist on Hold | 18x22 | A faint ghost that uses ghost contact (no contact damage) and hurls desk objects (stapler, mug, fax) along a warned line. |

**Shared:** `seance_intern_reaper` and `seance_notary_public` replace the golf recolours, if golf had them. Otherwise use the same pattern as the Cruise.

**Summon:** `ectoplasm`, a slow green blob that leaves a short sticky trail.

### Mini-boss: Sister Celestine, Tarot Reader (`celestine`, 32x40)

She deals 3 cards face down on the floor in front of her and turns them over one at a time. Each turned card shows its symbol briefly before it acts:
- **The Tower:** ceiling tiles fall on marked squares.
- **Death:** a scythe sweep through a marked arc.
- **The Wheel:** a spinning ring around her.
- **The Star:** marked spots of light rain down.

It never deals 3 of the same card.

### Boss: Madame Zara, the Medium (`madame_zara`, 44x52)

- **On the line:** a phone cord tethers Harold to a point. A marked circle shows first, then for 3 s he cannot leave it while other attacks run. It is never used together with a lethal lane that has no gap inside the circle; OverlapRoute checks the circle has a safe spot.
- **Ouija board:** the floor shows a letter grid, and the planchette slides from letter to letter along a path previewed in advance. Touching it hurts.
- **Possession:** a ghostly copy of Harold replays his last 2 s of movement, and touching it hurts. It lasts 4 s.
- **Phase 2, the séance circle, below half health:** the candles go out except for a ring of light around a slowly drifting point. Spirits circle outside the ring and attack anything outside it. The circle is a different shape from Matron Mercy's Lights Out: it moves, it is wider, and the rest of the room is dim, not black.
- **No hold music:** Zara has none, which stays Doreen's.
- **Difficulty:** Thaddeus's slot after contact damage. The bot's win rate should be within about 20% of Thaddeus's current number in the same session.

## Waiting Room, story and save changes

**Back Room** (the Dealer) now opens on the first Cinema clear instead of the Mall. No other change.

**The Pro Shop becomes the Crystal Counter.** It opens on the first Séance clear, run by a new NPC, **Esme, a crystal-shop keeper**. The department keeps its slot, its unlock flow and its stock logic. Duffy's art is retired. Its title and items are rethemed: gloves, tees and regrets become crystals, candles and incense with the same effects.

**Letters** in letter_book.gd are replaced:
- **Cinema:** "Your granddaughter: Grandpa, they showed your favourite film again. I saved you the aisle seat."
- **Séance:** "A psychic hotline: You've got one new message. It's from someone called Gerald. He says it's on his side."

**Mementos** in mementos.gd: new entries for the Projectionist and Madame Zara, with the same structure and new names, short names and effects themed to them. The two old entries are removed.

**Bounties:**
- the `gloria` and `mall_santa` bounties become `crabtree` and `projectionist`;
- the `chip` and `thaddeus_fairweather` bounties become `celestine` and `madame_zara`;
- each keeps its reward and changes only its floor_id.

**First-clear items:** brass_topper, coupon_booklet, hagglers_hat, hover_round, knitting_needles and loaded_dice keep their ids and effects, but get new display names and descriptions fitting the new path they come from, and their first_clear_path changes. For example, Coupon Booklet becomes "Ticket Stub Book".

**Music:** music_rules.gd maps the new ids to two new synth tracks in tools/music/songs.py:
- the Cinema: an old organ intermission theme;
- the Séance: a theremin-and-tremolo line.

The old Mall and golf songs are removed.

**Endings:** the depth 3 and 4 entries in SCENIC_PATHS move to the new ids, with the same rules.

**Lists of paths:** dev_start.gd ALL_PATHS, progress_data.gd PATHS_AT_DEPTH and the floor_scene.gd depth table use the new ids.

**Save migration (critical):** in the existing migration path, map every stored `golden_years_mall` to `flashback_cinema` and `fairways_end` to `seance_hotline`. This covers:
- cleared paths and first-clear flags;
- bounties;
- mementos;
- ending and scenic-route records;
- the run log and case-file history;
- department unlocks, and so on.

Further rules:
- **Run checkpoint on a retired path:** the run resumes at the start of that floor on the replacement path. Items, pills and money are kept.
- **Beaten bosses:** the old bosses' kills in the case file's bestiary stay as history entries, and their art falls back to a placeholder.
- **The .bak behaviour and atomic writes are unchanged.**
- **Tests:** an old-save fixture with Mall and golf progress, and a checkpoint on each.

## Rooms

- Each new path gets its own `data/rooms/<id>/` folder with the same room count and mix as the old paths: 33 each, covering combat, large combat, shop, treasure, mini-boss and boss rooms.
- Start from the old layouts' shapes, and change the obstacle placement to fit: seat rows in the Cinema, cubicle rows in the Séance.
- Every Cinema combat room has the screen on its north wall, and room for one life sign.

## Art

New art follows `docs/art/art-inventory.md` section 4. That means v3 at 48 px for regulars, 64 for the mini-bosses and 88 for the bosses, low top-down, a black outline, east-facing anims that are flipped, and the lighting rules in section 5.

New pieces:
- **Characters:**
  - the 3 regulars per path, plus the summon;
  - the mini-boss;
  - the boss with its signature anims;
  - Esme.
- **Objects:**
  - the film reel enemy;
  - the popcorn tub, kernels, pies, tumbleweed, crystal ball, stapler, mug, fax and tarot cards;
  - the planchette;
  - the props: seats, screen frame, aisle lights, pillars, cubicles, desks, lava lamp, beaded curtain and séance table.
- **Tile sets:** one per path.
- **Screen scenes:** 12 to 15 sepia memory scenes for the screen, at about 160x64 px (a landscape strip) or what fits the screen frame.

The Mall and golf characters already generated are kept on PixelLab and not used.

## Testing

**Unit tests:**
- every new attack;
- the 200-seed OverlapRoute checks for the Lens Beam, Splice, On the Line and the Ouija path;
- the tarot deal rules;
- the life signs: once per run, seen lines saved;
- the screen's scene choice;
- the save migration;
- the Waiting Room unlocks under the new ids.

**Removing old tests:** tests and probes that refer to the old ids are moved to the new ids or removed with their content.

**Full loops:** 2 or more, in `git archive` copies on D:.

**Bot batches:** the Projectionist against the Mall Santa's baseline, and Madame Zara against Thaddeus's, in the same session.

**Screenshots:**
- each new enemy and boss attack;
- the screen with flicker;
- a life sign;
- the Ouija board;
- the séance circle;
- both paths' rooms under their lighting.

## Out of scope

- Any change to the other eight paths.
- Item icons, which wait for the item audit.
- The Estate Sale idea, which is saved for a possible ending or late-game use. It is not built here.
