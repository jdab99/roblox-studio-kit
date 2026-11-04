# Roblox Studio Kit: notes for Claude

The person using this kit may be non-technical. Do the setup and the work yourself, explain in plain words, and
ask them only to click things in Roblox Studio that you cannot click.

## Setup (do these in order, check each one)
1. Check `python --version` (3.11+) and `ffmpeg -version`. Install what is missing (`winget install ffmpeg`).
2. `pip install -r requirements.txt`
3. Check `claude mcp list` for `Roblox_Studio`. If missing:
   `claude mcp add Roblox_Studio --scope user -- cmd.exe /c "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"`
   (`%LOCALAPPDATA%\Roblox\mcp.bat` only exists once Studio's MCP server has been turned on once.)
   The `mcp__Roblox_Studio__*` tools appear in NEW sessions; mid-session use `python tools/rbx.py`.
4. The person opens Studio, signs in, opens a place, and turns on Assistant > ... > Manage MCP Servers >
   Enable Studio as MCP server.
5. Prove it: `python tools/rbx.py list` prints the tool list. Then run a tiny `execute_luau` (Edit) that prints
   something and read it back.

## Read before real work
- `tools/README.md`: how Studio is driven, filmed and tested, and every gotcha we hit. These notes come from the
  original setup (two monitors, a "Place1" place name, a heist game already built); adjust to this PC.
- `film/KIT.md`: the style kit (looks, faces, pets, VFX, camera helpers, ready-made sets).

## Main paths
- Heist game: `python tools/install_heist.py <steps.json>` then `python tools/rbx.py run <steps.json>` (Studio in
  Edit mode), then `python tools/heist_test.py main <out_dir>`. `film.py restore` expects this game to be built.
- Story reel: copy `examples/reel-sir-barks-a-lot/` to `reels/<name>/`, write `script.md`, then
  `python tools/narrate.py <script.md> reels/<name>` (needs `ELEVENLABS_API_KEY`) for `narration.mp3` + `words.json`,
  write `shots.luau` on that clock, `python tools/film.py stills ...` to check frames, `record` to film, then
  `python tools/assemble.py reels/<name> <take.mp4> <out.mp4>`.
- Filming finds Studio by its place name (window title "<name> - Roblox Studio"). A new unsaved place is "Place1",
  the default. For any other place set `BLOCKY_STUDIO=<name>` before `film.py` / `heist_test.py`.
  `rbx.py` drives "Place1" if open, else the first Studio it finds.

## Not included (bring your own)
Sound effects (`assets/sfx/`, file name = cue name), music (`assets/music/`, set in `sfx.json`), the voice key.
