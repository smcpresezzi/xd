

local Sources = {
    Library = [=[return assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/087d501b05f37c149cedabddbbaa96bc9eee81e7/source/game-bridge.lua"), "Axis UI bridge"))()]=],
    Adapter = [=[
local A = {}
local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local function combatant(model)
    if not model then return false end
    if Players:GetPlayerFromCharacter(model) then return true end
    local bots = workspace:FindFirstChild("BotCharacters")
    local range = workspace:FindFirstChild("Shooting Range")
    local dummies = range and range:FindFirstChild("Dummies")
    return bots and model:IsDescendantOf(bots) or dummies and model:IsDescendantOf(dummies)
end
local function records()
    local out = {}
    local function add(model, player)
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and model:FindFirstChild("Head") and model:FindFirstChild("HumanoidRootPart") then
            out[model] = {IsLocal = player == LP, Player = player, IsNPC = player == nil}
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do add(player.Character, player) end
    local bots = workspace:FindFirstChild("BotCharacters")
    if bots then for _, model in ipairs(bots:GetChildren()) do add(model) end end
    local range = workspace:FindFirstChild("Shooting Range")
    local dummies = range and range:FindFirstChild("Dummies")
    if dummies then for _, model in ipairs(dummies:GetChildren()) do add(model) end end
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
local safeParts, nextZones = {}, 0
local protectedCache = setmetatable({}, {__mode="k"})
function A.IsProtected(model)
    if not model then return true end
    if model:GetAttribute("CurrentHighlight") == "SpawnProtection" then return true end
    local owner = Players:GetPlayerFromCharacter(model)
    if owner and owner:GetAttribute("Deployed") == false then return true end
    local now = os.clock()
    local cached = protectedCache[model]
    if cached and now-cached.At < 0.1 then return cached.Value end
    local player = Players:GetPlayerFromCharacter(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, name in ipairs({"LobbyInvulnerable", "SpawnInvulnerable"}) do
            local flag = humanoid:FindFirstChild(name)
            if flag and (not flag:IsA("BoolValue") or flag.Value) then return true end
        end
    end
    local protected = model:FindFirstChildOfClass("ForceField") ~= nil or model:GetAttribute("InLobby") == true
        or model:GetAttribute("InSafeZone") == true or model:GetAttribute("SafeZone") == true
        or player and player:GetAttribute("InSafeZone") == true
    if not protected then
        if now >= nextZones then
            nextZones = now+2 safeParts = {}
            local zones = workspace:FindFirstChild("Zones") local folder = zones and zones:FindFirstChild("Safe")
            if folder then for _,part in ipairs(folder:GetDescendants()) do if part:IsA("BasePart") then table.insert(safeParts,part) end end end
        end
        local root = model:FindFirstChild("HumanoidRootPart")
        if root then for _,part in ipairs(safeParts) do if part.Parent then
            local point = part.CFrame:PointToObjectSpace(root.Position) local half = part.Size/2
            if math.abs(point.X)<=half.X and math.abs(point.Y)<=half.Y and math.abs(point.Z)<=half.Z then protected=true break end
        end end end
    end
    protected = protected == true
    protectedCache[model] = {At=now,Value=protected}
    return protected
end
A.GlobalStuff = {}
function A.GlobalStuff:CanHit(_,model)
    if not combatant(model) or model==LP.Character or A.Health(model)<=0 or A.IsProtected(model) then return false end
    local other=Players:GetPlayerFromCharacter(model)
    if not other and A.Config and A.Config.TargetNPCs == false then return false end
    if A.Config and A.Config.TeamCheck then
        local api = A.Damage
        if api then
            local ok, allowed = pcall(api.PlayerCanDamage, api, LP, model:FindFirstChildOfClass("Humanoid"))
            if ok then return allowed == true end
        end
    end
    if not (A.Config and A.Config.TeamCheck) then return true end
    if other and not LP.Neutral and not other.Neutral then return LP.Team~=other.Team end
    local ours=LP.Character and LP.Character:GetAttribute("team")
    local theirs=model:GetAttribute("team")
    return ours==nil or theirs==nil or ours~=theirs
end
function A.IsVisualTarget(model)
    return model~=LP.Character and combatant(model) and A.Health(model)>0 and A.GlobalStuff:CanHit(LP,model)
end
A.Hitboxes = {}
function A.Hitboxes.ZoneCenter(pose, zone)
    local model = pose.Model
    local part = model and (model:FindFirstChild(zone) or model:FindFirstChild(zone == "Torso" and "UpperTorso" or "Head"))
    if not part then return nil end
    local registry = nil
    local folder = registry and registry.folders[model]
    local proxy = folder and folder:FindFirstChild(part.Name)
    if proxy and proxy:IsA("BasePart") and (proxy.Position - part.Position).Magnitude <= 4 then
        return proxy.Position
    end
    local proxy=model:FindFirstChild("Hitbox_"..part.Name,true)
    return proxy and proxy:IsA("BasePart") and proxy.Position or part.Position
end
function A.CastVisibility(origin, direction, params)
    if A.Config and A.Config.Wallbang then return nil end
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
function A.ShotClient:AimDirection() return self.NativeDirection or workspace.CurrentCamera.CFrame.LookVector end
A.Action={}
function A.Action:GetWModel()
    return LP.Character and LP.Character:FindFirstChildOfClass("Tool")
end
function A.ResolveHeldVisual(model) return model end
function A.Install(S, H)
    local C = S.Config
    A.Config = C
    C.TargetNPCs = true
    C.ShootWhileInspect = false
    local controls = S.Tabs.Combat:AddRightGroupbox("Weapon options")
    H.toggle(controls, "ShootWhileInspect", "Shoot while inspecting")
    H.toggle(controls, "TargetNPCs", "Target NPCs")
    local attempt
    for _, candidate in ipairs(getgc()) do
        if type(candidate) == "function" and islclosure(candidate) then
            local source, name = debug.info(candidate, "sn")
            if name == "AttemptShoot" and source and source:find(LP.Name .. ".PlayerScripts.Shooter_Client", 1, true) then
                local hasCamera, hasConfig = false, false
                for _, value in pairs(debug.getupvalues(candidate)) do
                    if typeof(value) == "Instance" and value:IsA("Camera") then hasCamera = true end
                    if type(value) == "table" and rawget(value, "WeaponStats") then hasConfig = true end
                end
                if hasCamera and hasConfig then attempt = candidate break end
            end
        end
    end
    assert(attempt, "Native shooting function unavailable")
    local originalCameraIndex, configIndex, rigIndex
    local originalConfig
    for index, value in pairs(debug.getupvalues(attempt)) do
        if typeof(value) == "Instance" and value:IsA("Camera") then originalCameraIndex = index end
        if type(value) == "table" and rawget(value, "WeaponStats") then configIndex = index originalConfig = value end
        if type(value) == "table" and rawget(value, "inspectSoundsDone") then rigIndex = index end
    end
    assert(originalCameraIndex and configIndex, "Native shooting layout changed")
    local weaponState = require(RS.Modules.LocalWeaponState)
    setthreadidentity(8)
    local previousAttempt
    local function localRig()
        local rig = weaponState.rig
        return type(rig) == "table" and rig or nil
    end
    A.ResolveHeldVisual = function(tool)
        local rig = localRig()
        return rig and rig.viewmodel or tool
    end
    local offsetSaved = {}
    local firing = false
    previousAttempt = H.hook(attempt, function(...)
        if not S.Loaded or firing then return previousAttempt(...) end
        local camera = debug.getupvalue(previousAttempt or attempt, originalCameraIndex)
        local tool = A.Action:GetWModel()
        local target
        if tool and tool:GetAttribute("Melee") ~= true and camera then
            if C.RageAura then target = A.SelectAura(camera.CFrame.Position, C.AuraRange, S.WorldParams())
            elseif (C.SilentAim or C.Triggerbot) and math.random(1,100) <= C.HitChance then
                target = S.SelectTarget(camera.CFrame.Position, originalConfig.WeaponStats.Range, S.WorldParams(), nil, A.ShotClient:Ignore())
            end
        end
        if target then
            local frame = CFrame.lookAt(camera.CFrame.Position, target.Point)
            local proxy = setmetatable({CFrame = frame}, {__index = function(_, key)
                local value = camera[key]
                if type(value) == "function" then return function(_, ...) return value(camera, ...) end end
                return value
            end})
            debug.setupvalue(previousAttempt or attempt, originalCameraIndex, proxy)
        end
        firing = true
        local result = table.pack(pcall(previousAttempt, ...))
        firing = false
        if target then debug.setupvalue(previousAttempt or attempt, originalCameraIndex, camera) end
        S.FireAttempts = (S.FireAttempts or 0) + 1
        if target then S.Redirects = S.Redirects + 1 end
        if not result[1] then H.recordError("Shoot", result[2]) return end
        return table.unpack(result, 2, result.n)
    end)
    S.TryNativeShot = attempt
    local core = require(RS.Modules.ViewmodelRigParts.Core)
    setthreadidentity(8)
    local function keepInspect(self)
        return S.Loaded and C.ShootWhileInspect and self == localRig() and self.inspectStart ~= nil
    end
    for _, method in ipairs({"playShoot", "playReload", "playAim"}) do
        if type(core[method]) == "function" then
            local previous
            previous = H.hook(core[method], function(self, ...)
                if not keepInspect(self) then return previous(self, ...) end
                local start, queued = self.inspectStart, self.inspectQueued
                local result = table.pack(pcall(previous, self, ...))
                self.inspectStart, self.inspectQueued = start, queued
                self.kickStart, self.reloadStart, self.akimboReload = nil, nil, nil
                S.PreservedInspects = (S.PreservedInspects or 0) + 1
                if not result[1] then H.recordError("Inspect", result[2]) return end
                return table.unpack(result, 2, result.n)
            end)
        end
    end
    local stopInspect
    stopInspect = H.hook(core.stopInspect, function(self, ...)
        if firing and keepInspect(self) then return end
        return stopInspect(self, ...)
    end)
    local recoiler = require(RS.Modules.CameraRecoiler)
    setthreadidentity(8)
    local recoil
    if type(recoiler.recoil) == "function" then
        recoil = H.hook(recoiler.recoil, function(...)
            if S.Loaded and C.NoRecoil then return end
            return recoil(...)
        end)
    end
    local nextShot = 0
    local lastConfig
    local function maintenance()
        local current = debug.getupvalue(previousAttempt or attempt, configIndex)
        if current ~= lastConfig and current ~= originalConfig then originalConfig = current end
        local private = table.clone(originalConfig)
        private.WeaponStats = table.clone(originalConfig.WeaponStats)
        local duration = private.WeaponStats.ReloadDuration
        if C.RapidFire then duration = duration / math.max(C.FireMultiplier, 1) end
        if C.InstantReload then duration = .02 end
        private.WeaponStats.ReloadDuration = duration
        if C.InfiniteRange then private.WeaponStats.Range = 100000 end
        debug.setupvalue(previousAttempt or attempt, configIndex, private)
        lastConfig = private
        local rig = localRig()
        local offset = rig and rig.viewmodel and rig.viewmodel:FindFirstChild("ViewmodelOffset")
        if offset and offset:IsA("CFrameValue") then
            if C.ViewmodelOffset then
                if offsetSaved[offset] == nil then offsetSaved[offset] = offset.Value end
                offset.Value = offsetSaved[offset] * CFrame.new(C.ViewX, C.ViewY, C.ViewZ)
            elseif offsetSaved[offset] then offset.Value = offsetSaved[offset] offsetSaved[offset] = nil end
        end
        local safe = not S.Window.Native.IsOpen and not A.IsProtected(LP.Character) and A.Health(LP.Character) > 0
            and not game:GetService("GuiService").MenuIsOpen and not game:GetService("UserInputService"):GetFocusedTextBox()
        local tool = A.Action:GetWModel()
        local target
        if safe and tool then
            if C.RageAura then target = A.SelectAura(workspace.CurrentCamera.CFrame.Position, C.AuraRange, S.WorldParams())
            elseif C.Triggerbot then target = S.CurrentTarget end
        end
        S.AuraTarget = C.RageAura and target or nil
        S.FireStatus = not safe and "Protected or menu open" or not tool and "Equip a weapon" or not target and "No visible target" or "Ready"
        local held = safe and tool and C.AutomaticSemi and game:GetService("UserInputService"):IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        if (target or held) and os.clock() >= nextShot and not firing then
            nextShot = os.clock() + math.max(.03, duration)
            S.AutomaticAttempts = (S.AutomaticAttempts or 0) + 1
            attempt()
        end
    end
    S.AdapterMaintenance = maintenance
    S.CleanupWeapon = function()
        debug.setupvalue(previousAttempt or attempt, configIndex, originalConfig)
        for offset, value in pairs(offsetSaved) do if offset.Parent then offset.Value = value end end
    end
    S.GetNativeRig = localRig
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

return function(S,H)
    local C=S.Config
    local player=game:GetService("Players").LocalPlayer
    local run=game:GetService("RunService")
    local modified={}
    local function restore()
        for joint,transform in pairs(modified) do if joint.Parent then joint.Transform=transform end end
        table.clear(modified)
    end
    local function pitch(t)
        if C.AAPitchMode=="Up" then return math.rad(70) end
        if C.AAPitchMode=="Down" then return math.rad(-75) end
        if C.AAPitchMode=="Alternating" then return math.rad(math.floor(t*2)%2==0 and 70 or -75) end
        if C.AAPitchMode=="Rotate" then return math.rad(-2.5+72.5*math.sin(t*math.rad(C.AASpeed))) end
        return math.rad(math.clamp(C.AAPitch,-75,70))
    end
    S.ComputeAAPitch=pitch
    local function step()
        if not S.Loaded or not C.AntiAim then return end
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health<=0 or humanoid.Sit or humanoid.SeatPart
            or humanoid:GetAttribute("_RagdollState") or character:GetAttribute("Critical") then return end
        local t=os.clock()
        local yaw=0
        if C.AAYawMode=="Backward" then yaw=math.pi
        elseif C.AAYawMode=="Spin" then yaw=(t*math.rad(C.AASpeed))%(2*math.pi)
        elseif C.AAYawMode=="Jitter" then yaw=math.floor(t*4)%2==0 and math.pi/2 or -math.pi/2 end
        local function pose(model)
            if not model then return end
            for _,joint in ipairs(model:GetDescendants()) do
                if joint:IsA("Motor6D") and (joint.Name=="Neck" or joint.Name=="Waist") then
                    modified[joint]=joint.Transform
                    if joint.Name=="Neck" then joint.Transform=joint.Transform*CFrame.Angles(pitch(t),0,0)
                    elseif yaw~=0 then joint.Transform=joint.Transform*CFrame.Angles(0,yaw,0) end
                end
            end
        end
        pose(character) pose(S.AvatarModel)
        S.AAStatus="local pose"
    end
    table.insert(S.Connections,run.PreAnimation:Connect(restore))
    table.insert(S.Connections,run.PreSimulation:Connect(function()
        local ok,err=pcall(step)
        if not ok then H.recordError("AntiAim",err) end
    end))
    S.CleanupAntiAim=restore
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
    local defaults={WorldLighting=false,Fullbright=false,NoShadows=false,NoAtmosphere=false,
        AmbientColor=Color3.fromRGB(160,160,180),Exposure=0,ColorGrading=false,Saturation=0,Contrast=0,
        BloomEnabled=false,BloomIntensity=.4,BloomSize=24,BloomThreshold=1,SunRaysEnabled=false,SunRaysIntensity=.08}
    for key,value in pairs(defaults) do if C[key]==nil then C[key]=value end end
    S.Adapter.Install(S, H)
    assert(loadstring(S.AntiAimSource,"StreetAntiAim"))()(S,H)
    local aa=S.Tabs.Utility:AddRightGroupbox("Anti aim")
    H.toggle(aa,"AntiAim","Enabled")
    H.dropdown(aa,"AAPitchMode","Pitch",{"Up","Down","Alternating","Rotate","Custom"})
    H.slider(aa,"AAPitch","Custom pitch",-75,70)
    H.dropdown(aa,"AAYawMode","Yaw",{"None","Backward","Spin","Jitter"})
    H.slider(aa,"AASpeed","Speed",15,720)
    local controls = S.Tabs.Combat:AddRightGroupbox("Weapon actions")
    H.toggle(controls, "InfiniteRange", "Unlimited range")
    H.toggle(controls, "RapidFire", "Rapid fire (client)")
    H.slider(controls, "FireMultiplier", "Fire-rate multiplier", 1, 5, 1)
    H.toggle(controls, "AutomaticSemi", "Automatic semi-auto")
    H.toggle(controls, "Triggerbot", "Triggerbot")
    H.toggle(controls, "InstantReload", "Instant reload")
    local targeting = S.Tabs.Combat:AddLeftGroupbox("Target handling")
    H.toggle(targeting, "TeamCheck", "Team check")
    H.toggle(targeting, "HitboxFallback", "Visible body fallback")
    local aura = S.Tabs.Combat:AddLeftGroupbox("Rage aura")
    H.toggle(aura, "RageAura", "Enabled")
    H.slider(aura, "AuraRange", "Range (studs)", 5, 500)
    local auraStatus = aura:AddLabel("Off")
    local nextAuraStatus = 0
    table.insert(S.Connections, RunService.Heartbeat:Connect(function()
        if not S.Loaded or os.clock() < nextAuraStatus then return end
        nextAuraStatus = os.clock() + .5
        setthreadidentity(8)
        auraStatus:SetText(C.RageAura and (S.FireStatus or "Checking weapon") or "Off")
    end))
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
    local lightControls=S.Tabs.Visuals:AddLeftGroupbox("Lighting")
    H.inlineColor(H.toggle(lightControls,"WorldLighting","Custom lighting"),"AmbientColor","Ambient color")
    H.slider(lightControls,"Exposure","Exposure",-3,3,2)
    H.toggle(lightControls,"Fullbright","Fullbright")
    H.toggle(lightControls,"NoShadows","No shadows")
    H.toggle(lightControls,"NoAtmosphere","Clear atmosphere")
    local grading=S.Tabs.Visuals:AddLeftGroupbox("Effects")
    H.toggle(grading,"ColorGrading","Color grading")
    H.slider(grading,"Saturation","Saturation",-1,1,2)
    H.slider(grading,"Contrast","Contrast",-1,1,2)
    H.toggle(grading,"BloomEnabled","Bloom")
    H.slider(grading,"BloomIntensity","Bloom intensity",0,3,2)
    H.slider(grading,"BloomSize","Bloom size",0,56)
    H.slider(grading,"BloomThreshold","Bloom threshold",0,4,2)
    H.toggle(grading,"SunRaysEnabled","Sun rays")
    H.slider(grading,"SunRaysIntensity","Sun rays intensity",0,1,2)
    local fields = table.clone(faces)
    for _, name in ipairs({"SunTextureId", "MoonTextureId", "CelestialBodiesShown", "SunAngularSize", "MoonAngularSize", "StarCount"}) do table.insert(fields, name) end
    local savedSky, savedLighting = {}, nil
    local colorEffect,createdSky,bloomEffect,sunEffect
    local atmospheres={}
    local function restoreWorld()
        for obj,props in pairs(savedSky) do if obj.Parent then for key,value in pairs(props) do pcall(function() obj[key]=value end) end end end
        table.clear(savedSky)
        if savedLighting then for key,value in pairs(savedLighting) do Lighting[key]=value end savedLighting=nil end
        for obj,props in pairs(atmospheres) do if obj.Parent then obj.Density=props.Density obj.Haze=props.Haze obj.Glare=props.Glare end end
        table.clear(atmospheres)
        if colorEffect then colorEffect:Destroy() colorEffect=nil end
        if bloomEffect then bloomEffect:Destroy() bloomEffect=nil end
        if sunEffect then sunEffect:Destroy() sunEffect=nil end
        if createdSky then createdSky:Destroy() createdSky=nil end
    end
    local function worldStep()
        local active=C.SkyEnabled or C.WorldLighting or C.Fullbright or C.NoShadows or C.NoAtmosphere
            or C.NoFog or C.ColorGrading or C.BloomEnabled or C.SunRaysEnabled
        if not active then if savedLighting then restoreWorld() end return end
        if not savedLighting then
            savedLighting={}
            for _,key in ipairs({"ClockTime","Brightness","FogEnd","FogStart","Ambient","OutdoorAmbient","ExposureCompensation","GlobalShadows"}) do savedLighting[key]=Lighting[key] end
        end
        for key,value in pairs(savedLighting) do Lighting[key]=value end
        for obj,props in pairs(savedSky) do if obj.Parent then for key,value in pairs(props) do obj[key]=value end end end
        if C.SkyEnabled then
            local current=Lighting:FindFirstChildOfClass("Sky")
            if not current then current=Instance.new("Sky") current.Parent=Lighting createdSky=current end
            if not savedSky[current] then savedSky[current]={} for _,key in ipairs(fields) do savedSky[current][key]=current[key] end end
            local template=folder:FindFirstChild(C.SkyPreset)
            if template then for _,key in ipairs(fields) do current[key]=template[key] end end
            Lighting.ClockTime=C.SkyTime Lighting.Brightness=C.SkyBrightness
        end
        if C.WorldLighting then Lighting.Ambient=C.AmbientColor Lighting.OutdoorAmbient=C.AmbientColor Lighting.ExposureCompensation=C.Exposure end
        if C.Fullbright then Lighting.Ambient=Color3.new(1,1,1) Lighting.OutdoorAmbient=Color3.new(1,1,1) Lighting.Brightness=2 end
        if C.NoShadows then Lighting.GlobalShadows=false end
        if C.NoFog then Lighting.FogStart=1000000 Lighting.FogEnd=1000000 end
        for _,obj in ipairs(Lighting:GetChildren()) do if obj:IsA("Atmosphere") then
            if not atmospheres[obj] then atmospheres[obj]={Density=obj.Density,Haze=obj.Haze,Glare=obj.Glare} end
            local old=atmospheres[obj]
            obj.Density=C.NoAtmosphere and 0 or old.Density obj.Haze=C.NoAtmosphere and 0 or old.Haze obj.Glare=C.NoAtmosphere and 0 or old.Glare
        end end
        if C.SkyEnabled or C.ColorGrading then
            if not colorEffect then colorEffect=Instance.new("ColorCorrectionEffect") colorEffect.Name="AxisColor" colorEffect.Parent=Lighting end
            colorEffect.TintColor=C.SkyEnabled and C.SkyTint or Color3.new(1,1,1)
            colorEffect.Saturation=C.ColorGrading and C.Saturation or 0 colorEffect.Contrast=C.ColorGrading and C.Contrast or 0
        elseif colorEffect then colorEffect:Destroy() colorEffect=nil end
        if C.BloomEnabled then
            if not bloomEffect then bloomEffect=Instance.new("BloomEffect") bloomEffect.Name="AxisBloom" bloomEffect.Parent=Lighting end
            bloomEffect.Intensity=C.BloomIntensity bloomEffect.Size=C.BloomSize bloomEffect.Threshold=C.BloomThreshold
        elseif bloomEffect then bloomEffect:Destroy() bloomEffect=nil end
        if C.SunRaysEnabled then
            if not sunEffect then sunEffect=Instance.new("SunRaysEffect") sunEffect.Name="AxisSunRays" sunEffect.Parent=Lighting end
            sunEffect.Intensity=C.SunRaysIntensity
        elseif sunEffect then sunEffect:Destroy() sunEffect=nil end
    end
    local visibility, gripSaved = {}, nil
    local viewVisibility={}
    local speedHumanoid, speedSaved
    local function restoreVisibility()
        for part, value in pairs(visibility) do if part.Parent then part.LocalTransparencyModifier = value end end
        table.clear(visibility)
        for part,value in pairs(viewVisibility) do if part.Parent then part.LocalTransparencyModifier=value end end
        table.clear(viewVisibility)
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
        if C.FirstPerson and not C.ThirdPerson then
            cam.CFrame = CFrame.new(head.Position + Vector3.new(0, 0.15, 0)) * cam.CFrame.Rotation
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") and (obj == head or obj:FindFirstAncestorOfClass("Accessory")) then
                    if visibility[obj] == nil then visibility[obj] = obj.LocalTransparencyModifier end
                    obj.LocalTransparencyModifier = 1
                end
            end
        elseif C.ThirdPerson then
            for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then
                if visibility[part]==nil then visibility[part]=part.LocalTransparencyModifier end
                part.LocalTransparencyModifier=(part.Name=="HumanoidRootPart" or part:GetAttribute("AxisCosmeticHidden")) and 1 or 0
            end end
            local view=cam:FindFirstChild("Viewmodel")
            if view then for _,part in ipairs(view:GetDescendants()) do if part:IsA("BasePart") then
                if viewVisibility[part]==nil then viewVisibility[part]=part.LocalTransparencyModifier end
                part.LocalTransparencyModifier=1
            end end end
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
    RunService:BindToRenderStep("UrbanCameraExtras", Enum.RenderPriority.Last.Value + 110, function()
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
        if S.CleanupWeapon then S.CleanupWeapon() end
        if S.CleanupAntiAim then S.CleanupAntiAim() end
        RunService:UnbindFromRenderStep("UrbanOffsetReset")
        RunService:UnbindFromRenderStep("UrbanCameraExtras")
        restoreGrip() restoreSpeed() restoreVisibility() restoreWorld() folder:Destroy()
    end
    setthreadidentity(8)
    S.WorldMaintenance = worldStep
end
]=],
}
local function start()
getgenv().UrbanLastError = nil

assert(game.GameId == 10769024512, "Unexpected experience: this build targets Urban")
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
    InfiniteAmmo = false, InstantReload = false, TeamCheck = false, Wallbang = false, InstantBullet = false, InfiniteRange = false,
    AntiAim = false, AAPitchMode = "Up", AAPitch = 70, AAYawMode = "None", AASpeed = 90, SilentAim = false, Camlock = false, LockAlways = false, RageAura = false, AuraRange = 100,
    Radius = 160, FullFOV = false, Zone = "Head", Priority = "Crosshair",
    Sticky = false, Prediction = 0, Smoothness = 14, HitChance = 100,
    ShowFOV = false, TargetLine = false, Chams = false, Skeletons = false,
    Boxes = false, Names = false, Health = false, Distance = false,
    ThroughWalls = true, VisualDistance = 2000, GunChams = false,
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

    local menu = {AddLabel = function(_, text) return {AddKeyPicker = function(_, id, data) getgenv().Options[id] = {Value = data.Default, OnChanged = function() end, OnClick = function() end} end} end, AddButton = function() end}
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
        local isEnemy = Adapter.IsVisualTarget(model)
        
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
        local model = Adapter.ResolveHeldVisual(action:GetWModel())
        setthreadidentity(8)
        if not C.GunChams or not model or not model.Parent then
            if next(S.GunOriginals) or next(S.GunSurfaces) or S.GunHighlight then restoreGun() end
            return
        end
        if S.GunModel ~= model then restoreGun() S.GunModel = model end
        for obj, props in pairs(S.GunOriginals) do
            if obj~=model and not obj:IsDescendantOf(model) then
                if obj.Parent then pcall(function() for k, v in pairs(props) do obj[k] = v end end) end
                S.GunOriginals[obj] = nil
            end
        end
        local gunObjects=model:GetDescendants()
        if model:IsA("BasePart") then table.insert(gunObjects,1,model) end
        for _, obj in ipairs(gunObjects) do
            if S.EquippedCosmeticModel and obj:IsDescendantOf(S.EquippedCosmeticModel) then continue end
            if obj:IsA("BasePart") then
                if not S.GunOriginals[obj] then
                    local props = {Color = obj.Color, Material = obj.Material, Reflectance = obj.Reflectance}
                    if obj:IsA("UnionOperation") then props.UsePartColor=obj.UsePartColor end
                    if obj:IsA("MeshPart") then props.TextureID = obj.TextureID end
                    S.GunOriginals[obj] = props
                end
                obj.Color = C.GunColor obj.Material = Enum.Material[C.GunMaterial] obj.Reflectance = 0
                if obj:IsA("UnionOperation") then obj.UsePartColor=true end
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
            C.ThroughWalls = true
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
        if not S.Loaded or not C.Camlock or Window.Native.IsOpen or UIS:GetFocusedTextBox() then return end
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
    setthreadidentity(8)
    Library:Finish(S)
    setthreadidentity(8)
    S.DisableAll()
    for k,v in pairs(C) do if typeof(v)=="boolean" and k~="ThroughWalls" and k~="TargetNPCs" then C[k]=false end end
    getgenv().Toggles.UR_TargetNPCs:SetValue(true)
    C.TargetNPCs=true

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
