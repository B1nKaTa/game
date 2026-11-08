# The Flashback Cinema: life-sign lines by film

Written 2026-11-08 on branch `cinema-story`. The source of truth is `scripts/content/life_signs.gd` (`LifeSigns.ALL`); this page lists it by the film each line belongs to (`CinemaScenes`).

- A lobby card stands only in a room with a screen (combat, mini-boss and boss rooms), in the first row under the screen wall, just west of the picture.
- Its line is always one of the film that screen plays (`LifeSigns.take(..., scene_id)`), each line at most once a run, in the run seed's order, unseen lines first (`life_signs_seen`).
- A floor gives each screen its own film while unused films remain (`CinemaScenes.assign`), so every card has its film's two or three lines to itself.
- 19 films, 40 lines. Biscuit is named in 3 lines, Gerald in 7. Lines that kept their words kept their ids, so saves still know them.
- Nothing here touches what an ending shows: no stairs, sandwich, bath, ladder or bulb, armchair or television, grapes, roses, lawnmower, haunting, holiday snaps or golf, nothing about his house, and no promise; his wife is alive in the letters, so no line says otherwise.

## The hedge, 1974 (`hedge_1974`)

- `hedge_1974`: 1974. The hedge went up. Gerald says it's on his side. It isn't.
- `gerald_tape`: 1975. Gerald bought a tape measure. Harold bought a longer one.
- `gerald_trim`: Harold trimmed the hedge to the inch. Gerald trimmed his side to the inch and a quarter.

## Walking Biscuit (`biscuit_walk`)

- `biscuit_seven`: Biscuit, every morning at seven. Same bench. Same pigeon. Neither of them ever won.
- `biscuit_name`: He wanted to call the dog Rex. The children called him Biscuit. The dog sided with the children.

## His first car (`first_car`)

- `car_dent`: His first car cost forty pounds and came with a dent. He polished round the dent for six years.
- `small_driving_test`: Driving test, third attempt. The examiner shook his hand. Harold still thinks it was relief.

## The works do (`works_do`)

- `works_paper_hat`: The depot Christmas do: one paper hat, two sausage rolls, and the foreman's speech, twice.
- `depot_tea`: Tea at ten, tea at two, and tea whenever the foreman was out. Harold kept count. It was a lot.

## A family Christmas (`family_christmas`)

- `christmas_cracker`: Christmas. He read every cracker joke out loud, then explained it. Then explained it again.
- `christmas_turkey`: The year Biscuit got the turkey, they had cheese on toast and called it a tradition.

## Fixing the fence (`fence_fix`)

- `fence_lean`: He mended the fence on Saturday. By Sunday it leaned towards Gerald's. He called that a statement.
- `gerald_leaves`: Autumn. Gerald's leaves blew over the fence. Harold blew them back. It took all weekend. So did Gerald's.

## The retirement cake (`retirement_cake`)

- `depot_clock`: Forty-one years at the depot. One clock. He was never late. The clock was.
- `depot_watch`: They gave him a watch when he retired. It ran four minutes fast. He liked it better that way.

## A day at the seaside (`seaside_day`)

- `seaside_gull`: A day at the seaside: one ice cream, one gull, and one very short ice cream.
- `seaside_hanky`: A knotted hanky on his head and trousers rolled to the knee. He called it his summer suit.

## The lost umbrella (`lost_umbrella`)

- `small_umbrellas`: He left seventeen umbrellas on buses. Once he found one. It was not his. He kept it.
- `depot_lost_property`: Lost property at the depot: four hundred umbrellas, some false teeth and a trombone. Nobody came for the trombone.

## Learning to dance (`dance_lesson`)

- `small_foxtrot`: He learned the foxtrot to impress her, and remembered the first four steps for fifty years. It worked anyway.
- `dance_toes`: Saturday nights at the dance hall. He trod on her toes, said sorry, and asked her for the next one.

## The burnt Sunday roast (`burnt_roast`)

- `small_roast`: The Sunday roast: crisp outside, raw inside, carved with total confidence.
- `roast_alarm`: When the smoke alarm went off, the family took their seats. It meant dinner was ready.

## The pigeon on the bench (`pigeon_bench`)

- `pigeon_crumbs`: Every Tuesday, a bag of crumbs and the same pigeon. It never came closer. He never stopped trying.
- `pigeon_name`: He named the pigeon Reginald. Reginald never knew, and would not have cared.

## Painting the shed (`shed_painting`)

- `shed_green`: He painted the shed green in 1979. Then green again in 1980, because it was the wrong green.
- `shed_sign`: The shed had a chair, a radio and a sign saying KEEP OUT. The sign was mostly for Gerald.

## The bike lesson (`bike_lesson`)

- `bike_got_you`: Bike lessons. He ran behind holding the saddle, shouting 'I've got you!' He hadn't. They were fine.
- `bike_puncture`: He could mend anyone's puncture in four minutes. His own took forty, and he blamed a tree.

## The number 12 (`bus_route`) (new film)

- `depot_number_12`: He drove the number 12 for twenty years. He still tells strangers to mind the step.
- `bus_wave`: He waved at every bus coming the other way. Most drivers waved back. The rest got a second wave.

## The wedding (`wedding_day`) (new film)

- `wedding_hat`: His wedding day. The wind took his hat on the church steps. She caught it. He knew he'd chosen well.
- `wedding_suit`: He married in his brother's suit. His brother was taller. The pictures are mostly sleeve.
- `wedding_speech`: His wedding speech lasted nine seconds. Her mother called it the best she had ever heard.

## The prize marrow (`prize_marrow`) (new film)

- `gerald_marrow`: The village show. Gerald's marrow won by half an inch. Harold asked for a recount.
- `marrow_talk`: He talked to his marrows every evening. Over the fence, somebody took notes.

## The fishing trip (`fishing_trip`) (new film)

- `fishing_boot`: Thirty years of Sunday fishing: one boot, two bicycles, no fish. He called it a hobby.
- `fishing_flask`: He went fishing for the peace and quiet. The flask of tea did most of the work.

## The caravan holiday (`caravan_holiday`) (new film)

- `caravan_rain`: A week in a caravan by the sea. It rained for eight days. He called it a cracking week.
- `caravan_windbreak`: He put the windbreak up every morning. The wind took it every afternoon. Neither of them gave in.
