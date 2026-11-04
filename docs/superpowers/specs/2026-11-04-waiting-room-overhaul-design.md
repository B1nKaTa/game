# Waiting Room overhaul: design

Status: draft for review, 2026-11-04. Nothing here is built yet.

## Goal

The Waiting Room today is one flat 20×11 room. It holds four merchants, Agnes and the key board, and the seven upgrades are plain stat buys from a list. This design turns it into a place that grows with Grandpa's progress, gives him choices instead of stat bars, and rewards every boss in a way he can see.

## 1. Departments: the Waiting Room becomes a small floor

The Waiting Room is built from the same room grid and doors as the run floors, with no enemies. Each room is a department. The lobby is open from the start, and every other department sits behind a locked door that opens on the **first clear of its floor**, meaning the first time that floor's boss is beaten. When a door opens, a short arrival line plays the next time Grandpa enters the Waiting Room.

| Department | Opens on the first clear of | Holds |
|---|---|---|
| **Lobby** | (start) | Run door, ticket machine, noticeboard (letters), Black Market, Dr. Squint, Agnes, key board, trophy wall |
| **Bounty Office** | Records Basement | The bounty clerk and the wanted posters (section 4) |
| **Training Yard** | Unkempt Cemetery | The dummy, the item rack and the coach (section 5) |
| **Apothecary Wing** | Sunset Shores | Madame Murk moves here |
| **Boiler Room** | Furnace Works | Boom Bernard moves here |
| **Decor Office** | Eternal Rest Funeral Parlour | The cosmetic shop (section 7) |
| **Back Room** | Golden Years Mall | The Dealer's private table and the loadout bench (sections 8 and 9) |

Merchants keep their current unlock rules. Only the room each one stands in changes.

## 2. Upgrades become forms

Every permanent upgrade becomes a **form**. Buying a level means filing that form with Pension, and it gets a stamp: the panel shows the form and the stamp lands on it. Levels and prices stay as they are today.

**A choice at the milestone.** At one milestone level of each form, usually the middle one, Grandpa picks one of two options. Proposals:

| Form | Option A | Option B |
|---|---|---|
| Reinforced Cane | Heavy Head: more damage per swing, slightly slower | Lightweight: faster combo, slightly less damage |
| Better Knees | Long Stride: longer dodge | Quick Recovery: shorter dodge cooldown |
| Black Market Pills | One more pill | Pills heal more |
| Bribed Clerk | More Pension from enemies | More Pension from chests and bosses |
| Prescription Glasses | Bifocals: hits on a weak spot do more damage | Night Vision: secret rooms show on the map |
| Denture Adhesive | Bite: harder hits | Boomerang: the dentures come back faster |
| Questionable Fuel | Big Bang: larger blast | Spare Can: one more thermos charge |

**Refiling.** Grandpa can switch his choice at the forms counter for a flat fee (to tune).

## 3. Trophy wall

The trophy wall is in the lobby with an empty frame for every floor boss, so the frames still to fill are always in view. Beating a floor boss for the first time hangs that boss's memento in its frame, and each memento gives a small permanent perk. Proposals, with numbers to tune:

| Boss | Memento | Perk |
|---|---|---|
| Regional Reaper | Name badge | Start each run with 10 Pension |
| Mortimer, Tired Undertaker | Bent shovel | Breakables drop Pension a little more often |
| Matron Mercy | Bedpan | The first pill of each run heals one extra |
| Old Smokey | Coal shovel | Fire hazards hurt Grandpa less |
| Mortimer Grimsby | Top hat | +1 pill when entering a boss room |
| The Mall Santa | Empty sack | One extra chest option in treasure rooms |

Mini bosses give no memento. They are the bounty board's job (section 4).

## 4. The Bounty Office: wanted posters

A new NPC, the bounty clerk (name to be decided), keeps a board of wanted posters.

- **Which posters show up:** there is one poster for every mini boss and every floor boss, 12 today. A floor's posters appear once that floor is unlocked, meaning Grandpa can reach it.
- **One quest at a time:** Grandpa takes one poster at a time, and it **stays taken through death and new runs** until he beats that boss in any run.
- **Collecting the reward:** once he has won, he returns to the clerk to collect. The poster is then retired for good and can never be taken again.
- **Rewards:** every poster pays a **Pension lump sum**, larger for floor bosses, plus **Condolences** (section 7). Each poster also has one fixed extra reward, which is one of these:
  - a **unique item**, which then joins the run item pool
  - a **recipe** handed to Agnes
  - a **cosmetic**

  The extras are spread across the 12 posters, and which poster gives which is decided in the plan.

## 5. Training Yard

- **The dummy:** a grim reaper intern on a stand. It shows the damage of each hit and never dies.
- **The item rack:** it lists **every recipe Grandpa has earned**, including ones not yet crafted, so he can try an item before spending Pension on it. New recipes appear on the rack automatically.
  - Taking an item from the rack equips it for the yard only, and charges and consumables are unlimited there.
  - Everything taken is gone when Grandpa leaves the yard.
- **The coach:** a tutorial NPC. He gives a short tip for the item Grandpa is holding, and basic controls on the first visit. His lines will be written with the NPC dialogue.

## 6. Ticket number and letters

**Ticket number.** Grandpa's queue ticket goes up by one every run. At some numbers, for example every 5th run, the number is called and an event happens on his next return:

- **Clerk deal:** one form is discounted for this visit.
- **New arrival:** a merchant or NPC introduces themselves, or says a line.
- **Cursed ticket (opt-in):** the next run has tougher enemies and pays more Pension.

**Letters.** A letter from the living world arrives on the noticeboard after each first clear of a floor. It carries the story slowly, with no gameplay effect. The text will be written later.

## 7. Second currency: Condolences (cosmetic only)

There is a second currency, working name **Condolences**. It buys **only cosmetics and visual things, never gameplay power**.

**How Grandpa earns it:**
- from bounty rewards
- the first time he beats each mini boss and floor boss
- from the cursed ticket event
- as a rare drop from chests

It is never earned from regular enemies, so it stays special. Condolences carry over between runs and are never lost on death.

**Where he spends it:** at the Decor Office.
- **Waiting Room decor:** plants, posters, a better chair in the lobby, lighting, a fish tank, a different carpet. Each item visibly changes the department it is placed in.
- **Grandpa cosmetics:** hats, cardigan colours and cane skins. *To confirm:* whether cosmetics for Grandpa himself are in, or only decor for the Waiting Room.

The HUD in the Waiting Room shows both currencies. During runs it shows Pension only, plus a short pop-up when Condolences are earned.

## 8. The Dealer's back room

The Dealer already stands in the Arcade with placeholder lines. He becomes the Arcade's implied owner and coaxes Grandpa to play with funny lines, to be written with the NPC dialogue. Once the Golden Years Mall is cleared, he also keeps a private table in the Waiting Room's Back Room. *To confirm:* which games he plays there and whether the house edge is the same.

## 9. Loadout bench (later)

The loadout bench is for choosing what Grandpa starts a run with. It only matters once there is more than one weapon or more than one item that can start a run. Its place is reserved in the Back Room, and it gets built when a second weapon exists.

## Suggested build order

1. Departments, the lobby rebuilt on the room grid, and the trophy wall
2. Forms with the milestone choices and refiling
3. The Bounty Office and Condolences
4. The Training Yard
5. The Decor Office with the first decor set
6. The ticket number, letters and the Dealer's back room

Every step leaves the game playable and the save compatible. Upgrades already bought carry over, and each milestone choice starts at option A and can be switched once for free.

## Open questions

- Are cosmetics for Grandpa himself included, or only decor for the Waiting Room?
- Names: the bounty clerk, the coach, and the currency (working name "Condolences").
- Which posters pay a unique item, which a recipe and which a cosmetic.
- Two floor bosses are named Mortimer: the Tired Undertaker in the Cemetery and Mortimer Grimsby in the Funeral Parlour. Same man promoted, or a clash to rename?
- This should be built after floor 3 has been played and merged.
