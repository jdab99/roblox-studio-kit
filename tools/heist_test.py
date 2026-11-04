"""Heist playtest driver: one MCP session, starts Play, runs a scenario, prints state, saves window grabs, stops Play.
usage: python heist_test.py <scenario> <out_dir>
Scenarios: patrol, main, guard, camera, laser, poweroff, input, + shooter: fpv, ko, reload, cops, fight
"""
import asyncio, json, os, subprocess, sys, time
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

SCEN, OUT = sys.argv[1], sys.argv[2]
os.makedirs(OUT, exist_ok=True)
WINSHOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "winshot.ps1")


def P(code):  # run on the server as the first player
    return "local p = game.Players:GetPlayers()[1]; local c = p.Character; " + code


async def main():
    params = StdioServerParameters(command="cmd.exe", args=["/c", os.path.expandvars(r"%LOCALAPPDATA%\Roblox\mcp.bat")])
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()
            sid = None
            for _ in range(40):
                st = json.loads((await s.call_tool("list_roblox_studios", {})).content[0].text)["studios"]
                if st:  # 11-03: two Studios can be open; the heist game is Place1
                    sid = next((x["id"] for x in st if x.get("name") == "Place1"), st[0]["id"]); break
                await asyncio.sleep(0.5)

            async def luau(code, dm="Server"):
                res = await s.call_tool("execute_luau", {"studio_id": sid, "datamodel_type": dm, "code": code})
                return res.content[0].text if res.content else ""

            async def T(cmd, a=None):
                arg = "" if a is None else (", " + json.dumps(a))
                return await luau(f'return game.ServerStorage.HeistTest:Invoke("{cmd}"{arg})')

            async def state(tag):
                raw = await T("state")
                try:
                    d = json.loads(raw)
                    gs = " ".join(f"[{g['name']} {g['state']} s={g['susp']} ko={g['ko']} hp={g.get('hp')} {g['pos']}]" for g in d["npcs"])
                    print(f"{tag}: phase={d['phase']} alarm={d['alarm']}({d.get('reason')}) banked={d['banked']} bag={d['bag']} "
                          f"hp={round(d.get('hp') or 0)} ammo={d.get('ammo')} reload={d.get('reloading')} wave={d.get('wave')} next={round(d['police'],1)} "
                          f"power={d['power']} front={d['front']} vault={d['vault']} drive={d['drive']} downed={d.get('downed')} arrested={d['arrested']} "
                          f"result={d['result']} npcs={gs}")
                    return d
                except Exception:
                    print(tag, "RAW", raw[:400]); return {}

            def shot(name):
                subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", WINSHOT,
                                "-Out", os.path.join(OUT, name + ".png")], capture_output=True)

            async def tp(x, y, z, look=None):
                lk = f", Vector3.new({look[0]},{look[1]},{look[2]})" if look else ""
                cf = f"CFrame.lookAt(Vector3.new({x},{y},{z}){lk})" if look else f"CFrame.new({x},{y},{z})"
                return await luau(P(f"c:PivotTo({cf}) return 'tp'"))

            print((await s.call_tool("start_stop_play", {"studio_id": sid, "is_start": True})).content[0].text)
            await asyncio.sleep(4)
            print("skip:", await T("skipLobby"))
            # console probe: proves get_console_output can see server prints (a log that reads nothing reports "no errors")
            await luau('print("HEIST_PROBE_OK") warn("HEIST_PROBE_WARN") return 1')
            for _ in range(20):
                d = await state("wait")
                if d.get("phase") == "Heist":
                    break
                await asyncio.sleep(1)

            if SCEN == "patrol":
                for i in range(3):
                    await asyncio.sleep(3)
                    await state(f"patrol t+{3*(i+1)}")
                shot("patrol")
            elif SCEN == "main":
                # park the guards' attention elsewhere is not possible, so move fast like a real run
                await tp(0, 3, 26, (0, 3, 10)); await asyncio.sleep(1)
                print("lock:", await T("lock")); await asyncio.sleep(1)
                shot("main_frontdoor")
                for case in ["Case1", "Case2", "Case3"]:
                    print(case, await T("grab", case))
                await state("after cases")
                await tp(68, 3, 15); await asyncio.sleep(1.5)
                await state("after stash 1")
                print("power:", await T("power"))
                d = await state("power cut")
                print("wrong code:", await T("code", "0000"))
                print("right code:", await T("code", d["code"]))
                await asyncio.sleep(3.5)
                await tp(-20, 3, -31, (-20, 3, -36)); await asyncio.sleep(0.5)
                shot("main_vault_open")
                for item in ["Diamond", "Gold1"]:
                    print(item, await T("grab", item))
                await state("after vault")
                await tp(68, 3, 15); await asyncio.sleep(1.5)
                d = await state("after stash 2")
                shot("main_ready_to_drive")
                print("drive:", await T("drive")); await asyncio.sleep(2)
                await state("after drive")
                shot("main_win")
            elif SCEN == "guard":
                # stand right in front of the showroom guard
                d = await state("before")
                gpos = await luau('local g = workspace.HeistMap.Guards.Guard1.HumanoidRootPart; local f = g.CFrame.LookVector; local p = g.Position + f*12; return string.format("%.1f,%.1f,%.1f,%.1f,%.1f", p.X, p.Z, g.Position.X, g.Position.Z, 0)')
                x, z, gx, gz, _ = [float(v) for v in gpos.split(",")]
                await tp(x, 3, z, (gx, 3, gz))
                for i in range(8):
                    await asyncio.sleep(0.5)
                    d = await state(f"seen t+{0.5*(i+1)}")
                    if i == 1: shot("guard_spotted")
                    if d.get("arrested") or d.get("phase") == "End":
                        break
                await asyncio.sleep(1)
                shot("guard_caught")
                await state("end")
            elif SCEN == "camera":
                await state("before")
                # vault room: only Cam3 covers it (no guard route there)
                await tp(-18, 3, -20)
                for i in range(20):
                    await asyncio.sleep(0.5)
                    d = await state(f"cam t+{0.5*(i+1)}")
                    if d.get("alarm"):
                        break
                shot("camera_alarm")
            elif SCEN == "laser":
                await tp(-17, 3, -2, (-17, 3, -12))
                await state("at doorway")
                for i in range(8):
                    await tp(-17, 3, -7.5)
                    await asyncio.sleep(0.5)
                    d = await state(f"laser t+{0.5*(i+1)}")
                    if d.get("alarm"):
                        break
                shot("laser_alarm")
            elif SCEN == "poweroff":
                # negative check: with the power cut, the same camera spot + the laser doorway must NOT set off the alarm
                print("power:", await T("power"))
                await tp(-18, 3, -20)
                for i in range(10):
                    await asyncio.sleep(1)
                    d = await state(f"cam spot, power off t+{i+1}")
                    if d.get("alarm"): break
                for i in range(4):
                    await tp(-17, 3, -7.5)
                    await asyncio.sleep(1)
                    d = await state(f"laser spot, power off t+{i+1}")
                    if d.get("alarm"): break
                shot("poweroff")
            elif SCEN == "input":
                # real keyboard input through Studio: C to sneak, hold E on prompts, then the HUD's own remote for the code
                async def keys(acts):
                    return (await s.call_tool("user_keyboard_input", {"studio_id": sid, "datamodel_type": "Client", "actions": acts})).content[0].text
                print("press C:", (await keys([{"action": "keyPress", "key_code": "C"}]))[:80]); await asyncio.sleep(0.6)
                print("sneaking/speed:", await luau(P("return tostring(p:GetAttribute('Sneaking')) .. ' ' .. c.Humanoid.WalkSpeed")))
                await keys([{"action": "keyPress", "key_code": "C"}]); await asyncio.sleep(0.4)
                await tp(0, 3, 25, (0, 3, 15)); await asyncio.sleep(0.8)
                print("hold E on door:", (await keys([{"action": "keyDown", "key_code": "E"}, {"action": "wait", "wait_time_ms": 3400}, {"action": "keyUp", "key_code": "E"}]))[:80])
                await asyncio.sleep(0.6)
                d = await state("after door")
                await tp(22.6, 3, -21.2, (22.6, 3, -24)); await asyncio.sleep(0.8)
                print("prompts near note:", await luau("local out = {} local r = game.Players.LocalPlayer.Character.HumanoidRootPart for _, pp in workspace.HeistMap:GetDescendants() do if pp:IsA('ProximityPrompt') and pp.Parent:IsA('BasePart') then local d = (pp.Parent.Position - r.Position).Magnitude if d < 12 then table.insert(out, pp.Parent.Name .. ':' .. pp.ActionText .. ' d=' .. math.floor(d*10)/10 .. ' en=' .. tostring(pp.Enabled) .. ' max=' .. pp.MaxActivationDistance) end end end return table.concat(out, ' | ')", "Client"))
                await keys([{"action": "keyPress", "key_code": "E"}]); await asyncio.sleep(1)
                print("note on screen:", await luau("local g = game.Players.LocalPlayer.PlayerGui.HeistHUD; for _, x in g:GetDescendants() do if x:IsA('TextLabel') and x.Text:find('Vault code') then return x.Text end end return 'NO NOTE'", "Client"))
                shot("input_note")
                await tp(-15, 3, -24.5, (-15, 3, -28)); await asyncio.sleep(0.8)
                await keys([{"action": "keyPress", "key_code": "E"}]); await asyncio.sleep(1)
                print("keypad open:", await luau("local g = game.Players.LocalPlayer.PlayerGui.HeistHUD; for _, x in g:GetDescendants() do if x:IsA('TextButton') and x.Text == 'OK' then return 'KEYPAD UP' end end return 'NO KEYPAD'", "Client"))
                shot("input_keypad")
                code = d.get("code", "0000")
                await luau(f'game.ReplicatedStorage.HeistRemote:FireServer("Code", "{code}") return 1', "Client"); await asyncio.sleep(3)
                await state("after keypad code")
                # end the round and confirm the next one resets cleanly
                await luau('game.ServerStorage.HeistTest:Invoke("code","1111") game.ServerStorage.HeistTest:Invoke("code","1112") return 1')
                await state("wrong codes after open (should stay closed=vault True)")
                print("cut power:", await T("power"))
                print("alarm:", await T("alarm", "test"))
                await luau('return game.ServerStorage.HeistTest:Invoke("police", 1)')
                await asyncio.sleep(2.5)
                await state("round over")
                await asyncio.sleep(10)
                await state("next round (expect Lobby or Heist, vault False, power True, banked 0)")
            elif SCEN == "fpv":
                async def keys(acts):
                    return (await s.call_tool("user_keyboard_input", {"studio_id": sid, "datamodel_type": "Client", "actions": acts})).content[0].text
                print("fpv:", await luau("local p = game.Players.LocalPlayer; local vm = workspace.CurrentCamera:FindFirstChild('HeistViewmodel'); local vis = 0; if vm then for _, x in vm:GetChildren() do if x.LocalTransparencyModifier == 0 then vis += 1 end end end; return tostring(p.CameraMode) .. ' viewmodel parts visible=' .. vis .. ' equipped=' .. tostring(p.Character:FindFirstChild('StunBlaster') ~= nil) .. ' camDist=' .. math.floor((workspace.CurrentCamera.CFrame.Position - p.Character.Head.Position).Magnitude*10)/10", "Client"))
                await tp(0, 3, 26, (0, 3, 10)); await asyncio.sleep(1.2)
                # NOTE: a window grab pulls Studio to the front, which Roblox reads as a click (fires the blaster) and
                # breaks a held key, so grabs happen only between actions, never right before an E hold
                print("hold E:", (await keys([{"action": "keyDown", "key_code": "E"}, {"action": "wait", "wait_time_ms": 3400}, {"action": "keyUp", "key_code": "E"}]))[:40])
                await asyncio.sleep(0.6)
                d = await state("after E on door (FPV)")
                shot("fpv_at_door")
                await asyncio.sleep(0.5)
                d = await state("after grab")
                a0 = d.get("ammo")
                vp = await luau("local v = workspace.CurrentCamera.ViewportSize return math.floor(v.X/2) .. ',' .. math.floor(v.Y/2)", "Client")
                vx, vy = [int(v) for v in vp.split(",")]
                mres = await s.call_tool("user_mouse_input", {"studio_id": sid, "datamodel_type": "Client", "actions": [{"action": "moveTo", "x": vx, "y": vy}, {"action": "mouseButtonClick", "mouse_button": "left"}]})
                print("click:", (mres.content[0].text if mres.content else "")[:160])
                await asyncio.sleep(0.6)
                d = await state("after click")
                print("ammo before/after click:", a0, d.get("ammo"))
                shot("fpv_shot")
                print("shift:", (await keys([{"action": "keyDown", "key_code": "LeftShift"}]))[:20])
                await asyncio.sleep(0.5)
                print("speed while sprinting:", await luau(P("return c.Humanoid.WalkSpeed")))
                await keys([{"action": "keyUp", "key_code": "LeftShift"}]); await asyncio.sleep(0.5)
                print("speed after:", await luau(P("return c.Humanoid.WalkSpeed")))
            elif SCEN == "ko":
                g = await luau('local g = workspace.HeistMap.Guards.Guard1.HumanoidRootPart return string.format("%.1f,%.1f", g.Position.X, g.Position.Z)')
                gx, gz = [float(v) for v in g.split(",")]
                sx = gx + 12 if gx < 0 else gx - 12  # stay inside the store
                await tp(sx, 3, gz, (gx, 3, gz)); await asyncio.sleep(0.3)
                print("fire at Guard1:", await T("fireAt", "Guard1")); await asyncio.sleep(0.8)
                d = await state("after shot")
                shot("ko_guard_down")
                print("Guard2 before noise:", [n for n in d["npcs"] if n["name"] == "Guard2"])
                g2 = await luau('local g = workspace.HeistMap.Guards.Guard2.HumanoidRootPart return string.format("%.1f,%.1f", g.Position.X, g.Position.Z)')
                g2x, g2z = [float(v) for v in g2.split(",")]
                # 30 studs from the office guard, behind a wall: it can't see us but must HEAR the shot
                await tp(g2x, 3, g2z + 30)
                print("loud shot:", await luau('return game.ServerStorage.HeistTest:Invoke("fireDir", Vector3.new(0, -1, 0.2))'))
                await asyncio.sleep(0.5)
                await state("after loud shot near Guard2")
                for i in range(6):
                    await asyncio.sleep(2)
                    await state(f"KO timer t+{1.3 + 2*(i+1)}")
                shot("ko_guard_up")
            elif SCEN == "reload":
                await tp(-60, 3, 70)
                outs = []
                for i in range(9):
                    outs.append(await luau('return game.ServerStorage.HeistTest:Invoke("fireDir", Vector3.new(0, 0.3, -1))'))
                    await asyncio.sleep(0.2)
                print("9 shots:", outs)
                await state("empty")
                await s.call_tool("user_keyboard_input", {"studio_id": sid, "datamodel_type": "Client", "actions": [{"action": "keyPress", "key_code": "R"}]})
                await asyncio.sleep(0.5)
                await state("reloading")
                await asyncio.sleep(1.4)
                await state("after reload")
            elif SCEN == "cops":
                print("alarm:", await T("alarm", "Test alarm"))
                print("wave:", await T("wave"))
                await tp(0, 3, 14, (0, 3, 30))
                for i in range(8):
                    await asyncio.sleep(1)
                    await state(f"under fire t+{i+1}")
                    if i == 4: shot("cops_fight")
                print("set hp 5:", await T("hp", 5))
                for i in range(10):
                    await asyncio.sleep(1)
                    d = await state(f"low hp t+{i+1}")
                    if d.get("arrested") or d.get("phase") == "End":
                        break
                shot("cops_caged")
            elif SCEN == "fight":
                await tp(0, 3, 26, (0, 3, 10))
                print("lock:", await T("lock"))
                for case in ["Case1", "Case2", "Case7", "Case4", "Case5"]:
                    print(case, await T("grab", case))
                print("alarm:", await T("alarm", "Smash and grab!"))
                await tp(68, 3, 15); await asyncio.sleep(1.2)
                print("code:", await T("code", (await state("x")).get("code")))
                await asyncio.sleep(3)
                await tp(-20, 3, -31, (-20, 3, -36)); await asyncio.sleep(0.4)
                for item in ["Diamond", "Gold1", "Gold2"]:
                    print(item, await T("grab", item))
                print("wave:", await T("wave")); await asyncio.sleep(1.5)
                await tp(0, 3, 8, (0, 3, 30))  # showroom, facing the street the cops come from
                await asyncio.sleep(2.5)
                d = await state("cops coming")
                cops = [n["name"] for n in d["npcs"] if n["name"].startswith("Cop") or n["name"].startswith("Guard")]
                for rnd in range(3):
                    for cname in cops:
                        r1 = await T("fireAt", cname)
                        print("shoot", cname, r1)
                        if r1.startswith("empty"):
                            await luau('game.ReplicatedStorage.HeistRemote:FireServer("Reload") return 1', "Client")
                            await asyncio.sleep(1.7)
                        await asyncio.sleep(0.25)
                await state("after shooting")
                shot("fight_cops_down")
                # walk (real navigation) out the front door and around to the van, logging health on the way
                nav_task = asyncio.create_task(s.call_tool("character_navigation", {"studio_id": sid, "datamodel_type": "Client", "x": 66, "y": 3, "z": 16, "speed_multiplier": 1.0}))
                for i in range(12):
                    await asyncio.sleep(1)
                    d = await state(f"running t+{i+1}")
                    if i == 2: shot("fight_running")
                    if d.get("banked", 0) >= 2500 or d.get("arrested") or nav_task.done():
                        break
                nav = await nav_task
                print("navigate:", (nav.content[0].text if nav.content else "")[:160])
                await asyncio.sleep(1)
                d = await state("at van?")
                if d.get("banked", 0) < 2500:
                    await tp(68, 3, 15); await asyncio.sleep(1.5)
                    await state("teleported to van")
                print("drive:", await T("drive")); await asyncio.sleep(2)
                await state("end")
                shot("fight_escaped")
            elif SCEN == "police":
                print("wrong x3:", await T("code", "1111"), await T("code", "2222"), await T("code", "3333"))
                await state("after wrong codes")
                await tp(-60, 3, 70)  # far from the guards so nobody catches us
                print("police:", await T("police", 3)); await asyncio.sleep(4)
                await state("after police")
                shot("police_busted")
            print("CONSOLE:", ((await s.call_tool("get_console_output", {"studio_id": sid})).content[0].text)[-3000:])
            print((await s.call_tool("start_stop_play", {"studio_id": sid, "is_start": False})).content[0].text)


asyncio.run(main())
