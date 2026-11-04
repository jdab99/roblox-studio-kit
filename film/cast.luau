-- Reel cast: every actor for the story reels, built in Edit mode into workspace.Film.Cast (parked offstage).
-- Root anchored, limbs free, so the client Director can play animations and set poses.
-- Classic round head + our face decals (assets/faces/face_ids.json). Safe to re-run.
local Players = game:GetService("Players")
local FACES = {
	happy = 72579951856139, shocked = 123471687600628, scared = 81022056057673, sneaky = 82374946742835,
	angry = 125197693534047, sad = 72026756477677, sleep = 70540320410457, laugh = 90847884666687,
}
local film = workspace:FindFirstChild("Film") or Instance.new("Model")
film.Name = "Film"
film.Parent = workspace
local old = film:FindFirstChild("Cast")
if old then old:Destroy() end
local cast = Instance.new("Folder")
cast.Name = "Cast"
cast.Parent = film

local SKIN = Color3.fromRGB(255, 205, 150)
local function weldPart(m, attachTo, name, size, cf, color, mat, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.CanCollide = false
	p.Massless = true
	p.CFrame = attachTo.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = attachTo, p
	w.Parent = p
	p.Parent = m
	return p
end

local function build(look)
	local desc = Instance.new("HumanoidDescription")
	if look.shirt then desc.Shirt = look.shirt end
	if look.pants then desc.Pants = look.pants end
	if look.hair then desc.HairAccessory = tostring(look.hair) end
	if look.hat then desc.HatAccessory = tostring(look.hat) end
	if look.faceAcc then desc.FaceAccessory = look.faceAcc end
	local skin = look.skin or SKIN
	desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = skin, skin, skin
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

-- try the full look; drop items one by one if an id is bad
local function makeActor(name, look, slot)
	local m, err = build(look)
	local dropped = {}
	if not m then
		for _, k in {"faceAcc", "hat", "hair", "pants", "shirt"} do
			if look[k] then
				look[k] = nil
				table.insert(dropped, k)
				m = build(look)
				if m then break end
			end
		end
	end
	if not m then return name .. " FAILED " .. tostring(err) end
	m.Name = name
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	local an = m:FindFirstChild("Animate")
	if an then an:Destroy() end
	if not hum:FindFirstChildOfClass("Animator") then Instance.new("Animator", hum) end
	-- classic head + face decal
	local head = m.Head
	head.Transparency = 1
	local fc = head:FindFirstChildOfClass("FaceControls")
	if fc then fc:Destroy() end
	for _, d in head:GetChildren() do if d:IsA("Decal") then d:Destroy() end end
	local ch = Instance.new("Part")
	ch.Name = "ClassicHead"
	ch.Size = Vector3.new(2, 1, 1)
	ch.Color = look.skin or SKIN
	ch.CanCollide = false
	ch.Massless = true
	ch.CFrame = head.CFrame
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25) * (head.Size.Y / 1.2)
	mesh.Parent = ch
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Face = Enum.NormalId.Front
	face.Texture = "rbxassetid://" .. FACES[look.mood or "happy"]
	face.Parent = ch
	local w = Instance.new("WeldConstraint")
	w.Part0, w.Part1 = head, ch
	w.Parent = ch
	ch.Parent = m
	if look.extras then look.extras(m, ch) end
	m:PivotTo(CFrame.new(slot, 400, 3000))
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = (p.Name == "HumanoidRootPart")
			p.CastShadow = true
		end
	end
	m:SetAttribute("HipY", hum.HipHeight + m.HumanoidRootPart.Size.Y / 2)
	m.Parent = cast
	return name .. (#dropped > 0 and (" (dropped " .. table.concat(dropped, ",") .. ")") or "") .. string.format(" hipY=%.2f", m:GetAttribute("HipY"))
end

-- parts-built accessories
local BLACK = Color3.fromRGB(25, 25, 30)
local function topHat(m, ch)
	local hs = ch.Size.Y
	weldPart(m, ch, "HatBrim", Vector3.new(0.12, 2.3, 2.3), CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, nil, Enum.PartType.Cylinder)
	weldPart(m, ch, "HatTop", Vector3.new(1.5, 1.5, 1.5), CFrame.new(0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, nil, Enum.PartType.Cylinder)
	weldPart(m, ch, "HatBand", Vector3.new(0.3, 1.56, 1.56), CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 200, 40), Enum.Material.Foil, Enum.PartType.Cylinder)
end
local function nightcap(color)
	return function(m, ch)
		weldPart(m, ch, "Cap", Vector3.new(1.4, 1.2, 1.4), CFrame.new(0, 0.75, 0.1) * CFrame.Angles(math.rad(-25), 0, 0), color, Enum.Material.Fabric, Enum.PartType.Ball)
		weldPart(m, ch, "Pom", Vector3.new(0.45, 0.45, 0.45), CFrame.new(0, 1.15, 0.9), Color3.new(1, 1, 1), Enum.Material.Fabric, Enum.PartType.Ball)
	end
end

local GUARD = {shirt = 15438617003, pants = 10915602283, hat = "104751413508452"}
local COP = {shirt = 74614200094847, pants = 10915602283, hat = "113169407574034"}
local BLACKPANTS = 7189083561
local L = {}
local function add(name, look) table.insert(L, {name, look}) end

-- main cast
add("Blocky", {shirt = 4601719918, pants = 9180295140, hair = 98588731108499, mood = "happy"})
add("Pip", {shirt = 8696625817, hair = 6413290259, legs = Color3.fromRGB(255, 220, 90), scale = 0.75, headScale = 1.15, mood = "sad"})
add("Grandma", {shirt = 6258389026, hair = 6216526940, faceAcc = "4143016822", legs = Color3.fromRGB(150, 90, 170),
	skin = Color3.fromRGB(245, 200, 160), mood = "sleep"})
add("Glimmer", {shirt = 6554200369, pants = BLACKPANTS, hair = 7611015444, faceAcc = "4435441139,5618226026", mood = "laugh",
	extras = topHat})
add("Tony", {shirt = GUARD.shirt, pants = GUARD.pants, hat = GUARD.hat, scale = 1.3, width = 1.45, skin = Color3.fromRGB(200, 150, 110), mood = "angry"})
add("Guard2", {shirt = GUARD.shirt, pants = GUARD.pants, hat = GUARD.hat, skin = Color3.fromRGB(230, 180, 140), mood = "angry"})
for i = 1, 4 do
	add("Cop" .. i, {shirt = COP.shirt, pants = COP.pants, hat = COP.hat, skin = (i % 2 == 0) and Color3.fromRGB(160, 110, 80) or Color3.fromRGB(235, 190, 150), mood = "angry"})
end
-- neighbors in pajamas
local PJ = {
	{shirt = 9399259460, hair = 63690008, legs = Color3.fromRGB(255, 220, 90)},
	{shirt = 9362987703, hair = 376527350, legs = Color3.fromRGB(240, 240, 250)},
	{shirt = 7904289104, hair = 376524487, legs = Color3.fromRGB(190, 40, 50)},
	{shirt = 127908713366728, hair = 5314006793, legs = Color3.fromRGB(110, 150, 230)},
	{shirt = 11771162194, hair = 7611004838, legs = Color3.fromRGB(240, 240, 240), skin = Color3.fromRGB(240, 195, 160)},
	{shirt = 16092670534, hair = 376548738, legs = Color3.fromRGB(40, 40, 45), skin = Color3.fromRGB(150, 100, 70)},
	{shirt = 9399259460, hair = 6413288640, legs = Color3.fromRGB(255, 220, 90), scale = 0.75, headScale = 1.15},
	{shirt = 9362987703, hair = 63690008, legs = Color3.fromRGB(240, 240, 250), scale = 0.8, headScale = 1.15, skin = Color3.fromRGB(150, 100, 70)},
}
for i, pj in PJ do
	pj.mood = "sad"
	if i == 1 or i == 5 then pj.extras = nightcap(i == 1 and Color3.fromRGB(70, 100, 200) or Color3.fromRGB(200, 60, 60)) end
	add("Fam" .. i, pj)
end
-- gag extras
add("Sleeper", {shirt = 7904289104, hair = 376524487, legs = Color3.fromRGB(190, 40, 50), mood = "sleep", extras = nightcap(Color3.fromRGB(190, 40, 50))})
add("Thief", {shirt = 16092670534, pants = BLACKPANTS, hat = "4904891637", mood = "sneaky"})
add("Prisoner", {shirt = 16092670534, legs = Color3.fromRGB(240, 240, 240), hair = 7611023035, mood = "sad"})
add("Teacher", {shirt = 6553589977, pants = BLACKPANTS, hair = 376527350, faceAcc = "11884330", mood = "sneaky"})
local KIDS = {{398635081, 398635338, 63690008}, {144076436, 12598481285, 6413290259}, {4047884939, 7189083561, 376548738}, {3670737444, 398635338, 6413288640}}
for i, k in KIDS do
	add("Kid" .. i, {shirt = k[1], pants = k[2], hair = k[3], scale = 0.8, headScale = 1.1, mood = "sneaky",
		skin = (i % 2 == 0) and Color3.fromRGB(160, 110, 80) or SKIN})
end

local out = {}
for i, e in L do
	table.insert(out, makeActor(e[1], e[2], i * 12))
	if i % 4 == 0 then task.wait() end
end
return table.concat(out, "\n")
