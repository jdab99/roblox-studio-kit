-- Reel 01 "The Key Heist" sets, built in Edit mode into workspace.Film.Sets (+ Film.Store for the jewelry-store extras).
-- The heist map (HeistMap) is the store itself; nothing here edits it. Safe to re-run.
-- Areas: TOWN (600,0,0)  GAGS (600,0,500)  LOT (-600,0,0)  MANSION (-600,0,500)  VEHICLES parked x=900.
local film = workspace:FindFirstChild("Film") or Instance.new("Model")
film.Name = "Film"
film.Parent = workspace
for _, n in {"Sets", "Store"} do
	local o = film:FindFirstChild(n)
	if o then o:Destroy() end
end
local SETS = Instance.new("Folder")
SETS.Name = "Sets"
SETS.Parent = film
local STORE = Instance.new("Folder")
STORE.Name = "Store"
STORE.Parent = film

local count = 0
local function tick()
	count += 1
	if count % 250 == 0 then task.wait() end
end
local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function model(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end
local function part(props)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		if k ~= "Parent" and k ~= "Class" then p[k] = v end
	end
	p.Parent = props.Parent
	tick()
	return p
end
-- box between two corners, in world space or relative to a CFrame `at`
local function box(parent, name, x1, y1, z1, x2, y2, z2, color, mat, at)
	local size = Vector3.new(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1))
	local c = Vector3.new((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)
	return part({Name = name, Size = size, CFrame = (at or CFrame.new()) * CFrame.new(c), Color = color,
		Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function cyl(parent, name, len, dia, cf, color, mat)
	return part({Name = name, Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, dia, dia), CFrame = cf, Color = color,
		Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function ball(parent, name, d, cf, color, mat)
	return part({Name = name, Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = cf, Color = color,
		Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function wedge(parent, name, size, cf, color, mat)
	return part({Class = "WedgePart", Name = name, Size = size, CFrame = cf, Color = color, Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function text(p, face, str, color, font, bgColor, canvas)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 0.2
	sg.CanvasSize = canvas or Vector2.new(400, 120)
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bgColor and 0 or 1
	if bgColor then t.BackgroundColor3 = bgColor end
	t.Font = font or Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = color
	t.Parent = sg
	return t
end
local function plight(p, color, brightness, range, shadows)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Shadows = shadows ~= false
	l.Parent = p
	return l
end
local function slight(p, face, color, brightness, range, angle)
	local l = Instance.new("SpotLight")
	l.Face = face
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Angle = angle
	l.Shadows = true
	l.Parent = p
	return l
end

local WHITE = Color3.fromRGB(245, 245, 240)
local DARK = Color3.fromRGB(30, 30, 36)
local GOLD = Color3.fromRGB(255, 196, 40)
local GRASS = Color3.fromRGB(75, 140, 70)
local ASPHALT = Color3.fromRGB(45, 47, 54)
local WARM = Color3.fromRGB(255, 205, 130)
local CONCRETE = Color3.fromRGB(165, 165, 165)

---------------------------------------------------------------- house
-- origin = front-center at ground, front faces local +Z. Returns the model; door is a separate part "Door".
local HOUSE_COLORS = {
	blocky = {wall = Color3.fromRGB(120, 185, 235), roof = Color3.fromRGB(200, 60, 50), trim = WHITE},
	{wall = Color3.fromRGB(245, 225, 170), roof = Color3.fromRGB(70, 120, 70), trim = WHITE},
	{wall = Color3.fromRGB(240, 170, 180), roof = Color3.fromRGB(110, 110, 120), trim = WHITE},
	{wall = Color3.fromRGB(250, 220, 100), roof = Color3.fromRGB(120, 75, 50), trim = WHITE},
	{wall = Color3.fromRGB(160, 225, 200), roof = Color3.fromRGB(50, 70, 130), trim = WHITE},
	{wall = Color3.fromRGB(230, 230, 225), roof = Color3.fromRGB(60, 60, 66), trim = Color3.fromRGB(40, 90, 160)},
	{wall = Color3.fromRGB(200, 120, 90), roof = Color3.fromRGB(50, 50, 50), trim = WHITE},
	{wall = Color3.fromRGB(190, 170, 230), roof = Color3.fromRGB(90, 60, 130), trim = WHITE},
	{wall = Color3.fromRGB(255, 190, 120), roof = Color3.fromRGB(150, 50, 40), trim = WHITE},
	{wall = Color3.fromRGB(170, 200, 120), roof = Color3.fromRGB(90, 80, 60), trim = WHITE},
}
local function house(parent, name, cf, col, lit)
	local m = model(name, parent)
	local W, D, H, R = 26, 22, 12, 7
	box(m, "Walls", -W / 2, 0, -D, W / 2, H, 0, col.wall, Enum.Material.Plaster, cf)
	box(m, "Base", -W / 2 - 0.3, 0, -D - 0.3, W / 2 + 0.3, 1, 0.3, Color3.fromRGB(120, 120, 120), Enum.Material.Brick, cf)
	-- roof halves + gable ends
	wedge(m, "RoofFront", Vector3.new(W + 2, R, D / 2 + 1.2), cf * CFrame.new(0, H + R / 2, -D / 4 + 0.6), col.roof, Enum.Material.Slate)
	wedge(m, "RoofBack", Vector3.new(W + 2, R, D / 2 + 1.2), cf * CFrame.new(0, H + R / 2, -3 * D / 4 - 0.6) * CFrame.Angles(0, math.pi, 0), col.roof, Enum.Material.Slate)
	for _, x in {-W / 2 + 0.4, W / 2 - 0.4} do
		wedge(m, "Gable", Vector3.new(0.8, R, D / 2), cf * CFrame.new(x, H + R / 2, -D / 4), col.wall, Enum.Material.Plaster)
		wedge(m, "Gable", Vector3.new(0.8, R, D / 2), cf * CFrame.new(x, H + R / 2, -3 * D / 4) * CFrame.Angles(0, math.pi, 0), col.wall, Enum.Material.Plaster)
	end
	box(m, "Chimney", 6, H + 2, -16, 9, H + R + 3, -13, Color3.fromRGB(150, 70, 55), Enum.Material.Brick, cf)
	-- door (hinge on its left edge, x = -2) + frame + keyhole
	box(m, "DoorFrame", -2.6, 1, 0, 2.6, 9.4, 0.25, col.trim, nil, cf)
	local door = box(m, "Door", -2, 1, 0.25, 2, 8.8, 0.6, Color3.fromRGB(150, 85, 50), Enum.Material.Wood, cf)
	box(m, "Knob", 1.1, 4.6, 0.6, 1.5, 5, 0.9, GOLD, Enum.Material.Metal, cf).Parent = door
	local knob = m:FindFirstChild("Knob") or door:FindFirstChild("Knob")
	box(m, "Keyhole", 1.2, 4.1, 0.6, 1.4, 4.4, 0.7, DARK, nil, cf).Parent = door
	for _, c in door:GetChildren() do if c:IsA("BasePart") then
		local w = Instance.new("WeldConstraint") w.Part0, w.Part1 = door, c w.Parent = c
	end end
	door:SetAttribute("Home", door.CFrame)
	-- windows (warm lit at night, or dark)
	for _, x in {-8, 8} do
		box(m, "WinFrame", x - 2.6, 4.4, 0, x + 2.6, 9.6, 0.2, col.trim, nil, cf)
		local wcol = lit and Color3.fromRGB(255, 215, 140) or Color3.fromRGB(70, 90, 120)
		local w = box(m, "Window", x - 2.2, 4.8, 0.1, x + 2.2, 9.2, 0.3, wcol, lit and Enum.Material.Neon or Enum.Material.Glass, cf)
		box(m, "WinBar", x - 0.15, 4.8, 0.3, x + 0.15, 9.2, 0.4, col.trim, nil, cf)
		box(m, "WinBar", x - 2.2, 6.85, 0.3, x + 2.2, 7.15, 0.4, col.trim, nil, cf)
		if lit then plight(w, WARM, 0.8, 12, false) end
	end
	box(m, "Step", -4, 0, 0, 4, 0.8, 2.5, CONCRETE, Enum.Material.Concrete, cf)
	local pl = box(m, "PorchLight", 3, 9, 0.2, 3.8, 10, 0.8, Color3.fromRGB(255, 235, 180), Enum.Material.Neon, cf)
	plight(pl, WARM, 1, 16)
	return m, door
end

local function tree(parent, pos, s)
	s = s or 1
	cyl(parent, "Trunk", 8 * s, 1.6 * s, CFrame.new(pos + Vector3.new(0, 4 * s, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 75, 50), Enum.Material.Wood)
	ball(parent, "Leaves", 9 * s, CFrame.new(pos + Vector3.new(0, 10 * s, 0)), Color3.fromRGB(60, 150, 70), Enum.Material.Grass)
	ball(parent, "Leaves", 6 * s, CFrame.new(pos + Vector3.new(2 * s, 13 * s, 1 * s)), Color3.fromRGB(80, 170, 80), Enum.Material.Grass)
end
local function lamp(parent, pos, facing)
	box(parent, "LampPost", pos.X - 0.3, pos.Y, pos.Z - 0.3, pos.X + 0.3, pos.Y + 14, pos.Z + 0.3, DARK, Enum.Material.Metal)
	local h = part({Name = "LampHead", Size = Vector3.new(2, 0.6, 2.4), CFrame = CFrame.new(pos + Vector3.new(0, 14, 0) + facing * 1.2),
		Color = Color3.fromRGB(255, 230, 170), Material = Enum.Material.Neon, Parent = parent})
	plight(h, Color3.fromRGB(255, 205, 140), 2, 36)
end

-- one big ground under everything so no shot ever sees the empty void
for gx = -2, 2 do
	for gz = -2, 2 do
		box(SETS, "WorldGround", gx * 2000 - 1000, -2.6, gz * 2000 - 1000, gx * 2000 + 1000, -2.25, gz * 2000 + 1000, GRASS, Enum.Material.Grass)
	end
end

---------------------------------------------------------------- TOWN: Blocky's street
local T = Vector3.new(600, 0, 0)
local town = folder("Town", SETS)
local tStatic = folder("Static", town)
local tHouses = folder("Houses", town)
local tProps = folder("Props", town)
box(tStatic, "Ground", T.X - 220, -2, -200, T.X + 220, 0, 200, GRASS, Enum.Material.Grass)
box(tStatic, "Road", T.X - 220, 0, -10, T.X + 220, 0.2, 10, ASPHALT, Enum.Material.Asphalt)
box(tStatic, "WalkN", T.X - 220, 0, -16, T.X + 220, 0.6, -10, CONCRETE, Enum.Material.Concrete)
box(tStatic, "WalkS", T.X - 220, 0, 10, T.X + 220, 0.6, 16, CONCRETE, Enum.Material.Concrete)
for x = T.X - 215, T.X + 215, 18 do
	box(tStatic, "LaneMark", x, 0.2, -0.4, x + 8, 0.25, 0.4, Color3.fromRGB(240, 210, 70), Enum.Material.Neon)
end
local LOTS = {520, 560, 600, 640, 680}
local ci = 0
for _, side in {-1, 1} do
	for _, x in LOTS do
		ci += 1
		local isBlocky = (side == -1 and x == 600)
		local cf = CFrame.new(x, 0.01, side * 24) * (side == 1 and CFrame.Angles(0, math.pi, 0) or CFrame.new())
		local col = isBlocky and HOUSE_COLORS.blocky or HOUSE_COLORS[(ci - 1) % #HOUSE_COLORS + 1]
		local h = house(tHouses, isBlocky and "BlockyHouse" or ("House" .. ci), cf, col, true)
		h:SetAttribute("Lot", x)
		-- driveway path + mailbox
		box(tStatic, "Path", x - 2, 0, math.min(side * 16, side * 24), x + 2, 0.4, math.max(side * 16, side * 24), CONCRETE, Enum.Material.Concrete)
		local mb = Vector3.new(x + 6, 0.6, side * 17.5)
		box(tStatic, "MailPost", mb.X - 0.2, 0.6, mb.Z - 0.2, mb.X + 0.2, 4, mb.Z + 0.2, Color3.fromRGB(110, 75, 50), Enum.Material.Wood)
		box(tStatic, "MailBox", mb.X - 0.7, 4, mb.Z - 1.1, mb.X + 0.7, 5.2, mb.Z + 1.1, Color3.fromRGB(60, 60, 70), Enum.Material.Metal)
		tree(tStatic, Vector3.new(x + 16, 0, side * 34), 0.9 + (ci % 3) * 0.1)
	end
end
for x = T.X - 200, T.X + 200, 40 do
	lamp(tStatic, Vector3.new(x, 0.6, -13), Vector3.new(0, 0, 1))
	lamp(tStatic, Vector3.new(x + 20, 0.6, 13), Vector3.new(0, 0, -1))
end
-- empty-lot foundations (shown when the houses are gone)
for _, side in {-1, 1} do
	for _, x in LOTS do
		local cf = CFrame.new(x, 0, side * 24) * (side == 1 and CFrame.Angles(0, math.pi, 0) or CFrame.new())
		local f = box(tProps, "Foundation", -13, 0, -22, 13, 0.5, 0, Color3.fromRGB(120, 115, 110), Enum.Material.Concrete, cf)
		f:SetAttribute("Lot", x * side)
	end
end
-- Blocky's bed + Grandma's recliner on the sidewalk (after the theft)
local bed = model("SidewalkBed", tProps)
local BP = CFrame.new(600, 0.6, -13)
box(bed, "Frame", -4, 0, -2.6, 4, 1.6, 2.6, Color3.fromRGB(120, 80, 50), Enum.Material.Wood, BP)
box(bed, "Headboard", -4.6, 0, -2.6, -4, 4.2, 2.6, Color3.fromRGB(120, 80, 50), Enum.Material.Wood, BP)
box(bed, "Mattress", -4, 1.6, -2.4, 4, 2.6, 2.4, WHITE, Enum.Material.Fabric, BP)
box(bed, "Pillow", -3.8, 2.6, -1.6, -2.2, 3.2, 1.6, Color3.fromRGB(250, 250, 255), Enum.Material.Fabric, BP)
box(bed, "Blanket", -1.6, 2.6, -2.5, 4.1, 4.3, 2.5, Color3.fromRGB(255, 140, 40), Enum.Material.Fabric, BP)
local chair = model("Recliner", tProps)
local CP = CFrame.new(608, 0.6, -13) * CFrame.Angles(0, math.rad(-20), 0)
box(chair, "Seat", -2.4, 0, -2.2, 2.4, 2.4, 2.4, Color3.fromRGB(150, 90, 60), Enum.Material.Fabric, CP)
box(chair, "Back", -2.4, 2.4, -2.4, 2.4, 6.4, -1.2, Color3.fromRGB(150, 90, 60), Enum.Material.Fabric, CP)
box(chair, "ArmL", -3.2, 0, -2.4, -2.4, 3.6, 2.4, Color3.fromRGB(140, 80, 55), Enum.Material.Fabric, CP)
box(chair, "ArmR", 2.4, 0, -2.4, 3.2, 3.6, 2.4, Color3.fromRGB(140, 80, 55), Enum.Material.Fabric, CP)
-- stuff the neighbors saved: scattered beds, lamps, a TV
for i, x in {528, 566, 646, 676} do
	local s = (i % 2 == 0) and -1 or 1
	box(tProps, "ScatterBed", x - 3, 0.6, s * 12 - 2, x + 3, 2.4, s * 12 + 2, Color3.fromRGB(230, 230, 240), Enum.Material.Fabric)
	box(tProps, "ScatterBox", x + 5, 0.6, s * 13 - 1, x + 7.4, 3, s * 13 + 1.4, Color3.fromRGB(190, 150, 100), Enum.Material.Cardboard)
end

---------------------------------------------------------------- VEHICLES (parked at x=900, the Director drives them)
local veh = folder("Vehicles", SETS)
-- Glimmer's truck: faces local +X; origin at ground center of the trailer
local truck = model("Truck", veh)
local TR = CFrame.new(900, 0, -120)
box(truck, "Trailer", -17, 2.4, -7, 13, 3.6, 7, Color3.fromRGB(50, 50, 56), Enum.Material.Metal, TR)
-- tractor: red semi with a hood, sleeper, chrome grille + bumper, stacks, mirrors, fuel tanks
local RED, CHROME = Color3.fromRGB(205, 35, 40), Color3.fromRGB(205, 205, 215)
local GLASS = Color3.fromRGB(60, 90, 130)
local function glass(p) p.Reflectance = 0.25 return p end
box(truck, "Rails", 10, 1.6, -3.4, 27.6, 2.6, 3.4, DARK, Enum.Material.Metal, TR)
box(truck, "FifthWheel", 10.5, 2.6, -3, 14, 3.0, 3, DARK, Enum.Material.Metal, TR)
box(truck, "Sleeper", 14, 3.8, -5.2, 18, 12.2, 5.2, RED, nil, TR)
box(truck, "Cab", 18, 3.8, -5.2, 22.6, 11, 5.2, RED, nil, TR)
wedge(truck, "Fairing", Vector3.new(10.4, 1.2, 4.6), TR * CFrame.new(20.3, 11.6, 0) * CFrame.Angles(0, math.rad(-90), 0), RED)
box(truck, "Stripe", 14, 6.4, -5.25, 22.6, 6.8, 5.25, GOLD, Enum.Material.Foil, TR)
glass(box(truck, "Windshield", 22.55, 7.4, -4.8, 22.75, 10.4, 4.8, GLASS, nil, TR))
box(truck, "Divider", 22.6, 7.4, -0.15, 22.8, 10.4, 0.15, RED, nil, TR)
for _, s in {-1, 1} do
	glass(box(truck, "SideWindow", 18.6, 7.4, s * 5.15, 21.8, 10.2, s * 5.3, GLASS, nil, TR))
	box(truck, "MirrorArm", 21.9, 8.4, s * 5.2, 22.0, 8.6, s * 5.7, DARK, nil, TR)
	box(truck, "Mirror", 21.8, 7.6, s * 5.6, 22.1, 9.8, s * 6.3, DARK, nil, TR)
	cyl(truck, "Stack", 10.5, 0.6, TR * CFrame.new(13.6, 9.2, s * 4.6) * CFrame.Angles(0, 0, math.rad(90)), CHROME, Enum.Material.Metal)
	cyl(truck, "FuelTank", 2.8, 1.8, TR * CFrame.new(22.1, 2.6, s * 4.4), CHROME, Enum.Material.Metal)
	box(truck, "Fender", 23.6, 3.8, s * 4.2, 28, 4.4, s * 5.9, RED, nil, TR)
	local door = box(truck, "NamePanel", 14.2, 3.95, s * 5.2, 22.4, 6.3, s * 5.26, RED, nil, TR)
	text(door, s < 0 and Enum.NormalId.Front or Enum.NormalId.Back, "GLIMMER", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(330, 95))
	box(truck, "MudFlap", 12.4, 0.6, s * 4.3, 12.6, 3.6, s * 5.7, DARK, nil, TR)
	box(truck, "TailLight", -17.2, 2.5, s * 5, -17, 3.3, s * 6.5, Color3.fromRGB(255, 40, 40), Enum.Material.Neon, TR)
	box(truck, "Headlight", 27.4, 4.4, s * 3.0, 27.8, 5.2, s * 4.1, Color3.fromRGB(255, 250, 220), Enum.Material.Neon, TR)
end
box(truck, "Hood", 22.6, 3.8, -4.2, 27.4, 7.8, 4.2, RED, nil, TR)
box(truck, "Grille", 27.4, 4.0, -2.8, 27.7, 7.6, 2.8, CHROME, Enum.Material.Metal, TR)
for _, y in {4.8, 5.8, 6.8} do
	box(truck, "GrilleBar", 27.7, y - 0.12, -2.6, 27.75, y + 0.12, 2.6, DARK, nil, TR)
end
local hl = box(truck, "Bumper", 27.7, 2.2, -5.2, 28.6, 3.6, 5.2, CHROME, Enum.Material.Metal, TR)
slight(hl, Enum.NormalId.Right, Color3.fromRGB(255, 245, 220), 3, 50, 60)
for z = -2, 2 do
	box(truck, "Marker", 22.2, 11, z - 0.2, 22.5, 11.3, z + 0.2, Color3.fromRGB(255, 170, 40), Enum.Material.Neon, TR)
end
local banner = box(truck, "Banner", -15, 3.6, 7, 11, 6.6, 7.4, DARK, nil, TR)
text(banner, Enum.NormalId.Back, "GLIMMER", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(900, 100))
local banner2 = box(truck, "Banner2", -15, 3.6, -7.4, 11, 6.6, -7, DARK, nil, TR)
text(banner2, Enum.NormalId.Front, "GLIMMER", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(900, 100))
-- wheels with silver hubs: trailer tandem, drive tandem, steer
for _, w in {{-13, 6.2}, {-9, 6.2}, {15, 5.0}, {18.6, 5.0}, {25.8, 5.0}} do
	for _, s in {-1, 1} do
		local cf = TR * CFrame.new(w[1], 1.9, s * w[2]) * CFrame.Angles(0, math.rad(90), 0)
		cyl(truck, "Wheel", 1.4, 3.8, cf, Color3.fromRGB(20, 20, 20))
		cyl(truck, "Hub", 1.5, 1.6, cf, CHROME, Enum.Material.Metal)
	end
end
-- the stolen house rides on the trailer (Blocky's colors), front facing the truck's +Z side
local th = house(truck, "HouseOnTruck", TR * CFrame.new(-2, 3.6, 11) , HOUSE_COLORS.blocky, false)
th.Parent = truck
truck.PrimaryPart = truck.Trailer

-- police cars: face local -Z
local function copCar(name, at)
	local m = model(name, veh)
	box(m, "Body", -3.6, 1.2, -7, 3.6, 3.6, 7, WHITE, nil, at)
	box(m, "Hood", -3.62, 1.2, -7.02, 3.62, 3.62, -3, DARK, nil, at)
	box(m, "Trunk", -3.62, 1.2, 4, 3.62, 3.62, 7.02, DARK, nil, at)
	box(m, "Cabin", -3.2, 3.6, -2.5, 3.2, 6, 3.5, Color3.fromRGB(70, 90, 120), Enum.Material.Glass, at)
	box(m, "Roof", -3.3, 6, -2.4, 3.3, 6.3, 3.4, WHITE, nil, at)
	local red = box(m, "RedLight", -2.4, 6.3, -0.4, -0.1, 7, 0.6, Color3.fromRGB(255, 30, 30), Enum.Material.Neon, at)
	local blue = box(m, "BlueLight", 0.1, 6.3, -0.4, 2.4, 7, 0.6, Color3.fromRGB(40, 90, 255), Enum.Material.Neon, at)
	plight(red, Color3.fromRGB(255, 30, 30), 4, 30, false).Name = "Glow"
	plight(blue, Color3.fromRGB(40, 90, 255), 4, 30, false).Name = "Glow"
	local door = box(m, "DoorL", -3.65, 1.6, -2, -3.6, 3.4, 3, WHITE, nil, at)
	text(door, Enum.NormalId.Left, "POLICE", DARK, Enum.Font.GothamBlack)
	local door2 = box(m, "DoorR", 3.6, 1.6, -2, 3.65, 3.4, 3, WHITE, nil, at)
	text(door2, Enum.NormalId.Right, "POLICE", DARK, Enum.Font.GothamBlack)
	local h = box(m, "Headlights", -3, 2.4, -7.1, 3, 3, -7, Color3.fromRGB(255, 250, 220), Enum.Material.Neon, at)
	slight(h, Enum.NormalId.Front, Color3.fromRGB(255, 245, 220), 2, 40, 60)
	for _, z in {-4.5, 4.5} do
		for _, x in {-3.4, 3.4} do
			cyl(m, "Wheel", 1, 2.6, at * CFrame.new(x, 1.3, z), Color3.fromRGB(20, 20, 20))
		end
	end
	m.PrimaryPart = m.Body
	return m
end
for i = 1, 3 do copCar("CopCar" .. i, CFrame.new(900, 0, i * 30)) end

-- van cab interior (for close-ups of Grandma driving). Faces local -Z (camera in front looks +Z).
local vc = model("VanCab", veh)
local VC = CFrame.new(900, 0, 300)
box(vc, "Floor", -5, 0, -4, 5, 1.5, 6, Color3.fromRGB(60, 60, 66), nil, VC)
box(vc, "Dash", -5, 1.5, -4, 5, 4.6, -2.4, Color3.fromRGB(40, 40, 46), nil, VC)
box(vc, "DashTop", -5, 4.6, -4, 5, 5, -2.8, Color3.fromRGB(30, 30, 34), nil, VC)
cyl(vc, "Wheel", 0.4, 2.6, VC * CFrame.new(-2.5, 5.2, -2.4) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(0, 0, math.rad(25)), DARK)
box(vc, "WheelPost", -2.7, 3.6, -3, -2.3, 5, -2.4, DARK, nil, VC)
for i, x in {-2.5, 0.3, 3} do
	box(vc, "Seat", x - 1.4, 1.5, 0.6, x + 1.4, 3.2, 3.4, Color3.fromRGB(200, 120, 40), Enum.Material.Fabric, VC)
	box(vc, "SeatBack", x - 1.4, 3.2, 3, x + 1.4, 7.4, 3.8, Color3.fromRGB(200, 120, 40), Enum.Material.Fabric, VC)
end
box(vc, "Back", -5, 1.5, 5.5, 5, 10, 6, Color3.fromRGB(225, 225, 220), nil, VC)
box(vc, "Roof", -5, 10, -4.4, 5, 10.6, 6, Color3.fromRGB(235, 235, 230), nil, VC)
box(vc, "PillarL", -5, 5, -4.4, -4.4, 10, -3.8, Color3.fromRGB(235, 235, 230), nil, VC)
box(vc, "PillarR", 4.4, 5, -4.4, 5, 10, -3.8, Color3.fromRGB(235, 235, 230), nil, VC)
box(vc, "DoorL", -5.2, 1.5, -4, -4.8, 5.6, 5.5, Color3.fromRGB(235, 235, 230), nil, VC)
box(vc, "DoorR", 4.8, 1.5, -4, 5.2, 5.6, 5.5, Color3.fromRGB(235, 235, 230), nil, VC)
box(vc, "Stripe", -5.3, 3.6, -4, -5.2, 4.4, 5.5, Color3.fromRGB(255, 120, 0), nil, VC)
box(vc, "Road", -60, -0.6, -200, 60, -0.4, 200, ASPHALT, Enum.Material.Asphalt, VC)
local passing = folder("Passing", vc)
for i = 0, 9 do
	for _, x in {-14, 14} do
		local z = -180 + i * 40
		box(passing, "Post", x - 0.3, 0, z - 0.3, x + 0.3, 14, z + 0.3, DARK, Enum.Material.Metal, VC)
		local hd = box(passing, "Head", x - 1, 14, z - 1, x + 1, 14.6, z + 1, Color3.fromRGB(255, 230, 170), Enum.Material.Neon, VC)
		plight(hd, Color3.fromRGB(255, 200, 130), 2.5, 30, false)
	end
end
vc.PrimaryPart = vc.Floor

---------------------------------------------------------------- GAGS (600,0,500): little rooms for the opening montage
local G = Vector3.new(600, 0, 500)
local gags = folder("Gags", SETS)
local function room(name, origin, floorCol, wallCol, floorMat, wallMat)
	local f = folder(name, gags)
	local at = CFrame.new(origin)
	box(f, "Floor", -15, -1, -15, 15, 0, 15, floorCol, floorMat or Enum.Material.WoodPlanks, at)
	box(f, "WallBack", -15, 0, -16, 15, 16, -15, wallCol, wallMat or Enum.Material.Plaster, at)
	box(f, "WallLeft", -16, 0, -16, -15, 16, 15, wallCol, wallMat or Enum.Material.Plaster, at)
	box(f, "WallRight", 15, 0, -16, 16, 16, 15, wallCol, wallMat or Enum.Material.Plaster, at)
	return f, at
end
-- a) sleeping on top of their stuff
do
	local f, at = room("StuffPile", G, Color3.fromRGB(150, 110, 75), Color3.fromRGB(110, 120, 160))
	box(f, "Couch", -8, 0, -8, 4, 3.5, -2, Color3.fromRGB(80, 130, 90), Enum.Material.Fabric, at)
	box(f, "CouchBack", -8, 3.5, -8, 4, 6, -6.6, Color3.fromRGB(80, 130, 90), Enum.Material.Fabric, at)
	box(f, "TV", -6, 3.5, -5.5, 0, 7.4, -4.6, DARK, nil, at)
	box(f, "TVScreen", -5.6, 3.9, -4.65, -0.4, 7, -4.55, Color3.fromRGB(80, 160, 255), Enum.Material.Neon, at)
	box(f, "Box1", 0.5, 3.5, -6, 4, 6, -3, Color3.fromRGB(190, 150, 100), Enum.Material.Cardboard, at)
	box(f, "Box2", -9, 0, -2, -5, 3, 2, Color3.fromRGB(190, 150, 100), Enum.Material.Cardboard, at)
	box(f, "Box3", 1, 6, -5.5, 3.6, 8, -3.4, Color3.fromRGB(200, 160, 110), Enum.Material.Cardboard, at)
	ball(f, "PiggyBank", 1.8, at * CFrame.new(-2, 8.4, -5), Color3.fromRGB(255, 150, 180))
	cyl(f, "Trophy", 1.4, 0.8, at * CFrame.new(3, 8.7, -4.4) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Foil)
	cyl(f, "Bike", 0.4, 3, at * CFrame.new(6, 1.5, -4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(220, 40, 40))
	cyl(f, "Bike", 0.4, 3, at * CFrame.new(9, 1.5, -4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(220, 40, 40))
	local win = box(f, "Window", -4, 7, -15.1, 4, 13, -14.9, Color3.fromRGB(150, 180, 255), Enum.Material.Neon, at)
	slight(win, Enum.NormalId.Back, Color3.fromRGB(150, 170, 255), 2, 30, 70)
	local lmp = box(f, "Lamp", 9, 0, -12, 10.4, 7, -10.6, Color3.fromRGB(255, 220, 160), Enum.Material.Neon, at)
	plight(lmp, WARM, 1.5, 24)
end
-- b) the locked fridge
do
	local f, at = room("Fridge", G + Vector3.new(40, 0, 0), Color3.fromRGB(230, 230, 230), Color3.fromRGB(250, 235, 190), Enum.Material.Marble)
	box(f, "Counter", -14, 0, -15, -4, 4, -11, Color3.fromRGB(200, 120, 70), Enum.Material.Wood, at)
	box(f, "CounterTop", -14, 4, -15, -4, 4.4, -10.6, Color3.fromRGB(60, 60, 66), Enum.Material.Marble, at)
	local fr = box(f, "Fridge", -3, 0, -15, 3, 11, -10, Color3.fromRGB(235, 240, 245), Enum.Material.SmoothPlastic, at)
	box(f, "FridgeSplit", -3, 7.4, -10, 3, 7.6, -9.9, Color3.fromRGB(180, 180, 185), nil, at)
	box(f, "Handle", 2, 3, -9.9, 2.4, 7, -9.6, Color3.fromRGB(160, 160, 165), Enum.Material.Metal, at)
	-- chains in an X + a giant padlock
	local fc = at * CFrame.new(0, 5.5, -9.6)
	for _, a in {50, -50} do
		for i = -6, 6 do
			local c = fc * CFrame.Angles(0, 0, math.rad(a)) * CFrame.new(i * 0.55, 0, 0)
			part({Name = "Chain", Size = Vector3.new(0.7, 0.32, 0.2), CFrame = c * CFrame.Angles(i % 2 == 0 and math.rad(90) or 0, 0, 0),
				Color = Color3.fromRGB(110, 110, 120), Material = Enum.Material.Metal, Parent = f})
		end
	end
	box(f, "LockBody", -1.1, 4.0, -9.5, 1.1, 5.9, -8.6, GOLD, Enum.Material.Foil, at)
	box(f, "Shackle", -0.8, 5.9, -9.2, -0.5, 7.0, -8.9, Color3.fromRGB(170, 170, 180), Enum.Material.Metal, at)
	box(f, "Shackle", 0.5, 5.9, -9.2, 0.8, 7.0, -8.9, Color3.fromRGB(170, 170, 180), Enum.Material.Metal, at)
	box(f, "Shackle", -0.8, 6.8, -9.2, 0.8, 7.1, -8.9, Color3.fromRGB(170, 170, 180), Enum.Material.Metal, at)
	box(f, "LockHole", -0.15, 4.5, -8.62, 0.15, 5.1, -8.55, DARK, nil, at)
	local cl = box(f, "Ceiling", -15, 16, -15, 15, 16.5, 15, WHITE, nil, at)
	local l = box(f, "Light", -2, 15.6, -6, 2, 16, -2, Color3.fromRGB(255, 250, 230), Enum.Material.Neon, at)
	plight(l, Color3.fromRGB(255, 245, 225), 1.5, 30)
end
-- c) the dog with a padlock
do
	local f = folder("DogYard", gags)
	local at = CFrame.new(G + Vector3.new(80, 0, 0))
	box(f, "Grass", -15, -1, -15, 15, 0, 15, GRASS, Enum.Material.Grass, at)
	for x = -14, 14, 2 do
		box(f, "Picket", x - 0.4, 0, -14.4, x + 0.4, 4, -14, WHITE, nil, at)
	end
	box(f, "Rail", -15, 2.4, -14.2, 15, 2.8, -14.1, WHITE, nil, at)
	box(f, "DogHouse", 4, 0, -10, 12, 6, -4, Color3.fromRGB(200, 60, 50), Enum.Material.WoodPlanks, at)
	wedge(f, "DHRoof", Vector3.new(9, 3, 3.5), at * CFrame.new(8, 7.5, -5.3), Color3.fromRGB(90, 60, 40), Enum.Material.Slate)
	wedge(f, "DHRoof", Vector3.new(9, 3, 3.5), at * CFrame.new(8, 7.5, -8.7) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(90, 60, 40), Enum.Material.Slate)
	box(f, "DHDoor", 6.5, 0, -4.05, 9.5, 4, -3.95, DARK, nil, at)
	local sign = box(f, "DHSign", 6, 4.6, -3.95, 10, 5.8, -3.85, WHITE, nil, at)
	text(sign, Enum.NormalId.Back, "REX", Color3.fromRGB(200, 60, 50))
	local dog = model("Dog", f)
	local D = at * CFrame.new(-2, 0, -2) * CFrame.Angles(0, math.rad(20), 0)
	local BR = Color3.fromRGB(170, 115, 60)
	box(dog, "Body", -1, 2, -2, 1, 3.6, 2, BR, Enum.Material.SmoothPlastic, D)
	box(dog, "Head", -0.9, 3.2, -3.4, 0.9, 5, -1.6, BR, nil, D)
	box(dog, "Snout", -0.5, 3.3, -4.1, 0.5, 4.1, -3.4, Color3.fromRGB(200, 150, 100), nil, D)
	box(dog, "Nose", -0.25, 3.8, -4.2, 0.25, 4.15, -4.05, DARK, nil, D)
	box(dog, "EarL", -1.1, 4.2, -2.8, -0.7, 5.6, -2.2, Color3.fromRGB(110, 70, 40), nil, D)
	box(dog, "EarR", 0.7, 4.2, -2.8, 1.1, 5.6, -2.2, Color3.fromRGB(110, 70, 40), nil, D)
	box(dog, "EyeL", -0.6, 4.3, -3.42, -0.3, 4.6, -3.38, DARK, nil, D)
	box(dog, "EyeR", 0.3, 4.3, -3.42, 0.6, 4.6, -3.38, DARK, nil, D)
	for _, xz in {{-0.7, -1.4}, {0.7, -1.4}, {-0.7, 1.4}, {0.7, 1.4}} do
		box(dog, "Leg", xz[1] - 0.3, 0, xz[2] - 0.3, xz[1] + 0.3, 2, xz[2] + 0.3, BR, nil, D)
	end
	box(dog, "Tail", -0.15, 3.2, 2, 0.15, 3.5, 3.2, BR, nil, D).Name = "Tail"
	box(dog, "Collar", -1, 3.1, -1.9, 1, 3.5, -1.5, Color3.fromRGB(220, 40, 40), nil, D)
	box(dog, "Lock", -0.6, 1.8, -2.2, 0.6, 3.0, -1.8, GOLD, Enum.Material.Foil, D)
	box(dog, "LockShackle", -0.4, 3.0, -2.1, 0.4, 3.3, -1.9, Color3.fromRGB(170, 170, 180), Enum.Material.Metal, D)
	dog.PrimaryPart = dog.Body
	tree(f, at.Position + Vector3.new(-10, 0, -8), 0.8)
end
-- d) sneaking class
do
	local f, at = room("Classroom", G + Vector3.new(120, 0, 0), Color3.fromRGB(190, 160, 120), Color3.fromRGB(235, 225, 190))
	local board = box(f, "Chalkboard", -10, 5, -14.9, 10, 12, -14.7, Color3.fromRGB(40, 80, 55), nil, at)
	text(board, Enum.NormalId.Back, "SNEAKING 101", Color3.fromRGB(245, 245, 235), Enum.Font.PermanentMarker, nil, Vector2.new(500, 170))
	box(f, "BoardTrim", -10.4, 4.6, -14.95, 10.4, 5, -14.6, Color3.fromRGB(150, 110, 70), Enum.Material.Wood, at)
	box(f, "TeacherDesk", 6, 0, -11, 13, 3.6, -7.5, Color3.fromRGB(150, 100, 60), Enum.Material.Wood, at)
	ball(f, "Apple", 0.9, at * CFrame.new(11, 4.05, -9), Color3.fromRGB(220, 30, 30))
	for _, xz in {{-9, 2}, {-3, 2}, {3, 2}, {-9, 8}, {-3, 8}, {3, 8}} do
		box(f, "Desk", xz[1] - 1.8, 2.6, xz[2] - 1.2, xz[1] + 1.8, 3, xz[2] + 1.2, Color3.fromRGB(200, 160, 110), Enum.Material.Wood, at)
		box(f, "DeskLeg", xz[1] - 0.2, 0, xz[2] - 0.2, xz[1] + 0.2, 2.6, xz[2] + 0.2, Color3.fromRGB(80, 80, 90), Enum.Material.Metal, at)
	end
	local poster = box(f, "Poster", -15, 6, -6, -14.9, 11, 0, Color3.fromRGB(255, 240, 200), nil, at)
	text(poster, Enum.NormalId.Right, "SHHH!", Color3.fromRGB(200, 50, 50), Enum.Font.FredokaOne)
	box(f, "Ceiling", -15, 16, -15, 15, 16.5, 15, WHITE, nil, at)
	for _, x in {-7, 7} do
		local l = box(f, "Light", x - 2, 15.6, -4, x + 2, 16, 0, Color3.fromRGB(255, 250, 230), Enum.Material.Neon, at)
		plight(l, Color3.fromRGB(255, 245, 225), 1.4, 28)
	end
end
-- e) Blocky's bedroom
do
	local f, at = room("Bedroom", G + Vector3.new(160, 0, 0), Color3.fromRGB(110, 140, 200), Color3.fromRGB(120, 170, 220), Enum.Material.Fabric)
	box(f, "BedFrame", -6, 0, -14, 2, 1.6, -8.8, Color3.fromRGB(120, 80, 50), Enum.Material.Wood, at)
	box(f, "Headboard", -6.6, 0, -14, -6, 4.2, -8.8, Color3.fromRGB(120, 80, 50), Enum.Material.Wood, at)
	box(f, "Mattress", -6, 1.6, -13.8, 2, 2.6, -9, WHITE, Enum.Material.Fabric, at)
	box(f, "Pillow", -5.8, 2.6, -13, -4.2, 3.2, -9.8, Color3.fromRGB(250, 250, 255), Enum.Material.Fabric, at)
	box(f, "Blanket", -3.6, 2.6, -13.9, 2.1, 4.3, -8.9, Color3.fromRGB(255, 140, 40), Enum.Material.Fabric, at)
	box(f, "Nightstand", 3, 0, -14, 6, 3, -11, Color3.fromRGB(150, 100, 60), Enum.Material.Wood, at)
	local l = box(f, "Lamp", 4, 3, -13, 5, 5.2, -12, Color3.fromRGB(255, 220, 150), Enum.Material.Neon, at)
	plight(l, WARM, 1.6, 20)
	local poster = box(f, "Poster", -2, 7, -14.95, 4, 12, -14.85, Color3.fromRGB(255, 120, 0), nil, at)
	text(poster, Enum.NormalId.Back, "BLOCKY", WHITE, Enum.Font.FredokaOne)
	local win = box(f, "Window", 7, 6, -14.95, 12, 12, -14.85, Color3.fromRGB(140, 170, 255), Enum.Material.Neon, at)
	slight(win, Enum.NormalId.Back, Color3.fromRGB(140, 160, 255), 1.5, 30, 70)
	for i = 0, 3 do
		box(f, "Toy", -12 + i * 1.6, 0, -14, -10.6 + i * 1.6, 1.4, -12.6, ({Color3.fromRGB(230, 50, 50), Color3.fromRGB(50, 150, 230), Color3.fromRGB(250, 210, 40), Color3.fromRGB(60, 190, 90)})[i + 1], nil, at)
	end
end
-- f) Mr. Glimmer's money room
do
	local f, at = room("MoneyRoom", G + Vector3.new(200, 0, 0), Color3.fromRGB(90, 30, 40), Color3.fromRGB(110, 30, 45), Enum.Material.Fabric, Enum.Material.Fabric)
	box(f, "Trim", -15, 13, -14.9, 15, 14, -14.6, GOLD, Enum.Material.Foil, at)
	local frame = box(f, "Portrait", -5, 6, -14.95, 5, 14.5, -14.6, GOLD, Enum.Material.Foil, at)
	local canvas = box(f, "PortraitCanvas", -4.3, 6.6, -14.6, 4.3, 13.9, -14.5, Color3.fromRGB(40, 30, 30), nil, at)
	text(canvas, Enum.NormalId.Back, "MR.\nGLIMMER", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(300, 260))
	local rng = Random.new(7)
	for i = 1, 260 do
		local r = 9 * math.sqrt(rng:NextNumber())
		local a = rng:NextNumber() * math.pi * 2
		local x, z = math.cos(a) * r, math.sin(a) * r * 0.7 - 4
		local y = math.max(0, 4.5 - r * 0.45) + rng:NextNumber() * 0.6
		cyl(f, "Coin", 0.25, 1.4, at * CFrame.new(x, y, z) * CFrame.Angles(rng:NextNumber() * 0.6, rng:NextNumber() * 6, math.rad(90) + rng:NextNumber() * 0.6), GOLD, Enum.Material.Foil)
	end
	for i = 0, 4 do
		box(f, "GoldBar", 9, i * 0.9, -12, 12, i * 0.9 + 0.9, -10.6, GOLD, Enum.Material.Foil, at)
		box(f, "GoldBar", -12, i * 0.9, -12, -9, i * 0.9 + 0.9, -10.6, GOLD, Enum.Material.Foil, at)
	end
	for _, x in {-11, 11} do
		ball(f, "MoneyBag", 3, at * CFrame.new(x, 1.5, -6), Color3.fromRGB(110, 160, 80), Enum.Material.Fabric)
		local tag = box(f, "BagSign", x - 0.8, 1.2, -4.55, x + 0.8, 2.4, -4.45, Color3.fromRGB(110, 160, 80), nil, at)
		text(tag, Enum.NormalId.Back, "$", GOLD)
	end
	local cl = box(f, "Chandelier", -2, 14.5, -6, 2, 15.5, -2, GOLD, Enum.Material.Neon, at)
	plight(cl, Color3.fromRGB(255, 220, 140), 2.5, 34)
end

---------------------------------------------------------------- GLIMMER LOT (-600,0,0): every stolen house in rows
local LOT = Vector3.new(-600, 0, 0)
local lot = folder("Lot", SETS)
local lStatic = folder("Static", lot)
box(lStatic, "Gravel", LOT.X - 160, -2, -160, LOT.X + 160, 0, 260, Color3.fromRGB(150, 145, 135), Enum.Material.Pebble)
box(lStatic, "Grass", LOT.X - 400, -2.1, -400, LOT.X + 400, -0.05, 400, GRASS, Enum.Material.Grass)
box(lStatic, "Road", LOT.X - 12, 0, 82, LOT.X + 12, 0.2, 260, ASPHALT, Enum.Material.Asphalt)
box(lStatic, "LotRoad", LOT.X - 150, 0, 58, LOT.X + 150, 0.15, 72, Color3.fromRGB(110, 110, 110), Enum.Material.Asphalt)
for x = LOT.X - 140, LOT.X + 140, 10 do
	if math.abs(x - LOT.X) > 14 then
		box(lStatic, "FencePost", x - 0.25, 0, 79.75, x + 0.25, 10, 80.25, Color3.fromRGB(140, 140, 150), Enum.Material.Metal)
		local pnl = box(lStatic, "Fence", x, 0.5, 79.9, x + 10, 9.5, 80.1, Color3.fromRGB(170, 175, 185), Enum.Material.DiamondPlate)
		pnl.Transparency = 0.55
	end
end
for z = -140, 80, 10 do
	for _, x in {LOT.X - 140, LOT.X + 140} do
		box(lStatic, "FencePost", x - 0.25, 0, z - 0.25, x + 0.25, 10, z + 0.25, Color3.fromRGB(140, 140, 150), Enum.Material.Metal)
		local pnl = box(lStatic, "Fence", x - 0.1, 0.5, z, x + 0.1, 9.5, z + 10, Color3.fromRGB(170, 175, 185), Enum.Material.DiamondPlate)
		pnl.Transparency = 0.55
	end
end
for _, x in {LOT.X - 15, LOT.X + 15} do
	box(lStatic, "GatePost", x - 1, 0, 79, x + 1, 22, 81, DARK, Enum.Material.Metal)
end
local sign = box(lStatic, "LotSign", LOT.X - 16, 15, 79.6, LOT.X + 16, 21, 80.4, DARK)
text(sign, Enum.NormalId.Back, "GLIMMER LOT", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(800, 150))
text(sign, Enum.NormalId.Front, "GLIMMER LOT", GOLD, Enum.Font.FredokaOne, nil, Vector2.new(800, 150))
plight(sign, Color3.fromRGB(255, 210, 120), 2, 30)
local lHouses = folder("Houses", lot)
local rows = {40, -10, -60, -110}
local cols = {-110, -66, -22, 22, 66, 110}
local k = 0
for ri, z in rows do
	for ci2, dx in cols do
		k += 1
		local isBlocky = (ri == 1 and dx == 22)
		local col = isBlocky and HOUSE_COLORS.blocky or HOUSE_COLORS[(k * 3) % #HOUSE_COLORS + 1]
		local h, door = house(lHouses, isBlocky and "BlockyLotHouse" or ("LotHouse" .. k), CFrame.new(LOT.X + dx, 0.01, z), col, false)
	end
end
for _, xz in {{-140, 80}, {140, 80}, {-140, -140}, {140, -140}, {0, -20}} do
	box(lStatic, "Flood", LOT.X + xz[1] - 0.4, 0, xz[2] - 0.4, LOT.X + xz[1] + 0.4, 26, xz[2] + 0.4, DARK, Enum.Material.Metal)
	local fl = box(lStatic, "FloodHead", LOT.X + xz[1] - 1.5, 26, xz[2] - 1.5, LOT.X + xz[1] + 1.5, 27, xz[2] + 1.5, Color3.fromRGB(255, 245, 220), Enum.Material.Neon)
	plight(fl, Color3.fromRGB(255, 240, 210), 2, 60, false)
end

---------------------------------------------------------------- MANSION (-600,0,500): where Blocky's family ends up
local M = Vector3.new(-600, 0, 500)
local man = folder("Mansion", SETS)
local MA = CFrame.new(M)
box(man, "Lawn", -120, -2, -120, 120, 0, 60, GRASS, Enum.Material.Grass, MA)
box(man, "Street", -120, 0, 40, 120, 0.2, 60, ASPHALT, Enum.Material.Asphalt, MA)
box(man, "Curb", -120, 0, 34, 120, 0.8, 40, CONCRETE, Enum.Material.Concrete, MA)
box(man, "Walk", -6, 0, 0, 6, 0.4, 34, Color3.fromRGB(230, 220, 200), Enum.Material.Marble, MA)
box(man, "MainHouse", -40, 0, -60, 40, 34, -10, Color3.fromRGB(250, 245, 235), Enum.Material.Marble, MA)
box(man, "RoofTop", -42, 34, -62, 42, 36, -8, Color3.fromRGB(60, 60, 70), Enum.Material.Slate, MA)
box(man, "GoldTrim", -40.2, 33, -60, 40.2, 34, -9.8, GOLD, Enum.Material.Foil, MA)
for x = -32, 32, 8 do
	cyl(man, "Pillar", 22, 2.4, MA * CFrame.new(x, 11, -7) * CFrame.Angles(0, 0, math.rad(90)), WHITE, Enum.Material.Marble)
end
box(man, "Portico", -36, 22, -10, 36, 24, -5, WHITE, Enum.Material.Marble, MA)
box(man, "Balcony", -12, 22, -10, 12, 23, -2, WHITE, Enum.Material.Marble, MA)
box(man, "BalconyRail", -12, 23, -2.4, 12, 25.6, -2, GOLD, Enum.Material.Foil, MA)
box(man, "FrontDoor", -4, 0, -10.2, 4, 12, -9.8, Color3.fromRGB(120, 60, 30), Enum.Material.Wood, MA)
for _, x in {-24, -14, 14, 24} do
	for _, y in {6, 20, 28} do
		local w = box(man, "Win", x - 2.5, y - 2.5, -10.2, x + 2.5, y + 2.5, -9.9, Color3.fromRGB(255, 220, 150), Enum.Material.Neon, MA)
	end
end
for x = -100, 100, 4 do
	if math.abs(x) > 8 then
		box(man, "GoldFence", x - 0.3, 0, 31.7, x + 0.3, 7, 32.3, GOLD, Enum.Material.Foil, MA)
	end
end
box(man, "FenceRail", -100, 6, 31.8, -8, 6.6, 32.2, GOLD, Enum.Material.Foil, MA)
box(man, "FenceRail", 8, 6, 31.8, 100, 6.6, 32.2, GOLD, Enum.Material.Foil, MA)
local gsign = box(man, "GateSign", -8, 8, 31.6, 8, 11, 32.4, DARK, nil, MA)
text(gsign, Enum.NormalId.Back, "GLIMMER MANSION", GOLD)
local throne = model("FancyChair", man)
local FC = MA * CFrame.new(16, 0, 10) * CFrame.Angles(0, math.rad(-20), 0)
box(throne, "Seat", -2.4, 0, -2.2, 2.4, 2.4, 2.4, Color3.fromRGB(170, 30, 50), Enum.Material.Fabric, FC)
box(throne, "Back", -2.4, 2.4, -2.4, 2.4, 8, -1.2, Color3.fromRGB(170, 30, 50), Enum.Material.Fabric, FC)
box(throne, "Trim", -2.6, 8, -2.5, 2.6, 8.6, -1.1, GOLD, Enum.Material.Foil, FC)
tree(man, M + Vector3.new(-50, 0, 10), 1.3)
tree(man, M + Vector3.new(50, 0, 10), 1.3)
box(man, "Fountain", -26, 0, 4, -14, 1.6, 16, Color3.fromRGB(230, 230, 230), Enum.Material.Marble, MA)
local water = box(man, "Water", -25, 1.2, 5, -15, 1.5, 15, Color3.fromRGB(80, 170, 255), Enum.Material.Glass, MA)
water.Transparency = 0.3

---------------------------------------------------------------- STORE extras (inside the heist map)
-- keypad face with a screen the Director types into
local KP = CFrame.new(-15, 5.5, -27.45)
local kface = box(STORE, "KeypadFace", -0.8, -1, -0.05, 0.8, 1, 0.05, Color3.fromRGB(25, 25, 30), nil, KP)
local ks = Instance.new("SurfaceGui")
ks.Face = Enum.NormalId.Back
ks.CanvasSize = Vector2.new(160, 200)
ks.LightInfluence = 0
ks.Parent = kface
local scr = Instance.new("TextLabel")
scr.Name = "Screen"
scr.Size = UDim2.new(1, -16, 0, 44)
scr.Position = UDim2.fromOffset(8, 6)
scr.BackgroundColor3 = Color3.fromRGB(20, 60, 30)
scr.TextColor3 = Color3.fromRGB(90, 255, 120)
scr.Font = Enum.Font.Code
scr.TextScaled = true
scr.Text = "----"
scr.Parent = ks
local n = 0
for r = 0, 3 do
	for c = 0, 2 do
		n += 1
		local b = Instance.new("TextLabel")
		b.Name = "Btn" .. n
		b.Size = UDim2.fromOffset(40, 30)
		b.Position = UDim2.fromOffset(14 + c * 46, 58 + r * 35)
		b.BackgroundColor3 = Color3.fromRGB(70, 72, 80)
		b.TextColor3 = WHITE
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.Text = ({"1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"})[n]
		b.Parent = ks
	end
end
-- the sticky note's code
local noteTxt = box(STORE, "NoteText", 22, 3.56, -24.6, 23.4, 3.6, -23.4, Color3.fromRGB(255, 245, 160))
text(noteTxt, Enum.NormalId.Top, "4821", Color3.fromRGB(30, 30, 160), Enum.Font.PermanentMarker, nil, Vector2.new(200, 200))
-- breaker lever (pivot = LeverPivot; the Director turns it) + POWER sign
local pivot = box(STORE, "LeverPivot", 39.0, 5.3, -17.7, 39.3, 5.7, -17.3, Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
local arm = box(STORE, "LeverArm", 38.0, 5.35, -17.62, 39.0, 5.65, -17.38, Color3.fromRGB(150, 150, 150), Enum.Material.Metal)
local knob = box(STORE, "LeverKnob", 37.4, 5.1, -17.85, 38.1, 5.9, -17.15, Color3.fromRGB(220, 30, 30))
pivot:SetAttribute("Home", pivot.CFrame)
arm:SetAttribute("Home", arm.CFrame)
knob:SetAttribute("Home", knob.CFrame)
local psign = box(STORE, "PowerSign", 39.2, 8.4, -18.8, 39.3, 9.8, -16.2, Color3.fromRGB(255, 210, 0))
text(psign, Enum.NormalId.Left, "⚡ POWER", DARK, Enum.Font.GothamBlack)
-- the key wall inside the vault (back wall + both sides)
local keys = folder("VaultKeys", STORE)
local NAMES = {"SMITH", "LOPEZ", "KIM", "JONES", "PATEL", "GARCIA", "BROWN", "LEE", "NGUYEN", "DAVIS", "MILLER", "WILSON", "TAYLOR",
	"CLARK", "HALL", "YOUNG", "KING", "WRIGHT", "GREEN", "BAKER", "ADAMS", "NELSON", "HILL", "CAMPBELL"}
local rng2 = Random.new(3)
local ki = 0
local function key(parent, cf, named)
	ki += 1
	local m = model("Key" .. ki, parent)
	local kc = rng2:NextNumber() < 0.7 and GOLD or Color3.fromRGB(200, 205, 215)
	cyl(m, "Bow", 0.12, 0.55, cf * CFrame.Angles(0, math.rad(90), 0), kc, Enum.Material.Metal)
	part({Name = "Shaft", Size = Vector3.new(0.14, 0.75, 0.08), CFrame = cf * CFrame.new(0, -0.6, 0), Color = kc, Material = Enum.Material.Metal, Parent = m})
	local tag = part({Name = "Tag", Size = Vector3.new(0.6, 0.38, 0.05), CFrame = cf * CFrame.new(0.42, -0.35, 0.02) * CFrame.Angles(0, 0, math.rad(-12)),
		Color = Color3.fromRGB(250, 248, 235), Parent = m})
	if named then
		text(tag, Enum.NormalId.Back, NAMES[(ki % #NAMES) + 1], Color3.fromRGB(30, 30, 30), Enum.Font.PermanentMarker, nil, Vector2.new(120, 70))
	end
	return m
end
for y = 1.6, 10.6, 1.0 do
	for x = -32.4, -7.8, 0.85 do
		local named = (y > 3.5 and y < 8.5) and (rng2:NextNumber() < 0.5)
		key(keys, CFrame.new(x, y, -38.85), named)
	end
end
for _, side in {{-32.85, math.rad(90)}, {-7.15, math.rad(-90)}} do
	for y = 1.6, 10.6, 1.0 do
		for z = -38.2, -29.6, 0.85 do
			key(keys, CFrame.new(side[1], y, z) * CFrame.Angles(0, side[2], 0), false)
		end
	end
end
local vl = box(STORE, "VaultGlow", -22, 11.6, -36, -18, 11.9, -32, Color3.fromRGB(255, 235, 190), Enum.Material.Neon)
plight(vl, Color3.fromRGB(255, 225, 170), 2, 26)
-- hero props (parked offstage; the Director attaches them to hands)
local props = folder("HeroProps", STORE)
local function heroKey(name, label)
	local m = model(name, props)
	local cf = CFrame.new(0, 300, 3000)
	cyl(m, "Bow", 0.25, 1.1, cf * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal)
	part({Name = "Shaft", Size = Vector3.new(0.28, 1.5, 0.14), CFrame = cf * CFrame.new(0, -1.2, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = m})
	part({Name = "Tooth", Size = Vector3.new(0.4, 0.2, 0.14), CFrame = cf * CFrame.new(0.2, -1.7, 0), Color = GOLD, Material = Enum.Material.Metal, Parent = m})
	local tag = part({Name = "Tag", Size = Vector3.new(1.7, 0.95, 0.06), CFrame = cf * CFrame.new(1.05, -0.5, 0) * CFrame.Angles(0, 0, math.rad(-10)),
		Color = Color3.fromRGB(250, 248, 235), Parent = m})
	text(tag, Enum.NormalId.Back, label, Color3.fromRGB(30, 30, 30), Enum.Font.PermanentMarker, nil, Vector2.new(200, 110))
	text(tag, Enum.NormalId.Front, label, Color3.fromRGB(30, 30, 30), Enum.Font.PermanentMarker, nil, Vector2.new(200, 110))
	m.PrimaryPart = m.Bow
	return m
end
heroKey("KeyTony", "TONY")
heroKey("KeyGlimmer", "MR. GLIMMER")
heroKey("KeyBlocky", "BLOCKY")
local bag = model("Bag", props)
ball(bag, "Sack", 3, CFrame.new(10, 300, 3000), Color3.fromRGB(150, 110, 70), Enum.Material.Fabric)
cyl(bag, "Tie", 0.8, 1.2, CFrame.new(10, 301.6, 3000) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(120, 85, 55), Enum.Material.Fabric)
for i = 1, 5 do
	cyl(bag, "PokingKey", 0.1, 0.5, CFrame.new(10 + (i - 3) * 0.3, 302.2, 3000 + (i % 2) * 0.3) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal)
end
bag.PrimaryPart = bag.Sack
local fl = model("Flashlight", props)
cyl(fl, "Body", 1.4, 0.45, CFrame.new(20, 300, 3000), DARK, Enum.Material.Metal)
local lens = cyl(fl, "Lens", 0.12, 0.55, CFrame.new(20.75, 300, 3000), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
local beam = slight(lens, Enum.NormalId.Right, Color3.fromRGB(255, 248, 215), 6, 40, 30)
beam.Name = "Beam"
fl.PrimaryPart = fl.Body
local tv = model("TV", props)
box(tv, "Box", -1.6, -1.2, -0.7, 1.6, 1.2, 0.7, DARK, nil, CFrame.new(30, 300, 3000))
box(tv, "Screen", -1.4, -1.0, -0.72, 1.4, 1.0, -0.7, Color3.fromRGB(80, 160, 255), Enum.Material.Neon, CFrame.new(30, 300, 3000))
tv.PrimaryPart = tv.Box

local total = 0
for _ in film:GetDescendants() do total += 1 end
return "sets built: " .. count .. " parts, film total " .. total .. " instances"
