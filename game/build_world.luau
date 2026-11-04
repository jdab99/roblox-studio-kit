-- Scramble Floor: builds the world in Edit mode. Safe to re-run (replaces its own folder).
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

for _, n in {"OttoTest", "ScrambleFloor"} do
	local old = workspace:FindFirstChild(n)
	if old then old:Destroy() end
end
local oldSpawn = workspace:FindFirstChild("SpawnLocation")
if oldSpawn then oldSpawn:Destroy() end
local base = workspace:FindFirstChild("Baseplate")
if base then base:Destroy() end

local root = Instance.new("Folder")
root.Name = "ScrambleFloor"
root.Parent = workspace

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do p[k] = v end
	p.Parent = props.Parent or root
	return p
end

-- the six cube colors (names are what the game calls out)
local COLORS = {
	{"WHITE", Color3.fromRGB(245, 245, 245)},
	{"YELLOW", Color3.fromRGB(255, 213, 0)},
	{"GREEN", Color3.fromRGB(0, 170, 80)},
	{"BLUE", Color3.fromRGB(0, 80, 200)},
	{"RED", Color3.fromRGB(200, 20, 50)},
	{"ORANGE", Color3.fromRGB(255, 110, 0)},
}
local colorFolder = RS:FindFirstChild("CubeColors") or Instance.new("Folder")
colorFolder.Name = "CubeColors"
colorFolder:ClearAllChildren()
for i, c in COLORS do
	local v = Instance.new("Color3Value")
	v.Name = c[1]
	v.Value = c[2]
	v:SetAttribute("Order", i)
	v.Parent = colorFolder
end
colorFolder.Parent = RS

-- the floor: 9x9 stickers on a black cube body, high in the sky
local N, TILE, GAP, Y = 9, 10, 0.6, 60
local floorFolder = Instance.new("Folder")
floorFolder.Name = "Tiles"
floorFolder.Parent = root
local span = N * TILE
part({Name = "CubeBody", Size = Vector3.new(span + 2, 12, span + 2), Position = Vector3.new(0, Y - 6.6, 0),
	Color = Color3.fromRGB(20, 20, 24), Material = Enum.Material.SmoothPlastic, CanCollide = false})
for i = 1, N do
	for j = 1, N do
		local x = (i - (N + 1) / 2) * TILE
		local z = (j - (N + 1) / 2) * TILE
		local t = part({Name = "Tile", Size = Vector3.new(TILE - GAP, 1, TILE - GAP), Position = Vector3.new(x, Y, z),
			Color = COLORS[math.random(1, 6)][2], Material = Enum.Material.SmoothPlastic, Parent = floorFolder})
		t:SetAttribute("Home", t.Position)
	end
end

-- the void below: touching it = out
local void = part({Name = "Void", Size = Vector3.new(600, 2, 600), Position = Vector3.new(0, 4, 0),
	Color = Color3.fromRGB(40, 10, 70), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false})
void:SetAttribute("Kills", true)

-- lobby: a floating platform beside the cube, with a spawn
local lobby = part({Name = "Lobby", Size = Vector3.new(40, 2, 40), Position = Vector3.new(0, Y, 85),
	Color = Color3.fromRGB(60, 60, 75), Material = Enum.Material.SmoothPlastic})
local spawn = Instance.new("SpawnLocation")
spawn.Name = "LobbySpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(10, 1, 10)
spawn.Position = lobby.Position + Vector3.new(0, 1.5, 0)
spawn.Color = Color3.fromRGB(255, 213, 0)
spawn.Material = Enum.Material.Neon
spawn.Duration = 0
spawn.Parent = root

-- sky + light: bright cartoon day
Lighting.ClockTime = 14
Lighting.Brightness = 3
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
Lighting.GlobalShadows = true
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.Parent = Lighting
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Density = 0.25
atmo.Haze = 1
atmo.Color = Color3.fromRGB(200, 220, 255)
atmo.Parent = Lighting

return "built " .. #floorFolder:GetChildren() .. " tiles"
