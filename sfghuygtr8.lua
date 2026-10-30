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
if not ok then warn("[SilentAim reload] " .. tostring(err)) end
]]):format(SELF_URL))
    end
end

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G

if game.GameId ~= 9534705677 then
    warn("[SilentAim] Not Sniper Arena (GameId=" .. tostring(game.GameId) .. "), idling.")
    return
end

local Config = {
    enabled      = true,

    aimParts     = { "Head", "UpperTorso", "HumanoidRootPart" },
    aimPart      = nil,

    aimBots      = false,
    teamCheck    = true,
    wallCheck    = true,
    maxDistance  = 1500,
    noDelay      = false,

    --// ---------- FOV ----------
    fovRadius        = 45,
    fovCircleRadius  = 45,
    fovEnabled       = true,
    fovVisible       = false,

    fovColor         = Color3.fromRGB(255, 0, 0),
    fovThickness     = 1.5,
    fovTransparency  = 0.7,

    -- Горячие клавиши.
    hotkeys          = true,
    keyRadiusDown    = Enum.KeyCode.LeftBracket,
    keyRadiusUp      = Enum.KeyCode.RightBracket,
    keyToggleCircle  = Enum.KeyCode.BackSlash,
    stepRadius       = 25,
}

local alive = true
local Stats = {
    installed    = false,
    error        = nil,
    lastTarget   = nil,
    lastPart     = nil,
    hooks        = 0,
    fovFiltered  = 0,
}
local silentHooks, silentDepth, silentChoice = {}, 0, nil

local EntityAPI
do
    local remote = RS:FindFirstChild("Remote")
    local module = remote and remote:FindFirstChild("EntityService")
    if module then
        local ok, value = pcall(require, module)
        if ok then EntityAPI = value end
    end
end

local function finite(n)
    return type(n) == "number" and n == n and math.abs(n) < 1e6
end

local function validPosition(p)
    return typeof(p) == "Vector3" and finite(p.X) and finite(p.Y) and finite(p.Z)
end

local function characterOf(unit)
    if typeof(unit) == "Instance" and unit:IsA("Model") then return unit end
    if EntityAPI and type(EntityAPI.GetEntity) == "function" then
        local ok, model = pcall(function()
            local e = EntityAPI.GetEntity(unit)
            return e and e:GetModel()
        end)
        if ok and typeof(model) == "Instance" and model:IsA("Model") then return model end
    end
    return unit.Character
end

local function healthOf(unit, model)
    local health  = unit:GetAttribute("Health")
    local maximum = unit:GetAttribute("MaxHealth")
    if EntityAPI and type(EntityAPI.GetHealth) == "function" then
        local ok, v = pcall(EntityAPI.GetHealth, unit)
        if ok and finite(v) then health = v end
    end
    local h = model and model:FindFirstChildOfClass("Humanoid")
    if type(health)  ~= "number" then health  = h and h.Health    or 0   end
    if type(maximum) ~= "number" then maximum = h and h.MaxHealth or 100 end
    return math.max(0, health), math.max(1, maximum)
end

local function sameRoom(other)
    local own    = Player:GetAttribute("GameRoom") or Player:GetAttribute("World")
    local theirs = other:GetAttribute("GameRoom") or other:GetAttribute("World")
    return not (own and theirs and own ~= theirs)
end

local function friendly(unit)
    if not Config.teamCheck then return false end
    if EntityAPI and type(EntityAPI.IsFriendly) == "function" then
        local ok, v = pcall(EntityAPI.IsFriendly, unit)
        if ok and type(v) == "boolean" then return v end
    end
    local a, b = Player:GetAttribute("Team"), unit:GetAttribute("Team")
    if a ~= nil and b ~= nil then return a == b end
    if typeof(unit) == "Instance" and not unit:IsA("Player") then return false end
    return Player.Team ~= nil and unit.Team ~= nil and Player.Team == unit.Team
end

local function targetUnits()
    local units = Players:GetPlayers()
    if not Config.aimBots then return units end

    local seen = {}
    local function add(model)
        if typeof(model) == "Instance" and model:IsA("Model")
            and not seen[model]
            and model:GetAttribute("_entity") == "HumanoidEntity"
            and not Players:GetPlayerFromCharacter(model) then
            seen[model] = true
            table.insert(units, model)
        end
    end

    if EntityAPI and EntityAPI.Entity and type(EntityAPI.Entity.GetAll) == "function" then
        local ok, reg = pcall(EntityAPI.Entity.GetAll)
        if ok and type(reg) == "table" then
            for _, e in pairs(reg._items or reg) do
                if type(e) == "table" then add(e.Instance) end
            end
        end
    end

    local worlds = workspace:FindFirstChild("World")
    if worlds then
        for _, w in ipairs(worlds:GetChildren()) do
            local ents = w:FindFirstChild("Entities")
            if ents then
                for _, m in ipairs(ents:GetChildren()) do add(m) end
            end
        end
    end
    return units
end

local function canSee(camera, model, position)
    if not Config.wallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = false
    local own = characterOf(Player)
    params.FilterDescendantsInstances = own and {own} or {}
    local hit = workspace:Raycast(camera.CFrame.Position, position - camera.CFrame.Position, params)
    if not hit or hit.Instance:IsDescendantOf(model) then return true end
    if EntityAPI and type(EntityAPI.FetchEntity) == "function"
        and type(EntityAPI.GetEntity) == "function" then
        local ok, same = pcall(function()
            local a = EntityAPI.FetchEntity(hit.Instance)
            local b = EntityAPI.GetEntity(model)
            return a ~= nil and a == b
        end)
        if ok and same then return true end
    end
    return false
end

--// ---------- Список частей ----------
local function partsList()
    if type(Config.aimParts) == "table" and #Config.aimParts > 0 then
        return Config.aimParts
    end
    if type(Config.aimPart) == "string" and Config.aimPart ~= "" then
        return { Config.aimPart }
    end
    return { "Head" }
end

local function candidateParts(unit)
    if unit == Player or not sameRoom(unit) then return nil end
    local model = characterOf(unit)
    if not model or not model:IsDescendantOf(workspace) then return nil end
    local hp = healthOf(unit, model)
    if hp <= 0 then return nil end
    if EntityAPI and type(EntityAPI.IsAlive) == "function" then
        local ok, v = pcall(EntityAPI.IsAlive, unit)
        if ok and v == false then return nil end
    end

    local collider = model:FindFirstChild("Collider")
    local out = {}
    local seenParts = {}

    for rank, name in ipairs(partsList()) do
        local lookup = (name == "UpperTorso") and "Body" or name
        local part = collider and collider:FindFirstChild(lookup, true)
            or model:FindFirstChild(name)

        if part and part:IsA("BasePart") and validPosition(part.Position) and not seenParts[part] then
            seenParts[part] = true
            table.insert(out, { part = part, position = part.Position, name = name, rank = rank })
        end
    end

    if #out == 0 then
        for _, name in ipairs({ "Head", "HumanoidRootPart" }) do
            local part = model:FindFirstChild(name)
            if part and part:IsA("BasePart") and validPosition(part.Position) then
                table.insert(out, { part = part, position = part.Position, name = name, rank = 999 })
                break
            end
        end
    end

    if #out == 0 then return nil end
    return model, out
end

--// ---------- Визуальный круг FOV ----------
local aimCircle
do
    local ok = pcall(function()
        aimCircle = Drawing.new("Circle")
        aimCircle.Filled   = false
        aimCircle.NumSides = 32
        aimCircle.Visible  = false
    end)
    if not ok then aimCircle = nil end
end

local function updateFovCircle()
    if not aimCircle then return end
    aimCircle.Radius       = Config.fovCircleRadius
    aimCircle.Color        = Config.fovColor
    aimCircle.Thickness    = Config.fovThickness
    aimCircle.Transparency = Config.fovTransparency
    aimCircle.Visible      = Config.fovVisible and Config.fovEnabled and alive
end
updateFovCircle()

RunService.RenderStepped:Connect(function()
    if aimCircle and aimCircle.Visible then
        local cam = workspace.CurrentCamera
        if cam then aimCircle.Position = cam.ViewportSize / 2 end
    end
end)

--// ---------- Горячие клавиши ----------
if Config.hotkeys then
    UIS.InputBegan:Connect(function(input, gp)
        if gp then return end

        if input.KeyCode == Config.keyRadiusDown then
            Config.fovRadius       = math.max(50, Config.fovRadius - Config.stepRadius)
            Config.fovCircleRadius = Config.fovRadius
            updateFovCircle()
            print("[SilentAim FOV] radius =", Config.fovRadius)
        elseif input.KeyCode == Config.keyRadiusUp then
            Config.fovRadius       = math.min(2000, Config.fovRadius + Config.stepRadius)
            Config.fovCircleRadius = Config.fovRadius
            updateFovCircle()
            print("[SilentAim FOV] radius =", Config.fovRadius)
        elseif input.KeyCode == Config.keyToggleCircle then
            Config.fovVisible = not Config.fovVisible
            updateFovCircle()
            print("[SilentAim FOV] circle visible =", Config.fovVisible)
        end
    end)
end

--// ---------- Выбор цели ----------
local function chooseTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local origin = camera.ViewportSize / 2
    local best = nil
    Stats.fovFiltered = 0

    for _, unit in ipairs(targetUnits()) do
        if not friendly(unit) then
            local model, parts = candidateParts(unit)
            if model then
                for _, entry in ipairs(parts) do
                    local pos = entry.position
                    if (pos - camera.CFrame.Position).Magnitude <= Config.maxDistance then
                        local point, onScreen = camera:WorldToViewportPoint(pos)
                        if onScreen and point.Z > 0 then
                            local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude

                            if not Config.fovEnabled or delta < Config.fovRadius then
                                local visible = canSee(camera, model, pos)

                                local better
                                if not best then
                                    better = true
                                elseif visible and not best.visible then
                                    better = true
                                elseif visible == best.visible then
                                    if delta < best.delta - 0.01 then
                                        better = true
                                    elseif math.abs(delta - best.delta) <= 0.01
                                        and entry.rank < best.rank then
                                        better = true
                                    end
                                end

                                if better then
                                    best = {
                                        unit = unit, part = entry.part,
                                        position = pos, name = entry.name,
                                        delta = delta, visible = visible, rank = entry.rank,
                                    }
                                end
                            else
                                Stats.fovFiltered += 1
                            end
                        end
                    end
                end
            end
        end
    end

    if best then
        return best.unit, best.position, best.part, best.name
    end
    return nil
end

--// ---------- Хуки ----------
local function clearSilent()
    local unhook = ENV.restorefunction
        or (type(restorefunction) == "function" and restorefunction)
    if type(unhook) == "function" then
        for _, fn in ipairs(silentHooks) do pcall(unhook, fn) end
    end
    table.clear(silentHooks)
    silentDepth, silentChoice = 0, nil
    Stats.installed = false
    Stats.hooks = 0
    if aimCircle then aimCircle.Visible = false end
end

local function installSilent()
    if #silentHooks > 0 then return true end
    local hook   = ENV.hookfunction
        or (type(hookfunction) == "function" and hookfunction)
    local unhook = ENV.restorefunction
        or (type(restorefunction) == "function" and restorefunction)
    local ups    = ENV.getupvalues
        or (debug and debug.getupvalues)
    if type(hook) ~= "function" or type(unhook) ~= "function" or type(ups) ~= "function" then
        Stats.error = "Executor lacks hookfunction/restorefunction/getupvalues"
        return false
    end

    local ok, err = pcall(function()
        local cameraAPI = require(RS.Client.CameraController)
        local shootable = require(RS.Client.CombatController.ClientComponent.ClientShootableComponent)
        local originFn  = cameraAPI.GetCombatOriginFn()

        local originState
        for _, v in pairs(ups(originFn)) do
            if type(v) == "table" and type(v.Get) == "function" and v.TempParams then
                originState = v
                break
            end
        end

        local targetingInternal
        for _, v in pairs(ups(cameraAPI.GetTargetingFn())) do
            if type(v) == "function" then
                targetingInternal = v
                break
            end
        end

        assert(originState and targetingInternal and type(shootable.LocalShoot) == "function",
               "Shot API unavailable")

        local originalOrigin
        originalOrigin = hook(originState.Get, function(...)
            local cf, at, params = originalOrigin(...)
            if alive and Config.enabled and silentDepth > 0 and silentChoice
                and typeof(cf) == "CFrame" then
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
            Stats.lastTarget = nil
            Stats.lastPart   = nil

            if alive and Config.enabled and not UIS:GetFocusedTextBox() then
                local unit, position, part, name = chooseTarget()
                if unit and part then
                    choice = { unit = unit, position = position, part = part, name = name }
                    Stats.lastTarget = (typeof(unit) == "Instance" and unit.Name) or tostring(unit)
                    Stats.lastPart   = name
                end
            end

            if choice and Config.noDelay
                and type(self._LastShootTime) == "number"
                and type(self.GetTimeNow) == "function"
                and self.Holder
                and type(self.Holder.GetCurrentAttackRate) == "function" then
                local ok2, remaining = pcall(function()
                    local rate = self.Holder:GetCurrentAttackRate("Shoot")
                    if type(rate) ~= "number" or rate <= 0 then return 0 end
                    return 1 / rate - (self:GetTimeNow() - self._LastShootTime)
                end)
                if ok2 and remaining > 0.01 then return nil end
            end

            local args = table.pack(...)
            if choice and (args[1] == nil or type(args[1]) == "table")
                and EntityAPI and type(EntityAPI.GetEntity) == "function" then
                local ok3, packet = pcall(function()
                    local entity = EntityAPI.GetEntity(choice.unit)
                    if not entity or not entity.Instance then return nil end
                    local pivot = entity:GetPivot(true)
                    if typeof(pivot) ~= "CFrame" then return nil end
                    local v = table.clone(args[1] or {})
                    v.Target         = entity.Instance
                    v.TargetPos      = pivot:PointToObjectSpace(choice.position)
                    v.TargetHeadshot = choice.name == "Head"
                    return v
                end)
                if ok3 and packet then
                    args[1] = packet
                    args.n  = math.max(args.n, 1)
                end
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

    if not ok then
        clearSilent()
        Stats.error = tostring(err)
        return false
    end
    Stats.installed = true
    Stats.hooks = #silentHooks
    updateFovCircle()
    return true
end

--// ---------- Публичный API ----------
local API = {
    Config = Config,
    Stats  = Stats,

    Start = function()
        Config.enabled = true
        local ok = installSilent()
        updateFovCircle()
        return ok
    end,

    Stop = function()
        Config.enabled = false
        clearSilent()
        if aimCircle then
            pcall(function() aimCircle:Remove() end)
            aimCircle = nil
        end
    end,

    Toggle = function(v)
        Config.enabled = (v ~= false)
        if Config.enabled then
            local ok = installSilent()
            updateFovCircle()
            return ok
        end
        clearSilent()
        return false
    end,

    SetAimParts = function(list)
        if type(list) == "table" and #list > 0 then
            Config.aimParts = list
        end
    end,

    SetAimPartsString = function(str)
        local out = {}
        for token in tostring(str):gmatch("[^,%s]+") do
            table.insert(out, token)
        end
        if #out > 0 then Config.aimParts = out end
        return out
    end,

    AddAimPart = function(name)
        for _, v in ipairs(Config.aimParts) do
            if v == name then return end
        end
        table.insert(Config.aimParts, name)
    end,

    RemoveAimPart = function(name)
        for i = #Config.aimParts, 1, -1 do
            if Config.aimParts[i] == name then
                table.remove(Config.aimParts, i)
            end
        end
    end,

    SetFovRadius = function(px)
        Config.fovRadius       = math.max(0, px)
        Config.fovCircleRadius = Config.fovRadius
        updateFovCircle()
    end,

    SetFovEnabled = function(v)
        Config.fovEnabled = (v ~= false)
        updateFovCircle()
    end,

    SetFovVisible = function(v)
        Config.fovVisible = (v ~= false)
        updateFovCircle()
    end,

    SetFovColor = function(c)
        if typeof(c) == "Color3" then
            Config.fovColor = c
            updateFovCircle()
        end
    end,

    UpdateFov = updateFovCircle,
}

if ENV.ATLAS_SILENT_AIM and ENV.ATLAS_SILENT_AIM.Stop then
    pcall(ENV.ATLAS_SILENT_AIM.Stop)
end

installSilent()

do
    local CoreGui      = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")

    local existing = CoreGui:FindFirstChild("notif")
    if existing then existing:Destroy() end

    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "notif"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.DisplayOrder = 100
    notifGui.Parent = CoreGui

    -- Main
    local main = Instance.new("CanvasGroup")
    main.Name = "Main"
    main.BorderSizePixel = 0
    main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    main.BackgroundTransparency = 0.2
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Size = UDim2.new(0.216, 0, 0.091, 0)
    main.Position = UDim2.new(1.11, 0, 0.91, 0)
    main.BorderColor3 = Color3.fromRGB(0, 0, 0)
    main.Parent = notifGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.TextWrapped = true
    title.BorderSizePixel = 0
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextScaled = true
    title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.AnchorPoint = Vector2.new(0.5, 0.5)
    title.Size = UDim2.new(0.17742, 0, 0.23911, 0)
    title.Position = UDim2.new(0.20728, 0, 0.30118, 0)
    title.BorderColor3 = Color3.fromRGB(0, 0, 0)
    title.Text = "Voxer"
    title.Parent = main

    -- Disc
    local disc = Instance.new("TextLabel")
    disc.Name = "Disc"
    disc.TextWrapped = true
    disc.BorderSizePixel = 0
    disc.TextSize = 14
    disc.TextXAlignment = Enum.TextXAlignment.Left
    disc.TextScaled = true
    disc.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    disc.BackgroundTransparency = 1
    disc.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    disc.TextColor3 = Color3.fromRGB(255, 255, 255)
    disc.AnchorPoint = Vector2.new(0.5, 0.5)
    disc.Size = UDim2.new(0.82258, 0, 0.2529, 0)
    disc.Position = UDim2.new(0.53286, 0, 0.6529, 0)
    disc.BorderColor3 = Color3.fromRGB(0, 0, 0)
    disc.Text = "Succesful loaded"
    disc.Parent = main

    -- ProgressBar
    local bar = Instance.new("Frame")
    bar.Name = "ProgressBar"
    bar.BorderSizePixel = 0
    bar.BackgroundColor3 = Color3.fromRGB(255, 171, 0)
    bar.Size = UDim2.new(1, 0, 0.051, 0)
    bar.Position = UDim2.new(0, 0, 0.948, 0)
    bar.BorderColor3 = Color3.fromRGB(0, 0, 0)
    bar.Parent = main

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0.5, 0)
    barCorner.Parent = bar

    local shadow = Instance.new("UIShadow")
    shadow.Parent = main

    -- Анимация: wait(1) -> выезд 0.1s -> бар 3s -> уезд 0.1s
    local tweenInfo  = TweenInfo.new(.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
    local tweenInfo2 = TweenInfo.new(3,  Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
    local HIDDEN_POS  = UDim2.new(1.11, 0, 0.91, 0)
    local VISIBLE_POS = UDim2.new(0.892, 0, 0.91, 0)

    task.spawn(function()
        task.wait(1)
        TweenService:Create(main, tweenInfo, { Position = VISIBLE_POS }):Play()
        task.wait(.1)
        TweenService:Create(bar, tweenInfo2, { Size = UDim2.new(0, 0, 0.051, 0) }):Play()
        task.wait(3)
        local out = TweenService:Create(main, tweenInfo, { Position = HIDDEN_POS })
        out:Play()
        out.Completed:Once(function()
            notifGui:Destroy()
        end)
    end)
end

ENV.ATLAS_SILENT_AIM = API
return API
