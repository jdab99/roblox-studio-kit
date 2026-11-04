-- Heist HUD + controls (StarterPlayerScripts.HeistClient):
-- first-person blaster viewmodel, crosshair, ammo, health, hit feedback, kill feed, sneak/sprint, note, keypad.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Config = require(RS:WaitForChild("HeistConfig"))
local H = RS:WaitForChild("Heist")
local remote = RS:WaitForChild("HeistRemote")
local B = Config.Blaster

local FONT = Enum.Font.FredokaOne
local DARK = Color3.fromRGB(20, 18, 28)
local CYAN = Color3.fromRGB(60, 230, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "HeistHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")
-- the blaster is always in hand (server equips it), so hide Roblox's item bar: it sat on top of the sneak/sprint label
pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.4
	for k, v in props do l[k] = v end
	l.Parent = parent
	return l
end
local function panel(parent, props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = DARK
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	for k, v in props do f[k] = v end
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	f.Parent = parent
	return f
end
local function bar(parent, props) -- plain rectangle (no rounded corners)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for k, v in props do f[k] = v end
	f.Parent = parent
	return f
end

-- red hurt flash (under everything)
local hurtFlash = bar(gui, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 0, 0), BackgroundTransparency = 1, ZIndex = 0})

-- objective bar (top center)
local objBar = panel(gui, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0.56, 0, 0, 46)})
local objText = label(objBar, {Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5)})

-- loot panel (bottom right)
local lootP = panel(gui, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -18), Size = UDim2.fromOffset(250, 104)})
local teamText = label(lootP, {Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 8), TextXAlignment = Enum.TextXAlignment.Left})
local bagText = label(lootP, {Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 42), TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(255, 220, 120)})
local barBack = panel(lootP, {Position = UDim2.fromOffset(10, 76), Size = UDim2.new(1, -20, 0, 14), BackgroundColor3 = Color3.fromRGB(60, 60, 70), BackgroundTransparency = 0})
local barFill = panel(barBack, {Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(90, 230, 120), BackgroundTransparency = 0})
local codeText = label(gui, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -196), Size = UDim2.fromOffset(250, 26),
	TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 245, 160), Text = ""})

-- ammo (above the loot panel)
local ammoP = panel(gui, {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -130), Size = UDim2.fromOffset(250, 60)})
local ammoText = label(ammoP, {Size = UDim2.new(0.55, 0, 1, -12), Position = UDim2.fromOffset(12, 6), TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = CYAN})
local ammoHint = label(ammoP, {Size = UDim2.new(0.45, -14, 0, 22), Position = UDim2.new(0.55, 0, 0.5, -11), TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = Color3.fromRGB(200, 200, 210), Text = "R reload"})

-- health (bottom left)
local hpP = panel(gui, {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -18), Size = UDim2.fromOffset(300, 52)})
local hpBack = bar(hpP, {Position = UDim2.fromOffset(60, 14), Size = UDim2.new(1, -74, 0, 24), BackgroundColor3 = Color3.fromRGB(70, 20, 25)})
local hpFill = bar(hpBack, {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(90, 230, 120)})
local hpNum = label(hpBack, {Size = UDim2.fromScale(1, 1), Text = "100", ZIndex = 3})
label(hpP, {Size = UDim2.fromOffset(44, 24), Position = UDim2.fromOffset(10, 14), Text = "HP"})

-- alarm banner
local alarmBar = panel(gui, {AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.new(0.42, 0, 0, 52),
	BackgroundColor3 = Color3.fromRGB(200, 20, 30), BackgroundTransparency = 0.05, Visible = false})
local alarmText = label(alarmBar, {Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5)})

-- sneak button (bottom center, also for touch)
local sneakBtn = Instance.new("TextButton")
sneakBtn.AnchorPoint = Vector2.new(0.5, 1)
sneakBtn.Position = UDim2.new(0.5, 0, 1, -18)
sneakBtn.Size = UDim2.fromOffset(300, 42)
sneakBtn.BackgroundColor3 = DARK
sneakBtn.BackgroundTransparency = 0.2
sneakBtn.Font = FONT
sneakBtn.TextScaled = true
sneakBtn.TextColor3 = Color3.new(1, 1, 1)
sneakBtn.Text = "C SNEAK   SHIFT SPRINT"
sneakBtn.Selectable = false
Instance.new("UICorner", sneakBtn).CornerRadius = UDim.new(0, 12)
sneakBtn.Parent = gui

-- crosshair + hit marker
local cross = Instance.new("Frame")
cross.AnchorPoint = Vector2.new(0.5, 0.5)
cross.Position = UDim2.fromScale(0.5, 0.5)
cross.Size = UDim2.fromOffset(40, 40)
cross.BackgroundTransparency = 1
cross.Parent = gui
for _, s in {{0.5, 0.12, 2, 9}, {0.5, 0.88, 2, 9}, {0.12, 0.5, 9, 2}, {0.88, 0.5, 9, 2}} do
	local l = bar(cross, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s[1], s[2]), Size = UDim2.fromOffset(s[3], s[4]),
		BackgroundColor3 = Color3.new(1, 1, 1)})
	local st = Instance.new("UIStroke", l)
	st.Thickness = 1
	st.Transparency = 0.4
end
bar(cross, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(3, 3), BackgroundColor3 = CYAN})
local hitMark = Instance.new("Frame")
hitMark.AnchorPoint = Vector2.new(0.5, 0.5)
hitMark.Position = UDim2.fromScale(0.5, 0.5)
hitMark.Size = UDim2.fromOffset(44, 44)
hitMark.BackgroundTransparency = 1
hitMark.Visible = false
hitMark.Parent = gui
for _, r in {45, -45} do
	local l = bar(hitMark, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(46, 4),
		BackgroundColor3 = Color3.new(1, 1, 1), Rotation = r})
	l.Name = "Line"
end

-- toast stack (middle) + kill feed (right, under the player list)
local function stack(props, align)
	local f = Instance.new("Frame")
	f.BackgroundTransparency = 1
	for k, v in props do f[k] = v end
	f.Parent = gui
	local l = Instance.new("UIListLayout")
	l.HorizontalAlignment = align
	l.Padding = UDim.new(0, 6)
	l.Parent = f
	return f
end
local toastHolder = stack({AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.62, 0), Size = UDim2.new(0.5, 0, 0.22, 0)},
	Enum.HorizontalAlignment.Center)
local feedHolder = stack({AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 130), Size = UDim2.fromOffset(330, 260)},
	Enum.HorizontalAlignment.Right)

-- big result / level title / knocked-down text
local bigTitle = label(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.new(0.7, 0, 0, 110),
	Text = "", TextStrokeTransparency = 0, Visible = false})
local bigSub = label(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.46), Size = UDim2.new(0.6, 0, 0, 40),
	Text = "", Visible = false})

local function money(n)
	local s = tostring(math.floor(n))
	return "$" .. s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end
local function fmtTime(s)
	s = math.max(0, math.ceil(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function refresh()
	objText.Text = H.Objective.Value
	teamText.Text = "CREW: " .. money(H.Banked.Value) .. " / " .. money(H.Quota.Value)
	barFill.Size = UDim2.fromScale(math.clamp(H.Banked.Value / math.max(1, H.Quota.Value), 0, 1), 1)
	local slots = player:GetAttribute("BagSlots") or 0
	bagText.Text = "BAG: " .. slots .. "/" .. Config.BagSlots .. "   " .. money(player:GetAttribute("BagValue") or 0)
	local sneaking, sprinting = player:GetAttribute("Sneaking"), player:GetAttribute("Sprinting")
	sneakBtn.Text = sneaking and "SNEAKING..." or sprinting and "SPRINTING!" or "C SNEAK   SHIFT SPRINT"
	sneakBtn.BackgroundColor3 = sneaking and Color3.fromRGB(60, 40, 110) or sprinting and Color3.fromRGB(150, 80, 20) or DARK
	alarmBar.Visible = H.Alarm.Value and H.Phase.Value == "Heist"
	alarmText.Text = (H.Wave.Value > 0 and ("ALARM!  WAVE " .. H.Wave.Value .. "   NEXT BACKUP " .. fmtTime(H.PoliceLeft.Value)))
		or ("ALARM!  POLICE BACKUP IN " .. fmtTime(H.PoliceLeft.Value))
	local ammo = player:GetAttribute("Ammo") or B.Ammo
	ammoText.Text = "⚡ " .. ammo .. " / " .. B.Ammo
	ammoText.TextColor3 = ammo == 0 and Color3.fromRGB(255, 80, 80) or CYAN
	ammoHint.Text = player:GetAttribute("Reloading") and "RELOADING..." or (ammo == 0 and "PRESS R!" or "R reload")
	local hp = player:GetAttribute("HP") or 100
	hpFill.Size = UDim2.fromScale(math.clamp(hp / Config.Player.MaxHealth, 0, 1), 1)
	hpFill.BackgroundColor3 = hp > 60 and Color3.fromRGB(90, 230, 120) or hp > 30 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(255, 70, 60)
	hpNum.Text = tostring(math.ceil(hp))
	if player:GetAttribute("Arrested") then
		objText.Text = "CAUGHT! Wait in the cage for a teammate to free you."
	end
	if H.Phase.Value == "End" and H.Result.Value ~= "" then
		local ok, r = pcall(function() return HttpService:JSONDecode(H.Result.Value) end)
		if ok then
			bigTitle.Text = r.title
			bigTitle.TextColor3 = r.won and Color3.fromRGB(120, 255, 150) or Color3.fromRGB(255, 80, 80)
			bigSub.Text = r.sub
			bigTitle.Visible, bigSub.Visible = true, true
		end
	elseif H.Phase.Value ~= "End" and bigTitle.Text ~= "" and not bigTitle:GetAttribute("Intro") and not bigTitle:GetAttribute("Down") then
		bigTitle.Visible, bigSub.Visible = false, false
		bigTitle.Text = ""
	end
	if H.Phase.Value == "Lobby" then codeText.Text = "" end
end
for _, v in H:GetChildren() do v.Changed:Connect(refresh) end
player.AttributeChanged:Connect(refresh)
refresh()

task.spawn(function()
	while true do
		task.wait(0.45)
		if alarmBar.Visible then
			alarmBar.BackgroundTransparency = alarmBar.BackgroundTransparency < 0.3 and 0.45 or 0.05
		end
	end
end)

local function showToast(text, color)
	local f = panel(toastHolder, {Size = UDim2.new(1, 0, 0, 38)})
	label(f, {Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = text, TextColor3 = color or Color3.new(1, 1, 1)})
	task.delay(3, function()
		TweenService:Create(f, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
		task.wait(0.4)
		f:Destroy()
	end)
end
local function showFeed(text, color)
	local f = panel(feedHolder, {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 0.35})
	label(f, {Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Text = text, TextColor3 = color or Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Right})
	task.delay(4.5, function() f:Destroy() end)
end

---------------------------------------------------------------- controls
local function setSneak(on) remote:FireServer("Crouch", on) end
sneakBtn.Activated:Connect(function() setSneak(not player:GetAttribute("Sneaking")) end)
UIS.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.C or input.KeyCode == Enum.KeyCode.LeftControl then
		setSneak(not player:GetAttribute("Sneaking"))
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		remote:FireServer("Sprint", true)
	elseif input.KeyCode == Enum.KeyCode.R then
		remote:FireServer("Reload")
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift then remote:FireServer("Sprint", false) end
end)

local keypad -- the open keypad frame (declared early: the render step checks it)

---------------------------------------------------------------- first-person viewmodel
local cam = workspace.CurrentCamera
local vm = Instance.new("Model")
vm.Name = "HeistViewmodel"
local vmParts = {}
local K = 0.6 -- viewmodel scale: smaller parts closer in = a smaller blaster on screen
local function scaled(cf) return CFrame.new(cf.Position * K) * cf.Rotation end
local function vp(size, offset, color, mat, shape)
	offset = scaled(offset)
	local p = Instance.new("Part")
	p.Size = size * K
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	if shape then p.Shape = shape end
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = vm
	table.insert(vmParts, {p, offset})
	return p
end
local SLEEVE, SKIN = Color3.fromRGB(35, 35, 45), Color3.fromRGB(255, 205, 150)
vp(Vector3.new(0.8, 0.8, 2.4), CFrame.new(0.55, -0.55, 0.55) * CFrame.Angles(math.rad(-6), math.rad(4), 0), SLEEVE)            -- right sleeve
vp(Vector3.new(0.7, 0.7, 0.6), CFrame.new(0.4, -0.35, -0.75), SKIN)                                                            -- right hand
vp(Vector3.new(0.75, 0.75, 2.4), CFrame.new(-0.75, -0.7, -0.2) * CFrame.Angles(math.rad(-4), math.rad(-28), 0), SLEEVE)        -- left sleeve
vp(Vector3.new(0.65, 0.65, 0.6), CFrame.new(-0.05, -0.35, -1.45), SKIN)                                                         -- left hand
vp(Vector3.new(0.5, 0.75, 1.9), CFrame.new(0.35, 0.05, -1.15), Color3.fromRGB(45, 48, 60))                                      -- blaster body
vp(Vector3.new(1.1, 0.34, 0.34), CFrame.new(0.35, 0.18, -2.4) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(28, 28, 34),
	Enum.Material.Metal, Enum.PartType.Cylinder)                                                                                  -- barrel
local glow = vp(Vector3.new(0.52, 0.12, 1.3), CFrame.new(0.35, 0.45, -1.1), CYAN, Enum.Material.Neon)                           -- energy strip
vp(Vector3.new(0.42, 0.8, 0.45), CFrame.new(0.35, -0.45, -0.55) * CFrame.Angles(math.rad(-14), 0, 0), Color3.fromRGB(255, 120, 0)) -- grip
local MUZZLE = scaled(CFrame.new(0.35, 0.18, -3.0))
local flash = vp(Vector3.new(0.7, 0.7, 0.7), CFrame.new(0.35, 0.18, -3.0), Color3.fromRGB(150, 245, 255), Enum.Material.Neon, Enum.PartType.Ball)
flash.Transparency = 1
local flashLight = Instance.new("PointLight")
flashLight.Color, flashLight.Range, flashLight.Brightness, flashLight.Enabled = CYAN, 14, 6, false
flashLight.Parent = flash
vm.Parent = cam

local recoil, shake, bobT, flashUntil = 0, 0, 0, 0
local lastFire = 0
local function equipped()
	local c = player.Character
	return c and c:FindFirstChild("StunBlaster")
end
local function firstPerson()
	local c = player.Character
	local head = c and c:FindFirstChild("Head")
	return head and (cam.CFrame.Position - head.Position).Magnitude < 2
end
local function vmBase()
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	local speed = r and Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude or 0
	local k = math.min(speed / 16, 1.5)
	local bob = CFrame.new(math.sin(bobT) * 0.05 * k, -math.abs(math.cos(bobT)) * 0.06 * k, 0)
	return cam.CFrame * CFrame.new(0.82, -0.82, -1.1) * bob * CFrame.new(0, 0, recoil * 0.3) * CFrame.Angles(recoil * 0.22, 0, 0)
end

RunService:BindToRenderStep("HeistViewmodel", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local c = player.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if r then
		local speed = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z).Magnitude
		bobT += dt * speed * 0.55
	end
	recoil = recoil * math.max(0, 1 - dt * 14)
	shake = shake * math.max(0, 1 - dt * 7)
	-- camera kick + shake (visual offset on top of the camera module each frame)
	if recoil > 0.001 or shake > 0.001 then
		cam.CFrame = cam.CFrame * CFrame.Angles(recoil * 0.035 + (math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
	end
	local show = equipped() and firstPerson() and not player:GetAttribute("Arrested")
	local base = vmBase()
	for _, e in vmParts do
		e[1].CFrame = base * e[2]
		e[1].LocalTransparencyModifier = show and 0 or 1
	end
	flash.Transparency = (show and os.clock() < flashUntil) and 0.1 or 1
	flashLight.Enabled = show and os.clock() < flashUntil
	glow.Color = (player:GetAttribute("Ammo") or 1) == 0 and Color3.fromRGB(255, 70, 70) or CYAN
	-- hide the third-person blaster in our own hands
	local tool = equipped()
	if tool then
		for _, p in tool:GetDescendants() do
			if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
		end
	end
	cross.Visible = show and true or false
	-- hide the mouse arrow over the crosshair (show it again while the keypad needs clicks)
	UIS.MouseIconEnabled = not show or keypad ~= nil
end)

local function tracer(a, b, color, width)
	local d = (b - a).Magnitude
	if d < 0.5 then return end
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Size = Vector3.new(width or 0.12, width or 0.12, d)
	p.CFrame = CFrame.lookAt(a, b) * CFrame.new(0, 0, -d / 2)
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.14), {Transparency = 1, Size = Vector3.new(0.02, 0.02, d)}):Play()
	Debris:AddItem(p, 0.2)
	local spark = Instance.new("Part")
	spark.Anchored, spark.CanCollide, spark.CanQuery, spark.CanTouch = true, false, false, false
	spark.Shape = Enum.PartType.Ball
	spark.Material = Enum.Material.Neon
	spark.Color = color
	spark.Size = Vector3.new(0.6, 0.6, 0.6)
	spark.Position = b
	spark.Parent = workspace
	TweenService:Create(spark, TweenInfo.new(0.2), {Transparency = 1, Size = Vector3.new(1.4, 1.4, 1.4)}):Play()
	Debris:AddItem(spark, 0.25)
end

local function tryFire()
	if not equipped() or player:GetAttribute("Arrested") or player:GetAttribute("Reloading") then return end
	if os.clock() - lastFire < B.FireInterval then return end
	local ammo = player:GetAttribute("Ammo") or 0
	if ammo <= 0 then
		remote:FireServer("Reload")
		return
	end
	lastFire = os.clock()
	local origin = cam.CFrame.Position
	local dir = cam.CFrame.LookVector
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character, vm}
	local res = workspace:Raycast(origin, dir * B.Range, params)
	local hitPos = res and res.Position or origin + dir * B.Range
	tracer((vmBase() * MUZZLE).Position, hitPos, CYAN, 0.14)
	recoil = 1
	flashUntil = os.clock() + 0.05
	remote:FireServer("Fire", origin, dir)
end
local function hookTool(c)
	local tool = c:WaitForChild("StunBlaster", 8) or player.Backpack:FindFirstChild("StunBlaster")
	if tool then tool.Activated:Connect(tryFire) end
end
player.CharacterAdded:Connect(hookTool)
if player.Character then task.spawn(hookTool, player.Character) end

---------------------------------------------------------------- note + keypad
local function showNote(code)
	local f = panel(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(340, 240),
		BackgroundColor3 = Color3.fromRGB(255, 240, 140), BackgroundTransparency = 0})
	f.Rotation = -3
	label(f, {Size = UDim2.new(1, -30, 0, 50), Position = UDim2.fromOffset(15, 18), Text = "don't forget!!", TextColor3 = Color3.fromRGB(60, 50, 40),
		TextStrokeTransparency = 1, Font = Enum.Font.PermanentMarker})
	label(f, {Size = UDim2.new(1, -30, 0, 34), Position = UDim2.fromOffset(15, 76), Text = "VAULT CODE:", TextColor3 = Color3.fromRGB(60, 50, 40),
		TextStrokeTransparency = 1, Font = Enum.Font.PermanentMarker})
	label(f, {Size = UDim2.new(1, -30, 0, 80), Position = UDim2.fromOffset(15, 116), Text = code:gsub(".", "%0 "), TextColor3 = Color3.fromRGB(200, 30, 40),
		TextStrokeTransparency = 1, Font = Enum.Font.PermanentMarker})
	codeText.Text = "Vault code: " .. code
	task.delay(5, function() f:Destroy() end)
end

local function openKeypad()
	if keypad then return end
	local entry = ""
	keypad = panel(gui, {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(300, 420),
		BackgroundColor3 = Color3.fromRGB(30, 32, 40), BackgroundTransparency = 0, ZIndex = 5})
	local screen = panel(keypad, {Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 60), BackgroundColor3 = Color3.fromRGB(10, 40, 20), BackgroundTransparency = 0})
	local disp = label(screen, {Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), Text = "- - - -", TextColor3 = Color3.fromRGB(90, 255, 120),
		Font = Enum.Font.Code})
	local function show() disp.Text = entry == "" and "- - - -" or entry:gsub(".", "%0 ") end
	local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "X", "0", "OK"}
	for i, k in keys do
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(78, 64)
		b.Position = UDim2.fromOffset(20 + ((i - 1) % 3) * 88, 96 + ((i - 1) // 3) * 74)
		b.BackgroundColor3 = k == "OK" and Color3.fromRGB(40, 160, 70) or k == "X" and Color3.fromRGB(170, 50, 50) or Color3.fromRGB(70, 74, 88)
		b.Font = FONT
		b.TextScaled = true
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = k
		b.Modal = i == 1 -- frees the mouse from first-person lock while the keypad is open
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
		b.Parent = keypad
		b.Activated:Connect(function()
			if k == "X" then
				keypad:Destroy()
				keypad = nil
			elseif k == "OK" then
				if #entry == 4 then remote:FireServer("Code", entry) end
			elseif #entry < 4 then
				entry ..= k
				show()
			end
		end)
	end
	keypad.AttributeChanged:Connect(function()
		entry = ""
		show()
	end)
end
---------------------------------------------------------------- server events
local hitSound = Instance.new("Sound")
hitSound.SoundId = Config.Sounds.HitMarker
hitSound.Volume = 0.7
hitSound.Parent = gui
remote.OnClientEvent:Connect(function(kind, a, b, c, d)
	if kind == "Toast" then
		showToast(a, b)
	elseif kind == "Feed" then
		showFeed(a, b)
	elseif kind == "Note" then
		showNote(a)
	elseif kind == "Keypad" then
		openKeypad()
	elseif kind == "CodeResult" and keypad then
		if a == "open" then
			keypad:Destroy()
			keypad = nil
		else
			keypad:SetAttribute("Reset", not keypad:GetAttribute("Reset"))
		end
	elseif kind == "Tracer" then
		if c == "player" and d == player.UserId then return end -- we already drew our own
		tracer(a, b, c == "cop" and Color3.fromRGB(255, 70, 90) or CYAN, c == "cop" and 0.16 or 0.12)
	elseif kind == "HitMarker" then
		hitMark.Visible = true
		for _, l in hitMark:GetChildren() do l.BackgroundColor3 = a and Color3.fromRGB(255, 60, 60) or Color3.new(1, 1, 1) end
		hitSound:Play()
		task.delay(0.18, function() hitMark.Visible = false end)
	elseif kind == "Hurt" then
		shake = math.min(0.09, shake + 0.04)
		hurtFlash.BackgroundTransparency = 0.55
		TweenService:Create(hurtFlash, TweenInfo.new(0.35), {BackgroundTransparency = 1}):Play()
	elseif kind == "Downed" then
		shake = 0.12
		bigTitle.Text = "KNOCKED DOWN!"
		bigTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
		bigSub.Text = "The police are dragging you to the cage..."
		bigTitle:SetAttribute("Down", true)
		bigTitle.Visible, bigSub.Visible = true, true
		task.delay(Config.Player.DownTime + 1.5, function()
			bigTitle:SetAttribute("Down", nil)
			if H.Phase.Value ~= "End" then bigTitle.Visible, bigSub.Visible = false, false end
		end)
	end
end)

-- level intro title when a heist starts
H.Phase.Changed:Connect(function(ph)
	if ph == "Heist" then
		bigTitle.Text = string.upper(H.LevelName.Value)
		bigTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
		bigSub.Text = "Steal " .. money(H.Quota.Value) .. ". Sneak, or blast your way out."
		bigTitle:SetAttribute("Intro", true)
		bigTitle.Visible, bigSub.Visible = true, true
		task.delay(3.5, function()
			bigTitle:SetAttribute("Intro", nil)
			if H.Phase.Value == "Heist" then bigTitle.Visible, bigSub.Visible = false, false end
		end)
	elseif ph == "Lobby" then
		codeText.Text = ""
	end
end)
