local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")

local Prefix1 = {}
local Prefix2 = {}

local CurrentLetter = nil
local Ready = false
local Options = {}

--------------------------------------------------
-- UI PREMIUM
--------------------------------------------------

local gui = Instance.new("ScreenGui",PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame",gui)
frame.Size = UDim2.new(0,360,0,320)
frame.Position = UDim2.new(0,30,0.5,-160)
frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner",frame).CornerRadius = UDim.new(0,14)

local stroke = Instance.new("UIStroke",frame)
stroke.Color = Color3.fromRGB(70,70,70)
stroke.Thickness = 1.2

local grad = Instance.new("UIGradient",frame)
grad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0,Color3.fromRGB(35,35,35)),
	ColorSequenceKeypoint.new(1,Color3.fromRGB(15,15,15))
}
grad.Rotation = 90

-- TITLE
local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,0,0,42)
title.BackgroundTransparency = 1
title.Text = "KBBI BY.Sobing4413"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(255,255,255)

-- PREFIX
local prefixLabel = Instance.new("TextLabel",frame)
prefixLabel.Size = UDim2.new(1,-20,0,26)
prefixLabel.Position = UDim2.new(0,10,0,45)
prefixLabel.BackgroundTransparency = 1
prefixLabel.Text = "Awalan : ..."
prefixLabel.Font = Enum.Font.Gotham
prefixLabel.TextSize = 17
prefixLabel.TextColor3 = Color3.fromRGB(180,180,180)
prefixLabel.TextXAlignment = Enum.TextXAlignment.Left

-- SCROLL LIST
local scroll = Instance.new("ScrollingFrame",frame)
scroll.Size = UDim2.new(1,-20,1,-90)
scroll.Position = UDim2.new(0,10,0,80)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0,0,0,0)

local layout = Instance.new("UIListLayout",scroll)
layout.Padding = UDim.new(0,6)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+10)
end)

local buttons = {}

local function CreateButton()

	local btn = Instance.new("TextButton")

	btn.Size = UDim2.new(1,0,0,34)
	btn.Text = "..."
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 17
	btn.TextColor3 = Color3.fromRGB(235,235,235)
	btn.BackgroundColor3 = Color3.fromRGB(32,32,32)
	btn.Parent = scroll

	Instance.new("UICorner",btn).CornerRadius = UDim.new(0,8)

	local stroke = Instance.new("UIStroke",btn)
	stroke.Color = Color3.fromRGB(70,70,70)
	stroke.Thickness = 1

	btn.MouseEnter:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
	end)

	btn.MouseLeave:Connect(function()
		btn.BackgroundColor3 = Color3.fromRGB(32,32,32)
	end)

	table.insert(buttons,btn)

end

-- 30 opsi jawaban scroll
for i=1,30 do
	CreateButton()
end

--------------------------------------------------
-- LOAD WORDLIST
--------------------------------------------------

task.spawn(function()

	local text

	local ok,res = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/SOBING4413/sambungkata/main/dependescis/kbbi.txt")
	end)

	if ok then
		text = res
	else
		warn("Failed load github wordlist")
		return
	end

	for word in string.gmatch(text,"[^\r\n]+") do

		local w = string.lower(word)

		if string.match(w,"^[a-z]+$") and #w >= 3 then

			local p1 = string.sub(w,1,1)
			local p2 = string.sub(w,1,2)

			Prefix1[p1] = Prefix1[p1] or {}
			table.insert(Prefix1[p1],w)

			Prefix2[p2] = Prefix2[p2] or {}
			table.insert(Prefix2[p2],w)

		end

	end

	Ready = true
	print("Wordlist loaded")

end)

--------------------------------------------------
-- LETTER DIFFICULTY
--------------------------------------------------

local HardLetters = {
	q=10,x=9,z=8,v=7,f=6,w=5,y=4,k=3,b=2,p=1
}

local function Difficulty(word)

	local last = string.sub(word,-1)
	return HardLetters[last] or 0

end

--------------------------------------------------
-- FIND OPTIONS
--------------------------------------------------

local function FindOptions(prefix)

	prefix = string.lower(prefix)

	local list

	if #prefix >= 2 then
		list = Prefix2[string.sub(prefix,1,2)]
	end

	if not list then
		list = Prefix1[string.sub(prefix,1,1)]
	end

	if not list then return end

	local results = {}

	for i=1,80 do
		table.insert(results,list[math.random(#list)])
	end

	table.sort(results,function(a,b)
		return Difficulty(a) < Difficulty(b)
	end)

	return results

end

--------------------------------------------------
-- UPDATE UI
--------------------------------------------------

local function UpdatePreview()

	if not Ready then return end
	if not CurrentLetter then return end

	Options = FindOptions(CurrentLetter)

	if not Options then return end

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

		CurrentLetter = tostring(data)

		UpdatePreview()

	end

end)
