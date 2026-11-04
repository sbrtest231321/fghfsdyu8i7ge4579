repeat task.wait() until game:IsLoaded()

do
    local SELF_URL = "https://raw.githubusercontent.com/sbrtest231321/fghfsdyu8i7ge4579/refs/heads/main/sfghuygtr8.lua"
    if type(queueonteleport) == "function" then
        queueonteleport(([[
repeat task.wait() until game:IsLoaded()
local ok, err = pcall(function()
    local src = game:HttpGet(%q, true)
    local fn, lerr = loadstring(src, "SilentAimReload")
    if not fn then error(lerr) end
    fn()
end)
if not ok then warn("[Voxer] " .. tostring(err)) end
]]):format(SELF_URL))
    end
end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local DEBUG_CHANGES = true
local _currentModule = "?"

local function logChange(fmtStr, ...)
    if DEBUG_CHANGES then
        -- print
    end
end

local keybindRegistry = {}
local recordingKeybind = nil
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
    title.BorderSizePixel = 0
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Size = UDim2.new(0.17742, 0, 0.23911, 0)
    title.Position = UDim2.new(0.20728, 0, 0.30118, 0)
    title.Text = titleText or "Voxer"
    title.Parent = main

    local disc = Instance.new("TextLabel")
    disc.BorderSizePixel = 0
    disc.TextXAlignment = Enum.TextXAlignment.Left
    disc.TextScaled = true
    disc.BackgroundTransparency = 1
    disc.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    disc.TextColor3 = Color3.fromRGB(255, 255, 255)
    disc.AnchorPoint = Vector2.new(0.5, 0.5)
    disc.Size = UDim2.new(0.82258, 0, 0.2529, 0)
    disc.Position = UDim2.new(0.53286, 0, 0.6529, 0)
    disc.Text = discText or ""
    disc.Parent = main

    local bar = Instance.new("Frame")
    bar.BorderSizePixel = 0
    bar.BackgroundColor3 = Color3.fromRGB(255, 171, 0)
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

do
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local old = pg:FindFirstChild("Voxer Admin")
        if old then old:Destroy() end
    end
    local oldCg = CoreGui:FindFirstChild("Voxer Admin")
    if oldCg then oldCg:Destroy() end
end

local CONFIG_FOLDER = "Voxer"
local CONFIG_FILE   = "Voxer/default.txt"
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
        if value ~= nil then
            table.insert(lines, key .. "=" .. value)
        end
    end
    local ok = pcall(writefile, CONFIG_FILE, table.concat(lines, "\n"))
    if ok then
        logChange("Config saved")
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
    logChange("Config loaded: %d", loaded)
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
    logChange("Config reset")
end

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
    warn("[Voxer Admin] CoreGui недоступна")
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
    b.Name = name
    b.TextWrapped = true
    b.BorderSizePixel = 0
    b.TextScaled = true
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundTransparency = 1
    b.Size = UDim2.new(0.8, 0, 0.05, 0)
    b.LayoutOrder = i
    b.Text = name
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
    sf.Name = name
    sf.Visible = visible or false
    sf.BorderSizePixel = 0
    sf.ScrollBarImageTransparency = 1
    sf.Selectable = false
    sf.AnchorPoint = Vector2.new(0.5, 0.5)
    sf.Size = UDim2.new(0.83841, 0, 0.82846, 0)
    sf.Position = UDim2.new(0.5808, 0, 0.51314, 0)
    sf.BackgroundTransparency = 1
    local l = Instance.new("UIListLayout", sf)
    l.Wraps = true
    l.Padding = UDim.new(0.02, 0)
    l.FillDirection = Enum.FillDirection.Horizontal
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
    logChange("Tab -> %s", name)
end
for n, b in pairs(tabButtons) do
    if tabFrames[n] then
        b.MouseButton1Click:Connect(function() selectTab(n) end)
    end
end

local TeamCheck = {
    IsFriendlyPlayer = function(player)
        if player == LP then return true end
        local myTeam, theirTeam = LP.Team, player.Team
        if myTeam and theirTeam then return myTeam == theirTeam end
        local a, b = LP:GetAttribute("Team"), player:GetAttribute("Team")
        if a ~= nil and b ~= nil then return a == b end
        return false
    end,
    IsFriendlyUnit = function(unit)
        if unit == LP then return true end
        if EntityAPI and type(EntityAPI.IsFriendly) == "function" then
            local ok, v = pcall(EntityAPI.IsFriendly, unit)
            if ok and type(v) == "boolean" then return v end
        end
        local a, b = LP:GetAttribute("Team"), (typeof(unit) == "Instance" and unit:GetAttribute("Team"))
        if a ~= nil and b ~= nil then return a == b end
        if typeof(unit) == "Instance" and unit:IsA("Player") then
            return LP.Team ~= nil and unit.Team ~= nil and LP.Team == unit.Team
        end
        return false
    end,
}

local WallCheck = {}
local wallCheckParams = RaycastParams.new()
wallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
wallCheckParams.RespectCanCollide = false

local function updateWallCheckFilter()
    local list = {}
    if LP.Character then table.insert(list, LP.Character) end
    wallCheckParams.FilterDescendantsInstances = list
end
updateWallCheckFilter()
LP.CharacterAdded:Connect(function() task.wait(0.2); updateWallCheckFilter() end)

function WallCheck.CanSee(camera, model, position)
    if not camera or not model or not position then return false end
    local origin = camera.CFrame.Position
    local myChar = LP.Character
    local head = myChar and myChar:FindFirstChild("Head")
    local hrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if head and hrp and (origin - head.Position).Magnitude < 1.5 then
        origin = hrp.Position + Vector3.new(0, 1.5, 0)
    end
    local dir = position - origin
    if dir.Magnitude < 0.01 then return true end
    local hit = workspace:Raycast(origin, dir.Unit * 1000, wallCheckParams)
    return hit and hit.Instance:IsDescendantOf(model) or false
end

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
    local moduleName = displayName or _currentModule
    local btn = Instance.new("TextButton", parent)
    btn.Name = "Enable"
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundTransparency = 1
    btn.Size = size
    btn.Position = pos
    btn.Text = ""
    local set = buildHeaderToggleVisual(btn)
    local state = {Enabled = false, Default = false}
    local function setVisual(v, showNotif)
        state.Enabled = v
        set(v)
        if onToggle then onToggle(v) end
        if showNotif then
            logChange("Module '%s' -> %s", moduleName, v and "ON" or "OFF")
            Notify("Module", moduleName .. " " .. (v and "enabled" or "disabled"), 2)
        end
    end
    state.Set = function(v, showNotif) setVisual(v, showNotif) end
    btn.MouseButton1Click:Connect(function()
        setVisual(not state.Enabled, true)
    end)
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
    label.TextWrapped = true
    label.TextSize = 14
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
    es.Color = Color3.fromRGB(255, 255, 255)
    es.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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
    label.TextWrapped = true
    label.TextSize = 14
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
    local ds = Instance.new("UIStroke", dot)
    ds.Thickness = 2
    ds.Color = Color3.fromRGB(255, 255, 255)
    Instance.new("UIAspectRatioConstraint", dot)

    local button = Instance.new("TextButton", fullsize)
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Text = ""

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
        sliding = true
        update()
        while sliding do update(); task.wait() end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    return state, apply, row
end

-- ИЗМЕНЕНО: добавлен аргумент options в конец
local function makeDropdownRow(parent, titleText, defaultText, order, onChange, options)
    local row = Instance.new("Frame", parent)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Size = UDim2.new(0.89595, 0, 0.09382, 0)
    row.LayoutOrder = order or 1
    row.BackgroundTransparency = 1
    row.ZIndex = 10

    local label = Instance.new("TextLabel", row)
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
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
    dropdown.Position = UDim2.new(0.5, 0, 1.583, 0)
    dropdown.ZIndex = 11
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0.2, 0)
    Instance.new("UIPadding", dropdown).PaddingLeft = UDim.new(0.02, 0)

    local dvar = Instance.new("Frame", row)
    dvar.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
    dvar.AnchorPoint = Vector2.new(0.5, 0)
    dvar.Size = UDim2.new(0.99819, 0, 0.81962, 0)
    dvar.Position = UDim2.new(0.5, 0, 1.95873, 0)
    dvar.BackgroundTransparency = 1
    dvar.Visible = false
    dvar.ZIndex = 12
    Instance.new("UICorner", dvar).CornerRadius = UDim.new(0.2, 0)
    local dvl = Instance.new("UIListLayout", dvar)
    dvl.HorizontalAlignment = Enum.HorizontalAlignment.Center
    dvl.SortOrder = Enum.SortOrder.LayoutOrder

    local state = {Value = defaultText, Default = defaultText}
    local function setValue(name)
        state.Value = name
        dropdown.Text = name
        dvar.Visible = false
        if onChange then onChange(name) end
    end
    state.Set = setValue
    
    options = options or {"Closest", "Head", "Torso"}
    local function makeOpt(name, optOrder)
        local btn = Instance.new("TextButton", dvar)
        btn.BackgroundColor3 = Color3.fromRGB(66, 66, 66)
        btn.TextScaled = true
        btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.LayoutOrder = optOrder
        btn.Text = name
        btn.ZIndex = 13
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.2, 0)
        btn.MouseButton1Click:Connect(function() setValue(name) end)
    end
    for i, optName in ipairs(options) do
        makeOpt(optName, i - 1)
    end
    
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
    _currentModule = config.title or config.name or "?"
    local card = Instance.new("Frame", parent)
    card.Name = config.name
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    card.AnchorPoint = Vector2.new(0.5, 0)
    card.Size = UDim2.new(0.47, 0, config.cardH, 0)
    card.BorderColor3 = Color3.fromRGB(0, 0, 0)
    card.LayoutOrder = config.layoutOrder or 1
    Instance.new("UICorner", card).CornerRadius = UDim.new(0.03, 0)

    local title = Instance.new("TextLabel", card)
    title.TextWrapped = true
    title.TextXAlignment = Enum.TextXAlignment.Left
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
    kb.Name = "Keybind"
    kb.TextWrapped = true
    kb.BorderSizePixel = 0
    kb.TextScaled = true
    kb.TextColor3 = Color3.fromRGB(255, 255, 255)
    kb.BackgroundColor3 = Color3.fromRGB(51, 51, 51)
    kb.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    kb.AnchorPoint = Vector2.new(0.5, 0.5)
    kb.Size = config.keybindSize
    kb.Text = "None"
    kb.Position = config.keybindPos
    local kbs = Instance.new("UIStroke", kb)
    kbs.Color = Color3.fromRGB(255, 255, 255)
    kbs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Instance.new("UICorner", kb).CornerRadius = UDim.new(0.2, 0)

    local keybindState = {Key = nil, Default = nil, _isKeybind = true}
    function keybindState.Set(v)
        if v == nil or v == "" then
            keybindState.Key = nil
            kb.Text = "None"
            return
        end
        local kc
        if typeof(v) == "EnumItem" then
            kc = v
        elseif typeof(v) == "string" then
            kc = Enum.KeyCode[v]
        end
        if kc then
            keybindState.Key = kc
            kb.Text = kc.Name
        else
            keybindState.Key = nil
            kb.Text = "None"
        end
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

local EntityAPI
do
    local remote = ReplicatedStorage:FindFirstChild("Remote")
    local module = remote and remote:FindFirstChild("EntityService")
    if module then
        local ok, value = pcall(require, module)
        if ok then EntityAPI = value end
    end
end

local function getUnitModel(unit)
    if typeof(unit) == "Instance" and unit:IsA("Model") then return unit end
    if unit.Character then return unit.Character end
    return nil
end

local function getAllTargets(includeBots)
    if includeBots == nil then includeBots = true end
    local units, seen = {}, {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(units, p)
            seen[p] = true
        end
    end
    if not includeBots then return units end
    local function add(m)
        if typeof(m) == "Instance" and m:IsA("Model") and not seen[m]
            and m:GetAttribute("_entity") == "HumanoidEntity"
            and not Players:GetPlayerFromCharacter(m) then
            seen[m] = true
            table.insert(units, m)
        end
    end
    if EntityAPI and EntityAPI.Entity and type(EntityAPI.Entity.GetAll) == "function" then
        local ok, reg = pcall(EntityAPI.Entity.GetAll)
        if ok and type(reg) == "table" then
            for _, e in pairs(reg._items or reg) do if type(e) == "table" then add(e.Instance) end end
        end
    end
    local worlds = workspace:FindFirstChild("World")
    if worlds then
        for _, w in ipairs(worlds:GetChildren()) do
            local ents = w:FindFirstChild("Entities")
            if ents then for _, m in ipairs(ents:GetChildren()) do add(m) end end
        end
    end
    return units
end

local SilentAim = { API = nil, Enabled = false, _installed = false }

do
    local Config = {
        enabled = false,
        aimParts = { "Head", "UpperTorso", "HumanoidRootPart" },
        aimPart = nil, aimBots = true, teamCheck = true, wallCheck = true,
        maxDistance = 1500, noDelay = false,
        fovRadius = 120, fovCircleRadius = 120, fovEnabled = true, fovVisible = true,
        fovColor = Color3.fromRGB(255, 0, 0), fovThickness = 1.5, fovTransparency = 0.7,
    }
    local alive = true
    local Stats = { installed = false, error = nil, lastTarget = nil, lastPart = nil, hooks = 0, fovFiltered = 0 }
    local silentHooks, silentDepth, silentChoice = {}, 0, nil

    local function finite(n) return type(n) == "number" and n == n and math.abs(n) < 1e6 end
    local function validPosition(p) return typeof(p) == "Vector3" and finite(p.X) and finite(p.Y) and finite(p.Z) end
    local function characterOf(unit)
        if typeof(unit) == "Instance" and unit:IsA("Model") then return unit end
        if EntityAPI and type(EntityAPI.GetEntity) == "function" then
            local ok, model = pcall(function() local e = EntityAPI.GetEntity(unit); return e and e:GetModel() end)
            if ok and typeof(model) == "Instance" and model:IsA("Model") then return model end
        end
        return unit.Character
    end
    local function healthOf(unit, model)
        local health = unit:GetAttribute("Health")
        if EntityAPI and type(EntityAPI.GetHealth) == "function" then
            local ok, v = pcall(EntityAPI.GetHealth, unit)
            if ok and finite(v) then health = v end
        end
        local h = model and model:FindFirstChildOfClass("Humanoid")
        if type(health) ~= "number" then health = h and h.Health or 0 end
        return math.max(0, health)
    end
    local function sameRoom(other)
        local own = LP:GetAttribute("GameRoom") or LP:GetAttribute("World")
        local theirs = other:GetAttribute("GameRoom") or other:GetAttribute("World")
        return not (own and theirs and own ~= theirs)
    end
    local function friendlyUnit(unit)
        if not Config.teamCheck then return false end
        return TeamCheck.IsFriendlyUnit(unit)
    end
    local function partsList()
        if type(Config.aimParts) == "table" and #Config.aimParts > 0 then return Config.aimParts end
        return { "Head" }
    end
    local function candidateParts(unit)
        if unit == LP or not sameRoom(unit) then return nil end
        local model = characterOf(unit)
        if not model or not model:IsDescendantOf(workspace) then return nil end
        if healthOf(unit, model) <= 0 then return nil end
        if EntityAPI and type(EntityAPI.IsAlive) == "function" then
            local ok, v = pcall(EntityAPI.IsAlive, unit)
            if ok and v == false then return nil end
        end
        local collider = model:FindFirstChild("Collider")
        local out, seenParts = {}, {}
        for rank, name in ipairs(partsList()) do
            local lookup = (name == "UpperTorso") and "Body" or name
            local part = collider and collider:FindFirstChild(lookup, true) or model:FindFirstChild(name)
            if part and part:IsA("BasePart") and validPosition(part.Position) and not seenParts[part] then
                seenParts[part] = true
                table.insert(out, { part = part, position = part.Position, name = name, rank = rank })
            end
        end
        if #out == 0 then return nil end
        return model, out
    end
    local aimCircle
    local function updateFovCircle()
        if not aimCircle then
            local ok = pcall(function()
                aimCircle = Drawing.new("Circle")
                aimCircle.Filled = false
                aimCircle.NumSides = 32
                aimCircle.Visible = false
            end)
            if not ok then return end
        end
        aimCircle.Radius = Config.fovCircleRadius
        aimCircle.Color = Config.fovColor
        aimCircle.Thickness = Config.fovThickness
        aimCircle.Transparency = Config.fovTransparency
        aimCircle.Visible = Config.fovVisible and Config.fovEnabled and Config.enabled and alive
    end
    updateFovCircle()
    RunService.RenderStepped:Connect(function()
        if aimCircle and aimCircle.Visible then
            local cam = workspace.CurrentCamera
            if cam then aimCircle.Position = cam.ViewportSize / 2 end
        end
    end)
    local function chooseTarget()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local origin = camera.ViewportSize / 2
        local best = nil
        Stats.fovFiltered = 0
        for _, unit in ipairs(getAllTargets(Config.aimBots)) do
            if not friendlyUnit(unit) then
                local model, parts = candidateParts(unit)
                if model then
                    for _, entry in ipairs(parts) do
                        local pos = entry.position
                        if (pos - camera.CFrame.Position).Magnitude <= Config.maxDistance then
                            local point, onScreen = camera:WorldToViewportPoint(pos)
                            if onScreen and point.Z > 0 then
                                local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude
                                if not Config.fovEnabled or delta < Config.fovRadius then
                                    local visible = not Config.wallCheck or WallCheck.CanSee(camera, model, pos)
                                    local better
                                    if not best then better = true
                                    elseif visible and not best.visible then better = true
                                    elseif visible == best.visible then
                                        if delta < best.delta - 0.01 then better = true
                                        elseif math.abs(delta - best.delta) <= 0.01 and entry.rank < best.rank then better = true end
                                    end
                                    if better then
                                        best = { unit = unit, part = entry.part, position = pos, name = entry.name, delta = delta, visible = visible, rank = entry.rank }
                                    end
                                else Stats.fovFiltered += 1 end
                            end
                        end
                    end
                end
            end
        end
        if best then return best.unit, best.position, best.part, best.name end
        return nil
    end
    local function clearSilent()
        local unhook = getgenv().restorefunction or (type(restorefunction) == "function" and restorefunction)
        if type(unhook) == "function" then for _, fn in ipairs(silentHooks) do pcall(unhook, fn) end end
        table.clear(silentHooks)
        silentDepth, silentChoice = 0, nil
        Stats.installed = false; Stats.hooks = 0
        if aimCircle then aimCircle.Visible = false end
    end
    local function installSilent()
        if #silentHooks > 0 then return true end
        local hook = getgenv().hookfunction or (type(hookfunction) == "function" and hookfunction)
        local unhook = getgenv().restorefunction or (type(restorefunction) == "function" and restorefunction)
        local ups = getgenv().getupvalues or (debug and debug.getupvalues)
        if type(hook) ~= "function" or type(unhook) ~= "function" or type(ups) ~= "function" then
            Stats.error = "Executor lacks hookfunction/restorefunction/getupvalues"
            return false
        end
        local ok, err = pcall(function()
            local cameraAPI = require(ReplicatedStorage.Client.CameraController)
            local shootable = require(ReplicatedStorage.Client.CombatController.ClientComponent.ClientShootableComponent)
            local originFn = cameraAPI.GetCombatOriginFn()
            local originState
            for _, v in pairs(ups(originFn)) do
                if type(v) == "table" and type(v.Get) == "function" and v.TempParams then originState = v; break end
            end
            local targetingInternal
            for _, v in pairs(ups(cameraAPI.GetTargetingFn())) do
                if type(v) == "function" then targetingInternal = v; break end
            end
            assert(originState and targetingInternal and type(shootable.LocalShoot) == "function", "Shot API unavailable")

            local originalOrigin
            originalOrigin = hook(originState.Get, function(...)
                local cf, at, params = originalOrigin(...)
                if alive and Config.enabled and silentDepth > 0 and silentChoice and typeof(cf) == "CFrame" then
                    return CFrame.lookAt(cf.Position, silentChoice.position), at, params
                end
                return cf, at, params
            end)
            table.insert(silentHooks, originState.Get)

            local originalTargeting
            originalTargeting = hook(targetingInternal, function(...)
                if alive and Config.enabled and silentDepth > 0 and silentChoice then
                    return silentChoice.position, silentChoice.part
                end
                return originalTargeting(...)
            end)
            table.insert(silentHooks, targetingInternal)

            local originalShoot
            originalShoot = hook(shootable.LocalShoot, function(self, ...)
                local choice
                Stats.lastTarget = nil; Stats.lastPart = nil
                if alive and Config.enabled and not UIS:GetFocusedTextBox() then
                    local unit, position, part, name = chooseTarget()
                    if unit and part then
                        choice = { unit = unit, position = position, part = part, name = name }
                        Stats.lastTarget = (typeof(unit) == "Instance" and unit.Name) or tostring(unit)
                        Stats.lastPart = name
                    end
                end
                if choice and Config.noDelay and type(self._LastShootTime) == "number"
                    and type(self.GetTimeNow) == "function"
                    and self.Holder and type(self.Holder.GetCurrentAttackRate) == "function" then
                    local ok2, remaining = pcall(function()
                        local rate = self.Holder:GetCurrentAttackRate("Shoot")
                        if type(rate) ~= "number" or rate <= 0 then return 0 end
                        return 1 / rate - (self:GetTimeNow() - self._LastShootTime)
                    end)
                    if ok2 and remaining > 0.01 then return nil end
                end
                local args = table.pack(...)
                if choice and (args[1] == nil or type(args[1]) == "table") and EntityAPI and type(EntityAPI.GetEntity) == "function" then
                    local ok3, packet = pcall(function()
                        local entity = EntityAPI.GetEntity(choice.unit)
                        if not entity or not entity.Instance then return nil end
                        local pivot = entity:GetPivot(true)
                        if typeof(pivot) ~= "CFrame" then return nil end
                        local v = table.clone(args[1] or {})
                        v.Target = entity.Instance
                        v.TargetPos = pivot:PointToObjectSpace(choice.position)
                        v.TargetHeadshot = choice.name == "Head"
                        return v
                    end)
                    if ok3 and packet then args[1] = packet; args.n = math.max(args.n, 1) end
                end
                local previous = silentChoice
                silentChoice = choice
                silentDepth += 1
                local result = table.pack(pcall(originalShoot, self, table.unpack(args, 1, args.n)))
                silentDepth -= 1
                silentChoice = previous
                if not result[1] then error(result[2], 0) end
                return table.unpack(result, 2, result.n)
            end)
            table.insert(silentHooks, shootable.LocalShoot)
        end)
        if not ok then clearSilent(); Stats.error = tostring(err); return false end
        Stats.installed = true; Stats.hooks = #silentHooks; updateFovCircle()
        return true
    end
    local API = {
        Config = Config, Stats = Stats,
        Start = function() Config.enabled = true; local ok = installSilent(); updateFovCircle(); return ok end,
        Stop = function() Config.enabled = false; clearSilent() end,
        SetAimParts = function(list) if type(list) == "table" and #list > 0 then Config.aimParts = list end end,
        SetFovRadius = function(px) Config.fovRadius = math.max(0, px); Config.fovCircleRadius = Config.fovRadius; updateFovCircle() end,
        SetFovVisible = function(v) Config.fovVisible = (v ~= false); updateFovCircle() end,
    }
    SilentAim.API = API
    pcall(installSilent)
end

local TriggerBot = { Enabled = false, VisibleCheck = false, TeamCheck = false, MaxDistance = 500, ClickCooldown = 0.1, _lastClick = 0, _conn = nil, _raycastParams = nil }
local function tbBuildRaycastParams()
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    if LP.Character then p.FilterDescendantsInstances = {LP.Character} end
    return p
end
TriggerBot._raycastParams = tbBuildRaycastParams()
LP.CharacterAdded:Connect(function() task.wait(0.2); TriggerBot._raycastParams = tbBuildRaycastParams() end)

local function tbGetPlayerUnderCursor()
    local p = TriggerBot._raycastParams
    if not p then return nil end
    local mp = UIS:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
    local res = workspace:Raycast(ray.Origin, ray.Direction * TriggerBot.MaxDistance, p)
    if not res then return nil end
    local hitChar = res.Instance:FindFirstAncestorOfClass("Model")
    if not hitChar then return nil end
    local hp = Players:GetPlayerFromCharacter(hitChar)
    if not hp or hp == LP then return nil end
    local hum = hitChar:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    if TriggerBot.TeamCheck and TeamCheck.IsFriendlyPlayer(hp) then return nil end
    if TriggerBot.VisibleCheck and not WallCheck.CanSee(Camera, hitChar, res.Position) then return nil end
    return hp, hitChar
end
local function tbClick()
    local m1 = getgenv().mouse1click or (type(mouse1click) == "function" and mouse1click)
    if type(m1) == "function" then pcall(m1); return true end
    local vim = game:GetService("VirtualInputManager")
    if vim then
        pcall(function()
            vim:SendMouseButtonEvent(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y, 0, true, game, 1, false)
            task.wait(0.02)
            vim:SendMouseButtonEvent(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y, 0, false, game, 1, false)
        end)
        return true
    end
    return false
end
function TriggerBot.stop() if TriggerBot._conn then TriggerBot._conn:Disconnect(); TriggerBot._conn = nil end end
function TriggerBot.start()
    TriggerBot.stop()
    TriggerBot._conn = RunService.Heartbeat:Connect(function()
        if not TriggerBot.Enabled or UIS:GetFocusedTextBox() then return end
        if not tbGetPlayerUnderCursor() then return end
        local now = os.clock()
        if now - TriggerBot._lastClick < TriggerBot.ClickCooldown then return end
        TriggerBot._lastClick = now
        tbClick()
    end)
end

local ESP = { Enabled = false, ShowBox = false, ShowName = false, ShowDistance = false, MaxDistance = 1000, BoxColor = Color3.fromRGB(255, 0, 0), BoxThickness = 2, TextColor = Color3.fromRGB(255, 255, 255), TextSize = 16, TeamCheck = false }
local ESPFolder = Instance.new("Folder")
ESPFolder.Parent = CoreGui
local ESPBoxes, ESPLabels = {}, {}

local function espCreateBox(model)
    if not model or ESPBoxes[model] then return end
    local b = {Top=Drawing.new("Line"),Bottom=Drawing.new("Line"),Left=Drawing.new("Line"),Right=Drawing.new("Line")}
    for _, l in pairs(b) do l.Visible=false; l.Color=ESP.BoxColor; l.Thickness=ESP.BoxThickness end
    ESPBoxes[model] = b
end
local function espCreateLabel(model)
    if not model or ESPLabels[model] then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "VoxerLabel"
    bb.Parent = ESPFolder
    bb.ResetOnSpawn = false
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,200,0,50)
    bb.StudsOffsetWorldSpace = Vector3.new(0,3,0)
    bb.Enabled = false
    local nl = Instance.new("TextLabel", bb)
    nl.BackgroundTransparency = 1
    nl.Size = UDim2.new(1,0,0.6,0)
    nl.Font = Enum.Font.GothamBold
    nl.TextSize = ESP.TextSize
    nl.TextColor3 = ESP.TextColor
    nl.TextStrokeTransparency = 0
    local dl = Instance.new("TextLabel", bb)
    dl.BackgroundTransparency = 1
    dl.Size = UDim2.new(1,0,0.4,0)
    dl.Position = UDim2.new(0,0,0.6,0)
    dl.Font = Enum.Font.Gotham
    dl.TextSize = ESP.TextSize - 2
    dl.TextColor3 = Color3.fromRGB(200,200,200)
    dl.TextStrokeTransparency = 0
    ESPLabels[model] = {Billboard=bb, NameLabel=nl, DistanceLabel=dl}
end
local function espRemoveModel(model)
    if ESPBoxes[model] then for _,l in pairs(ESPBoxes[model]) do l:Remove() end; ESPBoxes[model]=nil end
    if ESPLabels[model] then ESPLabels[model].Billboard:Destroy(); ESPLabels[model]=nil end
end
local function espUpdateUnit(unit)
    local model = getUnitModel(unit)
    if not model then return end
    if not ESPBoxes[model] then espCreateBox(model) end
    if not ESPLabels[model] then espCreateLabel(model) end
    
    local isFriendly = false
    if typeof(unit) == "Instance" and unit:IsA("Player") and ESP.TeamCheck and TeamCheck.IsFriendlyPlayer(unit) then
        isFriendly = true
    end

    local hrp = model:FindFirstChild("HumanoidRootPart")
    local hum = model:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        for _,l in pairs(ESPBoxes[model]) do l.Visible=false end
        ESPLabels[model].Billboard.Enabled = false
        return
    end

    local d = (hrp.Position - Camera.CFrame.Position).Magnitude
    local b = ESPBoxes[model]
    
    if not ESP.Enabled or not ESP.ShowBox or isFriendly or d > ESP.MaxDistance then
        for _,l in pairs(b) do l.Visible=false end
    else
        local sz = model:GetExtentsSize()
        local tp = (hrp.CFrame * CFrame.new(0, sz.Y/2, 0)).Position
        local bp = (hrp.CFrame * CFrame.new(0, -sz.Y/2, 0)).Position
        local t, to_ = Camera:WorldToViewportPoint(tp)
        local bt, bo_ = Camera:WorldToViewportPoint(bp)
        if not to_ or not bo_ or t.Z<=0 or bt.Z<=0 then
            for _,l in pairs(b) do l.Visible=false end
        else
            local h = bt.Y - t.Y
            local w = h * 0.65
            local lX, rX = t.X - w/2, t.X + w/2
            b.Top.From = Vector2.new(lX, t.Y); b.Top.To = Vector2.new(rX, t.Y); b.Top.Visible = true
            b.Bottom.From = Vector2.new(lX, bt.Y); b.Bottom.To = Vector2.new(rX, bt.Y); b.Bottom.Visible = true
            b.Left.From = Vector2.new(lX, t.Y); b.Left.To = Vector2.new(lX, bt.Y); b.Left.Visible = true
            b.Right.From = Vector2.new(rX, t.Y); b.Right.To = Vector2.new(rX, bt.Y); b.Right.Visible = true
        end
    end

    local dl = ESPLabels[model]
    if not ESP.Enabled or isFriendly or (not ESP.ShowName and not ESP.ShowDistance) or d > ESP.MaxDistance then
        dl.Billboard.Enabled = false
    else
        dl.Billboard.Adornee = hrp
        dl.Billboard.Enabled = true
        if ESP.ShowName then
            dl.NameLabel.Visible = true
            dl.NameLabel.Text = typeof(unit) == "Instance" and unit:IsA("Player") and unit.DisplayName or model.Name
            dl.NameLabel.TextColor3 = ESP.TextColor
            dl.NameLabel.TextSize = ESP.TextSize
        else dl.NameLabel.Visible = false end
        if ESP.ShowDistance then
            dl.DistanceLabel.Visible = true
            dl.DistanceLabel.Text = string.format("[%d]", math.floor(d))
            dl.DistanceLabel.TextSize = math.max(ESP.TextSize - 2, 8)
        else dl.DistanceLabel.Visible = false end
    end
end

RunService.RenderStepped:Connect(function()
    local units = getAllTargets()
    local activeModels = {}
    for _, unit in ipairs(units) do
        local model = getUnitModel(unit)
        if model then
            activeModels[model] = true
            espUpdateUnit(unit)
        end
    end
    for model, _ in pairs(ESPBoxes) do if not activeModels[model] then espRemoveModel(model) end end
end)

function ESP.SetEnabled(v)
    ESP.Enabled = v
    if not v then
        for _,b in pairs(ESPBoxes) do for _,l in pairs(b) do l.Visible=false end end
        for _,d in pairs(ESPLabels) do d.Billboard.Enabled=false end
    end
end

local Chams = { Enabled = false, AlwaysOnTop = false, Outline = false, FillColor = Color3.fromRGB(255, 0, 0), OutlineColor = Color3.fromRGB(255, 255, 255), Transparency = 0.5, TeamCheck = false }
local ChamsFolder = Instance.new("Folder")
ChamsFolder.Parent = CoreGui
local ChamsHighlights = {}

local function chamsApply(hl)
    hl.FillColor = Chams.FillColor
    hl.OutlineColor = Chams.OutlineColor
    hl.FillTransparency = Chams.Transparency
    hl.OutlineTransparency = Chams.Outline and 0 or 1
    hl.DepthMode = Chams.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
end

local function chamsCreate(model)
    if not model or ChamsHighlights[model] then return end
    local hl = Instance.new("Highlight")
    hl.Parent = ChamsFolder
    hl.Enabled = false
    chamsApply(hl)
    ChamsHighlights[model] = hl
end

local function chamsRemoveModel(model)
    if ChamsHighlights[model] then ChamsHighlights[model]:Destroy(); ChamsHighlights[model]=nil end
end

local function chamsUpdateUnit(unit)
    local model = getUnitModel(unit)
    if not model then return end
    if not ChamsHighlights[model] then chamsCreate(model) end
    local hl = ChamsHighlights[model]
    
    local isFriendly = false
    if typeof(unit) == "Instance" and unit:IsA("Player") and Chams.TeamCheck and TeamCheck.IsFriendlyPlayer(unit) then
        isFriendly = true
    end

    if not Chams.Enabled or isFriendly then
        hl.Enabled = false
        return
    end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        hl.Enabled = false
        return
    end
    hl.Adornee = model
    hl.Enabled = true
    chamsApply(hl)
end

RunService.RenderStepped:Connect(function()
    local units = getAllTargets()
    local activeModels = {}
    for _, unit in ipairs(units) do
        local model = getUnitModel(unit)
        if model then
            activeModels[model] = true
            chamsUpdateUnit(unit)
        end
    end
    for model, _ in pairs(ChamsHighlights) do if not activeModels[model] then chamsRemoveModel(model) end end
end)

function Chams.SetEnabled(v)
    Chams.Enabled = v
    if not v then for _,hl in pairs(ChamsHighlights) do hl.Enabled=false end end
end

-- ИЗМЕНЕНО: Обертки для нажатия клавиш
local function doKeyPress(vkCode)
    local kp = getgenv().keypress or (type(keypress) == "function" and keypress)
    if type(kp) == "function" then pcall(kp, vkCode) return end
    local vim = game:GetService("VirtualInputManager")
    if vim then 
        local key = Enum.KeyCode.LeftControl
        if vkCode == 0x11 then key = Enum.KeyCode.LeftControl end
        pcall(function() vim:SendKeyEvent(true, key, false, game) end) 
    end
end
local function doKeyRelease(vkCode)
    local kr = getgenv().keyrelease or (type(keyrelease) == "function" and keyrelease)
    if type(kr) == "function" then pcall(kr, vkCode) return end
    local vim = game:GetService("VirtualInputManager")
    if vim then 
        local key = Enum.KeyCode.LeftControl
        if vkCode == 0x11 then key = Enum.KeyCode.LeftControl end
        pcall(function() vim:SendKeyEvent(false, key, false, game) end) 
    end
end

-- ИЗМЕНЕНО: Добавлена логика Bypass в Speed
local Speed = { Enabled = false, Amount = 50, BypassMethod = "None", _conn = nil, _isPulsing = false }
function Speed.stop() 
    if Speed._conn then Speed._conn:Disconnect(); Speed._conn = nil end 
    Speed._isPulsing = false
    doKeyRelease(0x11)
end
function Speed.start()
    Speed.stop()
    Speed._conn = RunService.Heartbeat:Connect(function(dt)
        if not Speed.Enabled then return end
        local c = LP.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not h then return end
        local hv = Vector3.zero
        if h.MoveDirection.Magnitude > 0 then hv = h.MoveDirection * (Speed.Amount/50) * 60 end
        
        -- Bypass Pulse: остановка движения
        if Speed.BypassMethod == "Pulse" and Speed._isPulsing then
            hv = Vector3.zero
        end
        
        hrp.AssemblyLinearVelocity = Vector3.new(hv.X, hrp.AssemblyLinearVelocity.Y, hv.Z)
    end)
    
    -- Bypass Slide & Pulse логика таймеров
    task.spawn(function()
        local lastSlide = 0
        local lastPulse = 0
        while Speed.Enabled do
            local now = os.clock()
            if Speed.BypassMethod == "Slide" then
                if now - lastSlide >= 1.5 then
                    lastSlide = now
                    doKeyPress(0x11)
                    task.wait(0.5)
                    doKeyRelease(0x11)
                else
                    task.wait(0.1)
                end
            elseif Speed.BypassMethod == "Pulse" then
                if now - lastPulse >= 1 then
                    lastPulse = now
                    Speed._isPulsing = true
                    task.wait(.3)
                    Speed._isPulsing = false
                else
                    task.wait(0.1)
                end
            else
                Speed._isPulsing = false
                task.wait(0.1)
            end
        end
        Speed._isPulsing = false
        doKeyRelease(0x11)
    end)
end

local Fly = { Enabled = false, Speed = 50, VerticalSpeed = 50, _conn = nil }
function Fly.stop() if Fly._conn then Fly._conn:Disconnect(); Fly._conn = nil end end
function Fly.start()
    Fly.stop()
    Fly._conn = RunService.Heartbeat:Connect(function(dt)
        if not Fly.Enabled then return end
        local c = LP.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local h = c:FindFirstChildOfClass("Humanoid")
        if not hrp or not h then return end
        local hv = Vector3.zero
        if h.MoveDirection.Magnitude > 0 then hv = h.MoveDirection * (Fly.Speed/50) * 60 end
        local vert = 0
        if UIS:IsKeyDown(Enum.KeyCode.E) then vert = vert + 1 end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vert = vert - 1 end
        if vert ~= 0 then
            local vs = vert * (Fly.VerticalSpeed/50) * (dt*60)
            hrp.CFrame = hrp.CFrame + Vector3.new(0, vs, 0)
        end
        hrp.AssemblyLinearVelocity = Vector3.new(hv.X, 0, hv.Z)
    end)
end

local combat = tabFrames.Combat
local RageBot = { Enabled = false, LimitToFOV = false, QuickScope = false, TeamCheck = false, MaxDistance = 500, FOVRadius = 220, WallCheck = true, ClickCooldown = 1, _lastClick = 0 }

local function rbClick()
    local m1 = getgenv().mouse1click or (type(mouse1click) == "function" and mouse1click)
    if type(m1) == "function" then pcall(m1); return true end
    local vim = game:GetService("VirtualInputManager")
    if vim then
        pcall(function()
            vim:SendMouseButtonEvent(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y, 0, true, game, 1, false)
            task.wait(0.01)
            vim:SendMouseButtonEvent(UIS:GetMouseLocation().X, UIS:GetMouseLocation().Y, 0, false, game, 1, false)
        end)
        return true
    end
    return false
end
local function qsScopeDown()
    local m2d = getgenv().mouse2down
    if type(m2d) == "function" then pcall(m2d); return end
    local vim = game:GetService("VirtualInputManager")
    if vim then pcall(function() vim:SendMouseButtonEvent(0, 0, 2, true, game, 1, false) end) end
end
local function qsScopeUp()
    local m2u = getgenv().mouse2up
    if type(m2u) == "function" then pcall(m2u); return end
    local vim = game:GetService("VirtualInputManager")
    if vim then pcall(function() vim:SendMouseButtonEvent(0, 0, 2, false, game, 1, false) end) end
end

local AimAssist = { Enabled = false, Hold = true, Radius = 220, Smooth = 3, AimPart = "Head", WallCheck = true, TeamCheck = false, MaxDistance = 1500, AimBots = true, ShowFOV = false, _running = false }
local ENV = getgenv()
local aaMouseMove = ENV.mousemoverel or (type(mousemoverel) == "function" and mousemoverel)
local aaPointerAvailable = type(aaMouseMove) == "function"

local aaOverlay
do
    local ok = pcall(function()
        local g = Instance.new("ScreenGui")
        g.Name = "VoxerAdmin_AA"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 49
        g.Parent = CoreGui
        aaOverlay = g
    end)
    if not ok or not aaOverlay then
        local g = Instance.new("ScreenGui")
        g.Name = "VoxerAdmin_AA"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 49
        g.Parent = LP:WaitForChild("PlayerGui")
        aaOverlay = g
    end
end
local aaFovCircle = Instance.new("Frame")
aaFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
aaFovCircle.BackgroundTransparency = 1
aaFovCircle.Visible = false
aaFovCircle.Parent = aaOverlay
Instance.new("UICorner", aaFovCircle).CornerRadius = UDim.new(0.5, 0)
local aaFovStroke = Instance.new("UIStroke", aaFovCircle)
aaFovStroke.Color = Color3.fromRGB(0, 255, 100)
aaFovStroke.Thickness = 1.5
aaFovStroke.Transparency = 0.15

local aaFinite = function(n) return type(n) == "number" and n == n and math.abs(n) < 1e6 end
local aaValidPos = function(p) return typeof(p) == "Vector3" and aaFinite(p.X) and aaFinite(p.Y) and aaFinite(p.Z) end
local function aaCharacterOf(unit)
    if typeof(unit) == "Instance" and unit:IsA("Model") then return unit end
    if EntityAPI and type(EntityAPI.GetEntity) == "function" then
        local ok, model = pcall(function() local e = EntityAPI.GetEntity(unit); return e and e:GetModel() end)
        if ok and typeof(model) == "Instance" and model:IsA("Model") then return model end
    end
    return unit.Character
end
local function aaHealthOf(unit, model)
    local h = unit:GetAttribute("Health")
    if EntityAPI and type(EntityAPI.GetHealth) == "function" then
        local ok, v = pcall(EntityAPI.GetHealth, unit)
        if ok and aaFinite(v) then h = v end
    end
    local hh = model and model:FindFirstChildOfClass("Humanoid")
    if type(h) ~= "number" then h = hh and hh.Health or 0 end
    return math.max(0, h)
end
local function aaSameRoom(unit)
    local o = LP:GetAttribute("GameRoom") or LP:GetAttribute("World")
    local t = unit:GetAttribute("GameRoom") or unit:GetAttribute("World")
    return not (o and t and o ~= t)
end
local function aaFriendly(unit)
    if not AimAssist.TeamCheck then return false end
    return TeamCheck.IsFriendlyUnit(unit)
end
local function aaCandidate(unit)
    if unit == LP or not aaSameRoom(unit) then return nil end
    local model = aaCharacterOf(unit)
    if not model or not model:IsDescendantOf(workspace) then return nil end
    if aaHealthOf(unit, model) <= 0 then return nil end
    if EntityAPI and type(EntityAPI.IsAlive) == "function" then
        local ok, v = pcall(EntityAPI.IsAlive, unit)
        if ok and v == false then return nil end
    end
    local collider = model:FindFirstChild("Collider")
    local req = AimAssist.AimPart
    local part = collider and collider:FindFirstChild(req == "UpperTorso" and "Body" or req, true)
        or model:FindFirstChild(req) or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
    if not part or not part:IsA("BasePart") or not aaValidPos(part.Position) then return nil end
    return model, part
end
local function aaAimOrigin(camera)
    if (UIS.TouchEnabled and not UIS.MouseEnabled) or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return camera.ViewportSize / 2
    end
    return UIS:GetMouseLocation() - GuiService:GetGuiInset()
end

local function aaChooseTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local origin = aaAimOrigin(camera)
    local best, bestPos, bestPart, score = nil, nil, nil, AimAssist.Radius
    local bestVisible = false
    for _, unit in ipairs(getAllTargets(AimAssist.AimBots)) do
        if not aaFriendly(unit) then
            local model, part = aaCandidate(unit)
            if model and part then
                local position = part.Position
                local point, visible = camera:WorldToViewportPoint(position)
                if visible and point.Z > 0 and (position - camera.CFrame.Position).Magnitude <= AimAssist.MaxDistance then
                    local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude
                    if delta < AimAssist.Radius then
                        local vS = not AimAssist.WallCheck or WallCheck.CanSee(camera, model, position)
                        local allowed = not AimAssist.WallCheck or vS
                        local pV = vS and not bestVisible
                        local sP = (vS == bestVisible)
                        if allowed and (pV or (sP and delta < score)) then
                            best, bestPos, bestPart, score, bestVisible = unit, position, part, delta, vS
                        end
                    end
                end
            end
        end
    end
    if best then return best, bestPos, bestPart end
    return nil
end
local function aaAlpha(dt) return 1 - math.exp(-180 / math.max(1, AimAssist.Smooth) * math.clamp(dt, 0, 0.05)) end
local function aaAimAt(position, dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    local alpha = aaAlpha(dt)
    if aaPointerAvailable then
        local point = camera:WorldToViewportPoint(position)
        if not point.Z or point.Z <= 0 then return end
        local origin = aaAimOrigin(camera)
        local delta = (Vector2.new(point.X, point.Y) - origin) * alpha
        aaMouseMove(math.clamp(delta.X, -160, 160), math.clamp(delta.Y, -160, 160))
    else
        local cf = camera.CFrame
        camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, position), alpha)
    end
end
RunService.RenderStepped:Connect(function(dt)
    local camera = workspace.CurrentCamera
    if not camera then return end
    aaFovCircle.Visible = AimAssist.Enabled and AimAssist.ShowFOV
    if aaFovCircle.Visible then
        local origin = aaAimOrigin(camera)
        aaFovCircle.Position = UDim2.fromOffset(origin.X, origin.Y)
        local diameter = AimAssist.Radius * 2
        if aaFovCircle.Size.X.Offset ~= diameter then aaFovCircle.Size = UDim2.fromOffset(diameter, diameter) end
    end
    if not AimAssist.Enabled then AimAssist._running = false; return end
    if UIS:GetFocusedTextBox() then return end
    local touch = UIS.TouchEnabled and not UIS.MouseEnabled
    local engaged
    if touch then engaged = not AimAssist.Hold or AimAssist._running
    else engaged = not AimAssist.Hold or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if not engaged then AimAssist._running = false; return end
    AimAssist._running = true
    local lm = aaCharacterOf(LP)
    if aaHealthOf(LP, lm) <= 0 then return end
    local target, position = aaChooseTarget()
    if not target or not position then return end
    aaAimAt(position, dt)
end)

local saCard, saSet, saEnable, saKeybind = buildModule(combat, {
    name = "SilentAim", title = "Silent Aim", cardH = 0.25, layoutOrder = 1,
    titleSize = UDim2.new(0.4464, 0, 0.08639, 0), titlePos = UDim2.new(0.27153, 0, 0.08598, 0),
    enablePos = UDim2.new(0.85341, 0, 0.0858, 0), enableSize = UDim2.new(0.1, 0, 0.074, 0),
    keybindPos = UDim2.new(0.67498, 0, 0.08483, 0), keybindSize = UDim2.new(0.15007, 0, 0.06872, 0),
    settingsPos = UDim2.new(0.5, 0, 0.5815, 0), settingsSize = UDim2.new(1, 0, 0.83699, 0),
    onEnable = function(v)
        if v then
            SilentAim.Enabled = true
            local ok = SilentAim.API.Start()
            if not ok then warn("[Voxer Admin] Silent Aim не установлен") end
        else
            SilentAim.Enabled = false
            SilentAim.API.Stop()
        end
    end,
})
local saFovState = makeSliderRow(saSet, "FOV", 0, 1000, 100, 1, 0, function(v) if SilentAim.API then SilentAim.API.SetFovRadius(v) end end)
local saShowFovState = makeToggleRow(saSet, "Show FOV", 2)
local saVisibleState = makeToggleRow(saSet, "VIsible Check", 3)
local saTeamState = makeToggleRow(saSet, "Team Check", 4)
local saDistState = makeSliderRow(saSet, "Distance", 0, 5000, 500, 5, 0, function(v) if SilentAim.API then SilentAim.API.Config.maxDistance = v end end)
local function saApplyHitPart(val)
    if not SilentAim.API then return end
    if val == "Closest" or val == "Head, Torso" then SilentAim.API.SetAimParts({"Head","UpperTorso","HumanoidRootPart"})
    elseif val == "Head" then SilentAim.API.SetAimParts({"Head"})
    elseif val == "Torso" then SilentAim.API.SetAimParts({"UpperTorso"}) end
end
local saHitPartState = makeDropdownRow(saSet, "Hit Part", "Head, Torso", 6, saApplyHitPart)
saApplyHitPart(saHitPartState.Value)
if SilentAim.API then
    SilentAim.API.SetFovRadius(saFovState.Value)
    SilentAim.API.SetFovVisible(saShowFovState.Enabled)
    SilentAim.API.Config.wallCheck = saVisibleState.Enabled
    SilentAim.API.Config.teamCheck = saTeamState.Enabled
    SilentAim.API.Config.maxDistance = saDistState.Value
    RunService.Heartbeat:Connect(function()
        SilentAim.API.Config.wallCheck = saVisibleState.Enabled
        SilentAim.API.Config.teamCheck = saTeamState.Enabled
        SilentAim.API.Config.maxDistance = saDistState.Value
        SilentAim.API.SetFovVisible(saShowFovState.Enabled)
    end)
end

local aaCard, aaSet, aaEnable, aaKeybind = buildModule(combat, {
    name = "AimAssist", title = "Aim Assist", cardH = 0.27, layoutOrder = 2,
    titleSize = UDim2.new(0.44479, 0, 0.07877, 0), titlePos = UDim2.new(0.27096, 0, 0.07877, 0),
    enablePos = UDim2.new(0.85208, 0, 0.07877, 0), enableSize = UDim2.new(0.09884, 0, 0.06665, 0),
    keybindPos = UDim2.new(0.67485, 0, 0.07675, 0), keybindSize = UDim2.new(0.14997, 0, 0.06261, 0),
    settingsPos = UDim2.new(0.49932, 0, 0.53723, 0), settingsSize = UDim2.new(0.99864, 0, 0.77352, 0),
    onEnable = function(v) AimAssist.Enabled = v; if not v then AimAssist._running = false end end,
})
local aaFovState = makeSliderRow(aaSet, "FOV", 50, 800, 220, 1, 0, function(v) AimAssist.Radius = v end)
AimAssist.Radius = aaFovState.Value
local aaShowFovState = makeToggleRow(aaSet, "Show FOV", 2)
local aaVisibleState = makeToggleRow(aaSet, "VIsible Check", 3)
local aaTeamState = makeToggleRow(aaSet, "Team Check", 4)
local aaDistState = makeSliderRow(aaSet, "Distance", 0, 5000, 1500, 5, 0, function(v) AimAssist.MaxDistance = v end)
AimAssist.MaxDistance = aaDistState.Value
local aaSmoothState = makeSliderRow(aaSet, "Smoothness", 1, 20, 3, 6, 0, function(v) AimAssist.Smooth = v end)
AimAssist.Smooth = aaSmoothState.Value
local function aaApplyHitPart(val)
    if val == "Closest" or val == "Head, Torso" then AimAssist.AimPart = "Head"
    elseif val == "Head" then AimAssist.AimPart = "Head"
    elseif val == "Torso" then AimAssist.AimPart = "UpperTorso" end
end
local aaHitPartState = makeDropdownRow(aaSet, "Hit Part", "Head, Torso", 7, aaApplyHitPart)
aaApplyHitPart(aaHitPartState.Value)
AimAssist.ShowFOV = aaShowFovState.Enabled
AimAssist.WallCheck = aaVisibleState.Enabled
AimAssist.TeamCheck = aaTeamState.Enabled
RunService.Heartbeat:Connect(function()
    AimAssist.Radius = aaFovState.Value
    AimAssist.ShowFOV = aaShowFovState.Enabled
    AimAssist.WallCheck = aaVisibleState.Enabled
    AimAssist.TeamCheck = aaTeamState.Enabled
    AimAssist.MaxDistance = aaDistState.Value
    AimAssist.Smooth = aaSmoothState.Value
end)

local tbCard, tbSet, tbEnable, tbKeybind = buildModule(combat, {
    name = "TriggerBot", title = "Trigger Bot", cardH = 0.14, layoutOrder = 3,
    titleSize = UDim2.new(0.44479, 0, 0.15191, 0), titlePos = UDim2.new(0.27096, 0, 0.15191, 0),
    enablePos = UDim2.new(0.85208, 0, 0.15191, 0), enableSize = UDim2.new(0.09884, 0, 0.12854, 0),
    keybindPos = UDim2.new(0.67485, 0, 0.14801, 0), keybindSize = UDim2.new(0.14997, 0, 0.12075, 0),
    settingsPos = UDim2.new(0.49932, 0, 1.03608, 0), settingsSize = UDim2.new(0.99864, 0, 1.4918, 0),
    onEnable = function(v) TriggerBot.Enabled = v; if v then TriggerBot.start() else TriggerBot.stop() end end,
})
local tbVisibleState = makeToggleRow(tbSet, "VIsible Check", 3)
local tbTeamState = makeToggleRow(tbSet, "Team Check", 4)
local tbDistState = makeSliderRow(tbSet, "Distance", 0, 5000, 500, 5, 0, function(v) TriggerBot.MaxDistance = v end)
TriggerBot.MaxDistance = tbDistState.Value
TriggerBot.VisibleCheck = tbVisibleState.Enabled
TriggerBot.TeamCheck = tbTeamState.Enabled
RunService.Heartbeat:Connect(function()
    TriggerBot.VisibleCheck = tbVisibleState.Enabled
    TriggerBot.TeamCheck = tbTeamState.Enabled
    TriggerBot.MaxDistance = tbDistState.Value
end)

local rbCard, rbSet, rbEnable, rbKeybind = buildModule(combat, {
    name = "RageBot", title = "Rage Bot", cardH = 0.17, layoutOrder = 4,
    titleSize = UDim2.new(0.445, 0, 0.125, 0), titlePos = UDim2.new(0.271, 0, 0.125, 0),
    enablePos = UDim2.new(0.852, 0, 0.125, 0), enableSize = UDim2.new(0.099, 0, 0.106, 0),
    keybindPos = UDim2.new(0.675, 0, 0.122, 0), keybindSize = UDim2.new(0.15, 0, 0.099, 0),
    settingsPos = UDim2.new(0.498, 0, 0.853, 0), settingsSize = UDim2.new(0.999, 0, 1.229, 0),
    onEnable = function(v) RageBot.Enabled = v end,
})
local rbLimitFovState = makeToggleRow(rbSet, "Limit To FOV", 1)
local rbQuickScopeState = makeToggleRow(rbSet, "Quick Scope", 2)
local rbTeamState = makeToggleRow(rbSet, "Team Check", 3)
local rbDistState = makeSliderRow(rbSet, "Distance", 0, 5000, 500, 4, 0, function(v) RageBot.MaxDistance = v end)
local rbVisibleState = makeToggleRow(rbSet, "VIsible Check", 5)
RageBot.MaxDistance = rbDistState.Value
RageBot.LimitToFOV = rbLimitFovState.Enabled
RageBot.QuickScope = rbQuickScopeState.Enabled
RageBot.TeamCheck = rbTeamState.Enabled
RageBot.WallCheck = rbVisibleState.Enabled
RunService.Heartbeat:Connect(function()
    RageBot.LimitToFOV = rbLimitFovState.Enabled
    RageBot.QuickScope = rbQuickScopeState.Enabled
    RageBot.TeamCheck = rbTeamState.Enabled
    RageBot.WallCheck = rbVisibleState.Enabled
    RageBot.MaxDistance = rbDistState.Value
    if SilentAim and SilentAim.API and SilentAim.API.Config then
        RageBot.FOVRadius = SilentAim.API.Config.fovRadius
    end
end)
task.spawn(function()
    while task.wait(0.01) do
        if RageBot.Enabled and not UIS:GetFocusedTextBox() then
            local camera = workspace.CurrentCamera
            if camera then
                local origin
                if (UIS.TouchEnabled and not UIS.MouseEnabled) or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
                    origin = camera.ViewportSize / 2
                else
                    origin = UIS:GetMouseLocation() - GuiService:GetGuiInset()
                end
                local bestUnit, bestPart = nil, nil
                local bestDist = RageBot.LimitToFOV and RageBot.FOVRadius or math.huge
                local maxDist = RageBot.MaxDistance
                for _, unit in ipairs(getAllTargets(true)) do
                    if not (RageBot.TeamCheck and TeamCheck.IsFriendlyUnit(unit)) then
                        local model, part = aaCandidate(unit)
                        if model and part then
                            local pos = part.Position
                            local d3 = (pos - camera.CFrame.Position).Magnitude
                            if d3 <= maxDist then
                                local point, onScreen = camera:WorldToViewportPoint(pos)
                                if onScreen and point.Z > 0 then
                                    local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude
                                    if delta < bestDist then
                                        if not RageBot.WallCheck or WallCheck.CanSee(camera, model, pos) then
                                            bestUnit, bestPart = unit, part
                                            bestDist = delta
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if bestUnit and bestPart then
                    local now = os.clock()
                    if now - RageBot._lastClick >= RageBot.ClickCooldown then
                        RageBot._lastClick = now
                        if RageBot.QuickScope then qsScopeDown(); task.wait(0.05) end
                        rbClick()
                        if RageBot.QuickScope then qsScopeUp() end
                    end
                end
            end
        end
    end
end)

local movement = tabFrames.Movement
local spdCard, spdSet, spdEnable, spdKeybind = buildModule(movement, {
    name = "Speed", title = "Speed", cardH = 0.09, layoutOrder = 1,
    titleSize = UDim2.new(0.44479, 0, 0.2363, 0), titlePos = UDim2.new(0.27096, 0, 0.2363, 0),
    enablePos = UDim2.new(0.85208, 0, 0.2363, 0), enableSize = UDim2.new(0.09884, 0, 0.19994, 0),
    keybindPos = UDim2.new(0.67485, 0, 0.23024, 0), keybindSize = UDim2.new(0.14997, 0, 0.18783, 0),
    settingsPos = UDim2.new(0.49932, 0, 1.61168, 0), settingsSize = UDim2.new(0.99864, 0, 2.32057, 0),
    onEnable = function(v) Speed.Enabled = v; if v then Speed.start() else Speed.stop() end end,
})
local spdSliderState = makeSliderRow(spdSet, "Amount", 0, 500, 50, 5, 0, function(v) Speed.Amount = v end)
Speed.Amount = spdSliderState.Value

-- ИЗМЕНЕНО: Добавлен дропдаун Bypass Method для Speed
local spdBypassState = makeDropdownRow(spdSet, "Bypass Method", "None", 6, function(val) Speed.BypassMethod = val end, {"None", "Slide", "Pulse"})
Speed.BypassMethod = spdBypassState.Value

local flyCard, flySet, flyEnable, flyKeybind = buildModule(movement, {
    name = "Fly", title = "Fly", cardH = 0.11, layoutOrder = 2,
    titleSize = UDim2.new(0.445, 0, 0.193, 0), titlePos = UDim2.new(0.271, 0, 0.188, 0),
    enablePos = UDim2.new(0.852, 0, 0.188, 0), enableSize = UDim2.new(0.099, 0, 0.164, 0),
    keybindPos = UDim2.new(0.675, 0, 0.183, 0), keybindSize = UDim2.new(0.15, 0, 0.154, 0),
    settingsPos = UDim2.new(0.498, 0, 1.314, 0), settingsSize = UDim2.new(0.999, 0, 1.899, 0),
    onEnable = function(v) Fly.Enabled = v; if v then Fly.start() else Fly.stop() end end,
})
local flySpeedState = makeSliderRow(flySet, "Speed", 0, 500, 50, 5, 0, function(v) Fly.Speed = v end)
Fly.Speed = flySpeedState.Value
local flyVertState = makeSliderRow(flySet, "Vertical Speed", 0, 500, 50, 5, 0, function(v) Fly.VerticalSpeed = v end)
Fly.VerticalSpeed = flyVertState.Value

local utils = tabFrames.Utilities
local LongNeck = { Enabled = false, LiftAmount = 10, _conn = nil, _holding = false, _targetY = nil, _baseY = nil }
function LongNeck.stop()
    LongNeck._holding = false
    if LongNeck._conn then LongNeck._conn:Disconnect(); LongNeck._conn = nil end
end
function LongNeck.start()
    if LongNeck._holding then return end
    local c = LP.Character
    if not c then return end
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    LongNeck._baseY = r.Position.Y
    LongNeck._targetY = LongNeck._baseY + LongNeck.LiftAmount
    LongNeck._holding = true
    LongNeck._conn = RunService.Heartbeat:Connect(function()
        if not LongNeck._holding then return end
        local ch = LP.Character
        if not ch then LongNeck.stop() return end
        local hrp = ch:FindFirstChild("HumanoidRootPart")
        if not hrp then LongNeck.stop() return end
        local p = hrp.Position
        hrp.CFrame = CFrame.new(p.X, LongNeck._targetY, p.Z) * (hrp.CFrame - hrp.Position)
    end)
end
local lnCard, lnSet, lnEnable, lnKeybind = buildModule(utils, {
    name = "LongNeck", title = "Long Neck", cardH = 0.07, layoutOrder = 1,
    titleSize = UDim2.new(0.445, 0, 0.304, 0), titlePos = UDim2.new(0.271, 0, 0.296, 0),
    enablePos = UDim2.new(0.852, 0, 0.296, 0), enableSize = UDim2.new(0.099, 0, 0.257, 0),
    keybindPos = UDim2.new(0.675, 0, 0.288, 0), keybindSize = UDim2.new(0.15, 0, 0.241, 0),
    settingsPos = UDim2.new(0.498, 0, 2.064, 0), settingsSize = UDim2.new(0.999, 0, 2.984, 0),
    onEnable = function(v) LongNeck.Enabled = v; if v then LongNeck.start() else LongNeck.stop() end end,
})
local lnSliderState = makeSliderRow(lnSet, "Distance", 0, 20, 10, 5, 0, function(v)
    LongNeck.LiftAmount = v
    if LongNeck._holding and LongNeck._baseY then LongNeck._targetY = LongNeck._baseY + v end
end)
LongNeck.LiftAmount = lnSliderState.Value

local renderTab = tabFrames.Render
local espCard, espSet, espEnable, espKeybind = buildModule(renderTab, {
    name = "ESP", title = "ESP", cardH = 0.16, layoutOrder = 1,
    titleSize = UDim2.new(0.44479, 0, 0.13292, 0), titlePos = UDim2.new(0.27096, 0, 0.12951, 0),
    enablePos = UDim2.new(0.85208, 0, 0.12951, 0), enableSize = UDim2.new(0.09884, 0, 0.11247, 0),
    keybindPos = UDim2.new(0.67485, 0, 0.1261, 0), keybindSize = UDim2.new(0.14997, 0, 0.10565, 0),
    settingsPos = UDim2.new(0.49762, 0, 0.90316, 0), settingsSize = UDim2.new(0.99864, 0, 1.30532, 0),
    onEnable = function(v) ESP.SetEnabled(v) end,
})
local espBoxState = makeToggleRow(espSet, "Box", 0)
local espNameState = makeToggleRow(espSet, "Name", 1)
local espDistState = makeToggleRow(espSet, "Distance", 2)
local espTeamState = makeToggleRow(espSet, "Team Check", 3)
ESP.ShowBox = espBoxState.Enabled
ESP.ShowName = espNameState.Enabled
ESP.ShowDistance = espDistState.Enabled
ESP.TeamCheck = espTeamState.Enabled
RunService.Heartbeat:Connect(function()
    ESP.ShowBox = espBoxState.Enabled
    ESP.ShowName = espNameState.Enabled
    ESP.ShowDistance = espDistState.Enabled
    ESP.TeamCheck = espTeamState.Enabled
end)

local chamsCard, chamsSet, chamsEnable, chamsKeybind = buildModule(renderTab, {
    name = "Chams", title = "Chams", cardH = 0.13, layoutOrder = 2,
    titleSize = UDim2.new(0.44479, 0, 0.16359, 0), titlePos = UDim2.new(0.27096, 0, 0.1594, 0),
    enablePos = UDim2.new(0.85208, 0, 0.1594, 0), enableSize = UDim2.new(0.09884, 0, 0.13842, 0),
    keybindPos = UDim2.new(0.67485, 0, 0.1552, 0), keybindSize = UDim2.new(0.14997, 0, 0.13003, 0),
    settingsPos = UDim2.new(0.49762, 0, 1.11158, 0), settingsSize = UDim2.new(0.99864, 0, 1.60655, 0),
    onEnable = function(v) Chams.SetEnabled(v) end,
})
local chamsTopState = makeToggleRow(chamsSet, "Always On Top", 0)
local chamsOutlineState = makeToggleRow(chamsSet, "Outline", 1)
local chamsTeamState = makeToggleRow(chamsSet, "Team Check", 3)
Chams.AlwaysOnTop = chamsTopState.Enabled
Chams.Outline = chamsOutlineState.Enabled
Chams.TeamCheck = chamsTeamState.Enabled
RunService.Heartbeat:Connect(function()
    Chams.AlwaysOnTop = chamsTopState.Enabled
    Chams.Outline = chamsOutlineState.Enabled
    Chams.TeamCheck = chamsTeamState.Enabled
end)

local configTab = tabFrames.Config
local infoLabel = Instance.new("TextLabel", configTab)
infoLabel.BackgroundTransparency = 1
infoLabel.Size = UDim2.new(0.9, 0, 0.15, 0)
infoLabel.AnchorPoint = Vector2.new(0.5, 0.5)
infoLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
infoLabel.LayoutOrder = 0
infoLabel.TextWrapped = true
infoLabel.Text = "Auto-save every " .. AUTO_SAVE_INTERVAL .. "s"
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextScaled = true
infoLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
makeButtonRow(configTab, "Save Config Now", 1, function() SaveConfig(true) end)
makeButtonRow(configTab, "Load Config", 2, function()
    if LoadConfig() then Notify("Config", "Loaded successfully", 3)
    else Notify("Config", "Load failed or no file", 3) end
end)
makeButtonRow(configTab, "Reset to Defaults", 3, function()
    ResetConfig(); SaveConfig(false)
    Notify("Config", "Reset to defaults", 3)
end)

registerState("silent_enabled", saEnable); registerState("silent_fov", saFovState)
registerState("silent_showfov", saShowFovState); registerState("silent_visible", saVisibleState)
registerState("silent_team", saTeamState); registerState("silent_distance", saDistState)
registerState("silent_hitpart", saHitPartState); registerState("silent_keybind", saKeybind)

registerState("aim_enabled", aaEnable); registerState("aim_fov", aaFovState)
registerState("aim_showfov", aaShowFovState); registerState("aim_visible", aaVisibleState)
registerState("aim_team", aaTeamState); registerState("aim_distance", aaDistState)
registerState("aim_smooth", aaSmoothState); registerState("aim_hitpart", aaHitPartState)
registerState("aim_keybind", aaKeybind)

registerState("trigger_enabled", tbEnable); registerState("trigger_visible", tbVisibleState)
registerState("trigger_team", tbTeamState); registerState("trigger_distance", tbDistState)
registerState("trigger_keybind", tbKeybind)

registerState("rage_enabled", rbEnable); registerState("rage_limitfov", rbLimitFovState)
registerState("rage_quickscope", rbQuickScopeState); registerState("rage_team", rbTeamState)
registerState("rage_visible", rbVisibleState); registerState("rage_distance", rbDistState)
registerState("rage_keybind", rbKeybind)

registerState("esp_enabled", espEnable); registerState("esp_box", espBoxState)
registerState("esp_name", espNameState); registerState("esp_distance", espDistState)
registerState("esp_team", espTeamState); registerState("esp_keybind", espKeybind)

registerState("chams_enabled", chamsEnable); registerState("chams_top", chamsTopState)
registerState("chams_outline", chamsOutlineState); registerState("chams_team", chamsTeamState)
registerState("chams_keybind", chamsKeybind)

registerState("speed_enabled", spdEnable); registerState("speed_amount", spdSliderState)
registerState("speed_bypass", spdBypassState); registerState("speed_keybind", spdKeybind)

registerState("fly_enabled", flyEnable); registerState("fly_speed", flySpeedState)
registerState("fly_vertical", flyVertState); registerState("fly_keybind", flyKeybind)

registerState("neck_enabled", lnEnable); registerState("neck_distance", lnSliderState)
registerState("neck_keybind", lnKeybind)

ensureConfigFolder()
task.wait(0.5)
if type(isfile) == "function" and isfile(CONFIG_FILE) then
    if LoadConfig() then Notify("Voxer", "Config loaded", 3)
    else Notify("Voxer", "Config load failed", 3) end
else
    SaveConfig(false)
    Notify("Voxer", "Default config created", 3)
end

task.spawn(function()
    while task.wait(AUTO_SAVE_INTERVAL) do pcall(SaveConfig, false) end
end)

selectTab("Combat")
local panelVisible = true
local TOGGLE_KEYS = { [Enum.KeyCode.Insert] = true, [Enum.KeyCode.RightShift] = true }
local function setPanelVisible(v)
    panelVisible = v
    G2L["2"].Visible = v
    G2L["2"].Active = v
end
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if recordingKeybind then return end
    if TOGGLE_KEYS[input.KeyCode] then setPanelVisible(not panelVisible) end
end)

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

do
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
end
