-- Blocky, the face of Blocky Tales. Builds him on a portrait set at x=1000 (away from game maps).
-- Classic round head + our own face decals (assets/faces/face_ids.json); new default heads ignore classic faces.
local Players = game:GetService("Players")
local FACES = {
	happy = 72579951856139, shocked = 123471687600628, scared = 81022056057673,
	sneaky = 82374946742835, angry = 125197693534047, sad = 72026756477677,
}
local SKIN = Color3.fromRGB(255, 205, 150)

local old = workspace:FindFirstChild("MascotSet")
if old then old:Destroy() end
local set = Instance.new("Model")
set.Name = "MascotSet"
set.Parent = workspace

local O = Vector3.new(1000, 50, 0)
local function part(name, size, pos, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = O + pos
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.Parent = set
	return p
end
part("Floor", Vector3.new(90, 1, 90), Vector3.new(0, -0.5, 0), Color3.fromRGB(255, 196, 40))
part("Wall", Vector3.new(60, 40, 1), Vector3.new(0, 20, 12), Color3.fromRGB(255, 210, 70))

-- swap a character's dynamic head for a classic round head wearing our face decal
local function classicHead(m, mood)
	local head = m.Head
	head.Transparency = 1
	local fc = head:FindFirstChildOfClass("FaceControls")
	if fc then fc:Destroy() end
	for _, d in head:GetChildren() do
		if d:IsA("Decal") then d:Destroy() end
	end
	local ch = Instance.new("Part")
	ch.Name = "ClassicHead"
	ch.Size = Vector3.new(2, 1, 1)
	ch.Color = SKIN
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
	face.Texture = "rbxassetid://" .. FACES[mood]
	face.Parent = ch
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = head, ch
	weld.Parent = ch
	ch.Anchored = head.Anchored
	ch.Parent = m
	m:SetAttribute("Mood", mood)
end

local function makeBlocky(hair, mood, pos)
	local desc = Instance.new("HumanoidDescription")
	desc.Shirt = 4601719918        -- Orange Hoodie
	desc.Pants = 9180295140        -- Dark Blue Jeans
	desc.HairAccessory = tostring(hair)
	desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = SKIN, SKIN, SKIN
	desc.LeftLegColor, desc.RightLegColor, desc.TorsoColor = SKIN, SKIN, SKIN
	desc.BodyTypeScale, desc.ProportionScale = 0, 0
	local m = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	m.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then p.Anchored = true end
	end
	m:PivotTo(CFrame.new(pos)) -- faces -Z, toward the camera
	classicHead(m, mood)
	m.Parent = set
	return m
end

local HAIR = 98588731108499 -- short brown boy hair (catalog: "Brown messy fluffy cool boy hair"), picked 11-02
local hero = makeBlocky(HAIR, "happy", O + Vector3.new(0, 3.2, 0))
hero.Name = "Blocky"
local x = -15
for _, mood in {"happy", "shocked", "scared", "sneaky", "angry", "sad"} do
	local m = makeBlocky(HAIR, mood, O + Vector3.new(x, 3.2, -30))
	m.Name = "Blocky_" .. mood
	x += 6
end
return "ok"
