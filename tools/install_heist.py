"""Write a steps.json that builds the heist map and installs its scripts into the open Studio place.
usage: python install_heist.py <out_steps.json>      then: python rbx.py run <out_steps.json>
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
G = os.path.join(HERE, "..", "game", "heist")
out = sys.argv[1]


def src(name):
    s = open(os.path.join(G, name), encoding="utf-8").read()
    assert "]=====]" not in s
    return s


install = f"""
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
-- clear old installs + Scramble Floor leftovers
for _, x in {{RS:FindFirstChild("HeistConfig"), SSS:FindFirstChild("HeistServer"), SPS:FindFirstChild("HeistClient"),
	RS:FindFirstChild("Status"), RS:FindFirstChild("CalledColor"), RS:FindFirstChild("Timer"), RS:FindFirstChild("CubeColors"),
	RS:FindFirstChild("Heist"), RS:FindFirstChild("HeistRemote")}} do
	if x then x:Destroy() end
end
local m = Instance.new("ModuleScript")
m.Name = "HeistConfig"
m.Source = [=====[{src("HeistConfig.module.luau")}]=====]
m.Parent = RS
local s = Instance.new("Script")
s.Name = "HeistServer"
s.Source = [=====[{src("HeistServer.server.luau")}]=====]
s.Parent = SSS
local l = Instance.new("LocalScript")
l.Name = "HeistClient"
l.Source = [=====[{src("HeistClient.client.luau")}]=====]
l.Parent = SPS
return "installed heist scripts: " .. #m.Source .. " + " .. #s.Source .. " + " .. #l.Source .. " chars"
"""
inst = os.path.join(os.path.dirname(os.path.abspath(out)), "install_heist_scripts.luau")
open(inst, "w", encoding="utf-8").write(install)
steps = [
    {"tool": "execute_luau", "code_file": os.path.join(G, "build_map.luau"), "args": {"datamodel_type": "Edit"}},
    {"tool": "execute_luau", "code_file": inst, "args": {"datamodel_type": "Edit"}},
]
json.dump(steps, open(out, "w", encoding="utf-8"), indent=1)
print("wrote", out)
