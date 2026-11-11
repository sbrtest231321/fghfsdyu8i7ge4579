repeat task.wait() until game:IsLoaded()

do
    local SELF_URL = "https://raw.githubusercontent.com/sbrtest231321/fghfsdyu8i7ge4579/refs/heads/main/sfghuygtr8.lua"
    if type(queueonteleport) == "function" then
        queueonteleport(([[
repeat task.wait() until game:IsLoaded()
local ok, err = pcall(function()
    local src = game:HttpGet(%q, true)
    local fn, lerr = loadstring(src, "VoxerMain")
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

local UI_URL = "https://raw.githubusercontent.com/sbrtest231321/fghfsdyu8i7ge4579/refs/heads/main/ui.lua"
local UI = loadstring(game:HttpGet(UI_URL, true))()

local G2L = UI.G2L
local tabFrames = UI.tabFrames
local Notify = UI.Notify
local registerState = UI.registerState
local SaveConfig = UI.SaveConfig
local LoadConfig = UI.LoadConfig
local ResetConfig = UI.ResetConfig
local ensureConfigFolder = UI.ensureConfigFolder
local buildModule = UI.buildModule
local makeToggleRow = UI.makeToggleRow
local makeSliderRow = UI.makeSliderRow
local makeDropdownRow = UI.makeDropdownRow
local makeButtonRow = UI.makeButtonRow
local selectTab = UI.selectTab
local CONFIG_FILE = UI.CONFIG_FILE
local AUTO_SAVE_INTERVAL = UI.AUTO_SAVE_INTERVAL

-- ========== SHARED HELPERS ==========
local TeamCheck, WallCheck, EntityAPI, getUnitModel, getAllTargets, aaCharacterOf, aaHealthOf, aaSameRoom, aaCandidate =
(function()
    local EntityAPI
    do
        local remote = ReplicatedStorage:FindFirstChild("Remote")
        local module = remote and remote:FindFirstChild("EntityService")
        if module then
            local ok, value = pcall(require, module)
            if ok then EntityAPI = value end
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
    local lastFilterChar = nil
    local function ensureWallFilter()
        local myChar = LP.Character
        if myChar and lastFilterChar ~= myChar then
            lastFilterChar = myChar
            wallCheckParams.FilterDescendantsInstances = {myChar}
        end
    end
    ensureWallFilter()
    LP.CharacterAdded:Connect(function() task.wait(0.2); lastFilterChar = nil; ensureWallFilter() end)
    function WallCheck.CanSee(camera, model, position)
        if not model or not position then return false end
        ensureWallFilter()
        local myChar = LP.Character
        local head = myChar and myChar:FindFirstChild("Head")
        if not head then return false end
        local origin = head.Position
        local dir = position - origin
        if dir.Magnitude < 0.01 then return true end
        local hit = workspace:Raycast(origin, dir.Unit * 1000, wallCheckParams)
        if not hit then return true end
        return hit.Instance:IsDescendantOf(model) or hit.Instance == model
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
            if p ~= LP then table.insert(units, p); seen[p] = true end
        end
        if not includeBots then return units end
        local function add(m)
            if typeof(m) == "Instance" and m:IsA("Model") and not seen[m]
                and m:GetAttribute("_entity") == "HumanoidEntity"
                and not Players:GetPlayerFromCharacter(m) then
                seen[m] = true; table.insert(units, m)
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
    local function aaFinite(n) return type(n) == "number" and n == n and math.abs(n) < 1e6 end
    local function aaValidPos(p) return typeof(p) == "Vector3" and aaFinite(p.X) and aaFinite(p.Y) and aaFinite(p.Z) end
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
    local function aaCandidate(unit, req)
        req = req or "Head"
        if unit == LP or not aaSameRoom(unit) then return nil end
        local model = aaCharacterOf(unit)
        if not model or not model:IsDescendantOf(workspace) then return nil end
        if aaHealthOf(unit, model) <= 0 then return nil end
        if EntityAPI and type(EntityAPI.IsAlive) == "function" then
            local ok, v = pcall(EntityAPI.IsAlive, unit)
            if ok and v == false then return nil end
        end
        local collider = model:FindFirstChild("Collider")
        local part = collider and collider:FindFirstChild(req == "UpperTorso" and "Body" or req, true)
            or model:FindFirstChild(req) or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
        if not part or not part:IsA("BasePart") or not aaValidPos(part.Position) then return nil end
        return model, part
    end
    return TeamCheck, WallCheck, EntityAPI, getUnitModel, getAllTargets, aaCharacterOf, aaHealthOf, aaSameRoom, aaCandidate
end)()

-- ========== SILENT AIM ==========
local SilentAim = (function()
    local self = { API = nil, Enabled = false, _installed = false }
    local Config = {
        enabled = false,
        aimParts = { "Head", "UpperTorso", "HumanoidRootPart" },
        aimPart = nil, aimBots = true, teamCheck = true, wallCheck = true,
        maxDistance = 1500, noDelay = false,
        fovRadius = 120, fovCircleRadius = 120, fovEnabled = true, fovVisible = true,
        fovColor = Color3.fromRGB(255, 0, 0), fovThickness = 1.5, fovTransparency = 0.7,
        tracersEnabled = true, forcedTarget = nil,
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
                aimCircle.Filled = false; aimCircle.NumSides = 32; aimCircle.Visible = false
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
        if Config.forcedTarget then
            local ft = Config.forcedTarget
            Config.forcedTarget = nil
            if (os.clock() - ft.time) < 0.5 then
                local model = characterOf(ft.unit)
                if model and model:IsDescendantOf(workspace) and healthOf(ft.unit, model) > 0
                   and ft.part and ft.part:IsDescendantOf(workspace) then
                    return ft.unit, ft.part.Position, ft.part, ft.name
                end
            end
        end
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
    local TracerFolder = Instance.new("Folder")
    TracerFolder.Name = "VoxerTracers"
    TracerFolder.Parent = workspace
    local function spawnTracer(fromPos, toPos)
        local dir = toPos - fromPos
        local dist = dir.Magnitude
        if dist < 0.1 then return end
        local mid = fromPos + dir * 0.5
        local part = Instance.new("Part")
        part.Name = "VoxerTracer"
        part.Anchored = true
        part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
        part.CastShadow = false
        part.Material = Enum.Material.Neon
        part.Color = Color3.fromRGB(255, 255, 255)
        part.Transparency = 0
        part.Size = Vector3.new(0.2, 0.2, dist)
        part.CFrame = CFrame.lookAt(mid, toPos)
        part.Parent = TracerFolder
        task.delay(0.5, function()
            if not part or not part.Parent then return end
            local tween = TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = Vector3.new(0, 0, dist), Transparency = 1,
            })
            tween:Play()
            tween.Completed:Once(function() if part then part:Destroy() end end)
        end)
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
                if choice and Config.tracersEnabled and result[2] then
                    local myChar = LP.Character
                    local head = myChar and myChar:FindFirstChild("Head")
                    if head then spawnTracer(head.Position - Vector3.new(0, 0.5,0), choice.position) end
                end
                return table.unpack(result, 2, result.n)
            end)
            table.insert(silentHooks, shootable.LocalShoot)
        end)
        if not ok then clearSilent(); Stats.error = tostring(err); return false end
        Stats.installed = true; Stats.hooks = #silentHooks; updateFovCircle()
        return true
    end
    self.API = {
        Config = Config, Stats = Stats,
        Start = function() Config.enabled = true; local ok = installSilent(); updateFovCircle(); return ok end,
        Stop = function() Config.enabled = false; clearSilent() end,
        SetAimParts = function(list) if type(list) == "table" and #list > 0 then Config.aimParts = list end end,
        SetFovRadius = function(px) Config.fovRadius = math.max(0, px); Config.fovCircleRadius = Config.fovRadius; updateFovCircle() end,
        SetFovVisible = function(v) Config.fovVisible = (v ~= false); updateFovCircle() end,
        SetForcedTarget = function(unit, part, name)
            if unit and part then
                Config.forcedTarget = { unit = unit, part = part, name = name or part.Name, time = os.clock() }
            else
                Config.forcedTarget = nil
            end
        end,
    }
    pcall(installSilent)
    return self
end)()

-- ========== TRIGGER BOT ==========
local TriggerBot = (function()
    local self = { Enabled = false, VisibleCheck = false, TeamCheck = false, MaxDistance = 500, ClickCooldown = 0.1, _lastClick = 0, _conn = nil, _raycastParams = nil }
    local function buildRP()
        local p = RaycastParams.new()
        p.FilterType = Enum.RaycastFilterType.Exclude
        if LP.Character then p.FilterDescendantsInstances = {LP.Character} end
        return p
    end
    self._raycastParams = buildRP()
    LP.CharacterAdded:Connect(function() task.wait(0.2); self._raycastParams = buildRP() end)
    local function getUnderCursor()
        local p = self._raycastParams
        if not p then return nil end
        local mp = UIS:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mp.X, mp.Y)
        local res = workspace:Raycast(ray.Origin, ray.Direction * self.MaxDistance, p)
        if not res then return nil end
        local hitChar = res.Instance:FindFirstAncestorOfClass("Model")
        if not hitChar then return nil end
        local hp = Players:GetPlayerFromCharacter(hitChar)
        if not hp or hp == LP then return nil end
        local hum = hitChar:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return nil end
        if self.TeamCheck and TeamCheck.IsFriendlyPlayer(hp) then return nil end
        if self.VisibleCheck and not WallCheck.CanSee(Camera, hitChar, res.Position) then return nil end
        return hp, hitChar
    end
    local function click()
            task.wait(0.05)
        local m1 = getgenv().mouse1click or (type(mouse1click) == "function" and mouse1click)
        if type(m1) == "function" then pcall(m1); return true end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local mp = UIS:GetMouseLocation()
            pcall(function()
                vim:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 1, false)
                task.wait(0.02)
                vim:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 1, false)
            end)
            return true
        end
        return false
    end
    function self.stop() if self._conn then self._conn:Disconnect(); self._conn = nil end end
    function self.start()
        self.stop()
        self._conn = RunService.Heartbeat:Connect(function()
            if not self.Enabled or UIS:GetFocusedTextBox() then return end
            if not getUnderCursor() then return end
            local now = os.clock()
            if now - self._lastClick < self.ClickCooldown then return end
            self._lastClick = now
            click()
        end)
    end
    return self
end)()

-- ========== ESP ==========
local ESP = (function()
    local self = { Enabled = false, ShowBox = false, ShowName = false, ShowDistance = false, MaxDistance = 1000,
        BoxColor = Color3.fromRGB(255, 0, 0), BoxThickness = 2,
        TextColor = Color3.fromRGB(255, 255, 255), TextSize = 16, TeamCheck = false }
    local folder = Instance.new("Folder"); folder.Parent = CoreGui
    local boxes, labels = {}, {}
    local function createBox(model)
        if not model or boxes[model] then return end
        local b = {Top=Drawing.new("Line"),Bottom=Drawing.new("Line"),Left=Drawing.new("Line"),Right=Drawing.new("Line")}
        for _, l in pairs(b) do l.Visible=false; l.Color=self.BoxColor; l.Thickness=self.BoxThickness end
        boxes[model] = b
    end
    local function createLabel(model)
        if not model or labels[model] then return end
        local bb = Instance.new("BillboardGui")
        bb.Name = "VoxerLabel"; bb.Parent = folder
        bb.ResetOnSpawn = false; bb.AlwaysOnTop = true
        bb.Size = UDim2.new(0,200,0,50)
        bb.StudsOffsetWorldSpace = Vector3.new(0,3,0)
        bb.Enabled = false
        local nl = Instance.new("TextLabel", bb)
        nl.BackgroundTransparency = 1; nl.Size = UDim2.new(1,0,0.6,0)
        nl.Font = Enum.Font.GothamBold; nl.TextSize = self.TextSize
        nl.TextColor3 = self.TextColor; nl.TextStrokeTransparency = 0
        local dl = Instance.new("TextLabel", bb)
        dl.BackgroundTransparency = 1; dl.Size = UDim2.new(1,0,0.4,0)
        dl.Position = UDim2.new(0,0,0.6,0)
        dl.Font = Enum.Font.Gotham; dl.TextSize = self.TextSize - 2
        dl.TextColor3 = Color3.fromRGB(200,200,200); dl.TextStrokeTransparency = 0
        labels[model] = {Billboard=bb, NameLabel=nl, DistanceLabel=dl}
    end
    local function removeModel(model)
        if boxes[model] then for _,l in pairs(boxes[model]) do l:Remove() end; boxes[model]=nil end
        if labels[model] then labels[model].Billboard:Destroy(); labels[model]=nil end
    end
    local function updateUnit(unit)
        local model = getUnitModel(unit)
        if not model then return end
        if not boxes[model] then createBox(model) end
        if not labels[model] then createLabel(model) end
        local isFriendly = false
        if typeof(unit) == "Instance" and unit:IsA("Player") and self.TeamCheck and TeamCheck.IsFriendlyPlayer(unit) then
            isFriendly = true
        end
        local hrp = model:FindFirstChild("HumanoidRootPart")
        local hum = model:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            for _,l in pairs(boxes[model]) do l.Visible=false end
            labels[model].Billboard.Enabled = false
            return
        end
        local d = (hrp.Position - Camera.CFrame.Position).Magnitude
        local b = boxes[model]
        if not self.Enabled or not self.ShowBox or isFriendly or d > self.MaxDistance then
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
                local h = bt.Y - t.Y; local w = h * 0.65
                local lX, rX = t.X - w/2, t.X + w/2
                b.Top.From = Vector2.new(lX, t.Y); b.Top.To = Vector2.new(rX, t.Y); b.Top.Visible = true
                b.Bottom.From = Vector2.new(lX, bt.Y); b.Bottom.To = Vector2.new(rX, bt.Y); b.Bottom.Visible = true
                b.Left.From = Vector2.new(lX, t.Y); b.Left.To = Vector2.new(lX, bt.Y); b.Left.Visible = true
                b.Right.From = Vector2.new(rX, t.Y); b.Right.To = Vector2.new(rX, bt.Y); b.Right.Visible = true
            end
        end
        local dl = labels[model]
        if not self.Enabled or isFriendly or (not self.ShowName and not self.ShowDistance) or d > self.MaxDistance then
            dl.Billboard.Enabled = false
        else
            dl.Billboard.Adornee = hrp
            dl.Billboard.Enabled = true
            if self.ShowName then
                dl.NameLabel.Visible = true
                dl.NameLabel.Text = typeof(unit) == "Instance" and unit:IsA("Player") and unit.DisplayName or model.Name
                dl.NameLabel.TextColor3 = self.TextColor
                dl.NameLabel.TextSize = self.TextSize
            else dl.NameLabel.Visible = false end
            if self.ShowDistance then
                dl.DistanceLabel.Visible = true
                dl.DistanceLabel.Text = string.format("[%d]", math.floor(d))
                dl.DistanceLabel.TextSize = math.max(self.TextSize - 2, 8)
            else dl.DistanceLabel.Visible = false end
        end
    end
    RunService.RenderStepped:Connect(function()
        local units = getAllTargets()
        local active = {}
        for _, unit in ipairs(units) do
            local model = getUnitModel(unit)
            if model then active[model] = true; updateUnit(unit) end
        end
        for model, _ in pairs(boxes) do if not active[model] then removeModel(model) end end
    end)
    function self.SetEnabled(v)
        self.Enabled = v
        if not v then
            for _,b in pairs(boxes) do for _,l in pairs(b) do l.Visible=false end end
            for _,d in pairs(labels) do d.Billboard.Enabled=false end
        end
    end
    return self
end)()

-- ========== CHAMS ==========
local Chams = (function()
    local self = { Enabled = false, AlwaysOnTop = false, Outline = false,
        FillColor = Color3.fromRGB(255, 0, 0), OutlineColor = Color3.fromRGB(255, 255, 255),
        Transparency = 0.5, TeamCheck = false }
    local folder = Instance.new("Folder"); folder.Parent = CoreGui
    local highlights = {}
    local function apply(hl)
        hl.FillColor = self.FillColor
        hl.OutlineColor = self.OutlineColor
        hl.FillTransparency = self.Transparency
        hl.OutlineTransparency = self.Outline and 0 or 1
        hl.DepthMode = self.AlwaysOnTop and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    end
    local function create(model)
        if not model or highlights[model] then return end
        local hl = Instance.new("Highlight")
        hl.Parent = folder; hl.Enabled = false
        apply(hl)
        highlights[model] = hl
    end
    local function remove(model)
        if highlights[model] then highlights[model]:Destroy(); highlights[model]=nil end
    end
    local function updateUnit(unit)
        local model = getUnitModel(unit)
        if not model then return end
        if not highlights[model] then create(model) end
        local hl = highlights[model]
        local isFriendly = false
        if typeof(unit) == "Instance" and unit:IsA("Player") and self.TeamCheck and TeamCheck.IsFriendlyPlayer(unit) then
            isFriendly = true
        end
        if not self.Enabled or isFriendly then hl.Enabled = false; return end
        local hum = model:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then hl.Enabled = false; return end
        hl.Adornee = model; hl.Enabled = true; apply(hl)
    end
    RunService.RenderStepped:Connect(function()
        local units = getAllTargets()
        local active = {}
        for _, unit in ipairs(units) do
            local model = getUnitModel(unit)
            if model then active[model] = true; updateUnit(unit) end
        end
        for model, _ in pairs(highlights) do if not active[model] then remove(model) end end
    end)
    function self.SetEnabled(v)
        self.Enabled = v
        if not v then for _,hl in pairs(highlights) do hl.Enabled=false end end
    end
    return self
end)()

-- ========== SPEED ==========
local Speed = (function()
    local self = { Enabled = false, Amount = 50, BypassMethod = "None", _conn = nil, _isPulsing = false, _smoothMultiplier = 0 }
    local function kp(vk)
        local f = getgenv().keypress or (type(keypress) == "function" and keypress)
        if type(f) == "function" then pcall(f, vk); return end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local key = (vk == 0x11) and Enum.KeyCode.LeftControl or Enum.KeyCode.LeftControl
            pcall(function() vim:SendKeyEvent(true, key, false, game) end)
        end
    end
    local function kr(vk)
        local f = getgenv().keyrelease or (type(keyrelease) == "function" and keyrelease)
        if type(f) == "function" then pcall(f, vk); return end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local key = (vk == 0x11) and Enum.KeyCode.LeftControl or Enum.KeyCode.LeftControl
            pcall(function() vim:SendKeyEvent(false, key, false, game) end)
        end
    end
    function self.stop()
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        self._isPulsing = false; self._smoothMultiplier = 0
        kr(0x11)
    end
    function self.start()
        self.stop()
        self._conn = RunService.Heartbeat:Connect(function(dt)
            if not self.Enabled then return end
            local c = LP.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not hrp or not h then return end
            local isMoving = h.MoveDirection.Magnitude > 0.01
            if self.BypassMethod == "Jump" and isMoving then h.Jump = true end
            if self.BypassMethod == "Smooth" then
                if isMoving then self._smoothMultiplier = math.min(self._smoothMultiplier + dt * 1.5, 1)
                else self._smoothMultiplier = math.max(self._smoothMultiplier - dt * 3, 0) end
            else self._smoothMultiplier = 1 end
            local hv = Vector3.zero
            if isMoving then hv = h.MoveDirection * (self.Amount / 50) * 60 * self._smoothMultiplier end
            if self.BypassMethod == "Pulse" and self._isPulsing and isMoving then hv = Vector3.zero end
            hrp.AssemblyLinearVelocity = Vector3.new(hv.X, hrp.AssemblyLinearVelocity.Y, hv.Z)
        end)
        task.spawn(function()
            local lastSlide, lastPulse = 0, 0
            while self.Enabled do
                local now = os.clock()
                local char = LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local isMoving = hum and hum.MoveDirection.Magnitude > 0.01
                if isMoving then
                    if self.BypassMethod == "Slide" then
                        if now - lastSlide >= 1.5 then
                            lastSlide = now; kp(0x11); task.wait(0.5); kr(0x11)
                        else task.wait(0.1) end
                    elseif self.BypassMethod == "Pulse" then
                        if now - lastPulse >= 1 then
                            lastPulse = now; self._isPulsing = true; task.wait(.3); self._isPulsing = false
                        else task.wait(0.1) end
                    else task.wait(0.1) end
                else
                    lastSlide = now; lastPulse = now; self._isPulsing = false
                    if self.BypassMethod == "Slide" then kr(0x11) end
                    task.wait(0.1)
                end
            end
            self._isPulsing = false; kr(0x11)
        end)
    end
    return self
end)()

-- ========== FLY ==========
local Fly = (function()
    local self = { Enabled = false, Speed = 50, VerticalSpeed = 50, _conn = nil }
    function self.stop() if self._conn then self._conn:Disconnect(); self._conn = nil end end
    function self.start()
        self.stop()
        self._conn = RunService.Heartbeat:Connect(function(dt)
            if not self.Enabled then return end
            local c = LP.Character; if not c then return end
            local hrp = c:FindFirstChild("HumanoidRootPart")
            local h = c:FindFirstChildOfClass("Humanoid")
            if not hrp or not h then return end
            local hv = Vector3.zero
            if h.MoveDirection.Magnitude > 0 then hv = h.MoveDirection * (self.Speed/50) * 60 end
            local vert = 0
            if UIS:IsKeyDown(Enum.KeyCode.E) then vert = vert + 1 end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then vert = vert + 1 end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vert = vert - 1 end
            if vert ~= 0 then
                local vs = vert * (self.VerticalSpeed/50) * (dt*60)
                hrp.CFrame = hrp.CFrame + Vector3.new(0, vs, 0)
            end
            hrp.AssemblyLinearVelocity = Vector3.new(hv.X, 0, hv.Z)
        end)
    end
    return self
end)()

-- ========== AIM ASSIST ==========
local AimAssist = (function()
    local self = { Enabled = false, Hold = true, Radius = 220, Smooth = 3, AimPart = "Head", WallCheck = true,
        TeamCheck = false, MaxDistance = 1500, AimBots = true, ShowFOV = false, _running = false }
    local ENV = getgenv()
    local mouseMove = ENV.mousemoverel or (type(mousemoverel) == "function" and mousemoverel)
    local pointerAvail = type(mouseMove) == "function"
    local overlay
    do
        local ok = pcall(function()
            local g = Instance.new("ScreenGui")
            g.Name = "VoxerAdmin_AA"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 49
            g.Parent = CoreGui
            overlay = g
        end)
        if not ok or not overlay then
            local g = Instance.new("ScreenGui")
            g.Name = "VoxerAdmin_AA"; g.ResetOnSpawn = false; g.IgnoreGuiInset = true; g.DisplayOrder = 49
            g.Parent = LP:WaitForChild("PlayerGui")
            overlay = g
        end
    end
    local fovCircle = Instance.new("Frame")
    fovCircle.AnchorPoint = Vector2.new(0.5, 0.5); fovCircle.BackgroundTransparency = 1
    fovCircle.Visible = false; fovCircle.Parent = overlay
    Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(0.5, 0)
    local fovStroke = Instance.new("UIStroke", fovCircle)
    fovStroke.Color = Color3.fromRGB(0, 255, 100); fovStroke.Thickness = 1.5; fovStroke.Transparency = 0.15
    local function friendly(unit)
        if not self.TeamCheck then return false end
        return TeamCheck.IsFriendlyUnit(unit)
    end
    local function aimOrigin(camera)
        if (UIS.TouchEnabled and not UIS.MouseEnabled) or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
            return camera.ViewportSize / 2
        end
        return UIS:GetMouseLocation() - GuiService:GetGuiInset()
    end
    local function chooseTarget()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local origin = aimOrigin(camera)
        local best, bestPos, bestPart, score = nil, nil, nil, self.Radius
        local bestVisible = false
        for _, unit in ipairs(getAllTargets(self.AimBots)) do
            if not friendly(unit) then
                local model, part = aaCandidate(unit, self.AimPart)
                if model and part then
                    local position = part.Position
                    local point, visible = camera:WorldToViewportPoint(position)
                    if visible and point.Z > 0 and (position - camera.CFrame.Position).Magnitude <= self.MaxDistance then
                        local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude
                        if delta < self.Radius then
                            local vS = not self.WallCheck or WallCheck.CanSee(camera, model, position)
                            local allowed = not self.WallCheck or vS
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
    local function alpha(dt) return 1 - math.exp(-180 / math.max(1, self.Smooth) * math.clamp(dt, 0, 0.05)) end
    local function aimAt(position, dt)
        local camera = workspace.CurrentCamera
        if not camera then return end
        local a = alpha(dt)
        if pointerAvail then
            local point = camera:WorldToViewportPoint(position)
            if not point.Z or point.Z <= 0 then return end
            local origin = aimOrigin(camera)
            local delta = (Vector2.new(point.X, point.Y) - origin) * a
            mouseMove(math.clamp(delta.X, -160, 160), math.clamp(delta.Y, -160, 160))
        else
            local cf = camera.CFrame
            camera.CFrame = cf:Lerp(CFrame.lookAt(cf.Position, position), a)
        end
    end
    RunService.RenderStepped:Connect(function(dt)
        local camera = workspace.CurrentCamera
        if not camera then return end
        fovCircle.Visible = self.Enabled and self.ShowFOV
        if fovCircle.Visible then
            local origin = aimOrigin(camera)
            fovCircle.Position = UDim2.fromOffset(origin.X, origin.Y)
            local diameter = self.Radius * 2
            if fovCircle.Size.X.Offset ~= diameter then fovCircle.Size = UDim2.fromOffset(diameter, diameter) end
        end
        if not self.Enabled then self._running = false; return end
        if UIS:GetFocusedTextBox() then return end
        local touch = UIS.TouchEnabled and not UIS.MouseEnabled
        local engaged
        if touch then engaged = not self.Hold or self._running
        else engaged = not self.Hold or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
        if not engaged then self._running = false; return end
        self._running = true
        local lm = aaCharacterOf(LP)
        if aaHealthOf(LP, lm) <= 0 then return end
        local target, position = chooseTarget()
        if not target or not position then return end
        aimAt(position, dt)
    end)
    return self
end)()

local RageBot = (function()
    local self = { Enabled = false, LimitToFOV = false, QuickScope = false, TeamCheck = false, MaxDistance = 500,
        FOVRadius = 220, WallCheck = true, ClickCooldown = 0.5, _lastClick = 0 }
    local function qsScopeDown()
        if type(getgenv().mouse2press) == "function" then pcall(getgenv().mouse2press); return end
        if type(mouse2press) == "function" then pcall(mouse2press); return end
        local kp = getgenv().keypress or (type(keypress) == "function" and keypress)
        if type(kp) == "function" then pcall(kp, 0x02); return end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local mp = UIS:GetMouseLocation()
            pcall(function() vim:SendMouseButtonEvent(mp.X, mp.Y, 2, true, game, 1, false) end)
        end
    end
    local function qsScopeUp()
        if type(getgenv().mouse2release) == "function" then pcall(getgenv().mouse2release); return end
        if type(mouse2release) == "function" then pcall(mouse2release); return end
        local kr = getgenv().keyrelease or (type(keyrelease) == "function" and keyrelease)
        if type(kr) == "function" then pcall(kr, 0x02); return end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local mp = UIS:GetMouseLocation()
            pcall(function() vim:SendMouseButtonEvent(mp.X, mp.Y, 2, false, game, 1, false) end)
        end
    end
    local function click()
        local m1 = getgenv().mouse1click or (type(mouse1click) == "function" and mouse1click)
        if type(m1) == "function" then pcall(m1); return true end
        local vim = game:GetService("VirtualInputManager")
        if vim then
            local mp = UIS:GetMouseLocation()
            pcall(function()
                vim:SendMouseButtonEvent(mp.X, mp.Y, 0, true, game, 1, false)
                task.wait(0.02)
                vim:SendMouseButtonEvent(mp.X, mp.Y, 0, false, game, 1, false)
            end)
            return true
        end
        return false
    end
    RunService.Heartbeat:Connect(function()
        if SilentAim.API and SilentAim.API.Config then
            self.FOVRadius = SilentAim.API.Config.fovRadius
        end
    end)
    task.spawn(function()
        while task.wait(0.01) do
            if self.Enabled and not UIS:GetFocusedTextBox() then
                local camera = workspace.CurrentCamera
                if camera then
                    local origin
                    if (UIS.TouchEnabled and not UIS.MouseEnabled) or UIS.MouseBehavior == Enum.MouseBehavior.LockCenter then
                        origin = camera.ViewportSize / 2
                    else
                        origin = UIS:GetMouseLocation() - GuiService:GetGuiInset()
                    end
                    local bestUnit, bestPart = nil, nil
                    local bestDist = self.LimitToFOV and self.FOVRadius or math.huge
                    local maxDist = self.MaxDistance
                    for _, unit in ipairs(getAllTargets(true)) do
                        if not (self.TeamCheck and TeamCheck.IsFriendlyUnit(unit)) then
                            local model, part = aaCandidate(unit, "Head")
                            if model and part then
                                local pos = part.Position
                                local d3 = (pos - camera.CFrame.Position).Magnitude
                                if d3 <= maxDist then
                                    local point, onScreen = camera:WorldToViewportPoint(pos)
                                    if onScreen and point.Z > 0 then
                                        local delta = (Vector2.new(point.X, point.Y) - origin).Magnitude
                                        if delta < bestDist then
                                            if not self.WallCheck or WallCheck.CanSee(camera, model, pos) then
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
                        if now - self._lastClick >= self.ClickCooldown then
                            self._lastClick = now
                            if SilentAim.API then
                                SilentAim.API.SetForcedTarget(bestUnit, bestPart, bestPart.Name)
                            end
                            if self.QuickScope then
                                qsScopeDown()
                                task.wait(0.15)
                                click()
                                task.wait(0.1)
                                qsScopeUp()
                            else
                                click()
                            end
                        end
                    end
                end
            end
        end
    end)
    return self
end)()

local LongNeck = (function()
    local self = { Enabled = false, LiftAmount = 10, _conn = nil, _holding = false, _targetY = nil, _baseY = nil }
    function self.stop()
        self._holding = false
        if self._conn then self._conn:Disconnect(); self._conn = nil end
    end
    function self.start()
        if self._holding then return end
        local c = LP.Character; if not c then return end
        local r = c:FindFirstChild("HumanoidRootPart"); if not r then return end
        self._baseY = r.Position.Y
        self._targetY = self._baseY + self.LiftAmount
        self._holding = true
        self._conn = RunService.Heartbeat:Connect(function()
            if not self._holding then return end
            local ch = LP.Character
            if not ch then self.stop() return end
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if not hrp then self.stop() return end
            local p = hrp.Position
            hrp.CFrame = CFrame.new(p.X, self._targetY, p.Z) * (hrp.CFrame - hrp.Position)
        end)
    end
    return self
end)()

local ThirdPerson = (function()
    local self = { Enabled = false, _conn = nil, _charConn = nil, _charAddedConn = nil, _saved = nil }
    local function applyTransparency(model)
        if not model then return end
        for _, obj in ipairs(model:GetDescendants()) do
            if obj:IsA("MeshPart") and obj.Name ~= "Head" and obj.Name ~= "HumanoidRootPart" then
                obj.Transparency = 0
            end
        end
    end
    local function watchCharacter(character)
        applyTransparency(character)
        local conn = character.DescendantAdded:Connect(function(inst)
            if inst:IsA("MeshPart") and inst.Name ~= "Head" and inst.Name ~= "HumanoidRootPart" then
                task.wait()
                inst.Transparency = 0
            end
        end)
        return conn
    end
    function self.start()
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
        if self._charAddedConn then self._charAddedConn:Disconnect(); self._charAddedConn = nil end
        self.Enabled = true
        if not self._saved then
            self._saved = {
                CameraMode = LP.CameraMode,
                MinZoom = LP.CameraMinZoomDistance,
                MaxZoom = LP.CameraMaxZoomDistance,
            }
        end
        LP.CameraMode = Enum.CameraMode.Classic
        LP.CameraMinZoomDistance = 12.5
        LP.CameraMaxZoomDistance = 12.5
        if LP.Character then self._charConn = watchCharacter(LP.Character) end
        self._charAddedConn = LP.CharacterAdded:Connect(function(char)
            task.wait(0.1)
            if self._charConn then self._charConn:Disconnect() end
            self._charConn = watchCharacter(char)
            if self.Enabled then
                LP.CameraMode = Enum.CameraMode.Classic
                LP.CameraMinZoomDistance = 12.5
                LP.CameraMaxZoomDistance = 12.5
            end
        end)
        self._conn = RunService.RenderStepped:Connect(function()
            if not self.Enabled then return end
            if LP.CameraMode ~= Enum.CameraMode.Classic then LP.CameraMode = Enum.CameraMode.Classic end
            if LP.CameraMinZoomDistance ~= 12.5 or LP.CameraMaxZoomDistance ~= 12.5 then
                LP.CameraMinZoomDistance = 12.5; LP.CameraMaxZoomDistance = 12.5
            end
        end)
    end
    function self.stop()
        if not self._saved then self.Enabled = false; return end
        self.Enabled = false
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        if self._charConn then self._charConn:Disconnect(); self._charConn = nil end
        if self._charAddedConn then self._charAddedConn:Disconnect(); self._charAddedConn = nil end
        LP.CameraMode = self._saved.CameraMode
        LP.CameraMinZoomDistance = self._saved.MinZoom
        LP.CameraMaxZoomDistance = self._saved.MaxZoom
        self._saved = nil
    end
    return self
end)()

;(function()
    local savedB, savedI, savedValid = nil, nil, false
    local prevMenu, prevTP, prevTab = false, false, false
    RunService.RenderStepped:Connect(function()
        local menuOpen = G2L["2"] and G2L["2"].Visible
        local tpOn = ThirdPerson.Enabled
        local tabHeld = UIS:IsKeyDown(Enum.KeyCode.Tab)
        local wantFreeMouse = menuOpen or tabHeld

        local shouldSave = false
        if (wantFreeMouse and not (prevMenu or prevTab)) then shouldSave = true end
        if (tpOn and not prevTP and not wantFreeMouse) then shouldSave = true end
        if shouldSave and not savedValid then
            savedB = UIS.MouseBehavior
            savedI = UIS.MouseIconEnabled
            savedValid = true
        end

        local shouldRestore = false
        if not wantFreeMouse and not tpOn and savedValid then
            if prevMenu or prevTab or prevTP then shouldRestore = true end
        end
        if shouldRestore then
            UIS.MouseBehavior = savedB
            UIS.MouseIconEnabled = savedI
            savedB, savedI, savedValid = nil, nil, false
        end

        prevMenu, prevTP, prevTab = menuOpen, tpOn, tabHeld

        if wantFreeMouse then
            if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then UIS.MouseBehavior = Enum.MouseBehavior.Default end
            if not UIS.MouseIconEnabled then UIS.MouseIconEnabled = true end
        elseif tpOn then
            if UIS.MouseBehavior ~= Enum.MouseBehavior.LockCenter then UIS.MouseBehavior = Enum.MouseBehavior.LockCenter end
            if UIS.MouseIconEnabled then UIS.MouseIconEnabled = false end
        end
    end)
end)()

;(function()
    local _, saSet, saEnable, saKeybind = buildModule(tabFrames.Combat, {
        name="SilentAim", title="Silent Aim", cardH=0.25, layoutOrder=1,
        titleSize=UDim2.new(0.4464,0,0.08639,0), titlePos=UDim2.new(0.27153,0,0.08598,0),
        enablePos=UDim2.new(0.85341,0,0.0858,0), enableSize=UDim2.new(0.1,0,0.074,0),
        keybindPos=UDim2.new(0.67498,0,0.08483,0), keybindSize=UDim2.new(0.15007,0,0.06872,0),
        settingsPos=UDim2.new(0.5,0,0.5815,0), settingsSize=UDim2.new(1,0,0.83699,0),
        onEnable=function(v)
            if v then
                SilentAim.Enabled = true
                local ok = SilentAim.API.Start()
                if not ok then warn("[Voxer] Silent Aim not installed") end
            else
                SilentAim.Enabled = false
                SilentAim.API.Stop()
            end
        end,
    })
    local saFovState = makeSliderRow(saSet, "FOV", 0, 1000, 100, 1, 0, function(v) SilentAim.API.SetFovRadius(v) end)
    local saShowFovState = makeToggleRow(saSet, "Show FOV", 2)
    local saVisibleState = makeToggleRow(saSet, "VIsible Check", 3)
    local saTracerState = makeToggleRow(saSet, "Tracers", 4)
    local saTeamState = makeToggleRow(saSet, "Team Check", 5)
    local saDistState = makeSliderRow(saSet, "Distance", 0, 5000, 500, 6, 0, function(v) SilentAim.API.Config.maxDistance = v end)
    local function saApplyHitPart(val)
        if val == "Closest" or val == "Head, Torso" then SilentAim.API.SetAimParts({"Head","UpperTorso","HumanoidRootPart"})
        elseif val == "Head" then SilentAim.API.SetAimParts({"Head"})
        elseif val == "Torso" then SilentAim.API.SetAimParts({"UpperTorso"}) end
    end
    local saHitPartState = makeDropdownRow(saSet, "Hit Part", "Head, Torso", 7, saApplyHitPart)
    saApplyHitPart(saHitPartState.Value)
    registerState("silent_enabled", saEnable)
    registerState("silent_fov", saFovState)
    registerState("silent_showfov", saShowFovState)
    registerState("silent_visible", saVisibleState)
    registerState("silent_tracers", saTracerState)
    registerState("silent_team", saTeamState)
    registerState("silent_distance", saDistState)
    registerState("silent_hitpart", saHitPartState)
    registerState("silent_keybind", saKeybind)
    SilentAim.API.SetFovRadius(saFovState.Value)
    SilentAim.API.SetFovVisible(saShowFovState.Enabled)
    SilentAim.API.Config.wallCheck = saVisibleState.Enabled
    SilentAim.API.Config.teamCheck = saTeamState.Enabled
    SilentAim.API.Config.maxDistance = saDistState.Value
    SilentAim.API.Config.tracersEnabled = saTracerState.Enabled
    RunService.Heartbeat:Connect(function()
        SilentAim.API.Config.wallCheck = saVisibleState.Enabled
        SilentAim.API.Config.teamCheck = saTeamState.Enabled
        SilentAim.API.Config.maxDistance = saDistState.Value
        SilentAim.API.Config.tracersEnabled = saTracerState.Enabled
        SilentAim.API.SetFovVisible(saShowFovState.Enabled)
    end)
end)()

;(function()
    local _, aaSet, aaEnable, aaKeybind = buildModule(tabFrames.Combat, {
        name="AimAssist", title="Aim Assist", cardH=0.27, layoutOrder=2,
        titleSize=UDim2.new(0.44479,0,0.07877,0), titlePos=UDim2.new(0.27096,0,0.07877,0),
        enablePos=UDim2.new(0.85208,0,0.07877,0), enableSize=UDim2.new(0.09884,0,0.06665,0),
        keybindPos=UDim2.new(0.67485,0,0.07675,0), keybindSize=UDim2.new(0.14997,0,0.06261,0),
        settingsPos=UDim2.new(0.49932,0,0.53723,0), settingsSize=UDim2.new(0.99864,0,0.77352,0),
        onEnable=function(v) AimAssist.Enabled = v; if not v then AimAssist._running = false end end,
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
    registerState("aim_enabled", aaEnable)
    registerState("aim_fov", aaFovState)
    registerState("aim_showfov", aaShowFovState)
    registerState("aim_visible", aaVisibleState)
    registerState("aim_team", aaTeamState)
    registerState("aim_distance", aaDistState)
    registerState("aim_smooth", aaSmoothState)
    registerState("aim_hitpart", aaHitPartState)
    registerState("aim_keybind", aaKeybind)
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
end)()

;(function()
    local _, tbSet, tbEnable, tbKeybind = buildModule(tabFrames.Combat, {
        name="TriggerBot", title="Trigger Bot", cardH=0.14, layoutOrder=3,
        titleSize=UDim2.new(0.44479,0,0.15191,0), titlePos=UDim2.new(0.27096,0,0.15191,0),
        enablePos=UDim2.new(0.85208,0,0.15191,0), enableSize=UDim2.new(0.09884,0,0.12854,0),
        keybindPos=UDim2.new(0.67485,0,0.14801,0), keybindSize=UDim2.new(0.14997,0,0.12075,0),
        settingsPos=UDim2.new(0.49932,0,1.03608,0), settingsSize=UDim2.new(0.99864,0,1.4918,0),
        onEnable=function(v) TriggerBot.Enabled = v; if v then TriggerBot.start() else TriggerBot.stop() end end,
    })
    local tbVisibleState = makeToggleRow(tbSet, "VIsible Check", 3)
    local tbTeamState = makeToggleRow(tbSet, "Team Check", 4)
    local tbDistState = makeSliderRow(tbSet, "Distance", 0, 5000, 500, 5, 0, function(v) TriggerBot.MaxDistance = v end)
    registerState("trigger_enabled", tbEnable)
    registerState("trigger_visible", tbVisibleState)
    registerState("trigger_team", tbTeamState)
    registerState("trigger_distance", tbDistState)
    registerState("trigger_keybind", tbKeybind)
    TriggerBot.MaxDistance = tbDistState.Value
    TriggerBot.VisibleCheck = tbVisibleState.Enabled
    TriggerBot.TeamCheck = tbTeamState.Enabled
    RunService.Heartbeat:Connect(function()
        TriggerBot.VisibleCheck = tbVisibleState.Enabled
        TriggerBot.TeamCheck = tbTeamState.Enabled
        TriggerBot.MaxDistance = tbDistState.Value
    end)
end)()

;(function()
    local _, rbSet, rbEnable, rbKeybind = buildModule(tabFrames.Combat, {
        name="RageBot", title="Rage Bot", cardH=0.17, layoutOrder=4,
        titleSize=UDim2.new(0.445,0,0.125,0), titlePos=UDim2.new(0.271,0,0.125,0),
        enablePos=UDim2.new(0.852,0,0.125,0), enableSize=UDim2.new(0.099,0,0.106,0),
        keybindPos=UDim2.new(0.675,0,0.122,0), keybindSize=UDim2.new(0.15,0,0.099,0),
        settingsPos=UDim2.new(0.498,0,0.853,0), settingsSize=UDim2.new(0.999,0,1.229,0),
        onEnable=function(v) RageBot.Enabled = v end,
    })
    local rbLimitFovState = makeToggleRow(rbSet, "Limit To FOV", 1)
    local rbQuickScopeState = makeToggleRow(rbSet, "Quick Scope", 2)
    local rbTeamState = makeToggleRow(rbSet, "Team Check", 3)
    local rbDistState = makeSliderRow(rbSet, "Distance", 0, 5000, 500, 4, 0, function(v) RageBot.MaxDistance = v end)
    local rbVisibleState = makeToggleRow(rbSet, "VIsible Check", 5)
    registerState("rage_enabled", rbEnable)
    registerState("rage_limitfov", rbLimitFovState)
    registerState("rage_quickscope", rbQuickScopeState)
    registerState("rage_team", rbTeamState)
    registerState("rage_distance", rbDistState)
    registerState("rage_visible", rbVisibleState)
    registerState("rage_keybind", rbKeybind)
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
    end)
end)()

;(function()
    local _, spdSet, spdEnable, spdKeybind = buildModule(tabFrames.Movement, {
        name="Speed", title="Speed", cardH=0.09, layoutOrder=1,
        titleSize=UDim2.new(0.44479,0,0.2363,0), titlePos=UDim2.new(0.27096,0,0.2363,0),
        enablePos=UDim2.new(0.85208,0,0.2363,0), enableSize=UDim2.new(0.09884,0,0.19994,0),
        keybindPos=UDim2.new(0.67485,0,0.23024,0), keybindSize=UDim2.new(0.14997,0,0.18783,0),
        settingsPos=UDim2.new(0.49932,0,1.61168,0), settingsSize=UDim2.new(0.99864,0,2.32057,0),
        onEnable=function(v) Speed.Enabled = v; if v then Speed.start() else Speed.stop() end end,
    })
    local spdSliderState = makeSliderRow(spdSet, "Amount", 0, 500, 50, 5, 0, function(v) Speed.Amount = v end)
    Speed.Amount = spdSliderState.Value
    local spdBypassState = makeDropdownRow(spdSet, "Bypass Method", "None", 6, function(val) Speed.BypassMethod = val end, {"None", "Slide", "Pulse", "Jump", "Smooth"})
    Speed.BypassMethod = spdBypassState.Value
    registerState("speed_enabled", spdEnable)
    registerState("speed_amount", spdSliderState)
    registerState("speed_bypass", spdBypassState)
    registerState("speed_keybind", spdKeybind)
end)()

;(function()
    local _, flySet, flyEnable, flyKeybind = buildModule(tabFrames.Movement, {
        name="Fly", title="Fly", cardH=0.11, layoutOrder=2,
        titleSize=UDim2.new(0.445,0,0.193,0), titlePos=UDim2.new(0.271,0,0.188,0),
        enablePos=UDim2.new(0.852,0,0.188,0), enableSize=UDim2.new(0.099,0,0.164,0),
        keybindPos=UDim2.new(0.675,0,0.183,0), keybindSize=UDim2.new(0.15,0,0.154,0),
        settingsPos=UDim2.new(0.498,0,1.314,0), settingsSize=UDim2.new(0.999,0,1.899,0),
        onEnable=function(v) Fly.Enabled = v; if v then Fly.start() else Fly.stop() end end,
    })
    local flySpeedState = makeSliderRow(flySet, "Speed", 0, 500, 50, 5, 0, function(v) Fly.Speed = v end)
    Fly.Speed = flySpeedState.Value
    local flyVertState = makeSliderRow(flySet, "Vertical Speed", 0, 500, 50, 5, 0, function(v) Fly.VerticalSpeed = v end)
    Fly.VerticalSpeed = flyVertState.Value
    registerState("fly_enabled", flyEnable)
    registerState("fly_speed", flySpeedState)
    registerState("fly_vertical", flyVertState)
    registerState("fly_keybind", flyKeybind)
end)()

;(function()
    local _, lnSet, lnEnable, lnKeybind = buildModule(tabFrames.Utilities, {
        name="LongNeck", title="Long Neck", cardH=0.07, layoutOrder=1,
        titleSize=UDim2.new(0.445,0,0.304,0), titlePos=UDim2.new(0.271,0,0.296,0),
        enablePos=UDim2.new(0.852,0,0.296,0), enableSize=UDim2.new(0.099,0,0.257,0),
        keybindPos=UDim2.new(0.675,0,0.288,0), keybindSize=UDim2.new(0.15,0,0.241,0),
        settingsPos=UDim2.new(0.498,0,2.064,0), settingsSize=UDim2.new(0.999,0,2.984,0),
        onEnable=function(v) LongNeck.Enabled = v; if v then LongNeck.start() else LongNeck.stop() end end,
    })
    local lnSliderState = makeSliderRow(lnSet, "Distance", 0, 20, 10, 5, 0, function(v)
        LongNeck.LiftAmount = v
        if LongNeck._holding and LongNeck._baseY then LongNeck._targetY = LongNeck._baseY + v end
    end)
    LongNeck.LiftAmount = lnSliderState.Value
    registerState("neck_enabled", lnEnable)
    registerState("neck_distance", lnSliderState)
    registerState("neck_keybind", lnKeybind)
end)()

;(function()
    local _, tpSet, tpEnable, tpKeybind = buildModule(tabFrames.Utilities, {
        name="ThirdPerson", title="Third Person", cardH=0.09, layoutOrder=2,
        titleSize=UDim2.new(0.445,0,0.2363,0), titlePos=UDim2.new(0.271,0,0.2363,0),
        enablePos=UDim2.new(0.852,0,0.2363,0), enableSize=UDim2.new(0.099,0,0.19994,0),
        keybindPos=UDim2.new(0.675,0,0.23024,0), keybindSize=UDim2.new(0.15,0,0.18783,0),
        settingsPos=UDim2.new(0.499,0,1.61168,0), settingsSize=UDim2.new(0.998,0,2.32057,0),
        onEnable=function(v) ThirdPerson.Enabled = v; if v then ThirdPerson.start() else ThirdPerson.stop() end end,
    })
    registerState("tp_enabled", tpEnable)
    registerState("tp_keybind", tpKeybind)
end)()

;(function()
    local _, espSet, espEnable, espKeybind = buildModule(tabFrames.Render, {
        name="ESP", title="ESP", cardH=0.16, layoutOrder=1,
        titleSize=UDim2.new(0.44479,0,0.13292,0), titlePos=UDim2.new(0.27096,0,0.12951,0),
        enablePos=UDim2.new(0.85208,0,0.12951,0), enableSize=UDim2.new(0.09884,0,0.11247,0),
        keybindPos=UDim2.new(0.67485,0,0.1261,0), keybindSize=UDim2.new(0.14997,0,0.10565,0),
        settingsPos=UDim2.new(0.49762,0,0.90316,0), settingsSize=UDim2.new(0.99864,0,1.30532,0),
        onEnable=function(v) ESP.SetEnabled(v) end,
    })
    local espBoxState = makeToggleRow(espSet, "Box", 0)
    local espNameState = makeToggleRow(espSet, "Name", 1)
    local espDistState = makeToggleRow(espSet, "Distance", 2)
    local espTeamState = makeToggleRow(espSet, "Team Check", 3)
    registerState("esp_enabled", espEnable)
    registerState("esp_box", espBoxState)
    registerState("esp_name", espNameState)
    registerState("esp_distance", espDistState)
    registerState("esp_team", espTeamState)
    registerState("esp_keybind", espKeybind)
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
end)()

;(function()
    local _, chamsSet, chamsEnable, chamsKeybind = buildModule(tabFrames.Render, {
        name="Chams", title="Chams", cardH=0.13, layoutOrder=2,
        titleSize=UDim2.new(0.44479,0,0.16359,0), titlePos=UDim2.new(0.27096,0,0.1594,0),
        enablePos=UDim2.new(0.85208,0,0.1594,0), enableSize=UDim2.new(0.09884,0,0.13842,0),
        keybindPos=UDim2.new(0.67485,0,0.1552,0), keybindSize=UDim2.new(0.14997,0,0.13003,0),
        settingsPos=UDim2.new(0.49762,0,1.11158,0), settingsSize=UDim2.new(0.99864,0,1.60655,0),
        onEnable=function(v) Chams.SetEnabled(v) end,
    })
    local chamsTopState = makeToggleRow(chamsSet, "Always On Top", 0)
    local chamsOutlineState = makeToggleRow(chamsSet, "Outline", 1)
    local chamsTeamState = makeToggleRow(chamsSet, "Team Check", 3)
    registerState("chams_enabled", chamsEnable)
    registerState("chams_top", chamsTopState)
    registerState("chams_outline", chamsOutlineState)
    registerState("chams_team", chamsTeamState)
    registerState("chams_keybind", chamsKeybind)
    Chams.AlwaysOnTop = chamsTopState.Enabled
    Chams.Outline = chamsOutlineState.Enabled
    Chams.TeamCheck = chamsTeamState.Enabled
    RunService.Heartbeat:Connect(function()
        Chams.AlwaysOnTop = chamsTopState.Enabled
        Chams.Outline = chamsOutlineState.Enabled
        Chams.TeamCheck = chamsTeamState.Enabled
    end)
end)()

;(function()
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
end)()

-- ========== INIT ==========
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
