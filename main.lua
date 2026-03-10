local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")

local Dependencies = ReplicatedStorage:WaitForChild("dependescis")

local Prefix1 = {}
local Prefix2 = {}

local CurrentLetter = nil
local Ready = false
local Options = {}

--------------------------------------------------
-- UI
--------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Parent = PlayerGui
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Parent = gui
frame.Size = UDim2.new(0,360,0,320)
frame.Position = UDim2.new(0,30,0.5,-160)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner",frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke")
stroke.Parent = frame
stroke.Color = Color3.fromRGB(70,70,70)
stroke.Thickness = 1.2

local title = Instance.new("TextLabel")
title.Parent = frame
title.Size = UDim2.new(1,0,0,42)
title.BackgroundTransparency = 1
title.Text = "KBBI | by.Sobing4413"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255,255,255)

local prefixLabel = Instance.new("TextLabel")
prefixLabel.Parent = frame
prefixLabel.Size = UDim2.new(1,-20,0,26)
prefixLabel.Position = UDim2.new(0,10,0,45)
prefixLabel.BackgroundTransparency = 1
prefixLabel.Text = "Awalan : ..."
prefixLabel.Font = Enum.Font.Gotham
prefixLabel.TextSize = 17
prefixLabel.TextColor3 = Color3.fromRGB(180,180,180)
prefixLabel.TextXAlignment = Enum.TextXAlignment.Left

local scroll = Instance.new("ScrollingFrame")
scroll.Parent = frame
scroll.Size = UDim2.new(1,-20,1,-90)
scroll.Position = UDim2.new(0,10,0,80)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4

local layout = Instance.new("UIListLayout")
layout.Parent = scroll
layout.Padding = UDim.new(0,6)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)
end)

local buttons = {}

local function CreateButton()

	local btn = Instance.new("TextButton")
	btn.Parent = scroll
	btn.Size = UDim2.new(1,0,0,34)
	btn.Text = "..."
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 17
	btn.TextColor3 = Color3.fromRGB(235,235,235)
	btn.BackgroundColor3 = Color3.fromRGB(32,32,32)

	Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

	local stroke = Instance.new("UIStroke")
	stroke.Parent = btn
	stroke.Color = Color3.fromRGB(70,70,70)

	table.insert(buttons,btn)

end

for i = 1,30 do
	CreateButton()
end

--------------------------------------------------
-- WORD SYSTEM
--------------------------------------------------

local function AddWord(word)

	word = tostring(word):lower():gsub("%s","")

	if word:match("^[a-z]+$") and #word >= 3 then

		local p1 = word:sub(1,1)
		local p2 = word:sub(1,2)

		Prefix1[p1] = Prefix1[p1] or {}
		table.insert(Prefix1[p1],word)

		Prefix2[p2] = Prefix2[p2] or {}
		table.insert(Prefix2[p2],word)

	end

end

--------------------------------------------------
-- LOAD DEPENDENCIS
--------------------------------------------------

local function LoadWords(data)

	if typeof(data) ~= "table" then return end

	for _,v in pairs(data) do

		if typeof(v) == "string" then
			AddWord(v)

		elseif typeof(v) == "table" then
			LoadWords(v)
		end

	end

end

task.spawn(function()

	for _,file in ipairs(Dependencies:GetDescendants()) do

		if file:IsA("ModuleScript") then

			local ok,data = pcall(require,file)
			if ok then
				LoadWords(data)
			end

		elseif file:IsA("StringValue") then

			local ok,data = pcall(function()
				return HttpService:JSONDecode(file.Value)
			end)

			if ok then
				LoadWords(data)
			end

		end

	end

	Ready = true
	print("Wordlist Loaded:",#Prefix1)

end)

--------------------------------------------------
-- LETTER DIFFICULTY
--------------------------------------------------

local HardLetters = {
	q=10,x=9,z=8,v=7,f=6,w=5,y=4,k=3,b=2,p=1
}

local function Difficulty(word)
	return HardLetters[word:sub(-1)] or 0
end

--------------------------------------------------
-- FIND OPTIONS
--------------------------------------------------

local function FindOptions(prefix)

	prefix = tostring(prefix):lower():gsub("[^a-z]","")

	local list

	if #prefix >= 2 then
		list = Prefix2[prefix:sub(1,2)]
	else
		list = Prefix1[prefix:sub(1,1)]
	end

	if not list then
		return {}
	end

	local filtered = {}
	local used = {}

	for _,word in ipairs(list) do

		if word:sub(1,#prefix) == prefix and not used[word] then
			used[word] = true
			table.insert(filtered,word)
		end

	end

	table.sort(filtered,function(a,b)
		return Difficulty(a) < Difficulty(b)
	end)

	return filtered

end

--------------------------------------------------
-- UPDATE UI
--------------------------------------------------

local function UpdatePreview()

	if not Ready or not CurrentLetter then return end

	Options = FindOptions(CurrentLetter)

	prefixLabel.Text = "Awalan : "..CurrentLetter

	for i,btn in ipairs(buttons) do
		btn.Text = Options[i] or ""
	end

end

--------------------------------------------------
-- BUTTON CLICK
--------------------------------------------------

for i,btn in ipairs(buttons) do

	btn.MouseButton1Click:Connect(function()

		local word = Options[i]
		if not word then return end

		local box = player.PlayerGui:FindFirstChild("MatchUI",true)

		if box then

			local input = box:FindFirstChildWhichIsA("TextBox",true)

			if input then
				input.Text = word
			end

		end

	end)

end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

MatchUI.OnClientEvent:Connect(function(event,data)

	if event == "UpdateServerLetter" then

		CurrentLetter = tostring(data):lower():gsub("[^a-z]","")
		UpdatePreview()

	end

end)
