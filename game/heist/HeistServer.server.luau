-- Heist round logic (ServerScriptService.HeistServer).
-- Loop: Lobby countdown -> Heist (sneak, solve, loot, stash at the van, fight the police, drive away) -> End -> reset.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")

local Config = require(RS:WaitForChild("HeistConfig"))
local map = workspace:WaitForChild("HeistMap")
local F = {
	Loot = map:WaitForChild("Loot"), Cameras = map:WaitForChild("Cameras"), Lasers = map:WaitForChild("Lasers"),
	Lights = map:WaitForChild("StoreLights"), AlarmLights = map:WaitForChild("AlarmLights"),
	Routes = map:WaitForChild("GuardRoutes"), Props = map:WaitForChild("Props"), Glass = map:WaitForChild("Glass"),
}
local function npcFolder(name)
	local f = map:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name
	f.Parent = map
	return f
end
F.Guards, F.Police = npcFolder("Guards"), npcFolder("Police")
local van = map:WaitForChild("Van")
local stash = van:WaitForChild("StashZone")
local drivePrompt = van:WaitForChild("DriverDoor"):WaitForChild("Prompt")
local spawnPart = map:WaitForChild("HeistSpawn")
local jailSpot = map:WaitForChild("JailSpot")
local vanHome = van:GetPivot()

local LEVEL = 1
local L = Config.Levels[LEVEL]
local B, PC = Config.Blaster, Config.Player

-- shared state the HUD reads
local H = RS:FindFirstChild("Heist") or Instance.new("Folder")
H.Name = "Heist"
H.Parent = RS
local function val(class, name, v)
	local x = H:FindFirstChild(name) or Instance.new(class)
	x.Name = name
	if v ~= nil then x.Value = v end
	x.Parent = H
	return x
end
local Phase = val("StringValue", "Phase", "Lobby")
local Objective = val("StringValue", "Objective", "")
local Quota = val("IntValue", "Quota", L.Quota)
local Banked = val("IntValue", "Banked", 0)
local Alarm = val("BoolValue", "Alarm", false)
local PoliceLeft = val("NumberValue", "PoliceLeft", 0) -- seconds until the next backup wave
local Wave = val("IntValue", "Wave", 0)
local TimeLeft = val("NumberValue", "TimeLeft", 0)
local Result = val("StringValue", "Result", "")
local Power = val("BoolValue", "Power", true)
local LevelName = val("StringValue", "LevelName", L.Name)
local remote = RS:FindFirstChild("HeistRemote") or Instance.new("RemoteEvent")
remote.Name = "HeistRemote"
remote.Parent = RS

local function sound(id, parent, volume, looped, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.6
	s.Looped = looped or false
	s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 220
	s.Parent = parent
	return s
end
local function oneShot(id, parent, volume, speed)
	local s = sound(id, parent, volume, false, speed)
	s:Play()
	game:GetService("Debris"):AddItem(s, 3)
end
local siren = sound(Config.Sounds.Siren, stash, 0.5, true)
local bell = sound(Config.Sounds.Bell, map:WaitForChild("Static"):WaitForChild("Ceiling"), 0.5, true)

local S -- round state, rebuilt by resetRound()
local bags, crouch, sprint, arrested, downed = {}, {}, {}, {}, {}
local lastHit, lastShot, reloading = {}, {}, {}

local function toast(player, text, color)
	if player then
		remote:FireClient(player, "Toast", text, color)
	else
		remote:FireAllClients("Toast", text, color)
	end
end
local function feed(text, color) remote:FireAllClients("Feed", text, color) end
local function charOf(p)
	local c = p and p.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health > 0 then return c, h, r end
	return nil
end
local function bag(p)
	bags[p] = bags[p] or {slots = 0, value = 0, items = {}}
	return bags[p]
end
local function updatePlayer(p)
	local b = bag(p)
	p:SetAttribute("BagSlots", b.slots)
	p:SetAttribute("BagValue", b.value)
	p:SetAttribute("Arrested", arrested[p] == true)
	p:SetAttribute("Sneaking", crouch[p] == true)
	p:SetAttribute("Sprinting", sprint[p] == true and not crouch[p])
	local _, h = charOf(p)
	if h then
		local sp = math.max(Config.MinSpeed, Config.BaseSpeed - b.slots * Config.SpeedPerSlot)
		if crouch[p] then
			sp *= Config.SneakMultiplier
		elseif sprint[p] then
			sp *= Config.SprintMultiplier
		end
		if downed[p] then sp = 0 end
		h.WalkSpeed = sp
	end
end
local function eligible()
	local out = {}
	for _, p in Players:GetPlayers() do
		local c, h, r = charOf(p)
		if c and not arrested[p] and not downed[p] then table.insert(out, {p = p, c = c, r = r}) end
	end
	return out
end
local function flat(v) return Vector3.new(v.X, 0, v.Z) end

---------------------------------------------------------------- alarm + power
local function setAlarmLights(on)
	for _, p in F.AlarmLights:GetChildren() do
		local l = p:FindFirstChildOfClass("PointLight")
		if l then l.Enabled = on end
		p.Color = on and Color3.fromRGB(255, 30, 30) or Color3.fromRGB(90, 0, 0)
		p.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end
local function triggerAlarm(reason)
	if Phase.Value ~= "Heist" or Alarm.Value then return false end
	Alarm.Value = true
	S.alarmReason = reason
	S.nextWave = os.clock() + Config.Police.FirstWave
	siren:Play()
	bell:Play()
	toast(nil, "ALARM! " .. reason, Color3.fromRGB(255, 70, 70))
	for _, g in S.guards do
		if not g.koUntil then g.state = "chase" end
	end
	task.spawn(function()
		local on = true
		while Alarm.Value and S and not S.over do
			setAlarmLights(on)
			on = not on
			task.wait(0.45)
		end
		setAlarmLights(false)
	end)
	return true
end
local function setPower(on)
	Power.Value = on
	for _, cam in F.Cameras:GetChildren() do
		cam.Beam.Enabled = on
		cam.Led.Enabled = on
	end
	for _, l in F.Lasers:GetChildren() do
		l.Transparency = on and 0 or 1
	end
	for _, lamp in F.Lights:GetChildren() do
		local l = lamp:FindFirstChildOfClass("PointLight")
		if l then l.Brightness = on and 0.9 or 0.18 end
		lamp.Material = on and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
	local pb = F.Props:FindFirstChild("PowerBox")
	if pb then pb.Status.Color = on and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 40, 40) end
end

---------------------------------------------------------------- loot
local function noise(pos, radius, strength)
	for _, g in S.guards do
		if g.root and not g.koUntil and (g.root.Position - pos).Magnitude < radius and g.state ~= "chase" then
			g.susp = math.min(0.95, g.susp + (strength or 0.45))
			g.state = "investigate"
			g.investigate = pos
			g.investigateUntil = nil
		end
	end
end
local function setItemTaken(item, taken)
	item:SetAttribute("Taken", taken)
	item.Transparency = taken and 1 or (item.Name == "Diamond" and 0.15 or 0)
	item.Prompt.Enabled = not taken
	local l = item:FindFirstChildOfClass("PointLight")
	if l then l.Enabled = not taken end
end
local function grab(p, item)
	if Phase.Value ~= "Heist" or arrested[p] or downed[p] or item:GetAttribute("Taken") then return false, "not now" end
	local b = bag(p)
	local slots = item:GetAttribute("Slots") or 1
	if b.slots + slots > Config.BagSlots then
		toast(p, "Your bag is full! Stash it at the van.", Color3.fromRGB(255, 200, 60))
		return false, "full"
	end
	local glassRef = item:FindFirstChild("Glass")
	if glassRef and glassRef.Value and glassRef.Value.Transparency < 1 then
		glassRef.Value.Transparency = 1
		oneShot(Config.Sounds.Glass, item, 0.8)
		noise(item.Position, 28)
	end
	setItemTaken(item, true)
	b.slots += slots
	b.value += item:GetAttribute("Value")
	table.insert(b.items, item)
	updatePlayer(p)
	toast(p, "+$" .. item:GetAttribute("Value") .. "  " .. (item:GetAttribute("Label") or item.Name), Color3.fromRGB(120, 255, 150))
	return true
end
local function dropBag(p)
	local b = bag(p)
	for _, item in b.items do setItemTaken(item, false) end
	bags[p] = nil
	updatePlayer(p)
end
local function inZone(pos, part)
	local rel = part.CFrame:PointToObjectSpace(pos)
	local half = part.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y + 3 and math.abs(rel.Z) <= half.Z
end
local function stashAll()
	for _, p in Players:GetPlayers() do
		local _, _, r = charOf(p)
		local b = bags[p]
		if r and b and b.value > 0 and not arrested[p] and not downed[p] and inZone(r.Position, stash) then
			Banked.Value += b.value
			toast(nil, p.DisplayName .. " stashed $" .. b.value .. "!", Color3.fromRGB(120, 255, 150))
			bags[p] = nil
			updatePlayer(p)
		end
	end
	drivePrompt.Enabled = Phase.Value == "Heist" and Banked.Value >= Quota.Value
end

---------------------------------------------------------------- doors, note, vault, power box
local function openFrontDoor()
	if S.frontOpen then return false end
	S.frontOpen = true
	local d = F.Props.FrontDoor
	d.CanCollide = false
	d.Prompt.Enabled = false
	TweenService:Create(d, TweenInfo.new(0.8), {CFrame = d:GetAttribute("Home") * CFrame.new(7.5, 0, 0)}):Play()
	return true
end
local function openVault()
	if S.vaultOpen then return false end
	S.vaultOpen = true
	local d, w = F.Props.VaultDoor, F.Props.VaultWheel
	F.Props.Keypad.Status.Color = Color3.fromRGB(60, 255, 90)
	F.Props.Keypad.Prompt.Enabled = false
	TweenService:Create(w, TweenInfo.new(1.2), {CFrame = w:GetAttribute("Home") * CFrame.Angles(math.rad(360), 0, 0)}):Play()
	task.delay(1.2, function()
		d.CanCollide = false
		TweenService:Create(d, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {CFrame = d:GetAttribute("Home") * CFrame.new(-6.2, 0, 0)}):Play()
		TweenService:Create(w, TweenInfo.new(1.5, Enum.EasingStyle.Quad), {CFrame = w:GetAttribute("Home") + Vector3.new(-6.2, 0, 0)}):Play()
	end)
	toast(nil, "The vault is open!", Color3.fromRGB(120, 255, 150))
	return true
end
local function tryCode(p, digits)
	if Phase.Value ~= "Heist" or S.vaultOpen or arrested[p] then return "closed" end
	if tostring(digits) == S.code then
		openVault()
		return "open"
	end
	S.wrongCodes += 1
	toast(p, "Wrong code (" .. S.wrongCodes .. "/" .. L.WrongCodeLimit .. ")", Color3.fromRGB(255, 120, 60))
	if S.wrongCodes >= L.WrongCodeLimit then
		triggerAlarm("Too many wrong codes on the vault!")
	end
	return "wrong"
end
local function cutPower(p)
	if not Power.Value or Phase.Value ~= "Heist" then return false end
	setPower(false)
	toast(nil, "Power cut! Cameras and lasers are OFF.", Color3.fromRGB(150, 200, 255))
	noise(F.Props.PowerBox.Position, 18)
	return true
end

---------------------------------------------------------------- player health, down, cage
local function arrest(p)
	if arrested[p] then return end
	arrested[p] = true
	downed[p] = nil
	dropBag(p)
	crouch[p], sprint[p] = false, false
	p:SetAttribute("HP", PC.MaxHealth)
	local c, h = charOf(p)
	if h then h.PlatformStand = false end
	if c then c:PivotTo(jailSpot.CFrame + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))) end
	updatePlayer(p)
	feed(p.DisplayName .. " got dragged to the cage!", Color3.fromRGB(255, 90, 90))
	toast(p, "You're in the police cage. A teammate can free you!", Color3.fromRGB(150, 180, 255))
end
local function knockDownPlayer(p)
	if downed[p] or arrested[p] then return end
	downed[p] = true
	local _, h = charOf(p)
	if h then h.PlatformStand = true end
	updatePlayer(p)
	remote:FireClient(p, "Downed")
	task.delay(PC.DownTime, function()
		if downed[p] and S and not S.over then arrest(p) end
	end)
end
local function damage(p, amount, fromPos)
	if arrested[p] or downed[p] or Phase.Value ~= "Heist" then return end
	local hp = math.max(0, (p:GetAttribute("HP") or PC.MaxHealth) - amount)
	p:SetAttribute("HP", hp)
	lastHit[p] = os.clock()
	remote:FireClient(p, "Hurt", amount, fromPos)
	if hp <= 0 then knockDownPlayer(p) end
end
local function freeCrew(p)
	if arrested[p] or Phase.Value ~= "Heist" then return false end
	local n = 0
	for q, a in arrested do
		if a then
			arrested[q] = false
			n += 1
			if q.Character then q.Character:PivotTo(jailSpot.CFrame + Vector3.new(0, 3, -12)) end
			updatePlayer(q)
		end
	end
	if n > 0 then feed(p.DisplayName .. " freed the crew!", Color3.fromRGB(150, 200, 255)) end
	return n > 0
end

---------------------------------------------------------------- NPCs (guards + police)
local WALK, IDLE, RUN = "rbxassetid://913402848", "rbxassetid://507766388", "rbxassetid://913376220"
local npcByModel = {}
local function setFace(n, mood)
	if n.mood == mood then return end
	n.mood = mood
	if n.face then n.face.Texture = "rbxassetid://" .. Config.Faces[mood] end
end
local function makeNPC(look, cf, name, folder, skin)
	local desc = Instance.new("HumanoidDescription")
	desc.Shirt = look.Shirt
	desc.Pants = look.Pants
	desc.HatAccessory = look.Hat
	skin = skin or Color3.fromRGB(230, 180, 140)
	desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = skin, skin, skin
	desc.LeftLegColor, desc.RightLegColor, desc.TorsoColor = skin, skin, skin
	desc.BodyTypeScale, desc.ProportionScale = 0, 0
	local ok, m = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok then warn("npc build failed: " .. tostring(m)) return nil end
	m.Name = name
	local hum = m:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.BreakJointsOnDeath = false
	-- classic round head + face decal (same trick as the Blocky mascot)
	local head = m.Head
	head.Transparency = 1
	local fc = head:FindFirstChildOfClass("FaceControls")
	if fc then fc:Destroy() end
	for _, d in head:GetChildren() do if d:IsA("Decal") then d:Destroy() end end
	local ch = Instance.new("Part")
	ch.Name = "ClassicHead"
	ch.Size = Vector3.new(2, 1, 1)
	ch.Color = skin
	ch.CanCollide = false
	ch.Massless = true
	ch.CFrame = head.CFrame
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25) * (head.Size.Y / 1.2)
	mesh.Parent = ch
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Parent = ch
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = head, ch
	weld.Parent = ch
	ch.Parent = m
	local fl = Instance.new("SpotLight")
	fl.Name = "Flashlight"
	fl.Face = Enum.NormalId.Front
	fl.Color = Color3.fromRGB(255, 245, 200)
	fl.Brightness = 3
	fl.Range = Config.Guard.Range
	fl.Angle = Config.Guard.Fov * 2
	fl.Shadows = true
	fl.Parent = ch
	local bb = Instance.new("BillboardGui")
	bb.Name = "Alert"
	bb.Size = UDim2.fromOffset(60, 60)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = ch
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true
	tl.Text = ""
	tl.TextStrokeTransparency = 0
	tl.Parent = bb
	-- cartoon stars for knockouts
	local sb = Instance.new("BillboardGui")
	sb.Name = "Stars"
	sb.Size = UDim2.fromOffset(110, 50)
	sb.StudsOffset = Vector3.new(0, 1.2, 0)
	sb.AlwaysOnTop = true
	sb.Enabled = false
	sb.Parent = ch
	local st = tl:Clone()
	st.Text = "★  ✦  ★"
	st.TextColor3 = Color3.fromRGB(255, 225, 60)
	st.Parent = sb
	m:PivotTo(cf)
	m.Parent = folder
	local root = m:FindFirstChild("HumanoidRootPart")
	pcall(function() root:SetNetworkOwner(nil) end)
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local function track(id)
		local a = Instance.new("Animation")
		a.AnimationId = id
		local okT, t = pcall(function() return animator:LoadAnimation(a) end)
		return okT and t or nil
	end
	local n = {model = m, hum = hum, root = root, head = ch, face = face, label = tl, stars = st, starGui = sb, flashlight = fl,
		walk = track(WALK), run = track(RUN), idle = track(IDLE)}
	npcByModel[m] = n
	if n.idle then n.idle:Play() end
	hum.Running:Connect(function(speed)
		if not n.walk or n.koUntil then return end
		local moving, fast = speed > 0.5, speed > 12
		if moving and fast then
			if n.walk.IsPlaying then n.walk:Stop(0.2) end
			if n.run and not n.run.IsPlaying then n.run:Play(0.2) end
		elseif moving then
			if n.run and n.run.IsPlaying then n.run:Stop(0.2) end
			if not n.walk.IsPlaying then n.walk:Play(0.2) end
		else
			n.walk:Stop(0.2)
			if n.run then n.run:Stop(0.2) end
		end
	end)
	return n
end
local function makeGuard(routeFolder, i)
	local pts = {}
	for k = 1, #routeFolder:GetChildren() do pts[k] = routeFolder["P" .. k].Position end
	local g = makeNPC(Config.GuardLook, CFrame.lookAt(pts[1] + Vector3.new(0, 3, 0), pts[2] + Vector3.new(0, 3, 0)), "Guard" .. i, F.Guards)
	if not g then return nil end
	g.kind, g.pts, g.idx, g.susp, g.state = "guard", pts, 2, 0, "patrol"
	g.hum.WalkSpeed = Config.Guard.WalkSpeed
	setFace(g, "calm")
	return g
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
local function canSee(fromPos, char, ignore)
	local r = char and char:FindFirstChild("HumanoidRootPart")
	if not r then return false end
	rayParams.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(fromPos, r.Position - fromPos, rayParams)
	return hit and hit.Instance:IsDescendantOf(char) or false
end
local function floorBelow(pos)
	rayParams.FilterDescendantsInstances = {F.Guards, F.Police, F.Loot}
	local hit = workspace:Raycast(pos, Vector3.new(0, -14, 0), rayParams)
	return hit and hit.Position.Y or 0.4
end

local function knockOut(n, by)
	if n.koUntil then
		n.koUntil = os.clock() + B.StunTime -- shot again while down: stays down longer
		return
	end
	n.koUntil = os.clock() + B.StunTime
	n.hum:MoveTo(n.root.Position)
	for _, t in {n.walk, n.run, n.idle} do if t then t:Stop(0) end end
	local pos = n.root.Position
	local _, yaw = n.root.CFrame:ToOrientation()
	n.root.Anchored = true
	n.hum.PlatformStand = true
	n.root.CFrame = CFrame.new(pos.X, floorBelow(pos) + 0.9, pos.Z) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(-90), 0, 0)
	setFace(n, "knocked")
	n.label.Text = ""
	n.starGui.Enabled = true
	n.flashlight.Enabled = false
	n.susp = 0
	feed((n.kind == "cop" and "Cop" or "Guard") .. " knocked out!" .. (by and (" (" .. by.DisplayName .. ")") or ""), Color3.fromRGB(255, 225, 60))
end
local function wakeUp(n)
	n.koUntil = nil
	local pos = n.root.Position
	local _, yaw = n.root.CFrame:ToOrientation()
	n.root.CFrame = CFrame.new(pos.X, floorBelow(pos + Vector3.new(0, 2, 0)) + 3, pos.Z) * CFrame.Angles(0, yaw, 0)
	n.root.Anchored = false
	n.hum.PlatformStand = false
	n.starGui.Enabled = false
	n.flashlight.Enabled = true
	if n.idle then n.idle:Play() end
	if n.kind == "cop" then
		n.hp = n.maxHp
		setFace(n, "alert")
	else
		n.susp = Alarm.Value and 1 or 0.6
		n.state = Alarm.Value and "chase" or "investigate"
		n.investigate = pos
		setFace(n, "suspicious")
	end
end

local function guardTick(g, dt)
	if not (g.root and g.root.Parent) or g.koUntil then return end
	local G = Config.Guard
	local eye = g.head.Position
	local fwd = flat(g.root.CFrame.LookVector).Unit
	local seen, seenDist = nil, math.huge
	for _, e in eligible() do
		local to = e.r.Position - eye
		local d = to.Magnitude
		if d < G.Range then
			local ang = math.deg(math.acos(math.clamp(fwd:Dot(flat(to).Unit), -1, 1)))
			local sneaking = crouch[e.p]
			if ang < G.Fov and canSee(eye, e.c, {g.model, F.Loot, F.Lasers, F.Glass, F.Props.FrontDoor}) then
				local rate = G.SeeRate * (1.5 - d / G.Range) * (sneaking and G.SneakRate or 1)
				if d < 7 then rate *= 2 end
				g.susp += rate * dt
				if d < seenDist then seen, seenDist = e, d end
			elseif d < 5 and not sneaking then
				g.susp += 0.7 * dt -- heard footsteps right behind
				if d < seenDist then seen, seenDist = e, d end
			end
		end
	end
	if not seen then g.susp = math.max(0, g.susp - G.Decay * dt) end
	g.susp = math.min(g.susp, 1.2)

	if g.susp >= 1 and g.state ~= "chase" then
		g.state = "chase"
		g.target = seen and seen.p
		g.reactUntil = os.clock() + G.ReactTime
		triggerAlarm("A guard spotted you!")
	end

	if g.state == "chase" then
		setFace(g, "alert")
		g.label.Text = "!"
		g.label.TextColor3 = Color3.fromRGB(255, 50, 50)
		g.hum.WalkSpeed = G.ChaseSpeed
		if g.reactUntil and os.clock() < g.reactUntil then
			g.hum:MoveTo(g.root.Position) -- the "!" moment: a beat to run (or shoot)
			return
		end
		local tgt = g.target and not arrested[g.target] and not downed[g.target] and select(3, charOf(g.target))
		if not tgt then
			g.target = nil
			local best
			for _, e in eligible() do
				local d = (e.r.Position - g.root.Position).Magnitude
				if d < 70 and (not best or d < best.d) then best = {p = e.p, d = d} end
			end
			if best then g.target = best.p end
			tgt = g.target and select(3, charOf(g.target))
		end
		if tgt then
			g.hum:MoveTo(tgt.Position)
			if (tgt.Position - g.root.Position).Magnitude < G.CatchDistance and os.clock() > (g.tackleReady or 0) then
				-- tackle: a big hit, not an instant cage, so you can still fight back
				g.tackleReady = os.clock() + 2
				g.reactUntil = os.clock() + 1.1 -- the guard staggers after a tackle: a beat to get away or shoot
				damage(g.target, 20, g.root.Position)
				local _, _, pr = charOf(g.target)
				if pr then pr.AssemblyLinearVelocity = (flat(pr.Position - g.root.Position).Unit * 45) + Vector3.new(0, 25, 0) end
			end
		else
			g.hum:MoveTo(g.pts[g.idx])
		end
		return
	end

	g.hum.WalkSpeed = G.WalkSpeed
	if seen and g.susp > 0.3 then
		setFace(g, "suspicious")
		g.label.Text = "?"
		g.label.TextColor3 = Color3.fromRGB(255, 220, 40)
		g.hum:MoveTo(g.root.Position)
		local look = Vector3.new(seen.r.Position.X, g.root.Position.Y, seen.r.Position.Z)
		g.root.CFrame = g.root.CFrame:Lerp(CFrame.lookAt(g.root.Position, look), math.min(1, dt * 6))
		return
	end
	g.label.Text = g.susp > 0.12 and "?" or ""
	g.label.TextColor3 = Color3.fromRGB(255, 220, 40)
	setFace(g, g.susp > 0.12 and "suspicious" or "calm")
	if g.state == "investigate" and g.investigate then
		g.hum:MoveTo(g.investigate)
		if flat(g.investigate - g.root.Position).Magnitude < 4 then
			g.investigateUntil = g.investigateUntil or (os.clock() + 3)
			if os.clock() > g.investigateUntil then
				g.state, g.investigate = "patrol", nil
			end
		end
		return
	end
	local goal = g.pts[g.idx]
	g.hum:MoveTo(goal)
	if flat(goal - g.root.Position).Magnitude < 2 then
		g.idx = g.idx % #g.pts + 1
	end
end

---------------------------------------------------------------- police backup
local CAR_SPOTS = {Vector3.new(-40, 0, 38), Vector3.new(-14, 0, 37), Vector3.new(14, 0, 37), Vector3.new(40, 0, 38)}
local function policeCar(pos)
	local car = Instance.new("Model")
	car.Name = "PoliceCar"
	local function cp(size, off, color, mat)
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.Position = pos + off
		p.Color = color
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Parent = car
		return p
	end
	cp(Vector3.new(14, 3, 7), Vector3.new(0, 2.2, 0), Color3.fromRGB(240, 240, 245))
	cp(Vector3.new(14.1, 1.2, 7.1), Vector3.new(0, 2.6, 0), Color3.fromRGB(20, 25, 40))
	cp(Vector3.new(8, 2.2, 6.6), Vector3.new(-0.5, 4.8, 0), Color3.fromRGB(20, 25, 40), Enum.Material.Glass)
	for j, c in {Color3.fromRGB(255, 30, 30), Color3.fromRGB(40, 80, 255)} do
		local bar = cp(Vector3.new(1.6, 0.7, 1.4), Vector3.new(j == 1 and -1 or 1, 6.2, 0), c, Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Color, l.Range, l.Brightness = c, 32, 5
		l.Parent = bar
		task.spawn(function()
			while bar.Parent do
				l.Enabled = not l.Enabled
				task.wait(0.22 + j * 0.06)
			end
		end)
	end
	car.Parent = F.Police
	return car
end
local function makeCop(pos, stats, i)
	local c = makeNPC(Config.CopLook, CFrame.lookAt(pos + Vector3.new(0, 3, 0), Vector3.new(0, 3, 10)), "Cop" .. i, F.Police,
		Color3.fromRGB(200 + math.random(0, 40), 150 + math.random(0, 40), 110 + math.random(0, 40)))
	if not c then return nil end
	c.kind, c.stats, c.hp, c.maxHp = "cop", stats, stats.hits, stats.hits
	c.hum.WalkSpeed = stats.speed
	c.flashlight.Color = Color3.fromRGB(200, 220, 255)
	setFace(c, "alert")
	c.label.Text = "!"
	c.label.TextColor3 = Color3.fromRGB(80, 140, 255)
	return c
end
local function spawnWave(n)
	Wave.Value = n
	local stats = Config.Police.Wave(n)
	local alive = 0
	for _, c in S.cops do if c.model.Parent then alive += 1 end end
	local count = math.min(stats.count, Config.Police.MaxAlive - alive)
	if count <= 0 then return 0 end
	local spot = CAR_SPOTS[(n - 1) % #CAR_SPOTS + 1]
	policeCar(spot)
	for i = 1, count do
		S.copCount += 1
		local c = makeCop(spot + Vector3.new(-5 + i * 3, 0, -6), stats, S.copCount)
		if c then table.insert(S.cops, c) end
	end
	openFrontDoor() -- backup kicks the front door in
	feed("BACKUP! Wave " .. n .. ": " .. count .. " cops", Color3.fromRGB(110, 160, 255))
	return count
end
local function copShoot(c, e)
	local st = c.stats
	local from = c.head.Position + c.root.CFrame.LookVector * 1.2
	local aim = e.r.Position + Vector3.new(0, 0.6, 0)
	local spread = st.spread + ((e.r.AssemblyLinearVelocity.Magnitude > 12) and 2.5 or 0) + (crouch[e.p] and -1 or 0)
	local dir = (aim - from).Unit
	local cf = CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(math.rad((math.random() * 2 - 1) * spread), math.rad((math.random() * 2 - 1) * spread), 0)
	rayParams.FilterDescendantsInstances = {F.Police, F.Guards, F.Loot, F.Lasers, F.Glass, F.Props.FrontDoor}
	local res = workspace:Raycast(from, cf.LookVector * 200, rayParams)
	local hitPos = res and res.Position or (from + cf.LookVector * 200)
	oneShot(Config.Sounds.Blaster, c.head, 0.5, 0.8)
	remote:FireAllClients("Tracer", from, hitPos, "cop")
	if res then
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		local p = m and Players:GetPlayerFromCharacter(m)
		if p then damage(p, st.damage, from) end
	end
end
local function copTick(c, dt)
	if not (c.root and c.root.Parent) or c.koUntil then return end
	local now = os.clock()
	-- nearest target, prefer ones in sight
	local best, bestD, bestSeen
	for _, e in eligible() do
		local d = (e.r.Position - c.root.Position).Magnitude
		local sees = d < 120 and canSee(c.head.Position, e.c, {F.Police, F.Guards, F.Loot, F.Lasers, F.Glass, F.Props.FrontDoor})
		local score = d - (sees and 60 or 0)
		if not best or score < bestD then best, bestD, bestSeen = e, score, sees end
	end
	if not best then
		c.hum:MoveTo(c.root.Position)
		return
	end
	local d = (best.r.Position - c.root.Position).Magnitude
	if bestSeen then
		c.path = nil
		c.seenAt = c.seenAt or now
		if d > 30 then
			c.hum:MoveTo(best.r.Position)
		else
			c.hum:MoveTo(c.root.Position)
			local look = Vector3.new(best.r.Position.X, c.root.Position.Y, best.r.Position.Z)
			c.root.CFrame = c.root.CFrame:Lerp(CFrame.lookAt(c.root.Position, look), math.min(1, dt * 8))
		end
		if now - c.seenAt >= c.stats.react and now >= (c.nextShot or 0) then
			c.nextShot = now + c.stats.interval * (0.8 + math.random() * 0.4)
			copShoot(c, best)
		end
	else
		c.seenAt = nil
		-- path around walls toward the target
		if not c.computing and (not c.path or now - (c.pathAt or 0) > 1.5) then
			c.computing = true
			local goal = best.r.Position
			task.spawn(function()
				local path = PathfindingService:CreatePath({AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = false})
				local ok = pcall(function() path:ComputeAsync(c.root.Position, goal) end)
				if ok and path.Status == Enum.PathStatus.Success then
					c.path, c.wp = path:GetWaypoints(), 2
				else
					c.path = nil
				end
				c.pathAt = os.clock()
				c.computing = false
			end)
		end
		if c.path and c.path[c.wp] then
			local wp = c.path[c.wp].Position
			c.hum:MoveTo(wp)
			if flat(wp - c.root.Position).Magnitude < 3 then c.wp += 1 end
		else
			c.hum:MoveTo(best.r.Position)
		end
	end
end

---------------------------------------------------------------- the stun blaster
local function fire(p, origin, dir)
	if typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" or dir.Magnitude < 0.01 then return "bad" end
	local c, h, r = charOf(p)
	if not c or arrested[p] or downed[p] then return "cant" end
	if reloading[p] then return "reloading" end
	local now = os.clock()
	if now - (lastShot[p] or 0) < B.FireInterval then return "cooldown" end
	local ammo = p:GetAttribute("Ammo") or B.Ammo
	if ammo <= 0 then return "empty" end
	lastShot[p] = now
	p:SetAttribute("Ammo", ammo - 1)
	local head = c:FindFirstChild("Head") or r
	if (origin - head.Position).Magnitude > 8 then origin = head.Position end -- don't trust far-off origins
	rayParams.FilterDescendantsInstances = {c, F.Loot, F.Lasers, F.Cameras, F.Glass, F.Props.FrontDoor}
	local res = workspace:Raycast(origin, dir.Unit * B.Range, rayParams)
	local hitPos = res and res.Position or (origin + dir.Unit * B.Range)
	oneShot(Config.Sounds.Blaster, head, 0.7)
	remote:FireAllClients("Tracer", origin, hitPos, "player", p.UserId)
	local outcome = "miss"
	if res then
		local m = res.Instance:FindFirstAncestorOfClass("Model")
		if m and not npcByModel[m] then m = m:FindFirstAncestorOfClass("Model") end -- e.g. a hat inside the NPC
		local n = m and npcByModel[m]
		if n and n.model.Parent then
			outcome = "hit"
			if n.kind == "cop" and not n.koUntil then
				n.hp -= 1
				if n.hp <= 0 then knockOut(n, p) outcome = "ko" end
			else
				knockOut(n, p)
				outcome = "ko"
			end
			remote:FireClient(p, "HitMarker", outcome == "ko")
		end
	end
	if Phase.Value == "Heist" then noise(r.Position, B.NoiseRadius, 0.6) end
	return outcome, res and res.Instance:GetFullName() or "nothing"
end
local function reload(p)
	if reloading[p] or (p:GetAttribute("Ammo") or 0) >= B.Ammo then return false end
	reloading[p] = true
	p:SetAttribute("Reloading", true)
	local _, _, r = charOf(p)
	if r then oneShot(Config.Sounds.Reload, r, 0.6) end
	task.delay(B.ReloadTime, function()
		reloading[p] = nil
		p:SetAttribute("Reloading", false)
		p:SetAttribute("Ammo", B.Ammo)
	end)
	return true
end

---------------------------------------------------------------- cameras + lasers
local camT = 0
local function camerasTick(dt)
	camT += dt
	local C = Config.Camera
	for i, cam in F.Cameras:GetChildren() do
		local yaw = math.rad(C.SweepDegrees) * math.sin((camT / C.SweepTime) * math.pi * 2 + i * 1.7)
		cam.CFrame = cam:GetAttribute("Home") * CFrame.Angles(0, yaw, 0)
		if Power.Value and Phase.Value == "Heist" and not Alarm.Value then
			S.camSpot[cam] = S.camSpot[cam] or {}
			for _, e in eligible() do
				local to = e.r.Position - cam.Position
				local ok = to.Magnitude < C.Range
					and math.deg(math.acos(math.clamp(cam.CFrame.LookVector:Dot(to.Unit), -1, 1))) < C.Cone
					and canSee(cam.Position, e.c, {F.Cameras, F.Loot, F.Lasers, F.Glass, F.Props.FrontDoor})
				local t = ok and ((S.camSpot[cam][e.p] or 0) + dt) or 0
				S.camSpot[cam][e.p] = t
				if t >= C.SpotTime then
					triggerAlarm("A security camera saw you!")
				end
			end
		end
	end
end
local laserT = 0
local function lasersTick(dt)
	laserT += dt
	local on = Power.Value and (laserT % 3.4) < 2.0
	for _, l in F.Lasers:GetChildren() do
		l.Transparency = on and 0 or 1
	end
	if on and Phase.Value == "Heist" and not Alarm.Value then
		for _, l in F.Lasers:GetChildren() do
			for _, hpart in workspace:GetPartBoundsInBox(l.CFrame, l.Size + Vector3.new(0, 0, 0.8)) do
				local m = hpart:FindFirstAncestorOfClass("Model")
				local p = m and Players:GetPlayerFromCharacter(m)
				if p and not arrested[p] then
					triggerAlarm("You tripped a laser!")
					return
				end
			end
		end
	end
end

---------------------------------------------------------------- round control
local function endRound(won, title, sub)
	if S.over then return end
	S.over = true
	Phase.Value = "End"
	Result.Value = HttpService:JSONEncode({won = won, title = title, sub = sub or ""})
	drivePrompt.Enabled = false
	if won then
		local crew = #Players:GetPlayers()
		for _, p in Players:GetPlayers() do
			local ls = p:FindFirstChild("leaderstats")
			if ls then
				ls.Cash.Value += math.floor(Banked.Value / math.max(1, crew))
				ls.Heists.Value += 1
			end
		end
		local target = vanHome * CFrame.new(0, 0, -160)
		task.spawn(function()
			for i = 1, 60 do
				van:PivotTo(vanHome:Lerp(target, (i / 60) ^ 2))
				task.wait(1 / 30)
			end
		end)
	end
end

local function resetRound()
	for _, n in npcByModel do if n.model then n.model:Destroy() end end
	npcByModel = {}
	F.Police:ClearAllChildren()
	F.Guards:ClearAllChildren()
	S = {guards = {}, cops = {}, copCount = 0, camSpot = {}, frontOpen = false, vaultOpen = false, wrongCodes = 0, over = false,
		code = string.format("%d%d%d%d", math.random(1, 9), math.random(1, 9), math.random(1, 9), math.random(1, 9))}
	siren:Stop()
	bell:Stop()
	Alarm.Value = false
	setAlarmLights(false)
	setPower(true)
	Banked.Value, PoliceLeft.Value, Wave.Value, Result.Value = 0, 0, 0, ""
	for _, item in F.Loot:GetChildren() do
		setItemTaken(item, false)
		item.CFrame = item:GetAttribute("Home")
	end
	for _, g in F.Props:GetChildren() do
		if g.Name == "CaseGlass" then g.Transparency = 0.75 end
	end
	local d = F.Props.FrontDoor
	d.CFrame, d.CanCollide = d:GetAttribute("Home"), true
	d.Prompt.Enabled = true
	local vd, vw = F.Props.VaultDoor, F.Props.VaultWheel
	vd.CFrame, vd.CanCollide = vd:GetAttribute("Home"), true
	vw.CFrame = vw:GetAttribute("Home")
	F.Props.Keypad.Status.Color = Color3.fromRGB(255, 60, 60)
	F.Props.Keypad.Prompt.Enabled = true
	van:PivotTo(vanHome)
	drivePrompt.Enabled = false
	bags, crouch, sprint, downed, reloading = {}, {}, {}, {}, {}
	for p in arrested do arrested[p] = false end
	for _, p in Players:GetPlayers() do
		p:SetAttribute("HP", PC.MaxHealth)
		p:SetAttribute("Ammo", B.Ammo)
		p:SetAttribute("Reloading", false)
		local _, h = charOf(p)
		if h then h.PlatformStand = false end
		updatePlayer(p)
		local c = p.Character
		if c then c:PivotTo(spawnPart.CFrame + Vector3.new(math.random(-3, 3), 4, math.random(-3, 3))) end
	end
	local i = 0
	for _, routeFolder in F.Routes:GetChildren() do
		i += 1
		local g = makeGuard(routeFolder, i)
		if g then table.insert(S.guards, g) end
	end
end

local function objectiveText()
	if Banked.Value >= Quota.Value then return "You have enough! Get to the van and DRIVE AWAY!" end
	if Alarm.Value then return "ALARM! Fight your way out. Stash loot in the van. Goal: $" .. Quota.Value end
	if not S.frontOpen and not S.vaultOpen and Banked.Value == 0 then
		return "Sneak into Glimmer & Co. (front lock or back alley). Goal: $" .. Quota.Value
	end
	if not S.vaultOpen then return "Find the vault code in the back office. Stash loot in the van. Goal: $" .. Quota.Value end
	return "Vault open! Grab the diamond and stash it. Goal: $" .. Quota.Value
end

---------------------------------------------------------------- wiring
for _, item in F.Loot:GetChildren() do
	item.Prompt.Triggered:Connect(function(p) grab(p, item) end)
end
F.Props.FrontDoor.Prompt.Triggered:Connect(function() if Phase.Value == "Heist" then openFrontDoor() end end)
F.Props.Note.Prompt.Triggered:Connect(function(p)
	if Phase.Value == "Heist" then remote:FireClient(p, "Note", S.code) end
end)
F.Props.Keypad.Prompt.Triggered:Connect(function(p)
	if Phase.Value == "Heist" and not S.vaultOpen then remote:FireClient(p, "Keypad") end
end)
F.Props.PowerBox.Prompt.Triggered:Connect(function(p) cutPower(p) end)
F.Props.CageLock.Prompt.Triggered:Connect(function(p) freeCrew(p) end)
drivePrompt.Triggered:Connect(function(p)
	if Phase.Value == "Heist" and Banked.Value >= Quota.Value and not arrested[p] then
		endRound(true, "YOU ESCAPED!", "Your crew got away with $" .. Banked.Value)
	end
end)
remote.OnServerEvent:Connect(function(p, kind, a, b)
	if kind == "Crouch" then
		crouch[p] = a == true and not arrested[p]
		updatePlayer(p)
	elseif kind == "Sprint" then
		sprint[p] = a == true
		updatePlayer(p)
	elseif kind == "Fire" then
		fire(p, a, b)
	elseif kind == "Reload" then
		reload(p)
	elseif kind == "Code" and typeof(a) == "string" and #a <= 6 then
		local res = tryCode(p, a)
		remote:FireClient(p, "CodeResult", res)
	end
end)
local function equipBlaster(p, c)
	local hum = c:WaitForChild("Humanoid", 5)
	local bp = p:WaitForChild("Backpack", 5)
	local tool = bp and bp:WaitForChild("StunBlaster", 5)
	if hum and tool then hum:EquipTool(tool) end
end
local function onPlayer(p)
	if p:FindFirstChild("leaderstats") then return end
	p.CameraMode = Enum.CameraMode.LockFirstPerson
	p:SetAttribute("HP", PC.MaxHealth)
	p:SetAttribute("Ammo", B.Ammo)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, n in {"Cash", "Heists"} do
		local v = Instance.new("IntValue")
		v.Name = n
		v.Parent = ls
	end
	ls.Parent = p
	local function onChar(c)
		task.wait()
		if arrested[p] then c:PivotTo(jailSpot.CFrame + Vector3.new(0, 3, 0)) end
		updatePlayer(p)
		task.spawn(equipBlaster, p, c)
	end
	p.CharacterAdded:Connect(onChar)
	if p.Character then task.spawn(onChar, p.Character) end
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do onPlayer(p) end
Players.PlayerRemoving:Connect(function(p)
	bags[p], crouch[p], sprint[p], arrested[p], downed[p] = nil, nil, nil, nil, nil
end)

-- test hooks (ServerStorage.HeistTest) so playtests can drive the real code paths
local test = ServerStorage:FindFirstChild("HeistTest") or Instance.new("BindableFunction")
test.Name = "HeistTest"
test.Parent = ServerStorage
test.OnInvoke = function(cmd, a, b)
	local p = Players:GetPlayers()[1]
	if cmd == "state" then
		local ns = {}
		for _, list in {S.guards, S.cops} do
			for _, n in list do
				table.insert(ns, {name = n.model.Name, state = n.state or "cop", susp = math.floor((n.susp or 0) * 100) / 100,
					ko = n.koUntil ~= nil, hp = n.hp, lying = n.root and n.root.Anchored or false,
					pos = n.root and tostring(Vector3.new(math.floor(n.root.Position.X), math.floor(n.root.Position.Y), math.floor(n.root.Position.Z)))})
			end
		end
		local bg = p and bags[p]
		return HttpService:JSONEncode({phase = Phase.Value, objective = Objective.Value, banked = Banked.Value,
			alarm = Alarm.Value, reason = S.alarmReason, police = PoliceLeft.Value, wave = Wave.Value, timeLeft = TimeLeft.Value,
			power = Power.Value, vault = S.vaultOpen, front = S.frontOpen, code = S.code, wrong = S.wrongCodes,
			bag = bg and {bg.slots, bg.value} or {0, 0}, arrested = p and arrested[p] or false, downed = p and downed[p] or false,
			hp = p and p:GetAttribute("HP"), ammo = p and p:GetAttribute("Ammo"), reloading = p and p:GetAttribute("Reloading"),
			result = Result.Value, npcs = ns, drive = drivePrompt.Enabled})
	elseif cmd == "grab" then return tostring(grab(p, F.Loot[a]))
	elseif cmd == "code" then return tryCode(p, a)
	elseif cmd == "power" then return tostring(cutPower(p))
	elseif cmd == "lock" then return tostring(openFrontDoor())
	elseif cmd == "drive" then
		if Banked.Value >= Quota.Value then endRound(true, "YOU ESCAPED!", "Your crew got away with $" .. Banked.Value) end
		return Phase.Value
	elseif cmd == "wave" then return tostring(spawnWave(Wave.Value + 1))
	elseif cmd == "hp" then p:SetAttribute("HP", a) return "ok"
	elseif cmd == "skipLobby" then S.skipLobby = true return "ok"
	elseif cmd == "free" then return tostring(freeCrew(p))
	elseif cmd == "alarm" then return tostring(triggerAlarm(a or "Test alarm"))
	elseif cmd == "fireAt" then
		-- aim from the player's head at a named NPC and fire through the same function the remote uses
		local n
		for m, x in npcByModel do if m.Name == a then n = x end end
		local c = p.Character
		if not (n and c) then return "no target" end
		local o = c.Head.Position
		local out, what = fire(p, o, (n.root.Position + Vector3.new(0, 1, 0) - o))
		return out .. " -> " .. tostring(what)
	elseif cmd == "fireDir" then
		local c = p.Character
		return fire(p, c.Head.Position, a)
	end
	return "unknown"
end

---------------------------------------------------------------- main loop
RunService.Heartbeat:Connect(function(dt)
	if not S then return end
	camerasTick(dt)
	lasersTick(dt)
	local now = os.clock()
	for _, n in npcByModel do
		if n.koUntil then
			n.stars.Rotation = (n.stars.Rotation + dt * 240) % 360
			if now >= n.koUntil then wakeUp(n) end
		end
	end
	if Phase.Value == "Heist" and not S.over then
		for _, g in S.guards do guardTick(g, dt) end
		for _, c in S.cops do copTick(c, dt) end
		for _, p in Players:GetPlayers() do
			local hp = p:GetAttribute("HP") or PC.MaxHealth
			if hp < PC.MaxHealth and not downed[p] and not arrested[p] and now - (lastHit[p] or 0) > PC.RegenDelay then
				p:SetAttribute("HP", math.min(PC.MaxHealth, hp + PC.RegenRate * dt))
			end
		end
	end
end)

while true do
	resetRound()
	Phase.Value = "Lobby"
	repeat task.wait(0.5) until #Players:GetPlayers() > 0
	for s = L.LobbyTime, 1, -1 do
		if S.skipLobby then break end
		Objective.Value = "Heist starts in " .. s .. "...  Plan your way in!"
		task.wait(1)
	end
	Phase.Value = "Heist"
	TimeLeft.Value = L.TimeLimit
	toast(nil, "LEVEL " .. LEVEL .. ": " .. L.Name, Color3.fromRGB(255, 220, 120))
	local last = os.clock()
	while not S.over do
		task.wait(0.2)
		local now = os.clock()
		local dt = now - last
		last = now
		stashAll()
		Objective.Value = objectiveText()
		TimeLeft.Value = math.max(0, TimeLeft.Value - dt)
		if Alarm.Value and S.nextWave then
			if now >= S.nextWave then
				spawnWave(Wave.Value + 1)
				S.nextWave = now + Config.Police.WaveEvery
			end
			PoliceLeft.Value = math.max(0, S.nextWave - now)
		end
		if TimeLeft.Value <= 0 then
			endRound(false, "THE SUN CAME UP", "You ran out of night. Banked: $" .. Banked.Value)
		end
		local free = 0
		for _, p in Players:GetPlayers() do if not arrested[p] then free += 1 end end
		if free == 0 and #Players:GetPlayers() > 0 then
			endRound(false, "BUSTED!", "The whole crew is in the police cage.")
		end
	end
	siren:Stop()
	bell:Stop()
	for s = 8, 1, -1 do
		Objective.Value = "Next heist in " .. s .. "..."
		task.wait(1)
	end
end
