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

--------------------------------------------------
-- UI
--------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 240, 0, 95)
Frame.Position = UDim2.new(0, 20, 0.5, -45)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundTransparency = 1
Title.Text = "ExterFrameworked | Sambung Kata"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.new(0.35, 0, 0, 28)
Toggle.Position = UDim2.new(0.05, 0, 0, 35)
Toggle.Text = "ON"
Toggle.TextScaled = true
Toggle.Font = Enum.Font.GothamBold
Toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Parent = Frame

local WordLabel = Instance.new("TextLabel")
WordLabel.Size = UDim2.new(0.9, 0, 0, 25)
WordLabel.Position = UDim2.new(0.05, 0, 0, 65)
WordLabel.BackgroundTransparency = 1
WordLabel.Text = "Next Word : ..."
WordLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
WordLabel.TextScaled = true
WordLabel.Font = Enum.Font.Gotham
WordLabel.TextXAlignment = Enum.TextXAlignment.Left
WordLabel.Parent = Frame

Toggle.MouseButton1Click:Connect(function()

    Enabled = not Enabled

    if Enabled then
        Toggle.Text = "ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        Toggle.Text = "OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    end

end)

--------------------------------------------------
-- LOAD WORDLIST
--------------------------------------------------

task.spawn(function()

    if not shared.kbbiwords then

        local ok, res = pcall(function()
            return game:HttpGet(
                       "https://raw.githubusercontent.com/SOBING4413/sambungkata/main/dependescis/kbbi.txt")
        end)

        if not ok then
            warn("Failed download wordlist")
            return
        end

        shared.kbbiwords = res

    end

    for word in string.gmatch(shared.kbbiwords, "[^\r\n]+") do

        local w = string.lower(word)

        if string.match(w, "^[a-z]+$") and #w >= 3 then

            local p = string.sub(w, 1, 2)

            Prefix[p] = Prefix[p] or {}
            table.insert(Prefix[p], w)

        end

    end

    Ready = true

end)

--------------------------------------------------
-- FIND WORD
--------------------------------------------------

local function FindWord(letter)

    local pool = Prefix[letter]

    if not pool then return nil end

    for i = 1, 200 do

        local w = pool[math.random(#pool)]

        if not Used[w] then return w end

    end

end

--------------------------------------------------
-- TYPE WORD
--------------------------------------------------

local function TypeWord(word, already)

    for i = #already + 1, #word do

        local partial = string.sub(word, 1, i)

        BillboardUpdate:FireServer(partial)

        task.wait(math.random(35, 55) / 100)

    end

end

--------------------------------------------------
-- ANSWER
--------------------------------------------------

local function DoAnswer()

    if not CurrentLetter or not Enabled then return end

    local word = FindWord(CurrentLetter)

    if not word then return end

    WordLabel.Text = "Next Word : " .. word

    Used[word] = true

    task.wait(math.random(80, 120) / 100)

    TypeWord(word, CurrentLetter)

    task.wait(math.random(30, 50) / 100)

    SubmitWord:FireServer(word)

end

local function Answer()

    if not CurrentLetter or Answered or not Enabled then return end

    Answered = true

    task.spawn(function()

        while not Ready do task.wait(0.3) end

        DoAnswer()

    end)

end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

MatchUI.OnClientEvent:Connect(function(event, data)

    if event == "UpdateServerLetter" and type(data) == "string" then

        CurrentLetter = string.lower(data)
        Answered = false

    elseif event == "StartTurn" then

        task.wait(math.random(70, 120) / 100)

        Answered = false
        Answer()

    elseif event == "Mistake" then

        Answered = false
        task.wait(0.7)
        Answer()

    elseif event == "EndTurn" then

        CurrentLetter = nil
        Answered = false
        WordLabel.Text = "Next Word : ..."

    end

end)
