-- ui.lua — UI-каркас Voxer Admin
-- Возвращает таблицу с хелперами и ссылками на элементы UI

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ========== NOTIFY ==========
local notifGui = nil
local function Notify(titleText, discText, duration)
    duration = duration or 3
    if notifGui and notifGui.Parent then notifGui:Destroy() end
    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "notif"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder = 100
    notifGui.Parent = CoreGui
    local main = Instance.new("CanvasGroup")
    main.BorderSizePixel = 0
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BackgroundTransparency = 0.2
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Size = UDim2.new(0.216, 0, 0.091, 0)
    main.Position = UDim2.new(1.11, 0, 0.91, 0)
    main.Parent = notifGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0.15, 0)
    local title = Instance.new("TextLabel")
    title.BorderSizePixel = 0; title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextScaled = true; title.BackgroundTransparency = 1
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Size = UDim2.new(0.17742, 0, 0.23911, 0)
    title.Position = UDim2.new(0.20728, 0, 0.30118, 0)
    title.Text = titleText or "Voxer"; title.Parent = main
    local disc = Instance.new("TextLabel")
    disc.BorderSizePixel = 0; disc.TextXAlignment = Enum.TextXAlignment.Left
    disc.TextScaled = true; disc.BackgroundTransparency = 1
    disc.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    disc.TextColor3 = Color3.fromRGB(255, 255, 255)
    disc.AnchorPoint = Vector2.new(0.5, 0.5)
    disc.Size = UDim2.new(0.82258, 0, 0.2529, 0)
    disc.Position = UDim2.new(0.53286, 0, 0.6529, 0)
    disc.Text = discText or ""; disc.Parent = main
    local bar = Instance.new("Frame")
    bar.BorderSizePixel = 0; bar.BackgroundColor3 = Color3.fromRGB(255, 171, 0)
    bar.Size = UDim2.new(1, 0, 0.051, 0)
    bar.Position = UDim2.new(0, 0, 0.948, 0)
    bar.Parent = main
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0.5, 0)
    Instance.new("UIShadow", main)
    local ti1 = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ti2 = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local HIDDEN, VISIBLE = UDim2.new(1.11, 0, 0.91, 0), UDim2.new(0.892, 0, 0.91, 0)
    task.spawn(function()
        TweenService:Create(main, ti1, {Position = VISIBLE}):Play()
        task.wait(.1)
        TweenService:Create(bar, ti2, {Size = UDim2.new(0, 0, 0.051, 0)}):Play()
        task.wait(duration)
        local out = TweenService:Create(main, ti1, {Position = HIDDEN})
        out:Play()
        out.Completed:Once(function()
            if notifGui then notifGui:Destroy(); notifGui = nil end
        end)
    end)
end

-- ========== CONFIG SYSTEM ==========
local CONFIG_FOLDER = "Voxer"
local CONFIG_FILE = "Voxer/default.txt"
local UIStates = {}
local AUTO_SAVE_INTERVAL = 5

local function registerState(key, state) UIStates[key] = state end

local function ensureConfigFolder()
    if type(isfolder) ~= "function" or type(makefolder) ~= "function" then return false end
    local ok = pcall(isfolder, CONFIG_FOLDER)
    if ok then
        if not isfolder(CONFIG_FOLDER) then pcall(makefolder, CONFIG_FOLDER) end
    else
        pcall(makefolder, CONFIG_FOLDER)
    end
    return true
end

local function SaveConfig(notifyUser)
    ensureConfigFolder()
    if type(writefile) ~= "function" then
        if notifyUser then Notify("Config", "writefile unavailable", 3) end
        return false
    end
    local lines = {"# Voxer CFG", "# Format: key=value"}
    local keys = {}
    for k in pairs(UIStates) do table.insert(keys, k) end
    table.sort(keys)
    for _, key in ipairs(keys) do
        local state = UIStates[key]
        local value
        if state._isKeybind then
            value = state.Key and state.Key.Name or ""
        elseif state.Enabled ~= nil then
            value = state.Enabled and "true" or "false"
        elseif state.Value ~= nil then
            value = tostring(state.Value)
        end
        if value ~= nil then table.insert(lines, key .. "=" .. value) end
    end
    local ok = pcall(writefile, CONFIG_FILE, table.concat(lines, "\n"))
    if ok then
        if notifyUser then Notify("Config", "Saved successfully", 3) end
    elseif notifyUser then
        Notify("Config", "Save failed", 3)
    end
    return ok
end

local function LoadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return false end
    if not isfile(CONFIG_FILE) then return false end
    local ok, content = pcall(readfile, CONFIG_FILE)
    if not ok or type(content) ~= "string" then return false end
    local loaded = 0
    for line in content:gmatch("[^\r\n]+") do
        if line ~= "" and not line:match("^%s*#") then
            local key, value = line:match("^([^=]+)=(.*)$")
            if key then
                key = key:gsub("^%s+", ""):gsub("%s+$", "")
                value = value:gsub("^%s+", ""):gsub("%s+$", "")
                local state = UIStates[key]
                if state and state.Set then
                    if state._isKeybind then
                        state.Set(value)
                    elseif state.Enabled ~= nil then
                        state.Set(value == "true" or value == "1")
                    else
                        local num = tonumber(value)
                        if num then state.Set(num) else state.Set(value) end
                    end
                    loaded = loaded + 1
                end
            end
        end
    end
    return true
end

local function ResetConfig()
    for _, state in pairs(UIStates) do
        if state._isKeybind then
            state.Set(nil)
        elseif state.Default ~= nil then
            state.Set(state.Default)
        end
    end
end

-- ========== KEYBIND SYSTEM ==========
local keybindRegistry = {}
local recordingKeybind = nil

local function cancelKeybindRecording()
    if not recordingKeybind then return end
    local rb = recordingKeybind
    recordingKeybind = nil
    rb.btn.Text = rb.keyState.Key and rb.keyState.Key.Name or "None"
end

local function startKeybindRecording(keyState, btn)
    if recordingKeybind then cancelKeybindRecording() end
    recordingKeybind = {keyState = keyState, btn = btn}
    btn.Text = "..."
end

local function commitKeybindRecording(keyCode)
    if not recordingKeybind then return end
    local rb = recordingKeybind
    recordingKeybind = nil
    if keyCode == Enum.KeyCode.Escape then
        rb.keyState.Set(nil)
        Notify("Keybind", "Cleared", 2)
    else
        rb.keyState.Set(keyCode)
        Notify("Keybind", "Bound to " .. keyCode.Name, 2)
    end
end

-- ========== SCREEN GUI ==========
do
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("Voxer Admin")
        if old then old:Destroy() end
    end
    local oldCg = CoreGui:FindFirstChild("Voxer Admin")
    if oldCg then oldCg:Destroy() end
end

local G2L = {}
local screenGuiParent = CoreGui
local okCore
if CoreGui then
    okCore = pcall(function()
        local test = Instance.new("Folder")
        test.Parent = CoreGui
        test:Destroy()
    end)
end
if not okCore then
    screenGuiParent = LP:WaitForChild("PlayerGui")
end

G2L["1"] = Instance.new("ScreenGui", screenGuiParent)
G2L["1"].Name = "Voxer Admin"
G2L["1"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
G2L["1"].ResetOnSpawn = false
G2L["1"].IgnoreGuiInset = true

G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"].Name = "Main"
G2L["2"].BorderSizePixel = 0
G2L["2"].BackgroundColor3 = Color3.fromRGB(0, 0, 0)
G2L["2"].AnchorPoint = Vector2.new(0.5, 0.5)
G2L["2"].Size = UDim2.new(0.8, 0, 0.849, 0)
G2L["2"].Position = UDim2.new(0.5, 0, 0.5, 0)
G2L["2"].BackgroundTransparency = 0.1
Instance.new("UICorner", G2L["2"]).CornerRadius = UDim.new(0.05, 0)
Instance.new("UIShadow", G2L["2"])

local mainLine = Instance.new("Frame", G2L["2"])
mainLine.BorderSizePixel = 0
mainLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainLine.AnchorPoint = Vector2.new(0.5, 0.5)
mainLine.Size = UDim2.new(0.001, 0, 0.9, 0)
mainLine.Position = UDim2.new(0.16109, 0, 0.49891, 0)

local mainTitle = Instance.new("TextLabel", G2L["2"])
mainTitle.TextWrapped = true
mainTitle.BorderSizePixel = 0
mainTitle.TextScaled = true
mainTitle.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.BackgroundTransparency = 1
mainTitle.AnchorPoint = Vector2.new(0.5, 0.5)
mainTitle.Size = UDim2.new(0.21067, 0, 0.05028, 0)
mainTitle.Text = "Voxer"
mainTitle.Position = UDim2.new(0.5, 0, 0.03995, 0)

local menus = Instance.new("Frame", G2L["2"])
menus.AnchorPoint = Vector2.new(0.5, 0.5)
menus.Size = UDim2.new(0.16072, 0, 0.8, 0)
menus.Position = UDim2.new(0.08023, 0, 0.49891, 0)
menus.BackgroundTransparency = 1

local buttonsFolder = Instance.new("Folder", menus)
local bl = Instance.new("UIListLayout", buttonsFolder)
bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
bl.Padding = UDim.new(0.07, 0)
bl.SortOrder = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", buttonsFolder).PaddingTop = UDim.new(0.01, 0)

local tabNames = {"Combat", "Movement", "Utilities", "Render", "Config"}
local tabButtons = {}
for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton", buttonsFolder)
    b.Name = name; b.TextWrapped = true
    b.BorderSizePixel = 0; b.TextScaled = true
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundTransparency = 1
    b.Size = UDim2.new(0.8, 0, 0.05, 0)
    b.LayoutOrder = i; b.Text = name
    tabButtons[name] = b
end

local account = Instance.new("Frame", menus)
account.AnchorPoint = Vector2.new(0.5, 0.5)
account.Size = UDim2.new(0.8, 0, 0.1502, 0)
account.Position = UDim2.new(0.5, 0, 0.98709, 0)
account.BackgroundTransparency = 1

local avatar = Instance.new("ImageLabel", account)
avatar.BackgroundColor3 = Color3.fromRGB(72, 72, 72)
avatar.AnchorPoint = Vector2.new(0.5, 0.5)
avatar.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
avatar.Size = UDim2.new(0.5, 0, 0.5, 0)
avatar.Position = UDim2.new(0.13678, 0, 0.57182, 0)
Instance.new("UIAspectRatioConstraint", avatar)
Instance.new("UICorner", avatar).CornerRadius = UDim.new(1, 0)

local welcome = Instance.new("TextLabel", account)
welcome.TextWrapped = true
welcome.TextXAlignment = Enum.TextXAlignment.Left
welcome.TextScaled = true
welcome.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
welcome.BackgroundTransparency = 1
welcome.AnchorPoint = Vector2.new(0.5, 0.5)
welcome.Size = UDim2.new(0.72215, 0, 0.307, 0)
welcome.Text = "Welcome back,"
welcome.Position = UDim2.new(0.71917, 0, 0.40172, 0)

local usernameLbl = Instance.new("TextLabel", account)
usernameLbl.TextWrapped = true
usernameLbl.TextXAlignment = Enum.TextXAlignment.Left
usernameLbl.TextScaled = true
usernameLbl.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
usernameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
usernameLbl.BackgroundTransparency = 1
usernameLbl.AnchorPoint = Vector2.new(0.5, 0.5)
usernameLbl.Size = UDim2.new(0.72215, 0, 0.41333, 0)
usernameLbl.Text = LP.DisplayName
usernameLbl.Position = UDim2.new(0.71917, 0, 0.71811, 0)

local tabsFolder = Instance.new("Folder", G2L["2"])
tabsFolder.Name = "Tabs"

local function makeTab(name, visible)
    local sf = Instance.new("ScrollingFrame", tabsFolder)
    sf.Name = name; sf.Visible = visible or false
    sf.BorderSizePixel = 0; sf.ScrollBarImageTransparency = 1
    sf.Selectable = false
    sf.AnchorPoint = Vector2.new(0.5, 0.5)
    sf.Size = UDim2.new(0.83841, 0, 0.82846, 0)
    sf.Position = UDim2.new(0.5808, 0, 0.51314, 0)
    sf.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", sf)
    l.Wraps = true; l.Padding = UDim.new(0.02, 0); l.FillDirection = Enum.FillDirection.Horizontal
    Instance.new("UIPadding", sf).PaddingLeft = UDim.new(0.03, 0)
    return sf
end

local tabFrames = {
    Combat = makeTab("Combat", true),
    Movement = makeTab("Movement", false),
    Utilities = makeTab("Utilities", false),
    Render = makeTab("Render", false),
    Config = makeTab("Config", false),
}

local function selectTab(name)
    for n, f in pairs(tabFrames) do f.Visible = (n == name) end
end
for n, b in pairs(tabButtons) do
    if tabFrames[n] then
        b.MouseButton1Click:Connect(function() selectTab(n) end)
    end
end

-- ========== BUILD HELPERS ==========
local function buildHeaderToggleVisual(btn)
    local cg = Instance.new("CanvasGroup", btn)
    cg.BackgroundColor3 = Color3.fromRGB(46, 46, 46)
    cg.AnchorPoint = Vector2.new(0.5, 0.5)
    cg.Size = UDim2.new(1, 0, 0.973, 0)
    cg.Position = UDim2.new(0.5, 0, 0.5, 0)
    Instance.new("UICorner", cg).CornerRadius = UDim.new(1, 0)
    local cgs = Instance.new("UIStroke", cg); cgs.Thickness = 2; cgs.Color = Color3.fromRGB(89, 89, 89)
    local circle = Instance.new("Frame", cg)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Size = UDim2.new(0.9, 0, 0.9, 0)
    circle.Position = UDim2.new(0.3, 0, 0.5, 0)
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    Instance.new("UIAspectRatioConstraint", circle)
    return function(v)
        circle.Position = UDim2.new(v and 0.7 or 0.3, 0, 0.5, 0)
        cg.BackgroundColor3 = v and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(46, 46, 46)
    end
end

local function makeHeaderToggle(parent, pos, size, onToggle, displayName)
    local moduleName = displayName or "?"
    local btn = Instance.new("TextButton", parent)
    btn.Name = "Enable"; btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundTransparency = 1
    btn.Size = size; btn.Position = pos; btn.Text = ""
    local set = buildHeaderToggleVisual(btn)
    local state = {Enabled = false, Default = false}
    local function setVisual(v, showNotif)
        state.Enabled = v; set(v)
        if onToggle then onToggle(v) end
        if showNotif then
            Notify("Module", moduleName .. " " .. (v and "enabled" or "disabled"), 2)
        end
    end
    state.Set = function(v, showNotif) setVisual(v, showNotif) end
    btn.MouseButton1Click:Connect(function() setVisual(not state.Enabled, true) end)
    return state
end

local function makeToggleRow(parent, titleText, order)
    local row = Instance.new("Frame", parent)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Size = UDim2.new(0.89595, 0, 0.09382, 0)
    row.LayoutOrder = order or 1
    row.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", row)
    label.TextWrapped = true; label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.new(0.43837, 0, 1, 0)
    label.Text = titleText
    label.Position = UDim2.new(0.21919, 0, 0.5, 0)
    local enabled = Instance.new("TextButton", row)
    enabled.BorderSizePixel = 0
    enabled.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    enabled.AnchorPoint = Vector2.new(0.5, 0.5)
    enabled.BackgroundTransparency = 1
    enabled.Size = UDim2.new(0.9, 0, 0.9, 0)
    enabled.Text = ""
    enabled.Position = UDim2.new(0.965, 0, 0.5, 0)
    Instance.new("UIAspectRatioConstraint", enabled)
    local es = Instance.new("UIStroke", enabled)
    es.Color = Color3.fromRGB(255, 255, 255); es.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Instance.new("UICorner", enabled).CornerRadius = UDim.new(0.2, 0)
    local state = {Enabled = false, Default = false}
    local function setVisual(v) state.Enabled = v; enabled.BackgroundTransparency = v and 0 or 1 end
    state.Set = setVisual
    enabled.MouseButton1Click:Connect(function() setVisual(not state.Enabled) end)
    return state, row
end

local function makeSliderRow(parent, titleText, min, max, default, order, decimals, onChange)
    decimals = decimals or 0
    local row = Instance.new("Frame", parent)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Size = UDim2.new(0.899, 0, 0.13, 0)
    row.LayoutOrder = order or 1
    row.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", row)
    label.TextWrapped = true; label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.new(0.3638, 0, 0.5521, 0)
    label.Text = titleText
    label.Position = UDim2.new(0.18098, 0, 0.20704, 0)
    local valText = Instance.new("TextLabel", row)
    valText.TextXAlignment = Enum.TextXAlignment.Right
    valText.TextScaled = true
    valText.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    valText.TextColor3 = Color3.fromRGB(255, 255, 255)
    valText.BackgroundTransparency = 1
    valText.AnchorPoint = Vector2.new(0.5, 0.5)
    valText.Size = UDim2.new(0.21791, 0, 0.5521, 0)
    valText.Text = "100"
    valText.Position = UDim2.new(0.89012, 0, 0.20704, 0)
    local fullsize = Instance.new("Frame", row)
    fullsize.AnchorPoint = Vector2.new(0.5, 0.5)
    fullsize.Size = UDim2.new(0.99908, 0, 0.20704, 0)
    fullsize.Position = UDim2.new(0.5, 0, 0.59694, 0)
    fullsize.BackgroundTransparency = 1
    Instance.new("UICorner", fullsize).CornerRadius = UDim.new(0.3, 0)
    Instance.new("UIStroke", fullsize).Color = Color3.fromRGB(255, 255, 255)
    local fill = Instance.new("Frame", fullsize)
    fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fill.Size = UDim2.new(0.5, 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0.3, 0)
    Instance.new("UIStroke", fill).Color = Color3.fromRGB(255, 255, 255)
    local dot = Instance.new("Frame", fill)
    dot.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Size = UDim2.new(2, 0, 2, 0)
    dot.Position = UDim2.new(1, 0, 0.5, 0)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local ds = Instance.new("UIStroke", dot); ds.Thickness = 2; ds.Color = Color3.fromRGB(255, 255, 255)
    Instance.new("UIAspectRatioConstraint", dot)
    local button = Instance.new("TextButton", fullsize)
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 1, 0); button.Text = ""
    local state = {Value = default, Default = default}
    local sliding = false
    local function fmt(v) return decimals > 0 and string.format("%." .. decimals .. "f", v) or tostring(math.round(v)) end
    local function apply(v)
        v = math.clamp(v, min, max)
        state.Value = v
        fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
        valText.Text = fmt(v)
        if onChange then onChange(v) end
    end
    local function update()
        local m = UIS:GetMouseLocation()
        local a = math.clamp((m.X - fullsize.AbsolutePosition.X) / fullsize.AbsoluteSize.X, 0, 1)
        apply(min + (max - min) * a)
    end
    state.Set = apply
    apply(default)
    button.MouseButton1Down:Connect(function()
        sliding = true; update()
        while sliding do update(); task.wait() end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    return state, apply, row
end

local function makeDropdownRow(parent, titleText, defaultText, order, onChange, options)
    local row = Instance.new("Frame", parent)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Size = UDim2.new(0.89595, 0, 0.09382, 0)
    row.LayoutOrder = order or 1
    row.BackgroundTransparency = 1; row.ZIndex = 10
    local label = Instance.new("TextLabel", row)
    label.TextWrapped = true; label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextScaled = true
    label.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.AnchorPoint = Vector2.new(0.5, 0.5)
    label.Size = UDim2.new(0.43837, 0, 1, 0)
    label.Text = titleText
    label.Position = UDim2.new(0.21919, 0, 0.5, 0)
    local dropdown = Instance.new("TextButton", row)
    dropdown.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    dropdown.AnchorPoint = Vector2.new(0.5, 0.5)
    dropdown.Size = UDim2.new(0.99819, 0, 0.75146, 0)
    dropdown.TextXAlignment = Enum.TextXAlignment.Left
    dropdown.TextScaled = true
    dropdown.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    dropdown.Text = defaultText
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.Position = UDim2.new(0.5, 0, 1.583, 0)
    dropdown.ZIndex = 11
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0.2, 0)
    Instance.new("UIPadding", dropdown).PaddingLeft = UDim.new(0.02, 0)
    local dvar = Instance.new("Frame", row)
    dvar.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    dvar.AnchorPoint = Vector2.new(0.5, 0)
    dvar.Size = UDim2.new(0.99819, 0, 0.81962, 0)
    dvar.Position = UDim2.new(0.5, 0, 1.95873, 0)
    dvar.BackgroundTransparency = 1; dvar.Visible = false; dvar.ZIndex = 12
    Instance.new("UICorner", dvar).CornerRadius = UDim.new(0.2, 0)
    local dvl = Instance.new("UIListLayout", dvar)
    dvl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dvl.SortOrder = Enum.SortOrder.LayoutOrder
    local state = {Value = defaultText, Default = defaultText}
    local function setValue(name)
        state.Value = name; dropdown.Text = name; dvar.Visible = false
        if onChange then onChange(name) end
    end
    state.Set = setValue
    options = options or {"Closest", "Head", "Torso"}
    local function makeOpt(name, optOrder)
        local btn = Instance.new("TextButton", dvar)
        btn.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextScaled = true
        btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.LayoutOrder = optOrder; btn.Text = name; btn.ZIndex = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.2, 0)
        btn.MouseButton1Click:Connect(function() setValue(name) end)
    end
    for i, optName in ipairs(options) do makeOpt(optName, i - 1) end
    dropdown.MouseButton1Click:Connect(function() dvar.Visible = not dvar.Visible end)
    return state, row
end

local function makeButtonRow(parent, titleText, order, onClick)
    local row = Instance.new("Frame", parent)
    row.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Size = UDim2.new(0.9, 0, 0.1, 0)
    row.Position = UDim2.new(0.5, 0, 0.5, 0)
    row.LayoutOrder = order or 1
    Instance.new("UICorner", row).CornerRadius = UDim.new(0.2, 0)
    local btn = Instance.new("TextButton", row)
    btn.BackgroundTransparency = 1
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.Text = titleText
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    btn.MouseButton1Click:Connect(onClick)
    return row
end

local function buildModule(parent, config)
    local card = Instance.new("Frame", parent)
    card.Name = config.name
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.Size = UDim2.new(0.47, 0, config.cardH, 0)
    card.BorderColor3 = Color3.fromRGB(0, 0, 0)
    card.LayoutOrder = config.layoutOrder or 1
    Instance.new("UICorner", card).CornerRadius = UDim.new(0.03, 0)
    local title = Instance.new("TextLabel", card)
    title.TextWrapped = true; title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextScaled = true
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Size = config.titleSize
    title.Text = config.title
    title.Position = config.titlePos
    local enableState = makeHeaderToggle(card, config.enablePos, config.enableSize, config.onEnable, config.title)
    local kb = Instance.new("TextButton", card)
    kb.Name = "Keybind"; kb.TextWrapped = true
    kb.BorderSizePixel = 0; kb.TextScaled = true
    kb.TextColor3 = Color3.fromRGB(255, 255, 255)
    kb.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    kb.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    kb.AnchorPoint = Vector2.new(0.5, 0.5)
    kb.Size = config.keybindSize; kb.Text = "None"
    kb.Position = config.keybindPos
    local kbs = Instance.new("UIStroke", kb)
    kbs.Color = Color3.fromRGB(255, 255, 255); kbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Instance.new("UICorner", kb).CornerRadius = UDim.new(0.2, 0)
    local keybindState = {Key = nil, Default = nil, _isKeybind = true}
    function keybindState.Set(v)
        if v == nil or v == "" then
            keybindState.Key = nil; kb.Text = "None"; return
        end
        local kc
        if typeof(v) == "EnumItem" then kc = v
        elseif typeof(v) == "string" then kc = Enum.KeyCode[v] end
        if kc then keybindState.Key = kc; kb.Text = kc.Name
        else keybindState.Key = nil; kb.Text = "None" end
    end
    kb.MouseButton1Click:Connect(function()
        if recordingKeybind and recordingKeybind.keyState == keybindState then
            recordingKeybind = nil
            keybindState.Set(nil)
            Notify("Keybind", "Cleared", 2)
            return
        end
        if recordingKeybind then cancelKeybindRecording() end
        startKeybindRecording(keybindState, kb)
    end)
    table.insert(keybindRegistry, {keyState = keybindState, toggleState = enableState})
    local settings = Instance.new("Frame", card)
    settings.AnchorPoint = Vector2.new(0.5, 0.5)
    settings.Size = config.settingsSize
    settings.Position = config.settingsPos
    settings.BackgroundTransparency = 1
    local sl = Instance.new("UIListLayout", settings)
    sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sl.Padding = UDim.new(0.03, 0)
    sl.SortOrder = Enum.SortOrder.LayoutOrder
    return card, settings, enableState, keybindState
end

-- ========== ГЛОБАЛЬНЫЕ ОБРАБОТЧИКИ UI ==========

;(function()
    local dragging, dragStart, startPos
    mainTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = G2L["2"].Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local d = input.Position - dragStart
            G2L["2"].Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end)()

;(function()
    local panelVisible = true
    local TOGGLE_KEYS = { [Enum.KeyCode.Insert] = true, [Enum.KeyCode.RightShift] = true }
    UIS.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if recordingKeybind then return end
        if TOGGLE_KEYS[input.KeyCode] then
            panelVisible = not panelVisible
            G2L["2"].Visible = panelVisible
            G2L["2"].Active = panelVisible
        end
    end)
end)()

;(function()
    UIS.InputBegan:Connect(function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if recordingKeybind then
            if input.KeyCode == Enum.KeyCode.Escape then
                cancelKeybindRecording()
                local rb = recordingKeybind
                if rb then
                    rb.keyState.Set(nil)
                    Notify("Keybind", "Cleared", 2)
                end
                return
            end
            commitKeybindRecording(input.KeyCode)
            return
        end
        if processed then return end
        if UIS:GetFocusedTextBox() then return end
        for _, entry in ipairs(keybindRegistry) do
            if entry.keyState.Key and entry.keyState.Key == input.KeyCode then
                entry.toggleState.Set(not entry.toggleState.Enabled, true)
            end
        end
    end)
end)()

-- ========== RETURN ==========
return {
    G2L = G2L,
    tabFrames = tabFrames,
    tabButtons = tabButtons,
    mainTitle = mainTitle,
    Notify = Notify,
    registerState = registerState,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    ResetConfig = ResetConfig,
    ensureConfigFolder = ensureConfigFolder,
    buildModule = buildModule,
    makeToggleRow = makeToggleRow,
    makeSliderRow = makeSliderRow,
    makeDropdownRow = makeDropdownRow,
    makeButtonRow = makeButtonRow,
    makeHeaderToggle = makeHeaderToggle,
    selectTab = selectTab,
    CONFIG_FILE = CONFIG_FILE,
    AUTO_SAVE_INTERVAL = AUTO_SAVE_INTERVAL,
}
