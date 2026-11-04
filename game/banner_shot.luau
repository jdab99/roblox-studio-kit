-- Rearranges MascotSet for the channel banner: big yellow set, 3 Blockys each side, empty middle for the title.
local set = workspace.MascotSet
local O = Vector3.new(1000, 50, 0)
set.Wall.Size = Vector3.new(400, 120, 1)
set.Wall.Position = O + Vector3.new(0, 40, 12)
set.Floor.Size = Vector3.new(400, 1, 400)
set.Blocky:PivotTo(CFrame.new(O + Vector3.new(0, 3.2, 300))) -- out of the shot
local xs = {happy = 16, sneaky = 12, shocked = 8, scared = -8, angry = -12, sad = -16} -- +X shows on screen-left
for mood, x in xs do
	local m = set["Blocky_" .. mood]
	-- slight turn toward the middle
	local yaw = x > 0 and 16 or -16
	m:PivotTo(CFrame.new(O + Vector3.new(x, 3.2, -30)) * CFrame.Angles(0, math.rad(yaw), 0))
end
return "arranged"
