"""Reel filming driver. Every Studio session takes the STUDIO LOCK, so several reels can be worked on at once
(one Studio, one session at a time; the others wait in line).

usage (reel = a folder like reels/03-floor-is-lava):
  python tools/film.py install <reel>                     make sure Studio holds this reel (base sets/cast, the reel's own
                                                          sets/cast, its director) - stills/record do this themselves
  python tools/film.py stills <reel> <out_dir> T1 T2 ...  Play, freeze on each narration time, grab the viewport upright, stop Play
  python tools/film.py record <reel> <out.mp4> START END  Play, record the viewport while the Director runs START..END, trim on the magenta markers
  python tools/film.py restore                            put the heist game back the way it was (scripts on, streaming on, blaster back)

A reel folder holds shots.luau (required: the shot list, appended after film/core.luau) and optionally
sets.luau (builds ONLY into workspace.Film.ReelSets) and cast.luau (builds ONLY into workspace.Film.ReelCast).
Capture = the Studio WINDOW (tools/wincap.py, Windows Graphics Capture): other windows on top don't matter, Studio
never comes to the front, it only must not be minimized (restored automatically). Viewport found from the magenta marker.
If the lock is busy for over LOCK_WAIT seconds this exits with code 75 and "STUDIO BUSY": just run it again.
"""
import asyncio, hashlib, json, msvcrt, os, subprocess, sys, time
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import wincap

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FILM = os.path.join(ROOT, "film")
WINSHOT = os.path.join(HERE, "winshot.ps1")
LOCK = os.path.join(HERE, ".studio.lock" if wincap.STUDIO == "Place1" else f".studio-{wincap.STUDIO.lower()}.lock")
LOCK_WAIT = 480
VIEW = dict(x=286, y=168, w=2092, h=1152)
# portrait crop: drop Roblox's corner icons (bottom-left after rotation), keep 9:16
VF = "transpose=2,crop=iw*0.94:ih*0.94:iw*0.06:0,scale=1080:1920:flags=lanczos,setsar=1"

SETUP = """
local Players = game:GetService("Players")
game.ServerScriptService.HeistServer.Enabled = false
game.StarterPlayer.StarterPlayerScripts.HeistClient.Enabled = false
Players.CharacterAutoLoads = false
workspace.StreamingEnabled = false
local sp = game.StarterPack:FindFirstChild("StunBlaster") if sp then sp.Parent = game.ServerStorage end
local t = workspace:FindFirstChild("FilmTest") if t then t:Destroy() end
local RS = game:GetService("ReplicatedStorage")
local old = RS:FindFirstChild("FilmDirector") if old then old:Destroy() end
local m = Instance.new("ModuleScript")
m.Name = "FilmDirector"
m.Source = [=====[%s]=====]
m.Parent = RS
return "filming setup ok, director " .. #m.Source .. " chars"
"""
RESTORE = """
local Players = game:GetService("Players")
game.ServerScriptService.HeistServer.Enabled = true
game.StarterPlayer.StarterPlayerScripts.HeistClient.Enabled = true
Players.CharacterAutoLoads = true
workspace.StreamingEnabled = true
local sp = game.ServerStorage:FindFirstChild("StunBlaster") if sp then sp.Parent = game.StarterPack end
local f = workspace:FindFirstChild("Film") if f then f:Destroy() end
local d = game.ReplicatedStorage:FindFirstChild("FilmDirector") if d then d:Destroy() end
for _, n in {"FilmCC", "FilmBloom", "FilmRays"} do local e = game.Lighting:FindFirstChild(n) if e then e:Destroy() end end
return "heist game restored"
"""
GET_STATE = """
local f = workspace:FindFirstChild("Film")
if not f then return "{}" end
return game:GetService("HttpService"):JSONEncode({base = f:GetAttribute("BaseHash"), reel = f:GetAttribute("ReelHash")})
"""
CLEAR_REEL = """
local f = workspace:FindFirstChild("Film")
for _, n in {"ReelSets", "ReelCast"} do local o = f:FindFirstChild(n) if o then o:Destroy() end end
f:SetAttribute("ReelHash", nil)
return "reel cleared"
"""


def read(p):
    return open(p, encoding="utf-8").read()


def h(*parts):
    return hashlib.sha1("\0".join(parts).encode("utf-8")).hexdigest()[:16]


def lock(path=None, wait=None):
    f = open(path or LOCK, "a+")
    t0 = time.time()
    while True:
        try:
            f.seek(0)
            msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
            return f
        except OSError:
            if time.time() - t0 > (wait or LOCK_WAIT):
                print("STUDIO BUSY (another reel is filming). Run the same command again.")
                sys.exit(75)
            time.sleep(2)


# 11-03 (reel 34's builder): when BOTH Studios record at once, both drop to ~15 unique fps and the takes go choppy.
# So recording (real-time capture) is one-at-a-time across all Studios; installs and stills still run in parallel.
RECORD_LOCK = os.path.join(HERE, ".record.lock")


async def session(fn):
    params = StdioServerParameters(command="cmd.exe", args=["/c", os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")])
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            sid = None
            for _ in range(40):
                st = json.loads((await s.call_tool("list_roblox_studios", {})).content[0].text)["studios"]
                sid = wincap.pick_studio(st)
                if sid:
                    break
                await asyncio.sleep(0.5)
            if not sid:
                sys.exit(f"no studio {wincap.STUDIO}")

            async def luau(code, dm="Edit"):
                res = await s.call_tool("execute_luau", {"studio_id": sid, "datamodel_type": dm, "code": code})
                txt = res.content[0].text if res.content else ""
                if getattr(res, "is_error", False) or getattr(res, "isError", False):
                    raise RuntimeError(txt)
                return txt

            async def play(on):
                return (await s.call_tool("start_stop_play", {"studio_id": sid, "is_start": on})).content[0].text

            await fn(luau, play)


def front():
    subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", WINSHOT, "-Out",
                    os.path.join(os.environ.get("TEMP", "."), "_front.png")], capture_output=True)


async def wait_ready(luau):
    for _ in range(60):
        try:
            r = await luau('return (workspace:FindFirstChild("Film") and game.ReplicatedStorage:FindFirstChild("FilmDirector")) and "ok" or "no"', "Client")
            if r == "ok":
                return
        except Exception:
            pass
        await asyncio.sleep(0.5)
    raise RuntimeError("client never saw Film + FilmDirector")


async def find_box(luau, cap):
    """Show the magenta marker, find the viewport inside the Studio window, hide it again."""
    await luau("return require(game.ReplicatedStorage.FilmDirector).marker(true)", "Client")
    await asyncio.sleep(0.5)
    box = wincap.magenta_box(cap.frame())
    await luau("return require(game.ReplicatedStorage.FilmDirector).marker(false)", "Client")
    print("viewport in Studio window:", box)
    return box


def save_still(f, box, path):
    x, y, w, h = box
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "bgra", "-s", f"{w}x{h}", "-i", "-",
                    "-frames:v", "1", "-vf", VF + ",scale=360:640", path],
                   input=f[y:y + h, x:x + w].tobytes(), check=True)


def director_source(reel):
    """core.luau + kit.luau (shared look/faces/VFX helpers, if present) + the reel's shots.luau."""
    kit = os.path.join(FILM, "kit.luau")
    src = (read(os.path.join(FILM, "core.luau")) + "\n" + (read(kit) + "\n" if os.path.exists(kit) else "")
           + read(os.path.join(reel, "shots.luau"))
           + "\ntable.sort(SH, function(a, b) return a.t < b.t end)\nD.shots = SH\nreturn D\n")
    assert "]=====]" not in src
    return src


async def install(luau, reel):
    """Bring Studio to this reel's state, rebuilding only what changed."""
    base_c, base_s = read(os.path.join(FILM, "cast.luau")), read(os.path.join(FILM, "sets.luau"))
    rs_p, rc_p = os.path.join(reel, "sets.luau"), os.path.join(reel, "cast.luau")
    reel_s = read(rs_p) if os.path.exists(rs_p) else ""
    reel_c = read(rc_p) if os.path.exists(rc_p) else ""
    ks_p = os.path.join(FILM, "kit_sets.luau")  # shared sets/assets for every reel, builds ONLY into Film.KitSets
    kit_s = read(ks_p) if os.path.exists(ks_p) else ""
    want_base, want_reel = h(base_c, base_s, kit_s), h(os.path.basename(os.path.normpath(reel)), reel_s, reel_c)
    state = json.loads(await luau(GET_STATE) or "{}")
    if state.get("base") != want_base:
        print("installing base cast + sets ...")
        print((await luau(base_c))[-200:])
        print(await luau(base_s))
        if kit_s:
            print("kit sets:", (await luau(kit_s))[-300:])
        await luau(f'workspace.Film:SetAttribute("BaseHash", "{want_base}") return 1')
        state["reel"] = None
    if state.get("reel") != want_reel:
        print(await luau(CLEAR_REEL))
        if reel_c:
            print("reel cast:", (await luau(reel_c))[-300:])
        if reel_s:
            print("reel sets:", (await luau(reel_s))[-300:])
        await luau(f'workspace.Film:SetAttribute("ReelHash", "{want_reel}") return 1')
    print(await luau(SETUP % director_source(reel)))


ERRS = 'local o = {} for _, m in game:GetService("LogService"):GetLogHistory() do if m.messageType == Enum.MessageType.MessageError then table.insert(o, m.message) end end return table.concat(o, "\\n")'


def main():
    mode = sys.argv[1]
    if mode == "restore":
        lk = lock()
        async def go(luau, play):
            print(await luau(RESTORE))
        asyncio.run(session(go))
        return
    reel = os.path.abspath(sys.argv[2])
    assert os.path.exists(os.path.join(reel, "shots.luau")), "no shots.luau in " + reel
    lk = lock()
    if mode == "install":
        async def go(luau, play):
            await install(luau, reel)
        asyncio.run(session(go))
    elif mode == "stills":
        out = sys.argv[3]
        os.makedirs(out, exist_ok=True)
        times = [float(t) for t in sys.argv[4:]]

        async def go(luau, play):
            await install(luau, reel)
            print(await play(True))
            await wait_ready(luau)
            cap = wincap.Cap()
            try:
                box = await find_box(luau, cap)
                for t in times:
                    print(t, await luau(f"return require(game.ReplicatedStorage.FilmDirector).still({t})", "Client"))
                    await asyncio.sleep(1.5)  # lights in a new set switch on 0.5-1.1 s after the cut
                    save_still(cap.frame(), box, os.path.join(out, f"still_{t:07.2f}.jpg"))
                logs = await luau(ERRS, "Client")
                print("CLIENT ERRORS:", chr(10).join(sorted(set(logs.split(chr(10)))))[-4000:] if logs else "none")
            finally:
                cap.stop()
                try:
                    await luau("require(game.ReplicatedStorage.FilmDirector).stop() return 1", "Client")
                except Exception as e:
                    print("stop failed:", str(e)[:300])
                print(await play(False))
        asyncio.run(session(go))
    elif mode == "record":
        out, a, b = sys.argv[3], float(sys.argv[4]), float(sys.argv[5])
        rlk = lock(RECORD_LOCK, 1500)  # held until this process exits
        raw = out.replace(".mp4", "_raw.mp4")

        async def go(luau, play):
            await install(luau, reel)
            print(await play(True))
            await wait_ready(luau)
            await asyncio.sleep(3)  # let textures/animations load
            cap = wincap.Cap()
            try:
                box = await find_box(luau, cap)
                await luau(f"return require(game.ReplicatedStorage.FilmDirector).still({a})", "Client")
                await asyncio.sleep(2)
                rec = wincap.Recorder(cap, box, raw, VF)
                await asyncio.sleep(1.0)
                print(await luau(f"return require(game.ReplicatedStorage.FilmDirector).run({a}, {b})", "Client"))
                await asyncio.sleep((b - a) + 2.5)
                print(rec.close())
                logs = await luau(ERRS, "Client")
                print("CLIENT ERRORS:", chr(10).join(sorted(set(logs.split(chr(10)))))[-4000:] if logs else "none")
            finally:
                cap.stop()
                try:
                    await luau("require(game.ReplicatedStorage.FilmDirector).stop() return 1", "Client")
                except Exception as e:
                    print("stop failed:", str(e)[:300])
                print(await play(False))
        asyncio.run(session(go))
        trim(raw, out, b - a)


def trim(raw, out, length):
    """Find the magenta markers (start = last magenta frame of the first run) and cut exactly `length` seconds after it."""
    p = subprocess.run(["ffmpeg", "-v", "error", "-i", raw, "-vf", "scale=8:8,format=rgb24", "-f", "rawvideo", "-"],
                       capture_output=True)
    data = p.stdout
    n = len(data) // (8 * 8 * 3)
    mag = []
    for i in range(n):
        px = data[i * 192 + 27 * 3: i * 192 + 27 * 3 + 3]  # a pixel near the middle
        r, g, b = px[0], px[1], px[2]
        mag.append(r > 200 and g < 70 and b > 200)
    start = None
    for i in range(1, n):
        if mag[i - 1] and not mag[i]:
            start = i
            break
    if start is None:
        sys.exit(f"no start marker found in {n} frames")
    t0 = start / 30.0
    print(f"frames {n}, magenta {sum(mag)}, start marker at frame {start} ({t0:.3f}s)")
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{t0:.3f}", "-i", raw, "-t", f"{length:.3f}", "-c:v", "libx264",
                    "-preset", "medium", "-crf", "16", "-pix_fmt", "yuv420p", "-r", "30", out], check=True)
    print("wrote", out)


if __name__ == "__main__":
    main()
