-- FilmDirector CORE (shared by every reel). film.py builds the module as: core.luau + reels/<reel>/shots.luau + 'D.shots = SH return D'.
-- Everything below is in scope for a reel's shots file (actors, props, P poses, world(), light(), LP, camMove, shot(), ...).
-- Do NOT edit for one reel: override or add helpers inside the reel's shots.luau instead.
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
local castModels = CastF:GetChildren()
local ReelCastF = Film:FindFirstChild("ReelCast") -- a reel's own extra actors (reels/<reel>/cast.luau)
if ReelCastF then for _, m in ReelCastF:GetChildren() do table.insert(castModels, m) end end
local ReelSets = Film:FindFirstChild("ReelSets") -- a reel's own sets (reels/<reel>/sets.luau), may be nil
for _, m in castModels do
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
function D.marker(on)
	prepClient()
	marker(on)
	return "marker " .. tostring(on)
end
function D.stop()
	RunService:UnbindFromRenderStep("FilmDirector")
	marker(false)
end
