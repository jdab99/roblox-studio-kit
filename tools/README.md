# Roblox Stories: how Otto drives Roblox Studio (proven 2026-11-02)

**11-03: TWO STUDIOS can film at once (Jesse asked "mess around with opening Roblox Studio in multiple windows").**
- Studio 1 = "Place1 - Roblox Studio" on the main monitor (default). Studio 2 = opened from `film\studio2\Place2.rbxl`
  (`RobloxStudioBeta.exe "<that path>"`, PID in `film\studio2\studio2.pid`), parked on the 2nd monitor (x=2560).
- Pick one with the env var `BLOCKY_STUDIO=Place2` before `python tools\film.py ...` (default Place1). Each Studio has its
  own lock (`.studio.lock`, `.studio-place2.lock`), MCP id is picked by name (`wincap.pick_studio`), the window by title.
- Proven 11-03: reel 31 stills ran in both Studios at the same time, both exit 0, same frames. Place2's viewport is
  smaller (1436x776 on the 1080p monitor vs ~2092x1152) = a bit softer video; its default sky/lighting is slightly greyer.
- Place2 renders ~21-24 fps while both Studios work (reel 36: 244 unique frames per 10 s vs 300 on Place1), so its
  videos are a bit less smooth and film.py's ">2% repeated frames" warning always fires there (false alarm; use
  freezedetect for real freezes). Put the calmer reels on Place2, action-heavy ones on Place1.
- RECORDING is one-at-a-time across both Studios (11-03, reel 34: two takes at once dropped both to ~15 unique
  fps). `film.py record` waits on `tools\.record.lock` (up to 25 min); installs + stills still run in parallel.
- Restore BOTH at batch end: `python tools\film.py restore` (Place1 = heist game). Place2 is a throwaway copy.

**UPDATED 11-02 evening (multi-reel engine + window capture). This block wins over older notes below.**
- Director is split: `film\core.luau` (shared engine) + `reels\<reel>\shots.luau` (that reel's shot list; every core
  local is in scope). Optional `reels\<reel>\sets.luau` builds ONLY into `workspace.Film.ReelSets`, `cast.luau` ONLY
  into `workspace.Film.ReelCast`. Base `film\cast.luau` + `film\sets.luau` are shared, don't edit them per reel.
  Mind Luau's 200-locals limit: group reel helpers in tables or `do` blocks.
- `python tools\film.py install|stills|record <reel_dir> ...` takes a STUDIO LOCK (several reels can queue for one
  Studio; exit 75 = busy, run again) and installs only what changed (hash attributes on workspace.Film).
- Capture = the Studio WINDOW via Windows Graphics Capture (`tools\wincap.py`, pip `windows-capture`): windows on top
  don't get filmed and Studio never comes to the front. It must not be MINIMIZED (a minimized window renders
  nothing; wincap restores it without activating and sizes it to the work area). Viewport is found from the
  director's magenta marker (`D.marker(on)`), so the window layout doesn't matter. Real time, ~50 fps captured,
  written as constant 30 fps.
- `assemble.py`: `sfx.json` "music" can be a list of acts (file, lufs, start, end, from, fin, fout) so the music
  changes when the story turns (Jesse 11-02, from the Ralph "first word" reference).

**Story reels (built 11-02 for reel 01 "The Key Heist"):**
1. `python tools\narrate.py scripts\<reel>.md reels\<reel>` = voice + `words.json`.
2. `film\cast.luau` (actors), `film\sets.luau` (sets), `film\director.luau` (every shot on the narration clock:
   `shot(time, light, setup, update)`; poses, faces, props, lighting presets, tilted camera). Copy director.luau per reel.
3. `python tools\film.py install` (or `director` to reload only the director), then
   `python tools\film.py stills <dir> T1 T2 ...` to check frames, then `python tools\film.py record <out.mp4> 0 <end>`.
   Record trims itself on magenta marker frames. `python tools\film.py restore` puts the heist game back afterwards.
4. `python tools\assemble.py reels\<reel> <take.mp4> <out.mp4>` = one-word captions + narration + music + SFX cues
   (`reels\<reel>\sfx.json`, SFX names from Jesse's APPROVED list) mastered to -13 LUFS / -1 dBTP.
Gotchas: filming needs StreamingEnabled off and CharacterAutoLoads off (install does it); the screen recorder films
ANYTHING on top of Studio (a browser window got into a still once), so check the contact sheet of every take;
default exposure blows out faces (presets in director.luau are tuned); a face that passes close to a PointLight
(street lamp, porch light, lit window) glows white at night: Jesse flagged it on reel 01's opening, fixed with
`dimHouses()` per shot (dims Town house + lamp lights). Check night close-ups for this before recording;
to fix one section, re-record just that range and splice it in by frame number (take3 = take2-open frames 0-166 + take1 167+); a model's PrimaryPart rotation becomes its
pivot (hero keys pivot on WorldPivot instead); props are solid blocks, so an actor posed near one clips through it
(Jesse r2 caught Blocky inside the blanket and Pip inside the headboard): check every still for limbs or bodies inside
props; TextScaled caps at 100 px, so keep a SurfaceGui canvas about 100 px tall or the letters come out tiny; the MascotSet at x=1000 shows at the end of the town road (director hides it).

**Style kit (11-02, reel 02 on):** `film/kit.luau` (table `K`: looks, v2 faces, pets, wish-star/number markers, VFX, camera
helpers) + `film/kit_sets.luau` (golden-hour town, snowy park + pond, vet room, nursery, school hallway, bedroom) - read
`film/KIT.md`. Gotcha: a Studio window FULLY covered by another window (e.g. maximized Chrome) stops drawing the Play view
(client ViewportSize 1x1), so stills/record fail with "magenta marker not visible". If Jesse is away (idle), raise Studio
without taking focus: `powershell -File tools
aise_window.ps1 -Match "Roblox Studio"`, then raise his window back after.
Billboard GUIs are drawn in the rolled landscape viewport: rotate their contents by `K.ROLL` (90) to read upright.

**Narration:** `python tools\narrate.py scripts\<reel>.md reels\<reel>` = the Blocky Tales voice (ElevenLabs Adam,
sped up 1.4x with pitch, locked by Jesse 11-02) + `words.json` word timings. Script text = the "## Script (narrator)" section.

Goal: Ralph-style "In this world..." story shorts (see hub memory
`ralphanimations-roblox-story-format-2026-11-02`), built in real Roblox Studio.

## Connection
- Studio's BUILT-IN MCP server: Studio > Assistant > ... > Manage MCP Servers > Enable Studio as MCP server.
  Jesse must be logged in and have a place open.
- Claude Code: added at user scope as `Roblox_Studio` (`cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`).
  New sessions get the tools natively. Mid-session: `python tools/rbx.py run steps.json` (one connection per batch,
  waits for Studio to appear; first call after spawn can report "no studios" without the wait).
- Run Python from a neutral cwd (e.g. C:\Users\Jesse); `mcp` 2.x uses `input_schema` / `is_error`.

## What works
- `execute_luau` with datamodel_type Edit (building), Server / Client (during Play).
- `Players:CreateHumanoidModelFromUserId(StudioService:GetUserId())` = Jesse's own avatar (pink hair, pink jacket).
- Joints on new rigs are `AnimationConstraint` (C0 is read-only); pose with `.Transform`. Shows in Play mode.
- `screen_capture`: ~0.57 s each, 1920x1058 JPEG (saved bytes are JPEG even if named .png). It IGNORES camera roll.

## Tall (9:16) video = Play mode + tilted camera + screen recording
1. `start_stop_play` true. Server luau: anchor actors, hide name labels, move the player's own character away.
2. Client luau: hide CoreGui/chat/topbar, `BindToRenderStep` a Scriptable camera with `* CFrame.Angles(0,0,rad(90))`.
3. Record the viewport: ffmpeg gdigrab, offset 286,167 size 2092x1152 (Studio maximized on the main monitor;
   re-measure if the layout changes), `transpose=2,scale=1080:1920`. Test got 29.7 fps.
4. Studio window must stay uncovered while recording.
- Edit-mode camera and `screen_capture` both drop the roll. Only the Play-mode client camera keeps it.
- Leftover: a tiny Roblox icon bottom-left; crop or hide it.

## Heist game, level 1 "Glimmer & Co. Jewelers" (built 2026-11-02)
Source: `game\heist\` = `build_map.luau` (Edit-mode map, removes Scramble Floor), `HeistConfig.module.luau`
(ReplicatedStorage: tuning + `Levels` table), `HeistServer.server.luau` (ServerScriptService), `HeistClient.client.luau`
(StarterPlayerScripts: HUD, sneak, note, keypad).
- **Rebuild:** `python tools\install_heist.py <steps.json>` then `python tools\rbx.py run <steps.json>` (Studio in Edit mode).
- **Test:** `python tools\heist_test.py <scenario> <out_dir>` (starts Play, skips the lobby, prints round state, saves
  window grabs, prints the console, stops Play). Scenarios: `patrol`, `main` (lock, loot, stash, power, wrong+right code,
  vault, stash, drive = win), `guard` (spotted, chased, caught), `camera`, `laser`, `poweroff` (negative check: same spots,
  no alarm), `police` (3 wrong codes, timer = BUSTED), `input` (real C / held E keys, note + keypad UI, next-round reset).
  The run prints `HEIST_PROBE_OK` from a planted print: if that line is missing the console check read nothing.
- Test hooks: `ServerStorage.HeistTest:Invoke(cmd, ...)` with state / grab / code / power / lock / drive / police / alarm /
  skipLobby / free. They call the same functions the prompts call.
- **Shooter update (11-02, Jesse: "should be fpv and you should maybe get a gun"):** first person (LockFirstPerson),
  client viewmodel (arms + blaster parented to the camera, scale K=0.6), crosshair, Shift sprint, C sneak, head-bob,
  recoil, camera shake. `StunBlaster` Tool (built into StarterPack by build_map): click = client raycast from the camera,
  server re-raycasts from the head and validates ammo/cooldown/range; 8 shots, R reloads (1.5 s). Hits knock guards
  and cops OUT (lie down, spinning stars, up after 10 s). Shots are loud (45-stud noise). Alarm = police backup waves
  every 22 s from the street (first after 25 s), each wave bigger, tougher (more hits), better aim; cops path around
  walls and shoot with spread + reaction delay + line of sight. Player HP 100, regen after 4 s; 0 HP = knocked down,
  then the cage. Guards tackle for 20 and stagger. Tuning lives in `HeistConfig` (Blaster, Player, Police.Wave(n)).
  More scenarios: `fpv`, `ko`, `reload`, `cops`, `fight` (solo fast loot, shoot guards + cops, walk to van, win).
- Gotchas (shooter): solid parts can't turn CanQuery off, so the store windows live in `HeistMap.Glass` and every
  sight line / shot excludes that folder plus the front door; a window grab (winshot) pulls Studio to the front, which
  Roblox reads as a CLICK (fires the blaster) and it breaks a held key, so never grab right before input;
  `get_console_output` does not obviously show CLIENT errors: read the client's `LogService:GetLogHistory()` too (plant
  an error first to prove the reader works); Jesse may click in the Studio window during tests (stray shots).
- Gotchas: a camera that sweeps faster than its spot time can never catch anyone (fixed: 8 s sweep, 0.5 s spot);
  `user_keyboard_input` needs `datamodel_type: "Client"` and waits use `wait_time_ms`; give a prompt ~1 s after a teleport
  before pressing E; NPC walk/run/idle use Roblox's stock R15 animation ids; Lighting is global, so the night setting
  also darkens the Blocky mascot set at x=1000 (re-set ClockTime before mascot shots).
