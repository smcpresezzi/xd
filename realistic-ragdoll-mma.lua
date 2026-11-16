local previousConfig=getgenv().AxisMMA and getgenv().AxisMMA.Config
if getgenv().AxisMMA and getgenv().AxisMMA.Unload then getgenv().AxisMMA.Unload() end

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local ROFC=RS:WaitForChild("ROFC")
local Match=require(ROFC.Match)
local Fighter=require(ROFC.Fighter)
local Combat=require(ROFC.Combat)
local Rig=require(ROFC.Rig)
local Styles=require(ROFC.Styles)
local Config=require(ROFC.Config)
local LP=Players.LocalPlayer
local C={
    AutoSlip=false,SlipVisualizer=false,AutoTiming=true,PredictCombos=true,ReplicaChains=false,PunishSlip=false,
    Aimbot=false,AimZone="Head",AimSmooth=1,FPCamera=false,
    AutoJab=false,AutoCross=false,AutoHooks=false,AutoKick=false,AutoKnee=false,AutoBlock=false,AutoCounter=false,
    HitAura=false,AuraRange=5,AuraStamina=18,AuraIdleOnly=true,
    FullAuto=false,NoStun=false,MistakeControl=false,AlwaysMove=false,PunchSpeed=false,PunchMultiplier=1.5,
    Autoplay=false,AutoPunch=false,YieldInput=true,StepBack=false,StepIn=false,Sidestep=false,SlipWalk=false,
    Walkspeed=false,WalkValue=5,Fly=false,FlySpeed=10,JumpPower=false,JumpValue=50,
    CSpeed=false,CSpeedValue=1.5,Gravity=false,GravityValue=196.2,Noclip=false,InfiniteJump=false,
    NoSlipCooldown=false,InfiniteStamina=false,NoSlipCost=false,NoWalkLock=false,InfiniteSlip=false,
    HitboxExpander=false,HitboxSize=1.5,DamageMultiplier=false,DamageValue=2,FastHands=false,
    Godmode=false,AlwaysBlock=false,PaperChin=false,SuperPower=false,IronChin=false,FreePunches=false,SoftHard=false,
    StyleChanger=false,Style="boxer"
}
local CosmeticFields={"hairStyle","hairColor","facialHair","facialColor","skin","eyeColor","gloveColor","shortsColor","shortsStyle","tattoos","song","walkoutTop","topColor","faceTattoo"}
local defaultProfile=Config.defaultProfile()
for _,key in ipairs(CosmeticFields) do C["Cosmetic_"..key]=defaultProfile[key] end
C.Cosmetics=false
C.NameSpoofer=false
C.FirstName="AXIS"
C.LastName="FIGHTER"
C.UnlockAllStyles=false
C.VIPGold=false
C.GuaranteeEvade=true
C.AuraNotBlocking=true
C.AuraHasStamina=true
for _,kind in ipairs({"Jab","Cross","Hook","Kick","Knee"}) do C[kind.."Reaction"]="Off" end
if previousConfig then for key,value in pairs(previousConfig) do if C[key]~=nil then C[key]=value end end end
local S={Alive=true,Connections={},Original={},LastStrike=0,LastSlip=0,LastPunish=0,LastMove=0,LastAura=0,LastSeen=0,ComboIndex=0,LastInput=0,Direction=1,Parts={},Fighters=setmetatable({},{__mode="k"}),LastHealth=100,JumpStart=0,FlyHeight=0,ComboUntil=0}
getgenv().AxisMMA=S
S.Config=C

local function connect(signal,fn)
    local c=signal:Connect(fn)
    S.Connections[#S.Connections+1]=c
    return c
end

local function active()
    local m=S.CachedMatch
    if m and m.state=="fight" then return m end
end

local function applyProfile(profile)
    if type(profile)~="table" then return end
    if C.NameSpoofer then profile.first=C.FirstName profile.last=C.LastName end
    if C.Cosmetics then
        for _,key in ipairs(CosmeticFields) do profile[key]=C["Cosmetic_"..key] end
    end
    if C.VIPGold then profile.vipGloves=1 profile.vipHair=1 profile.vipSkin=1 end
end

local function applyPreviewLook(look)
    if type(look)~="table" or look.name~="Preview" then return look end
    local edited=table.clone(look)
    if C.Cosmetics then
        for _,key in ipairs(CosmeticFields) do edited[key]=C["Cosmetic_"..key] end
    end
    if C.VIPGold then edited.vipGloves=1 edited.vipHair=1 edited.vipSkin=1 end
    if C.NameSpoofer then edited.name=C.LastName end
    return edited
end

S.Original.RigNew=Rig.new
Rig.new=function(look,...)
    if S.Alive then look=applyPreviewLook(look) end
    return S.Original.RigNew(look,...)
end

S.Original.SetStyle=Fighter.setStyle
Fighter.setStyle=function(fighter,style,...)
    if S.Alive and fighter.rig and fighter.rig.look and fighter.rig.look.name=="Preview" and (C.StyleChanger or C.UnlockAllStyles) then
        style=Styles.BY_ID[C.Style] or style
    end
    return S.Original.SetStyle(fighter,style,...)
end

local function findPreviewBuild()
    if not getgc then return end
    for _,fn in pairs(getgc()) do
        if type(fn)=="function" and debug.info(fn,"n")=="buildPreview" then
            local ok,environment=pcall(getfenv,fn)
            if ok and environment.script and environment.script.Name=="ROFCClient" then S.PreviewBuild=fn return end
        end
    end
end
findPreviewBuild()

local function refreshMenuPreview()
    if not S.PreviewBuild then findPreviewBuild() end
    if not S.PreviewBuild then return false end
    local values=debug.getupvalues(S.PreviewBuild)
    if type(values[4])~="table" then return false end
    local ok=pcall(S.PreviewBuild)
    if not ok then return false end
    if C.StyleChanger or C.UnlockAllStyles then
        local preview=debug.getupvalues(S.PreviewBuild)[1]
        local style=Styles.BY_ID[C.Style]
        if preview and preview.rig and preview.rig.model and style then pcall(function()preview:setStyle(style)end) end
    end
    return true
end

local function applyStyle(m)
    if not m or not m.player or not m.player.rig or not m.player.rig.model or not (C.StyleChanger or C.UnlockAllStyles) then return end
    local style=Styles.BY_ID[C.Style]
    if style and m.player.fstyle~=style then m.player:setStyle(style) end
end

local function rebuildAppearance(m)
    if not m or m.state~="fight" or not m.player or not m.player.rig or not m.player.rig.model or m.player.rig.ragdolled or m.player.down or m.gnd or m.drive then return false end
    local old=m.player.rig
    local replacement=Rig.new(Match.lookFromProfile(m.profile,{name="Player",teeColor=Color3.fromRGB(150,20,28)}))
    if m.rayParams then
        local list=m.rayParams.FilterDescendantsInstances
        for index,item in ipairs(list) do if item==old.model then list[index]=replacement.model end end
        m.rayParams.FilterDescendantsInstances=list
    end
    m.player.rig=replacement
    m.player.s=replacement.s
    m.player.d=replacement.dim
    m.player:snapFeet()
    old:destroy()
    return true
end

S.Original.New=Match.new
Match.new=function(options,...)
    if S.Alive and type(options)=="table" then applyProfile(options.profile) end
    local m=S.Original.New(options,...)
    if S.Alive then S.CachedMatch=m end
    return m
end

S.Original.Setup=Match.setup
Match.setup=function(m,...)
    if S.Alive then
        applyProfile(m.profile)
        if C.StyleChanger or C.UnlockAllStyles then m.playerStyle=C.Style end
    end
    local result=S.Original.Setup(m,...)
    if S.Alive then S.CachedMatch=m S.CosmeticDirty=false applyStyle(m) end
    return result
end

local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function distance(a,b) return (flat(a.pos)-flat(b.pos)).Magnitude end
local function valid(m)
    return m and m.player and m.opp and m.state=="fight" and m.player.mode=="fight" and m.opp.mode=="fight" and not m.player.down and not m.opp.down
end
local function target(m)
    local p=m.opp
    local zone=C.AimZone=="Body" and "body" or "head"
    local point=p.rig:point(zone)
    local bone=zone=="body" and p.rig.bones.Abdomen.core or p.rig.bones.Head.core
    return point,bone,zone
end
local function strike(m,kind)
    if not valid(m) or m.player:isAttacking() then return false end
    local previous=m.player.lastStrikeT
    local ok=pcall(function() m:playerStrike(kind) end)
    local fired=ok and m.player.lastStrikeT~=previous
    if fired then S.LastStrike=os.clock() end
    return fired
end
local function incoming(m)
    if not valid(m) then return nil end
    for _,v in pairs(m.opp.strikes) do
        if not v.impacted and not v.cancelled then
            local phase=Fighter.phaseOf(v)
            if phase=="windup" or phase=="extend" then return v,phase end
        end
    end
end
local function category(attack)
    local kind=attack and (attack.kind or attack.type)
    if kind=="jab" then return "Jab" end
    if kind=="cross" then return "Cross" end
    if kind=="lhook" or kind=="rhook" then return "Hook" end
    if kind=="lkick" or kind=="rkick" then return "Kick" end
    if kind=="knee" then return "Knee" end
end
local function slipLead(attack)
    if not attack or not attack.def or not attack.speed or attack.speed<=0 then return nil end
    return attack.def.windup/attack.speed-attack.t
end
local function slip(m)
    if not valid(m) then return false end
    local p=m.player
    if C.NoSlipCooldown or C.InfiniteSlip then p.slipCool=0 end
    if C.InfiniteSlip then p.slipT=-1 end
    local direction=S.Direction
    S.Direction=-direction
    local old=p.stamina
    local ok=p:slip(direction)
    if ok then
        S.LastSlip=os.clock()
        if C.NoSlipCost or C.InfiniteStamina then p.stamina=old end
        if m.pvp then pcall(function()m:netSend({op="slip",dir=direction})end)end
    end
    return ok
end

S.Original.Aim=Match.aim
Match.aim=function(m,...)
    if S.Alive and C.Aimbot and valid(m) then
        local point,bone,zone=target(m)
        if point then return point,bone,zone,point end
    end
    return S.Original.Aim(m,...)
end

S.Original.Resolve=Combat.resolve
Combat.resolve=function(attacker,defender,strikeData,...)
    if S.Alive and defender and defender.isPlayer and (C.Godmode or (C.AutoSlip and C.GuaranteeEvade)) then
        return {landed=false,evaded=C.AutoSlip and C.GuaranteeEvade or false,slipped=C.AutoSlip and C.GuaranteeEvade or false,kind=strikeData.kind,attacker=attacker,defender=defender,move=strikeData.move}
    end
    return S.Original.Resolve(attacker,defender,strikeData,...)
end

S.Original.Slip=Fighter.slip
Fighter.slip=function(p,dir,...)
    if S.Alive and p.isPlayer then
        if C.NoSlipCooldown or C.InfiniteSlip then p.slipCool=0 end
        if C.InfiniteSlip then p.slipT=-1 end
        local stamina=p.stamina
        local result=S.Original.Slip(p,dir,...)
        if result and (C.NoSlipCost or C.InfiniteStamina) then p.stamina=stamina end
        return result
    end
    return S.Original.Slip(p,dir,...)
end

S.Original.StrikeDef=Fighter.strikeDef
Fighter.strikeDef=function(p,kind,...)
    local def=S.Original.StrikeDef(p,kind,...)
    if S.Alive and p.isPlayer and def then
        if C.PunchSpeed or C.FastHands then
            local mul=C.FastHands and 2 or C.PunchMultiplier
            local copy=table.clone(def)
            for _,key in ipairs({"windup","extend","hold","retract","recover"}) do if type(copy[key])=="number" then copy[key]=copy[key]/mul end end
            def=copy
        end
        if C.FreePunches then local copy=table.clone(def) copy.stamina=0 def=copy end
    end
    return def
end

S.Original.UpdateMovement=Fighter.updateMovement
Fighter.updateMovement=function(p,dt,...)
    local before=p.pos
    local result=S.Original.UpdateMovement(p,dt,...)
    if S.Alive and p.isPlayer and p.mode=="fight" then
        local factor=1
        if C.Walkspeed then factor=factor*C.WalkValue/4.5 end
        if C.CSpeed then factor=factor*C.CSpeedValue end
        if C.NoWalkLock and p:isAttacking() then factor=factor*(p.strikes.leg and 4 or 1.35) end
        if factor~=1 then
            local delta=flat(p.pos-before)
            p.pos=Fighter.clampOctagon(before+delta*factor)
        end
        if C.Fly then
            local vertical=UIS:IsKeyDown(Enum.KeyCode.Space) and 1 or (UIS:IsKeyDown(Enum.KeyCode.LeftControl) and -1 or 0)
            S.FlyHeight=math.clamp(S.FlyHeight+vertical*C.FlySpeed*dt,-1,20)
            p.pos=Vector3.new(p.pos.X,4+S.FlyHeight,p.pos.Z)
        elseif S.JumpStart>0 then
            local age=os.clock()-S.JumpStart
            local gravity=C.Gravity and C.GravityValue or 196.2
            local velocity=C.JumpPower and C.JumpValue or 45
            local height=math.max(0,velocity*age-0.5*gravity*age*age)
            if height>0 then p.pos=Vector3.new(p.pos.X,4+height,p.pos.Z) else S.JumpStart=0 end
        end
    end
    return result
end

S.Original.Step=Match.step
local function override(fighter,base,key,enabled,value)
    local marker=key.."Active"
    if enabled then
        if not base[marker] then base[key]=fighter[key] end
        fighter[key]=value
        base[marker]=true
    elseif base[marker] then
        fighter[key]=base[key]
        base[marker]=false
    else
        base[key]=fighter[key]
    end
end
Match.step=function(m,dt,...)
    S.CachedMatch=m
    local result=S.Original.Step(m,dt,...)
    if not S.Alive or S.MenuOpen or S.Window and S.Window.IsOpen or not S.NeedsStep or not valid(m) then return result end
    local p,o=m.player,m.opp
    local now=os.clock()
    if C.InfiniteStamina then p.stamina=p.maxStamina or 100 end
    if C.NoStun then p.stun=0 p.rockedT=0 p.bodyHurtT=0 end
    if C.Godmode then for k in pairs(p.hp) do p.hp[k]=100 end p.down=false end
    if C.NoSlipCooldown or C.InfiniteSlip then p.slipCool=0 end
    if C.AlwaysBlock then p.block=true end
    if not S.Fighters[p] then S.Fighters[p]={chin=p.chin,power=p.power,walkSpeed=p.walkSpeed,speedMul=p.speedMul,hard=p.hard} end
    if not S.Fighters[o] then S.Fighters[o]={chin=o.chin,power=o.power,walkSpeed=o.walkSpeed,speedMul=o.speedMul,hard=o.hard} end
    local playerBase,opponentBase=S.Fighters[p],S.Fighters[o]
    override(p,playerBase,"chin",C.IronChin,10)
    override(o,opponentBase,"chin",C.PaperChin,0.1)
    override(p,playerBase,"power",C.DamageMultiplier or C.SuperPower,C.DamageMultiplier and C.DamageValue or 5)
    override(p,playerBase,"walkSpeed",C.Walkspeed,C.WalkValue)
    if C.NoWalkLock then p.walkLock=0 p.moveLock=0 end
    override(p,playerBase,"speedMul",C.CSpeed,C.CSpeedValue)
    override(p,playerBase,"hard",C.SoftHard,false)
    if C.MistakeControl then p.disloc.L=false p.disloc.R=false p.lastStrikeT=math.min(p.lastStrikeT or 0,p.time-0.1) end
    applyStyle(m)
    if C.Cosmetics or C.NameSpoofer or C.VIPGold then
        applyProfile(m.profile)
        applyProfile(p.profile)
        if C.NameSpoofer then p.name=C.LastName end
    end
    local attack,phase=incoming(m)
    if attack and attack~=S.LastAttack then
        if C.PredictCombos and now-S.LastSeen<0.8 then S.ComboUntil=now+0.7 end
        S.LastAttack=attack
        S.LastSeen=now
    end
    local reaction=attack and C[(category(attack) or "").."Reaction"] or "Off"
    if reaction=="Block" then p.block=true end
    if reaction=="Slip" and now-S.LastSlip>0.28 then slip(m) end
    if reaction=="Counter" and now-S.LastStrike>0.35 then strike(m,"cross") end
    if C.AutoSlip and attack and now-S.LastSlip>0.28 then
        local lead=slipLead(attack)
        local threshold=C.PredictCombos and now<S.ComboUntil and 0.065 or 0.04
        local should=C.AutoTiming and lead and lead<=threshold and lead>=-0.12 or not C.AutoTiming and (phase=="windup" or phase=="extend")
        if C.ReplicaChains and now<S.ComboUntil then p.slipCool=0 end
        if should and slip(m) and C.PunishSlip then S.LastPunish=now+0.18 end
    end
    if C.PunishSlip and S.LastPunish>0 and now>=S.LastPunish then S.LastPunish=0 strike(m,"cross") end
    local d=distance(p,o)
    if C.AutoBlock and attack then p.block=true end
    if attack and now-S.LastSlip>0.2 and now-S.LastStrike>0.35 then
        local kind=attack.kind or attack.type or "jab"
        local kick=kind=="lkick" or kind=="rkick"
        local knee=kind=="knee"
        if C.AutoCounter or (kick and C.AutoKick) or (knee and C.AutoKnee) or (not kick and not knee and (C.AutoJab or C.AutoCross or C.AutoHooks)) then
            local reply=C.AutoHooks and "lhook" or (C.AutoCross and "cross" or (C.AutoKnee and knee and "knee" or (C.AutoKick and kick and "rkick" or "jab")))
            strike(m,reply)
        end
    end
    if C.HitAura and d<=C.AuraRange and now-S.LastAura>0.28 then
        if (not C.AuraIdleOnly or not p:isAttacking()) and (not C.AuraHasStamina or p.stamina>=C.AuraStamina) and (not C.AuraNotBlocking or not p.block) then
            S.LastAura=now
            strike(m,(S.ComboIndex%2==0) and "jab" or "cross")
            S.ComboIndex=S.ComboIndex+1
        end
    end
    if C.Autoplay and now-S.LastStrike>0.45 and d<6 then
        if not C.YieldInput or now-S.LastInput>0.7 then
            local sequence={}
            if C.AutoPunch then for _,kind in ipairs({"jab","cross","lhook","rhook"}) do sequence[#sequence+1]=kind end end
            if C.AutoKick then for _,kind in ipairs({"lkick","rkick"}) do sequence[#sequence+1]=kind end end
            if C.AutoKnee and d<3 then sequence[#sequence+1]="knee" end
            if #sequence>0 and strike(m,sequence[S.ComboIndex%#sequence+1]) then S.ComboIndex=S.ComboIndex+1 end
        end
    end
    if C.FullAuto and now-S.LastStrike>0.23 and d<5 then strike(m,S.ComboIndex%2==0 and "jab" or "cross") S.ComboIndex=S.ComboIndex+1 end
    if C.FPCamera and not m.fp then pcall(function()m:enterFP()end) end
    if C.AlwaysMove or C.Autoplay then
        if now-S.LastMove>0.4 then S.LastMove=now S.Direction=-S.Direction end
        local delta=flat(o.pos-p.pos)
        if delta.Magnitude>0.01 then
            local forward=delta.Unit
            local side=Vector3.new(-forward.Z,0,forward.X)
            local movement=Vector3.zero
            if C.StepIn and d>3 then movement=movement+forward end
            if C.StepBack and d<2.5 then movement=movement-forward end
            if C.Sidestep or C.AlwaysMove then movement=movement+side*S.Direction end
            if C.SlipWalk and p:isSlipping() then movement=movement+side*S.Direction end
            if movement.Magnitude>0 and (not C.YieldInput or now-S.LastInput>0.7) then p.moveInput=movement.Unit end
        end
    end
    return result
end

connect(UIS.InputBegan,function(input,processed)
    if not processed then S.LastInput=os.clock() end
    if (C.InfiniteJump or C.JumpPower) and not processed and input.KeyCode==Enum.KeyCode.Space then
        local m=active()
        if valid(m) and (C.InfiniteJump or S.JumpStart==0) then S.JumpStart=os.clock() end
    end
end)

connect(RunService.Heartbeat,function(dt)
    if not S.Alive then return end
    if S.CosmeticDirty and os.clock()-(S.LastCosmeticEdit or 0)>0.35 then
        local current=active()
        if current and (C.Cosmetics or C.NameSpoofer or C.VIPGold) then
            applyProfile(current.profile)
            local ok,applied=pcall(rebuildAppearance,current)
            if ok and applied then S.CosmeticDirty=false end
        elseif os.clock()-(S.LastPreviewAttempt or 0)>0.5 then
            S.LastPreviewAttempt=os.clock()
            if refreshMenuPreview() then S.CosmeticDirty=false end
        end
    end
    if not C.HitboxExpander and not C.Noclip and next(S.Parts)==nil then return end
    local m=active()
    local desired={}
    local function part(part)
        if part and part:IsA("BasePart") then
            if not S.Parts[part] then S.Parts[part]={Size=part.Size,CanCollide=part.CanCollide} end
            return S.Parts[part]
        end
    end
    if valid(m) then
        local head=m.opp.rig.bones.Head.core
        if C.HitboxExpander then
            local old=part(head)
            if old then head.Size=old.Size*C.HitboxSize desired[head]=true end
        end
        if C.Noclip then
            for _,bone in pairs(m.player.rig.bones) do
                local core=bone.core
                local old=part(core)
                if old then core.CanCollide=false desired[core]=true end
            end
        end
    end
    for p,old in pairs(S.Parts) do
        if not desired[p] then
            if p.Parent then p.Size=old.Size p.CanCollide=old.CanCollide end
            S.Parts[p]=nil
        end
    end
end)

local visual=Instance.new("BillboardGui")
visual.Name="AxisSlipVisualizer"
visual.Size=UDim2.fromOffset(120,25)
visual.StudsOffset=Vector3.new(0,2.5,0)
visual.AlwaysOnTop=true
visual.Parent=LP.PlayerGui
local visualText=Instance.new("TextLabel")
visualText.BackgroundTransparency=1
visualText.Size=UDim2.fromScale(1,1)
visualText.TextColor3=Color3.fromRGB(255,220,70)
visualText.TextStrokeTransparency=0
visualText.Font=Enum.Font.GothamBold
visualText.TextSize=14
visualText.Parent=visual
connect(RunService.RenderStepped,function()
    if not S.Alive or not C.SlipVisualizer and not (C.Aimbot and C.FPCamera) then visual.Enabled=false return end
    local m=active()
    if C.SlipVisualizer then
        local attack,phase=m and incoming(m)
        visual.Enabled=attack~=nil
        if visual.Enabled then
            visual.Adornee=m.opp.rig.bones.Head.core
            visualText.Text=phase=="extend" and "SLIP NOW" or "INCOMING"
        end
    else visual.Enabled=false end
    if S.Alive and not S.MenuOpen and C.Aimbot and C.FPCamera and valid(m) then
        local camera=workspace.CurrentCamera
        local point=target(m)
        local nextCF=CFrame.lookAt(camera.CFrame.Position,point)
        camera.CFrame=camera.CFrame:Lerp(nextCF,math.clamp(1/C.AimSmooth,0.05,1))
    end
end)

local library=assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua")))()
library.Holder.Instance.Parent=LP.PlayerGui
library.UnusedHolder.Instance.Parent=LP.PlayerGui
local logo=library.Folders.Assets.."/axis-logo.png"
if not isfile(logo) then writefile(logo,game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/assets/axis-logo.png")) end
library.MenuKeybind=tostring(Enum.KeyCode.RightShift)
local window=library:Window({Name="",SubName="",Logo=getcustomasset(logo),Wordmark=true})
S.Window=window
local mouseStep="AxisMMA_Mouse_"..tostring(math.random(100000,999999))
local mouseWasOpen=false
local function menuOpen()
    return S.Alive and window.IsOpen and window.Items.MainFrame.Instance.Visible
end
RunService:BindToRenderStep(mouseStep,Enum.RenderPriority.Last.Value+2,function()
    local open=menuOpen()
    S.MenuOpen=open
    if open then
        if not mouseWasOpen then
            S.PreviousMouseBehavior=UIS.MouseBehavior
            S.PreviousMouseIcon=UIS.MouseIconEnabled
        end
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        UIS.MouseIconEnabled=true
    elseif mouseWasOpen then
        local m=active()
        UIS.MouseBehavior=m and m.fp and Enum.MouseBehavior.LockCenter or (S.PreviousMouseBehavior or Enum.MouseBehavior.Default)
        UIS.MouseIconEnabled=not (m and m.fp) and (S.PreviousMouseIcon~=false)
    end
    mouseWasOpen=open
end)
S.Original.UpdateFP=Match.updateFP
Match.updateFP=function(m,...)
    if menuOpen() then return end
    return S.Original.UpdateFP(m,...)
end
local controls={}
local stepKeys={AutoSlip=true,ReplicaChains=true,PunishSlip=true,AutoJab=true,AutoCross=true,AutoHooks=true,AutoKick=true,AutoKnee=true,AutoBlock=true,AutoCounter=true,HitAura=true,FullAuto=true,NoStun=true,MistakeControl=true,AlwaysMove=true,Autoplay=true,Walkspeed=true,Fly=true,JumpPower=true,CSpeed=true,Gravity=true,InfiniteJump=true,NoSlipCooldown=true,InfiniteStamina=true,NoSlipCost=true,NoWalkLock=true,InfiniteSlip=true,DamageMultiplier=true,Godmode=true,AlwaysBlock=true,PaperChin=true,SuperPower=true,IronChin=true,SoftHard=true,StyleChanger=true,UnlockAllStyles=true,Cosmetics=true,NameSpoofer=true,VIPGold=true,FPCamera=true}
local function refreshStep()
    S.NeedsStep=false
    for key in pairs(stepKeys) do if C[key] then S.NeedsStep=true return end end
    for _,kind in ipairs({"Jab","Cross","Hook","Kick","Knee"}) do if C[kind.."Reaction"]~="Off" then S.NeedsStep=true return end end
    for fighter,base in pairs(S.Fighters) do
        fighter.chin=base.chin
        fighter.power=base.power
        fighter.walkSpeed=base.walkSpeed
        fighter.speedMul=base.speedMul
        fighter.hard=base.hard
    end
end
refreshStep()
local function changed(key)
    if key=="Cosmetics" or key=="NameSpoofer" or key=="VIPGold" or key:sub(1,9)=="Cosmetic_" or key=="FirstName" or key=="LastName" then
        S.CosmeticDirty=true
        S.LastCosmeticEdit=os.clock()
    end
    if key=="Style" or key=="StyleChanger" or key=="UnlockAllStyles" then
        applyStyle(S.CachedMatch)
        S.CosmeticDirty=true
        S.LastCosmeticEdit=os.clock()
    end
end
local function toggle(section,key,label)
    controls[key]=section:Toggle({Name=label,Flag="MMA_"..key,Default=C[key],Callback=function(v)C[key]=v refreshStep() changed(key) end})
end
local function slider(section,key,label,min,max,step)
    section:Slider({Name=label,Flag="MMA_"..key,Default=C[key],Min=min,Max=max,Decimals=step or 1,Callback=function(v)C[key]=v changed(key) end})
end
local function dropdown(section,key,label,items)
    section:Dropdown({Name=label,Flag="MMA_"..key,Default=C[key],Items=items,Callback=function(v)C[key]=v refreshStep() changed(key) end})
end
local combat=window:Page({Name="Combat",Icon="134242818164054"})
local aim=combat:Section({Name="Aim",Side=1})
toggle(aim,"Aimbot","Aimbot")
dropdown(aim,"AimZone","Hitbox",{"Head","Body"})
slider(aim,"AimSmooth","Smoothness",1,20,.1)
toggle(aim,"FPCamera","FP camera")
local slips=combat:Section({Name="Auto slip",Side=2})
toggle(slips,"AutoSlip","Auto slip")
toggle(slips,"GuaranteeEvade","Guaranteed evade (local)")
toggle(slips,"SlipVisualizer","Slip visualizer")
toggle(slips,"AutoTiming","Auto timing")
toggle(slips,"PredictCombos","Predict combo strings")
toggle(slips,"ReplicaChains","Replica chain slips")
toggle(slips,"PunishSlip","Punish after slip")
local reactions=combat:Section({Name="Reactions",Side=1})
toggle(reactions,"AutoJab","Jab counter")
toggle(reactions,"AutoCross","Cross counter")
toggle(reactions,"AutoHooks","Hook counter")
toggle(reactions,"AutoKick","Kick counter")
toggle(reactions,"AutoKnee","Knee counter")
toggle(reactions,"AutoBlock","Auto block")
toggle(reactions,"AutoCounter","Auto counter")
for _,kind in ipairs({"Jab","Cross","Hook","Kick","Knee"}) do dropdown(reactions,kind.."Reaction",kind.." response",{"Off","Block","Slip","Counter"}) end
local aura=combat:Section({Name="Hit aura",Side=2})
toggle(aura,"HitAura","Hit aura")
slider(aura,"AuraRange","Range",1,8,.1)
toggle(aura,"AuraNotBlocking","Only when not blocking")
toggle(aura,"AuraHasStamina","Require stamina")
slider(aura,"AuraStamina","Minimum stamina",0,100,1)
toggle(aura,"AuraIdleOnly","Only when idle")
local offense=combat:Section({Name="Offense",Side=1})
toggle(offense,"FullAuto","Full auto")
toggle(offense,"NoStun","No stun")
toggle(offense,"MistakeControl","Mistake control")
toggle(offense,"AlwaysMove","Always move")
toggle(offense,"PunchSpeed","Punch speed")
slider(offense,"PunchMultiplier","Punch multiplier",1,4,.1)
local autoplay=combat:Section({Name="Autoplay",Side=2})
toggle(autoplay,"Autoplay","Enabled")
toggle(autoplay,"AutoPunch","Auto punch")
toggle(autoplay,"YieldInput","Yield to input")
toggle(autoplay,"StepBack","Step back")
toggle(autoplay,"StepIn","Step in")
toggle(autoplay,"Sidestep","Sidestep")
toggle(autoplay,"SlipWalk","Walk with slip")
local utility=window:Page({Name="Utility",Icon="112148279212860"})
local movement=utility:Section({Name="Movement",Side=1})
toggle(movement,"Walkspeed","Walkspeed")
slider(movement,"WalkValue","Speed",1,20,.1)
toggle(movement,"Fly","Fly")
slider(movement,"FlySpeed","Fly speed",1,30,.1)
toggle(movement,"JumpPower","Jump power")
slider(movement,"JumpValue","Power",10,120,1)
toggle(movement,"CSpeed","CSpeed")
slider(movement,"CSpeedValue","Multiplier",1,4,.1)
toggle(movement,"Gravity","Gravity")
slider(movement,"GravityValue","Gravity value",0,196.2,.1)
toggle(movement,"Noclip","Noclip")
toggle(movement,"InfiniteJump","Infinite jump")
local bypass=utility:Section({Name="Combat limits",Side=2})
toggle(bypass,"NoSlipCooldown","No slip cooldown")
toggle(bypass,"InfiniteStamina","Infinite stamina")
toggle(bypass,"NoSlipCost","No slip stamina cost")
toggle(bypass,"NoWalkLock","No walk lock")
toggle(bypass,"InfiniteSlip","Infinite slip")
local stats=utility:Section({Name="Stats",Side=1})
toggle(stats,"HitboxExpander","Hitbox expander")
slider(stats,"HitboxSize","Hitbox size",1,4,.1)
toggle(stats,"DamageMultiplier","Damage multiplier")
slider(stats,"DamageValue","Damage",1,5,.1)
toggle(stats,"FastHands","Fast hands")
toggle(stats,"Godmode","Godmode")
toggle(stats,"AlwaysBlock","Always block")
toggle(stats,"PaperChin","Paper chin")
toggle(stats,"SuperPower","Super power")
toggle(stats,"IronChin","Iron chin")
toggle(stats,"FreePunches","Free punches")
toggle(stats,"SoftHard","Soft hard mode")
local styles=utility:Section({Name="Styles",Side=2})
toggle(styles,"StyleChanger","Style changer")
toggle(styles,"UnlockAllStyles","All styles")
local styleNames={}
for id in pairs(Styles.BY_ID) do styleNames[#styleNames+1]=id end
table.sort(styleNames)
dropdown(styles,"Style","Style",styleNames)
local cosmetics=window:Page({Name="Cosmetics",Icon="100033680381365"})
local appearance=cosmetics:Section({Name="Appearance",Side=1})
toggle(appearance,"Cosmetics","Unlock all cosmetics")
for _,item in ipairs({{"hairStyle","Hair",1,#Config.HairStyles},{"hairColor","Hair color",1,#Config.HairColors},{"facialHair","Facial hair",1,#Config.FacialHair},{"skin","Skin tone",1,#Config.SkinTones},{"eyeColor","Eyes",1,#Config.EyeColors},{"gloveColor","Gloves",1,#Config.GearColors},{"shortsColor","Shorts",1,#Config.GearColors},{"shortsStyle","Shorts style",1,#Config.ShortsStyles},{"tattoos","Tattoos",0,#Config.Tattoos},{"song","Walkout",1,#Config.WalkoutSongs}}) do
    slider(appearance,"Cosmetic_"..item[1],item[2],item[3],item[4],1)
end
toggle(appearance,"VIPGold","VIP gold")
local identity=cosmetics:Section({Name="Identity",Side=2})
toggle(identity,"NameSpoofer","Name spoofer")
identity:Textbox({Name="First name",Flag="MMA_FirstName",Default=C.FirstName,Finished=true,Callback=function(v)C.FirstName=v changed("FirstName") end})
identity:Textbox({Name="Last name",Flag="MMA_LastName",Default=C.LastName,Finished=true,Callback=function(v)C.LastName=v changed("LastName") end})
library:CreateSettingsPage(window)
local settings=window.Pages[#window.Pages]:Section({Name="Session",Side=2})
settings:Button({Name="Disable all",Callback=function()for k,v in pairs(controls) do if type(C[k])=="boolean" then v:Set(false) end end end})
settings:Button({Name="Unload",Callback=function()S.Unload()end})

function S.Unload()
    if not S.Alive then return end
    S.Alive=false
    for _,c in ipairs(S.Connections) do c:Disconnect() end
    Match.aim=S.Original.Aim
    Match.new=S.Original.New
    Match.setup=S.Original.Setup
    Match.step=S.Original.Step
    Match.updateFP=S.Original.UpdateFP
    Fighter.slip=S.Original.Slip
    Fighter.strikeDef=S.Original.StrikeDef
    Fighter.updateMovement=S.Original.UpdateMovement
    Fighter.setStyle=S.Original.SetStyle
    Rig.new=S.Original.RigNew
    Combat.resolve=S.Original.Resolve
    for fighter,base in pairs(S.Fighters) do
        fighter.chin=base.chin
        fighter.power=base.power
        fighter.walkSpeed=base.walkSpeed
        fighter.speedMul=base.speedMul
        fighter.hard=base.hard
    end
    for p,old in pairs(S.Parts) do if p.Parent then p.Size=old.Size p.CanCollide=old.CanCollide end end
    visual:Destroy()
    RunService:UnbindFromRenderStep(mouseStep)
    if mouseWasOpen then
        local m=active()
        UIS.MouseBehavior=m and m.fp and Enum.MouseBehavior.LockCenter or (S.PreviousMouseBehavior or Enum.MouseBehavior.Default)
        UIS.MouseIconEnabled=not (m and m.fp) and (S.PreviousMouseIcon~=false)
    end
    library:Unload()
    if getgenv().AxisMMA==S then getgenv().AxisMMA=nil end
end
