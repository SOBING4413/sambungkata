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
local Enabled = false
local Ready = false
local Options = {}

--------------------------------------------------
-- UI
--------------------------------------------------

local gui = Instance.new("ScreenGui",PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame",gui)
frame.Size = UDim2.new(0,270,0,170)
frame.Position = UDim2.new(0,20,0.5,-85)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel",frame)
title.Size = UDim2.new(1,0,0,30)
title.BackgroundTransparency = 1
title.Text = "Sambung Kata Helper"
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextColor3 = Color3.fromRGB(255,255,255)

local toggle = Instance.new("TextButton",frame)
toggle.Size = UDim2.new(0,70,0,25)
toggle.Position = UDim2.new(1,-80,0,3)
toggle.Text = "OFF"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 13
toggle.BackgroundColor3 = Color3.fromRGB(170,0,0)
toggle.TextColor3 = Color3.new(1,1,1)

Instance.new("UICorner",toggle)

local prefixLabel = Instance.new("TextLabel",frame)
prefixLabel.Size = UDim2.new(1,-20,0,20)
prefixLabel.Position = UDim2.new(0,10,0,35)
prefixLabel.BackgroundTransparency = 1
prefixLabel.Text = "Prefix : ..."
prefixLabel.Font = Enum.Font.Gotham
prefixLabel.TextSize = 14
prefixLabel.TextColor3 = Color3.fromRGB(200,200,200)
prefixLabel.TextXAlignment = Enum.TextXAlignment.Left

local listFrame = Instance.new("Frame",frame)
listFrame.Size = UDim2.new(1,-20,0,100)
listFrame.Position = UDim2.new(0,10,0,60)
listFrame.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout",listFrame)
layout.Padding = UDim.new(0,5)

local buttons = {}

for i=1,5 do

    local btn = Instance.new("TextButton",listFrame)

    btn.Size = UDim2.new(1,0,0,18)
    btn.Text = "..."
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
    btn.TextColor3 = Color3.fromRGB(230,230,230)

    Instance.new("UICorner",btn)

    table.insert(buttons,btn)

end

--------------------------------------------------
-- TOGGLE
--------------------------------------------------

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

    for i=1,5 do
        table.insert(results,list[math.random(#list)])
    end

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

    prefixLabel.Text = "Prefix : "..CurrentLetter

    for i,btn in ipairs(buttons) do
        btn.Text = Options[i] or "..."
    end

end

--------------------------------------------------
-- BUTTON CLICK
--------------------------------------------------

for i,btn in ipairs(buttons) do

    btn.MouseButton1Click:Connect(function()

        if not Enabled then return end
        if not Options[i] then return end

        local word = Options[i]

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

    elseif event == "EndTurn" then

        CurrentLetter = nil

    end

end)
