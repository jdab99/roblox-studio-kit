-- Reel 42 "Sir Barks-A-Lot" sets. Built in Edit mode ONLY into workspace.Film.ReelSets (safe to re-run: destroys it first).
-- Inside the kit world (TOWN = 0,0,-3000):
--   HOME interior  H = TOWN + (250, 0, -120): floor top 0.2, room x -14..14, z -12..12, walls 12 tall + ceiling.
--       front door in the SOUTH wall (x 7..11, opens out), doormat x 7..11 z 9.2..11.6, the crayon KEVIN label on the
--       south wall west of the door, couch on the west wall (seat top 2.2), dining table (top 3.2) at (5, -5),
--       window in the north wall (x -7..1, y 4..9; panel recoloured per shot), ceiling light (PointLight "RoomLight").
--       Outside the door: a snow yard z 12..60 with small footprints leading away (the night she went out).
--   ZOO  Z = TOWN + (-260, 0, -125): three fence rings round the hamster pen (inner half-size 14, then 18, then 22),
--       front faces +Z (toward the street); GODZILLA sign on the outer front fence.
--   Street lamps along the north sidewalk x 0..240 (z -17), lights off by default (ReelSets.Lamps).
--   Props (ReelSets.Props, Home attribute, parked; the Director pivots them): SnowTown (snow blanket over the street),
--       Sign1 / Sign2 / Sign3 (QUIET PLEASE / QUIET PLEASE big / why), Torch1..6 (flashlights with a light + beam),
--       Log, Gary (the stick), Cake, Banner, BigTicket, Table, DH1..DH4 (doghouses), Cape, Door outside fixtures.
--   Pets (ReelSets.Pets, kit pet format, root between the feet, front = -Z): Barks (scruffy brown dog, Jaw limb opens to
--       bark), BarksPup (him as a puppy), Second (Mr. Greer's puppy), Fluff (the cat that is 90% fluff).
local film = workspace:FindFirstChild("Film")
local old = film:FindFirstChild("ReelSets")
if old then old:Destroy() end
local SETS = Instance.new("Folder")
SETS.Name = "ReelSets"

local V, CF, rad = Vector3.new, CFrame.new, math.rad
local A = CFrame.Angles
local C3 = Color3.fromRGB
local M = Enum.Material
local TOWN = V(0, 0, -3000)
local PARK = CF(TOWN + V(0, -430, 0))
local n = 0
local LOG = {}
local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end
local function part(p)
	local o = Instance.new(p.Class or "Part")
	o.Anchored = true
	o.CanCollide = false
	o.CanTouch = false
	o.TopSurface = Enum.SurfaceType.Smooth
	o.BottomSurface = Enum.SurfaceType.Smooth
	o.Material = M.SmoothPlastic
	for k, v in p do if k ~= "Parent" and k ~= "Class" then o[k] = v end end
	o.Parent = p.Parent
	n += 1
	if n % 300 == 0 then task.wait() end
	return o
end
local function box(parent, name, c, x1, y1, z1, x2, y2, z2, col, mat, extra)
	local o = part({Name = name, Size = V(math.abs(x2 - x1), math.abs(y2 - y1), math.abs(z2 - z1)),
		CFrame = CF(c + V((x1 + x2) / 2, (y1 + y2) / 2, (z1 + z2) / 2)), Color = col, Material = mat or M.SmoothPlastic, Parent = parent})
	if extra then for k, v in extra do o[k] = v end end
	return o
end
local function text(p, face, str, color, bg, font, canvas, stroke)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 0.25
	sg.CanvasSize = canvas or Vector2.new(400, 100)
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Name = "T"
	t.Size = UDim2.fromScale(0.94, 0.9)
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.5, 0.5)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or C3(255, 255, 255)
	t.Font = font or Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = color
	t.Parent = sg
	if stroke then
		local st = Instance.new("UIStroke")
		st.Thickness = 3
		st.Color = stroke
		st.Parent = t
	end
	return sg
end
-- a prop model: parts built around PARK (local frame, front = -Z), pivot = PARK, Home attribute
local props = folder("Props", SETS)
local function model(name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = props
	return m
end
local function finish(m)
	m.WorldPivot = PARK
	m:SetAttribute("Home", PARK)
end
local function lp(m, name, size, cf, col, mat, extra)
	local t = {Name = name, Size = size, CFrame = PARK * cf, Color = col, Material = mat or M.SmoothPlastic, Parent = m}
	if extra then for k, v in extra do t[k] = v end end
	return part(t)
end

---------------------------------------------------------------- HOME interior
do
	local H = TOWN + V(250, 0, -120)
	local f = folder("Home", SETS)
	local WALL, TRIM, FLOOR = C3(250, 232, 205), C3(255, 250, 240), C3(170, 115, 70)
	box(f, "Floor", H, -14.5, -0.6, -12.5, 14.5, 0.2, 12.5, FLOOR, M.WoodPlanks)
	box(f, "Rug", H, -9, 0.2, -2, 1, 0.26, 6, C3(90, 130, 170), M.Fabric)
	box(f, "WallN", H, -14.5, 0, -13, 14.5, 12.5, -12.5, WALL, M.Plaster)
	box(f, "WallW", H, -15, 0, -12.5, -14.5, 12.5, 12.5, WALL, M.Plaster)
	box(f, "WallE", H, 14.5, 0, -12.5, 15, 12.5, 12.5, WALL, M.Plaster)
	-- south wall with the door gap x 7..11 (door 8 tall)
	box(f, "WallS1", H, -14.5, 0, 12.5, 7, 12.5, 13, WALL, M.Plaster)
	box(f, "WallS2", H, 11, 0, 12.5, 14.5, 12.5, 13, WALL, M.Plaster)
	box(f, "WallS3", H, 7, 8.2, 12.5, 11, 12.5, 13, WALL, M.Plaster)
	box(f, "Ceiling", H, -15, 12.5, -13, 15, 13, 13, C3(250, 248, 240))
	for _, z in {-12.45, 12.45} do box(f, "Baseboard", H, -14.5, 0.2, z - 0.05, 14.5, 0.8, z + 0.05, TRIM) end
	box(f, "DoorFrameL", H, 6.7, 0.2, 12.4, 7, 8.4, 13.1, TRIM)
	box(f, "DoorFrameR", H, 11, 0.2, 12.4, 11.3, 8.4, 13.1, TRIM)
	box(f, "DoorFrameT", H, 6.7, 8.2, 12.4, 11.3, 8.5, 13.1, TRIM)
	-- window (north wall): frame + a panel the Director recolours (day sky / night blizzard)
	box(f, "WinFrame", H, -7.4, 3.6, -12.5, 1.4, 9.4, -12.35, TRIM)
	box(f, "WinPanel", H, -7, 4, -12.4, 1, 9, -12.3, C3(140, 200, 245), M.SmoothPlastic)
	box(f, "WinBar", H, -3.1, 4, -12.32, -2.9, 9, -12.26, TRIM)
	box(f, "WinBar2", H, -7, 6.4, -12.32, 1, 6.6, -12.26, TRIM)
	box(f, "Sill", H, -7.6, 3.4, -12.5, 1.6, 3.7, -11.8, TRIM)
	-- couch (west wall, faces +X)
	box(f, "CouchSeat", H, -13.6, 1.0, -6, -10.2, 2.2, 3, C3(200, 80, 70), M.Fabric)
	box(f, "CouchBack", H, -14.4, 1.0, -6, -13.4, 5.0, 3, C3(185, 70, 62), M.Fabric)
	box(f, "CouchArmN", H, -14.4, 1.0, -6.9, -10.2, 3.4, -6, C3(185, 70, 62), M.Fabric)
	box(f, "CouchArmS", H, -14.4, 1.0, 3, -10.2, 3.4, 3.9, C3(185, 70, 62), M.Fabric)
	box(f, "CouchBase", H, -14.2, 0.2, -6.7, -10.4, 1.0, 3.7, C3(90, 60, 40), M.Wood)
	-- dining table (top 3.2) + chairs
	box(f, "TableTop", H, 1.5, 2.9, -8, 8.5, 3.2, -2, C3(150, 95, 55), M.Wood)
	for _, p in {{2, -7.5}, {8, -7.5}, {2, -2.5}, {8, -2.5}} do box(f, "TableLeg", H, p[1] - 0.25, 0.2, p[2] - 0.25, p[1] + 0.25, 2.9, p[2] + 0.25, C3(120, 75, 45), M.Wood) end
	box(f, "Cloth", H, 1.3, 3.2, -8.2, 8.7, 3.24, -1.8, C3(250, 250, 245), M.Fabric)
	for _, c in {{0, -5, 1}, {10, -5, -1}} do
		box(f, "ChairSeat", H, c[1] - 1.1, 1.8, c[2] - 1.1, c[1] + 1.1, 2.1, c[2] + 1.1, C3(150, 95, 55), M.Wood)
		box(f, "ChairBack", H, c[1] - c[3] * 1.1 - 0.15, 2.1, c[2] - 1.1, c[1] - c[3] * 1.1 + 0.15, 5, c[2] + 1.1, C3(150, 95, 55), M.Wood)
	end
	-- floor lamp in the NE corner + the ceiling light
	box(f, "LampPole", H, 12.4, 0.2, -10.6, 12.7, 6.5, -10.3, C3(60, 60, 65), M.Metal)
	local shade = box(f, "LampShade", H, 11.7, 6.5, -11.3, 13.4, 8, -9.6, C3(255, 235, 190), M.Fabric)
	local pl = Instance.new("PointLight")
	pl.Name = "LampLight"
	pl.Color = C3(255, 210, 150)
	pl.Brightness = 1.2
	pl.Range = 22
	pl.Parent = shade
	local cl = box(f, "CeilLight", H, -2, 12.2, -2, 2, 12.5, 2, C3(255, 245, 220), M.Neon)
	local rl = Instance.new("PointLight")
	rl.Name = "RoomLight"
	rl.Color = C3(255, 225, 180)
	rl.Brightness = 1.3
	rl.Range = 30
	rl.Shadows = true
	rl.Parent = cl
	-- doormat + shoe rack with Dad's big boots + the crayon KEVIN label above Juniper's (empty) spot
	box(f, "Doormat", H, 7, 0.2, 9.2, 11, 0.3, 11.6, C3(140, 90, 60), M.Fabric)
	box(f, "Rack", H, 12, 0.2, 6, 14.4, 1.6, 12, C3(130, 85, 50), M.Wood)
	for i, z in {7, 8.5, 10} do
		box(f, "BigBoot", H, 12.4, 1.6, z, 13.9, 3.2, z + 1.1, C3(70, 50, 35), M.Leather)
	end
	local lab = box(f, "KevinLabel", H, 3.4, 2.4, 12.35, 6.6, 4.4, 12.45, C3(255, 255, 255), M.SmoothPlastic)
	text(lab, Enum.NormalId.Front, "KEVIN + KEVIN", C3(255, 70, 160), nil, Enum.Font.PermanentMarker, Vector2.new(300, 180))
	box(f, "KevinMat", H, 3.8, 0.2, 10.2, 6.4, 0.27, 12.2, C3(255, 190, 220), M.Fabric)
	-- pictures on the walls
	local pic = box(f, "Picture", H, -14.45, 6, -2, -14.35, 9, 2, C3(255, 220, 120), M.SmoothPlastic)
	text(pic, Enum.NormalId.Right, "HOME", C3(120, 70, 30), nil, Enum.Font.FredokaOne)
	-- outside the door: a snow yard with small footprints leading away into the dark (night shots only see this)
	box(f, "SnowYard", H, -20, -0.6, 13, 40, 0.3, 70, C3(235, 240, 250), M.Snow)
	box(f, "Step", H, 6.5, 0.2, 13, 11.5, 0.45, 15, C3(160, 160, 165), M.Concrete)
	for i = 0, 11 do
		local z = 16 + i * 2.6
		local x = 9 + math.sin(i * 0.6) * 2 + ((i % 2 == 0) and -0.45 or 0.45)
		box(f, "Print", H, x - 0.3, 0.3, z - 0.45, x + 0.3, 0.33, z + 0.45, C3(150, 165, 195), M.Snow)
	end
end

---------------------------------------------------------------- ZOO (Godzilla the hamster's pen)
do
	local Z = TOWN + V(-260, 0, -125)
	local f = folder("Zoo", SETS)
	box(f, "Straw", Z, -13.5, -0.4, -13.5, 13.5, 0.15, 13.5, C3(225, 195, 110), M.Grass)
	box(f, "Path", Z, -30, -0.4, 22.5, 30, 0.12, 32, C3(190, 180, 165), M.Concrete)
	local FCOL = {C3(60, 110, 70), C3(70, 90, 110), C3(110, 70, 60)}
	for ring, h in ipairs({14, 18, 22}) do
		local tall = 5 + ring * 1.6
		local col = FCOL[ring]
		for _, s in {-1, 1} do
			-- rails along X (front/back) and along Z (sides)
			for k = 1, 3 do
				local y = tall * k / 3.2
				box(f, "Rail", Z, -h, y - 0.15, s * h - 0.15, h, y + 0.15, s * h + 0.15, col, M.Metal)
				box(f, "Rail", Z, s * h - 0.15, y - 0.15, -h, s * h + 0.15, y + 0.15, h, col, M.Metal)
			end
			for x = -h, h, 2 do
				box(f, "Bar", Z, x - 0.1, 0, s * h - 0.1, x + 0.1, tall, s * h + 0.1, col, M.Metal)
				box(f, "Bar", Z, s * h - 0.1, 0, x - 0.1, s * h + 0.1, tall, x + 0.1, col, M.Metal)
			end
		end
	end
	local sg = box(f, "GodzillaSign", Z, -6, 5.2, 22.3, 6, 8.6, 22.5, C3(255, 230, 60), M.SmoothPlastic)
	text(sg, Enum.NormalId.Back, "GODZILLA", C3(200, 30, 30), nil, Enum.Font.FredokaOne, Vector2.new(400, 110), C3(255, 255, 255))
	box(f, "SignBorder", Z, -6.3, 4.9, 22.15, 6.3, 8.9, 22.3, C3(30, 30, 35))
	local sg2 = box(f, "FeedSign", Z, -17, 3.2, 22.3, -11, 5.2, 22.5, C3(250, 250, 250), M.SmoothPlastic)
	text(sg2, Enum.NormalId.Back, "DO NOT FEED", C3(30, 30, 35), nil, Enum.Font.FredokaOne)
	-- giant seed pile + a giant water bottle on the inner fence
	for i = 0, 6 do
		local a = i * 0.9
		box(f, "Seed", Z, -9 + math.cos(a) * 2 - 0.9, 0.15, 7 + math.sin(a) * 2 - 1.4, -9 + math.cos(a) * 2 + 0.9, 1.2, 7 + math.sin(a) * 2 + 1.4, (i % 2 == 0) and C3(60, 55, 50) or C3(235, 230, 215), M.SmoothPlastic)
	end
	box(f, "Bottle", Z, 10, 4, -14.6, 13, 14, -13.8, C3(170, 220, 250), M.Glass, {Transparency = 0.35})
	box(f, "BottleCap", Z, 11, 2.4, -14.4, 12, 4, -13.9, C3(60, 160, 80), M.SmoothPlastic)
	-- zoo arch to the east of the pen
	box(f, "ArchL", Z, 26, 0, 24, 27.2, 12, 25.2, C3(120, 80, 50), M.Wood)
	box(f, "ArchR", Z, 36, 0, 24, 37.2, 12, 25.2, C3(120, 80, 50), M.Wood)
	local ab = box(f, "ArchBoard", Z, 25.5, 10, 24.3, 37.7, 13, 24.9, C3(80, 160, 90), M.Wood)
	text(ab, Enum.NormalId.Back, "CITY ZOO", C3(255, 255, 255), nil, Enum.Font.FredokaOne)
end

---------------------------------------------------------------- street lamps (north sidewalk), off by default
do
	local f = folder("Lamps", SETS)
	for i, x in {-40, 0, 40, 80, 120, 160, 200, 240} do
		local c = TOWN + V(x, 0.55, -17.5)
		box(f, "Pole", c, -0.25, 0, -0.25, 0.25, 13, 0.25, C3(50, 52, 58), M.Metal)
		box(f, "Arm", c, -0.15, 12.6, -0.15, 0.15, 12.9, 2.6, C3(50, 52, 58), M.Metal)
		local hd = box(f, "Head", c, -0.8, 12.0, 1.6, 0.8, 12.6, 3.2, C3(90, 90, 85), M.SmoothPlastic)
		hd:SetAttribute("I", i)
		local l = Instance.new("PointLight")
		l.Color = C3(255, 200, 130)
		l.Brightness = 2
		l.Range = 34
		l.Enabled = false
		l.Parent = hd
	end
end

---------------------------------------------------------------- props
-- the snow blanket over Maple Street + lawns + the school plaza (pivot it to TOWN for winter shots)
do
	local m = model("SnowTown")
	lp(m, "Snow", V(960, 1.4, 160), CF(140, 0.05, 0), C3(236, 241, 250), M.Snow)
	finish(m)
end
-- Mr. Greer's three signs (front = -Z). Sign1 small QUIET PLEASE, Sign2 BIG, Sign3 tiny "why"
local function sign(name, w, h, post, str, col, bg, font)
	local m = model(name)
	for _, s in {-1, 1} do lp(m, "Post", V(0.35, post + h, 0.35), CF(s * (w / 2 - 0.5), (post + h) / 2, 0.25), C3(120, 80, 50), M.Wood) end
	local b = lp(m, "Board", V(w, h, 0.25), CF(0, post + h / 2, 0), bg or C3(250, 250, 245), M.SmoothPlastic)
	text(b, Enum.NormalId.Front, str, col, nil, font or Enum.Font.FredokaOne, Vector2.new(100 * w / h, 100))
	text(b, Enum.NormalId.Back, str, col, nil, font or Enum.Font.FredokaOne, Vector2.new(100 * w / h, 100))
	lp(m, "Frame", V(w + 0.3, h + 0.3, 0.2), CF(0, post + h / 2, 0.08), C3(60, 60, 65))
	finish(m)
end
sign("Sign1", 4.2, 1.8, 2.2, "QUIET PLEASE", C3(40, 40, 45))
sign("Sign2", 13, 5.2, 2.6, "QUIET PLEASE", C3(220, 30, 30), C3(255, 240, 120))
sign("Sign3", 2.6, 1.4, 2.0, "why", C3(40, 40, 45), nil, Enum.Font.Gotham)
-- flashlights (lens at local -Z): a SpotLight + a soft beam
for i = 1, 6 do
	local m = model("Torch" .. i)
	lp(m, "Body", V(0.32, 0.32, 1.3), CF(0, 0, 0.1), C3(40, 40, 45), M.Metal)
	local lens = lp(m, "Lens", V(0.42, 0.42, 0.2), CF(0, 0, -0.6), C3(255, 250, 220), M.Neon)
	local sp = Instance.new("SpotLight")
	sp.Face = Enum.NormalId.Front
	sp.Color = C3(255, 245, 215)
	sp.Brightness = 3
	sp.Range = 40
	sp.Angle = 32
	sp.Shadows = false
	sp.Parent = lens
	local a0 = Instance.new("Attachment") a0.Position = V(0, 0, -0.1) a0.Parent = lens
	local a1 = Instance.new("Attachment") a1.Position = V(0, 0, -24) a1.Parent = lens
	local bm = Instance.new("Beam")
	bm.Attachment0, bm.Attachment1 = a0, a1
	bm.Width0, bm.Width1 = 0.3, 4.5
	bm.FaceCamera = true
	bm.LightEmission = 0.8
	bm.LightInfluence = 0
	bm.Color = ColorSequence.new(C3(255, 248, 225))
	bm.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.5, 0.88), NumberSequenceKeypoint.new(1, 1)})
	bm.Segments = 4
	bm.Parent = lens
	finish(m)
end
-- the log in the woods (along X), snow on top; Juniper curls up behind it (on its +Z side)
do
	local m = model("Log")
	lp(m, "Log", V(12, 2.4, 2.4), CF(0, 1.2, 0), C3(110, 75, 45), M.Wood, {Shape = Enum.PartType.Cylinder})
	lp(m, "EndL", V(0.1, 2.0, 2.0), CF(-6.02, 1.2, 0), C3(200, 160, 110), M.Wood, {Shape = Enum.PartType.Cylinder})
	lp(m, "EndR", V(0.1, 2.0, 2.0), CF(6.02, 1.2, 0), C3(200, 160, 110), M.Wood, {Shape = Enum.PartType.Cylinder})
	lp(m, "SnowCap", V(11.6, 0.4, 1.6), CF(0, 2.45, 0), C3(240, 245, 252), M.Snow)
	lp(m, "Branch", V(0.35, 2.2, 0.35), CF(-2.5, 2.8, -0.4) * A(rad(-20), 0, rad(25)), C3(100, 70, 40), M.Wood)
	finish(m)
end
-- Gary: a stick with googly eyes and a paper name tag (held along its length; grip end = local +Y bottom)
do
	local m = model("Gary")
	lp(m, "Stick", V(0.22, 2.6, 0.22), CF(0, 1.1, 0), C3(130, 90, 50), M.Wood)
	lp(m, "Twig", V(0.12, 0.8, 0.12), CF(0.25, 1.9, 0) * A(0, 0, rad(-35)), C3(130, 90, 50), M.Wood)
	for _, s in {-1, 1} do
		lp(m, "Eye", V(0.3, 0.3, 0.3), CF(s * 0.13, 2.1, -0.14), C3(255, 255, 255), M.SmoothPlastic, {Shape = Enum.PartType.Ball})
		lp(m, "Pupil", V(0.14, 0.14, 0.14), CF(s * 0.13, 2.08, -0.28), C3(20, 20, 20), M.SmoothPlastic, {Shape = Enum.PartType.Ball})
	end
	local tag = lp(m, "Tag", V(1.2, 0.6, 0.04), CF(0, 1.35, -0.16), C3(255, 255, 240))
	text(tag, Enum.NormalId.Front, "GARY", C3(255, 70, 160), nil, Enum.Font.PermanentMarker, Vector2.new(200, 100))
	finish(m)
end
-- birthday cake (6 candles, flames named Flame) + a HAPPY BIRTHDAY banner
do
	local m = model("Cake")
	lp(m, "Plate", V(0.12, 3.2, 3.2), CF(0, 0.06, 0), C3(250, 250, 250), M.SmoothPlastic, {Shape = Enum.PartType.Cylinder, CFrame = PARK * CF(0, 0.06, 0) * A(0, 0, rad(90))})
	lp(m, "Tier1", V(1.2, 2.6, 2.6), CF(0, 0.72, 0) * A(0, 0, rad(90)), C3(255, 190, 210), M.SmoothPlastic, {Shape = Enum.PartType.Cylinder})
	lp(m, "Icing", V(0.18, 2.7, 2.7), CF(0, 1.38, 0) * A(0, 0, rad(90)), C3(255, 255, 255), M.SmoothPlastic, {Shape = Enum.PartType.Cylinder})
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		local x, z = math.cos(a) * 0.85, math.sin(a) * 0.85
		lp(m, "Candle", V(0.14, 0.7, 0.14), CF(x, 1.8, z), (i % 2 == 0) and C3(90, 170, 255) or C3(255, 220, 60))
		lp(m, "Flame", V(0.16, 0.3, 0.16), CF(x, 2.3, z), C3(255, 190, 60), M.Neon, {Shape = Enum.PartType.Ball})
	end
	finish(m)
	local b = model("Banner")
	local bp = lp(b, "Banner", V(14, 2.2, 0.1), CF(0, 0, 0), C3(255, 255, 255))
	text(bp, Enum.NormalId.Front, "HAPPY BIRTHDAY!", C3(240, 60, 120), nil, Enum.Font.FredokaOne, Vector2.new(640, 100))
	finish(b)
end
-- the uncle's porch table (top 3.0) + the big winning ticket
do
	local m = model("Table")
	lp(m, "Top", V(0.25, 4, 4), CF(0, 2.9, 0), C3(250, 250, 250), M.SmoothPlastic, {Shape = Enum.PartType.Cylinder, CFrame = PARK * CF(0, 2.9, 0) * A(0, 0, rad(90))})
	lp(m, "Leg", V(0.4, 2.8, 0.4), CF(0, 1.4, 0), C3(200, 200, 205), M.Metal)
	finish(m)
	local t = model("BigTicket")
	local tp = lp(t, "Ticket", V(3.2, 1.6, 0.06), CF(0, 0, 0), C3(255, 225, 70))
	text(tp, Enum.NormalId.Front, "WINNER!", C3(200, 30, 30), nil, Enum.Font.FredokaOne, Vector2.new(200, 100))
	text(tp, Enum.NormalId.Back, "LOTTO", C3(40, 120, 60), nil, Enum.Font.FredokaOne, Vector2.new(200, 100))
	lp(t, "Edge", V(3.3, 1.7, 0.04), CF(0, 0, 0.03), C3(40, 140, 70))
	finish(t)
end
-- doghouses with a name plate (front = -Z, door on the front)
for i = 1, 4 do
	local m = model("DH" .. i)
	local col = ({C3(200, 60, 50), C3(70, 130, 200), C3(90, 160, 90), C3(240, 180, 60)})[i]
	lp(m, "Walls", V(5, 4, 5.6), CF(0, 2, 0), col, M.WoodPlanks)
	lp(m, "Door", V(2, 2.6, 0.1), CF(0, 1.3, -2.82), C3(30, 25, 25))
	for _, s in {-1, 1} do
		lp(m, "Roof", V(0.3, 3.9, 6.2), CF(s * 1.25, 5.0, 0) * A(0, 0, rad(s * 42)), C3(110, 70, 50), M.WoodPlanks)
	end
	local pl = lp(m, "Plate", V(4.4, 0.9, 0.1), CF(0, 3.3, -2.86), C3(255, 250, 235))
	text(pl, Enum.NormalId.Front, "SIR BARKS-A-LOT", C3(30, 30, 35), nil, Enum.Font.FredokaOne, Vector2.new(490, 100))
	finish(m)
end
-- Juniper's HERO cape (a red cape for the dog's back, gold H)
do
	local m = model("Cape")
	local c = lp(m, "Cape", V(2.6, 0.12, 3.2), CF(0, 0, 0), C3(220, 30, 40), M.Fabric)
	text(c, Enum.NormalId.Top, "H", C3(255, 210, 50), nil, Enum.Font.FredokaOne, Vector2.new(100, 100))
	lp(m, "Tie", V(2.0, 0.3, 0.3), CF(0, 0.2, -1.6), C3(255, 210, 50), M.Fabric)
	finish(m)
end

---------------------------------------------------------------- PETS (kit pet format)
local pets = folder("Pets", SETS)
local INK = C3(18, 16, 16)
local WHITE = C3(255, 255, 255)
local function creature(name)
	local m = Instance.new("Model")
	m.Name = name
	local root = part({Name = "Root", Size = V(1, 1, 1), CFrame = PARK, Transparency = 1, Parent = m})
	m.PrimaryPart = root
	m.Parent = pets
	local api = {model = m}
	function api.limb(limb, pivot, parentLimb)
		m:SetAttribute("Pivot_" .. limb, pivot)
		if parentLimb then m:SetAttribute("Parent_" .. limb, parentLimb) end
	end
	function api.p(limb, shape, size, cf, color, opts)
		opts = opts or {}
		local t = {Name = opts.name or limb, Size = size, CFrame = PARK * cf, Color = color, Material = opts.mat or M.SmoothPlastic, Parent = m}
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
-- SIR BARKS-A-LOT: scruffy brown mutt (built at kit-dog size, filmed at scale ~0.55). Jaw limb opens with X(-35).
do
	local FUR, LIGHT, EAR, DARK = C3(132, 86, 50), C3(205, 160, 112), C3(92, 58, 34), C3(105, 66, 38)
	local F = M.Fabric
	local d = creature("Barks")
	d.limb("Body", CF(0, 3.0, 0))
	d.p("Body", "block", V(2.8, 2.6, 5.0), CF(0, 3.3, 0.3), FUR, {mat = F})
	d.p("Body", "block", V(2.3, 2.0, 0.5), CF(0, 3.0, -2.25), LIGHT, {name = "Chest", mat = F})
	d.p("Body", "block", V(2.0, 0.8, 3.8), CF(0, 1.95, 0.3), LIGHT, {name = "Belly", mat = F})
	d.p("Body", "block", V(1.9, 1.9, 1.7), CF(0, 4.3, -2.4), FUR, {name = "Neck", mat = F})
	for i, z in {-1.2, 0.2, 1.6} do -- shaggy back tufts
		d.p("Body", "block", V(1.2, 0.5, 1.0), CF((i - 2) * 0.35, 4.7, z) * A(rad(20), 0, rad((i - 2) * 15)), DARK, {name = "Tuft", mat = F})
	end
	d.p("Body", "block", V(2.06, 0.5, 1.8), CF(0, 3.75, -2.4), C3(210, 35, 45), {name = "Collar"})
	d.p("Body", "cyl", V(0.14, 0.7, 0.7), CF(0, 3.25, -3.35) * A(0, rad(90), 0), C3(255, 200, 50), {name = "Tag", mat = M.Metal})
	d.limb("Head", CF(0, 4.8, -2.9), "Body")
	d.p("Head", "block", V(2.6, 2.4, 2.4), CF(0, 5.8, -3.5), FUR, {mat = F})
	d.p("Head", "block", V(1.5, 0.75, 1.0), CF(0, 5.3, -5.1), LIGHT, {name = "Snout", mat = F})
	d.p("Head", "block", V(0.62, 0.42, 0.3), CF(0, 5.5, -5.64), INK, {name = "Nose"})
	d.p("Head", "block", V(0.16, 0.1, 0.12), CF(-0.14, 5.62, -5.8), C3(120, 120, 130), {name = "NoseShine"})
	d.p("Head", "block", V(1.25, 0.6, 1.0), CF(0, 4.75, -4.95), C3(110, 25, 35), {name = "MouthIn"})
	for _, s in {-1, 1} do d.p("Head", "block", V(0.2, 0.2, 0.12), CF(s * 0.42, 4.84, -5.55), WHITE, {name = "Tooth"}) end
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.86, 0.86, 0.86), CF(s * 0.64, 6.08, -4.6), INK, {name = "Eye" .. tag})
		d.p("Head", "ball", V(0.3, 0.3, 0.3), CF(s * 0.64 + 0.13, 6.25, -4.98), WHITE, {name = "Shine" .. tag})
		d.p("Head", "ball", V(0.14, 0.14, 0.14), CF(s * 0.64 - 0.14, 5.92, -5.0), WHITE, {name = "Shine2" .. tag})
		d.p("Head", "block", V(1.0, 0.58, 0.24), CF(s * 0.64, 6.1, -5.0), FUR, {name = "Lid" .. tag, transp = 1})
		d.p("Head", "block", V(0.66, 0.2, 0.16), CF(s * 0.62, 6.78, -4.72) * A(0, 0, rad(s * -10)), LIGHT, {name = "Brow" .. tag, mat = F})
		d.p("Head", "block", V(0.35, 1.0, 1.2), CF(s * 1.35, 5.3, -4.2) * A(0, 0, rad(s * 12)), LIGHT, {name = "Cheek", mat = F})
	end
	for i, x in {-0.55, 0, 0.55} do -- scruffy head tufts
		d.p("Head", "block", V(0.45, 0.75, 0.45), CF(x, 7.15 + (i == 2 and 0.15 or 0), -3.6) * A(rad(-15), 0, rad(-x * 40)), DARK, {name = "HeadTuft", mat = F})
	end
	d.limb("Jaw", CF(0, 4.85, -4.4), "Head")
	d.p("Jaw", "block", V(1.3, 0.42, 1.1), CF(0, 4.62, -5.0), LIGHT, {name = "Jaw", mat = F})
	d.p("Jaw", "block", V(0.75, 0.12, 0.75), CF(0, 4.86, -5.0), C3(235, 95, 115), {name = "Tongue"})
	d.p("Jaw", "block", V(0.9, 0.4, 0.5), CF(0, 4.3, -5.15), LIGHT, {name = "Goatee", mat = F})
	-- ears: left floppy, right half up
	d.limb("EarL", CF(-1.25, 6.8, -3.4), "Head")
	d.p("EarL", "block", V(0.42, 2.0, 1.25), CF(-1.47, 5.8, -3.4), EAR, {mat = F})
	d.limb("EarR", CF(1.0, 6.85, -3.35), "Head")
	d.p("EarR", "block", V(0.4, 1.3, 1.05), CF(1.05, 7.4, -3.35) * A(0, 0, rad(-14)), EAR, {mat = F})
	d.p("EarR", "block", V(0.34, 0.6, 0.7), CF(1.35, 7.95, -3.6) * A(rad(-35), 0, rad(-14)), EAR, {name = "EarTip", mat = F})
	d.limb("Tail", CF(0, 4.2, 2.75), "Body")
	d.p("Tail", "block", V(0.55, 0.55, 2.0), CF(0, 5.0, 3.4) * A(rad(45), 0, 0), FUR, {mat = F})
	d.p("Tail", "block", V(0.75, 0.75, 0.8), CF(0, 5.75, 4.05) * A(rad(45), 0, 0), DARK, {name = "TailTuft", mat = F})
	for _, l in {{"LegFL", -1, -1.6}, {"LegFR", 1, -1.6}, {"LegBL", -1, 2.0}, {"LegBR", 1, 2.0}} do
		d.limb(l[1], CF(l[2] * 0.85, 2.25, l[3]), "Body")
		d.p(l[1], "block", V(0.92, 2.25, 0.92), CF(l[2] * 0.85, 1.12, l[3]), FUR, {mat = F})
		d.p(l[1], "block", V(1.0, 0.36, 1.22), CF(l[2] * 0.85, 0.18, l[3] - 0.12), LIGHT, {name = "Paw", mat = F})
	end
end
-- puppies: round body, big head + eyes, a Jaw limb (opens with X(-35)), scruffy tuft. Barks as a puppy + Mr. Greer's
local function puppy(name, FUR, LIGHT, EAR, COLLAR)
	local d = creature(name)
	d.limb("Body", CF(0, 1.0, 0))
	d.p("Body", "block", V(1.5, 1.25, 2.1), CF(0, 1.12, 0.15), FUR, {mat = M.Fabric})
	d.p("Body", "block", V(1.2, 0.5, 1.6), CF(0, 0.6, 0.15), LIGHT, {name = "Belly", mat = M.Fabric})
	d.p("Body", "block", V(1.56, 0.22, 0.9), CF(0, 1.7, -0.72), COLLAR, {name = "Collar"})
	d.limb("Head", CF(0, 1.55, -0.85), "Body")
	d.p("Head", "block", V(1.75, 1.55, 1.5), CF(0, 2.35, -1.1), FUR, {mat = M.Fabric})
	d.p("Head", "block", V(0.85, 0.42, 0.45), CF(0, 2.02, -1.98), LIGHT, {name = "Snout", mat = M.Fabric})
	d.p("Head", "block", V(0.36, 0.24, 0.16), CF(0, 2.15, -2.24), INK, {name = "Nose"})
	d.p("Head", "block", V(0.7, 0.36, 0.5), CF(0, 1.72, -1.85), C3(110, 25, 35), {name = "MouthIn"})
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.6, 0.6, 0.6), CF(s * 0.43, 2.48, -1.78), INK, {name = "Eye" .. tag})
		d.p("Head", "ball", V(0.21, 0.21, 0.21), CF(s * 0.43 + 0.1, 2.61, -2.05), WHITE, {name = "Shine" .. tag})
		d.p("Head", "block", V(0.68, 0.36, 0.12), CF(s * 0.43, 2.5, -1.98), FUR, {name = "Lid" .. tag, transp = 1})
		d.p("Head", "block", V(0.36, 0.09, 0.06), CF(s * 0.43, 2.92, -1.86), LIGHT, {name = "Brow" .. tag})
	end
	d.p("Head", "block", V(0.35, 0.5, 0.35), CF(0.1, 3.2, -1.2) * A(rad(-15), 0, rad(-20)), EAR, {name = "HeadTuft", mat = M.Fabric})
	d.limb("Jaw", CF(0, 1.88, -1.6), "Head")
	d.p("Jaw", "block", V(0.75, 0.24, 0.5), CF(0, 1.68, -1.95), LIGHT, {name = "Jaw", mat = M.Fabric})
	d.p("Jaw", "block", V(0.4, 0.07, 0.38), CF(0, 1.82, -1.95), C3(235, 95, 115), {name = "Tongue"})
	for _, s in {-1, 1} do
		local ear = s < 0 and "EarL" or "EarR"
		d.limb(ear, CF(s * 0.86, 3.0, -1.15), "Head")
		d.p(ear, "block", V(0.28, 1.05, 0.75), CF(s * 1.0, 2.5, -1.1), EAR, {mat = M.Fabric})
	end
	d.limb("Tail", CF(0, 1.5, 1.15), "Body")
	d.p("Tail", "block", V(0.3, 0.3, 0.75), CF(0, 1.72, 1.45) * A(rad(35), 0, 0), EAR)
	for _, l in {{"LegFL", -1, -0.55}, {"LegFR", 1, -0.55}, {"LegBL", -1, 0.75}, {"LegBR", 1, 0.75}} do
		d.limb(l[1], CF(l[2] * 0.45, 0.62, l[3]), "Body")
		d.p(l[1], "block", V(0.48, 0.62, 0.48), CF(l[2] * 0.45, 0.31, l[3]), FUR, {mat = M.Fabric})
		d.p(l[1], "block", V(0.54, 0.2, 0.62), CF(l[2] * 0.45, 0.1, l[3] - 0.06), LIGHT, {name = "Paw", mat = M.Fabric})
	end
end
puppy("BarksPup", C3(150, 100, 60), C3(215, 172, 125), C3(100, 64, 38), C3(210, 35, 45))
puppy("Second", C3(150, 100, 60), C3(215, 172, 125), C3(100, 64, 38), C3(50, 110, 220))
-- FLUFF: Mrs. Lee's cat, now 90% fluff: a giant cream fluff ball (about 6.5 across) with tiny eyes, ears, paws, tail
do
	local CREAM, CREAM2, WARM = C3(252, 244, 228), C3(240, 228, 208), C3(250, 210, 160)
	local d = creature("Fluff")
	d.limb("Body", CF(0, 3.2, 0))
	local rng = Random.new(42)
	d.p("Body", "ball", V(6.2, 6.2, 6.2), CF(0, 3.2, 0), CREAM, {mat = M.Fabric})
	for i = 1, 22 do
		local th, ph = rng:NextNumber(0, math.pi * 2), rng:NextNumber(-1.2, 1.3)
		local dir = V(math.cos(ph) * math.cos(th), math.sin(ph), math.cos(ph) * math.sin(th))
		local s = rng:NextNumber(1.6, 2.6)
		d.p("Body", "ball", V(s, s, s), CF(V(0, 3.2, 0) + dir * 2.7), (i % 3 == 0) and CREAM2 or ((i % 5 == 0) and WARM or CREAM), {name = "Puff", mat = M.Fabric})
	end
	d.limb("Head", CF(0, 3.6, -2.6), "Body")
	for _, s in {-1, 1} do
		local tag = s < 0 and "L" or "R"
		d.p("Head", "ball", V(0.42, 0.42, 0.42), CF(s * 0.45, 3.85, -3.55), INK, {name = "Eye" .. tag})
		d.p("Head", "ball", V(0.14, 0.14, 0.14), CF(s * 0.45 + 0.06, 3.93, -3.74), WHITE, {name = "Shine" .. tag})
		d.p("Head", "wedge", V(0.2, 0.55, 0.45), CF(s * 0.95, 5.6, -2.7), WARM, {name = "Ear"})
		d.p("Body", "ball", V(0.6, 0.45, 0.7), CF(s * 0.9, 0.22, -2.3), CREAM2, {name = "Paw", mat = M.Fabric})
		d.p("Head", "block", V(0.8, 0.04, 0.04), CF(s * 0.85, 3.45, -3.55) * A(0, 0, rad(s * 8)), C3(120, 110, 100), {name = "Whisker"})
	end
	d.p("Head", "block", V(0.22, 0.15, 0.1), CF(0, 3.55, -3.66), C3(240, 120, 140), {name = "Nose"})
	d.limb("Tail", CF(0, 2.0, 3.0), "Body")
	d.p("Tail", "ball", V(1.6, 1.6, 2.2), CF(0, 3.0, 3.6), WARM, {mat = M.Fabric})
end

---------------------------------------------------------------- finish: everything anchored, no collisions, no scripts
SETS.Parent = film
for _, d in SETS:GetDescendants() do
	if d:IsA("LuaSourceContainer") then d:Destroy() end
	if d:IsA("BasePart") then d.Anchored = true d.CanCollide = false d.CanTouch = false end
end
return "reel 42 sets ok, " .. n .. " parts; " .. table.concat(LOG, "; ")
