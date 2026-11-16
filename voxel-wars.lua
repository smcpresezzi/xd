local axisOk, axisResult = pcall(function()
local Sources={
    Library=[=[
return assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/source/game-bridge.lua")))()]=],
    Adapter=[=[
local A={}
local Players=game:GetService("Players")
local LP=Players.LocalPlayer
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Voxel=RS.Voxel
local VR=require(Voxel.VR)
local Recoil=require(Voxel.GunRecoil)
local Viewmodel=require(Voxel.Viewmodel)
local contexts=setmetatable({},{__mode="k"})
local weapons=setmetatable({},{__mode="k"})
local active
local function records()
    local out={}
    for _,p in ipairs(Players:GetPlayers())do
        local m=p.Character local h=m and m:FindFirstChildOfClass("Humanoid")
        if h and h.Health>0 and m:IsDescendantOf(workspace)then out[m]={Player=p,IsLocal=p==LP}end
    end
    local rigs=workspace:FindFirstChild("BotRigs")
    if rigs then for _,m in ipairs(rigs:GetChildren())do
        if m:IsA("Model")and m:GetAttribute("Alive")==true and m:FindFirstChild("Head")then out[m]={IsNPC=true,IsLocal=false}end
    end end
    return out
end
function A.Health(m)
    local h=m and m:FindFirstChildOfClass("Humanoid")
    if h then return h.Health,h.MaxHealth end
    return m and m:GetAttribute("Alive")==true and 100 or 0,100
end
function A.IsProtected(m)
    return not m or m:GetAttribute("Protected")==true or m:GetAttribute("Downed")==true or m:FindFirstChildOfClass("ForceField")~=nil
end
A.EntityClient={}
function A.EntityClient:GetRecords()return records()end
function A.EntityClient:GetLocalModel()return LP.Character end
function A.EntityClient:GetVelocity(m)
    local r=m and m:FindFirstChild("HumanoidRootPart")
    return r and r.AssemblyLinearVelocity or Vector3.zero
end
A.GlobalStuff={}
function A.GlobalStuff:CanHit(_,m)
    if not m or m==LP.Character or A.Health(m)<=0 or A.IsProtected(m)then return false end
    local p=Players:GetPlayerFromCharacter(m)
    if not p and not(m:GetAttribute("BotId")and A.Config.TargetNPCs)then return false end
    if A.Config.TeamCheck then
        local team=p and p.Team and p.Team.Name or m:GetAttribute("Team")
        if LP.Team and team==LP.Team.Name then return false end
    end
    return true
end
function A.IsVisualTarget(m)return A.GlobalStuff:CanHit(LP,m)end
A.Hitboxes={}
function A.Hitboxes.ZoneCenter(pose,zone)
    local m=pose.Model
    local part=m and(m:FindFirstChild(zone=="Torso"and "UpperTorso"or zone)or m:FindFirstChild("Head"))
    return part and part.Position
end
function A.CastVisibility(origin,direction,params)return workspace:Raycast(origin,direction,params)end
function A.VisiblePoint(m,origin,params,zone)
    for _,name in ipairs({zone,"UpperTorso","LowerTorso","Head"})do
        local point=A.Hitboxes.ZoneCenter({Model=m},name)
        if point then local hit=A.CastVisibility(origin,point-origin,params)
            if not hit or hit.Instance:IsDescendantOf(m)then return point end
        end
    end
end
A.ShotClient={}
function A.ShotClient:GetPoses()
    local out={}for m,r in pairs(records())do if not r.IsLocal then out[#out+1]={Model=m}end end return out
end
function A.ShotClient:Exclude()
    local out={workspace.CurrentCamera}
    if LP.Character then out[#out+1]=LP.Character end
    return out
end
function A.ShotClient:Ignore()return LP.Character and {[LP.Character]=true}or {}end
function A.ShotClient:Origin()return workspace.CurrentCamera.CFrame.Position end
function A.ShotClient:AimDirection()return workspace.CurrentCamera.CFrame.LookVector end
function A.SelectAura(origin,range,params)
    local best,distance
    for m,r in pairs(records())do if not r.IsLocal and A.GlobalStuff:CanHit(LP,m)then
        local point=A.VisiblePoint(m,origin,params,A.Config.Zone)
        if point then local d=(point-origin).Magnitude
            if d>0.01 and d<=range and(not distance or d<distance)then distance=d best={Model=m,Point=point,Direction=(point-origin).Unit,Distance=d}end
        end
    end end
    return best
end
A.Action={}
function A.IsGunVisual(object,model)
    local top=object
    while top.Parent and top.Parent~=model do top=top.Parent end
    return not top.Name:match("^Left.*Arm$")and not top.Name:match("^Right.*Arm$")and top.Name~="LeftHand"and top.Name~="RightHand"
end
function A.Action:GetWModel()
    if active and active.Tool.Parent==LP.Character and active.View and active.View.model then return active.View.model end
    return LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
end
function A.Install(S,H)
    local C=S.Config A.Config=C
    local controls=S.Tabs.Combat:AddRightGroupbox("Targets")
    H.toggle(controls,"TargetNPCs","Target NPCs")
    local function selectShot()
        local origin=workspace.CurrentCamera.CFrame.Position
        if C.RageAura then return A.SelectAura(origin,C.AuraRange,S.WorldParams())end
        if(C.SilentAim or C.Triggerbot)and math.random(1,100)<=C.HitChance then return S.SelectTarget(origin,500,S.WorldParams(),nil,A.ShotClient:Ignore())end
    end
    local originalFrame
    originalFrame=H.hook(VR.frame,function(...)
        local frame=originalFrame(...)
        local target=contexts[coroutine.running()]
        if S.Loaded and type(target)=="table"and(target.Point-frame.Position).Magnitude>0.001 then return CFrame.lookAt(frame.Position,target.Point)end
        return frame
    end)
    local originalRay
    originalRay=H.hook(VR.ray,function(...)
        local ray=originalRay(...)
        local target=contexts[coroutine.running()]
        if S.Loaded and type(target)=="table"and(target.Point-ray.Origin).Magnitude>0.001 then return Ray.new(ray.Origin,(target.Point-ray.Origin).Unit)end
        return ray
    end)
    local originalRecoil
    originalRecoil=H.hook(Recoil.shot,function(self,...)
        if S.Loaded and C.NoRecoil and contexts[coroutine.running()]~=nil then return end
        return originalRecoil(self,...)
    end)
    local originalFired
    originalFired=H.hook(Viewmodel.fired,function(self,...)
        if S.Loaded and C.NoRecoil and self.tool and self.tool.Parent==LP.Character then return end
        return originalFired(self,...)
    end)
    local function bindTool(tool)
        if weapons[tool]then return weapons[tool]end
        local scriptObject=tool:FindFirstChildOfClass("LocalScript")
        if not scriptObject then return end
        local found={Tool=tool}
        local functions={}
        local visited={}
        local function collect(fn,depth)
            if type(fn)~="function"or not islclosure(fn)or visited[fn]or depth>8 then return end
            visited[fn]=true
            local ok,scope=pcall(getfenv,fn)
            if ok and scope.script==scriptObject then
                functions[#functions+1]=fn
                local name=debug.info(fn,"n")
                if name=="shoot"then found.Shoot=fn elseif name=="spreadDir"then found.Spread=fn elseif name=="startReload"then found.Reload=fn end
                for _,value in pairs(debug.getupvalues(fn))do if type(value)=="function"then collect(value,depth+1)end end
            end
        end
        if getconnections then
            for _,signal in ipairs({RunService.RenderStepped,tool.Activated,tool.Equipped})do
                for _,connection in ipairs(getconnections(signal))do if connection.Function then collect(connection.Function,0)end end
            end
        end
        if not found.Shoot then for _,fn in ipairs(getgc())do collect(fn,0)end end
        if not found.Shoot then return end
        for _,value in pairs(debug.getupvalues(found.Shoot))do
            if type(value)=="table"and rawget(value,"tool")==tool then found.View=value end
            if type(value)=="function"and debug.info(value,"n")=="spreadDir"then found.Spread=value end
        end
        for _,fn in ipairs(functions)do
            local values=debug.getupvalues(fn)
            for index,value in pairs(values)do
                if value==found.Shoot and type(values[index-1])=="number"then found.Step=fn found.TimerIndex=index-1 end
            end
        end
        if found.Spread then local originalSpread
            originalSpread=H.hook(found.Spread,function(direction,spread,...)
                if S.Loaded and C.NoSpread then return direction end
                return originalSpread(direction,spread,...)
            end)
        end
        local originalShoot
        originalShoot=H.hook(found.Shoot,function(...)
            if not S.Loaded then return originalShoot(...)end
            local thread=coroutine.running()
            contexts[thread]=selectShot()or false
            local results=table.pack(pcall(originalShoot,...))
            contexts[thread]=nil
            if C.RapidFire and found.Step and found.TimerIndex then
                local nextShot=debug.getupvalue(found.Step,found.TimerIndex)
                if type(nextShot)=="number"then
                    local now=os.clock()
                    debug.setupvalue(found.Step,found.TimerIndex,now+math.max(nextShot-now,0.01)/C.FireMultiplier)
                end
            end
            if results[1]then return table.unpack(results,2,results.n)end
        end)
        weapons[tool]=found
        return found
    end
    local firingTool
    local savedHolds={}
    local nextScan=0
    local function stopFire()
        if firingTool then pcall(function()firingTool:Deactivate()end)firingTool=nil end
    end
    S.AdapterMaintenance=function()
        local tool=LP.Character and LP.Character:FindFirstChildWhichIsA("Tool")
        if not tool then active=nil stopFire()return end
        if not active or active.Tool~=tool then
            stopFire()
            if os.clock()<nextScan then return end
            nextScan=os.clock()+1
            active=bindTool(tool)
        end
        local enabled=active and active.View and active.View.active and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom
            and not S.Window.Native.IsOpen and not game:GetService("UserInputService"):GetFocusedTextBox()
        local target
        if enabled and C.RageAura then target=A.SelectAura(workspace.CurrentCamera.CFrame.Position,C.AuraRange,S.WorldParams())
        elseif enabled and C.Triggerbot then target=S.CurrentTarget end
        if target then
            if firingTool~=tool then stopFire()firingTool=tool tool:Activate()end
        else stopFire()end
        if enabled and C.AutoReload and active.Reload and(tool:GetAttribute("Ammo")or math.huge)<=C.ReloadAt then active.Reload()end
        if active and active.View and active.View.spec then
            local spec=active.View.spec
            if not savedHolds[spec]then savedHolds[spec]=spec.hold end
            if savedHolds[spec]then spec.hold=C.ViewmodelOffset and savedHolds[spec]*CFrame.new(C.ViewX,C.ViewY,C.ViewZ)or savedHolds[spec]end
        end
    end
    S.GetNativeGun=function()return active and active.View,active and active.View and active.View.spec end
    S.CleanupWeapon=function()
        stopFire()
        for spec,hold in pairs(savedHolds)do spec.hold=hold end
    end
end
return A
]=],
    Chams=[=[

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
]=],
    Extras=[=[

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
    local controls = S.Tabs.Combat:AddRightGroupbox("Weapon actions")
    H.toggle(controls, "RapidFire", "Rapid fire")
    H.slider(controls, "FireMultiplier", "Fire rate", 1, 5, 1)
    H.toggle(controls, "Triggerbot", "Triggerbot")
    H.toggle(controls, "AutoReload", "Auto reload")
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
    C.CustomFOV=false C.CustomFOVValue=80
    H.toggle(camControls,"CustomFOV","Custom FOV")
    H.slider(camControls,"CustomFOVValue","FOV",40,120)
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
        for _, id in ipairs({"ViewX", "ViewY", "ViewZ"}) do getgenv().Options["VW_" .. id]:SetValue(0) end
    end})
    local hop = player:AddTab("Movement")
    local hopToggle = H.toggle(hop, "BunnyHop", "Bunny hop")
    S.HopActivation = H.keybind(hopToggle, "HopActivation", "Bunny hop activation", "Space", "Hold")

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
    local fovCamera,fovSaved
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
        if cam.CameraType~=Enum.CameraType.Custom or humanoid.SeatPart then restoreVisibility()return end
        if C.CustomFOV then
            if fovCamera~=cam then
                if fovCamera and fovSaved then fovCamera.FieldOfView=fovSaved end
                fovCamera=cam fovSaved=cam.FieldOfView
            end
            cam.FieldOfView=C.CustomFOVValue
        elseif fovCamera then fovCamera.FieldOfView=fovSaved fovCamera=nil fovSaved=nil end
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
    RunService:BindToRenderStep("VoxelOffsetReset", Enum.RenderPriority.First.Value + 1, function()
        if S.Loaded then pcall(restoreGrip) end
    end)
    RunService:BindToRenderStep("VoxelCameraExtras", Enum.RenderPriority.Last.Value + 110, function()
        if not S.Loaded then return end
        local ok, err = xpcall(cameraStep, function()return nil end)
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
                if h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
            else restoreSpeed() end
        end, function()return nil end)
        if not ok then H.recordError("Extras", err) end
    end))
    function S.CleanupExtras()
        if S.CleanupUtility then S.CleanupUtility()end
        if S.CleanupWeapon then S.CleanupWeapon() end
        RunService:UnbindFromRenderStep("VoxelOffsetReset")
        RunService:UnbindFromRenderStep("VoxelCameraExtras")
        restoreGrip() restoreSpeed() restoreVisibility() restoreWorld() folder:Destroy()
        if fovCamera and fovSaved then fovCamera.FieldOfView=fovSaved end
    end
    setthreadidentity(8)
    S.WorldMaintenance = worldStep
end
]=],
    Avatar=[=[
return function(S,H)
    local Players = game:GetService("Players")
    local LP = Players.LocalPlayer
    local native = S.Library.Native
    local group=S.Tabs.Utility:AddRightGroupbox("Avatar")
    local section=group.Native
    S.Config.CustomAvatarEnabled=false
    local enabled=H.toggle(group,"CustomAvatarEnabled","Custom model")
    local input = ""
    local kind = "Auto"
    section:Textbox({Name="Model ID or link",Flag="AxisAvatarInput",Default=input,Finished=true,
        Callback=function(value) input=value end})
    section:Dropdown({Name="Type",Flag="AxisAvatarType",Items={"Auto","Bundle","Model"},Default="Auto",
        Callback=function(value) kind=value end})
    local status = section:Label("Ready")
    local active, saved, tracks = nil, {}, {}
    local offsets,joints={},{}
    local request = 0
    local function message(text)
        setthreadidentity(8)
        if S.Loaded then status:SetText(text) end
    end
    local function restore()
        for object,entry in pairs(saved) do if object.Parent then object[entry.Property]=entry.Value end end
        saved={}
        for _,entry in pairs(tracks) do pcall(function() entry.Track:Stop(0) entry.Track:Destroy() end) end
        tracks={}
        if active then active:Destroy() active=nil end
        offsets={} joints={}
        S.AvatarModel=nil
        if S.Loaded and S.SetPreviewModel then S.SetPreviewModel(nil) end
    end
    local function parse(text)
        local id = tonumber(tostring(text):match("/bundles/(%d+)") or tostring(text):match("/catalog/(%d+)")
            or tostring(text):match("[?&]id=(%d+)") or tostring(text):match("^%s*(%d+)%s*$"))
        assert(id and id>0,"Enter a Roblox model ID or bundle link")
        local isBundle = tostring(text):find("/bundles/",1,true)~=nil or kind=="Bundle"
        return id,isBundle
    end
    local function bundleModel(id)
        local bundle = game:GetService("AssetService"):GetBundleDetailsAsync(id)
        local outfit
        for _,item in ipairs(bundle.Items or {}) do if item.Type=="UserOutfit" then outfit=item.Id break end end
        assert(outfit,"This bundle has no avatar outfit")
        local description = Players:GetHumanoidDescriptionFromOutfitIdAsync(outfit)
        local model = Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
        description:Destroy()
        return model,bundle.Name
    end
    local function load(text)
        local id,isBundle = parse(text)
        if isBundle or kind=="Auto" then
            local ok,model,name = pcall(bundleModel,id)
            if ok then return model,name end
            if isBundle then error(model) end
        end
        local objects = game:GetObjects("rbxassetid://"..string.format("%.0f",id))
        assert(objects[1],"Model unavailable")
        local model=objects[1]
        for i=2,#objects do objects[i]:Destroy() end
        if not model:IsA("Model") then
            local wrapper=Instance.new("Model") model.Parent=wrapper model=wrapper
        end
        return model,model.Name
    end
    function S.ApplyAvatar(text)
        request+=1 local current=request
        message("Loading...")
        local ok,model,name=pcall(load,text or input)
        setthreadidentity(8)
        if not ok then message("Could not load model") return false,tostring(model) end
        if current~=request or not S.Loaded then model:Destroy() return false,"Cancelled" end
        local root=model:FindFirstChild("HumanoidRootPart",true) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart",true)
        if not root then model:Destroy() message("Model has no body parts") return false,"No body parts" end
        for _,object in ipairs(model:GetDescendants()) do
            if object:IsA("LuaSourceContainer") then object:Destroy()
            elseif object:IsA("Constraint") and not object:IsA("AnimationConstraint")and not object:IsA("WeldConstraint")or object:IsA("BodyMover")then object:Destroy()
            elseif object:IsA("BasePart") then object.Anchored=true object.CanCollide=false object.CanTouch=false object.CanQuery=false object.Massless=true end
        end
        restore()
        model.PrimaryPart=root
        for _,object in ipairs(model:GetDescendants())do
            if object:IsA("BasePart")then offsets[object]=root.CFrame:ToObjectSpace(object.CFrame)
            elseif object:IsA("Motor6D")or object:IsA("Weld")then
                if object.Part0 and object.Part1 then joints[#joints+1]={Object=object,Part0=object.Part0,Part1=object.Part1,C0=object.C0,C1=object.C1,Motor=object:IsA("Motor6D")}end
            elseif object:IsA("AnimationConstraint")then
                local a0,a1=object.Attachment0,object.Attachment1
                if a0 and a1 and a0.Parent:IsA("BasePart")and a1.Parent:IsA("BasePart")then
                    object.IsKinematic=true
                    joints[#joints+1]={Object=object,Part0=a0.Parent,Part1=a1.Parent,C0=a0.CFrame,C1=a1.CFrame,Motor=true}
                end
            elseif object:IsA("WeldConstraint")and object.Part0 and object.Part1 then
                joints[#joints+1]={Object=object,Part0=object.Part0,Part1=object.Part1,C0=object.Part0.CFrame:ToObjectSpace(object.Part1.CFrame),C1=CFrame.identity}
            end
        end
        local humanoid=model:FindFirstChildOfClass("Humanoid")
        for _,object in ipairs(model:GetDescendants()) do if object:IsA("BasePart") then object.Anchored=true end end
        if humanoid then humanoid.EvaluateStateMachine=false humanoid.AutoRotate=false humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
        model.Name="AxisAvatar"
        model.Parent=workspace.CurrentCamera
        active=model S.AvatarModel=model
        if not enabled.Value then enabled:SetValue(true)end
        if S.SetPreviewModel then S.SetPreviewModel(model) end
        message(name or "Applied")
        return true
    end
    section:Button({Name="Apply model",Callback=function() task.spawn(S.ApplyAvatar,input) end})
    enabled:OnChanged(function()
        if enabled.Value then
            if not active then task.spawn(S.ApplyAvatar,input)end
        else request+=1 restore()message("Ready")end
    end)
    section:Button({Name="Reset avatar",Callback=function()enabled:SetValue(false)end})
    local function hide(object,property,value)
        if not saved[object] then saved[object]={Property=property,Value=object[property]} end
        object[property]=value
    end
    local function step()
        if not active then return end
        local character=LP.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if active.Parent~=workspace.CurrentCamera then active.Parent=workspace.CurrentCamera end
        local close=not S.Config.ThirdPerson and(workspace.CurrentCamera.CFrame.Position-root.Position).Magnitude<3
        for part,offset in pairs(offsets)do if part.Parent then
            part.CFrame=root.CFrame*offset
            part.LocalTransparencyModifier=close and 1 or 0
        end end
        local pending=table.clone(joints)
        local solved={[active.PrimaryPart]=true}
        for _=1,#pending do
            local progress=false
            for i=#pending,1,-1 do
                local joint=pending[i]
                if solved[joint.Part0] then
                    local transform=joint.Motor and joint.Object.Transform or CFrame.identity
                    joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*transform*joint.C1:Inverse()
                    solved[joint.Part1]=true table.remove(pending,i) progress=true
                end
            end
            if not progress then break end
        end
        for _,object in ipairs(character:GetDescendants()) do
            if not object:FindFirstAncestorOfClass("Tool") then
                if object:IsA("BasePart") then hide(object,"LocalTransparencyModifier",1)
                elseif object:IsA("Decal") then hide(object,"Transparency",1) end
            end
        end
        local source=character:FindFirstChildOfClass("Humanoid")
        local target=active:FindFirstChildOfClass("Humanoid")
        local animator=target and target:FindFirstChildOfClass("Animator")
        local sourceAnimator=source and source:FindFirstChildOfClass("Animator")
        if animator and sourceAnimator then
            local playing={}
            for _,track in ipairs(sourceAnimator:GetPlayingAnimationTracks()) do
                local animation=track.Animation
                if animation then
                    playing[track]=true
                    local entry=tracks[track]
                    if not entry then
                        local copy=animator:LoadAnimation(animation) copy.Priority=track.Priority copy.Looped=track.Looped
                        copy:Play(0,track.WeightCurrent,track.Speed)
                        entry={Track=copy} tracks[track]=entry
                    end
                    entry.Track:AdjustSpeed(track.Speed) entry.Track:AdjustWeight(track.WeightCurrent,0)
                    if math.abs(entry.Track.TimePosition-track.TimePosition)>.08 then entry.Track.TimePosition=track.TimePosition end
                end
            end
            for original,entry in pairs(tracks) do if not playing[original] then entry.Track:Stop(.1) entry.Track:Destroy() tracks[original]=nil end end
        end
    end
    game:GetService("RunService"):BindToRenderStep("AxisVoxelAvatar",Enum.RenderPriority.Camera.Value+140,function()
        if not S.Loaded then return end
        setthreadidentity(8)
        local ok,err=pcall(step)
    end)
    S.CleanupAvatar=function()
        request+=1
        game:GetService("RunService"):UnbindFromRenderStep("AxisVoxelAvatar")
        restore()
    end
end
]=],
    Utility=[=[
return function(S,H)
    local C=S.Config
    local Players=game:GetService("Players")
    local LP=Players.LocalPlayer
    local RunService=game:GetService("RunService")
    local UIS=game:GetService("UserInputService")
    local defaults={BhopBoost=false,BhopBoostSpeed=40,WalkSpeedEnabled=false,WalkSpeedValue=24,HipHeightEnabled=false,HipHeightValue=2,
        JumpPowerEnabled=false,JumpPowerValue=60,Fly=false,FlySpeed=50,FlyVerticalSpeed=30,SpinBot=false,SpinSpeed=180}
    for key,value in pairs(defaults)do C[key]=value end
    local movement=S.Tabs.Utility:AddRightGroupbox("Movement")
    H.toggle(movement,"BhopBoost","Bunny hop boost")
    H.slider(movement,"BhopBoostSpeed","Boost speed",16,120)
    H.toggle(movement,"WalkSpeedEnabled","Walk speed")
    H.slider(movement,"WalkSpeedValue","Speed",8,100)
    H.toggle(movement,"HipHeightEnabled","Hip height")
    H.slider(movement,"HipHeightValue","Height",0,12,1)
    H.toggle(movement,"JumpPowerEnabled","Jump power")
    H.slider(movement,"JumpPowerValue","Power",20,150)
    local flight=S.Tabs.Utility:AddRightGroupbox("Flight")
    H.toggle(flight,"Fly","Enabled")
    H.slider(flight,"FlySpeed","Speed",10,200)
    H.slider(flight,"FlyVerticalSpeed","Vertical speed",10,100)
    local spin=S.Tabs.Utility:AddRightGroupbox("Spin")
    H.toggle(spin,"SpinBot","Enabled")
    H.slider(spin,"SpinSpeed","Speed",30,1080)
    local humanoid,root,stateConnection
    local saved={}
    local attachment,velocity,orientation
    local yaw=0
    local function restoreProperty(key)
        local entry=saved[key]
        if entry and humanoid and humanoid.Parent then pcall(function()humanoid[key]=entry.Value end)end
        saved[key]=nil
    end
    local function setProperty(key,value,enabled)
        if enabled then
            if not saved[key]then saved[key]={Value=humanoid[key]}end
            humanoid[key]=value
        else restoreProperty(key)end
    end
    local function stopFlight()
        local wasFlying=velocity~=nil
        if velocity then velocity:Destroy()velocity=nil end
        if orientation then orientation:Destroy()orientation=nil end
        if attachment then attachment:Destroy()attachment=nil end
        if wasFlying and root and root.Parent then root.AssemblyLinearVelocity=Vector3.zero end
    end
    local function resetCharacter()
        stopFlight()
        if stateConnection then stateConnection:Disconnect()stateConnection=nil end
        local keys={}for key in pairs(saved)do keys[#keys+1]=key end
        for _,key in ipairs(keys)do restoreProperty(key)end
        humanoid=nil root=nil
    end
    local function blocked()
        return S.Window.Native.IsOpen or UIS:GetFocusedTextBox()or game:GetService("GuiService").MenuIsOpen
    end
    local function bindCharacter(h,r)
        resetCharacter()
        humanoid=h root=r
        stateConnection=h.StateChanged:Connect(function(_,state)
            if not S.Loaded or not C.BunnyHop or not C.BhopBoost or C.Fly or blocked()or state~=Enum.HumanoidStateType.Jumping then return end
            if not(C.HopAlways or S.HopActivation and S.HopActivation:GetState())then return end
            local direction=Vector3.new(h.MoveDirection.X,0,h.MoveDirection.Z)
            if direction.Magnitude>.01 then
                local current=r.AssemblyLinearVelocity
                local speed=math.max(Vector3.new(current.X,0,current.Z).Magnitude,C.BhopBoostSpeed)
                r.AssemblyLinearVelocity=direction.Unit*speed+Vector3.new(0,current.Y,0)
            end
        end)
    end
    local function startFlight()
        if velocity then return end
        attachment=Instance.new("Attachment")attachment.Name="AxisFlightAttachment"attachment.Parent=root
        velocity=Instance.new("LinearVelocity")velocity.Name="AxisFlightVelocity"velocity.Attachment0=attachment
        velocity.RelativeTo=Enum.ActuatorRelativeTo.World velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector
        velocity.ForceLimitsEnabled=false velocity.VectorVelocity=Vector3.zero velocity.Parent=root
        orientation=Instance.new("AlignOrientation")orientation.Name="AxisFlightOrientation"orientation.Attachment0=attachment
        orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment orientation.MaxTorque=1000000
        orientation.Responsiveness=25 orientation.Parent=root
    end
    table.insert(S.Connections,RunService.PreSimulation:Connect(function(dt)
        if not S.Loaded then return end
        local character=LP.Character
        local h=character and character:FindFirstChildOfClass("Humanoid")
        local r=character and character:FindFirstChild("HumanoidRootPart")
        if not h or not r or h.Health<=0 then if humanoid then resetCharacter()end return end
        if h~=humanoid or r~=root then bindCharacter(h,r)end
        setProperty("WalkSpeed",C.WalkSpeedValue,C.WalkSpeedEnabled)
        setProperty("HipHeight",C.HipHeightValue,C.HipHeightEnabled)
        setProperty("JumpPower",C.JumpPowerValue,C.JumpPowerEnabled and h.UseJumpPower)
        setProperty("JumpHeight",C.JumpPowerValue*C.JumpPowerValue/(2*math.max(workspace.Gravity,1)),C.JumpPowerEnabled and not h.UseJumpPower)
        local flying=C.Fly and not h.SeatPart and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom
        local spinning=C.SpinBot and not blocked()and not h.SeatPart
        setProperty("AutoRotate",false,flying or spinning)
        if spinning then yaw=(yaw+math.rad(C.SpinSpeed)*math.min(dt,.1))%(math.pi*2)end
        if flying then
            startFlight()
            local camera=workspace.CurrentCamera.CFrame
            local direction=Vector3.zero local vertical=0
            if not blocked()then
                if UIS:IsKeyDown(Enum.KeyCode.W)then direction+=camera.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S)then direction-=camera.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.D)then direction+=camera.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.A)then direction-=camera.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space)then vertical+=1 end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl)then vertical-=1 end
            end
            if direction.Magnitude>1 then direction=direction.Unit end
            velocity.VectorVelocity=direction*C.FlySpeed+Vector3.new(0,vertical*C.FlyVerticalSpeed,0)
            orientation.CFrame=spinning and CFrame.Angles(0,yaw,0)or camera.Rotation
        else
            stopFlight()
            if spinning then r.CFrame=CFrame.new(r.Position)*CFrame.Angles(0,yaw,0)end
        end
    end))
    assert(loadstring(S.AvatarSource))()(S,H)
    S.CleanupUtility=function()
        resetCharacter()
        if S.CleanupAvatar then S.CleanupAvatar()end
    end
end
]=]
}
local function start()


if game.GameId~=10773416193 then return end
local env = getgenv()
local previousConfig = env.VoxelHub and table.clone(env.VoxelHub.Config)
if env.VoxelHub and env.VoxelHub.NativeTargets then env.VoxelNativeTargets = env.VoxelHub.NativeTargets end
if env.VoxelHub and env.VoxelHub.Unload then env.VoxelHub.Unload() end

local librarySource = Sources.Library
local Library = assert(loadstring(librarySource, "AxisLib"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local Adapter = assert(loadstring(Sources.Adapter, "VoxelAdapter"))()
local ShotClient = Adapter.ShotClient
local EntityClient = Adapter.EntityClient
local Hitboxes = Adapter.Hitboxes
local GlobalStuff = Adapter.GlobalStuff

local C = {
    TeamCheck=true,TargetNPCs=true,
    SilentAim = false, Camlock = false, LockAlways = false, RageAura = false, AuraRange = 100,
    Radius = 160, FullFOV = false, Zone = "Head", Priority = "Crosshair",
    Sticky = false, Prediction = 0, Smoothness = 14, HitChance = 100,
    ShowFOV = false, TargetLine = false, Chams = false, Skeletons = false,
    Boxes = false, Names = false, Health = false, Distance = false,
    ThroughWalls = true, VisualDistance = 2000, GunChams = false,
    NoRecoil = false, NoSpread = false, FirstPerson = false,
    ChamsColor = Color3.fromRGB(255, 85, 125), ChamsMaterial = "Neon", ChamsTransparency = 0.25,
    SkeletonColor = Color3.fromRGB(255, 85, 125), BoxColor = Color3.fromRGB(255, 85, 125),
    NameColor = Color3.new(1, 1, 1), DistanceColor = Color3.new(1, 1, 1), HealthColor = Color3.fromRGB(90, 255, 130),
    FOVColor = Color3.fromRGB(100, 225, 255), TracerColor = Color3.fromRGB(100, 225, 255),
    EnemyColor = Color3.fromRGB(255, 85, 125),
    TargetColor = Color3.fromRGB(100, 225, 255),
    GunColor = Color3.fromRGB(145, 100, 255), GunMaterial = "Neon",
    RapidFire = false, FireMultiplier = 2, Triggerbot = false, AutoReload = false, ReloadAt = 5, HitboxFallback = false, SkipProtected = false,
    SkyEnabled = false, SkyPreset = "Original", SkyTime = 14, SkyBrightness = 2,
    SkyTint = Color3.new(1, 1, 1), NoFog = false,
    ThirdPerson = false, CameraDistance = 9, CameraShoulder = 1.5, CameraHeight = 0.7,
    ViewmodelOffset = false, ViewX = 0, ViewY = 0, ViewZ = 0,
    BunnyHop = false, HopAlways = false, HopBoost = false, HopSpeed = 32,
}
if previousConfig then
    for k, v in pairs(previousConfig) do
        if C[k] ~= nil and typeof(v) ~= "boolean" and typeof(C[k]) == typeof(v) then C[k] = v end
    end
end
env.VoxelKeybinds = env.VoxelKeybinds or {}
local S = {
    Config = C, Library = Library, Loaded = true, MenuVisible = true, Hooks = {}, Drawings = {},
    Connections = {}, Visuals = {}, GunOriginals = {}, 
    Target = nil, FrameCount = 0, GunSurfaces = {},
}
env.VoxelHub = S
S.Adapter = Adapter
S.AvatarSource = Sources.Avatar



local function recordError()end

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
    p.CollisionGroup = "Default"
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
    RunService:UnbindFromRenderStep("VoxelAxisCamera")
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
        local saved = env.VoxelKeybinds[id]
        parent:AddKeyPicker("VW_" .. id, {Default = saved or default or "None", Mode = mode or "Toggle",
            Modes = {mode or "Toggle"}, Text = text, NoUI = true, SyncToggleState = false})
        local picker = env.Options["VW_" .. id]
        picker:OnChanged(function() env.VoxelKeybinds[id] = picker.Value end)
        S.Bindings[id] = picker
        return picker
    end
    local majorBindings = {SilentAim=true,ThirdPerson=true,FirstPerson=true,Triggerbot=true,RageAura=true,Fly=true,SpinBot=true}
    S.Materials = {"SmoothPlastic", "Plastic", "Neon", "ForceField", "Glass", "Metal", "DiamondPlate", "Foil", "CorrodedMetal", "Wood", "WoodPlanks", "Marble", "Granite", "Slate", "Concrete", "Brick", "Cobblestone", "Ice", "Sand", "Fabric", "Grass", "Pebble"}
    local function toggle(group, id, text)
        local t = group:AddToggle("VW_" .. id, {Text = text, Default = C[id]})
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
        group:AddSlider("VW_" .. id, {Text = text, Default = C[id], Min = minimum, Max = maximum, Rounding = rounding or 0})
        local o = env.Options["VW_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end
    local function dropdown(group, id, text, values)
        group:AddDropdown("VW_" .. id, {Text = text, Values = values, Default = C[id]})
        local o = env.Options["VW_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end
    local function color(group, id, text)
        group:AddLabel(text):AddColorPicker("VW_" .. id, {Default = C[id], Title = text})
        local o = env.Options["VW_" .. id]
        o:OnChanged(function() C[id] = o.Value end)
    end

    local function inlineColor(control, id, title)
        control:AddColorPicker("VW_" .. id, {Default = C[id], Title = title})
        local option = env.Options["VW_" .. id]
        option:OnChanged(function() C[id] = option.Value end)
        return control
    end
    local silent = aim:AddLeftGroupbox("Silent aim")
    S.SilentToggle = toggle(silent, "SilentAim", "Enabled")
    slider(silent, "Radius", "FOV radius", 20, 800)
    slider(silent, "HitChance", "Hit chance (%)", 0, 100)
    dropdown(silent, "Zone", "Hitbox", {"Head", "Torso", "UpperTorso", "LowerTorso"})
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
                local control = env.Toggles["VW_" .. id]
                if control then control:SetValue(false) else C[id] = false end
            end
        end
    end
    function S.SyncControls()
        for id, value in pairs(C) do
            if typeof(value) == "boolean" then
                local control = env.Toggles["VW_" .. id]
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
        if S.Loaded and C.RageAura then
            local ok, target = pcall(Adapter.SelectAura, origin, math.min(C.AuraRange, range or C.AuraRange), params)
            S.AuraTarget = ok and target or nil
            if ok and target then
                return target.Direction
            elseif not ok then recordError("Aura", target) end
        end

        if S.Loaded and (C.SilentAim or C.Triggerbot) and math.random(1, 100) <= C.HitChance then
            local ok, target = pcall(selectTarget, origin, range, params, poses, ignore)
            if ok and target then
                S.Target = target.Model
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
            if obj~=model and not obj:IsDescendantOf(model) then
                if obj.Parent then pcall(function() for k, v in pairs(props) do obj[k] = v end end) end
                S.GunOriginals[obj] = nil
            end
        end
        local gunObjects=model:GetDescendants()
        if model:IsA("BasePart") then table.insert(gunObjects,1,model) end
        for _, obj in ipairs(gunObjects) do
            if Adapter.IsGunVisual and not Adapter.IsGunVisual(obj,model)then continue end
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
        end, function()return nil end)
        if not ok then recordError("Render", err) end
    end))
    function S.StepCamera(dt)
        if C.RageAura then return end
        if not S.Loaded or not C.Camlock or Window.Native.IsOpen or UIS:GetFocusedTextBox() then return end
        if not S.CamActivation:GetState() then return end
        local target, cam = S.CurrentTarget, camera()
        if target and cam and cam.CameraType==Enum.CameraType.Custom then
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
    RunService:BindToRenderStep("VoxelAxisCamera", Enum.RenderPriority.Camera.Value + 100, S.StepCamera)
    S.SelectTarget = selectTarget
    S.WorldParams = worldParams
    S.WeaponMaintenance = weaponMaintenance
    S.RestoreGunAppearance = restoreGun
    local extend = assert(loadstring(Sources.Extras, "VoxelExtras"))()
    extend(S, {toggle = toggle, slider = slider, dropdown = dropdown, color = color,
        inlineColor = inlineColor, keybind = keybind, hook = hook, recordError = recordError, worldParams = worldParams})
    setthreadidentity(8)
    assert(loadstring(Sources.Utility))()(S,{toggle=toggle,slider=slider,dropdown=dropdown,keybind=keybind})
    Library:Finish(S)
    local modalRoot=Library.Native.Holder.Instance.Parent
    local modalButtons={}
    local function refreshModal(gui,button)
        if button.Parent then button.Modal=gui.Enabled and Window.Native.IsOpen end
    end
    for _,gui in ipairs(modalRoot:GetDescendants())do
        if gui:IsA("ScreenGui")and gui.Name=="AxisBindModal"then
            local button=gui:FindFirstChild("Backdrop")
            if button and button:IsA("GuiButton")then
                modalButtons[gui]=button
                refreshModal(gui,button)
                table.insert(S.Connections,gui:GetPropertyChangedSignal("Enabled"):Connect(function()refreshModal(gui,button)end))
            end
        end
    end
    table.insert(S.Connections,Window.Holder:GetPropertyChangedSignal("Visible"):Connect(function()
        for gui,button in pairs(modalButtons)do refreshModal(gui,button)end
    end))
    setthreadidentity(8)


end

local ok, err = xpcall(build, function()return nil end)
if not ok then
    pcall(S.Unload)
    return
end

end
local success, failure = xpcall(start, function()return nil end)
if not success then
    if S and S.Unload then pcall(S.Unload)end
end

end)
if axisOk then return axisResult end
