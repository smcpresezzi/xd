

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
local safeParts, nextZones = {}, 0
local protectedCache = setmetatable({}, {__mode="k"})
function A.IsProtected(model)
    if not model then return true end
    local now = os.clock()
    local cached = protectedCache[model]
    if cached and now-cached.At < 0.1 then return cached.Value end
    local player = Players:GetPlayerFromCharacter(model)
    local protected = model:FindFirstChildOfClass("ForceField") ~= nil or model:FindFirstChild("OnboardingHighlight") ~= nil
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
function A.GlobalStuff:CanHit(_, model)
    local other = model and Players:GetPlayerFromCharacter(model)
    if not other or other == LP or other.Character ~= model or A.Health(model)<=0 or A.IsProtected(model) then return false end
    return not (A.Config and A.Config.TeamCheck) or LP.Neutral or other.Neutral or other.Team ~= LP.Team
end
function A.IsVisualTarget(model)
    local player = model and Players:GetPlayerFromCharacter(model)
    return player ~= nil and player ~= LP and model.Parent ~= nil and A.Health(model)>0
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
    return part.Position
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
A.Action = {}
function A.Action:GetWModel()
    local char = LP.Character
    if char then for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") and child:FindFirstChild("Settings") then return child end
    end end
end

function A.ResolveHeldVisual(tool) return tool end
function A.Install(S,H)
    local C = S.Config A.Config = C
    local function findGun()
        local tool = A.Action:GetWModel()
        if A.Gun and A.Gun.Instance == tool and not A.Gun.IsDestroyed then return A.Gun end
        A.Gun = nil
        if tool then
            for _,value in ipairs(getgc(true)) do
                if type(value) == "table" and rawget(value,"Instance") == tool and rawget(value,"Spring_Recoil") then
                    A.Gun = value break
                end
            end
        end
        return A.Gun
    end
    local gun = findGun()
    local class = gun and getmetatable(gun)
    if not class then
        for _, value in ipairs(getgc(true)) do
            if type(value)=="table" and type(rawget(value,"FireBullet"))=="function"
                and type(rawget(value,"Update"))=="function" and type(rawget(value,"SwitchHold"))=="function" then
                class=value break
            end
        end
    end
    assert(type(class)=="table" and class.FireBullet and class.Update, "Weapon class unavailable")
    S.WeaponClass = class
    local ammoTouched = setmetatable({}, {__mode="k"})
    local originalGet
    originalGet = H.hook(class.Get,function(self,key,...)
        local value = originalGet(self,key,...)
        if S.Loaded and C.InfiniteAmmo and self.Character == LP.Character and key == "Ammo_Client" then
            ammoTouched[self.Instance] = true
            return math.max(value or 0,self.Settings.Ammo or 1,1)
        end
        return value
    end)
    local originalSet
    originalSet = H.hook(class.Set,function(self,key,value,...)
        if S.Loaded and self.Character == LP.Character and key == "Ammo_Client" and C.InfiniteAmmo then
            local current = self.Instance:GetAttribute("Ammo_Client") or 0
            local magazine = self.Settings.Ammo or current
            value = math.max(value or 0,current,magazine,1)
            ammoTouched[self.Instance] = true
        end
        return originalSet(self,key,value,...)
    end)
    local oldReload
    oldReload = H.hook(class.Reload,function(self,...)
        if not S.Loaded or not C.InstantReload or self.Character ~= LP.Character then return oldReload(self,...) end
        local ammoBefore = self.Instance:GetAttribute("Ammo_Client") or 0
        local reloadingBefore = self.Instance:GetAttribute("IsReloading")
        local result = table.pack(pcall(oldReload,self,...))
        if result[1] and not reloadingBefore and self.Instance:GetAttribute("IsReloading") then
            local reserve = self.Instance:GetAttribute("Capacity") or 0
            local maximum = self.Settings.Ammo or ammoBefore
            if reserve > 0 or C.InfiniteAmmo then
                originalSet(self,"Ammo_Client", math.min(maximum, ammoBefore+reserve))
                ammoTouched[self.Instance] = true
            end
            originalSet(self,"IsReloading",false)
            local track = self._Animations and self._Animations.Reload
            if track and track.Track then track.Track:Stop(0) end
            S.ReloadShortcuts = (S.ReloadShortcuts or 0)+1
        end
        if not result[1] then H.recordError("Reload",result[2]) return end
        return table.unpack(result,2,result.n)
    end)
    local function restoreAmmo(tool)
        local authoritative = tool and tool:GetAttribute("Ammo_Server")
        if tool and type(authoritative)=="number" then tool:SetAttribute("Ammo_Client",authoritative) end
        ammoTouched[tool] = nil
    end
    S.CleanupWeapon = function()
        for tool in pairs(ammoTouched) do if tool.Parent then restoreAmmo(tool) end end
    end
    local framework = RS.Modules.GunFramework
    local projectile = require(framework.Modules.Projectile)
    local shared = require(framework.Modules.Shared)
    local active = setmetatable({}, {__mode="k"})
    local oldProjectile
    oldProjectile = H.hook(projectile.new, function(options)
        if S.Loaded and active[coroutine.running()] then
            options = table.clone(options)
            if C.InstantBullet then options.Speed = 100000 end
            if C.Wallbang then
                local params = RaycastParams.new() params.FilterType = Enum.RaycastFilterType.Include
                params.CollisionGroup = "Bullet"
                local models = {}
                for model,record in pairs(records()) do
                    if not record.IsLocal and not A.IsProtected(model) then
                        for _,part in ipairs(model:GetChildren()) do
                            if part:IsA("BasePart") then table.insert(models,part) end
                        end
                    end
                end
                params.FilterDescendantsInstances = models options.RaycastParams = params
            end
        end
        return oldProjectile(options)
    end)
    function S.ProbeProjectile()
        local thread = coroutine.running() active[thread] = true
        local object = projectile.new({Origin=Vector3.zero,Direction=Vector3.new(0,0,-1),Acceleration=Vector3.zero,Speed=100,RaycastParams=RaycastParams.new()})
        active[thread] = nil
        local result = {Speed=object.Speed,FilterType=tostring(object.RaycastParams.FilterType),Included=#object.RaycastParams.FilterDescendantsInstances}
        object:Destroy() return result
    end
    local shotContexts = setmetatable({}, {__mode="k"})
    local mouse = LP:GetMouse()
    local oldIndex
    oldIndex = hookmetamethod(game,"__index",newcclosure(function(object,key)
        local context = shotContexts[coroutine.running()]
        if object == mouse and key == "Hit" and context then return CFrame.new(context.Point) end
        return oldIndex(object,key)
    end))
    S.RestoreNamecall = function() hookmetamethod(game,"__index",oldIndex) end
    local oldFire
    oldFire = H.hook(class.Fire,function(self,...)
        if not S.Loaded or self.Character ~= LP.Character then return oldFire(self,...) end
        local thread = coroutine.running() local prior = shotContexts[thread]
        local muzzle = self.Handle and self.Handle:FindFirstChild("MuzzleAttachment")
        local origin = muzzle and muzzle.WorldPosition or self.RootPart.Position
        local range = C.InfiniteRange and 100000 or self.Settings.Range
        local target
        if C.RageAura then target = A.SelectAura(origin,math.min(C.AuraRange,range),S.WorldParams())
        elseif (C.SilentAim or C.Triggerbot) and math.random(1,100)<=C.HitChance then
            target = S.SelectTarget(origin,range,S.WorldParams(),nil,A.ShotClient:Ignore())
        end
        if target then shotContexts[thread] = {Point=target.Point}
        elseif C.Wallbang then local ray=mouse.UnitRay shotContexts[thread]={Point=ray.Origin+ray.Direction*range} end
        local result = table.pack(pcall(oldFire,self,...)) shotContexts[thread]=prior
        if not result[1] then H.recordError("Fire",result[2]) return end
        return table.unpack(result,2,result.n)
    end)
    local oldBullet
    oldBullet = H.hook(class.FireBullet, function(self, origin, direction, ...)
        if not S.Loaded or self.Character ~= LP.Character then return oldBullet(self,origin,direction,...) end
        local context = shotContexts[coroutine.running()]
        if context and (context.Point-origin).Magnitude>0.001 then direction=(context.Point-origin).Unit end
        local thread = coroutine.running() local previous = active[thread] active[thread] = true
        local settings = self.Settings
        if C.InfiniteRange then self.Settings = table.clone(settings) self.Settings.Range = 100000 end
        local result = table.pack(pcall(oldBullet,self,origin,direction,...))
        self.Settings = settings active[thread] = previous
        S.ShotRays = (S.ShotRays or 0)+1
        if not result[1] then H.recordError("Bullet",result[2]) return end
        return table.unpack(result,2,result.n)
    end)
    local oldRandom
    oldRandom = H.hook(shared.RandomizeDirection,function(origin,direction,...)
        if S.Loaded and C.NoSpread then return direction end
        return oldRandom(origin,direction,...)
    end)
    local springClass = gun and getmetatable(gun.Spring_Recoil) or require(framework.Modules.Spring)
    if springClass and springClass.Shove then
        local oldShove
        oldShove = H.hook(springClass.Shove,function(self,...)
            local current = A.Gun
            if S.Loaded and C.NoRecoil and current and current.Spring_Recoil == self then return end
            return oldShove(self,...)
        end)
    end
    local baseSettings = setmetatable({}, {__mode="k"})
    local oldUpdate
    oldUpdate = H.hook(class.Update,function(self,dt,...)
        if not S.Loaded or self.Character ~= LP.Character then return oldUpdate(self,dt,...) end
        A.Gun = self
        if not C.InfiniteAmmo and not C.InstantReload and ammoTouched[self.Instance] then restoreAmmo(self.Instance) end
        local safe = not A.IsProtected(LP.Character) and not S.Window.Native.IsOpen
            and not game:GetService("GuiService").MenuIsOpen and not game:GetService("UserInputService"):GetFocusedTextBox()
        if not baseSettings[self] then baseSettings[self] = {Settings=self.Settings,Delta=self.DeltaTime} end
        local settings, delta = baseSettings[self].Settings,baseSettings[self].Delta
        local hold,request,last = self._HoldState,self._FireRequest,self._LastRequest
        local modified = table.clone(settings)
        if safe and C.RapidFire then modified.FireRate = settings.FireRate * math.max(C.FireMultiplier,1) self.DeltaTime = 60/modified.FireRate end
        if safe and C.AutomaticSemi then modified.IsAutomatic = true end
        if safe and C.NoRecoil then modified.Recoil = 0 end
        self.Settings = modified
        if safe and C.HipFire then self._HoldState = false end
        if safe and C.RageAura then
            S.AuraTarget = A.SelectAura(workspace.CurrentCamera.CFrame.Position,C.AuraRange,S.WorldParams())
        else S.AuraTarget = nil end
        local auto = safe and ((C.RageAura and S.AuraTarget~=nil) or (C.Triggerbot and S.CurrentTarget~=nil))
        if auto then self._FireRequest = true self._LastRequest = false self._HoldState = false end
        if safe and C.RapidFire and self._FireRequest then self._LastRequest = false end
        local result = table.pack(pcall(oldUpdate,self,dt,...))
        self.Settings = settings self.DeltaTime = delta self._HoldState = hold
        if auto then self._FireRequest = request self._LastRequest = last end
        if safe and C.AutoReload and self:Get("Ammo_Client") <= C.ReloadAt and not self:Get("IsReloading") then self:Reload() end
        S.FireStatus = safe and "ready" or "menu/input"
        if not result[1] then H.recordError("Weapon",result[2]) return end
        return table.unpack(result,2,result.n)
    end)
    S.Capabilities = {fire=true,rapidFire=true,wallbang=true}
    S.AdapterMaintenance = findGun
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
    S.Adapter.Install(S, H)
    assert(loadstring(S.AntiAimSource,"StreetAntiAim"))()(S,H)
    local aa=S.Tabs.Utility:AddRightGroupbox("Anti aim")
    H.toggle(aa,"AntiAim","Enabled")
    H.dropdown(aa,"AAPitchMode","Pitch",{"Up","Down","Alternating","Rotate","Custom"})
    H.slider(aa,"AAPitch","Custom pitch",-75,70)
    H.dropdown(aa,"AAYawMode","Yaw",{"None","Backward","Spin","Jitter"})
    H.slider(aa,"AASpeed","Speed",15,720)
    local controls = S.Tabs.Combat:AddRightGroupbox("Weapon actions")
    H.toggle(controls, "HipFire", "Shoot without aiming")
    H.toggle(controls, "Wallbang", "Wallbang")
    H.toggle(controls, "InstantBullet", "Instant bullets")
    H.toggle(controls, "InfiniteRange", "Unlimited range")
    H.toggle(controls, "RapidFire", "Rapid fire (client)")
    H.slider(controls, "FireMultiplier", "Fire-rate multiplier", 1, 5, 1)
    H.toggle(controls, "AutomaticSemi", "Automatic semi-auto")
    H.toggle(controls, "Triggerbot", "Triggerbot")
    H.toggle(controls, "InfiniteAmmo", "Infinite ammo")
    H.toggle(controls, "InstantReload", "Instant reload")
    H.toggle(controls, "AutoReload", "Automatic reload")
    H.slider(controls, "ReloadAt", "Reload below", 0, 25)
    local targeting = S.Tabs.Combat:AddLeftGroupbox("Target handling")
    H.toggle(targeting, "TeamCheck", "Team check")
    H.toggle(targeting, "HitboxFallback", "Visible body fallback")
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
        if S.CleanupWeapon then S.CleanupWeapon() end
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

assert(game.GameId == 6726637224, "Unexpected experience: this build targets Urban")
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
    toggle(controls, "NoSpread", "No spread")
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
    Library:Finish(S)

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
