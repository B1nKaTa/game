# Steam Launch Checklist

The last stage of the roadmap: content, then art, then testing, then the friends playtest, then Steam.
This list takes Grandpa from now to a Steam release, in the order the work should start.
Some items take weeks of waiting on Valve, so they start long before the game is done.

Marks used below:
- **(checked)** means the rule was read on Valve's or the vendor's own page on 2026-11-07.
- **(not verified)** means it is common practice or second-hand, and needs checking before relying on it.

## 0. Decisions needed soon

These drive everything else. Decide them before paying the fee.

- [ ] **A target release month.** Every date below counts back from it.
- [ ] **When to put up the Coming Soon page.** It needs at least the store assets and a few real screenshots, so it waits for the art pass. The longer it is up before release, the more wishlists it gathers (not verified, but widely reported).
- [ ] **The price.** See section 5.
- [ ] **Whether to add the Steamworks SDK.** Achievements and the Steam overlay need it. In Godot that means a GDExtension add-on, which is a new dependency. Cloud saves and Steam Input do not need it (see section 7).
- [ ] **A demo or not.** A demo is the usual way into Steam's festival events (not verified: check the current event rules).
- [ ] **The developer name and legal name** shown on the store. Identity, bank and tax details must match.

## 1. Steamworks account and app fee

Start this first. It is mostly waiting.

- [ ] Sign up at partner.steamgames.com and sign the digital paperwork.
- [ ] Pay the Steam Direct fee: **$100 per game**, not refundable. It is paid back once the game earns $1,000 in adjusted gross revenue. (checked)
- [ ] Finish identity, bank and tax details. Valve says this can take **15 to 30 days**. The legal name must match the bank account holder. (checked)
- [ ] Note the date the fee was paid. The game cannot release until **21 days** after it. (checked)
- [ ] Write down the App ID once Steam creates it. The build scripts and Auto-Cloud setup need it.

## 2. Licences, credits and AI disclosure

Do this early: a licence problem found late can mean redoing art.

- [ ] **PixelLab art.** Its terms (read 2026-11-07) say the user owns what they make and may use it commercially, and they do not separate free and paid plans. They also say the user is fully responsible for the content. (checked) Read the terms again just before release, save a copy with the date in `docs/release/`, and note which plan was active while the art was made.
- [ ] **Steam's AI question.** The content survey asks about AI-generated content that ships in the game. PixelLab art counts as **pre-generated** AI content and must be disclosed. Valve reviews it like any other content. (checked) The store page will show the disclosure to players.
- [ ] **Music and sound.** The music and effects are rendered from the project's own scripts in `tools/music` and `tools/sfx`. Confirm no sample, sound font or loop from elsewhere went into them. If one did, record its licence.
- [ ] **Fonts.** List every font the game draws with, including Godot's built-in default if it is still used, and its licence (not verified: check which font Godot 4.7's default theme embeds and its licence).
- [ ] **Godot engine.** Godot is MIT-licensed and the licence notice must ship with the game. Add a credits page or a licences text with the Godot notice and its third-party notices.
- [ ] **Credits screen.** Name, roles, tools, music and font credits, the Godot notice, and "Art made with PixelLab" if wanted.
- [ ] **Trademarks.** Search the name "Grandpa" and the store title for clashes. A subtitle may help with search and with clashes.

## 3. Game readiness

These are changes to the game itself. Most can be done during the content and art stages.

### Settings, resolution and ultrawide
- [ ] Defaults fit any screen. The first friend test failed because the window was bigger than the friend's screen. The window now sizes from its own screen and logs the screens it saw to `display_log.txt`. Keep that check in every release build.
- [ ] Test at 1280x720, 1280x800, 1920x1080, 2560x1440, 3840x2160 and one ultrawide (2560x1080 or 3440x1440). The view is 640x360 with integer scaling, so check the borders on screens that do not divide evenly, and on ultrawide.
- [ ] Fullscreen, windowed, and the toggle (F11, Alt+Enter) work, and survive a restart.
- [ ] Settings save and load. A broken or old `settings.cfg` falls back to defaults instead of crashing.
- [ ] Check a 125% and 150% Windows display scale, and a second monitor.

### Controller and Steam Deck
- [ ] Every screen works with a controller alone: title, options, the Keys board, shops, card tables, the case file, the big map.
- [ ] Button prompts match the device in use (keyboard or pad).
- [ ] Decide if Deck Verified is a goal. Valve's main tests (checked):
  - the default controller layout reaches all content;
  - prompts match the input in use;
  - runs at 1280x800 or 1280x720;
  - **no text smaller than 9 px tall at 1280x800** (12 px is recommended);
  - no launcher, and no warning that the device is unsupported;
  - 30 fps at its default settings.
- [ ] The 9 px rule matters for Grandpa: the 640x360 view scales by 2 at 1280x720, so any font drawn under 5 px tall in the view would fail. Measure the smallest text, likely the HUD counters and the mini map.
- [ ] Grandpa ships for Windows. The Deck runs it through Proton, so test it there if possible.

### Accessibility
- [ ] Keep the existing options: Attack warnings, screen shake, hit stop, vibration, key rebinding, brightness, contrast and gamma.
- [ ] Check warnings do not rely on red against green alone. Look at screenshots in a colour-blind simulator.
- [ ] Consider a text size option, or at least check the smallest text, as above.
- [ ] Mention the options on the store page. Players look for them.

### Localisation readiness
- [ ] Every player-facing string goes through `tr()`. Search for string literals in labels, buttons and speech that skip it.
- [ ] Build an export of the strings (a POT or CSV) and check it holds every line.
- [ ] Check long text. Run once with a fake locale that makes every string 30% longer, and look at the panels that were already tight at 360 px tall.
- [ ] Only list languages on the store that are fully done. Steam asks per language whether it covers the interface, audio and subtitles.

### Saves, cloud and save location
- [ ] Saves live in `user://`, which is `%APPDATA%\Godot\app_userdata\Grandpa` with the current settings. Decide before release whether to keep this or set a custom user folder (`%APPDATA%\Grandpa`). Changing it later would hide players' saves, so decide once, before any public build.
- [ ] **Steam Auto-Cloud** needs no code: in Steamworks, set a byte quota and file count, then add a root path. (checked) For Grandpa: root `WinAppDataRoaming`, subfolder `Godot/app_userdata/Grandpa` (or the custom folder), and only the save files: `slot_*/save.json`, its `.bak`, `slot_*/run.json` and `keys.json`.
- [ ] Do **not** sync `settings.cfg`, `display_log.txt` or the `logs` folder. Window size and fullscreen belong to each PC; syncing them would bring the first friend-test bug back on a second machine.
- [ ] Test a save made on one PC, loaded on another through the cloud, and a conflict when both played offline.

### Achievements
- [ ] Only if the SDK is added. Draft a list (first boss, each floor, each ending, a no-hit boss). Each needs a name, a description and two icons, 64x64, one in colour and one grey (not verified: check sizes in Steamworks when adding them).
- [ ] Test each one unlocks once, and that the game still runs with Steam closed.

### Crash and log collection
- [ ] Godot's file log is on in release builds, with the `logs` folder kept to a few files.
- [ ] The game writes the build id (version and commit) into the log at start, so every report can be matched to a build.
- [ ] Add a short "Report a bug" line in the options or pause menu that names the log folder.
- [ ] Decide if online crash reports are needed. Sending anything off the PC means a privacy policy (section 4). For launch, asking players for the log file is enough.

## 4. Legal

- [ ] **Privacy.** If the game sends nothing over the network, say so on the store page and in the credits. If any reporting or analytics is added later, write a privacy policy first.
- [ ] **EULA.** Steam has its own subscriber agreement, so a small game usually needs no EULA of its own (not verified: Steamworks offers an optional custom EULA if wanted).
- [ ] **Business.** Selling as a private person or through a company changes the tax form and how income is taxed. Check local rules (not verified: depends on the country).

## 5. Store page

### Assets (all checked on Valve's asset pages)
| Asset | Size | Notes |
|---|---|---|
| Header capsule | 920 x 430 | Required |
| Small capsule | 462 x 174 | Required. The logo should nearly fill it |
| Main capsule | 1232 x 706 | Required |
| Vertical capsule | 748 x 896 | Required |
| Page background | 1438 x 810 | Optional |
| Library capsule | 600 x 900 | Required |
| Library header | 920 x 430 | Required, falls back to the header capsule |
| Library hero | 3840 x 1240 | Required |
| Library logo | 1280 wide and/or 720 tall | Required, transparent PNG |
| Screenshots | 1920 x 1080 or larger, 16:9 | At least 5 |

- [ ] Capsules show game art and the title only. No review quotes, awards, discount text or "wishlist now". (checked)
- [ ] Screenshots show real gameplay, not concept art. Mark at least four as suitable for all ages. (checked)
- [ ] Pixel art screenshots: render at 640x360 and scale by exactly 3 to 1920x1080, so pixels stay sharp.
- [ ] Trailer: 30 to 90 seconds, gameplay in the first few seconds. (not verified: check Valve's trailer page for format and size)
- [ ] Short description, long description, tags, system requirements (minimum and recommended, Windows only).
- [ ] No links to other sites in the description. (checked)

### Content survey and age rating
- [ ] Fill in the content survey. It has three parts: general content, mature content and generative AI. The general part creates ratings for several regional boards. (checked)
- [ ] Germany requires an age rating, and Steam produces one from the survey. (checked: the survey page links a page on it)
- [ ] Answer honestly for Grandpa: cartoon violence against people, death themes (undertakers, funeral parlour, a reaper), gambling-themed rooms (the Arcade Room and the Back Room's card tables). **Card games with in-game money often raise the age rating** even with no real money (not verified: depends on each board). Check how the survey asks about simulated gambling.
- [ ] Disclose the PixelLab art under generative AI, pre-generated. (checked)

### Pricing and regions
- [ ] Set the base price in US dollars, then use Steam's suggested regional prices as a start (not verified: check the current tool in Steamworks).
- [ ] Choose a launch discount, if any. Steam has rules on how often a game can be discounted (not verified: read the discount rules before planning one).
- [ ] Decide which countries the game is sold in. The default is all.

## 6. Coming Soon and wishlists

- [ ] Store page review takes **3 to 5 business days**. Send it **at least 7 business days** before the page should go live. (checked)
- [ ] The Coming Soon page must be up for **at least two weeks** before release. (checked) Treat two weeks as the floor, not the plan.
- [ ] Put the page up as early as the art allows. Most of a small game's launch week sales come from wishlists (not verified: common advice).
- [ ] Plan a few update posts while the page is up: art pass done, a new floor, the friends playtest done.
- [ ] Check the dates of Steam's festival events and whether a demo is needed to join (not verified).

## 7. Windows build and depots

- [ ] Use the Windows export preset: one `Grandpa.exe` with the pack embedded, release mode, no debug console.
- [ ] Set the version in `project.godot` and the exe's file details (name, company, version).
- [ ] Tag the commit for each build sent to Steam.
- [ ] Install SteamCMD and set up a SteamPipe build script for the app and its Windows depot.
- [ ] Set the launch option: `Grandpa.exe`, Windows only.
- [ ] Upload to a test branch first, install it from Steam on a clean PC, and play a full run.
- [ ] Check first launch on a PC that has never run the game: no old settings, no saves.

## 8. Code signing and SmartScreen

- [ ] Players who install from Steam should not see SmartScreen. The Steam client writes the files itself, so they do not get the "downloaded from the internet" mark that SmartScreen checks. (not verified on a Valve page: confirm on a clean PC from the test branch)
- [ ] The zip handed to friends **does** show SmartScreen ("More info, then Run anyway"). That is normal for an unsigned exe and covered in the playtest plan.
- [ ] Signing is only worth it for builds handed out outside Steam (demos, press). Even a signed exe can warn until it gains reputation. Microsoft's own signing service costs about $10 a month (not verified: check current price). Skip it for launch unless the zip builds keep going out.
- [ ] Some antivirus tools flag new unsigned Godot exes. Scan the release exe with Windows Defender before uploading.

## 9. Review builds

- [ ] Build review also takes **3 to 5 business days**; plan for **7**. (checked)
- [ ] The build must start on every OS the page lists, and every feature the page lists must be in it. (checked)
- [ ] Before sending: full test suite, three full loops, and one full run by hand on the release exe.
- [ ] Run the friends playtest's pre-flight check (`docs/release/playtest-plan.md`) on this build.
- [ ] Keys for reviewers and streamers: request them in Steamworks and send a week or two before launch (not verified: check the key request rules).

## 10. Launch day

- [ ] The release build has been approved and set live on the default branch.
- [ ] Press release at a time when you can watch for the next few hours.
- [ ] Post a launch announcement on the store page.
- [ ] Watch the discussion forum and reviews. Answer bug reports with where the log file is.
- [ ] Keep a hotfix branch ready. Know how to build, upload and set a new build live in under an hour.
- [ ] Note every report in a bug list sorted by how bad it is (see the playtest plan's triage).
- [ ] First week: a patch for crashes and blockers, then a short post on what was fixed.

---

Sources: ideas taken from the "Claude Code Game Studios" template by Donchitos (launch checklist, release checklist, Steam certification and PC platform templates), https://github.com/Donchitos/Claude-Code-Game-Studios. Steam rules from the Steamworks documentation: https://partner.steamgames.com/steamdirect, https://partner.steamgames.com/doc/gettingstarted/appfee, https://partner.steamgames.com/doc/store/review_process, https://partner.steamgames.com/doc/store/coming_soon, https://partner.steamgames.com/doc/store/assets/standard, https://partner.steamgames.com/doc/store/assets/libraryassets, https://partner.steamgames.com/doc/store/assets/rules, https://partner.steamgames.com/doc/gettingstarted/contentsurvey, https://partner.steamgames.com/doc/steamdeck/compat, https://partner.steamgames.com/doc/features/cloud. PixelLab terms: https://pixellab.ai/termsofservice. SmartScreen background: https://learn.microsoft.com/windows/apps/package-and-deploy/smartscreen-reputation.
