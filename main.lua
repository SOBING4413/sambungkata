local cloneref = cloneref or function(o) return o end
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchUI = Remotes:WaitForChild("MatchUI")

local Prefix1 = {}
local Prefix2 = {}

local CurrentLetter = nil
local Ready = false
local Options = {}
local IsMinimized = false
local ScriptActive = true

-- Strategy data: how many words start with each letter (populated after load)
local LetterWordCount = {}

-- ============================================================
-- KILLER LETTER CONFIG (OPTIMIZED)
-- Huruf-huruf yang jadi "senjata mematikan" karena lawan
-- akan sangat kesulitan mencari kata yang berawalan huruf ini.
-- Skor lebih tinggi = lebih mematikan = ditaruh paling atas.
-- ============================================================
local KILLER_SCORE_OVERRIDE = {
	x = 99999,  -- hampir tidak ada kata berawalan x
	z = 95000,  -- sangat sedikit kata berawalan z
	q = 90000,  -- sangat sedikit kata berawalan q
	v = 70000,  -- sedikit kata berawalan v
	f = 60000,  -- lumayan sedikit
	w = 50000,  -- agak sedikit
	y = 45000,  -- agak sedikit
	j = 35000,  -- cukup sulit
	k = 30000,  -- cukup sulit
	g = 25000,  -- agak sulit
	c = 22000,  -- agak sulit
}

-- Jumlah tombol ditambah dari 30 → 50 agar lebih banyak opsi muncul
local MAX_BUTTONS = 50

--------------------------------------------------
-- TWEEN HELPER
--------------------------------------------------

local function Tween(obj, props, duration, style, dir)
	local info = TweenInfo.new(
		duration or 0.3,
		style or Enum.EasingStyle.Quint,
		dir or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function TweenWait(obj, props, duration, style, dir)
	local t = Tween(obj, props, duration, style, dir)
	t.Completed:Wait()
end

--------------------------------------------------
-- THEME SYSTEM
--------------------------------------------------

local Themes = {
	Merah = {
		accent = Color3.fromRGB(230, 55, 65),
		accentLight = Color3.fromRGB(255, 95, 100),
		accentDark = Color3.fromRGB(170, 30, 35),
		gradTop = Color3.fromRGB(32, 10, 12),
		gradBot = Color3.fromRGB(14, 6, 8),
		cardBg = Color3.fromRGB(30, 12, 14),
		cardBgAlt = Color3.fromRGB(36, 15, 17),
		cardHover = Color3.fromRGB(50, 18, 22),
		panelBg = Color3.fromRGB(22, 9, 11),
		stroke = Color3.fromRGB(80, 25, 28),
		strokeLight = Color3.fromRGB(120, 40, 45),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(200, 170, 172),
		textMuted = Color3.fromRGB(140, 110, 112),
		scrollBar = Color3.fromRGB(230, 55, 65),
		glow = Color3.fromRGB(255, 70, 80),
		success = Color3.fromRGB(40, 200, 100),
		error = Color3.fromRGB(230, 55, 65),
		info = Color3.fromRGB(55, 170, 240),
		warning = Color3.fromRGB(240, 180, 40),
	},
	Hijau = {
		accent = Color3.fromRGB(40, 200, 100),
		accentLight = Color3.fromRGB(70, 235, 130),
		accentDark = Color3.fromRGB(25, 150, 70),
		gradTop = Color3.fromRGB(10, 30, 16),
		gradBot = Color3.fromRGB(6, 14, 9),
		cardBg = Color3.fromRGB(12, 28, 16),
		cardBgAlt = Color3.fromRGB(15, 33, 20),
		cardHover = Color3.fromRGB(20, 44, 26),
		panelBg = Color3.fromRGB(9, 22, 13),
		stroke = Color3.fromRGB(28, 75, 38),
		strokeLight = Color3.fromRGB(40, 110, 55),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(175, 215, 185),
		textMuted = Color3.fromRGB(110, 150, 120),
		scrollBar = Color3.fromRGB(40, 200, 100),
		glow = Color3.fromRGB(60, 255, 120),
		success = Color3.fromRGB(40, 200, 100),
		error = Color3.fromRGB(230, 55, 65),
		info = Color3.fromRGB(55, 170, 240),
		warning = Color3.fromRGB(240, 180, 40),
	},
	Biru = {
		accent = Color3.fromRGB(55, 130, 240),
		accentLight = Color3.fromRGB(90, 165, 255),
		accentDark = Color3.fromRGB(30, 90, 180),
		gradTop = Color3.fromRGB(10, 16, 35),
		gradBot = Color3.fromRGB(6, 8, 18),
		cardBg = Color3.fromRGB(12, 18, 36),
		cardBgAlt = Color3.fromRGB(15, 22, 42),
		cardHover = Color3.fromRGB(22, 30, 55),
		panelBg = Color3.fromRGB(9, 13, 28),
		stroke = Color3.fromRGB(28, 45, 85),
		strokeLight = Color3.fromRGB(45, 70, 130),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(175, 195, 225),
		textMuted = Color3.fromRGB(110, 130, 165),
		scrollBar = Color3.fromRGB(55, 130, 240),
		glow = Color3.fromRGB(80, 160, 255),
		success = Color3.fromRGB(40, 200, 100),
		error = Color3.fromRGB(230, 55, 65),
		info = Color3.fromRGB(55, 170, 240),
		warning = Color3.fromRGB(240, 180, 40),
	},
	Ungu = {
		accent = Color3.fromRGB(150, 70, 235),
		accentLight = Color3.fromRGB(185, 110, 255),
		accentDark = Color3.fromRGB(110, 40, 180),
		gradTop = Color3.fromRGB(22, 10, 38),
		gradBot = Color3.fromRGB(10, 6, 20),
		cardBg = Color3.fromRGB(22, 12, 36),
		cardBgAlt = Color3.fromRGB(27, 16, 44),
		cardHover = Color3.fromRGB(36, 22, 56),
		panelBg = Color3.fromRGB(16, 9, 28),
		stroke = Color3.fromRGB(60, 28, 90),
		strokeLight = Color3.fromRGB(90, 45, 135),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(205, 185, 225),
		textMuted = Color3.fromRGB(145, 120, 165),
		scrollBar = Color3.fromRGB(150, 70, 235),
		glow = Color3.fromRGB(185, 100, 255),
		success = Color3.fromRGB(40, 200, 100),
		error = Color3.fromRGB(230, 55, 65),
		info = Color3.fromRGB(55, 170, 240),
		warning = Color3.fromRGB(240, 180, 40),
	},
	["Abu-abu"] = {
		accent = Color3.fromRGB(140, 145, 160),
		accentLight = Color3.fromRGB(185, 190, 205),
		accentDark = Color3.fromRGB(100, 105, 118),
		gradTop = Color3.fromRGB(28, 28, 32),
		gradBot = Color3.fromRGB(12, 12, 15),
		cardBg = Color3.fromRGB(26, 26, 30),
		cardBgAlt = Color3.fromRGB(32, 32, 37),
		cardHover = Color3.fromRGB(42, 42, 48),
		panelBg = Color3.fromRGB(20, 20, 24),
		stroke = Color3.fromRGB(55, 55, 62),
		strokeLight = Color3.fromRGB(80, 80, 90),
		textPrimary = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(185, 185, 195),
		textMuted = Color3.fromRGB(120, 120, 132),
		scrollBar = Color3.fromRGB(140, 145, 160),
		glow = Color3.fromRGB(200, 205, 220),
		success = Color3.fromRGB(40, 200, 100),
		error = Color3.fromRGB(230, 55, 65),
		info = Color3.fromRGB(55, 170, 240),
		warning = Color3.fromRGB(240, 180, 40),
	},
}

local CurrentThemeName = "Biru"
local CurrentTheme = Themes[CurrentThemeName]

-- Sort mode: "strategy" (smart) or "difficulty" (old)
local SortMode = "strategy"

--------------------------------------------------
-- SCREEN GUI
--------------------------------------------------

local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "KBBIModernGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

--================================================
--     NOTIFICATION SYSTEM (Modern Toast Style)
--================================================

local notifContainer = Instance.new("Frame", gui)
notifContainer.Name = "NotificationContainer"
notifContainer.Size = UDim2.new(0, 320, 1, 0)
notifContainer.Position = UDim2.new(1, -330, 0, 10)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 200

local notifLayout = Instance.new("UIListLayout", notifContainer)
notifLayout.Padding = UDim.new(0, 8)
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local notifOrderCounter = 0

local NotifIcons = {
	success = "✅",
	error = "❌",
	info = "ℹ️",
	warning = "⚠️",
	correct = "🎉",
	wrong = "💢",
	loaded = "📦",
	unloaded = "🔌",
	danger = "💀",
	strategy = "🧠",
}

local NotifColors = {
	success = Color3.fromRGB(40, 200, 100),
	error = Color3.fromRGB(230, 55, 65),
	info = Color3.fromRGB(55, 170, 240),
	warning = Color3.fromRGB(240, 180, 40),
	correct = Color3.fromRGB(40, 220, 110),
	wrong = Color3.fromRGB(240, 60, 70),
	loaded = Color3.fromRGB(55, 170, 240),
	unloaded = Color3.fromRGB(180, 100, 50),
	danger = Color3.fromRGB(200, 30, 30),
	strategy = Color3.fromRGB(180, 120, 255),
}

local function SendNotification(notifType, titleText, messageText, duration)
	duration = duration or 3.5
	notifOrderCounter = notifOrderCounter + 1

	local notifColor = NotifColors[notifType] or Color3.fromRGB(55, 130, 240)
	local notifIcon = NotifIcons[notifType] or "🔔"

	local notif = Instance.new("Frame", notifContainer)
	notif.Name = "Notif_" .. notifOrderCounter
	notif.Size = UDim2.new(0, 310, 0, 0)
	notif.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.LayoutOrder = notifOrderCounter
	notif.ZIndex = 201
	notif.BackgroundTransparency = 0.05

	Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)

	local notifStroke = Instance.new("UIStroke", notif)
	notifStroke.Color = notifColor
	notifStroke.Thickness = 1.5
	notifStroke.Transparency = 0.4

	local notifGrad = Instance.new("UIGradient", notif)
	notifGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 24, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 14, 22)),
	}
	notifGrad.Rotation = 135

	local accentBar = Instance.new("Frame", notif)
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 4, 1, -12)
	accentBar.Position = UDim2.new(0, 6, 0, 6)
	accentBar.BackgroundColor3 = notifColor
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 203
	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 3)

	local accentGlow = Instance.new("Frame", notif)
	accentGlow.Name = "AccentGlow"
	accentGlow.Size = UDim2.new(0, 40, 1, 0)
	accentGlow.Position = UDim2.new(0, 0, 0, 0)
	accentGlow.BackgroundColor3 = notifColor
	accentGlow.BackgroundTransparency = 0.88
	accentGlow.BorderSizePixel = 0
	accentGlow.ZIndex = 202

	local glowGrad = Instance.new("UIGradient", accentGlow)
	glowGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}
	glowGrad.Rotation = 0

	local iconLabel = Instance.new("TextLabel", notif)
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 32, 0, 32)
	iconLabel.Position = UDim2.new(0, 18, 0, 12)
	iconLabel.BackgroundColor3 = notifColor
	iconLabel.BackgroundTransparency = 0.85
	iconLabel.Text = notifIcon
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextSize = 16
	iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconLabel.BorderSizePixel = 0
	iconLabel.ZIndex = 204
	Instance.new("UICorner", iconLabel).CornerRadius = UDim.new(0, 8)

	local notifTitle = Instance.new("TextLabel", notif)
	notifTitle.Name = "Title"
	notifTitle.Size = UDim2.new(1, -100, 0, 18)
	notifTitle.Position = UDim2.new(0, 58, 0, 10)
	notifTitle.BackgroundTransparency = 1
	notifTitle.Text = titleText or "Notification"
	notifTitle.Font = Enum.Font.GothamBlack
	notifTitle.TextSize = 13
	notifTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	notifTitle.TextXAlignment = Enum.TextXAlignment.Left
	notifTitle.TextTruncate = Enum.TextTruncate.AtEnd
	notifTitle.ZIndex = 204

	local notifMsg = Instance.new("TextLabel", notif)
	notifMsg.Name = "Message"
	notifMsg.Size = UDim2.new(1, -100, 0, 28)
	notifMsg.Position = UDim2.new(0, 58, 0, 28)
	notifMsg.BackgroundTransparency = 1
	notifMsg.Text = messageText or ""
	notifMsg.Font = Enum.Font.Gotham
	notifMsg.TextSize = 11
	notifMsg.TextColor3 = Color3.fromRGB(180, 185, 200)
	notifMsg.TextXAlignment = Enum.TextXAlignment.Left
	notifMsg.TextWrapped = true
	notifMsg.TextYAlignment = Enum.TextYAlignment.Top
	notifMsg.ZIndex = 204

	local notifClose = Instance.new("TextButton", notif)
	notifClose.Name = "CloseBtn"
	notifClose.Size = UDim2.new(0, 24, 0, 24)
	notifClose.Position = UDim2.new(1, -30, 0, 8)
	notifClose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	notifClose.BackgroundTransparency = 0.92
	notifClose.Text = "✕"
	notifClose.Font = Enum.Font.GothamBold
	notifClose.TextSize = 10
	notifClose.TextColor3 = Color3.fromRGB(140, 140, 155)
	notifClose.BorderSizePixel = 0
	notifClose.AutoButtonColor = false
	notifClose.ZIndex = 205
	Instance.new("UICorner", notifClose).CornerRadius = UDim.new(0, 6)

	notifClose.MouseEnter:Connect(function()
		Tween(notifClose, {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.15)
	end)
	notifClose.MouseLeave:Connect(function()
		Tween(notifClose, {BackgroundTransparency = 0.92, TextColor3 = Color3.fromRGB(140, 140, 155)}, 0.15)
	end)

	local progressBar = Instance.new("Frame", notif)
	progressBar.Name = "ProgressBar"
	progressBar.Size = UDim2.new(1, -16, 0, 3)
	progressBar.Position = UDim2.new(0, 8, 1, -8)
	progressBar.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
	progressBar.BorderSizePixel = 0
	progressBar.ZIndex = 203
	Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 2)

	local progressFill = Instance.new("Frame", progressBar)
	progressFill.Name = "Fill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = notifColor
	progressFill.BorderSizePixel = 0
	progressFill.ZIndex = 204
	Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0, 2)

	Tween(notif, {Size = UDim2.new(0, 310, 0, 68)}, 0.35, Enum.EasingStyle.Back)
	Tween(progressFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear)

	local dismissed = false
	local function DismissNotif()
		if dismissed then return end
		dismissed = true
		Tween(notif, {Size = UDim2.new(0, 310, 0, 0), BackgroundTransparency = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(notifStroke, {Transparency = 1}, 0.2)
		task.wait(0.35)
		notif:Destroy()
	end

	notifClose.MouseButton1Click:Connect(DismissNotif)
	task.delay(duration, function()
		DismissNotif()
	end)

	return notif
end

--================================================
--          LOADING SCREEN
--================================================

local loadScreen = Instance.new("Frame", gui)
loadScreen.Name = "LoadingScreen"
loadScreen.Size = UDim2.new(1, 0, 1, 0)
loadScreen.BackgroundColor3 = Color3.fromRGB(8, 10, 20)
loadScreen.BorderSizePixel = 0
loadScreen.ZIndex = 100

local loadGrad = Instance.new("UIGradient", loadScreen)
loadGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 15, 30)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 10, 20)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 16)),
}
loadGrad.Rotation = 150

for i = 1, 25 do
	local dot = Instance.new("Frame", loadScreen)
	dot.Name = "Particle_" .. i
	local sz = math.random(2, 6)
	dot.Size = UDim2.new(0, sz, 0, sz)
	dot.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, math.random() * 0.9 + 0.05, 0)
	dot.BackgroundColor3 = Color3.fromRGB(55, 130, 240)
	dot.BackgroundTransparency = math.random(60, 90) / 100
	dot.BorderSizePixel = 0
	dot.ZIndex = 101
	Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
	task.spawn(function()
		while dot and dot.Parent do
			local newY = dot.Position.Y.Scale + (math.random() - 0.5) * 0.08
			local newX = dot.Position.X.Scale + (math.random() - 0.5) * 0.04
			newY = math.clamp(newY, 0.05, 0.95)
			newX = math.clamp(newX, 0.05, 0.95)
			Tween(dot, {
				Position = UDim2.new(newX, 0, newY, 0),
				BackgroundTransparency = math.random(50, 90) / 100
			}, math.random(20, 40) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(math.random(20, 40) / 10)
		end
	end)
end

local loadCenter = Instance.new("Frame", loadScreen)
loadCenter.Name = "Center"
loadCenter.Size = UDim2.new(0, 400, 0, 360)
loadCenter.Position = UDim2.new(0.5, -200, 0.5, -180)
loadCenter.BackgroundTransparency = 1
loadCenter.ZIndex = 102

-- ============ GLOBE / EARTH ANIMATION ============
local globeContainer = Instance.new("Frame", loadCenter)
globeContainer.Name = "GlobeContainer"
globeContainer.Size = UDim2.new(0, 90, 0, 90)
globeContainer.Position = UDim2.new(0.5, -45, 0, 10)
globeContainer.BackgroundTransparency = 1
globeContainer.ZIndex = 103

local globe = Instance.new("Frame", globeContainer)
globe.Name = "Globe"
globe.Size = UDim2.new(1, 0, 1, 0)
globe.BackgroundColor3 = Color3.fromRGB(20, 60, 140)
globe.BorderSizePixel = 0
globe.ZIndex = 103
globe.ClipsDescendants = true
Instance.new("UICorner", globe).CornerRadius = UDim.new(1, 0)

local globeStroke = Instance.new("UIStroke", globe)
globeStroke.Color = Color3.fromRGB(55, 130, 240)
globeStroke.Thickness = 2
globeStroke.Transparency = 0.3

local globeGrad = Instance.new("UIGradient", globe)
globeGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 90, 180)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(20, 60, 140)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 30, 80)),
}
globeGrad.Rotation = 135

local continents = {
	{x = 0.15, y = 0.2, w = 22, h = 28, color = Color3.fromRGB(40, 160, 80)},
	{x = 0.45, y = 0.15, w = 16, h = 20, color = Color3.fromRGB(45, 170, 85)},
	{x = 0.55, y = 0.25, w = 24, h = 30, color = Color3.fromRGB(38, 155, 75)},
	{x = 0.7, y = 0.18, w = 28, h = 22, color = Color3.fromRGB(42, 165, 82)},
	{x = 0.75, y = 0.6, w = 18, h = 14, color = Color3.fromRGB(48, 175, 90)},
	{x = 0.2, y = 0.55, w = 14, h = 18, color = Color3.fromRGB(36, 150, 72)},
}

local continentFrames = {}
for _, c in ipairs(continents) do
	local cont = Instance.new("Frame", globe)
	cont.Size = UDim2.new(0, c.w, 0, c.h)
	cont.Position = UDim2.new(c.x, 0, c.y, 0)
	cont.BackgroundColor3 = c.color
	cont.BorderSizePixel = 0
	cont.ZIndex = 104
	Instance.new("UICorner", cont).CornerRadius = UDim.new(0, 4)
	table.insert(continentFrames, cont)
end

task.spawn(function()
	while globe and globe.Parent do
		for _, cont in ipairs(continentFrames) do
			local currentX = cont.Position.X.Scale
			local newX = currentX + 0.005
			if newX > 1.1 then newX = -0.3 end
			cont.Position = UDim2.new(newX, 0, cont.Position.Y.Scale, 0)
		end
		task.wait(0.05)
	end
end)

local globeGlow = Instance.new("Frame", globeContainer)
globeGlow.Name = "GlobeGlow"
globeGlow.Size = UDim2.new(1, 16, 1, 16)
globeGlow.Position = UDim2.new(0, -8, 0, -8)
globeGlow.BackgroundColor3 = Color3.fromRGB(55, 130, 240)
globeGlow.BackgroundTransparency = 0.85
globeGlow.BorderSizePixel = 0
globeGlow.ZIndex = 102
Instance.new("UICorner", globeGlow).CornerRadius = UDim.new(1, 0)

task.spawn(function()
	while globeGlow and globeGlow.Parent do
		TweenWait(globeGlow, {BackgroundTransparency = 0.7, Size = UDim2.new(1, 22, 1, 22), Position = UDim2.new(0, -11, 0, -11)}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenWait(globeGlow, {BackgroundTransparency = 0.9, Size = UDim2.new(1, 16, 1, 16), Position = UDim2.new(0, -8, 0, -8)}, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end)

-- ============ BOOK ANIMATION ============
local bookContainer = Instance.new("Frame", loadCenter)
bookContainer.Name = "BookContainer"
bookContainer.Size = UDim2.new(0, 160, 0, 120)
bookContainer.Position = UDim2.new(0.5, -80, 0, 115)
bookContainer.BackgroundTransparency = 1
bookContainer.ZIndex = 103

local bookSpine = Instance.new("Frame", bookContainer)
bookSpine.Name = "Spine"
bookSpine.Size = UDim2.new(0, 8, 0, 100)
bookSpine.Position = UDim2.new(0.5, -4, 0, 10)
bookSpine.BackgroundColor3 = Color3.fromRGB(45, 35, 25)
bookSpine.BorderSizePixel = 0
bookSpine.ZIndex = 106
Instance.new("UICorner", bookSpine).CornerRadius = UDim.new(0, 2)

local bookLeft = Instance.new("Frame", bookContainer)
bookLeft.Name = "LeftPage"
bookLeft.Size = UDim2.new(0, 70, 0, 96)
bookLeft.Position = UDim2.new(0.5, -74, 0, 12)
bookLeft.BackgroundColor3 = Color3.fromRGB(180, 160, 130)
bookLeft.BorderSizePixel = 0
bookLeft.ZIndex = 105
bookLeft.ClipsDescendants = true
Instance.new("UICorner", bookLeft).CornerRadius = UDim.new(0, 4)

local leftGrad = Instance.new("UIGradient", bookLeft)
leftGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 185, 155)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(165, 148, 120)),
}
leftGrad.Rotation = 0

for li = 1, 5 do
	local line = Instance.new("Frame", bookLeft)
	line.Size = UDim2.new(0, math.random(30, 55), 0, 2)
	line.Position = UDim2.new(0, 8, 0, 14 + (li - 1) * 14)
	line.BackgroundColor3 = Color3.fromRGB(120, 105, 85)
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel = 0
	line.ZIndex = 106
	Instance.new("UICorner", line).CornerRadius = UDim.new(0, 1)
end

local bookRight = Instance.new("Frame", bookContainer)
bookRight.Name = "RightPage"
bookRight.Size = UDim2.new(0, 70, 0, 96)
bookRight.Position = UDim2.new(0.5, 4, 0, 12)
bookRight.BackgroundColor3 = Color3.fromRGB(195, 180, 150)
bookRight.BorderSizePixel = 0
bookRight.ZIndex = 105
bookRight.ClipsDescendants = true
Instance.new("UICorner", bookRight).CornerRadius = UDim.new(0, 4)

local rightGrad = Instance.new("UIGradient", bookRight)
rightGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(175, 158, 128)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 195, 168)),
}
rightGrad.Rotation = 0

for li = 1, 5 do
	local line = Instance.new("Frame", bookRight)
	line.Size = UDim2.new(0, math.random(30, 55), 0, 2)
	line.Position = UDim2.new(0, 8, 0, 14 + (li - 1) * 14)
	line.BackgroundColor3 = Color3.fromRGB(120, 105, 85)
	line.BackgroundTransparency = 0.5
	line.BorderSizePixel = 0
	line.ZIndex = 106
	Instance.new("UICorner", line).CornerRadius = UDim.new(0, 1)
end

local flipPage = Instance.new("Frame", bookContainer)
flipPage.Name = "FlipPage"
flipPage.Size = UDim2.new(0, 70, 0, 96)
flipPage.Position = UDim2.new(0.5, 4, 0, 12)
flipPage.BackgroundColor3 = Color3.fromRGB(220, 210, 185)
flipPage.BorderSizePixel = 0
flipPage.ZIndex = 107
flipPage.ClipsDescendants = true
Instance.new("UICorner", flipPage).CornerRadius = UDim.new(0, 4)

task.spawn(function()
	while flipPage and flipPage.Parent do
		flipPage.Position = UDim2.new(0.5, 4, 0, 12)
		flipPage.Size = UDim2.new(0, 70, 0, 96)
		flipPage.BackgroundColor3 = Color3.fromRGB(220, 210, 185)
		flipPage.BackgroundTransparency = 0

		task.wait(0.8)

		TweenWait(flipPage, {Size = UDim2.new(0, 2, 0, 96), Position = UDim2.new(0.5, -1, 0, 12)}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		flipPage.Position = UDim2.new(0.5, -74, 0, 12)
		flipPage.Size = UDim2.new(0, 2, 0, 96)
		flipPage.BackgroundColor3 = Color3.fromRGB(210, 198, 172)

		TweenWait(flipPage, {Size = UDim2.new(0, 70, 0, 96)}, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		task.wait(0.6)

		TweenWait(flipPage, {BackgroundTransparency = 1}, 0.3)
		task.wait(0.3)
	end
end)

local bookShadow = Instance.new("Frame", bookContainer)
bookShadow.Name = "BookShadow"
bookShadow.Size = UDim2.new(0, 150, 0, 8)
bookShadow.Position = UDim2.new(0.5, -75, 1, -12)
bookShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bookShadow.BackgroundTransparency = 0.7
bookShadow.BorderSizePixel = 0
bookShadow.ZIndex = 102
Instance.new("UICorner", bookShadow).CornerRadius = UDim.new(1, 0)

-- ============ TITLE TEXT ============
local loadTitle = Instance.new("TextLabel", loadCenter)
loadTitle.Name = "Title"
loadTitle.Size = UDim2.new(1, 0, 0, 36)
loadTitle.Position = UDim2.new(0, 0, 0, 248)
loadTitle.BackgroundTransparency = 1
loadTitle.Text = "KBBI"
loadTitle.Font = Enum.Font.GothamBlack
loadTitle.TextSize = 36
loadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
loadTitle.ZIndex = 103

local loadSubtitle = Instance.new("TextLabel", loadCenter)
loadSubtitle.Name = "Subtitle"
loadSubtitle.Size = UDim2.new(1, 0, 0, 20)
loadSubtitle.Position = UDim2.new(0, 0, 0, 284)
loadSubtitle.BackgroundTransparency = 1
loadSubtitle.Text = "by.Sobing4413"
loadSubtitle.Font = Enum.Font.GothamMedium
loadSubtitle.TextSize = 16
loadSubtitle.TextColor3 = Color3.fromRGB(55, 130, 240)
loadSubtitle.ZIndex = 103

local loadBarBg = Instance.new("Frame", loadCenter)
loadBarBg.Name = "LoadBarBg"
loadBarBg.Size = UDim2.new(0, 240, 0, 4)
loadBarBg.Position = UDim2.new(0.5, -120, 0, 318)
loadBarBg.BackgroundColor3 = Color3.fromRGB(30, 35, 55)
loadBarBg.BorderSizePixel = 0
loadBarBg.ZIndex = 103
Instance.new("UICorner", loadBarBg).CornerRadius = UDim.new(1, 0)

local loadBar = Instance.new("Frame", loadBarBg)
loadBar.Name = "LoadBar"
loadBar.Size = UDim2.new(0, 0, 1, 0)
loadBar.BackgroundColor3 = Color3.fromRGB(55, 130, 240)
loadBar.BorderSizePixel = 0
loadBar.ZIndex = 104
Instance.new("UICorner", loadBar).CornerRadius = UDim.new(1, 0)

local loadBarGlow = Instance.new("UIGradient", loadBar)
loadBarGlow.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 130, 240)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 130, 240)),
}

local loadStatus = Instance.new("TextLabel", loadCenter)
loadStatus.Name = "LoadStatus"
loadStatus.Size = UDim2.new(1, 0, 0, 16)
loadStatus.Position = UDim2.new(0, 0, 0, 330)
loadStatus.BackgroundTransparency = 1
loadStatus.Text = "Memuat kamus..."
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 11
loadStatus.TextColor3 = Color3.fromRGB(120, 140, 180)
loadStatus.ZIndex = 103

-- ============ LOADING ENTRANCE ANIMATION ============
loadTitle.TextTransparency = 1
loadSubtitle.TextTransparency = 1
loadBarBg.BackgroundTransparency = 1
loadBar.BackgroundTransparency = 1
loadStatus.TextTransparency = 1
globeContainer.Size = UDim2.new(0, 0, 0, 0)
globeContainer.Position = UDim2.new(0.5, 0, 0, 55)
bookContainer.Size = UDim2.new(0, 0, 0, 0)
bookContainer.Position = UDim2.new(0.5, 0, 0, 175)

task.spawn(function()
	task.wait(0.3)

	Tween(globeContainer, {Size = UDim2.new(0, 90, 0, 90), Position = UDim2.new(0.5, -45, 0, 10)}, 0.6, Enum.EasingStyle.Back)
	task.wait(0.3)

	Tween(bookContainer, {Size = UDim2.new(0, 160, 0, 120), Position = UDim2.new(0.5, -80, 0, 115)}, 0.6, Enum.EasingStyle.Back)
	task.wait(0.3)

	Tween(loadTitle, {TextTransparency = 0}, 0.5)
	task.wait(0.15)
	Tween(loadSubtitle, {TextTransparency = 0}, 0.5)
	task.wait(0.2)

	Tween(loadBarBg, {BackgroundTransparency = 0}, 0.3)
	Tween(loadBar, {BackgroundTransparency = 0}, 0.3)
	Tween(loadStatus, {TextTransparency = 0}, 0.3)
end)

--================================================
--     MAIN UI (Hidden initially, shown after load)
--================================================

local shadow = Instance.new("ImageLabel", gui)
shadow.Name = "Shadow"
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 1
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.Size = UDim2.new(0, 720 + 40, 0, 420 + 40)
shadow.Position = UDim2.new(0.5, -380, 0.5, -230)
shadow.ZIndex = 1

local frame = Instance.new("Frame", gui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 720, 0, 420)
frame.Position = UDim2.new(0.5, -360, 0.5, -210)
frame.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Visible = false
frame.ZIndex = 2

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", frame)
mainStroke.Color = CurrentTheme.stroke
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.15

local mainGrad = Instance.new("UIGradient", frame)
mainGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, CurrentTheme.gradTop),
	ColorSequenceKeypoint.new(1, CurrentTheme.gradBot)
}
mainGrad.Rotation = 145

frame:GetPropertyChangedSignal("Position"):Connect(function()
	shadow.Position = UDim2.new(
		frame.Position.X.Scale,
		frame.Position.X.Offset - 20,
		frame.Position.Y.Scale,
		frame.Position.Y.Offset - 20
	)
end)

--------------------------------------------------
-- TOP BAR
--------------------------------------------------

local topBar = Instance.new("Frame", frame)
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 48)
topBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topBar.BackgroundTransparency = 0.5
topBar.BorderSizePixel = 0
topBar.ZIndex = 5

local topBarCorner = Instance.new("UICorner", topBar)
topBarCorner.CornerRadius = UDim.new(0, 16)

local topBarFill = Instance.new("Frame", topBar)
topBarFill.Size = UDim2.new(1, 0, 0, 18)
topBarFill.Position = UDim2.new(0, 0, 1, -18)
topBarFill.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
topBarFill.BackgroundTransparency = 0.5
topBarFill.BorderSizePixel = 0
topBarFill.ZIndex = 5

local accentLine = Instance.new("Frame", frame)
accentLine.Name = "AccentLine"
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 0, 48)
accentLine.BackgroundColor3 = CurrentTheme.accent
accentLine.BorderSizePixel = 0
accentLine.ZIndex = 6

local accentGlowGrad = Instance.new("UIGradient", accentLine)
accentGlowGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.15, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
}
accentGlowGrad.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.9),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0.9)
}

local titleIconGlow = Instance.new("Frame", topBar)
titleIconGlow.Name = "TitleIconGlow"
titleIconGlow.Size = UDim2.new(0, 38, 0, 38)
titleIconGlow.Position = UDim2.new(0, 9, 0.5, -19)
titleIconGlow.BackgroundColor3 = CurrentTheme.accent
titleIconGlow.BackgroundTransparency = 0.8
titleIconGlow.BorderSizePixel = 0
titleIconGlow.ZIndex = 5
Instance.new("UICorner", titleIconGlow).CornerRadius = UDim.new(0, 10)

local titleIcon = Instance.new("TextLabel", topBar)
titleIcon.Name = "TitleIcon"
titleIcon.Size = UDim2.new(0, 32, 0, 32)
titleIcon.Position = UDim2.new(0, 12, 0.5, -16)
titleIcon.BackgroundColor3 = CurrentTheme.accent
titleIcon.Text = "K"
titleIcon.Font = Enum.Font.GothamBlack
titleIcon.TextSize = 17
titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
titleIcon.BorderSizePixel = 0
titleIcon.ZIndex = 6
Instance.new("UICorner", titleIcon).CornerRadius = UDim.new(0, 8)

local titleIconStroke = Instance.new("UIStroke", titleIcon)
titleIconStroke.Color = CurrentTheme.accentLight
titleIconStroke.Thickness = 1
titleIconStroke.Transparency = 0.5

local title = Instance.new("TextLabel", topBar)
title.Name = "Title"
title.Size = UDim2.new(0, 280, 0, 22)
title.Position = UDim2.new(0, 52, 0, 6)
title.BackgroundTransparency = 1
title.Text = "KBBI SAMBUNG KATA"
title.Font = Enum.Font.GothamBlack
title.TextSize = 17
title.TextColor3 = CurrentTheme.textPrimary
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 6

local subtitle = Instance.new("TextLabel", topBar)
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0, 280, 0, 14)
subtitle.Position = UDim2.new(0, 52, 0, 28)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by.Sobing4413 • v2 Strategy+"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 10
subtitle.TextColor3 = CurrentTheme.textMuted
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.ZIndex = 6

--------------------------------------------------
-- WINDOW CONTROL BUTTONS
--------------------------------------------------

local function CreateControlBtn(name, text, hoverColor, posX, textSz)
	local btn = Instance.new("TextButton", topBar)
	btn.Name = name
	btn.Size = UDim2.new(0, 30, 0, 30)
	btn.Position = UDim2.new(1, posX, 0.5, -15)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BackgroundTransparency = 0.92
	btn.Text = text
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = textSz or 14
	btn.TextColor3 = Color3.fromRGB(180, 180, 190)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.ZIndex = 6
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseEnter:Connect(function()
		Tween(btn, {BackgroundColor3 = hoverColor, BackgroundTransparency = 0.15, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.92, TextColor3 = Color3.fromRGB(180, 180, 190)}, 0.2)
	end)
	return btn
end

local closeBtn = CreateControlBtn("CloseBtn", "✕", Color3.fromRGB(220, 50, 50), -42, 13)
local minimizeBtn = CreateControlBtn("MinimizeBtn", "—", Color3.fromRGB(220, 180, 40), -78, 14)
local themeBtn = CreateControlBtn("ThemeBtn", "◆", CurrentTheme.accent, -114, 12)
local sortBtn = CreateControlBtn("SortBtn", "🧠", Color3.fromRGB(180, 120, 255), -150, 12)
local unloadBtn = CreateControlBtn("UnloadBtn", "⏏", Color3.fromRGB(180, 100, 50), -186, 13)

closeBtn.MouseButton1Click:Connect(function()
	SendNotification("info", "Menutup GUI", "KBBI sedang ditutup...", 2)
	task.wait(0.3)
	Tween(frame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	Tween(shadow, {ImageTransparency = 1}, 0.3)
	task.wait(0.45)
	gui:Destroy()
end)

local OriginalSize = frame.Size
local OriginalShadowSize = shadow.Size

minimizeBtn.MouseButton1Click:Connect(function()
	if IsMinimized then
		IsMinimized = false
		Tween(frame, {Size = OriginalSize}, 0.35, Enum.EasingStyle.Back)
		Tween(shadow, {Size = OriginalShadowSize, ImageTransparency = 0.5}, 0.35)
		SendNotification("info", "Dipulihkan", "GUI telah dipulihkan ke ukuran semula.", 2)
	else
		IsMinimized = true
		Tween(frame, {Size = UDim2.new(0, 720, 0, 48)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(shadow, {Size = UDim2.new(0, 760, 0, 88), ImageTransparency = 0.7}, 0.35)
		SendNotification("info", "Diminimalkan", "Klik — untuk memulihkan.", 2)
	end
end)

-- Forward declare UpdatePreview
local UpdatePreview

sortBtn.MouseButton1Click:Connect(function()
	if SortMode == "strategy" then
		SortMode = "difficulty"
		SendNotification("info", "Mode: Difficulty", "Urutan berdasarkan tingkat kesulitan huruf akhir (lama).", 2.5)
	else
		SortMode = "strategy"
		SendNotification("strategy", "Mode: Strategy+ 🧠", "Kata akhiran x/z/q/v/f di PALING ATAS! Banyak opsi killer muncul. Musuh bakal stuck!", 3.5)
	end
	if UpdatePreview then UpdatePreview() end
end)

unloadBtn.MouseButton1Click:Connect(function()
	if not ScriptActive then return end
	ScriptActive = false
	SendNotification("unloaded", "Script Di-unload", "KBBI telah di-unload. GUI akan ditutup.", 3)
	task.wait(1)
	Tween(frame, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	Tween(shadow, {ImageTransparency = 1}, 0.4)
	task.wait(0.6)
	gui:Destroy()
	print("[KBBI v2] Script unloaded by user.")
end)

--------------------------------------------------
-- THEME SELECTOR PANEL
--------------------------------------------------

local themePanel = Instance.new("Frame", gui)
themePanel.Name = "ThemePanel"
themePanel.Size = UDim2.new(0, 200, 0, 0)
themePanel.Position = UDim2.new(0.5, 210, 0.5, -210)
themePanel.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
themePanel.BorderSizePixel = 0
themePanel.Visible = false
themePanel.ZIndex = 50
themePanel.ClipsDescendants = true
Instance.new("UICorner", themePanel).CornerRadius = UDim.new(0, 12)

local themePanelStroke = Instance.new("UIStroke", themePanel)
themePanelStroke.Color = Color3.fromRGB(45, 48, 60)
themePanelStroke.Thickness = 1

local themePanelHeader = Instance.new("TextLabel", themePanel)
themePanelHeader.Name = "Header"
themePanelHeader.Size = UDim2.new(1, -16, 0, 24)
themePanelHeader.Position = UDim2.new(0, 8, 0, 6)
themePanelHeader.BackgroundTransparency = 1
themePanelHeader.Text = "🎨 PILIH TEMA"
themePanelHeader.Font = Enum.Font.GothamBlack
themePanelHeader.TextSize = 10
themePanelHeader.TextColor3 = Color3.fromRGB(150, 155, 175)
themePanelHeader.TextXAlignment = Enum.TextXAlignment.Left
themePanelHeader.ZIndex = 51

local ThemeElements = {}

local scroll, prefixLabel, statusLabel, countLabel, strategyLabel, dangerLabel

local function ApplyTheme(themeName)
	CurrentThemeName = themeName
	CurrentTheme = Themes[themeName]

	mainGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, CurrentTheme.gradTop),
		ColorSequenceKeypoint.new(1, CurrentTheme.gradBot)
	}
	mainStroke.Color = CurrentTheme.stroke
	accentLine.BackgroundColor3 = CurrentTheme.accent
	titleIcon.BackgroundColor3 = CurrentTheme.accent
	titleIconGlow.BackgroundColor3 = CurrentTheme.accent
	titleIconStroke.Color = CurrentTheme.accentLight
	title.TextColor3 = CurrentTheme.textPrimary
	subtitle.TextColor3 = CurrentTheme.textMuted

	for _, data in ipairs(ThemeElements) do
		if data.type == "button" then
			data.obj.BackgroundColor3 = CurrentTheme.cardBg
			local s = data.obj:FindFirstChildWhichIsA("UIStroke")
			if s then s.Color = CurrentTheme.stroke end
			local b = data.obj:FindFirstChild("Badge")
			if b then b.BackgroundColor3 = CurrentTheme.accent end
		end
	end

	if scroll then scroll.ScrollBarImageColor3 = CurrentTheme.scrollBar end
	if prefixLabel then prefixLabel.TextColor3 = CurrentTheme.accent end
	if statusLabel then statusLabel.TextColor3 = CurrentTheme.accentLight end
	if countLabel then countLabel.TextColor3 = CurrentTheme.textSecondary end

	SendNotification("info", "Tema Diubah", "Tema berhasil diubah ke " .. themeName .. ".", 2.5)
end

local themeOrder = {"Merah", "Hijau", "Biru", "Ungu", "Abu-abu"}
local themeIcons = {
	Merah = "🔴",
	Hijau = "🟢",
	Biru = "🔵",
	Ungu = "🟣",
	["Abu-abu"] = "⚪",
}

local themeBtnList = {}
for idx, name in ipairs(themeOrder) do
	local theme = Themes[name]
	local optBtn = Instance.new("TextButton", themePanel)
	optBtn.Name = "Theme_" .. name
	optBtn.Size = UDim2.new(1, -16, 0, 36)
	optBtn.Position = UDim2.new(0, 8, 0, 30 + (idx - 1) * 40)
	optBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
	optBtn.Text = ""
	optBtn.BorderSizePixel = 0
	optBtn.AutoButtonColor = false
	optBtn.ZIndex = 51
	Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 8)

	local colorDot = Instance.new("Frame", optBtn)
	colorDot.Size = UDim2.new(0, 16, 0, 16)
	colorDot.Position = UDim2.new(0, 10, 0.5, -8)
	colorDot.BackgroundColor3 = theme.accent
	colorDot.BorderSizePixel = 0
	colorDot.ZIndex = 52
	Instance.new("UICorner", colorDot).CornerRadius = UDim.new(1, 0)

	local dotGlow = Instance.new("UIStroke", colorDot)
	dotGlow.Color = theme.accent
	dotGlow.Thickness = 2
	dotGlow.Transparency = 0.6

	local nameLabel = Instance.new("TextLabel", optBtn)
	nameLabel.Size = UDim2.new(1, -50, 1, 0)
	nameLabel.Position = UDim2.new(0, 34, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 52

	local check = Instance.new("TextLabel", optBtn)
	check.Name = "Check"
	check.Size = UDim2.new(0, 20, 0, 20)
	check.Position = UDim2.new(1, -28, 0.5, -10)
	check.BackgroundTransparency = 1
	check.Text = (name == CurrentThemeName) and "✓" or ""
	check.Font = Enum.Font.GothamBold
	check.TextSize = 14
	check.TextColor3 = theme.accent
	check.ZIndex = 52

	optBtn.MouseEnter:Connect(function()
		Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(40, 42, 55)}, 0.15)
	end)
	optBtn.MouseLeave:Connect(function()
		Tween(optBtn, {BackgroundColor3 = Color3.fromRGB(28, 30, 40)}, 0.15)
	end)

	optBtn.MouseButton1Click:Connect(function()
		ApplyTheme(name)
		for _, b in ipairs(themeBtnList) do
			local c = b:FindFirstChild("Check")
			if c then c.Text = "" end
		end
		check.Text = "✓"
		task.wait(0.2)
		Tween(themePanel, {Size = UDim2.new(0, 200, 0, 0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.3)
		themePanel.Visible = false
	end)

	table.insert(themeBtnList, optBtn)
end

local themePanelFullHeight = 30 + #themeOrder * 40 + 8

themeBtn.MouseButton1Click:Connect(function()
	if themePanel.Visible then
		Tween(themePanel, {Size = UDim2.new(0, 200, 0, 0)}, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.3)
		themePanel.Visible = false
	else
		themePanel.Size = UDim2.new(0, 200, 0, 0)
		themePanel.Visible = true
		Tween(themePanel, {Size = UDim2.new(0, 200, 0, themePanelFullHeight)}, 0.3, Enum.EasingStyle.Back)
	end
end)

--------------------------------------------------
-- LEFT PANEL
--------------------------------------------------

local leftPanel = Instance.new("Frame", frame)
leftPanel.Name = "LeftPanel"
leftPanel.Size = UDim2.new(0, 220, 1, -60)
leftPanel.Position = UDim2.new(0, 10, 0, 54)
leftPanel.BackgroundColor3 = CurrentTheme.panelBg
leftPanel.BackgroundTransparency = 0.15
leftPanel.BorderSizePixel = 0
leftPanel.ZIndex = 3
Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 12)

local leftStroke = Instance.new("UIStroke", leftPanel)
leftStroke.Color = Color3.fromRGB(35, 38, 48)
leftStroke.Thickness = 1
leftStroke.Transparency = 0.2

local leftPanelGrad = Instance.new("UIGradient", leftPanel)
leftPanelGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 35)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 26)),
}
leftPanelGrad.Rotation = 160

-- Section: Current Prefix
local prefixSection = Instance.new("Frame", leftPanel)
prefixSection.Name = "PrefixSection"
prefixSection.Size = UDim2.new(1, -16, 0, 90)
prefixSection.Position = UDim2.new(0, 8, 0, 8)
prefixSection.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
prefixSection.BorderSizePixel = 0
prefixSection.ZIndex = 4
Instance.new("UICorner", prefixSection).CornerRadius = UDim.new(0, 10)

local prefixSectionStroke = Instance.new("UIStroke", prefixSection)
prefixSectionStroke.Color = Color3.fromRGB(35, 40, 55)
prefixSectionStroke.Thickness = 1
prefixSectionStroke.Transparency = 0.4

local prefixSectionGrad = Instance.new("UIGradient", prefixSection)
prefixSectionGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 25, 40)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 18, 30)),
}
prefixSectionGrad.Rotation = 135

local prefixTitle = Instance.new("TextLabel", prefixSection)
prefixTitle.Size = UDim2.new(1, -12, 0, 16)
prefixTitle.Position = UDim2.new(0, 10, 0, 8)
prefixTitle.BackgroundTransparency = 1
prefixTitle.Text = "🔤 AWALAN HURUF"
prefixTitle.Font = Enum.Font.GothamBold
prefixTitle.TextSize = 9
prefixTitle.TextColor3 = CurrentTheme.textMuted
prefixTitle.TextXAlignment = Enum.TextXAlignment.Left
prefixTitle.ZIndex = 5

prefixLabel = Instance.new("TextLabel", prefixSection)
prefixLabel.Name = "PrefixLabel"
prefixLabel.Size = UDim2.new(0, 80, 0, 48)
prefixLabel.Position = UDim2.new(0, 10, 0, 28)
prefixLabel.BackgroundTransparency = 1
prefixLabel.Text = "—"
prefixLabel.Font = Enum.Font.GothamBlack
prefixLabel.TextSize = 38
prefixLabel.TextColor3 = CurrentTheme.accent
prefixLabel.TextXAlignment = Enum.TextXAlignment.Left
prefixLabel.ZIndex = 5

dangerLabel = Instance.new("TextLabel", prefixSection)
dangerLabel.Name = "DangerLabel"
dangerLabel.Size = UDim2.new(0, 90, 0, 20)
dangerLabel.Position = UDim2.new(1, -98, 0, 12)
dangerLabel.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
dangerLabel.BackgroundTransparency = 0.75
dangerLabel.Text = ""
dangerLabel.Font = Enum.Font.GothamBold
dangerLabel.TextSize = 9
dangerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
dangerLabel.BorderSizePixel = 0
dangerLabel.ZIndex = 6
dangerLabel.Visible = false
Instance.new("UICorner", dangerLabel).CornerRadius = UDim.new(0, 6)

strategyLabel = Instance.new("TextLabel", prefixSection)
strategyLabel.Name = "StrategyLabel"
strategyLabel.Size = UDim2.new(0, 90, 0, 18)
strategyLabel.Position = UDim2.new(1, -98, 0, 56)
strategyLabel.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
strategyLabel.BackgroundTransparency = 0.8
strategyLabel.Text = "🧠 STRATEGY+"
strategyLabel.Font = Enum.Font.GothamBold
strategyLabel.TextSize = 8
strategyLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
strategyLabel.BorderSizePixel = 0
strategyLabel.ZIndex = 6
Instance.new("UICorner", strategyLabel).CornerRadius = UDim.new(0, 5)

-- Section: Status
local statusSection = Instance.new("Frame", leftPanel)
statusSection.Name = "StatusSection"
statusSection.Size = UDim2.new(1, -16, 0, 52)
statusSection.Position = UDim2.new(0, 8, 0, 104)
statusSection.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
statusSection.BorderSizePixel = 0
statusSection.ZIndex = 4
Instance.new("UICorner", statusSection).CornerRadius = UDim.new(0, 8)

local statusSectionStroke = Instance.new("UIStroke", statusSection)
statusSectionStroke.Color = Color3.fromRGB(30, 35, 48)
statusSectionStroke.Thickness = 1
statusSectionStroke.Transparency = 0.5

statusLabel = Instance.new("TextLabel", statusSection)
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -16, 0, 18)
statusLabel.Position = UDim2.new(0, 10, 0, 8)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏳ Memuat kamus..."
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextSize = 11
statusLabel.TextColor3 = CurrentTheme.accentLight
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.ZIndex = 5

countLabel = Instance.new("TextLabel", statusSection)
countLabel.Name = "CountLabel"
countLabel.Size = UDim2.new(1, -16, 0, 16)
countLabel.Position = UDim2.new(0, 10, 0, 28)
countLabel.BackgroundTransparency = 1
countLabel.Text = "Kata ditemukan: 0"
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 11
countLabel.TextColor3 = CurrentTheme.textSecondary
countLabel.TextTransparency = 0.1
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.ZIndex = 5

local divider = Instance.new("Frame", leftPanel)
divider.Size = UDim2.new(1, -24, 0, 1)
divider.Position = UDim2.new(0, 12, 0, 164)
divider.BackgroundColor3 = Color3.fromRGB(40, 42, 52)
divider.BorderSizePixel = 0
divider.ZIndex = 4

local tipsHeader = Instance.new("TextLabel", leftPanel)
tipsHeader.Size = UDim2.new(1, -16, 0, 16)
tipsHeader.Position = UDim2.new(0, 10, 0, 172)
tipsHeader.BackgroundTransparency = 1
tipsHeader.Text = "💡 PANDUAN"
tipsHeader.Font = Enum.Font.GothamBold
tipsHeader.TextSize = 10
tipsHeader.TextColor3 = CurrentTheme.textMuted
tipsHeader.TextXAlignment = Enum.TextXAlignment.Left
tipsHeader.ZIndex = 4

local tips = {
	"Klik kata → auto input",
	"🧠 = strategi+ cerdas ON",
	"💀 = akhiran x/z/q (KILLER)",
	"⚠️ = akhiran v/f/w (BAHAYA)",
	"🟢 = akhiran aman",
	"Banyak opsi killer muncul!",
	"◆ Ganti tema, ⏏ Unload",
}

for i, tip in ipairs(tips) do
	local tipLabel = Instance.new("TextLabel", leftPanel)
	tipLabel.Size = UDim2.new(1, -22, 0, 14)
	tipLabel.Position = UDim2.new(0, 14, 0, 172 + (i * 16))
	tipLabel.BackgroundTransparency = 1
	tipLabel.Text = "› " .. tip
	tipLabel.Font = Enum.Font.Gotham
	tipLabel.TextSize = 10
	tipLabel.TextColor3 = CurrentTheme.textMuted
	tipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tipLabel.TextWrapped = true
	tipLabel.ZIndex = 4
end

local versionBadge = Instance.new("Frame", leftPanel)
versionBadge.Size = UDim2.new(1, -16, 0, 28)
versionBadge.Position = UDim2.new(0, 8, 1, -34)
versionBadge.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
versionBadge.BorderSizePixel = 0
versionBadge.ZIndex = 4
Instance.new("UICorner", versionBadge).CornerRadius = UDim.new(0, 7)

local versionStroke = Instance.new("UIStroke", versionBadge)
versionStroke.Color = Color3.fromRGB(30, 35, 48)
versionStroke.Thickness = 1
versionStroke.Transparency = 0.5

local versionText = Instance.new("TextLabel", versionBadge)
versionText.Size = UDim2.new(1, 0, 1, 0)
versionText.BackgroundTransparency = 1
versionText.Text = "⚡ v2 Strategy+ • KBBI"
versionText.Font = Enum.Font.GothamMedium
versionText.TextSize = 10
versionText.TextColor3 = CurrentTheme.textMuted
versionText.ZIndex = 5

--------------------------------------------------
-- RIGHT PANEL (Word List)
--------------------------------------------------

local rightPanel = Instance.new("Frame", frame)
rightPanel.Name = "RightPanel"
rightPanel.Size = UDim2.new(1, -248, 1, -60)
rightPanel.Position = UDim2.new(0, 238, 0, 54)
rightPanel.BackgroundTransparency = 1
rightPanel.BorderSizePixel = 0
rightPanel.ZIndex = 3

local headerBar = Instance.new("Frame", rightPanel)
headerBar.Name = "HeaderBar"
headerBar.Size = UDim2.new(1, -4, 0, 30)
headerBar.Position = UDim2.new(0, 0, 0, 0)
headerBar.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
headerBar.BackgroundTransparency = 0.2
headerBar.BorderSizePixel = 0
headerBar.ZIndex = 4
Instance.new("UICorner", headerBar).CornerRadius = UDim.new(0, 8)

local headerStroke = Instance.new("UIStroke", headerBar)
headerStroke.Color = Color3.fromRGB(30, 35, 48)
headerStroke.Thickness = 1
headerStroke.Transparency = 0.5

local headerLabel = Instance.new("TextLabel", headerBar)
headerLabel.Size = UDim2.new(1, -12, 1, 0)
headerLabel.Position = UDim2.new(0, 12, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "📋 DAFTAR KATA • 💀=killer ⚠️=bahaya 🟢=aman"
headerLabel.Font = Enum.Font.GothamBlack
headerLabel.TextSize = 10
headerLabel.TextColor3 = CurrentTheme.textMuted
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.ZIndex = 5

scroll = Instance.new("ScrollingFrame", rightPanel)
scroll.Name = "WordScroll"
scroll.Size = UDim2.new(1, -2, 1, -36)
scroll.Position = UDim2.new(0, 0, 0, 34)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = CurrentTheme.scrollBar
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.BorderSizePixel = 0
scroll.ZIndex = 4

local scrollLayout = Instance.new("UIListLayout", scroll)
scrollLayout.Padding = UDim.new(0, 4)

scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, scrollLayout.AbsoluteContentSize.Y + 8)
end)

--------------------------------------------------
-- WORD BUTTONS (50 buttons instead of 30)
--------------------------------------------------

local buttons = {}
local buttonIndicators = {}

local function CreateButton(index)
	local btn = Instance.new("TextButton")
	btn.Name = "WordBtn_" .. index
	btn.Size = UDim2.new(1, -6, 0, 32)
	btn.Text = ""
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = CurrentTheme.textPrimary
	btn.BackgroundColor3 = (index % 2 == 0) and CurrentTheme.cardBgAlt or CurrentTheme.cardBg
	btn.BorderSizePixel = 0
	btn.Parent = scroll
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.AutoButtonColor = false
	btn.ZIndex = 5

	local padding = Instance.new("UIPadding", btn)
	padding.PaddingLeft = UDim.new(0, 12)

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)

	local btnStroke = Instance.new("UIStroke", btn)
	btnStroke.Color = CurrentTheme.stroke
	btnStroke.Thickness = 1
	btnStroke.Transparency = 0.5

	-- Strategy indicator (right side)
	local indicator = Instance.new("TextLabel", btn)
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 70, 0, 18)
	indicator.Position = UDim2.new(1, -100, 0.5, -9)
	indicator.BackgroundColor3 = Color3.fromRGB(40, 200, 100)
	indicator.BackgroundTransparency = 0.75
	indicator.Text = ""
	indicator.Font = Enum.Font.GothamBold
	indicator.TextSize = 8
	indicator.TextColor3 = Color3.fromRGB(255, 255, 255)
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 6
	indicator.Visible = false
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 5)

	-- Number badge
	local badge = Instance.new("TextLabel", btn)
	badge.Name = "Badge"
	badge.Size = UDim2.new(0, 22, 0, 18)
	badge.Position = UDim2.new(1, -28, 0.5, -9)
	badge.BackgroundColor3 = CurrentTheme.accent
	badge.BackgroundTransparency = 0.7
	badge.Text = tostring(index)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 9
	badge.TextColor3 = CurrentTheme.textPrimary
	badge.TextTransparency = 0.2
	badge.BorderSizePixel = 0
	badge.ZIndex = 6
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)

	btn.MouseEnter:Connect(function()
		Tween(btn, {BackgroundColor3 = CurrentTheme.cardHover}, 0.12)
		Tween(btnStroke, {Color = CurrentTheme.accentLight, Transparency = 0.15}, 0.12)
		Tween(badge, {BackgroundTransparency = 0.25}, 0.12)
	end)

	btn.MouseLeave:Connect(function()
		local bg = (index % 2 == 0) and CurrentTheme.cardBgAlt or CurrentTheme.cardBg
		Tween(btn, {BackgroundColor3 = bg}, 0.12)
		Tween(btnStroke, {Color = CurrentTheme.stroke, Transparency = 0.5}, 0.12)
		Tween(badge, {BackgroundTransparency = 0.7}, 0.12)
	end)

	table.insert(buttons, btn)
	table.insert(buttonIndicators, indicator)
	table.insert(ThemeElements, {type = "button", obj = btn, index = index})
end

-- CREATE 50 BUTTONS (was 30)
for i = 1, MAX_BUTTONS do
	CreateButton(i)
end

--------------------------------------------------
-- LOAD WORDLIST
--------------------------------------------------

task.spawn(function()
	local function SetLoadProgress(pct, text)
		if loadBar and loadBar.Parent then
			Tween(loadBar, {Size = UDim2.new(pct, 0, 1, 0)}, 0.4)
		end
		if loadStatus and loadStatus.Parent then
			loadStatus.Text = text
		end
	end

	SetLoadProgress(0.1, "Menghubungkan ke server...")
	task.wait(0.5)

	local text
	local ok, res = pcall(function()
		return game:HttpGet("https://raw.githubusercontent.com/SOBING4413/sambungkata/main/dependescis/kbbi.txt")
	end)

	if ok then
		text = res
		SetLoadProgress(0.4, "Memproses kamus KBBI...")
	else
		warn("Failed to load github wordlist")
		text = ""
		SetLoadProgress(0.4, "Gagal memuat, menggunakan cache...")
	end

	task.wait(0.3)

	local wordCount = 0
	for word in string.gmatch(text, "[^\r\n]+") do
		local w = string.lower(word):gsub("%s", "")
		if string.match(w, "^[a-z]+$") and #w >= 3 then
			local p1 = string.sub(w, 1, 1)
			local p2 = string.sub(w, 1, 2)
			Prefix1[p1] = Prefix1[p1] or {}
			table.insert(Prefix1[p1], w)
			Prefix2[p2] = Prefix2[p2] or {}
			table.insert(Prefix2[p2], w)
			wordCount = wordCount + 1
		end
	end

	-- Build LetterWordCount: how many words START with each letter
	for letter = string.byte("a"), string.byte("z") do
		local ch = string.char(letter)
		LetterWordCount[ch] = Prefix1[ch] and #Prefix1[ch] or 0
	end

	SetLoadProgress(0.8, "Mengindeks " .. wordCount .. " kata + strategi+...")
	task.wait(0.4)

	SetLoadProgress(1.0, "Selesai! Memuat antarmuka...")
	task.wait(0.6)

	Ready = true
	statusLabel.Text = "✅ " .. wordCount .. " kata dimuat"

	-- ============ TRANSITION: Loading → Main UI ============
	Tween(loadTitle, {TextTransparency = 1}, 0.4)
	Tween(loadSubtitle, {TextTransparency = 1}, 0.4)
	Tween(loadBarBg, {BackgroundTransparency = 1}, 0.3)
	Tween(loadBar, {BackgroundTransparency = 1}, 0.3)
	Tween(loadStatus, {TextTransparency = 1}, 0.3)
	Tween(globeContainer, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0, 55)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	Tween(bookContainer, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0, 175)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In)

	for _, child in ipairs(loadScreen:GetChildren()) do
		if child.Name:find("Particle") then
			Tween(child, {BackgroundTransparency = 1}, 0.3)
		end
	end

	task.wait(0.5)
	Tween(loadScreen, {BackgroundTransparency = 1}, 0.5)
	task.wait(0.2)

	frame.Visible = true
	frame.Size = UDim2.new(0, 0, 0, 0)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.ImageTransparency = 1

	Tween(frame, {Size = UDim2.new(0, 720, 0, 420), Position = UDim2.new(0.5, -360, 0.5, -210)}, 0.5, Enum.EasingStyle.Back)
	Tween(shadow, {ImageTransparency = 0.5}, 0.5)

	task.wait(0.6)
	loadScreen:Destroy()

	SendNotification("loaded", "Script Berhasil Dimuat!", "KBBI v2 Strategy+ siap. " .. wordCount .. " kata tersedia. 50 opsi per halaman!", 4)

	-- Print letter stats for debug
	local deadLetters = {}
	for letter = string.byte("a"), string.byte("z") do
		local ch = string.char(letter)
		local cnt = LetterWordCount[ch] or 0
		if cnt <= 5 then
			table.insert(deadLetters, ch:upper() .. "(" .. cnt .. ")")
		end
	end
	if #deadLetters > 0 then
		SendNotification("strategy", "Huruf Mematikan 💀", "Huruf dengan sedikit kata: " .. table.concat(deadLetters, ", "), 6)
	end

	print("[KBBI v2] Loaded " .. wordCount .. " words with Strategy+ engine!")
end)

--------------------------------------------------
-- STRATEGY+ ENGINE (OPTIMIZED)
--
-- Sorting priorities for Strategy mode:
-- 1. KILLER_SCORE_OVERRIDE: manual boost for x, z, q, v, f, w, y, etc.
-- 2. Dynamic score: 10000 - LetterWordCount[lastChar]
-- 3. Final score = max(override, dynamic) so killer letters ALWAYS on top
-- 4. Tiebreaker: shorter words first (faster to type)
--
-- This ensures ALL words ending in x/z/q appear at the very top,
-- not just 1, but ALL of them grouped together.
--------------------------------------------------

local function GetEndingDangerScore(word)
	local lastChar = string.sub(word, -1)
	local opponentOptions = LetterWordCount[lastChar] or 0

	-- Check manual override first (for guaranteed killer letters)
	local overrideScore = KILLER_SCORE_OVERRIDE[lastChar] or 0

	-- Dynamic score based on actual word count
	local dynamicScore = 0
	if opponentOptions == 0 then
		dynamicScore = 99999
	else
		dynamicScore = 10000 - opponentOptions
	end

	-- Return the HIGHER of the two, ensuring killer letters always win
	return math.max(overrideScore, dynamicScore)
end

-- Get danger level category for display (ENHANCED with more tiers)
local function GetDangerCategory(word)
	local lastChar = string.sub(word, -1)
	local cnt = LetterWordCount[lastChar] or 0

	-- Check if it's a manually-defined killer letter
	local isKillerOverride = KILLER_SCORE_OVERRIDE[lastChar] and KILLER_SCORE_OVERRIDE[lastChar] >= 70000

	if cnt == 0 then
		return "impossible", "☠️ IMPOSSIBLE", Color3.fromRGB(255, 0, 0)
	elseif cnt <= 3 or isKillerOverride then
		return "killer", "💀 KILLER", Color3.fromRGB(255, 40, 40)
	elseif cnt <= 10 or (KILLER_SCORE_OVERRIDE[lastChar] and KILLER_SCORE_OVERRIDE[lastChar] >= 40000) then
		return "danger", "⚠️ BAHAYA", Color3.fromRGB(255, 150, 30)
	elseif cnt <= 30 or (KILLER_SCORE_OVERRIDE[lastChar] and KILLER_SCORE_OVERRIDE[lastChar] >= 20000) then
		return "risky", "🟡 RISKY", Color3.fromRGB(240, 220, 40)
	elseif cnt <= 100 then
		return "normal", "🔵 NORMAL", Color3.fromRGB(100, 160, 240)
	else
		return "safe", "🟢 AMAN", Color3.fromRGB(40, 200, 100)
	end
end

--------------------------------------------------
-- LETTER DIFFICULTY (old mode, unchanged)
--------------------------------------------------

local HardLetters = {
	q = 10, x = 9, z = 8, v = 7, f = 6, w = 5, y = 4, k = 3, b = 2, p = 1
}

local function Difficulty(word)
	local last = string.sub(word, -1)
	return HardLetters[last] or 0
end

--------------------------------------------------
-- FIND OPTIONS (OPTIMIZED)
--------------------------------------------------

local function FindOptions(prefix)
	prefix = string.lower(prefix):gsub("[^a-z]", "")

	local list
	if #prefix >= 2 then
		list = Prefix2[string.sub(prefix, 1, 2)]
	else
		list = Prefix1[string.sub(prefix, 1, 1)]
	end

	if not list then return {} end

	local filtered = {}
	local used = {}

	for _, word in ipairs(list) do
		if string.sub(word, 1, #prefix) == prefix then
			if not used[word] then
				used[word] = true
				table.insert(filtered, word)
			end
		end
	end

	if #filtered == 0 then return {} end

	-- Sort based on current mode
	if SortMode == "strategy" then
		-- ============================================================
		-- STRATEGY+ SORT (OPTIMIZED)
		-- 
		-- Priority order:
		-- 1. Words ending in x, z, q (KILLER_SCORE >= 90000) → PALING ATAS
		-- 2. Words ending in v, f (KILLER_SCORE >= 60000) → ATAS
		-- 3. Words ending in w, y (KILLER_SCORE >= 40000) → MENENGAH ATAS
		-- 4. Words ending in rare letters (dynamic low count) → MENENGAH
		-- 5. Words ending in common letters → BAWAH
		--
		-- ALL words with killer endings show up, not just 1!
		-- ============================================================
		table.sort(filtered, function(a, b)
			local scoreA = GetEndingDangerScore(a)
			local scoreB = GetEndingDangerScore(b)
			if scoreA ~= scoreB then
				return scoreA > scoreB -- higher danger = higher position
			end
			-- Tiebreaker 1: shorter words first (faster to type in game)
			if #a ~= #b then
				return #a < #b
			end
			-- Tiebreaker 2: alphabetical
			return a < b
		end)
	else
		-- Old difficulty mode (reversed to put hard at top too)
		table.sort(filtered, function(a, b)
			local diffA = Difficulty(a)
			local diffB = Difficulty(b)
			if diffA ~= diffB then
				return diffA > diffB -- hard letters at top
			end
			return #a < #b
		end)
	end

	return filtered
end

--------------------------------------------------
-- UPDATE UI (OPTIMIZED)
--------------------------------------------------

UpdatePreview = function()
	if not Ready then return end
	if not CurrentLetter then return end

	Options = FindOptions(CurrentLetter)

	-- Update strategy label
	if SortMode == "strategy" then
		strategyLabel.Text = "🧠 STRATEGY+"
		strategyLabel.TextColor3 = Color3.fromRGB(200, 160, 255)
		strategyLabel.BackgroundColor3 = Color3.fromRGB(180, 120, 255)
	else
		strategyLabel.Text = "📊 DIFFICULTY"
		strategyLabel.TextColor3 = Color3.fromRGB(160, 200, 255)
		strategyLabel.BackgroundColor3 = Color3.fromRGB(80, 130, 220)
	end

	if not Options or #Options == 0 then
		prefixLabel.Text = CurrentLetter:upper()
		countLabel.Text = "Kata ditemukan: 0"
		statusLabel.Text = "⚠️ Tidak ada kata"

		dangerLabel.Visible = true
		dangerLabel.Text = "💀 MATI!"
		dangerLabel.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		dangerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)

		SendNotification("danger", "MATI! Tidak Ada Kata 💀", "Huruf '" .. CurrentLetter:upper() .. "' tidak punya kata valid di KBBI! Kamu stuck.", 5)

		for _, btn in ipairs(buttons) do
			btn.Text = ""
			btn.Visible = false
		end
		for _, ind in ipairs(buttonIndicators) do
			ind.Visible = false
		end
		return
	end

	prefixLabel.Text = CurrentLetter:upper()
	countLabel.Text = "Kata ditemukan: " .. #Options
	statusLabel.Text = "✅ " .. math.min(#Options, MAX_BUTTONS) .. "/" .. #Options .. " ditampilkan"

	-- Count killer words at top for notification
	local killerCount = 0
	for i = 1, math.min(#Options, MAX_BUTTONS) do
		local lastChar = string.sub(Options[i], -1)
		local score = KILLER_SCORE_OVERRIDE[lastChar] or 0
		local cnt = LetterWordCount[lastChar] or 0
		if score >= 60000 or cnt <= 3 then
			killerCount = killerCount + 1
		end
	end

	-- Danger indicator based on option count
	if #Options <= 3 then
		dangerLabel.Visible = true
		dangerLabel.Text = "⚠️ KRITIS! " .. #Options
		dangerLabel.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
		dangerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		SendNotification("warning", "Situasi Kritis! ⚠️", "Hanya " .. #Options .. " kata tersedia untuk '" .. CurrentLetter:upper() .. "'. Pilih dengan hati-hati!", 4)
	elseif #Options <= 10 then
		dangerLabel.Visible = true
		dangerLabel.Text = "⚠️ SEDIKIT " .. #Options
		dangerLabel.BackgroundColor3 = Color3.fromRGB(200, 150, 30)
		dangerLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	else
		dangerLabel.Visible = false
	end

	-- Show killer count notification in strategy mode
	if SortMode == "strategy" and killerCount > 0 then
		SendNotification("strategy", "🧠 " .. killerCount .. " Kata Killer Ditemukan!", "Kata dengan akhiran mematikan (x/z/q/v/f) ditaruh paling atas. Gunakan untuk menjebak lawan!", 4)
	end

	for i, btn in ipairs(buttons) do
		local ind = buttonIndicators[i]
		if Options[i] then
			btn.Text = "  " .. Options[i]
			btn.Visible = true
			btn.BackgroundTransparency = 1

			-- Show strategy indicator
			if SortMode == "strategy" then
				local _, label, color = GetDangerCategory(Options[i])
				ind.Text = label
				ind.BackgroundColor3 = color
				ind.TextColor3 = Color3.fromRGB(255, 255, 255)
				ind.Visible = true
			else
				-- Also show in difficulty mode
				local lastChar = string.sub(Options[i], -1)
				local diff = HardLetters[lastChar]
				if diff and diff >= 6 then
					ind.Text = "💀 HARD"
					ind.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
					ind.TextColor3 = Color3.fromRGB(255, 255, 255)
					ind.Visible = true
				elseif diff and diff >= 3 then
					ind.Text = "⚠️ MED"
					ind.BackgroundColor3 = Color3.fromRGB(240, 180, 40)
					ind.TextColor3 = Color3.fromRGB(255, 255, 255)
					ind.Visible = true
				else
					ind.Visible = false
				end
			end

			task.delay(i * 0.012, function()
				Tween(btn, {BackgroundTransparency = 0}, 0.2)
			end)
		else
			btn.Text = ""
			btn.Visible = false
			ind.Visible = false
		end
	end
end

--------------------------------------------------
-- BUTTON CLICK (Auto-input with notification)
--------------------------------------------------

for i, btn in ipairs(buttons) do
	btn.MouseButton1Click:Connect(function()
		local word = Options[i]
		if not word then return end

		-- Click feedback
		local origColor = btn.BackgroundColor3
		Tween(btn, {BackgroundColor3 = CurrentTheme.accent}, 0.08)
		task.delay(0.12, function()
			Tween(btn, {BackgroundColor3 = origColor}, 0.25)
		end)

		-- Show strategy info in notification
		local lastChar = string.sub(word, -1)
		local opponentCount = LetterWordCount[lastChar] or 0
		local _, dangerText = GetDangerCategory(word)
		local strategyMsg = 'Kata "' .. word .. '" → akhiran "' .. lastChar:upper() .. '" (' .. opponentCount .. ' kata musuh) ' .. dangerText

		local box = player.PlayerGui:FindFirstChild("MatchUI", true)
		if box then
			local input = box:FindFirstChildWhichIsA("TextBox", true)
			if input then
				input.Text = word
				if SortMode == "strategy" and opponentCount <= 5 then
					SendNotification("strategy", "Serangan Mematikan! 💀", strategyMsg, 3.5)
				elseif SortMode == "strategy" and opponentCount <= 15 then
					SendNotification("warning", "Serangan Kuat! ⚠️", strategyMsg, 3)
				else
					SendNotification("success", "Kata Dipilih", strategyMsg, 2.5)
				end
			end
		end
	end)
end

--------------------------------------------------
-- EVENTS
--------------------------------------------------

MatchUI.OnClientEvent:Connect(function(event, data)
	if event == "UpdateServerLetter" then
		CurrentLetter = string.lower(tostring(data)):gsub("[^a-z]", "")
		UpdatePreview()
	elseif event == "CorrectAnswer" then
		SendNotification("correct", "Jawaban Benar! 🎉", "Kerja bagus! Jawabanmu tepat!", 3)
	elseif event == "WrongAnswer" then
		SendNotification("wrong", "Jawaban Salah! 💢", "Coba lagi dengan kata yang berbeda.", 3)
	end
end)

--------------------------------------------------
-- ACCENT LINE PULSE
--------------------------------------------------

task.spawn(function()
	while accentLine and accentLine.Parent do
		TweenWait(accentLine, {BackgroundTransparency = 0.4}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenWait(accentLine, {BackgroundTransparency = 0}, 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end)

--------------------------------------------------
-- TITLE ICON GLOW PULSE
--------------------------------------------------

task.spawn(function()
	while titleIconGlow and titleIconGlow.Parent do
		TweenWait(titleIconGlow, {BackgroundTransparency = 0.65, Size = UDim2.new(0, 42, 0, 42), Position = UDim2.new(0, 7, 0.5, -21)}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		TweenWait(titleIconGlow, {BackgroundTransparency = 0.85, Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 9, 0.5, -19)}, 1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
end)

print("[KBBI v2] Script initialized with Strategy+ Engine! Theme: " .. CurrentThemeName)
print("[KBBI v2] Optimizations: 50 buttons, killer letters prioritized, multi-tier sorting")
