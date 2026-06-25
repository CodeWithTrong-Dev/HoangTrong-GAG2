-- AutoHarvest & AutoBuy GUI (v7 - DROPDOWN MENU)
-- Grow a Garden 2 Clone — Auto System

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ================================================
-- CONFIG
-- ================================================
local CONFIG = {
	HarvestInterval    = 0.05,    
	BuyInterval        = 0.05,    
	HarvestProximity   = 15,      
}

local SEED_TYPES = {"Apple", "Carrot", "Strawberry", "Watermelon", "Corn", "Pumpkin", "Wheat", "Potato", "Tomato", "Onion"}
local selectedSeedName = SEED_TYPES[1]

-- ================================================
-- STATE
-- ================================================
local autoHarvestEnabled = false
local autoBuyEnabled     = false
local totalHarvested     = 0
local lastScanTime       = 0
local lastBuyTime        = 0

-- ================================================
-- FIND NETWORKING EVENT
-- ================================================
local PurchaseSeedEvent = nil

local function getPurchaseEvent()
	if PurchaseSeedEvent then return PurchaseSeedEvent end
	
	local success, networking = pcall(function() return require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking")) end)
	if success and networking and networking.SeedShop and networking.SeedShop.PurchaseSeed then
		PurchaseSeedEvent = networking.SeedShop.PurchaseSeed
		return PurchaseSeedEvent
	end
	
	for _, v in pairs(getgc(true)) do
		if type(v) == "table" and rawget(v, "PurchaseSeed") then
			PurchaseSeedEvent = rawget(v, "PurchaseSeed")
			return PurchaseSeedEvent
		end
		if type(v) == "table" and rawget(v, "SeedShop") and type(rawget(v, "SeedShop")) == "table" then
			if rawget(v.SeedShop, "PurchaseSeed") then
				PurchaseSeedEvent = v.SeedShop.PurchaseSeed
				return PurchaseSeedEvent
			end
		end
	end
	return nil
end
task.spawn(getPurchaseEvent)

-- ================================================
-- BUILD GUI
-- ================================================
if playerGui:FindFirstChild("AutoSystemGui") then playerGui.AutoSystemGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "AutoSystemGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 240, 0, 250)
panel.Position          = UDim2.new(1, -260, 0, 20)
panel.BackgroundColor3  = Color3.fromRGB(30, 30, 30)
panel.BackgroundTransparency = 0.15
panel.BorderSizePixel   = 0
panel.Parent            = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = Color3.fromRGB(100, 200, 100)
panelStroke.Thickness = 1.5

local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
titleBar.BorderSizePixel  = 0
titleBar.Parent           = panel
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size              = UDim2.new(1, -10, 1, 0)
titleLabel.Position          = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text              = "🌱  Auto System"
titleLabel.Font              = Enum.Font.GothamBold
titleLabel.TextSize          = 15
titleLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
titleLabel.Parent            = titleBar

-- Harvest Buttons
local toggleHarvestBtn = Instance.new("TextButton")
toggleHarvestBtn.Size              = UDim2.new(1, -30, 0, 35)
toggleHarvestBtn.Position          = UDim2.new(0, 15, 0, 48)
toggleHarvestBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 60)
toggleHarvestBtn.Text              = "▶  Start Auto Harvest"
toggleHarvestBtn.Font              = Enum.Font.GothamSemibold
toggleHarvestBtn.TextSize          = 13
toggleHarvestBtn.TextColor3        = Color3.fromRGB(200, 255, 200)
toggleHarvestBtn.Parent            = panel
Instance.new("UICorner", toggleHarvestBtn).CornerRadius = UDim.new(0, 8)

local counterLabel = Instance.new("TextLabel")
counterLabel.Size              = UDim2.new(1, -30, 0, 20)
counterLabel.Position          = UDim2.new(0, 15, 0, 88)
counterLabel.BackgroundTransparency = 1
counterLabel.Text              = "Harvested: 0"
counterLabel.Font              = Enum.Font.Gotham
counterLabel.TextSize          = 12
counterLabel.TextColor3        = Color3.fromRGB(160, 230, 160)
counterLabel.TextXAlignment    = Enum.TextXAlignment.Left
counterLabel.Parent            = panel

-- ==============================================
-- DROPDOWN SEED SELECTION
-- ==============================================
local dropdownBtn = Instance.new("TextButton")
dropdownBtn.Size              = UDim2.new(1, -30, 0, 35)
dropdownBtn.Position          = UDim2.new(0, 15, 0, 120)
dropdownBtn.BackgroundColor3  = Color3.fromRGB(50, 50, 80)
dropdownBtn.Text              = "🛒 Seed: " .. selectedSeedName .. " ▾"
dropdownBtn.Font              = Enum.Font.GothamSemibold
dropdownBtn.TextColor3        = Color3.fromRGB(255, 200, 100)
dropdownBtn.TextSize          = 13
dropdownBtn.Parent            = panel
Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)

-- Khung chứa danh sách các hạt giống
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size              = UDim2.new(1, -30, 0, 120)
scrollFrame.Position          = UDim2.new(0, 15, 0, 160)
scrollFrame.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
scrollFrame.BorderSizePixel   = 0
scrollFrame.ScrollBarThickness = 4
scrollFrame.Visible           = false
scrollFrame.ZIndex            = 10 -- Hiện đè lên nút Buy
scrollFrame.Parent            = panel
Instance.new("UICorner", scrollFrame).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)

-- Hàm đổ dữ liệu vào Dropdown
local function populateDropdown()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	
	for i, seed in ipairs(SEED_TYPES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, -6, 0, 25)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.Text = seed
		btn.Font = Enum.Font.Gotham
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.ZIndex = 11
		btn.Parent = scrollFrame
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		
		btn.MouseButton1Click:Connect(function()
			selectedSeedName = seed
			dropdownBtn.Text = "🛒 Seed: " .. seed .. " ▾"
			scrollFrame.Visible = false
		end)
	end
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #SEED_TYPES * 27)
end

dropdownBtn.MouseButton1Click:Connect(function()
	scrollFrame.Visible = not scrollFrame.Visible
end)

-- Tự động cào dữ liệu toàn bộ hạt giống có thật trong game
task.spawn(function()
	pcall(function()
		local SeedData = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("SeedData"))
		local newSeeds = {}
		for k, v in pairs(SeedData) do
			if type(v) == "table" and (v.SeedShopDisplayOrder or v.RestockShop) then
				local sName = type(k) == "string" and k or v.SeedName
				if sName and typeof(sName) == "string" then
					table.insert(newSeeds, sName)
				end
			end
		end
		if #newSeeds > 0 then
			table.sort(newSeeds)
			SEED_TYPES = newSeeds
			selectedSeedName = SEED_TYPES[1]
			dropdownBtn.Text = "🛒 Seed: " .. selectedSeedName .. " ▾"
			populateDropdown()
		end
	end)
end)
populateDropdown() -- Lần load danh sách mặc định đầu tiên
-- ==============================================

local toggleBuyBtn = Instance.new("TextButton")
toggleBuyBtn.Size              = UDim2.new(1, -30, 0, 35)
toggleBuyBtn.Position          = UDim2.new(0, 15, 0, 165)
toggleBuyBtn.BackgroundColor3  = Color3.fromRGB(60, 60, 60)
toggleBuyBtn.Text              = "▶  Start Auto Buy"
toggleBuyBtn.Font              = Enum.Font.GothamSemibold
toggleBuyBtn.TextSize          = 13
toggleBuyBtn.TextColor3        = Color3.fromRGB(200, 200, 255)
toggleBuyBtn.Parent            = panel
Instance.new("UICorner", toggleBuyBtn).CornerRadius = UDim.new(0, 8)

local buyStatusLabel = Instance.new("TextLabel")
buyStatusLabel.Size              = UDim2.new(1, -30, 0, 20)
buyStatusLabel.Position          = UDim2.new(0, 15, 0, 205)
buyStatusLabel.BackgroundTransparency = 1
buyStatusLabel.Text              = "Buy Status: Idle"
buyStatusLabel.Font              = Enum.Font.Gotham
buyStatusLabel.TextSize          = 12
buyStatusLabel.TextColor3        = Color3.fromRGB(180, 180, 180)
buyStatusLabel.TextXAlignment    = Enum.TextXAlignment.Left
buyStatusLabel.Parent            = panel

-- ================================================
-- DRAG PANEL
-- ================================================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, panel.Position
	end
end)
titleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- ================================================
-- PACKET REMOTE (Auto Harvest)
-- ================================================
local packetRemote = ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Packet"):WaitForChild("RemoteEvent")
local function fireHarvestPacket(plantId, fruitId)
	packetRemote:FireServer(buffer.fromstring("\198\000$" .. plantId .. "$" .. fruitId))
end

-- ================================================
-- AUTO FUNCTIONS
-- ================================================
local function doHarvest()
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local rootPos = char.HumanoidRootPart.Position
	local gardens = workspace:FindFirstChild("Gardens") or workspace:FindFirstChild("_Gardens")
	if not gardens then return end

	local harvestedThisTick = 0
	for _, plot in ipairs(gardens:GetChildren()) do
		local plants = plot:FindFirstChild("Plants")
		if plants then
			for _, crop in ipairs(plants:GetChildren()) do
				if crop:GetAttribute("PlantGrowthReady") == true then
					local plantId = crop:GetAttribute("PlantId")
					local fruitsFolder = crop:FindFirstChild("Fruits")
					if plantId and fruitsFolder then
						for _, fruit in ipairs(fruitsFolder:GetChildren()) do
							local fruitId = fruit:GetAttribute("FruitId")
							if fruitId then
								local primaryPart = fruit:FindFirstChildWhichIsA("BasePart") or crop.PrimaryPart or crop:FindFirstChildWhichIsA("BasePart", true)
								if primaryPart and (rootPos - primaryPart.Position).Magnitude <= CONFIG.HarvestProximity then
									fireHarvestPacket(plantId, fruitId)
									harvestedThisTick += 1
									totalHarvested += 1
								end
							end
						end
					end
				end
			end
		end
	end

	if harvestedThisTick > 0 then
		counterLabel.Text = "Harvested: " .. totalHarvested
		TweenService:Create(counterLabel, TweenInfo.new(0.15), { TextColor3 = Color3.fromRGB(255, 255, 120) }):Play()
		task.delay(0.3, function() TweenService:Create(counterLabel, TweenInfo.new(0.3), { TextColor3 = Color3.fromRGB(160, 230, 160) }):Play() end)
	end
end

local function doBuySeed()
	local pEvent = getPurchaseEvent()
	if not pEvent then
		buyStatusLabel.Text = "Lỗi: Không tìm thấy Event Module!"
		buyStatusLabel.TextColor3 = Color3.fromRGB(230, 80, 80)
		return
	end
	
	pcall(function()
		pEvent:Fire(selectedSeedName)
		pEvent:Fire(selectedSeedName)
		pEvent:Fire(selectedSeedName)
	end)
	
	buyStatusLabel.Text = "Đang mua: " .. selectedSeedName .. "..."
	TweenService:Create(buyStatusLabel, TweenInfo.new(0.1), { TextColor3 = Color3.fromRGB(100, 255, 100) }):Play()
end

RunService.Heartbeat:Connect(function()
	local now = tick()
	if autoHarvestEnabled and now - lastScanTime >= CONFIG.HarvestInterval then
		lastScanTime = now
		doHarvest()
	end
	if autoBuyEnabled and now - lastBuyTime >= CONFIG.BuyInterval then
		lastBuyTime = now
		doBuySeed()
	end
end)

-- ================================================
-- UI EVENTS
-- ================================================
toggleHarvestBtn.MouseButton1Click:Connect(function()
	autoHarvestEnabled = not autoHarvestEnabled
	if autoHarvestEnabled then
		toggleHarvestBtn.Text = "⏹  Stop Auto Harvest"
		toggleHarvestBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
	else
		toggleHarvestBtn.Text = "▶  Start Auto Harvest"
		toggleHarvestBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	end
end)

toggleBuyBtn.MouseButton1Click:Connect(function()
	autoBuyEnabled = not autoBuyEnabled
	if autoBuyEnabled then
		toggleBuyBtn.Text = "⏹  Stop Auto Buy"
		toggleBuyBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		buyStatusLabel.Text = "Buy Status: Đang chạy siêu tốc!"
	else
		toggleBuyBtn.Text = "▶  Start Auto Buy"
		toggleBuyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		buyStatusLabel.Text = "Buy Status: Tạm dừng"
	end
end)
