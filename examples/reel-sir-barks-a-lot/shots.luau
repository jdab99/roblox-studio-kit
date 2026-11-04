-- Reel 42 "Sir Barks-A-Lot" shot list (times = narration seconds, words.json). Appended after film/core.luau + film/kit.luau:
-- every core local (actors, pos, rootAt, act, P, X/Y/Z, V, camMove, camCF, light, LP, S, HIDE, ReelSets ...) and K are in scope.
-- In my world, your pet becomes whatever you name it. Blocky (base actor) = "I". The dog = pet build ReelSets.Pets.Barks:
-- he barks NONSTOP, every bark = jaw open + a "bark wave" ring from his mouth (R.rings). Always filmed low, face to camera.
local R = {}
local C0 = K.TOWN
R.HOME = C0 + V(250, 0, -120)   -- interior (floor top 0.2), door in the south wall x 7..11
R.ZOO = C0 + V(-260, 0, -125)   -- hamster pen centre; fences at half-size 14 / 18 / 22, front = +Z
R.W0 = C0 + V(120, 0, 430)      -- snowy park centre (snow top 0.2); pond centre W0 + (30, 0, 30), ice radius ~30
R.LOG = R.W0 + V(0, 0, 82)      -- the log (along X) in the trees
R.DS = 0.55                     -- Sir Barks-A-Lot's scale
R.WAVE = Color3.fromRGB(255, 250, 215)

---------------------------------------------------------------- looks
do
	local C = Color3.fromRGB
	LP.home = {ClockTime = 13, Brightness = 2.1, Ambient = C(150, 140, 128), OutdoorAmbient = C(165, 158, 150), Exposure = -0.1,
		Density = 0.2, Haze = 0.6, AColor = C(220, 210, 200), Decay = C(150, 165, 200), Sat = 0.26, Contrast = 0.12, Tint = C(255, 244, 228), Bloom = 0.35, Rays = 0}
	LP.party = {ClockTime = 19, Brightness = 0.9, Ambient = C(130, 108, 98), OutdoorAmbient = C(100, 92, 112), Exposure = -0.2,
		Density = 0.1, Haze = 0, AColor = C(90, 90, 120), Decay = C(50, 50, 80), Sat = 0.26, Contrast = 0.14, Tint = C(255, 236, 214), Bloom = 0.15, Rays = 0}
	LP.memory42 = {ClockTime = 15.5, Brightness = 2.2, Ambient = C(150, 132, 115), OutdoorAmbient = C(170, 155, 140), Exposure = 0.0,
		Density = 0.2, Haze = 0.6, AColor = C(255, 220, 190), Decay = C(200, 170, 150), Sat = 0.02, Contrast = 0.06, Tint = C(255, 232, 205), Bloom = 0.6, Rays = 0}
	LP.night42 = {ClockTime = 0, Brightness = 1.7, Ambient = C(92, 102, 142), OutdoorAmbient = C(128, 140, 188), Exposure = 0.3,
		Density = 0.3, Haze = 1.2, AColor = C(85, 100, 150), Decay = C(40, 50, 90), Sat = 0.12, Contrast = 0.14, Tint = C(226, 234, 255), Bloom = 0.55, Rays = 0}
	LP.bliz = {ClockTime = 0, Brightness = 1.5, Ambient = C(105, 115, 148), OutdoorAmbient = C(132, 144, 182), Exposure = 0.4,
		Density = 0.5, Haze = 2.6, AColor = C(120, 136, 170), Decay = C(96, 110, 145), Sat = 0.06, Contrast = 0.16, Tint = C(222, 230, 252), Bloom = 0.5, Rays = 0}
	LP.darkIn = {ClockTime = 0, Brightness = 0.6, Ambient = C(78, 86, 118), OutdoorAmbient = C(62, 72, 108), Exposure = 0.35,
		Density = 0.1, Haze = 0, AColor = C(80, 90, 130), Decay = C(40, 45, 80), Sat = 0.1, Contrast = 0.15, Tint = C(225, 232, 255), Bloom = 0.6, Rays = 0}
	LP.morning42 = {ClockTime = 9.6, Brightness = 2.4, Ambient = C(128, 132, 148), OutdoorAmbient = C(160, 168, 188), Exposure = -0.35,
		Density = 0.25, Haze = 0.8, AColor = C(210, 225, 245), Decay = C(160, 180, 215), Sat = 0.2, Contrast = 0.12, Tint = C(255, 250, 245), Bloom = 0.2, Rays = 0.05}
	LP.end42 = {ClockTime = 16.5, Brightness = 2.3, Ambient = C(125, 112, 112), OutdoorAmbient = C(155, 140, 140), Exposure = -0.3,
		Density = 0.3, Haze = 1.1, AColor = C(230, 200, 175), Decay = C(130, 140, 175), Sat = 0.24, Contrast = 0.12, Tint = C(255, 240, 222), Bloom = 0.25, Rays = 0.1}
end

---------------------------------------------------------------- hide the kit pines inside our sets (client only)
do
	local NAT = K.SETS and K.SETS:FindFirstChild("Nature")
	local function inZone(p)
		if ((p - R.HOME) * V(1, 0, 1)).Magnitude < 75 then return true end
		if ((p - R.ZOO) * V(1, 0, 1)).Magnitude < 45 then return true end
		return false
	end
	if NAT then
		for _, m in NAT:GetChildren() do
			local ok, p = pcall(function() return m:GetPivot().Position end)
			if ok and inZone(p) then m.Parent = HIDE end
		end
	end
end

---------------------------------------------------------------- reel pets: register like the kit pets
do
	local PF = ReelSets and ReelSets:FindFirstChild("Pets")
	for _, m in (PF and PF:GetChildren() or {}) do
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
function R.ppart(pet, name) local i = K.pets[pet] local e = i and i.byName[name] return e and e[1].p end
-- the mouth of a pet (dogs: under the nose), and its facing
function R.mouth(pet)
	local n = R.ppart(pet, "Nose") or R.ppart(pet, "Head")
	local s = K.pets[pet].s
	local hd = R.ppart(pet, "Head")
	local f = hd and hd.CFrame.LookVector or K.fwd(pet)
	return n.Position - V(0, 0.55 * s, 0) + f * 0.3 * s, f
end
-- bark joints: jaw open + head up on each bark (period p from t0); merges into a base gait
function R.bk(T, t0, p)
	if T < t0 then return 0, -1 end
	local x = (T - t0) / p
	local ph = x % 1
	local k = (ph < 0.5) and math.sin(ph / 0.5 * math.pi) or 0
	return k, math.floor(x)
end
function R.bj(T, t0, p, base)
	local j = {}
	for a, b in (base or {}) do j[a] = b end
	local k = R.bk(T, t0, p or 0.42)
	j.Jaw = X(-40 * k)
	j.Head = (j.Head or CFrame.identity) * X(10 * k)
	j.EarL = (j.EarL or CFrame.identity) * Z(-14 * k)
	j.EarR = (j.EarR or CFrame.identity) * Z(10 * k)
	return j
end
-- BARK WAVES: rings out of the mouth for the last 3 barks (deterministic in T), optional WOOF! word
function R.rings(key, pet, T, t0, p, rs, woof, col)
	p = p or 0.42
	rs = rs or 1
	local pool = K.flags["rg" .. key]
	if not pool then
		pool = {}
		for i = 1, 3 do
			local a = K.anchor(K.PARK.Position)
			local bb, im = K.bill(a, 2, K.TEX.ring, col or R.WAVE, 1, 2)
			bb.AlwaysOnTop = false
			local bb2, im2 = K.bill(a, 2, K.TEX.glow, col or R.WAVE, 1, 1)
			table.insert(pool, {a = a, bb = bb, im = im, bb2 = bb2, im2 = im2})
		end
		local wa = K.anchor(K.PARK.Position)
		local wb = Instance.new("BillboardGui")
		wb.Size = UDim2.new(3, 0, 3, 0)
		wb.LightInfluence = 0
		wb.MaxDistance = 2000
		wb.Parent = wa
		local wl = Instance.new("TextLabel")
		wl.Size = UDim2.fromScale(1, 0.5)
		wl.AnchorPoint = Vector2.new(0.5, 0.5)
		wl.Position = UDim2.fromScale(0.5, 0.5)
		wl.Rotation = K.ROLL
		wl.BackgroundTransparency = 1
		wl.Font = Enum.Font.FredokaOne
		wl.TextScaled = true
		wl.Text = "WOOF!"
		wl.TextColor3 = Color3.fromRGB(255, 215, 50)
		wl.TextTransparency = 1
		wl.Parent = wb
		local st = Instance.new("UIStroke") st.Thickness = 4 st.Color = Color3.fromRGB(30, 20, 20) st.Transparency = 1 st.Parent = wl
		pool.w = {a = wa, bb = wb, l = wl, st = st}
		K.flags["rg" .. key] = pool
	end
	local m, f = R.mouth(pet)
	local _, idx = R.bk(T, t0, p)
	local age0 = (T - t0) % p
	for i, r in ipairs(pool) do
		local bi = idx - (i - 1)
		local age = age0 + (i - 1) * p
		if T >= t0 and bi >= 0 and age < 0.8 then
			local u = age / 0.8
			local sz = (0.9 + 4.6 * u) * rs
			r.a.CFrame = CFrame.new(m + f * (0.4 + 3.2 * u) * rs)
			r.bb.Size = UDim2.new(sz, 0, sz, 0)
			r.im.ImageTransparency = 0.05 + 0.95 * u * u
			r.bb2.Size = UDim2.new(sz * 0.8, 0, sz * 0.8, 0)
			r.im2.ImageTransparency = 0.55 + 0.45 * u
		else
			r.im.ImageTransparency = 1
			r.im2.ImageTransparency = 1
		end
	end
	local w = pool.w
	if woof and T >= t0 and age0 < 0.34 then
		local k = math.clamp(age0 / 0.08, 0, 1)
		local sz = (1.6 + 1.4 * k) * rs * (woof == true and 1 or woof)
		w.bb.Size = UDim2.new(sz, 0, sz, 0)
		w.a.CFrame = CFrame.new(m + f * 1.1 * rs + V(0, 1.6 * rs, 0))
		w.l.TextTransparency = (age0 > 0.26) and (age0 - 0.26) / 0.08 or 0
		w.st.Transparency = w.l.TextTransparency
		w.l.Rotation = K.ROLL + ((idx % 2 == 0) and -8 or 8)
	else
		w.l.TextTransparency = 1
		w.st.Transparency = 1
	end
end
-- pose a pet with its feet at cf (drop = root sinks for sit/lie, in scale-1 studs)
function R.dog(cf, j, drop, s, name)
	s = s or R.DS
	K.pose(name or "Barks", cf * CFrame.new(0, -(drop or 0) * s, 0), j or {}, s)
end
-- the dog barking every frame: pose + jaw + rings in one call
function R.barkDog(name, cf, base, T, t0, p, s, rs, woof, drop)
	R.dog(cf, R.bj(T, t0, p, base), drop, s, name)
	R.rings(name, name, T, t0, p, rs, woof)
end

---------------------------------------------------------------- props + set handles
R.props = {}
if ReelSets and ReelSets:FindFirstChild("Props") then for _, m in ReelSets.Props:GetChildren() do R.props[m.Name] = {m = m, home = m:GetAttribute("Home") or m:GetPivot()} end end
R.usedP = {}
function R.prop(name, cf)
	local p = R.props[name]
	if not p then return nil end
	R.usedP[name] = true
	p.m:PivotTo(cf)
	return p.m
end
R.leafy = {}
do
	local NAT = K.SETS and K.SETS:FindFirstChild("Nature")
	for _, m in (NAT and NAT:GetChildren() or {}) do if m.Name == "StreetTree" then table.insert(R.leafy, m) end end
	R.natF = NAT
end
function R.trees(on)
	if R.treesOn == on then return end
	R.treesOn = on
	for _, m in R.leafy do m.Parent = on and R.natF or HIDE end
end
function R.snow(on) if on then R.prop("SnowTown", CFrame.new(C0)) R.snowOn = true end end
R.lampHeads = {}
do
	local lf = ReelSets and ReelSets:FindFirstChild("Lamps")
	for _, p in (lf and lf:GetChildren() or {}) do if p.Name == "Head" then table.insert(R.lampHeads, p) end end
end
-- street lamps: on/off each (fn(i) -> bool)
function R.lamps(fn)
	for _, h in R.lampHeads do
		local on = fn and fn(h:GetAttribute("I")) or false
		h.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
		h.Color = on and Color3.fromRGB(255, 225, 160) or Color3.fromRGB(90, 90, 85)
		local l = h:FindFirstChildOfClass("PointLight")
		if l then l.Enabled = on end
	end
end
R.homeF = ReelSets and ReelSets:FindFirstChild("Home")
function R.homeLights(on)
	if not R.homeF then return end
	local cl, sh = R.homeF:FindFirstChild("CeilLight"), R.homeF:FindFirstChild("LampShade")
	if cl then cl.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic cl.Color = on and Color3.fromRGB(255, 245, 220) or Color3.fromRGB(150, 150, 150) cl.RoomLight.Enabled = on end
	if sh then sh.LampLight.Enabled = on sh.Material = on and Enum.Material.Neon or Enum.Material.Fabric end
end
function R.window(col)
	local w = R.homeF and R.homeF:FindFirstChild("WinPanel")
	if w then w.Color = col end
end
-- ground point at world (C0.X + x, C0.Z + z) (raycast: lawns, sidewalks, the snow blanket when it is out)
function R.G(x, z)
	local rp = RaycastParams.new()
	local ex = {Film:FindFirstChild("Cast"), Film:FindFirstChild("ReelCast")}
	if K.SETS then table.insert(ex, K.SETS:FindFirstChild("Pets")) table.insert(ex, K.SETS:FindFirstChild("Props")) table.insert(ex, K.SETS:FindFirstChild("Nature")) end
	if ReelSets then table.insert(ex, ReelSets:FindFirstChild("Pets")) table.insert(ex, ReelSets:FindFirstChild("Lamps")) end
	for nm, p in R.props do if nm ~= "SnowTown" then table.insert(ex, p.m) end end
	rp.FilterDescendantsInstances = ex
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local o = V(C0.X + x, 8, C0.Z + z)
	local hit = workspace:Raycast(o, V(0, -20, 0), rp)
	return hit and hit.Position or V(o.X, 0, o.Z)
end

---------------------------------------------------------------- actors: one decal per mood, places, poses
R.MOODS = {happy = 135773001893013, laugh = 140615351309004, scream = 74187334953026, shocked = 87555246095537,
	scared = 82071220644850, dizzy = 120248967875008, angry = 124090698532510, smug = 80289889743945, cry = 139929720410872,
	starry = 95985606586642, focus = 90634447576450, nervous = 90946346829906, wow = 82444194871225, sad = 135482990429946,
	sleep = 70540320410457}
do
	local A = actors.Blocky
	if A and not A.head:FindFirstChild("M_happy") then
		for mood, id in R.MOODS do
			local d = Instance.new("Decal")
			d.Name = "M_" .. mood
			d.Face = Enum.NormalId.Front
			d.Texture = "rbxassetid://" .. id
			d.Transparency = 0.995
			d.Parent = A.head
		end
	end
	-- Blocky's earmuffs (night shots only): welded to his head, hidden unless R.muffs(true)
	R.muffParts = {}
	if A then
		local h = A.head
		local k = h.Size.Y
		local function mp(size, cf, col, shape)
			local p = Instance.new("Part")
			p.Name = "Muff"
			p.Anchored, p.CanCollide, p.CanQuery, p.Massless = false, false, false, true
			p.Size = size
			p.Color = col
			p.Material = Enum.Material.Fabric
			if shape then p.Shape = shape end
			p.CFrame = h.CFrame * cf
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = h, p
			w.Parent = p
			p.Transparency = 1
			p.Parent = A.m
			table.insert(R.muffParts, p)
		end
		for _, s in {-1, 1} do mp(V(0.55, 0.9, 0.9) * k, CFrame.new(s * 1.28 * k, 0.02 * k, 0.05 * k), Color3.fromRGB(80, 170, 230), Enum.PartType.Ball) end
	end
end
function R.muffs(on) for _, p in R.muffParts do p.Transparency = on and 0 or 1 end end
R.moodDecals = {}
function R.face(name, mood)
	local A = actors[name]
	A.used = true
	if not mood then return end
	mood = mood:gsub("2$", "")
	local set = R.moodDecals[name]
	if not set then
		set = {}
		for _, d in A.head:GetChildren() do
			if d:IsA("Decal") and d.Name:sub(1, 2) == "M_" then set[d.Name:sub(3)] = d end
		end
		R.moodDecals[name] = set
	end
	local pick = set[mood]
	if pick then
		A.face.Transparency = 1
		for _, d in set do d.Transparency = (d == pick) and 0 or 0.995 end
	end
end
function R.act(name, mood, animName, speed, pose)
	act(name, nil, animName, speed, pose)
	R.face(name, mood)
end
function R.pose(name, pose) actors[name].used = true S.poses[name] = pose end
function R.at(n, p, tx, tz, dy) pos(n, K.face(p, tx, tz), dy) end
R.HOFF = {}
for name, A in actors do R.HOFF[name] = A.root.CFrame:PointToObjectSpace(A.head.Position) end
function R.head(name)
	local A = actors[name]
	return A.root.CFrame * (R.HOFF[name] or V(0, 1.6, 0)), A.root.CFrame.LookVector
end
function R.fc(name, dist, up, side, h)
	local hp, f = R.head(name)
	local r = f:Cross(V(0, 1, 0))
	return hp + f * dist + V(0, up or 0, 0) + r * (side or 0), hp + V(0, h or 0, 0)
end
function R.hand(name, side)
	local h = actors[name].m:FindFirstChild((side or "Right") .. "Hand")
	return h and h.Position or actors[name].root.Position
end
function R.aim(name, target, side)
	side = side or "Right"
	local A = actors[name]
	local j = A.joints[side .. "Shoulder"]
	local sp
	if j and j:IsA("AnimationConstraint") and j.Attachment0 then sp = j.Attachment0.WorldPosition
	elseif j and j:IsA("Motor6D") then sp = (j.Part0.CFrame * j.C0).Position
	else sp = A.root.Position + V(0, 1, 0) end
	local d = A.root.CFrame:VectorToObjectSpace(target - sp)
	if d.Magnitude < 0.01 then return {} end
	d = d.Unit
	local down = V(0, -1, 0)
	local ax = down:Cross(d)
	local ang = math.acos(math.clamp(down:Dot(d), -1, 1))
	local cf = (ax.Magnitude < 1e-4) and CFrame.identity or CFrame.fromAxisAngle(ax.Unit, ang)
	return {[side .. "Shoulder"] = cf, [side .. "Elbow"] = CFrame.identity}
end
-- a flashlight in an actor's right hand, pointed at target (pose the arm with R.aim first; call after the pose is applied)
function R.torch(i, name, target)
	local h = R.hand(name)
	R.prop("Torch" .. i, CFrame.lookAt(h, target))
end
-- poses
R.WALK = function(T, sp, amp) local a = math.sin(T * (sp or 8)) * (amp or 25) return {RightHip = X(a), LeftHip = X(-a), RightKnee = X(-8 - math.abs(a) * 0.3), LeftKnee = X(-8 - math.abs(a) * 0.3), RightShoulder = X(-a * 0.7), LeftShoulder = X(a * 0.7)} end
R.RUN = function(T, sp) local a = math.sin(T * (sp or 13)) * 40 return {RightHip = X(a), LeftHip = X(-a), RightKnee = X(-25 - math.abs(a) * 0.6), LeftKnee = X(-25 - math.abs(a) * 0.6), RightShoulder = X(-a * 0.9), LeftShoulder = X(a * 0.9), RightElbow = X(60), LeftElbow = X(60), Waist = X(10)} end
R.CHEER = {RightShoulder = X(165) * Z(15), LeftShoulder = X(165) * Z(-15), Neck = X(8)}
R.YELL = {Waist = X(-8), Neck = X(12), RightShoulder = X(130) * Z(-35), RightElbow = X(70), LeftShoulder = X(130) * Z(35), LeftElbow = X(70)}
R.POINT = {RightShoulder = X(95), Neck = X(4)}
R.HAMMER = function(T) local a = math.abs(math.sin(T * 9)) return {RightShoulder = X(60 + 90 * a), RightElbow = X(20), Waist = X(14), LeftShoulder = X(40)} end
R.SLUMP = {Waist = X(18), Neck = X(-22), RightShoulder = Z(8), LeftShoulder = Z(-8)}
R.CARRY = {RightShoulder = X(70) * Z(-10), LeftShoulder = X(70) * Z(10), RightElbow = X(45), LeftElbow = X(45)}
function R.talk(T, base) return merge(base or {}, {Neck = X(math.sin(T * 9) * 3) * ((base and base.Neck) or CFrame.identity)}) end
function R.once(key, fn) if not K.flags[key] then K.flags[key] = true fn() end end

---------------------------------------------------------------- VFX helpers
function R.mk(size, col, mat, shape, tr)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.CastShadow = false
	p.Size = size
	p.Color = col
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = tr or 0
	if shape then p.Shape = shape end
	p.CFrame = K.PARK
	p.Parent = workspace
	table.insert(S.extra, p)
	return p
end
-- camera-facing card (names, numbers, signs over things); pops in at t0
function R.card(key, pos, text, T, t0, w, bg, fg, font, gone)
	local c = K.flags["card" .. key]
	if T < t0 or (gone and T >= gone) then if c then c.sg.Enabled = false c.p.CFrame = K.PARK end return end
	if not c then
		local p = K.anchor(pos)
		p.Size = V(w, w * 0.32, 0.02)
		p.CastShadow = false
		local sg = Instance.new("SurfaceGui")
		sg.Face = Enum.NormalId.Front
		sg.CanvasSize = Vector2.new(312, 100)
		sg.LightInfluence = 0
		sg.Parent = p
		local f = Instance.new("TextLabel")
		f.Size = UDim2.fromScale(0.97, 0.92)
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.BackgroundColor3 = bg or Color3.new(1, 1, 1)
		f.BackgroundTransparency = bg == false and 1 or 0
		f.TextColor3 = fg or Color3.fromRGB(20, 20, 25)
		f.Font = font or Enum.Font.FredokaOne
		f.TextScaled = true
		f.Text = text
		f.Parent = sg
		local cr = Instance.new("UICorner") cr.CornerRadius = UDim.new(0.25, 0) cr.Parent = f
		local st = Instance.new("UIStroke") st.Thickness = 4 st.Color = Color3.fromRGB(20, 20, 25)
		st.ApplyStrokeMode = (bg == false) and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border st.Parent = f
		p.Transparency = 1
		c = {p = p, sg = sg, w = w, f = f}
		K.flags["card" .. key] = c
	end
	c.sg.Enabled = true
	local k = math.clamp((T - t0) / 0.12, 0, 1)
	local sc = (0.5 + 0.5 * k) * (1 + 0.12 * math.sin(math.clamp((T - t0) / 0.25, 0, 1) * math.pi))
	c.p.Size = V(c.w * sc, c.w * 0.32 * sc, 0.02)
	c.p.CFrame = CFrame.lookAt(pos, camCF.Position)
	return c
end
-- a puff burst once at t0
function R.puffAt(key, pos, T, t0, n, size, col)
	if T >= t0 and not K.flags["pf" .. key] then
		K.flags["pf" .. key] = true
		K.puffs(pos, n or 10, col or Color3.fromRGB(250, 245, 235), size or 0.9)
	end
end
-- flashback look (warm wash + soft bright edges)
function R.memory(on)
	if on and (not R.mg or not R.mg.Parent) then
		local g = Instance.new("ScreenGui")
		g.Name = "ReelMemory"
		g.IgnoreGuiInset = true
		g.DisplayOrder = 40
		g.ResetOnSpawn = false
		local wash = Instance.new("Frame")
		wash.Size = UDim2.fromScale(1, 1)
		wash.BackgroundColor3 = Color3.fromRGB(255, 205, 150)
		wash.BackgroundTransparency = 0.86
		wash.BorderSizePixel = 0
		wash.Parent = g
		local function edge(p, size, rot)
			local f = Instance.new("Frame")
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = p
			f.Size = size
			f.BackgroundColor3 = Color3.fromRGB(255, 240, 220)
			f.BorderSizePixel = 0
			f.Parent = g
			local gr = Instance.new("UIGradient")
			gr.Rotation = rot
			gr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1)})
			gr.Parent = f
		end
		edge(UDim2.fromScale(0.5, 0.07), UDim2.fromScale(1, 0.14), 90)
		edge(UDim2.fromScale(0.5, 0.93), UDim2.fromScale(1, 0.14), -90)
		edge(UDim2.fromScale(0.06, 0.5), UDim2.fromScale(0.12, 1), 0)
		edge(UDim2.fromScale(0.94, 0.5), UDim2.fromScale(0.12, 1), 180)
		g.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
		R.mg = g
	end
	if R.mg then R.mg.Enabled = on end
end
-- BLIZZARD: sideways snow streaming across the frame (box in front of the camera, wind along the camera's right)
function R.bliz(T, rate, wind)
	local b = K.flags.bliz
	if not b then
		local a = K.anchor(K.PARK.Position)
		a.Size = V(26, 18, 10)
		local e = K.emitter(a, K.TEX.glow, Color3.fromRGB(240, 245, 255), 0.16, 1.3, 0, rate or 260,
			{Shape = Enum.ParticleEmitterShape.Box, LightEmission = 0.35, Drag = 0,
				Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 1)})})
		e.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.12)})
		e.Rotation = NumberRange.new(0, 0)
		e.RotSpeed = NumberRange.new(0, 0)
		e.Orientation = Enum.ParticleOrientation.VelocityParallel
		e.Squash = NumberSequence.new(1.7)
		b = {a = a, e = e}
		K.flags.bliz = b
	end
	local look = camCF.LookVector
	local right = camCF.RightVector
	b.a.CFrame = CFrame.lookAt(camCF.Position + look * 9, camCF.Position + look * 20)
	b.e.Acceleration = right * (wind or 38) * 1.25 + V(0, -5, 0)
	b.e.Speed = NumberRange.new(4, 8)
	b.e.SpreadAngle = Vector2.new(10, 10)
	b.e.EmissionDirection = Enum.NormalId.Right
	if not b.pre then b.pre = true b.e:Emit((rate or 260) * 1.2) end
end
-- a soft light that rides with the camera (faces read at night)
function R.fill(br, col, range)
	local f = K.flags.fill
	if not f then f = K.lamp(K.PARK.Position, col or Color3.fromRGB(205, 220, 255), br or 0.9, range or 18, false) K.flags.fill = f end
	f.Parent.CFrame = CFrame.new(camCF.Position + V(0, 1.2, 0) - camCF.LookVector * 0.5)
end
-- a speech bubble near a point (world), returns label
function R.bubble(key, pos, text, studs)
	local b = K.flags["bb" .. key]
	if not b then
		local a = K.anchor(pos)
		local bb, l = K.say(a, text, studs or 5)
		bb.StudsOffsetWorldSpace = V(0, 0, 0)
		b = {a = a, bb = bb, l = l}
		K.flags["bb" .. key] = b
	end
	b.a.CFrame = CFrame.new(pos)
	return b
end

---------------------------------------------------------------- per-shot wrapper + cameras
function R.reset()
	for nm in R.usedP do local p = R.props[nm] p.m:PivotTo(p.home) end
	R.usedP = {}
	R.memory(false)
	R.muffs(false)
	R.lamps(nil)
	R.homeLights(true)
	R.window(Color3.fromRGB(140, 200, 245))
	R.snowOn = false
end
function R.cut(t, preset, setup, update)
	K.sh(t, preset, function()
		R.reset()
		setup()
		R.trees(not R.snowOn)
	end, function(T, u)
		update(T, u)
		cam.Focus = CFrame.new(camCF.Position + camCF.LookVector * 10)
	end)
end
local Cm = {}
R.Cm = Cm
function Cm.face(name, dist, side, up, h, push, fov, shT, shA)
	return function(T, u)
		local e1, l1 = R.fc(name, dist, up or 0, side or 0, h or 0)
		local e2 = e1 + (l1 - e1).Unit * (push or 0.6)
		local sh = shT and K.shake(T, shT, 0.35, shA or 0.25) or V(0, 0, 0)
		camMove(e1 + sh, l1, e2 + sh, l1, u, fov or 45)
	end
end
function Cm.pet(pet, dist, up, side, h, push, fov, shT, shA)
	return function(T, u)
		local e1, l1 = K.frontCam(pet, dist, up or 0, side or 0, h or 0)
		local e2 = e1 + (l1 - e1).Unit * (push or 0.6)
		local sh = shT and K.shake(T, shT, 0.35, shA or 0.3) or V(0, 0, 0)
		camMove(e1 + sh, l1, e2 + sh, l1, u, fov or 48)
	end
end
function Cm.fix(e1, l1, e2, l2, fov, shT, shA)
	return function(T, u)
		local sh = shT and K.shake(T, shT, 0.35, shA or 0.3) or V(0, 0, 0)
		camMove(e1 + sh, l1, (e2 or e1) + sh, l2 or l1, u, fov or 50)
	end
end
-- whip-in: look starts `side` off and whips onto l (speed lines mid-whip)
function R.whipLook(T, t0, l, side, dur)
	local w = K.whip(T, t0, dur or 0.16)
	return l + side * (1 - w)
end
-- ground points used a lot
R.LEE = function() return R.G(-60, -31) end
R.OURS = function() return R.G(62, -31) end
R.GRE = function() return R.G(118, -31) end
R.KIDY = function() return R.G(60, 30) end
R.UNC = function() return R.G(-60, 30) end
R.H = function(x, z) return R.HOME + V(x, 0.2, z) end

---------------------------------------------------------------- THE SHOTS
---------------------------------------------------------------- HOOK: the rule happening (0 - 2.55)
-- 0.00 "In my world" : Mrs. Lee yells FLUFFY! and her cat POOFS into a giant fluff ball (shake, flash, whoosh+boom)
R.cut(0.0, "golden", function()
	local g = R.LEE()
	R.at("MrsLee", g + V(-6.2, 0, 0.5), g.X, g.Z + 6)
	R.act("MrsLee", "wow", nil, 1, R.CHEER)
	K.dof(9, 3, 0.4, 0)
end, function(T, u)
	local g = R.LEE()
	local k = math.clamp((T - 0.12) / 0.3, 0, 1)
	local el = (k >= 1) and 1 or (1 - math.exp(-6 * k) * math.cos(k * 14))
	if T < 0.12 then
		K.pose("Cat", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Tail = X(math.sin(T * 9) * 15)}, 1.2)
	else
		K.pose("Cat", K.PARK, {}, 1)
		K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Body = X(math.sin(T * 13) * 3)}, math.max(0.25, 1.25 * el))
	end
	R.puffAt("poof", g + V(1, 2.5, 0), T, 0.12, 26, 2.2)
	R.bubble("fl", R.head("MrsLee") + V(0.5, 2.2, 0), "FLUFFY!", 5.5)
	K.flash(T > 0.12 and T < 0.2 and 0.5 or 0)
	local e = g + V(1.5, 2.8, 14)
	local l = g + V(-1.8, 4.2, 0)
	camMove(e + K.shake(T, 0.12, 0.4, 0.5), l, e + V(-0.6, 0, -2.2) + K.shake(T, 0.12, 0.4, 0.5), l, u, 60)
end)
-- 0.55 "world," : push in on the fluff ball's tiny face, it bounces
R.cut(0.55, "golden", function() K.dof(6, 2, 0.4, 0) end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Body = X(math.sin(T * 10) * 4)}, 1.25 * (1 + 0.05 * math.sin(T * 20)))
	local hp = K.head("Fluff")
	camMove(hp + V(0.8, -0.6, 12), hp + V(0, 0.2, 0), hp + V(0.4, -0.4, 9.5), hp + V(0, 0.2, 0), u, 52)
end)
-- 0.95 "your pet becomes" : the hamster GROWS huge behind the zoo fences (whip in)
R.cut(0.95, "golden", function() K.dof(nil) end, function(T, u)
	local k = math.clamp((T - 0.98) / 0.42, 0, 1)
	local s = 1 + 10 * (1 - (1 - k) ^ 3)
	K.pose("Hamster", K.face(R.ZOO, R.ZOO.X, R.ZOO.Z + 20), {}, s)
	local e = R.ZOO + V(9, 11.5, 33)
	local l = R.ZOO + V(0, 3 + 4 * k, 0)
	camMove(e + K.shake(T, 1.3, 0.3, 0.35), R.whipLook(T, 0.95, l, V(-14, 0, 0), 0.14), e + V(0, 0.5, -2), l, u, 62)
end)
-- 1.48 "whatever you" : the uncle's goldfish and lottery tickets raining, uncle cheering
R.cut(1.48, "golden", function()
	local g = R.UNC()
	R.prop("BigTicket", CFrame.new(g + V(-2.4, 6.6, -1.2)) * Y(180))
	R.at("Uncle", g + V(-2.4, 0, 0), g.X - 2.4, g.Z - 10)
	R.act("Uncle", "starry", nil, 1, R.CHEER)
	K.dof(10, 4, 0.35, 0)
	K.flags.tix = {}
	local rng = Random.new(3)
	for i = 1, 22 do
		local p = R.mk(V(1.2, 0.6, 0.04), (i % 3 == 0) and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(255, 225, 70))
		table.insert(K.flags.tix, {p = p, x = rng:NextNumber(-6, 6), z = rng:NextNumber(-3, 4), ph = rng:NextNumber(0, 6), sp = rng:NextNumber(5, 8)})
	end
end, function(T, u)
	local g = R.UNC()
	R.bowl(T)
	for _, t in K.flags.tix do
		local y = 14 - ((T * t.sp + t.ph * 3) % 14)
		t.p.CFrame = CFrame.new(g + V(t.x, y, t.z)) * CFrame.Angles(T * 3 + t.ph, T * 2, t.ph)
	end
	local e = g + V(1, 3.4, -9)
	local l = g + V(0, 4.4, 0)
	camMove(e + K.shake(T, 1.48, 0.25, 0.3), l, e + V(0, 0, 1.5), l, u, 60)
end)
-- 2.02 "name it." : Sir Barks-A-Lot barking straight into the camera (rings + WOOF)
R.cut(2.02, "goldenClose", function() K.dof(5, 2, 0.45, 0) end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X, g.Z + 10), K.DOG.stand(T, 0, 30), T, 2.06, 0.38, R.DS, 1, true)
	local e, l = K.frontCam("Barks", 4.5, -0.2, 0.6, -0.1)
	camMove(e + K.shake(T, 2.06, 0.3, 0.3), l, e + (l - e).Unit * 1.2, l, u, 52)
end)

---------------------------------------------------------------- Mrs. Lee + Fluffy (2.55 - 6.6)
-- 2.55 "Mrs. Lee named her cat"
R.cut(2.55, "golden", function()
	local g = R.LEE()
	R.at("MrsLee", g + V(-4.2, 0, -0.5), g.X + 1, g.Z)
	R.act("MrsLee", "happy", "idle", 0.7, {RightShoulder = X(70) * Z(-20), Neck = Y(-10)})
	K.dof(10, 4, 0.35, 0)
end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 3, g.Z + 10), {Body = X(math.sin(T * 4) * 2)}, 1.25)
	camMove(g + V(-1.5, 2.4, 11), g + V(-1.5, 3.6, 0), g + V(-1, 2.6, 9), g + V(-1.5, 3.6, 0), u, 55)
end)
-- 3.27 "cat Fluffy." : Mrs. Lee close, calling FLUFFY!
R.cut(3.27, "goldenClose", function()
	local g = R.LEE()
	R.at("MrsLee", g + V(-4.2, 0, -0.5), g.X + 1, g.Z + 2)
	R.act("MrsLee", "starry", nil, 1, merge(R.CHEER, {LeftShoulder = X(40)}))
	K.dof(4, 1.5, 0.5, 0)
end, function(T, u)
	R.bubble("fl2", R.head("MrsLee") + V(-0.6, 1.9, 0), "FLUFFY!", 4)
	Cm.face("MrsLee", 4.6, 1.2, 0, 0.2, 0.7, 48)(T, u)
end)
-- 4.07 "It's ninety percent" : the fluff ball front on, 90% FLUFF card pops over it
R.cut(4.07, "golden", function() K.dof(nil) end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Body = X(math.sin(T * 6) * 3)}, 1.25)
	R.card("90", g + V(1, 10.4, 0.5), "90% FLUFF", T, 4.25, 7, Color3.fromRGB(255, 220, 60))
	camMove(g + V(1.5, 2.2, 13.5), g + V(1, 5.6, 0), g + V(1.2, 2.2, 11.5), g + V(1, 5.6, 0), u, 55)
end)
-- 4.67 "fluff now." : Blocky beside it, tiny, shocked (the ball is taller than him)
R.cut(4.67, "golden", function()
	local g = R.LEE()
	R.at("Blocky", g + V(5.6, 0, 1.5), g.X + 1, g.Z)
	R.act("Blocky", "shocked", nil, 1, {Neck = X(14)})
	K.dof(nil)
end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Body = X(math.sin(T * 6) * 3)}, 1.25)
	local c = g + V(3, 3.5, 0.5)
	camMove(c + V(math.sin(rad(40 - 25 * u)) * 13, -1.2, math.cos(rad(40 - 25 * u)) * 13), c, nil, nil, 0, 55)
end)
-- 5.44 "You can lose a shoe" : Blocky steps INTO the fluff, his leg vanishes to the knee
R.cut(5.44, "golden", function()
	local g = R.LEE()
	K.dof(7, 3, 0.35, 0)
end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {Body = X(math.sin(T * 6) * 2)}, 1.25)
	R.at("Blocky", g + V(4.4 - 0.5 * u, 0, 1.2), g.X + 1, g.Z)
	R.act("Blocky", (u < 0.35) and "focus" or "shocked", nil, 1, {RightHip = X(55 * math.min(u * 2.5, 1)), RightKnee = X(-30), LeftShoulder = Z(-35), RightShoulder = Z(35)})
	local e = g + V(9, 2.2, 7)
	camMove(e, g + V(4, 2.4, 1), e + V(-0.8, 0, -0.8), g + V(4, 2.4, 1), u, 52)
end)
-- 6.05 "in it." : a red sneaker sinks into the fluff and is gone (puff)
R.cut(6.05, "goldenClose", function()
	K.dof(4, 1.5, 0.5, 0)
	K.flags.shoe = {R.mk(V(0.9, 0.5, 1.6), Color3.fromRGB(220, 40, 40)), R.mk(V(0.95, 0.15, 1.65), Color3.fromRGB(250, 250, 250))}
end, function(T, u)
	local g = R.LEE()
	K.pose("Fluff", K.face(g + V(1, 0, 0), g.X + 1, g.Z + 10), {}, 1.25)
	local k = math.clamp((T - 6.12) / 0.4, 0, 1)
	local p = g + V(2.8, 5.6 - 2.5 * k, 3.0 - 1.6 * k)
	K.flags.shoe[1].CFrame = CFrame.new(p) * CFrame.Angles(0.4, 0.6 + T, 0.2)
	K.flags.shoe[2].CFrame = CFrame.new(p) * CFrame.Angles(0.4, 0.6 + T, 0.2) * CFrame.new(0, -0.3, 0)
	R.puffAt("shoe", g + V(2.4, 4.5, 2.0), T, 6.45, 12, 1.0)
	camMove(g + V(7.5, 5.4, 13), g + V(2.5, 4.4, 2), g + V(7, 5.3, 11.5), g + V(2.5, 4.2, 2), u, 50)
end)

---------------------------------------------------------------- the hamster Godzilla (6.6 - 11.15)
-- 6.60 "The kid next door" : the kid on his lawn holding a tiny hamster
R.cut(6.6, "golden", function()
	local g = R.KIDY()
	R.at("KidNext", g, g.X, g.Z - 10)
	R.act("KidNext", "happy", nil, 1, {RightShoulder = X(22) * Z(-8), LeftShoulder = X(22) * Z(8), RightElbow = X(50), LeftElbow = X(50)})
	K.dof(6, 2.5, 0.4, 0)
end, function(T, u)
	local h = (R.hand("KidNext") + R.hand("KidNext", "Left")) / 2
	K.pose("Hamster", K.face(h + V(0, 0.05, 0), h.X, h.Z - 10), {}, 1)
	Cm.face("KidNext", 5.5, -1.2, -0.6, -0.5, 0.8, 50)(T, u)
end)
-- 7.20 "named his hamster" : close on the hamster in his hands
R.cut(7.2, "goldenClose", function()
	local g = R.KIDY()
	R.at("KidNext", g, g.X, g.Z - 10)
	R.act("KidNext", "happy", nil, 1, {RightShoulder = X(40) * Z(-8), LeftShoulder = X(40) * Z(8), RightElbow = X(55), LeftElbow = X(55), Neck = X(-12)})
	K.dof(3, 1.2, 0.5, 0)
end, function(T, u)
	local h = (R.hand("KidNext") + R.hand("KidNext", "Left")) / 2
	K.pose("Hamster", K.face(h + V(0, 0.05, 0), h.X + math.sin(T * 3), h.Z - 10), {}, 1)
	local hp = K.head("Hamster")
	camMove(hp + V(0.4, 0.4, -3.2), hp, hp + V(0.3, 0.3, -2.4), hp, u, 48)
end)
-- 7.74 "Godzilla." : it GROWS in his hands, the kid is knocked flat, shake + boom
R.cut(7.74, "golden", function()
	local g = R.KIDY()
	K.dof(nil)
end, function(T, u)
	local g = R.KIDY()
	local k = math.clamp((T - 7.8) / 0.45, 0, 1)
	local s = 1 + 9 * (1 - (1 - k) ^ 3)
	local fall = math.clamp((T - 7.95) / 0.3, 0, 1)
	R.at("KidNext", g + V(0, 0, 1.5 + 2.5 * fall), g.X, g.Z - 10)
	R.act("KidNext", "scream", nil, 1, {RightShoulder = X(150) * Z(-30), LeftShoulder = X(150) * Z(30), Waist = X(-25 * fall), Neck = X(-10)})
	K.pose("Hamster", K.face(g + V(0, 0, -3 - 3 * k), g.X, g.Z - 20), {}, s)
	local e = g + V(-15, 2.4, -1)
	camMove(e + K.shake(T, 7.9, 0.5, 0.6), g + V(0, 3 + 3 * k, -3), e + V(-1.5, 0.5, 0) + K.shake(T, 7.9, 0.5, 0.6), g + V(0, 3 + 4 * k, -3), u, 64)
end)
-- 8.57 "It lives at the zoo now." : the zoo, the giant hamster in its pen
R.cut(8.57, "golden", function() K.dof(nil) end, function(T, u)
	K.pose("Hamster", K.face(R.ZOO, R.ZOO.X + math.sin(T * 0.8) * 4, R.ZOO.Z + 20), {}, 11)
	camMove(R.ZOO + V(14, 12, 34), R.ZOO + V(0, 6, 0), R.ZOO + V(11, 11.5, 32), R.ZOO + V(0, 6, 0), u, 58)
end)
-- 9.28 "now." : low close on the giant hamster's face, chewing
R.cut(9.28, "goldenClose", function() K.dof(13, 5, 0.4, 0.3) end, function(T, u)
	K.pose("Hamster", K.face(R.ZOO, R.ZOO.X, R.ZOO.Z + 20) * CFrame.new(0, math.abs(math.sin(T * 14)) * 0.15, 0), {}, 11)
	camMove(R.ZOO + V(-3, 3, 26), R.ZOO + V(0, 8, 0), R.ZOO + V(-2, 3, 24.5), R.ZOO + V(0, 8, 0), u, 52)
end)
-- 9.87 "Behind three fences." : the camera slides past three fence rings, a big 3 pops
R.cut(9.87, "golden", function() K.dof(nil) end, function(T, u)
	K.pose("Hamster", K.face(R.ZOO, R.ZOO.X, R.ZOO.Z + 20), {}, 11)
	R.card("3", R.ZOO + V(0, 17.5, 3), "3 FENCES", T, 10.22, 9, Color3.fromRGB(255, 220, 60))
	camMove(R.ZOO + V(-15, 3, 30), R.ZOO + V(0, 8, 0), R.ZOO + V(9, 3.5, 28), R.ZOO + V(0, 9, 0), u, 58)
end)
-- 10.44 "fences." : Blocky + the kid at the outer fence, looking up, shocked
R.cut(10.44, "golden", function()
	R.at("Blocky", R.ZOO + V(-2.2, 0.12, 24.5), R.ZOO.X - 2, R.ZOO.Z)
	R.act("Blocky", "wow", nil, 1, {Neck = X(18), RightShoulder = X(90), LeftShoulder = X(90), RightElbow = X(10)})
	R.at("KidNext", R.ZOO + V(2.2, 0.12, 24.5), R.ZOO.X + 2, R.ZOO.Z)
	R.act("KidNext", "sad", nil, 1, {Neck = X(18)})
	K.dof(nil)
end, function(T, u)
	K.pose("Hamster", K.face(R.ZOO, R.ZOO.X, R.ZOO.Z + 20), {}, 11)
	camMove(R.ZOO + V(0, 2.4, 33), R.ZOO + V(0, 7, 0), R.ZOO + V(0, 2.2, 31), R.ZOO + V(0, 7.5, 0), u, 60)
end)

---------------------------------------------------------------- the uncle + Lucky (11.15 - 14.47)
R.tixSetup = function(n, seed)
	K.flags.tix = {}
	local rng = Random.new(seed or 3)
	for i = 1, n do
		local p = R.mk(V(1.2, 0.6, 0.04), (i % 3 == 0) and Color3.fromRGB(120, 220, 120) or Color3.fromRGB(255, 225, 70))
		table.insert(K.flags.tix, {p = p, x = rng:NextNumber(-6, 6), z = rng:NextNumber(-4, 4), ph = rng:NextNumber(0, 6), sp = rng:NextNumber(4, 7)})
	end
end
R.tixRain = function(g, T, on)
	for _, t in (K.flags.tix or {}) do
		local y = on and (14 - ((T * t.sp + t.ph * 3) % 14)) or -300
		t.p.CFrame = CFrame.new(g + V(t.x, y, t.z)) * CFrame.Angles(T * 3 + t.ph, T * 2, t.ph)
	end
end
R.bowlC = function()
	local m = K.props.FishBowl.m
	local best, bs = nil, 0
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency > 0.15 and p.Transparency < 0.95 and p.Size.Magnitude > bs then best, bs = p, p.Size.Magnitude end
	end
	return best and best.Position or m:GetPivot().Position
end
R.bowl = function(T)
	local g = R.UNC()
	K.prop("FishBowl", CFrame.new(g + V(2.5, 0, 0)))
	K.pose("Goldfish", CFrame.new(R.bowlC() + V(0, -0.2, 0)) * Y(-90 + math.sin(T * 2.5) * 40), {Tail = Y(math.sin(T * 12) * 25)}, 1)
end
-- 11.15 "My uncle named his goldfish"
R.cut(11.15, "golden", function()
	local g = R.UNC()
	R.at("Uncle", g + V(-1.2, 0, 1.2), g.X + 2.5, g.Z)
	R.act("Uncle", "happy", "idle", 0.7, {RightShoulder = X(60) * Z(-15)})
	K.dof(8, 3, 0.35, 0)
end, function(T, u)
	local g = R.UNC()
	R.bowl(T)
	camMove(g + V(3, 3.4, -9), g + V(1, 4.2, 0), g + V(2.5, 3.6, -7.6), g + V(1, 4.2, 0), u, 52)
end)
-- 11.90 "goldfish Lucky." : close on the bowl, a LUCKY card pops over the fish
R.cut(11.9, "goldenClose", function() K.dof(3.2, 1.4, 0.5, 0) end, function(T, u)
	local g = R.UNC()
	R.bowl(T)
	local c = R.bowlC()
	camMove(c + V(0.5, 0.4, -5.2), c, c + V(0.3, 0.4, -4.2), c + V(0, 0.2, 0), u, 50)
end)
-- 12.44 "Lucky." : tight on the fish, the LUCKY card pops
R.cut(12.44, "goldenClose", function() K.dof(2.6, 1.2, 0.5, 0) end, function(T, u)
	R.bowl(T)
	R.card("lucky", R.bowlC() + V(0, 1.9, 0), "LUCKY", T, 12.5, 2.6, Color3.fromRGB(110, 220, 120))
	local c = R.bowlC()
	camMove(c + V(-1.2, 0.8, -4.0), c + V(0, 0.6, 0), c + V(-0.9, 0.8, -3.3), c + V(0, 0.7, 0), u, 50)
end)
-- 13.06 "It has won the lottery" : tickets raining, uncle holding the WINNER ticket
R.cut(13.06, "golden", function()
	local g = R.UNC()
	R.at("Uncle", g + V(-1.2, 0, 1.2), g.X - 1.2, g.Z - 10)
	R.act("Uncle", "starry", nil, 1, R.CHEER)
	R.tixSetup(26, 5)
	K.dof(7, 3, 0.4, 0)
end, function(T, u)
	local g = R.UNC()
	R.bowl(T)
	R.tixRain(g, T, true)
	local h = (R.hand("Uncle") + R.hand("Uncle", "Left")) / 2
	R.prop("BigTicket", CFrame.lookAt(h + V(0, 0.8, 0), camCF.Position))
	Cm.face("Uncle", 7, -1.5, -1.2, 0.5, 1.2, 55, 13.1, 0.2)(T, u)
end)
-- 13.88 "twice." : a SECOND ticket slams in, x2 card, shake
R.cut(13.88, "golden", function()
	local g = R.UNC()
	R.at("Uncle", g + V(-1.2, 0, 1.2), g.X - 1.2, g.Z - 10)
	R.act("Uncle", "laugh", "jump", 1.4, nil)
	R.tixSetup(30, 9)
	K.dof(nil)
end, function(T, u)
	local g = R.UNC()
	R.bowl(T)
	R.tixRain(g, T, true)
	R.card("x2", g + V(-1.2, 8.6, 0.6), "x2", T, 13.95, 3.4, Color3.fromRGB(255, 80, 80), Color3.new(1, 1, 1))
	local e = g + V(-1, 3, -11)
	camMove(e + K.shake(T, 13.95, 0.35, 0.45), g + V(-0.5, 4.8, 0), e + V(0, 0, 2) + K.shake(T, 13.95, 0.35, 0.45), g + V(-0.5, 4.8, 0), u, 60)
end)

---------------------------------------------------------------- the puppy flashback (14.47 - 19.49)
R.memSet = function()
	R.memory(true)
	R.window(Color3.fromRGB(170, 215, 245))
end
-- 14.47 "When I was four," : little Blocky on the rug, happy, flashback look
R.cut(14.47, "memory42", function()
	R.memSet()
	R.at("BlockyKid", R.H(-3, 1), R.HOME.X + 4, R.HOME.Z - 2)
	R.act("BlockyKid", "happy", "idle", 0.8, nil)
	K.dof(5, 2, 0.4, 0)
end, function(T, u)
	Cm.face("BlockyKid", 4.4, 1.2, 0.1, -0.2, 0.8, 48)(T, u)
end)
-- 15.36 "my parents let me" : Mom + Dad on the couch side, smiling down
R.cut(15.36, "memory42", function()
	R.memSet()
	R.at("Mom", R.H(-7, -3), R.HOME.X - 2, R.HOME.Z + 2)
	R.act("Mom", "happy", "idle", 0.6, {Neck = X(-12)})
	R.at("Dad", R.H(-7.6, 0.6), R.HOME.X - 2, R.HOME.Z + 2)
	R.act("Dad", "happy", "idle", 0.6, {Neck = X(-12), RightShoulder = X(30) * Z(-20)})
	R.at("BlockyKid", R.H(-3, 1), R.HOME.X - 7, R.HOME.Z - 1)
	R.act("BlockyKid", "happy", nil, 1, {Neck = X(14)})
	K.dof(7, 3, 0.4, 0)
end, function(T, u)
	camMove(R.H(-1.5, -6.5) + V(0, 3.6, 0), R.H(-6, 0.5) + V(0, 4.4, 0), R.H(-2.2, -6) + V(0, 3.8, 0), R.H(-6, 0.5) + V(0, 4.6, 0), u, 55)
end)
-- 16.10 "name our puppy." : the puppy on the rug, low, big eyes, tail going
R.cut(16.1, "memory42", function()
	R.memSet()
	K.dof(3.5, 1.5, 0.5, 0)
end, function(T, u)
	R.dog(K.face(R.H(-0.5, 1.5), R.HOME.X + 4, R.HOME.Z + 6), merge(K.DOG.sit(T, 12, 40), {Jaw = X(-8)}), K.PUP.sitDrop, 0.95, "BarksPup")
	local e, l = K.frontCam("BarksPup", 4.2, 0.0, -0.6, 0)
	camMove(e, l, e + (l - e).Unit * 1.2, l, u, 50)
end)
-- 16.98 "I named him" : little Blocky points at the puppy, proud
R.cut(16.98, "memory42", function()
	R.memSet()
	R.at("BlockyKid", R.H(-3, 1), R.HOME.X - 0.5, R.HOME.Z + 1.5)
	R.act("BlockyKid", "starry", nil, 1, merge(R.aim("BlockyKid", R.H(-0.5, 1.5) + V(0, 1, 0)), {Neck = X(-6)}))
	K.dof(4.5, 2, 0.4, 0)
end, function(T, u)
	R.dog(K.face(R.H(-0.5, 1.5), R.HOME.X - 1.5, R.HOME.Z + 10), K.DOG.sit(T, 8, 40), K.PUP.sitDrop, 0.95, "BarksPup")
	camMove(R.H(-1.8, 8.5) + V(0, 2.6, 0), R.H(-1.8, 1.3) + V(0, 2.2, 0), R.H(-1.8, 7.6) + V(0, 2.6, 0), R.H(-1.8, 1.3) + V(0, 2.2, 0), u, 55)
end)
-- 17.51 "Sir Barks-A-Lot." : the name card pops over the puppy, and he barks for the first time (first ring)
R.cut(17.51, "memory42", function()
	R.memSet()
	K.dof(4, 1.8, 0.45, 0)
end, function(T, u)
	R.barkDog("BarksPup", K.face(R.H(-0.5, 1.5), R.HOME.X + 4, R.HOME.Z + 6), K.DOG.sit(T, 0, 40), T, 18.05, 0.4, 0.95, 0.7, true, K.PUP.sitDrop)
	R.card("name1", K.head("BarksPup") + V(0, 2.9, 0), "SIR BARKS-A-LOT", T, 17.6, 5.4, Color3.fromRGB(255, 220, 60))
	local e, l = K.frontCam("BarksPup", 5, 0.3, 0.4, 1.2)
	camMove(e, l, e + (l - e).Unit * 0.8, l, u, 55)
end)
-- 18.64 "I was four." : Mom + Dad's faces: Dad facepalm, Mom nervous
R.cut(18.64, "memory42", function()
	R.memSet()
	R.at("Mom", R.H(-6.4, -1.6), R.HOME.X + 4, R.HOME.Z + 4)
	R.act("Mom", "nervous", nil, 1, {Neck = X(-8)})
	R.at("Dad", R.H(-6.8, 1.4), R.HOME.X + 4, R.HOME.Z + 4)
	R.act("Dad", "dizzy", nil, 1, P.facepalm)
	K.dof(5, 2.5, 0.4, 0)
end, function(T, u)
	local hm, hd = R.head("Mom"), R.head("Dad")
	local c = (hm + hd) / 2
	camMove(c + V(5.2, -0.4, 2.2), c, c + V(4.4, -0.3, 1.9), c, u, 50)
end)

---------------------------------------------------------------- he never stops (19.49 - 26.66)
-- 19.49 "Sir Barks-A-Lot" : grown up, on our lawn, barking at the camera (low)
R.cut(19.49, "goldenClose", function() K.dof(5, 2, 0.45, 0) end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X + 2, g.Z + 10), K.DOG.stand(T, 0, 35), T, 19.5, 0.4, R.DS, 1, true)
	local e, l = K.frontCam("Barks", 5.2, -0.4, -1.0, 0)
	camMove(e, l, e + (l - e).Unit * 1.4, l, u, 52)
end)
-- 20.18 "has not stopped" : Blocky next to him, hands over his ears
R.cut(20.18, "golden", function()
	local g = R.OURS()
	R.at("Blocky", g + V(-3.2, 0, -0.5), g.X - 1, g.Z + 10)
	R.act("Blocky", "dizzy", nil, 1, P.earsCover)
	K.dof(7, 3, 0.4, 0)
end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X + 1, g.Z + 10), K.DOG.stand(T, 0, 35), T, 20.2, 0.38, R.DS, 1, false)
	camMove(g + V(1.5, 2.6, 9.5), g + V(-1.5, 3.2, 0), g + V(1, 2.7, 8.4), g + V(-1.5, 3.2, 0), u, 55)
end)
-- 20.86 "barking since." : side angle, bark after bark (WOOF)
R.cut(20.86, "goldenClose", function() K.dof(5, 2, 0.4, 0) end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X + 10, g.Z + 4), K.DOG.stand(T, 6, 35), T, 20.9, 0.34, R.DS, 1, true)
	local e, l = K.frontCam("Barks", 3.6, -0.4, 3.2, 0)
	camMove(e, l + K.fwd("Barks") * 1.2, e + (l - e).Unit * 0.6, l + K.fwd("Barks") * 1.2, u, 52)
end)
-- 21.91 "He barks when he eats." : the food bowl, kibble flies out with every bark
R.cut(21.91, "home", function()
	K.prop("FoodBowl", CFrame.new(R.H(4, 5)))
	K.dof(4.5, 2, 0.45, 0)
	K.flags.kib = {}
	for i = 1, 14 do table.insert(K.flags.kib, R.mk(V(0.28, 0.2, 0.28), Color3.fromRGB(140, 85, 45))) end
end, function(T, u)
	R.barkDog("Barks", K.face(R.H(4, 7.6), R.HOME.X + 4, R.HOME.Z + 5), {Head = X(-22)}, T, 21.95, 0.42, R.DS, 0.9, true)
	local k, idx = R.bk(T, 21.95, 0.42)
	local age = (T - 21.95) % 0.42
	for i, p in K.flags.kib do
		local a = i * 2.4 + idx
		local v = V(math.cos(a) * 2.2, 6 + (i % 3), math.sin(a) * 2.2 - 1.5)
		local pp = R.H(4, 5) + V(0, 0.6, 0) + v * age + V(0, -20 * age * age, 0)
		p.CFrame = (T > 21.95 and pp.Y > R.HOME.Y) and CFrame.new(pp) * CFrame.Angles(a, age * 9, 0) or K.PARK
	end
	camMove(R.H(1.6, 2.6) + V(0, 1.6, 0), R.H(4, 6.2) + V(0, 1.6, 0), R.H(2.2, 3.4) + V(0, 1.5, 0), R.H(4, 6.2) + V(0, 1.6, 0), u, 52)
end)
-- 22.57 "eats." : close: his face in the bowl, kibble everywhere
R.cut(22.57, "home", function()
	K.prop("FoodBowl", CFrame.new(R.H(4, 5)))
	K.dof(3, 1.4, 0.5, 0)
end, function(T, u)
	R.barkDog("Barks", K.face(R.H(4, 7.6), R.HOME.X + 4, R.HOME.Z + 5), {Head = X(-12)}, T, 22.6, 0.36, R.DS, 0.9, true)
	local e, l = K.frontCam("Barks", 3.2, -0.6, 0.7, -0.2)
	camMove(e, l, e + (l - e).Unit * 0.6, l, u, 50)
end)
-- 23.10 "He barks in his sleep." : asleep in his dog bed, eyes shut, still barking (Zzz + rings)
R.cut(23.1, "party", function()
	R.homeLights(true)
	K.prop("DogBed", CFrame.new(R.H(-6, 8)))
	R.window(Color3.fromRGB(30, 40, 80))
	K.dof(5, 2, 0.4, 0)
end, function(T, u)
	local base = K.DOG.lie(T, false, 0)
	R.barkDog("Barks", K.face(R.H(-6, 8) + V(0, 0.45, 0), R.HOME.X, R.HOME.Z + 4), base, T, 23.15, 0.5, R.DS, 0.8, true, K.DOG.lieDrop)
	K.petFace("Barks", "closed", false, nil)
	R.card("zzz", K.head("Barks") + V(1.2, 2.2 + (T * 0.8) % 1, 0), "z Z z", T, 23.1, 2.2, false, Color3.new(1, 1, 1))
	local e, l = K.frontCam("Barks", 5.2, 0.6, -1.4, 0.2)
	camMove(e, l, e + (l - e).Unit * 1.2, l, u, 52)
end)
-- 23.71 "sleep." : closer, his sleeping face, mouth going
R.cut(23.71, "party", function()
	K.prop("DogBed", CFrame.new(R.H(-6, 8)))
	R.window(Color3.fromRGB(30, 40, 80))
	K.dof(2.8, 1.2, 0.5, 0)
end, function(T, u)
	R.barkDog("Barks", K.face(R.H(-6, 8) + V(0, 0.45, 0), R.HOME.X, R.HOME.Z + 4), K.DOG.lie(T, false, 0), T, 23.75, 0.46, R.DS, 0.7, false, K.DOG.lieDrop)
	K.petFace("Barks", "closed", false, nil)
	R.card("zzz2", K.head("Barks") + V(0.9, 1.6 + (T * 0.8) % 1, 0), "z Z z", T, 23.71, 1.6, false, Color3.new(1, 1, 1))
	local e, l = K.frontCam("Barks", 3.0, 0.1, 0.8, 0)
	camMove(e, l, e + (l - e).Unit * 0.5, l, u, 48)
end)
-- birthday table: banner, cake, family
R.party = function(T, blown)
	R.prop("Banner", CFrame.new(R.H(2.5, -12.2) + V(0, 10.2, 0)))
	R.prop("Cake", CFrame.new(R.H(3.8, -4.2) + V(0, 3.04, 0)))
	local cake = R.props.Cake.m
	for _, f in cake:GetChildren() do
		if f.Name == "Flame" then
			f.Transparency = (T >= blown) and 1 or 0
			f.Size = V(0.16, 0.3 + 0.06 * math.sin(T * 30 + f.Position.X * 9), 0.16)
		end
	end
end
-- 24.33 "He barked through my whole birthday," : Blocky behind the cake, the dog barking at the table
R.cut(24.33, "party", function()
	R.at("Blocky", R.H(6.4, -9.6), R.HOME.X + 6.4, R.HOME.Z)
	R.act("Blocky", "sad", "idle", 0.6, nil)
	R.at("Mom", R.H(1.2, -9.4), R.HOME.X + 4, R.HOME.Z - 4)
	R.act("Mom", "nervous", "idle", 0.6, nil)
	R.at("Juniper", R.H(8.6, -9.0), R.HOME.X + 6, R.HOME.Z - 4)
	R.act("Juniper", "laugh", "idle", 0.8, nil)
	K.dof(9, 3.5, 0.35, 0)
end, function(T, u)
	R.party(T, 99)
	R.barkDog("Barks", K.face(R.H(10.5, -0.5), R.HOME.X + 6, R.HOME.Z - 4.5), K.DOG.stand(T, 0, 40), T, 24.35, 0.4, R.DS, 0.9, true)
	camMove(R.H(5, 3) + V(0, 5.2, 0), R.H(5.5, -7) + V(0, 4.4, 0), R.H(5, 2) + V(0, 5.2, 0), R.H(5.5, -7) + V(0, 4.4, 0), u, 58)
end)
-- 25.14 "birthday," : Blocky's face over the cake, done with it
R.cut(25.14, "party", function()
	R.at("Blocky", R.H(6.4, -9.6), R.HOME.X + 6.4, R.HOME.Z)
	R.act("Blocky", "angry", nil, 1, {Neck = X(-4)})
	K.dof(4, 1.6, 0.45, 0)
end, function(T, u)
	R.party(T, 99)
	Cm.face("Blocky", 4.6, -0.8, 0.9, -0.3, 0.6, 46)(T, u)
end)
-- 25.50 "including the candles." : a bark wave hits the cake and blows every candle out
R.cut(25.5, "party", function() K.dof(3.6, 1.6, 0.45, 0) end, function(T, u)
	R.party(T, 25.93)
	R.barkDog("Barks", K.face(R.H(7.4, -3.4), R.HOME.X + 5, R.HOME.Z - 5), {Head = X(18)}, T, 25.7, 0.5, R.DS, 1.2, true)
	R.puffAt("smoke", R.H(3.8, -4.2) + V(0, 4.8, 0), T, 25.93, 10, 0.5, Color3.fromRGB(200, 200, 205))
	local c = R.H(3.8, -4.2) + V(0, 4.3, 0)
	camMove(c + V(-1.8, 0.6, 3.6), c, c + V(-1.4, 0.5, 2.9), c, u, 50)
end)

---------------------------------------------------------------- Mr. Greer's signs (26.66 - 33.75)
-- 26.66 "Our neighbor Mr. Greer" : on his lawn in his bathrobe, glaring, arms crossed
R.cut(26.66, "goldenClose", function()
	local g = R.GRE()
	R.at("Greer", g, g.X - 6, g.Z + 10)
	R.act("Greer", "angry", "idle", 0.5, {RightShoulder = X(72) * Z(-28), LeftShoulder = X(72) * Z(28), RightElbow = X(100), LeftElbow = X(100)})
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	Cm.face("Greer", 5.2, 1.4, -0.6, -0.3, 0.9, 48)(T, u)
end)
-- 27.50 "put a sign in his yard." : hammering Sign1 into the lawn
R.cut(27.5, "golden", function()
	local g = R.GRE()
	R.at("Greer", g + V(1.8, 0, 0), g.X - 6, g.Z)
	R.act("Greer", "angry", nil, 1, nil)
	K.dof(7, 3, 0.4, 0)
end, function(T, u)
	local g = R.GRE()
	local k = math.abs(math.sin(T * 9))
	R.prop("Sign1", K.face(g + V(-1.5, -0.6 + 0.4 * (1 - math.clamp((T - 27.5) / 1.2, 0, 1)) + 0.12 * k, 0), g.X - 1.5, g.Z + 10))
	R.pose("Greer", R.HAMMER(T))
	camMove(g + V(-4, 2.4, 9), g + V(0, 3, 0), g + V(-3.4, 2.5, 8), g + V(0, 3, 0), u, 52)
end)
-- 28.80 "Quiet please." : the sign, readable, the dog barking in the background next door
R.cut(28.8, "golden", function()
	K.dof(6, 3, 0.45, 0)
end, function(T, u)
	local g = R.GRE()
	R.prop("Sign1", K.face(g + V(-1.5, -0.6, 0), g.X - 1.5, g.Z + 10))
	local d = R.G(86, -26)
	R.barkDog("Barks", K.face(d, d.X + 10, d.Z + 2), K.DOG.stand(T, 0, 30), T, 28.85, 0.4, R.DS, 1.2, true)
	camMove(g + V(-0.5, 2.6, 6.5), g + V(-1.5, 2.9, 0), g + V(-1, 2.7, 5.6), g + V(-1.5, 2.9, 0), u, 55)
end)
-- 29.66 "Then a bigger sign." : Sign2 SLAMS down onto the lawn (shake + dust)
R.cut(29.66, "golden", function() K.dof(nil) end, function(T, u)
	local g = R.GRE()
	local k = math.clamp((T - 29.7) / 0.25, 0, 1)
	R.prop("Sign2", K.face(g + V(-3, -0.8 + 9 * (1 - k * k), -1), g.X - 3, g.Z + 10))
	R.prop("Sign1", K.face(g + V(5, -0.6, 1), g.X + 5, g.Z + 10))
	R.puffAt("slam", g + V(-3, 0.5, 0), T, 29.95, 18, 1.5, Color3.fromRGB(150, 130, 100))
	local e = g + V(-1, 3, 17)
	camMove(e + K.shake(T, 29.95, 0.4, 0.5), g + V(-2, 5, 0), e + V(0, 0, -1.5) + K.shake(T, 29.95, 0.4, 0.5), g + V(-2, 5, 0), u, 58)
end)
-- 30.63 "QUIET PLEASE." : the huge sign, low, Greer tiny beside it, pointing
R.cut(30.63, "golden", function()
	local g = R.GRE()
	R.at("Greer", g + V(5, 0, 1), g.X - 2, g.Z + 10)
	R.act("Greer", "angry", nil, 1, R.aim("Greer", g + V(-3, 6, -1)))
	K.dof(nil)
end, function(T, u)
	local g = R.GRE()
	R.prop("Sign2", K.face(g + V(-3, -0.8, -1), g.X - 3, g.Z + 10))
	camMove(g + V(0, 1.4, 14), g + V(-1, 5.4, 0), g + V(0.5, 1.4, 12.5), g + V(-1, 5.4, 0), u, 62)
end)
-- 31.68 "Then a sign that just said," : Greer slumped next to a tiny sign, exhausted
R.cut(31.68, "goldenClose", function()
	local g = R.GRE()
	R.at("Greer", g + V(1.2, 0, 0.5), g.X - 4, g.Z + 10)
	R.act("Greer", "sad", nil, 1, R.SLUMP)
	K.dof(6, 2.5, 0.45, 0)
end, function(T, u)
	local g = R.GRE()
	R.prop("Sign2", K.face(g + V(-6, -0.8, -5), g.X - 6, g.Z + 10))
	R.prop("Sign3", K.face(g + V(-1.6, -0.5, 1.2), g.X - 1.6, g.Z + 10))
	camMove(g + V(-2.5, 2.4, 9), g + V(0, 3.2, 0), g + V(-2.2, 2.4, 7.6), g + V(0, 3.1, 0), u, 52)
end)
-- 33.01 "why." : close on the tiny "why" sign (crickets)
R.cut(32.85, "goldenClose", function() K.dof(3.5, 1.4, 0.5, 0) end, function(T, u)
	local g = R.GRE()
	R.prop("Sign3", K.face(g + V(-1.6, -0.5, 1.2), g.X - 1.6, g.Z + 10))
	R.at("Greer", g + V(1.2, 0, 0.5), g.X - 4, g.Z + 10)
	R.act("Greer", "sad", nil, 1, R.SLUMP)
	local c = g + V(-1.6, 2.2, 1.2)
	camMove(c + V(0.2, 0.2, 3.6), c, c + V(0.1, 0.2, 3.0), c, u, 48)
end)

---------------------------------------------------------------- Juniper (33.75 - 38.55)
-- 33.75 "My little sister Juniper is three." : tiny Juniper on our lawn, low camera at her height
R.cut(33.75, "goldenClose", function()
	local g = R.OURS()
	R.at("Juniper", g, g.X - 1, g.Z + 10)
	R.act("Juniper", "happy", "idle", 0.9, nil)
	K.dof(4, 1.8, 0.45, 0)
end, function(T, u)
	Cm.face("Juniper", 4.6, -1.0, 0.1, -0.1, 1.0, 48)(T, u)
end)
-- 34.67 "is three." : she waves, a 3 card pops
R.cut(34.67, "goldenClose", function()
	local g = R.OURS()
	R.at("Juniper", g, g.X + 1, g.Z + 10)
	R.act("Juniper", "laugh", "wave", 1, nil)
	K.dof(3.2, 1.5, 0.5, 0)
end, function(T, u)
	R.card("three", R.head("Juniper") + V(-1.6, 1.6, 0.5), "3", T, 34.79, 1.4, Color3.fromRGB(255, 130, 185), Color3.new(1, 1, 1))
	Cm.face("Juniper", 3.4, 0.6, 0.2, 0.2, 0.5, 48)(T, u)
end)
-- the nearest street tree to (x, z) (C0-relative): its trunk base
function R.tree(x, z)
	local NAT = K.SETS and K.SETS:FindFirstChild("Nature")
	local best, bd = C0 + V(x, 0, z), 1e9
	for _, m in (NAT and NAT:GetChildren() or {}) do
		if m.Name == "StreetTree" then
			local p = m:GetPivot().Position
			local d = ((p - (C0 + V(x, 0, z))) * V(1, 0, 1)).Magnitude
			if d < bd then best, bd = p, d end
		end
	end
	return V(best.X, 0, best.Z)
end
-- 35.35 "She names everything." : she points at the tree: a BOB tag pops on it
R.cut(35.35, "golden", function()
	local tr = R.tree(62, -21)
	R.at("Juniper", tr + V(-4, 0, -4) + V(0, R.G(tr.X - C0.X - 4, tr.Z - C0.Z - 4).Y, 0), tr.X, tr.Z)
	R.act("Juniper", "starry", nil, 1, R.aim("Juniper", tr + V(0, 3, 0)))
	K.dof(nil)
end, function(T, u)
	local tr = R.tree(62, -21)
	R.card("bob", tr + V(-0.8, 4.2, -1.4), "BOB", T, 35.55, 2.6, Color3.new(1, 1, 1), Color3.fromRGB(255, 70, 160), Enum.Font.PermanentMarker)
	camMove(tr + V(-7, 2.2, -0.8), tr + V(-2.6, 2.8, -3.4), tr + V(-6.4, 2.3, -1.0), tr + V(-2.6, 3.0, -3.4), u, 56)
end)
-- 35.95 "everything." : she points at Blocky: STEVE on his head. Blocky unimpressed
R.cut(35.95, "goldenClose", function()
	local g = R.OURS()
	R.at("Blocky", g + V(3, 0, 1), g.X, g.Z + 6)
	R.act("Blocky", "smug", nil, 1, nil)
	R.at("Juniper", g + V(-0.6, 0, 3.5), g.X + 3, g.Z + 1)
	R.act("Juniper", "laugh", nil, 1, R.aim("Juniper", g + V(3, 4.5, 1)))
	K.dof(6, 2.5, 0.4, 0)
end, function(T, u)
	R.card("steve", R.head("Blocky") + V(0, 2.1, 0), "STEVE", T, 36.05, 3, Color3.new(1, 1, 1), Color3.fromRGB(255, 70, 160), Enum.Font.PermanentMarker)
	local g = R.OURS()
	camMove(g + V(1.5, 3, 10.5), g + V(1.4, 3.4, 1.5), g + V(1.4, 3, 9.4), g + V(1.4, 3.4, 1.5), u, 52)
end)
-- 36.47 "Her shoes are named Kevin." : LOW close on the pink boots, KEVIN readable
R.cut(36.47, "goldenClose", function()
	local g = R.OURS()
	R.at("Juniper", g, g.X, g.Z + 10)
	R.act("Juniper", "happy", nil, 1, {Neck = X(-18), RightHip = Z(10), LeftHip = Z(-10)})
	K.dof(2.2, 1, 0.5, 0)
end, function(T, u)
	local A = actors.Juniper
	local c = (A.m.LeftLowerLeg.Position + A.m.RightLowerLeg.Position) / 2
	camMove(c + V(0.3, 0.25, 3.0), c, c + V(0.2, 0.2, 2.4), c, u, 46)
end)
-- 37.15 "Kevin." : Juniper looks down at them, proud
R.cut(37.15, "goldenClose", function()
	local g = R.OURS()
	R.at("Juniper", g, g.X, g.Z + 10)
	R.act("Juniper", "starry", nil, 1, {Neck = X(-12), RightShoulder = Z(30), LeftShoulder = Z(-30)})
	K.dof(3.4, 1.5, 0.5, 0)
end, function(T, u)
	Cm.face("Juniper", 3.6, -0.4, 0.6, -0.5, 0.4, 48)(T, u)
end)
-- 37.72 "Both of them." : slide from the left boot to the right boot
R.cut(37.72, "goldenClose", function()
	local g = R.OURS()
	R.at("Juniper", g, g.X, g.Z + 10)
	R.act("Juniper", "happy", nil, 1, {RightHip = Z(10), LeftHip = Z(-10)})
	K.dof(2.2, 1, 0.5, 0)
end, function(T, u)
	local A = actors.Juniper
	local l, r = A.m.LeftLowerLeg.Position, A.m.RightLowerLeg.Position
	camMove(r + V(-0.2, 0.1, 2.3), r, l + V(0.2, 0.1, 2.3), l, u, 44)
end)

---------------------------------------------------------------- winter night, the power, the blizzard (38.55 - 48.94)
-- 38.55 "One night in winter," : the street under snow at night, lamps on, soft snow falling
R.cut(38.55, "night42", function()
	R.snow(true)
	R.lamps(function() return true end)
	K.snowfall(C0 + V(100, 30, -10), 90, 160)
	K.dof(nil)
end, function(T, u)
	camMove(C0 + V(40, 3, 14), C0 + V(120, 5, -22), C0 + V(46, 3.4, 13), C0 + V(120, 5, -22), u, 55)
end)
-- 39.47 "the power went out" : the lamps die one after another down the street
R.cut(39.47, "night42", function()
	R.snow(true)
	K.snowfall(C0 + V(100, 30, -10), 90, 160)
end, function(T, u)
	R.lamps(function(i) return T < 39.84 + (i - 1) * 0.11 end)
	camMove(C0 + V(-60, 3.2, -2), C0 + V(120, 8, -20), C0 + V(-56, 3.2, -2), C0 + V(120, 8, -20), u, 50)
end)
-- 40.38 "across the whole town." : high over the dark town, the last lamps going out
R.cut(40.38, "night42", function()
	R.snow(true)
	K.snowfall(C0 + V(100, 40, 0), 140, 200)
end, function(T, u)
	R.lamps(function(i) return T < 40.5 + (8 - i) * 0.04 end)
	camMove(C0 + V(100, 60, 110), C0 + V(100, 0, -20), C0 + V(100, 52, 100), C0 + V(100, 0, -20), u, 55)
end)
-- 41.31 "Then the snow came in sideways." : our house, snow BLASTING sideways, Blocky at the door in his earmuffs
R.cut(41.31, "bliz", function()
	R.snow(true)
	local g = R.OURS()
	R.at("Blocky", g + V(0, 0, -2), g.X, g.Z + 10)
	R.act("Blocky", "scared", nil, 1, merge(P.scared, {Neck = Y(15)}))
	R.muffs(true)
	K.dof(5, 2.5, 0.4, 0)
end, function(T, u)
	R.bliz(T, 320, 42)
	R.fill(0.8)
	Cm.face("Blocky", 6, 2, -0.6, -0.4, 1.2, 52)(T, u)
end)
-- 42.11 "sideways." : the dog in the snow, ears blown back, squinting
R.cut(42.11, "bliz", function()
	R.snow(true)
	K.dof(4, 2, 0.45, 0)
end, function(T, u)
	local g = R.OURS()
	R.dog(K.face(g + V(2, 0, 2), g.X + 2, g.Z + 12), merge(K.DOG.stand(T, 0, 0), {EarL = Z(-60) * X(-30), EarR = Z(40) * X(-30), Head = X(-6)}))
	K.petFace("Barks", "squint", false, "sad")
	R.bliz(T, 320, 46)
	R.fill(0.9)
	local e, l = K.frontCam("Barks", 4.4, -0.3, 0.8, 0)
	camMove(e, l, e + (l - e).Unit * 0.8, l, u, 50)
end)
-- 42.88 "And Juniper was gone." : torch on the couch: her little pink blanket, empty (music turns)
R.cut(42.88, "darkIn", function()
	R.homeLights(false)
	R.window(Color3.fromRGB(25, 30, 55))
	R.at("Blocky", R.H(-4, -1), R.HOME.X - 12, R.HOME.Z - 1)
	R.act("Blocky", "shocked", nil, 1, merge(R.aim("Blocky", R.H(-12, -1.5) + V(0, 2.4, 0)), {}))
	R.muffs(true)
	local bl = R.mk(V(2.4, 0.3, 2.8), Color3.fromRGB(255, 140, 190), Enum.Material.Fabric)
	bl.CFrame = CFrame.new(R.H(-12, -1.5) + V(0, 2.15, 0)) * Y(15)
	local pl = R.mk(V(1.6, 0.6, 1.2), Color3.fromRGB(250, 250, 250), Enum.Material.Fabric)
	pl.CFrame = CFrame.new(R.H(-12.4, -4.2) + V(0, 2.3, 0))
	K.dof(nil)
end, function(T, u)
	R.torch(1, "Blocky", R.H(-12, -1.5) + V(0, 2.2, 0))
	R.fill(0.35, Color3.fromRGB(150, 170, 230), 14)
	camMove(R.H(-2.5, 3.5) + V(0, 4.2, 0), R.H(-10, -1.5) + V(0, 2.8, 0), R.H(-3.2, 3.0) + V(0, 4.0, 0), R.H(-10, -1.5) + V(0, 2.8, 0), u, 55)
end)
-- 43.45 "was gone." : Blocky's face in the dark, the flashlight under it
R.cut(43.45, "darkIn", function()
	R.homeLights(false)
	R.window(Color3.fromRGB(25, 30, 55))
	R.at("Blocky", R.H(-4, -1), R.HOME.X + 4, R.HOME.Z + 2)
	R.act("Blocky", "scared", nil, 1, {RightShoulder = X(60), RightElbow = X(40)})
	R.muffs(true)
	K.dof(4, 1.8, 0.45, 0)
end, function(T, u)
	local hp = R.head("Blocky")
	R.torch(1, "Blocky", hp + V(6, -3, 3))
	R.fill(0.7, Color3.fromRGB(180, 195, 240), 12)
	Cm.face("Blocky", 4.2, -1, -0.3, -0.1, 0.6, 46)(T, u)
end)
-- 44.33 "Her boots were gone from the door." : torch beam on the empty pink mat under KEVIN + KEVIN
R.cut(44.33, "darkIn", function()
	R.homeLights(false)
	R.window(Color3.fromRGB(25, 30, 55))
	R.at("Blocky", R.H(3.6, 4.5), R.HOME.X + 5, R.HOME.Z + 12)
	R.act("Blocky", "scared", nil, 1, R.aim("Blocky", R.H(5, 11.4) + V(0, 1, 0)))
	R.muffs(true)
	K.dof(nil)
end, function(T, u)
	R.torch(1, "Blocky", R.H(5.1, 11.4) + V(0, 0.8, 0))
	R.fill(0.3, Color3.fromRGB(150, 170, 230), 14)
	camMove(R.H(1.4, 6.2) + V(0, 4.4, 0), R.H(5.1, 11.6) + V(0, 2, 0), R.H(2.2, 7.0) + V(0, 4.0, 0), R.H(5.1, 11.6) + V(0, 2, 0), u, 55)
end)
-- 45.80 "Both Kevins." : close on the crayon label in the torch light, nothing under it
R.cut(45.8, "darkIn", function()
	R.homeLights(false)
	R.at("Blocky", R.H(3.6, 5.5), R.HOME.X + 5, R.HOME.Z + 12)
	R.act("Blocky", "sad", nil, 1, R.aim("Blocky", R.H(5, 12.2) + V(0, 3, 0)))
	K.dof(3.5, 1.5, 0.45, 0)
end, function(T, u)
	R.torch(1, "Blocky", R.H(5, 12.3) + V(0, 3.2, 0))
	local c = R.H(5, 12.3) + V(0, 2.4, 0)
	camMove(c + V(0.4, 0.2, -4.6), c, c + V(0.2, 0.1, -3.8), c, u, 50)
end)
-- 46.79 "She'd gone out to see the snow." : the open door, little footprints leading out into the blizzard
R.cut(46.79, "bliz", function()
	R.homeLights(false)
	K.dof(nil)
end, function(T, u)
	R.bliz(T, 240, 30)
	local c = R.H(9, 18)
	camMove(R.H(8.4, 9.6) + V(0, 1.4, 0), c + V(0, 0.4, 0), R.H(8.8, 11.4) + V(0, 1.2, 0), c + V(0.5, 0.6, 6), u, 55)
end)
-- 47.37 "the snow." : (what she did) tiny Juniper walking out into the snow, from behind, curious
R.cut(47.37, "bliz", function()
	R.at("Juniper", R.H(9, 22), R.HOME.X + 10, R.HOME.Z + 60)
	R.act("Juniper", "wow", nil, 1, nil)
	K.dof(5, 3, 0.4, 0)
end, function(T, u)
	R.pose("Juniper", R.WALK(T, 7, 22))
	R.at("Juniper", R.H(9 + u * 0.3, 22 + (T - 47.37) * 2.2), R.HOME.X + 10, R.HOME.Z + 60)
	R.bliz(T, 260, 36)
	R.fill(0.9)
	local hp = R.head("Juniper")
	camMove(hp + V(-1.6, 0.4, -5), hp + V(0, -0.3, 2), hp + V(-1.4, 0.3, -4.6), hp + V(0, -0.3, 2), u, 52)
end)
-- 48.16 "In the dark." : wide, her small figure going into the dark snow
R.cut(48.16, "bliz", function()
	R.at("Juniper", R.H(9.5, 26), R.HOME.X + 10, R.HOME.Z + 60)
	R.act("Juniper", "wow", nil, 1, nil)
	K.dof(nil)
end, function(T, u)
	R.pose("Juniper", R.WALK(T, 7, 22))
	R.at("Juniper", R.H(9.5, 26 + (T - 48.16) * 2.2), R.HOME.X + 10, R.HOME.Z + 60)
	R.bliz(T, 300, 40)
	camMove(R.H(9, 13.5) + V(0, 2.2, 0), R.H(9.5, 30) + V(0, 1.6, 0), R.H(9, 13.0) + V(0, 2.4, 0), R.H(9.5, 30) + V(0, 1.6, 0), u, 48)
end)

---------------------------------------------------------------- the search (48.94 - 58.65)
-- everyone with flashlights on the snowy street (positions round SP)
R.SP = function() return R.G(110, 2) end
R.party2 = function(T, moods, aimAt)
	local g = R.SP()
	local who = {{"Blocky", V(0, 0, 0)}, {"Dad", V(-3.5, 0, -2.5)}, {"Mom", V(3.5, 0, -2)}, {"N1", V(-7, 0, -5)}, {"N2", V(7, 0, -4.5)}, {"N3", V(-10, 0, -9)}, {"N4", V(10, 0, -8.5)}}
	for i, w in ipairs(who) do
		local p = g + w[2]
		local tgt = (aimAt or g + V(0, 0, 30)) + V(math.sin(T * 1.3 + i) * 3, 0, 0)
		R.at(w[1], p, tgt.X, tgt.Z)
		R.act(w[1], (moods and moods[i]) or "nervous", nil, 1, merge(R.aim(w[1], tgt + V(0, 1.5, 0)), {LeftShoulder = Z(-10)}))
	end
	R.muffs(true)
	return who
end
R.torches = function(T, aimAt)
	local g = R.SP()
	local list = {"Blocky", "Dad", "Mom", "N1", "N2", "N3"}
	for i, n in ipairs(list) do
		local tgt = (aimAt or g + V(0, 0, 30)) + V(math.sin(T * 1.3 + i) * 3, 1.5, 0)
		R.torch(i, n, tgt)
	end
end
-- 48.94 "Everybody came out with flashlights." : the group fans out, beams sweeping
R.cut(48.94, "bliz", function()
	R.snow(true)
	R.party2(48.94)
	K.dof(nil)
end, function(T, u)
	R.party2(T)
	R.torches(T)
	R.bliz(T, 200, 30)
	R.fill(0.8, nil, 22)
	local g = R.SP()
	camMove(g + V(2, 3, 13), g + V(0, 3.4, -3), g + V(1.5, 3.2, 11.5), g + V(0, 3.4, -3), u, 60)
end)
-- 49.63 "flashlights." : close on Mom + Dad sweeping their beams
R.cut(49.63, "bliz", function()
	R.snow(true)
	R.party2(49.63)
	K.dof(5, 3, 0.4, 0)
end, function(T, u)
	R.party2(T)
	R.torches(T)
	R.bliz(T, 220, 34)
	R.fill(0.9)
	local g = R.SP()
	local c = g + V(0, 4.6, -2.2)
	camMove(c + V(-1.5, -0.4, 7.5), c, c + V(1.5, -0.4, 7.0), c, u, 55)
end)
-- 50.30 "Mr. Greer too." : Mr. Greer in his bathrobe with a big flashlight, determined
R.cut(50.3, "bliz", function()
	R.snow(true)
	local g = R.G(118, -4)
	R.at("Greer", g, g.X - 6, g.Z + 12)
	R.act("Greer", "focus", nil, 1, R.aim("Greer", g + V(-6, 1.5, 12)))
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	local g = R.G(118, -4)
	R.torch(1, "Greer", g + V(-6, 1.2, 12))
	R.bliz(T, 260, 38)
	R.fill(1.0)
	Cm.face("Greer", 5, -1.6, -0.5, -0.2, 1.2, 48)(T, u)
end)
-- 51.34 "But the snow was so thick" : a wall of snow, the beams just stop in it
R.cut(51.34, "bliz", function()
	R.snow(true)
	R.party2(51.34)
	K.dof(nil)
end, function(T, u)
	R.party2(T)
	R.torches(T)
	R.bliz(T, 520, 48)
	camMove(R.SP() + V(1.5, 4.2, -9), R.SP() + V(0, 3, 20), R.SP() + V(1.2, 4.0, -7.5), R.SP() + V(0, 3, 20), u, 58)
end)
-- 52.28 "you couldn't see your own hand." : Blocky holds his hand up to his face: it is barely there
R.cut(52.28, "bliz", function()
	R.snow(true)
	local g = R.SP()
	R.at("Blocky", g, g.X, g.Z + 12)
	R.act("Blocky", "nervous", nil, 1, {RightShoulder = X(120) * Z(-18), RightElbow = X(55), Neck = X(-4)})
	R.muffs(true)
	K.dof(3.5, 1, 0.5, 0.5)
end, function(T, u)
	R.bliz(T, 560, 50)
	R.fill(0.9)
	Cm.face("Blocky", 4.6, -0.8, 0, -0.1, 0.8, 50)(T, u)
end)
-- 53.51 "Flashlights didn't help." : a beam into the white, swallowed
R.cut(53.51, "bliz", function()
	R.snow(true)
	R.party2(53.51)
	K.dof(nil)
end, function(T, u)
	R.party2(T)
	R.torches(T)
	R.bliz(T, 480, 46)
	local g = R.SP()
	camMove(g + V(1.2, 5.8, -3.8), g + V(0.2, 3.4, 10), g + V(1.0, 5.7, -3.2), g + V(0.2, 3.4, 10), u, 55)
end)
-- 54.68 "Shouting didn't help." : Blocky yells JUNIPER!
R.cut(54.68, "bliz", function()
	R.snow(true)
	local g = R.SP()
	R.at("Blocky", g, g.X - 4, g.Z + 12)
	R.act("Blocky", "scream", nil, 1, merge(R.YELL, {}))
	R.muffs(true)
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	R.bliz(T, 380, 44)
	R.fill(1.0)
	R.bubble("yell", R.head("Blocky") + V(0, 2.3, 0), "JUNIPER!", 3.6)
	Cm.face("Blocky", 5, 1.4, -0.3, 0.4, 0.8, 50)(T, u)
end)
-- 55.80 "The wind ate every word." : the bubble is ripped sideways, shrinks and is gone
R.cut(55.8, "bliz", function()
	R.snow(true)
	local g = R.SP()
	R.at("Blocky", g, g.X - 4, g.Z + 12)
	R.act("Blocky", "sad", nil, 1, R.YELL)
	R.muffs(true)
	K.dof(nil)
end, function(T, u)
	R.bliz(T, 420, 50)
	R.fill(1.0)
	local k = math.clamp((T - 56.0) / 1.0, 0, 1)
	local b = R.bubble("yell2", R.head("Blocky") + V(0, 2.3, 0) + camCF.RightVector * (k * k * 14) + V(0, k * 2, 0), "JUNIPER!", 3.8)
	b.bb.Size = UDim2.new(3.8 * (1 - 0.75 * k), 0, 3.8 * (1 - 0.75 * k), 0)
	b.l.TextTransparency = k
	b.l.BackgroundTransparency = k
	local st = b.l:FindFirstChildOfClass("UIStroke")
	if st then st.Transparency = k end
	b.l.Rotation = K.ROLL + k * 40
	Cm.face("Blocky", 7.5, 2.2, -0.2, 0.6, 0.6, 55)(T, u)
end)
-- 57.34 "Except one sound." : low on the dog in the snow: his ears go UP
R.cut(57.34, "bliz", function()
	R.snow(true)
	K.dof(3.6, 1.6, 0.45, 0)
end, function(T, u)
	local g = R.G(112, 8)
	local k = math.clamp((T - 57.55) / 0.2, 0, 1)
	R.dog(K.face(g, g.X - 1, g.Z - 10), merge(K.DOG.stand(T, 14 * (1 - k), 0), {EarL = Z(-30 * (1 - k)) * X(30 * k), EarR = Z(30 * k), Head = X(8 * k)}))
	K.petFace("Barks", k > 0.5 and "open" or "squint", false, k > 0.5 and "up" or "sad")
	R.bliz(T, 260, 38)
	R.fill(1.0)
	local e, l = K.frontCam("Barks", 3.6, -0.3, -0.6, 0)
	camMove(e, l, e + (l - e).Unit * 0.8, l, u, 48)
end)

---------------------------------------------------------------- the barking leads them (57.97 - 70.94)
-- 57.97 "one sound." : his first big bark (rings + WOOF), shake
R.cut(57.97, "bliz", function()
	R.snow(true)
	K.dof(4, 1.8, 0.45, 0)
end, function(T, u)
	local g = R.G(112, 8)
	R.barkDog("Barks", K.face(g, g.X - 1, g.Z - 10), {Head = X(14)}, T, 58.05, 0.6, R.DS, 1.4, 1.3)
	R.bliz(T, 260, 38)
	R.fill(1.0)
	local e, l = K.frontCam("Barks", 4.4, -0.4, 1.0, 0.2)
	camMove(e + K.shake(T, 58.05, 0.35, 0.3), l, e + (l - e).Unit * 0.6 + K.shake(T, 58.05, 0.35, 0.3), l, u, 52)
end)
-- 58.65 "Sir Barks-A-Lot ran into the dark," : he runs away from us into the blizzard, rings trailing
R.cut(58.65, "bliz", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local p = R.G(112, 8) + V(0, 0, -(T - 58.65) * 9)
	R.barkDog("Barks", K.face(p, p.X, p.Z - 10), K.DOG.walk(T, 16, 40), T, 58.7, 0.45, R.DS, 1.3, false)
	R.bliz(T, 300, 42)
	R.fill(0.8, nil, 24)
	local c = R.G(112, 8)
	camMove(c + V(1.5, 1.6, 6), c + V(0, 1.6, -10), c + V(1.5, 1.8, 5), c + V(0, 1.8, -14), u, 55)
end)
-- 59.50 "into the dark," : low side tracking, legs flying, rings
R.cut(59.5, "bliz", function()
	R.snow(true)
	K.dof(4, 2.5, 0.4, 0)
end, function(T, u)
	local p = R.G(100, 0) + V(-(T - 59.5) * 9, 0, 0)
	R.barkDog("Barks", K.face(p, p.X - 10, p.Z), K.DOG.walk(T, 16, 40), T, 59.55, 0.42, R.DS, 1.1, true)
	R.bliz(T, 300, 42)
	R.fill(1.0)
	local hp = K.head("Barks")
	camMove(hp + V(-2.6, -0.3, 5.2), hp + V(-0.4, -0.2, 0), nil, nil, 0, 52)
end)
-- 60.23 "barking." : far away in the dark: just the glowing bark rings
R.cut(60.23, "bliz", function()
	R.snow(true)
	R.party2(60.23, nil, R.G(110, 2) + V(-40, 0, -6))
	K.dof(nil)
end, function(T, u)
	local p = R.G(70, -6)
	R.barkDog("Barks", K.face(p, p.X - 10, p.Z), K.DOG.walk(T, 14, 30), T, 60.25, 0.55, R.DS, 2.8, false)
	R.bliz(T, 260, 40)
	local g = R.SP()
	camMove(g + V(3, 4.8, 4), p + V(0, 2, 0), g + V(3, 4.8, 3.4), p + V(0, 2, 0), u, 40)
end)
-- 60.80 "And barking." : the group turns, beams swing toward the sound
R.cut(60.8, "bliz", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local p = R.G(70, -6)
	local k = math.clamp((T - 60.85) / 0.35, 0, 1)
	local aimAt = (R.SP() + V(0, 0, 30)):Lerp(p, k)
	R.party2(T, {"wow", "focus", "wow", "focus", "wow", "focus", "wow"}, aimAt)
	R.torches(T, aimAt)
	R.barkDog("Barks", K.face(p, p.X - 10, p.Z), K.DOG.walk(T, 14, 30), T, 60.82, 0.55, R.DS, 2.8, false)
	R.bliz(T, 220, 36)
	R.fill(0.9, nil, 22)
	local g = R.SP()
	camMove(g + V(-12, 3, 6), g + V(0, 3.6, 0), g + V(-11, 3, 5), g + V(0, 3.6, 0), u, 55)
end)
-- 61.47 "And barking." : close on his barking face as he runs (WOOF)
R.cut(61.47, "bliz", function()
	R.snow(true)
	K.dof(3.6, 1.6, 0.45, 0)
end, function(T, u)
	local p = R.G(60, -6) + V(-(T - 61.47) * 8, 0, 0)
	R.barkDog("Barks", K.face(p, p.X - 10, p.Z), K.DOG.walk(T, 15, 34), T, 61.5, 0.4, R.DS, 1, true)
	R.bliz(T, 300, 42)
	R.fill(1.0)
	local e, l = K.frontCam("Barks", 4, -0.4, 1.2, 0)
	camMove(e, l, nil, nil, 0, 50)
end)
-- 62.27 "And we could hear exactly where he was." : the group runs toward the rings, beams on them
R.cut(62.27, "bliz", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local d = R.G(20, -4)
	local g = R.G(110 - (T - 62.27) * 6, 2)
	local who = {{"Blocky", V(0, 0, 0)}, {"Dad", V(3, 0, -2.5)}, {"Mom", V(3, 0, 2.5)}, {"N1", V(6, 0, -4.5)}, {"N2", V(6, 0, 4)}, {"Greer", V(8.5, 0, 0)}}
	for i, w in ipairs(who) do
		R.at(w[1], g + w[2], d.X, d.Z)
		R.act(w[1], (i % 2 == 0) and "focus" or "wow", nil, 1, merge(R.RUN(T + i * 0.4, 11), R.aim(w[1], d + V(0, 2, 0))))
		if i <= 5 then R.torch(i, w[1], d + V(0, 1.5, 0)) end
	end
	R.muffs(true)
	R.barkDog("Barks", K.face(d, d.X - 10, d.Z), K.DOG.walk(T, 14, 30), T, 62.3, 0.5, R.DS, 2.4, false)
	R.bliz(T, 220, 36)
	R.fill(1.0, nil, 24)
	camMove(g + V(-6, 3.2, 8), g + V(0, 3.4, 0), g + V(-9, 3.2, 8), g + V(-2, 3.4, 0), u, 58)
end)
-- 63.15 "where he was." : Mr. Greer points into the dark, shouting
R.cut(63.15, "bliz", function()
	R.snow(true)
	K.dof(4.4, 2, 0.45, 0)
end, function(T, u)
	local g = R.G(100, 0)
	R.at("Greer", g, g.X - 20, g.Z - 3)
	R.act("Greer", "shocked", nil, 1, merge(R.aim("Greer", g + V(-20, 4, -3)), {LeftShoulder = X(80), LeftElbow = X(40)}))
	R.torch(1, "Greer", g + V(-20, 3, -3))
	R.bliz(T, 260, 40)
	R.fill(1.0)
	Cm.face("Greer", 4.8, 1.6, -0.3, 0, 0.9, 48)(T, u)
end)
-- 64.03 "We followed the barking past the school," : the school in the snow, beams, rings ahead
R.cut(64.03, "bliz", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local d = R.G(400, 26 + (T - 64.03) * 5)
	R.barkDog("Barks", K.face(d, d.X, d.Z + 10), K.DOG.walk(T, 15, 32), T, 64.05, 0.45, R.DS, 2.0, false)
	local g = R.G(380, 4 + (T - 64.03) * 5)
	local who = {{"Blocky", V(0, 0, 0)}, {"Dad", V(-3, 0, -2)}, {"Mom", V(3, 0, -2.5)}, {"Greer", V(0, 0, -4.5)}}
	for i, w in ipairs(who) do
		R.at(w[1], g + w[2], d.X, d.Z)
		R.act(w[1], "focus", nil, 1, merge(R.RUN(T + i * 0.5, 11), R.aim(w[1], d + V(0, 2, 0))))
		R.torch(i, w[1], d + V(0, 1.4, 0))
	end
	R.muffs(true)
	R.bliz(T, 200, 34)
	R.fill(0.8, nil, 26)
	camMove(C0 + V(360, 3.5, -14), C0 + V(420, 7, 6), C0 + V(362, 3.5, -10), C0 + V(420, 6, 14), u, 62)
end)
-- 65.63 "past the frozen pond," : the dog running along the pond's edge, rings over the ice
R.cut(65.63, "bliz", function() K.dof(nil) end, function(T, u)
	local a = rad(200 + (T - 65.63) * 28)
	local pc = R.W0 + V(30, 0, 30)
	local d = pc + V(math.cos(a) * 34, 0.2, math.sin(a) * 34)
	local fw = V(-math.sin(a), 0, math.cos(a))
	R.barkDog("Barks", CFrame.lookAt(d, d + fw), K.DOG.walk(T, 15, 32), T, 65.65, 0.45, R.DS, 1.8, false)
	R.bliz(T, 220, 36)
	R.fill(0.7, nil, 30)
	camMove(pc + V(-8, 4, -14), d + V(0, 1.5, 0), pc + V(-6, 4, -12), d + V(0, 1.5, 0), u, 50)
end)
-- 66.62 "into the trees." : snowy pines, beams cutting between them
R.cut(66.62, "bliz", function() K.dof(nil) end, function(T, u)
	local d = R.LOG + V(-10 + (T - 66.62) * 6, 0.2, -6)
	R.barkDog("Barks", K.face(d, d.X + 10, d.Z + 3), K.DOG.walk(T, 15, 32), T, 66.64, 0.45, R.DS, 1.8, false)
	local g = R.LOG + V(-20 + (T - 66.62) * 5, 0.2, -16)
	local who = {{"Blocky", V(0, 0, 0)}, {"Dad", V(-3, 0, -2)}, {"Greer", V(2.5, 0, -3)}}
	for i, w in ipairs(who) do
		R.at(w[1], g + w[2], d.X, d.Z)
		R.act(w[1], "focus", nil, 1, merge(R.RUN(T + i * 0.5, 11), R.aim(w[1], d + V(0, 2, 0))))
		R.torch(i, w[1], d + V(0, 1.4, 0))
	end
	R.muffs(true)
	R.bliz(T, 240, 36)
	R.fill(0.8, nil, 26)
	camMove(R.LOG + V(-28, 3, -26), R.LOG + V(-10, 3, -8), R.LOG + V(-26, 3, -24), R.LOG + V(-8, 3, -8), u, 58)
end)
-- 67.52 "Then the barking changed." : he stops dead in one spot, braced, barking harder
R.cut(67.52, "bliz", function() K.dof(4.5, 2, 0.45, 0) end, function(T, u)
	local d = R.LOG + V(-3, 0.2, -3.5)
	local k = math.clamp((T - 67.52) / 0.3, 0, 1)
	R.barkDog("Barks", K.face(d + V(-2 * (1 - k), 0, 0), d.X + 6, d.Z - 6), K.DOG.pull(T, 0), T, 68.17, 0.3, R.DS, 1.4, false)
	R.bliz(T, 220, 34)
	R.fill(1.0)
	local e, l = K.frontCam("Barks", 5, -0.3, -1.4, 0)
	camMove(e, l, e + (l - e).Unit * 1.2, l, u, 52)
end)
-- 69.09 "Short and loud," : fast barks, WOOF WOOF, big rings
R.cut(69.09, "bliz", function() K.dof(3.6, 1.6, 0.45, 0) end, function(T, u)
	local d = R.LOG + V(-3, 0.2, -3.5)
	R.barkDog("Barks", K.face(d, d.X + 6, d.Z - 6), {Head = X(10)}, T, 69.1, 0.26, R.DS, 1.5, 1.3)
	R.bliz(T, 220, 34)
	R.fill(1.0)
	local e, l = K.frontCam("Barks", 3.6, -0.3, 0.4, 0)
	camMove(e + K.shake(T, 69.1, 0.8, 0.12), l, nil, nil, 0, 50)
end)
-- 69.94 "in one spot." : from the searchers: one spot of pulsing rings, every beam swings onto it
R.cut(69.94, "bliz", function() K.dof(nil) end, function(T, u)
	local d = R.LOG + V(-3, 0.2, -3.5)
	R.barkDog("Barks", K.face(d, d.X + 6, d.Z - 6), {Head = X(10)}, T, 69.95, 0.28, R.DS, 2.2, false)
	local g = R.LOG + V(8, 0.2, -20)
	local who = {{"Blocky", V(0, 0, 0)}, {"Dad", V(-3, 0, 1)}, {"Mom", V(3, 0, 1.5)}, {"Greer", V(1, 0, 3)}}
	for i, w in ipairs(who) do
		R.at(w[1], g + w[2], d.X, d.Z)
		R.act(w[1], "wow", nil, 1, R.aim(w[1], d + V(0, 1, 0)))
		R.torch(i, w[1], d + V(0, 0.8, 0))
	end
	R.muffs(true)
	R.bliz(T, 200, 32)
	R.fill(0.7, nil, 26)
	camMove(g + V(9, 4.5, 5), d + V(0, 1.5, 0), g + V(8, 4.5, 6), d + V(0, 1.5, 0), u, 50)
end)

---------------------------------------------------------------- found (70.94 - 79.6)
-- Juniper curled up on her side ON the snow behind the log (+Z side), holding Gary
R.junCurl = function(mood, opn)
	local g = R.LOG + V(-1.5, 0.2, 2.2)
	local cf = CFrame.lookAt(g, g + V(-1, 0, 0)) * CFrame.new(0, 0.72, 0) * CFrame.Angles(0, 0, rad(90))
	rootAt("Juniper", cf)
	R.act("Juniper", mood or "sleep", nil, 1, {RightHip = X(85), LeftHip = X(80), RightKnee = X(-95), LeftKnee = X(-90), RightShoulder = X(75) * Z(-15), LeftShoulder = X(70) * Z(10), RightElbow = X(60), LeftElbow = X(50), Neck = X(10)})
end
R.gary = function()
	local h = (R.hand("Juniper") + R.hand("Juniper", "Left")) / 2
	R.prop("Gary", CFrame.lookAt(h + V(0, -0.2, 0), h + V(0, -0.2, 0) + V(0, 0, 1)) * CFrame.Angles(rad(70), 0, 0) * CFrame.new(0, -1.0, 0))
end
R.logOn = function() R.prop("Log", CFrame.new(R.LOG + V(0, 0.2, 0))) end
-- 70.94 "He was standing over Juniper," : the reveal: the dog over the little pink shape behind the log (music turns bright)
R.cut(70.94, "bliz", function()
	R.logOn()
	R.junCurl("sleep")
	K.dof(nil)
end, function(T, u)
	R.gary()
	local d = R.LOG + V(-4.6, 0.2, 2.6)
	R.barkDog("Barks", K.face(d, d.X + 10, d.Z), {Head = X(-12)}, T, 71.0, 0.5, R.DS, 1.2, false)
	R.bliz(T, 160, 26)
	R.fill(1.2, Color3.fromRGB(255, 235, 210), 20)
	local c = R.LOG + V(-2.5, 1.2, 2.4)
	camMove(c + V(2, 4.6, 8), c, c + V(1.5, 3.6, 6.5), c, u, 52)
end)
-- 72.06 "curled up in the snow behind a log," : low and close on her, asleep, tiny, safe
R.cut(72.06, "bliz", function()
	R.logOn()
	R.junCurl("sleep")
	K.dof(3.5, 1.5, 0.45, 0)
end, function(T, u)
	R.gary()
	R.bliz(T, 120, 22)
	R.fill(1.2, Color3.fromRGB(255, 235, 210), 16)
	local hp = R.head("Juniper")
	camMove(hp + V(-3.6, 1.0, 1.6), hp + V(0.4, -0.2, 0), hp + V(-3.0, 0.9, 1.3), hp + V(0.4, -0.2, 0), u, 50)
end)
-- 73.70 "holding a stick" : insert: Gary in her mittens
R.cut(73.7, "bliz", function()
	R.logOn()
	R.junCurl("sleep")
	K.dof(2.5, 1.2, 0.5, 0)
end, function(T, u)
	R.gary()
	R.bliz(T, 100, 20)
	R.fill(1.2, Color3.fromRGB(255, 235, 210), 14)
	local g = R.props.Gary.m:FindFirstChild("Tag")
	local c = g and g.Position or R.LOG
	camMove(c + V(-1.4, 1.6, 4.6), c, c + V(-1.2, 1.4, 4.0), c, u, 48)
end)
-- 74.33 "she had named Gary." : Gary's googly eyes + GARY tag, close
R.cut(74.33, "bliz", function()
	R.logOn()
	R.junCurl("sleep")
	K.dof(2.2, 1.0, 0.5, 0)
end, function(T, u)
	R.gary()
	R.bliz(T, 90, 18)
	R.fill(1.3, Color3.fromRGB(255, 235, 210), 12)
	local e = R.props.Gary.m:FindFirstChild("Eye")
	local tg = R.props.Gary.m:FindFirstChild("Tag")
	local c = e and tg and (e.Position + tg.Position) / 2 or R.LOG
	camMove(c + V(-1.6, 0.9, 3.4), c, c + V(-1.3, 0.8, 2.9), c, u, 46)
end)
-- the walk home: Mr. Greer carries her (bride carry, a gap between them), the dog barks up at her
R.carry = function(T, gp, face, jmood)
	R.at("Greer", gp, gp.X + face.X, gp.Z + face.Z)
	R.act("Greer", "happy", nil, 1, merge(R.CARRY, R.WALK(T, 6, 14), {RightShoulder = X(70) * Z(-10), LeftShoulder = X(70) * Z(10)}))
	-- she sits upright on his forearms, side-on, head by his shoulder, a gap from his chest (no merged bodies)
	local A = actors.Greer
	rootAt("Juniper", A.root.CFrame * CFrame.new(0.15, 0.95, -1.4) * Y(90))
	R.act("Juniper", jmood, nil, 1, {RightHip = X(85), LeftHip = X(85), RightKnee = X(-75), LeftKnee = X(-75), RightShoulder = X(60) * Z(-10), LeftShoulder = X(35), RightElbow = X(40), Neck = Y(-30) * X(8)})
end
-- 75.61 "He barked at her the whole way home" : walking through the snowy trees, the dog bouncing, barking up at her
R.cut(75.61, "bliz", function() K.dof(nil) end, function(T, u)
	local gp = R.G(60, 6) + V(-(T - 75.61) * 3, 0, 0)
	local k = R.bk(T, 75.65, 0.45)
	R.carry(T, gp, V(-10, 0, 0), (k > 0.4) and "shocked" or "sleep")
	local d = gp + V(-1.5, 0, 3.4)
	R.barkDog("Barks", CFrame.lookAt(d, d + V(-1, 0, -0.5)), merge(K.DOG.walk(T, 12, 25), {Head = X(25)}), T, 75.65, 0.45, R.DS, 1.0, true)
	R.snow(true)
	R.bliz(T, 110, 20)
	R.fill(1.1, Color3.fromRGB(255, 235, 210), 22)
	camMove(gp + V(-9, 2.6, 7), gp + V(0, 3.4, 0), gp + V(-10.5, 2.6, 6), gp + V(-1.5, 3.4, 0), u, 55)
end)
-- 76.88 "so she couldn't fall asleep." : her face: eyes droop... BARK... eyes pop open (each bark)
R.cut(76.88, "bliz", function()
	R.snow(true)
	K.dof(3.4, 1.4, 0.45, 0)
end, function(T, u)
	local gp = R.G(54, 6) + V(-(T - 76.88) * 3, 0, 0)
	local k = R.bk(T, 76.95, 0.5)
	R.carry(T, gp, V(-10, 0, 0), (k > 0.25) and "shocked" or "sleep")
	local d = gp + V(-1.5, 0, 3.4)
	R.barkDog("Barks", CFrame.lookAt(d, d + V(-1, 0, -0.5)), merge(K.DOG.walk(T, 12, 25), {Head = X(25)}), T, 76.95, 0.5, R.DS, 0.8, true)
	R.bliz(T, 80, 16)
	R.fill(1.2, Color3.fromRGB(255, 235, 210), 14)
	local hp = R.head("Juniper")
	camMove(hp + V(-1.2, 2.2, 2.6), hp, hp + V(-1.0, 1.9, 2.2), hp, u, 48)
end)
-- 78.14 "Mr. Greer carried her." : Mr. Greer's kind face over her, close, warm
R.cut(78.14, "bliz", function()
	R.snow(true)
	K.dof(4, 2, 0.45, 0)
end, function(T, u)
	local gp = R.G(48, 6) + V(-(T - 78.14) * 2, 0, 0)
	R.carry(T, gp, V(-10, 0, 0), "happy")
	R.bliz(T, 70, 14)
	R.fill(1.2, Color3.fromRGB(255, 225, 190), 16)
	Cm.face("Greer", 6.5, -3.2, 0.4, -0.9, 0.8, 52)(T, u)
end)

---------------------------------------------------------------- the morning after + the second puppy (79.6 - 85.8)
-- 79.60 "The next morning Mr. Greer" : sunny snowy morning, his signs still up
R.cut(79.6, "morning42", function()
	R.snow(true)
	local g = R.GRE()
	R.at("Greer", g + V(3.5, 0, 1), g.X - 3, g.Z)
	R.act("Greer", "happy", "idle", 0.6, nil)
	K.dof(nil)
end, function(T, u)
	local g = R.GRE()
	R.prop("Sign2", K.face(g + V(-3, -0.8, -1), g.X - 3, g.Z + 10))
	R.prop("Sign1", K.face(g + V(5.5, -0.6, 2), g.X + 5.5, g.Z + 10))
	R.prop("Sign3", K.face(g + V(-8, -0.5, 1.5), g.X - 8, g.Z + 10))
	camMove(g + V(-2, 3, 18), g + V(0, 4, 0), g + V(-1.5, 3, 16.5), g + V(0, 4, 0), u, 58)
end)
-- 80.70 "took down every one of his signs." : he pulls the big sign up out of the snow
R.cut(80.7, "morning42", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local g = R.GRE()
	local k = math.clamp((T - 80.8) / 0.7, 0, 1)
	R.prop("Sign2", K.face(g + V(-3, -0.8 + 2.4 * k, -1), g.X - 3, g.Z + 10) * CFrame.Angles(rad(-12 * k), 0, 0))
	R.at("Greer", g + V(-3, 0, 1.0), g.X - 3, g.Z - 5)
	R.act("Greer", "laugh", nil, 1, {RightShoulder = X(150 + 15 * k), LeftShoulder = X(150 + 15 * k), Waist = X(-8 * k)})
	R.puffAt("pull", g + V(-3, 0.8, -1), T, 80.85, 14, 1.0)
	camMove(g + V(3, 2.4, 13), g + V(-2, 4.6, 0), g + V(2.4, 2.6, 11.5), g + V(-2, 4.8, 0), u, 58)
end)
-- 81.34 "every one of his signs." : the "why" sign goes on the pile, he waves at the dog next door
R.cut(81.34, "morning42", function()
	R.snow(true)
	local g = R.GRE()
	R.at("Greer", g, g.X - 10, g.Z + 4)
	R.act("Greer", "laugh", "wave", 1, nil)
	K.dof(6, 3, 0.4, 0)
end, function(T, u)
	local g = R.GRE()
	R.prop("Sign2", CFrame.new(g + V(2.5, 1.0, -3)) * CFrame.Angles(rad(-90), rad(20), 0))
	R.prop("Sign3", CFrame.new(g + V(2.2, 1.6, -2.4)) * CFrame.Angles(rad(-80), rad(-30), 0))
	local d = R.G(92, -26)
	R.barkDog("Barks", K.face(d, g.X, g.Z), K.DOG.stand(T, 0, 45), T, 81.4, 0.42, R.DS, 1, true)
	camMove(g + V(-6, 2.6, 9), g + V(-3, 3.2, 0), g + V(-5.4, 2.6, 8), g + V(-3, 3.2, 0), u, 58)
end)
-- 82.21 "The week after that, he got a puppy." : Mr. Greer on his lawn, a tiny puppy at his slippers
R.cut(82.21, "morning42", function()
	R.snow(true)
	local g = R.GRE()
	R.at("Greer", g, g.X - 1, g.Z + 10)
	R.act("Greer", "starry", "idle", 0.6, {Neck = X(-15)})
	K.dof(5, 2.5, 0.4, 0)
end, function(T, u)
	local g = R.GRE()
	R.barkDog("Second", K.face(g + V(-1.6, 0, 2.6), g.X - 1, g.Z + 12), K.DOG.stand(T, 0, 50), T, 83.1, 0.36, 0.95, 0.6, false)
	camMove(g + V(1.5, 3.4, 11), g + V(-0.8, 2.6, 1), g + V(1.3, 3.4, 9.8), g + V(-0.8, 2.6, 1), u, 55)
end)
-- 83.28 "puppy." : the puppy's first bark into the camera (tiny rings, tiny WOOF)
R.cut(83.28, "morning42", function()
	R.snow(true)
	K.dof(2.8, 1.2, 0.5, 0)
end, function(T, u)
	local g = R.GRE()
	R.barkDog("Second", K.face(g + V(-1.6, 0, 2.6), g.X - 1, g.Z + 12), K.DOG.stand(T, 0, 50), T, 83.32, 0.36, 0.95, 0.55, 0.6)
	local e, l = K.frontCam("Second", 3.0, -0.1, -0.4, 0)
	camMove(e, l, e + (l - e).Unit * 0.5, l, u, 48)
end)
-- 83.89 "He named it" : Mr. Greer proud, holding a name tag
R.cut(83.89, "morning42", function()
	R.snow(true)
	local g = R.GRE()
	R.at("Greer", g, g.X - 1, g.Z + 10)
	R.act("Greer", "laugh", nil, 1, R.CHEER)
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	Cm.face("Greer", 5, -1.0, -0.6, 0, 0.9, 48)(T, u)
end)
-- 84.34 "Sir Barks-A-Lot the Second." : the puppy at his new doghouse, the name card + THE 2ND
R.cut(84.34, "morning42", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	local g = R.GRE()
	R.prop("DH1", K.face(g + V(-4, 0, -2), g.X - 4, g.Z + 10))
	R.barkDog("Second", K.face(g + V(-4, 0, 1.6), g.X - 3, g.Z + 12), K.DOG.stand(T, 0, 50), T, 84.4, 0.38, 0.95, 0.6, false)
	R.card("second", g + V(-4, 7.8, 1.6), "THE 2ND", T, 85.0, 4.4, Color3.fromRGB(255, 220, 60))
	camMove(g + V(-4, 2.4, 11), g + V(-4, 3.6, 0), g + V(-4, 2.4, 9.6), g + V(-4, 3.8, 0), u, 55)
end)

---------------------------------------------------------------- the loud street + Hero (85.8 - 95.6)
R.DOGS = {
	{"Barks", 62, -27, R.DS, true}, {"Second", 124, -26, 0.95, true}, {"DogSpot", 92, -27, 0.5, false},
	{"DogBrown", -175, -28, 0.5, false}, {"Biscuit", 20, 27, 0.5, false}, {"Pup", 100, 27, 1.0, false}, {"Puppy", -110, 27, 0.6, false},
}
R.street = function(T, t0)
	for i, dd in ipairs(R.DOGS) do
		local g = R.G(dd[2], dd[3])
		local tz = (dd[3] < 0) and g.Z + 10 or g.Z - 10
		R.barkDog(dd[1], K.face(g, g.X, tz), K.DOG.stand(T, 0, 40), T, t0 + i * 0.07, 0.36 + (i % 3) * 0.04, dd[4], 1.3, i % 2 == 0)
	end
	local dh = {{"DH1", 112, -36}, {"DH2", -60, -37}, {"DH3", 20, 36}, {"DH4", 100, 36}}
	for _, h in ipairs(dh) do
		local g = R.G(h[2], h[3])
		R.prop(h[1], K.face(g, g.X, (h[3] < 0) and g.Z + 10 or g.Z - 10))
	end
end
-- 85.80 "Now half the dogs on our street" : high wide: doghouses + dogs barking all down the street
R.cut(85.8, "end42", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	R.street(T, 85.8)
	camMove(C0 + V(-10, 16, 30), C0 + V(50, 2, -10), C0 + V(0, 14, 28), C0 + V(60, 2, -10), u, 60)
end)
-- 86.54 "have that name." : low tracking past three of them, every doghouse says SIR BARKS-A-LOT
R.cut(86.54, "end42", function()
	R.snow(true)
	K.dof(nil)
end, function(T, u)
	R.street(T, 86.5)
	camMove(C0 + V(70, 2.4, -14), C0 + V(62, 2.6, -27), C0 + V(114, 2.4, -14), C0 + V(123, 2.6, -27), u, 52)
end)
-- 87.92 "It's very loud here." : Blocky in the middle of it all, ears covered, dizzy, rings all round him (shake)
R.cut(87.92, "end42", function()
	R.snow(true)
	local g = R.G(62, -20)
	R.at("Blocky", g, g.X, g.Z + 10)
	R.act("Blocky", "dizzy", nil, 1, P.earsCover)
	K.dof(5, 2.5, 0.4, 0)
end, function(T, u)
	R.street(T, 87.9)
	local hp = R.head("Blocky")
	camMove(hp + V(0, -0.4, 6.5) + K.shake(T, 88.1, 1.5, 0.12), hp, hp + V(0, -0.3, 5) + K.shake(T, 88.1, 1.5, 0.12), hp, u, 58)
end)
-- 89.31 "Juniper renamed our dog Hero." : she ties the red cape on him, HERO card
R.cut(89.31, "end42", function()
	R.snow(true)
	local g = R.OURS()
	R.at("Juniper", g + V(-2.6, 0, 0.4), g.X, g.Z + 0.4)
	R.act("Juniper", "starry", nil, 1, merge(R.aim("Juniper", g + V(0, 2.4, 0)), {LeftShoulder = X(70)}))
	K.dof(5, 2.5, 0.4, 0)
end, function(T, u)
	local g = R.OURS()
	R.dog(K.face(g, g.X + 1, g.Z + 10), K.DOG.sit(T, 10, 30), K.DOG.sitDrop)
	local bd = R.ppart("Barks", "Body")
	R.prop("Cape", bd.CFrame * CFrame.new(0, 0.85, 0.5) * CFrame.Angles(rad(-20), 0, 0))
	R.card("hero", K.head("Barks") + V(0, 2.4, 0), "HERO", T, 90.57, 3.4, Color3.fromRGB(230, 40, 50), Color3.new(1, 1, 1))
	camMove(g + V(2, 2.2, 8.5), g + V(-0.8, 2.6, 0), g + V(1.6, 2.2, 7.2), g + V(-0.8, 2.6, 0), u, 52)
end)
-- 90.57 "Hero." : the dog in the cape, heroic, low, wind in the cape
R.cut(90.57, "end42", function()
	R.snow(true)
	K.dof(4, 2, 0.45, 0)
end, function(T, u)
	local g = R.OURS()
	R.dog(K.face(g, g.X + 1, g.Z + 10), merge(K.DOG.stand(T, 0, 20), {Head = X(12)}))
	local bd = R.ppart("Barks", "Body")
	R.prop("Cape", bd.CFrame * CFrame.new(0, 0.85, 0.6) * CFrame.Angles(rad(-20 + math.sin(T * 8) * 8), 0, 0))
	R.card("hero2", K.head("Barks") + V(0, 2.4, 0), "HERO", T, 90.57, 3.4, Color3.fromRGB(230, 40, 50), Color3.new(1, 1, 1))
	local e, l = K.frontCam("Barks", 5, -0.8, 1.6, 0.4)
	camMove(e, l, e + (l - e).Unit * 1.0, l, u, 52)
end)
-- 91.27 "It didn't take." : he BARKS, the cape flies off, HERO pops
R.cut(91.27, "end42", function()
	R.snow(true)
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X + 1, g.Z + 10), K.DOG.stand(T, 0, 40), T, 91.4, 0.42, R.DS, 1.1, true)
	local bd = R.ppart("Barks", "Body")
	local k = math.clamp((T - 91.42) / 0.6, 0, 1)
	R.prop("Cape", bd.CFrame * CFrame.new(-3 * k, 0.85 + 3 * k - 4 * k * k, 0.6 + 2 * k) * CFrame.Angles(rad(-20 + 200 * k), rad(90 * k), 0))
	R.card("hero3", K.head("Barks") + V(0, 2.4, 0), "HERO", T, 91.27, 3.4, Color3.fromRGB(230, 40, 50), Color3.new(1, 1, 1), nil, 91.45)
	if T >= 91.45 then R.puffAt("heropop", K.head("Barks") + V(0, 2.4, 0), T, 91.45, 14, 0.7, Color3.fromRGB(255, 220, 80)) end
	local e, l = K.frontCam("Barks", 6, -0.4, -1.2, 0.8)
	camMove(e, l, e + (l - e).Unit * 0.8, l, u, 54)
end)
-- 92.25 "He's still Sir Barks-A-Lot." : the real name card comes back, he barks happily
R.cut(92.25, "end42", function()
	R.snow(true)
	K.dof(4.5, 2, 0.45, 0)
end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g, g.X + 1, g.Z + 10), K.DOG.stand(T, 0, 50), T, 92.3, 0.4, R.DS, 1, false)
	R.card("name2", K.head("Barks") + V(0, 2.6, 0), "SIR BARKS-A-LOT", T, 92.61, 5.6, Color3.fromRGB(255, 220, 60))
	local e, l = K.frontCam("Barks", 6, -0.3, 0.8, 1.2)
	camMove(e, l, e + (l - e).Unit * 0.8, l, u, 55)
end)
-- 93.84 "Some names are just right the first time." : the whole family on the lawn at sunset, Greer + his puppy next door
R.cut(93.84, "end42", function()
	R.snow(true)
	local g = R.OURS()
	R.at("Blocky", g + V(-2.5, 0, -1), g.X - 1, g.Z + 10)
	R.act("Blocky", "happy", "idle", 0.6, nil)
	R.at("Juniper", g + V(2.4, 0, 0), g.X + 1, g.Z + 10)
	R.act("Juniper", "laugh", "idle", 0.8, nil)
	R.at("Mom", g + V(-5.5, 0, -3), g.X - 3, g.Z + 10)
	R.act("Mom", "happy", "idle", 0.6, nil)
	R.at("Dad", g + V(5, 0, -3.2), g.X + 3, g.Z + 10)
	R.act("Dad", "happy", "idle", 0.6, nil)
	K.dof(nil)
end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g + V(0, 0, 1.6), g.X, g.Z + 10), K.DOG.stand(T, 0, 50), T, 93.9, 0.45, R.DS, 1, false)
	camMove(g + V(0.5, 2.6, 13), g + V(0, 3.4, 0), g + V(0.3, 2.8, 10.5), g + V(0, 3.4, 0), u, 58)
end)
-- 94.82 "the first time." : last close: him barking at us, Blocky laughing behind
R.cut(94.82, "end42", function()
	R.snow(true)
	local g = R.OURS()
	R.at("Blocky", g + V(-2.5, 0, -1), g.X - 1, g.Z + 10)
	R.act("Blocky", "laugh", nil, 1, nil)
	K.dof(4.5, 2.5, 0.4, 0)
end, function(T, u)
	local g = R.OURS()
	R.barkDog("Barks", K.face(g + V(0, 0, 1.6), g.X, g.Z + 10), K.DOG.stand(T, 0, 50), T, 94.85, 0.42, R.DS, 1, true)
	local e, l = K.frontCam("Barks", 5, -0.2, 1.4, 0.6)
	camMove(e, l, e + (l - e).Unit * 1.2, l, u, 55)
end)
