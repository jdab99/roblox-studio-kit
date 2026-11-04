-- Reel 42 "Sir Barks-A-Lot" actors, built in Edit mode into workspace.Film.ReelCast (parked offstage).
-- Blocky is the BASE actor (film/cast.luau). This file adds little Blocky (4), Juniper (3), Mom, Dad, Mr. Greer, Mrs. Lee,
-- the kid next door, the uncle and four search neighbours.
-- Recipe (reels 31 / 36): classic head + ONE decal per mood (switch by Transparency, never by Texture), parts-built hair and
-- clothes welded to the part they belong to. Small kids: head SEATED on the torso (headDrop) + a neck filler; their hair
-- accessory is moved down with the head and welded to it (no floating hair).
local Players = game:GetService("Players")
local MOODS = {happy = 135773001893013, laugh = 140615351309004, scream = 74187334953026, shocked = 87555246095537,
	scared = 82071220644850, dizzy = 120248967875008, angry = 124090698532510, smug = 80289889743945, cry = 139929720410872,
	starry = 95985606586642, focus = 90634447576450, nervous = 90946346829906, wow = 82444194871225, sad = 135482990429946,
	sleep = 70540320410457}
local film = workspace:FindFirstChild("Film")
local old = film:FindFirstChild("ReelCast")
if old then old:Destroy() end
local cast = Instance.new("Folder")
cast.Name = "ReelCast"
cast.Parent = film

local C3 = Color3.fromRGB
local SKIN = C3(255, 205, 150)
local rad = math.rad
local function weldPart(m, attachTo, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.CFrame = attachTo.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = attachTo, p
	w.Parent = p
	p.Parent = m
	return p
end
local function sphere(p) local sm = Instance.new("SpecialMesh") sm.MeshType = Enum.MeshType.Sphere sm.Parent = p return p end
local function label(p, face, str, col, bg)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 0.3
	sg.CanvasSize = Vector2.new(200, 100)
	sg.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = bg and 0 or 1
	t.BackgroundColor3 = bg or C3(255, 255, 255)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.Text = str
	t.TextColor3 = col
	t.Parent = sg
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = C3(255, 255, 255)
	st.Parent = t
end

local function build(look)
	local desc = Instance.new("HumanoidDescription")
	if look.shirt then desc.Shirt = look.shirt end
	if look.pants then desc.Pants = look.pants end
	if look.hair then desc.HairAccessory = tostring(look.hair) end
	local skin = look.skin or SKIN
	desc.HeadColor = skin
	desc.LeftArmColor, desc.RightArmColor = look.arms or skin, look.arms or skin
	desc.TorsoColor = look.torso or skin
	desc.LeftLegColor = look.legs or skin
	desc.RightLegColor = look.legs or skin
	desc.BodyTypeScale, desc.ProportionScale = 0, 0
	local s = look.scale or 1
	desc.HeightScale, desc.WidthScale, desc.DepthScale = s, look.width or s, look.width or s
	desc.HeadScale = look.headScale or 1
	local ok, m = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	return ok and m or nil, (not ok) and tostring(m) or nil
end

local function makeActor(name, look, slot)
	local m, err = build(look)
	if not m then return name .. " FAILED " .. tostring(err) end
	m.Name = name
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	-- Play re-applies the body scale and shrinks/shifts every welded extra on a scaled actor (reel 29's floating hair,
	-- this reel's vanished boots): the rig is already built at size, so switch the automatic rescale off
	hum.AutomaticScalingEnabled = false
	local an = m:FindFirstChild("Animate")
	if an then an:Destroy() end
	if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator", hum) end
	local head = m.Head
	head.Transparency = 1
	local fc = head:FindFirstChildOfClass("FaceControls")
	if fc then fc:Destroy() end
	for _, d in head:GetChildren() do if d:IsA("Decal") then d:Destroy() end end
	local drop = look.headDrop or 0
	local ch = Instance.new("Part")
	ch.Name = "ClassicHead"
	ch.Size = Vector3.new(2, 1, 1)
	ch.Color = look.skin or SKIN
	ch.CanCollide = false
	ch.Massless = true
	ch.CFrame = head.CFrame * CFrame.new(0, -drop, 0)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25) * (head.Size.Y / 1.2)
	mesh.Parent = ch
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxassetid://" .. MOODS[look.mood or "happy"]
	face.Transparency = 1
	face.Parent = ch
	for mood, id in MOODS do
		local d = Instance.new("Decal")
		d.Name = "M_" .. mood
		d.Face = Enum.NormalId.Front
		d.Texture = "rbxassetid://" .. id
		d.Transparency = (mood == (look.mood or "happy")) and 0 or 0.995
		d.Parent = ch
	end
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = head, ch
	w.Parent = ch
	ch.Parent = m
	-- accessory hair follows the seated head: move it down by the drop and weld it to the classic head
	for _, acc in m:GetChildren() do
		if acc:IsA("Accessory") then
			local hd = acc:FindFirstChild("Handle")
			if hd then
				for _, j in hd:GetChildren() do if j:IsA("JointInstance") or j:IsA("WeldConstraint") then j:Destroy() end end
				hd.CFrame = hd.CFrame * CFrame.new(0, 0, 0) - Vector3.new(0, drop + (look.hairDrop or 0), 0)
				local wc = Instance.new("WeldConstraint")
				wc.Part0, wc.Part1 = ch, hd
				wc.Parent = hd
				hd.Massless = true
			end
		end
	end
	for _, f in (look.extras or {}) do f(m, ch, mesh.Scale.Y / 1.25) end
	m:PivotTo(CFrame.new(slot, 400, 3600))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = (p.Name == "HumanoidRootPart")
			p.CastShadow = true
		end
	end
	m:SetAttribute("HipY", hum.HipHeight + m.HumanoidRootPart.Size.Y / 2)
	m.Parent = cast
	-- parts on the legs go on AFTER the rig is in the workspace (its scale settles on parenting: boots built earlier
	-- came out half size and a stud below the feet)
	if look.late then
		task.wait()
		for _, f in look.late do f(m) end
		for _, p in m:GetDescendants() do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Anchored = false end end
	end
	local nb = 0
	for _, p in m:GetChildren() do if p.Name == "BootShaft" then nb += 1 end end
	local bs = ""
	for _, p in m:GetChildren() do
		if p.Name == "BootShaft" then
			local ll = m:FindFirstChild("LeftLowerLeg")
			local r = ll.CFrame:PointToObjectSpace(p.Position)
			bs = bs .. string.format(" [%.2f %.2f %.2f s%.2f]", r.X, r.Y, r.Z, p.Size.X)
		end
	end
	return name .. string.format(" hipY=%.2f boots=%d", m:GetAttribute("HipY"), nb) .. bs
end

---------------------------------------------------------------- parts-built looks (k = head unit)
local function shortHair(col, full)
	return function(m, ch, k)
		sphere(weldPart(m, ch, "HairCap", Vector3.new(1.42, full and 0.95 or 0.62, 1.42) * k, CFrame.new(0, (full and 0.22 or 0.58) * k, 0.12 * k), col))
		weldPart(m, ch, "Fringe", Vector3.new(1.18, 0.2, 0.28) * k, CFrame.new(0, (full and 0.44 or 0.74) * k, -0.48 * k) * CFrame.Angles(rad(-25), 0, 0), col)
		weldPart(m, ch, "SideL", Vector3.new(0.16, 0.4, 0.75) * k, CFrame.new(-0.6 * k, 0.12 * k, 0.12 * k), col)
		weldPart(m, ch, "SideR", Vector3.new(0.16, 0.4, 0.75) * k, CFrame.new(0.6 * k, 0.12 * k, 0.12 * k), col)
		weldPart(m, ch, "HairBack", Vector3.new(1.05, 0.45, 0.22) * k, CFrame.new(0, 0.12 * k, 0.6 * k), col)
	end
end
local function pigtails(col, tie)
	return function(m, ch, k)
		sphere(weldPart(m, ch, "HairCap", Vector3.new(1.56, 1.15, 1.52) * k, CFrame.new(0, 0.3 * k, 0.1 * k), col))
		weldPart(m, ch, "Fringe", Vector3.new(1.1, 0.18, 0.24) * k, CFrame.new(0, 0.44 * k, -0.56 * k) * CFrame.Angles(rad(-35), 0, 0), col)
		for _, s in {-1, 1} do
			weldPart(m, ch, "Tail", Vector3.new(0.62, 0.8, 0.62) * k, CFrame.new(s * 0.66 * k, 0.18 * k, 0.24 * k), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			weldPart(m, ch, "Tail2", Vector3.new(0.5, 0.62, 0.5) * k, CFrame.new(s * 0.72 * k, -0.22 * k, 0.26 * k), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
			weldPart(m, ch, "Tie", Vector3.new(0.28, 0.28, 0.28) * k, CFrame.new(s * 0.6 * k, 0.46 * k, 0.22 * k), tie, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		end
	end
end
local function glasses(F)
	F = F or C3(120, 80, 50)
	return function(m, ch, k)
		for _, x in {-0.42, 0.42} do
			weldPart(m, ch, "RimT", Vector3.new(0.6, 0.05, 0.04) * k, CFrame.new(x * k, 0.33 * k, -0.68 * k), F)
			weldPart(m, ch, "RimB", Vector3.new(0.6, 0.05, 0.04) * k, CFrame.new(x * k, -0.19 * k, -0.68 * k), F)
			weldPart(m, ch, "RimL", Vector3.new(0.05, 0.52, 0.04) * k, CFrame.new((x - 0.28) * k, 0.07 * k, -0.68 * k), F)
			weldPart(m, ch, "RimR", Vector3.new(0.05, 0.52, 0.04) * k, CFrame.new((x + 0.28) * k, 0.07 * k, -0.68 * k), F)
		end
		weldPart(m, ch, "Bridge", Vector3.new(0.3, 0.05, 0.04) * k, CFrame.new(0, 0.2 * k, -0.68 * k), F)
	end
end
local function momHair(col)
	return function(m, ch, k)
		shortHair(col, true)(m, ch, k)
		weldPart(m, ch, "Long", Vector3.new(1.5, 1.6, 0.45) * k, CFrame.new(0, -0.45 * k, 0.48 * k), col)
		weldPart(m, ch, "LongL", Vector3.new(0.3, 1.3, 0.8) * k, CFrame.new(-0.66 * k, -0.35 * k, 0.15 * k), col)
		weldPart(m, ch, "LongR", Vector3.new(0.3, 1.3, 0.8) * k, CFrame.new(0.66 * k, -0.35 * k, 0.15 * k), col)
	end
end
-- Mrs. Lee: grey bun
local function bun(color)
	return function(m, ch, k)
		sphere(weldPart(m, ch, "HairCap", Vector3.new(1.5, 0.9, 1.48) * k, CFrame.new(0, 0.4 * k, 0.1 * k), color))
		weldPart(m, ch, "Bun", Vector3.new(0.8, 0.8, 0.8) * k, CFrame.new(0, 0.85 * k, 0.4 * k), color, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	end
end
-- Mr. Greer: bald top, grey ring of hair, huge grey eyebrows, grey moustache
local function greerHair(col)
	return function(m, ch, k)
		weldPart(m, ch, "HairBack", Vector3.new(1.3, 0.55, 0.3) * k, CFrame.new(0, 0.05 * k, 0.6 * k), col, Enum.Material.Fabric)
		for _, s in {-1, 1} do
			sphere(weldPart(m, ch, "Tuft", Vector3.new(0.35, 0.6, 0.75) * k, CFrame.new(s * 0.66 * k, 0.15 * k, 0.15 * k), col))
			weldPart(m, ch, "Brow", Vector3.new(0.48, 0.16, 0.12) * k, CFrame.new(s * 0.38 * k, 0.5 * k, -0.62 * k) * CFrame.Angles(0, 0, rad(s * -12)), col, Enum.Material.Fabric)
		end
		sphere(weldPart(m, ch, "Stache", Vector3.new(0.95, 0.24, 0.26) * k, CFrame.new(0, -0.2 * k, -0.62 * k), col))
	end
end
local function capOn(color)
	return function(m, ch, k)
		weldPart(m, ch, "CapTop", Vector3.new(1.4, 0.75, 1.4) * k, CFrame.new(0, 0.5 * k, 0.04 * k), color, Enum.Material.Fabric, Enum.PartType.Ball)
		weldPart(m, ch, "CapBill", Vector3.new(1.15, 0.1, 0.75) * k, CFrame.new(0, 0.42 * k, -0.85 * k) * CFrame.Angles(rad(-6), 0, 0), color, Enum.Material.Fabric)
	end
end
local function beanie(color, pom)
	return function(m, ch, k)
		sphere(weldPart(m, ch, "Beanie", Vector3.new(1.5, 0.95, 1.5) * k, CFrame.new(0, 0.45 * k, 0.05 * k), color))
		weldPart(m, ch, "BeanieRim", Vector3.new(1.52, 0.25, 1.48) * k, CFrame.new(0, 0.2 * k, 0.05 * k), color:Lerp(C3(255, 255, 255), 0.25), Enum.Material.Fabric)
		weldPart(m, ch, "Pom", Vector3.new(0.4, 0.4, 0.4) * k, CFrame.new(0, 0.98 * k, 0.05 * k), pom or C3(255, 255, 255), Enum.Material.Fabric, Enum.PartType.Ball)
	end
end
local function stache(col)
	return function(m, ch, k)
		sphere(weldPart(m, ch, "Stache", Vector3.new(0.9, 0.22, 0.25) * k, CFrame.new(0, -0.24 * k, -0.62 * k), col))
	end
end
local function beard(col)
	return function(m, ch, k)
		weldPart(m, ch, "Beard", Vector3.new(1.18, 0.4, 0.95) * k, CFrame.new(0, -0.47 * k, -0.08 * k), col, Enum.Material.Fabric)
		weldPart(m, ch, "BeardChin", Vector3.new(0.8, 0.25, 0.6) * k, CFrame.new(0, -0.68 * k, -0.25 * k), col, Enum.Material.Fabric)
	end
end
local function neckFill(col)
	return function(m, ch, k)
		local ut = m:FindFirstChild("UpperTorso")
		if ut then weldPart(m, ut, "NeckFill", Vector3.new(ut.Size.X * 0.55, 0.32, ut.Size.Z * 0.66), CFrame.new(0, ut.Size.Y / 2 + 0.08, 0), col, Enum.Material.Fabric) end
	end
end
local function stripes(col)
	return function(m)
		local ut = m:FindFirstChild("UpperTorso")
		if not ut then return end
		for i = 0, 2 do
			weldPart(m, ut, "Stripe", Vector3.new(ut.Size.X + 0.04, ut.Size.Y * 0.12, ut.Size.Z + 0.04), CFrame.new(0, ut.Size.Y * (0.28 - i * 0.28), 0), col, Enum.Material.Fabric)
		end
	end
end
local function cardigan(col, inner)
	return function(m)
		local ut = m:FindFirstChild("UpperTorso")
		if not ut then return end
		local zf = -ut.Size.Z / 2
		weldPart(m, ut, "Blouse", Vector3.new(0.55, ut.Size.Y * 0.98, 0.06), CFrame.new(0, 0, zf - 0.02), inner or C3(250, 240, 220), Enum.Material.Fabric)
		weldPart(m, ut, "Collar", Vector3.new(ut.Size.X * 0.75, 0.25, ut.Size.Z + 0.12), CFrame.new(0, ut.Size.Y / 2 - 0.06, 0), col:Lerp(C3(255, 255, 255), 0.2), Enum.Material.Fabric)
	end
end
-- a long bathrobe: over the torso, down to the shins, a belt and lapels
local function robe(col, belt)
	return function(m)
		local ut, lt = m:FindFirstChild("UpperTorso"), m:FindFirstChild("LowerTorso")
		if lt then
			weldPart(m, lt, "RobeSkirt", Vector3.new(lt.Size.X + 0.3, lt.Size.Y + 1.7, lt.Size.Z + 0.3), CFrame.new(0, -0.85, 0), col, Enum.Material.Fabric)
			weldPart(m, lt, "Belt", Vector3.new(lt.Size.X + 0.36, 0.22, lt.Size.Z + 0.36), CFrame.new(0, lt.Size.Y / 2, 0), belt, Enum.Material.Fabric)
		end
		if ut then
			local zf = -ut.Size.Z / 2
			for _, s in {-1, 1} do
				weldPart(m, ut, "Lapel", Vector3.new(0.3, ut.Size.Y * 0.9, 0.06), CFrame.new(s * 0.18, 0, zf - 0.03) * CFrame.Angles(0, 0, rad(s * 14)), col:Lerp(C3(255, 255, 255), 0.3), Enum.Material.Fabric)
			end
			weldPart(m, ut, "Undershirt", Vector3.new(0.3, ut.Size.Y * 0.6, 0.05), CFrame.new(0, ut.Size.Y * 0.18, zf - 0.02), C3(240, 240, 235), Enum.Material.Fabric)
		end
	end
end
local function slippers(col)
	return function(m)
		for _, n in {"LeftFoot", "RightFoot"} do
			local f = m:FindFirstChild(n)
			if f then weldPart(m, f, "Slipper", f.Size + Vector3.new(0.14, 0.06, 0.25), CFrame.new(0, 0.02, -0.08), col, Enum.Material.Fabric) end
		end
	end
end
-- a puffy winter coat (torso + sleeves) + a scarf
local function coat(col, scarf)
	return function(m)
		local ut = m:FindFirstChild("UpperTorso")
		if ut then
			weldPart(m, ut, "Coat", ut.Size + Vector3.new(0.22, 0.05, 0.22), CFrame.new(0, -0.02, 0), col, Enum.Material.Fabric)
			if scarf then weldPart(m, ut, "Scarf", Vector3.new(ut.Size.X * 0.8, 0.32, ut.Size.Z + 0.3), CFrame.new(0, ut.Size.Y / 2 - 0.05, 0), scarf, Enum.Material.Fabric) end
		end
		for _, n in {"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm"} do
			local a = m:FindFirstChild(n)
			if a then weldPart(m, a, "Sleeve", a.Size + Vector3.new(0.12, 0.02, 0.12), CFrame.new(), col, Enum.Material.Fabric) end
		end
	end
end
-- Juniper's pink snow boots, "KEVIN" written on both (sized from her own scaled leg parts)
local function kevinBoots(col)
	return function(m)
		for _, side in {"Left", "Right"} do
			local ll, f = m:FindFirstChild(side .. "LowerLeg"), m:FindFirstChild(side .. "Foot")
			if ll and f then
				local sh = weldPart(m, ll, "BootShaft", Vector3.new(ll.Size.X * 0.98, ll.Size.Y * 0.95, ll.Size.Z * 1.45), CFrame.new(0, -ll.Size.Y * 0.06, 0), col, Enum.Material.SmoothPlastic)
				label(sh, Enum.NormalId.Front, "KEVIN", C3(40, 40, 140))
				weldPart(m, ll, "BootCuff", Vector3.new(ll.Size.X * 1.0, ll.Size.Y * 0.16, ll.Size.Z * 1.6), CFrame.new(0, ll.Size.Y * 0.44, 0), C3(255, 255, 255), Enum.Material.Fabric)
				weldPart(m, f, "BootToe", Vector3.new(f.Size.X * 1.0, f.Size.Y * 1.35, f.Size.Z * 1.35), CFrame.new(0, f.Size.Y * 0.1, -f.Size.Z * 0.08), col, Enum.Material.SmoothPlastic)
				weldPart(m, f, "BootSole", Vector3.new(f.Size.X * 1.0, f.Size.Y * 0.35, f.Size.Z * 1.4), CFrame.new(0, -f.Size.Y * 0.55, -f.Size.Z * 0.08), C3(250, 250, 250), Enum.Material.SmoothPlastic)
			end
		end
	end
end
local function puffCoat(col)
	return function(m)
		local ut, lt = m:FindFirstChild("UpperTorso"), m:FindFirstChild("LowerTorso")
		if ut then
			weldPart(m, ut, "Coat", ut.Size + Vector3.new(0.16, 0.04, 0.16), CFrame.new(0, -0.02, 0), col, Enum.Material.Fabric)
			for i = 0, 1 do weldPart(m, ut, "Quilt", Vector3.new(ut.Size.X + 0.2, 0.06, ut.Size.Z + 0.2), CFrame.new(0, ut.Size.Y * (0.1 - i * 0.3), 0), col:Lerp(C3(255, 255, 255), 0.35), Enum.Material.Fabric) end
			weldPart(m, ut, "Hood", Vector3.new(ut.Size.X * 0.75, 0.28, ut.Size.Z * 1.05), CFrame.new(0, ut.Size.Y / 2, 0.06), C3(255, 255, 255), Enum.Material.Fabric)
		end
		if lt then weldPart(m, lt, "CoatHem", lt.Size + Vector3.new(0.18, 0.1, 0.18), CFrame.new(0, 0.02, 0), col, Enum.Material.Fabric) end
	end
end

---------------------------------------------------------------- the cast
local L = {}
local function add(name, look) table.insert(L, {name, look}) end
local SK = C3(245, 205, 170)
local BROWN = C3(110, 70, 40)
local ORANGE = C3(232, 110, 35)
-- little Blocky at 4: the same orange hoodie, jeans and hair as Blocky, as a small kid (head seated + neck filler)
add("BlockyKid", {shirt = 4601719918, pants = 9180295140, hair = 98588731108499, scale = 0.62, headScale = 1.22, headDrop = 0.36,
	mood = "happy", extras = {neckFill(ORANGE)}})
-- Juniper (3): tiny, pink puffy coat, purple leggings, brown pigtails with yellow ties, pink KEVIN boots
add("Juniper", {torso = C3(255, 130, 185), arms = C3(255, 130, 185), legs = C3(150, 110, 200), skin = SK, scale = 0.52, headScale = 1.3,
	headDrop = 0.36, mood = "happy", extras = {neckFill(C3(255, 255, 255)), puffCoat(C3(255, 130, 185)), pigtails(C3(105, 62, 35), C3(255, 215, 50))}, late = {kevinBoots(C3(255, 105, 175))}})
-- Mom + Dad (also seen 10 years younger in the puppy flashback: same people)
add("Mom", {torso = C3(60, 150, 160), arms = C3(60, 150, 160), legs = C3(60, 70, 110), skin = C3(245, 205, 172), mood = "happy",
	extras = {momHair(C3(110, 65, 40)), cardigan(C3(60, 150, 160))}})
add("Dad", {torso = C3(70, 110, 170), arms = C3(70, 110, 170), legs = C3(60, 65, 85), skin = C3(240, 196, 160), scale = 1.04, mood = "happy",
	extras = {shortHair(C3(85, 55, 35)), beard(C3(95, 60, 38))}})
-- Mr. Greer: grumpy old neighbour, faded blue bathrobe, slippers, glasses, grey hair ring + big brows
add("Greer", {torso = C3(110, 135, 175), arms = C3(110, 135, 175), legs = C3(225, 190, 165), skin = C3(235, 190, 160), scale = 1.02, width = 1.08, mood = "angry",
	extras = {robe(C3(110, 135, 175), C3(70, 85, 120)), slippers(C3(120, 80, 60)), greerHair(C3(215, 215, 220)), glasses(C3(60, 55, 55))}})
-- Mrs. Lee: lavender cardigan, grey bun, glasses
add("MrsLee", {torso = C3(170, 130, 210), arms = C3(170, 130, 210), legs = C3(110, 90, 140), skin = C3(240, 205, 175), mood = "happy",
	extras = {bun(C3(225, 225, 230)), glasses(C3(150, 90, 120)), cardigan(C3(170, 130, 210))}})
-- the kid next door (Godzilla's owner): green striped tee, red cap (about 9: no head gap at this scale, collar anyway)
add("KidNext", {torso = C3(80, 180, 90), arms = SK, legs = C3(60, 80, 140), skin = C3(200, 145, 100), scale = 0.78, headScale = 1.12, headDrop = 0.12,
	mood = "happy", extras = {neckFill(C3(80, 180, 90)), stripes(C3(250, 250, 250)), capOn(C3(220, 40, 40))}})
-- the uncle (Lucky's owner): loud yellow shirt, moustache, cap
add("Uncle", {torso = C3(255, 205, 40), arms = C3(255, 205, 40), legs = C3(70, 80, 100), skin = C3(220, 165, 120), scale = 1.06, width = 1.15, mood = "starry",
	extras = {shortHair(C3(50, 35, 25)), stache(C3(50, 35, 25)), capOn(C3(40, 120, 200))}})
-- the search party: winter coats, beanies
local NB = {
	{C3(200, 50, 50), C3(40, 40, 50), C3(240, 190, 150), C3(30, 30, 40)},
	{C3(40, 120, 90), C3(250, 220, 80), C3(160, 110, 80), C3(230, 230, 230)},
	{C3(240, 170, 40), C3(60, 60, 140), C3(250, 210, 170), C3(200, 40, 60)},
	{C3(90, 80, 160), C3(240, 240, 240), C3(120, 80, 55), C3(255, 160, 40)},
}
for i, c in ipairs(NB) do
	add("N" .. i, {torso = c[1], arms = c[1], legs = C3(50, 55, 75), skin = c[3], mood = "nervous", extras = {coat(c[1], c[2]), beanie(c[4], C3(255, 255, 255))}})
end

local out = {}
for i, e in L do
	table.insert(out, makeActor(e[1], e[2], 9800 + i * 12))
	task.wait()
end
return table.concat(out, "\n")
