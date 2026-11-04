# Roblox Studio Kit

This kit lets Claude drive Roblox Studio for you. Claude can build worlds, make
characters, act out scenes, and film them as tall (9:16) videos. It also has a full
heist game you can rebuild and play.

It was made by Jesse Gaskins with Claude, for the Blocky Tales story videos.

## The easy way

1. Install the things in "What you need" below.
2. Open this folder in VS Code with Claude Code.
3. Tell Claude: **"Read CLAUDE.md and set this kit up for me."**

Claude will do the rest and tell you what to click.

## What you need

- A Windows PC (the filming part only works on Windows).
- **Roblox Studio**, signed in to your Roblox account.
- **Claude Code** (in VS Code or the terminal).
- **Python 3.11 or newer** from python.org.
- **ffmpeg** (this makes the videos). Easy install: `winget install ffmpeg`
- An **ElevenLabs** account, only if you want the voice. You can skip it.

## Set it up by hand

**Step 1. Turn on Studio's helper.**
Open Roblox Studio and open any place. Go to the Assistant panel. Click the three
dots. Click "Manage MCP Servers". Turn on "Enable Studio as MCP server".

**Step 2. Connect Claude to Studio.** Run this one time:

```
claude mcp add Roblox_Studio --scope user -- cmd.exe /c "cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat"
```

Close Claude Code and open it again.

**Step 3. Install the Python parts.** In this folder, run:

```
pip install -r requirements.txt
```

**Step 4. Test it.** With Studio open, run:

```
python tools/rbx.py list
```

You should see a list of Studio tools. If you do, it works.

## What you can do with it

| You want to | Say this to Claude |
|---|---|
| Build the heist game | "Build the heist game in Studio and test it." |
| Make a story video | "Make a reel like the example in examples/." |
| Try a scene | "Put Blocky in the snowy park and take some pictures." |

## What is in here

| Folder | What it holds |
|---|---|
| `tools/` | The scripts that talk to Studio, film it, add the voice, and finish the video. `tools/README.md` has every lesson we learned. |
| `film/` | The movie maker: actors, sets, camera moves, faces, effects. `film/KIT.md` explains it. |
| `game/` | The game code. `game/heist/` is a full first person heist game. |
| `assets/` | Faces, drawings and effect pictures (already on Roblox), and the caption font. |
| `examples/` | One finished story ("Sir Barks a Lot"): the script, the sets, the cast, every shot, and the sound list. |

## Things you add yourself

These are not in the kit. They belong to other people, so you bring your own.

- **Sound effects.** Put them in `assets/sfx/`. The file name is the sound name (like
  `vine-boom.mp3`). The example uses names like `whoosh-short`, `pop-soft`, `chime`,
  `bass-boom`, `vine-boom`.
- **Music.** Put a song in `assets/music/` and set it in the reel's `sfx.json`.
  Free songs with credit: incompetech.com (Kevin MacLeod).
- **Voice.** Set your own ElevenLabs key as `ELEVENLABS_API_KEY` to use `tools/narrate.py`.

## Good to know

- Keep the Studio window open while filming. It can be behind other windows, but
  not shrunk to the taskbar.
- Studio does not save what Claude builds unless you save the place. Save often.
- Filming looks for a place called "Place1" (the name a new place gets). If your place
  has another name, tell Claude the name.
- The fonts are free (Poppins, Open Font License, see `assets/fonts/OFL.txt`).
