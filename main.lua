local cloneref = cloneref or function(obj) return obj end
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Remotes = replicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")
local SubmitWord = Remotes:WaitForChild("SubmitWord")
local BillboardUpdate = Remotes:WaitForChild("BillboardUpdate")

local Used = {}
local Prefix = {}

local CurrentLetter = nil
local Answered = false
local Ready = false
local Enabled = true

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SambungKataUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0,150,0,60)
Frame.Position = UDim2.new(0,20,0.5,-30)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(1,-20,1,-20)
Button.Position = UDim2.new(0,10,0,10)
Button.BackgroundColor3 = Color3.fromRGB(0,170,0)
Button.Text = "AUTO : ON"
Button.TextColor3 = Color3.new(1,1,1)
Button.TextScaled = true
Button.Parent = Frame

Button.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	
	if Enabled then
		Button.Text = "AUTO : ON"
		Button.BackgroundColor3 = Color3.fromRGB(0,170,0)
	else
		Button.Text = "AUTO : OFF"
		Button.BackgroundColor3 = Color3.fromRGB(170,0,0)
	end
end)

-- Load Wordlist
task.spawn(function()

	if not shared.kbbiwords then
		local ok,res = pcall(function()
			return game:HttpGet("https://raw.githubusercontent.com/SOBING4413/sambungkata/refs/heads/main/dependescis/kbbi.txt",true)
		end)

		if not ok or not res then
			warn("Failed downloading kbbi")
			return
		end

		shared.kbbiwords = res
	end

	for word in string.gmatch(shared.kbbiwords,"[^\r\n]+") do

		local w = string.lower(word)

		if string.match(w,"^[a-z]+$") and #w >= 3 and #w <= 15 then

			for len = 1, math.min(3,#w) do
				local p = string.sub(w,1,len)

				Prefix[p] = Prefix[p] or {}
				table.insert(Prefix[p],w)
			end

		end

	end

	Ready = true
end)

local function FindWord(letter)

	local pool = Prefix[letter]
	if not pool then return nil end

	for i = 1,100 do
		local w = pool[math.random(#pool)]
		if not Used[w] then
			return w
		end
	end

	return nil
end

local function TypeWord(word,already)

	for i = #already + 1,#word do

		BillboardUpdate:FireServer(string.sub(word,1,i))

		local delay

		if i <= 2 then
			delay = math.random(30,45)/100
		elseif i >= #word - 1 then
			delay = math.random(45,65)/100
		else
			delay = math.random(35,55)/100
		end

		task.wait(delay)

	end

end

local function DoAnswer()

	if not CurrentLetter or not Enabled then return end

	local word = FindWord(CurrentLetter)
	if not word then return end

	Used[word] = true

	task.wait(math.random(100,180)/100)

	TypeWord(word,CurrentLetter)

	task.wait(math.random(40,80)/100)

	SubmitWord:FireServer(word)

end

local function Answer()

	if not CurrentLetter or Answered or not Enabled then return end

	Answered = true

	task.spawn(function()

		local t = 0

		while not Ready and t < 10 do
			task.wait(0.5)
			t += 0.5
		end

		if Ready and Enabled then
			DoAnswer()
		end

	end)

end

MatchUI.OnClientEvent:Connect(function(event,data)

	if event == "UpdateServerLetter" and type(data) == "string" then

		CurrentLetter = string.lower(data)
		Answered = false

	elseif event == "StartTurn" then

		task.wait(math.random(80,140)/100)

		Answered = false
		Answer()

	elseif event == "Mistake" then

		Answered = false
		task.wait(math.random(60,120)/100)
		Answer()

	elseif event == "EndTurn" then

		CurrentLetter = nil
		Answered = false

	end

end)
