"""Write a steps.json that rebuilds the Scramble Floor world and installs its scripts.
usage: python install.py <game_dir> <out_steps.json>
"""
import json, os, sys

game, out = sys.argv[1], sys.argv[2]
src_server = open(os.path.join(game, "GameServer.server.luau"), encoding="utf-8").read()
src_ui = open(os.path.join(game, "GameUI.client.luau"), encoding="utf-8").read()
for s in (src_server, src_ui):
    assert "]===]" not in s

install = f"""
local SSS = game:GetService("ServerScriptService")
local SG = game:GetService("StarterGui")
for _, c in {{SSS, SG}} do
	local old = c:FindFirstChild("ScrambleGame") or c:FindFirstChild("ScrambleUI")
	if old then old:Destroy() end
end
local s = Instance.new("Script")
s.Name = "ScrambleGame"
s.Source = [===[{src_server}]===]
s.Parent = SSS
local l = Instance.new("LocalScript")
l.Name = "ScrambleUI"
l.Source = [===[{src_ui}]===]
l.Parent = SG
return "installed " .. #s.Source .. " + " .. #l.Source .. " chars"
"""
inst_path = os.path.join(os.path.dirname(out), "install_scripts.luau")
open(inst_path, "w", encoding="utf-8").write(install)
steps = [
    {"tool": "execute_luau", "code_file": os.path.join(game, "build_world.luau"), "args": {"datamodel_type": "Edit"}},
    {"tool": "execute_luau", "code_file": inst_path, "args": {"datamodel_type": "Edit"}},
]
json.dump(steps, open(out, "w", encoding="utf-8"), indent=1)
print("wrote", out)
