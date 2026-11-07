# Friends Playtest Plan

The fourth stage of the roadmap: content, then art, then testing, then the friends playtest, then Steam.
Its job is to learn what a person who has never seen Grandpa does with it,
and to find the bugs that only show up on other people's PCs.

## 1. Pre-flight check (before any friend gets the build)

The first friend test failed before it started: the window came out bigger than the friend's screen and cut off the HUD.
Nothing on the development PC showed it. So every build is checked on a second setup first.

- [ ] Build the release exe from a tagged commit. Write down the build id (version and short commit).
- [ ] Zip `Grandpa.exe` alone as `Grandpa-<build id>.zip`.
- [ ] Copy the zip to a **second PC, or a second display setup**, through a download or a USB stick, not a shared folder, so Windows treats it as a stranger's file.
- [ ] On that setup, with no old settings or saves (rename `%APPDATA%\Godot\app_userdata\Grandpa` out of the way first):
  - [ ] SmartScreen shows, and "More info, then Run anyway" starts the game.
  - [ ] The whole window and HUD fit on the screen, in windowed and fullscreen. F11 and Alt+Enter switch between them.
  - [ ] Try at least one of: a laptop at 1366x768 or 1280x720, Windows scaling at 125% or 150%, a second monitor of a different size, an ultrawide.
  - [ ] Keyboard and mouse work. A controller works, if one is at hand.
  - [ ] Start a run, clear a room, die or quit, start the game again: the save and settings came back.
  - [ ] `display_log.txt` and the `logs` folder exist and name the screens and the build id.
- [ ] Only then send the build.

## 2. Handing out the build

Send each friend the zip and this short note (edit freely):

> Thanks for playing Grandpa! It is an early build, so expect rough art and bugs.
>
> 1. Unzip `Grandpa-<build>.zip` anywhere, for example your Desktop.
> 2. Double-click `Grandpa.exe`.
> 3. Windows will say "Windows protected your PC". This is because the game is not signed yet. Click **More info**, then **Run anyway**.
> 4. If the window does not fit your screen, press **F11** or **Alt+Enter**, and tell me.
> 5. Play for 30 to 60 minutes, then fill in the questions I sent.
> 6. If something breaks, send me the files described under "Bug report".

- Give each friend the same build. If a fix is needed mid-test, give it a new build id and note who has which.
- Keep a short list: who, which build, date sent, PC (screen size, laptop or desktop, pad or keyboard).

## 3. What to ask players to do

Ask them to play the way they would at home. Do not explain the game first: what they miss without help is the main finding.

1. Start a new game and play from the title screen, without being told the controls.
2. Play until they have died at least three times, or 45 minutes have passed.
3. Look at the options once, and try the Attack warnings setting if they find the fights hard.
4. If they can, play once with a controller.
5. If they want, record their screen and talk out loud while they play (OBS or the Windows Game Bar). This shows more than any form.

If watching in person or on a call: say nothing, note where they stop, look lost, or lean in, and only help if they are stuck for over two minutes.

## 4. Feedback form

Keep it short. Send it as a message or a simple online form after they play.

1. Roughly how long did you play, and how far did you get (which floor)?
2. In your own words, what is the game about and what are you trying to do?
3. Did the controls make sense? Was anything hard to find out (dodge, throw, Thermos, the potion)?
4. How hard was it? Too easy / about right / too hard. Where did it feel unfair?
5. Did you see attacks coming? Was any attack a surprise? Did you use the Attack warnings setting?
6. Was anything hard to read: text, icons, enemies against the floor, the map?
7. Did you understand what Pension is for and what to buy in the Waiting Room?
8. What was the best moment? What was the most annoying?
9. Did it ever stutter, freeze or crash?
10. Would you play another run? Would you buy it, and what would feel like a fair price?
11. Your screen size, and keyboard and mouse or controller?
12. Anything else?

## 5. Bug report

Ask for one message per bug. Copy this for them:

```
What happened:
What I expected:
Steps (what I did just before):
Floor and room (name on the map, or describe it):
How often: once / sometimes / every time
Build id (title screen corner, or the zip's name):
Screenshot or short video, if you have one:
```

And attach these files:
- `%APPDATA%\Godot\app_userdata\Grandpa\display_log.txt`
- the folder `%APPDATA%\Godot\app_userdata\Grandpa\logs`

To find them: press Win+R, paste `%APPDATA%\Godot\app_userdata\Grandpa`, press Enter, and zip `display_log.txt` and the `logs` folder.
Ask them not to send `save.json` unless asked: it is only needed for bugs about progress.

If the build id is not shown in the game yet, add it to the title screen before the test (see the launch checklist, section 3).

## 6. What to watch for

In order of importance for this stage:

1. **Crashes and blockers.** Anything that ends a run or loses a save.
2. **The window and display.** Does it fit, in windowed and fullscreen, on every friend's screen? Check every `display_log.txt` that comes back, even with no complaint.
3. **Difficulty with warnings hidden.** The bot tests read every warning perfectly; people do not. Note whether players who leave Attack warnings at its default die to attacks they never saw, and whether turning it on changes that. The open balance questions in `docs/playtest-notes.md` (the cruise and terminal floors as walls, whether the Chairman is hard enough, the Adjuster as a wall for slower players) are the ones to confirm or close.
4. **Readability.** Enemies against busy floors, small HUD text, warnings in a crowd, dark rooms. Ask for screenshots of anything hard to read.
5. **Controls.** What they press first, what they never find, whether rebinding is needed, whether a pad works everywhere.
6. **Performance.** Stutters in large rooms or boss fights, especially on laptops. Ask for their PC's graphics card if anything stutters.
7. **Understanding.** Whether they get the Waiting Room, Pension, items and the two paths without help.

## 7. Collecting and triage

Keep everything in one place: a new section in `docs/playtest-notes.md` per playtest round, with a list of reports below it.

After each round:

1. **Gather.** Put every form, bug and log under the round's heading, one line each, with who and which build.
2. **Sort each item into one of four groups:**
   - **Bug**: something is broken (a crash, a stuck run, a wrong number).
   - **Balance**: a number feels wrong (too hard, too slow, too cheap).
   - **Design**: players misunderstand or dislike how something works.
   - **Polish**: small friction to fix later.
3. **Rate bugs by how bad they are:**
   - **Critical**: crash, lost save, or a run cannot go on. Fix before the next build goes out.
   - **High**: a major thing is broken but the game goes on. Fix before the next round.
   - **Medium**: wrong but has a workaround. Plan it.
   - **Low**: looks wrong, no effect on play. Fix when convenient.
4. **Count, don't guess.** One friend's opinion is a note; the same point from three friends is a change. Write the count next to each item.
5. **Feed the plan.** Critical and High bugs become the next fix round. Balance and Design items go to the next plan in `docs/superpowers/plans/`, with the playtest as the reason. Add any gotcha to `LESSONS.md`.
6. **Close the loop.** Tell friends what changed because of them, and send the next build with its new id.

The stage is done when a round comes back with no Critical or High bugs, the window fits on every friend's PC, and the difficulty answers are mostly "about right". Then the Steam checklist (`docs/release/steam-launch-checklist.md`) takes over.

---

Sources: ideas taken from the "Claude Code Game Studios" template by Donchitos (playtest report, bug report and bug triage templates), https://github.com/Donchitos/Claude-Code-Game-Studios. SmartScreen background: https://learn.microsoft.com/windows/apps/package-and-deploy/smartscreen-reputation.
