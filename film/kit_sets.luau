-- Blocky Tales KIT SETS: the shared world every reel can film in. Built in Edit mode ONLY into workspace.Film.KitSets
-- (installed with the base by film.py; destroys KitSets first, so it is safe to re-run). Map + names: film/KIT.md.
-- World centre C = (0, 0, -3000): Maple Street (road along X), houses both sides, school at the east end, the fair
-- (Ferris wheel) and the WINTER park (snow, sled hill, frozen pond) to the south, interiors (bedroom, vet room) in the
-- west woods, pine forest band, mountain ring on the horizon.
-- Creator Store models are fetched with game:GetObjects; EVERY script inside them is deleted, every part anchored.
-- Pets (Biscuit + puppy, cat, hamster, parrot, goldfish, fish-with-legs, car-sized fish) are block builds with named
-- limbs + pivots; they park underground and the Director poses them every frame.
local film = workspace:FindFirstChild("Film")
local old = film:FindFirstChild("KitSets")
if old then old:Destroy() end
local SETS = Instance.new("Folder")
SETS.Name = "KitSets"

local V, CF, rad = Vector3.new, CFrame.new, math.rad
local C3 = Color3.fromRGB
local C = V(0, 0, -3000)
local PARK = CF(C + V(0, -400, 0)) -- offstage (underground) for movable things
local LOG = {}
local nparts = 0
local function tick()
	nparts += 1
	if nparts % 300 == 0 then task.wait() end
end
local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
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
local function box(parent, name, x1, y1, z1, x2, y2, z2, color, mat)
	return part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
		CFrame = CF(C + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)), Color = color, Material = mat or Enum.Material.SmoothPlastic, Parent = parent})
end
local function text(p, face, str, color, font, bg)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 0.3
	sg.CanvasSize = Vector2.new(600, 100)
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	if bg then t.BackgroundColor3 = bg end
	t.Font = font or Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = color
	t.Parent = sg
	return t
end

---------------------------------------------------------------- Creator Store loader (scripts stripped)
local cache = {}
local function fetch(id)
	if cache[id] ~= nil then return cache[id] end
	local ok, r = pcall(function() return game:GetObjects("rbxassetid://" .. id) end)
	if not ok or not r or #r == 0 then
		table.insert(LOG, "FAILED " .. id .. " " .. tostring(r))
		cache[id] = false
		return false
	end
	local m = Instance.new("Model")
	m.Name = "Store" .. id
	for _, o in r do o.Parent = m end
	local stripped, np = 0, 0
	for _, d in m:GetDescendants() do
		if d.Parent == nil then continue end
		if d:IsA("LuaSourceContainer") then stripped += 1 d:Destroy()
		elseif d:IsA("Humanoid") or d:IsA("Sound") or d:IsA("ClickDetector") or d:IsA("ProximityPrompt") or d:IsA("Tool")
			or d:IsA("BillboardGui") or d:IsA("Fire") or d:IsA("Smoke") then d:Destroy()
		elseif d:IsA("BasePart") then
			np += 1
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	-- whatever is left that can run code is gone; double-check
	for _, d in m:GetDescendants() do
		if d:IsA("LuaSourceContainer") then error("script survived in " .. id) end
	end
	m:SetAttribute("StoreId", id)
	m:SetAttribute("ScriptsStripped", stripped)
	table.insert(LOG, string.format("store %s: %d parts, %d scripts stripped", id, np, stripped))
	cache[id] = m
	return m
end
-- place a store model with its footprint's bottom-centre at `cf` (optionally scaled, yawed first)
local function store(id, name, parent, cf, scale)
	local src = fetch(id)
	if not src then return nil end
	local m = src:Clone()
	m.Name = name
	if scale and scale ~= 1 then m:ScaleTo(scale) end
	local bcf, sz = m:GetBoundingBox()
	m.WorldPivot = CF(bcf.Position.X, bcf.Position.Y - sz.Y / 2, bcf.Position.Z)
	m:PivotTo(cf)
	m.Parent = parent
	task.wait()
	return m
end

---------------------------------------------------------------- ground, street
local GRASS = C3(96, 152, 62)
local ASPHALT = C3(62, 64, 70)
local WALK = C3(190, 186, 176)
local ground = folder("Ground", SETS)
box(ground, "Ground", -1300, -2, -1300, 1300, 0, 1300, GRASS, Enum.Material.Grass)
box(ground, "Road", -330, -1, -11, 330, 0.12, 11, ASPHALT, Enum.Material.Asphalt)
box(ground, "WalkN", -330, -1, -19, 330, 0.55, -11, WALK, Enum.Material.Concrete)
box(ground, "WalkS", -330, -1, 11, 330, 0.55, 19, WALK, Enum.Material.Concrete)
for x = -320, 320, 16 do
	box(ground, "Dash", x, 0.12, -0.3, x + 7, 0.16, 0.3, C3(245, 210, 70), Enum.Material.SmoothPlastic)
end
-- the road runs on into the school's front plaza
box(ground, "Plaza", 330, -1, -40, 420, 0.3, 40, C3(200, 196, 186), Enum.Material.Concrete)

---------------------------------------------------------------- houses (Creator Store), both sides of the street
local houses = folder("Houses", SETS)
-- {store id, yaw that turns its front toward +Z (north side)}: checked by eye in the lookdev stills
local HOUSE_IDS = {{18102018549, 0}, {317197851, 0}, {16127244089, 0}, {125443645311849, 0}, {18609718207, 0}}
local XS = {-175, -60, 60, 175}
local k = 0
for _, side in {-1, 1} do
	for _, x in XS do
		k += 1
		local h = HOUSE_IDS[(k - 1) % #HOUSE_IDS + 1]
		if side == -1 and x == 60 then h = HOUSE_IDS[1] end -- Blocky's house: the sage-green two-storey
		local src = fetch(h[1])
		if src then
			local _, sz = src:GetBoundingBox()
			local yaw = h[2] + (side == 1 and 180 or 0)
			local depth = (math.abs(math.cos(rad(h[2]))) > 0.5) and sz.Z or sz.X
			local cf = CF(C + V(x, 0, side * (24 + depth / 2))) * CFrame.Angles(0, rad(yaw), 0)
			local m = store(h[1], (side == -1 and x == 60) and "BlockyHouse" or ("House" .. k), houses, cf)
			if m then m:SetAttribute("Side", side) m:SetAttribute("X", x) end
		end
	end
end

---------------------------------------------------------------- trees, forest, mountains
local nature = folder("Nature", SETS)
local rng = Random.new(42)
-- leafy street trees on the verge
for _, side in {-1, 1} do
	for x = -300, 300, 58 do
		local m = store(12605122162, "StreetTree", nature, CF(C + V(x + rng:NextNumber(-6, 6), 0, side * 21)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber(0.26, 0.34))
	end
end
-- pine forest band (keeps out of the street, park, school and interiors)
local function reserved(x, z)
	return (math.abs(x) < 340 and math.abs(z) < 160) or (math.abs(x) < 320 and z > 140 and z < 580)
		or (x > 320 and x < 640 and math.abs(z) < 200) or (x < -320 and x > -600 and math.abs(z) < 140)
end
local placed = 0
for i = 1, 900 do
	if placed >= 260 then break end
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(250, 1050)
	local x, z = math.cos(a) * r, math.sin(a) * r
	if not reserved(x, z) then
		local id = (i % 4 == 0) and 183435411 or 5392132809
		local s = (id == 183435411) and rng:NextNumber(1.2, 2.0) or rng:NextNumber(0.9, 1.6)
		store(id, "Pine", nature, CF(C + V(x, 0, z)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), s)
		placed += 1
	end
end
-- mountain ring on the horizon
for i = 0, 11 do
	local a = math.pi * 2 * i / 12 + rng:NextNumber(-0.1, 0.1)
	local r = rng:NextNumber(1550, 1800)
	local id = (i % 2 == 0) and 11720266086 or 8761896930
	store(id, "Mountain", nature, CF(C + V(math.cos(a) * r, -20, math.sin(a) * r)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber(0.85, 1.25))
end
for _, m in nature:GetChildren() do
	if m.Name == "Mountain" then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then p.Color = C3(92, 112, 96) p.CastShadow = false end
		end
	end
end
table.insert(LOG, "pines " .. placed)

---------------------------------------------------------------- school (east end), playground (park), interiors (west woods)
local places = folder("Places", SETS)
store(76558120171446, "School", places, CF(C + V(500, 0, 0)) * CFrame.Angles(0, rad(90), 0))
store(3699248235, "Playground", places, CF(C + V(-60, 0, 250)))
store(5474231697, "Bedroom", places, CF(C + V(-460, 0, -60)))
store(7159480504, "FerrisWheel", places, CF(C + V(-190, 0, 330)) * CFrame.Angles(0, rad(20), 0))

store(303336108, "RockingChairSrc", places, CF(C + V(0, -400, 40)))

---------------------------------------------------------------- WINTER park (south): snow field, sled hill, frozen pond
-- (ice top y 0.85, dark water top y 0.35 under it) the pond's ice = 24 outer slabs + a core + 8 chunks (Ice1..Ice8) round the hole spot, so the Director can crack/sink them.
local winter = folder("Winter", SETS)
local W0 = C + V(120, 0, 430)
local SNOW = C3(240, 244, 252)
part({Name = "SnowField", Shape = Enum.PartType.Cylinder, Size = V(1.4, 300, 300), CFrame = CF(W0 + V(0, -0.5, 0)) * CFrame.Angles(0, 0, rad(90)),
	Color = SNOW, Material = Enum.Material.Snow, Parent = winter})
part({Name = "SledHill", Shape = Enum.PartType.Ball, Size = V(120, 60, 120), CFrame = CF(W0 + V(-70, -14, -40)), Color = SNOW, Material = Enum.Material.Snow, Parent = winter})
part({Name = "Water", Shape = Enum.PartType.Cylinder, Size = V(0.4, 62, 62), CFrame = CF(W0 + V(30, 0.15, 30)) * CFrame.Angles(0, 0, rad(90)),
	Color = C3(18, 40, 58), Material = Enum.Material.Glass, Reflectance = 0.25, Parent = winter})
part({Name = "PondBank", Shape = Enum.PartType.Cylinder, Size = V(0.6, 70, 70), CFrame = CF(W0 + V(30, -0.05, 30)) * CFrame.Angles(0, 0, rad(90)),
	Color = C3(120, 110, 100), Material = Enum.Material.Slate, Parent = winter})
local iceF = folder("Ice", winter)
local HOLE = W0 + V(36, 0, 36)
winter:SetAttribute("Hole", HOLE)
for i = 0, 29 do -- outer ice ring (radius 13..30), always whole
	local a0 = math.pi * 2 * i / 30
	local mid = W0 + V(30, 0, 30) + V(math.cos(a0) * 21.5, 0, math.sin(a0) * 21.5)
	part({Name = "IceSlab", Size = V(17.5, 0.5, 7), CFrame = CFrame.lookAt(mid + V(0, 0.6, 0), W0 + V(30, 0.6, 30)) * CFrame.Angles(0, rad(90), 0),
		Color = C3(190, 225, 245), Material = Enum.Material.Ice, Transparency = 0.08, Parent = iceF})
end
-- inner ice: a 2-stud grid inside radius 13, leaving the hole spot for the chunks
for gx = -13, 13, 2 do
	for gz = -13, 13, 2 do
		local c = W0 + V(30 + gx, 0.6, 30 + gz)
		if gx * gx + gz * gz <= 13.5 * 13.5 and ((c - HOLE) * V(1, 0, 1)).Magnitude > 4.0 then
			part({Name = "IceTile", Size = V(2.05, 0.5, 2.05), CFrame = CF(c), Color = C3(190, 225, 245), Material = Enum.Material.Ice, Transparency = 0.08, Parent = iceF})
		end
	end
end
for i = 1, 8 do
	local a = math.pi * 2 * i / 8
	local c = HOLE + V(math.cos(a) * 2.6, 0.61, math.sin(a) * 2.6)
	local ch = part({Name = "Ice" .. i, Size = V(3.4, 0.5, 3.0), CFrame = CFrame.lookAt(c, HOLE + V(0, 0.61, 0)), Color = C3(195, 228, 248),
		Material = Enum.Material.Ice, Transparency = 0.05, Parent = iceF})
	ch:SetAttribute("Home", ch.CFrame)
end
local mid = part({Name = "Ice9", Size = V(2.6, 0.5, 2.6), CFrame = CF(HOLE + V(0, 0.61, 0)), Color = C3(195, 228, 248), Material = Enum.Material.Ice, Transparency = 0.05, Parent = iceF})
mid:SetAttribute("Home", mid.CFrame)
for i = 1, 40 do
	local a = rng:NextNumber(0, math.pi * 2)
	local r = rng:NextNumber(95, 145)
	store(11590212184, "SnowPine", winter, CF(W0 + V(math.cos(a) * r, 0, math.sin(a) * r)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), rng:NextNumber(0.7, 1.2))
end
local sign = Instance.new("Model")
sign.Name = "ThinIceSign"
sign.Parent = winter
part({Name = "Post", Size = V(0.4, 5, 0.4), CFrame = CF(W0 + V(8, 2.5, 8)), Color = C3(120, 80, 50), Material = Enum.Material.Wood, Parent = sign})
local board = part({Name = "Board", Size = V(4.4, 2.2, 0.25), CFrame = CF(W0 + V(8, 4.6, 8)) * CFrame.Angles(0, rad(-45), 0), Color = C3(250, 250, 250), Parent = sign})
text(board, Enum.NormalId.Front, "THIN ICE", C3(210, 30, 30))
text(board, Enum.NormalId.Back, "THIN ICE", C3(210, 30, 30))
part({Name = "SnowPile", Shape = Enum.PartType.Ball, Size = V(5, 4.4, 5), CFrame = CF(W0 + V(8, 2.6, 8)), Color = SNOW, Material = Enum.Material.Snow, Parent = sign})

---------------------------------------------------------------- VET ROOM (west woods): exam table, lamp, cabinet, poster
local vet = folder("VetRoom", SETS)
local VR = C + V(-470, 0, 150)
local function vbox(name, x1, y1, z1, x2, y2, z2, col, mat)
	return part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)), CFrame = CF(VR + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)),
		Color = col, Material = mat or Enum.Material.SmoothPlastic, Parent = vet})
end
vbox("Floor", -12, -0.5, -12, 12, 0.2, 12, C3(170, 200, 205), Enum.Material.Marble)
vbox("WallN", -12, 0, -12.5, 12, 13, -12, C3(225, 240, 235), Enum.Material.Plaster)
vbox("WallS", -12, 0, 12, 12, 13, 12.5, C3(225, 240, 235), Enum.Material.Plaster)
vbox("WallW", -12.5, 0, -12, -12, 13, 12, C3(225, 240, 235), Enum.Material.Plaster)
vbox("WallE", 12, 0, -12, 12.5, 13, 12, C3(225, 240, 235), Enum.Material.Plaster)
vbox("Ceiling", -12.5, 13, -12.5, 12.5, 13.5, 12.5, C3(245, 245, 245))
vbox("Stripe", -12, 3.6, -11.95, 12, 4.2, -11.9, C3(90, 180, 170))
vbox("ExamTop", -3, 3.0, -2, 3, 3.4, 2, C3(200, 205, 210), Enum.Material.Metal)
vbox("ExamBase", -0.6, 0.2, -0.6, 0.6, 3.0, 0.6, C3(150, 155, 160), Enum.Material.Metal)
vbox("Cabinet", 6, 0.2, -11.9, 11.5, 7, -9.5, C3(240, 240, 240))
vbox("CabTop", 6, 7, -11.9, 11.5, 7.3, -9.5, C3(90, 180, 170))
for i = 0, 2 do vbox("Jar", 6.6 + i * 1.6, 7.3, -11.2, 7.6 + i * 1.6, 8.6, -10.3, C3(200, 230, 250), Enum.Material.Glass).Transparency = 0.3 end
local poster = vbox("Poster", -8, 6, -11.95, -2, 10, -11.85, C3(255, 250, 235))
text(poster, Enum.NormalId.Back, "PAWS CLINIC", C3(40, 130, 120))
local lampHead = vbox("LampHead", -1.5, 9.4, -1.5, 1.5, 10, 1.5, C3(255, 245, 220), Enum.Material.Neon)
local ll = Instance.new("SpotLight")
ll.Face = Enum.NormalId.Bottom
ll.Color = C3(255, 220, 170)
ll.Brightness = 1.6
ll.Range = 18
ll.Angle = 70
ll.Shadows = true
ll.Parent = lampHead
vbox("LampArm", -0.15, 10, -0.15, 0.15, 13, 0.15, C3(120, 120, 125), Enum.Material.Metal)
vbox("Window", 12.0, 5, -5, 12.1, 10, 1, C3(120, 170, 220), Enum.Material.Glass).Transparency = 0.4
-- two chairs on the west side of the exam table (seat top 2.2, facing +X)
for i, z in {0, 3.4} do
	vbox("ChairSeat", -7.4, 1.8, z - 1.3, -4.8, 2.2, z + 1.3, C3(80, 150, 145), Enum.Material.Fabric)
	vbox("ChairBack", -7.8, 2.2, z - 1.3, -7.4, 5.4, z + 1.3, C3(80, 150, 145), Enum.Material.Fabric)
	vbox("ChairLegs", -7.2, 0.2, z - 1.1, -5.0, 1.8, z + 1.1, C3(150, 155, 160), Enum.Material.Metal).Transparency = 0.6
end

---------------------------------------------------------------- HOSPITAL NURSERY (west woods): incubator on a cart, monitor, chair, night window
local nur = folder("Nursery", SETS)
local NU = C + V(-470, 0, 270)
local function nbox(name, x1, y1, z1, x2, y2, z2, col, mat, parent)
	return part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)), CFrame = CF(NU + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)),
		Color = col, Material = mat or Enum.Material.SmoothPlastic, Parent = parent or nur})
end
nbox("Floor", -12, -0.5, -12, 12, 0.2, 12, C3(225, 215, 200), Enum.Material.Marble)
nbox("WallN", -12, 0, -12.5, 12, 13, -12, C3(250, 236, 220), Enum.Material.Plaster)
nbox("WallS", -12, 0, 12, 12, 13, 12.5, C3(250, 236, 220), Enum.Material.Plaster)
nbox("WallW", -12.5, 0, -12, -12, 13, 12, C3(250, 236, 220), Enum.Material.Plaster)
nbox("WallE", 12, 0, -12, 12.5, 13, 12, C3(250, 236, 220), Enum.Material.Plaster)
nbox("Ceiling", -12.5, 13, -12.5, 12.5, 13.5, 12.5, C3(250, 248, 245))
nbox("Border", -12, 7.5, -11.95, 12, 8.1, -11.9, C3(150, 200, 235))
for i = 0, 6 do -- little star stickers on the border
	local st = nbox("StarSticker", -10 + i * 3.3, 7.55, -11.92, -9.3 + i * 3.3, 8.05, -11.88, C3(255, 210, 80), Enum.Material.Neon)
	st.Transparency = 0.2
end
nbox("WindowFrame", 4, 4.5, -12.0, 10, 10.5, -11.8, C3(240, 240, 240))
local nwin = nbox("Window", 4.4, 4.9, -11.95, 9.6, 10.1, -11.85, C3(30, 40, 80), Enum.Material.Neon)
nwin.Transparency = 0.1
nbox("Moon", 8.2, 9.0, -11.84, 9.0, 9.8, -11.8, C3(250, 245, 220), Enum.Material.Neon)
-- the incubator (cart + clear hood) at the room centre; the Director lays the baby inside (prop "Baby")
nbox("CartTop", -2.4, 3.0, -1.6, 2.4, 3.3, 1.6, C3(235, 235, 240), Enum.Material.SmoothPlastic)
nbox("CartLeg", -0.4, 0.2, -0.4, 0.4, 3.0, 0.4, C3(170, 175, 185), Enum.Material.Metal)
nbox("CartBase", -1.8, 0.2, -1.2, 1.8, 0.5, 1.2, C3(170, 175, 185), Enum.Material.Metal)
nbox("Mattress", -2.0, 3.3, -1.3, 2.0, 3.6, 1.3, C3(250, 250, 255), Enum.Material.Fabric)
local hood = nbox("Hood", -2.3, 3.3, -1.5, 2.3, 5.6, 1.5, C3(220, 240, 255), Enum.Material.Glass)
hood.Transparency = 0.75
local blank = nbox("Blanket", -1.0, 3.6, -0.9, 1.4, 3.75, 0.9, C3(255, 220, 230), Enum.Material.Fabric)
-- heart monitor on a pole, a soft night lamp, a chair for Grandma
nbox("MonPole", 3.4, 0.2, -0.2, 3.6, 6.5, 0.0, C3(170, 175, 185), Enum.Material.Metal)
local mon = nbox("Monitor", 2.6, 6.5, -0.5, 4.4, 7.9, 0.3, C3(40, 40, 45))
local scr = nbox("Screen", 2.75, 6.65, -0.52, 4.25, 7.75, -0.5, C3(10, 30, 20), Enum.Material.Neon)
local beat = nbox("Beat", 2.85, 7.15, -0.53, 4.15, 7.22, -0.52, C3(80, 255, 140), Enum.Material.Neon)
local lamp = nbox("NightLamp", -9, 0.2, -10, -8, 4.5, -9, C3(255, 230, 190), Enum.Material.Neon)
local nl = Instance.new("PointLight")
nl.Color = C3(255, 205, 150)
nl.Brightness = 1.2
nl.Range = 22
nl.Shadows = true
nl.Parent = lamp
do -- wall clock on the north wall, hands at 3:00 (centre NU + (-4, 10, -11.8))
	local cc = NU + V(-4, 10, -11.8)
	local face = CF(cc) * CFrame.Angles(0, rad(90), 0)
	part({Name = "ClockRim", Shape = Enum.PartType.Cylinder, Size = V(0.25, 2.9, 2.9), CFrame = face, Color = C3(60, 60, 70), Material = Enum.Material.Metal, Parent = nur})
	part({Name = "ClockFace", Shape = Enum.PartType.Cylinder, Size = V(0.3, 2.6, 2.6), CFrame = face * CF(0.02, 0, 0), Color = C3(252, 250, 240), Parent = nur})
	for i = 0, 11 do
		local a = math.pi * 2 * i / 12
		part({Name = "Tick", Size = V(i % 3 == 0 and 0.16 or 0.09, i % 3 == 0 and 0.36 or 0.22, 0.05), CFrame = CF(cc + V(math.sin(a) * 1.05, math.cos(a) * 1.05, 0.2)) * CFrame.Angles(0, 0, -a),
			Color = C3(40, 40, 50), Parent = nur})
	end
	part({Name = "HourHand", Size = V(0.75, 0.13, 0.05), CFrame = CF(cc + V(0.36, 0, 0.24)), Color = C3(30, 30, 35), Parent = nur})
	part({Name = "MinuteHand", Size = V(0.09, 1.0, 0.05), CFrame = CF(cc + V(0, 0.48, 0.26)), Color = C3(30, 30, 35), Parent = nur})
	part({Name = "ClockPin", Shape = Enum.PartType.Ball, Size = V(0.18, 0.18, 0.18), CFrame = CF(cc + V(0, 0, 0.28)), Color = C3(200, 60, 60), Parent = nur})
end
for i = 1, 9 do -- stars in the night window
	local st = nbox("WinStar", 4.8 + (i * 1.37) % 4.4, 5.5 + (i * 0.71) % 4.0, -11.84, 4.95 + (i * 1.37) % 4.4, 5.65 + (i * 0.71) % 4.0, -11.82, C3(255, 255, 230), Enum.Material.Neon)
end
nbox("ChairSeat", -6.5, 2.0, 2.0, -3.5, 2.4, 5.0, C3(120, 140, 170), Enum.Material.Fabric)
nbox("ChairBack", -6.5, 2.4, 4.6, -3.5, 5.5, 5.0, C3(120, 140, 170), Enum.Material.Fabric)
for _, o in {V(-6.3, 1, 2.2), V(-3.7, 1, 2.2), V(-6.3, 1, 4.8), V(-3.7, 1, 4.8)} do nbox("ChairLeg", o.X - 0.15, 0.2, o.Z - 0.15, o.X + 0.15, 2.0, o.Z + 0.15, C3(90, 90, 95), Enum.Material.Metal) end

---------------------------------------------------------------- SCHOOL HALLWAY (west woods): lockers both sides, ceiling lights, trophy case
local hall = folder("Hallway", SETS)
local HA = C + V(-470, 0, 390)
local function hbox(name, x1, y1, z1, x2, y2, z2, col, mat)
	return part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)), CFrame = CF(HA + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)),
		Color = col, Material = mat or Enum.Material.SmoothPlastic, Parent = hall})
end
hbox("Floor", -40, -0.5, -8, 40, 0.2, 8, C3(200, 205, 210), Enum.Material.Marble)
for x = -40, 36, 8 do hbox("FloorStripe", x, 0.2, -8, x + 4, 0.22, 8, C3(170, 190, 215), Enum.Material.SmoothPlastic) end
hbox("WallN", -40, 0, -8.5, 40, 14, -8, C3(240, 230, 200), Enum.Material.Plaster)
hbox("WallS", -40, 0, 8, 40, 14, 8.5, C3(240, 230, 200), Enum.Material.Plaster)
hbox("WallW", -40.5, 0, -8, -40, 14, 8, C3(240, 230, 200), Enum.Material.Plaster)
hbox("WallE", 40, 0, -8, 40.5, 14, 8, C3(240, 230, 200), Enum.Material.Plaster)
hbox("Ceiling", -40.5, 14, -8.5, 40.5, 14.5, 8.5, C3(245, 245, 245))
local LOCK = {C3(60, 120, 220), C3(220, 70, 70)}
for _, side in {-1, 1} do
	for i = 0, 22 do
		local x = -36 + i * 2.6
		if not (x > -6 and x < 6) then
			local z1 = side < 0 and -8 or 6.6
			local lk = hbox("Locker", x, 0.2, z1, x + 2.4, 8, z1 + 1.4, LOCK[(i % 2) + 1], Enum.Material.Metal)
			for v = 0, 2 do hbox("Vent", x + 0.5, 6.4 + v * 0.35, side < 0 and -6.58 or 6.58, x + 1.9, 6.5 + v * 0.35, side < 0 and -6.55 or 6.55, C3(30, 30, 35)) end
			hbox("Handle", x + 1.8, 4.0, side < 0 and -6.58 or 6.55, x + 2.0, 4.8, side < 0 and -6.5 or 6.62, C3(200, 200, 205), Enum.Material.Metal)
		end
	end
end
for x = -32, 32, 16 do
	local l = hbox("CeilLight", x - 3, 13.7, -1, x + 3, 14, 1, C3(255, 252, 240), Enum.Material.Neon)
	local pl = Instance.new("PointLight")
	pl.Brightness = 0.8
	pl.Range = 20
	pl.Color = C3(255, 245, 225)
	pl.Parent = l
end
local banner = hbox("Banner", -5, 9, -7.95, 5, 11.5, -7.85, C3(40, 90, 190))
text(banner, Enum.NormalId.Back, "MAPLE ELEMENTARY", C3(255, 220, 60))
hbox("TrophyCase", -5, 0.2, -8, 5, 7, -6.6, C3(120, 80, 50), Enum.Material.Wood)
local glassC = hbox("CaseGlass", -4.7, 1, -6.62, 4.7, 6.7, -6.58, C3(210, 235, 255), Enum.Material.Glass)
glassC.Transparency = 0.6
for i = -2, 2 do hbox("Trophy", i * 1.7 - 0.3, 3, -7.6, i * 1.7 + 0.3, 4.3 + (i % 2) * 0.6, -7.2, C3(255, 200, 50), Enum.Material.Foil) end

---------------------------------------------------------------- BOY'S BEDROOM (west woods): blue + orange, bed on the north wall, posters, toys, window
-- open floor south of the bed for a dog bed (prop) at its foot; nothing tall between the bed and the dog bed
local boy = folder("BoyRoom", SETS)
local BR = C + V(-470, 0, 510)
local function bbox(name, x1, y1, z1, x2, y2, z2, col, mat)
	return part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)), CFrame = CF(BR + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)),
		Color = col, Material = mat or Enum.Material.SmoothPlastic, Parent = boy})
end
local BLUEW, ORANGE, NAVY = C3(120, 175, 230), C3(255, 150, 50), C3(40, 60, 120)
bbox("Floor", -12, -0.5, -12, 12, 0.4, 12, C3(190, 140, 90), Enum.Material.WoodPlanks)
bbox("WallN", -12, 0, -12.5, 12, 13, -12, BLUEW, Enum.Material.Plaster)
bbox("WallS", -12, 0, 12, 12, 13, 12.5, BLUEW, Enum.Material.Plaster)
bbox("WallW", -12.5, 0, -12, -12, 13, 12, ORANGE, Enum.Material.Plaster)
bbox("WallE", 12, 0, -12, 12.5, 13, 12, BLUEW, Enum.Material.Plaster)
bbox("Ceiling", -12.5, 13, -12.5, 12.5, 13.5, 12.5, C3(245, 245, 250))
bbox("Skirting", -12, 0.4, -11.95, 12, 1.0, -11.85, C3(250, 250, 250))
-- window on the west wall (sky/trees outside)
bbox("WinFrame", -12.0, 4.5, -3, -11.8, 10.5, 4, C3(250, 250, 250))
local win = bbox("Window", -11.95, 4.9, -2.6, -11.75, 10.1, 3.6, C3(170, 210, 240), Enum.Material.Glass)
win.Transparency = 0.55
bbox("WinBarV", -11.9, 4.9, 0.45, -11.7, 10.1, 0.55, C3(250, 250, 250))
bbox("WinBarH", -11.9, 7.45, -2.6, -11.7, 7.55, 3.6, C3(250, 250, 250))
-- the bed (head on the north wall)
bbox("BedFrame", -4, 0.4, -12, 1.4, 1.8, -4.4, NAVY, Enum.Material.Wood)
bbox("Headboard", -4, 0.4, -12, 1.4, 5.0, -11.4, NAVY, Enum.Material.Wood)
bbox("Mattress", -3.8, 1.8, -11.4, 1.2, 2.6, -4.6, C3(245, 245, 245), Enum.Material.Fabric)
bbox("Blanket", -3.9, 2.6, -8.2, 1.3, 2.85, -4.5, ORANGE, Enum.Material.Fabric)
bbox("BlanketStripe", -3.92, 2.62, -6.6, 1.32, 2.87, -6.0, NAVY, Enum.Material.Fabric)
bbox("Pillow", -3.2, 2.6, -11.2, 0.6, 3.3, -9.8, C3(255, 255, 255), Enum.Material.Fabric)
-- nightstand + lamp (warm light for night shots)
bbox("Nightstand", 2.0, 0.4, -12, 4.4, 3.2, -9.8, C3(230, 160, 80), Enum.Material.Wood)
local lamp = bbox("Lamp", 2.7, 3.2, -11.4, 3.7, 4.8, -10.4, C3(255, 230, 170), Enum.Material.Neon)
local ll = Instance.new("PointLight")
ll.Color = C3(255, 200, 140)
ll.Brightness = 0.7
ll.Range = 14
ll.Shadows = true
ll.Parent = lamp
-- posters (north wall, east of the bed) + a pennant
local function poster(x1, x2, y1, y2, col, label, tcol)
	local p = bbox("Poster", x1, y1, -11.95, x2, y2, -11.85, col)
	text(p, Enum.NormalId.Back, label, tcol)
end
poster(5, 9, 6, 10.5, C3(30, 40, 90), "SPACE", C3(255, 210, 60))
poster(-10.5, -6.5, 6.5, 9.5, C3(240, 70, 60), "DINO", C3(255, 255, 255))
-- toy shelf on the east wall + toys
bbox("Shelf", 11.0, 0.4, 2, 12, 6, 9, C3(250, 250, 250), Enum.Material.Wood)
for i, col in {C3(230, 60, 60), C3(60, 140, 230), C3(250, 200, 50), C3(80, 190, 90)} do
	bbox("ToyBlock", 11.1, 3.0, 2.4 + i * 1.3, 11.9, 3.8, 3.2 + i * 1.3, col)
end
part({Name = "Ball", Shape = Enum.PartType.Ball, Size = V(1.6, 1.6, 1.6), CFrame = CF(BR + V(8, 1.2, 8)), Color = C3(240, 80, 60), Parent = boy})
part({Name = "Rug", Shape = Enum.PartType.Cylinder, Size = V(0.1, 9, 9), CFrame = CF(BR + V(-1, 0.45, 3)) * CFrame.Angles(0, 0, rad(90)), Color = C3(90, 150, 220), Material = Enum.Material.Fabric, Parent = boy})
-- desk under the window side
bbox("Desk", -12, 0.4, 6, -8.5, 3.4, 11, C3(230, 160, 80), Enum.Material.Wood)
bbox("Globe", -11, 3.4, 9, -10, 4.4, 10, C3(70, 150, 220), Enum.Material.SmoothPlastic)

---------------------------------------------------------------- movable props (parked; the Director places them)
local props = folder("Props", SETS)
local function prop(name)
	local m = Instance.new("Model")
	m.Name = name
	m.WorldPivot = PARK
	m.Parent = props
	return m
end
local function pr(m, name, shape, size, cf, col, mat, extra)
	local t = {Name = name, Size = size, CFrame = PARK * cf, Color = col, Material = mat or Enum.Material.SmoothPlastic, CanCollide = false, Parent = m}
	if shape == "ball" then t.Shape = Enum.PartType.Ball elseif shape == "cyl" then t.Shape = Enum.PartType.Cylinder elseif shape == "wedge" then t.Class = "WedgePart" end
	for k2, v2 in (extra or {}) do t[k2] = v2 end
	return part(t)
end
local A = CFrame.Angles
do -- food bowl (Biscuit's): red dish + kibble + name
	local m = prop("FoodBowl")
	pr(m, "Dish", "cyl", V(0.7, 2.6, 2.6), CF(0, 0.35, 0) * A(0, 0, rad(90)), C3(210, 40, 40))
	pr(m, "Kibble", "cyl", V(0.1, 2.1, 2.1), CF(0, 0.72, 0) * A(0, 0, rad(90)), C3(150, 95, 50), Enum.Material.Pebble)
	local t = pr(m, "Label", nil, V(1.4, 0.4, 0.05), CF(0, 0.35, -1.31), C3(210, 40, 40))
	text(t, Enum.NormalId.Front, "BISCUIT", C3(255, 255, 255))
end
do -- upright vacuum
	local m = prop("Vacuum")
	pr(m, "Head", nil, V(2.6, 0.6, 1.4), CF(0, 0.3, 0), C3(60, 60, 66))
	pr(m, "Body", nil, V(1.5, 2.6, 1.0), CF(0, 2.0, 0.35), C3(220, 40, 60))
	pr(m, "Bag", "cyl", V(2.6, 1.1, 1.1), CF(0, 2.1, 0.75) * A(0, 0, rad(90)), C3(240, 240, 240))
	pr(m, "Handle", nil, V(0.22, 2.6, 0.22), CF(0, 4.6, 0.5), C3(60, 60, 66))
	pr(m, "Grip", nil, V(1.0, 0.25, 0.25), CF(0, 5.9, 0.5), C3(30, 30, 30))
	pr(m, "Light", "cyl", V(0.1, 0.5, 0.5), CF(0, 0.35, -0.72) * A(0, rad(90), 0), C3(255, 250, 200), Enum.Material.Neon)
end
do -- magnifying glass (the vet's)
	local m = prop("Magnifier")
	pr(m, "Rim", "cyl", V(0.18, 1.7, 1.7), A(0, rad(90), 0), C3(40, 40, 45), Enum.Material.Metal)
	pr(m, "Lens", "cyl", V(0.2, 1.45, 1.45), A(0, rad(90), 0), C3(200, 230, 255), Enum.Material.Glass, {Transparency = 0.55})
	pr(m, "Handle", nil, V(0.25, 1.6, 0.25), CF(0, -1.6, 0), C3(110, 70, 40), Enum.Material.Wood)
end
do -- goldfish bowl on a little table
	local m = prop("FishBowl")
	pr(m, "Glass", "ball", V(3.2, 3.2, 3.2), CF(0, 4.6, 0), C3(210, 240, 255), Enum.Material.Glass, {Transparency = 0.65})
	pr(m, "Water", "ball", V(2.8, 2.4, 2.8), CF(0, 4.3, 0), C3(110, 190, 240), Enum.Material.Glass, {Transparency = 0.6})
	pr(m, "Gravel", "cyl", V(0.3, 2.0, 2.0), CF(0, 3.3, 0) * A(0, 0, rad(90)), C3(120, 200, 140), Enum.Material.Pebble)
	pr(m, "TableTop", nil, V(3.6, 0.3, 3.6), CF(0, 3.0, 0), C3(160, 110, 70), Enum.Material.Wood)
	for _, o in {V(-1.5, 1.4, -1.5), V(1.5, 1.4, -1.5), V(-1.5, 1.4, 1.5), V(1.5, 1.4, 1.5)} do pr(m, "Leg", nil, V(0.3, 2.9, 0.3), CF(o), C3(140, 95, 60), Enum.Material.Wood) end
end
do -- parrot perch
	local m = prop("Perch")
	pr(m, "Base", "cyl", V(0.3, 2.2, 2.2), CF(0, 0.15, 0) * A(0, 0, rad(90)), C3(90, 60, 40), Enum.Material.Wood)
	pr(m, "Pole", nil, V(0.3, 4.6, 0.3), CF(0, 2.4, 0), C3(110, 75, 45), Enum.Material.Wood)
	pr(m, "Bar", "cyl", V(2.6, 0.3, 0.3), CF(0, 4.6, 0), C3(110, 75, 45), Enum.Material.Wood)
end
do -- Biscuit's dog bed
	local m = prop("DogBed")
	pr(m, "Rim", "cyl", V(1.0, 7.4, 7.4), CF(0, 0.5, 0) * A(0, 0, rad(90)), C3(170, 50, 60), Enum.Material.Fabric)
	pr(m, "Cushion", "cyl", V(0.8, 6.4, 6.4), CF(0, 0.55, 0) * A(0, 0, rad(90)), C3(235, 215, 190), Enum.Material.Fabric)
end
do -- a blanket (vet table)
	local m = prop("Blanket")
	pr(m, "Sheet", nil, V(4.2, 0.25, 4.6), CF(), C3(90, 130, 200), Enum.Material.Fabric)
end
do -- sled
	local m = prop("Sled")
	pr(m, "Deck", nil, V(2.2, 0.25, 4.4), CF(0, 0.6, 0), C3(210, 40, 40), Enum.Material.Wood)
	for _, x in {-1.0, 1.0} do pr(m, "Runner", nil, V(0.15, 0.4, 4.6), CF(x, 0.25, 0), C3(60, 60, 66), Enum.Material.Metal) end
	pr(m, "Curl", "cyl", V(2.2, 0.6, 0.6), CF(0, 0.75, -2.3), C3(210, 40, 40), Enum.Material.Wood)
end
do -- a swaddled newborn (sleeping face) for the nursery incubator
	local m = prop("Baby")
	pr(m, "Swaddle", "ball", V(0.9, 0.8, 1.6), CF(0, 0.4, 0.3), C3(170, 210, 250), Enum.Material.Fabric)
	local hd = pr(m, "Head", "ball", V(0.75, 0.75, 0.75), CF(0, 0.45, -0.75), C3(255, 210, 175))
	local d = Instance.new("Decal")
	d.Face = Enum.NormalId.Top
	d.Texture = "rbxassetid://70540320410457"
	d.Parent = hd
	pr(m, "Cap", "ball", V(0.6, 0.4, 0.6), CF(0, 0.75, -0.85), C3(255, 200, 220), Enum.Material.Fabric)
end
do -- rocking chair (Creator Store model) becomes a prop
	local src = places:FindFirstChild("RockingChairSrc")
	if src then
		src.Name = "RockingChair"
		src.Parent = props
	end
end

---------------------------------------------------------------- PETS (block builds with limbs)
local pets = folder("Pets", SETS)
local INK = C3(18, 16, 16)
local WHITE = C3(255, 255, 255)
-- creature builder: parts given in ROOT space (root = between the feet, front = -Z); each part belongs to a limb with a
-- pivot ("Pivot_<limb>" attribute, root space) and optional parent limb ("Parent_<limb>").
local function creature(name)
	local m = Instance.new("Model")
	m.Name = name
	local root = part({Name = "Root", Size = V(1, 1, 1), CFrame = PARK, Transparency = 1, CanCollide = false, Parent = m})
	m.PrimaryPart = root
	m.Parent = pets
	local api = {model = m}
	function api.limb(limb, pivot, parentLimb)
		m:SetAttribute("Pivot_" .. limb, pivot)
		if parentLimb then m:SetAttribute("Parent_" .. limb, parentLimb) end
	end
	function api.p(limb, shape, size, cf, color, opts)
		opts = opts or {}
		local t = {Name = opts.name or limb, Size = size, CFrame = PARK * cf, Color = color, CanCollide = false,
			Material = opts.mat or Enum.Material.SmoothPlastic, Parent = m}
		if shape == "wedge" then t.Class = "WedgePart" elseif shape == "ball" then t.Shape = Enum.PartType.Ball elseif shape == "cyl" then t.Shape = Enum.PartType.Cylinder end
		if opts.transp then t.Transparency = opts.transp end
		local p = part(t)
		if shape == "sphere" then
			local sm = Instance.new("SpecialMesh")
			sm.MeshType = Enum.MeshType.Sphere
			sm.Parent = p
		end
		p:SetAttribute("Limb", limb)
		return p
	end
	return api
end

-- DOGS: Biscuit (big old golden retriever, red collar) + recoloured neighbours' dogs + the puppy. Toggle parts: Lid* (eyes
-- closed), Tongue (panting), Brow* (tilted for sad/worried) are named so the Director can find them.
local function dog(name, col)
	local d = creature(name)
	d.limb("Body", CF(0, 3.0, 0))
	d.p("Body", "block", V(2.8, 2.6, 5.4), CF(0, 3.3, 0.2), col.fur)
	d.p("Body", "block", V(2.3, 2.0, 0.5), CF(0, 3.0, -2.5), col.light, {name = "Chest"})
	d.p("Body", "block", V(2.0, 0.8, 4.0), CF(0, 1.95, 0.3), col.light, {name = "Belly"})
	d.p("Body", "block", V(1.9, 1.9, 1.7), CF(0, 4.35, -2.5), col.fur, {name = "Neck"})
	if col.collar then
		d.p("Body", "block", V(2.06, 0.5, 1.8), CF(0, 3.8, -2.5), col.collar, {name = "Collar"})
		d.p("Body", "cyl", V(0.14, 0.55, 0.55), CF(0, 3.32, -3.45) * A(0, rad(90), 0), C3(255, 200, 50), {name = "Tag", mat = Enum.Material.Metal})
	end
	d.limb("Head", CF(0, 4.8, -2.9), "Body")
	d.p("Head", "block", V(2.6, 2.4, 2.4), CF(0, 5.75, -3.5), col.fur)
	d.p("Head", "block", V(1.5, 1.0, 0.95), CF(0, 5.0, -5.1), col.muzzle, {name = "Snout"})
	d.p("Head", "block", V(0.62, 0.42, 0.3), CF(0, 5.36, -5.64), INK, {name = "Nose"})
	d.p("Head", "block", V(0.16, 0.1, 0.12), CF(-0.14, 5.48, -5.8), C3(120, 120, 130), {name = "NoseShine"})
	d.p("Head", "block", V(0.5, 0.1, 0.6), CF(0, 4.47, -5.2), C3(235, 95, 115), {name = "Tongue"})
	d.p("Head", "block", V(0.7, 0.08, 0.06), CF(0, 4.72, -5.58), C3(90, 60, 50), {name = "Mouth"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.8, 0.8, 0.8), CF(s * 0.66, 6.0, -4.58), INK, {name = "Eye" .. tag})
		d.p("Head", "ball", V(0.27, 0.27, 0.27), CF(s * 0.66 + 0.13, 6.17, -4.95), WHITE, {name = "Shine" .. tag})
		d.p("Head", "ball", V(0.13, 0.13, 0.13), CF(s * 0.66 - 0.14, 5.86, -4.97), WHITE, {name = "Shine2" .. tag})
		d.p("Head", "block", V(0.92, 0.5, 0.2), CF(s * 0.66, 6.02, -4.86), col.fur, {name = "Lid" .. tag, transp = 1})
		d.p("Head", "block", V(0.5, 0.11, 0.08), CF(s * 0.66, 6.66, -4.72), col.light, {name = "Brow" .. tag})
		local ear = s < 0 and "EarL" or "EarR"
		d.limb(ear, CF(s * 1.3, 6.75, -3.4), "Head")
		d.p(ear, "block", V(0.42, 2.1, 1.35), CF(s * 1.5, 5.75, -3.4), col.ear)
	end
	if col.grey then d.p("Head", "block", V(1.56, 0.22, 0.85), CF(0, 5.55, -5.08), col.grey, {name = "GreyMuzzle"}) end
	d.limb("Tail", CF(0, 4.1, 2.8), "Body")
	d.p("Tail", "block", V(0.55, 0.55, 2.3), CF(0, 4.7, 3.75) * A(rad(32), 0, 0), col.ear)
	for _, l in {{"LegFL", -1, -1.75}, {"LegFR", 1, -1.75}, {"LegBL", -1, 2.05}, {"LegBR", 1, 2.05}} do
		d.limb(l[1], CF(l[2] * 0.85, 2.25, l[3]), "Body")
		d.p(l[1], "block", V(0.92, 2.25, 0.92), CF(l[2] * 0.85, 1.12, l[3]), col.fur)
		d.p(l[1], "block", V(1.0, 0.36, 1.22), CF(l[2] * 0.85, 0.18, l[3] - 0.12), col.light, {name = "Paw"})
	end
	return d
end
dog("Biscuit", {fur = C3(222, 168, 82), light = C3(246, 222, 170), ear = C3(196, 132, 58), muzzle = C3(240, 222, 188), grey = C3(236, 232, 222), collar = C3(205, 30, 40)})
dog("Puppy", {fur = C3(232, 182, 96), light = C3(250, 230, 182), ear = C3(204, 140, 64), muzzle = C3(248, 232, 196), collar = C3(205, 30, 40)})
dog("DogSpot", {fur = C3(245, 245, 245), light = C3(255, 255, 255), ear = C3(40, 40, 44), muzzle = C3(255, 255, 255), collar = C3(40, 120, 230)})
dog("DogBrown", {fur = C3(120, 75, 45), light = C3(190, 140, 95), ear = C3(85, 52, 30), muzzle = C3(190, 140, 95), collar = C3(60, 180, 80)})
-- PUP: Biscuit as a puppy, built as a puppy (not a shrunk adult): round body, big head, huge eyes, stubby legs, floppy ears
do
	local FUR, LIGHT, EAR = C3(238, 190, 105), C3(252, 234, 192), C3(212, 150, 70)
	local d = creature("Pup")
	d.limb("Body", CF(0, 1.0, 0))
	d.p("Body", "block", V(1.5, 1.25, 2.1), CF(0, 1.12, 0.15), FUR)
	d.p("Body", "block", V(1.2, 0.5, 1.6), CF(0, 0.6, 0.15), LIGHT, {name = "Belly"})
	d.p("Body", "block", V(1.56, 0.22, 0.9), CF(0, 1.7, -0.72), C3(205, 30, 40), {name = "Collar"})
	d.limb("Head", CF(0, 1.55, -0.85), "Body")
	d.p("Head", "block", V(1.75, 1.55, 1.5), CF(0, 2.3, -1.1), FUR)
	d.p("Head", "block", V(0.85, 0.55, 0.45), CF(0, 1.88, -1.98), LIGHT, {name = "Snout"})
	d.p("Head", "block", V(0.36, 0.24, 0.16), CF(0, 2.05, -2.24), INK, {name = "Nose"})
	d.p("Head", "block", V(0.32, 0.07, 0.4), CF(0, 1.62, -2.0), C3(235, 95, 115), {name = "Tongue"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.58, 0.58, 0.58), CF(s * 0.43, 2.42, -1.78), INK, {name = "Eye" .. tag})
		d.p("Head", "ball", V(0.2, 0.2, 0.2), CF(s * 0.43 + 0.1, 2.55, -2.04), WHITE, {name = "Shine" .. tag})
		d.p("Head", "ball", V(0.09, 0.09, 0.09), CF(s * 0.43 - 0.1, 2.32, -2.06), WHITE, {name = "Shine2" .. tag})
		d.p("Head", "block", V(0.66, 0.36, 0.12), CF(s * 0.43, 2.44, -1.98), FUR, {name = "Lid" .. tag, transp = 1})
		d.p("Head", "block", V(0.34, 0.07, 0.05), CF(s * 0.43, 2.86, -1.86), LIGHT, {name = "Brow" .. tag})
		local ear = s < 0 and "EarL" or "EarR"
		d.limb(ear, CF(s * 0.86, 2.95, -1.15), "Head")
		d.p(ear, "block", V(0.28, 1.05, 0.75), CF(s * 1.0, 2.45, -1.1), EAR)
	end
	d.limb("Tail", CF(0, 1.5, 1.15), "Body")
	d.p("Tail", "block", V(0.3, 0.3, 0.75), CF(0, 1.72, 1.45) * A(rad(35), 0, 0), EAR)
	for _, l in {{"LegFL", -1, -0.55}, {"LegFR", 1, -0.55}, {"LegBL", -1, 0.75}, {"LegBR", 1, 0.75}} do
		d.limb(l[1], CF(l[2] * 0.45, 0.62, l[3]), "Body")
		d.p(l[1], "block", V(0.48, 0.62, 0.48), CF(l[2] * 0.45, 0.31, l[3]), FUR)
		d.p(l[1], "block", V(0.54, 0.2, 0.62), CF(l[2] * 0.45, 0.1, l[3] - 0.06), LIGHT, {name = "Paw"})
	end
end

-- CAT (Mrs. Boone's orange tabby)
do
	local O, OL, OD = C3(245, 150, 60), C3(255, 215, 160), C3(200, 105, 35)
	local d = creature("Cat")
	d.limb("Body", CF(0, 1.4, 0))
	d.p("Body", "block", V(1.5, 1.4, 2.8), CF(0, 1.55, 0.1), O)
	for z = -0.6, 0.9, 0.75 do d.p("Body", "block", V(1.52, 0.25, 0.3), CF(0, 2.12, z), OD, {name = "Stripe"}) end
	d.p("Body", "block", V(1.2, 0.5, 2.2), CF(0, 0.95, 0.1), OL, {name = "Belly"})
	d.limb("Head", CF(0, 2.0, -1.3), "Body")
	d.p("Head", "block", V(1.6, 1.35, 1.35), CF(0, 2.55, -1.75), O)
	d.p("Head", "block", V(0.9, 0.55, 0.3), CF(0, 2.2, -2.5), OL, {name = "Muzzle"})
	d.p("Head", "block", V(0.25, 0.18, 0.12), CF(0, 2.45, -2.66), C3(240, 120, 140), {name = "Nose"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "wedge", V(0.15, 0.6, 0.5), CF(s * 0.5, 3.5, -1.75), O, {name = "Ear"})
		d.p("Head", "ball", V(0.42, 0.42, 0.42), CF(s * 0.38, 2.75, -2.38), C3(140, 210, 80), {name = "Eye" .. tag})
		d.p("Head", "block", V(0.08, 0.32, 0.06), CF(s * 0.38, 2.75, -2.6), INK, {name = "Slit" .. tag})
		d.p("Head", "block", V(0.8, 0.04, 0.04), CF(s * 0.75, 2.3, -2.5) * A(0, 0, rad(s * 8)), WHITE, {name = "Whisker"})
	end
	d.limb("Tail", CF(0, 1.9, 1.4), "Body")
	d.p("Tail", "block", V(0.3, 0.3, 2.3), CF(0, 2.8, 1.9) * A(rad(-55), 0, 0), O)
	for _, l in {{"LegFL", -1, -0.9}, {"LegFR", 1, -0.9}, {"LegBL", -1, 1.0}, {"LegBR", 1, 1.0}} do
		d.limb(l[1], CF(l[2] * 0.45, 1.0, l[3]), "Body")
		d.p(l[1], "block", V(0.42, 1.0, 0.42), CF(l[2] * 0.45, 0.5, l[3]), O)
	end
end
-- HAMSTER (Max's)
do
	local T, TL = C3(230, 175, 110), C3(252, 236, 210)
	local d = creature("Hamster")
	d.limb("Body", CF(0, 0.6, 0))
	d.p("Body", "sphere", V(1.3, 1.1, 1.5), CF(0, 0.62, 0), T)
	d.p("Body", "sphere", V(1.0, 0.8, 1.2), CF(0, 0.5, -0.12), TL, {name = "Belly"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Body", "ball", V(0.36, 0.36, 0.36), CF(s * 0.38, 1.18, -0.3), C3(250, 170, 180), {name = "Ear"})
		d.p("Body", "ball", V(0.2, 0.2, 0.2), CF(s * 0.27, 0.86, -0.66), INK, {name = "Eye" .. tag})
		d.p("Body", "ball", V(0.3, 0.3, 0.3), CF(s * 0.38, 0.6, -0.6), C3(255, 200, 200), {name = "Cheek"})
		d.p("Body", "block", V(0.2, 0.12, 0.25), CF(s * 0.3, 0.06, -0.4), C3(250, 170, 180), {name = "Foot"})
	end
	d.p("Body", "ball", V(0.14, 0.14, 0.14), CF(0, 0.7, -0.78), C3(240, 120, 140), {name = "Nose"})
end
-- PARROT (the Parkers'): about 3 studs on its feet
do
	local G, R, B, Y = C3(60, 190, 80), C3(225, 45, 45), C3(50, 120, 230), C3(255, 205, 40)
	local d = creature("Parrot")
	d.limb("Body", CF(0, 0.5, 0))
	d.p("Body", "sphere", V(1.0, 1.6, 1.0), CF(0, 1.3, 0.05) * A(rad(10), 0, 0), G)
	d.p("Body", "block", V(0.35, 1.5, 0.15), CF(0, 0.5, 0.6) * A(rad(20), 0, 0), R, {name = "TailFeathers"})
	for _, s in {-1, 1} do
		local w = s < 0 and "WingL" or "WingR"
		d.limb(w, CF(s * 0.45, 1.8, 0), "Body")
		d.p(w, "block", V(0.18, 1.2, 0.8), CF(s * 0.55, 1.25, 0.15), B)
		d.p("Body", "block", V(0.12, 0.3, 0.3), CF(s * 0.2, 0.3, -0.05), C3(90, 90, 95), {name = "Foot"})
	end
	d.limb("Head", CF(0, 2.0, -0.05), "Body")
	d.p("Head", "ball", V(0.95, 0.95, 0.95), CF(0, 2.4, -0.15), G)
	d.p("Head", "wedge", V(0.3, 0.55, 0.45), CF(0, 2.25, -0.75) * A(rad(180), 0, 0), Y, {name = "Beak"})
	d.limb("Jaw", CF(0, 2.15, -0.5), "Head")
	d.p("Jaw", "block", V(0.26, 0.12, 0.3), CF(0, 2.05, -0.65), C3(60, 60, 60), {name = "LowerBeak"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.32, 0.32, 0.32), CF(s * 0.32, 2.55, -0.45), WHITE, {name = "EyeWhite"})
		d.p("Head", "ball", V(0.16, 0.16, 0.16), CF(s * 0.35, 2.56, -0.58), INK, {name = "Eye" .. tag})
	end
	d.p("Head", "block", V(0.6, 0.35, 0.5), CF(0, 2.9, 0.05), R, {name = "Crest"})
end
-- FISH builder (goldfish at scale s): root at its body centre (or on top of legs), front = -Z
local function fish(name, s, body, fin, into, lift)
	local d = into or creature(name)
	local o = CF(0, lift or 0, 0)
	d.limb("Body", o)
	d.p("Body", "sphere", V(0.55, 0.85, 1.1) * s, o, body)
	d.p("Body", "wedge", V(0.12, 0.5, 0.45) * s, o * CF(0, 0.5 * s, 0.05 * s), fin, {name = "TopFin"})
	d.limb("Tail", o * CF(0, 0, 0.5 * s), "Body")
	d.p("Tail", "wedge", V(0.1, 0.8, 0.6) * s, o * CF(0, 0.15 * s, 0.75 * s) * A(rad(20), 0, 0), fin, {name = "TailTop"})
	d.p("Tail", "wedge", V(0.1, 0.8, 0.6) * s, o * CF(0, -0.15 * s, 0.75 * s) * A(rad(160), 0, 0), fin, {name = "TailBot"})
	for _, k in {-1, 1} do
		local tag = k < 0 and "L" or "R"
		d.p("Body", "ball", V(0.26, 0.26, 0.26) * s, o * CF(k * 0.2 * s, 0.12 * s, -0.36 * s), WHITE, {name = "EyeWhite"})
		d.p("Body", "ball", V(0.13, 0.13, 0.13) * s, o * CF(k * 0.25 * s, 0.12 * s, -0.42 * s), INK, {name = "Eye" .. tag})
	end
	d.p("Body", "ball", V(0.16, 0.12, 0.1) * s, o * CF(0, -0.12 * s, -0.55 * s), C3(180, 40, 60), {name = "Mouth"})
	return d
end
fish("Goldfish", 1, C3(255, 130, 30), C3(255, 190, 60))
fish("BigFish", 13, C3(255, 120, 35), C3(255, 185, 60))
-- the goldfish that wished for legs: a man-sized goldfish on two long skinny legs in sneakers
do
	local d = creature("FishLegs")
	fish("FishLegs", 3, C3(255, 130, 30), C3(255, 190, 60), d, 4.6)
	for _, k in {-1, 1} do
		local l = k < 0 and "LegL" or "LegR"
		d.limb(l, CF(k * 0.45, 3.5, 0))
		d.p(l, "block", V(0.55, 3.3, 0.55), CF(k * 0.45, 1.85, 0), C3(60, 100, 170), {name = "Jeans"})
		d.p(l, "block", V(0.75, 0.45, 1.25), CF(k * 0.45, 0.22, -0.22), WHITE, {name = "Shoe"})
		d.p(l, "block", V(0.77, 0.12, 1.27), CF(k * 0.45, 0.05, -0.22), C3(220, 40, 40), {name = "Sole"})
	end
end

---------------------------------------------------------------- done
SETS.Parent = film
local n = 0
for _, d in SETS:GetDescendants() do if d:IsA("BasePart") then n += 1 end end
table.insert(LOG, "KitSets parts: " .. n)
for _, d in SETS:GetDescendants() do
	if d:IsA("LuaSourceContainer") then error("a script is inside KitSets: " .. d:GetFullName()) end
end
table.insert(LOG, "script check: 0 scripts in KitSets")
return table.concat(LOG, "\n")
