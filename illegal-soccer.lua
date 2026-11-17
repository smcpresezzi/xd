local Sources={
    UI=[=[
return function(context)
    local config=context.Config
    local state=context.State
    local library=assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua")))()
    local playerGui=game:GetService("Players").LocalPlayer.PlayerGui
    library.Holder.Instance.Parent=playerGui
    library.UnusedHolder.Instance.Parent=playerGui
    local logo=library.Folders.Assets.."/axis-logo.png"
    if not isfile(logo)then writefile(logo,game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/assets/axis-logo.png"))end
    library.MenuKeybind=tostring(Enum.KeyCode.RightShift)
    local window=library:Window({Name="",SubName="",Logo=getcustomasset(logo),Wordmark=true})
    local controls={}
    local bindsReady=false
    local bound={ShotAimbot=true,AutoGoalkeeper=true,BallMagnet=true,SpeedBoost=true,ItemAimbot=true}
    local function toggle(section,key,name,color)
        local control=section:Toggle({Name=name,Flag="IS_"..key,Default=config[key],Callback=function(value)context.Set(key,value)end})
        controls[key]=control
        if bound[key]then control:GetBind({Flag="IS_"..key.."Key",Default=Enum.KeyCode.Backspace,Mode="Toggle",Callback=function(value)if bindsReady and not library.RestoringConfig then control:Set(value)end end})end
        if color then control:Colorpicker({Flag="IS_"..color,Default=config[color],Alpha=1,Callback=function(value)config[color]=value end})end
        return control
    end
    local function slider(section,key,name,minimum,maximum,step)
        local control=section:Slider({Name=name,Flag="IS_"..key,Default=config[key],Min=minimum,Max=maximum,Decimals=step or 1,Callback=function(value)context.Set(key,value)end})
        controls[key]=control
    end
    local function dropdown(section,key,name,items)
        local control=section:Dropdown({Name=name,Flag="IS_"..key,Default=config[key],Items=items,Callback=function(value)context.Set(key,value)end})
        controls[key]=control
    end
    local combat=window:Page({Name="Combat",Icon="134242818164054"})
    local shots=combat:Section({Name="Shooting",Side=1})
    toggle(shots,"ShotAimbot","Enabled")
    dropdown(shots,"ShotPlacement","Placement",{"Auto","Upper Left","Upper Right","Lower Left","Lower Right","Center"})
    dropdown(shots,"TargetPost","Target goal",{"Automatic","Team1","Team2"})
    slider(shots,"ShootRange","Shoot range",25,250,5)
    slider(shots,"ShotMargin","Post clearance",1.5,4,.1)
    toggle(shots,"UnsavableShot","Unsavable shot")
    toggle(shots,"PerfectCharge","Perfect charge")
    toggle(shots,"FlickShot","Flick shot")
    toggle(shots,"CurveShot","Curve shot")
    dropdown(shots,"CurveSide","Curve side",{"Auto","Left","Right"})
    slider(shots,"ShotCurve","Curve strength",-100,100)
    toggle(shots,"FeintShot","Feint shot")
    slider(shots,"FeintChance","Feint chance (%)",0,100)
    toggle(shots,"ShotPreview","Shot preview","ShotColor")
    local passing=combat:Section({Name="Passing",Side=2})
    toggle(passing,"AutoPass","Auto pass")
    slider(passing,"PassRange","Range",15,160)
    toggle(passing,"AutoVolley","Auto volley")
    toggle(passing,"KeeperClearAimbot","Keeper clear aim")
    toggle(passing,"AutoCallForPass","Call for pass")
    slider(passing,"CallInterval","Call interval",1,8,.1)
    local defense=combat:Section({Name="Defense",Side=1})
    toggle(defense,"TackleAimbot","Tackle aim")
    toggle(defense,"AutoTackle","Auto tackle")
    slider(defense,"TackleRange","Tackle range",4,24)
    toggle(defense,"AutoDribble","Auto dribble")
    slider(defense,"DribbleRange","Dribble range",5,25)
    local keeper=combat:Section({Name="Goalkeeper",Side=2})
    toggle(keeper,"AutoGoalkeeper","Enabled")
    toggle(keeper,"KeeperAutoTackle","Auto tackle")
    slider(keeper,"KeeperTackleRange","Tackle range",4,24)
    slider(keeper,"KeeperReaction","Reaction lead",.05,.45,.01)
    slider(keeper,"KeeperContactLead","Tackle reaction lead",0,.45,.01)
    toggle(keeper,"KeeperDiveOnContact","Dive on contact")
    slider(keeper,"KeeperDiveRange","Dive range",5,18,.5)
    local items=combat:Section({Name="Items",Side=2})
    toggle(items,"ItemAimbot","Item aim")
    slider(items,"ItemAimFOV","Aim FOV",30,500)
    toggle(items,"ShowItemFOV","Show FOV","ItemFOVColor")
    toggle(items,"AutoUseItem","Auto use")
    local visuals=window:Page({Name="Visuals",Icon="100033680381365"})
    local players=visuals:Section({Name="Players",Side=1})
    toggle(players,"PlayerESP","Boxes","EnemyColor")
    toggle(players,"PlayerNames","Names","NameColor")
    toggle(players,"PlayerHealth","Health","HealthColor")
    toggle(players,"PlayerDistance","Distance","DistanceColor")
    toggle(players,"PlayerSkeletons","Skeletons","SkeletonColor")
    slider(players,"SkeletonThickness","Thickness",1,4,.1)
    toggle(players,"PlayerTracers","Tracers","TracerColor")
    toggle(players,"ShowTeammates","Teammates","TeamColor")
    slider(players,"ESPDistance","Max distance",50,2000)
    local chams=visuals:Section({Name="Chams",Side=2})
    toggle(chams,"PlayerChams","Enabled","ChamsColor")
    dropdown(chams,"ChamsMaterial","Material",{"SmoothPlastic","Plastic","Neon","ForceField","Glass","Metal","DiamondPlate","Foil","Wood","Marble","Ice","Fabric"})
    slider(chams,"ChamsTransparency","Transparency",0,.9,.05)
    toggle(chams,"PlayerGlow","Glow","GlowColor")
    toggle(chams,"PlayerShader","Shader chams","ShaderColor")
    local ball=visuals:Section({Name="Ball",Side=2})
    toggle(ball,"BallESP","Ball ESP","BallColor")
    toggle(ball,"FlightPath","Flight path","PathColor")
    slider(ball,"FlightPathSeconds","Prediction seconds",.5,5,.1)
    toggle(ball,"LandingMarker","Landing marker","LandingColor")
    local world=visuals:Section({Name="World items",Side=1})
    toggle(world,"ItemBoxESP","Item boxes","ItemBoxColor")
    toggle(world,"WorldItemESP","World items","ItemColor")
    toggle(world,"ProjectileESP","Projectiles","ProjectileColor")
    local utility=window:Page({Name="Utility",Icon="112148279212860"})
    local movement=utility:Section({Name="Movement",Side=1})
    toggle(movement,"SpeedBoost","Speed boost")
    slider(movement,"SpeedMultiplier","Multiplier",1,2.5,.05)
    toggle(movement,"AntiRagdoll","Anti ragdoll")
    toggle(movement,"AutoSprint","Auto sprint")
    toggle(movement,"InfiniteStamina","Infinite stamina")
    toggle(movement,"NoBallSlowdown","No ball slowdown")
    toggle(movement,"FullSpeedCharge","Full speed charge")
    local possession=utility:Section({Name="Possession",Side=2})
    toggle(possession,"BallMagnet","Ball magnet")
    slider(possession,"MagnetRange","Range",4,24)
    slider(possession,"MagnetStealRange","Steal distance",2,5,.1)
    slider(possession,"MagnetCooldown","Cooldown",.3,2,.1)
    library:CreateSettingsPage(window)
    local settings=window.Pages[#window.Pages]:Section({Name="Session",Side=2})
    settings:Button({Name="Disable all",Callback=function()
        for key,control in pairs(controls)do if typeof(config[key])=="boolean"then control:Set(false)end end
    end})
    local nativeUnload=library.Unload
    function library:Unload()
        if state.Alive then context.Unload()else nativeUnload(self)end
    end
    local function updateBlocker(gui,button)
        if button.Parent then button.Modal=gui.Enabled and window.IsOpen end
    end
    local blockers={}
    for _,gui in ipairs(library.Holder.Instance.Parent:GetDescendants())do
        if gui:IsA("ScreenGui")and gui.Name=="AxisBindModal"then
            local button=gui:FindFirstChild("Backdrop")
            if button then
                blockers[gui]=button
                context.Connect(gui:GetPropertyChangedSignal("Enabled"),function()updateBlocker(gui,button)end)
                updateBlocker(gui,button)
            end
        end
    end
    context.Connect(window.Items.MainFrame.Instance:GetPropertyChangedSignal("Visible"),function()
        for gui,button in pairs(blockers)do updateBlocker(gui,button)end
    end)
    if game:GetService("UserInputService").TouchEnabled then
        local mobile=Instance.new("ScreenGui")
        mobile.Name="AxisSoccerMobile"
        mobile.ResetOnSpawn=false
        mobile.IgnoreGuiInset=false
        mobile.DisplayOrder=150
        mobile.Parent=playerGui
        state.MobileGui=mobile
        local dock=Instance.new("Frame")
        dock.AnchorPoint=Vector2.new(1,0)
        dock.Position=UDim2.new(1,-12,0,70)
        dock.Size=UDim2.fromOffset(260,42)
        dock.BackgroundColor3=library.Theme.Background
        dock.BorderSizePixel=0
        dock.Parent=mobile
        local layout=Instance.new("UIListLayout")
        layout.FillDirection=Enum.FillDirection.Horizontal
        layout.HorizontalAlignment=Enum.HorizontalAlignment.Center
        layout.VerticalAlignment=Enum.VerticalAlignment.Center
        layout.Padding=UDim.new(0,4)
        layout.Parent=dock
        local buttons={}
        for _,entry in ipairs({{"ShotAimbot","Aim"},{"FlickShot","Flick"},{"AutoGoalkeeper","Keeper"},{"BallMagnet","Magnet"}})do
            local key,label=entry[1],entry[2]
            local button=Instance.new("TextButton")
            button.Name=key
            button.Size=UDim2.fromOffset(61,34)
            button.BackgroundColor3=library.Theme.Element
            button.BorderSizePixel=0
            button.TextColor3=library.Theme.Text
            button.TextSize=12
            button.Font=Enum.Font.GothamMedium
            button.Text=label
            button.Parent=dock
            buttons[key]={Button=button,Label=label}
            context.Connect(button.Activated,function()
                local control=controls[key]
                if control then control:Set(not config[key])end
            end)
        end
        local elapsed=0
        context.Connect(game:GetService("RunService").Heartbeat,function(dt)
            elapsed+=dt
            if elapsed<.2 then return end
            elapsed=0
            for key,entry in pairs(buttons)do
                entry.Button.BackgroundColor3=config[key]and library.Theme.Accent or library.Theme.Element
                entry.Button.Text=entry.Label
            end
        end)
    end
    window:Init()
    bindsReady=true
    return {Library=library,Window=window,Controls=controls}
end
]=],
    Visuals=[=[
return function(context)
    local config=context.Config
    local state=context.State
    local overlay=context.Overlay
    local create=context.Create
    local materialChams=assert(loadstring(context.Chams))()
    local entries={}
    local links={{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
        {"LeftLowerLeg","LeftFoot"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}
    local function line()
        return create("Frame",{BorderSizePixel=0,BackgroundColor3=config.SkeletonColor,AnchorPoint=Vector2.new(.5,.5),Visible=false,ZIndex=3},overlay)
    end
    local function drawLine(frame,a,b,color,thickness)
        local delta=b-a
        frame.Position=UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
        frame.Size=UDim2.fromOffset(delta.Magnitude,thickness)
        frame.Rotation=math.deg(math.atan2(delta.Y,delta.X))
        frame.BackgroundColor3=color frame.Visible=true
    end
    local function text()
        return create("TextLabel",{BackgroundTransparency=1,BorderSizePixel=0,Font=Enum.Font.GothamMedium,TextSize=12,TextColor3=Color3.new(1,1,1),
            TextStrokeTransparency=.25,TextStrokeColor3=Color3.new(0,0,0),Size=UDim2.fromOffset(200,18),AnchorPoint=Vector2.new(.5,1),Visible=false,ZIndex=4},overlay)
    end
    local function makeEntry(model)
        local entry={Bones={}}
        entry.Box=create("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Visible=false,ZIndex=2},overlay)
        entry.Stroke=create("UIStroke",{Thickness=1,Color=config.EnemyColor},entry.Box)
        entry.Name=text()entry.Distance=text()entry.Tracer=line()
        entry.Health=create("Frame",{BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(16,17,20),Visible=false,ZIndex=2},overlay)
        entry.Fill=create("Frame",{BorderSizePixel=0,AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),BackgroundColor3=config.HealthColor},entry.Health)
        for _,pair in ipairs(links)do
            if model:FindFirstChild(pair[1])and model:FindFirstChild(pair[2])then entry.Bones[#entry.Bones+1]={A=pair[1],B=pair[2],Line=line()}end
        end
        entry.Chams=materialChams.new(model,overlay)
        entries[model]=entry
        return entry
    end
    local function remove(entry)
        for _,key in ipairs({"Box","Name","Distance","Tracer","Health"})do entry[key]:Destroy()end
        for _,bone in ipairs(entry.Bones)do bone.Line:Destroy()end
        entry.Chams:Destroy()
    end
    local function project(camera,point)
        local projected,visible=camera:WorldToViewportPoint(point)
        return Vector2.new(projected.X,projected.Y),visible and projected.Z>0
    end
    local function render(camera,origin)
        local seen={}
        local any=config.PlayerESP or config.PlayerNames or config.PlayerDistance or config.PlayerHealth or config.PlayerSkeletons
            or config.PlayerTracers or config.PlayerChams or config.PlayerGlow or config.PlayerShader
        if any then for _,actor in ipairs(state.Actors)do
            local model=actor.Character
            if model.Parent and actor.Root.Parent and(not actor.Friendly or config.ShowTeammates)and(actor.Root.Position-origin).Magnitude<=config.ESPDistance then
                seen[model]=true
                local entry=entries[model]or makeEntry(model)
                entry.Box.Visible=false entry.Name.Visible=false entry.Distance.Visible=false entry.Tracer.Visible=false entry.Health.Visible=false
                for _,bone in ipairs(entry.Bones)do bone.Line.Visible=false end
                local color=actor.Friendly and config.TeamColor or config.EnemyColor
                local top,topVisible=project(camera,actor.Root.Position+Vector3.new(0,3.5,0))
                local bottom,bottomVisible=project(camera,actor.Root.Position-Vector3.new(0,3.5,0))
                if topVisible and bottomVisible then
                    local height=math.abs(bottom.Y-top.Y)local width=height*.55
                    local x,y=top.X-width/2,math.min(top.Y,bottom.Y)
                    entry.Box.Position=UDim2.fromOffset(x,y)entry.Box.Size=UDim2.fromOffset(width,height)
                    entry.Stroke.Color=color entry.Box.Visible=config.PlayerESP
                    entry.Name.Text=actor.Name..(actor.Keeper and " · GK"or "")entry.Name.TextColor3=config.NameColor
                    entry.Name.Position=UDim2.fromOffset(top.X,y-2)entry.Name.Visible=config.PlayerNames
                    entry.Distance.Text=string.format("%dm",math.floor((actor.Root.Position-origin).Magnitude/3.57))
                    entry.Distance.TextColor3=config.DistanceColor entry.Distance.Position=UDim2.fromOffset(top.X,y+height+18)entry.Distance.Visible=config.PlayerDistance
                    local humanoid=model:FindFirstChildOfClass("Humanoid")
                    if config.PlayerHealth and humanoid then
                        entry.Health.Position=UDim2.fromOffset(x-5,y)entry.Health.Size=UDim2.fromOffset(3,height)entry.Health.Visible=true
                        entry.Fill.Size=UDim2.fromScale(1,math.clamp(humanoid.Health/math.max(humanoid.MaxHealth,1),0,1))entry.Fill.BackgroundColor3=config.HealthColor
                    end
                    if config.PlayerTracers then drawLine(entry.Tracer,Vector2.new(camera.ViewportSize.X*.5,camera.ViewportSize.Y-3),bottom,config.TracerColor,1.2)end
                end
                if config.PlayerSkeletons then for _,bone in ipairs(entry.Bones)do
                    local a,b=model:FindFirstChild(bone.A),model:FindFirstChild(bone.B)
                    if a and b then local pa,va=project(camera,a.Position)local pb,vb=project(camera,b.Position)
                        if va and vb then drawLine(bone.Line,pa,pb,config.SkeletonColor,config.SkeletonThickness)end
                    end
                end end
                if config.PlayerChams or config.PlayerGlow or config.PlayerShader then
                    entry.Chams:Update(camera,config.ChamsColor,config.ChamsMaterial,config.ChamsTransparency,true,
                        {Base=config.PlayerChams,Glow=config.PlayerGlow,GlowColor=config.GlowColor,GlowIntensity=.8,Shader=config.PlayerShader,ShaderColor=config.ShaderColor,ShaderIntensity=.6})
                else entry.Chams:SetEnabled(false)end
            end
        end end
        for model,entry in pairs(entries)do if not seen[model]then remove(entry)entries[model]=nil end end
    end
    local function cleanup()
        for _,entry in pairs(entries)do remove(entry)end
        table.clear(entries)
    end
    return {Render=render,Cleanup=cleanup}
end
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
]=]
}
local env = getgenv and getgenv() or _G
local previous_config = env.AxisIllegalSoccer and table.clone(env.AxisIllegalSoccer.Config)
if env.AxisIllegalSoccer then
    env.AxisIllegalSoccer.Unload()
end
assert(game.GameId == 10155360168, "Illegal Soccer: unsupported universe")
local queue_teleport = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport)
if queue_teleport then
    pcall(queue_teleport, 'loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/5f4d88230f244edad4322df84b85dc0f.lua"))()')
end

local players = game:GetService("Players")
local run_service = game:GetService("RunService")
local input_service = game:GetService("UserInputService")
local http_service = game:GetService("HttpService")
local collection_service = game:GetService("CollectionService")
local local_player = players.LocalPlayer
local storage = game:GetService("ReplicatedStorage")
local player_gui = local_player:WaitForChild("PlayerGui")
local gui_parent = player_gui
local library, window
local player_visuals
local ui_controls = {}

local state = {
    Alive = true,
    Connections = {},
    Hooks = {},
    Errors = {},
    Actors = {},
    DribbleThreats = {},
    DribbleProbe = {},
    Items = {},
    Next = {},
    Points = {},
    Version = "1.0.0",
}
local config = {
    SpeedBoost=false,SpeedMultiplier=1.3,AntiRagdoll=false,MagnetCooldown=.7,ShotMargin=2.5,
    PlayerNames=false,PlayerHealth=false,PlayerDistance=false,PlayerSkeletons=false,SkeletonThickness=1.2,
    PlayerGlow=false,PlayerShader=false,ChamsMaterial="Neon",ChamsTransparency=.25,
    NameColor=Color3.new(1,1,1),HealthColor=Color3.fromRGB(90,255,130),DistanceColor=Color3.new(1,1,1),
    SkeletonColor=Color3.fromRGB(65,155,255),TracerColor=Color3.fromRGB(65,155,255),ChamsColor=Color3.fromRGB(65,155,255),
    GlowColor=Color3.fromRGB(65,155,255),ShaderColor=Color3.fromRGB(65,155,255),ShotColor=Color3.fromRGB(65,155,255),
    LandingColor=Color3.fromRGB(103,227,198),ProjectileColor=Color3.fromRGB(255,130,90),ItemBoxColor=Color3.fromRGB(190,156,255),ItemFOVColor=Color3.new(1,1,1),
    ShotAimbot = false, ShotPlacement = "Auto", TargetPost = "Automatic", ShootRange = 110,
    UnsavableShot = false, PerfectCharge = false, AutoPass = false,
    CurveShot = false, CurveSide = "Auto", ShotCurve = 70, FeintShot = false, FeintChance = 50, FlickShot = false, KeeperAutoTackle = false, KeeperTackleRange = 12,
    KeeperDiveOnContact = true, KeeperDiveRange = 10,
    AutoVolley = false, TackleAimbot = false, AutoTackle = false,
    AutoDribble = false, AutoGoalkeeper = false, KeeperClearAimbot = false,
    AutoCallForPass = false, AutoSprint = false, InfiniteStamina = false,
    NoBallSlowdown = false, FullSpeedCharge = false, BallMagnet = false,
    FlightPath = false, FlightPathSeconds = 3, LandingMarker = false,
    ShotPreview = false, BallESP = false, PlayerESP = false,
    PlayerTracers = false, PlayerChams = false, ItemBoxESP = false,
    WorldItemESP = false, ProjectileESP = false, ESPDistance = 600,
    ShowTeammates = true, ItemAimbot = false, ItemAimFOV = 180,
    ShowItemFOV = false, AutoUseItem = false, TackleRange = 15,
    DribbleRange = 14, MagnetRange = 14, MagnetStealRange = 3.2, PassRange = 100,
    CallInterval = 2.5, KeeperReaction = 0.18, KeeperContactLead = 0.12,
    EnemyColor = Color3.fromRGB(250, 109, 129),
    TeamColor = Color3.fromRGB(103, 191, 255),
    BallColor = Color3.fromRGB(255, 218, 116),
    ItemColor = Color3.fromRGB(190, 156, 255),
    PathColor = Color3.fromRGB(103, 227, 198),
}
if previous_config then
    for key, value in previous_config do
        if typeof(value) == typeof(config[key]) then config[key] = value end
    end
end
local autosave_path="Axis/Config/"..tostring(game.GameId).."/autosave.json"
if isfile and readfile and isfile(autosave_path)then
    local ok,saved=pcall(function()return http_service:JSONDecode(readfile(autosave_path))end)
    if ok and type(saved)=="table"then
        for key,default in pairs(config)do
            local value=saved["IS_"..key]
            if typeof(value)==typeof(default)then
                config[key]=value
            elseif typeof(default)=="Color3"and type(value)=="table"and type(value.Color)=="string"then
                local valid,color=pcall(Color3.fromHex,value.Color)
                if valid then config[key]=color end
            end
        end
    end
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    state.Connections[#state.Connections + 1] = connection
    return connection
end

local function guarded(name, callback, ...)
    if setthreadidentity then setthreadidentity(8)end
    local result=table.pack(pcall(callback,...))
    if not result[1]then state.Errors[name]=tostring(result[2])return nil end
    return table.unpack(result,2,result.n)
end

local function module(path)
    local object = storage
    for name in path:gmatch("[^.]+") do
        object = assert(object:FindFirstChild(name), "Missing game module: " .. path)
    end
    return require(object)
end

local modules = {
    Renderer = module("Client.Gameplay.Ball.Renderer"),
    Physics = module("Modules.Ball.Physics"),
    Shoot = module("Modules.Actions.Shoot"),
    KickCore = module("Modules.Actions.KickCore"),
    KickPowerups = module("Modules.Actions.KickPowerups"),
    Throw = module("Modules.Actions.Throw"),
    Carry = module("Modules.Ball.Carry"),
    ActorTeams = module("Client.Gameplay.ActorTeams"),
    Practice = module("Client.Gameplay.PracticeSession"),
    PracticeBoundary = module("Modules.Gameplay.PracticeBoundaryWorld"),
    Actors = module("Modules.Characters.Actors"),
    Controls = module("Modules.Gameplay.Controls"),
    ShotAssist = module("Modules.Actions.ShotAimAssist"),
    CharacterMotion = module("Modules.Characters.CharacterMotion"),
    CharacterControllers = module("Modules.Characters.CharacterControllers"),
    Clock = module("Client.Player.CharacterMotionSmoothing"),
    Reticle = module("Client.Interface.Reticle"),
    Protocol = module("Modules.Actions.ActionRemoteProtocol"),
    ClientShoot = module("Client.Gameplay.Actions.Shoot"),
    Pass = module("Client.Gameplay.Actions.Pass"),
    Volley = module("Client.Gameplay.Actions.VolleyOpportunity"),
    Dodge = module("Client.Gameplay.Actions.Dodge"),
    DodgeAction = module("Modules.Actions.Dodge"),
    SlideTackle = module("Modules.Actions.SlideTackle"),
    Tackle = module("Client.Gameplay.Actions.SlideTackleInput"),
    Call = module("Client.Gameplay.Actions.CallForPass"),
    Sprint = module("Client.Gameplay.Player.Sprint"),
    Movement = module("Client.Gameplay.Player.Movement"),
    TurnControl = module("Client.Gameplay.Player.TurnControl"),
    ActionMovement = module("Modules.Actions.ActionMovement"),
    Keeper = module("Client.Gameplay.Player.GoalkeeperRole"),
    Dive = module("Modules.Actions.GoalkeeperDive"),
    ActionCharge = module("Modules.Actions.ActionChargeState"),
    Hitboxes = module("Modules.Gameplay.HitboxSettings"),
    Mobile = module("Client.Interface.Mobile"),
    DiveAssist = module("Modules.Actions.GoalkeeperDiveAssist"),
    ChargePreview = module("Client.Gameplay.Actions.ChargePathPreview"),
    ItemUse = module("Client.Gameplay.ItemUseState"),
    Ragdoll = module("Modules.Characters.Ragdoll"),
    RainbowFlick = module("Modules.Actions.RainbowFlick"),
}

local function patch(target, key, factory)
    local original = assert(target[key], "Missing function: " .. key)
    local replacement = factory(original)
    target[key] = replacement
    state.Hooks[#state.Hooks + 1] = {target, key, original, replacement}
    return original
end

local function is_goalkeeper()
    local character=local_player.Character
    return character~=nil and character:GetAttribute("ActiveGoalkeeper")==true
end

local function root_of(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function local_root()
    return root_of(local_player.Character)
end

local function flat(vector)
    local result = Vector3.new(vector.X, 0, vector.Z)
    return result.Magnitude > 0.001 and result.Unit or nil
end

local function ready(name, seconds)
    local now = os.clock()
    if now < (state.Next[name] or 0) then
        return false
    end
    state.Next[name] = now + seconds
    return true
end

local function owns_ball()
    return modules.Renderer.IsBoundBallOwnedBy(local_player.UserId)
end

local function can_act()
    local character = local_player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and local_root()
        and(modules.ActorTeams.GetActorTeamName(local_player)~=nil or (modules.Practice.IsActive()or modules.Practice.IsInWing())or modules.Practice.IsInWing())
        and (config.AntiRagdoll or not character:GetAttribute("Ragdolled"))
        and not character:GetAttribute("Stunned")
        and not input_service:GetFocusedTextBox()
        and not(window and window.IsOpen)
end

local function refresh_actors()
    local list = {}
    local team = modules.ActorTeams.GetActorTeamName(local_player)
    for _, character in modules.Actors.GetAllCharacterModels() do
        local root = root_of(character)
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if character ~= local_player.Character and root and humanoid and humanoid.Health > 0 then
            local actor = modules.Actors.GetFromCharacter(character)
            local actor_team = modules.ActorTeams.GetCharacterTeamName(character)
            if (modules.Practice.IsActive()or modules.Practice.IsInWing()) then actor_team = actor_team or character:GetAttribute("PracticeTeam") end
            if actor then
                local friendly = team ~= nil and team == actor_team
                if (modules.Practice.IsActive()or modules.Practice.IsInWing()) and character:GetAttribute("PracticeTeam") then
                    if character:GetAttribute("ActiveGoalkeeper") or is_goalkeeper() then friendly = false end
                end
                local name = actor.DisplayName
                if not name or name == "" then name = character.Name == "PracticeBot" and "Practice Bot" or character.Name end
                list[#list + 1] = {
                    Character = character, Root = root, Actor = actor,
                    UserId = modules.Actors.GetUserId(actor), Team = actor_team,
                    Friendly = friendly,
                    Name = name,
                    Keeper = character:GetAttribute("ActiveGoalkeeper") == true,
                }
            end
        end
    end
    state.Actors = list
end

local function goal_for(own)
    if (modules.Practice.IsActive()or modules.Practice.IsInWing()) then
        if own then return modules.Practice.GetDefendedGoalPart(), "Practice" end
        local root = local_root()
        local best, distance = nil, math.huge
        local goalParts=modules.Practice.GetGoalParts()
        if not goalParts then
            goalParts={}
            local lobby=workspace:FindFirstChild("Lobby")
            local practice=lobby and lobby:FindFirstChild("Practice")
            local folder=practice and practice:FindFirstChild("Goals")
            if folder then for _,side in ipairs(folder:GetChildren())do
                local part=side:FindFirstChild("Goal")if part and part:IsA("BasePart")then goalParts[#goalParts+1]=part end
            end end
        end
        if config.TargetPost~="Automatic"then
            local offense={}
            for _,part in ipairs(goalParts)do if part.Parent.Name~="Defence"then offense[#offense+1]=part end end
            table.sort(offense,function(a,b)return a.Position.Z<b.Position.Z end)
            return offense[config.TargetPost=="Team1"and 1 or 2],"Practice"
        end
        for _, goal in goalParts do
            if root and goal.Parent.Name ~= "Defence" and (goal.Position - root.Position).Magnitude < distance then
                best, distance = goal, (goal.Position - root.Position).Magnitude
            end
        end
        return best, "Practice"
    end
    local map = workspace:FindFirstChild("Map")
    local data = map and map:FindFirstChild("Data")
    if not data then return nil end
    local team = modules.ActorTeams.GetActorTeamName(local_player)
    local name
    if not own and config.TargetPost ~= "Automatic" then
        name = config.TargetPost
    elseif team == "Team1" or team == "Team2" then
        name = own and team or (team == "Team1" and "Team2" or "Team1")
    end
    local side = name and data:FindFirstChild(name)
    return side and side:FindFirstChild("Goal"), name
end

local function get_mouth(goal)
    if (modules.Practice.IsActive()or modules.Practice.IsInWing()) then
        local axis = goal.Size.X >= goal.Size.Z and goal.CFrame.LookVector or goal.CFrame.RightVector
        local root = local_root()
        if root and axis:Dot(root.Position - goal.Position) < 0 then axis = -axis end
        return modules.ShotAssist.GetGoalMouth(goal, goal.Position + axis * 100)
    end
    local map = workspace:FindFirstChild("Map")
    local data = map and map:FindFirstChild("Data")
    local center = data and data:FindFirstChild("Center")
    return modules.ShotAssist.GetGoalMouth(goal, center and center.Position or Vector3.zero)
end

local function shot_clearance()
    return math.max(modules.Physics.BallRadius + .8, config.ShotMargin)
end

local function within_shoot_range(goal)
    goal=goal or goal_for(false)
    local root=local_root()
    if not goal or not root then return false end
    local offset=goal.Position-root.Position
    return Vector3.new(offset.X,0,offset.Z).Magnitude<=config.ShootRange
end

local function safe_shot_target(target, mouth)
    if not mouth then return target end
    local clearance = math.min(shot_clearance(),math.max(0,mouth.HalfWidth-.25),math.max(0,(mouth.TopY-mouth.BottomY)*.5-.25))
    local width = math.max(0, mouth.HalfWidth - clearance)
    local low = mouth.BottomY + clearance
    local high = math.max(low, mouth.TopY - clearance)
    local lateral = math.clamp((target - mouth.PlanePosition):Dot(mouth.Lateral), -width, width)
    local point = mouth.PlanePosition + mouth.Lateral * lateral
    return Vector3.new(point.X, math.clamp(target.Y, low, high), point.Z)
end

local function select_shot()
    local goal,team=goal_for(false)
    local root=local_root()
    if not goal or not root or not within_shoot_range(goal) then return nil end
    local mouth=get_mouth(goal)
    if not mouth then return nil end
    local clearance=math.min(shot_clearance(),math.max(0,mouth.HalfWidth-.25),math.max(0,(mouth.TopY-mouth.BottomY)*.5-.25))
    local width=math.max(0,mouth.HalfWidth-clearance)
    local low=mouth.BottomY+clearance
    local high=math.max(low,mouth.TopY-clearance)
    local middle=(low+high)*.5
    local function point(x,y)
        local position=mouth.PlanePosition+mouth.Lateral*x
        return safe_shot_target(Vector3.new(position.X,y,position.Z),mouth)
    end
    local placements={
        ["Upper Left"]=point(-width,high),["Upper Right"]=point(width,high),
        ["Lower Left"]=point(-width,low),["Lower Right"]=point(width,low),Center=point(0,middle),
    }
    if config.ShotPlacement~="Auto"then return placements[config.ShotPlacement]or placements.Center,goal end
    local keeper,nearest
    for _,actor in ipairs(state.Actors)do
        if actor.Keeper and(actor.Team==team or team=="Practice")and actor.Root.Parent then
            local distance=(actor.Root.Position-goal.Position).Magnitude
            if not nearest or distance<nearest then keeper=actor nearest=distance end
        end
    end
    local origin=root.Position
    local character=local_player.Character
    local tuning=modules.Physics.GetCharacterTuning(character)
    local damping=math.max(tuning.AirDamping or 0,0)
    local gravity=math.abs(tuning.Gravity.Y)
    local horizontalMultiplier=modules.KickPowerups.GetVelocityMultipliers(modules.KickPowerups.GetMultiplier(character))
    local speed=modules.Shoot.Constants.Shot.MaximumSpeed*horizontalMultiplier*.94
    local inherited=modules.KickCore.GetInheritedVelocity(character,nil)
    local keeperReach=keeper and modules.Dive.GetDistance(keeper.Character)or 0
    local contactReach=modules.Dive.Constants.SaveReachStuds
    local function flightTime(distance,shotSpeed)
        if damping<.0001 then return distance/shotSpeed end
        return -math.log(math.max(.02,1-distance*damping/shotSpeed))/damping
    end
    local function difficulty(candidate)
        if not keeper then return 0 end
        local segment=candidate-origin
        local horizontal=Vector3.new(segment.X,0,segment.Z)
        if horizontal.Magnitude<.01 then return 0 end
        local shotSpeed=math.max(20,speed+inherited:Dot(horizontal.Unit))
        local depth=segment:Dot(mouth.Forward)
        local keeperDepth=(keeper.Root.Position-origin):Dot(mouth.Forward)
        local fraction=math.abs(depth)>.01 and math.clamp(keeperDepth/depth,.05,1)or 1
        local arrival=flightTime(horizontal.Magnitude*fraction,shotSpeed)
        local fullFlight=math.max(.05,flightTime(horizontal.Magnitude,shotSpeed))
        local intercept=origin+segment*fraction
        local verticalSpeed=(candidate.Y-origin.Y+.5*gravity*fullFlight*fullFlight)/fullFlight
        intercept=Vector3.new(intercept.X,origin.Y+verticalSpeed*arrival-.5*gravity*arrival*arrival,intercept.Z)
        local predicted=keeper.Root.Position+keeper.Root.AssemblyLinearVelocity*math.min(arrival,.35)
        local offset=intercept-predicted
        local horizontalGap=Vector3.new(offset.X,0,offset.Z).Magnitude
        local lateralVelocity=keeper.Root.AssemblyLinearVelocity:Dot(mouth.Lateral)
        local reverseDelay=lateralVelocity*offset:Dot(mouth.Lateral)<0 and math.min(.12,math.abs(lateralVelocity)*.006)or 0
        local available=math.max(0,arrival-.14-reverseDelay)
        local reachable=modules.Dive.GetTravel(available,keeperReach)+contactReach
        local needed=math.max(0,horizontalGap-contactReach)
        local diveTime=modules.Dive.GetCurveSecondsForTravel(math.min(needed,keeperReach),keeperReach)
        local aboveReach=math.max(0,intercept.Y-predicted.Y-modules.Dive.Constants.MaximumSaveHeight)
        return (horizontalGap-reachable)*2+(diveTime-available)*8+aboveReach*2
    end
    local best,bestScore
    local ranked={}
    for _,fraction in ipairs({-.95,.95,-.72,.72,-.45,.45,0})do
        for _,height in ipairs({low,middle,high})do
            local candidate=point(width*fraction,height)
            local score=difficulty(candidate)
            score-=math.abs(fraction)^4*.35
            score-=math.abs(height-middle)*.04
            if state.LastShotTarget and os.clock()-(state.LastShotAt or 0)<12 then
                score-=math.max(0,1-(candidate-state.LastShotTarget).Magnitude/8)*.5
            end
            local segment=candidate-origin
            local length=math.max(segment:Dot(segment),1)
            for _,actor in ipairs(state.Actors)do
                if actor.Team==team and not actor.Keeper and actor.Root.Parent then
                    local alpha=math.clamp((actor.Root.Position-origin):Dot(segment)/length,0,1)
                    local travel=flightTime(segment.Magnitude*alpha,math.max(20,speed))
                    local predicted=actor.Root.Position+actor.Root.AssemblyLinearVelocity*math.min(travel,.3)
                    local distance=(predicted-(origin+segment*alpha)).Magnitude
                    score-=math.max(0,5-distance)*2
                end
            end
            ranked[#ranked+1]={Target=candidate,Score=score}
            if not bestScore or score>bestScore then best,bestScore=candidate,score end
        end
    end
    table.sort(ranked,function(a,b)return a.Score>b.Score end)
    state.ShotCandidates=ranked
    return best or placements.Center,goal
end
local function select_flick_shot()
    local goal,team=goal_for(false)
    local root=local_root()
    if not goal or not root or not within_shoot_range(goal) then return nil end
    local mouth=get_mouth(goal)
    if not mouth then return nil end
    local keeper
    for _,actor in ipairs(state.Actors)do
        if actor.Keeper and actor.Root.Parent and (actor.Team==team or team=="Practice")then
            keeper=actor
            break
        end
    end
    local predicted=keeper and keeper.Root.Position+keeper.Root.AssemblyLinearVelocity*.18
    local reference=predicted or root.Position
    local side=(reference-mouth.PlanePosition):Dot(mouth.Lateral)>=0 and -1 or 1
    local clearance=shot_clearance()
    local width=math.max(0,mouth.HalfWidth-clearance)
    local low=mouth.BottomY+clearance
    local middle=(mouth.BottomY+mouth.TopY)*.5
    local position=mouth.PlanePosition+mouth.Lateral*side*width
    local height=low
    if predicted and math.abs(middle-predicted.Y)*1.3>math.abs(low-predicted.Y)+.4 then height=middle end
    return safe_shot_target(Vector3.new(position.X,height,position.Z),mouth),goal,side
end

local function best_teammate()
    local root = local_root()
    local goal = goal_for(false)
    if not root then return nil end
    local best, best_score = nil, -math.huge
    for _, actor in state.Actors do
        if actor.Friendly and actor.Root.Parent and not actor.Character:GetAttribute("Ragdolled") then
            local distance = (actor.Root.Position - root.Position).Magnitude
            if distance >= 8 and distance <= config.PassRange then
                local clearance = 40
                for _, enemy in state.Actors do
                    if not enemy.Friendly and enemy.Team then
                        clearance = math.min(clearance, (enemy.Root.Position - actor.Root.Position).Magnitude)
                    end
                end
                local progress = goal and ((root.Position - goal.Position).Magnitude - (actor.Root.Position - goal.Position).Magnitude) or 0
                local score = clearance * 1.4 + progress * 0.4 - distance * 0.12
                if score > best_score then best, best_score = actor, score end
            end
        end
    end
    return best
end

local function enemy_near(position, distance)
    local best
    for _, actor in state.Actors do
        if not actor.Friendly and actor.Team and actor.Root.Parent and not actor.Character:GetAttribute("Ragdolled") then
            local d = (actor.Root.Position - position).Magnitude
            if d < distance then best, distance = actor, d end
        end
    end
    return best, distance
end

local function dribble_tap()
    if not state.MobileDribbleBegin and debug.getupvalues then
        local ok,callbacks=pcall(debug.getupvalues,modules.Mobile.Start)
        if ok and type(callbacks)=="table" then
            for _,callback in callbacks do
                if type(callback)=="function" then
                    local name=debug.info(callback,"n")
                    if name=="handleMobileActionBegan" then state.MobileDribbleBegin=callback end
                    if name=="handleMobileActionEnded" then state.MobileDribbleEnd=callback end
                end
            end
        end
    end
    if state.MobileDribbleBegin and state.MobileDribbleEnd then
        local ok=pcall(state.MobileDribbleBegin,"Dribble")
        pcall(state.MobileDribbleEnd,"Dribble",false)
        return ok and modules.Dodge.IsDribbling()
    end
    local input=modules.Controls.CreateInput("Dribble")
    if not input then return false end
    local ok=pcall(modules.Dodge.HandleInputBegan,input,false)
    pcall(modules.Dodge.HandleInputEnded,input)
    return ok and modules.Dodge.IsDribbling()
end

local function dribble_path_hits(root,enemy,forward,elapsed,shown,starts,ends,lag)
    local slide=modules.SlideTackle
    local hitboxes=modules.Hitboxes
    local box=hitboxes.SlideTackle
    local grown={Size=box.Size+Vector3.new(3,0,3),CFrameOffset=box.CFrameOffset,Shape=box.Shape}
    local frame={CFrame=enemy.Root.CFrame}
    local travel=slide.GetTravel(shown,enemy.Character)
    local velocity=root.AssemblyLinearVelocity
    local from=root.Position+velocity*(starts-lag)-forward*(slide.GetTravel(elapsed+starts,enemy.Character)-travel)
    if hitboxes.ContainsPoint(frame,grown,from) then return true end
    for step=1,4 do
        local t=starts+(ends-starts)*step/4
        local to=root.Position+velocity*(t-lag)-forward*(slide.GetTravel(elapsed+t,enemy.Character)-travel)
        if hitboxes.GetSegmentEnterAlpha(frame,grown,from,to)~=nil then return true end
        from=to
    end
    return false
end

local function dribble_threat(root,enemy,now)
    local character=enemy.Character
    local their_root=enemy.Root
    if not character.Parent or not their_root.Parent or enemy.Friendly or character:GetAttribute("Ragdolled") then
        state.DribbleThreats[character]=nil
        return false
    end
    local slide=modules.SlideTackle
    local until_time=slide.GetSlidingUntil(character)
    state.DribbleProbe.Character=character
    local charging=modules.ActionCharge.IsCharging(state.DribbleProbe)==true
    local mark=state.DribbleThreats[character]
    local released=type(mark)=="number" and now<mark
    if not until_time and not charging and not released then
        state.DribbleThreats[character]=nil
        return false
    end
    local delta=root.Position-their_root.Position
    local horizontal=Vector3.new(delta.X,0,delta.Z)
    local distance=horizontal.Magnitude
    if distance>config.DribbleRange or distance<.01 then return false end
    local ping=0
    local ok_ping,value=pcall(local_player.GetNetworkPing,local_player)
    if ok_ping and type(value)=="number" then ping=math.clamp(value,0,.5) end
    local lead=math.clamp(ping+.12,.08,.45)
    if type(until_time)=="number" then
        local constants=slide.Constants
        local elapsed=math.max(0,workspace:GetServerTimeNow()-until_time+constants.TotalMotionSeconds)
        local shown=math.max(0,elapsed-math.min(ping,.25))
        local starts=math.max(0,constants.HitboxDelaySeconds-elapsed)
        local ends=math.min(lead,constants.HitboxDelaySeconds+constants.HitboxSeconds+(constants.CounterHitGraceSeconds or 0)-elapsed)
        if starts<=ends then
            local forward=slide.GetFlatForward(their_root)
            if forward and dribble_path_hits(root,enemy,forward,elapsed,shown,starts,ends,0) then return true end
            if forward and ping>0 and dribble_path_hits(root,enemy,forward,elapsed,shown,starts,ends,ping) then return true end
        end
    end
    if charging or released then
        local velocity=their_root.AssemblyLinearVelocity
        local kicker=their_root.Position+velocity*math.min(ping+.1,.3)
        local facing=Vector3.new(their_root.CFrame.LookVector.X,0,their_root.CFrame.LookVector.Z)
        if facing.Magnitude>.01 then
            local frame={CFrame=CFrame.lookAt(kicker,kicker+facing.Unit)}
            local box=modules.Hitboxes.Kick
            local grown={Size=box.Size+Vector3.new(3,0,3),CFrameOffset=box.CFrameOffset,Shape=box.Shape}
            local from=root.Position
            local to=from+(root.AssemblyLinearVelocity-velocity)*lead
            if modules.Hitboxes.ContainsPoint(frame,grown,from)
                or modules.Hitboxes.GetSegmentEnterAlpha(frame,grown,from,to)~=nil then return true end
        end
    end
    return false
end

local function dribble_step(root)
    local now=os.clock()
    if now<(state.NextDribbleAt or 0) or modules.Dodge.IsDribbling() then return end
    if now>=(state.NextDribbleScanAt or 0) then
        state.NextDribbleScanAt=now+.15
        local seen={}
        for _,enemy in ipairs(state.Actors)do
            seen[enemy.Character]=true
            if not enemy.Friendly and enemy.Root.Parent then
                state.DribbleProbe.Character=enemy.Character
                if modules.SlideTackle.GetSlidingUntil(enemy.Character) or modules.ActionCharge.IsCharging(state.DribbleProbe) then
                    state.DribbleThreats[enemy.Character]=true
                end
            end
        end
        for model in state.DribbleThreats do
            if not seen[model] or not model.Parent then state.DribbleThreats[model]=nil end
        end
    end
    for _,enemy in ipairs(state.Actors)do
        if state.DribbleThreats[enemy.Character] and dribble_threat(root,enemy,now) then
            local started=dribble_tap()
            state.NextDribbleAt=now+(started and modules.DodgeAction.Constants.RepeatDelaySeconds or .12)
            return
        end
    end
end

local function item_target()
    local camera = workspace.CurrentCamera
    local root = local_root()
    if not camera or not root then return nil end
    local center = camera.ViewportSize * modules.Reticle.GunScreenPosition
    local best, best_distance = nil, config.ItemAimFOV
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {local_player.Character, state.World}
    for _, actor in state.Actors do
        if not actor.Friendly and actor.Team and actor.Root.Parent then
            local position, visible = camera:WorldToViewportPoint(actor.Root.Position)
            local delta = (Vector2.new(position.X, position.Y) - center).Magnitude
            if visible and delta < best_distance and (actor.Root.Position - root.Position).Magnitude <= config.ESPDistance then
                local hit = workspace:Raycast(camera.CFrame.Position, actor.Root.Position - camera.CFrame.Position, params)
                if not hit or hit.Instance:IsDescendantOf(actor.Character) then
                    best, best_distance = actor, delta
                end
            end
        end
    end
    return best
end

local function shot_curve()
    if state.MagnetSteal or not config.CurveShot or not within_shoot_range() or config.ShotCurve==0 or (state.FeintActive and not state.FeintCommitted) then return nil end
    local amount=math.clamp(math.abs(config.ShotCurve)/100,0,1)
    local goal=state.TargetGoal
    local target=state.ShotProbeTarget or (state.FeintActive and state.FeintCommitted and state.FeintRealTarget or state.ShotTarget)
    local mouth=goal and get_mouth(goal)
    if not mouth or not target then return config.ShotCurve<0 and -amount or amount end
    local origin=local_root()
    if not origin then return config.ShotCurve<0 and -amount or amount end
    local toward=flat(mouth.PlanePosition-origin.Position)
    if not toward then return config.ShotCurve<0 and -amount or amount end
    local side=(target-mouth.PlanePosition):Dot(Vector3.yAxis:Cross(toward))<0 and 1 or -1
    if config.CurveSide=="Left" then side=1 elseif config.CurveSide=="Right" then side=-1 end
    return side*amount*(config.ShotCurve<0 and -1 or 1)
end

local feint_random=Random.new()

local function begin_shot_feint()
    state.FeintCommitted=false
    state.FeintActive=config.FeintShot and within_shoot_range() and feint_random:NextNumber()<math.clamp(config.FeintChance,0,100)/100
    state.FeintSide=state.FeintActive and (feint_random:NextInteger(0,1)==0 and -1 or 1) or nil
    state.FeintRealTarget=state.FeintActive and state.ShotTarget or nil
    state.ShotSolution=nil
end

local function shot_target()
    if not within_shoot_range() then return nil end
    if state.FlickVolley and state.FlickShotTarget then return state.FlickShotTarget end
    if not config.FeintShot or not state.FeintActive then return state.ShotTarget end
    local goal=state.TargetGoal or goal_for(false)
    local mouth=goal and get_mouth(goal)
    if not mouth then return state.ShotTarget end
    local real=safe_shot_target(state.FeintRealTarget or state.ShotTarget or mouth.PlanePosition,mouth)
    if state.FeintCommitted then return real end
    local lateral=(real-mouth.PlanePosition):Dot(mouth.Lateral)
    local side=lateral>=0 and -1 or 1
    local width=math.max(0,mouth.HalfWidth-shot_clearance())
    local position=mouth.PlanePosition+mouth.Lateral*side*math.max(width*.7,math.abs(lateral)*.7)
    return safe_shot_target(Vector3.new(position.X,real.Y,position.Z),mouth)
end
local function begin_shot_flick()
    state.FlickAttemptAt=os.clock()
    if not config.FlickShot or state.FlickVolley or not can_act() or not owns_ball()or is_goalkeeper()or not within_shoot_range()then return false end
    if not modules.Controls.IsRainbowFlickUnlocked()or modules.Controls.IsOnCooldown("RainbowFlick")then return false end
    if not state.NativeFlick then
        for _,callback in ipairs(getgc(true))do
            if type(callback)=="function"and debug.info(callback,"n")=="beginRainbowFlick"
                and debug.info(callback,"s")=="ReplicatedStorage.Client.Gameplay.Gameplay"then
                state.NativeFlick=callback
                break
            end
        end
    end
    if not state.NativeFlick then return false end
    local ok,result=pcall(state.NativeFlick)
    if not ok or result~=Enum.ContextActionResult.Sink
        or not modules.RainbowFlick.GetWindingUpUntil(local_player)then return false end
    state.FlickPending=os.clock()+1.5
    state.FlickTriggeredAt=os.clock()
    state.FlickJiggleStarted=os.clock()
    local _,_,side=select_flick_shot()
    state.FlickJiggleSide=side
    return true
end

local raw_velocity=modules.Shoot.GetVelocity
local function launch_position(pass_type,aim,charge)
    local character=local_player.Character
    if character then return modules.Carry.GetLaunchPosition(character,pass_type,aim,false,charge)end
end

local raw_spin=modules.Shoot.GetSpin

local function pivot_crossing(origin,velocity,spin,plane,normal,tuning)
    local previous=origin
    local distance=(origin-plane):Dot(normal)
    if distance<=0 then return nil end
    for step=1,50 do
        local position=modules.Physics.GetAirFlight(origin,velocity,spin,step*.05,tuning)
        if typeof(position)~="Vector3" then return nil end
        local remaining=(position-plane):Dot(normal)
        if remaining<=0 then
            local alpha=distance/(distance-remaining)
            return previous:Lerp(position,alpha),(step-1+alpha)*.05
        end
        if position.Y<plane.Y-15 then return nil end
        previous,distance=position,remaining
    end
    return nil
end

local function pivot_entry(origin,velocity,spin,goal,boundary)
    if not boundary or not goal then return nil end
    local now=modules.Clock.GetSmoothedServerTime()
    local ball=modules.Physics.NewState(origin,velocity,modules.Physics.BallRadius,now,spin)
    ball.LastKickerUserId=local_player.UserId
    return modules.Physics.GetFirstBoxEntry(ball,boundary,goal,now,2.5,true)
end

local function pivot_solve_once(target,charge,initial_aim,goal,mouth,requested)
    local character=local_player.Character
    local core=modules.KickCore
    local shoot=modules.Shoot
    local powerups=modules.KickPowerups
    local physics=modules.Physics
    if not character or not goal or not mouth then return nil end
    local origin=launch_position("Shot",initial_aim,charge)
    if not origin then return nil end
    local normal=mouth.Forward
    local plane=mouth.PlanePosition
    if (origin-plane):Dot(normal)<0 then normal=-normal end
    local wanted=target-normal*(target-plane):Dot(normal)
    local movement=modules.CharacterMotion.GetVelocity(character) or Vector3.zero
    local ok_reported,reported=pcall(core.SanitizeReportedVelocity,movement)
    if not ok_reported or typeof(reported)~="Vector3" then reported=Vector3.zero end
    local multiplier=powerups.GetMultiplier(character)
    local horizontal,vertical=powerups.GetVelocityMultipliers(multiplier)
    local charge_constants=powerups.GetChargeConstants(character,core.Constants) or core.Constants
    local scaled=shoot.GetPowerScaledCurve(1,charge,character)
    local move_spin=core.GetSideSpin(character,reported) or 0
    local curved_spin=(core.GetSideSpin(character,reported,scaled) or 0)-move_spin
    local neutral=math.abs(curved_spin)>1e-6 and -move_spin/curved_spin or 0
    local eye=type(initial_aim)=="table" and typeof(initial_aim.Origin)=="Vector3" and initial_aim.Origin or origin+Vector3.new(0,6,0)
    local airborne=type(initial_aim)=="table" and initial_aim.IsAirborne==true
    local tuning=physics.GetCharacterTuning(character)
    local gravity=math.abs(tuning.Gravity.Y)
    local damping=tuning.AirDamping or .5
    local shot=shoot.Constants.Shot
    local solve_speed=core.GetChargedSpeed(shot.MinimumSpeed,shot.MaximumSpeed,core.Constants.MaximumChargeSeconds,core.Constants,core.LaunchKinds and core.LaunchKinds.Kick,character)
    local speed=core.GetChargedSpeed(shot.MinimumSpeed,shot.MaximumSpeed,charge,charge_constants,core.LaunchKinds and core.LaunchKinds.Kick,character)
    local inherited=core.GetInheritedVelocity(character,reported)
    local maximum_tangent=math.tan(math.rad(shot.MaximumLaunchAngleDegrees))*horizontal/vertical
    local base=flat(wanted-origin)
    if not base then return nil end
    local _,boundary=modules.Renderer.GetAuthoritativeMovementState()
    local lobby=workspace:FindFirstChild("Lobby")
    if lobby and goal:IsDescendantOf(lobby) then boundary=modules.PracticeBoundary.GetIfReady() or boundary end
    local function ray_for(direction,tangent)
        local length=math.sqrt(1+tangent*tangent)
        local drift=(direction*(solve_speed/length)+direction*inherited:Dot(direction))*horizontal
        local rise=solve_speed*tangent/length*vertical
        local function slope(time)
            local point=origin+drift*physics.GetDampedTravel(1,damping,time)+Vector3.new(0,rise*time-.5*gravity*time*time,0)-eye
            local ahead=point:Dot(direction)
            return ahead>1e-3 and point.Y/ahead or -math.huge
        end
        local low,high=0,rise/gravity
        for _=1,16 do
            local a,b=low+(high-low)/3,high-(high-low)/3
            if slope(a)<slope(b) then low=a else high=b end
        end
        local peak=slope((low+high)*.5)
        if peak==-math.huge then return nil end
        local ray=(direction+Vector3.new(0,peak,0)).Unit
        return {Origin=eye,Direction=ray,CameraCFrame=CFrame.lookAt(eye,eye+ray),IsAirborne=airborne,TargetPosition=target}
    end
    local radius=physics.BallRadius
    local best_fallback
    for attempt=0,3 do
        local desired=attempt==3 and 0 or requested*.5^attempt
        if requested==0 and attempt>0 then break end
        local candidate_curve=math.clamp(desired+neutral,-1,1)
        local seed=shoot.GetTargetShotDirection(origin,wanted,speed,inherited,horizontal,vertical,base,tuning)
        local tangent=maximum_tangent
        if typeof(seed)=="Vector3" then
            local seed_flat=Vector3.new(seed.X,0,seed.Z)
            if seed_flat.Magnitude>1e-4 then tangent=math.clamp(seed.Y/seed_flat.Magnitude,0,maximum_tangent) end
        end
        local yaw=0
        local function cast(at_yaw,at_tangent)
            local direction=CFrame.fromAxisAngle(Vector3.yAxis,at_yaw):VectorToWorldSpace(base)
            local aim=ray_for(direction,at_tangent)
            if not aim then return nil end
            local velocity=raw_velocity(character,charge,aim,origin,horizontal,vertical,reported,nil,direction,nil,nil,nil,candidate_curve)
            if typeof(velocity)~="Vector3" then return nil end
            local spin=raw_spin(character,velocity,reported,candidate_curve,charge)
            local crossing,time=pivot_crossing(origin,velocity,spin,plane,normal,tuning)
            return crossing,time,aim,direction,velocity,spin
        end
        local good,step,last_error
        for _=1,10 do
            local crossing,time,aim,direction,velocity,spin=cast(yaw,tangent)
            if aim and desired~=0 and spin.Y*requested<=0 then break end
            if not crossing then
                if good then
                    step*=.5
                    yaw,tangent=good[1]+step.X,math.clamp(good[2]+step.Y,0,maximum_tangent)
                elseif tangent<maximum_tangent then
                    tangent=math.min(tangent+(maximum_tangent-tangent)*.5+.05,maximum_tangent)
                else break end
                continue
            end
            local error=wanted-crossing
            if good and last_error and error.Magnitude>last_error then
                step*=.5
                yaw,tangent=good[1]+step.X,math.clamp(good[2]+step.Y,0,maximum_tangent)
                continue
            end
            last_error=error.Magnitude
            if error.Magnitude<=.25 then
                local inside=math.abs((crossing-plane):Dot(mouth.Lateral))<=mouth.HalfWidth-radius
                    and crossing.Y>=mouth.BottomY+radius and crossing.Y<=mouth.TopY-radius
                if inside and pivot_entry(origin,velocity,spin,goal,boundary) then
                    return aim,velocity,origin,direction,candidate_curve
                end
                break
            end
            local lateral=Vector3.yAxis:Cross(normal)
            local tilt=tangent<maximum_tangent-.005 and .005 or -.005
            local turned=cast(yaw+.005,tangent)
            local lifted=cast(yaw,tangent+tilt)
            if not turned or not lifted then break end
            local a,b=(turned-crossing):Dot(lateral)/.005,(lifted-crossing):Dot(lateral)/tilt
            local c,d=(turned-crossing).Y/.005,(lifted-crossing).Y/tilt
            local determinant=a*d-b*c
            if math.abs(determinant)<1e-9 then break end
            local miss_l,miss_h=error:Dot(lateral),error.Y
            step=Vector2.new((d*miss_l-b*miss_h)/determinant,(a*miss_h-c*miss_l)/determinant)
            if tangent>=maximum_tangent-1e-6 and step.Y>0 then
                if math.abs(miss_l)<.5 then
                    if desired==0 and math.abs((crossing-plane):Dot(mouth.Lateral))<=mouth.HalfWidth-radius
                        and crossing.Y>=mouth.BottomY+radius and crossing.Y<=mouth.TopY-radius then
                        best_fallback={aim,velocity,origin,direction,candidate_curve,spin}
                    end
                    break
                end
                step=Vector2.new(miss_l/a,0)
            end
            local scale=math.min(1,.3/math.max(math.abs(step.X),1e-9),.2/math.max(math.abs(step.Y),1e-9))
            step*=scale
            good={yaw,tangent}
            yaw,tangent=yaw+step.X,math.clamp(tangent+step.Y,0,maximum_tangent)
        end
    end
    if best_fallback and pivot_entry(best_fallback[3],best_fallback[2],best_fallback[6],goal,boundary) then
        return best_fallback[1],best_fallback[2],best_fallback[3],best_fallback[4],best_fallback[5]
    end
    return nil
end

local function pivot_solve(target,charge,initial_aim,goal,mouth)
    local requested=shot_curve() or 0
    local signs=requested~=0 and config.CurveSide=="Auto" and {requested,-requested} or {requested}
    for _,curve in ipairs(signs)do
        local ok,aim,velocity,origin,direction,applied=pcall(pivot_solve_once,target,charge,initial_aim,goal,mouth,curve)
        if ok and aim then return aim,velocity,origin,direction,applied end
        if not ok then state.Errors["pivot shot"]=tostring(aim) end
    end
    return nil
end

local function predict_shot_crossing(origin,velocity,charge,goal)
    local _,boundary=modules.Renderer.GetAuthoritativeMovementState()
    local lobby=workspace:FindFirstChild("Lobby")
    if goal and lobby and goal:IsDescendantOf(lobby)then
        boundary=modules.PracticeBoundary.GetIfReady()or boundary
    end
    if not boundary or not goal then return nil end
    local now=modules.Clock.GetSmoothedServerTime()
    local spin=modules.Shoot.GetSpin(local_player.Character,velocity,nil,shot_curve(),charge)
    local ball=modules.Physics.NewState(origin,velocity,modules.Physics.BallRadius,now,spin)
    ball.LastKickerUserId=local_player.UserId
    return modules.Physics.GetFirstBoxEntry(ball,boundary,goal,now,4,false)
end

local function solve_shot(target,charge,is_throw,initial_aim,post_retry)
    local character=local_player.Character
    if not character or not target then return nil end
    local goal = not is_throw and (state.FlickVolley and state.FlickGoal or state.TargetGoal or goal_for(false)) or nil
    local mouth = goal and get_mouth(goal)
    if mouth then target = safe_shot_target(target, mouth) end
    local constants=is_throw and modules.Throw.Constants or nil
    charge=charge or modules.Shoot.GetChargeSecondsFromAlpha(1,character)
    local now=os.clock()
    local position=modules.CharacterMotion.GetPosition(character)
    local characterVelocity=modules.CharacterMotion.GetVelocity(character)
    local cached=state.ShotSolution
    if cached and cached.Character==character and cached.IsThrow==is_throw and cached.Curve==shot_curve() and now-cached.At<.035
        and math.abs(cached.Charge-charge)<.001 and(cached.Target-target).Magnitude<.02
        and position and(position-cached.Position).Magnitude<.04 and(characterVelocity-cached.CharacterVelocity).Magnitude<.1 then
        return table.clone(cached.Aim),cached.Velocity,cached.Origin,cached.Direction,cached.AppliedCurve
    end
    if not is_throw and goal and mouth then
        local pivot_aim,pivot_velocity,pivot_origin,pivot_direction,pivot_curve=pivot_solve(target,charge,initial_aim,goal,mouth)
        if pivot_aim then
            if config.ShotPreview and state.TargetGoal and now-(state.ShotPredictionAt or 0)>.12 then
                state.ShotPredictionAt=now
                state.ShotCrossing=predict_shot_crossing(pivot_origin,pivot_velocity,charge,state.TargetGoal)
            end
            if position then
                state.ShotSolution={Character=character,IsThrow=false,Curve=shot_curve(),AppliedCurve=pivot_curve,At=now,Charge=charge,Target=target,Position=position,
                    CharacterVelocity=characterVelocity,Aim=table.clone(pivot_aim),Velocity=pivot_velocity,Origin=pivot_origin,Direction=pivot_direction}
            end
            return pivot_aim,pivot_velocity,pivot_origin,pivot_direction,pivot_curve
        end
    end
    local pass_type=is_throw and "Throw"or "Shot"
    local origin=launch_position(pass_type,initial_aim,charge)
    if not origin then return nil end
    local horizontal,vertical=modules.KickPowerups.GetVelocityMultipliers(modules.KickPowerups.GetMultiplier(character))
    local direction=flat(target-origin)
    if not direction then return nil end
    local aim={Origin=origin,Direction=direction,CameraCFrame=CFrame.lookAt(origin,origin+direction),IsAirborne=false,TargetPosition=target}
    local inherited=modules.KickCore.GetInheritedVelocity(character,nil)
    inherited=direction*inherited:Dot(direction)
    local velocity
    for _=1,4 do
        local desired=raw_velocity(character,charge,nil,origin,horizontal,vertical,nil,constants,direction,target)
        if not desired or desired.Magnitude<.01 then return nil end
        local unscaled=Vector3.new(desired.X/horizontal,desired.Y/vertical,desired.Z/horizontal)-inherited
        if unscaled.Magnitude<.01 then return nil end
        aim.Direction=unscaled.Unit
        aim.Origin=origin
        aim.CameraCFrame=CFrame.lookAt(origin,origin+aim.Direction)
        local next_origin=launch_position(pass_type,aim,charge)or origin
        if(next_origin-origin).Magnitude<.01 then origin=next_origin break end
        origin=next_origin
    end
    aim.Origin=origin
    aim.CameraCFrame=CFrame.lookAt(origin,origin+aim.Direction)
    for _=1,4 do
        velocity=raw_velocity(character,charge,aim,origin,horizontal,vertical,nil,constants,direction,target)
        local desired=raw_velocity(character,charge,nil,origin,horizontal,vertical,nil,constants,direction,target)
        if not velocity or not desired then return nil end
        local desiredFlat=Vector3.new(desired.X,0,desired.Z)
        local actualFlat=Vector3.new(velocity.X,0,velocity.Z)
        local yawError=math.atan2(desired.Z,desired.X)-math.atan2(velocity.Z,velocity.X)
        yawError=(yawError+math.pi)%(2*math.pi)-math.pi
        local pitchError=math.atan2(desired.Y,desiredFlat.Magnitude)-math.atan2(velocity.Y,actualFlat.Magnitude)
        if math.abs(yawError)+math.abs(pitchError)<.0005 then break end
        local yaw=math.atan2(aim.Direction.Z,aim.Direction.X)+math.clamp(yawError,-.2,.2)
        local pitch=math.asin(math.clamp(aim.Direction.Y,-1,1))+math.clamp(pitchError,-.15,.15)
        aim.Direction=Vector3.new(math.cos(yaw)*math.cos(pitch),math.sin(pitch),math.sin(yaw)*math.cos(pitch))
        aim.CameraCFrame=CFrame.lookAt(origin,origin+aim.Direction)
    end
    velocity=raw_velocity(character,charge,aim,origin,horizontal,vertical,nil,constants,direction,target,nil,nil,not is_throw and shot_curve() or nil)
    if mouth and (target - origin).Magnitude <= 160 then
        local _, boundary = modules.Renderer.GetAuthoritativeMovementState()
        local lobby = workspace:FindFirstChild("Lobby")
        if goal and lobby and goal:IsDescendantOf(lobby) then boundary = modules.PracticeBoundary.GetIfReady() or boundary end
        if boundary then
            local flight_world = table.clone(boundary)
            flight_world.Solids = {}
            flight_world.GroundSolids = {}
            local curve = shot_curve()
            local function evaluate(yaw, pitch)
                local ray = table.clone(aim)
                ray.Direction = Vector3.new(math.cos(yaw) * math.cos(pitch), math.sin(pitch), math.sin(yaw) * math.cos(pitch))
                ray.CameraCFrame = CFrame.lookAt(origin, origin + ray.Direction)
                local start = launch_position(pass_type, ray, charge) or origin
                ray.Origin = start
                ray.CameraCFrame = CFrame.lookAt(start, start + ray.Direction)
                local kick_direction = flat(ray.Direction) or direction
                local speed = raw_velocity(character, charge, ray, start, horizontal, vertical, nil, constants, kick_direction, target, nil, nil, curve)
                if not speed then return nil end
                local normal_speed = speed:Dot(mouth.Forward)
                if math.abs(normal_speed) < .01 then return nil end
                local time = (mouth.PlanePosition - start):Dot(mouth.Forward) / normal_speed
                if time <= 0 or time > 4 then return nil end
                local spin = modules.Shoot.GetSpin(character, speed, nil, curve, charge)
                local ball = modules.Physics.NewState(start, speed, modules.Physics.BallRadius, 0, spin)
                ball.LastKickerUserId = local_player.UserId
                local sample
                for _ = 1, 7 do
                    sample = modules.Physics.GetStateAtTime(ball, time, flight_world)
                    local depth = (sample.Position - mouth.PlanePosition):Dot(mouth.Forward)
                    if math.abs(depth) < .01 then break end
                    local rate = sample.Velocity:Dot(mouth.Forward)
                    if math.abs(rate) < .01 then return nil end
                    time -= depth / rate
                    if time <= 0 or time > 4 then return nil end
                end
                if not sample or math.abs((sample.Position - mouth.PlanePosition):Dot(mouth.Forward)) > .1 then return nil end
                local error_x = (sample.Position - target):Dot(mouth.Lateral)
                local error_y = sample.Position.Y - target.Y
                return {Direction=kick_direction,Aim=ray, Velocity=speed, Origin=start, X=error_x, Y=error_y,
                    Loss=error_x*error_x+error_y*error_y,Time=time,Ball=ball,Crossing=sample.Position}
            end
            local yaw = math.atan2(aim.Direction.Z, aim.Direction.X)
            local pitch = math.asin(math.clamp(aim.Direction.Y, -1, 1))
            local best
            local safeWidth=math.max(0,mouth.HalfWidth-modules.Physics.BallRadius-.5)
            local safeBottom=mouth.BottomY+modules.Physics.BallRadius+.5
            local safeTop=mouth.TopY-modules.Physics.BallRadius-.5
            local function inside(sample)
                return sample and math.abs((sample.Crossing-mouth.PlanePosition):Dot(mouth.Lateral))<=safeWidth
                    and sample.Crossing.Y>=safeBottom and sample.Crossing.Y<=safeTop
            end
            for _ = 1, 9 do
                local sample = evaluate(yaw, pitch)
                if not sample then break end
                if inside(sample) and (not best or sample.Loss < best.Loss) then best = sample end
                if inside(sample) and sample.Loss < .0225 then break end
                local dx = evaluate(yaw + .01, pitch)
                local dy = evaluate(yaw, pitch + .01)
                if not dx or not dy then break end
                local xx, yx = (dx.X-sample.X)/.01, (dx.Y-sample.Y)/.01
                local xy, yy = (dy.X-sample.X)/.01, (dy.Y-sample.Y)/.01
                local determinant = xx*yy-xy*yx
                if math.abs(determinant) < .001 then break end
                yaw -= math.clamp((sample.X*yy-sample.Y*xy)/determinant, -.15, .15)
                pitch = math.clamp(pitch-math.clamp((sample.Y*xx-sample.X*yx)/determinant, -.12, .12), -.4, 1.2)
            end
            if not best then
                for _,yawOffset in ipairs({0,-.02,.02,-.05,.05,-.1,.1})do
                    for _,pitchOffset in ipairs({0,-.03,.03,-.07,.07})do
                        local sample=evaluate(yaw+yawOffset,pitch+pitchOffset)
                        if inside(sample) and (not best or sample.Loss<best.Loss)then best=sample end
                    end
                end
            end
            if best and not post_retry then
                local ok,actual=pcall(modules.Physics.GetStateAtTime,best.Ball,best.Time,boundary)
                local safeWidth=math.max(0,mouth.HalfWidth-shot_clearance()+.5)
                local blocked=ok and actual and (actual.Position-best.Crossing).Magnitude>1.5
                local outside=math.abs((best.Crossing-mouth.PlanePosition):Dot(mouth.Lateral))>safeWidth
                    or best.Crossing.Y<mouth.BottomY+modules.Physics.BallRadius+1
                    or best.Crossing.Y>mouth.TopY-modules.Physics.BallRadius-1
                if blocked or outside or best.Loss>2.25 then
                    local position=mouth.PlanePosition+mouth.Lateral*math.clamp((target-mouth.PlanePosition):Dot(mouth.Lateral),-safeWidth*.7,safeWidth*.7)
                    local fallback=Vector3.new(position.X,math.clamp(target.Y,mouth.BottomY+shot_clearance(),mouth.TopY-shot_clearance()),position.Z)
                    if (fallback-target).Magnitude>.1 then
                        return solve_shot(fallback,charge,is_throw,initial_aim,true)
                    end
                    return nil
                end
            end
            if best then
                aim, velocity, origin, direction = best.Aim, best.Velocity, best.Origin, best.Direction
            else
                return nil
            end
        end
    end
    if config.ShotPreview and not is_throw and state.TargetGoal and now-(state.ShotPredictionAt or 0)>.12 then
        state.ShotPredictionAt=now
        local crossing=predict_shot_crossing(origin,velocity,charge,state.TargetGoal)
        state.ShotCrossing=crossing
    end
    if position then
        state.ShotSolution={Character=character,IsThrow=is_throw,Curve=shot_curve(),At=now,Charge=charge,Target=target,Position=position,
            CharacterVelocity=characterVelocity,Aim=table.clone(aim),Velocity=velocity,Origin=origin,Direction=direction,AppliedCurve=shot_curve()}
    end
    return aim,velocity,origin,direction,shot_curve()
end

local function keeper_save_miss(ball,boundary,keeper,entry,entered_at,now)
    local dive=modules.Dive
    local assist=modules.DiveAssist
    local physics=modules.Physics
    local root=keeper.Root
    local flight=math.max(0,entered_at-now)
    local predicted=root.CFrame+root.AssemblyLinearVelocity*math.min(flight,.25)
    local keeper_root={CFrame=predicted,Position=predicted.Position}
    local launch_at=math.max(now+.15,entered_at-(dive.Constants.HitboxCurveSeconds or .6))
    if launch_at>=entered_at then return (entry-predicted.Position).Magnitude end
    local ok_live,live=pcall(physics.GetStateAtTime,ball,launch_at,boundary)
    if not ok_live or type(live)~="table" then return nil end
    local best=math.huge
    local standing={CanExtendReach=false,ElapsedSeconds=0,WarpedSeconds=0,TravelScale=1,Distance=0,GetVerticalOffset=function()return 0 end}
    local ok_still,still=pcall(assist.FindFlightIntercept,ball,boundary,predicted,predicted.LookVector,now,standing)
    if ok_still and type(still)=="table" and type(still.MissDistance)=="number" and type(still.OffsetSeconds)=="number" and now+still.OffsetSeconds<entered_at then
        best=still.MissDistance
    end
    for _,name in ipairs({"F","LF","L","LB","B","RB","R","RF"})do
        local ok_choice,choice=pcall(dive.GetDirectionChoiceByName,name)
        local ok_direction,direction=ok_choice and pcall(dive.GetWorldDirection,choice,predicted,predicted.LookVector)
        if ok_direction and typeof(direction)=="Vector3" then
            local ok_assist,info=pcall(assist.GetAssist,live,boundary,keeper_root,direction,launch_at)
            local aimed=direction
            local context={CanExtendReach=true,ElapsedSeconds=0,WarpedSeconds=0,TravelScale=1,Distance=dive.Constants.Distance,GetVerticalOffset=dive.GetVerticalTravel}
            if ok_assist and type(info)=="table" then
                if type(info.YawRadians)=="number" and info.YawRadians~=0 then
                    local ok_rotate,rotated=pcall(dive.RotateFlatDirection,direction,info.YawRadians)
                    if ok_rotate and typeof(rotated)=="Vector3" then aimed=rotated end
                end
                local up=info.InitialVerticalVelocity or dive.Constants.InitialVerticalVelocity
                local gravity=info.Gravity or dive.Constants.GravityStudsPerSecondSquared
                context={CanExtendReach=false,ElapsedSeconds=0,WarpedSeconds=0,TravelScale=info.TravelScale or 1,Distance=dive.Constants.Distance+(info.ExtraDistance or 0),GetVerticalOffset=function(t)return up*t+.5*gravity*t*t end}
            end
            local ok_hit,hit=pcall(assist.FindFlightIntercept,live,boundary,predicted,aimed,launch_at,context,live)
            if ok_hit and type(hit)=="table" and type(hit.MissDistance)=="number" and type(hit.OffsetSeconds)=="number" and hit.OffsetSeconds<entered_at-launch_at then
                best=math.min(best,hit.MissDistance)
            end
        end
    end
    return best
end

local function choose_shot(target,goal)
    if not target or not goal or config.ShotPlacement~="Auto" or not config.ShotAimbot then return target end
    local keeper
    local team=select(2,goal_for(false))
    for _,actor in ipairs(state.Actors)do
        if actor.Keeper and actor.Root.Parent and (actor.Team==team or team=="Practice")then keeper=actor break end
    end
    if not keeper then return target end
    local now_clock=os.clock()
    if state.ShotSearchAt and now_clock-state.ShotSearchAt<.2 and state.ShotSearchGoal==goal
        and state.ShotSearchKeeper and (keeper.Root.Position-state.ShotSearchKeeper).Magnitude<1 then
        return state.ShotSearchTarget or target
    end
    local _,boundary=modules.Renderer.GetAuthoritativeMovementState()
    local mouth=get_mouth(goal)
    if not boundary or not mouth then return target end
    local candidates=state.ShotCandidates
    if not candidates then return target end
    local charge=modules.Shoot.GetChargeSecondsFromAlpha(1,local_player.Character)
    local old_solution,old_crossing,old_prediction,old_goal=state.ShotSolution,state.ShotCrossing,state.ShotPredictionAt,state.TargetGoal
    state.TargetGoal=goal
    local best,best_miss=target,-math.huge
    local started=os.clock()
    for index=1,math.min(#candidates,6)do
        if os.clock()-started>.03 then break end
        local candidate=candidates[index].Target
        state.ShotProbeTarget=candidate
        state.ShotSolution=nil
        local ray,velocity,origin,_,applied_curve=solve_shot(candidate,charge,false,nil)
        if ray and velocity and origin then
            local now=modules.Clock.GetSmoothedServerTime()
            local spin=raw_spin(local_player.Character,velocity,nil,applied_curve,charge)
            local ball=modules.Physics.NewState(origin,velocity,modules.Physics.BallRadius,now,spin)
            ball.LastKickerUserId=local_player.UserId
            local ok,entry,entered_at=pcall(modules.Physics.GetFirstBoxEntry,ball,boundary,goal,now,4,false)
            if ok and typeof(entry)=="Vector3" and type(entered_at)=="number" then
                local miss=keeper_save_miss(ball,boundary,keeper,entry,entered_at,now)
                if miss and miss>best_miss then best,best_miss=candidate,miss end
            end
        end
    end
    state.ShotProbeTarget=nil
    state.ShotSolution,state.ShotCrossing,state.ShotPredictionAt,state.TargetGoal=old_solution,old_crossing,old_prediction,old_goal
    state.ShotSearchAt=now_clock
    state.ShotSearchGoal=goal
    state.ShotSearchKeeper=keeper.Root.Position
    state.ShotSearchTarget=best
    return best
end

local function aim_payload(original)
    if not state.Alive or not can_act() then return original end
    if state.MagnetSteal then
        local target=state.MagnetStealTarget or modules.Renderer.GetPosition()
        local origin=original and original.Origin or workspace.CurrentCamera.CFrame.Position
        if target and (target-origin).Magnitude>.01 then
            local result=table.clone(original or {})
            result.Origin=origin result.Direction=(target-origin).Unit
            result.CameraCFrame=CFrame.lookAt(origin,target)
            result.TargetPosition=target result.ClientHit=nil
            return result
        end
        return original
    end
    if modules.ItemUse.IsEquipped() then
        if config.ItemAimbot and state.ItemTarget and state.ItemTarget.Root.Parent then
            local target = state.ItemTarget.Root.Position
            local origin = original and original.Origin or workspace.CurrentCamera.CFrame.Position
            local result = table.clone(original or {})
            result.Origin = origin
            result.Direction = (target - origin).Unit
            result.CameraCFrame = CFrame.lookAt(origin, target)
            result.ClientHit = nil
            result.TargetPosition = target
            return result
        end
        return original
    end
    if config.AutoPass and state.PassTarget and state.PassTarget.Root.Parent then
        local target = state.PassTarget.Root.Position + state.PassTarget.Root.AssemblyLinearVelocity * 0.15
        local origin = original and original.Origin or workspace.CurrentCamera.CFrame.Position
        local result = table.clone(original or {})
        result.Origin = origin
        result.Direction = (target - origin).Unit
        result.CameraCFrame = CFrame.lookAt(origin, target)
        result.TargetPosition = target
        result.ClientHit = nil
        return result
    end
    if is_goalkeeper()then
        if config.KeeperClearAimbot and modules.Keeper.IsForcedClearActive()then
            local teammate=best_teammate()
            if teammate then
                local target=teammate.Root.Position+teammate.Root.AssemblyLinearVelocity*.2
                local result=table.clone(original or {})
                local origin=result.Origin or workspace.CurrentCamera.CFrame.Position
                if(target-origin).Magnitude>.01 then
                    result.Origin=origin result.Direction=(target-origin).Unit
                    result.CameraCFrame=CFrame.lookAt(origin,target)
                    result.TargetPosition=target result.ClientHit=nil
                    return result
                end
            end
        end
        return original
    end
    if (config.ShotAimbot or config.UnsavableShot or state.FlickVolley or (config.FeintShot and state.FeintActive)) and shot_target() and not modules.Pass.IsCharging() and not is_goalkeeper() then
        return solve_shot(shot_target(), nil, false, original) or original
    end
    return original
end

local function rewrite_command(command)
    if type(command) ~= "table" then return end
    if state.MagnetSteal then return end
    if not is_goalkeeper() and command.PassType == "Shot" and shot_curve() then command.Curve = shot_curve() end
    if not is_goalkeeper()and command.PassType == "Shot" and (config.ShotAimbot or config.UnsavableShot or state.FlickVolley or (config.FeintShot and state.FeintActive)) and shot_target() then
        local ray, _, _, direction, applied_curve = solve_shot(shot_target(), command.ChargeSeconds, false, command.AimDirection)
        if ray then
            command.AimDirection = ray
            command.KickDirection = direction
            command.TargetPosition = ray.TargetPosition
            command.Curve = applied_curve
        end
    end
end

local function install_hooks()
    patch(modules.Shoot, "GetVelocity", function(original)
        return function(character, ...)
            local args = table.pack(...)
            if character == local_player.Character and not state.MagnetSteal and not is_goalkeeper() and args[7] == nil then
                if shot_curve() then args[12] = shot_curve() args.n = math.max(args.n, 12) end
                if config.ShotAimbot or config.UnsavableShot or state.FlickVolley or (config.FeintShot and state.FeintActive and state.FeintCommitted) then
                    local target = shot_target()
                    local aim, _, _, direction, applied_curve = solve_shot(target, args[1], false, args[2])
                    if aim then args[2] = aim args[8] = direction args[9] = aim.TargetPosition args[12] = applied_curve args.n = math.max(args.n, 12) end
                end
            end
            return original(character, table.unpack(args, 1, args.n))
        end
    end)
    patch(modules.Shoot, "GetSpin", function(original)
        return function(character, velocity, movement, curve, charge)
            if character == local_player.Character and not state.MagnetSteal and not is_goalkeeper() and shot_curve() then
                local solved=state.ShotSolution
                curve=solved and os.clock()-solved.At<.15 and solved.AppliedCurve or shot_curve()
            end
            return original(character, velocity, movement, curve, charge)
        end
    end)
    patch(modules.Ragdoll,"SetEnabled",function(original)
        return function(character,enabled,...)
            if config.AntiRagdoll and character==local_player.Character and enabled then
                return original(character,false,...)
            end
            return original(character,enabled,...)
        end
    end)
    for _, name in {"GetCameraAimRay", "GetCameraAimRayWithoutHit"} do
        patch(modules.Reticle, name, function(original)
            return function(...)
                local ray = original(...)
                return guarded("aim", aim_payload, ray) or ray
            end
        end)
    end
    for _, name in {"Start", "Update", "Release", "Send", "LockAim"} do
        patch(modules.Protocol, name, function(original)
            return function(command, ...)
                if type(command)=="table" and command.PassType=="Shot" then
                    if name=="Start" and not state.MagnetSteal then begin_shot_feint() end
                    if name=="LockAim" or name=="Release" then state.FeintCommitted=true state.ShotSolution=nil end
                end
                guarded("command aim", rewrite_command, command)
                if name=="Release"and type(command)=="table"and command.PassType=="Shot"then
                    if not state.MagnetSteal then state.LastShotTarget=shot_target() state.LastShotAt=os.clock() end
                end
                local result=table.pack(original(command,...))
                if name=="Release"and type(command)=="table"and command.PassType=="Shot"then
                    if state.FlickVolley then state.FlickVolleyReleasedAt=os.clock() end
                    state.FlickVolley=false state.FlickShotTarget=nil state.FlickGoal=nil
                end
                return table.unpack(result,1,result.n)
            end
        end)
    end
    patch(modules.ClientShoot, "HandleInputBegan", function(original)
        return function(input, processed, ...)
            if is_goalkeeper()then return original(input,processed,...)end
            if config.FlickShot and modules.Controls.IsInput("Kick",input)then
                state.FlickInputAt=os.clock()
                state.FlickInputProcessed=processed
            end
            if not processed and modules.Controls.IsInput("Kick", input) then
                if not modules.ClientShoot.IsCharging() then
                    state.FeintActive, state.FeintSide, state.FeintCommitted, state.FeintRealTarget = false, nil, false, nil
                end
                if begin_shot_flick()then return true end
                state.ShotInput = input
                state.FullChargeAt = nil
            end
            return original(input, processed, ...)
        end
    end)
    patch(modules.ClientShoot, "HandleInputEnded", function(original)
        return function(input, ...)
            if is_goalkeeper()then return original(input,...)end
            if within_shoot_range() and (config.PerfectCharge or config.UnsavableShot) and not state.ReleasingPerfect and state.ShotInput == input and modules.ClientShoot.IsCharging() then
                return true
            end
            if state.ShotInput == input then state.FeintCommitted = true state.ShotSolution = nil state.ShotInput = nil end
            return original(input, ...)
        end
    end)
    patch(modules.ActionMovement, "GetJogWalkSpeed", function(original)
        return function(speed, has_ball)
            return original(speed, has_ball and not config.NoBallSlowdown)
        end
    end)
    patch(modules.ActionMovement, "GetRunWalkSpeed", function(original)
        return function(speed, has_ball)
            return original(speed, has_ball and not config.NoBallSlowdown)
        end
    end)
    patch(modules.ActionMovement, "GetChargingWalkSpeed", function(original)
        return function(speed, has_ball)
            if config.FullSpeedCharge then
                return modules.ActionMovement.GetJogWalkSpeed(speed, has_ball)
            end
            return original(speed, has_ball)
        end
    end)
    patch(modules.Tackle, "HandleInputBegan", function(original)
        return function(input, processed)
            local root = local_root()
            if (config.TackleAimbot or (config.KeeperAutoTackle and is_goalkeeper())) and root and not processed and modules.Controls.IsInput("Tackle", input) then
                local owner = modules.Renderer.GetOwnedUserId()
                local enemy = enemy_near(root.Position, config.TackleRange + 8)
                for _, actor in state.Actors do
                    if actor.UserId == owner and not actor.Friendly then enemy = actor break end
                end
                state.TackleDirection = enemy and flat(enemy.Root.Position + enemy.Root.AssemblyLinearVelocity * 0.1 - root.Position)
            end
            local result = table.pack(pcall(original, input, processed))
            state.TackleDirection = nil
            if not result[1] then error(result[2], 0) end
            return table.unpack(result, 2, result.n)
        end
    end)
    patch(modules.CharacterControllers, "GetMoveCommand", function(original)
        return function(character, ...)
            if character == local_player.Character then
                if state.TackleDirection then return state.TackleDirection end
                if state.DribbleDirection then return state.DribbleDirection end
                if state.MoveDirection then
                    local manual=original(character,...)
                    if typeof(manual)=="Vector3"and manual.Magnitude>.05 then return manual end
                    return state.MoveDirection
                end
            end
            return original(character, ...)
        end
    end)
    patch(modules.CharacterControllers, "SetMoveCommand", function(original)
        return function(character, direction, look, rotate)
            if character==local_player.Character and state.MoveDirection and direction.Magnitude<.05 then
                direction = state.MoveDirection
            end
            return original(character, direction, look, rotate)
        end
    end)
    patch(modules.Dive, "GetDirectionChoice", function(original)
        return function(direction, camera, fallback)
            if state.DiveDirection and state.AutomaticDiveThread==coroutine.running() then
                local choice = original(state.DiveDirection, camera, fallback)
                state.DiveChoice = choice
                return choice
            end
            return original(direction, camera, fallback)
        end
    end)
    patch(modules.Dive, "GetWorldDirection", function(original)
        return function(...)
            if state.DiveDirection and state.AutomaticDiveThread==coroutine.running()then return state.DiveDirection end
            return original(...)
        end
    end)
    patch(modules.Dive, "Run", function(original)
        return function(root, humanoid, choice, get_camera, options)
            if state.DiveDirection and root == local_root() and state.AutomaticDiveThread == coroutine.running() then
                local direction = state.DiveDirection
                local right = Vector3.new(-direction.Z, 0, direction.X)
                local forward = (direction * choice.Forward - right * choice.Right).Unit
                get_camera = function() return CFrame.lookAt(root.Position, root.Position + forward) end
            end
            return original(root, humanoid, choice, get_camera, options)
        end
    end)
    patch(modules.TurnControl, "HasAutoRotateLock", function(original)
        return function(...)
            if state.DiveDirection and state.AutomaticDiveThread==coroutine.running() then return true end
            return original(...)
        end
    end)

end

local function create(class_name, properties, parent)
    local object = Instance.new(class_name)
    for key, value in properties do object[key] = value end
    object.Parent = parent
    return object
end

local world = create("Folder", {Name = "AxisSoccerVisuals"}, workspace)
state.World = world
local overlay = create("ScreenGui", {
    Name = "AxisSoccerOverlay", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 90, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, gui_parent)
local esp_entries = {}
local path_lines = {}

local function label(parent, text, color)
    return create("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = text, TextColor3 = color, TextSize = 12,
        Font = Enum.Font.GothamMedium, TextStrokeColor3 = Color3.new(0, 0, 0),
        TextStrokeTransparency = 0.2, Size = UDim2.fromOffset(200, 20),
        AnchorPoint = Vector2.new(0.5, 1), ZIndex = 3,
    }, parent)
end

local function line(parent, color, thickness)
    return create("Frame", {
        BackgroundColor3 = color, BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(1, thickness or 1),
        Visible = false, ZIndex = 1,
    }, parent)
end

local function set_line(object, a, b, color, thickness)
    local delta = b - a
    object.Position = UDim2.fromOffset((a.X + b.X) * 0.5, (a.Y + b.Y) * 0.5)
    object.Size = UDim2.fromOffset(delta.Magnitude, thickness or 1)
    object.Rotation = math.deg(math.atan2(delta.Y, delta.X))
    object.BackgroundColor3 = color
    object.Visible = true
end

local shot_marker = create("Frame", {
    Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1, Visible = false, ZIndex = 5,
}, overlay)
create("UICorner", {CornerRadius = UDim.new(1, 0)}, shot_marker)
local shot_stroke = create("UIStroke", {Color = config.PathColor, Thickness = 2}, shot_marker)
local shot_label = label(shot_marker, "SHOT", config.PathColor)
shot_label.Position = UDim2.new(0.5, 0, 0, -4)
local landing_marker = create("Part", {
    Name = "Landing", Anchored = true, CanCollide = false, CanTouch = false,
    CanQuery = false, Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon,
    Size = Vector3.new(0.06, 3, 3), Color = config.PathColor, Transparency = 1,
}, world)
local landing_label = label(overlay, "", config.PathColor)
landing_label.Visible = false
local fov_circle = create("Frame", {
    BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
    Visible = false, ZIndex = 1,
}, overlay)
create("UICorner", {CornerRadius = UDim.new(1, 0)}, fov_circle)
create("UIStroke", {Color = Color3.fromRGB(215, 220, 233), Thickness = 1, Transparency = 0.35}, fov_circle)
local ball_label = label(overlay, "BALL", config.BallColor)
ball_label.Visible = false

local function entry_for(key)
    local entry = esp_entries[key]
    if entry then return entry end
    local frame = create("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
    }, overlay)
    local box = create("Frame", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
    }, frame)
    local stroke = create("UIStroke", {Thickness = 1, Color = config.EnemyColor}, box)
    entry = {Frame = frame, Box = box, Stroke = stroke, Label = label(frame, "", config.EnemyColor), Tracer = line(overlay, config.EnemyColor)}
    entry.Label.Position = UDim2.new(0.5, 0, 0, -3)
    esp_entries[key] = entry
    return entry
end

local function refresh_items()
    local items, seen = {}, {}
    local misc = workspace:FindFirstChild("Misc")
    local folder = misc and misc:FindFirstChild("Items")
    local function add(object, kind)
        if seen[object] or not (object:IsA("Model") or object:IsA("BasePart")) then return end
        seen[object] = true
        local name = object.Name
        if not kind then
            if name:find("ItemBox") or collection_service:HasTag(object, "GameplayItemBox") then
                kind = "ItemBoxESP"
            elseif name:lower():find("projectile") or name:lower():find("rocket") then
                kind = "ProjectileESP"
            else
                kind = "WorldItemESP"
            end
        end
        items[#items + 1] = {Object = object, Kind = kind, Name = kind == "ItemBoxESP" and "ITEM BOX" or name:gsub("Projectile", "")}
    end
    if folder then for _, object in folder:GetChildren() do add(object) end end
    for _, object in collection_service:GetTagged("GameplayItemBox") do add(object, "ItemBoxESP") end
    state.Items = items
end

local function project(camera, position)
    local point, visible = camera:WorldToViewportPoint(position)
    return Vector2.new(point.X, point.Y), visible and point.Z > 0
end

local function render_esp()
    local camera = workspace.CurrentCamera
    local root = local_root()
    if not camera then return end
    for _, entry in esp_entries do
        entry.Seen = false
        entry.Frame.Visible = false
        entry.Tracer.Visible = false
        if entry.Cham then entry.Cham.Enabled = false end
    end
    local origin = root and root.Position or camera.CFrame.Position
    player_visuals.Render(camera,origin)
    for _, item in state.Items do
        local object = item.Object
        if config[item.Kind] and object.Parent then
            local position = object:IsA("BasePart") and object.Position or object:GetPivot().Position
            local distance = (position - origin).Magnitude
            if distance <= config.ESPDistance then
                local entry = entry_for(object)
                entry.Seen = true
                local p, visible = project(camera, position)
                if visible then
                    entry.Frame.Visible = true
                    entry.Frame.Position = UDim2.fromOffset(p.X, p.Y)
                    entry.Frame.Size = UDim2.fromOffset(0, 0)
                    entry.Box.Visible = false
                    entry.Label.TextColor3 = item.Kind=="ItemBoxESP"and config.ItemBoxColor or item.Kind=="ProjectileESP"and config.ProjectileColor or config.ItemColor
                    entry.Label.Text = string.format("%s  %dm", item.Name, math.floor(distance / 3.57))
                end
            end
        end
    end
    for key, entry in esp_entries do
        if not entry.Seen then
            entry.Frame:Destroy()
            entry.Tracer:Destroy()
            if entry.Cham then entry.Cham:Destroy() end
            esp_entries[key] = nil
        end
    end
    ball_label.Visible = false
    local position = modules.Renderer.GetPosition()
    if config.BallESP and position and (position - origin).Magnitude <= config.ESPDistance then
        local p, visible = project(camera, position)
        ball_label.Visible = visible
        ball_label.Position = UDim2.fromOffset(p.X, p.Y - 12)
        ball_label.TextColor3 = config.BallColor
        ball_label.Text = string.format("BALL  %dm", math.floor((position - origin).Magnitude / 3.57))
    end
    shot_marker.Visible = false
    if config.ShotPreview and state.ShotTarget then
        local p, visible = project(camera, state.ShotCrossing or state.ShotTarget)
        shot_marker.Position = UDim2.fromOffset(p.X, p.Y)
        shot_marker.Visible = visible
        shot_stroke.Color = config.ShotColor
        shot_label.TextColor3 = config.ShotColor
    end
    fov_circle:FindFirstChildOfClass("UIStroke").Color=config.ItemFOVColor
    fov_circle.Visible = config.ShowItemFOV and config.ItemAimbot
    fov_circle.Position = UDim2.fromOffset(camera.ViewportSize.X * modules.Reticle.GunScreenPosition.X, camera.ViewportSize.Y * modules.Reticle.GunScreenPosition.Y)
    fov_circle.Size = UDim2.fromOffset(config.ItemAimFOV * 2, config.ItemAimFOV * 2)
    for _, segment in path_lines do segment.Visible = false end
    if config.FlightPath then
        for i = 2, #state.Points do
            local a, a_visible = project(camera, state.Points[i - 1])
            local b, b_visible = project(camera, state.Points[i])
            if a_visible and b_visible then
                local segment = path_lines[i - 1]
                if not segment then
                    segment = line(overlay, config.PathColor, 2)
                    path_lines[i - 1] = segment
                end
                set_line(segment, a, b, config.PathColor, 2)
            end
        end
    end
    landing_label.Visible = false
    landing_marker.Transparency = 1
    if config.LandingMarker and state.Landing then
        local hit = state.Landing
        local normal = hit.Normal or Vector3.yAxis
        local point = hit.Position - normal * modules.Physics.BallRadius + normal * 0.06
        landing_marker.CFrame = CFrame.lookAt(point, point + normal) * CFrame.Angles(0, math.pi * 0.5, 0)
        landing_marker.Color = config.LandingColor
        landing_marker.Transparency = 0.25
        local p, visible = project(camera, point)
        landing_label.Position = UDim2.fromOffset(p.X, p.Y - 10)
        landing_label.TextColor3 = config.LandingColor
        landing_label.Text = string.format("LAND  %.1fs", math.max(0, hit.Time - modules.Clock.GetSmoothedServerTime()))
        landing_label.Visible = visible
    end
end

local function update_prediction()
    if not (config.FlightPath or config.LandingMarker or config.AutoGoalkeeper or config.BallMagnet) then
        table.clear(state.Points)
        state.Landing = nil
        return
    end
    local ball_state, boundary = modules.Renderer.GetAuthoritativeMovementState()
    local now = modules.Clock.GetSmoothedServerTime()
    if not ball_state or not boundary or modules.Renderer.GetOwnedUserId() then
        table.clear(state.Points)
        state.Landing = nil
        state.Crossing = nil
        return
    end
    local current = modules.Physics.GetStateAtTime(ball_state, now, boundary)
    state.BallState = current
    state.Boundary = boundary
    state.BallTime = now
    table.clear(state.Points)
    if config.FlightPath then
        state.Points[1] = current.Position
        local sample = current
        local step = 0.06
        for i = 1, math.ceil(config.FlightPathSeconds / step) do
            sample = modules.Physics.GetStateAtTime(sample, now + i * step, boundary)
            state.Points[#state.Points + 1] = sample.Position
            if sample.Mode == "Resting" then break end
        end
    end
    state.Landing = config.LandingMarker and modules.Physics.GetLanding(current, boundary, now, config.FlightPathSeconds) or nil
    state.Crossing = nil
    if config.AutoGoalkeeper and is_goalkeeper() then
        local goal = goal_for(true)
        if goal then
            local mouth=get_mouth(goal)
            local root=local_root()
            if mouth and root and current.Velocity:Dot(mouth.Forward)<-.1 then
                local depth=math.clamp((root.Position-mouth.PlanePosition):Dot(mouth.Forward),1,12)
                local plane=mouth.PlanePosition+mouth.Forward*depth
                local center=Vector3.new(plane.X,(mouth.BottomY+mouth.TopY)*.5,plane.Z)
                local box={CFrame=CFrame.lookAt(center,center+mouth.Forward),Size=Vector3.new(mouth.HalfWidth*2+2,mouth.TopY-mouth.BottomY+2,.8)}
                local position,time=modules.Physics.GetFirstBoxEntry(current,boundary,box,now,2.5,false)
                if position and time then state.Crossing={Position=position,Time=time,Box=box}end
            end
        end
    end
end

local function attempt_keeper_dive(direction)
    if not direction or os.clock()<(state.KeeperNextDiveAt or 0)then return false end
    state.DiveDirection=direction
    state.AutomaticDiveThread=coroutine.running()
    local accepted=guarded("keeper dive",modules.Keeper.Dive)
    state.DiveDirection=nil
    state.AutomaticDiveThread=nil
    state.DiveChoice=nil
    state.KeeperNextDiveAt=os.clock()+(accepted and modules.Dive.Constants.RepeatDelaySeconds or .25)
    return accepted==true
end

local function keeper_step()
    if not config.AutoGoalkeeper or not is_goalkeeper()or owns_ball()then return false end
    if modules.ClientShoot.IsCharging()or modules.Pass.IsCharging()or modules.Keeper.IsForcedClearActive()then return false end
    local crossing=state.Crossing
    local root=local_root()
    local goal=goal_for(true)
    if not root or not goal then return false end
    local mouth=get_mouth(goal)
    if not mouth then return false end
    local carrier=modules.Renderer.GetOwnedUserId()
    if config.KeeperDiveOnContact and carrier and not modules.Dive.IsDiveConstraintActive(root)
        and not modules.Tackle.IsSlideTackling()then
        local zone=goal.Parent and goal.Parent:FindFirstChild("Goalkeeper")
        local nearest,nearestDistance=nil,config.KeeperDiveRange
        local ball=modules.Renderer.GetPosition()
        for _,actor in ipairs(state.Actors)do
            if actor.UserId==carrier and not actor.Friendly and actor.Root.Parent and actor.Character.Parent
                and not actor.Character:GetAttribute("Ragdolled")
                and (not ball or (ball-actor.Root.Position).Magnitude<=6)then
                local predicted=actor.Root.Position+actor.Root.AssemblyLinearVelocity*config.KeeperContactLead
                local inside=false
                if zone and zone:IsA("BasePart")then
                    local p=zone.CFrame:PointToObjectSpace(predicted)
                    inside=math.abs(p.X)<=zone.Size.X*.5 and math.abs(p.Z)<=zone.Size.Z*.5
                        and math.abs(p.Y)<=zone.Size.Y*.5+4
                else
                    local relative=predicted-mouth.PlanePosition
                    inside=math.abs(relative:Dot(mouth.Lateral))<=mouth.HalfWidth+30
                        and math.abs(relative:Dot(mouth.Forward))<=35
                end
                if inside then
                    local delta=predicted-root.Position
                    local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
                    if distance<nearestDistance then nearest,nearestDistance=predicted,distance end
                end
            end
        end
        if nearest then
            local direction=flat(nearest-root.Position)
            if direction and os.clock()>=(state.KeeperNextDiveAt or 0)then
                attempt_keeper_dive(direction)
                return true
            end
        end
    end
    if not crossing then return false end
    if carrier then state.Crossing=nil return false end
    local remaining=crossing.Time-modules.Clock.GetSmoothedServerTime()
    if remaining<=0 then state.Crossing=nil return false end
    local delta=crossing.Position-root.Position
    local horizontal=Vector3.new(delta.X,0,delta.Z)
    local distance=horizontal.Magnitude
    local reach=modules.Dive.GetDistance(local_player.Character)
    local contact=modules.Dive.Constants.SaveReachStuds or 2
    local travel=modules.Dive.GetCurveSecondsForTravel(math.clamp(distance-contact,0,reach),reach)
    local threshold=travel+config.KeeperReaction+.05
    if distance>reach+contact then
        state.MoveDirection=flat(delta)
        return true
    end
    if remaining>threshold then
        if distance>2 then state.MoveDirection=flat(delta)end
        return true
    end
    local ball_state,boundary=modules.Renderer.GetAuthoritativeMovementState()
    local now=modules.Clock.GetSmoothedServerTime()
    if not ball_state or not boundary or modules.Renderer.GetOwnedUserId()then state.Crossing=nil return false end
    local current=modules.Physics.GetStateAtTime(ball_state,now,boundary)
    if not current or current.Velocity:Dot(mouth.Forward)>=-.1 then state.Crossing=nil return false end
    local position,time=modules.Physics.GetFirstBoxEntry(current,boundary,crossing.Box,now,2.5,false)
    if not position or not time then state.Crossing=nil return false end
    crossing.Position,crossing.Time=position,time
    delta=position-root.Position
    horizontal=Vector3.new(delta.X,0,delta.Z)
    distance=horizontal.Magnitude
    remaining=time-now
    travel=modules.Dive.GetCurveSecondsForTravel(math.clamp(distance-contact,0,reach),reach)
    threshold=travel+config.KeeperReaction+.05
    if distance>reach+contact or remaining>threshold then
        if distance>2 then state.MoveDirection=flat(delta)end
        return true
    end
    local ball=modules.Renderer.GetPosition()
    local direction=flat(delta)or(ball and flat(ball-root.Position))or mouth.Forward
    attempt_keeper_dive(direction)
    return true
end

local function magnet_ball_velocity(owner,position)
    local now=os.clock()
    local velocity
    if state.MagnetBallOwner==owner and state.MagnetBallPosition and state.MagnetBallAt then
        local elapsed=now-state.MagnetBallAt
        if elapsed>=.03 and elapsed<=.25 then
            local observed=(position-state.MagnetBallPosition)/elapsed
            if observed.Magnitude<70 then velocity=observed end
        end
    end
    state.MagnetBallOwner=owner
    state.MagnetBallPosition=position
    state.MagnetBallAt=now
    return velocity
end

local function magnet_intercept(position,root,enemy,ball_velocity,lead)
    local carrier_velocity=enemy.Root.AssemblyLinearVelocity
    local horizontal=Vector3.new(carrier_velocity.X,0,carrier_velocity.Z)
    if horizontal.Magnitude>35 then horizontal=horizontal.Unit*35 end
    local observed=ball_velocity and Vector3.new(ball_velocity.X,0,ball_velocity.Z) or horizontal
    local velocity=horizontal*.7+observed*.3
    local local_velocity=root.AssemblyLinearVelocity
    local local_horizontal=Vector3.new(local_velocity.X,0,local_velocity.Z)
    if local_horizontal.Magnitude>35 then local_horizontal=local_horizontal.Unit*35 end
    local target=position+velocity*lead
    local future_root=root.Position+local_horizontal*lead
    return target,target-future_root
end

local function magnet_kick(owner,position,root,enemy,ball_velocity)
    if not owner or owner==local_player.UserId or is_goalkeeper()or state.MagnetStealInput
        or modules.ClientShoot.IsCharging()or modules.Pass.IsCharging()then return end
    if enemy.Character:GetAttribute("Ragdolled") or modules.DodgeAction.IsDribbling(enemy.Character)
        or modules.SlideTackle.GetSlidingUntil(enemy.Character)then return end
    local offset=position-root.Position
    local horizontal=Vector3.new(offset.X,0,offset.Z)
    local target,predicted=magnet_intercept(position,root,enemy,ball_velocity,modules.KickCore.Constants.MinimumChargeSeconds+.02)
    local predicted_horizontal=Vector3.new(predicted.X,0,predicted.Z)
    if offset.Magnitude>config.MagnetStealRange+.8 or predicted_horizontal.Magnitude>config.MagnetStealRange
        or math.abs(offset.Y)>2.25 or math.abs(predicted.Y)>2.5 then return end
    if horizontal.Magnitude>.01 and root.CFrame.LookVector:Dot(horizontal.Unit)<.55 then return end
    if predicted_horizontal.Magnitude>.01 and root.CFrame.LookVector:Dot(predicted_horizontal.Unit)<.5 then return end
    if os.clock()<(state.NextMagnetKickAt or 0)then return end
    local input=modules.Controls.CreateInput("Kick")
    state.MagnetSteal=true
    state.MagnetStealTarget=target
    state.MagnetStealAttemptAt=os.clock()
    state.MagnetStealAttemptDistance=offset.Magnitude
    guarded("magnet kick",modules.ClientShoot.HandleInputBegan,input,false)
    if modules.ClientShoot.IsCharging()then
        state.NextMagnetKickAt=os.clock()+.8
        state.MagnetStealChargedAt=os.clock()
        state.MagnetStealInput=input
        state.MagnetStealReleaseAt=os.clock()+modules.KickCore.Constants.MinimumChargeSeconds+.03
    else
        state.NextMagnetKickAt=os.clock()+.12
        state.MagnetSteal=false state.MagnetStealTarget=nil state.ShotInput=nil
    end
end

local function magnet_step()
    if not config.BallMagnet or owns_ball()or state.MagnetStealInput then
        state.MagnetDirection=nil
        return
    end
    local root=local_root()
    local position=modules.Renderer.GetPosition()
    if not root or not position or(position-root.Position).Magnitude>config.MagnetRange then
        state.MagnetDirection=nil
        return
    end
    local owner=modules.Renderer.GetOwnedUserId()
    if owner then
        local enemy
        for _,actor in ipairs(state.Actors)do
            if actor.UserId==owner then
                if actor.Friendly then state.MagnetDirection=nil return end
                enemy=actor
                break
            end
        end
        if not enemy then state.MagnetDirection=nil return end
        state.MagnetDirection=nil
        local velocity=magnet_ball_velocity(owner,position)
        local predicted=magnet_intercept(position,root,enemy,velocity,.18)
        local toward=flat(predicted-root.Position)
        if toward then state.MoveDirection=toward end
        magnet_kick(owner,position,root,enemy,velocity)
        return
    end
    local predicted=position
    if not owner and state.BallState and state.Boundary then
        local now=modules.Clock.GetSmoothedServerTime()
        predicted=modules.Physics.GetStateAtTime(state.BallState,now+.08,state.Boundary).Position
    end
    local delta=Vector3.new(predicted.X-root.Position.X,0,predicted.Z-root.Position.Z)
    if math.abs(predicted.Y-root.Position.Y)>7 then return end
    if delta.Magnitude<1.5 then state.MagnetDirection=nil return end
    if not state.MagnetDirection or ready("magnet",config.MagnetCooldown)then
        state.MagnetDirection=delta.Unit
    end
    state.MoveDirection=state.MagnetDirection
end

local function automation_step()
    state.MoveDirection = nil
    if state.MagnetStealInput and (not config.BallMagnet or owns_ball()
        or not modules.ClientShoot.IsCharging()or os.clock()>=(state.MagnetStealReleaseAt or 0))then
        local input=state.MagnetStealInput
        if modules.ClientShoot.IsCharging()then
            local root=local_root()
            local ball=modules.Renderer.GetPosition()
            local owner=modules.Renderer.GetOwnedUserId()
            local enemy
            for _,actor in ipairs(state.Actors)do
                if actor.UserId==owner and not actor.Friendly then enemy=actor break end
            end
            local offset=root and ball and ball-root.Position
            local horizontal=offset and Vector3.new(offset.X,0,offset.Z)
            local aligned=horizontal and horizontal.Magnitude>.01
                and root.CFrame.LookVector:Dot(horizontal.Unit)>=.5
            if config.BallMagnet and enemy and not modules.DodgeAction.IsDribbling(enemy.Character)
                and not modules.SlideTackle.GetSlidingUntil(enemy.Character) and not owns_ball()and offset
                and offset.Magnitude<=config.MagnetStealRange+.4 and math.abs(offset.Y)<=2.5 and aligned then
                state.MagnetStealTarget=magnet_intercept(ball,root,enemy,nil,.04)
                state.ReleasingPerfect=true
                guarded("magnet kick release",modules.ClientShoot.HandleInputEnded,input)
                state.MagnetStealReleasedAt=os.clock()
                state.ReleasingPerfect=false
            else
                guarded("magnet kick cancel",modules.ClientShoot.CancelCharge)
            end
        end
        state.MagnetStealInput=nil state.MagnetSteal=false state.MagnetStealTarget=nil
        state.MagnetStealCooldownUntil=os.clock()+.35
    end
    if config.SpeedBoost then modules.Movement.SetMultiplier("AxisSoccerSpeed",{WalkSpeed=config.SpeedMultiplier})
    else modules.Movement.ClearMultiplier("AxisSoccerSpeed")end
    if config.AntiRagdoll and ready("ragdoll",.4)then
        modules.Movement.SuppressServerRagdoll("AxisSoccer",.8,math.huge)
        local character=local_player.Character
        if character and modules.Ragdoll.IsEnabled(character)then modules.Ragdoll.SetEnabled(character,false)end
    end
    if not can_act() then return end
    local root = local_root()
    local has_ball = owns_ball()
    if state.FlickPending and os.clock()>state.FlickPending then
        state.FlickPending=nil state.FlickJiggleSide=nil
    end
    if state.FlickPending and state.FlickJiggleSide and state.FlickJiggleStarted then
        local elapsed=os.clock()-state.FlickJiggleStarted
        local goal=goal_for(false)
        local mouth=goal and get_mouth(goal)
        if mouth and elapsed<.42 then
            local phase=math.floor(elapsed/.14)%2==0 and -1 or 1
            state.MoveDirection=mouth.Lateral*state.FlickJiggleSide*phase
        end
    end
    if state.HadBall~=has_ball then
        state.HadBall=has_ball
        state.PossessionSince=has_ball and os.clock()or nil
    end
    if config.AutoSprint and not is_goalkeeper() and not modules.Sprint.IsSprintButtonToggled() then
        modules.Sprint.ToggleSprintButton()
        state.OwnedSprintToggle = true
    end
    if within_shoot_range() and (config.PerfectCharge or config.UnsavableShot or state.AutoShot) and state.ShotInput and modules.ClientShoot.IsCharging() then
        if (modules.ClientShoot.GetFullChargeProgress() or 0) >= 1 then
            state.FullChargeAt = state.FullChargeAt or os.clock()
        end
        if state.FullChargeAt and os.clock() - state.FullChargeAt >= modules.KickCore.Constants.FullChargeGraceSeconds then
            state.ReleasingPerfect = true
            modules.ClientShoot.HandleInputEnded(state.ShotInput)
            state.ReleasingPerfect = false
            state.FullChargeAt = nil
            state.AutoShot = false
        end
    elseif not modules.ClientShoot.IsCharging() then
        state.AutoShot = false
    else
        state.FullChargeAt = nil
        if state.AutoShot and not within_shoot_range() then
            modules.ClientShoot.CancelCharge()
            state.AutoShot = false
            state.ShotInput = nil
        end
    end
    if state.FlickVolley and not modules.ClientShoot.IsCharging() and not state.AutoShot
        and os.clock()-(state.FlickVolleyStartedAt or 0)>.3 then
        state.FlickVolley=false state.FlickShotTarget=nil state.FlickGoal=nil
    end
    if state.PassInput then
        if not has_ball or not config.AutoPass then
            modules.Pass.CancelCharge()
            state.PassInput, state.PassTarget = nil, nil
        elseif os.clock() >= state.PassReleaseAt then
            modules.Pass.HandleInputEnded(state.PassInput)
            state.PassInput, state.PassTarget = nil, nil
        end
    end
    if modules.ItemUse.IsEquipped() then
        if config.AutoUseItem and not modules.ItemUse.IsEquippedItemFired() and ready("item", 0.35) then
            if not modules.ItemUse.UsesZoom() or state.ItemTarget then
                if modules.ItemUse.ActivateEquipped() then  end
            end
        end
        return
    end
    if not keeper_step() and not state.FlickPending then magnet_step() end
    if has_ball then
        if config.AutoDribble and not state.FlickPending and not is_goalkeeper()
            and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging()
            and state.PossessionSince and os.clock()-state.PossessionSince>.04 then
            guarded("auto dribble",dribble_step,root)
        end
        if config.AutoPass and not state.FlickPending and not state.PassInput and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and not modules.Dodge.IsDribbling() and ready("pass", 1.1) then
            local teammate = best_teammate()
            if teammate then
                state.PassTarget = teammate
                state.PassInput = modules.Controls.CreateInput("Pass")
                state.PassReleaseAt = os.clock() + 0.3
                modules.Pass.HandleInputBegan(state.PassInput, false)
                if modules.Pass.IsCharging() then  else state.PassInput, state.PassTarget = nil, nil end
            end
        end
    else
        if state.FlickPending and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging()
            and modules.Volley.IsAvailable(local_player.Character)then
            state.FlickPending=nil
            state.FlickJiggleSide=nil
            state.FlickShotTarget,state.FlickGoal=select_flick_shot()
            state.FlickVolley=state.FlickShotTarget~=nil
            state.FlickVolleyStartedAt=os.clock()
            state.ShotInput=modules.Controls.CreateInput("Kick")
            state.AutoShot=true
            modules.ClientShoot.HandleInputBegan(state.ShotInput,false)
            if not modules.ClientShoot.IsCharging()then
                state.FlickVolley=false state.FlickShotTarget=nil state.FlickGoal=nil state.AutoShot=false
            end
        end
        if config.AutoVolley and within_shoot_range() and not state.FlickVolley and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and ready("volley", 0.18) then
            if modules.Volley.IsAvailable(local_player.Character) then
                state.ShotInput = modules.Controls.CreateInput("Kick")
                state.AutoShot = true
                modules.ClientShoot.HandleInputBegan(state.ShotInput, false)
                if modules.ClientShoot.IsCharging() then  end
            end
        end
        if ((config.AutoTackle and not is_goalkeeper()) or (config.KeeperAutoTackle and is_goalkeeper()))
            and not state.MagnetStealInput and os.clock()>=(state.MagnetStealCooldownUntil or 0)
            and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and not modules.Dive.IsDiveConstraintActive(root) and not modules.Tackle.IsSlideTackling() and ready("tackle", 0.25) then
            local owner = modules.Renderer.GetOwnedUserId()
            local ball=modules.Renderer.GetPosition()
            if not (config.BallMagnet and not is_goalkeeper()and owner and ball
                and(ball-root.Position).Magnitude<=config.MagnetRange)then
                for _, actor in state.Actors do
                    if actor.UserId == owner and not actor.Friendly and (actor.Root.Position - root.Position).Magnitude <= (is_goalkeeper() and config.KeeperTackleRange or config.TackleRange) then
                        modules.Tackle.HandleInputBegan(modules.Controls.CreateInput("Tackle"), false)
                        if modules.Tackle.IsSlideTackling() then  end
                        break
                    end
                end
            end
        end
        if config.AutoCallForPass and ready("call", config.CallInterval) then
            if modules.Call.CanCallForPass() then
                modules.Call.HandleInputBegan(modules.Controls.CreateInput("Request"), false)
                
            end
        end
    end
end

local function unload()
    if not state.Alive then return end
    state.Alive = false
    if state.MobileGui then state.MobileGui:Destroy()state.MobileGui=nil end
    if library and library.FlushAutosave then pcall(function()library:FlushAutosave()end)end
    pcall(modules.Movement.ClearMultiplier,"AxisSoccerSpeed")
    pcall(modules.Movement.ClearServerRagdollSuppression,"AxisSoccer")
    if player_visuals then pcall(player_visuals.Cleanup)end
    for _, connection in state.Connections do connection:Disconnect() end
    state.MoveDirection, state.DiveDirection, state.TackleDirection, state.DribbleDirection = nil, nil, nil, nil
    state.MagnetStealTarget=nil
    if state.AutoShot then pcall(modules.ClientShoot.CancelCharge) end
    if state.MagnetStealInput then pcall(modules.ClientShoot.CancelCharge) end
    if state.PassInput then pcall(modules.Pass.CancelCharge) end
    pcall(modules.Sprint.SetUnlimitedStamina, "AxisSoccer", false)
    if state.OwnedSprintToggle and modules.Sprint.IsSprintButtonToggled() then
        pcall(modules.Sprint.ToggleSprintButton)
    end
    for i = #state.Hooks, 1, -1 do
        local hook = state.Hooks[i]
        if hook[1][hook[2]] == hook[4] then hook[1][hook[2]] = hook[3] end
    end
    pcall(function() overlay:Destroy() end)
    pcall(function() world:Destroy() end)
    if library and not library.Unloaded then
        library.Unloaded = true
        pcall(function() library:Unload() end)
    end
    if env.AxisIllegalSoccer and env.AxisIllegalSoccer.State == state then env.AxisIllegalSoccer = nil end
end

local function set_config(key,value)
    config[key]=value
    if key=="FlickShot"and not value then
        state.FlickPending=nil state.FlickVolley=false state.FlickShotTarget=nil
        state.FlickGoal=nil state.FlickJiggleSide=nil
    end
    if key=="AutoPass"and not value then state.PassTarget=nil end
    if key=="AutoDribble"and not value then table.clear(state.DribbleThreats) state.NextDribbleAt=nil end
    if key=="BallMagnet"and not value then state.MagnetDirection=nil state.MagnetStealTarget=nil end
    if key=="AutoGoalkeeper"and not value then state.DiveDirection=nil state.MoveDirection=nil end
    if key=="ShotCurve" or key=="CurveShot" or key=="CurveSide" or key=="FeintShot" then state.ShotSolution=nil state.ShotSearchAt=nil end
    if key=="FeintShot" and not value then state.FeintActive, state.FeintSide = false, nil end
    if key=="InfiniteStamina"then modules.Sprint.SetUnlimitedStamina("AxisSoccer",value)end
    if key=="AntiRagdoll"and not value then modules.Movement.ClearServerRagdollSuppression("AxisSoccer")end
    if key=="SpeedBoost"and not value then modules.Movement.ClearMultiplier("AxisSoccerSpeed")end
    if key=="AutoSprint"and not value and state.OwnedSprintToggle then
        if modules.Sprint.IsSprintButtonToggled()then modules.Sprint.ToggleSprintButton()end
        state.OwnedSprintToggle=false
    end
end
local function build_ui()
    local ui=assert(loadstring(Sources.UI))()({Config=config,State=state,Set=set_config,Unload=unload,Connect=connect})
    library,window,ui_controls=ui.Library,ui.Window,ui.Controls
    state.Window=window
    player_visuals=assert(loadstring(Sources.Visuals))()({Config=config,State=state,Overlay=overlay,Create=create,Chams=Sources.Chams})
end

env.AxisIllegalSoccer={
    State=state,Config=config,Unload=unload,
    Set=function(key,value)
        local control=ui_controls[key]
        if control then control:Set(value)else set_config(key,value)end
    end,
    SolveShot=solve_shot,SelectShot=select_shot,GetShotTarget=shot_target,PredictShotCrossing=predict_shot_crossing,
}

local ok, err = xpcall(function()
    build_ui()
    set_config("InfiniteStamina",config.InfiniteStamina)
    install_hooks()
    refresh_actors()
    refresh_items()
    local accumulator = 0
    local function mark_dribble(model,active)
        if not config.AutoDribble or not owns_ball() or typeof(model)~="Instance" or not model:IsA("Model") or model==local_player.Character then return end
        if active==false then
            state.DribbleThreats[model]=os.clock()+.15
        else
            state.DribbleThreats[model]=true
        end
    end
    for _,signal in ipairs({modules.SlideTackle.SlidingUntilChanged,modules.ActionCharge.StateChanged})do
        if typeof(signal)=="Instance" and signal:IsA("BindableEvent") then
            connect(signal.Event,mark_dribble)
        end
    end
    connect(run_service.Heartbeat, function(dt)
        if not state.Alive then return end
        accumulator += dt
        if accumulator < 0.04 then return end
        accumulator = 0
        if ready("actors", 0.35) then guarded("actors", refresh_actors) end
        if ready("world", 0.5) then guarded("world", refresh_items) end
        if ready("target", 0.08) then
            guarded("targets", function()
                if config.ShotAimbot or config.UnsavableShot or config.ShotPreview or config.FeintShot or config.CurveShot then
                    local target,goal=select_shot()
                    target=choose_shot(target,goal)
                    if state.TargetGoal~=goal or not target or not state.ShotTarget or(target-state.ShotTarget).Magnitude>.1 then state.ShotCrossing=nil end
                    state.ShotTarget,state.TargetGoal=target,goal
                else state.ShotTarget, state.TargetGoal = nil, nil end
                state.ItemTarget = (config.ItemAimbot or config.AutoUseItem) and item_target() or nil
            end)
        end
        if ready("prediction", config.AutoGoalkeeper and .04 or .1) then guarded("prediction", update_prediction) end
        guarded("automation", automation_step)
    end)
    connect(run_service.RenderStepped, function()
        if state.Alive then guarded("visuals", render_esp) end
    end)
    connect(local_player.CharacterRemoving, function()
        state.ShotInput, state.PassInput, state.PassTarget = nil, nil, nil
        state.MoveDirection, state.DiveDirection, state.Crossing = nil, nil, nil
        state.BallState, state.Boundary, state.Landing = nil, nil, nil
        state.AutoShot = false
        state.FeintCommitted, state.ShotSolution, state.DiveChoice = nil, nil, nil
        state.FeintActive, state.FeintSide, state.FeintSwitchAt = false, nil, nil
        state.FlickPending=nil state.FlickVolley=false state.FlickShotTarget=nil
        state.FlickGoal=nil state.FlickJiggleSide=nil state.PossessionSince=nil
        state.MagnetSteal=false state.MagnetStealInput=nil state.MagnetStealTarget=nil
        state.MagnetDirection=nil state.MagnetBallPosition=nil state.MagnetBallOwner=nil state.NextMagnetKickAt=nil
        state.DribbleDirection=nil state.NextDribbleAt=nil state.NextDribbleScanAt=nil table.clear(state.DribbleThreats)
        table.clear(state.Points)
    end)
end,function(message)return tostring(message)end)

if not ok then state.Errors.Startup=err unload()end
