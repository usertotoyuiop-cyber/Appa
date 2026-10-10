--[[
	NurHub MM2  |  v5.0  |  Murder Mystery 2
	Без Drawing API: всё на Frame / UIStroke / Highlight / PointLight / Part.
	Меню: кнопка NH или RightShift.  Telegram: https://t.me/NurHuboffical
]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local Workspace    = game:GetService("Workspace")
local GuiService   = game:GetService("GuiService")
local Lighting     = game:GetService("Lighting")
local HttpService  = game:GetService("HttpService")

local LP = Players.LocalPlayer
local WHITE = Color3.new(1, 1, 1)
local TG_LINK = "https://t.me/NurHuboffical"
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

if ENV.NurHubMM2Unload then pcall(ENV.NurHubMM2Unload) end
if ENV.NurHubVisualUnload then pcall(ENV.NurHubVisualUnload) end

local alive = true
local conns = {}
local function track(c)
	conns[#conns + 1] = c
	return c
end

----------------------------------------------------------------
-- Утилиты
----------------------------------------------------------------
local function mount(gui)
	local ok = pcall(function()
		gui.Parent = (typeof(gethui) == "function" and gethui()) or game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		gui.Parent = LP:WaitForChild("PlayerGui")
	end
end

local function new(class, props, parent)
	local o = Instance.new(class)
	if props then
		for k, v in pairs(props) do o[k] = v end
	end
	if parent then o.Parent = parent end
	return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, c, th, tr)
	return new("UIStroke", {
		Color = c, Thickness = th or 1, Transparency = tr or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, o)
end
local function tw(o, t, props, style, dir)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end
local orderN = 0
local function ord()
	orderN = orderN + 1
	return orderN
end
local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end
local function avatarUrl(userId)
	return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(userId) .. "&w=150&h=150"
end

do -- остатки старых запусков
	local roots = { LP:FindFirstChildOfClass("PlayerGui") }
	pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
	pcall(function() if typeof(gethui) == "function" then table.insert(roots, gethui()) end end)
	for _, r in ipairs(roots) do
		for _, n in ipairs({ "NurHubMM2_UI", "NurHubMM2_ESP", "NurHubVisual_UI", "NurHubVisual_ESP" }) do
			local o = r and r:FindFirstChild(n)
			if o then pcall(function() o:Destroy() end) end
		end
	end
end

----------------------------------------------------------------
-- Файлы (сохранение настроек / конфигов)
----------------------------------------------------------------
local DIR = "NurHubMM2"
local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
local function fsRead(name)
	if hasFS then
		local ok, res = pcall(function()
			if isfile(DIR .. "/" .. name) then return readfile(DIR .. "/" .. name) end
		end)
		if ok and res then return res end
	end
	return ENV["NHMM2_" .. name]
end
local function fsWrite(name, data)
	ENV["NHMM2_" .. name] = data
	if hasFS then
		pcall(function()
			if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(DIR) then makefolder(DIR) end
			writefile(DIR .. "/" .. name, data)
		end)
	end
end

local function ser(v)
	local t = typeof(v)
	if t == "Color3" then
		return { __c = { v.R, v.G, v.B } }
	elseif t == "table" then
		local o = {}
		for k, x in pairs(v) do o[k] = ser(x) end
		return o
	end
	return v
end
local function deser(v)
	if type(v) == "table" then
		if v.__c then return Color3.new(v.__c[1], v.__c[2], v.__c[3]) end
		local o = {}
		for k, x in pairs(v) do o[k] = deser(x) end
		return o
	end
	return v
end
local function merge(dst, src)
	for k, v in pairs(src) do
		if dst[k] == nil then
			dst[k] = v
		elseif type(v) == "table" and type(dst[k]) == "table" then
			merge(dst[k], v)
		elseif typeof(dst[k]) == typeof(v) then
			dst[k] = v
		end
	end
end
local function jdecode(s)
	if not s then return nil end
	local ok, r = pcall(function() return HttpService:JSONDecode(s) end)
	if ok then return deser(r) end
end
local function jencode(t)
	local ok, r = pcall(function() return HttpService:JSONEncode(ser(t)) end)
	if ok then return r end
end

----------------------------------------------------------------
-- Тема, язык, настройки меню
----------------------------------------------------------------
local C = {
	bg = Color3.fromRGB(13, 13, 19), side = Color3.fromRGB(16, 16, 24), card = Color3.fromRGB(21, 20, 31),
	drawer = Color3.fromRGB(15, 15, 23), line = Color3.fromRGB(38, 36, 54), text = Color3.fromRGB(235, 235, 245),
	sub = Color3.fromRGB(135, 133, 158), off = Color3.fromRGB(50, 48, 70), track = Color3.fromRGB(34, 33, 50),
	field = Color3.fromRGB(11, 11, 17), accent = Color3.fromRGB(122, 92, 255), accent2 = Color3.fromRGB(88, 140, 255),
}
local UI = { lang = "English", scale = 100, alpha = 0, accent = Color3.fromRGB(122, 92, 255) }
do
	local saved = jdecode(fsRead("settings.json"))
	if type(saved) == "table" then merge(UI, saved) end
end
local uiDirty = false
local function saveUI() uiDirty = true end

local accentFns = {}
local function onAccent(fn)
	accentFns[#accentFns + 1] = fn
	fn()
end
local function applyAccent()
	local h, s, v = UI.accent:ToHSV()
	C.accent = UI.accent
	C.accent2 = Color3.fromHSV((h + 0.09) % 1, s, v)
	for _, f in ipairs(accentFns) do pcall(f) end
end
applyAccent()

local RU = {}
local function tr(s)
	if UI.lang == "Русский" then return RU[s] or s end
	return s
end
local langFns = {}
local function onLang(fn)
	langFns[#langFns + 1] = fn
	fn()
end
local function setText(obj, en)
	onLang(function() obj.Text = tr(en) end)
end
local function applyLang()
	for _, f in ipairs(langFns) do pcall(f) end
end

local refreshers = {}
local function refreshAll()
	for _, f in ipairs(refreshers) do pcall(f) end
end

----------------------------------------------------------------
-- Роли MM2
----------------------------------------------------------------
local ROLE_COL = { Murderer = Color3.fromRGB(255, 60, 60), Sheriff = Color3.fromRGB(70, 140, 255) }
local roles = {}
local function hasTool(plr, name)
	local bp = plr:FindFirstChildOfClass("Backpack")
	local ch = plr.Character
	return (bp ~= nil and bp:FindFirstChild(name) ~= nil) or (ch ~= nil and ch:FindFirstChild(name) ~= nil)
end
local function scanRole(plr)
	if hasTool(plr, "Knife") then return "Murderer" end
	if hasTool(plr, "Gun") then return "Sheriff" end
	return nil
end

----------------------------------------------------------------
-- НАСТРОЙКИ
----------------------------------------------------------------
local PURPLE = Color3.fromRGB(150, 110, 255)
local YELLOW = Color3.fromRGB(255, 205, 60)
local CFG = {
	esp     = { on = true, roleColors = true, maxDist = 1500 },
	espFor  = { mode = "All", target = "", colors = {} },
	box2d   = { on = false, color = WHITE },
	corner  = { on = false, color = WHITE, len = 28 },
	fill    = { on = false, c1 = Color3.fromRGB(12, 12, 20), c2 = PURPLE, trans = 0.5 },
	box3d   = { on = false, color = Color3.fromRGB(80, 200, 255) },
	name    = { on = false, color = WHITE, size = 12 },
	dist    = { on = false, color = Color3.fromRGB(190, 190, 210), size = 12 },
	health  = { on = false, color = Color3.fromRGB(70, 230, 120), thick = 2, dyn = true },
	avatar  = { on = false, size = 30 },
	chams   = { on = false, color = PURPLE, trans = 0.5 },
	outline = { on = false, color = WHITE },
	vis     = { on = false, hidden = Color3.fromRGB(255, 40, 40), shown = Color3.fromRGB(60, 255, 100), trans = 0.5 },
	glow    = { on = false, color = PURPLE, range = 16, bright = 2 },
	tracer  = { on = false, color = WHITE, origin = "Bottom" },
	skel    = { on = false, color = WHITE },
	head    = { on = false, color = Color3.fromRGB(255, 90, 110) },
	arrows  = { on = false, color = WHITE, radius = 130, size = 14 },
	fov     = { on = false, val = 90 },
	third   = { on = false, dist = 12 },
	hat     = { on = false, color = Color3.fromRGB(150, 90, 230), trans = 0.4, scope = "Everyone", size = 100,
		style = "Lines", lines = 14, rainbow = true, anim = true },
	trail   = { on = false, color = Color3.fromRGB(122, 92, 255), len = 1.2, width = 0.8, scope = "Only me" },
	steps   = { on = false, color = PURPLE, rainbow = false, dur = 1.2, shape = "Circle", size = 3, scope = "Only me" },
	fps     = { on = false, color = WHITE, custom = false, value = 999, px = 0.02, py = 0.02 },
	gun     = { on = false, text = true, textColor = WHITE, color = YELLOW, tracer = false, tracerColor = YELLOW },
	coin    = { on = false, color = YELLOW, text = true, textColor = WHITE },
	xray    = { on = false, val = 60 },
	walk    = { on = false, val = 32 },
	jump    = { on = false, val = 70 },
	spin    = { on = false, val = 20 },
	noclip  = { on = false },
	fly     = { on = false, speed = 60 },
	farm    = { on = false, speed = 60, delay = 0.25 },
	world   = { on = false, preset = "None", full = false, bright = 2, clock = 14, dark = 0, bloom = 0, contrast = 0,
		sat = 0, fog = 0, rays = 0, blur = 0, tint = WHITE, fogc = Color3.fromRGB(200, 200, 210), particles = "None" },
}
local SEL = { fling = "", tp = "" } -- не сохраняется в конфиг

----------------------------------------------------------------
-- ОКНО
----------------------------------------------------------------
local MAIN_W, H, SIDE, PREV_W, GAP = 640, 470, 128, 252, 12
local FULL_W = MAIN_W + GAP + PREV_W

local gui = new("ScreenGui", {
	Name = "NurHubMM2_UI", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(gui)

local Root = new("Frame", {
	Name = "Root", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
	Size = UDim2.fromOffset(FULL_W, H), BackgroundTransparency = 1, Visible = false,
}, gui)
local fitScale = new("UIScale", { Scale = 1 }, Root)
local Anim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, Root)
local animScale = new("UIScale", { Scale = .9 }, Anim)

local Main = new("CanvasGroup", {
	Size = UDim2.fromOffset(MAIN_W, H), BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1,
}, Anim)
corner(Main, 16)
stroke(Main, C.line, 1)

local Preview = new("CanvasGroup", {
	Position = UDim2.fromOffset(MAIN_W + GAP, 0), Size = UDim2.fromOffset(PREV_W, H),
	BackgroundColor3 = C.bg, BorderSizePixel = 0, GroupTransparency = 1, Visible = false,
}, Anim)
corner(Preview, 16)
stroke(Preview, C.line, 1)

local function fit()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	local base = math.clamp(math.min((vs.X - 24) / FULL_W, (vs.Y - 24) / H), 0.35, 1)
	fitScale.Scale = math.clamp(base * UI.scale / 100, 0.3, 1.6)
end
fit()
do
	local cam = Workspace.CurrentCamera
	if cam then track(cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end
end

local function makeDraggable(handle, target, onClick, scaleObj)
	local dragging, moved, startMouse, startPos = false, false, nil, nil
	handle.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, moved = true, false
			startMouse, startPos = i.Position, target.Position
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then
			local d = i.Position - startMouse
			if d.Magnitude > 5 then moved = true end
			if moved then
				local k = scaleObj and scaleObj.Scale or 1
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X / k, startPos.Y.Scale, startPos.Y.Offset + d.Y / k)
			end
		end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if not moved and onClick then onClick() end
		end
	end))
end

-- иконки из Frame
local function Icon(kind, parent, size)
	local box = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5),
		Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1,
	}, parent)
	new("UIScale", { Scale = (size or 20) / 20 }, box)
	local ss, ff = {}, {}
	local function ring(w, h, x, y, th, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			BackgroundTransparency = 1, BorderSizePixel = 0,
		}, box)
		corner(f, rad or math.max(w, h) / 2)
		ss[#ss + 1] = stroke(f, WHITE, th or 2)
	end
	local function solid(w, h, x, y, rot, rad)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
			Rotation = rot or 0, BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, box)
		if rad then corner(f, rad) end
		ff[#ff + 1] = f
	end
	if kind == "eye" then
		ring(18, 12, 10, 10, 2); solid(6, 6, 10, 10, 0, 3)
	elseif kind == "info" then
		ring(16, 16, 10, 10, 2); solid(2, 2, 10, 6, 0, 1); solid(2, 6, 10, 12)
	elseif kind == "user" then
		ring(8, 8, 10, 6, 2); solid(14, 7, 10, 15, 0, 3)
	elseif kind == "globe" then
		ring(16, 16, 10, 10, 2); ring(7, 16, 10, 10, 2); solid(16, 2, 10, 10)
	elseif kind == "troll" then
		ring(16, 16, 10, 10, 2); solid(3, 3, 7, 8, 0, 1); solid(3, 3, 13, 8, 0, 1); solid(8, 2, 10, 14, 0, 1)
	elseif kind == "misc" then
		solid(7, 7, 6, 6, 0, 2); solid(7, 7, 14, 6, 0, 2); solid(7, 7, 6, 14, 0, 2); solid(7, 7, 14, 14, 0, 2)
	elseif kind == "cfg" then
		solid(16, 2, 10, 5, 0, 1); solid(16, 2, 10, 10, 0, 1); solid(16, 2, 10, 15, 0, 1)
		solid(4, 6, 7, 5, 0, 2); solid(4, 6, 13, 10, 0, 2); solid(4, 6, 8, 15, 0, 2)
	elseif kind == "gear" then
		ring(10, 10, 10, 10, 2); solid(2, 4, 10, 2); solid(2, 4, 10, 18); solid(4, 2, 2, 10); solid(4, 2, 18, 10)
	end
	local api = {}
	function api.paint(col, t)
		for _, s in ipairs(ss) do tw(s, t or .2, { Color = col }) end
		for _, f in ipairs(ff) do tw(f, t or .2, { BackgroundColor3 = col }) end
	end
	api.paint(C.sub, 0)
	return api
end

local function Arrow(parent, pos)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = pos, Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
	}, parent)
	for _, d in ipairs({ { 3.5, 45 }, { 8.5, -45 } }) do
		corner(new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(d[1], 6), Size = UDim2.fromOffset(7, 2),
			Rotation = d[2], BackgroundColor3 = C.sub, BorderSizePixel = 0,
		}, c), 1)
	end
	return c
end

-- боковая панель
local Side = new("Frame", { Size = UDim2.new(0, SIDE, 1, 0), BackgroundColor3 = C.side, BorderSizePixel = 0 }, Main)
new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.line, BorderSizePixel = 0 }, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 20), Size = UDim2.new(1, -20, 0, 26),
	Font = Enum.Font.GothamBlack, Text = "NURHUB", TextSize = 21, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
new("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 46), Size = UDim2.new(1, -20, 0, 14),
	Font = Enum.Font.GothamMedium, Text = "murder mystery 2  •  v5.0", TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
}, Side)
local dragZone = new("Frame", { Size = UDim2.new(1, 0, 0, 66), BackgroundTransparency = 1 }, Side)
makeDraggable(dragZone, Root, nil, fitScale)
local dragTop = new("Frame", { Position = UDim2.fromOffset(SIDE, 0), Size = UDim2.new(1, -SIDE, 0, 12), BackgroundTransparency = 1 }, Main)
makeDraggable(dragTop, Root, nil, fitScale)

local navList = new("Frame", { Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 1, -76), BackgroundTransparency = 1 }, Side)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, navList)
new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, navList)

local Content = new("Frame", {
	Position = UDim2.new(0, SIDE + 14, 0, 14), Size = UDim2.new(1, -(SIDE + 28), 1, -28), BackgroundTransparency = 1,
}, Main)

local tabs, pages, ptok = {}, {}, {}
local current
local onTabChanged

local function paintTab(name, sel, anim)
	local t = tabs[name]
	local d = anim and .22 or 0
	tw(t.btn, d, { BackgroundTransparency = sel and 0 or 1 })
	tw(t.lbl, d, { TextColor3 = sel and WHITE or C.sub })
	t.icon.paint(sel and WHITE or C.sub, d)
end

local function switchTab(name)
	if name == current then return end
	local prev = current
	current = name
	ptok[prev] = (ptok[prev] or 0) + 1
	local my = ptok[prev]
	local old, nxt = pages[prev], pages[name]
	tw(old, .18, { GroupTransparency = 1, Position = UDim2.new(0, 0, 0, -12) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(.2, function()
		if ptok[prev] == my and current ~= prev then old.Visible = false end
	end)
	nxt.Position = UDim2.new(0, 0, 0, 22)
	nxt.GroupTransparency = 1
	nxt.Visible = true
	tw(nxt, .45, { GroupTransparency = 0, Position = UDim2.new(0, 0, 0, 0) })
	for n in pairs(tabs) do paintTab(n, n == name, true) end
	if onTabChanged then onTabChanged(name) end
end

local function createTab(name, iconKind, sub)
	local btn = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = WHITE, BackgroundTransparency = 1,
		BorderSizePixel = 0, AutoButtonColor = false, Text = "", LayoutOrder = ord(),
	}, navList)
	corner(btn, 10)
	local bg = new("UIGradient", { Rotation = 0 }, btn)
	onAccent(function() bg.Color = ColorSequence.new(C.accent, C.accent2) end)
	local holder = new("Frame", { Size = UDim2.fromOffset(34, 38), BackgroundTransparency = 1 }, btn)
	local icon = Icon(iconKind, holder, 19)
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -40, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, btn)
	setText(lbl, name)
	tabs[name] = { btn = btn, lbl = lbl, icon = icon }
	btn.MouseEnter:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.text }); icon.paint(C.text, .15) end
	end)
	btn.MouseLeave:Connect(function()
		if current ~= name then tw(lbl, .15, { TextColor3 = C.sub }); icon.paint(C.sub, .15) end
	end)
	btn.MouseButton1Click:Connect(function() switchTab(name) end)

	local cg = new("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 }, Content)
	local head = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), Font = Enum.Font.GothamBold, RichText = true,
		TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, cg)
	onLang(function()
		head.Text = tr(name) .. ' <font color="rgb(135,133,158)">· ' .. tr(sub) .. "</font>"
	end)
	local sf = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 1, -32), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, cg)
	onAccent(function() sf.ScrollBarImageColor3 = C.accent end)
	new("UIPadding", { PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 12), PaddingTop = UDim.new(0, 2) }, sf)
	pages[name] = cg
	return sf
end

local function Columns(sf)
	local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, sf)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12),
		VerticalAlignment = Enum.VerticalAlignment.Top, SortOrder = Enum.SortOrder.LayoutOrder,
	}, holder)
	local function col(o)
		local c = new("Frame", {
			Size = UDim2.new(.5, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = o,
		}, holder)
		new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, c)
		return c
	end
	return col(1), col(2)
end
local function Single(sf)
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	return sf
end

----------------------------------------------------------------
-- Компоненты
----------------------------------------------------------------
local ROW = 28

local function Card(parent, title)
	local outer = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = ord(),
	}, parent)
	new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, outer)
	if title then
		local t = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 1, Font = Enum.Font.GothamBold,
			TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
		}, outer)
		onLang(function() t.Text = string.upper(tr(title)) end)
		new("UIPadding", { PaddingLeft = UDim.new(0, 3) }, t)
	end
	local panel = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card,
		BorderSizePixel = 0, LayoutOrder = 2,
	}, outer)
	corner(panel, 10)
	stroke(panel, C.line, 1)
	new("UIPadding", {
		PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12),
	}, panel)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
	return panel
end

local function Label(parent, text, color, size)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.Gotham, TextSize = size or 12, TextColor3 = color or C.sub, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
	}, parent)
	setText(l, text)
	return l
end

local function Button(parent, text, cb, fill)
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = fill and WHITE or C.drawer, BorderSizePixel = 0, AutoButtonColor = false,
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, LayoutOrder = ord(),
	}, parent)
	setText(b, text)
	corner(b, 9)
	if fill then
		local g = new("UIGradient", {}, b)
		onAccent(function() g.Color = ColorSequence.new(C.accent, C.accent2) end)
	else
		stroke(b, C.line, 1)
		b.MouseEnter:Connect(function() tw(b, .15, { BackgroundColor3 = Color3.fromRGB(30, 29, 44) }) end)
		b.MouseLeave:Connect(function() tw(b, .15, { BackgroundColor3 = C.drawer }) end)
	end
	b.MouseButton1Click:Connect(function() if cb then cb(b) end end)
	return b
end

local function TextField(parent, placeholder, init, onDone, numeric)
	local box = new("TextBox", {
		Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = C.field, BorderSizePixel = 0, Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = C.text, PlaceholderColor3 = C.sub, ClearTextOnFocus = false, Text = init or "",
		LayoutOrder = ord(), TextXAlignment = Enum.TextXAlignment.Center,
	}, parent)
	onLang(function() box.PlaceholderText = tr(placeholder) end)
	corner(box, 9)
	stroke(box, C.line, 1)
	box.FocusLost:Connect(function() if onDone then onDone(box.Text, box) end end)
	return box
end

local function Slider(parent, title, min, max, tbl, key, opts)
	opts = opts or {}
	local div = opts.div or 1
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	local tl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(.62, 0, 0, 16), Font = Enum.Font.GothamMedium,
		TextSize = 12, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	setText(tl, title)
	local val = new("TextLabel", {
		BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(.38, 0, 0, 16), Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, row)
	local bar = new("Frame", { Position = UDim2.fromOffset(0, 23), Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = C.track, BorderSizePixel = 0 }, row)
	corner(bar, 3)
	local fill = new("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, bar)
	corner(fill, 3)
	local fg = new("UIGradient", {}, fill)
	onAccent(function() fg.Color = ColorSequence.new(C.accent, C.accent2) end)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(1, 0, .5, 0), Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, fill)
	corner(knob, 7)
	local hit = new("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 24),
	}, row)

	local function show()
		local v = tbl[key]
		fill.Size = UDim2.new(math.clamp((v * div - min) / (max - min), 0, 1), 0, 1, 0)
		val.Text = opts.fmt and opts.fmt(v) or tostring(v)
	end
	show()
	refreshers[#refreshers + 1] = show
	local dragging, scroller = false, nil
	local function upd(i)
		local p = math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		tbl[key] = math.floor(min + (max - min) * p + .5) / div
		show()
		if opts.onChange then opts.onChange(tbl[key]) end
	end
	hit.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging = true
			scroller = hit:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then scroller.ScrollingEnabled = false end
			upd(i)
		end
	end)
	track(UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then upd(i) end
	end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if scroller then scroller.ScrollingEnabled = true end
		end
	end))
end

local QUICK = {
	Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 70, 85), Color3.fromRGB(255, 190, 50),
	Color3.fromRGB(80, 235, 130), Color3.fromRGB(70, 215, 255), Color3.fromRGB(80, 120, 255),
	Color3.fromRGB(170, 100, 255), Color3.fromRGB(255, 100, 200),
}
local function ColorBar(parent, label, onChange)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	local tl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 10), Font = Enum.Font.GothamMedium,
		TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	setText(tl, label)
	local bar = new("TextButton", {
		Text = "", AutoButtonColor = false, Position = UDim2.fromOffset(0, 14), Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, row)
	corner(bar, 4)
	local grad = new("UIGradient", {}, bar)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 0, .5, 0), Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = WHITE, BorderSizePixel = 0,
	}, bar)
	corner(knob, 6)
	stroke(knob, Color3.fromRGB(18, 18, 24), 2)
	local dragging, scroller = false, nil
	local function upd(i) onChange(math.clamp((i.Position.X - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)) end
	bar.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging = true
			scroller = bar:FindFirstAncestorOfClass("ScrollingFrame")
			if scroller then scroller.ScrollingEnabled = false end
			upd(i)
		end
	end)
	track(UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then upd(i) end end))
	track(UIS.InputEnded:Connect(function(i)
		if dragging and isPress(i) then
			dragging = false
			if scroller then scroller.ScrollingEnabled = true end
		end
	end))
	return { grad = grad, set = function(a) tw(knob, .06, { Position = UDim2.new(a, 0, .5, 0) }) end }
end

local function ColorPicker(parent, tbl, key, title, onChange)
	if title then Label(parent, title, C.sub, 10) end
	local h, s, v = tbl[key]:ToHSV()
	local top = new("Frame", { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, top)
	local prev = new("Frame", { Size = UDim2.fromOffset(26, 16), BorderSizePixel = 0, LayoutOrder = 0 }, top)
	corner(prev, 4)
	stroke(prev, Color3.fromRGB(70, 68, 92), 1)
	local hueB, satB, valB
	local function refresh()
		local c = Color3.fromHSV(h, s, v)
		prev.BackgroundColor3 = c
		satB.grad.Color = ColorSequence.new(Color3.fromHSV(h, 0, v), Color3.fromHSV(h, 1, v))
		valB.grad.Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.fromHSV(h, s, 1))
		hueB.set(h); satB.set(s); valB.set(v)
		return c
	end
	local function user()
		tbl[key] = refresh()
		if onChange then onChange(tbl[key]) end
	end
	for i, c in ipairs(QUICK) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(14, 14), BackgroundColor3 = c, BorderSizePixel = 0, LayoutOrder = i,
		}, top)
		corner(b, 4)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		b.MouseButton1Click:Connect(function()
			h, s, v = c:ToHSV()
			user()
		end)
	end
	hueB = ColorBar(parent, "Hue", function(a) h = math.min(a, .999); user() end)
	satB = ColorBar(parent, "Saturation", function(a) s = a; user() end)
	valB = ColorBar(parent, "Brightness", function(a) v = a; user() end)
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, .999), 1, 1)) end
	hueB.grad.Color = ColorSequence.new(keys)
	refresh()
	local api = { set = function(c) h, s, v = c:ToHSV(); refresh() end }
	refreshers[#refreshers + 1] = function() api.set(tbl[key]) end
	return api
end

local GRADS = {
	{ Color3.fromRGB(12, 12, 20), Color3.fromRGB(150, 110, 255) },
	{ Color3.fromRGB(255, 80, 100), Color3.fromRGB(255, 190, 70) },
	{ Color3.fromRGB(40, 220, 160), Color3.fromRGB(60, 140, 255) },
	{ Color3.fromRGB(255, 255, 255), Color3.fromRGB(70, 70, 90) },
	{ Color3.fromRGB(255, 100, 200), Color3.fromRGB(110, 90, 255) },
	{ Color3.fromRGB(0, 0, 0), Color3.fromRGB(230, 230, 240) },
}
local function GradientPicker(parent, tbl, k1, k2)
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = ord() }, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
	}, row)
	local p1 = ColorPicker(parent, tbl, k1, "Top color")
	local p2 = ColorPicker(parent, tbl, k2, "Bottom color")
	for i, g in ipairs(GRADS) do
		local b = new("TextButton", {
			Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 20), BackgroundColor3 = WHITE,
			BorderSizePixel = 0, LayoutOrder = i,
		}, row)
		corner(b, 5)
		stroke(b, Color3.fromRGB(60, 58, 80), 1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(g[1], g[2]) }, b)
		b.MouseButton1Click:Connect(function()
			tbl[k1], tbl[k2] = g[1], g[2]
			p1.set(g[1]); p2.set(g[2])
		end)
	end
end

local function Dropdown(parent, title, list, tbl, key, onChange)
	local IT, GAPY = 22, 2
	local holder = new("Frame", {
		Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local tl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium,
		TextSize = 11, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)
	setText(tl, title)
	local head = new("TextButton", {
		Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = C.field, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "",
	}, holder)
	corner(head, 6)
	stroke(head, C.line, 1)
	local curLbl = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -34, 1, 0),
		Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, head)
	local arrow = Arrow(head, UDim2.new(1, -14, .5, 0))
	local listH = #list * IT + (#list - 1) * GAPY + 8
	local box = new("Frame", {
		Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, listH), BackgroundColor3 = C.field, BorderSizePixel = 0,
	}, holder)
	corner(box, 6)
	stroke(box, C.line, 1)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }, box)
	new("UIListLayout", { Padding = UDim.new(0, GAPY), SortOrder = Enum.SortOrder.LayoutOrder }, box)
	local btns, open = {}, false
	local function render()
		curLbl.Text = tr(tbl[key])
		for n, b in pairs(btns) do b.TextColor3 = (n == tbl[key]) and WHITE or C.sub end
	end
	local function setOpen(v)
		open = v
		tw(holder, .25, { Size = UDim2.new(1, 0, 0, v and (46 + listH) or 44) })
		tw(arrow, .25, { Rotation = v and 180 or 0 })
	end
	for i, n in ipairs(list) do
		local b = new("TextButton", {
			Size = UDim2.new(1, 0, 0, IT), BackgroundColor3 = C.accent, BackgroundTransparency = 1, AutoButtonColor = false,
			Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
			BorderSizePixel = 0, LayoutOrder = i, Text = "",
		}, box)
		corner(b, 5)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
		btns[n] = b
		onLang(function() b.Text = tr(n); render() end)
		b.MouseEnter:Connect(function() tw(b, .12, { BackgroundTransparency = .75 }) end)
		b.MouseLeave:Connect(function() tw(b, .12, { BackgroundTransparency = 1 }) end)
		b.MouseButton1Click:Connect(function()
			tbl[key] = n
			render()
			setOpen(false)
			if onChange then onChange(n) end
		end)
	end
	head.MouseButton1Click:Connect(function() setOpen(not open) end)
	render()
	refreshers[#refreshers + 1] = render
end

-- переключатель; tbl == nil -> просто раскрывающаяся шторка со стрелкой
local function Toggle(parent, title, tbl, key, builder, onToggle)
	local box = new("Frame", {
		Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = ord(),
	}, parent)
	local head = new("TextButton", { Size = UDim2.new(1, 0, 0, ROW), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, box)
	local lbl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, tbl and -90 or -30, 1, 0), Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, head)
	setText(lbl, title)
	local flip = function() end
	if tbl then
		local sw = new("TextButton", {
			AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, 0, 0, ROW / 2), Size = UDim2.fromOffset(36, 18),
			BorderSizePixel = 0, AutoButtonColor = false, Text = "", BackgroundColor3 = C.off,
		}, box)
		corner(sw, 9)
		local swGrad = new("UIGradient", { Enabled = false }, sw)
		onAccent(function() swGrad.Color = ColorSequence.new(C.accent, C.accent2) end)
		local knob = new("Frame", {
			AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, 3, .5, 0),
			BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, sw)
		corner(knob, 6)
		local function paint(anim)
			local on = tbl[key]
			local d = anim and .2 or 0
			swGrad.Enabled = on
			tw(sw, d, { BackgroundColor3 = on and WHITE or C.off })
			tw(knob, d, { Position = on and UDim2.new(1, -15, .5, 0) or UDim2.new(0, 3, .5, 0) }, Enum.EasingStyle.Back)
		end
		paint(false)
		refreshers[#refreshers + 1] = function() paint(false) end
		flip = function()
			tbl[key] = not tbl[key]
			paint(true)
			if onToggle then onToggle(tbl[key]) end
		end
		sw.MouseButton1Click:Connect(flip)
	end

	if builder then
		local arrow = Arrow(head, UDim2.new(1, tbl and -52 or -10, .5, 0))
		local drawer = new("Frame", {
			Position = UDim2.fromOffset(0, ROW + 6), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.drawer, BorderSizePixel = 0,
		}, box)
		corner(drawer, 8)
		stroke(drawer, C.line, 1)
		local layout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, drawer)
		new("UIPadding", { PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 9), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, drawer)
		builder(drawer)
		local open = false
		local function drawerH() return layout.AbsoluteContentSize.Y + 18 end
		local function resize(t)
			drawer.Size = UDim2.new(1, 0, 0, drawerH())
			local h = open and (ROW + 6 + drawerH() + 2) or ROW
			tw(box, t, { Size = UDim2.new(1, 0, 0, h) })
		end
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			drawer.Size = UDim2.new(1, 0, 0, drawerH())
			if open then box.Size = UDim2.new(1, 0, 0, ROW + 6 + drawerH() + 2) end
		end)
		head.MouseButton1Click:Connect(function()
			open = not open
			resize(.3)
			tw(arrow, .28, { Rotation = open and 180 or 0 })
		end)
	elseif tbl then
		head.MouseButton1Click:Connect(flip)
	end
end

-- список игроков с аватарками (внутри шторки, листается)
local listUpdaters = {}
local function PlayerList(parent, h, onPick, isSel, includeSelf)
	local sf = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.field, BorderSizePixel = 0, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, LayoutOrder = ord(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, parent)
	onAccent(function() sf.ScrollBarImageColor3 = C.accent end)
	corner(sf, 8)
	stroke(sf, C.line, 1)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sf)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6) }, sf)
	local empty = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = C.sub, Visible = false,
	}, sf)
	setText(empty, "No players")
	local rows = {}
	local function roleColor(p)
		return ROLE_COL[roles[p] or ""] or C.text
	end
	local function colors()
		for p, r in pairs(rows) do
			r.name.TextColor3 = roleColor(p)
			r.tag.Text = roles[p] and tr(roles[p]) or ""
			r.tag.TextColor3 = roleColor(p)
			r.stroke.Color = (isSel and isSel(p)) and C.accent or C.line
		end
	end
	local function rebuild()
		for _, r in pairs(rows) do r.btn:Destroy() end
		rows = {}
		local n = 0
		for _, p in ipairs(Players:GetPlayers()) do
			if includeSelf or p ~= LP then
				n = n + 1
				local btn = new("TextButton", {
					Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false,
					Text = "", LayoutOrder = n,
				}, sf)
				corner(btn, 8)
				local st = stroke(btn, C.line, 1)
				local img = new("ImageLabel", {
					Position = UDim2.fromOffset(6, 5), Size = UDim2.fromOffset(30, 30), BackgroundColor3 = C.field,
					BorderSizePixel = 0, Image = avatarUrl(p.UserId),
				}, btn)
				corner(img, 15)
				local nm = new("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 4), Size = UDim2.new(1, -110, 0, 17),
					Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, Text = p.DisplayName,
				}, btn)
				new("TextLabel", {
					BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 21), Size = UDim2.new(1, -110, 0, 14),
					Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd, Text = "@" .. p.Name,
				}, btn)
				local tag = new("TextLabel", {
					BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0),
					Size = UDim2.fromOffset(60, 16), Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right,
				}, btn)
				rows[p] = { btn = btn, name = nm, tag = tag, stroke = st }
				btn.MouseButton1Click:Connect(function()
					if onPick then onPick(p) end
					colors()
				end)
			end
		end
		empty.Visible = n == 0
		colors()
	end
	rebuild()
	track(Players.PlayerAdded:Connect(function() task.wait(.2); rebuild() end))
	track(Players.PlayerRemoving:Connect(function() task.wait(.1); rebuild() end))
	listUpdaters[#listUpdaters + 1] = colors
	refreshers[#refreshers + 1] = colors
	return { rebuild = rebuild, colors = colors }
end

-- всплывающее уведомление
local function notify(msg)
	local t = new("TextLabel", {
		AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -50), Size = UDim2.fromOffset(300, 34),
		BackgroundColor3 = C.card, BackgroundTransparency = 1, TextTransparency = 1, Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = WHITE, Text = tr(msg), ZIndex = 50, BorderSizePixel = 0,
	}, gui)
	corner(t, 10)
	local st = stroke(t, C.line, 1, 1)
	tw(t, .25, { BackgroundTransparency = .05, TextTransparency = 0 })
	tw(st, .25, { Transparency = 0 })
	task.delay(2.2, function()
		tw(t, .3, { BackgroundTransparency = 1, TextTransparency = 1 })
		tw(st, .3, { Transparency = 1 })
		task.delay(.35, function() t:Destroy() end)
	end)
end


----------------------------------------------------------------
-- Линии / стрелки (общее для ESP и превью)
----------------------------------------------------------------
local function mkLine(parent)
	return new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), BorderSizePixel = 0, BackgroundColor3 = WHITE,
		Visible = false, Size = UDim2.fromOffset(0, 1),
	}, parent)
end
local function setLine(f, a, b, col, th)
	local d = b - a
	f.Size = UDim2.fromOffset(d.Magnitude, th)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.BackgroundColor3 = col
	f.Visible = true
end
local function hideList(l) if l then for _, f in ipairs(l) do f.Visible = false end end end

local function mkArrow(parent)
	local c = new("Frame", {
		AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Visible = false,
	}, parent)
	local sc = new("UIScale", { Scale = 1 }, c)
	local bars = {}
	for _, r in ipairs({ { 12, 12, 0, 16 }, { 15, 7.8, 40, 13 }, { 15, 16.2, -40, 13 } }) do
		local b = new("Frame", {
			AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(r[1], r[2]), Size = UDim2.fromOffset(r[4], 3),
			Rotation = r[3], BackgroundColor3 = WHITE, BorderSizePixel = 0,
		}, c)
		corner(b, 2)
		bars[#bars + 1] = b
	end
	return { frame = c, scale = sc, bars = bars }
end
local function paintArrow(a, col, size)
	for _, b in ipairs(a.bars) do b.BackgroundColor3 = col end
	a.scale.Scale = size / 24
end

----------------------------------------------------------------
-- ESP слой
----------------------------------------------------------------
local espGui = new("ScreenGui", {
	Name = "NurHubMM2_ESP", ResetOnSpawn = false, IgnoreGuiInset = true,
	DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})
mount(espGui)

local TH = 1.5
local function mkBox()
	return new("Frame", { BorderSizePixel = 0, BackgroundColor3 = WHITE, Visible = false }, espGui)
end
local function mkText()
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(220, 14), Font = Enum.Font.GothamBold, TextSize = 12,
		TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
	}, espGui)
end

local R15 = {
	{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local R6 = {
	{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
	{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local EDGES = {}
for i = 0, 7 do
	for _, b in ipairs({ 1, 2, 4 }) do
		if bit32.band(i, b) == 0 then EDGES[#EDGES + 1] = { i, i + b } end
	end
end

local S = {}
local function hideAll(d)
	for _, v in pairs(d) do
		if typeof(v) == "Instance" then
			if v:IsA("GuiObject") then
				v.Visible = false
			elseif v:IsA("Highlight") or v:IsA("Light") then
				v.Enabled = false
			end
		elseif type(v) == "table" then
			for _, f in ipairs(v) do
				if typeof(f) == "Instance" and f:IsA("GuiObject") then f.Visible = false end
			end
		end
	end
end
local function destroyData(d)
	for _, v in pairs(d) do
		if typeof(v) == "Instance" then
			pcall(function() v:Destroy() end)
		elseif type(v) == "table" then
			for _, x in ipairs(v) do
				if typeof(x) == "Instance" then pcall(function() x:Destroy() end) end
			end
		end
	end
end

local function setCorners(list, x0, y0, x1, y1, l, t, col)
	local spec = {
		{ x0, y0, l, t }, { x0, y0, t, l },
		{ x1 - l, y0, l, t }, { x1 - t, y0, t, l },
		{ x0, y1 - t, l, t }, { x0, y1 - l, t, l },
		{ x1 - l, y1 - t, l, t }, { x1 - t, y1 - l, t, l },
	}
	for i, s in ipairs(spec) do
		local f = list[i]
		f.Position = UDim2.fromOffset(s[1], s[2])
		f.Size = UDim2.fromOffset(s[3], s[4])
		f.BackgroundColor3 = col
		f.Visible = true
	end
end

-- цвет для игрока: свой цвет > цвет роли > цвет функции
local function pcol(plr, base)
	local o = CFG.espFor.colors[plr.Name]
	if o then return o end
	if CFG.esp.roleColors then
		local rc = ROLE_COL[roles[plr] or ""]
		if rc then return rc end
	end
	return base
end

local function allowed(plr)
	local m = CFG.espFor.mode
	if m == "All" then return true end
	if m == "Murderer" then return roles[plr] == "Murderer" end
	if m == "Sheriff" then return roles[plr] == "Sheriff" end
	return plr.Name == CFG.espFor.target
end

-- проверка «виден ли игрок без стены»
local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Exclude
local function clearPath(origin, target, ignore)
	for _ = 1, 5 do
		rayP.FilterDescendantsInstances = ignore
		local res = Workspace:Raycast(origin, target - origin, rayP)
		if not res then return true end
		local p = res.Instance
		if p.CanCollide == false or p.Transparency >= 0.85 then
			ignore[#ignore + 1] = p
		else
			return false
		end
	end
	return false
end

local function drawPlayer(d, plr, char, hum, root, cam, vs)
	-- Chams + Outline + Wall check (Highlight)
	if CFG.chams.on or CFG.outline.on or CFG.vis.on then
		local hl = d.hl
		if not hl then
			hl = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop }, espGui)
			d.hl = hl
		end
		hl.Adornee = char
		if CFG.vis.on then
			local now = os.clock()
			if not d.visT or now - d.visT > 0.08 then
				d.visT = now
				local head = char:FindFirstChild("Head") or root
				local o = cam.CFrame.Position
				d.vis = clearPath(o, root.Position, { char, LP.Character }) or clearPath(o, head.Position, { char, LP.Character })
			end
			local col = d.vis and CFG.vis.shown or CFG.vis.hidden
			hl.FillColor = col
			hl.FillTransparency = CFG.vis.trans
			hl.OutlineColor = col
			hl.OutlineTransparency = 0
		else
			hl.FillColor = pcol(plr, CFG.chams.color)
			hl.FillTransparency = CFG.chams.on and CFG.chams.trans or 1
			hl.OutlineColor = pcol(plr, CFG.outline.color)
			hl.OutlineTransparency = CFG.outline.on and 0 or 1
		end
		hl.Enabled = true
	elseif d.hl then
		d.hl.Enabled = false
	end

	-- Glow
	if CFG.glow.on then
		local l = d.light
		if not l or l.Parent ~= root then
			if l then l:Destroy() end
			l = new("PointLight", { Shadows = false }, root)
			d.light = l
		end
		l.Color = pcol(plr, CFG.glow.color)
		l.Range = CFG.glow.range
		l.Brightness = CFG.glow.bright
		l.Enabled = true
	elseif d.light then
		d.light.Enabled = false
	end

	-- Стрелки
	local rp = cam:WorldToViewportPoint(root.Position)
	local off = rp.Z <= 0 or rp.X < 0 or rp.X > vs.X or rp.Y < 0 or rp.Y > vs.Y
	if CFG.arrows.on and off then
		local a = d.arrow
		if not a then
			a = mkArrow(espGui)
			d.arrow = a
			d.arrowF = a.frame
		end
		local center = vs / 2
		local dir
		if rp.Z > 0 then
			dir = Vector2.new(rp.X, rp.Y) - center
		else
			local v = cam.CFrame:PointToObjectSpace(root.Position)
			dir = Vector2.new(v.X, -v.Y)
		end
		if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
		dir = dir.Unit
		local R = math.min(CFG.arrows.radius, math.min(vs.X, vs.Y) / 2 - 24)
		local pos = center + dir * R
		a.frame.Position = UDim2.fromOffset(pos.X, pos.Y)
		a.frame.Rotation = math.deg(math.atan2(dir.Y, dir.X))
		paintArrow(a, pcol(plr, CFG.arrows.color), CFG.arrows.size)
		a.frame.Visible = true
	elseif d.arrowF then
		d.arrowF.Visible = false
	end

	-- Границы
	local needBox = CFG.box2d.on or CFG.corner.on or CFG.fill.on or CFG.box3d.on or CFG.name.on or CFG.dist.on or CFG.health.on or CFG.avatar.on
	local pts, allFront
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	if needBox then
		local cf, size = char:GetBoundingBox()
		local hs = size / 2
		pts, allFront = {}, true
		for i = 0, 7 do
			local x = (i % 2) * 2 - 1
			local y = (math.floor(i / 2) % 2) * 2 - 1
			local z = math.floor(i / 4) * 2 - 1
			local p = cam:WorldToViewportPoint(cf:PointToWorldSpace(Vector3.new(x * hs.X, y * hs.Y, z * hs.Z)))
			pts[i] = p
			if p.Z <= 0 then
				allFront = false
			else
				x0 = math.min(x0, p.X); y0 = math.min(y0, p.Y)
				x1 = math.max(x1, p.X); y1 = math.max(y1, p.Y)
			end
		end
	end
	local rect = pts ~= nil and allFront

	-- заливка
	if CFG.fill.on and rect then
		local f = d.fill
		if not f then
			f = mkBox()
			d.fill = f
			d.fillG = new("UIGradient", { Rotation = 90 }, f)
		end
		f.Position = UDim2.fromOffset(x0, y0)
		f.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		f.BackgroundTransparency = CFG.fill.trans
		d.fillG.Color = ColorSequence.new(CFG.fill.c1, CFG.fill.c2)
		f.Visible = true
	elseif d.fill then
		d.fill.Visible = false
	end

	-- Box 2D
	if CFG.box2d.on and rect then
		local b = d.box
		if not b then
			b = new("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
			d.box = b
			d.boxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		end
		b.Position = UDim2.fromOffset(x0, y0)
		b.Size = UDim2.fromOffset(x1 - x0, y1 - y0)
		d.boxS.Color = pcol(plr, CFG.box2d.color)
		b.Visible = true
	elseif d.box then
		d.box.Visible = false
	end

	-- Углы
	if CFG.corner.on and rect then
		if not d.cn then
			d.cn = {}
			for i = 1, 8 do d.cn[i] = mkBox() end
		end
		local l = math.min(CFG.corner.len, (x1 - x0) / 2, (y1 - y0) / 2)
		setCorners(d.cn, x0, y0, x1, y1, l, 2, pcol(plr, CFG.corner.color))
	else
		hideList(d.cn)
	end

	-- Box 3D
	if CFG.box3d.on and pts then
		if not d.e3 then
			d.e3 = {}
			for i = 1, 12 do d.e3[i] = mkLine(espGui) end
		end
		local c3 = pcol(plr, CFG.box3d.color)
		for i, e in ipairs(EDGES) do
			local a, b = pts[e[1]], pts[e[2]]
			if a.Z > 0 and b.Z > 0 then
				setLine(d.e3[i], Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), c3, TH)
			else
				d.e3[i].Visible = false
			end
		end
	else
		hideList(d.e3)
	end

	-- Ник (фиксированный размер текста, не зависит от дистанции)
	if CFG.name.on and rect then
		local t = d.name
		if not t then t = mkText(); d.name = t end
		t.AnchorPoint = Vector2.new(.5, 1)
		t.TextSize = CFG.name.size
		t.Size = UDim2.fromOffset(220, CFG.name.size + 2)
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y0 - 3)
		t.Text = plr.DisplayName
		t.TextColor3 = pcol(plr, CFG.name.color)
		t.Visible = true
	elseif d.name then
		d.name.Visible = false
	end

	-- Дистанция (фиксированный размер)
	if CFG.dist.on and rect then
		local t = d.dist
		if not t then t = mkText(); d.dist = t end
		t.AnchorPoint = Vector2.new(.5, 0)
		t.TextSize = CFG.dist.size
		t.Size = UDim2.fromOffset(220, CFG.dist.size + 2)
		t.Position = UDim2.fromOffset((x0 + x1) / 2, y1 + 3)
		t.Text = math.floor((cam.CFrame.Position - root.Position).Magnitude) .. "m"
		t.TextColor3 = pcol(plr, CFG.dist.color)
		t.Visible = true
	elseif d.dist then
		d.dist.Visible = false
	end

	-- Здоровье (тонкая полоска, свой цвет)
	if CFG.health.on and rect then
		local bg = d.hpBg
		if not bg then
			bg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .35, BorderSizePixel = 0, Visible = false }, espGui)
			d.hpBg = bg
			d.hpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, bg)
		end
		local th = CFG.health.thick
		local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
		bg.Position = UDim2.fromOffset(x0 - th - 3, y0)
		bg.Size = UDim2.fromOffset(th, y1 - y0)
		d.hpFill.Size = UDim2.fromScale(1, frac)
		if CFG.health.dyn then
			d.hpFill.BackgroundColor3 = Color3.fromRGB(255, 60, 60):Lerp(CFG.health.color, frac)
		else
			d.hpFill.BackgroundColor3 = CFG.health.color
		end
		bg.Visible = true
	elseif d.hpBg then
		d.hpBg.Visible = false
	end

	-- Аватар в круге
	if CFG.avatar.on and rect then
		local a = d.av
		if not a then
			a = new("ImageLabel", {
				AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = Color3.fromRGB(20, 20, 28), BorderSizePixel = 0,
				Visible = false, Image = avatarUrl(plr.UserId),
			}, espGui)
			new("UICorner", { CornerRadius = UDim.new(1, 0) }, a)
			d.avS = new("UIStroke", { Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, a)
			d.av = a
		end
		local sz = CFG.avatar.size
		a.Size = UDim2.fromOffset(sz, sz)
		a.Position = UDim2.fromOffset(x1 + sz / 2 + 6, y0 + sz / 2)
		d.avS.Color = pcol(plr, WHITE)
		a.Visible = true
	elseif d.av then
		d.av.Visible = false
	end

	-- Голова
	local head = char:FindFirstChild("Head")
	if CFG.head.on and head then
		local hp = cam:WorldToViewportPoint(head.Position)
		if hp.Z > 0 then
			local up = cam.CFrame.UpVector * (head.Size.Y / 2)
			local pt = cam:WorldToViewportPoint(head.Position + up)
			local pb = cam:WorldToViewportPoint(head.Position - up)
			local diam = math.max(6, math.abs(pt.Y - pb.Y))
			local r = d.ring
			if not r then
				r = new("Frame", { AnchorPoint = Vector2.new(.5, .5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, espGui)
				new("UICorner", { CornerRadius = UDim.new(1, 0) }, r)
				d.ringS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, r)
				d.ring = r
			end
			r.Position = UDim2.fromOffset(hp.X, hp.Y)
			r.Size = UDim2.fromOffset(diam, diam)
			d.ringS.Color = pcol(plr, CFG.head.color)
			r.Visible = true
		elseif d.ring then
			d.ring.Visible = false
		end
	elseif d.ring then
		d.ring.Visible = false
	end

	-- Skeleton
	if CFG.skel.on then
		local list = hum.RigType == Enum.HumanoidRigType.R15 and R15 or R6
		if not d.sk then
			d.sk = {}
			for i = 1, 14 do d.sk[i] = mkLine(espGui) end
		end
		local sc = pcol(plr, CFG.skel.color)
		for i = 1, 14 do
			local pr, line = list[i], d.sk[i]
			if pr then
				local a, b = char:FindFirstChild(pr[1]), char:FindFirstChild(pr[2])
				if a and b then
					local pa = cam:WorldToViewportPoint(a.Position)
					local pb = cam:WorldToViewportPoint(b.Position)
					if pa.Z > 0 and pb.Z > 0 then
						setLine(line, Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y), sc, TH)
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			else
				line.Visible = false
			end
		end
	else
		hideList(d.sk)
	end

	-- Tracers
	if CFG.tracer.on and rp.Z > 0 then
		local o = Vector2.new(vs.X / 2, vs.Y)
		if CFG.tracer.origin == "Top" then
			o = Vector2.new(vs.X / 2, 0)
		elseif CFG.tracer.origin == "Crosshair" then
			o = Vector2.new(vs.X / 2, vs.Y / 2)
		end
		if not d.tr then d.tr = mkLine(espGui) end
		setLine(d.tr, o, Vector2.new(rp.X, rp.Y), pcol(plr, CFG.tracer.color), TH)
	elseif d.tr then
		d.tr.Visible = false
	end
end

track(RunService.RenderStepped:Connect(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			local d = S[plr]
			if not d then d = {}; S[plr] = d end
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
			if not CFG.esp.on or not hum or not root or hum.Health <= 0
				or (cam.CFrame.Position - root.Position).Magnitude > CFG.esp.maxDist or not allowed(plr) then
				hideAll(d)
			else
				drawPlayer(d, plr, char, hum, root, cam, vs)
			end
		end
	end
end))

----------------------------------------------------------------
-- MM2: роли, карта, монеты, пистолет
----------------------------------------------------------------
local mapModel, coinList = nil, {}
local function scanMap()
	local found
	for _, m in ipairs(Workspace:GetChildren()) do
		if m:IsA("Model") and m:FindFirstChild("CoinContainer") then found = m break end
	end
	mapModel = found
	local list = {}
	if found then
		for _, c in ipairs(found.CoinContainer:GetChildren()) do
			if c:IsA("BasePart") then list[#list + 1] = c end
		end
	end
	coinList = list
end

task.spawn(function()
	local n = 0
	while alive do
		for _, p in ipairs(Players:GetPlayers()) do roles[p] = scanRole(p) end
		if n % 4 == 0 then pcall(scanMap) end
		n = n + 1
		task.wait(0.25)
	end
end)
task.spawn(function()
	while alive do
		for _, f in ipairs(listUpdaters) do pcall(f) end
		task.wait(1)
	end
end)

-- Gun ESP / Coin ESP
local gunHL, gunTxt, gunLn
local coinPool = {}
track(RunService.RenderStepped:Connect(function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize

	local g = Workspace:FindFirstChild("GunDrop")
	local part = g and (g:IsA("BasePart") and g or g:FindFirstChildWhichIsA("BasePart", true))
	if CFG.gun.on and g and part then
		if not gunHL then
			gunHL = new("Highlight", { DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, FillTransparency = .5 }, espGui)
			gunTxt = mkText()
			gunLn = mkLine(espGui)
		end
		gunHL.Adornee = g
		gunHL.FillColor = CFG.gun.color
		gunHL.OutlineColor = CFG.gun.color
		gunHL.Enabled = true
		local p = cam:WorldToViewportPoint(part.Position + Vector3.new(0, 1.5, 0))
		if CFG.gun.text and p.Z > 0 then
			gunTxt.AnchorPoint = Vector2.new(.5, 1)
			gunTxt.Position = UDim2.fromOffset(p.X, p.Y)
			gunTxt.Text = "Gun [" .. math.floor((cam.CFrame.Position - part.Position).Magnitude) .. "m]"
			gunTxt.TextColor3 = CFG.gun.textColor
			gunTxt.Visible = true
		else
			gunTxt.Visible = false
		end
		if CFG.gun.tracer and p.Z > 0 then
			setLine(gunLn, Vector2.new(vs.X / 2, vs.Y), Vector2.new(p.X, p.Y), CFG.gun.tracerColor, TH)
		else
			gunLn.Visible = false
		end
	elseif gunHL then
		gunHL.Enabled = false
		gunTxt.Visible = false
		gunLn.Visible = false
	end

	local n = 0
	if CFG.coin.on then
		for _, c in ipairs(coinList) do
			if n < 60 and c.Parent then
				local p = cam:WorldToViewportPoint(c.Position)
				if p.Z > 0 and p.X > -20 and p.X < vs.X + 20 and p.Y > -20 and p.Y < vs.Y + 20 then
					n = n + 1
					local e = coinPool[n]
					if not e then
						e = {
							dot = new("Frame", { AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(8, 8), BorderSizePixel = 0, Visible = false }, espGui),
							txt = mkText(),
						}
						corner(e.dot, 4)
						e.txt.Size = UDim2.fromOffset(60, 12)
						e.txt.TextSize = 11
						e.txt.AnchorPoint = Vector2.new(.5, 0)
						coinPool[n] = e
					end
					e.dot.Position = UDim2.fromOffset(p.X, p.Y)
					e.dot.BackgroundColor3 = CFG.coin.color
					e.dot.Visible = true
					e.txt.Position = UDim2.fromOffset(p.X, p.Y + 6)
					e.txt.Text = "Coin"
					e.txt.TextColor3 = CFG.coin.textColor
					e.txt.Visible = CFG.coin.text
				end
			end
		end
	end
	for i = n + 1, #coinPool do
		coinPool[i].dot.Visible = false
		coinPool[i].txt.Visible = false
	end
end))

----------------------------------------------------------------
-- FPS
----------------------------------------------------------------
local fpsLbl = new("TextLabel", {
	AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .45,
	BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = WHITE, Text = "60 FPS", Visible = false,
}, espGui)
corner(fpsLbl, 6)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, fpsLbl)
do
	local acc, frames, shown = 0, 0, 60
	track(RunService.RenderStepped:Connect(function(dt)
		acc = acc + dt
		frames = frames + 1
		if acc >= 0.25 then
			shown = math.floor(frames / acc + .5)
			acc, frames = 0, 0
		end
		fpsLbl.Visible = CFG.fps.on
		if CFG.fps.on then
			fpsLbl.Text = (CFG.fps.custom and tostring(CFG.fps.value) or tostring(shown)) .. " FPS"
			fpsLbl.TextColor3 = CFG.fps.color
			fpsLbl.AnchorPoint = Vector2.new(CFG.fps.px, CFG.fps.py)
			fpsLbl.Position = UDim2.fromScale(CFG.fps.px, CFG.fps.py)
		end
	end))
end

----------------------------------------------------------------
-- HAT (линии, радужные) / TRAILS / FOOTSTEPS
----------------------------------------------------------------
local hats, trails = {}, {}

local function hatSig()
	local h = CFG.hat
	return table.concat({ h.style, h.lines, h.size, h.trans, tostring(h.rainbow), tostring(h.color) }, "|")
end
local function addLine(model, head, a, b, col, k)
	local mid = (a + b) / 2
	local len = (b - a).Magnitude
	local rel = CFrame.lookAt(mid, b)
	local p = new("Part", {
		Size = Vector3.new(0.05 * k + 0.02, 0.05 * k + 0.02, len), Color = col, Material = Enum.Material.Neon,
		Anchored = false, CanCollide = false, CanTouch = false, CanQuery = false, Massless = true, CastShadow = false,
		CFrame = head.CFrame * rel,
	}, model)
	new("Weld", { Part0 = head, Part1 = p, C0 = rel }, p)
	return p
end
local function buildHat(char, head)
	local H = CFG.hat
	local k = H.size / 100
	local m = new("Model", { Name = "NH_Hat" })
	local top = head.Size.Y / 2
	local apexY = top + 0.95 * k
	local baseY = top + 0.05 * k
	local R = 1.4 * k
	local N = H.lines
	local lines = {}
	if H.style ~= "Solid" then
		local apex = Vector3.new(0, apexY, 0)
		local t = 0.55
		local ra, y = R * t, apexY + (baseY - apexY) * t
		for i = 1, N do
			local a1 = 2 * math.pi * (i - 1) / N
			local a2 = 2 * math.pi * i / N
			local c = H.rainbow and Color3.fromHSV((i - 1) / N, 0.9, 1) or H.color
			local rimA = Vector3.new(math.cos(a1) * R, baseY, math.sin(a1) * R)
			local rimB = Vector3.new(math.cos(a2) * R, baseY, math.sin(a2) * R)
			local midA = Vector3.new(math.cos(a1) * ra, y, math.sin(a1) * ra)
			local midB = Vector3.new(math.cos(a2) * ra, y, math.sin(a2) * ra)
			lines[#lines + 1] = { p = addLine(m, head, apex, rimA, c, k), i = i }
			lines[#lines + 1] = { p = addLine(m, head, rimA, rimB, c, k), i = i }
			lines[#lines + 1] = { p = addLine(m, head, midA, midB, c, k), i = i }
		end
	end
	if H.style ~= "Lines" then
		local rel = CFrame.new(0, top + 0.45 * k, 0)
		local p = new("Part", {
			Size = Vector3.new(1, 1, 1), Color = H.color, Material = Enum.Material.SmoothPlastic, Transparency = H.trans,
			Anchored = false, CanCollide = false, CanTouch = false, CanQuery = false, Massless = true, CastShadow = false,
			CFrame = head.CFrame * rel,
		}, m)
		new("SpecialMesh", { MeshType = Enum.MeshType.FileMesh, MeshId = "rbxassetid://1033714", Scale = Vector3.new(1.7, 1.1, 1.7) * k }, p)
		new("Weld", { Part0 = head, Part1 = p, C0 = rel }, p)
	end
	m.Parent = char
	return m, lines
end
local function destroyHat(h)
	if h then pcall(function() h.m:Destroy() end) end
end
local function updateHat(plr, cam)
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local h = hats[plr]
	local want = CFG.hat.on and head and hum and hum.Health > 0 and (CFG.hat.scope == "Everyone" or plr == LP)
	if want then
		local sig = hatSig()
		if not h or h.head ~= head or h.sig ~= sig or (not h.m.Parent and not h.hidden) then
			destroyHat(h)
			local m, lines = buildHat(char, head)
			h = { m = m, lines = lines, head = head, sig = sig, hidden = false }
			hats[plr] = h
		end
		local hide = plr == LP and cam and (cam.CFrame.Position - head.Position).Magnitude < 1.8
		if hide and not h.hidden then
			h.m.Parent = nil
			h.hidden = true
		elseif not hide and h.hidden then
			h.m.Parent = char
			h.hidden = false
		end
	elseif h then
		destroyHat(h)
		hats[plr] = nil
	end
end
task.spawn(function()
	while alive do
		local cam = Workspace.CurrentCamera
		local t = os.clock() * 0.25
		for _, plr in ipairs(Players:GetPlayers()) do
			pcall(updateHat, plr, cam)
			local h = hats[plr]
			if h and CFG.hat.rainbow and CFG.hat.anim then
				local N = CFG.hat.lines
				for _, ln in ipairs(h.lines) do
					ln.p.Color = Color3.fromHSV(((ln.i - 1) / N + t) % 1, 0.9, 1)
				end
			end
		end
		task.wait(0.07)
	end
end)

local function destroyTrail(t)
	if t then
		pcall(function() t.tr:Destroy() end)
		pcall(function() t.a0:Destroy() end)
		pcall(function() t.a1:Destroy() end)
	end
end
local function updateTrail(plr)
	local char = plr.Character
	local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
	local t = trails[plr]
	if CFG.trail.on and root and (CFG.trail.scope == "Everyone" or plr == LP) then
		if not t or not t.tr.Parent or t.a0.Parent ~= root then
			destroyTrail(t)
			local a0 = new("Attachment", { Name = "NH_T0" }, root)
			local a1 = new("Attachment", { Name = "NH_T1" }, root)
			local trl = new("Trail", { Name = "NH_Trail", Attachment0 = a0, Attachment1 = a1, FaceCamera = true, MinLength = 0.05 }, root)
			t = { a0 = a0, a1 = a1, tr = trl }
			trails[plr] = t
		end
		local w = CFG.trail.width
		t.a0.Position = Vector3.new(0, w / 2, 0)
		t.a1.Position = Vector3.new(0, -w / 2, 0)
		t.tr.Lifetime = CFG.trail.len
		t.tr.Color = ColorSequence.new(CFG.trail.color)
		t.tr.Transparency = NumberSequence.new(0.1, 1)
		t.tr.LightEmission = 1
		t.tr.Enabled = true
	elseif t then
		destroyTrail(t)
		trails[plr] = nil
	end
end
task.spawn(function()
	while alive do
		for _, plr in ipairs(Players:GetPlayers()) do pcall(updateTrail, plr) end
		task.wait(0.2)
	end
end)

-- Следы (анимированные круги на земле)
local stepFolder = new("Folder", { Name = "NH_Steps" }, Workspace)
local stepCount, stepState = 0, {}
local rayS = RaycastParams.new()
rayS.FilterType = Enum.RaycastFilterType.Exclude
local function spawnStep(root, char, side)
	rayS.FilterDescendantsInstances = { char, stepFolder }
	local res = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayS)
	if not res then return end
	local Sp = CFG.steps
	local d = Sp.size
	local pos = res.Position + Vector3.new(0, 0.06, 0)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 0.01 then flat = Vector3.new(0, 0, -1) end
	local base = CFrame.lookAt(pos, pos + flat)
	local col = Sp.rainbow and Color3.fromHSV((os.clock() * 0.4) % 1, 1, 1) or Sp.color
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
		Material = Enum.Material.Neon, Color = col, Transparency = 0.15,
	}, stepFolder)
	local s0, s1
	if Sp.shape == "Circle" then
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2)
		s0 = Vector3.new(0.1, d * 0.4, d * 0.4); s1 = Vector3.new(0.1, d * 1.8, d * 1.8)
	elseif Sp.shape == "Square" then
		p.CFrame = base
		s0 = Vector3.new(d * 0.4, 0.1, d * 0.4); s1 = Vector3.new(d * 1.8, 0.1, d * 1.8)
	elseif Sp.shape == "Diamond" then
		p.CFrame = base * CFrame.Angles(0, math.pi / 4, 0)
		s0 = Vector3.new(d * 0.4, 0.1, d * 0.4); s1 = Vector3.new(d * 1.6, 0.1, d * 1.6)
	else -- Foot
		p.CFrame = base * CFrame.new(side * d * 0.35, 0, 0)
		s0 = Vector3.new(d * 0.3, 0.1, d * 0.7); s1 = Vector3.new(d * 0.5, 0.1, d * 1.1)
	end
	p.Size = s0
	stepCount = stepCount + 1
	TweenService:Create(p, TweenInfo.new(Sp.dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = s1, Transparency = 1 }):Play()
	task.delay(Sp.dur + 0.1, function()
		pcall(function() p:Destroy() end)
		stepCount = stepCount - 1
	end)
end
task.spawn(function()
	while alive do
		if CFG.steps.on then
			for _, plr in ipairs(Players:GetPlayers()) do
				if CFG.steps.scope == "Everyone" or plr == LP then
					local char = plr.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local root = char and char:FindFirstChild("HumanoidRootPart")
					if hum and root and hum.Health > 0 and hum.FloorMaterial ~= Enum.Material.Air then
						local st = stepState[plr]
						if not st then
							st = { pos = root.Position, side = 1 }
							stepState[plr] = st
						end
						local spacing = math.max(1.8, CFG.steps.size * 0.9)
						if (root.Position - st.pos).Magnitude >= spacing and stepCount < 200 then
							st.pos = root.Position
							st.side = -st.side
							pcall(spawnStep, root, char, st.side)
						end
					end
				end
			end
		end
		task.wait(0.04)
	end
end)

track(Players.PlayerRemoving:Connect(function(p)
	local d = S[p]
	if d then destroyData(d); S[p] = nil end
	if hats[p] then destroyHat(hats[p]); hats[p] = nil end
	if trails[p] then destroyTrail(trails[p]); trails[p] = nil end
	roles[p] = nil
	stepState[p] = nil
end))

----------------------------------------------------------------
-- FOV / Third person
----------------------------------------------------------------
local fovOn, fovSaved = false, nil
RunService:BindToRenderStep("NH_FOV", Enum.RenderPriority.Camera.Value + 1, function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if CFG.fov.on then
		if not fovOn then fovSaved = cam.FieldOfView end
		fovOn = true
		cam.FieldOfView = CFG.fov.val
	elseif fovOn then
		fovOn = false
		cam.FieldOfView = fovSaved or 70
	end
end)

local tpSaved
local function thirdTick()
	if CFG.third.on then
		if not tpSaved then tpSaved = { LP.CameraMode, LP.CameraMinZoomDistance, LP.CameraMaxZoomDistance } end
		pcall(function()
			LP.CameraMode = Enum.CameraMode.Classic
			LP.CameraMaxZoomDistance = 128
			LP.CameraMinZoomDistance = CFG.third.dist
		end)
	elseif tpSaved then
		pcall(function()
			LP.CameraMaxZoomDistance = tpSaved[3]
			LP.CameraMinZoomDistance = tpSaved[2]
			LP.CameraMode = tpSaved[1]
		end)
		tpSaved = nil
	end
end
task.spawn(function()
	while alive do
		thirdTick()
		task.wait(0.25)
	end
end)

----------------------------------------------------------------
-- PLAYER: walkspeed, jump, spin, noclip, fly
----------------------------------------------------------------
local flinging = false
local walkSaved, jumpSaved
local flyBV, flyBG, flyPS = nil, nil, false

local function stopFly(hum)
	if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
	if flyPS and hum then hum.PlatformStand = false end
	flyPS = false
end

track(RunService.Heartbeat:Connect(function(dt)
	local char = LP.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return end

	if CFG.walk.on then
		if not walkSaved then walkSaved = hum.WalkSpeed end
		hum.WalkSpeed = CFG.walk.val
	elseif walkSaved then
		hum.WalkSpeed = walkSaved
		walkSaved = nil
	end

	if CFG.jump.on then
		if not jumpSaved then jumpSaved = hum.JumpPower end
		hum.UseJumpPower = true
		hum.JumpPower = CFG.jump.val
	elseif jumpSaved then
		hum.JumpPower = jumpSaved
		jumpSaved = nil
	end

	if CFG.spin.on and not flinging then
		root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(CFG.spin.val * 18 * dt), 0)
	end

	if CFG.fly.on and not flinging then
		local cam = Workspace.CurrentCamera
		if not flyBV or flyBV.Parent ~= root then
			stopFly(hum)
			flyBV = new("BodyVelocity", { MaxForce = Vector3.new(9e9, 9e9, 9e9), Velocity = Vector3.zero }, root)
			flyBG = new("BodyGyro", { MaxTorque = Vector3.new(9e9, 9e9, 9e9), P = 9e4 }, root)
		end
		hum.PlatformStand = true
		flyPS = true
		local look = cam.CFrame.LookVector
		flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(look.X, 0, look.Z) + Vector3.new(0, 0, 0.0001))
		local v = Vector3.zero
		local md = hum.MoveDirection
		if md.Magnitude > 0.01 then
			local lv = cam.CFrame:VectorToObjectSpace(md)
			v = cam.CFrame.LookVector * (-lv.Z) + cam.CFrame.RightVector * lv.X
			if v.Magnitude > 0.01 then v = v.Unit end
		end
		local up = 0
		if UIS:IsKeyDown(Enum.KeyCode.Space) then up = up + 1 end
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.Q) then up = up - 1 end
		flyBV.Velocity = (v + Vector3.new(0, up, 0)) * CFG.fly.speed
	elseif flyBV then
		stopFly(hum)
	end
end))

track(RunService.Stepped:Connect(function()
	if CFG.noclip.on or CFG.farm.on or flinging then
		local char = LP.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
			end
		end
	end
end))

----------------------------------------------------------------
-- Телепорты / Автофарм / Fling
----------------------------------------------------------------
local function myRoot()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function tpTo(cf)
	local r = myRoot()
	if r then r.CFrame = cf end
end
local function tpPlayer(p)
	local c = p and p.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	if r then
		tpTo(r.CFrame * CFrame.new(0, 0, 3))
	else
		notify("Player not found")
	end
end
local function tpRole(role)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP and roles[p] == role then
			tpPlayer(p)
			return
		end
	end
	notify(role == "Murderer" and "Murderer not found" or "Sheriff not found")
end
local function mapSpawnCF()
	if not mapModel then return nil end
	local sp = mapModel:FindFirstChild("Spawns")
	if sp then
		local cands = {}
		for _, o in ipairs(sp:GetChildren()) do
			if o:IsA("BasePart") then cands[#cands + 1] = o end
		end
		if #cands > 0 then return cands[math.random(#cands)].CFrame + Vector3.new(0, 4, 0) end
	end
	local ok, pv = pcall(function() return mapModel:GetPivot() end)
	if ok then return pv * CFrame.new(0, 10, 0) end
end
local function lobbyCF()
	local lobby = Workspace:FindFirstChild("Lobby")
	if lobby then
		local sp = lobby:FindFirstChild("Spawns")
		local cands = {}
		for _, o in ipairs((sp or lobby):GetDescendants()) do
			if o:IsA("SpawnLocation") or (sp and o:IsA("BasePart")) then cands[#cands + 1] = o end
		end
		if #cands > 0 then return cands[math.random(#cands)].CFrame + Vector3.new(0, 4, 0) end
		local ok, pv = pcall(function() return lobby:GetPivot() end)
		if ok then return pv * CFrame.new(0, 6, 0) end
	end
	for _, o in ipairs(Workspace:GetDescendants()) do
		if o:IsA("SpawnLocation") then return o.CFrame + Vector3.new(0, 4, 0) end
	end
end

-- Автофарм монет (с авто-noclip)
local visited = {}
task.spawn(function()
	while alive do
		if CFG.farm.on then
			local root = myRoot()
			local coin
			if root then
				local best = math.huge
				for _, c in ipairs(coinList) do
					if c.Parent and not (visited[c] and os.clock() < visited[c]) then
						local dd = (c.Position - root.Position).Magnitude
						if dd < best then best = dd; coin = c end
					end
				end
			end
			if coin and root then
				local t0 = os.clock()
				while alive and CFG.farm.on and coin.Parent and root.Parent do
					local dt = RunService.Heartbeat:Wait()
					local diff = coin.Position - root.Position
					local m = diff.Magnitude
					if m < 1.2 or os.clock() - t0 > 12 then break end
					root.CFrame = root.CFrame + diff.Unit * math.min(CFG.farm.speed * dt, m)
					root.AssemblyLinearVelocity = Vector3.zero
				end
				if coin.Parent and root.Parent then root.CFrame = CFrame.new(coin.Position) end
				visited[coin] = os.clock() + 3
				task.wait(CFG.farm.delay)
			else
				task.wait(0.3)
			end
		else
			task.wait(0.3)
		end
	end
end)

-- Fling
local function flingTarget(p)
	if flinging then return end
	local root = myRoot()
	local tc = p and p.Character
	local tr = tc and tc:FindFirstChild("HumanoidRootPart")
	if not root or not tr then notify("Player not found") return end
	flinging = true
	local origin = root.CFrame
	local t0 = os.clock()
	while alive and os.clock() - t0 < 2.5 and tr.Parent and root.Parent do
		RunService.Heartbeat:Wait()
		root.CFrame = tr.CFrame * CFrame.new(0, 0, 0)
		root.AssemblyAngularVelocity = Vector3.new(0, 9e5, 0)
		root.AssemblyLinearVelocity = Vector3.new(9e4, 9e4, 9e4)
	end
	for _ = 1, 8 do
		if not root.Parent then break end
		root.AssemblyAngularVelocity = Vector3.zero
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = origin
		RunService.Heartbeat:Wait()
	end
	flinging = false
end
local function flingAll()
	task.spawn(function()
		for _, p in ipairs(Players:GetPlayers()) do
			if not alive then break end
			if p ~= LP then flingTarget(p) end
		end
	end)
end

----------------------------------------------------------------
-- WORLD: шейдеры, настройки мира, Xray
----------------------------------------------------------------
local origL = {}
for _, n in ipairs({ "Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "FogEnd", "FogStart", "FogColor", "GlobalShadows" }) do
	origL[n] = Lighting[n]
end
local fxCC = new("ColorCorrectionEffect", { Name = "NH_CC", Enabled = false }, Lighting)
local fxBloom = new("BloomEffect", { Name = "NH_Bloom", Enabled = false, Size = 28, Threshold = 0.85 }, Lighting)
local fxRays = new("SunRaysEffect", { Name = "NH_Rays", Enabled = false }, Lighting)
local fxBlur = new("BlurEffect", { Name = "NH_Blur", Enabled = false, Size = 0 }, Lighting)

local DEF = {
	tint = WHITE, dark = 0, contrast = 0, sat = 0, bloom = 0, fog = 0, fogc = Color3.fromRGB(200, 200, 210),
	clock = 14, bright = 2, rays = 0, particles = "None",
}
local PRESETS = {
	Blood = { tint = Color3.fromRGB(255, 120, 120), dark = 25, contrast = 25, sat = 10, bloom = 20, fog = 35, fogc = Color3.fromRGB(90, 0, 0), clock = 18, bright = 1.2 },
	Sakura = { tint = Color3.fromRGB(255, 215, 235), contrast = 5, sat = 20, bloom = 35, fog = 15, fogc = Color3.fromRGB(255, 200, 225), clock = 16, bright = 2.2, rays = 30, particles = "Sakura" },
	["4K"] = { contrast = 30, sat = 25, bloom = 15, clock = 14, bright = 2.5, rays = 15 },
	Snow = { tint = Color3.fromRGB(215, 230, 255), dark = 5, sat = -20, bloom = 25, fog = 40, fogc = Color3.fromRGB(220, 230, 245), clock = 12, bright = 2.5, particles = "Snow" },
	Sunset = { tint = Color3.fromRGB(255, 185, 130), dark = 5, contrast = 15, sat = 30, bloom = 40, fog = 15, fogc = Color3.fromRGB(255, 150, 90), clock = 18, bright = 2, rays = 50 },
	Rain = { tint = Color3.fromRGB(170, 190, 215), dark = 20, contrast = 10, sat = -25, bloom = 5, fog = 45, fogc = Color3.fromRGB(110, 125, 145), clock = 14, bright = 1.4, particles = "Rain" },
	Night = { tint = Color3.fromRGB(150, 170, 255), dark = 20, contrast = 15, sat = -5, bloom = 30, fog = 20, fogc = Color3.fromRGB(10, 15, 40), clock = 0, bright = 1 },
	Neon = { tint = Color3.fromRGB(230, 180, 255), dark = 15, contrast = 35, sat = 60, bloom = 70, fog = 10, fogc = Color3.fromRGB(40, 0, 60), clock = 0, bright = 1.4 },
	Cyberpunk = { tint = Color3.fromRGB(255, 120, 230), dark = 10, contrast = 30, sat = 50, bloom = 60, fog = 25, fogc = Color3.fromRGB(30, 0, 70), clock = 1, bright = 1.3, rays = 20 },
	Dream = { tint = Color3.fromRGB(235, 220, 255), contrast = -10, sat = 25, bloom = 55, fog = 30, fogc = Color3.fromRGB(235, 215, 255), clock = 15, bright = 2.4, rays = 40 },
	Noir = { dark = 10, contrast = 40, sat = -100, bloom = 5, fog = 15, fogc = Color3.fromRGB(60, 60, 60), clock = 14, bright = 1.6 },
	Golden = { tint = Color3.fromRGB(255, 225, 160), contrast = 10, sat = 25, bloom = 35, fog = 10, fogc = Color3.fromRGB(255, 215, 130), clock = 17, bright = 2.2, rays = 45 },
	Matrix = { tint = Color3.fromRGB(150, 255, 170), dark = 15, contrast = 25, sat = 20, bloom = 25, fog = 25, fogc = Color3.fromRGB(0, 40, 10), clock = 0, bright = 1.2 },
	Arctic = { tint = Color3.fromRGB(190, 225, 255), contrast = 15, sat = -10, bloom = 30, fog = 35, fogc = Color3.fromRGB(200, 225, 245), clock = 13, bright = 2.6, particles = "Snow" },
	Autumn = { tint = Color3.fromRGB(255, 190, 120), dark = 5, contrast = 10, sat = 25, bloom = 20, fog = 20, fogc = Color3.fromRGB(190, 120, 60), clock = 16, bright = 1.9, particles = "Sakura" },
}
local PRESET_LIST = { "None", "Blood", "Sakura", "4K", "Snow", "Sunset", "Rain", "Night", "Neon", "Cyberpunk", "Dream", "Noir", "Golden", "Matrix", "Arctic", "Autumn" }
local function applyPreset(name)
	local p = PRESETS[name] or {}
	for k, v in pairs(DEF) do
		local x = p[k]
		if x == nil then x = v end
		CFG.world[k] = x
	end
	CFG.world.on = name ~= "None"
	refreshAll()
end

-- частицы (снег / дождь / сакура)
local fxPart, fxEm, fxKind
local function clearParticles()
	if fxPart then pcall(function() fxPart:Destroy() end) end
	fxPart, fxEm, fxKind = nil, nil, nil
end
local function setParticles(kind, cam)
	if kind == "None" or not CFG.world.on then
		if fxPart then clearParticles() end
		return
	end
	if not fxPart or fxPart.Parent == nil then
		clearParticles()
		fxPart = new("Part", {
			Name = "NH_FX", Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false, Transparency = 1,
			Size = Vector3.new(70, 1, 70), CastShadow = false,
		}, Workspace)
		fxEm = new("ParticleEmitter", { EmissionDirection = Enum.NormalId.Bottom, LockedToPart = false }, fxPart)
		fxKind = nil
	end
	if fxKind ~= kind then
		fxKind = kind
		local e = fxEm
		e.Texture = "rbxasset://textures/particles/smoke_main.dds"
		e.Orientation = Enum.ParticleOrientation.FacingCamera
		e.RotSpeed = NumberRange.new(0)
		e.Rotation = NumberRange.new(0)
		if kind == "Snow" then
			e.Color = ColorSequence.new(WHITE)
			e.Size = NumberSequence.new(0.35)
			e.Lifetime = NumberRange.new(7, 9)
			e.Speed = NumberRange.new(3, 5)
			e.SpreadAngle = Vector2.new(25, 25)
			e.Rate = 250
			e.Transparency = NumberSequence.new(0.2)
			e.Acceleration = Vector3.new(0, 0, 0)
		elseif kind == "Rain" then
			e.Color = ColorSequence.new(Color3.fromRGB(170, 195, 255))
			e.Size = NumberSequence.new(0.18)
			e.Lifetime = NumberRange.new(0.6, 0.7)
			e.Speed = NumberRange.new(65, 80)
			e.SpreadAngle = Vector2.new(3, 3)
			e.Rate = 700
			e.Transparency = NumberSequence.new(0.35)
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
			e.Acceleration = Vector3.new(0, 0, 0)
		else -- Sakura
			e.Color = ColorSequence.new(Color3.fromRGB(255, 170, 205))
			e.Size = NumberSequence.new(0.45)
			e.Lifetime = NumberRange.new(9, 11)
			e.Speed = NumberRange.new(2, 4)
			e.SpreadAngle = Vector2.new(35, 35)
			e.Rate = 90
			e.Transparency = NumberSequence.new(0.1)
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-60, 60)
			e.Acceleration = Vector3.new(1.5, 0, 0)
		end
	end
	if cam then fxPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 28, 0)) end
end

local worldApplied = false
local function restoreWorld()
	for n, v in pairs(origL) do pcall(function() Lighting[n] = v end) end
	fxCC.Enabled = false; fxBloom.Enabled = false; fxRays.Enabled = false; fxBlur.Enabled = false
	clearParticles()
	worldApplied = false
end
local function applyWorld()
	local W = CFG.world
	if not W.on then
		if worldApplied then restoreWorld() end
		return
	end
	worldApplied = true
	Lighting.Brightness = W.bright
	Lighting.ClockTime = W.clock
	fxCC.Enabled = true
	fxCC.TintColor = W.tint
	fxCC.Brightness = -W.dark / 100 * 0.5
	fxCC.Contrast = W.contrast / 100
	fxCC.Saturation = W.sat / 100
	fxBloom.Enabled = W.bloom > 0
	fxBloom.Intensity = W.bloom / 100 * 2.5
	fxRays.Enabled = W.rays > 0
	fxRays.Intensity = W.rays / 100
	fxRays.Spread = 0.6
	if W.fog > 0 then
		Lighting.FogColor = W.fogc
		Lighting.FogStart = 0
		Lighting.FogEnd = math.max(80, 3000 - W.fog * 29)
	else
		Lighting.FogEnd = origL.FogEnd
		Lighting.FogStart = origL.FogStart
		Lighting.FogColor = origL.FogColor
	end
	if W.full then
		Lighting.Ambient = Color3.fromRGB(180, 180, 180)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
		Lighting.GlobalShadows = false
	else
		Lighting.Ambient = origL.Ambient
		Lighting.OutdoorAmbient = origL.OutdoorAmbient
		Lighting.GlobalShadows = origL.GlobalShadows
	end
end
task.spawn(function()
	while alive do
		pcall(applyWorld)
		task.wait(0.12)
	end
end)
do
	local lastLook
	track(RunService.RenderStepped:Connect(function(dt)
		local cam = Workspace.CurrentCamera
		if not cam then return end
		pcall(setParticles, CFG.world.on and CFG.world.particles or "None", cam)
		if CFG.world.on and CFG.world.blur > 0 then
			local look = cam.CFrame.LookVector
			if lastLook then
				local delta = (look - lastLook).Magnitude / math.max(dt, 1 / 240)
				local target = math.clamp(delta * CFG.world.blur / 100 * 6, 0, 30)
				fxBlur.Size = fxBlur.Size + (target - fxBlur.Size) * 0.3
			end
			lastLook = look
			fxBlur.Enabled = true
		else
			lastLook = nil
			fxBlur.Size = 0
			fxBlur.Enabled = false
		end
	end))
end

-- Xray (прозрачность карты только у тебя на экране)
local xrayParts = setmetatable({}, { __mode = "k" })
local xrayApplied = nil
local function xrayScan(alpha)
	local n = 0
	for _, p in ipairs(Workspace:GetDescendants()) do
		n = n + 1
		if n % 1500 == 0 then task.wait() end
		if p:IsA("BasePart") and not p:IsA("Terrain") and not string.find(p.Name, "^NH_") then
			local m = p:FindFirstAncestorOfClass("Model")
			local isChar = m and m:FindFirstChildOfClass("Humanoid")
			if not isChar and not p:IsDescendantOf(stepFolder) then
				p.LocalTransparencyModifier = alpha
				xrayParts[p] = true
			end
		end
	end
end
task.spawn(function()
	local busy = false
	while alive do
		local want = CFG.xray.on and (CFG.xray.val / 100) or nil
		if want ~= xrayApplied and not busy then
			busy = true
			if want then
				xrayScan(want)
			else
				for p in pairs(xrayParts) do pcall(function() p.LocalTransparencyModifier = 0 end) end
				xrayParts = setmetatable({}, { __mode = "k" })
			end
			xrayApplied = want
			busy = false
		elseif want and os.clock() % 3 < 0.3 and not busy then
			busy = true
			xrayScan(want)
			busy = false
		end
		task.wait(0.3)
	end
end)


----------------------------------------------------------------
-- ESP EDITOR (предпросмотр справа)
----------------------------------------------------------------
local STAGE_W, STAGE_H = PREV_W - 24, 400
local SC_W, SC_H = 160, 320
local OX, OY = (STAGE_W - SC_W) / 2, STAGE_H - SC_H - 4
local BX, BY, BW, BH = 12, 72, 136, 222
local FX, FY = BX + 8, BY + 6

do
	local a = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 22),
		Font = Enum.Font.GothamBold, Text = "ESP Editor", TextSize = 16, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
	}, Preview)
	setText(a, "ESP Editor")
	local b = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -32, 0, 14),
		Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
	}, Preview)
	setText(b, "live preview of your settings")
end

local stage = new("Frame", {
	Position = UDim2.fromOffset(12, 58), Size = UDim2.fromOffset(STAGE_W, STAGE_H),
	BackgroundColor3 = C.field, BorderSizePixel = 0, ClipsDescendants = true,
}, Preview)
corner(stage, 12)
stroke(stage, C.line, 1)
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(24, 21, 38), Color3.fromRGB(10, 10, 16)) }, stage)
local scene = new("Frame", { Position = UDim2.fromOffset(OX, OY), Size = UDim2.fromOffset(SC_W, SC_H), BackgroundTransparency = 1 }, stage)

local function pvFrame(x, y, w, h, col, rad)
	local f = new("Frame", {
		Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundColor3 = col or WHITE,
		BorderSizePixel = 0, Visible = false,
	}, scene)
	if rad then corner(f, rad) end
	return f
end

local gl1 = pvFrame(BX - 18, BY - 18, BW + 36, BH + 36, WHITE, 44)
local gl2 = pvFrame(BX - 36, BY - 36, BW + 72, BH + 72, WHITE, 60)
local floorShadow = pvFrame(BX + 14, BY + BH - 8, 108, 12, Color3.new(0, 0, 0), 6)
floorShadow.BackgroundTransparency = .55
floorShadow.Visible = true
local pvFill = pvFrame(BX, BY, BW, BH, WHITE, 0)
local pvFillG = new("UIGradient", { Rotation = 90 }, pvFill)

local BASE = Color3.fromRGB(72, 70, 96)
local pieces = {}
for _, p in ipairs({
	{ 43, 0, 34, 34, 17 }, { 30, 37, 60, 70, 8 }, { 10, 37, 18, 68, 7 },
	{ 92, 37, 18, 68, 7 }, { 31, 110, 28, 100, 7 }, { 61, 110, 28, 100, 7 },
}) do
	local f = pvFrame(FX + p[1], FY + p[2], p[3], p[4], BASE, p[5])
	f.Visible = true
	local s = stroke(f, WHITE, 1.5)
	s.Enabled = false
	pieces[#pieces + 1] = { f = f, s = s }
end

local pv3 = {}
for i = 1, 12 do pv3[i] = mkLine(scene) end
local pvSk = {}
for i = 1, 14 do pvSk[i] = mkLine(scene) end
local pvTr = mkLine(scene)

local pvBox = pvFrame(BX, BY, BW, BH, WHITE, 0)
pvBox.BackgroundTransparency = 1
local pvBoxS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvBox)
local pvCn = {}
for i = 1, 8 do pvCn[i] = pvFrame(0, 0, 4, 4, WHITE, 0) end
local pvRing = pvFrame(FX + 60 - 20, FY + 17 - 20, 40, 40, WHITE, 20)
pvRing.BackgroundTransparency = 1
local pvRingS = new("UIStroke", { Thickness = TH, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, pvRing)

local pvHatBox = new("Frame", {
	Position = UDim2.fromOffset(FX + 30, FY + 3 - 30), Size = UDim2.fromOffset(60, 30),
	BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
}, scene)
local pvHat = new("Frame", {
	AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromOffset(30, 30), Size = UDim2.fromOffset(42, 42),
	Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0,
}, pvHatBox)
local pvHatG = new("UIGradient", { Enabled = false, Rotation = 0 }, pvHat)
do
	local keys = {}
	for i = 0, 6 do keys[#keys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(math.min(i / 6, .999), 1, 1)) end
	pvHatG.Color = ColorSequence.new(keys)
end

local function pvText()
	return new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 14), Font = Enum.Font.GothamBold, TextSize = 12,
		TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0), Visible = false,
	}, scene)
end
local pvName, pvDist = pvText(), pvText()
pvName.Text = "NurHub"
pvName.AnchorPoint = Vector2.new(.5, 1)
pvDist.Text = "37m"
pvDist.AnchorPoint = Vector2.new(.5, 0)
pvDist.Position = UDim2.fromOffset(BX + BW / 2, BY + BH + 3)
local pvHpBg = pvFrame(BX - 8, BY, 4, BH, Color3.new(0, 0, 0), 0)
pvHpBg.BackgroundTransparency = .35
local pvHpFill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), BorderSizePixel = 0 }, pvHpBg)

local pvAv = new("ImageLabel", {
	AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = Color3.fromRGB(20, 20, 28), BorderSizePixel = 0, Visible = false,
	Image = avatarUrl(LP.UserId),
}, scene)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, pvAv)
local pvAvS = new("UIStroke", { Thickness = 2, Color = WHITE }, pvAv)

local pvArrow = mkArrow(scene)
pvArrow.frame.Position = UDim2.fromOffset(SC_W / 2 - 6, 20)

local J = {
	head = { 60, 18 }, neck = { 60, 38 }, lsh = { 32, 42 }, rsh = { 88, 42 }, lel = { 20, 72 }, rel = { 100, 72 },
	lh = { 20, 102 }, rh = { 100, 102 }, pel = { 60, 108 }, lhip = { 45, 112 }, rhip = { 75, 112 },
	lkn = { 45, 160 }, rkn = { 75, 160 }, lft = { 45, 205 }, rft = { 75, 205 },
}
local BONES = {
	{ "head", "neck" }, { "neck", "pel" }, { "neck", "lsh" }, { "lsh", "lel" }, { "lel", "lh" },
	{ "neck", "rsh" }, { "rsh", "rel" }, { "rel", "rh" }, { "pel", "lhip" }, { "lhip", "lkn" },
	{ "lkn", "lft" }, { "pel", "rhip" }, { "rhip", "rkn" }, { "rkn", "rft" },
}
local function jp(n) return Vector2.new(FX + J[n][1], FY + J[n][2]) end
local function pvCorner3(i)
	local fx0, fy0, fx1, fy1 = BX, BY + 14, BX + 122, BY + BH
	local back = bit32.band(i, 4) ~= 0 and 14 or 0
	local x = (bit32.band(i, 1) ~= 0 and fx1 or fx0) + back
	local y = (bit32.band(i, 2) ~= 0 and fy1 or fy0) - back
	return Vector2.new(x, y)
end

local function pvUpdate(t)
	local e = CFG.esp.on
	for _, p in ipairs(pieces) do
		local col = BASE
		if e and CFG.vis.on then
			col = BASE:Lerp((math.floor(t) % 2 == 0) and CFG.vis.hidden or CFG.vis.shown, 1 - CFG.vis.trans)
		elseif e and CFG.chams.on then
			col = BASE:Lerp(CFG.chams.color, 1 - CFG.chams.trans)
		end
		p.f.BackgroundColor3 = col
		p.s.Enabled = e and (CFG.outline.on or CFG.vis.on)
		p.s.Color = CFG.vis.on and ((math.floor(t) % 2 == 0) and CFG.vis.hidden or CFG.vis.shown) or CFG.outline.color
	end
	local g = e and CFG.glow.on
	gl1.Visible = g; gl2.Visible = g
	if g then
		gl1.BackgroundColor3 = CFG.glow.color; gl2.BackgroundColor3 = CFG.glow.color
		gl1.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 9, .6, .92)
		gl2.BackgroundTransparency = math.clamp(1 - CFG.glow.bright / 18, .8, .96)
	end
	pvFill.Visible = e and CFG.fill.on
	if pvFill.Visible then
		pvFill.BackgroundTransparency = CFG.fill.trans
		pvFillG.Color = ColorSequence.new(CFG.fill.c1, CFG.fill.c2)
	end
	pvBox.Visible = e and CFG.box2d.on
	pvBoxS.Color = CFG.box2d.color
	if e and CFG.corner.on then
		local l = math.min(CFG.corner.len, BW / 2, BH / 2)
		setCorners(pvCn, BX, BY, BX + BW, BY + BH, l, 2, CFG.corner.color)
	else
		for _, f in ipairs(pvCn) do f.Visible = false end
	end
	if e and CFG.box3d.on then
		for i, ed in ipairs(EDGES) do
			setLine(pv3[i], pvCorner3(ed[1]), pvCorner3(ed[2]), CFG.box3d.color, TH)
		end
	else
		hideList(pv3)
	end
	if e and CFG.skel.on then
		for i, b in ipairs(BONES) do setLine(pvSk[i], jp(b[1]), jp(b[2]), CFG.skel.color, TH) end
	else
		hideList(pvSk)
	end
	pvRing.Visible = e and CFG.head.on
	pvRingS.Color = CFG.head.color
	if e and CFG.tracer.on then
		local o = Vector2.new(SC_W / 2, STAGE_H - OY)
		if CFG.tracer.origin == "Top" then
			o = Vector2.new(SC_W / 2, -OY)
		elseif CFG.tracer.origin == "Crosshair" then
			o = Vector2.new(SC_W / 2, STAGE_H / 2 - OY)
		end
		setLine(pvTr, o, Vector2.new(FX + 60, FY + 72), CFG.tracer.color, TH)
	else
		pvTr.Visible = false
	end
	pvHatBox.Visible = CFG.hat.on
	if CFG.hat.on then
		pvHatG.Enabled = CFG.hat.rainbow
		pvHat.BackgroundColor3 = CFG.hat.rainbow and WHITE or CFG.hat.color
		pvHat.BackgroundTransparency = CFG.hat.style == "Lines" and .35 or CFG.hat.trans
		pvHatG.Offset = Vector2.new((t * 0.3) % 1 - 0.5, 0)
	end
	pvName.Visible = e and CFG.name.on
	pvName.TextColor3 = CFG.name.color
	pvName.TextSize = CFG.name.size
	pvName.Position = UDim2.fromOffset(BX + BW / 2, BY - 4 - (CFG.hat.on and 28 or 0))
	pvDist.Visible = e and CFG.dist.on
	pvDist.TextColor3 = CFG.dist.color
	pvDist.TextSize = CFG.dist.size
	pvHpBg.Visible = e and CFG.health.on
	if pvHpBg.Visible then
		local frac = 0.7 + 0.3 * math.sin(t * 1.5)
		pvHpBg.Size = UDim2.fromOffset(CFG.health.thick, BH)
		pvHpBg.Position = UDim2.fromOffset(BX - CFG.health.thick - 3, BY)
		pvHpFill.Size = UDim2.fromScale(1, frac)
		pvHpFill.BackgroundColor3 = CFG.health.dyn and Color3.fromRGB(255, 60, 60):Lerp(CFG.health.color, frac) or CFG.health.color
	end
	pvAv.Visible = e and CFG.avatar.on
	if pvAv.Visible then
		local sz = CFG.avatar.size
		pvAv.Size = UDim2.fromOffset(sz, sz)
		pvAv.Position = UDim2.fromOffset(BX + BW + sz / 2 + 6, BY + sz / 2)
	end
	pvArrow.frame.Visible = e and CFG.arrows.on
	if pvArrow.frame.Visible then
		pvArrow.frame.Rotation = (t * 50) % 360
		paintArrow(pvArrow, CFG.arrows.color, math.min(CFG.arrows.size, 30))
	end
end

----------------------------------------------------------------
-- Меню: открыть / закрыть
----------------------------------------------------------------
local menuOpen = false
local menuTok, pvTok = 0, 0
local liveUpdaters = {}

local function showPreview(v)
	pvTok = pvTok + 1
	local my = pvTok
	if v then
		Preview.Visible = true
		tw(Preview, .5, { GroupTransparency = UI.alpha / 100 })
	else
		tw(Preview, .22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(.25, function()
			if pvTok == my then Preview.Visible = false end
		end)
	end
end
onTabChanged = function(name)
	if menuOpen then showPreview(name == "Visual") end
end
local function applyAlpha()
	if menuOpen then
		Main.GroupTransparency = UI.alpha / 100
		if Preview.Visible then Preview.GroupTransparency = UI.alpha / 100 end
	end
end

local function setMenu(open)
	if open == menuOpen then return end
	menuOpen = open
	menuTok = menuTok + 1
	local my = menuTok
	if open then
		Root.Visible = true
		tw(Main, .4, { GroupTransparency = UI.alpha / 100 })
		tw(animScale, .5, { Scale = 1 }, Enum.EasingStyle.Back)
		if current == "Visual" then showPreview(true) end
	else
		tw(Main, .25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw(animScale, .28, { Scale = .9 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		showPreview(false)
		task.delay(.3, function()
			if menuTok == my then Root.Visible = false end
		end)
	end
end

----------------------------------------------------------------
-- СТРАНИЦА VISUAL
----------------------------------------------------------------
local function pct(v) return math.floor(v * 100 + .5) .. "%" end
local function px(v) return v .. " px" end

local sfV = createTab("Visual", "eye", "esp & render")
do
	local L, R = Columns(sfV)

	local cGen = Card(L, "General")
	Toggle(cGen, "ESP master", CFG.esp, "on")
	Toggle(cGen, "Role colors", CFG.esp, "roleColors")
	Slider(cGen, "Max distance", 100, 5000, CFG.esp, "maxDist", { fmt = function(v) return v .. " st" end })
	Toggle(cGen, "ESP for...", nil, nil, function(dr)
		Dropdown(dr, "Show", { "All", "Murderer", "Sheriff", "Player" }, CFG.espFor, "mode")
		local cur = new("TextLabel", {
			BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14), Font = Enum.Font.GothamMedium, TextSize = 11,
			TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
		}, dr)
		local ovr = { c = WHITE }
		local picker
		local function sync()
			local nm = CFG.espFor.target
			cur.Text = tr("Color for") .. ": " .. (nm ~= "" and nm or "—")
			local c = CFG.espFor.colors[nm]
			if not c then
				local p = nm ~= "" and Players:FindFirstChild(nm)
				c = (p and ROLE_COL[roles[p] or ""]) or WHITE
			end
			ovr.c = c
			if picker then picker.set(c) end
		end
		PlayerList(dr, 150, function(p)
			if CFG.espFor.target == p.Name and CFG.espFor.mode == "Player" then
				CFG.espFor.mode = "All"
			else
				CFG.espFor.mode = "Player"
			end
			CFG.espFor.target = p.Name
			refreshAll()
			sync()
		end, function(p) return CFG.espFor.target == p.Name end)
		picker = ColorPicker(dr, ovr, "c", nil, function(c)
			if CFG.espFor.target ~= "" then CFG.espFor.colors[CFG.espFor.target] = c end
		end)
		Button(dr, "Reset color", function()
			if CFG.espFor.target ~= "" then CFG.espFor.colors[CFG.espFor.target] = nil end
			sync()
		end)
		refreshers[#refreshers + 1] = sync
		onLang(sync)
	end)

	local cBox = Card(L, "Boxes")
	Toggle(cBox, "Esp box 2D", CFG.box2d, "on", function(dr) ColorPicker(dr, CFG.box2d, "color") end)
	Toggle(cBox, "Esp box 3D", CFG.box3d, "on", function(dr) ColorPicker(dr, CFG.box3d, "color") end)
	Toggle(cBox, "Corner box", CFG.corner, "on", function(dr)
		ColorPicker(dr, CFG.corner, "color")
		Slider(dr, "Length", 8, 80, CFG.corner, "len", { fmt = px })
	end)
	Toggle(cBox, "Filled box", CFG.fill, "on", function(dr)
		GradientPicker(dr, CFG.fill, "c1", "c2")
		Slider(dr, "Transparency", 0, 100, CFG.fill, "trans", { div = 100, fmt = pct })
	end)

	local cInfo = Card(L, "Info")
	Toggle(cInfo, "Show nickname", CFG.name, "on", function(dr)
		ColorPicker(dr, CFG.name, "color")
		Slider(dr, "Text size", 8, 22, CFG.name, "size")
	end)
	Toggle(cInfo, "Show distance", CFG.dist, "on", function(dr)
		ColorPicker(dr, CFG.dist, "color")
		Slider(dr, "Text size", 8, 22, CFG.dist, "size")
	end)
	Toggle(cInfo, "Show health", CFG.health, "on", function(dr)
		ColorPicker(dr, CFG.health, "color", "Health bar color")
		Slider(dr, "Thickness", 1, 8, CFG.health, "thick", { fmt = px })
		Toggle(dr, "Color by health", CFG.health, "dyn")
	end)
	Toggle(cInfo, "Show avatar", CFG.avatar, "on", function(dr)
		Slider(dr, "Circle size", 16, 70, CFG.avatar, "size", { fmt = px })
	end)

	local cRen = Card(R, "Render")
	Toggle(cRen, "Chams", CFG.chams, "on", function(dr)
		ColorPicker(dr, CFG.chams, "color")
		Slider(dr, "Fill transparency", 0, 100, CFG.chams, "trans", { div = 100, fmt = pct })
	end)
	Toggle(cRen, "Outline", CFG.outline, "on", function(dr) ColorPicker(dr, CFG.outline, "color") end)
	Toggle(cRen, "Wall check chams", CFG.vis, "on", function(dr)
		ColorPicker(dr, CFG.vis, "hidden", "Behind wall color")
		ColorPicker(dr, CFG.vis, "shown", "Visible color")
		Slider(dr, "Fill transparency", 0, 100, CFG.vis, "trans", { div = 100, fmt = pct })
	end)
	Toggle(cRen, "Glow", CFG.glow, "on", function(dr)
		ColorPicker(dr, CFG.glow, "color")
		Slider(dr, "Range", 5, 60, CFG.glow, "range")
		Slider(dr, "Brightness", 5, 60, CFG.glow, "bright", { div = 10 })
	end)

	local cLin = Card(R, "Lines")
	Toggle(cLin, "Line / Tracers", CFG.tracer, "on", function(dr)
		Dropdown(dr, "Line origin", { "Crosshair", "Bottom", "Top" }, CFG.tracer, "origin")
		ColorPicker(dr, CFG.tracer, "color")
	end)
	Toggle(cLin, "Skeleton", CFG.skel, "on", function(dr) ColorPicker(dr, CFG.skel, "color") end)
	Toggle(cLin, "Show head", CFG.head, "on", function(dr) ColorPicker(dr, CFG.head, "color") end)
	Toggle(cLin, "Enemy arrows", CFG.arrows, "on", function(dr)
		ColorPicker(dr, CFG.arrows, "color")
		Slider(dr, "Radius", 60, 400, CFG.arrows, "radius", { fmt = px })
		Slider(dr, "Size", 8, 30, CFG.arrows, "size")
	end)

	local cItems = Card(R, "Items")
	Toggle(cItems, "Gun ESP", CFG.gun, "on", function(dr)
		ColorPicker(dr, CFG.gun, "color", "ESP color")
		Toggle(dr, "Show text", CFG.gun, "text", function(d2) ColorPicker(d2, CFG.gun, "textColor", "Text color") end)
		Toggle(dr, "Tracer", CFG.gun, "tracer", function(d2) ColorPicker(d2, CFG.gun, "tracerColor", "Tracer color") end)
	end)
	Toggle(cItems, "Coin ESP", CFG.coin, "on", function(dr)
		ColorPicker(dr, CFG.coin, "color", "ESP color")
		Toggle(dr, "Show text", CFG.coin, "text", function(d2) ColorPicker(d2, CFG.coin, "textColor", "Text color") end)
	end)

	local cCam = Card(R, "Camera")
	Toggle(cCam, "Custom FOV", CFG.fov, "on", function(dr)
		Slider(dr, "Field of view", 30, 120, CFG.fov, "val")
	end)
	Toggle(cCam, "Third person", CFG.third, "on", function(dr)
		Slider(dr, "Distance", 5, 60, CFG.third, "dist")
	end)

	local cEx = Card(R, "Extras")
	Toggle(cEx, "Hat", CFG.hat, "on", function(dr)
		Dropdown(dr, "Style", { "Lines", "Solid", "Both" }, CFG.hat, "style")
		Slider(dr, "Lines count", 4, 30, CFG.hat, "lines")
		Toggle(dr, "Rainbow lines", CFG.hat, "rainbow")
		Toggle(dr, "Animated rainbow", CFG.hat, "anim")
		ColorPicker(dr, CFG.hat, "color", "Color (no rainbow / solid)")
		Slider(dr, "Transparency", 0, 100, CFG.hat, "trans", { div = 100, fmt = pct })
		Slider(dr, "Size", 50, 200, CFG.hat, "size", { fmt = function(v) return v .. "%" end })
		Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.hat, "scope")
	end)
	Toggle(cEx, "Trails", CFG.trail, "on", function(dr)
		ColorPicker(dr, CFG.trail, "color")
		Slider(dr, "Length", 2, 50, CFG.trail, "len", { div = 10, fmt = function(v) return v .. " s" end })
		Slider(dr, "Width", 2, 40, CFG.trail, "width", { div = 10 })
		Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.trail, "scope")
	end)
	Toggle(cEx, "Footsteps", CFG.steps, "on", function(dr)
		Dropdown(dr, "Shape", { "Circle", "Square", "Diamond", "Foot" }, CFG.steps, "shape")
		ColorPicker(dr, CFG.steps, "color")
		Toggle(dr, "Rainbow color", CFG.steps, "rainbow")
		Slider(dr, "Animation time", 3, 50, CFG.steps, "dur", { div = 10, fmt = function(v) return v .. " s" end })
		Slider(dr, "Size", 10, 80, CFG.steps, "size", { div = 10 })
		Dropdown(dr, "Show for", { "Everyone", "Only me" }, CFG.steps, "scope")
	end)

	local cHud = Card(R, "HUD")
	Toggle(cHud, "Show FPS", CFG.fps, "on", function(dr)
		Toggle(dr, "Custom FPS", CFG.fps, "custom")
		TextField(dr, "999", tostring(CFG.fps.value), function(txt, box)
			local n = tonumber(txt)
			if n then CFG.fps.value = math.clamp(math.floor(n), 0, 99999) end
			box.Text = tostring(CFG.fps.value)
		end)
		Label(dr, "Drag the badge across the screen", C.sub, 10)
		local st = new("Frame", {
			Size = UDim2.new(1, 0, 0, 110), BackgroundColor3 = Color3.fromRGB(30, 32, 56), BorderSizePixel = 0,
			LayoutOrder = ord(),
		}, dr)
		corner(st, 8)
		stroke(st, C.line, 1)
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(40, 44, 76), Color3.fromRGB(22, 24, 40)) }, st)
		local badge = new("TextButton", {
			AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, AutoButtonColor = false,
			Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, Text = "60 FPS",
		}, st)
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 6) }, badge)
		local function place()
			badge.AnchorPoint = Vector2.new(CFG.fps.px, CFG.fps.py)
			badge.Position = UDim2.fromScale(CFG.fps.px, CFG.fps.py)
			badge.TextColor3 = CFG.fps.color
			badge.Text = (CFG.fps.custom and tostring(CFG.fps.value) or "60") .. " FPS"
		end
		place()
		liveUpdaters[#liveUpdaters + 1] = place
		local dragging, scroller = false, nil
		badge.InputBegan:Connect(function(i)
			if isPress(i) then
				dragging = true
				scroller = badge:FindFirstAncestorOfClass("ScrollingFrame")
				if scroller then scroller.ScrollingEnabled = false end
			end
		end)
		track(UIS.InputChanged:Connect(function(i)
			if dragging and isMove(i) then
				local rel = i.Position - st.AbsolutePosition
				CFG.fps.px = math.clamp(rel.X / math.max(st.AbsoluteSize.X, 1), 0, 1)
				CFG.fps.py = math.clamp(rel.Y / math.max(st.AbsoluteSize.Y, 1), 0, 1)
				place()
			end
		end))
		track(UIS.InputEnded:Connect(function(i)
			if dragging and isPress(i) then
				dragging = false
				if scroller then scroller.ScrollingEnabled = true end
			end
		end))
		-- большие круглые цвета
		local row = new("Frame", { Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, LayoutOrder = ord() }, dr)
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
			VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder,
		}, row)
		local pk
		local cols = {
			WHITE, Color3.fromRGB(250, 215, 70), Color3.fromRGB(235, 80, 65), Color3.fromRGB(100, 205, 100),
			Color3.fromRGB(100, 200, 225), Color3.fromRGB(60, 130, 245), Color3.fromRGB(175, 90, 235),
		}
		for i, c in ipairs(cols) do
			local b = new("TextButton", {
				Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 24), BackgroundColor3 = c, BorderSizePixel = 0, LayoutOrder = i,
			}, row)
			corner(b, 12)
			b.MouseButton1Click:Connect(function()
				CFG.fps.color = c
				if pk then pk.set(c) end
				place()
			end)
		end
		pk = ColorPicker(dr, CFG.fps, "color", nil, function() place() end)
	end)
end

----------------------------------------------------------------
-- СТРАНИЦА PLAYER
----------------------------------------------------------------
local sfP = createTab("Player", "user", "movement")
do
	Single(sfP)
	local c = Card(sfP, "Movement")
	Toggle(c, "Walkspeed", CFG.walk, "on", function(dr) Slider(dr, "Speed", 16, 200, CFG.walk, "val") end)
	Toggle(c, "Jumppower", CFG.jump, "on", function(dr) Slider(dr, "Power", 50, 300, CFG.jump, "val") end)
	Toggle(c, "Spin", CFG.spin, "on", function(dr) Slider(dr, "Rotation speed", 1, 100, CFG.spin, "val") end)
	Toggle(c, "Noclip", CFG.noclip, "on")
	Toggle(c, "Fly", CFG.fly, "on", function(dr)
		Slider(dr, "Fly speed", 10, 300, CFG.fly, "speed")
		Label(dr, "Move with joystick / WASD. Space = up, Ctrl or Q = down. Look up/down to climb.", C.sub, 10)
	end)
end

----------------------------------------------------------------
-- СТРАНИЦА WORLD
----------------------------------------------------------------
local sfW = createTab("World", "globe", "shaders & xray")
do
	Single(sfW)
	local cSh = Card(sfW, "Shaders")
	Toggle(cSh, "Shaders", CFG.world, "on", function(dr)
		Dropdown(dr, "Shader preset", PRESET_LIST, CFG.world, "preset", function(n) applyPreset(n) end)
		Dropdown(dr, "Weather", { "None", "Snow", "Rain", "Sakura" }, CFG.world, "particles")
		Toggle(dr, "Fullbright", CFG.world, "full")
	end)
	local cW = Card(sfW, "World settings")
	Label(cW, "Turn on Shaders to apply these settings.", C.sub, 10)
	Slider(cW, "Brightness", 0, 50, CFG.world, "bright", { div = 10 })
	Slider(cW, "Time of day", 0, 240, CFG.world, "clock", { div = 10 })
	Slider(cW, "Darkness", 0, 100, CFG.world, "dark", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Glow (bloom)", 0, 100, CFG.world, "bloom", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Contrast", -100, 100, CFG.world, "contrast", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Saturation", -100, 100, CFG.world, "sat", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Fog", 0, 100, CFG.world, "fog", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Sun rays", 0, 100, CFG.world, "rays", { fmt = function(v) return v .. "%" end })
	Slider(cW, "Motion blur", 0, 100, CFG.world, "blur", { fmt = function(v) return v .. "%" end })
	Toggle(cW, "Tint color", nil, nil, function(dr) ColorPicker(dr, CFG.world, "tint") end)
	Toggle(cW, "Fog color", nil, nil, function(dr) ColorPicker(dr, CFG.world, "fogc") end)
	local cX = Card(sfW, "Xray")
	Toggle(cX, "Xray", CFG.xray, "on", function(dr)
		Slider(dr, "Wall transparency", 10, 95, CFG.xray, "val", { fmt = function(v) return v .. "%" end })
	end)
end

----------------------------------------------------------------
-- СТРАНИЦА TROLL
----------------------------------------------------------------
local sfT = createTab("Troll", "troll", "fun")
do
	Single(sfT)
	local c = Card(sfT, "Troll")
	Toggle(c, "Fling", nil, nil, function(dr)
		PlayerList(dr, 170, function(p)
			SEL.fling = (SEL.fling == p.Name) and "" or p.Name
		end, function(p) return SEL.fling == p.Name end)
		Button(dr, "Fling selected", function()
			local p = SEL.fling ~= "" and Players:FindFirstChild(SEL.fling)
			if p then
				task.spawn(flingTarget, p)
			else
				notify("Select a player first")
			end
		end, true)
		Button(dr, "Fling all", function() flingAll() end)
	end)
end

----------------------------------------------------------------
-- СТРАНИЦА MISC
----------------------------------------------------------------
local sfM = createTab("Misc", "misc", "tools")
do
	Single(sfM)
	local cF = Card(sfM, "Autofarm")
	Toggle(cF, "Autofarm coins", CFG.farm, "on", function(dr)
		Slider(dr, "Flight speed", 20, 200, CFG.farm, "speed")
		Slider(dr, "Farm delay", 0, 200, CFG.farm, "delay", { div = 100, fmt = function(v) return v .. " s" end })
		Label(dr, "Noclip is enabled automatically while farming.", C.sub, 10)
	end)
	local cT = Card(sfM, "Teleport")
	Toggle(cT, "Teleport to player", nil, nil, function(dr)
		PlayerList(dr, 190, function(p) tpPlayer(p) end, nil)
	end)
	Button(cT, "Teleport to spawn", function()
		local cf = lobbyCF()
		if cf then tpTo(cf) else notify("Spawn not found") end
	end)
	Button(cT, "Teleport to Map", function()
		scanMap()
		local cf = mapSpawnCF()
		if cf then tpTo(cf) else notify("Map not found") end
	end)
	Button(cT, "Teleport to murder", function() tpRole("Murderer") end)
	Button(cT, "Teleport to sheriff", function() tpRole("Sheriff") end)
end

----------------------------------------------------------------
-- СТРАНИЦА CONFIG (5 слотов)
----------------------------------------------------------------
local sfC = createTab("Config", "cfg", "configs")
do
	local store = { false, false, false, false, false }
	do
		local s = jdecode(fsRead("configs.json"))
		if type(s) == "table" then
			for i = 1, 5 do
				if type(s[i]) == "table" and s[i].name and s[i].data then store[i] = s[i] end
			end
		end
	end
	local function persist()
		local j = jencode(store)
		if j then fsWrite("configs.json", j) end
	end
	local rows = {}
	local slotsLbl
	local function render()
		local used = 0
		for i = 1, 5 do
			local e = store[i]
			local r = rows[i]
			if e then
				used = used + 1
				r.name.Text = e.name
				r.name.TextColor3 = C.text
				r.x.Visible = true
			else
				r.name.Text = tr("— empty —")
				r.name.TextColor3 = C.off
				r.x.Visible = false
			end
		end
		slotsLbl.Text = tr("Slots") .. ": " .. used .. " / 5"
	end

	local L, R = Columns(sfC)
	local cNew = Card(L, "New config")
	Label(cNew, "Save your current settings under a name", C.sub, 11)
	local nameBox = TextField(cNew, "Config name...", "", nil)
	Button(cNew, "Save", function()
		local nm = nameBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
		if nm == "" then notify("Enter a config name") return end
		local slot
		for i = 1, 5 do
			if store[i] and store[i].name == nm then slot = i break end
		end
		if not slot then
			for i = 1, 5 do
				if not store[i] then slot = i break end
			end
		end
		if not slot then notify("All 5 slots are used") return end
		store[slot] = { name = nm, data = deser(ser(CFG)) }
		persist()
		render()
		nameBox.Text = ""
		notify("Config saved")
	end, true)
	slotsLbl = new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = ord(),
	}, cNew)

	local cSv = Card(R, "Saved")
	for i = 1, 5 do
		local row = new("TextButton", {
			Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.field, BorderSizePixel = 0, AutoButtonColor = false,
			Text = "", LayoutOrder = ord(),
		}, cSv)
		corner(row, 9)
		stroke(row, C.line, 1)
		new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.fromOffset(16, 40),
			Font = Enum.Font.GothamBold, Text = tostring(i), TextSize = 12, TextColor3 = C.sub,
		}, row)
		local nm = new("TextLabel", {
			BackgroundTransparency = 1, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -74, 1, 0),
			Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		local x = new("TextButton", {
			AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -6, .5, 0), Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = C.card, BorderSizePixel = 0, AutoButtonColor = false, Font = Enum.Font.GothamBold,
			Text = "×", TextSize = 16, TextColor3 = C.text,
		}, row)
		corner(x, 7)
		rows[i] = { name = nm, x = x }
		row.MouseButton1Click:Connect(function()
			local e = store[i]
			if not e then return end
			CFG.espFor.colors = {}
			merge(CFG, deser(ser(e.data)))
			refreshAll()
			notify("Config loaded")
		end)
		x.MouseButton1Click:Connect(function()
			store[i] = false
			persist()
			render()
		end)
	end
	onLang(render)
end

----------------------------------------------------------------
-- СТРАНИЦА SETTINGS
----------------------------------------------------------------
local sfS = createTab("Settings", "gear", "menu")
do
	Single(sfS)
	local c = Card(sfS, "Menu")
	ColorPicker(c, UI, "accent", "Menu color", function() applyAccent(); saveUI() end)
	Slider(c, "Menu scale", 50, 130, UI, "scale", { fmt = function(v) return v .. "%" end, onChange = function() fit(); saveUI() end })
	Slider(c, "Menu transparency", 0, 60, UI, "alpha", { fmt = function(v) return v .. "%" end, onChange = function() applyAlpha(); saveUI() end })
	Dropdown(c, "Language", { "English", "Русский" }, UI, "lang", function() applyLang(); saveUI() end)
end

----------------------------------------------------------------
-- СТРАНИЦА INFO
----------------------------------------------------------------
local unload
local sfI = createTab("Info", "info", "about")
local bannerGrad
do
	new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, sfI)

	local banner = new("Frame", {
		Size = UDim2.new(1, 0, 0, 168), BackgroundColor3 = WHITE, BorderSizePixel = 0, LayoutOrder = ord(),
	}, sfI)
	corner(banner, 14)
	bannerGrad = new("UIGradient", { Rotation = 35 }, banner)
	onAccent(function() bannerGrad.Color = ColorSequence.new(C.accent, C.accent2) end)

	local logo = new("Frame", {
		Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(50, 50), BackgroundColor3 = WHITE, BackgroundTransparency = .8,
		BorderSizePixel = 0,
	}, banner)
	corner(logo, 25)
	stroke(logo, WHITE, 1.5, .4)
	new("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamBlack, Text = "NH",
		TextSize = 18, TextColor3 = WHITE,
	}, logo)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 20), Size = UDim2.new(1, -96, 0, 24),
		Font = Enum.Font.GothamBlack, Text = "NurHub Official", TextSize = 20, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)
	local sub = new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 46), Size = UDim2.new(1, -96, 0, 16),
		Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = Color3.fromRGB(235, 235, 255), TextXAlignment = Enum.TextXAlignment.Left,
	}, banner)
	setText(sub, "News, updates and support")

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.new(1, -36, 0, 40),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = .65, BorderSizePixel = 0,
	}, banner)
	corner(pill, 12)
	stroke(pill, WHITE, 1, .7)
	new("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0),
		Font = Enum.Font.GothamBold, Text = "t.me/NurHuboffical", TextSize = 15, TextColor3 = WHITE,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, pill)

	local cLinks = Card(sfI, "Telegram")
	Button(cLinks, "Copy link", function(b)
		local fn = (typeof(setclipboard) == "function" and setclipboard) or (typeof(toclipboard) == "function" and toclipboard)
		local ok = fn and pcall(fn, TG_LINK)
		b.Text = ok and tr("Copied!") or TG_LINK
		task.delay(1.6, function() if b.Parent then b.Text = tr("Copy link") end end)
	end, true)
	Button(cLinks, "Open Telegram", function()
		pcall(function() GuiService:OpenBrowserWindow(TG_LINK) end)
	end)

	local cAbout = Card(sfI, "About")
	Label(cAbout, "NurHub MM2 v5.0 — visuals, player, world and misc tools for Murder Mystery 2. No Drawing API: everything is built from Frame, Highlight, Trail and Lighting objects.", C.sub, 12)
	Label(cAbout, "Menu key: RightShift  •  or the NH button.", C.sub, 11)
	Button(cAbout, "Unload script", function() unload() end)
end

current = "Visual"
pages.Visual.Visible = true
pages.Visual.GroupTransparency = 0
for n in pairs(tabs) do paintTab(n, n == current, false) end

----------------------------------------------------------------
-- Кнопка NH + клавиша
----------------------------------------------------------------
local OpenBtn = new("Frame", {
	Name = "NH_Button", AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, 46, .5, 0),
	Size = UDim2.fromOffset(52, 52), BackgroundColor3 = Color3.fromRGB(14, 14, 20), BorderSizePixel = 0,
}, gui)
corner(OpenBtn, 16)
local btnScale = new("UIScale", { Scale = 1 }, OpenBtn)
local btnStroke = stroke(OpenBtn, WHITE, 2)
local btnGrad = new("UIGradient", {}, btnStroke)
onAccent(function()
	btnGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.accent), ColorSequenceKeypoint.new(.5, WHITE), ColorSequenceKeypoint.new(1, C.accent2),
	})
end)
local letterN = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(.5, 1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "N", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local letterH = new("TextLabel", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(.5, -1, .5, 0),
	Size = UDim2.fromOffset(20, 24), Font = Enum.Font.GothamBlack, Text = "H", TextSize = 20, TextColor3 = WHITE,
}, OpenBtn)
local hitBtn = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1) }, OpenBtn)
makeDraggable(hitBtn, OpenBtn, function() setMenu(not menuOpen) end)
hitBtn.MouseEnter:Connect(function() tw(btnScale, .25, { Scale = 1.1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseLeave:Connect(function() tw(btnScale, .25, { Scale = 1 }, Enum.EasingStyle.Back) end)
hitBtn.MouseButton1Down:Connect(function() tw(btnScale, .12, { Scale = .92 }) end)
hitBtn.MouseButton1Up:Connect(function() tw(btnScale, .2, { Scale = 1.1 }, Enum.EasingStyle.Back) end)

track(RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local off = math.sin(t * 2.4) * 4
	local sx = math.cos(t * 2.4) * 2
	letterN.Position = UDim2.new(.5, 1 + sx, .5, off)
	letterH.Position = UDim2.new(.5, -1 - sx, .5, -off)
	btnGrad.Rotation = (t * 120) % 360
	if bannerGrad then bannerGrad.Rotation = 35 + math.sin(t * .6) * 25 end
	if menuOpen then
		if Preview.Visible then pvUpdate(t) end
		for _, f in ipairs(liveUpdaters) do f() end
	end
end))

track(UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	if i.UserInputType == Enum.UserInputType.Keyboard and i.KeyCode == Enum.KeyCode.RightShift then
		setMenu(not menuOpen)
	end
end))

-- сохранение настроек меню (язык, цвет, масштаб, прозрачность)
task.spawn(function()
	while alive do
		if uiDirty then
			uiDirty = false
			local j = jencode(UI)
			if j then fsWrite("settings.json", j) end
		end
		task.wait(1)
	end
end)

----------------------------------------------------------------
-- Выгрузка
----------------------------------------------------------------
function unload()
	alive = false
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function() RunService:UnbindFromRenderStep("NH_FOV") end)
	pcall(function()
		local cam = Workspace.CurrentCamera
		if fovOn and cam then cam.FieldOfView = fovSaved or 70 end
	end)
	pcall(function()
		CFG.third.on = false
		thirdTick()
	end)
	pcall(function()
		local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
		stopFly(hum)
		if hum and walkSaved then hum.WalkSpeed = walkSaved end
		if hum and jumpSaved then hum.JumpPower = jumpSaved end
	end)
	pcall(restoreWorld)
	for _, f in ipairs({ fxCC, fxBloom, fxRays, fxBlur }) do pcall(function() f:Destroy() end) end
	for p in pairs(xrayParts) do pcall(function() p.LocalTransparencyModifier = 0 end) end
	for _, h in pairs(hats) do destroyHat(h) end
	for _, t in pairs(trails) do destroyTrail(t) end
	for _, d in pairs(S) do destroyData(d) end
	pcall(function() stepFolder:Destroy() end)
	local j = jencode(UI)
	if j then fsWrite("settings.json", j) end
	pcall(function() gui:Destroy() end)
	pcall(function() espGui:Destroy() end)
	ENV.NurHubMM2Unload = nil
end
ENV.NurHubMM2Unload = unload

----------------------------------------------------------------
-- Русский язык
----------------------------------------------------------------
local RU_LIST = {
	-- вкладки
	["Visual"] = "Визуал", ["Player"] = "Игрок", ["World"] = "Мир", ["Troll"] = "Троллинг", ["Misc"] = "Разное",
	["Config"] = "Конфиг", ["Settings"] = "Настройки", ["Info"] = "Инфо",
	["esp & render"] = "есп и рендер", ["movement"] = "движение", ["shaders & xray"] = "шейдеры и xray", ["fun"] = "веселье",
	["tools"] = "инструменты", ["configs"] = "конфиги", ["menu"] = "меню", ["about"] = "о скрипте",
	-- карточки
	["General"] = "Общее", ["Boxes"] = "Боксы", ["Render"] = "Рендер", ["Lines"] = "Линии", ["Items"] = "Предметы",
	["Camera"] = "Камера", ["Extras"] = "Дополнительно", ["HUD"] = "Экран", ["Movement"] = "Движение", ["Shaders"] = "Шейдеры",
	["World settings"] = "Настройки мира", ["Xray"] = "Xray", ["Autofarm"] = "Автофарм", ["Teleport"] = "Телепорт",
	["New config"] = "Новый конфиг", ["Saved"] = "Сохранённые", ["Menu"] = "Меню", ["Telegram"] = "Телеграм", ["About"] = "О скрипте",
	-- General
	["ESP master"] = "ESP главный", ["Role colors"] = "Цвета ролей", ["Max distance"] = "Макс. дистанция", ["ESP for..."] = "ESP для...",
	["Show"] = "Показывать", ["All"] = "Все", ["Murderer"] = "Убийца", ["Sheriff"] = "Шериф", ["Color for"] = "Цвет для",
	["Reset color"] = "Сбросить цвет", ["No players"] = "Нет игроков",
	-- Boxes
	["Esp box 2D"] = "Бокс 2D", ["Esp box 3D"] = "Бокс 3D", ["Corner box"] = "Угловой бокс", ["Filled box"] = "Заливка бокса",
	["Length"] = "Длина", ["Transparency"] = "Прозрачность", ["Top color"] = "Верхний цвет", ["Bottom color"] = "Нижний цвет",
	-- Info
	["Show nickname"] = "Показать ник", ["Show distance"] = "Показать дистанцию", ["Show health"] = "Показать здоровье",
	["Show avatar"] = "Показать аватар", ["Text size"] = "Размер текста", ["Health bar color"] = "Цвет полоски HP",
	["Thickness"] = "Толщина", ["Color by health"] = "Цвет по здоровью", ["Circle size"] = "Размер круга",
	-- Render
	["Chams"] = "Чамсы", ["Outline"] = "Контур", ["Wall check chams"] = "Чамсы за стеной", ["Behind wall color"] = "Цвет за стеной",
	["Visible color"] = "Цвет когда виден", ["Fill transparency"] = "Прозрачность заливки", ["Glow"] = "Свечение",
	["Range"] = "Радиус", ["Brightness"] = "Яркость",
	-- Lines
	["Line / Tracers"] = "Линии / Трейсеры", ["Line origin"] = "Начало линии", ["Crosshair"] = "Прицел", ["Bottom"] = "Низ", ["Top"] = "Верх",
	["Skeleton"] = "Скелет", ["Show head"] = "Показать голову", ["Enemy arrows"] = "Стрелки врагов", ["Radius"] = "Радиус", ["Size"] = "Размер",
	-- Items
	["Gun ESP"] = "ESP пистолета", ["Coin ESP"] = "ESP монет", ["ESP color"] = "Цвет ESP", ["Show text"] = "Показывать текст",
	["Text color"] = "Цвет текста", ["Tracer"] = "Трейсер", ["Tracer color"] = "Цвет трейсера",
	-- Camera
	["Custom FOV"] = "Свой FOV", ["Field of view"] = "Поле зрения", ["Third person"] = "Третье лицо", ["Distance"] = "Дистанция",
	-- Extras
	["Hat"] = "Шляпа", ["Style"] = "Стиль", ["Lines count"] = "Кол-во линий", ["Rainbow lines"] = "Радужные линии",
	["Animated rainbow"] = "Анимация радуги", ["Color (no rainbow / solid)"] = "Цвет (без радуги / сплошная)",
	["Solid"] = "Сплошная", ["Both"] = "Оба", ["Show for"] = "Показывать для", ["Everyone"] = "Всех", ["Only me"] = "Только я",
	["Trails"] = "Трейлы", ["Width"] = "Ширина", ["Footsteps"] = "Следы", ["Shape"] = "Форма", ["Circle"] = "Круг",
	["Square"] = "Квадрат", ["Diamond"] = "Ромб", ["Foot"] = "Нога", ["Rainbow color"] = "Радужный цвет",
	["Animation time"] = "Время анимации", ["Color"] = "Цвет",
	-- HUD
	["Show FPS"] = "Показать FPS", ["Custom FPS"] = "Свой FPS", ["Drag the badge across the screen"] = "Перетащи значок по экрану",
	-- Player
	["Walkspeed"] = "Скорость ходьбы", ["Speed"] = "Скорость", ["Jumppower"] = "Сила прыжка", ["Power"] = "Сила",
	["Spin"] = "Вращение", ["Rotation speed"] = "Скорость вращения", ["Noclip"] = "Noclip", ["Fly"] = "Полёт", ["Fly speed"] = "Скорость полёта",
	["Move with joystick / WASD. Space = up, Ctrl or Q = down. Look up/down to climb."] = "Двигайся джойстиком / WASD. Пробел — вверх, Ctrl или Q — вниз. Смотри вверх/вниз, чтобы лететь.",
	-- World
	["Shader preset"] = "Шейдер", ["Weather"] = "Погода", ["Fullbright"] = "Фулбрайт", ["None"] = "Нет", ["Snow"] = "Снег",
	["Rain"] = "Дождь", ["Sakura"] = "Сакура", ["Blood"] = "Кровь", ["Sunset"] = "Закат", ["Night"] = "Ночь",
	["Neon"] = "Неон", ["Cyberpunk"] = "Киберпанк", ["Dream"] = "Мечта", ["Noir"] = "Нуар", ["Golden"] = "Золото",
	["Matrix"] = "Матрица", ["Arctic"] = "Арктика", ["Autumn"] = "Осень",
	["Turn on Shaders to apply these settings."] = "Включи шейдеры, чтобы применить эти настройки.",
	["Time of day"] = "Время суток", ["Darkness"] = "Затемнение", ["Glow (bloom)"] = "Свечение (bloom)", ["Contrast"] = "Контраст",
	["Saturation"] = "Насыщенность", ["Fog"] = "Туман", ["Sun rays"] = "Лучи солнца", ["Motion blur"] = "Размытие движения",
	["Tint color"] = "Цвет оттенка", ["Fog color"] = "Цвет тумана", ["Wall transparency"] = "Прозрачность стен",
	-- Troll
	["Fling"] = "Fling", ["Fling selected"] = "Fling выбранного", ["Fling all"] = "Fling всех", ["Select a player first"] = "Сначала выбери игрока",
	-- Misc
	["Autofarm coins"] = "Автофарм монет", ["Flight speed"] = "Скорость полёта", ["Farm delay"] = "Задержка фарма",
	["Noclip is enabled automatically while farming."] = "Noclip включается автоматически во время фарма.",
	["Teleport to player"] = "Телепорт к игроку", ["Teleport to spawn"] = "Телепорт на спавн", ["Teleport to Map"] = "Телепорт на карту",
	["Teleport to murder"] = "Телепорт к убийце", ["Teleport to sheriff"] = "Телепорт к шерифу",
	["Player not found"] = "Игрок не найден", ["Murderer not found"] = "Убийца не найден", ["Sheriff not found"] = "Шериф не найден",
	["Spawn not found"] = "Спавн не найден", ["Map not found"] = "Карта не найдена",
	-- Config
	["Save your current settings under a name"] = "Сохрани текущие настройки под именем", ["Config name..."] = "Имя конфига...",
	["Save"] = "Сохранить", ["Slots"] = "Слоты", ["— empty —"] = "— пусто —", ["Enter a config name"] = "Введи имя конфига",
	["All 5 slots are used"] = "Все 5 слотов заняты", ["Config saved"] = "Конфиг сохранён", ["Config loaded"] = "Конфиг загружен",
	-- Settings
	["Menu color"] = "Цвет меню", ["Menu scale"] = "Масштаб меню", ["Menu transparency"] = "Прозрачность меню", ["Language"] = "Язык",
	-- Info
	["News, updates and support"] = "Новости, обновления и поддержка", ["Copy link"] = "Копировать ссылку", ["Copied!"] = "Скопировано!",
	["Open Telegram"] = "Открыть Telegram", ["Unload script"] = "Выгрузить скрипт",
	["NurHub MM2 v5.0 — visuals, player, world and misc tools for Murder Mystery 2. No Drawing API: everything is built from Frame, Highlight, Trail and Lighting objects."] = "NurHub MM2 v5.0 — визуал, игрок, мир и инструменты для Murder Mystery 2. Без Drawing API: всё собрано из Frame, Highlight, Trail и Lighting.",
	["Menu key: RightShift  •  or the NH button."] = "Клавиша меню: RightShift  •  или кнопка NH.",
	-- Превью
	["ESP Editor"] = "Редактор ESP", ["live preview of your settings"] = "предпросмотр твоих настроек",
}
for k, v in pairs(RU_LIST) do RU[k] = v end

applyAccent()
applyLang()
fit()
