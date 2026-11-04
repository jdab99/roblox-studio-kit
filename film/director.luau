-- FilmDirector (ModuleScript in ReplicatedStorage). Client-side: stages every shot of reel 01 "The Key Heist"
-- on the narration clock, with a tilted camera for 9:16 recording. Usage (Client luau):
--   require(game.ReplicatedStorage.FilmDirector).run(startT, endT)   -- returns at once; magenta frames mark start/end
--   require(...).still(T)                                           -- freeze on one moment (for checks)
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local D = {}
local Film = workspace:WaitForChild("Film")
local CastF = Film:WaitForChild("Cast")
local Sets = Film:WaitForChild("Sets")
local Store = Film:WaitForChild("Store")
local Heist = workspace:WaitForChild("HeistMap")
local HIDE = Instance.new("Folder") -- not parented: hidden things live here (client only)
local OFF = CFrame.new(0, 500, 4000)
local rad = math.rad

local FACES = {
	happy = 72579951856139, shocked = 123471687600628, scared = 81022056057673, sneaky = 82374946742835,
	angry = 125197693534047, sad = 72026756477677, sleep = 70540320410457, laugh = 90847884666687,
}
local ANIM = {idle = "rbxassetid://507766388", walk = "rbxassetid://913402848", run = "rbxassetid://913376220"}
local JOINTS = {"Neck", "Waist", "Root", "RightShoulder", "LeftShoulder", "RightElbow", "LeftElbow", "RightWrist", "LeftWrist",
	"RightHip", "LeftHip", "RightKnee", "LeftKnee", "RightAnkle", "LeftAnkle"}

---------------------------------------------------------------- actors
local actors = {}
for _, m in CastF:GetChildren() do
	local hum = m:FindFirstChildOfClass("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local A = {m = m, root = m:WaitForChild("HumanoidRootPart"), hip = m:GetAttribute("HipY") or 3, face = m.ClassicHead.face,
		head = m.ClassicHead, tracks = {}, joints = {}, name = m.Name}
	for k, id in ANIM do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, t = pcall(function() return animator:LoadAnimation(a) end)
		if ok then t.Looped = true A.tracks[k] = t end
	end
	for _, d in m:GetDescendants() do
		if (d:IsA("AnimationConstraint") or d:IsA("Motor6D")) and table.find(JOINTS, d.Name) then A.joints[d.Name] = d end
	end
	actors[m.Name] = A
end
local function anim(A, name, speed)
	for k, t in A.tracks do
		if k ~= name and t.IsPlaying then t:Stop(0) end
	end
	if name and A.tracks[name] then
		local t = A.tracks[name]
		if not t.IsPlaying then t:Play(0) end
		t:AdjustSpeed(speed or 1)
	end
	A.anim = name
end
local function setFace(A, mood)
	A.face.Texture = "rbxassetid://" .. FACES[mood]
end

---------------------------------------------------------------- props
local HP = Store:WaitForChild("HeroProps")
local props = {}
for _, p in HP:GetChildren() do props[p.Name] = p end
local fl2 = props.Flashlight:Clone()
fl2.Name = "Flashlight2"
fl2.Parent = HP
props.Flashlight2 = fl2
local give = Store.VaultKeys:FindFirstChild("Key1"):Clone()
give.Name = "GiveKey"
give.PrimaryPart = give.Bow
give.Parent = HP
props.GiveKey = give

---------------------------------------------------------------- client-side set fixes (found in the 11-02 still check)
-- hero keys: pivot on an unrotated frame so their tags face the camera (PrimaryPart = the Bow is turned 90 degrees)
for _, n in {"KeyTony", "KeyGlimmer", "KeyBlocky", "GiveKey"} do
	local k = props[n]
	k.PrimaryPart = nil
	k.WorldPivot = CFrame.new(k.Bow.Position)
end
-- the sticky note goes on the monitor (readable straight on); the desk note stays blank
do
	local nt = Store.NoteText
	nt.Size = Vector3.new(1.2, 0.04, 1.2)
	nt.CFrame = CFrame.new(20.5, 4.95, -26.0) * CFrame.Angles(rad(90), 0, 0) * CFrame.Angles(0, rad(-90), 0)
end
-- tame the brightest lights
local vg = Store:FindFirstChild("VaultGlow")
if vg then vg.PointLight.Brightness = 0.7 vg.Color = Color3.fromRGB(150, 140, 120) end
for _, p in Sets.Vehicles.VanCab.Passing:GetChildren() do
	local l = p:FindFirstChildOfClass("PointLight")
	if l then l.Brightness = 0.8 l.Range = 22 end
end
do
	local cab = Sets.Vehicles.VanCab
	local vc = CFrame.new(900, 0, 300)
	cab.Wheel.CFrame = vc * CFrame.new(-2.5, 4.3, -2.6) * CFrame.Angles(0, rad(90), 0) * CFrame.Angles(0, 0, rad(50))
	cab.Wheel.Size = Vector3.new(0.3, 2, 2)
	cab.WheelPost.CFrame = vc * CFrame.new(-2.5, 4, -2.9)
	cab.WheelPost.Size = Vector3.new(0.3, 1, 0.3)
	cab.Back.Color = Color3.fromRGB(120, 120, 130)
	cab.Roof.Color = Color3.fromRGB(150, 150, 155)
end
-- a glowing red lens on each security camera so "the cameras died" reads on screen
local camLens = {}
for _, c in Heist.Cameras:GetChildren() do
	local l = Instance.new("Part")
	l.Name = "FilmLens"
	l.Anchored = true
	l.CanCollide = false
	l.Shape = Enum.PartType.Ball
	l.Size = Vector3.new(0.7, 0.7, 0.7)
	l.Material = Enum.Material.Neon
	l.Color = Color3.fromRGB(255, 30, 30)
	l.Parent = c
	camLens[c] = l
end
for _, c in Sets.Gags.MoneyRoom:GetChildren() do
	if c.Name == "Coin" then c.Material = Enum.Material.Metal c.Color = Color3.fromRGB(235, 180, 45) end
	if c.Name == "Chandelier" then c.Material = Enum.Material.SmoothPlastic c.PointLight.Brightness = 1.2 end
end
-- house window + porch lights: dimmed for the opening thief shots (faces blew out walking past them)
local houseLights = {}
for _, f in {Sets.Town.Houses, Sets.Town.Static} do
	for _, l in f:GetDescendants() do
		if l:IsA("PointLight") then houseLights[l] = l.Brightness end
	end
end
-- Blocky kicks the blanket to the foot of the bed when he sits up (r2: he looked phased through it)
local bedFrame, blanket = Sets.Town.Props.SidewalkBed.Frame, Sets.Town.Props.SidewalkBed.Blanket
local blanketHome = {blanket.Size, blanket.CFrame}
local function blanketBack(on)
	if on then
		blanket.Size = Vector3.new(2.9, 0.9, 5)
		blanket.CFrame = bedFrame.CFrame * CFrame.new(2.65, 2.25, 0)
	else
		blanket.Size, blanket.CFrame = blanketHome[1], blanketHome[2]
	end
end
local function dimHouses(k)
	for l, b in houseLights do l.Brightness = b * k end
end
do
	local scr = props.TV:FindFirstChild("Screen")
	if scr then scr.Material = Enum.Material.SmoothPlastic scr.Color = Color3.fromRGB(70, 120, 170) end
end
-- the yellow mascot portrait set (x=1000) shows at the end of the town road: hide it while filming
local mascotSet = workspace:FindFirstChild("MascotSet")
if mascotSet then mascotSet.Parent = HIDE end
-- a street lamp stood right where Blocky's bed goes
for _, p in Sets.Town.Static:GetChildren() do
	if (p.Name == "LampPost" or p.Name == "LampHead") and math.abs(p.Position.X - 600) < 3 and p.Position.Z < 0 then
		p.Parent = HIDE
	end
end

---------------------------------------------------------------- shot state (reset at every cut)
local S = {used = {}, poses = {}, attach = {}, zzz = {}, extra = {}}
local function resetShot()
	for _, A in actors do
		if A.used then
			anim(A, nil)
			for _, j in A.joints do j.Transform = CFrame.identity end
			A.root.CFrame = OFF
			A.used = false
		end
	end
	for _, p in props do p:PivotTo(OFF) end
	props.Flashlight.Lens.Beam.Enabled = true
	props.Flashlight2.Lens.Beam.Enabled = true
	S.poses = {}
	S.attach = {}
	for _, g in S.zzz do g:Destroy() end
	S.zzz = {}
	for _, e in S.extra do e:Destroy() end
	S.extra = {}
	dimHouses(1)
	blanketBack(false)
end
-- place an actor by its FEET (cf = position on the ground + facing)
local function pos(name, cf, dy)
	local A = actors[name]
	A.used = true
	A.root.CFrame = cf * CFrame.new(0, A.hip + (dy or 0), 0)
end
-- place an actor by its root (lying down, etc.)
local function rootAt(name, cf)
	local A = actors[name]
	A.used = true
	A.root.CFrame = cf
end
local function act(name, mood, animName, speed, pose)
	local A = actors[name]
	A.used = true
	if mood then setFace(A, mood) end
	anim(A, animName, speed)
	S.poses[name] = pose
end
local function F(x, y, z, tx, tz)
	return CFrame.lookAt(Vector3.new(x, y, z), Vector3.new(tx, y, tz))
end
local function attach(prop, name, limb, off)
	table.insert(S.attach, {prop = props[prop], A = actors[name], limb = limb, off = off})
end
local function zzz(name)
	local A = actors[name]
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 80)
	bb.StudsOffset = Vector3.new(1.4, 1.6, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.Parent = A.head
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = "z Z z"
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Parent = bb
	table.insert(S.zzz, bb)
	return bb
end

-- poses (joint -> Transform). X+ on a shoulder raises the arm forward; Z+ swings the right arm out.
local function X(d) return CFrame.Angles(rad(d), 0, 0) end
local function Z(d) return CFrame.Angles(0, 0, rad(d)) end
local function Y(d) return CFrame.Angles(0, rad(d), 0) end
local function merge(...)
	local out = {}
	for _, p in {...} do for k, v in p do out[k] = v end end
	return out
end
local P = {}
P.hold = {RightShoulder = X(75), LeftShoulder = X(75), RightElbow = X(15), LeftElbow = X(15)}
P.bars = {RightShoulder = X(95) * Z(8), LeftShoulder = X(95) * Z(-8)}
P.armsUp = {RightShoulder = X(170), LeftShoulder = X(170)}
P.reach = {RightShoulder = X(80)}
P.sitChair = {RightHip = X(90), LeftHip = X(90), RightKnee = X(-90), LeftKnee = X(-90)}
P.sitGround = {RightHip = X(90), LeftHip = X(90)}
P.drive = merge(P.sitChair, {RightShoulder = X(65), LeftShoulder = X(65)})
P.cry = {RightShoulder = X(140) * Z(-30), LeftShoulder = X(140) * Z(30), RightElbow = X(40), LeftElbow = X(40), Neck = X(-12)}
P.sneak = {Waist = X(22), Neck = X(-14)}
P.lean = {Waist = X(28), RightShoulder = X(55), LeftShoulder = X(55)}
P.laugh = {Waist = X(-14), Neck = X(-18), RightShoulder = X(35) * Z(20), LeftShoulder = X(35) * Z(-20)}
P.flash = {RightShoulder = X(80)}
P.scared = {RightShoulder = X(50) * Z(25), LeftShoulder = X(50) * Z(-25), Waist = X(-8)}
P.bagFront = {RightShoulder = X(45), LeftShoulder = X(45)}

---------------------------------------------------------------- world state
local function hideIt(inst, on)
	if on then
		if inst.Parent ~= HIDE then inst:SetAttribute("Orig", inst.Parent:GetFullName()) inst:SetAttribute("_p", true) end
		if not S.home then S.home = {} end
		if not S.home[inst] then S.home[inst] = inst.Parent end
		inst.Parent = HIDE
	else
		if S.home and S.home[inst] then inst.Parent = S.home[inst] end
	end
end
local Town = Sets.Town
local townHouses = Town.Houses:GetChildren()
local bedM, reclinerM = Town.Props.SidewalkBed, Town.Props.Recliner
local afterProps = {}
for _, c in Town.Props:GetChildren() do table.insert(afterProps, c) end
local vaultDoor, vaultWheel = Heist.Props.VaultDoor, Heist.Props.VaultWheel
local doorHome, wheelHome = vaultDoor:GetAttribute("Home"), vaultWheel:GetAttribute("Home")
local keyModels = Store.VaultKeys:GetChildren()
local rngK = Random.new(11)
for i = #keyModels, 2, -1 do
	local j = rngK:NextInteger(1, i)
	keyModels[i], keyModels[j] = keyModels[j], keyModels[i]
end
local crashGlass
for _, g in Heist.Props:GetChildren() do
	if g.Name == "CaseGlass" and (g.Position - Vector3.new(-10, 4.4, 4)).Magnitude < 1 then crashGlass = g end
end
local lever = {pivot = Store.LeverPivot, arm = Store.LeverArm, knob = Store.LeverKnob}
local leverPivotCF = lever.pivot:GetAttribute("Home")
local leverArmRel = leverPivotCF:ToObjectSpace(lever.arm:GetAttribute("Home"))
local leverKnobRel = leverPivotCF:ToObjectSpace(lever.knob:GetAttribute("Home"))
local screen = Store.KeypadFace:FindFirstChildOfClass("SurfaceGui").Screen
local van = Heist.Van
local vanHome = van:GetPivot()
local truck = Sets.Vehicles.Truck
local truckHome = truck:GetPivot()
local cars = {Sets.Vehicles.CopCar1, Sets.Vehicles.CopCar2, Sets.Vehicles.CopCar3}
local carHome = {}
for i, c in cars do carHome[i] = c:GetPivot() end
local dog = Sets.Gags.DogYard.Dog
local lotHouse = Sets.Lot.Houses.BlockyLotHouse
local lotDoor = lotHouse.Door
local lotDoorHome = lotDoor:GetAttribute("Home")
local lotDoorKids = {}
for _, c in lotDoor:GetChildren() do
	if c:IsA("BasePart") then lotDoorKids[c] = lotDoorHome:ToObjectSpace(c.CFrame) end
end
local passing = Sets.Vehicles.VanCab.Passing
local passHome = {}
for _, p in passing:GetChildren() do passHome[p] = p.CFrame end

local W = {}
local DEFAULT = {houses = true, bed = false, power = true, alarm = false, vault = 0, keys = 1, glass = true, lever = 0, screen = "----"}
local function setPower(on)
	for _, c in Heist.Cameras:GetChildren() do
		c.Beam.Enabled = on
		c.Led.Enabled = on
		c.Color = on and Color3.fromRGB(235, 235, 240) or Color3.fromRGB(120, 120, 125)
		local lens = c:FindFirstChild("FilmLens")
		if lens then
			lens.CFrame = c.CFrame * CFrame.new(0, 0, -1.25)
			lens.Color = on and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(25, 25, 28)
			lens.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		end
	end
	for _, l in Heist.Lasers:GetChildren() do l.Transparency = on and 0 or 1 end
	for _, p in Heist.StoreLights:GetChildren() do
		local l = p:FindFirstChildOfClass("PointLight")
		if l then l.Brightness = on and 0.9 or 0.18 end
		p.Color = on and Color3.fromRGB(255, 240, 210) or Color3.fromRGB(90, 85, 80)
	end
end
local function setKeys(frac)
	local keep = math.floor(#keyModels * frac + 0.5)
	for i, k in keyModels do hideIt(k, i > keep) end
end
local function setVault(u)
	local hinge = doorHome * CFrame.new(-3, 0, 0) -- left edge of the door (x = -23)
	local cf = hinge * CFrame.Angles(0, rad(-105 * u), 0) * CFrame.new(3, 0, 0)
	vaultDoor.CFrame = cf
	vaultWheel.CFrame = cf * doorHome:ToObjectSpace(wheelHome)
end
local function setLever(u)
	local p = leverPivotCF * CFrame.Angles(0, 0, rad(55 - 110 * u))
	lever.arm.CFrame = p * leverArmRel
	lever.knob.CFrame = p * leverKnobRel
end
local function setLotDoor(u)
	local hinge = lotDoorHome * CFrame.new(-2, 0, 0)
	local cf = hinge * CFrame.Angles(0, rad(-100 * u), 0) * CFrame.new(2, 0, 0)
	lotDoor.CFrame = cf
	for c, rel in lotDoorKids do c.CFrame = cf * rel end
end
local function world(w)
	local want = {}
	for k, v in DEFAULT do want[k] = v end
	for k, v in (w or {}) do want[k] = v end
	if W.houses ~= want.houses then
		for _, h in townHouses do hideIt(h, not want.houses) end
		for _, p in afterProps do hideIt(p, want.houses) end
	end
	if W.bed ~= want.bed then
		hideIt(bedM, not want.bed)
		hideIt(reclinerM, not want.bed)
	end
	if W.power ~= want.power then setPower(want.power) end
	if W.keys ~= want.keys then setKeys(want.keys) end
	if W.vault ~= want.vault then setVault(want.vault) end
	if W.lever ~= want.lever then setLever(want.lever) end
	if W.glass ~= want.glass and crashGlass then crashGlass.Transparency = want.glass and 0.75 or 1 end
	if W.alarm ~= want.alarm then
		for _, p in Heist.AlarmLights:GetChildren() do
			local l = p:FindFirstChildOfClass("PointLight")
			if l then l.Enabled = want.alarm end
			p.Color = Color3.fromRGB(90, 0, 0)
		end
	end
	screen.Text = want.screen
	screen.TextColor3 = Color3.fromRGB(90, 255, 120)
	W = want
end

---------------------------------------------------------------- lighting
local CC = Lighting:FindFirstChild("FilmCC") or Instance.new("ColorCorrectionEffect")
CC.Name = "FilmCC"
CC.Parent = Lighting
local BL = Lighting:FindFirstChild("FilmBloom") or Instance.new("BloomEffect")
BL.Name = "FilmBloom"
BL.Threshold = 1.6
BL.Size = 22
BL.Parent = Lighting
local SR = Lighting:FindFirstChild("FilmRays") or Instance.new("SunRaysEffect")
SR.Name = "FilmRays"
SR.Parent = Lighting
local ATMO = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
local C = Color3.fromRGB
local LP = {
	night = {ClockTime = 0.3, Brightness = 1.5, Ambient = C(75, 78, 110), OutdoorAmbient = C(135, 140, 190), Exposure = -0.05,
		Density = 0.22, Haze = 0.4, AColor = C(95, 105, 155), Decay = C(55, 60, 95), Sat = 0.18, Contrast = 0.12, Tint = C(235, 240, 255), Bloom = 0.25, Rays = 0},
	store = {ClockTime = 0.3, Brightness = 1.2, Ambient = C(80, 78, 90), OutdoorAmbient = C(95, 100, 145), Exposure = -0.35,
		Density = 0.15, Haze = 0.2, AColor = C(95, 105, 155), Decay = C(55, 60, 95), Sat = 0.2, Contrast = 0.12, Tint = C(255, 248, 240), Bloom = 0.25, Rays = 0},
	dark = {ClockTime = 0.3, Brightness = 1, Ambient = C(60, 60, 80), OutdoorAmbient = C(80, 85, 125), Exposure = -0.3,
		Density = 0.15, Haze = 0.2, AColor = C(80, 90, 140), Decay = C(40, 45, 80), Sat = 0.15, Contrast = 0.15, Tint = C(230, 235, 255), Bloom = 0.3, Rays = 0},
	interior = {ClockTime = 0.3, Brightness = 1.2, Ambient = C(100, 96, 110), OutdoorAmbient = C(120, 125, 170), Exposure = -0.15,
		Density = 0.1, Haze = 0, AColor = C(95, 105, 155), Decay = C(55, 60, 95), Sat = 0.2, Contrast = 0.1, Tint = C(255, 245, 235), Bloom = 0.25, Rays = 0},
	predawn = {ClockTime = 5.6, Brightness = 1.8, Ambient = C(100, 85, 115), OutdoorAmbient = C(160, 125, 155), Exposure = 0,
		Density = 0.28, Haze = 1.0, AColor = C(220, 150, 170), Decay = C(130, 90, 140), Sat = 0.2, Contrast = 0.1, Tint = C(255, 235, 235), Bloom = 0.6, Rays = 0.05},
	sunrise = {ClockTime = 6.35, Brightness = 2.4, Ambient = C(120, 98, 90), OutdoorAmbient = C(200, 150, 120), Exposure = -0.15,
		Density = 0.3, Haze = 1.4, AColor = C(255, 170, 115), Decay = C(210, 120, 85), Sat = 0.25, Contrast = 0.1, Tint = C(255, 225, 195), Bloom = 0.3, Rays = 0.12},
	morning = {ClockTime = 9, Brightness = 3, Ambient = C(120, 120, 125), OutdoorAmbient = C(155, 155, 160), Exposure = 0.05,
		Density = 0.18, Haze = 0.5, AColor = C(200, 215, 240), Decay = C(140, 160, 200), Sat = 0.25, Contrast = 0.08, Tint = C(255, 250, 245), Bloom = 0.4, Rays = 0.05},
}
local function lerpV(a, b, u)
	if typeof(a) == "number" then return a + (b - a) * u end
	return a:Lerp(b, u)
end
local function light(a, b, u)
	local A, B = LP[a], LP[b or a]
	u = u or 0
	local function g(k) return lerpV(A[k], B[k], u) end
	Lighting.ClockTime = g("ClockTime")
	Lighting.Brightness = g("Brightness")
	Lighting.Ambient = g("Ambient")
	Lighting.OutdoorAmbient = g("OutdoorAmbient")
	Lighting.ExposureCompensation = g("Exposure")
	Lighting.GlobalShadows = true
	ATMO.Density = g("Density")
	ATMO.Haze = g("Haze")
	ATMO.Color = g("AColor")
	ATMO.Decay = g("Decay")
	CC.Saturation = g("Sat")
	CC.Contrast = g("Contrast")
	CC.TintColor = g("Tint")
	BL.Intensity = g("Bloom")
	SR.Intensity = g("Rays")
end

---------------------------------------------------------------- camera
local cam = workspace.CurrentCamera
local camCF, camFov = CFrame.new(), 50
local shake = 0
local function ease(u) return u * u * (3 - 2 * u) end
local function camMove(e1, l1, e2, l2, u, fov)
	u = ease(math.clamp(u, 0, 1))
	local e = e1:Lerp(e2 or e1, u)
	local l = l1:Lerp(l2 or l1, u)
	camCF = CFrame.lookAt(e, l)
	camFov = fov or 50
end
local V = Vector3.new

---------------------------------------------------------------- effects
local function shards(center, n)
	local list = {}
	local rng = Random.new(5)
	for i = 1, n do
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.Size = V(rng:NextNumber(0.2, 0.7), rng:NextNumber(0.2, 0.7), 0.06)
		p.Color = Color3.fromRGB(200, 230, 255)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.35
		p.Parent = workspace
		table.insert(S.extra, p)
		table.insert(list, {p = p, v = V(rng:NextNumber(-9, 9), rng:NextNumber(4, 13), rng:NextNumber(-9, 9)),
			r = V(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)), c = center + V(rng:NextNumber(-2.5, 2.5), rng:NextNumber(0, 1.6), rng:NextNumber(-1.4, 1.4))})
	end
	return list
end
local function stepShards(list, t)
	for _, s in list do
		local pos = s.c + s.v * t + V(0, -40 * t * t / 2, 0)
		if pos.Y < 0.5 then pos = V(pos.X, 0.5, pos.Z) end
		s.p.CFrame = CFrame.new(pos) * CFrame.Angles(s.r.X * t, s.r.Y * t, s.r.Z * t)
	end
end
local function coins(n)
	local list = {}
	local rng = Random.new(9)
	for i = 1, n do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.CanCollide = false
		p.Size = V(0.2, 1.2, 1.2)
		p.Color = Color3.fromRGB(255, 196, 40)
		p.Material = Enum.Material.Foil
		p.Parent = workspace
		table.insert(S.extra, p)
		table.insert(list, {p = p, t0 = rng:NextNumber(0, 1.6), v = V(rng:NextNumber(-5, 5), rng:NextNumber(10, 16), rng:NextNumber(0, 5)), spin = rng:NextNumber(5, 12)})
	end
	return list
end
local function flashCars(t)
	for i, c in cars do
		local on = math.floor(t * 6 + i) % 2 == 0
		c.RedLight.Glow.Enabled = on
		c.BlueLight.Glow.Enabled = not on
		c.RedLight.Color = on and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(90, 10, 10)
		c.BlueLight.Color = on and Color3.fromRGB(20, 30, 90) or Color3.fromRGB(60, 120, 255)
	end
end
local function carAt(i, x, z, yaw)
	cars[i]:PivotTo(CFrame.new(x, carHome[i].Y + 0.2, z) * CFrame.Angles(0, rad(yaw), 0))
end
local function vanAt(x, y, z, yaw)
	van:PivotTo(CFrame.new(x, vanHome.Y + y, z) * CFrame.Angles(0, rad(yaw), 0))
end
local function truckAt(x, z)
	truck:PivotTo(CFrame.new(x, truckHome.Y + 0.2, z))
end
local function passLamps(speed, t)
	for p, home in passHome do
		local dz = (t * speed) % 40
		p.CFrame = home + V(0, 0, dz)
	end
end
local function resetVehicles()
	van:PivotTo(vanHome)
	truck:PivotTo(truckHome)
	for i, c in cars do c:PivotTo(carHome[i]) end
	setLotDoor(0)
end

---------------------------------------------------------------- the shot list (times = narration seconds)
local G = V(600, 0, 500)
local SH = {}
local function shot(t, light_, setup, update)
	table.insert(SH, {t = t, light = light_, setup = setup, update = update})
end

-- 1. In this world, stealing is not a crime.
shot(0.00, "night", function()
	world({})
	dimHouses(0.2)
	act("Thief", "happy", "walk", 0.8, P.hold)
	attach("TV", "Thief", "UpperTorso", CFrame.new(0, -0.7, -1.7))
	act("Cop1", "happy", "idle")
end, function(T, u)
	pos("Thief", F(612 + u * 8, 0.6, -13.2, 700, -13.2))
	pos("Cop1", F(626, 0.6, -13.6, 600, -13.6))
	S.poses.Cop1 = {RightShoulder = Z(150 + 18 * math.sin(T * 14))}
	camMove(V(632, 3.8, -1), V(620.5, 4.4, -13.4), V(630.5, 3.9, -3), V(621, 4.5, -13.4), u, 60)
end)
-- 2. If you steal something and get it home before the sun comes up,
shot(1.70, "night", function()
	world({})
	dimHouses(0.2)
	act("Thief", "sneaky", "run", 1.3, P.hold)
	attach("TV", "Thief", "UpperTorso", CFrame.new(0, -0.7, -1.7))
end, function(T, u)
	light("night", "predawn", u)
	local x = 632 + u * 46
	pos("Thief", F(x, 0.6, -13.2, x + 50, -13.2))
	camMove(V(x - 7, 4, -4), V(x + 2, 3.6, -13.2), nil, nil, 0, 55)
end)
-- 3. it's yours. Forever.
shot(4.00, "sunrise", function()
	world({})
	dimHouses(0.1)
	act("Thief", "laugh", "idle", 1, P.hold)
	attach("TV", "Thief", "UpperTorso", CFrame.new(0, -0.7, -1.7))
end, function(T, u)
	pos("Thief", F(680, 0.8, -22.4, 680, 0) * CFrame.new(0, math.abs(math.sin(T * 7)) * 0.25, 0))
	camMove(V(680, 4.6, -12), V(680, 4.6, -22), V(680, 4.5, -15.5), V(680, 4.6, -22), u, 50)
end)
-- 4. But if you get caught on the way, you go to jail.
shot(5.55, "night", function()
	world({})
	act("Prisoner", "sad", nil, 1, P.bars)
	act("Cop2", "angry", "idle")
end, function(T, u)
	pos("Prisoner", F(-60.75, 0.6, 62.2, -60.75, 80))
	pos("Cop2", F(-55.5, 0, 66.5, -60, 60))
	camMove(V(-61.5, 5, 72), V(-60.75, 4.9, 62), V(-60.9, 5, 68.6), V(-60.75, 4.9, 62), u, 45)
end)
-- 5. So everybody sleeps on top of their stuff.
shot(7.90, "interior", function()
	world({})
	act("Sleeper", "sleep", nil)
	zzz("Sleeper")
end, function(T, u)
	rootAt("Sleeper", CFrame.fromMatrix(V(G.X - 1.8, 8.3 + math.sin(T * 3) * 0.05, G.Z - 5), V(0, 0, 1), V(-1, 0, 0)))
	camMove(V(G.X - 1, 11, G.Z + 7), V(G.X - 1.5, 7, G.Z - 5), V(G.X - 1.4, 10.4, G.Z + 3.5), V(G.X - 1.6, 7.4, G.Z - 5), u, 50)
end)
-- 6. Fridges have locks.
shot(9.60, "interior", function()
	world({})
	act("Kid1", "sad", "idle")
end, function(T, u)
	pos("Kid1", F(G.X + 44.5, 0, G.Z - 6.5, G.X + 40, G.Z - 10))
	camMove(V(G.X + 40.5, 6.4, G.Z + 3), V(G.X + 40, 5.6, G.Z - 10), V(G.X + 40.2, 6, G.Z - 2), V(G.X + 40, 5.5, G.Z - 10), u, 50)
end)
-- 7. Dogs have locks.
shot(10.65, "interior", function()
	world({})
	dog:PivotTo(CFrame.new(G.X + 78, 2.8, G.Z - 2) * CFrame.Angles(0, rad(200), 0))
end, function(T, u)
	local tail = dog:FindFirstChild("Tail")
	camMove(V(G.X + 79, 4.8, G.Z + 9), V(G.X + 78.4, 3.6, G.Z - 0.5), V(G.X + 78.8, 4.5, G.Z + 6.5), V(G.X + 78.4, 3.6, G.Z - 0.5), u, 50)
end)
-- 8. Kids take sneaking class at school.
shot(11.70, "interior", function()
	world({})
	for i = 1, 4 do act("Kid" .. i, "sneaky", "walk", 0.45, P.sneak) end
	act("Teacher", "sneaky", "idle", 1, {RightShoulder = X(150) * Z(-35), RightElbow = X(70)})
end, function(T, u)
	for i = 1, 4 do
		local x = G.X + 107 + u * 6 + (i - 1) * 3
		pos("Kid" .. i, F(x, 0, G.Z - 6, x + 10, G.Z - 6))
	end
	pos("Teacher", F(G.X + 129.5, 0, G.Z - 12, G.X + 120, G.Z + 10))
	camMove(V(G.X + 117, 6.5, G.Z + 12), V(G.X + 119, 6, G.Z - 10), V(G.X + 117.5, 6, G.Z + 8), V(G.X + 119, 6, G.Z - 10), u, 55)
end)
-- 9. And there's one store nobody has ever robbed.
shot(13.40, "store", function() world({}) end, function(T, u)
	camMove(V(0, 4.5, 60), V(0, 9, 20), V(0, 6, 44), V(0, 10.5, 20), u, 55)
end)
-- 10. Glimmer and Co. Jewelers.
shot(15.40, "store", function() world({}) end, function(T, u)
	camMove(V(-11, 12.5, 31), V(-5, 15.5, 21), V(7, 13, 31), V(3, 15.5, 21), u, 45)
end)
-- 11. Two guards who never sleep.
shot(16.75, "store", function()
	world({})
	act("Tony", "angry", "idle", 1, P.flash)
	act("Guard2", "angry", "idle", 1, P.flash)
	attach("Flashlight", "Tony", "RightHand", CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, rad(90), 0))
	attach("Flashlight2", "Guard2", "RightHand", CFrame.new(0, -0.5, -0.4) * CFrame.Angles(0, rad(90), 0))
end, function(T, u)
	pos("Tony", F(-4.5, 0.45, 8, -4.5, 30))
	pos("Guard2", F(4.5, 0.45, 9, 4.5, 30))
	camMove(V(0, 6.2, 21), V(0, 5.6, 8.5), V(0, 6, 18.5), V(0, 5.6, 8.5), u, 60)
end)
-- 12. Cameras on every wall.
shot(17.95, "store", function() world({}) end, function(T, u)
	local c = Heist.Cameras.Cam1
	local home = c:GetAttribute("Home")
	c.CFrame = CFrame.lookAt(home.Position, V(-14 + math.sin(T * 1.6) * 9, 0, 4))
	camMove(V(-33.5, 12.4, 14), V(-38.5, 14, 18.5), V(-34.6, 12.8, 15.2), V(-38.5, 14, 18.5), u, 45)
end)
-- 13. Red lasers.
shot(19.15, "store", function() world({}) end, function(T, u)
	for i, l in Heist.Lasers:GetChildren() do l.Transparency = 0.15 + 0.15 * math.sin(T * 10 + i) end
	camMove(V(-15, 3.4, -1.5), V(-17, 3.6, -7.6), V(-15.6, 3.6, -3.4), V(-17, 3.6, -7.6), u, 50)
end)
-- 14. And a vault with a new code every night.
shot(19.95, "store", function() world({}) end, function(T, u)
	local r = Random.new(math.floor(T * 5))
	screen.Text = string.format("%04d", r:NextInteger(0, 9999))
	camMove(V(-12.5, 6.5, -15.5), V(-17.5, 5.5, -28), V(-14.5, 6, -20), V(-16.5, 5.5, -28), u, 50)
end)
-- 15. Blocky never cared about any of it.
shot(21.65, "interior", function()
	world({})
	act("Blocky", "sleep", nil)
	zzz("Blocky")
end, function(T, u)
	rootAt("Blocky", CFrame.fromMatrix(V(G.X + 156.6, 3.15 + math.sin(T * 3) * 0.04, G.Z - 11.4), V(0, 0, 1), V(-1, 0, 0)))
	camMove(V(G.X + 157.5, 8, G.Z - 3), V(G.X + 157, 3.5, G.Z - 11.4), V(G.X + 157.2, 7, G.Z - 6), V(G.X + 156.8, 3.6, G.Z - 11.4), u, 50)
end)
-- 16. Until the night he woke up on the sidewalk.
shot(23.65, "night", function()
	world({houses = false, bed = true})
	act("Blocky", "sleep", nil)
end, function(T, u)
	if T > 24.37 then setFace(actors.Blocky, "shocked") end
	rootAt("Blocky", CFrame.fromMatrix(V(598.8, 3.75, -13), V(0, 0, 1), V(-1, 0, 0)))
	local sh = T > 24.37 and T < 24.7 and V(math.sin(T * 90) * 0.12, 0, 0) or V()
	camMove(V(601.5, 8.6, -13) + sh, V(597.3, 3.9, -13), V(600.4, 7.4, -13) + sh, V(597.3, 3.9, -13), u, 50)
end)
-- 17. Still in his bed.
shot(25.45, "night", function()
	world({houses = false, bed = true})
	act("Blocky", "shocked", nil)
end, function(T, u)
	rootAt("Blocky", CFrame.fromMatrix(V(598.8, 3.75, -13), V(0, 0, 1), V(-1, 0, 0)))
	camMove(V(604, 12, 0), V(599, 2.6, -13.5), V(603, 11, -2), V(599, 2.6, -13.5), u, 55)
end)
-- 18. Someone had stolen his house.
shot(26.30, "night", function()
	world({houses = false, bed = true})
	act("Blocky", "shocked", nil, 1, P.sitChair)
	blanketBack(true)
end, function(T, u)
	pos("Blocky", F(599.4, 3.2, -14.6, 599.4, -40), -2.1)
	camMove(V(599.6, 9.5, -7), V(599.4, 0.5, -32), V(599.5, 9.8, -9), V(599.4, 0.5, -33), u, 55)
end)
-- 19. Right out from around him.
shot(27.85, "night", function()
	world({houses = false, bed = true})
	act("Blocky", "scared", nil, 1, merge(P.sitChair, {RightShoulder = X(30) * Z(25), LeftShoulder = X(30) * Z(-25)}))
	blanketBack(true)
end, function(T, u)
	pos("Blocky", F(599.4, 3.2, -14.6, 599.4, -40), -2.1)
	local a = rad(-25 + 50 * ease(u))
	local e = V(599.4 + math.sin(a) * 7, 5.4, -14.6 - math.cos(a) * 7)
	camMove(e, V(599.4, 4.4, -14.6), nil, nil, 0, 50)
end)
-- 20. His little sister Pip was crying.
shot(29.30, "night", function()
	world({houses = false, bed = true})
	act("Pip", "sad", nil, 1, P.cry)
	act("Blocky", "sad", nil, 1, P.sitChair)
	blanketBack(true)
end, function(T, u)
	-- on the grass in front of the bed (r2: she stood inside the headboard)
	pos("Pip", F(603.6, 0, -18, 603.6, -40) * CFrame.new(0, math.abs(math.sin(T * 9)) * 0.08, 0))
	pos("Blocky", F(599.4, 3.2, -14.6, 599.4, -40), -2.1)
	camMove(V(604.2, 4.2, -25), V(602.6, 2.9, -15), V(603.9, 3.9, -23), V(602.8, 3, -15), u, 50)
end)
-- 21. Grandma was still snoring in her chair.
shot(30.85, "night", function()
	world({houses = false, bed = true})
	act("Grandma", "sleep", nil, 1, P.sitChair)
	zzz("Grandma")
	blanketBack(true)
end, function(T, u)
	local seat = CFrame.new(608, 0.6, -13) * CFrame.Angles(0, rad(-20), 0) * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.pi, 0)
	pos("Grandma", seat * CFrame.new(0, 2.4, 0) * CFrame.Angles(rad(-12), 0, 0), -2.05 + math.sin(T * 2.6) * 0.04)
	camMove(V(605.5, 5.2, -4.5), V(608, 4.6, -13), V(606.4, 5, -7.2), V(608, 4.6, -13), u, 50)
end)
-- 22. And down the street, a giant truck was driving away with their house on the back.
shot(32.45, "night", function()
	world({houses = false, bed = true})
	act("Blocky", "shocked", "idle")
	act("Pip", "sad", "idle")
	blanketBack(true)
end, function(T, u)
	pos("Blocky", F(598, 0.2, -7, 700, -4))
	pos("Pip", F(595.5, 0.2, -5.8, 700, -4))
	truckAt(642 + u * 95, -4)
	camMove(V(588.5, 5.8, -6.4), V(650, 5, -4), V(589.5, 5.9, -6.4), V(700, 6, -4), u, 50)
end)
-- 23. The name on the truck? Glimmer.
shot(35.85, "night", function()
	world({houses = false, bed = true})
end, function(T, u)
	local x = 678.5 + (T - 37.3) * 8
	truckAt(x, -4)
	camMove(V(700, 5.4, -27), V(x + 21.5, 7, -4), nil, nil, 0, 55)
end)
-- 24. Every house on the street was gone.
local FAM = {{"Fam1", 580, -20}, {"Fam2", 583.2, -20.6}, {"Fam7", 586.4, -19.8}, {"Fam3", 640, -19.5}, {"Fam4", 643.2, -20.4},
	{"Fam5", 560, 20}, {"Fam6", 563.4, 20.6}, {"Fam8", 680, 20}}
shot(38.05, "night", function()
	world({houses = false, bed = true})
	for _, f in FAM do act(f[1], "sad", nil, 1, P.sitGround) end
	act("Grandma", "sleep", nil, 1, P.sitChair)
	act("Pip", "sad", "idle")
end, function(T, u)
	for _, f in FAM do pos(f[1], F(f[2], 0, f[3], f[2], 0), -2.0) end
	local seat = CFrame.new(608, 0.6, -13) * CFrame.Angles(0, rad(-20), 0) * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.pi, 0)
	pos("Grandma", seat * CFrame.new(0, 2.4, 0) * CFrame.Angles(rad(-12), 0, 0), -2.05)
	pos("Pip", F(594.5, 0.6, -15, 594.5, 10))
	camMove(V(640, 24, 46), V(612, 0, -12), V(632, 38, 60), V(610, 0, -14), u, 55)
end)
-- 25. Families sat on the grass in their pajamas.
shot(39.80, "night", function()
	world({houses = false, bed = true})
	for _, f in FAM do act(f[1], "sad", nil, 1, P.sitGround) end
	setFace(actors.Fam1, "shocked")
end, function(T, u)
	for _, f in FAM do pos(f[1], F(f[2], 0, f[3], f[2], 0), -2.0) end
	camMove(V(583.2, 3.4, -11), V(583.2, 2.2, -20), V(583.2, 3.2, -13.5), V(583.2, 2.2, -20), u, 50)
end)
-- 26. Now everyone knew how Mr. Glimmer got so rich.
local coinList
shot(42.00, "interior", function()
	world({})
	act("Glimmer", "laugh", nil, 1, P.laugh)
	coinList = coins(14)
end, function(T, u)
	local t = T - 42.0
	pos("Glimmer", F(G.X + 200, 4.3, G.Z - 4, G.X + 200, G.Z + 20) * CFrame.new(0, math.abs(math.sin(T * 6)) * 0.2, 0))
	for _, c in coinList do
		local tt = (t - c.t0) % 1.6
		local p0 = V(G.X + 200, 9, G.Z - 3.5)
		c.p.CFrame = CFrame.new(p0 + c.v * tt + V(0, -30 * tt * tt / 2, 0)) * CFrame.Angles(c.spin * tt, 0, 1)
	end
	camMove(V(G.X + 200, 5.2, G.Z + 11), V(G.X + 200, 7.4, G.Z - 4), V(G.X + 200, 5, G.Z + 7), V(G.X + 200, 7.4, G.Z - 4), u, 50)
end)
-- 27. So the next night, Blocky snuck in.
shot(44.45, "night", function()
	world({})
	act("Blocky", "sneaky", "walk", 0.55, P.sneak)
end, function(T, u)
	local z = 12 - u * 12
	pos("Blocky", F(47, 0.6, z, 47, z - 20))
	camMove(V(53, 4.2, 18), V(47, 3.5, 4), V(52, 4, 14), V(47, 3.4, -2), u, 50)
end)
-- 28. Through the back alley.
shot(46.15, "night", function()
	world({})
	act("Blocky", "sneaky", "walk", 0.55, P.sneak)
end, function(T, u)
	local x = 52 - u * 12
	pos("Blocky", F(x, 0.2, -44.5, x - 20, -44.5))
	camMove(V(31, 4.4, -42.8), V(44, 3.2, -44.5), V(32, 4.2, -43), V(41, 3.2, -44.5), u, 50)
end)
-- 29. Past the guards.
shot(47.10, "store", function()
	world({})
	act("Blocky", "sneaky", "walk", 0.55, P.sneak)
	act("Guard2", "angry", "walk", 0.8, P.flash)
	attach("Flashlight2", "Guard2", "RightHand", CFrame.new(0, -0.5, -0.4) * CFrame.Angles(0, rad(90), 0))
end, function(T, u)
	pos("Blocky", F(13 + u * 6, 0.4, -30, 40, -30))
	pos("Guard2", F(26, 0.4, -13 + u * 3, 26, 20))
	camMove(V(8, 4.6, -35), V(19, 3.6, -20), V(9, 4.5, -34), V(20, 3.6, -20), u, 55)
end)
-- 30. He pulled the big switch on the breaker box.
shot(48.15, "store", function()
	world({})
	act("Blocky", "sneaky", nil, 1)
end, function(T, u)
	local pull = math.clamp((T - 49.15) / 0.25, 0, 1)
	setLever(pull)
	S.poses.Blocky = {RightShoulder = X(150 - 70 * pull) * Z(-10)}
	if pull >= 1 then setFace(actors.Blocky, "happy") end
	pos("Blocky", F(36.4, 0.4, -18.3, 39.5, -17.6))
	camMove(V(33, 6.3, -22), V(38.6, 5.5, -17.6), V(34, 6, -21), V(38.6, 5.5, -17.6), u, 50)
end)
-- 31. The cameras died.
shot(50.05, "store", function() world({}) end, function(T, u)
	local on = T < 50.6 or (T < 50.85 and math.floor(T * 20) % 2 == 0)
	setPower(on)
	camMove(V(33, 11.6, 1.5), V(38.4, 14, -4.6), V(34, 12, 0.2), V(38.4, 14, -4.6), u, 45)
end)
-- 32. The lasers blinked off.
shot(51.05, "dark", function() world({power = false}) end, function(T, u)
	local on = T < 51.6 or (T < 51.95 and math.floor(T * 16) % 2 == 0)
	for _, l in Heist.Lasers:GetChildren() do l.Transparency = on and 0.1 or 1 end
	camMove(V(-15, 3.4, -1.5), V(-17, 3.6, -7.6), V(-15.6, 3.6, -3.4), V(-17, 3.6, -7.6), u, 50)
end)
-- 33. Then he found the vault code.
shot(52.25, "dark", function()
	world({power = false, lever = 1})
	act("Blocky", "sneaky", nil, 1, P.lean)
end, function(T, u)
	pos("Blocky", F(20, 0.4, -20.3, 20, -30))
	camMove(V(13.5, 6, -15.5), V(20, 4, -23), V(15.5, 5.6, -17), V(20, 4, -23), u, 50)
end)
-- 34. On a sticky note.
shot(53.90, "dark", function() world({power = false, lever = 1}) end, function(T, u)
	camMove(V(20.5, 5.1, -22.6), V(20.5, 4.95, -26), V(20.5, 5.0, -23.6), V(20.5, 4.95, -26), u, 45)
end)
-- 35. The safest store in the world, and the code was on a sticky note.
shot(54.90, "dark", function()
	world({power = false, lever = 1})
	act("Blocky", "sneaky", "idle")
end, function(T, u)
	pos("Blocky", F(21.5, 0.4, -20.6, 21.5, 0))
	camMove(V(21.5, 5.1, -14.5), V(21.5, 4.8, -20.6), V(21.5, 4.9, -16.6), V(21.5, 4.8, -20.6), u, 50)
end)
-- 36. Beep. Beep. Beep. Beep.
shot(57.75, "dark", function()
	world({power = false, lever = 1})
	act("Blocky", "sneaky", nil, 1, P.reach)
end, function(T, u)
	local code = "4821"
	local n = (T >= 59.23 and 4) or (T >= 58.7 and 3) or (T >= 58.24 and 2) or (T >= 57.82 and 1) or 0
	screen.Text = code:sub(1, n) .. string.rep("-", 4 - n)
	if T > 59.6 then screen.Text = "OPEN" end
	local poke = math.max(0, 1 - ((T - 57.82) % 0.45) * 6)
	S.poses.Blocky = {RightShoulder = X(78 + 6 * poke)}
	pos("Blocky", F(-12.6, 0.4, -25.6, -15, -28))
	camMove(V(-15.3, 5.7, -24.2), V(-15, 5.5, -27.45), V(-15.2, 5.6, -25.1), V(-15, 5.5, -27.45), u, 45)
end)
-- 37. The vault swung open.
shot(60.05, "dark", function() world({power = false, lever = 1, screen = "OPEN"}) end, function(T, u)
	local spin = math.clamp((T - 60.05) / 0.4, 0, 1)
	local open = math.clamp((T - 60.4) / 0.8, 0, 1)
	setVault(ease(open))
	vaultWheel.CFrame = vaultWheel.CFrame * CFrame.Angles(rad(360 * spin), 0, 0)
	camMove(V(-12, 6, -14), V(-20, 5, -28), V(-13, 5.8, -16), V(-20, 5, -28), u, 50)
end)
-- 38. Blocky expected diamonds.
shot(61.20, "dark", function()
	world({power = false, lever = 1, vault = 1, screen = "OPEN"})
	act("Blocky", "happy", nil, 1, {RightShoulder = X(40) * Z(30), LeftShoulder = X(40) * Z(-30)})
end, function(T, u)
	pos("Blocky", F(-20, 0.4, -25, -20, -40) * CFrame.new(0, math.abs(math.sin(T * 8)) * 0.15, 0))
	camMove(V(-20, 4.9, -31.5), V(-20, 4.8, -25), V(-20, 4.85, -30), V(-20, 4.8, -25), u, 50)
end)
-- 39. But the vault was full of keys. Thousands of them.
shot(62.65, "dark", function()
	world({power = false, lever = 1, vault = 1, screen = "OPEN"})
	act("Blocky", "shocked", "idle")
end, function(T, u)
	pos("Blocky", F(-20, 0.4, -26.5, -20, -40))
	camMove(V(-19, 6.2, -20.5), V(-20, 5.5, -37), V(-19.5, 7.5, -23.5), V(-20, 5.8, -37), u, 55)
end)
-- 40. Each one had a tag with a name on it.
shot(65.25, "dark", function() world({power = false, lever = 1, vault = 1}) end, function(T, u)
	camMove(V(-28, 6, -35.6), V(-28, 6, -38.85), V(-13, 6, -35.6), V(-13, 6, -38.85), u, 42)
end)
-- 41. Every house Mr. Glimmer had ever stolen.
shot(67.00, "dark", function()
	world({power = false, lever = 1, vault = 1})
	act("Blocky", "sad", "idle")
end, function(T, u)
	if T > 68.2 then setFace(actors.Blocky, "angry") end
	pos("Blocky", F(-25, 0.4, -33, -25, -45))
	camMove(V(-26.5, 5, -36.4), V(-25, 4.7, -33), V(-26.2, 4.9, -35.8), V(-25, 4.7, -33), u, 50)
end)
-- 42. Blocky's bag could hold the diamonds.
shot(68.95, "dark", function() world({power = false, lever = 1, vault = 1}) end, function(T, u)
	local d = Heist.Loot:FindFirstChild("Diamond")
	if d then d.CFrame = CFrame.new(-20, 4.6, -35.5) * CFrame.Angles(rad(45), T * 1.5, rad(45)) end
	camMove(V(-21.5, 5.4, -31.6), V(-20, 4.6, -35.5), V(-18.6, 5.3, -32.2), V(-20, 4.6, -35.5), u, 45)
end)
-- 43. Or the keys.
shot(70.65, "dark", function() world({power = false, lever = 1, vault = 1}) end, function(T, u)
	camMove(V(-11, 6.5, -30.5), V(-26, 5, -38.5), V(-12, 6.3, -31.5), V(-26, 5, -38.5), u, 55)
end)
-- 44. Not both.
shot(71.45, "dark", function()
	world({power = false, lever = 1, vault = 1})
	act("Blocky", "sneaky", "idle")
end, function(T, u)
	if T > 71.9 then setFace(actors.Blocky, "angry") end
	S.poses.Blocky = {Neck = Y(35 * math.sin(T * 7))}
	pos("Blocky", F(-25, 0.4, -35, -25, 0))
	camMove(V(-25, 5, -31.4), V(-25, 4.8, -35), V(-25, 4.9, -32.1), V(-25, 4.8, -35), u, 50)
end)
-- 45. He took the keys. All of them.
shot(72.35, "dark", function()
	world({power = false, lever = 1, vault = 1})
	act("Blocky", "angry", nil)
	attach("Bag", "Blocky", "LeftHand", CFrame.new(0, -1.6, -0.6))
end, function(T, u)
	setKeys(1 - math.clamp((T - 72.45) / 1.6, 0, 1))
	S.poses.Blocky = {RightShoulder = X(90) * Z(-30 + 60 * math.abs(math.sin(T * 9))), LeftShoulder = X(30)}
	pos("Blocky", F(-26, 0.4, -36.2, -26, -50))
	camMove(V(-15.5, 7, -29.5), V(-24, 5, -37.5), V(-16.5, 6.6, -30.5), V(-24, 5, -37.5), u, 55)
end)
-- 46. Then a flashlight hit his face.
shot(74.30, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Blocky", "shocked", "idle", 1, {RightShoulder = X(70) * Z(-10)})
	act("Tony", "angry", "idle", 1, P.flash)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
	attach("Flashlight", "Tony", "RightHand", CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, rad(90), 0))
end, function(T, u)
	pos("Blocky", F(-20, 0.4, -24, -20, 0))
	pos("Tony", F(-18.6, 0.4, -16.5, -20, -24))
	camMove(V(-16.6, 8, -12.5), V(-20, 4.6, -24), V(-17.2, 7.6, -14), V(-20, 4.6, -24), u, 50)
end)
-- 47. A guard. The biggest one.
shot(75.75, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Tony", "angry", "idle", 1, P.flash)
	attach("Flashlight", "Tony", "RightHand", CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, rad(90), 0))
end, function(T, u)
	pos("Tony", F(-18.6, 0.4, -16.5, -20, -24))
	camMove(V(-19.6, 2.6, -22), V(-18.6, 7, -16.5), V(-19.4, 2.4, -21), V(-18.6, 7.2, -16.5), u, 55)
end)
-- 48. Blocky froze.
shot(77.75, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Blocky", "scared", nil, 1, P.scared)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
	act("Tony", "angry", "idle", 1, P.flash)
	attach("Flashlight", "Tony", "RightHand", CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, rad(90), 0))
end, function(T, u)
	pos("Tony", F(-18.6, 0.4, -16.5, -20, -24))
	pos("Blocky", F(-20, 0.4, -24, -20, 0))
	local sh = V(math.sin(T * 60) * 0.03, math.cos(T * 47) * 0.03, 0)
	camMove(V(-20, 5.1, -20.8) + sh, V(-20, 4.8, -24), V(-20, 5, -21.4) + sh, V(-20, 4.8, -24), u, 45)
end)
-- 49. The guard reached into the bag and pulled out a key.
shot(78.85, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Blocky", "scared", nil, 1, P.bagFront)
	act("Tony", "angry", "idle", 1)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, -1.2, -1.9))
end, function(T, u)
	local reach = math.clamp((T - 79.3) / 0.6, 0, 1)
	local lift = math.clamp((T - 80.25) / 0.5, 0, 1)
	S.poses.Tony = {RightShoulder = X(40 + 30 * reach + 60 * lift)}
	if lift > 0 then
		S.attach = {S.attach[1]}
		attach("KeyTony", "Tony", "RightHand", CFrame.new(0, -0.9, -0.3))
	end
	pos("Blocky", F(-20, 0.4, -24, -20, 0))
	pos("Tony", F(-19.6, 0.4, -20.3, -20, -24))
	camMove(V(-11.5, 5.4, -22.6), V(-19.8, 4.8, -22.2), V(-12.5, 5.6, -22.4), V(-19.8, 5, -22.2), u, 50)
end)
-- 50. The tag had his own name on it.
shot(81.45, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Tony", "angry", "idle")
end, function(T, u)
	if T > 82.3 then setFace(actors.Tony, "shocked") end
	pos("Tony", F(-20, 0.4, -24.6, -20, 0))
	props.KeyTony:PivotTo(CFrame.new(-19.4, 6.7, -22.2) * CFrame.Angles(0, 0, rad(math.sin(T * 2) * 6)))
	camMove(V(-18.6, 6.3, -18.2), V(-18.8, 6.3, -22.2), V(-18.6, 6.3, -18.9), V(-18.8, 6.3, -22.2), u, 45)
end)
-- 51. He looked at Blocky for a long time.
shot(83.30, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Tony", "shocked", "idle", 1, {RightShoulder = X(55)})
	act("Blocky", "scared", "idle")
	attach("KeyTony", "Tony", "RightHand", CFrame.new(0, -0.9, -0.3))
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
end, function(T, u)
	if T > 84.15 then setFace(actors.Tony, "sad") end
	pos("Tony", F(-20, 0.4, -20.3, -20, -24))
	pos("Blocky", F(-20, 0.4, -24, -20, 0))
	camMove(V(-21.4, 5.6, -26.6), V(-19.8, 6.1, -20.3), V(-21.1, 5.7, -25.8), V(-19.8, 6.2, -20.3), u, 50)
end)
-- 52. Then he clicked off his flashlight. And walked away.
shot(85.05, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Tony", "sad", "idle", 1, P.flash)
	act("Blocky", "shocked", "idle")
	attach("Flashlight", "Tony", "RightHand", CFrame.new(0, -0.6, -0.4) * CFrame.Angles(0, rad(90), 0))
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
end, function(T, u)
	props.Flashlight.Lens.Beam.Enabled = T < 85.6
	props.Flashlight.Lens.Color = T < 85.6 and Color3.fromRGB(255, 250, 220) or Color3.fromRGB(60, 60, 60)
	pos("Blocky", F(-20, 0.4, -24, -20, 0))
	if T < 86.7 then
		pos("Tony", F(-20, 0.4, -20.3, -20, -24))
	else
		local w = math.clamp((T - 86.7) / 1.15, 0, 1)
		if actors.Tony.anim ~= "walk" then act("Tony", "sad", "walk", 0.9) end
		pos("Tony", F(-19.5 + w * 2, 0.4, -19.5 + w * 7, -16, 0))
	end
	camMove(V(-31, 6, -19), V(-20, 4.4, -20), V(-30, 6, -18), V(-19, 4.4, -18), u, 50)
end)
-- 53. But on the way out, Blocky's bag hit the glass.
shot(87.85, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0})
	act("Blocky", "sneaky", "walk", 0.55, P.sneak)
	attach("Bag", "Blocky", "LeftHand", CFrame.new(-0.4, -1.6, 0))
end, function(T, u)
	if T > 89.45 then setFace(actors.Blocky, "shocked") anim(actors.Blocky, nil) end
	local z = -3 + math.clamp((T - 87.85) / 1.6, 0, 1) * 6.2
	pos("Blocky", F(-14.6, 0.45, z, -14.6, 30))
	camMove(V(-6, 5.6, 12.5), V(-13, 3.4, 1), V(-7, 5.2, 10.5), V(-12.5, 3.6, 2), u, 50)
end)
-- 54. Crash!
local shardList
shot(90.10, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0, glass = false})
	shardList = shards(V(-10, 4.4, 4), 34)
end, function(T, u)
	stepShards(shardList, math.max(0, T - 90.12))
	local sh = V(math.sin(T * 70) * 0.15, math.cos(T * 53) * 0.12, 0) * (1 - u)
	camMove(V(-7.5, 6.2, 9.5) + sh, V(-10, 4, 4), V(-8, 6, 10.5) + sh, V(-10, 4, 4), u, 55)
end)
-- 55. Red lights.
shot(90.85, "dark", function()
	world({power = false, lever = 1, vault = 1, keys = 0, glass = false, alarm = true})
	act("Blocky", "scared", nil, 1, P.scared)
	attach("Bag", "Blocky", "LeftHand", CFrame.new(-0.4, -1.6, 0))
end, function(T, u)
	local on = math.floor(T * 5) % 2 == 0
	for _, p in Heist.AlarmLights:GetChildren() do
		local l = p:FindFirstChildOfClass("PointLight")
		if l then l.Brightness = on and 5 or 0.6 end
		p.Color = on and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(90, 0, 0)
	end
	pos("Blocky", F(-14.6, 0.45, 3.2, -14.6, 30))
	camMove(V(0, 10, 17.5), V(-12, 3.5, 1), V(-2, 9, 16), V(-12, 3.5, 1), u, 55)
end)
-- 56. Sirens. Police everywhere.
shot(91.95, "night", function()
	world({power = false, alarm = true})
	act("Cop3", "angry", "run", 1)
	act("Cop4", "angry", "run", 1)
end, function(T, u)
	flashCars(T)
	local k = ease(math.clamp((T - 91.95) / 0.9, 0, 1))
	carAt(1, -90 + 70 * k, 36, -90)
	carAt(2, -120 + 120 * k, 44, -90)
	carAt(3, 110 - 88 * k, 36, 90)
	local r = math.clamp((T - 92.6) / 0.65, 0, 1)
	pos("Cop3", F(-8 + r * 4, 0.2, 33 - r * 5, 0, 20))
	pos("Cop4", F(8 - r * 4, 0.2, 33 - r * 5, 0, 20))
	camMove(V(28, 4, 25), V(0, 3, 40), V(26, 4.4, 24), V(-4, 3.2, 38), u, 60)
end)
-- 57. Blocky ran for the van.
shot(93.25, "night", function()
	world({power = false, alarm = true})
	act("Blocky", "scared", "run", 1.3)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
end, function(T, u)
	flashCars(T)
	carAt(1, -20, 36, -90)
	carAt(2, 0, 44, -90)
	carAt(3, 22, 36, 90)
	local p0, p1 = V(48, 0.6, -24), V(62, 0.2, -4)
	local p = p0:Lerp(p1, u)
	pos("Blocky", CFrame.lookAt(p, p + (p1 - p0)))
	camMove(V(52, 4.4, 3), V(55, 3.6, -14), V(54, 4.2, 1), V(60, 3.6, -6), u, 55)
end)
-- 58. Grandma was driving.
local VC = CFrame.new(900, 0, 300)
local function cabCrew(gFace, pFace, bFace)
	act("Grandma", gFace, nil, 1, P.drive)
	act("Pip", pFace, nil, 1, P.sitChair)
	act("Blocky", bFace, nil, 1, P.sitChair)
end
local function cabPlace(T)
	local seat = function(x) return VC * CFrame.new(x, 3.2, 2.0) end
	pos("Grandma", seat(-2.5), -2.15 + math.sin(T * 13) * 0.03)
	pos("Pip", seat(0.3), -1.65 + math.sin(T * 11) * 0.03)
	pos("Blocky", seat(3), -2.15 + math.sin(T * 12) * 0.03)
end
shot(94.35, "night", function()
	world({})
	cabCrew("angry", "shocked", "shocked")
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, -1.3, -1.8))
end, function(T, u)
	cabPlace(T)
	passLamps(70, T)
	camMove(V(900, 7.6, 290), V(900, 5.8, 302), V(900, 7.4, 292.5), V(900, 5.8, 302), u, 50)
end)
-- 58b. And Grandma was wide awake now.
shot(95.25, "night", function()
	world({})
	cabCrew("angry", "shocked", "shocked")
end, function(T, u)
	cabPlace(T)
	passLamps(70, T)
	local punch = ease(math.clamp((T - 95.9) / 0.3, 0, 1))
	camMove(V(897.5, 7.4, 293.5 + punch * 1.3), V(897.5, 6.2, 302), nil, nil, 0, 50 - punch * 8)
end)
-- 59. The sky turned orange. The sun was coming up.
shot(96.70, "sunrise", function()
	world({houses = false, bed = false})
	act("Grandma", "angry", nil, 1, P.drive)
end, function(T, u)
	flashCars(T)
	local x = 462 + u * 92
	vanAt(x, 0.2, 4, -90)
	carAt(1, x - 30, -4, -90)
	carAt(2, x - 52, 4, -90)
	carAt(3, 2000, 0, 0)
	camMove(V(505, 4.6, 30), V(600, 40, -150), V(514, 5, 29), V(x + 6, 3.5, 4), u, 55)
end)
-- 60. But there was a problem.
shot(98.95, "sunrise", function()
	world({})
	cabCrew("angry", "sad", "scared")
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, -1.3, -1.8))
end, function(T, u)
	cabPlace(T)
	passLamps(40, T)
	camMove(V(903, 7.2, 294), V(903, 6.2, 302), V(903, 7.1, 295), V(903, 6.2, 302), u, 45)
end)
-- 61. To keep what you steal, you have to get it home.
shot(100.05, "sunrise", function()
	world({})
	cabCrew("angry", "sad", "sad")
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, -1.3, -1.8))
end, function(T, u)
	cabPlace(T)
	passLamps(40, T)
	camMove(V(899.5, 7.6, 290.5), V(900, 5.8, 302), V(900, 7.5, 292), V(900, 5.8, 302), u, 50)
end)
-- 62. And Blocky didn't have a home anymore.
shot(102.30, "sunrise", function()
	world({})
	cabCrew("angry", "sad", "sad")
end, function(T, u)
	cabPlace(T)
	passLamps(40, T)
	camMove(V(903, 7.1, 294.5), V(903, 6.2, 302), V(903, 7, 296), V(903, 6.2, 302), u, 45)
end)
-- 63. Then he looked at the key in his hand.
shot(104.35, "sunrise", function()
	world({})
	cabCrew("angry", "sad", "sad")
end, function(T, u)
	if T > 105.2 then setFace(actors.Blocky, "sneaky") end
	cabPlace(T)
	passLamps(40, T)
	props.KeyBlocky:PivotTo(VC * CFrame.new(3.4, 6.55, -0.4) * CFrame.Angles(0, 0, rad(math.sin(T * 2) * 5)))
	camMove(V(904.7, 6.4, 296.2), V(904.6, 6.3, 300), V(904.7, 6.4, 296.8), V(904.6, 6.3, 300), u, 50)
end)
-- 64. Grandma floored it.
shot(105.95, "sunrise", function()
	world({})
	cabCrew("angry", "shocked", "happy")
end, function(T, u)
	cabPlace(T)
	passLamps(180, T)
	local sh = V(math.sin(T * 50) * 0.08, math.cos(T * 41) * 0.08, 0)
	camMove(V(898, 7.4, 293) + sh, V(897.5, 6.2, 302), V(897.6, 7.3, 295) + sh, V(897.5, 6.2, 302), u, 50)
end)
-- 65. Straight to the Glimmer lot, where every stolen house sat in rows.
shot(107.05, "sunrise", function() world({}) end, function(T, u)
	local k = math.clamp((T - 107.05) / 2.6, 0, 1)
	vanAt(-600, 0.2, 190 - 150 * ease(k), 0)
	if T < 108.3 then
		camMove(V(-586, 7, 96), V(-600, 6, 150), nil, nil, 0, 55)
	else
		camMove(V(-586, 7, 96), V(-600, 6, 60), V(-600, 62, 150), V(-600, 0, -10), (T - 108.3) / 2.0, 60)
	end
end)
-- 66. Blocky found his.
shot(110.30, "sunrise", function()
	world({})
	act("Blocky", "happy", "walk", 1)
	act("Pip", "happy", "walk", 1)
	act("Grandma", "happy", "walk", 0.8)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 0.3, 1.8))
end, function(T, u)
	local z = 54 - u * 9
	pos("Blocky", F(-578, 0, z, -578, 0))
	pos("Pip", F(-581.5, 0, z + 3, -578, 0))
	pos("Grandma", F(-574, 0, z + 4, -578, 0))
	camMove(V(-570, 5, 60), V(-578, 6, 40), V(-571.5, 5.5, 58), V(-578, 6, 40), u, 50)
end)
-- 67. Key in the door.
shot(111.45, "sunrise", function()
	world({})
	act("Blocky", "happy", nil, 1, P.reach)
end, function(T, u)
	local hole = V(-576.7, 4.26, 40.65)
	local d = 1.6 * (1 - ease(math.clamp((T - 111.5) / 0.6, 0, 1)))
	local turn = math.clamp((T - 112.25) / 0.2, 0, 1)
	props.KeyBlocky:PivotTo(CFrame.new(hole + V(0, 0, 1.95 + d)) * CFrame.Angles(rad(90), 0, 0) * CFrame.Angles(0, rad(-90 * turn), 0))
	pos("Blocky", F(-578.4, 0.8, 43.4, -578.4, 0))
	camMove(V(-575, 5.3, 46), V(-576.8, 4.4, 40.6), V(-575.4, 5.1, 45.2), V(-576.8, 4.4, 40.6), u, 50)
end)
-- 68. Click.
local glow
shot(112.45, "sunrise", function()
	world({})
	act("Blocky", "happy", "idle")
	act("Pip", "happy", "idle")
	act("Grandma", "happy", "idle")
	glow = Instance.new("Part")
	glow.Anchored = true
	glow.CanCollide = false
	glow.Size = V(4, 7.8, 0.1)
	glow.Material = Enum.Material.Neon
	glow.Color = Color3.fromRGB(255, 210, 140)
	glow.CFrame = lotDoorHome * CFrame.new(0, 0, -0.25)
	glow.Parent = workspace
	table.insert(S.extra, glow)
end, function(T, u)
	setLotDoor(ease(math.clamp((T - 112.55) / 0.4, 0, 1)))
	pos("Blocky", F(-577, 0.8, 45, -578, 0))
	pos("Pip", F(-580.5, 0, 46.5, -578, 0))
	pos("Grandma", F(-574, 0, 47, -578, 0))
	camMove(V(-573, 5.6, 52), V(-578, 4.6, 40.5), nil, nil, 0, 50)
end)
-- 69. The sun came up.
shot(113.00, "sunrise", function()
	world({})
	act("Blocky", "happy", "idle", 1, {RightShoulder = X(170), LeftShoulder = X(170)})
	act("Pip", "happy", "idle", 1, P.armsUp)
	act("Grandma", "happy", "idle")
end, function(T, u)
	light("sunrise", "morning", u)
	setLotDoor(1)
	pos("Blocky", F(-578, 0, 47, -578, 0))
	pos("Pip", F(-581.5, 0, 48.5, -578, 0))
	pos("Grandma", F(-574.5, 0, 48.5, -578, 0))
	camMove(V(-578, 2.2, 62), V(-578, 10, 30), V(-578, 2.6, 60), V(-578, 11, 30), u, 60)
end)
-- 70. And by law, every key in that bag was his.
shot(113.95, "morning", function()
	world({})
	act("Blocky", "happy", "idle", 1, P.armsUp)
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, 6.6, -0.2))
end, function(T, u)
	if T > 115.1 then setFace(actors.Blocky, "laugh") end
	setLotDoor(1)
	pos("Blocky", F(-578, 0, 47, -578, 100) * CFrame.new(0, math.abs(math.sin(T * 6)) * 0.3, 0))
	camMove(V(-578, 7.6, 56.5), V(-578, 6.4, 47), V(-578, 7.4, 54.5), V(-578, 6.6, 47), u, 60)
end)
-- 71. That morning, Blocky gave every family their key back.
local LINE = {"Fam1", "Fam2", "Fam7", "Fam3", "Fam4", "Fam5", "Fam6", "Fam8"}
shot(116.60, "morning", function()
	world({})
	act("Blocky", "happy", nil, 1, P.reach)
	attach("GiveKey", "Blocky", "RightHand", CFrame.new(0, -0.6, -0.3))
	for i, n in LINE do act(n, "happy", "idle", 1, i == 1 and P.reach or nil) end
end, function(T, u)
	pos("Blocky", F(-592, 0.15, 64, 0, 64))
	for i, n in LINE do pos(n, F(-588 + (i - 1) * 3.2, 0.15, 64 + (i % 2) * 0.6, -700, 64)) end
	camMove(V(-590.5, 5, 73), V(-589.5, 4.2, 64), V(-584, 5.5, 74), V(-585, 4.2, 64), u, 60)
end)
-- 72. The guard got his first.
shot(119.20, "morning", function()
	world({})
	act("Tony", "happy", "idle", 1, {RightShoulder = X(165)})
	act("Blocky", "happy", "idle")
	attach("KeyTony", "Tony", "RightHand", CFrame.new(0, -0.9, -0.3))
end, function(T, u)
	pos("Tony", F(-588, 0.15, 64, -594, 76) * CFrame.new(0, math.abs(math.sin(T * 7)) * 0.3, 0))
	pos("Blocky", F(-592.5, 0.15, 64, 0, 64))
	camMove(V(-591, 6.6, 75), V(-589.6, 8, 64), V(-591, 6.8, 73.5), V(-589.6, 8.2, 64), u, 60)
end)
-- 73. There was one key left.
shot(120.35, "morning", function()
	world({})
	act("Blocky", "sneaky", nil, 1, merge(P.lean, P.bagFront))
	attach("Bag", "Blocky", "UpperTorso", CFrame.new(0, -2.1, -1.8))
end, function(T, u)
	pos("Blocky", F(-592, 0.15, 64, -592, 100))
	camMove(V(-592, 5.3, 70), V(-592, 4.2, 64), V(-592, 5.2, 69), V(-592, 4.2, 64), u, 50)
end)
-- 74. The tag said: Mr. Glimmer.
shot(121.50, "morning", function()
	world({})
	act("Blocky", "sneaky", "idle")
end, function(T, u)
	pos("Blocky", F(-592, 0.15, 62.6, -592, 100))
	props.KeyGlimmer:PivotTo(CFrame.new(-591.6, 5.9, 65.2) * CFrame.Angles(0, 0, rad(math.sin(T * 2) * 6)))
	camMove(V(-591.4, 5.6, 68.3), V(-591.5, 5.6, 65.2), V(-591.4, 5.6, 67.8), V(-591.5, 5.6, 65.2), u, 45)
end)
-- 75. Blocky kept that one.
local MA = V(-600, 0, 500)
shot(123.20, "morning", function()
	world({})
	act("Glimmer", "sad", nil, 1, P.sitChair)
	act("Blocky", "happy", "idle", 1, {RightShoulder = Z(150)})
	act("Pip", "happy", "idle", 1, P.armsUp)
	act("Grandma", "sleep", nil, 1, P.sitChair)
	zzz("Grandma")
	attach("KeyGlimmer", "Blocky", "RightHand", CFrame.new(0, -0.9, -0.3))
end, function(T, u)
	pos("Glimmer", F(MA.X + 10, 0.8, MA.Z + 37.2, MA.X + 10, MA.Z + 100), -2.05)
	pos("Blocky", F(MA.X - 2, 23, MA.Z - 5, MA.X - 2, MA.Z + 100))
	S.poses.Blocky = {RightShoulder = Z(150 + 15 * math.sin(T * 12))}
	pos("Pip", F(MA.X + 2.5, 23, MA.Z - 5, MA.X + 2.5, MA.Z + 100))
	local seat = CFrame.new(MA + V(16, 0, 10)) * CFrame.Angles(0, rad(-20), 0) * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.pi, 0)
	pos("Grandma", seat * CFrame.new(0, 2.4, 0) * CFrame.Angles(rad(-12), 0, 0), -2.05)
	camMove(V(MA.X + 10, 3.4, MA.Z + 45), V(MA.X + 10, 3.2, MA.Z + 37.2), V(MA.X + 14, 20, MA.Z + 92), V(MA.X + 2, 14, MA.Z), u, 55)
end)
shot(126.00, "morning", function() world({}) end, function(T, u)
	camMove(V(MA.X + 14, 20, MA.Z + 92), V(MA.X + 2, 14, MA.Z), nil, nil, 0, 55)
end)

---------------------------------------------------------------- runtime
local gui
local function marker(on)
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "FilmMarker"
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 1000
		gui.ResetOnSpawn = false
		local f = Instance.new("Frame")
		f.Size = UDim2.fromScale(1, 1)
		f.BackgroundColor3 = Color3.fromRGB(255, 0, 255)
		f.BorderSizePixel = 0
		f.Parent = gui
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	gui.Enabled = on
end
local function prepClient()
	local SG = game:GetService("StarterGui")
	pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.All, false) end)
	pcall(function() SG:SetCore("TopbarEnabled", false) end)
	pcall(function() game:GetService("ProximityPromptService").Enabled = false end)
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)
	for _, b in Heist:GetDescendants() do
		if b:IsA("BillboardGui") then b.Enabled = false end
	end
	local zone = Heist.Van:FindFirstChild("StashZone")
	if zone then zone.Transparency = 1 end
	local sp = Heist:FindFirstChild("HeistSpawn")
	if sp then sp.Transparency = 1 end
end

local function shotAt(T)
	local idx = 1
	for i, s in SH do if T >= s.t then idx = i end end
	return idx
end
local current
local function frame(T)
	local idx = shotAt(T)
	local s = SH[idx]
	local nextT = SH[idx + 1] and SH[idx + 1].t or (s.t + 3)
	if current ~= idx then
		current = idx
		resetShot()
		resetVehicles()
		W = {}
		light(s.light)
		s.setup()
	end
	local u = math.clamp((T - s.t) / (nextT - s.t), 0, 1)
	s.update(T, u)
	for _, a in S.attach do
		local limb = a.A.m:FindFirstChild(a.limb)
		if limb and a.prop then a.prop:PivotTo(limb.CFrame * a.off) end
	end
	for name, pose in S.poses do
		local A = actors[name]
		if pose then
			for jn, j in A.joints do
				if pose[jn] then j.Transform = pose[jn]
				elseif not A.anim then j.Transform = CFrame.identity end
			end
		end
	end
	for _, g in S.zzz do
		local tl = g:FindFirstChildOfClass("TextLabel")
		g.StudsOffset = Vector3.new(1.4, 1.6 + (T * 0.8) % 1, 0)
		tl.TextTransparency = (T * 0.8) % 1
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = camFov
	cam.CFrame = camCF * CFrame.Angles(0, 0, rad(90))
end

function D.run(startT, endT)
	prepClient()
	RunService:UnbindFromRenderStep("FilmDirector")
	current = nil
	marker(true)
	frame(startT)
	task.delay(0.5, function()
		local t0 = os.clock()
		marker(false)
		RunService:BindToRenderStep("FilmDirector", Enum.RenderPriority.Last.Value + 1, function()
			local T = startT + (os.clock() - t0)
			if T >= endT then
				RunService:UnbindFromRenderStep("FilmDirector")
				marker(true)
				task.delay(0.5, function() marker(false) end)
				return
			end
			frame(T)
		end)
	end)
	return "running " .. startT .. " to " .. endT .. " (" .. #SH .. " shots)"
end
function D.still(T)
	prepClient()
	marker(false)
	RunService:UnbindFromRenderStep("FilmDirector")
	current = nil
	RunService:BindToRenderStep("FilmDirector", Enum.RenderPriority.Last.Value + 1, function()
		frame(T)
	end)
	return "still at " .. T .. " shot " .. shotAt(T)
end
function D.stop()
	RunService:UnbindFromRenderStep("FilmDirector")
	marker(false)
end
D.shots = SH
return D
