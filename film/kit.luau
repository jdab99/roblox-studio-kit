-- Blocky Tales STYLE KIT (shared by every reel). film.py builds the Director as core.luau + kit.luau + <reel>/shots.luau.
-- Everything lives in ONE table K (Luau allows 200 locals per function; core already uses many). See film/KIT.md.
-- Uses the shared world in workspace.Film.KitSets (film/kit_sets.luau): the golden-hour town at K.TOWN, pets, props.
-- Nothing here changes a reel that does not call K: reel 01 still runs exactly as before.
local K = {}
K.TOWN = V(0, 0, -3000)                -- centre of the kit town (Maple Street runs along X through here)
K.SETS = Film:FindFirstChild("KitSets") -- may be nil if the kit sets are not installed
K.flags = {}                            -- per-shot scratch flags (cleared at every cut by K.reset)

---------------------------------------------------------------- look: presets, sky, depth of field
do
	local C = Color3.fromRGB
	-- golden-hour day (the reference look): warm low sun, deep blue sky, hazy mountains, bloom + rays
	LP.golden = {ClockTime = 16.7, Brightness = 2.7, Ambient = C(110, 100, 100), OutdoorAmbient = C(150, 138, 135), Exposure = -0.08,
		Density = 0.3, Haze = 1.2, AColor = C(225, 195, 165), Decay = C(110, 125, 165), Sat = 0.24, Contrast = 0.13, Tint = C(255, 242, 226), Bloom = 0.55, Rays = 0.14}
	-- same light for tight close-ups (a touch darker so faces never blow out)
	LP.goldenClose = {ClockTime = 16.7, Brightness = 2.4, Ambient = C(110, 100, 100), OutdoorAmbient = C(145, 132, 128), Exposure = -0.15,
		Density = 0.3, Haze = 1.2, AColor = C(225, 195, 165), Decay = C(110, 125, 165), Sat = 0.24, Contrast = 0.13, Tint = C(255, 240, 222), Bloom = 0.45, Rays = 0.1}
	-- bright clean interior day (vet room, school)
	LP.dayIn = {ClockTime = 13, Brightness = 2, Ambient = C(150, 150, 155), OutdoorAmbient = C(160, 160, 165), Exposure = -0.05,
		Density = 0.2, Haze = 0.5, AColor = C(200, 215, 240), Decay = C(140, 160, 200), Sat = 0.2, Contrast = 0.1, Tint = C(250, 252, 255), Bloom = 0.35, Rays = 0}
	-- blue moonlit bedroom at night
	LP.moon = {ClockTime = 0.5, Brightness = 1.6, Ambient = C(100, 110, 155), OutdoorAmbient = C(110, 125, 180), Exposure = 0.3,
		Density = 0.2, Haze = 0.3, AColor = C(90, 105, 160), Decay = C(50, 60, 100), Sat = 0.12, Contrast = 0.14, Tint = C(225, 235, 255), Bloom = 0.4, Rays = 0}
	-- dusk for the goldfish (comment-bait hold): purple-orange, a bit eerie
	LP.dusk = {ClockTime = 18.2, Brightness = 1.6, Ambient = C(95, 80, 110), OutdoorAmbient = C(140, 110, 150), Exposure = 0,
		Density = 0.35, Haze = 1.6, AColor = C(230, 150, 160), Decay = C(120, 90, 150), Sat = 0.2, Contrast = 0.18, Tint = C(255, 225, 230), Bloom = 0.5, Rays = 0.1}
	-- winter afternoon: low sun, cold blue shadows, sparkly snow
	LP.winter = {ClockTime = 15.2, Brightness = 2.6, Ambient = C(120, 130, 150), OutdoorAmbient = C(160, 175, 200), Exposure = -0.2,
		Density = 0.32, Haze = 1.0, AColor = C(200, 215, 240), Decay = C(150, 170, 210), Sat = 0.12, Contrast = 0.14, Tint = C(240, 246, 255), Bloom = 0.5, Rays = 0.1}
	-- warm lamp-lit night interior (vet at night, Grandma's story)
	-- soft first light through a window (sunrise inside a room)
	LP.dawnIn = {ClockTime = 6.4, Brightness = 1.6, Ambient = C(120, 100, 105), OutdoorAmbient = C(170, 140, 140), Exposure = 0,
		Density = 0.25, Haze = 1.2, AColor = C(255, 180, 140), Decay = C(200, 130, 110), Sat = 0.18, Contrast = 0.1, Tint = C(255, 228, 210), Bloom = 0.5, Rays = 0.15}
	-- dreamy warm flashback (the nursery, years ago)
	LP.flashback = {ClockTime = 2, Brightness = 1, Ambient = C(140, 115, 100), OutdoorAmbient = C(90, 90, 120), Exposure = 0.15,
		Density = 0.1, Haze = 0, AColor = C(90, 90, 120), Decay = C(50, 50, 80), Sat = -0.05, Contrast = 0.05, Tint = C(255, 230, 200), Bloom = 0.8, Rays = 0}
	-- brighter warm lamp-lit night room (faces and fur read; still clearly night)
	LP.lampWarm = {ClockTime = 0.5, Brightness = 1.4, Ambient = C(150, 122, 105), OutdoorAmbient = C(90, 90, 125), Exposure = 0.25,
		Density = 0.1, Haze = 0, AColor = C(90, 90, 120), Decay = C(50, 50, 80), Sat = 0.2, Contrast = 0.1, Tint = C(255, 228, 200), Bloom = 0.35, Rays = 0}
	-- hospital nursery at night: soft blue-white room light (add a warm K.lamp by the bed)
	LP.nursery = {ClockTime = 0.5, Brightness = 0.6, Ambient = C(78, 84, 112), OutdoorAmbient = C(60, 70, 110), Exposure = -0.05,
		Density = 0.1, Haze = 0, AColor = C(90, 100, 140), Decay = C(50, 55, 90), Sat = 0.14, Contrast = 0.1, Tint = C(228, 234, 255), Bloom = 0.3, Rays = 0}
	LP.lamp = {ClockTime = 0.5, Brightness = 0.8, Ambient = C(95, 80, 70), OutdoorAmbient = C(70, 70, 100), Exposure = 0.1,
		Density = 0.1, Haze = 0, AColor = C(90, 90, 120), Decay = C(50, 50, 80), Sat = 0.18, Contrast = 0.12, Tint = C(255, 228, 200), Bloom = 0.4, Rays = 0}
end
-- one sky for kit shots: the anime-cloud skybox "Stylized" (the plain default sky waits offstage on this client)
function K.useSky()
	local stylized = Lighting:FindFirstChild("Stylized")
	if not stylized then return end
	for _, s in Lighting:GetChildren() do
		if s:IsA("Sky") and s ~= stylized then s.Parent = HIDE end
	end
end
K.dofFx = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect", Lighting)
function K.dof(focus, radius, far, near)
	local d = K.dofFx
	if not focus then d.Enabled = false return end
	d.Enabled = true
	d.FocusDistance = focus
	d.InFocusRadius = radius or 6
	d.FarIntensity = far or 0.45
	d.NearIntensity = near or 0.25
end

---------------------------------------------------------------- extra actor animations (Roblox stock R15 emotes)
do
	local EMOTES = {wave = "rbxassetid://507770239", point = "rbxassetid://507770453", cheer = "rbxassetid://507770677",
		laugh = "rbxassetid://507770818", dance = "rbxassetid://507771019", jump = "rbxassetid://507765000", sit = "rbxassetid://2506281703"}
	K.ANIM = EMOTES -- act(name, mood, "<one of these>") plays it (idle/walk/run come from core)
	for _, A in actors do
		local hum = A.m:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if animator then
			for k, id in EMOTES do
				local a = Instance.new("Animation")
				a.AnimationId = id
				local ok, t = pcall(function() return animator:LoadAnimation(a) end)
				if ok then t.Looped = true A.tracks[k] = t end
			end
		end
	end
	local FACES2 = {happy2 = 135773001893013, laugh2 = 140615351309004, scream = 74187334953026, shocked2 = 87555246095537,
		scared2 = 82071220644850, dizzy = 120248967875008, angry2 = 124090698532510, smug = 80289889743945, creepy = 95631127484038,
		cry = 139929720410872, starry = 95985606586642, focus = 90634447576450, nervous = 90946346829906, wow = 82444194871225,
		sad2 = 135482990429946}
	-- v2 faces join the old ones under their own names (old names keep their old art); setFace() in core reads FACES
	for k, v in FACES2 do if FACES[k] == nil then FACES[k] = v end end
	K.FACES = FACES2
end
P.pet = {RightShoulder = X(60) * Z(-10), Waist = X(30), Neck = X(-10)}
P.hug = {RightShoulder = X(80) * Z(-30), LeftShoulder = X(80) * Z(30), RightElbow = X(30), LeftElbow = X(30)}
P.handsUp = {RightShoulder = X(160) * Z(20), LeftShoulder = X(160) * Z(-20)}
P.facepalm = {RightShoulder = X(150) * Z(-40), RightElbow = X(100), Neck = X(-10)}
P.earsCover = {RightShoulder = X(150) * Z(60), LeftShoulder = X(150) * Z(-60), RightElbow = X(120), LeftElbow = X(120)}
P.lieBack = {}
P.shrug = {RightShoulder = Z(55), LeftShoulder = Z(-55), RightElbow = X(70), LeftElbow = X(70), Neck = Z(8)}

---------------------------------------------------------------- pets: pose by limb every frame
K.pets = {}
K.PARK = CFrame.new(K.TOWN + V(0, -400, 0))
do
	for _, m in (K.SETS and K.SETS:FindFirstChild("Pets") or Instance.new("Folder")):GetChildren() do
		local root = m.PrimaryPart
		local info = {m = m, parts = {}, pivot = {}, parent = {}, byName = {}, s = 1, home = root.CFrame}
		for k, v in m:GetAttributes() do
			if k:sub(1, 6) == "Pivot_" then info.pivot[k:sub(7)] = v
			elseif k:sub(1, 7) == "Parent_" then info.parent[k:sub(8)] = v end
		end
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p ~= root then
				local e = {p = p, limb = p:GetAttribute("Limb"), rel = root.CFrame:ToObjectSpace(p.CFrame), size = p.Size, tr = p.Transparency}
				table.insert(info.parts, e)
				info.byName[p.Name] = info.byName[p.Name] or {}
				table.insert(info.byName[p.Name], e)
			end
		end
		K.pets[m.Name] = info
	end
end
K.usedPets = {}
-- place pet `name` with its root at `cf`; joints = {Limb = rotation CFrame}; s = uniform scale
function K.pose(name, cf, joints, s)
	local info = K.pets[name]
	joints = joints or {}
	s = s or 1
	K.usedPets[name] = true
	local T = {}
	local function limbT(l)
		if not l then return CFrame.identity end
		if T[l] then return T[l] end
		local pv = info.pivot[l] or CFrame.identity
		local j = joints[l] or CFrame.identity
		local t = limbT(info.parent[l]) * pv * j * pv:Inverse()
		T[l] = t
		return t
	end
	local resize = info.s ~= s
	for _, e in info.parts do
		local M = limbT(e.limb) * e.rel
		if e.extra then M = M * e.extra end
		e.p.CFrame = cf * (CFrame.new(M.Position * s) * M.Rotation)
		if resize then e.p.Size = e.size * s end
	end
	info.s = s
	info.m.PrimaryPart.CFrame = cf
end
-- toggles: eyes "open"/"closed"/"squint", tongue true/false, brows "sad"/"up"/nil
function K.petFace(name, eyes, tongue, brows)
	local info = K.pets[name]
	for _, n in {"LidL", "LidR"} do
		for _, e in info.byName[n] or {} do
			e.p.Transparency = (eyes == "closed") and 0 or 1
			e.extra = (eyes == "squint") and CFrame.new(0, 0.12, 0) or nil
			if eyes == "squint" then e.p.Transparency = 0 end
		end
	end
	for _, e in info.byName.Tongue or {} do e.p.Transparency = tongue and 0 or 1 end
	for i, n in {"BrowL", "BrowR"} do
		local sgn = (i == 1) and 1 or -1
		for _, e in info.byName[n] or {} do
			if brows == "sad" then e.extra = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, rad(24 * sgn))
			elseif brows == "up" then e.extra = CFrame.new(0, 0.12, 0)
			else e.extra = nil end
		end
	end
end
-- world position of a pet's head (dogs/cat/parrot: the part named Head; hamster/fish: Body) and its facing
function K.head(name)
	local info = K.pets[name]
	local e = (info.byName.Head or info.byName.Body)[1]
	return e.p.Position
end
function K.fwd(name)
	return K.pets[name].m.PrimaryPart.CFrame.LookVector
end
K.STAR_UP = {Biscuit = 3.0, Puppy = 1.9, DogSpot = 3.0, DogBrown = 3.0, Cat = 2.2, Parrot = 1.9, Hamster = 1.7, Goldfish = 1.6}
K.STAR_UP.Pup = 1.6
-- the puppy build ("Pup", about 2.7 tall) uses the dog gaits; its own root drops for lying / crawling / sitting
K.PUP = {lieDrop = 0.5, crawlDrop = 0.4, sitDrop = 0.28}
-- keep star `key` over pet `name` (call after K.pose)
function K.starOver(key, name, T)
	K.starAt(key, K.head(name) + V(0, K.STAR_UP[name] or 2.5, 0), T)
end
-- any marker over a pet, an actor (by name) or a fixed point
function K.over(key, who, T, up)
	if typeof(who) == "Vector3" then return K.markAt(key, who + V(0, up or 0, 0), T) end
	if K.pets[who] then return K.markAt(key, K.head(who) + V(0, up or K.STAR_UP[who] or 2.5, 0), T) end
	local A = actors[who]
	if A then return K.markAt(key, A.head.Position + V(0, up or 2.6, 0), T) end
end
function K.parkPets()
	for name in K.usedPets do
		K.petFace(name, "open", false, nil)
		K.pose(name, K.pets[name].home, {}, 1)
	end
	K.usedPets = {}
end
-- dog gaits (joint tables); phase = T * speed
K.DOG = {}
function K.DOG.walk(T, speed, amp)
	local a = math.sin(T * (speed or 7)) * rad(amp or 28)
	return {LegFL = CFrame.Angles(a, 0, 0), LegBR = CFrame.Angles(a, 0, 0), LegFR = CFrame.Angles(-a, 0, 0), LegBL = CFrame.Angles(-a, 0, 0),
		Head = CFrame.Angles(math.sin(T * (speed or 7) * 2) * rad(3), 0, 0), Tail = CFrame.Angles(0, math.sin(T * 9) * rad(25), 0)}
end
function K.DOG.lie(T, headDown, wag)
	return {LegFL = CFrame.Angles(rad(88), 0, 0), LegFR = CFrame.Angles(rad(88), 0, 0), LegBL = CFrame.Angles(rad(-88), 0, 0), LegBR = CFrame.Angles(rad(-88), 0, 0),
		Head = CFrame.Angles(rad(headDown and -22 or 4), 0, 0), Tail = CFrame.Angles(rad(-30), math.sin(T * 10) * rad(wag or 0), 0),
		EarL = CFrame.Angles(0, 0, rad(-8)), EarR = CFrame.Angles(0, 0, rad(8))}
end
K.DOG.lieDrop = 1.75 -- how far the root drops when lying down
function K.DOG.sit(T, tilt, wag)
	return {Body = CFrame.Angles(rad(34), 0, 0), Head = CFrame.Angles(rad(-30), 0, rad(tilt or 0)), LegFL = CFrame.Angles(rad(-34), 0, 0), LegFR = CFrame.Angles(rad(-34), 0, 0),
		LegBL = CFrame.Angles(rad(56), 0, 0), LegBR = CFrame.Angles(rad(56), 0, 0), Tail = CFrame.Angles(rad(-60), math.sin(T * 11) * rad(wag or 0), 0)}
end
K.DOG.sitDrop = 1.05
function K.DOG.stand(T, tilt, wag)
	return {Head = CFrame.Angles(0, 0, rad(tilt or 0)), Tail = CFrame.Angles(rad(10), math.sin(T * 12) * rad(wag or 0), 0)}
end

---------------------------------------------------------------- props (KitSets.Props): place by pivot, park at every cut
K.props = {}
K.usedProps = {}
for _, m in (K.SETS and K.SETS:FindFirstChild("Props") or Instance.new("Folder")):GetChildren() do K.props[m.Name] = {m = m, home = m:GetPivot()} end
function K.prop(name, cf)
	local p = K.props[name]
	K.usedProps[name] = true
	p.m:PivotTo(cf)
end
function K.parkProps()
	for name in K.usedProps do K.props[name].m:PivotTo(K.props[name].home) end
	K.usedProps = {}
end

---------------------------------------------------------------- VFX (all made per shot into S.extra, so every cut cleans them)
K.TEX = {glow = "rbxassetid://116527711074663", burst = "rbxassetid://121608650924504", ring = "rbxassetid://83039403115786",
	puff = "rbxassetid://138838698583358", speedlines = "rbxassetid://71036060323858", sparkle = "rbxassetid://84487186146732",
	star = "rbxassetid://86541207268218", ghost = "rbxassetid://89106100064424"}
K.GOLD = Color3.fromRGB(255, 205, 70)
K.ROLL = 90 -- GUI rotation that makes a billboard read upright in the final 9:16 video (the camera is rolled 90 degrees)
function K.anchor(pos)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = V(0.2, 0.2, 0.2)
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	table.insert(S.extra, p)
	return p
end
function K.bill(parent, studs, image, color, transp, z)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(studs, 0, studs, 0)
	bb.LightInfluence = 0
	bb.AlwaysOnTop = false
	bb.MaxDistance = 2000
	bb.Parent = parent
	local im = Instance.new("ImageLabel")
	im.Size = UDim2.fromScale(1, 1)
	im.AnchorPoint = Vector2.new(0.5, 0.5)
	im.Position = UDim2.fromScale(0.5, 0.5)
	im.BackgroundTransparency = 1
	im.Image = image
	im.ImageColor3 = color or Color3.new(1, 1, 1)
	im.ImageTransparency = transp or 0
	im.ZIndex = z or 1
	im.Rotation = K.ROLL
	im.Parent = bb
	return bb, im
end
function K.emitter(parent, tex, color, size, life, speed, rate, extra)
	local e = Instance.new("ParticleEmitter")
	e.Texture = tex
	e.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	e.LightEmission = 1
	e.Size = typeof(size) == "NumberSequence" and size or NumberSequence.new({NumberSequenceKeypoint.new(0, size or 0.4), NumberSequenceKeypoint.new(1, 0)})
	e.Lifetime = NumberRange.new(life or 0.6, (life or 0.6) * 1.5)
	e.Speed = NumberRange.new(speed or 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate or 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-90, 90)
	e.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 1)})
	for k, v in (extra or {}) do e[k] = v end
	e.Parent = parent
	return e
end
-- MARKERS: anything that floats over a head (the wish star, a number like Ralph's "3", an icon). Bobs, can pop.
-- K.mark(key, {image=, text=, size=, color=, glow=, sparkle=, transp=}) makes one; K.markAt(key, pos, T) moves it;
-- K.over(key, who, T, up) keeps it over a pet (K.pets) or an actor's head; K.pop(key, t0, T) bursts it at t0 (gone after).
K.stars = {}
function K.mark(key, o)
	o = o or {}
	local a = K.anchor(K.PARK.Position)
	local size_ = o.size or 2.2
	local glowB, glowI = K.bill(a, size_ * 2.2, K.TEX.glow, o.glowColor or K.GOLD, 0.45, 1)
	glowB.Enabled = o.glow ~= false
	local bb, im
	if o.text then
		bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(size_, 0, size_, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 2000
		bb.Parent = a
		im = Instance.new("TextLabel")
		im.Size = UDim2.fromScale(1, 1)
		im.AnchorPoint = Vector2.new(0.5, 0.5)
		im.Position = UDim2.fromScale(0.5, 0.5)
		im.BackgroundTransparency = 1
		im.Font = Enum.Font.FredokaOne
		im.TextScaled = true
		im.Text = o.text
		im.TextColor3 = o.color or Color3.new(1, 1, 1)
		im.ZIndex = 2
		im.Rotation = K.ROLL
		im.Parent = bb
		local st = Instance.new("UIStroke")
		st.Thickness = 4
		st.Color = Color3.fromRGB(25, 20, 20)
		st.Parent = im
	else
		bb, im = K.bill(a, size_, o.image or K.TEX.star, o.color, o.transp or 0, 2)
	end
	local sp = (o.sparkle ~= false) and K.emitter(a, K.TEX.sparkle, Color3.fromRGB(255, 230, 140), size_ * 0.16, 0.9, size_ * 0.5, 5) or nil
	local burstB, burstI = K.bill(a, size_ * 3, K.TEX.burst, o.burstColor or K.GOLD, 1, 3)
	K.stars[key] = {a = a, bb = bb, im = im, glow = glowB, glowI = glowI, sp = sp, size = size_, burstB = burstB, burstI = burstI}
	return K.stars[key]
end
-- the wish star (ghost = the dashed "empty spot" outline)
function K.star(key, size, ghost)
	if ghost then return K.mark(key, {image = K.TEX.ghost, size = size, glow = false, sparkle = false, transp = 0.25}) end
	return K.mark(key, {image = K.TEX.star, size = size})
end
function K.markAt(key, pos, T)
	local s = K.stars[key]
	s.a.CFrame = CFrame.new(pos + V(0, math.sin(T * 2.2 + #key) * 0.18, 0))
	s.im.Rotation = K.ROLL + math.sin(T * 1.6 + #key) * 9
	s.glowI.ImageTransparency = 0.45 + math.sin(T * 3) * 0.1
end
K.starAt = K.markAt
function K.markFade(s, t)
	if s.im:IsA("TextLabel") then
		s.im.TextTransparency = t
		local st = s.im:FindFirstChildOfClass("UIStroke")
		if st then st.Transparency = t end
	else
		s.im.ImageTransparency = t
	end
end
function K.pop(key, t0, T)
	local s = K.stars[key]
	local k = T - t0
	if k < 0 then return end
	if not s.popped then
		s.popped = true
		local burst = K.emitter(s.a, K.TEX.sparkle, Color3.fromRGB(255, 225, 120), s.size * 0.35, 0.7, s.size * 4, 0)
		burst:Emit(45)
		if s.sp then s.sp.Rate = 0 end
	end
	local g = math.clamp(k / 0.12, 0, 1)
	s.bb.Size = UDim2.new(s.size * (1 + 0.6 * g), 0, s.size * (1 + 0.6 * g), 0)
	K.markFade(s, g)
	s.glowI.ImageTransparency = 0.45 + 0.55 * math.clamp(k / 0.3, 0, 1)
	local b = math.clamp(k / 0.4, 0, 1)
	s.burstB.Size = UDim2.new(s.size * (1 + 3 * b), 0, s.size * (1 + 3 * b), 0)
	s.burstI.ImageTransparency = (k < 0.4) and (0.1 + 0.9 * b) or 1
end
function K.burst(pos, n, color, size, speed)
	local a = K.anchor(pos)
	K.emitter(a, K.TEX.sparkle, color or Color3.fromRGB(255, 230, 140), size or 0.5, 0.8, speed or 8, 0):Emit(n or 30)
	return a
end
function K.puffs(pos, n, color, size)
	local a = K.anchor(pos)
	local e = K.emitter(a, K.TEX.puff, color or Color3.fromRGB(235, 225, 210), NumberSequence.new({NumberSequenceKeypoint.new(0, size or 0.8), NumberSequenceKeypoint.new(1, (size or 0.8) * 2.2)}),
		0.7, 3, 0, {LightEmission = 0, SpreadAngle = Vector2.new(70, 70), Acceleration = V(0, 1.5, 0),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})})
	e.EmissionDirection = Enum.NormalId.Top
	e:Emit(n or 8)
	return a, e
end
-- floating sparkles in a volume (magic in the air)
function K.motes(pos, rate, color, size)
	local a = K.anchor(pos)
	a.Size = V(6, 4, 6)
	K.emitter(a, K.TEX.sparkle, color or Color3.fromRGB(255, 235, 170), size or 0.25, 1.6, 0.6, rate or 8, {Shape = Enum.ParticleEmitterShape.Box})
	return a
end
-- a glow ring on the ground that grows + fades over `dur` from t0
function K.ring(pos, t0, T, radius, dur, color)
	local p = K.ringPart
	if not p or not p.Parent then
		p = Instance.new("Part")
		p.Anchored, p.CanCollide = true, false
		p.Transparency = 1
		p.Size = V(1, 0.05, 1)
		local d = Instance.new("Decal")
		d.Face = Enum.NormalId.Top
		d.Texture = K.TEX.ring
		d.Color3 = color or K.GOLD
		d.Parent = p
		p.Parent = workspace
		table.insert(S.extra, p)
		K.ringPart = p
	end
	local k = math.clamp((T - t0) / (dur or 0.8), 0, 1)
	local r = (radius or 6) * (0.3 + 0.7 * k)
	p.Size = V(r * 2, 0.05, r * 2)
	p.CFrame = CFrame.new(pos + V(0, 0.08, 0))
	p.Decal.Transparency = (T < t0) and 1 or k
end
-- screen overlays: speed lines, white flash, a speech bubble text over a head
function K.screen()
	if K.gui and K.gui.Parent then return K.gui end
	local g = Instance.new("ScreenGui")
	g.Name = "ReelFX"
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.ResetOnSpawn = false
	local sl = Instance.new("ImageLabel")
	sl.Name = "Speed"
	sl.BackgroundTransparency = 1
	sl.Image = K.TEX.speedlines
	sl.AnchorPoint = Vector2.new(0.5, 0.5)
	sl.Position = UDim2.fromScale(0.5, 0.5)
	sl.Size = UDim2.fromScale(1.6, 1.6)
	sl.SizeConstraint = Enum.SizeConstraint.RelativeXX
	sl.ImageTransparency = 1
	sl.Parent = g
	local fl = Instance.new("Frame")
	fl.Name = "Flash"
	fl.Size = UDim2.fromScale(1, 1)
	fl.BackgroundColor3 = Color3.new(1, 1, 1)
	fl.BackgroundTransparency = 1
	fl.BorderSizePixel = 0
	fl.Parent = g
	g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	K.gui = g
	return g
end
function K.speed(alpha, T)
	local sl = K.screen().Speed
	sl.ImageTransparency = 1 - (alpha or 0)
	sl.Rotation = ((T or 0) * 997) % 360
end
function K.flash(alpha)
	K.screen().Flash.BackgroundTransparency = 1 - (alpha or 0)
end
function K.say(parent, text, studs, T)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(studs or 5, 0, studs or 5, 0)
	bb.StudsOffsetWorldSpace = V(0, 1.2, 0) -- world up (screen offsets turn sideways with the rolled camera)
	bb.LightInfluence = 0
	bb.Parent = parent
	local f = Instance.new("TextLabel")
	f.Size = UDim2.fromScale(1, 0.45)
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Rotation = K.ROLL
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.TextColor3 = Color3.fromRGB(20, 20, 25)
	f.Font = Enum.Font.FredokaOne
	f.TextScaled = true
	f.Text = text
	f.Parent = bb
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = f
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = Color3.fromRGB(20, 20, 25)
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = f
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0.08, 0), UDim.new(0.08, 0)
	pad.Parent = f
	table.insert(S.extra, bb)
	return bb, f
end

---------------------------------------------------------------- per-shot wrapper: cleans the reel state, then the shot's setup
function K.reset()
	K.parkPets()
	K.parkProps()
	K.stars = {}
	K.ringPart = nil
	K.flags = {}
	K.useSky()
	K.dof(nil)
	K.speed(0)
	K.flash(0)
	ATMO.Offset = 0.25
	ATMO.Glare = 0.4
	K.iceReset()
end
function K.sh(t, preset, setup, update)
	shot(t, preset, function()
		world({})
		K.reset()
		setup()
	end, update)
end




---------------------------------------------------------------- camera helpers (add their offsets to camMove eyes / looks)
-- gentle handheld drift (amp in studs)
function K.handheld(T, amp)
	amp = amp or 0.06
	return V(math.sin(T * 1.7) + 0.5 * math.sin(T * 3.1), math.sin(T * 1.3 + 1) + 0.5 * math.sin(T * 2.7), 0) * amp
end
-- a decaying impact shake that starts at t0 (amp in studs, dur in s)
function K.shake(T, t0, dur, amp)
	if T < t0 or T > t0 + dur then return V(0, 0, 0) end
	local k = (1 - (T - t0) / dur) * (amp or 0.5)
	return V(math.sin(T * 90) * k, math.cos(T * 77) * k, 0)
end
-- a whip pan: returns 0..1 (fast ease) to blend two looks with camMove(..., u), and shows speed lines mid-whip
function K.whip(T, t0, dur)
	local u = math.clamp((T - t0) / (dur or 0.25), 0, 1)
	K.speed((u > 0 and u < 1) and 0.8 or 0, T)
	return u * u * u * (u * (u * 6 - 15) + 10)
end
-- a point on a circle round c (for orbits): angle in degrees, radius, height
function K.orbit(c, deg, radius, h)
	return c + V(math.sin(rad(deg)) * radius, h or 0, math.cos(rad(deg)) * radius)
end
-- face a point: root CFrame at p looking toward (x, z) (keeps p's height)
function K.face(p, x, z)
	return CFrame.lookAt(p, V(x, p.Y, z))
end
-- a camera eye `dist` in front of a pet's face (+up, +side), and the look point (+h above its head centre)
function K.frontCam(name, dist, up, side, h)
	local hp = K.head(name)
	local f = K.fwd(name)
	local r = f:Cross(V(0, 1, 0))
	return hp + f * dist + V(0, up or 0, 0) + r * (side or 0), hp + V(0, h or 0, 0)
end

---------------------------------------------------------------- shared places in the kit world (film/KIT.md has the map)
K.SPOT = {
	street = K.TOWN,                          -- Maple Street centre line (road along X from -330 to 330)
	walkN = K.TOWN + V(0, 0.55, -15),         -- north sidewalk (z -19..-11, top 0.55)
	walkS = K.TOWN + V(0, 0.55, 15),          -- south sidewalk
	yard = K.TOWN + V(66, 0, -36),            -- front lawn of the sage-green house (x 60, north side); its mailbox is at x 84
	school = K.TOWN + V(395, 0.3, 0),         -- plaza in front of the school (school front faces -X)
	ferris = K.TOWN + V(-190, 0, 330),        -- Ferris wheel base (hub about 33-38 up)
	playground = K.TOWN + V(-60, 0, 250),
	winter = K.TOWN + V(120, 0, 430),         -- centre of the snowy park (snow disc radius 150, sled hill to the north-west)
	pond = K.TOWN + V(150, 0, 460),           -- frozen pond centre (ice radius about 32)
	hole = K.TOWN + V(156, 0, 466),           -- the ice-hole spot (chunks Ice1..Ice8 round it)
	bed = K.TOWN + V(-460, 0, -60),           -- kids' bedroom (floor top 0.82; bed centre -459,-62, head end at z -67)
	vet = K.TOWN + V(-470, 0, 150),           -- vet room centre (exam table top y 3.4)
	nursery = K.TOWN + V(-470, 0, 270),       -- hospital nursery centre (incubator on a cart)
	hallway = K.TOWN + V(-470, 0, 390),       -- school hallway centre (runs along X, lockers both sides)
	boyroom = K.TOWN + V(-470, 0, 510),       -- boy's bedroom centre (floor top 0.4; bed head on the north wall, mattress top 2.6)
}

---------------------------------------------------------------- added for reel 02 phase 2 (new functions only; see KIT.md)
-- more dog poses
-- belly-down crawl with paddling legs (on ice)
function K.DOG.crawl(T, speed)
	local a = math.sin(T * (speed or 6)) * rad(25)
	return {LegFL = CFrame.Angles(rad(70) + a, 0, 0), LegFR = CFrame.Angles(rad(70) - a, 0, 0), LegBL = CFrame.Angles(rad(-70) - a, 0, 0), LegBR = CFrame.Angles(rad(-70) + a, 0, 0),
		Head = CFrame.Angles(rad(6), 0, 0), Tail = CFrame.Angles(rad(-20), 0, 0), EarL = CFrame.Angles(0, 0, rad(-20)), EarR = CFrame.Angles(0, 0, rad(20))}
end
K.DOG.crawlDrop = 1.3
-- braced and pulling backward (front legs planted forward, head down), shaking with effort
function K.DOG.pull(T, slip)
	local sh = math.sin(T * 40) * rad(2)
	local sl = (slip or 0) * math.sin(T * 9) * rad(25)
	return {Body = CFrame.Angles(rad(8) + sh, 0, 0), Head = CFrame.Angles(rad(-28), 0, sh * 2), LegFL = CFrame.Angles(rad(-35) + sl, 0, rad(-10)), LegFR = CFrame.Angles(rad(-35) - sl, 0, rad(10)),
		LegBL = CFrame.Angles(rad(-30) - sl, 0, 0), LegBR = CFrame.Angles(rad(-30) + sl, 0, 0), EarL = CFrame.Angles(0, 0, rad(-30)), EarR = CFrame.Angles(0, 0, rad(30)), Tail = CFrame.Angles(rad(-50), 0, 0)}
end
-- swimming / stuck in water: head up, front legs paddling
function K.DOG.swim(T)
	local a = math.sin(T * 8) * rad(40)
	return {Body = CFrame.Angles(rad(25), 0, 0), Head = CFrame.Angles(rad(-15), 0, 0), LegFL = CFrame.Angles(rad(50) + a, 0, 0), LegFR = CFrame.Angles(rad(50) - a, 0, 0),
		EarL = CFrame.Angles(0, 0, rad(-35)), EarR = CFrame.Angles(0, 0, rad(35))}
end

-- the frozen pond's hole chunks (KitSets.Winter.Ice.Ice1..Ice8): K.iceChunk(i, cf) moves one; every cut puts them back
K.ice = {}
do
	local ice = K.SETS and K.SETS:FindFirstChild("Winter") and K.SETS.Winter:FindFirstChild("Ice")
	if ice then
		for i = 1, 9 do
			local c = ice:FindFirstChild("Ice" .. i)
			if c then K.ice[i] = {p = c, home = c:GetAttribute("Home") or c.CFrame} end
		end
	end
end
K.iceMoved = false
function K.iceChunk(i, cf)
	local c = K.ice[i]
	if c then c.p.CFrame = cf K.iceMoved = true end
end
function K.iceHome(i)
	return K.ice[i] and K.ice[i].home
end
-- open the hole: u 0 = closed, 1 = all chunks tipped and sunk (sinkDepth studs)
function K.iceOpen(u, T, sinkDepth)
	for i, c in K.ice do
		local h = c.home
		local out = (h.Position - K.SPOT.hole) * V(1, 0, 1)
		if out.Magnitude < 0.1 then out = V(0.3, 0, 0.1) end
		local tilt = CFrame.fromAxisAngle(out.Unit:Cross(V(0, 1, 0)), rad(-35 * u + math.sin((T or 0) * 2 + i) * 4 * u))
		c.p.CFrame = CFrame.new(h.Position + out.Unit * 0.6 * u - V(0, (sinkDepth or 1.4) * u, 0)) * tilt * h.Rotation
	end
	K.iceMoved = u > 0
end
function K.iceReset()
	if not K.iceMoved then return end
	for _, c in K.ice do c.p.CFrame = c.home end
	K.iceMoved = false
end
-- crack lines spreading across ice from `center` (deterministic: same T, same cracks). n lines, len studs, grows over dur.
function K.cracks(key, center, t0, T, n, len, dur, seed)
	local set = K.flags["cracks_" .. key]
	if not set then
		set = {}
		local rng = Random.new(seed or 7)
		for i = 1, (n or 10) do
			local a = rng:NextNumber(0, math.pi * 2)
			local segs = {}
			local p = V(0, 0, 0)
			local L = (len or 6) * rng:NextNumber(0.6, 1.2)
			for k = 1, 4 do
				a += rng:NextNumber(-0.5, 0.5)
				local seg = L / 4
				local q = p + V(math.cos(a), 0, math.sin(a)) * seg
				local part = Instance.new("Part")
				part.Anchored, part.CanCollide, part.CanQuery = true, false, false
				part.Material = Enum.Material.Neon
				part.Color = Color3.fromRGB(235, 245, 255)
				part.Size = V(0.09, 0.03, 0.01)
				part.Parent = workspace
				table.insert(S.extra, part)
				table.insert(segs, {part = part, a = p, b = q, k = (i - 1) / (n or 10) * 0.3 + (k - 1) / 4})
				p = q
			end
			table.insert(set, segs)
		end
		K.flags["cracks_" .. key] = set
	end
	local g = math.clamp((T - t0) / (dur or 0.6), 0, 1.3)
	for _, segs in set do
		for _, sg in segs do
			local f = math.clamp((g - sg.k * 0.7) / 0.3, 0, 1)
			if f <= 0 then
				sg.part.CFrame = K.PARK
			else
				local b = sg.a:Lerp(sg.b, f)
				local mid = center + (sg.a + b) / 2
				sg.part.Size = V(0.09, 0.03, math.max(0.02, (b - sg.a).Magnitude))
				sg.part.CFrame = CFrame.lookAt(mid, center + b + V(0, 0, 0.0001))
			end
		end
	end
end
-- a splash: white spray + droplets
function K.splash(pos, n, size)
	K.puffs(pos, n or 14, Color3.fromRGB(235, 245, 255), size or 1.2)
	local a = K.anchor(pos)
	local e = K.emitter(a, K.TEX.sparkle, Color3.fromRGB(190, 225, 255), (size or 1.2) * 0.25, 0.9, 12, 0,
		{Acceleration = V(0, -40, 0), SpreadAngle = Vector2.new(45, 45), LightEmission = 0.3})
	e.EmissionDirection = Enum.NormalId.Top
	e:Emit((n or 14) * 3)
	return a
end
-- rising bubbles (under water)
function K.bubbles(pos, rate)
	local a = K.anchor(pos)
	local e = K.emitter(a, K.TEX.glow, Color3.fromRGB(210, 235, 255), 0.25, 1.2, 3, rate or 12, {LightEmission = 0.2, SpreadAngle = Vector2.new(20, 20)})
	e.EmissionDirection = Enum.NormalId.Top
	return a
end
-- falling snow in a box above pos (w studs wide)
function K.snowfall(pos, w, rate)
	local a = K.anchor(pos)
	a.Size = V(w or 60, 1, w or 60)
	local e = K.emitter(a, K.TEX.glow, Color3.fromRGB(255, 255, 255), 0.22, 7, 3, rate or 120,
		{Shape = Enum.ParticleEmitterShape.Box, LightEmission = 0.4, Acceleration = V(0.6, -1.2, 0),
			Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.85, 0.1), NumberSequenceKeypoint.new(1, 1)})})
	e.EmissionDirection = Enum.NormalId.Bottom
	e.Size = NumberSequence.new(0.22)
	e:Emit((rate or 120) * 4) -- prefill so stills and the first frame already have snow in the air
	return a
end
-- cold breath puffs from an actor's mouth (or a pet's head); call every frame (who = actor or pet name)
function K.breath(who, T, every)
	local key = "breath_" .. who
	local st = K.flags[key]
	if not st then
		local a = K.anchor(K.PARK.Position)
		local e = K.emitter(a, K.TEX.puff, Color3.fromRGB(245, 248, 255), NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.1)}),
			0.8, 1.2, 0, {LightEmission = 0, SpreadAngle = Vector2.new(15, 15),
				Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1)})})
		e.EmissionDirection = Enum.NormalId.Front
		st = {a = a, e = e, last = -1}
		K.flags[key] = st
	end
	local cf
	if K.pets[who] then
		cf = CFrame.lookAt(K.head(who), K.head(who) + K.fwd(who)) * CFrame.new(0, -0.6, -2.4)
	elseif actors[who] then
		cf = actors[who].head.CFrame * CFrame.new(0, -0.25, -0.7)
	end
	if cf then st.a.CFrame = cf end
	local beat = math.floor(T / (every or 1.4))
	if beat ~= st.last then st.last = beat st.e:Emit(6) end
end
-- tint the whole picture this frame (call in update after the preset is applied, e.g. icy-blue underwater)
function K.tint(color, sat, contrast)
	CC.TintColor = color
	if sat then CC.Saturation = sat end
	if contrast then CC.Contrast = contrast end
end
-- an extra light for one shot (cleaned at the cut): a warm lamp pool, window light, moonlight...
function K.lamp(pos, color, brightness, range, shadows)
	local a = K.anchor(pos)
	local l = Instance.new("PointLight")
	l.Color = color or Color3.fromRGB(255, 210, 150)
	l.Brightness = brightness or 2
	l.Range = range or 20
	l.Shadows = shadows ~= false
	l.Parent = a
	return l
end
