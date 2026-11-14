

local Sources = {
    Library = [=[return assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/087d501b05f37c149cedabddbbaa96bc9eee81e7/source/game-bridge.lua"), "Axis UI bridge"))()]=],
    Adapter = [=[

local A = {}
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local function records()
    local out = {}
    for _, player in ipairs(Players:GetPlayers()) do
        local model = player.Character
        local h = model and model:FindFirstChildOfClass("Humanoid")
        if model and model:IsDescendantOf(workspace) and h and h.Health > 0
            and model:FindFirstChild("Head") and model:FindFirstChild("HumanoidRootPart") then
            out[model] = {IsLocal = player == LP, Player = player}
        end
    end
    return out
end
function A.Health(model)
    local h = model and model:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0, h and h.MaxHealth or 100
end
A.EntityClient = {}
function A.EntityClient:GetRecords() return records() end
function A.EntityClient:GetLocalModel() return LP.Character end
function A.EntityClient:GetVelocity(model)
    local root = model and model:FindFirstChild("HumanoidRootPart")
    return root and root.AssemblyLinearVelocity or Vector3.zero
end
A.GlobalStuff = {}
function A.GlobalStuff:CanHit(_, model)
    if A.Config and A.Config.SkipProtected and model and
        (model:GetAttribute("SpawnShield") or model:GetAttribute("PvPSafe") or model:GetAttribute("Downed")) then return false end
    local other = model and Players:GetPlayerFromCharacter(model)
    if not other or other == LP or other.Character ~= model or A.Health(model) <= 0
        or model:FindFirstChildOfClass("ForceField") then return false end
    return LP.Neutral or other.Neutral or other.Team ~= LP.Team
end
A.Hitboxes = {}
function A.Hitboxes.ZoneCenter(pose, zone)
    local model = pose.Model
    local part = model and (model:FindFirstChild(zone) or model:FindFirstChild(zone == "Torso" and "UpperTorso" or "Head"))
    if not part then return nil end
    local registry = A.NativeHitboxes
    local folder = registry and registry.folders[model]
    local proxy = folder and folder:FindFirstChild(part.Name)
    if proxy and proxy:IsA("BasePart") and (proxy.Position - part.Position).Magnitude <= 4 then
        return proxy.Position
    end
    return part.Position
end
function A.CastVisibility(origin, direction, params)
    if A.NativeCast then return A.NativeCast(origin, direction, params) end
    return workspace:Raycast(origin, direction, params)
end
function A.VisiblePoint(model, origin, params, primary)
    local names = {primary, "UpperTorso", "LowerTorso", "Head"}
    for _, name in ipairs(names) do
        local point = A.Hitboxes.ZoneCenter({Model = model}, name)
        if point then
            local hit = A.CastVisibility(origin, point - origin, params)
            if not hit or hit.Instance:IsDescendantOf(model) or hit.Distance >= (point - origin).Magnitude - 0.1 then return point end
        end
    end
    return nil
end
function A.SelectAura(origin, range, params)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    if not root or not head then return nil end
    local best, closest
    for model, record in pairs(A.EntityClient:GetRecords()) do
        if not record.IsLocal and A.GlobalStuff:CanHit(LP, model)
            and not model:GetAttribute("SpawnShield") and not model:GetAttribute("PvPSafe") then
            local center = A.Hitboxes.ZoneCenter({Model = model}, A.Config and A.Config.Zone or "Head")
            if center and (center - root.Position).Magnitude <= range then
                local point = A.VisiblePoint(model, origin, params, A.Config and A.Config.Zone or "Head")
                if point then
                    local distance = (point - root.Position).Magnitude
                    local delta = point - origin
                    local hit = A.CastVisibility(head.Position, point - head.Position, params)
                    local visible = not hit or hit.Instance:IsDescendantOf(model) or hit.Distance >= (point - head.Position).Magnitude - 0.1
                    if visible and distance <= range and delta.Magnitude > 0.001 and (not closest or distance < closest) then
                        closest = distance
                        best = {Model = model, Point = point, Direction = delta.Unit, Distance = distance}
                    end
                end
            end
        end
    end
    return best
end
A.ShotClient = {}
function A.ShotClient:GetPoses()
    local out = {}
    for model, rec in pairs(records()) do if not rec.IsLocal then table.insert(out, {Model = model}) end end
    return out
end
function A.ShotClient:Exclude()
    local out = {workspace.CurrentCamera}
    for model in pairs(records()) do table.insert(out, model) end
    local fx = workspace:FindFirstChild("FX") if fx then table.insert(out, fx) end
    local hitboxes = workspace:FindFirstChild("ClientHitboxes") if hitboxes then table.insert(out, hitboxes) end
    return out
end
function A.ShotClient:Ignore() return LP.Character and {[LP.Character] = true} or {} end
function A.ShotClient:Origin() return workspace.CurrentCamera.CFrame.Position end
function A.ShotClient:AimDirection() return workspace.CurrentCamera.CFrame.LookVector end
A.Action = {}
function A.Action:GetWModel()
    local char = LP.Character
    if char then for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child:GetAttribute("Weapon") then return child end
    end end
end

local heldVisualCache = setmetatable({}, {__mode = "k"})
local nativeVisualCache
local nextVisualLookup = 0
function A.ResolveHeldVisual(tool)
    if not tool then return nil end
    local character = tool.Parent
    if not nativeVisualCache and os.clock() >= nextVisualLookup then
        nextVisualLookup = os.clock() + 1
        for _, fn in ipairs(getgc()) do
            if type(fn) == "function" and islclosure(fn) then
                local info = debug.getinfo(fn)
                if info.name == "getVisual" and (info.source or ""):find("GunAnimator", 1, true) then
                    for _, value in pairs(debug.getupvalues(fn)) do
                        local record = type(value) == "table" and rawget(value, character)
                        if type(record) == "table" and typeof(rawget(record, "model")) == "Instance" then
                            nativeVisualCache = value break
                        end
                    end
                end
            end
            if nativeVisualCache then break end
        end
    end
    local record = nativeVisualCache and rawget(nativeVisualCache, character)
    if type(record) == "table" and record.name == tool:GetAttribute("Weapon")
        and typeof(record.model) == "Instance" and record.model.Parent then
        heldVisualCache[tool] = record.model return record.model
    end
    local cached = heldVisualCache[tool]
    if cached and cached.Parent then
        local joint = cached:FindFirstChild("GA_Attach", true)
        if joint and joint.Part0 and joint.Part0:IsDescendantOf(tool) then return cached end
    end
    local reference = character and character:FindFirstChild("GA_Visual")
    if reference and reference:IsA("ObjectValue") and reference.Value then
        heldVisualCache[tool] = reference.Value return reference.Value
    end
    local fx = workspace:FindFirstChild("FX")
    if fx then for _, model in ipairs(fx:GetChildren()) do
        if model:IsA("Model") and model.Name == tool:GetAttribute("Weapon") then
            for _, joint in ipairs(model:GetDescendants()) do
                if joint.Name == "GA_Attach" and (joint:IsA("JointInstance") or joint:IsA("WeldConstraint"))
                    and joint.Part0 and joint.Part0:IsDescendantOf(tool) then
                    heldVisualCache[tool] = model return model
                end
            end
        end
    end end
    if cached and cached.Parent and cached.Name == tool:GetAttribute("Weapon") then return cached end
    return nil
end

function A.Install(S, H)
    local C = S.Config
    A.Config = C
    
    local state = require(RS.Weapons.ClientState)
    A.ClientState = state
    A.NativeHitboxes = require(RS.Weapons.ClientHitboxes)
    local functions = {}
    local savedTargets = getgenv().UrbanNativeTargets
    for _, fn in ipairs(getgc()) do
        if type(fn) == "function" and islclosure(fn) then
            local info = debug.getinfo(fn)
            local source, name = info.source or "", info.name or ""
            if source:find("PlayerScripts.WeaponClient", 1, true) then
                if name == "fire" or name == "bloomDir" or name == "currentSpread" or name == "pelletDirs" then functions[name] = fn end
                if name == "" then
                    for _, constant in pairs(debug.getconstants(fn)) do
                        if constant == "OpticAltZoom" then functions.weaponStep = fn break end
                        if constant == "Shoulder" then
                            local values = debug.getupvalues(fn)
                            if values[1] == state and type(values[4]) == "boolean" and type(values[5]) == "number" then functions.inputBegan = fn end
                        end
                    end
                end
            elseif source:find("PlayerScripts.CameraClient", 1, true) and name == "addRecoil" then
                functions.addRecoil = fn
            end
        end
    end
    if savedTargets then
        for name, fn in pairs(savedTargets) do
            if type(fn) == "function" then functions[name] = fn end
        end
    end
    if functions.weaponStep then
        for _, value in pairs(debug.getupvalues(functions.weaponStep)) do
            if type(value) == "function" and debug.getinfo(value).name == "fire" then functions.fire = value break end
        end
    end

    local function unwrapFire(fn)
        local seen = {}
        while type(fn) == "function" and not seen[fn] do
            seen[fn] = true
            local values = debug.getupvalues(fn)
            local owner = values[1]
            if type(owner) == "table" and rawget(owner, "Config") and rawget(owner, "Hooks")
                and type(values[2]) == "function" then fn = values[2] else break end
        end
        return fn
    end
    functions.fire = unwrapFire(functions.fire)
    if functions.fire then
        for _, value in pairs(debug.getupvalues(functions.fire)) do
            if type(value) == "function" then
                local name = debug.getinfo(value).name
                if name == "currentSpread" or name == "bloomDir" or name == "pelletDirs" or name == "startReload" then functions[name] = value end
                if name == "castVisible" then A.NativeCast = value end
            end
        end
    end
    S.NativeTargets = functions
    S.Capabilities = {}
    for name in pairs(functions) do S.Capabilities[name] = true end
    assert(functions.fire and functions.weaponStep, "Weapon callbacks unavailable: game version changed")
    local fireValues = debug.getupvalues(functions.fire)
    local configIndex, shotTimeIndex = 2, 3
    for index, value in pairs(fireValues) do
        if type(value) == "table" and rawget(value, "Fire") and rawget(value, "Bloom") then
            configIndex = index
            if type(fireValues[index + 1]) == "number" then shotTimeIndex = index + 1 end
            break
        end
    end
    S.Capabilities.rapidFire = configIndex ~= nil and shotTimeIndex ~= nil
    local firing = setmetatable({}, {__mode = "k"})
    local oldFire
    local fireDispatch
    fireDispatch = function(...)
        if not S.Loaded then return oldFire(...) end
        local thread = coroutine.running()
        firing[thread] = true
        S.Shots = (S.Shots or 0) + 1
        local result = table.pack(pcall(oldFire, ...))
        firing[thread] = nil
        if not result[1] then H.recordError("Fire", result[2]) return end
        return table.unpack(result, 2, result.n)
    end
    oldFire = H.hook(functions.fire, fireDispatch)
    local oldNamecall
    local replacement = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if not S.Loaded or not (C.SilentAim or C.Triggerbot or C.RageAura) or method ~= "ViewportPointToRay"
            or self ~= workspace.CurrentCamera or not firing[coroutine.running()] then
            return oldNamecall(self, ...)
        end
        local ray = oldNamecall(self, ...)
        S.ShotRays = (S.ShotRays or 0) + 1
        local ok, direction = pcall(function()
            local config = configIndex and debug.getupvalue(oldFire, configIndex)
            local range = config and config.Damage and config.Damage.Range or 1000
            return A.ShotClient:AimDirection(ray.Origin, range, S.WorldParams(), A.ShotClient:GetPoses(), A.ShotClient:Ignore())
        end)
        if ok and typeof(direction) == "Vector3" and direction.Magnitude > 0.001 then
            return Ray.new(ray.Origin, direction.Unit)
        end
        if not ok then H.recordError("ShotRay", direction) end
        return ray
    end)
    oldNamecall = hookmetamethod(game, "__namecall", replacement)
    local namecallRestored = false
    S.RestoreNamecall = function()
        if oldNamecall and not namecallRestored then
            hookmetamethod(game, "__namecall", oldNamecall)
            namecallRestored = true
        end
    end
    function S.ProbeShotRay()
        local thread = coroutine.running()
        local previous = firing[thread]
        firing[thread] = true
        local ok, result = pcall(function()
            local cam = workspace.CurrentCamera
            local center = cam.ViewportSize / 2
            return cam:ViewportPointToRay(center.X, center.Y)
        end)
        firing[thread] = previous
        return ok, result
    end
    if functions.currentSpread then
        local old
        old = H.hook(functions.currentSpread, function(...)
            if S.Loaded and C.NoSpread then return 0 end
            return old(...)
        end)
    end
    if functions.bloomDir then
        local old
        old = H.hook(functions.bloomDir, function(direction, spread, ...)
            if S.Loaded and C.NoSpread then return direction end
            return old(direction, spread, ...)
        end)
    end
    if functions.addRecoil then
        local old
        old = H.hook(functions.addRecoil, function(...)
            if S.Loaded and C.NoRecoil then return true end
            return old(...)
        end)
    end
    if functions.pelletDirs then
        local old
        old = H.hook(functions.pelletDirs, function(direction, ...)
            local result = old(direction, ...)
            if S.Loaded and C.NoSpread then
                for index in ipairs(result) do result[index] = direction end
            end
            return result
        end)
    end
    local lastRapid, lastHipShot = 0, 0
    local UIS = game:GetService("UserInputService")
    local oldStep
    oldStep = H.hook(functions.weaponStep, function(...)
        if not S.Loaded then return oldStep(...) end
        local safe = not state.CursorFree and not UIS:GetFocusedTextBox()
            and not game:GetService("GuiService").MenuIsOpen and not S.MenuVisible
        if C.RageAura and safe and state.Equipped then
            local values = debug.getupvalues(oldFire)
            local config = configIndex and values[configIndex]
            local range = math.min(C.AuraRange, config and config.Damage and config.Damage.Range or C.AuraRange)
            S.AuraTarget = A.SelectAura(workspace.CurrentCamera.CFrame.Position, range, S.WorldParams())
        else S.AuraTarget = nil end
        local aiming, rolling = state.Aiming, state.Rolling
        local changeRoll = safe and C.ShootRolling and rolling
        if changeRoll then state.Rolling = false end
        if safe and C.RapidFire and configIndex and shotTimeIndex then
            local config = debug.getupvalue(oldFire, configIndex)
            local rpm = config and config.Fire and config.Fire.RPM
            local now = os.clock()
            if type(rpm) == "number" and rpm > 0 and now - lastRapid >= 60 / (rpm * C.FireMultiplier) then
                debug.setupvalue(oldFire, shotTimeIndex, now - 60 / rpm - 0.001)
                lastRapid = now
            end
        end
        local input = functions.inputBegan
        local previousTrigger, previousQueue, injected
        if safe and input and not state.Healing and not state.HealItem and not state.DrinkStart then
            previousTrigger = debug.getupvalue(input, 4)
            previousQueue = debug.getupvalue(input, 5)
            local automatic = C.AutomaticSemi and previousTrigger == true
            local targetFire = (C.Triggerbot and S.CurrentTarget ~= nil) or (C.RageAura and S.AuraTarget ~= nil)
            if automatic or targetFire then
                debug.setupvalue(input, 4, true)
                debug.setupvalue(input, 5, os.clock())
                injected = true
            end
        end
        local result = table.pack(pcall(oldStep, ...))
        if injected then
            debug.setupvalue(input, 4, previousTrigger)
            if not previousTrigger then debug.setupvalue(input, 5, 0) end
        end
        if changeRoll then state.Rolling = rolling end
        
        if result[1] and safe and not aiming and (C.HipFire or C.RapidFire or C.SilentAim or C.Triggerbot or C.RageAura)
            and state.Equipped and not state.Reloading and not state.CaseRolling and not state.BetaIntermission
            and not state.Healing and not state.HealItem and not state.DrinkStart
            and (not rolling or C.ShootRolling) and input then
            local values = debug.getupvalues(oldFire)
            local config = configIndex and values[configIndex]
            local tool, humanoid, clip = values[23], values[13], values[8]
            local lastShot = shotTimeIndex and values[shotTimeIndex]
            local stepValues = debug.getupvalues(oldStep)
            local equipReady, boltReady, shield = stepValues[18], stepValues[36], stepValues[35]
            local now = os.clock()
            local held = debug.getupvalue(input, 4) == true
            local queuedAt = debug.getupvalue(input, 5)
            local autoTarget = (C.Triggerbot and S.CurrentTarget ~= nil) or (C.RageAura and S.AuraTarget ~= nil)
            local cfgFire = config and config.Fire
            local wantsShot = cfgFire and (autoTarget or held and (cfgFire.Mode == "Auto" or C.AutomaticSemi)
                or type(queuedAt) == "number" and queuedAt > 0 and now - queuedAt < 0.2)
            local protected = LP:GetAttribute("InCarGarage") or
                (type(shield) == "table" and type(shield.Active) == "function" and shield.Active(LP.Character))
            local interval = cfgFire and 60 / math.max(cfgFire.RPM or 600, 1)
            if interval and C.RapidFire then interval /= math.max(C.FireMultiplier, 1) end
            if wantsShot and not protected and tool and tool.Parent == LP.Character and humanoid and humanoid.Health > 0
                and type(clip) == "number" and clip > 0 and type(lastShot) == "number"
                and type(equipReady) == "number" and now >= equipReady
                and type(boltReady) == "number" and now >= boltReady
                and now - math.max(lastShot, lastHipShot) >= interval then
                lastHipShot = now
                debug.setupvalue(input, 5, 0)
                fireDispatch(now)
            end
        end
        S.FireStatus = not safe and "menu/input" or state.Reloading and "reloading"
            or not state.Equipped and "unequipped" or (rolling and not C.ShootRolling) and "rolling"
            or (not aiming and not (C.HipFire or C.RapidFire or C.SilentAim or C.Triggerbot or C.RageAura)) and "aim required" or "ready"
        if safe and C.AutoReload and functions.startReload and not state.Reloading then
            local values = debug.getupvalues(functions.startReload)
            local clip, capacity = values[3], values[4]
            if type(clip) == "number" and type(capacity) == "number" and clip < capacity and clip <= C.ReloadAt then
                local reloadOk, reloadError = pcall(functions.startReload)
                if not reloadOk then H.recordError("AutoReload", reloadError) end
            end
        end
        if not result[1] then H.recordError("WeaponStep", result[2]) return end
        return table.unpack(result, 2, result.n)
    end)
    S.AdapterMaintenance = function()
        A.ResolveHeldVisual(A.Action:GetWModel())
        if not configIndex then
            local values = debug.getupvalues(oldFire)
            for index, value in pairs(values) do
                if type(value) == "table" and rawget(value, "Fire") and rawget(value, "Bloom") then
                    configIndex = index
                    if type(values[index + 1]) == "number" then shotTimeIndex = index + 1 end
                    break
                end
            end
            S.Capabilities.rapidFire = configIndex ~= nil and shotTimeIndex ~= nil
        end
    end
    S.RestoreWeaponSettings = function() end
    S.ClientState = state
    S.NativeHitscan = true
end
return A
]=],
    Stamina = [=[

return function(S, H)
    local state, config = S.ClientState, S.Config
    local player = game:GetService("Players").LocalPlayer
    local native = S.NativeTargets and S.NativeTargets.movementStep
    if not native then
        for _, fn in ipairs(getgc()) do
            if type(fn) == "function" and islclosure(fn) then
                local info = debug.getinfo(fn)
                if (info.source or ""):find("PlayerScripts.MovementClient", 1, true) then
                    local values = debug.getupvalues(fn)
                    if values[2] == state and type(values[7]) == "boolean" then
                        for _, constant in pairs(debug.getconstants(fn)) do
                            if constant == "StaminaOut" then native = fn break end
                        end
                    end
                end
            end
            if native then break end
        end
    end
    if not native then S.Capabilities.infiniteStamina = false return end
    S.NativeTargets.movementStep = native
    S.Capabilities.infiniteStamina = true
    local original
    local function refill()
        local maximum = state.StaminaMax
        if type(maximum) ~= "number" or maximum <= 0 or maximum == math.huge then maximum = 150 end
        state.Stamina = maximum
        state.Exhausted = false
        
        if type(debug.getupvalue(original, 7)) == "boolean" then debug.setupvalue(original, 7, false) end
        local character = player.Character
        S.StaminaServerBlocked = character and character:GetAttribute("StaminaOut") == true or false
    end
    original = H.hook(native, function(...)
        if not S.Loaded or not config.InfiniteStamina then return original(...) end
        refill()
        local result = table.pack(pcall(original, ...))
        refill()
        if not result[1] then H.recordError("Stamina", result[2]) return end
        return table.unpack(result, 2, result.n)
    end)
end
]=],

    AntiAim = [=[

return function(S, H)
    local C, state = S.Config, S.ClientState
    local player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local functions = {}
    for _, fn in ipairs(getgc()) do
        if type(fn) == "function" and islclosure(fn) then
            local info = debug.getinfo(fn)
            local source, name = info.source or "", info.name
            if source:find("PlayerScripts.WeaponClient", 1, true) and name == "sendStance" then functions.sendStance = fn end
            if source:find("PlayerScripts.GunAnimator", 1, true) and name == "preAnimChar" then functions.preAnimChar = fn end
        end
    end
    for name, fn in pairs(S.NativeTargets or {}) do
        if name == "sendStance" or name == "preAnimChar" then functions[name] = fn end
    end
    if S.NativeTargets.weaponStep then
        for _, value in pairs(debug.getupvalues(S.NativeTargets.weaponStep)) do
            if type(value) == "function" and debug.getinfo(value).name == "sendStance" then functions.sendStance = value break end
        end
    end
    local function pitchAt(t)
        if C.AAPitchMode == "Up" then return math.rad(70) end
        if C.AAPitchMode == "Down" then return math.rad(-75) end
        if C.AAPitchMode == "Alternating" then return math.rad(math.floor(t * 2) % 2 == 0 and 70 or -75) end
        if C.AAPitchMode == "Rotate" then return math.rad(-2.5 + 72.5 * math.sin(t * math.rad(C.AASpeed))) end
        return math.rad(math.clamp(C.AAPitch, -75, 70))
    end
    S.ComputeAAPitch = pitchAt
    for name, fn in pairs(functions) do
        S.NativeTargets[name] = fn
        local original
        original = H.hook(fn, function(...)
            local args = table.pack(...)
            if not S.Loaded or not C.AntiAim or name == "preAnimChar" and args[1] ~= player.Character then
                return original(table.unpack(args, 1, args.n))
            end
            local previous = state.CamPitch
            state.CamPitch = pitchAt(os.clock())
            local result = table.pack(pcall(original, table.unpack(args, 1, args.n)))
            state.CamPitch = previous
            if not result[1] then H.recordError("AntiAim", result[2]) return end
            return table.unpack(result, 2, result.n)
        end)
    end
    S.Capabilities.antiAimPitch = functions.sendStance ~= nil and functions.preAnimChar ~= nil
    local lastRoot, lastRotation
    local function restoreYaw()
        if lastRoot and lastRoot.Parent and lastRotation then lastRoot.CFrame = CFrame.new(lastRoot.Position) * lastRotation end
        lastRoot, lastRotation = nil, nil
    end
    RunService:BindToRenderStep("UrbanAntiAimYaw", Enum.RenderPriority.Camera.Value + 115, function()
        if not S.Loaded or not C.AntiAim or C.AAYawMode == "None" then restoreYaw() return end
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 or humanoid.Sit or humanoid.SeatPart
            or state.Rolling or state.Vehicle or char:GetAttribute("Downed") or char:GetAttribute("CarRagdoll") then restoreYaw() return end
        local look = workspace.CurrentCamera.CFrame.LookVector
        local yaw = math.atan2(-look.X, -look.Z)
        if C.AAYawMode == "Backward" then yaw += math.pi
        elseif C.AAYawMode == "Spin" then yaw += os.clock() * math.rad(C.AASpeed)
        elseif C.AAYawMode == "Jitter" then yaw += math.floor(os.clock() * 4) % 2 == 0 and math.pi / 2 or -math.pi / 2 end
        lastRoot, lastRotation = root, root.CFrame.Rotation
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
    end)
    S.CleanupAntiAim = function() RunService:UnbindFromRenderStep("UrbanAntiAimYaw") restoreYaw() end
end
]=],
    HeldCosmetics = [=[

return function(catalog, assets, resolveVisual)
    local paint
    for _, value in pairs(debug.getupvalues(catalog.Apply)) do
        if type(value) == "function" and debug.getinfo(value).name == "paintSkin" then paint = value break end
    end
    assert(paint, "Native skin painter unavailable")
    return function(tool, weapon, selections)
        local source = assert(assets:FindFirstChild(weapon), "Weapon visual unavailable")
        local target = resolveVisual and resolveVisual(tool) or (not resolveVisual and tool)
        assert(target, "Waiting for the native held gun visual")
        local handle = target:FindFirstChild("Handle", true) or target:FindFirstChild("Origin", true)
        local sourceHandle = source:FindFirstChild("Handle", true) or source.PrimaryPart
        assert(handle and handle:IsA("BasePart") and sourceHandle, "Gun anchor unavailable")
        local saved, surfaces, spawned, hidden, attributes = {}, {}, {}, {}, {}
        local skin = selections.Skin and catalog.Skins[selections.Skin]
        local textureNames = {SkinBase = true, SkinFlow = true}
        for _, obj in ipairs(target:GetDescendants()) do
            if obj:IsA("BasePart") then
                local props = {Color = obj.Color, Material = obj.Material, MaterialVariant = obj.MaterialVariant,
                    Reflectance = obj.Reflectance, Transparency = obj.Transparency, LocalTransparencyModifier = obj.LocalTransparencyModifier}
                if obj:IsA("MeshPart") then props.TextureID = obj.TextureID end
                if obj:IsA("UnionOperation") then props.UsePartColor = obj.UsePartColor end
                saved[obj] = props
                attributes[obj] = {}
                for _, key in ipairs({"SkinFX", "GlintColor"}) do attributes[obj][key] = {Value = obj:GetAttribute(key)} end
                attributes[obj].SkinFXTag = obj:HasTag("SkinFX")
                attributes[obj].SkinGlintTag = obj:HasTag("SkinGlint")
            elseif obj:IsA("SpecialMesh") then saved[obj] = {TextureId = obj.TextureId, VertexColor = obj.VertexColor}
            end
        end
        local destroyed = false
        local view = {Model = target, Tool = tool, Weapon = weapon, Selections = table.clone(selections), Direct = true}
        function view:Destroy()
            if destroyed then return end destroyed = true
            for _, obj in ipairs(spawned) do obj:Destroy() end
            for obj, props in pairs(saved) do
                if obj.Parent then
                    if skin and obj:IsA("BasePart") then
                        for _, child in ipairs(obj:GetChildren()) do
                            if child:IsA("SurfaceAppearance") or child:IsA("Texture") and textureNames[child.Name] then child:Destroy() end
                        end
                    end
                    pcall(function() for key, value in pairs(props) do obj[key] = value end end)
                end
            end
            for obj, data in pairs(attributes) do if obj.Parent then
                obj:SetAttribute("SkinFX", data.SkinFX.Value) obj:SetAttribute("GlintColor", data.GlintColor.Value)
                if data.SkinFXTag then obj:AddTag("SkinFX") else obj:RemoveTag("SkinFX") end
                if data.SkinGlintTag then obj:AddTag("SkinGlint") else obj:RemoveTag("SkinGlint") end
            end end
            for obj, parent in pairs(surfaces) do
                if parent.Parent then obj.Parent = parent else obj:Destroy() end
            end
        end
        local ok, err = xpcall(function()
            local hiddenNames, replacedFamilies = {}, {}
            for family, id in pairs(selections) do
                local definition = catalog.FamilyById[family]
                local mount = definition and catalog.Mount(weapon, id)
                if mount then
                    replacedFamilies[family] = true
                    for _, name in ipairs(definition.Hides or {}) do hiddenNames[name] = true end
                    for _, name in ipairs((definition.HidesByWeapon or {})[weapon] or {}) do hiddenNames[name] = true end
                    local attachment = mount:Clone() attachment.Name = "UrbanAttachment_" .. id
                    table.insert(spawned, attachment)
                    local transform = handle.CFrame * sourceHandle.CFrame:Inverse()
                    for _, obj in ipairs(attachment:GetDescendants()) do
                        if obj:IsA("LuaSourceContainer") or obj:IsA("JointInstance") or obj:IsA("Constraint")
                            or obj:IsA("WeldConstraint") or obj:IsA("Sound") then obj:Destroy()
                        elseif obj:IsA("BasePart") then
                            obj.CFrame = transform * obj.CFrame obj.Anchored = false obj.Massless = true
                            obj.CanCollide = false obj.CanTouch = false obj.CanQuery = false
                            local weld = Instance.new("WeldConstraint") weld.Part0 = handle weld.Part1 = obj weld.Parent = obj
                        end
                    end
                    attachment.Parent = target
                end
            end
            for obj in pairs(saved) do
                if obj:IsA("BasePart") then
                    if replacedFamilies[obj:GetAttribute("ModFamily")] then hidden[obj] = true obj.LocalTransparencyModifier = 1 end
                    local parent = obj
                    while parent and parent ~= target do
                        if hiddenNames[parent.Name] then hidden[obj] = true obj.LocalTransparencyModifier = 1 break end
                        parent = parent.Parent
                    end
                    for _, child in ipairs(obj:GetChildren()) do
                        if skin and (child:IsA("SurfaceAppearance") or child:IsA("Texture") and textureNames[child.Name]) then
                            surfaces[child] = obj child.Parent = nil
                        end
                    end
                end
            end
            if skin then paint(target, skin, nil) end
        end, debug.traceback)
        if not ok then view:Destroy() error(err) end
        function view:Maintain()
            if destroyed or not tool.Parent or not target.Parent then return false end
            if resolveVisual and resolveVisual(tool) ~= target then return false end
            for part in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier = 1 end end
            return true
        end
        return view
    end
end
]=],
    Chams = [==[
local M = {}
local body = {}
for _, name in ipairs({"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg",
    "LeftFoot", "RightUpperLeg", "RightLowerLeg", "RightFoot"}) do body[name] = true end
function M.new(model, parent)
    local self = {Model = model, Saved = {}, Surfaces = {}, Clones = {}}
    local frame = Instance.new("ViewportFrame")
    frame.Name = "MaterialBody" frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundTransparency = 1 frame.BorderSizePixel = 0 frame.Visible = false
    frame.Ambient = Color3.new(0.8, 0.8, 0.8) frame.LightColor = Color3.new(1, 1, 1)
    frame.LightDirection = Vector3.new(-1, -1, -1)
    
    local gui = Instance.new("ScreenGui") gui.Name = "MaterialBodies"
    gui.IgnoreGuiInset = true gui.ResetOnSpawn = false gui.DisplayOrder = -10
    gui.Parent = parent.Parent frame.Parent = gui
    local world = Instance.new("WorldModel") world.Parent = frame
    local camera = Instance.new("Camera") camera.Parent = frame frame.CurrentCamera = camera
    self.Frame = frame self.Gui = gui
    local glow = Instance.new("Highlight")
    glow.Name = "AxisESPGlow" glow.Adornee = model glow.Enabled = false glow.Parent = model
    function self:SetEnabled(enabled)
        if enabled then return end
        glow.Enabled = false
        self.Mode = nil
        frame.Visible = false
        for obj, props in pairs(self.Saved) do
            if obj.Parent then pcall(function() for key, value in pairs(props) do obj[key] = value end end) end
        end
        table.clear(self.Saved)
        for surface, original in pairs(self.Surfaces) do
            if original.Parent then pcall(function() surface.Parent = original end) end
        end
        table.clear(self.Surfaces)
    end
    function self:Update(sourceCamera, color, materialName, transparency, throughWalls, effects)
        effects = effects or {}
        if not effects.Base and not effects.Shader and effects.Glow then
            self:SetEnabled(false)
            glow.Enabled = true
            glow.DepthMode = throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            glow.FillTransparency = 1
            glow.OutlineColor = effects.GlowColor or color
            glow.OutlineTransparency = 1 - math.clamp(effects.GlowIntensity or 0.7, 0, 1)
            return
        end
        glow.Enabled = effects.Glow == true
        glow.DepthMode = throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        glow.FillTransparency = 1
        glow.OutlineColor = effects.GlowColor or color
        glow.OutlineTransparency = 1 - math.clamp(effects.GlowIntensity or 0.7, 0, 1)
        if effects.Shader then color = effects.ShaderColor or color materialName = "ForceField" transparency = 1 - (1 - transparency) * math.clamp(effects.ShaderIntensity or 0.5,0,1) end
        if self.Mode ~= nil and self.Mode ~= throughWalls then self:SetEnabled(false) end
        self.Mode = throughWalls
        local material = Enum.Material[materialName] or Enum.Material.Neon
        camera.CFrame = sourceCamera.CFrame camera.FieldOfView = sourceCamera.FieldOfView
        camera.FieldOfViewMode = sourceCamera.FieldOfViewMode
        frame.Visible = throughWalls
        if not throughWalls then
            for _, clothing in ipairs(model:GetChildren()) do
                if clothing:IsA("Shirt") or clothing:IsA("Pants") or clothing:IsA("ShirtGraphic") then
                    self.Surfaces[clothing] = model clothing.Parent = nil
                end
            end
        end
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") and body[part.Name] and part.Transparency < 1 then
                if throughWalls then
                    local copy = self.Clones[part]
                    if not copy then
                        local previous = part.Archivable part.Archivable = true
                        copy = part:Clone() part.Archivable = previous
                        if copy then
                            for _, obj in ipairs(copy:GetDescendants()) do
                                if obj:IsA("SpecialMesh") then obj.TextureId = "" obj.VertexColor = Vector3.new(1, 1, 1)
                                elseif not obj:IsA("DataModelMesh") and not obj:IsA("Bone") then obj:Destroy() end
                            end
                            copy.Anchored = true copy.CanCollide = false copy.CanTouch = false copy.CanQuery = false
                            if copy:IsA("MeshPart") then copy.TextureID = "" end
                            copy.Parent = world self.Clones[part] = copy
                        end
                    end
                    if copy then
                        copy.CFrame = part.CFrame copy.Size = part.Size copy.Color = color
                        copy.Reflectance = effects.Shader and math.clamp(effects.ShaderIntensity or 0.5, 0, 1) or 0
                        copy.Material = material copy.Transparency = transparency copy.LocalTransparencyModifier = 0
                    end
                else
                    if not self.Saved[part] then
                        local props = {Color = part.Color, Material = part.Material, Transparency = part.Transparency}
                        if part:IsA("MeshPart") then props.TextureID = part.TextureID end
                        self.Saved[part] = props
                    end
                    part.Color = color part.Material = material part.Transparency = transparency
                    if part:IsA("MeshPart") then part.TextureID = "" end
                    for _, obj in ipairs(part:GetDescendants()) do
                        if obj:IsA("SurfaceAppearance") then self.Surfaces[obj] = obj.Parent obj.Parent = nil
                        elseif obj:IsA("SpecialMesh") then
                            if not self.Saved[obj] then self.Saved[obj] = {TextureId = obj.TextureId, VertexColor = obj.VertexColor} end
                            obj.TextureId = "" obj.VertexColor = Vector3.new(1, 1, 1)
                        elseif obj:IsA("Decal") or obj:IsA("Texture") then
                            if not self.Saved[obj] then self.Saved[obj] = {Transparency = obj.Transparency} end
                            obj.Transparency = 1
                        end
                    end
                end
            end
        end
        for part, copy in pairs(self.Clones) do
            if part.Parent ~= model then copy:Destroy() self.Clones[part] = nil end
        end
    end
    function self:Destroy() self:SetEnabled(false) glow:Destroy() gui:Destroy() end
    return self
end
return M
]==],
    Extras = [=[
return function(S, H)
    local C = S.Config
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UIS = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    S.Adapter.Install(S, H)
    assert(loadstring(S.StaminaSource, "UrbanStamina"))()(S, H)
    assert(loadstring(S.AntiAimSource, "UrbanAntiAim"))()(S, H)
    local aa = S.Tabs.Utility:AddRightGroupbox("Anti aim")
    H.toggle(aa, "AntiAim", "Enabled")
    H.dropdown(aa, "AAPitchMode", "Pitch", {"Up", "Down", "Alternating", "Rotate", "Custom"})
    H.slider(aa, "AAPitch", "Custom pitch", -75, 70)
    H.dropdown(aa, "AAYawMode", "Yaw", {"None", "Backward", "Spin", "Jitter"})
    H.slider(aa, "AASpeed", "Rotation speed", 15, 720)
    local controls = S.Tabs.Combat:AddRightGroupbox("Weapon actions")
    H.toggle(controls, "HipFire", "Shoot without aiming")
    H.toggle(controls, "ShootRolling", "Shoot while rolling")
    H.toggle(controls, "RapidFire", "Rapid fire (client)")
    H.slider(controls, "FireMultiplier", "Fire-rate multiplier", 1, 5, 1)
    H.toggle(controls, "AutomaticSemi", "Automatic semi-auto")
    H.toggle(controls, "Triggerbot", "Triggerbot")
    H.toggle(controls, "AutoReload", "Automatic reload")
    H.slider(controls, "ReloadAt", "Reload below", 0, 25)
    local targeting = S.Tabs.Combat:AddLeftGroupbox("Target handling")
    H.toggle(targeting, "HitboxFallback", "Visible body fallback")
    H.toggle(targeting, "SkipProtected", "Skip protected players")
    local aura = S.Tabs.Combat:AddLeftGroupbox("Rage aura")
    H.toggle(aura, "RageAura", "Enabled")
    H.slider(aura, "AuraRange", "Range (studs)", 5, 500)
    local player = S.Tabs.Utility:AddLeftTabbox()
    S.UtilityTabbox = player
    local camControls = player:AddTab("Camera")
    H.toggle(camControls, "FirstPerson", "First person")
    H.toggle(camControls, "ThirdPerson", "Custom third person")
    H.slider(camControls, "CameraDistance", "Distance", 2, 20, 1)
    H.slider(camControls, "CameraShoulder", "Shoulder", -4, 4, 1)
    H.slider(camControls, "CameraHeight", "Height", -2, 4, 1)
    local vm = player:AddTab("Weapon")
    H.toggle(vm, "ViewmodelOffset", "Weapon offset")
    H.slider(vm, "ViewX", "X", -3, 3, 2)
    H.slider(vm, "ViewY", "Y", -3, 3, 2)
    H.slider(vm, "ViewZ", "Z", -3, 3, 2)
    vm:AddButton({Text = "Reset offsets", Func = function()
        for _, id in ipairs({"ViewX", "ViewY", "ViewZ"}) do getgenv().Options["UR_" .. id]:SetValue(0) end
    end})
    local hop = player:AddTab("Movement")
    H.toggle(hop, "InfiniteStamina", "Infinite stamina")
    local hopToggle = H.toggle(hop, "BunnyHop", "Bunny hop")
    S.HopActivation = H.keybind(hopToggle, "HopActivation", "Bunny hop activation", "Space", "Hold")
    H.toggle(hop, "HopBoost", "Local speed boost")
    H.slider(hop, "HopSpeed", "Speed", 16, 60)

    local sky = S.Tabs.Visuals:AddRightGroupbox("World")
    H.inlineColor(H.toggle(sky, "SkyEnabled", "Custom sky"), "SkyTint", "World tint")
    local folder = Instance.new("Folder")
    local original = Lighting:FindFirstChildOfClass("Sky")
    local preset = original and original:Clone() or Instance.new("Sky")
    preset.Name = "Original" preset.Parent = folder
    preset = Instance.new("Sky") preset.Name = "Default" preset.Parent = folder
    local faces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
    local presets = {
        ["Blue clouds"] = {135483466,135483484,135483461,135483495,135483499,135483475},
        ["Purple nebula"] = {159454299,159454296,159454293,159454286,159454300,159454288},
        ["Sunset"] = {600830446,600831635,600832720,600886090,600833862,600835177},
        ["Starry night"] = {12064107,12064152,12064121,12063984,12064115,12064131},
    }
    for name, ids in pairs(presets) do
        local obj = Instance.new("Sky") obj.Name = name
        for i, face in ipairs(faces) do obj[face] = "rbxassetid://" .. ids[i] end
        obj.CelestialBodiesShown = name ~= "Purple nebula" obj.Parent = folder
    end
    local names = {}
    for _, obj in ipairs(folder:GetChildren()) do table.insert(names, obj.Name) end
    table.sort(names)
    if not table.find(names, C.SkyPreset) then C.SkyPreset = "Original" end
    H.dropdown(sky, "SkyPreset", "Sky preset", names)
    H.slider(sky, "SkyTime", "Time of day", 0, 24, 1)
    H.slider(sky, "SkyBrightness", "Brightness", 0, 5, 1)
    H.toggle(sky, "NoFog", "No fog")
    local fields = table.clone(faces)
    for _, name in ipairs({"SunTextureId", "MoonTextureId", "CelestialBodiesShown", "SunAngularSize", "MoonAngularSize", "StarCount"}) do table.insert(fields, name) end
    local savedSky, savedLighting = {}, nil
    local colorEffect, createdSky
    local function restoreWorld()
        for obj, props in pairs(savedSky) do if obj.Parent then
            for key, value in pairs(props) do pcall(function() obj[key] = value end) end
        end end
        table.clear(savedSky)
        if savedLighting then for key, value in pairs(savedLighting) do Lighting[key] = value end savedLighting = nil end
        if colorEffect then colorEffect:Destroy() colorEffect = nil end
        if createdSky then createdSky:Destroy() createdSky = nil end
    end
    local function worldStep()
        if not C.SkyEnabled then if savedLighting then restoreWorld() end return end
        if not savedLighting then savedLighting = {ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart} end
        local current = Lighting:FindFirstChildOfClass("Sky")
        if not current then current = Instance.new("Sky") current.Parent = Lighting createdSky = current end
        if not savedSky[current] then
            savedSky[current] = {}
            for _, key in ipairs(fields) do savedSky[current][key] = current[key] end
        end
        local template = folder:FindFirstChild(C.SkyPreset)
        if template then for _, key in ipairs(fields) do current[key] = template[key] end end
        Lighting.ClockTime = C.SkyTime Lighting.Brightness = C.SkyBrightness
        Lighting.FogEnd = C.NoFog and 1000000 or savedLighting.FogEnd
        Lighting.FogStart = C.NoFog and 1000000 or savedLighting.FogStart
        if not colorEffect then colorEffect = Instance.new("ColorCorrectionEffect") colorEffect.Name = "UrbanWorldTint" colorEffect.Parent = Lighting end
        colorEffect.TintColor = C.SkyTint
    end
    local visibility, gripSaved = {}, nil
    local speedHumanoid, speedSaved
    local function restoreVisibility()
        for part, value in pairs(visibility) do if part.Parent then part.LocalTransparencyModifier = value end end
        table.clear(visibility)
    end
    local function restoreGrip()
        if gripSaved and gripSaved.Joint.Parent then gripSaved.Joint.C0 = gripSaved.C0 end
        gripSaved = nil
    end
    local function restoreSpeed()
        if speedHumanoid and speedHumanoid.Parent then speedHumanoid.WalkSpeed = speedSaved end
        speedHumanoid, speedSaved = nil, nil
    end
    local function cameraStep()
        setthreadidentity(8)
        local cam, char = workspace.CurrentCamera, LP.Character
        local head = char and char:FindFirstChild("Head")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not cam or not head or not humanoid or humanoid.Health <= 0 then restoreVisibility() return end
        local state = S.Adapter.ClientState
        if state and (state.Spectating or state.WardrobeOpen or state.FixedCamera or state.RobloxCamera or state.Vehicle) then
            restoreVisibility() return
        end
        if C.FirstPerson then
            cam.CFrame = CFrame.new(head.Position + Vector3.new(0, 0.15, 0)) * cam.CFrame.Rotation
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") and (obj == head or obj:FindFirstAncestorOfClass("Accessory")) then
                    if visibility[obj] == nil then visibility[obj] = obj.LocalTransparencyModifier end
                    obj.LocalTransparencyModifier = 1
                end
            end
        elseif C.ThirdPerson then
            restoreVisibility()
            local pivot = head.Position + Vector3.new(0, C.CameraHeight, 0)
            local delta = cam.CFrame.RightVector * C.CameraShoulder - cam.CFrame.LookVector * C.CameraDistance
            local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = {char, cam}
            local hit = workspace:Spherecast(pivot, 0.25, delta, params)
            local position = hit and pivot + delta.Unit * math.max(hit.Distance - 0.2, 0) or pivot + delta
            cam.CFrame = CFrame.new(position) * cam.CFrame.Rotation
        else restoreVisibility() end
        if C.ViewmodelOffset then
            local tool = S.Adapter.Action:GetWModel()
            if tool then for _, joint in ipairs(char:GetDescendants()) do
                if joint:IsA("Motor6D") and joint.Part1 and joint.Part1:IsDescendantOf(tool) then
                    gripSaved = {Joint = joint, C0 = joint.C0}
                    joint.C0 = joint.C0 * CFrame.new(C.ViewX, C.ViewY, C.ViewZ)
                    break
                end
            end end
        end
    end
    RunService:BindToRenderStep("UrbanOffsetReset", Enum.RenderPriority.First.Value + 1, function()
        if S.Loaded then pcall(restoreGrip) end
    end)
    RunService:BindToRenderStep("UrbanCameraExtras", Enum.RenderPriority.Camera.Value + 110, function()
        if not S.Loaded then return end
        local ok, err = xpcall(cameraStep, debug.traceback)
        if not ok then H.recordError("CameraExtras", err) end
    end)
    local lastWorld = 0
    table.insert(S.Connections, RunService.Heartbeat:Connect(function()
        if not S.Loaded then return end
        local ok, err = xpcall(function()
            setthreadidentity(8)
            S.MenuVisible = S.Window.Holder.Visible
            if os.clock() - lastWorld >= 0.25 then lastWorld = os.clock() worldStep() end
            local h = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            local enabled = C.BunnyHop and h and h.Health > 0 and not S.Window.Holder.Visible
                and not UIS:GetFocusedTextBox() and (S.HopActivation:GetState())
            if enabled and h.MoveDirection.Magnitude > 0.05 then
                if C.HopBoost then
                    if speedHumanoid ~= h then restoreSpeed() speedHumanoid = h speedSaved = h.WalkSpeed end
                    h.WalkSpeed = C.HopSpeed
                else restoreSpeed() end
                if h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
            else restoreSpeed() end
        end, debug.traceback)
        if not ok then H.recordError("Extras", err) end
    end))
    function S.CleanupExtras()
        if S.CleanupAntiAim then S.CleanupAntiAim() end
        RunService:UnbindFromRenderStep("UrbanOffsetReset")
        RunService:UnbindFromRenderStep("UrbanCameraExtras")
        restoreGrip() restoreSpeed() restoreVisibility() restoreWorld() folder:Destroy()
    end
    S.WorldMaintenance = worldStep
end
]=],
}
local function start()
getgenv().UrbanLastError = nil

assert(game.GameId == 10769552054, "Unexpected experience: this build targets Urban")
local env = getgenv()
local previousConfig = env.UrbanHub and table.clone(env.UrbanHub.Config)
if env.UrbanHub and env.UrbanHub.NativeTargets then env.UrbanNativeTargets = env.UrbanHub.NativeTargets end
if env.UrbanHub and env.UrbanHub.Unload then env.UrbanHub.Unload() end

local librarySource = Sources.Library
local Library = assert(loadstring(librarySource, "LinoriaLib"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Adapter = assert(loadstring(Sources.Adapter, "UrbanAdapter"))()
local ShotClient = Adapter.ShotClient
local EntityClient = Adapter.EntityClient
local Hitboxes = Adapter.Hitboxes
local GlobalStuff = Adapter.GlobalStuff

local C = {
    AntiAim = false, AAPitchMode = "Up", AAPitch = 70, AAYawMode = "None", AASpeed = 90, SilentAim = false, Camlock = false, LockAlways = false, RageAura = false, AuraRange = 100,
    Radius = 160, FullFOV = false, Zone = "Head", Priority = "Crosshair",
    Sticky = false, Prediction = 0, Smoothness = 14, HitChance = 100,
    ShowFOV = false, TargetLine = false, Chams = false, Skeletons = false,
    Boxes = false, Names = false, Health = false, Distance = false,
    ThroughWalls = false, VisualDistance = 2000, GunChams = false,
    NoRecoil = false, NoSpread = false, HipFire = false, ShootRolling = false, FirstPerson = false,
    ChamsColor = Color3.fromRGB(255, 85, 125), ChamsMaterial = "Neon", ChamsTransparency = 0.25,
    SkeletonColor = Color3.fromRGB(255, 85, 125), BoxColor = Color3.fromRGB(255, 85, 125),
    NameColor = Color3.new(1, 1, 1), DistanceColor = Color3.new(1, 1, 1), HealthColor = Color3.fromRGB(90, 255, 130),
    FOVColor = Color3.fromRGB(100, 225, 255), TracerColor = Color3.fromRGB(100, 225, 255),
    EnemyColor = Color3.fromRGB(255, 85, 125),
    TargetColor = Color3.fromRGB(100, 225, 255),
    GunColor = Color3.fromRGB(145, 100, 255), GunMaterial = "Neon",
    RapidFire = false, FireMultiplier = 2, AutomaticSemi = false, Triggerbot = false, AutoReload = false, ReloadAt = 5, HitboxFallback = false, SkipProtected = false,
    SkyEnabled = false, SkyPreset = "Original", SkyTime = 14, SkyBrightness = 2,
    SkyTint = Color3.new(1, 1, 1), NoFog = false,
    ThirdPerson = false, CameraDistance = 9, CameraShoulder = 1.5, CameraHeight = 0.7,
    ViewmodelOffset = false, ViewX = 0, ViewY = 0, ViewZ = 0,
    InfiniteStamina = false, BunnyHop = false, HopAlways = false, HopBoost = false, HopSpeed = 32,
}
if previousConfig then
    for k, v in pairs(previousConfig) do
        if C[k] ~= nil and typeof(v) ~= "boolean" and typeof(C[k]) == typeof(v) then C[k] = v end
    end
end
env.UrbanKeybinds = env.UrbanKeybinds or {}
local S = {
    Config = C, Library = Library, Loaded = true, MenuVisible = true, Hooks = {}, Drawings = {},
    Connections = {}, Visuals = {}, GunOriginals = {}, Calls = 0, Redirects = 0,
    Errors = {}, Target = nil, FrameCount = 0, GunSurfaces = {},
}
env.UrbanHub = S
S.Adapter = Adapter
S.StaminaSource = Sources.Stamina
S.AntiAimSource = Sources.AntiAim
S.HeldCosmeticsSource = Sources.HeldCosmetics

local function recordError(section, err)
    local e = S.Errors[section] or {Count = 0}
    e.Count += 1
    e.Message = tostring(err)
    S.Errors[section] = e
end

local function drawing(kind, values)
    local d = Drawing.new(kind)
    table.insert(S.Drawings, d)
    for k, v in pairs(values) do d[k] = v end
    return d
end

local function hook(fn, replacement)
    local original = hookfunction(fn, replacement)
    table.insert(S.Hooks, fn)
    return original
end

local function camera() return workspace.CurrentCamera end
local function enemy(model)
    return model and model.Parent and not model:GetAttribute("KillPredicted")
        and GlobalStuff:CanHit(LP, model, true)
end

local function worldParams()
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.CollisionGroup = "Bullet"
    p.FilterDescendantsInstances = ShotClient:Exclude()
    return p
end

local function selectTarget(origin, range, params, poses, ignore)
    local cam = camera()
    if not cam or typeof(origin) ~= "Vector3" then return nil end
    local center = cam.ViewportSize / 2
    local best, bestScore
    for _, pose in ipairs(poses or ShotClient:GetPoses()) do
        local model = pose.Model
        if enemy(model) and not (ignore and ignore[model]) then
            local point = C.HitboxFallback and Adapter.VisiblePoint(model, origin, params, C.Zone) or Hitboxes.ZoneCenter(pose, C.Zone)
            if typeof(point) == "Vector3" then
                local basePoint = point
                if C.Prediction > 0 then
                    local velocity = EntityClient:GetVelocity(model)
                    if typeof(velocity) == "Vector3" then point += velocity * C.Prediction end
                end
                local projected, onScreen = cam:WorldToViewportPoint(basePoint)
                local delta = point - origin
                local distance = delta.Magnitude
                local screenDistance = (Vector2.new(projected.X, projected.Y) - center).Magnitude
                if distance > 0.001 and distance <= (range or 1000)
                    and (C.FullFOV or (onScreen and projected.Z > 0 and screenDistance <= C.Radius)) then
                    
                    local hit = Adapter.CastVisibility(origin, basePoint - origin, params)
                    if not hit or hit.Instance:IsDescendantOf(model)
                        or hit.Distance >= (basePoint - origin).Magnitude - 0.1 then
                        local score = screenDistance
                        if C.Priority == "Distance" then score = distance end
                        if C.Priority == "Lowest health" then score = Adapter.Health(model) end
                        if C.Sticky and S.Target == model then score -= 100000 end
                        if not bestScore or score < bestScore then
                            bestScore = score
                            best = {Model = model, Point = point, Direction = delta.Unit, Distance = distance}
                        end
                    end
                end
            end
        end
    end
    return best
end

local function restoreGun()
    for obj, props in pairs(S.GunOriginals) do
        if obj.Parent then pcall(function() for k, v in pairs(props) do obj[k] = v end end) end
    end
    table.clear(S.GunOriginals)
    for surface, parent in pairs(S.GunSurfaces) do
        if parent.Parent then pcall(function() surface.Parent = parent end) end
    end
    table.clear(S.GunSurfaces)
    if S.GunHighlight then S.GunHighlight:Destroy() S.GunHighlight = nil end
    S.GunModel = nil
end

local function removeVisual(v)
    if v.Chams then v.Chams:Destroy() end
    for _, d in ipairs(v.Drawings) do pcall(function() d:Remove() end) end
    
    for i = #S.Drawings, 1, -1 do
        if v.Owned[S.Drawings[i]] then table.remove(S.Drawings, i) end
    end
end

local function cleanup()
    if not S.Loaded then return end
    S.Loaded = false
    setthreadidentity(8)
    if S.CleanupExtras then pcall(S.CleanupExtras) end
    if S.RestoreNamecall then pcall(S.RestoreNamecall) end
    RunService:UnbindFromRenderStep("UrbanLinoriaCamera")
    for _, connection in ipairs(S.Connections) do connection:Disconnect() end
    for i = #S.Hooks, 1, -1 do pcall(restorefunction, S.Hooks[i]) end
    setthreadidentity(8)
    restoreGun()
    for _, v in pairs(S.Visuals) do if v.Chams then v.Chams:Destroy() end end
    for _, d in ipairs(S.Drawings) do pcall(function() d:Remove() end) end
    table.clear(S.Visuals)
    table.clear(S.Drawings)
    S.Target = nil
end
function S.Unload()
    if not S.Loaded then return end
    cleanup()
    Library:Unload()
end
Library:OnUnload(cleanup)

local function build()
    Library.MainColor = Color3.fromRGB(25, 26, 33)
    Library.BackgroundColor = Color3.fromRGB(17, 18, 24)
    Library.OutlineColor = Color3.fromRGB(46, 48, 60)
    Library.AccentColor = Color3.fromRGB(144, 125, 255)
    local Window = Library:CreateWindow({Title = "Axis", Center = true, AutoShow = true,
        Size = UDim2.fromOffset(620, 610), TabPadding = 14, MenuFadeTime = 0.12})
    S.Window = Window
    local aim = Window:AddTab("Combat")
    local visuals = Window:AddTab("Visuals")
    local utility = Window:AddTab("Utility")
    S.Tabs = {Combat = aim, Visuals = visuals, Utility = utility}
    S.Bindings = {}
    local function keybind(parent, id, text, default, mode)
        local saved = env.UrbanKeybinds[id]
        parent:AddKeyPicker("UR_" .. id, {Default = saved or default or "None", Mode = mode or "Toggle",
            Modes = {mode or "Toggle"}, Text = text, NoUI = true, SyncToggleState = false})
        local picker = env.Options["UR_" .. id]
        picker:OnChanged(function() env.UrbanKeybinds[id] = picker.Value end)
        S.Bindings[id] = picker
        return picker
    end
    local majorBindings = {SilentAim = true, ThirdPerson = true, FirstPerson = true, Triggerbot = true}
    S.Materials = {"SmoothPlastic", "Plastic", "Neon", "ForceField", "Glass", "Metal", "DiamondPlate", "Foil", "CorrodedMetal", "Wood", "WoodPlanks", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Ice", "Sand", "Fabric", "Grass", "Pebble"}
    local function toggle(group, id, text)
        local t = group:AddToggle("UR_" .. id, {Text = text, Default = C[id]})
        local picker
        if majorBindings[id] then
            picker = keybind(t, id .. "Key", text, "None", "Toggle")
            picker:OnClick(function()
                if not UIS:GetFocusedTextBox() then t:SetValue(not t.Value) end
            end)
        end
        t:OnChanged(function()
            C[id] = t.Value
            if picker then picker.Toggled = t.Value end
        end)
        return t
    end
    local function slider(group, id, text, minimum, maximum, rounding)
        group:AddSlider("UR_" .. id, {Text = text, Default = C[id], Min = minimum, Max = maximum, Rounding = rounding or 0})
        local o = env.Options["UR_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end
    local function dropdown(group, id, text, values)
        group:AddDropdown("UR_" .. id, {Text = text, Values = values, Default = C[id]})
        local o = env.Options["UR_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end
    local function color(group, id, text)
        group:AddLabel(text):AddColorPicker("UR_" .. id, {Default = C[id], Title = text})
        local o = env.Options["UR_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end

    local function inlineColor(control, id, title)
        control:AddColorPicker("UR_" .. id, {Default = C[id], Title = title})
        local option = env.Options["UR_" .. id]
        option:OnChanged(function() C[id] = option.Value end)
        return control
    end
    local silent = aim:AddLeftGroupbox("Silent aim")
    S.SilentToggle = toggle(silent, "SilentAim", "Enabled")
    slider(silent, "Radius", "FOV radius", 20, 800)
    slider(silent, "HitChance", "Hit chance (%)", 0, 100)
    dropdown(silent, "Zone", "Hitbox", {"Head", "Torso"})
    inlineColor(toggle(silent, "ShowFOV", "Draw FOV"), "FOVColor", "Draw FOV")
    inlineColor(toggle(silent, "TargetLine", "Target tracer"), "TracerColor", "Target tracer")
    local lock = aim:AddRightGroupbox("Camlock")
    local camlockToggle = toggle(lock, "Camlock", "Enabled")
    S.CamActivation = keybind(camlockToggle, "CamActivation", "Camlock activation", "MB2", "Hold")
    C.CamlockType = "Camera"
    dropdown(lock, "CamlockType", "Type", {"Camera", "Mouse"})
    slider(lock, "Smoothness", "Response", 1, 40)
    local targeting = aim:AddLeftGroupbox("Targeting")
    toggle(targeting, "FullFOV", "360-degree FOV")
    toggle(targeting, "Sticky", "Sticky target")
    dropdown(targeting, "Priority", "Priority", {"Crosshair", "Distance", "Lowest health"})
    slider(targeting, "Prediction", "Prediction", 0, 0.35, 2)

    local esp = visuals:AddLeftGroupbox("Enemy ESP")
    inlineColor(toggle(esp, "Chams", "Enemy chams"), "ChamsColor", "Enemy chams")
    inlineColor(toggle(esp, "Skeletons", "Skeletons"), "SkeletonColor", "Skeletons")
    inlineColor(toggle(esp, "Boxes", "2D boxes"), "BoxColor", "2D boxes")
    inlineColor(toggle(esp, "Names", "Names"), "NameColor", "Names")
    inlineColor(toggle(esp, "Health", "Health bars"), "HealthColor", "Health bars")
    inlineColor(toggle(esp, "Distance", "Distance labels"), "DistanceColor", "Distance labels")
    toggle(esp, "ThroughWalls", "Through walls")
    slider(esp, "VisualDistance", "Render distance", 100, 5000)
    C.Glow = false C.ShaderChams = false
    C.GlowColor = Color3.fromRGB(65,155,255) C.ShaderColor = Color3.fromRGB(65,155,255)
    C.GlowIntensity = 0.7 C.ShaderIntensity = 0.5
    inlineColor(toggle(esp, "Glow", "Glow"), "GlowColor", "Glow")
    slider(esp, "GlowIntensity", "Glow intensity", 0, 1, 2)
    inlineColor(toggle(esp, "ShaderChams", "Shader chams"), "ShaderColor", "Shader chams")
    slider(esp, "ShaderIntensity", "Shader intensity", 0, 1, 2)
    dropdown(esp, "ChamsMaterial", "Chams material", S.Materials)
    slider(esp, "ChamsTransparency", "Chams transparency", 0, 0.9, 2)
    local gun = visuals:AddRightGroupbox("Weapon")
    inlineColor(toggle(gun, "GunChams", "Gun chams"), "GunColor", "Gun chams")
    dropdown(gun, "GunMaterial", "Material", S.Materials)
    local controls = aim:AddRightGroupbox("Weapon")
    toggle(controls, "NoRecoil", "No recoil")
    toggle(controls, "NoSpread", "No spread")
    local menu = utility:AddRightGroupbox("Interface")
    Library.ToggleKeybind = keybind(menu:AddLabel("Menu key"), "MenuKey", "Menu", "RightShift", "Toggle")
    local unloadKey = keybind(menu:AddLabel("Unload key"), "UnloadKey", "Unload", "None", "Toggle")
    unloadKey:OnClick(function() if not UIS:GetFocusedTextBox() then S.Unload() end end)
    function S.DisableAll()
        for id, value in pairs(C) do
            if typeof(value) == "boolean" then
                local control = env.Toggles["UR_" .. id]
                if control then control:SetValue(false) else C[id] = false end
            end
        end
    end
    function S.SyncControls()
        for id, value in pairs(C) do
            if typeof(value) == "boolean" then
                local control = env.Toggles["UR_" .. id]
                if control then C[id] = control.Value end
            end
        end
    end
    menu:AddButton({Text = "Disable all", Func = S.DisableAll})
    menu:AddButton({Text = "Unload", Func = S.Unload})
    Library:SetWatermarkVisibility(false)
    Library.KeybindFrame.Visible = false

    local originalAim
    originalAim = hook(ShotClient.AimDirection, function(self, origin, range, params, poses, ignore, ...)
        S.Calls += 1
        if S.Loaded and C.RageAura then
            local ok, target = pcall(Adapter.SelectAura, origin, math.min(C.AuraRange, range or C.AuraRange), params)
            S.AuraTarget = ok and target or nil
            if ok and target then
                S.Redirects += 1
                S.AuraRedirects = (S.AuraRedirects or 0) + 1
                return target.Direction
            elseif not ok then recordError("Aura", target) end
        end

        if S.Loaded and (C.SilentAim or C.Triggerbot) and math.random(1, 100) <= C.HitChance then
            local ok, target = pcall(selectTarget, origin, range, params, poses, ignore)
            if ok and target then
                S.Target = target.Model
                S.Redirects += 1
                return target.Direction
            elseif not ok then recordError("Aim", target) end
        end
        return originalAim(self, origin, range, params, poses, ignore, ...)
    end)
    setthreadidentity(8)

    local fov = drawing("Circle", {Visible = false, Filled = false, NumSides = 64, Thickness = 1, Transparency = 0.8})
    local tracer = drawing("Line", {Visible = false, Thickness = 1.5, Transparency = 0.9})
    local skeletonLinks = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
    }
    local MaterialChams = assert(loadstring(Sources.Chams, "MaterialChams"))()
    local function createVisual(model)
        local v = {Drawings = {}, Owned = {}, Bones = {}, Model = model, Parts = {}}
        local function add(kind, values)
            local d = drawing(kind, values)
            table.insert(v.Drawings, d)
            v.Owned[d] = true
            return d
        end
        v.Box = add("Square", {Visible = false, Filled = false, Thickness = 1, Transparency = 1})
        v.Text = add("Text", {Visible = false, Center = true, Outline = true, Size = 13, Font = 2, Transparency = 1})
        v.DistanceText = add("Text", {Visible = false, Center = true, Outline = true, Size = 13, Font = 2, Transparency = 1})
        v.HealthBack = add("Line", {Visible = false, Thickness = 4, Color = Color3.new(), Transparency = 1})
        v.HealthLine = add("Line", {Visible = false, Thickness = 2, Transparency = 1})
        for _, link in ipairs(skeletonLinks) do
            table.insert(v.Bones, {A = link[1], B = link[2], Line = add("Line", {Visible = false, Thickness = 1, Transparency = 1})})
        end
        v.Chams = MaterialChams.new(model, Library.ScreenGui)
        S.Visuals[model] = v
        return v
    end
    local function part(v, name)
        local p = v.Parts[name]
        if not p or not p.Parent then
            p = v.Model:FindFirstChild(name)
            if p and p:IsA("BasePart") then v.Parts[name] = p else return nil end
        end
        return p
    end
    local function project(cam, point)
        local p, shown = cam:WorldToViewportPoint(point)
        return Vector2.new(p.X, p.Y), shown and p.Z > 0
    end
    local function drawEnemy(cam, model, v, origin, params)
        setthreadidentity(8)
        for _, d in ipairs(v.Drawings) do d.Visible = false end
        local isEnemy = enemy(model)
        
        setthreadidentity(8)
        if not isEnemy then v.Chams:SetEnabled(false) return end
        local root = part(v, "HumanoidRootPart") or part(v, "Torso")
        if not root then v.Chams:SetEnabled(false) return end
        local distance = (root.Position - origin).Magnitude
        if distance > C.VisualDistance then v.Chams:SetEnabled(false) return end
        local head = part(v, "Head")
        local destination = head and head.Position or root.Position
        local hit = Adapter.CastVisibility(origin, destination - origin, params)
        setthreadidentity(8)
        local visible = not hit or hit.Instance:IsDescendantOf(model) or hit.Distance >= (destination - origin).Magnitude - 0.1
        if not visible and not C.ThroughWalls then v.Chams:SetEnabled(false) return end
        if C.Chams or C.Glow or C.ShaderChams then v.Chams:Update(cam, C.ChamsColor, C.ChamsMaterial, C.ChamsTransparency, C.ThroughWalls, {Base=C.Chams,Glow=C.Glow,GlowColor=C.GlowColor,GlowIntensity=C.GlowIntensity,Shader=C.ShaderChams,ShaderColor=C.ShaderColor,ShaderIntensity=C.ShaderIntensity})
        else v.Chams:SetEnabled(false) end
        local rootScreen, rootVisible = project(cam, root.Position)
        if not rootVisible then return end
        local top, topVisible = project(cam, destination + Vector3.new(0, 1, 0))
        local bottom, bottomVisible = project(cam, root.Position - Vector3.new(0, 3.2, 0))
        if topVisible and bottomVisible then
            local height = math.max(math.abs(bottom.Y - top.Y), 4)
            local width = height * 0.55
            local corner = Vector2.new(rootScreen.X - width / 2, math.min(top.Y, bottom.Y))
            v.Box.Position = corner v.Box.Size = Vector2.new(width, height) v.Box.Color = C.BoxColor v.Box.Visible = C.Boxes
            local health, maximum = Adapter.Health(model)
            local ratio = math.clamp(health / math.max(maximum, 1), 0, 1)
            local topLeft = corner - Vector2.new(5, 0)
            v.HealthBack.From = topLeft v.HealthBack.To = topLeft + Vector2.new(0, height) v.HealthBack.Visible = C.Health
            v.HealthLine.From = topLeft + Vector2.new(0, height)
            v.HealthLine.To = topLeft + Vector2.new(0, height * (1 - ratio))
            v.HealthLine.Color = C.HealthColor v.HealthLine.Visible = C.Health
            local owner = Players:GetPlayerFromCharacter(model)
            v.Text.Text = owner and owner.DisplayName or model.Name
            v.Text.Position = Vector2.new(rootScreen.X, corner.Y - 16)
            v.Text.Color = C.NameColor v.Text.Visible = C.Names
            v.DistanceText.Text = tostring(math.floor(distance)) .. " st"
            v.DistanceText.Position = Vector2.new(rootScreen.X, corner.Y + height + 2)
            v.DistanceText.Color = C.DistanceColor v.DistanceText.Visible = C.Distance

        end
        if C.Skeletons then
            for _, bone in ipairs(v.Bones) do
                local a, b = part(v, bone.A), part(v, bone.B)
                if a and b then
                    local pa, shownA = project(cam, a.Position)
                    local pb, shownB = project(cam, b.Position)
                    if shownA and shownB then bone.Line.From = pa bone.Line.To = pb bone.Line.Color = C.SkeletonColor bone.Line.Visible = true end
                end
            end
        end
    end

    local function weaponMaintenance()
        if S.AdapterMaintenance then S.AdapterMaintenance() end
        local action = Adapter.Action
        local model = action:GetWModel()
        setthreadidentity(8)
        if not C.GunChams or not model or not model.Parent then
            if next(S.GunOriginals) or next(S.GunSurfaces) or S.GunHighlight then restoreGun() end
            return
        end
        if S.GunModel ~= model then restoreGun() S.GunModel = model end
        for obj, props in pairs(S.GunOriginals) do
            if not obj:IsDescendantOf(model) then
                if obj.Parent then pcall(function() for k, v in pairs(props) do obj[k] = v end end) end
                S.GunOriginals[obj] = nil
            end
        end
        for _, obj in ipairs(model:GetDescendants()) do
            if S.EquippedCosmeticModel and obj:IsDescendantOf(S.EquippedCosmeticModel) then continue end
            if obj:IsA("BasePart") then
                if not S.GunOriginals[obj] then
                    local props = {Color = obj.Color, Material = obj.Material, Reflectance = obj.Reflectance}
                    if obj:IsA("MeshPart") then props.TextureID = obj.TextureID end
                    S.GunOriginals[obj] = props
                end
                obj.Color = C.GunColor obj.Material = Enum.Material[C.GunMaterial] obj.Reflectance = 0
                if obj:IsA("MeshPart") then obj.TextureID = "" end
            elseif obj:IsA("SurfaceAppearance") then
                S.GunSurfaces[obj] = obj.Parent
                obj.Parent = nil
            elseif obj:IsA("SpecialMesh") then
                if not S.GunOriginals[obj] then S.GunOriginals[obj] = {TextureId = obj.TextureId, VertexColor = obj.VertexColor} end
                obj.TextureId = "" obj.VertexColor = Vector3.new(1, 1, 1)
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if not S.GunOriginals[obj] then S.GunOriginals[obj] = {Transparency = obj.Transparency} end
                obj.Transparency = 1
            end
        end

    end

    local lastMaintenance = 0
    local aimParams = worldParams()
    table.insert(S.Connections, RunService.RenderStepped:Connect(function()
        if not S.Loaded then return end
        local ok, err = xpcall(function()
            S.FrameCount += 1
            S.SyncControls()
            local cam = camera()
            if not cam then return end
            local now = os.clock()
            if now - lastMaintenance >= 0.25 then
                lastMaintenance = now
                aimParams = worldParams()
                local maintained, maintenanceError = pcall(weaponMaintenance)
                if not maintained then recordError("Weapon", maintenanceError) end
                local records = EntityClient:GetRecords()
                local espEnabled = C.Glow or C.ShaderChams or C.Chams or C.Skeletons or C.Boxes or C.Names or C.Health or C.Distance
                for model, v in pairs(S.Visuals) do
                    if not espEnabled or not model.Parent or not records[model] then removeVisual(v) S.Visuals[model] = nil end
                end
                if espEnabled then for model, rec in pairs(records) do
                    if not rec.IsLocal and model.Parent and not S.Visuals[model] then createVisual(model) end
                end
                end
            end
            local origin = ShotClient:Origin() or cam.CFrame.Position
            local needsTarget = C.SilentAim or C.Camlock or C.TargetLine or C.Triggerbot
            S.CurrentTarget = needsTarget and selectTarget(origin, 1000, aimParams, nil, ShotClient:Ignore()) or nil
            setthreadidentity(8)
            S.Target = S.CurrentTarget and S.CurrentTarget.Model or nil
            local center = cam.ViewportSize / 2
            fov.Position = center fov.Radius = C.Radius fov.Color = C.FOVColor fov.Visible = C.ShowFOV and not C.FullFOV
            tracer.Visible = false
            if C.TargetLine and S.CurrentTarget then
                local targetScreen, shown = project(cam, S.CurrentTarget.Point)
                if shown then tracer.From = center tracer.To = targetScreen tracer.Color = C.TracerColor tracer.Visible = true end
            end
            for model, v in pairs(S.Visuals) do drawEnemy(cam, model, v, origin, aimParams) end
        end, debug.traceback)
        if not ok then recordError("Render", err) end
    end))
    function S.StepCamera(dt)
        if C.RageAura then return end
        if not S.Loaded or not C.Camlock or Window.Holder.Visible or UIS:GetFocusedTextBox() then return end
        if not S.CamActivation:GetState() then return end
        local target, cam = S.CurrentTarget, camera()
        if target and cam then
            local direction = target.Point - cam.CFrame.Position
            if direction.Magnitude > 0.001 then
                local alpha = 1 - math.exp(-C.Smoothness * math.min(dt, 0.1))
                if C.CamlockType == "Mouse" then
                    local screen, shown = cam:WorldToViewportPoint(target.Point)
                    if shown and mousemoverel then
                        local mouse = UIS:GetMouseLocation() - game:GetService("GuiService"):GetGuiInset()
                        mousemoverel((screen.X - mouse.X) * alpha, (screen.Y - mouse.Y) * alpha)
                    end
                else
                    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, target.Point), alpha)
                end
            end
        end
    end
    RunService:BindToRenderStep("UrbanLinoriaCamera", Enum.RenderPriority.Camera.Value + 100, S.StepCamera)
    S.SelectTarget = selectTarget
    S.WorldParams = worldParams
    S.WeaponMaintenance = weaponMaintenance
    S.RestoreGunAppearance = restoreGun
    local extend = assert(loadstring(Sources.Extras, "UrbanExtras"))()
    extend(S, {toggle = toggle, slider = slider, dropdown = dropdown, color = color,
        inlineColor = inlineColor, keybind = keybind, hook = hook, recordError = recordError, worldParams = worldParams})

end

local ok, err = xpcall(build, debug.traceback)
if not ok then
    S.LastBuildError = tostring(err)
    pcall(S.Unload)
    error(err)
end

end
local success, failure = xpcall(start, debug.traceback)
if not success then
    getgenv().UrbanLastError = tostring(failure)
end
