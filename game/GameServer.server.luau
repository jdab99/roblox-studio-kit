-- Scramble Floor round loop (ServerScriptService)
-- The floor is a scrambled cube face. A color is called; every other color drops. Last one standing wins.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local root = workspace:WaitForChild("ScrambleFloor")
local tiles = root:WaitForChild("Tiles"):GetChildren()
local spawnPart = root:WaitForChild("LobbySpawn")
local void = root:WaitForChild("Void")

local colors = {}
for _, v in RS:WaitForChild("CubeColors"):GetChildren() do
	colors[v:GetAttribute("Order")] = {name = v.Name, color = v.Value}
end

-- what the client UI shows
local function value(class, name)
	local v = RS:FindFirstChild(name) or Instance.new(class)
	v.Name = name
	v.Parent = RS
	return v
end
local Status = value("StringValue", "Status")
local Called = value("StringValue", "CalledColor")
local Timer = value("NumberValue", "Timer")

-- leaderboard
Players.PlayerAdded:Connect(function(p)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Parent = ls
	local best = Instance.new("IntValue")
	best.Name = "Best Round"
	best.Parent = ls
	ls.Parent = p
end)

local alive = {}
local function knockOut(char)
	local p = Players:GetPlayerFromCharacter(char)
	if p and alive[p] then
		alive[p] = nil
		local h = char:FindFirstChildOfClass("Humanoid")
		if h then h.Health = 0 end
	end
end
void.Touched:Connect(function(hit)
	local char = hit:FindFirstAncestorOfClass("Model")
	if char then knockOut(char) end
	-- anyone touching the void dies, in a round or not
	local h = char and char:FindFirstChildOfClass("Humanoid")
	if h then h.Health = 0 end
end)

local function scramble()
	for _, t in tiles do
		t.Color = colors[math.random(1, 6)].color
		t.Transparency = 0
		t.CanCollide = true
		t.Position = t:GetAttribute("Home")
	end
end

local function countAlive()
	local n = 0
	for p in alive do
		if p.Parent and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
			n += 1
		else
			alive[p] = nil
		end
	end
	return n
end

local function wait_(seconds, label)
	for s = seconds, 1, -1 do
		Timer.Value = s
		if label then Status.Value = label .. " " .. s end
		task.wait(1)
	end
	Timer.Value = 0
end

while true do
	Called.Value = ""
	scramble()
	repeat
		Status.Value = "Waiting for players..."
		task.wait(1)
	until #Players:GetPlayers() > 0
	wait_(8, "Next game in")

	-- drop everyone onto the cube
	alive = {}
	local started = #Players:GetPlayers()
	for _, p in Players:GetPlayers() do
		local char = p.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local t = tiles[math.random(1, #tiles)]
			char:PivotTo(CFrame.new(t.Position + Vector3.new(0, 4, 0)))
			alive[p] = true
		end
	end

	local round = 0
	while true do
		round += 1
		local pick = colors[math.random(1, 6)]
		local think = math.max(1.6, 5 - (round - 1) * 0.35)
		Called.Value = pick.name
		Status.Value = "Round " .. round .. ": get on " .. pick.name .. "!"
		task.wait(think)
		-- everything that is not the called color falls away
		for _, t in tiles do
			if t.Color ~= pick.color then
				t.CanCollide = false
				TweenService:Create(t, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{Position = t:GetAttribute("Home") - Vector3.new(0, 40, 0), Transparency = 1}):Play()
			end
		end
		task.wait(2.2)
		for p in alive do
			local best = p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Best Round")
			if best and round > best.Value and countAlive() > 0 and alive[p] then best.Value = round end
		end
		local left = countAlive()
		if left == 0 or (started > 1 and left <= 1) then
			for p in alive do
				local w = p:FindFirstChild("leaderstats") and p.leaderstats:FindFirstChild("Wins")
				if w and started > 1 then w.Value += 1 end
				Status.Value = p.DisplayName .. (started > 1 and " wins!" or " survived " .. round .. " rounds!")
			end
			if left == 0 then Status.Value = "Everyone fell! " .. round .. " rounds." end
			Called.Value = ""
			task.wait(4)
			for p in alive do
				if p.Character then p.Character:PivotTo(spawnPart.CFrame + Vector3.new(0, 4, 0)) end
			end
			break
		end
		Called.Value = ""
		Status.Value = "Scrambling..."
		scramble()
		task.wait(1.2)
	end
end
