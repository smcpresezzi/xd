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
    slider(shots,"ShotMargin","Post clearance",1.5,4,.1)
    toggle(shots,"UnsavableShot","Unsavable shot")
    toggle(shots,"PerfectCharge","Perfect charge")
    toggle(shots,"FlickShot","Flick shot")
    slider(shots,"ShotCurve","Curve",-100,100)
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
    ShotAimbot = false, ShotPlacement = "Auto", TargetPost = "Automatic",
    UnsavableShot = false, PerfectCharge = false, AutoPass = false,
    ShotCurve = 0, FeintShot = false, FeintChance = 50, FlickShot = false, KeeperAutoTackle = false, KeeperTackleRange = 12,
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
    DribbleRange = 14, MagnetRange = 14, PassRange = 100,
    CallInterval = 2.5, KeeperReaction = 0.18,
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
    Tackle = module("Client.Gameplay.Actions.SlideTackleInput"),
    Call = module("Client.Gameplay.Actions.CallForPass"),
    Sprint = module("Client.Gameplay.Player.Sprint"),
    Movement = module("Client.Gameplay.Player.Movement"),
    TurnControl = module("Client.Gameplay.Player.TurnControl"),
    ActionMovement = module("Modules.Actions.ActionMovement"),
    Keeper = module("Client.Gameplay.Player.GoalkeeperRole"),
    Dive = module("Modules.Actions.GoalkeeperDive"),
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

local function safe_shot_target(target, mouth)
    if not mouth then return target end
    local clearance = math.max(modules.Physics.BallRadius + 1.25, config.ShotMargin)
    local width = math.max(0, mouth.HalfWidth - clearance)
    local low = mouth.BottomY + modules.Physics.BallRadius + .5
    local high = math.max(low, mouth.TopY - clearance - .75)
    local lateral = math.clamp((target - mouth.PlanePosition):Dot(mouth.Lateral), -width, width)
    local point = mouth.PlanePosition + mouth.Lateral * lateral
    return Vector3.new(point.X, math.clamp(target.Y, low, high), point.Z)
end

local function select_shot()
    local goal,team=goal_for(false)
    local root=local_root()
    if not goal or not root then return nil end
    local mouth=get_mouth(goal)
    if not mouth then return nil end
    local clearance=math.max(modules.Physics.BallRadius+.75,config.ShotMargin)
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
    local function keeperDifficulty(candidate)
        if not keeper then return 0 end
        local segment=candidate-origin
        local horizontal=Vector3.new(segment.X,0,segment.Z)
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
        local lateralOffset=offset:Dot(mouth.Lateral)
        local reverseDelay=lateralVelocity*lateralOffset<0 and math.min(.12,math.abs(lateralVelocity)*.006)or 0
        local available=math.max(0,arrival-.14-reverseDelay)
        local reachable=modules.Dive.GetTravel(available,keeperReach)+contactReach
        local distanceMargin=horizontalGap-reachable
        local needed=math.max(0,horizontalGap-contactReach)
        local diveTime=modules.Dive.GetCurveSecondsForTravel(math.min(needed,keeperReach),keeperReach)
        local timeMargin=diveTime-available
        local aboveReach=math.max(0,intercept.Y-predicted.Y-modules.Dive.Constants.MaximumSaveHeight)
        return distanceMargin*2+timeMargin*8+aboveReach*2
    end
    local best,bestScore
    for _,fraction in ipairs({0,-.36,.36,-.72,.72,-1,1})do
        for _,height in ipairs({middle,low,high})do
            local candidate=point(width*fraction,height)
            local score=keeperDifficulty(candidate)
            score-=math.abs(fraction)^4*.6
            score-=math.abs(height-middle)*.08
            score-=(candidate-root.Position).Magnitude*.01
            if state.LastShotTarget and os.clock()-(state.LastShotAt or 0)<12 then
                score-=math.max(0,1-(candidate-state.LastShotTarget).Magnitude/8)*.35
            end
            for _,actor in ipairs(state.Actors)do
                if actor.Team==team and not actor.Keeper and actor.Root.Parent then
                    local segment=candidate-root.Position
                    local alpha=math.clamp((actor.Root.Position-root.Position):Dot(segment)/math.max(segment:Dot(segment),1),0,1)
                    local distance=(actor.Root.Position-(root.Position+segment*alpha)).Magnitude
                    score-=math.max(0,5-distance)*2
                end
            end
            if not bestScore or score>bestScore then best=candidate bestScore=score end
        end
    end
    return best or placements.Center,goal
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
    if config.ShotCurve == 0 then return nil end
    return math.clamp(config.ShotCurve / 100, -1, 1)
end

local feint_random = Random.new()

local function begin_shot_feint()
    state.FeintCommitted = false
    state.FeintActive = config.FeintShot and feint_random:NextNumber() < math.clamp(config.FeintChance, 0, 100) / 100
    state.FeintSide = state.FeintActive and (feint_random:NextInteger(0, 1) == 0 and -1 or 1) or nil
    state.FeintSwitchAt = os.clock() + feint_random:NextNumber(.16,.25)
    state.ShotSolution = nil
end

local function shot_target()
    if not config.FeintShot or not state.FeintActive then return state.ShotTarget end
    local goal = state.TargetGoal or goal_for(false)
    local mouth = goal and get_mouth(goal)
    if not mouth then return state.ShotTarget end
    local clearance = math.max(modules.Physics.BallRadius + .75, config.ShotMargin)
    local width = math.max(0, mouth.HalfWidth - clearance)
    local blend=math.clamp((os.clock()-(state.FeintSwitchAt or 0))/.15,0,1)
    blend=blend*blend*(3-2*blend)
    if state.FeintCommitted then blend=1 end
    local position = mouth.PlanePosition + mouth.Lateral * ((state.FeintSide or 1) * width * (1-2*blend))
    return safe_shot_target(Vector3.new(position.X, math.max(mouth.BottomY + clearance, mouth.TopY - clearance), position.Z), mouth)
end

local function begin_shot_flick()
    state.FlickAttemptAt=os.clock()
    if not config.FlickShot or not can_act() or not owns_ball()or is_goalkeeper()then return false end
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
    return true
end

local raw_velocity=modules.Shoot.GetVelocity
local function launch_position(pass_type,aim,charge)
    local character=local_player.Character
    if character then return modules.Carry.GetLaunchPosition(character,pass_type,aim,false,charge)end
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

local function solve_shot(target,charge,is_throw,initial_aim)
    local character=local_player.Character
    if not character or not target then return nil end
    local goal = not is_throw and (state.TargetGoal or goal_for(false)) or nil
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
        return table.clone(cached.Aim),cached.Velocity,cached.Origin,cached.Direction
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
                return {Direction=kick_direction,Aim=ray, Velocity=speed, Origin=start, X=error_x, Y=error_y, Loss=error_x*error_x+error_y*error_y}
            end
            local yaw = math.atan2(aim.Direction.Z, aim.Direction.X)
            local pitch = math.asin(math.clamp(aim.Direction.Y, -1, 1))
            local best
            for _ = 1, 9 do
                local sample = evaluate(yaw, pitch)
                if not sample then break end
                if not best or sample.Loss < best.Loss then best = sample end
                if sample.Loss < .0225 then break end
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
            if best then
                aim, velocity, origin, direction = best.Aim, best.Velocity, best.Origin, best.Direction
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
            CharacterVelocity=characterVelocity,Aim=table.clone(aim),Velocity=velocity,Origin=origin,Direction=direction}
    end
    return aim,velocity,origin,direction
end

local function aim_payload(original)
    if not state.Alive or not can_act() then return original end
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
    if (config.ShotAimbot or config.UnsavableShot or (config.FeintShot and state.FeintActive)) and shot_target() and not modules.Pass.IsCharging() and not is_goalkeeper() then
        return solve_shot(shot_target(), nil, false, original) or original
    end
    return original
end

local function rewrite_command(command)
    if type(command) ~= "table" then return end
    if not is_goalkeeper() and command.PassType == "Shot" and shot_curve() then command.Curve = shot_curve() end
    if not is_goalkeeper()and command.PassType == "Shot" and (config.ShotAimbot or config.UnsavableShot or (config.FeintShot and state.FeintActive)) and shot_target() then
        local ray, _, _, direction = solve_shot(shot_target(), command.ChargeSeconds, false, command.AimDirection)
        if ray then
            command.AimDirection = ray
            command.KickDirection = direction
            command.TargetPosition = ray.TargetPosition
            command.Curve = shot_curve()
        end
    end
end

local function install_hooks()
    patch(modules.Shoot, "GetVelocity", function(original)
        return function(character, ...)
            local args = table.pack(...)
            if character == local_player.Character and not is_goalkeeper() and args[7] == nil then
                if shot_curve() then args[12] = shot_curve() args.n = math.max(args.n, 12) end
                if config.ShotAimbot or config.UnsavableShot or (config.FeintShot and state.FeintActive and state.FeintCommitted) then
                    local target = shot_target()
                    local aim, _, _, direction = solve_shot(target, args[1], false, args[2])
                    if aim then args[2] = aim args[8] = direction args[9] = aim.TargetPosition args.n = math.max(args.n, 9) end
                end
            end
            return original(character, table.unpack(args, 1, args.n))
        end
    end)
    patch(modules.Shoot, "GetSpin", function(original)
        return function(character, velocity, movement, curve, charge)
            if character == local_player.Character and not is_goalkeeper() and shot_curve() then curve = shot_curve() end
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
                    if name=="Start" then begin_shot_feint() end
                    if name=="Release" then state.FeintCommitted=true end
                end
                guarded("command aim", rewrite_command, command)
                if name=="Release"and type(command)=="table"and command.PassType=="Shot"then
                    state.LastShotTarget=shot_target() state.LastShotAt=os.clock()
                end
                return original(command, ...)
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
                    state.FeintActive, state.FeintSide, state.FeintCommitted = false, nil, false
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
            if (config.PerfectCharge or config.UnsavableShot) and not state.ReleasingPerfect and state.ShotInput == input and modules.ClientShoot.IsCharging() then
                return true
            end
            if state.ShotInput == input then state.FeintCommitted = true state.ShotInput = nil end
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
                if position and time then state.Crossing={Position=position,Time=time}end
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
    if config.KeeperDiveOnContact and not modules.Dive.IsDiveConstraintActive(root)
        and not modules.Tackle.IsSlideTackling()then
        local zone=goal.Parent and goal.Parent:FindFirstChild("Goalkeeper")
        local nearest,nearestDistance=nil,config.KeeperDiveRange
        for _,actor in ipairs(state.Actors)do
            if not actor.Friendly and actor.Root.Parent and actor.Character.Parent
                and not actor.Character:GetAttribute("Ragdolled")then
                local inside=false
                if zone and zone:IsA("BasePart")then
                    local p=zone.CFrame:PointToObjectSpace(actor.Root.Position)
                    inside=math.abs(p.X)<=zone.Size.X*.5 and math.abs(p.Z)<=zone.Size.Z*.5
                        and math.abs(p.Y)<=zone.Size.Y*.5+4
                else
                    local relative=actor.Root.Position-mouth.PlanePosition
                    inside=math.abs(relative:Dot(mouth.Lateral))<=mouth.HalfWidth+30
                        and math.abs(relative:Dot(mouth.Forward))<=35
                end
                if inside then
                    local delta=actor.Root.Position-root.Position
                    local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
                    if distance<nearestDistance then nearest,nearestDistance=actor,distance end
                end
            end
        end
        if nearest then
            local predicted=nearest.Root.Position+nearest.Root.AssemblyLinearVelocity*.08
            local direction=flat(predicted-root.Position)
            if direction and os.clock()>=(state.KeeperNextDiveAt or 0)then
                attempt_keeper_dive(direction)
                return true
            end
        end
    end
    if not crossing then return false end
    local remaining=crossing.Time-modules.Clock.GetSmoothedServerTime()
    if remaining<=0 then return true end
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
    local ball=modules.Renderer.GetPosition()
    local direction=flat(delta)or(ball and flat(ball-root.Position))or mouth.Forward
    attempt_keeper_dive(direction)
    return true
end

local function magnet_step()
    if not config.BallMagnet or owns_ball()then return end
    local root=local_root()
    local position=modules.Renderer.GetPosition()
    if not root or not position or(position-root.Position).Magnitude>config.MagnetRange then return end
    local owner=modules.Renderer.GetOwnedUserId()
    if owner then
        for _,actor in ipairs(state.Actors)do if actor.UserId==owner and actor.Friendly then return end end
    end
    local predicted=position
    if not owner and state.BallState and state.Boundary then
        local now=modules.Clock.GetSmoothedServerTime()
        predicted=modules.Physics.GetStateAtTime(state.BallState,now+.08,state.Boundary).Position
    end
    local delta=Vector3.new(predicted.X-root.Position.X,0,predicted.Z-root.Position.Z)
    if delta.Magnitude<1.5 or math.abs(predicted.Y-root.Position.Y)>7 then return end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    local excluded={local_player.Character,state.World}
    for _,actor in ipairs(state.Actors)do excluded[#excluded+1]=actor.Character end
    local ball=workspace:FindFirstChild("Ball")if ball then excluded[#excluded+1]=ball end
    params.FilterDescendantsInstances=excluded params.RespectCanCollide=true
    local obstruction=workspace:Raycast(root.Position,delta,params)
    if obstruction then state.MoveDirection=delta.Unit return end
    if not ready("magnet",config.MagnetCooldown)then return end
    local target=predicted-delta.Unit*(modules.Physics.BallRadius+.35)
    local ground=workspace:Raycast(target+Vector3.new(0,8,0),Vector3.new(0,-24,0),params)
    local humanoid=local_player.Character:FindFirstChildOfClass("Humanoid")
    local height=humanoid.HipHeight+root.Size.Y*.5
    target=Vector3.new(target.X,ground and ground.Position.Y+height or root.Position.Y,target.Z)
    root.CFrame=CFrame.lookAt(target,target+delta.Unit)
    root.AssemblyLinearVelocity=Vector3.zero
    if owner and not modules.Keeper.IsGoalkeeper()and ready("magnet tackle",.8)then
        modules.Tackle.HandleInputBegan(modules.Controls.CreateInput("Tackle"),false)
    end
end

local function automation_step()
    state.MoveDirection = nil
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
    if state.HadBall~=has_ball then
        state.HadBall=has_ball
        state.PossessionSince=has_ball and os.clock()or nil
    end
    if config.AutoSprint and not is_goalkeeper() and not modules.Sprint.IsSprintButtonToggled() then
        modules.Sprint.ToggleSprintButton()
        state.OwnedSprintToggle = true
    end
    if (config.PerfectCharge or config.UnsavableShot or state.AutoShot) and state.ShotInput and modules.ClientShoot.IsCharging() then
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
    if not keeper_step() then magnet_step() end
    if has_ball then
        if config.AutoDribble and not is_goalkeeper()and not modules.Dodge.IsDribbling()
            and not modules.ClientShoot.IsCharging()and not modules.Pass.IsCharging()
            and state.PossessionSince and os.clock()-state.PossessionSince>.35 then
            local enemy=enemy_near(root.Position,math.min(config.DribbleRange,11))
            if enemy then
                local toward=flat(enemy.Root.Position-root.Position)
                if toward and root.CFrame.LookVector:Dot(toward)>.2 and ready("dribble",2.5)then
                    modules.Dodge.HandleInputBegan(modules.Controls.CreateInput("Dribble"),false)
                end
            end
        end
        if config.AutoPass and not state.PassInput and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and not modules.Dodge.IsDribbling() and ready("pass", 1.1) then
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
        if state.FlickPending and os.clock()>state.FlickPending then state.FlickPending=nil end
        if state.FlickPending and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging()
            and modules.Volley.IsAvailable(local_player.Character)then
            state.FlickPending=nil
            state.ShotInput=modules.Controls.CreateInput("Kick")
            state.AutoShot=true
            modules.ClientShoot.HandleInputBegan(state.ShotInput,false)
        end
        if config.AutoVolley and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and ready("volley", 0.18) then
            if modules.Volley.IsAvailable(local_player.Character) then
                state.ShotInput = modules.Controls.CreateInput("Kick")
                state.AutoShot = true
                modules.ClientShoot.HandleInputBegan(state.ShotInput, false)
                if modules.ClientShoot.IsCharging() then  end
            end
        end
        if ((config.AutoTackle and not is_goalkeeper()) or (config.KeeperAutoTackle and is_goalkeeper())) and not modules.ClientShoot.IsCharging() and not modules.Pass.IsCharging() and not modules.Dive.IsDiveConstraintActive(root) and not modules.Tackle.IsSlideTackling() and ready("tackle", 0.25) then
            local owner = modules.Renderer.GetOwnedUserId()
            for _, actor in state.Actors do
                if actor.UserId == owner and not actor.Friendly and (actor.Root.Position - root.Position).Magnitude <= (is_goalkeeper() and config.KeeperTackleRange or config.TackleRange) then
                    modules.Tackle.HandleInputBegan(modules.Controls.CreateInput("Tackle"), false)
                    if modules.Tackle.IsSlideTackling() then  end
                    break
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
    state.MoveDirection, state.DiveDirection, state.TackleDirection = nil, nil, nil
    if state.AutoShot then pcall(modules.ClientShoot.CancelCharge) end
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
    if key=="FlickShot"and not value then state.FlickPending=nil end
    if key=="AutoPass"and not value then state.PassTarget=nil end
    if key=="AutoGoalkeeper"and not value then state.DiveDirection=nil state.MoveDirection=nil end
    if key=="ShotCurve" or key=="FeintShot" then state.ShotSolution=nil end
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
    SolveShot=solve_shot,SelectShot=select_shot,PredictShotCrossing=predict_shot_crossing,
}

local ok, err = xpcall(function()
    build_ui()
    set_config("InfiniteStamina",config.InfiniteStamina)
    install_hooks()
    refresh_actors()
    refresh_items()
    local accumulator = 0
    connect(run_service.Heartbeat, function(dt)
        if not state.Alive then return end
        accumulator += dt
        if accumulator < 0.04 then return end
        accumulator = 0
        if ready("actors", 0.35) then guarded("actors", refresh_actors) end
        if ready("world", 0.5) then guarded("world", refresh_items) end
        if ready("target", 0.08) then
            guarded("targets", function()
                if config.ShotAimbot or config.UnsavableShot or config.ShotPreview or config.FeintShot then
                    local target,goal=select_shot()
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
        state.FlickPending=nil state.PossessionSince=nil
        table.clear(state.Points)
    end)
end,function(message)return tostring(message)end)

if not ok then state.Errors.Startup=err unload()end
