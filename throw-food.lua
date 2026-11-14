if game.GameId ~= 10766972131 then return end
local LibrarySource = [=[return assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/087d501b05f37c149cedabddbbaa96bc9eee81e7/source/game-bridge.lua"), "Axis UI bridge"))()]=]
local env = getgenv()
if env.AxisFood and env.AxisFood.Loaded then env.AxisFood.Unload() end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local controllers = LP.PlayerScripts.Client.Controllers
local Data = require(controllers.DataController)
local State = require(controllers.ClientState)
local Training = require(controllers.TrainingController)
local Throwing = require(controllers.ThrowController)
local Plot = require(controllers.PlotController)
local Meter = require(controllers.ThrowMeter)
local Input = require(controllers.InputActions)
local MeterMath = require(RS.Shared.ThrowMeterMath)
local Remotes = require(RS.Shared.Remotes)
local Mutations = require(RS.Shared.Mutations)
local Stands = require(RS.Config.StandsConfig)
local Fence = require(RS.Config.FenceConfig)
local Foods = require(RS.Config.FoodsConfig)
local Balance = require(RS.Shared.BalanceCurve)
setthreadidentity(8)
local Library = assert(loadstring(LibrarySource,"Axis UI"))()
local C = {
    PerfectThrow=false, SkipCutscene=true, AutoThrow=false, AutoTraining=false, AutoBonus=false,
    AutoPlace=false, AutoPickup=false, EquipBest=false, AutoSell=false, SellMutations=false,
    UpgradeStand=false, UpgradeFence=false, BuyFood=false, BestFood=false,
    TrainSeconds=30, ThrowDelay=2, IncomeCutoff=0, KeepAnimals=3, ReserveCash=0,
    Names=false, Boxes=false, Health=false, Distance=false, Skeletons=false, Chams=false,
    BoxColor=Color3.new(1,1,1), NameColor=Color3.new(1,1,1), HealthColor=Color3.new(0,1,0),
    DistanceColor=Color3.new(1,1,1), SkeletonColor=Color3.new(1,1,1), ThroughWalls=true,
}
local S = {Loaded=true,Config=C,Connections={},Errors={},Jobs={},LastAction="Idle",Stats={}}
env.AxisFood=S
S.Adapter={EntityClient={GetLocalModel=function() return LP.Character end}}
local window = Library:CreateWindow()
S.Window=window
local farming=window:AddTab("Farming")
local animals=window:AddTab("Animals")
local upgrades=window:AddTab("Upgrades")
local function toggle(group,id,label)
    local control=group:AddToggle("AF_"..id,{Text=label,Default=C[id]})
    control:OnChanged(function() C[id]=control.Value end)
    return control
end
local function slider(group,id,label,min,max)
    group:AddSlider("AF_"..id,{Text=label,Default=C[id],Min=min,Max=max,Rounding=0})
    local option=env.Options["AF_"..id]
    option:OnChanged(function() C[id]=option.Value end)
end
local throws=farming:AddLeftGroupbox("Throwing")
toggle(throws,"PerfectThrow","Perfect timing")
toggle(throws,"SkipCutscene","Skip throw cutscene")
toggle(throws,"AutoThrow","Auto throw")
slider(throws,"ThrowDelay","Pause between throws",1,30)
local reps=farming:AddRightGroupbox("Training")
local trainingToggle=toggle(reps,"AutoTraining","Auto reps")
toggle(reps,"AutoBonus","Auto x2 circle")
slider(reps,"TrainSeconds","Seconds before throwing",5,120)
local placement=animals:AddLeftGroupbox("Placement")
toggle(placement,"AutoPlace","Auto place animals")
toggle(placement,"EquipBest","Auto equip best")
toggle(placement,"AutoPickup","Pick up low income animals")
local selling=animals:AddRightGroupbox("Selling")
toggle(selling,"AutoSell","Auto sell low income animals")
slider(selling,"IncomeCutoff","Maximum income to sell or pick up",0,1000000)
slider(selling,"KeepAnimals","Keep at least this many",1,30)
toggle(selling,"SellMutations","Include mutations")
local purchases=upgrades:AddLeftGroupbox("Purchases")
toggle(purchases,"UpgradeStand","Auto upgrade training stand")
toggle(purchases,"UpgradeFence","Auto upgrade fence")
toggle(purchases,"BuyFood","Auto buy better food")
toggle(purchases,"BestFood","Auto equip best food")
slider(purchases,"ReserveCash","Keep cash",0,1000000)
local session=farming:AddRightGroupbox("Session")
local status=session:AddLabel("Idle")
local stats=session:AddLabel("Loading stats")
local function record(key,err)
    S.Errors[key]={Message=tostring(err),At=os.clock()}
end
local function job(key,callback)
    if S.Jobs[key] or not S.Loaded then return end
    S.Jobs[key]=true
    task.spawn(function()
        local ok,err=pcall(callback)
        if not ok then record(key,err) end
        S.Jobs[key]=nil
    end)
end
local nextAction={}
local function due(key,seconds)
    if os.clock()<(nextAction[key] or 0) then return false end
    nextAction[key]=os.clock()+seconds
    return true
end
local function invoke(name,...)
    S.LastAction=name
    local result=Remotes.Invoke(name,...)
    if type(result)=="table" then
        S.LastResult={Action=name,Ok=result.Ok,Reason=result.Reason}
        if result.Ok then S.Stats[name]=(S.Stats[name] or 0)+1 end
    end
    return result
end
local ownsTraining=false
local trainingStarted=0
trainingToggle:OnChanged(function()
    if C.AutoTraining and Training.IsRunning() then
        ownsTraining=true
        trainingStarted=os.clock()
    end
end)
local nextThrow=0
local throwDue=false
local hooks={}
local oldRun
oldRun=hookfunction(Meter.Run,function(self,...)
    if not S.Loaded or not C.PerfectThrow then return oldRun(self,...) end
    local oldDelay=Meter.TestAutoTap
    local oldBlocked=self.TapsBlocked
    Meter.TestAutoTap=MeterMath.HalfPeriod()
    self.TapsBlocked=true
    local result=table.pack(pcall(oldRun,self,...))
    Meter.TestAutoTap=oldDelay
    self.TapsBlocked=oldBlocked
    if not result[1] then error(result[2],0) end
    S.LastMeter=result[2]
    return table.unpack(result,2,result.n)
end)
table.insert(hooks,Meter.Run)
local runSequence
for _, value in pairs(debug.getupvalues(Throwing.Start)) do
    if type(value)=="function" and debug.info(value,"n")=="runSequence" then runSequence=value break end
end
assert(runSequence,"Native throw sequence unavailable")
local CameraRig=require(controllers.CameraRig)
local ScreenFX=require(controllers.ScreenFX)
local Movement=require(controllers.Movement)
local HUD=require(controllers.HUDController)
local oldSequence
oldSequence=hookfunction(runSequence,function(start,...)
    if not S.Loaded or not C.SkipCutscene or start.RingRush then return oldSequence(start,...) end
    local character=LP.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid then return false,"NoCharacter" end
    local gui=Instance.new("ScreenGui")
    gui.Name="AxisFastThrow"
    gui.ResetOnSpawn=false
    gui.IgnoreGuiInset=true
    gui.DisplayOrder=60
    gui.Parent=LP.PlayerGui
    local meter=Meter.new(gui)
    CameraRig.Release()
    workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
    workspace.CurrentCamera.CameraSubject=humanoid
    ScreenFX.Reset()
    HUD.SetGameplayVisible(true)
    local result=table.pack(pcall(function()
        local timing=meter:Run()
        meter:Hide()
        local resolved=invoke("Throw_Resolve",timing)
        if not resolved or not resolved.Ok then return false,resolved and resolved.Reason or "ResolveFailed" end
        S.LastFastThrow={Timing=timing,Model=resolved.ModelName,Started=os.clock()}
        local complete=invoke("Throw_Complete")
        if not complete or not complete.Ok then
            local flight=math.clamp(tonumber(resolved.FlightTime) or 1, .25, 20)
            task.wait(flight)
            complete=invoke("Throw_Complete")
        end
        if not complete or not complete.Ok then
            record("Throw completion",complete and complete.Reason or "No response")
            return false,complete and complete.Reason or "CompleteFailed"
        end
        S.LastFastThrow.Completed=true
        Throwing.Finished:Fire(resolved)
        return true,complete
    end))
    meter:Destroy()
    gui:Destroy()
    if root.Parent then root.Anchored=false end
    Movement.Unlock()
    CameraRig.Release()
    ScreenFX.Reset()
    HUD.SetGameplayVisible(true)
    if not result[1] then error(result[2],0) end
    return table.unpack(result,2,result.n)
end)
table.insert(hooks,runSequence)
local bonusCallback
local oldBind
oldBind=hookfunction(Input.BindPressed,function(action,priority,callback,...)
    local unbind=oldBind(action,priority,callback,...)
    if action=="Special" and State.Busy=="Training" then
        bonusCallback=callback
        return function(...)
            if bonusCallback==callback then bonusCallback=nil end
            return unbind(...)
        end
    end
    return unbind
end)
table.insert(hooks,Input.BindPressed)
local function protected(entry)
    return entry.Favorite==true or entry.Locked==true or entry.Protected==true
        or not C.SellMutations and entry.Mutation~=nil and entry.Mutation~="" and entry.Mutation~="Normal"
end
local function income(entry)
    return Mutations.IncomeOf(entry)
end
local function disposable(entry)
    return not protected(entry) and income(entry)<=C.IncomeCutoff
end
local function animalsJob()
    local list=Data:Get("Animals") or {}
    local count,placed=0,0
    for _,entry in pairs(list) do count=count+1 if entry.Placed then placed=placed+1 end end
    if C.AutoSell and count>C.KeepAnimals and due("Sell",2) then
        for id,entry in pairs(list) do
            if not entry.Placed and disposable(entry) then invoke("Plot_SellAnimal",id) return end
        end
    end
    if C.AutoPickup and due("Pickup",2) then
        for id,entry in pairs(list) do
            if entry.Placed and disposable(entry) then invoke("Plot_PickUpAnimal",id,true) return end
        end
    end
    if C.EquipBest and due("EquipBest",8) then invoke("Plot_EquipBest") return end
    if not C.AutoPlace or placed>=Fence.SlotsFor(Data:Get("FenceLevel") or 0) or not due("Place",1.5) then return end
    local plot=Plot.GetPlotPart()
    if not plot then return end
    local id
    for key,entry in pairs(list) do
        if not entry.Placed and not ((C.AutoPickup or C.AutoSell) and disposable(entry)) then id=key break end
    end
    if not id then return end
    local position
    local halfX,halfZ=plot.Size.X/2-5,plot.Size.Z/2-5
    for x=-halfX,halfX,8 do
        for z=-halfZ,halfZ,8 do
            local free=true
            for _,entry in pairs(list) do
                if entry.Placed and type(entry.X)=="number" and type(entry.Z)=="number"
                    and Vector2.new(x-entry.X,z-entry.Z).Magnitude<7 then free=false break end
            end
            if free then position=plot.CFrame:PointToWorldSpace(Vector3.new(x,plot.Size.Y/2,z)) break end
        end
        if position then break end
    end
    if not position then return end
    local equip=invoke("Plot_EquipAnimal",id)
    if equip and equip.Ok then invoke("Plot_PlaceAnimal",id,position) end
end
local function upgradesJob()
    local budget=math.max(0,(Data:Get("Money") or 0)-C.ReserveCash)
    local stand=Data:Get("Stand") or 0
    if C.UpgradeStand and due("Stand",3) then
        local nextStand=stand<Stands.Count() and Stands.Get(stand+1)
        if nextStand and Balance.GetItemPrice(LP,nextStand)<=budget then invoke("Stand_Upgrade") return end
    end
    local level=Data:Get("FenceLevel") or 0
    if C.UpgradeFence and level<Fence.MaxLevel() and due("Fence",3) then
        local upgrade=Fence.Get(level+1)
        if upgrade and Balance.GetItemPrice(LP,upgrade)<=budget then invoke("Plot_UpgradeFence") return end
    end
    local owned=Data:Get("OwnedFoods") or {}
    local best=0
    for index,value in pairs(owned) do if value==true and tonumber(index) and tonumber(index)>best then best=tonumber(index) end end
    if C.BuyFood and due("BuyFood",3) then
        local nextFood=Foods.All[best+1]
        if nextFood and Balance.GetItemPrice(LP,nextFood)<=budget then invoke("Shop_Buy",best+1) return end
    end
    if C.BestFood and best>0 and best~=(Data:Get("EquippedFood") or 0) and due("EquipFood",2) then invoke("Shop_Equip",best) end
end
local function farmStep()
    if ownsTraining and (not C.AutoTraining or ((C.AutoThrow or C.UpgradeStand or C.UpgradeFence or C.BuyFood) and os.clock()-trainingStarted>=C.TrainSeconds)) then
        ownsTraining=false
        throwDue=C.AutoThrow
        Training.Stop()
        return
    end
    if State.Busy or State.OfflineOpen or not Data:IsReady() then return end
    if C.AutoThrow and os.clock()>=nextThrow and (throwDue or not C.AutoTraining or (Data:Get("Stand") or 0)<1) then
        throwDue=false
        S.LastAction="Throwing"
        Throwing.Start()
        nextThrow=os.clock()+C.ThrowDelay
        return
    end
    if C.AutoTraining and not Training.IsRunning() and (Data:Get("Stand") or 0)>0 then
        ownsTraining=true trainingStarted=os.clock()
        S.LastAction="Training"
        task.spawn(function()
            local ok,err=pcall(Training.Start)
            ownsTraining=false
            if not ok then record("Training",err) end
        end)
    end
end
local lastTick=0
local connection=RunService.Heartbeat:Connect(function()
    if not S.Loaded or os.clock()-lastTick<.15 then return end lastTick=os.clock()
    if C.AutoBonus and bonusCallback then
        local callback=bonusCallback
        local ok,claimed=pcall(callback)
        if ok and claimed then S.Stats.Bonus=(S.Stats.Bonus or 0)+1
        elseif not ok then record("Bonus",claimed) end
    end
    job("Cycle",function()
        if not State.Busy and not State.OfflineOpen then
            animalsJob()
            if S.Loaded and not State.Busy then upgradesJob() end
        end
        if S.Loaded then farmStep() end
    end)
    setthreadidentity(8)
    status:SetText(State.Busy and tostring(State.Busy) or S.LastAction)
    stats:SetText("Level "..tostring(Data:Get("Level") or 0).." | Cash "..tostring(math.floor(Data:Get("Money") or 0)))
end)
table.insert(S.Connections,connection)
function S.DisableAll()
    for id,value in pairs(C) do if type(value)=="boolean" then
        local control=env.Toggles["AF_"..id]
        if control then control:SetValue(false) end
    end end
    if ownsTraining then ownsTraining=false Training.Stop() end
end
local function cleanup()
    if not S.Loaded then return end
    if S.VisualEffects then for _,effect in pairs(S.VisualEffects) do effect:Destroy() end end
    S.Loaded=false
    for _,conn in ipairs(S.Connections) do conn:Disconnect() end
    for _,fn in ipairs(hooks) do pcall(restorefunction,fn) end
    if ownsTraining then ownsTraining=false pcall(Training.Stop) end
end
Library:OnUnload(cleanup)
S.Unload=function() cleanup() Library:Unload() end
local travel=upgrades:AddRightGroupbox("Travel")
travel:AddButton({Text="Training stand",Func=Plot.TeleportToStand})
travel:AddButton({Text="Food shop",Func=Plot.TeleportToShop})
session:AddButton({Text="Disable all",Func=S.DisableAll})
setthreadidentity(8)

local visualTab=window:AddTab("Visuals")
local effectsGroup=visualTab:AddLeftGroupbox("Players")
C.Glow=false C.ShaderChams=false
C.GlowColor=Color3.fromRGB(65,155,255) C.ShaderColor=Color3.fromRGB(65,155,255)
C.GlowIntensity=0.7 C.ShaderIntensity=0.5
local function effectToggle(key,text,color)
    local control=effectsGroup:AddToggle("AF_"..key,{Text=text,Default=false})
    control:OnChanged(function() C[key]=control.Value end)
    local picker=control:AddColorPicker("AF_"..color,{Default=C[color]})
    picker:OnChanged(function() C[color]=picker.Value end)
end
effectToggle("Glow","Glow","GlowColor")
effectToggle("ShaderChams","Shader chams","ShaderColor")
slider(effectsGroup,"GlowIntensity","Glow intensity",0,100)
slider(effectsGroup,"ShaderIntensity","Shader intensity",0,100)
C.GlowIntensity=70 C.ShaderIntensity=50
getgenv().Options.AF_GlowIntensity:SetValue(70)
getgenv().Options.AF_ShaderIntensity:SetValue(50)
local Effects=assert(loadstring([==[
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
]==],"ESP effects"))()
S.VisualEffects={}
local elapsed=0
table.insert(S.Connections,RunService.RenderStepped:Connect(function(dt)
    elapsed+=dt if elapsed<0.05 then return end elapsed=0
    local live={}
    if C.Glow or C.ShaderChams then
        for _,player in ipairs(Players:GetPlayers()) do
            local model=player.Character
            if player~=LP and model and model:FindFirstChildOfClass("Humanoid") then
                live[model]=true
                local effect=S.VisualEffects[model]
                if not effect then effect=Effects.new(model,Library.ScreenGui) S.VisualEffects[model]=effect end
                if workspace.CurrentCamera then effect:Update(workspace.CurrentCamera,C.ShaderColor,"ForceField",0.25,true,{Glow=C.Glow,GlowColor=C.GlowColor,GlowIntensity=C.GlowIntensity/100,Shader=C.ShaderChams,ShaderColor=C.ShaderColor,ShaderIntensity=C.ShaderIntensity/100}) end
            end
        end
    end
    for model,effect in pairs(S.VisualEffects) do if not live[model] then effect:Destroy() S.VisualEffects[model]=nil end end
end))

Library:Finish(S)
S.DisableAll()
env.Toggles.AF_SkipCutscene:SetValue(true)
C.SkipCutscene=true
