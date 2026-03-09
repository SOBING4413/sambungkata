local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")
local SubmitWord = Remotes:WaitForChild("SubmitWord")
local BillboardUpdate = Remotes:WaitForChild("BillboardUpdate")

local Used = {}
local Prefix1 = {}
local Prefix2 = {}

local CurrentLetter = nil
local Enabled = false
local Ready = false
local Answered = false

--------------------------------------------------
-- UI
--------------------------------------------------

local gui = Instance.new("ScreenGui", PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,95)
frame.Position = UDim2.new(0,20,0.5,-45)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner",frame)

local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,0,0,25)
title.BackgroundTransparency = 1
title.Text = "Auto Sambung Kata"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local toggle = Instance.new("TextButton",frame)
toggle.Size = UDim2.new(0.35,0,0,28)
toggle.Position = UDim2.new(0.05,0,0,35)
toggle.Text = "OFF"
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.BackgroundColor3 = Color3.fromRGB(170,0,0)
toggle.TextColor3 = Color3.new(1,1,1)

local label = Instance.new("TextLabel",frame)
label.Size = UDim2.new(0.9,0,0,25)
label.Position = UDim2.new(0.05,0,0,65)
label.BackgroundTransparency = 1
label.Text = "Next Word : ..."
label.TextColor3 = Color3.fromRGB(200,200,200)
label.TextScaled = true
label.Font = Enum.Font.Gotham
label.TextXAlignment = Enum.TextXAlignment.Left

toggle.MouseButton1Click:Connect(function()

    Enabled = not Enabled

    if Enabled then
        toggle.Text = "ON"
        toggle.BackgroundColor3 = Color3.fromRGB(0,170,0)
    else
        toggle.Text = "OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(170,0,0)
    end

end)

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
        local ok2,res2 = pcall(function()
            return readfile("kbbi.txt")
        end)

        if ok2 then
            text = res2
        else
            warn("Wordlist gagal load")
            return
        end
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
-- FIND WORD
--------------------------------------------------

local function FindWord(prefix)

    prefix = string.lower(prefix)

    if #prefix >= 2 then

        local p = Prefix2[string.sub(prefix,1,2)]

        if p then
            for i=1,200 do
                local w = p[math.random(#p)]
                if not Used[w] then return w end
            end
        end

    end

    local p = Prefix1[string.sub(prefix,1,1)]

    if p then
        for i=1,200 do
            local w = p[math.random(#p)]
            if not Used[w] then return w end
        end
    end

end

--------------------------------------------------
-- TYPE WORD
--------------------------------------------------

local function TypeWord(word,start)

    start = string.lower(start or "")

    -- cari panjang prefix yang cocok
    local skip = 0

    for i = 1, #start do
        if string.sub(word,1,i) == string.sub(start,1,i) then
            skip = i
        else
            break
        end
    end

    for i = skip + 1, #word do

        local partial = string.sub(word,1,i)

        BillboardUpdate:FireServer(partial)

        task.wait(0.04)

    end

end

--------------------------------------------------
-- ANSWER
--------------------------------------------------

local function Answer()

    if not Enabled or not CurrentLetter or Answered then return end
    if not Ready then return end

    Answered = true

    local word = FindWord(CurrentLetter)

    if not word then return end

    label.Text = "Next Word : "..word

    Used[word] = true

    task.wait(math.random(60,120)/100)

    TypeWord(word,CurrentLetter)

    task.wait(0.3)

    SubmitWord:FireServer(word)

end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

MatchUI.OnClientEvent:Connect(function(event,data)

    if event == "UpdateServerLetter" then

        CurrentLetter = tostring(data)
        Answered = false

        print("Prefix:",CurrentLetter)

    elseif event == "StartTurn" then

        task.wait(0.8)
        Answer()

    elseif event == "Mistake" then

        task.wait(0.7)
        Answer()

    elseif event == "EndTurn" then

        CurrentLetter = nil
        label.Text = "Next Word : ..."

    end

end)
