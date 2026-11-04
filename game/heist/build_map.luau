-- Heist level 1 map: "Glimmer & Co. Jewelers" at night. Edit-mode build, safe to re-run.
-- Layout (studs, ground top y=0): store x -40..40, z -40..20. Showroom z -6..20 (front, door at x -4..4).
-- Vault room x -40..0, z -40..-6 (laser doorway x -20..-14). Office x 0..40, z -40..-6 (back door x 26..32).
-- Getaway van on the side street at x 68. Police cage across the street at (-60, 0, 58).
local Lighting = game:GetService("Lighting")

for _, n in {"HeistMap", "ScrambleFloor", "OttoTest"} do
	local old = workspace:FindFirstChild(n)
	if old then old:Destroy() end
end
for _, s in {"ScrambleGame"} do
	local o = game.ServerScriptService:FindFirstChild(s)
	if o then o:Destroy() end
end
local ui = game.StarterGui:FindFirstChild("ScrambleUI")
if ui then ui:Destroy() end

local map = Instance.new("Model")
map.Name = "HeistMap"
map.Parent = workspace

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent or map
	return f
end
local F = {
	Static = folder("Static"), Lights = folder("StoreLights"), AlarmLights = folder("AlarmLights"),
	Loot = folder("Loot"), Cameras = folder("Cameras"), Lasers = folder("Lasers"),
	Routes = folder("GuardRoutes"), Props = folder("Props"),
	Glass = folder("Glass"), -- see-through: every sight line and shot skips this folder (CanQuery can't be off on solid parts)
}

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Parent" then p[k] = v end
	end
	p.Parent = props.Parent or F.Static
	return p
end
-- box from two corners (x1,y1,z1)-(x2,y2,z2)
local function box(name, x1, y1, z1, x2, y2, z2, color, mat, parent)
	return part({Name = name, Size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
		Position = Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2), Color = color,
		Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function light(parentPart, color, brightness, range, folderName)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = true
	l.Parent = parentPart
	return l
end

local H = 18
local WALL = Color3.fromRGB(236, 226, 210)
local TRIM = Color3.fromRGB(70, 45, 35)
local STEEL = Color3.fromRGB(120, 125, 135)
local ASPHALT = Color3.fromRGB(38, 40, 46)

-- ground, roads, sidewalks
box("Ground", -200, -2, -200, 200, 0, 200, Color3.fromRGB(52, 70, 50), Enum.Material.Grass)
box("FrontRoad", -200, 0, 30, 200, 0.2, 50, ASPHALT, Enum.Material.Asphalt)
box("SideRoad", 56, 0, -120, 82, 0.2, 30, ASPHALT, Enum.Material.Asphalt)
box("Alley", -44, 0, -64, 56, 0.2, -40, Color3.fromRGB(58, 58, 62), Enum.Material.Concrete)
box("Sidewalk", -200, 0, 20, 200, 0.6, 30, Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
box("SideWalk2", 44, 0, -64, 56, 0.6, 20, Color3.fromRGB(150, 150, 150), Enum.Material.Concrete)
for x = -190, 190, 20 do
	box("LaneMark", x, 0.2, 39.6, x + 9, 0.25, 40.4, Color3.fromRGB(230, 200, 60), Enum.Material.Neon)
end

-- store floor + ceiling
box("Floor", -40, 0, -40, 40, 0.4, 20, Color3.fromRGB(225, 222, 215), Enum.Material.Marble)
box("ShowroomRug", -34, 0.4, -2, 34, 0.45, 18, Color3.fromRGB(95, 22, 38), Enum.Material.Fabric)
box("Ceiling", -41, H, -41, 41, H + 1, 21, Color3.fromRGB(245, 240, 232))
box("Roof", -42, H + 1, -42, 42, H + 2, 22, Color3.fromRGB(60, 60, 66), Enum.Material.Slate)

-- outer walls
box("WallW", -41, 0, -41, -40, H, 21, WALL, Enum.Material.Plaster)
box("WallE", 40, 0, -41, 41, H, 21, WALL, Enum.Material.Plaster)
box("WallBackA", -40, 0, -41, 26, H, -40, WALL, Enum.Material.Plaster)
box("WallBackB", 32, 0, -41, 40, H, -40, WALL, Enum.Material.Plaster)
box("BackDoorTop", 26, 9, -41, 32, H, -40, WALL, Enum.Material.Plaster)
-- front: solid posts, window bands, door gap -4..4
for _, seg in {{-40, -36}, {-8, -4}, {4, 8}, {36, 40}} do
	box("FrontPost", seg[1], 0, 20, seg[2], H, 21, TRIM, Enum.Material.Wood)
end
for _, seg in {{-36, -8}, {8, 36}} do
	box("WindowBase", seg[1], 0, 20, seg[2], 2.5, 21, TRIM, Enum.Material.Wood)
	box("WindowTop", seg[1], 13, 20, seg[2], H, 21, TRIM, Enum.Material.Wood)
	local g = box("Window", seg[1], 2.5, 20.3, seg[2], 13, 20.7, Color3.fromRGB(160, 200, 230), Enum.Material.Glass, F.Glass)
	g.Transparency = 0.7
end
box("DoorTop", -4, 10, 20, 4, H, 21, TRIM, Enum.Material.Wood)
local door = box("FrontDoor", -4, 0.4, 20.2, 4, 10, 20.8, Color3.fromRGB(170, 210, 235), Enum.Material.Glass)
door.Transparency = 0.45
door.CanQuery = false
door.Parent = F.Props
door:SetAttribute("Home", door.CFrame)
local pick = Instance.new("ProximityPrompt")
pick.Name = "Prompt"
pick.ActionText = "Pick the lock"
pick.ObjectText = "Front door"
pick.HoldDuration = 3
pick.MaxActivationDistance = 9
pick.RequiresLineOfSight = false
pick.Parent = door

-- sign
local sign = box("Sign", -18, 13.5, 21, 18, 17.5, 21.6, Color3.fromRGB(25, 20, 30))
local sg = Instance.new("SurfaceGui")
sg.Face = Enum.NormalId.Back -- the street side is +Z
sg.CanvasSize = Vector2.new(900, 100)
sg.LightInfluence = 0
sg.Parent = sign
local t = Instance.new("TextLabel")
t.Size = UDim2.fromScale(1, 1)
t.BackgroundTransparency = 1
t.Font = Enum.Font.FredokaOne
t.TextScaled = true
t.Text = "GLIMMER & CO. JEWELERS"
t.TextColor3 = Color3.fromRGB(255, 220, 120)
t.Parent = sg
light(sign, Color3.fromRGB(255, 210, 120), 2, 22)

-- interior walls
box("WallMidA", -40, 0, -6.5, -20, H, -5.5, WALL, Enum.Material.Plaster)
box("WallMidB", -14, 0, -6.5, 18, H, -5.5, WALL, Enum.Material.Plaster)
box("WallMidC", 24, 0, -6.5, 40, H, -5.5, WALL, Enum.Material.Plaster)
box("VaultDoorwayTop", -20, 9, -6.5, -14, H, -5.5, WALL, Enum.Material.Plaster)
box("OfficeDoorwayTop", 18, 9, -6.5, 24, H, -5.5, WALL, Enum.Material.Plaster)
box("WallSplit", -0.5, 0, -40, 0.5, H, -6.5, WALL, Enum.Material.Plaster)
local stuffOnly = box("StaffOnly", 18.5, 9.3, -5.4, 23.5, 10.8, -5.3, Color3.fromRGB(200, 40, 40))
local sg2 = Instance.new("SurfaceGui")
sg2.Face = Enum.NormalId.Back
sg2.LightInfluence = 0.3
sg2.Parent = stuffOnly
local t2 = t:Clone()
t2.Text = "STAFF ONLY"
t2.TextColor3 = Color3.new(1, 1, 1)
t2.Parent = sg2

-- showroom display cases with loot
local LOOT = {
	{"Ruby Ring", 200, 1, Color3.fromRGB(230, 30, 60)},
	{"Gold Watch", 300, 1, Color3.fromRGB(255, 200, 40)},
	{"Pearl Necklace", 350, 1, Color3.fromRGB(245, 245, 255)},
	{"Emerald Ring", 250, 1, Color3.fromRGB(30, 220, 110)},
	{"Sapphire Bracelet", 300, 1, Color3.fromRGB(40, 90, 255)},
	{"Topaz Earrings", 200, 1, Color3.fromRGB(255, 150, 40)},
	{"Silver Crown", 400, 2, Color3.fromRGB(210, 215, 230)},
	{"Amethyst Pendant", 250, 1, Color3.fromRGB(170, 70, 230)},
}
local cases = {{-28, 15}, {-16, 15}, {16, 15}, {28, 15}, {-22, 4}, {-10, 4}, {10, 4}, {22, 4}}
local function lootItem(name, value, slots, color, pos, size, shape)
	local g = part({Name = name, Size = size or Vector3.new(1.1, 1.1, 1.1), Position = pos, Color = color,
		Material = Enum.Material.Neon, Shape = shape or Enum.PartType.Ball, CanCollide = false, Parent = F.Loot})
	g:SetAttribute("Value", value)
	g:SetAttribute("Slots", slots)
	g:SetAttribute("Home", g.CFrame)
	local sparkle = Instance.new("PointLight")
	sparkle.Color = color
	sparkle.Brightness = 1.2
	sparkle.Range = 7
	sparkle.Parent = g
	local pr = Instance.new("ProximityPrompt")
	pr.Name = "Prompt"
	pr.ActionText = "Grab"
	pr.ObjectText = name .. "  $" .. value
	pr.HoldDuration = 1
	pr.MaxActivationDistance = 8
	pr.RequiresLineOfSight = false
	pr.Parent = g
	return g
end
for i, c in cases do
	local x, z = c[1], c[2]
	box("CaseBase", x - 3, 0.4, z - 1.6, x + 3, 3.4, z + 1.6, TRIM, Enum.Material.Wood)
	box("CaseVelvet", x - 2.8, 3.4, z - 1.4, x + 2.8, 3.5, z + 1.4, Color3.fromRGB(40, 20, 60), Enum.Material.Fabric)
	local glass = box("CaseGlass", x - 3, 3.4, z - 1.6, x + 3, 5.4, z + 1.6, Color3.fromRGB(200, 230, 255), Enum.Material.Glass)
	glass.Transparency = 0.75
	glass.CanCollide = false
	glass.CanQuery = false
	glass.Name = "CaseGlass"
	glass.Parent = F.Props
	glass:SetAttribute("Home", glass.CFrame)
	local L = LOOT[i]
	local item = lootItem(L[1], L[2], L[3], L[4], Vector3.new(x, 4.1, z))
	item:SetAttribute("Glass", glass:GetFullName())
	item.Name = "Case" .. i
	item:SetAttribute("Label", L[1])
	local glassRef = Instance.new("ObjectValue")
	glassRef.Name = "Glass"
	glassRef.Value = glass
	glassRef.Parent = item
end
-- counter + wall displays for the set
box("Counter", -10, 0.4, -4.5, 10, 4, -2, TRIM, Enum.Material.Wood)
box("CounterTop", -10.2, 4, -4.7, 10.2, 4.3, -1.8, Color3.fromRGB(30, 30, 35), Enum.Material.Marble)
for _, x in {-39.4, 39.4} do
	for z = -2, 16, 6 do
		local m = box("WallMirror", x - 0.2, 6, z - 2, x + 0.2, 11, z + 2, Color3.fromRGB(200, 210, 220), Enum.Material.Glass)
		m.Reflectance = 0.4
	end
end

-- vault room: steel vault in the back, keypad by the door
local VX1, VX2, VZ1, VZ2 = -34, -6, -40, -28
box("VaultBack", VX1, 0, VZ1, VX2, 12, VZ1 + 1, STEEL, Enum.Material.DiamondPlate)
box("VaultSideW", VX1, 0, VZ1, VX1 + 1, 12, VZ2, STEEL, Enum.Material.DiamondPlate)
box("VaultSideE", VX2 - 1, 0, VZ1, VX2, 12, VZ2, STEEL, Enum.Material.DiamondPlate)
box("VaultTop", VX1, 12, VZ1, VX2, 13, VZ2, STEEL, Enum.Material.DiamondPlate)
box("VaultFrontA", VX1, 0, VZ2 - 1, -23, 12, VZ2, STEEL, Enum.Material.DiamondPlate)
box("VaultFrontB", -17, 0, VZ2 - 1, VX2, 12, VZ2, STEEL, Enum.Material.DiamondPlate)
box("VaultFrontTop", -23, 9, VZ2 - 1, -17, 12, VZ2, STEEL, Enum.Material.DiamondPlate)
local vdoor = box("VaultDoor", -23, 0.4, VZ2 - 0.8, -17, 9, VZ2 + 0.2, Color3.fromRGB(150, 155, 165), Enum.Material.Metal)
vdoor.Parent = F.Props
vdoor:SetAttribute("Home", vdoor.CFrame)
local wheel = part({Name = "VaultWheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 3.5, 3.5),
	CFrame = CFrame.new(-20, 5, VZ2 + 0.35) * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(200, 170, 60),
	Material = Enum.Material.Metal, CanCollide = false, Parent = F.Props})
wheel:SetAttribute("Home", wheel.CFrame)
local keypad = box("Keypad", -15.8, 4.5, VZ2 + 0.1, -14.2, 6.5, VZ2 + 0.5, Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
keypad.Parent = F.Props
local kl = Instance.new("PointLight")
kl.Color = Color3.fromRGB(255, 60, 60)
kl.Range = 5
kl.Brightness = 2
kl.Name = "Status"
kl.Parent = keypad
local kp = pick:Clone()
kp.ActionText = "Enter code"
kp.ObjectText = "Vault keypad"
kp.HoldDuration = 0
kp.Parent = keypad
-- inside the vault
box("Pedestal", -21.5, 0.4, -37, -18.5, 3.5, -34, Color3.fromRGB(40, 40, 45), Enum.Material.Marble)
local diamond = lootItem("Giant Diamond", 1500, 3, Color3.fromRGB(150, 230, 255), Vector3.new(-20, 4.6, -35.5),
	Vector3.new(1.8, 1.8, 1.8), Enum.PartType.Block)
diamond.Name = "Diamond"
diamond.Material = Enum.Material.Glass
diamond.Transparency = 0.15
diamond.CFrame = diamond.CFrame * CFrame.Angles(math.rad(45), 0, math.rad(45))
diamond:SetAttribute("Home", diamond.CFrame)
diamond:SetAttribute("Label", "Giant Diamond")
diamond.PointLight.Brightness = 3
diamond.PointLight.Range = 12
for i, x in {-31, -29, -11, -9} do
	local bar = lootItem("Gold Bars", 300, 1, Color3.fromRGB(255, 190, 30), Vector3.new(x, 1.0, -37),
		Vector3.new(2.2, 1, 1.2), Enum.PartType.Block)
	bar.Name = "Gold" .. i
	bar.Material = Enum.Material.Foil
	bar:SetAttribute("Label", "Gold Bars")
end

-- laser grid across the vault-room doorway (pulses; power cut turns it off)
for i, y in {1.2, 3, 4.8, 6.6} do
	local l = box("Laser", -20, y - 0.08, -7.6, -14, y + 0.08, -7.44, Color3.fromRGB(255, 20, 20), Enum.Material.Neon)
	l.Name = "Laser" .. i
	l.CanCollide = false
	l.CanQuery = false
	l.Parent = F.Lasers
end
box("LaserEmitterA", -20.6, 0.4, -8, -20, 7.5, -7, Color3.fromRGB(30, 30, 30), Enum.Material.Metal)
box("LaserEmitterB", -14, 0.4, -8, -13.4, 7.5, -7, Color3.fromRGB(30, 30, 30), Enum.Material.Metal)

-- office: desk with the code note, filing cabinets, power box
box("Desk", 15, 0.4, -27, 25, 3.5, -22, TRIM, Enum.Material.Wood)
box("Monitor", 18, 3.5, -26.5, 21, 5.8, -26.2, Color3.fromRGB(20, 20, 25))
local screen = box("MonitorGlow", 18.2, 3.7, -26.15, 20.8, 5.6, -26.1, Color3.fromRGB(80, 160, 255), Enum.Material.Neon)
local note = box("Note", 22, 3.5, -24.6, 23.4, 3.56, -23.4, Color3.fromRGB(255, 245, 160))
note.Parent = F.Props
local np = pick:Clone()
np.ActionText = "Read note"
np.ObjectText = "Sticky note"
np.HoldDuration = 0
np.MaxActivationDistance = 7
np.Parent = note
for z = -39, -31, 4 do
	box("Cabinet", 36, 0.4, z, 39.5, 7, z + 3.5, Color3.fromRGB(110, 115, 120), Enum.Material.Metal)
end
local power = box("PowerBox", 39.3, 3, -19, 39.9, 8, -16, Color3.fromRGB(90, 95, 80), Enum.Material.Metal)
power.Parent = F.Props
local pl = Instance.new("PointLight")
pl.Name = "Status"
pl.Color = Color3.fromRGB(80, 255, 80)
pl.Range = 6
pl.Brightness = 2
pl.Parent = power
local pp = pick:Clone()
pp.ActionText = "Cut the power"
pp.ObjectText = "Breaker box (cameras + lasers)"
pp.HoldDuration = 2.5
pp.Parent = power
box("Plant", 3, 0.4, -10, 5, 6, -8, Color3.fromRGB(40, 120, 50), Enum.Material.Grass)

-- ceiling lights (warm) + hidden red alarm lights
local function ceilingLamp(x, z, folderRef, color, brightness, range, name)
	local p = part({Name = name or "Lamp", Size = Vector3.new(3, 0.4, 3), Position = Vector3.new(x, H - 0.3, z),
		Color = Color3.fromRGB(255, 240, 210), Material = Enum.Material.Neon, CanCollide = false, Parent = folderRef})
	local l = light(p, color, brightness, range)
	return p, l
end
for _, xz in {{-24, 10}, {0, 10}, {24, 10}, {-24, 0}, {24, 0}, {-20, -20}, {20, -20}, {20, -34}, {-20, -34}} do
	ceilingLamp(xz[1], xz[2], F.Lights, Color3.fromRGB(255, 205, 150), 0.9, 24)
end
for _, xz in {{-30, 10}, {30, 10}, {0, 0}, {-20, -16}, {20, -16}} do
	local p, l = ceilingLamp(xz[1], xz[2], F.AlarmLights, Color3.fromRGB(255, 0, 0), 4, 34, "AlarmLamp")
	p.Color = Color3.fromRGB(90, 0, 0)
	p.Size = Vector3.new(1.5, 0.6, 1.5)
	l.Enabled = false
end

-- security cameras (server sweeps them; red spot shows where they look)
local function secCam(name, pos, lookAt)
	local m = part({Name = name, Size = Vector3.new(1.4, 1.2, 2.4), CFrame = CFrame.lookAt(pos, lookAt),
		Color = Color3.fromRGB(235, 235, 240), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = F.Cameras})
	m:SetAttribute("Home", m.CFrame)
	local lens = Instance.new("SpotLight")
	lens.Name = "Beam"
	lens.Face = Enum.NormalId.Front
	lens.Color = Color3.fromRGB(255, 40, 40)
	lens.Angle = 34
	lens.Range = 48
	lens.Brightness = 6
	lens.Shadows = true
	lens.Parent = m
	local led = Instance.new("PointLight")
	led.Name = "Led"
	led.Color = Color3.fromRGB(255, 0, 0)
	led.Range = 3
	led.Parent = m
	return m
end
secCam("Cam1", Vector3.new(-38.5, 14, 18.5), Vector3.new(-6, 0, 2))
secCam("Cam2", Vector3.new(38.5, 14, -4.5), Vector3.new(8, 0, 12))
secCam("Cam3", Vector3.new(-2, 14, -8), Vector3.new(-22, 0, -24))

-- guard patrol routes (ordered points)
local function route(name, pts)
	local f = folder(name, F.Routes)
	for i, p in pts do
		local w = part({Name = "P" .. i, Size = Vector3.new(1, 0.2, 1), Position = Vector3.new(p[1], 0.5, p[2]),
			Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = f})
	end
end
route("Showroom", {{-33, 9.5}, {33, 9.5}, {33, -1}, {-33, -1}})
route("Office", {{6, -12}, {33, -12}, {33, -34}, {6, -34}})

-- getaway van on the side street (faces -Z, back doors at +Z)
local VAN = Vector3.new(68, 0, 4)
local van = Instance.new("Model")
van.Name = "Van"
van.Parent = map
local function vpart(name, size, offset, color, mat)
	return part({Name = name, Size = size, Position = VAN + offset, Color = color, Material = mat or Enum.Material.SmoothPlastic, Parent = van})
end
vpart("Body", Vector3.new(8, 7, 16), Vector3.new(0, 4.6, 0), Color3.fromRGB(235, 235, 230))
vpart("Stripe", Vector3.new(8.1, 1, 16.1), Vector3.new(0, 4, 0), Color3.fromRGB(255, 120, 0))
vpart("Windshield", Vector3.new(7, 2.6, 0.2), Vector3.new(0, 6.4, -8.05), Color3.fromRGB(60, 80, 110), Enum.Material.Glass)
for _, o in {Vector3.new(-4, 1.6, -5), Vector3.new(4, 1.6, -5), Vector3.new(-4, 1.6, 5), Vector3.new(4, 1.6, 5)} do
	local w = part({Name = "Wheel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.2, 3.2),
		CFrame = CFrame.new(VAN + o), Color = Color3.fromRGB(25, 25, 25), Parent = van})
end
local hl = vpart("Headlights", Vector3.new(6, 0.8, 0.2), Vector3.new(0, 3.2, -8.1), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
local beam = Instance.new("SpotLight")
beam.Face = Enum.NormalId.Front
beam.Range = 40
beam.Brightness = 3
beam.Angle = 60
beam.Parent = hl
local driver = vpart("DriverDoor", Vector3.new(0.3, 4, 4), Vector3.new(-4.15, 5, -5), Color3.fromRGB(220, 220, 215))
local dp = pick:Clone()
dp.ActionText = "Drive away!"
dp.ObjectText = "Getaway van"
dp.HoldDuration = 1
dp.Enabled = false
dp.Parent = driver
local zone = vpart("StashZone", Vector3.new(12, 8, 8), Vector3.new(0, 4, 11), Color3.fromRGB(80, 255, 120), Enum.Material.Neon)
zone.Transparency = 0.85
zone.CanCollide = false
zone.CanQuery = false
local zg = Instance.new("BillboardGui")
zg.Size = UDim2.fromOffset(220, 50)
zg.StudsOffset = Vector3.new(0, 6, 0)
zg.AlwaysOnTop = true
zg.Parent = zone
local zt = t:Clone()
zt.Text = "STASH LOOT HERE"
zt.TextColor3 = Color3.fromRGB(120, 255, 150)
zt.TextStrokeTransparency = 0.2
zt.Parent = zg

local spawn = Instance.new("SpawnLocation")
spawn.Name = "HeistSpawn"
spawn.Anchored = true
spawn.Size = Vector3.new(8, 0.6, 8)
spawn.Position = Vector3.new(76, 0.5, 26)
spawn.Transparency = 0.6
spawn.Color = Color3.fromRGB(255, 120, 0)
spawn.Material = Enum.Material.Neon
spawn.Duration = 0
spawn.Neutral = true
spawn.Parent = map

-- police cage across the street (arrested players wait here; teammates can free them)
local CAGE = Vector3.new(-60, 0.6, 58)
box("CageFloor", CAGE.X - 6, 0, CAGE.Z - 6, CAGE.X + 6, 0.6, CAGE.Z + 6, Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
box("CageRoof", CAGE.X - 6, 10, CAGE.Z - 6, CAGE.X + 6, 10.5, CAGE.Z + 6, Color3.fromRGB(30, 30, 90), Enum.Material.Metal)
for i = -6, 6, 1.5 do
	for _, side in {{i, -6}, {i, 6}, {-6, i}, {6, i}} do
		box("Bar", CAGE.X + side[1] - 0.15, 0.6, CAGE.Z + side[2] - 0.15, CAGE.X + side[1] + 0.15, 10, CAGE.Z + side[2] + 0.15,
			Color3.fromRGB(160, 160, 170), Enum.Material.Metal)
	end
end
local cell = part({Name = "JailSpot", Size = Vector3.new(2, 1, 2), Position = CAGE + Vector3.new(0, 1, 0),
	Transparency = 1, CanCollide = false, Parent = map})
local free = part({Name = "CageLock", Size = Vector3.new(1.4, 1.4, 0.6), Position = CAGE + Vector3.new(0, 4, -6.6),
	Color = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Metal, Parent = F.Props})
local fp = pick:Clone()
fp.ActionText = "Free your crew"
fp.ObjectText = "Police cage"
fp.HoldDuration = 2
fp.Parent = free
local cagel = Instance.new("PointLight")
cagel.Color = Color3.fromRGB(80, 120, 255)
cagel.Range = 18
cagel.Brightness = 2
cagel.Parent = free

-- street lamps + neighbor buildings with lit windows (backdrop for filming)
for _, x in {-90, -50, -10, 30, 90} do
	box("LampPost", x - 0.3, 0.6, 26, x + 0.3, 14, 26.6, Color3.fromRGB(30, 30, 35), Enum.Material.Metal)
	local head = box("LampHead", x - 1, 14, 25.5, x + 1, 14.6, 28, Color3.fromRGB(255, 230, 170), Enum.Material.Neon)
	light(head, Color3.fromRGB(255, 200, 130), 2, 34)
end
local bcol = {Color3.fromRGB(120, 70, 60), Color3.fromRGB(70, 80, 110), Color3.fromRGB(90, 100, 80), Color3.fromRGB(110, 90, 120)}
local i = 0
for x = -150, 150, 34 do
	i += 1
	if not (x > -80 and x < -40) then -- leave room for the cage
		local h = 24 + (i % 3) * 10
		box("Building", x, 0, 64, x + 28, h, 90, bcol[i % 4 + 1], Enum.Material.Brick)
		for wy = 6, h - 6, 8 do
			for wx = x + 4, x + 22, 7 do
				local lit = ((wx + wy + i) % 3) == 0
				local w = box("Win", wx, wy, 63.7, wx + 3, wy + 3.5, 64, lit and Color3.fromRGB(255, 220, 140) or Color3.fromRGB(30, 35, 50),
					lit and Enum.Material.Neon or Enum.Material.Glass)
			end
		end
	end
end
for _, b in {{-100, -60, -44, -10}, {44, -110, 54, -66}, {-120, -120, -60, -70}} do
	box("BackBuilding", b[1], 0, b[2], b[3], 30, b[4], Color3.fromRGB(70, 65, 75), Enum.Material.Brick)
end
box("Dumpster", 34, 0.2, -52, 42, 5, -47, Color3.fromRGB(30, 90, 50), Enum.Material.Metal)
local al = box("AlleyLamp", 28, 10, -40.6, 30, 10.6, -40.2, Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
light(al, Color3.fromRGB(255, 190, 120), 1.5, 22)

-- the stun blaster every player spawns with (others see this in your hand; you see the client viewmodel)
local SP = game:GetService("StarterPack")
local oldTool = SP:FindFirstChild("StunBlaster")
if oldTool then oldTool:Destroy() end
local tool = Instance.new("Tool")
tool.Name = "StunBlaster"
tool.CanBeDropped = false
tool.ToolTip = "Stun Blaster: click to fire, R to reload"
tool.Grip = CFrame.new(0, -0.1, 0.3)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.45, 0.7, 1.7)
handle.Color = Color3.fromRGB(45, 48, 60)
handle.Material = Enum.Material.SmoothPlastic
handle.CanCollide = false
handle.Massless = true
handle.Parent = tool
local function toolBit(name, size, offset, color, mat, shape)
	local b = Instance.new("Part")
	b.Name = name
	b.Size = size
	b.Color = color
	b.Material = mat or Enum.Material.SmoothPlastic
	if shape then b.Shape = shape end
	b.CanCollide = false
	b.Massless = true
	b.CFrame = handle.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = handle, b
	w.Parent = b
	b.Parent = tool
	return b
end
toolBit("Barrel", Vector3.new(1.2, 0.32, 0.32), CFrame.new(0, 0.15, -1.2) * CFrame.Angles(0, math.rad(90), 0),
	Color3.fromRGB(30, 30, 36), Enum.Material.Metal, Enum.PartType.Cylinder)
toolBit("Glow", Vector3.new(0.48, 0.12, 1.2), CFrame.new(0, 0.38, -0.1), Color3.fromRGB(60, 230, 255), Enum.Material.Neon)
toolBit("Grip", Vector3.new(0.38, 0.9, 0.45), CFrame.new(0, -0.6, 0.45) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(255, 120, 0))
tool.Parent = SP

-- night
Lighting.ClockTime = 0.3
Lighting.Brightness = 1.2
Lighting.Ambient = Color3.fromRGB(35, 38, 60)
Lighting.OutdoorAmbient = Color3.fromRGB(70, 75, 120)
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.4
local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmo.Density = 0.3
atmo.Haze = 0.6
atmo.Color = Color3.fromRGB(80, 90, 140)
atmo.Decay = Color3.fromRGB(40, 45, 80)
atmo.Parent = Lighting

local n = 0
for _ in map:GetDescendants() do n += 1 end
return "heist map built: " .. n .. " instances"
