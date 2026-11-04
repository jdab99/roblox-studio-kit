-- Scramble Floor HUD (StarterGui LocalScript): the called color as a big banner
local RS = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ScrambleHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0.08, 0)
banner.Size = UDim2.new(0.5, 0, 0.1, 0)
banner.BackgroundTransparency = 0.15
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
banner.Font = Enum.Font.FredokaOne
banner.TextScaled = true
banner.TextColor3 = Color3.new(1, 1, 1)
banner.Text = ""
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0.25, 0)
local stroke = Instance.new("UIStroke", banner)
stroke.Thickness = 4

local status = Instance.new("TextLabel")
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.new(0.5, 0, 0.19, 0)
status.Size = UDim2.new(0.6, 0, 0.05, 0)
status.BackgroundTransparency = 1
status.Font = Enum.Font.FredokaOne
status.TextScaled = true
status.TextColor3 = Color3.new(1, 1, 1)
status.TextStrokeTransparency = 0.3
status.Parent = gui

local Status = RS:WaitForChild("Status")
local Called = RS:WaitForChild("CalledColor")
local colors = RS:WaitForChild("CubeColors")

local function refresh()
	status.Text = Status.Value
	local c = colors:FindFirstChild(Called.Value)
	banner.Visible = c ~= nil
	if c then
		banner.Text = Called.Value
		banner.BackgroundColor3 = c.Value
		local dark = (c.Value.R + c.Value.G + c.Value.B) > 2
		banner.TextColor3 = dark and Color3.fromRGB(20, 20, 24) or Color3.new(1, 1, 1)
		stroke.Color = Color3.fromRGB(20, 20, 24)
	end
end
Status.Changed:Connect(refresh)
Called.Changed:Connect(refresh)
refresh()
