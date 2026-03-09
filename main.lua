local cloneref = cloneref or function(obj) return obj end
local replicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local Remotes = replicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")
local SubmitWord = Remotes:WaitForChild("SubmitWord")
local BillboardUpdate = Remotes:WaitForChild("BillboardUpdate")

local Used = {}
local Prefix = {}

local CurrentLetter = nil
local Answered = false
local Ready = false
local Round = 1

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

	for i = 1,#pool do
		local w = pool[math.random(#pool)]

		if not Used[w] then
			return w
		end
	end

	return nil
end

local function Update(word,already)

	for i = #already + 1,#word do

		BillboardUpdate:FireServer(string.sub(word,1,i))

		task.wait(math.random(8,18)/100)

	end

end

local function DoAnswer()

	if not CurrentLetter then return end

	local word = FindWord(CurrentLetter)
	if not word then return end

	Used[word] = true

	task.wait(math.random(30,80)/100)

	Update(word,CurrentLetter)

	task.wait(math.random(5,15)/100)

	SubmitWord:FireServer(word)

end

local function Answer()

	if not CurrentLetter or Answered then return end

	Answered = true

	task.spawn(function()

		local t = 0

		while not Ready and t < 15 do
			task.wait(0.5)
			t += 0.5
		end

		if Ready then
			DoAnswer()
		end

	end)

end

MatchUI.OnClientEvent:Connect(function(event,data)

	if event == "UpdateServerLetter" and type(data) == "string" then

		CurrentLetter = string.lower(data)
		Answered = false

	elseif event == "StartTurn" then

		Round += 1
		Answered = false
		Answer()

	elseif event == "Mistake" then

		Answered = false
		task.wait(0.3)
		Answer()

	elseif event == "EndTurn" then

		CurrentLetter = nil
		Answered = false

	end

end)