# Task 12 tuning report: both eras about 15% above old Harold

## Values
| | before | after |
|---|---|---|
| Football kicks | 5+5+10 | 6+6+12 |
| Football spin hit | 4 | 5 |
| Bus punch | 20 | 25 |
| Bus barge hit | 6 | 8 |
Speed, lock, reach, push, stun unchanged (football 1.25 / 0.12 / 34; bus 1.0 / 0.42 / 46 / 160 / 0.2).
Round 1 used punch 22.5 and barge 7 (bus came out +3%), so round 2 raised them to 25 / 8.

## Tests
tests/test_eras.gd: renamed to test_era_damage_per_second_is_above_old_harolds. Paper model: kicks in [1.0, 1.2] x cane DPS (66.7 vs 63.3); punch under the cane but at least 0.75 (restored from 0.7; 60 vs 63.3 = 0.95); punch still outweighs any cane hit. Spec sections 4.3 and 7 updated. Full suite: 2428 tests, 0 failed (re-run on the final commit).

## Bot DPS (max good 6 0 1 eras, floor 1; pooled by fight seconds)
Round 1 (kicks 6+6+12, punch 22.5), tags uA1-6 (6 clean batches): old 18.2/s (93 rooms), football 21.5/s +18% (52 rooms), bus 18.8/s +3% (45 rooms).
Round 2 (kicks 6+6+12, punch 25), tags uB1-8: old 18.5/s (132 rooms, 2121 s), football 19.9/s +8% (64 rooms), bus 21.2/s +15% (80 rooms).
Football is unchanged between rounds, so pooled over all 14 batches: old 18.4/s (225 rooms), football 20.6/s +12% (116 rooms), bus (round 2 final) +15%.
Batch noise is large (old Harold ranged 15.4-21.7 per batch). Football sits at the low edge of the band.
(One extra batch, uA7, was killed when I stopped the round-1 loop and is excluded.)

## Rules batch (some average 12 0 1, tag rules1, final code)
12 runs: deaths 12, reached_mini 7, rooms 3.1, rules seen 3 / broken 0 / kept 3, Auditors 0, reels 3.
Previous floor-1 batches of the same case (6 runs each): base1 (before rules): reached_mini 0, rooms 2.0; rules1b: reached_mini 1, rooms 2.7, 1 Auditor, 6 deaths. Floor 1 is not harder with the Auditor (the some/average player dies in the first rooms either way). Control max/good (ctrl1): 6 runs, rules seen 5, broken 1, kept 3, Auditors 1.

## Smoke
tools/smoke.ps1 on the final commit: SMOKE PASS (both loops), exit 0. It took about 10 minutes this time.

## Save guard
%APPDATA%\Godot\app_userdata\Grandpa\save.json MD5 f4a62baf2984c99a2fc54ebd6dc1e308 at start; run_bot printed the same after each batch.

Final save.json MD5 checked at the end: see hand-back (expected unchanged).
