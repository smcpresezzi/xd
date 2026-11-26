local ok = pcall(function()
if setthreadidentity then setthreadidentity(8) end
if game.GameId ~= 10770730129 then return end
local env = getgenv()
if env.AxisSoccer then
    local previous=env.AxisSoccer
    if previous.Unload then previous.Unload() else
        previous.Loaded=false
        for _,entry in ipairs(previous.Hooks or {})do if restorefunction then pcall(restorefunction,entry.Function)end end
        if previous.Library then pcall(function()previous.Library:Unload()end)end
    end
end
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CS = game:GetService("CollectionService")
local HS = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local Shared = game.ReplicatedStorage.Shared
local Game = Shared.Game
local Client = LP.PlayerScripts.Client.Game
local Kick = require(Game.Kick)
local Dribble = require(Game.Dribble)
local Tuning = require(Game.MannequinAnimation.Tuning)
local BodyController = require(Game.MannequinAnimation.Body)
local KeeperHands = require(Game.KeeperHands)
local KeeperDives = require(Game.KeeperDives)
local Ball = require(Client.BallView)
local Mannequin = require(Client.MannequinClient)
local DribbleClient = require(Client.DribbleClient)
local Locker = require(Game.Locker)
local Emotes = require(Game.Emotes)
local Replay = require(Client.InstantReplay)
local Net = require(Shared.Net)
local C = {}
local S = {Loaded=true, Config=C, Connections={}, Hooks={}, Errors={}}
env.AxisSoccer = S
local patches, instances, originals, attributes = {}, {}, {}, {}
local movementWish, movementWishAt,movementSource=nil,0,nil
local function safe(fn, ...)
    local args=table.pack(...)
    if setthreadidentity then setthreadidentity(8)end
    local result = table.pack(pcall(function()return fn(table.unpack(args,1,args.n))end))
    if setthreadidentity then setthreadidentity(8)end
    if not result[1] then S.Errors.Last=tostring(result[2]) return end
    return table.unpack(result,2,result.n)
end
local function connect(signal, fn)
    local connection=signal:Connect(fn)
    table.insert(S.Connections,connection)
    return connection
end
local function patch(object,key,value,enabled)
    if not object then return end
    local record=patches[object]
    if not record then record={} patches[object]=record end
    if record[key]==nil then record[key]={Value=object[key]} end
    local wanted=record[key].Value
    if enabled then wanted=value end
    if object[key]~=wanted then safe(function() object[key]=wanted end) end
end
local function property(object,key,value,enabled)
    if not object then return end
    local record=originals[object]
    if not record then record={} originals[object]=record end
    if record[key]==nil then record[key]={Value=object[key]} end
    local wanted=record[key].Value
    if enabled then wanted=value end
    if object[key]~=wanted then safe(function()object[key]=wanted end)end
end
local function attribute(object,key,value,enabled)
    if not object then return end
    local record=attributes[object]
    if not record then record={} attributes[object]=record end
    if not record[key] then record[key]={Value=object:GetAttribute(key)}end
    local wanted=record[key].Value
    if enabled then wanted=value end
    if object:GetAttribute(key)~=wanted then object:SetAttribute(key,wanted)end
end
local function root()
    local model=LP.Character
    return model and model:FindFirstChild("Root"),model
end
local function emit(signal)
    if firesignal then firesignal(signal) return true end
    if getconnections then for _,connection in ipairs(getconnections(signal))do if connection.Function then safe(connection.Function)end end return true end
    return false
end
local function action(context,name,release)
    local ctx=LP.PlayerScripts:FindFirstChild(context)
    local input=ctx and ctx:FindFirstChild(name)
    if input and input:IsA("InputAction")then return emit(release and input.Released or input.Pressed)end
    return false
end
local Library=assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua")))()
S.Library=Library
Library.Holder.Instance.Parent=LP.PlayerGui
Library.UnusedHolder.Instance.Parent=LP.PlayerGui
local logoPath=Library.Folders.Assets.."/axis-logo.png"
if not isfile(logoPath)then writefile(logoPath,game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/assets/axis-logo.png"))end
Library.MenuKeybind=tostring(Enum.KeyCode.RightShift)
local Window=Library:Window({Name="",SubName="",Logo=getcustomasset(logoPath),Wordmark=true})
S.Window=Window
local function section(page,title,side)
    if setthreadidentity then setthreadidentity(8)end
return page:Section({Name=title,Side=side or 1})end
local function toggle(group,id,text,callback,bound,default)
    if setthreadidentity then setthreadidentity(8)end

    C[id]=default==true
    local t=group:Toggle({Name=text,Flag="Soccer_"..id,Default=C[id],Callback=function(v) C[id]=v if callback then safe(callback,v)end end})
    if bound then t:GetBind({Flag="Soccer_"..id.."Key",Default=Enum.KeyCode.Backspace,Mode="Toggle",Callback=function(v)t:Set(v)end})end
    return t
end
local function slider(group,id,text,value,min,max,step)
    if setthreadidentity then setthreadidentity(8)end

    C[id]=value
    return group:Slider({Name=text,Flag="Soccer_"..id,Default=value,Min=min,Max=max,Decimals=step or 1,Callback=function(v)C[id]=v end})
end
local function dropdown(group,id,text,items,value,callback)
    if setthreadidentity then setthreadidentity(8)end

    C[id]=value
    return group:Dropdown({Name=text,Flag="Soccer_"..id,Items=items,Default=value,Callback=function(v)C[id]=v if callback then safe(callback,v)end end})
end
local function textbox(group,id,text,value)
    if setthreadidentity then setthreadidentity(8)end

    C[id]=value
    return group:Textbox({Name=text,Flag="Soccer_"..id,Default=value,Placeholder=text,Finished=true,Callback=function(v)C[id]=v end})
end
local ballPage=Window:Page({Name="Ball",Icon="7733774602"})
local shots=section(ballPage,"Shooting")
toggle(shots,"AutoScore","Auto score",nil,true)
slider(shots,"ShootRange","Shoot range",95,30,220,5)
toggle(shots,"NoMiss","No miss")
toggle(shots,"PerfectShot","Perfect shots")
toggle(shots,"VaryShots","Vary shots",nil,false,true)
slider(shots,"ShotPower","Shot power",1,0.5,1.4,0.05)
slider(shots,"ShotGap","Shot interval",1.1,0.5,3,0.1)
dropdown(shots,"AimSide","Aim",{"Away from keeper","Left","Right","Center"},"Away from keeper")
slider(shots,"AimHeight","Height",0.55,0.1,0.9,0.05)
slider(shots,"AimWidth","Width",0.8,0.1,0.95,0.05)
slider(shots,"AimAngle","Aim angle",0,-20,20,1)
toggle(shots,"CustomCurve","Custom curve")
toggle(shots,"AutoCurve","Curve auto shots",nil,false,true)
dropdown(shots,"CurveSide","Curve",{"Toward corner","Left","Right"},"Toward corner")
slider(shots,"CurveAmount","Curve strength",20,0,60,1)
local control=section(ballPage,"Possession",2)
toggle(control,"StickToBall","Stick to ball",nil,true)
toggle(control,"BallReach","Ball reach")
slider(control,"Reach","Reach",1.5,1,3,0.1)
toggle(control,"BallMagnet","Ball magnet",nil,true)
slider(control,"MagnetRange","Magnet range",8,3,20,1)
slider(control,"MagnetCooldown","Magnet cooldown",0.8,0.3,3,0.1)
slider(control,"FollowRange","Follow range",35,10,100,1)
toggle(control,"NoDribbleCooldown","No dribble cooldown")
toggle(control,"NoDribbleSlowdown","No dribble slowdown")
control:Button({Name="Teleport to ball",Callback=function()
    local r=root() local position=Ball.getPosition()
    if r and position then r.CFrame=CFrame.new(position+Vector3.new(0,5,0)) end
end})
local keepPage=Window:Page({Name="Keeper",Icon="7743876054"})
local saves=section(keepPage,"Saves")
toggle(saves,"AutoSave","Auto save",nil,true)
toggle(saves,"KeeperPosition","Auto position",nil,true,false)
slider(saves,"PositionRange","Position range",105,40,160,5)
dropdown(saves,"KeeperMode","Mode",{"Legit","Blatant"},"Legit")
dropdown(saves,"KeeperAssist","Blatant assist",{"Boost","Teleport"},"Boost")
slider(saves,"KeeperBoost","Boost strength",2,1,6,0.1)
slider(saves,"Reaction","Reaction",0.03,0,0.3,0.01)
slider(saves,"MinBallSpeed","Min ball speed",12,1,100,1)
slider(saves,"KeeperTrackRange","Prediction range",180,40,300,5)
slider(saves,"KeeperHorizon","Prediction time",1.6,0.5,2.5,0.05)
toggle(saves,"LowSmother","Low dive / smother")
dropdown(saves,"DiveZone","Dive zones",{"All","Left","Right","Center"},"All")
local catches=section(keepPage,"Catching",2)
toggle(catches,"AlwaysCatch","Always catch")
slider(catches,"CatchReach","Catch reach",1,1,3,0.1)
local movePage=Window:Page({Name="Movement",Icon="7734051052"})
local movement=section(movePage,"Movement")
toggle(movement,"SpeedBoost","Speed boost",nil,true)
slider(movement,"SpeedMultiplier","Speed multiplier",1.2,1,2,0.05)
toggle(movement,"NoSlideCooldown","No slide cooldown")
slider(movement,"SlideBoost","Slide boost",1,1,2,0.05)
slider(movement,"Acceleration","Acceleration",1,1,3,0.1)
slider(movement,"TurnSpeed","Turn speed",1,1,3,0.1)
slider(movement,"DiveBoost","Dive boost",1,1,2,0.05)
local recovery=section(movePage,"Recovery",2)
toggle(recovery,"AntiRagdoll","Anti ragdoll")
toggle(recovery,"InstantGetUp","Instant get up")
toggle(recovery,"FastGetUp","Fast get up")
toggle(recovery,"WalkThroughNets","Walk through nets")
local Flight=require(Game.Kick.Flight)
local shotScopes=setmetatable({},{__mode="k"})
local shotCycle=0
local shotHistory={}
local pendingShot
local observedRelease
local goalCache,goalCacheAt={},0
local keeperCache,keeperCacheAt={},0
local function shotFlat(v)
    local p=Vector3.new(v.X,0,v.Z)
    return p.Magnitude>.001 and p.Unit or nil
end
local function refreshShotGoals()
    local now=os.clock()
    if now-goalCacheAt<.5 then return goalCache end
    goalCacheAt=now
    table.clear(goalCache)
    for _,part in ipairs(CS:GetTagged("SoccerGoalFrame"))do
        if part:IsA("BasePart")and part:IsDescendantOf(workspace)then goalCache[#goalCache+1]=part end
    end
    return goalCache
end
local function attackGoal(model)
    local team=model and model:GetAttribute("Team")
    if team~="Blue"and team~="Red"then return end
    local blueSide=workspace:GetAttribute("BlueSide")==1 and 1 or -1
    local attackSide=team=="Blue"and -blueSide or blueSide
    local selected
    for _,frame in ipairs(refreshShotGoals())do
        if frame.Position.X*attackSide>0 then selected=frame break end
    end
    return selected
end
local function shotMouth(goal)
    local goals=refreshShotGoals()
    local centre,count=Vector3.zero,0
    for _,frame in ipairs(goals)do centre+=frame.Position count+=1 end
    centre=count>1 and centre/count or Vector3.zero
    local xThin=goal.Size.X<goal.Size.Z
    local normal=shotFlat(xThin and goal.CFrame.RightVector or goal.CFrame.LookVector)
    local width=(xThin and goal.Size.Z or goal.Size.X)*.5
    local depth=(xThin and goal.Size.X or goal.Size.Z)*.5
    if not normal then return end
    if normal:Dot(centre-goal.Position)<0 then normal=-normal end
    local right=Vector3.yAxis:Cross(normal)
    local margin=Flight.RADIUS+.65
    return {Goal=goal,Normal=normal,Right=right,Plane=goal.Position+normal*depth,
        HalfWidth=math.max(0,width-margin),Bottom=goal.Position.Y-goal.Size.Y*.5+margin,
        Top=goal.Position.Y+goal.Size.Y*.5-margin}
end
local function shotInRange(from)
    local _,model=root()
    local goal=attackGoal(model)
    if typeof(from)~="Vector3"or not goal then return false end
    local delta=goal.Position-from
    return Vector3.new(delta.X,0,delta.Z).Magnitude<=(C.ShootRange or 95),goal
end
local function shotKeeper(model,mouth)
    local now=os.clock()
    if now-keeperCacheAt>.3 then
        keeperCacheAt=now
        table.clear(keeperCache)
        for _,candidate in ipairs(CS:GetTagged("MannequinCharacter"))do
            if candidate:IsA("Model")and candidate~=model and candidate:GetAttribute("Role")=="Goalkeeper"then
                keeperCache[#keeperCache+1]=candidate
            end
        end
    end
    local best,nearest
    for _,candidate in ipairs(keeperCache)do
        local r=candidate.Parent and candidate:FindFirstChild("Root")
        if r and candidate:GetAttribute("Team")~=model:GetAttribute("Team")then
            local distance=(r.Position-mouth.Plane).Magnitude
            if not nearest or distance<nearest then best,nearest=r,distance end
        end
    end
    return best
end
local function clampShotPoint(point,mouth)
    local lateral=math.clamp((point-mouth.Plane):Dot(mouth.Right),-mouth.HalfWidth,mouth.HalfWidth)
    local base=mouth.Plane+mouth.Right*lateral
    return Vector3.new(base.X,math.clamp(point.Y,mouth.Bottom,mouth.Top),base.Z)
end
local function newShotCycle()
    shotCycle+=1
    S.ShotPlan=nil
    pendingShot=nil
end
local function observeShotRelease()
    local ball=Ball.getBall()
    local _,model=root()
    if not ball or not model then return end
    local stamp=ball:GetAttribute("ReleasedAt")
    local by=ball:GetAttribute("ReleasedBy")
    if stamp and stamp~=observedRelease then
        observedRelease=stamp
        if pendingShot and by==model:GetAttribute("DribbleId")then
            shotHistory[#shotHistory+1]=pendingShot.Point
            if #shotHistory>4 then table.remove(shotHistory,1)end
            S.LastShotPoint=pendingShot.Point
            S.LastShotAt=os.clock()
            pendingShot=nil
            S.ShotPlan=nil
            shotCycle+=1
        end
    end
end
local function goalTarget(from)
    local inRange,goal=shotInRange(from)
    if not inRange then return end
    local _,model=root()
    local mouth=shotMouth(goal)
    if not mouth then return end
    local keeper=shotKeeper(model,mouth)
    local keeperPosition=keeper and keeper.Position
    local keeperVelocity=keeper and keeper.AssemblyLinearVelocity or Vector3.zero
    local signature=table.concat({tostring(C.AimSide),tostring(C.AimHeight),tostring(C.AimWidth),
        tostring(C.AimAngle),tostring(C.VaryShots),tostring(shotCycle)},"|")
    local cached=S.ShotPlan
    local charging=DribbleClient.kickState()~=nil
    if cached and cached.Goal==goal and cached.Signature==signature and(from-cached.From).Magnitude<3
        and(charging or os.clock()-cached.At<.12)
        and((not keeperPosition and not cached.KeeperPosition)or keeperPosition and cached.KeeperPosition
            and(keeperPosition-cached.KeeperPosition).Magnitude<1.5)then return cached.Point,cached.Side,cached end
    local width=mouth.HalfWidth*math.clamp(C.AimWidth or .8,.1,.97)
    local h=math.clamp(C.AimHeight or .55,.05,.95)
    local heights=C.VaryShots and {math.clamp(h-.28,.12,.88),h,math.clamp(h+.25,.12,.88)}or {h}
    local sides
    if C.AimSide=="Left"then sides={-1}
    elseif C.AimSide=="Right"then sides={1}
    elseif C.AimSide=="Center"then sides={0}
    else sides={-1,-.58,0,.58,1}end
    local candidates={}
    local random=Random.new(shotCycle*104729+7919)
    for _,side in ipairs(sides)do for _,height in ipairs(heights)do
        local point=mouth.Plane+mouth.Right*(side*width)
        point=Vector3.new(point.X,mouth.Bottom+(mouth.Top-mouth.Bottom)*height,point.Z)
        if (C.AimAngle or 0)~=0 then
            local shift=math.tan(math.rad(C.AimAngle))*(mouth.Plane-from).Magnitude
            point=clampShotPoint(point+mouth.Right*shift,mouth)
        end
        local delta=point-from
        local distance=delta.Magnitude
        local arrival=math.clamp(distance/110,.12,1.6)
        local score=0
        if keeper then
            local moving=keeperPosition+keeperVelocity*math.min(arrival,.25)
            local gap=point-moving
            local across=gap:Dot(mouth.Right)
            local toward=keeperVelocity:Dot(mouth.Right)
            local reverse=toward*across<0 and math.min(.14,math.abs(toward)*.006)or 0
            local available=math.max(0,arrival-.12-reverse)
            local reach=math.min(20,available*32)+2
            score=math.abs(across)-reach+math.max(0,point.Y-moving.Y-6)*.7
            if keeper.Parent:GetAttribute("BodyState")=="Diving"then
                local committed=keeperVelocity:Dot(mouth.Right)
                if committed*across<0 then score+=math.min(8,math.abs(committed)*.2)end
            end
        end
        if C.VaryShots then
            for index,old in ipairs(shotHistory)do
                score-=math.max(0,9-(point-old).Magnitude)*(index/#shotHistory)*1.25
            end
            score+=random:NextNumber(-.8,.8)
        end
        score-=math.abs(side)^4*.15
        candidates[#candidates+1]={Point=point,Side=side,Score=score,Mouth=mouth}
    end end
    table.sort(candidates,function(a,b)return a.Score>b.Score end)
    local best=candidates[1]
    if not best then return end
    local plan={Point=best.Point,Side=best.Side,Goal=goal,Mouth=mouth,From=from,At=os.clock(),Locked=charging,
        Keeper=keeper,KeeperPosition=keeperPosition,Signature=signature,Candidates=candidates,Cycle=shotCycle}
    S.ShotPlan=plan
    return plan.Point,plan.Side,plan
end
local function flightCrossing(args,result,mouth)
    if type(result)~="table"or typeof(result.vel)~="Vector3"or typeof(result.spin)~="Vector3"then return end
    local P=args.P or Flight.params(Ball.getBall())
    local ground=args.groundY or Ball.groundBallY()
    if type(ground)~="number"then ground=args.from.Y end
    local distance=(args.from-mouth.Plane):Dot(mouth.Normal)
    if distance<=0 then return end
    local position,velocity,spin=args.from,result.vel,result.spin
    local horizon=math.clamp((mouth.Plane-position).Magnitude/math.max(result.speed or velocity.Magnitude,1)*2+.35,.4,3)
    local step=1/120
    for time=step,horizon,step do
        local point,nextVelocity,nextSpin=Flight.airStep(position,velocity,spin,step,P)
        if point.Y<ground and nextVelocity.Y<0 then return nil,"Ground before goal"end
        local after=(point-mouth.Plane):Dot(mouth.Normal)
        if after<=0 then
            local alpha=distance/math.max(distance-after,1e-6)
            local crossing=position:Lerp(point,alpha)
            local inside=math.abs((crossing-mouth.Plane):Dot(mouth.Right))<=mouth.HalfWidth+.2
                and crossing.Y>=mouth.Bottom-.2 and crossing.Y<=mouth.Top+.2
            return crossing,inside and(time-step+step*alpha)or nil
        end
        position,velocity,spin,distance=point,nextVelocity,nextSpin,after
    end
end
local function desiredCurve(args,side)
    if not(C.CustomCurve or C.AutoCurve and S.AutoShotAt and os.clock()-S.AutoShotAt<1)then return args.curve end
    local sign=C.CurveSide=="Left"and -1 or 1
    if C.CurveSide=="Toward corner"then sign=side==0 and 0 or side end
    return sign*math.clamp(C.CurveAmount or 20,0,60)
end
local function locallyRelevant(args)
    local r,model=root()
    if not r or typeof(args.from)~="Vector3"then return false end
    if model:GetAttribute("Role")=="Goalkeeper"then return false end
    if args.model and args.model~=LP.Character then return false end
    return(args.from-r.Position).Magnitude<18
end
local function hook(fn,wrapper)
    if not hookfunction then return end
    local old
    old=hookfunction(fn,function(...)return wrapper(old,...)end)
    table.insert(S.Hooks,{Function=fn,Original=old})
end
hook(Kick.Strike.speedFor,function(old,...)
    local value=old(...)
    local scope=shotScopes[coroutine.running()]
    return scope and value*scope.Power or value
end)
hook(Kick.Strike.solve,function(old,args)
    if not S.Loaded or type(args)~="table"or not locallyRelevant(args)then return old(args)end
    local family=args.family
    local pass=family==Kick.Families.PushPass or family==Kick.Families.VolleyPass or family==Kick.Families.VolleyPush
    if pass then return old(args)end
    local thread=coroutine.running()
    local previous=shotScopes[thread]
    shotScopes[thread]={Power=math.clamp(C.ShotPower or 1,.5,1.4)}
    local ok,result=pcall(function()
        local working=table.clone(args)
        if C.NoMiss then working.errorScale=0 end
        if not C.PerfectShot then
            if shotInRange(args.from)then local _,side=goalTarget(args.from)working.curve=desiredCurve(args,side or 0)end
            return old(working)
        end
        local _,_,plan=goalTarget(args.from)
        if not plan then return old(working)end
        local cached=plan.Solution
        local curveKey=desiredCurve(args,plan.Side)
        local tolerance=UIS.TouchEnabled and .12 or .05
        if cached and os.clock()-cached.At<(UIS.TouchEnabled and .065 or .04)
            and cached.Family==family and cached.Foot==args.foot and cached.Exact==args.exact
            and cached.Straight==args.straight and cached.MaxLaunch==args.maxLaunch
            and cached.CurveKey==curveKey and cached.Power==(C.ShotPower or 1)
            and math.abs(cached.Charge-(args.charge or 0))<.005 and(cached.From-args.from).Magnitude<tolerance then
            pendingShot={Point=plan.Point,At=os.clock(),Cycle=shotCycle}
            if C.NoMiss then return table.clone(cached.Result)end
            local final=table.clone(cached.Args)
            final.errorScale=working.errorScale final.rng=working.rng
            return old(final)
        end
        local best,bestArgs,bestCandidate,bestScore
        local candidates=plan.Locked and plan.Selected and {plan.Selected}or plan.Candidates
        for index=1,math.min(#candidates,UIS.TouchEnabled and 2 or 3)do
            local candidate=candidates[index]
            local probe=table.clone(working)
            probe.aim=table.clone(working.aim or {})
            probe.aim.kind="Point"probe.aim.point=candidate.Point probe.aim.dir=(candidate.Point-args.from).Unit
            probe.curve=desiredCurve(args,candidate.Side)
            probe.errorScale=0 probe.rng=Random.new(shotCycle*17+index)
            local solved=old(probe)
            local crossing,time=flightCrossing(probe,solved,plan.Mouth)
            if crossing and time then
                local miss=(crossing-candidate.Point).Magnitude
                local score=candidate.Score-miss*4
                if plan.Keeper then
                    local moving=plan.Keeper.Position+plan.Keeper.AssemblyLinearVelocity*math.min(time,.25)
                    score=score+math.abs((crossing-moving):Dot(plan.Mouth.Right))*.2
                end
                if not bestScore or score>bestScore then best,bestArgs,bestCandidate,bestScore=solved,probe,candidate,score end
            end
        end
        if not bestArgs then
            local fallback=table.clone(working)
            fallback.aim=table.clone(working.aim or {})
            fallback.aim.kind="Point"fallback.aim.point=plan.Point fallback.aim.dir=(plan.Point-args.from).Unit
            fallback.curve=0
            fallback.errorScale=0 fallback.rng=Random.new(shotCycle*17+1)
            local fallbackResult=old(fallback)
            local crossing,time=flightCrossing(fallback,fallbackResult,plan.Mouth)
            if not crossing or not time then return old(working)end
            best,bestArgs=fallbackResult,fallback
            bestCandidate={Point=plan.Point,Side=plan.Side}
        end
        plan.Point,plan.Side=bestCandidate.Point,bestCandidate.Side
        if DribbleClient.kickState()~=nil then plan.Locked=true plan.Selected=bestCandidate end
        pendingShot={Point=plan.Point,At=os.clock(),Cycle=shotCycle}
        plan.Solution={At=os.clock(),Family=family,Foot=args.foot,Exact=args.exact,Straight=args.straight,
            MaxLaunch=args.maxLaunch,CurveKey=desiredCurve(args,plan.Side),Power=C.ShotPower or 1,
            Charge=args.charge or 0,From=args.from,Result=table.clone(best),Args=bestArgs}
        if C.NoMiss then return best end
        bestArgs.errorScale=working.errorScale bestArgs.rng=working.rng
        return old(bestArgs)
    end)
    shotScopes[thread]=previous
    if not ok then S.Errors.Shooting=tostring(result)return old(args)end
    return result
end)
S.Shooting={Begin=newShotCycle,Observe=observeShotRelease,Target=goalTarget,Goal=attackGoal,
    Mouth=shotMouth,Crossing=flightCrossing,Reset=function()S.ShotPlan=nil pendingShot=nil end}

hook(Mannequin.limitMove,function(old,model,direction,kind)
    if S.Loaded and model==LP.Character and S.KeeperDiveThread==coroutine.running()and S.KeeperDiveWorld then
        return S.KeeperDiveWorld
    end
    return old(model,direction,kind)
end)
S.KeeperDirectionHook=true
hook(Mannequin.kickFall,function(old,model,...)
    if S.Loaded and C.AntiRagdoll and model==LP.Character then return end
    return old(model,...)
end)
if type(Mannequin.shapeMove)=="function"then
    hook(Mannequin.shapeMove,function(old,input,...)
        if S.Loaded and movementWish and os.clock()-movementWishAt<0.15 and (movementSource=="Keeper"or not Window.IsOpen)and not UIS:GetFocusedTextBox()then
            if typeof(input)=="Vector2"and input.Magnitude>.18 then return old(input,...)end
            local cf=workspace.CurrentCamera.CFrame
            local forward=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
            local right=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z)
            if forward.Magnitude>0.001 and right.Magnitude>0.001 then
                return Vector2.new(movementWish:Dot(right.Unit),movementWish:Dot(forward.Unit))
            end
        end
        return old(input,...)
    end)
end
hook(BodyController.step,function(old,body,dt)
    if S.Loaded and body.model==LP.Character then S.KeeperBody=body end
    if S.Loaded and body.model==LP.Character and body.active then
        local falling=body.mode=="Fall"or body.mode=="FrontFall"or body.mode=="KickFall"
        local recovering=body.mode=="GetUp"
        if (C.AntiRagdoll and falling or C.InstantGetUp and(falling or recovering))and not body:_aloft()then
            body:_beginGetUp(true)
            body:_handBack()
            body:reseat()
            return
        end
        if C.FastGetUp and(falling or recovering)then dt*=2.5 end
    end
    return old(body,dt)
end)
local cosmeticPage=Window:Page({Name="Cosmetics",Icon="7743876054"})
local cosmetics=section(cosmeticPage,"Local appearance")
local previewWorld,previewCamera,previewFrame,previewClone
local updatePreview
local worn={}
local facesSaved={}
local function restoreCosmetics(model)
    local list=worn[model]
    if not list then return end
    if model.Parent then
        for _,child in ipairs(model:GetChildren())do if child:GetAttribute(Locker.WORN)then child:Destroy()end end
        for _,child in ipairs(list)do child.Parent=model end
        local head=model:FindFirstChild("Head")
        if head and facesSaved[model]then
            for _,child in ipairs(head:GetChildren())do if child:IsA("SurfaceAppearance")or child:IsA("Decal")then child:Destroy()end end
            for _,child in ipairs(facesSaved[model])do child.Parent=head end
        end
    end
    worn[model]=nil facesSaved[model]=nil
end
local function dress(model)
    if model then Locker.dress(model,{Hair=C.Hair~="None"and C.Hair or nil,Hat=C.Hat~="None"and C.Hat or nil,Face=C.Face~="None"and C.Face or nil,Expression=C.Expression})end
end
local function applyCosmetics()
    local model=LP.Character
    if not model then return end
    if not worn[model]then
        local list={}
        for _,child in ipairs(model:GetChildren())do if child:GetAttribute(Locker.WORN)then list[#list+1]=child:Clone()end end
        worn[model]=list
        local faceList={}
        local head=model:FindFirstChild("Head")
        if head then for _,child in ipairs(head:GetChildren())do
            if child:IsA("SurfaceAppearance")or child:IsA("Decal")then faceList[#faceList+1]=child:Clone()end
        end end
        facesSaved[model]=faceList
    end
    dress(model)
    if updatePreview then updatePreview()end
end
toggle(cosmetics,"CosmeticOverride","Preview all cosmetics",function(v)if v then applyCosmetics()else if LP.Character then restoreCosmetics(LP.Character)end if updatePreview then updatePreview()end end end)
local function catalog(kind)
    local list={"None"}
    for _,item in ipairs(Locker.items(kind))do table.insert(list,item.name)end
    return list
end
for _,kind in ipairs({"Hair","Hat","Face"})do dropdown(cosmetics,kind,kind,catalog(kind),"None",function()if C.CosmeticOverride then applyCosmetics()elseif updatePreview then updatePreview()end end)end
local faces=Locker.faces()
local expressions={}
for _,face in ipairs(faces)do table.insert(expressions,type(face)=="string"and face or face.name or face.Name)end
if #expressions==0 then expressions={"Rosy"}end
dropdown(cosmetics,"Expression","Expression",expressions,expressions[1],function()if C.CosmeticOverride then applyCosmetics()elseif updatePreview then updatePreview()end end)
cosmetics:Button({Name="Apply local appearance",Callback=applyCosmetics})
local previewSection=section(cosmeticPage,"3D preview",2)
previewFrame=Instance.new("ViewportFrame")
previewFrame.Name="AxisSoccerPreview" previewFrame.BackgroundColor3=Library.Theme["Section Background"] previewFrame.Size=UDim2.new(1,0,0,240)
previewFrame.BorderSizePixel=0 previewFrame.BackgroundTransparency=1
previewFrame.Ambient=Color3.new(1,1,1) previewFrame.LightColor=Color3.new(1,1,1)
previewFrame.ZIndex=previewSection.Items.Content.Instance.Parent.ZIndex+2
previewFrame.Active=true
previewFrame.Parent=previewSection.Items.Content.Instance
previewCamera=Instance.new("Camera")previewCamera.FieldOfView=35 previewCamera.Parent=previewFrame previewFrame.CurrentCamera=previewCamera
previewWorld=Instance.new("WorldModel")previewWorld.Parent=previewFrame
local yaw,zoom=math.pi,16
updatePreview=function()
    if previewClone then previewClone:Destroy()end
    local model=LP.Character if not model then return end
    local saved={}
    for _,object in ipairs(model:GetDescendants())do saved[object]=object.Archivable object.Archivable=true end
    local previous=model.Archivable model.Archivable=true previewClone=model:Clone()model.Archivable=previous
    for object,value in pairs(saved)do object.Archivable=value end
    for _,object in ipairs(previewClone:GetDescendants())do
        if object:IsA("BaseScript")or object:IsA("ModuleScript")then object:Destroy()
        elseif object:IsA("BasePart")then object.Anchored=true object.CanCollide=false object.LocalTransparencyModifier=0 end
    end
    previewClone:PivotTo(CFrame.new())
    dress(previewClone)
    for _,object in ipairs(previewClone:GetDescendants())do
        if object:IsA("BasePart")then object.Anchored=true object.CanCollide=false object.LocalTransparencyModifier=0 end
    end
    S.PreviewModel=previewClone
    previewClone.Parent=previewWorld
    local cf,size=previewClone:GetBoundingBox()zoom=math.max(size.Y*1.6,10)
    previewCamera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(math.sin(yaw)*zoom,1,math.cos(yaw)*zoom),cf.Position)
end
previewSection:Button({Name="Refresh preview",Callback=updatePreview})
local dragging=false
connect(previewFrame.InputBegan,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
connect(UIS.InputEnded,function(input)if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
connect(UIS.InputChanged,function(input)
    if not previewClone then return end
    if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then yaw+=input.Delta.X*0.015
    elseif input.UserInputType==Enum.UserInputType.MouseWheel then
        local mouse=UIS:GetMouseLocation()-game:GetService("GuiService"):GetGuiInset()
        local p,size=previewFrame.AbsolutePosition,previewFrame.AbsoluteSize
        if mouse.X<p.X or mouse.X>p.X+size.X or mouse.Y<p.Y or mouse.Y>p.Y+size.Y then return end
        zoom=math.clamp(zoom-input.Position.Z,6,30)
    else return end
    local cf=previewClone:GetBoundingBox()
    previewCamera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(math.sin(yaw)*zoom,1,math.cos(yaw)*zoom),cf.Position)
end)
local emoteGroup=section(cosmeticPage,"Emote slots")
local selectedSlot=1
for index=1,8 do dropdown(emoteGroup,"Emote"..index,"Slot "..index,Emotes.LIST,Emotes.DEFAULT_SLOTS[index]or Emotes.DEFAULT)end
dropdown(emoteGroup,"PlaySlot","Selected slot",{"1","2","3","4","5","6","7","8"},"1",function(v)selectedSlot=tonumber(v)end)
emoteGroup:Button({Name="Play selected emote",Callback=function()
    local playback=require(Client.Emotes.Playback)
    local name=C["Emote"..selectedSlot]
    playback.playOwn(name)
end})
emoteGroup:Button({Name="Save owned emote slots",Callback=function()
    local slots={}for i=1,8 do slots[i]=C["Emote"..i]end
    Net:RemoteEvent(Emotes.SAVE):FireServer(slots)
end})
local visuals=Window:Page({Name="Visuals",Icon="7733774602"})
local world=section(visuals,"World")
toggle(world,"ColorCorrection","Color correction")
slider(world,"Saturation","Saturation",0,-1,1,0.05)
slider(world,"Contrast","Contrast",0,-0.5,0.5,0.05)
toggle(world,"Bloom","Bloom")slider(world,"BloomIntensity","Bloom intensity",0.4,0,2,0.05)
toggle(world,"SunRays","Sun rays")slider(world,"SunIntensity","Sun rays intensity",0.1,0,0.5,0.01)
toggle(world,"CustomClock","Clock time")slider(world,"ClockTime","Time",14,0,24,0.1)
toggle(world,"RemoveFog","Remove fog")
toggle(world,"CustomFOV","Custom FOV")slider(world,"FOV","FOV",80,40,120,1)
toggle(world,"CustomSky","Custom skybox")
for _,face in ipairs({"Bk","Dn","Ft","Lf","Rt","Up"})do textbox(world,"Sky"..face,"Sky "..face,"")end
local correction=Instance.new("ColorCorrectionEffect")correction.Name="AxisColor"correction.Enabled=false correction.Parent=Lighting
local bloom=Instance.new("BloomEffect")bloom.Name="AxisBloom"bloom.Enabled=false bloom.Parent=Lighting
local sun=Instance.new("SunRaysEffect")sun.Name="AxisSun"sun.Enabled=false sun.Parent=Lighting
local sky=Instance.new("Sky")sky.Name="AxisSky"
for _,object in ipairs({correction,bloom,sun,sky})do table.insert(instances,object)end
local spoof=section(visuals,"Local display",2)
toggle(spoof,"SpoofName","Name display")textbox(spoof,"DisplayName","Name",LP.DisplayName)
toggle(spoof,"SpoofCoins","Coins display")slider(spoof,"Coins","Coins",10000,0,1000000,100)
toggle(spoof,"SpoofPing","Ping display")slider(spoof,"Ping","Ping",10,0,300,1)
toggle(spoof,"SpoofGoals","Match goals display")slider(spoof,"MatchGoals","Goals",10,0,100,1)
toggle(spoof,"SpoofOVR","OVR display")slider(spoof,"OVR","OVR",99,0,100,1)
toggle(spoof,"SpoofCareer","Stats card display")
for _,stat in ipairs({"Matches","Goals","Assists","Wins","TimePlayed"})do slider(spoof,"Career"..stat,stat,100,0,100000,1)end
local misc=Window:Page({Name="Misc",Icon="7743878358"})
local automation=section(misc,"Automation")
toggle(automation,"AntiAFK","Anti AFK")
toggle(automation,"AutoQuests","Auto claim completed quests")
toggle(automation,"AutoTeamSwitch","Auto accept team switch")
toggle(automation,"AutoJoin","Auto join match")
toggle(automation,"AutoSkipReplays","Auto skip replays")
toggle(automation,"HideHighPing","Hide high ping popup")
automation:Button({Name="Claim group coins",Callback=function()
    local rules=require(Game.FreeCoins)
    if LP:IsInGroup(rules.GROUP_ID)and not LP:GetAttribute(rules.CLAIMED)then Net:RemoteEvent(rules.REMOTE):FireServer()end
end})
local performance=section(misc,"Performance",2)
dropdown(performance,"FPSMode","FPS boost",{"Off","Balanced","Performance","Maximum"},"Off")
toggle(performance,"UnlockFPS","Unlock FPS cap",function(v)
    if setfpscap then setfpscap(v and 240 or 60)end
end)
performance:Button({Name="Unload",Callback=function()S.Unload()end})
local function visible(object)
    local current=object
    while current and not current:IsA("PlayerGui")do
        if current:IsA("GuiObject")and not current.Visible then return false end
        if current:IsA("ScreenGui")and not current.Enabled then return false end
        current=current.Parent
    end
    return true
end
local function click(button)
    if button and button:IsA("GuiButton")and visible(button)then emit(button.Activated) return true end
end
local lastPosition,lastAt,lastSave,lastShot=nil,0,0,0
local function shootNow()
    if S.AutoChargePending then return false end
    local r,model=root()
    if not r or model:GetAttribute("Role")=="Goalkeeper"or model:GetAttribute("BodyState")~="Animated"then return false end
    if S.Shooting then S.Shooting.Begin()end
    S.ShotPlan=nil
    S.AutoShotAt=os.clock()
    lastShot=S.AutoShotAt
    if not action("Kick","KickShoot")then S.AutoShotAt=nil return false end
    S.AutoChargePending=model
    task.delay(Kick.Rules.Charge.FullTime,function()
        if S.Loaded and S.AutoChargePending==model then
            action("Kick","KickShoot",true)
            S.AutoChargePending=nil
        end
    end)
    return true
end
local keeperController=(function()
    local controller={}
    local cachedGoal,goalAt,profileModel,profiles,fieldCentre,goalTeam
    local threatKey,threatAt,lastPlanAt,lastRequest=nil,0,0,0
    local assist,scheduled
    local jointOrder={"Waist","LeftShoulder","LeftElbow","LeftWrist","RightShoulder","RightElbow","RightWrist"}
    local function gameCall(fn,...)
        local identity=getthreadidentity and getthreadidentity()or 8
        if setthreadidentity then setthreadidentity(2)end
        local result=table.pack(pcall(fn,...))
        if setthreadidentity then setthreadidentity(identity)end
        if not result[1]then error(result[2],0)end
        return table.unpack(result,2,result.n)
    end
    local function flat(vector)
        local value=Vector3.new(vector.X,0,vector.Z)
        return value.Magnitude>.001 and value.Unit or nil
    end
    local function ownGoal(r,now)
        local model=LP.Character
        local team=model and model:GetAttribute("Team")
        if cachedGoal and cachedGoal.Parent and goalTeam==team and now-goalAt<1 then return cachedGoal end
        cachedGoal=nil goalAt=now goalTeam=team
        local area
        if team then
            local ok,rules=pcall(require,Game.KeeperRules)
            if ok then local valid,value=pcall(rules.area,team)if valid then area=value end end
        end
        local nearest,total,count=nil,Vector3.zero,0
        for _,frame in ipairs(CS:GetTagged("SoccerGoalFrame"))do
            if frame:IsA("BasePart")and frame:IsDescendantOf(workspace)then
                total+=frame.Position count+=1
                local distance=(frame.Position-r.Position).Magnitude
                if area and typeof(area.centre)=="Vector3"and type(area.side)=="number"then
                    local longitudinal=(frame.Position-area.centre).X*area.side
                    if longitudinal>0 then distance=math.abs(longitudinal-(area.line or longitudinal))
                    else distance=10000+distance end
                end
                if not nearest or distance<nearest then cachedGoal,nearest=frame,distance end
            end
        end
        fieldCentre=count>1 and total/count or Vector3.new(0,cachedGoal and cachedGoal.Position.Y or 0,0)
        return cachedGoal
    end
    local function goalAxes(goal,r)
        local narrow=goal.Size.X<goal.Size.Z
        local normal=flat(narrow and goal.CFrame.RightVector or goal.CFrame.LookVector)
        local across=flat(narrow and goal.CFrame.LookVector or goal.CFrame.RightVector)
        if not normal or not across then return end
        if (fieldCentre-goal.Position):Dot(normal)<0 then normal=-normal end
        return normal,across,(narrow and goal.Size.Z or goal.Size.X)*.5
    end
    local function makeProfiles(model)
        if model==profileModel and profiles then return profiles end
        profileModel=model profiles={}
        local Skeleton=gameCall(require,Game.MannequinAnimation.Skeleton)
        local skeleton=Skeleton.new(model,model:FindFirstChild("Root"))
        local Contacts=gameCall(require,Game.Dribble.Contacts)
        local catchParts={"LeftHand","RightHand","LeftForearm","RightForearm","LeftUpperArm","RightUpperArm","Chest"}
        for _,kind in ipairs({"Low","Mid","High","Smother"})do
            local track=gameCall(KeeperDives.track,kind)
            if track then for _,right in ipairs({false,true})do
                if kind~="Smother"or right then
                    local side=right and "right"or "left"
                    local data=track[side]
                    if data then
                        local sign=right and 1 or -1
                        local stick=kind=="Smother"and Vector2.new(0,-1)
                            or Vector2.new(sign,kind=="Low"and -.65 or kind=="High"and .7 or 0).Unit
                        local profile={Kind=kind,Right=right,Stick=stick,Track=track,Samples={}}
                        local last=math.min(track.duration,track.ragAt and track.ragAt-.025 or track.armsFrom and track.armsFrom-.025 or track.touch+.12)
                        for age=.12,last,.035 do
                            local pose=KeeperDives.pose(skeleton,data,age,CFrame.identity)
                            local frames=skeleton:solve(pose)
                            local boxes={}
                            for _,name in ipairs(catchParts)do
                                local part=model:FindFirstChild(name)
                                if frames[name]and part and part:IsA("BasePart")then
                                    local padding=tonumber(KeeperHands.SAVE_PAD)or .3
                                    local frame,size=Contacts.raise(frames[name],part.Size+Vector3.one*(2*padding),Contacts.HIT_LIFT)
                                    boxes[#boxes+1]={Name=name,Frame=frame,Size=size}
                                end
                            end
                            if #boxes>0 then profile.Samples[#profile.Samples+1]={Age=age,Boxes=boxes}end
                        end
                        if #profile.Samples>0 then profiles[#profiles+1]=profile end
                    end
                end
            end end
        end
        return profiles
    end
    local predictionModules
    local function trajectory(position,velocity,serverNow,horizon)
        if not predictionModules then
            local sim=gameCall(require,Game.BallSim)
            local world=gameCall(require,Game.BallSim.World)
            local flight=gameCall(require,Game.Kick.Flight)
            predictionModules={Sim=sim,World=world,Flight={airStep=flight.airStep,rollStep=flight.rollStep,
                rollingSpin=flight.rollingSpin,toGround=flight.toGround,atRest=flight.atRest,
                bounce=flight.bounce,BOUNCE_MIN=flight.BOUNCE_MIN or 2}}
        end
        local modules=predictionModules
        local state=Ball.freeSim and Ball.freeSim()
        if type(state)~="table"then return {{T=0,P=position}}end
        state=table.clone(state)
        state.pos=position state.vel=velocity state.t=serverNow state.n=state.n or 0
        local world=table.clone(modules.World.get())
        world.bodies={}
        local params=modules.World.params()
        local path={{T=0,P=position}}
        local step=modules.Sim.STEP or 1/120
        local nextSample=.025
        for elapsed=step,horizon+step,step do
            state=modules.Sim.step(modules.Flight,state,step,params,world,false,step)
            if elapsed>=nextSample or elapsed>=horizon then
                path[#path+1]={T=elapsed,P=state.pos}
                nextSample=elapsed+.025
            end
        end
        return path
    end

    local function planeCrossing(path,origin,normal)
        local before=(path[1].P-origin):Dot(normal)
        if before<=0 then return end
        for i=2,#path do
            local after=(path[i].P-origin):Dot(normal)
            if before>0 and after<=0 then
                local a,b=path[i-1],path[i]
                local fraction=before/(before-after)
                return a.T+(b.T-a.T)*fraction,a.P:Lerp(b.P,fraction)
            end
            before=after
        end
    end
    local function atPlane(path,origin,normal)
        return planeCrossing(path,origin,normal)
    end
    local function closestBox(frame,size,point)
        local offset=frame:PointToObjectSpace(point)
        local half=size*.5
        local closest=frame:PointToWorldSpace(Vector3.new(math.clamp(offset.X,-half.X,half.X),
            math.clamp(offset.Y,-half.Y,half.Y),math.clamp(offset.Z,-half.Z,half.Z)))
        return closest,(point-closest).Magnitude
    end
    local function contactFor(model,point,padding)
        local Contacts=gameCall(require,Game.Dribble.Contacts)
        local best,bestGap,bestName
        for name in pairs(KeeperHands.CATCH_PARTS)do
            local part=model:FindFirstChild(name)
            if part and part:IsA("BasePart")then
                local frame,size=Contacts.raise(part.CFrame,part.Size+Vector3.one*(2*padding),padding>0 and Contacts.HIT_LIFT or 0)
                local closest,gap=closestBox(frame,size,point)
                if not bestGap or gap<bestGap then best,bestGap,bestName=closest,gap,name end
            end
        end
        return best,bestGap,bestName
    end
    local function inputBasis()
        local camera=workspace.CurrentCamera
        local right=camera and flat(camera.CFrame.RightVector)
        if not right then return end
        local forward=Vector3.yAxis:Cross(right)
        return CFrame.lookAt(Vector3.zero,forward),right
    end
    function controller.Predict(position,velocity,r,model,now,pathOverride)
        local goal=ownGoal(r,now)
        if not goal then return end
        local normal,across,halfWidth=goalAxes(goal,r)
        if not normal or velocity:Dot(normal)>=-1 then return end
        local horizon=math.clamp(C.KeeperHorizon or 1.6,.5,2.5)
        local path=pathOverride or trajectory(position,velocity,workspace:GetServerTimeNow(),horizon)
        local goalTime,crossing=planeCrossing(path,goal.Position,normal)
        if not goalTime then return end
        local ball=Ball.getBall()
        local radius=ball and ball:IsA("BasePart")and ball.Size.Y*.5 or .85
        local base=goal.Position.Y-goal.Size.Y*.5
        if math.abs((crossing-goal.Position):Dot(across))>halfWidth+radius
            or crossing.Y>base+goal.Size.Y+radius or crossing.Y<base-radius then return end
        local basis,right=inputBasis()
        if not basis then return end
        local groundY=r.Position.Y-(tonumber(model:GetAttribute("RootHeight"))or 4.7)
        local anchor=Vector3.new(r.Position.X,groundY,r.Position.Z)
        local latency=1/120
        local carry=Vector3.new(r.AssemblyLinearVelocity.X,0,r.AssemblyLinearVelocity.Z)
        if carry.Magnitude>24 then carry=carry.Unit*24 end
        local best
        local blatant=C.KeeperMode=="Blatant"
        for _,profile in ipairs(makeProfiles(model))do
            local allowed=(profile.Kind~="Smother"or C.LowSmother)
                and(C.DiveZone=="All"or C.DiveZone=="Left"and not profile.Right and profile.Kind~="Smother"
                or C.DiveZone=="Right"and profile.Right and profile.Kind~="Smother"or C.DiveZone=="Center"and profile.Kind=="Smother")
            if allowed then for _,sample in ipairs(profile.Samples)do
                for _,box in ipairs(sample.Boxes)do
                    local drift=carry*math.min(sample.Age,.2)*.6
                    local frame=(CFrame.new(anchor)*basis)*box.Frame+drift
                    local time,point=atPlane(path,frame.Position,normal)
                    if time and time<=goalTime+.02 then
                        local delay=time-latency-sample.Age
                        if delay>=-.045 and delay<=horizon then
                            local clearance=point.Y-radius-groundY
                            local ground=clearance<=1
                            local validHeight=not ground or profile.Kind=="Low"or profile.Kind=="Smother"
                            local _,gap=closestBox(frame,box.Size,point)
                            local error=math.max(0,gap-radius-(tonumber(KeeperHands.MEET_SLACK)or .25))
                            local mismatch=clearance<2 and profile.Kind=="High"and 4 or 0
                            local score=error+mismatch+math.max(0,delay)*.12+time*.04
                            if not validHeight then score=math.huge end
                            if score<math.huge and(not best or score<best.Score)then
                                best={Score=score,Error=error,Delay=math.max(0,delay),ETA=time,Point=point,
                                    Direction=profile.Stick,Kind=profile.Kind,Age=sample.Age,ContactPart=box.Name,Ground=ground,
                                    WorldDirection=profile.Kind=="Smother"and basis.LookVector or right*(profile.Right and 1 or -1),
                                    Radius=radius,GoalTime=goalTime,Normal=normal}
                            end
                        end
                    end
                end
            end end
        end
        if not best and blatant then
            local time,point=atPlane(path,r.Position,normal)
            if time and time>latency+.04 then
                local side=(point-r.Position):Dot(right)
                local height=point.Y-r.Position.Y
                local ground=point.Y-radius-groundY<=1
                local kind=ground and "Low"or height>2 and "High"or height<-1 and "Low"or "Mid"
                local age=math.min(time-latency,.25)
                best={Score=100,Error=100,Delay=0,ETA=time,Point=point,Direction=Vector2.new(side>=0 and 1 or -1,
                    kind=="High"and .7 or kind=="Low"and -.65 or 0).Unit,Kind=kind,Age=age,
                    WorldDirection=right*(side>=0 and 1 or -1),Radius=radius,GoalTime=goalTime,Normal=normal,Ground=ground}
            end
        end
        return best
    end
    function controller.Reset()
        assist=nil scheduled=nil threatKey=nil threatAt=0 S.KeeperPlan=nil
    end
    local function shiftDive(active,delta)
        local body=S.KeeperBody
        if not body or body.model~=active.Model or not body.kdive then
            local animator=Mannequin.getAnimator(active.Model)
            body=animator and animator.body
        end
        local dive=body and body.model==active.Model and body.kdive
        if not dive or typeof(dive.anchor)~="CFrame"then return false end
        dive.anchor+=delta
        if dive.animated and dive.move and typeof(dive.move.anchor)=="CFrame"then dive.move.anchor+=delta end
        if typeof(dive.from)=="CFrame"then dive.from+=delta end
        local drive=body.assist and body.assist.position
        if body.active and typeof(drive)=="Instance"and drive:IsA("AlignPosition")then drive.Position+=delta end
        return true
    end
    function controller.Step(position,velocity,r,model,now)
        if not C.AutoSave or model:GetAttribute("Role")~="Goalkeeper"then controller.Reset()return end
        if assist or now-lastRequest<.14 or now-lastPlanAt<.025 then return end
        lastPlanAt=now
        local ball=Ball.getBall()
        if not ball or (tonumber(ball:GetAttribute("Possessor"))or 0)~=0 then controller.Reset()return end
        if model:GetAttribute("BodyState")~="Animated"then S.KeeperPlan=nil return end
        if velocity.Magnitude<math.max(1,C.MinBallSpeed or 8)
            or(position-r.Position).Magnitude>(C.KeeperTrackRange or 180)then S.KeeperPlan=nil return end
        if not Mannequin.keeperReady()or Mannequin.keeperBusy()then S.KeeperPlan=nil return end
        local key=tostring(ball:GetAttribute("ReleasedAt"))..":"..tostring(ball:GetAttribute("PossessionId"))
        if key~=threatKey then threatKey=key threatAt=now scheduled=nil end
        local plan=controller.Predict(position,velocity,r,model,now)
        S.KeeperPlan=plan
        if not plan then return end
        if C.KeeperMode~="Blatant"and now-threatAt<(C.Reaction or .03)then return end
        local tolerance=.45
        if C.KeeperMode~="Blatant"and plan.Error>tolerance then return end
        local deadline=now+plan.Delay
        if scheduled and scheduled.Key==key and now<=scheduled.Expires then
            local same=(scheduled.Plan.Point-plan.Point).Magnitude<1
                and math.abs(scheduled.Plan.Age-plan.Age)<.025
                and scheduled.Plan.ContactPart==plan.ContactPart
                and scheduled.Plan.Kind==plan.Kind and scheduled.Plan.Direction:Dot(plan.Direction)>.8
            if same then
                deadline=math.min(deadline,scheduled.At)
            end
        end
        scheduled={Key=key,At=deadline,Expires=now+math.min(.4,plan.ETA),Plan=plan,CreatedAt=now}
        if deadline-now>.018 then return end
        lastRequest=now scheduled=nil
        S.KeeperPlan=plan
        S.KeeperDiveThread=coroutine.running()
        S.KeeperDiveWorld=plan.WorldDirection
        local diveOK,accepted=pcall(gameCall,Mannequin.keeperDiveTo,plan.Direction,false)
        S.KeeperDiveThread=nil S.KeeperDiveWorld=nil
        if not diveOK then error(accepted,0)end
        if accepted then
            lastSave=now
            if C.KeeperMode=="Blatant"then
                assist={Model=model,Root=r,Ball=ball,Plan=plan,Started=now,Ends=now+math.min(1.2,plan.ETA+.08),
                    Method=C.KeeperAssist or "Boost",Teleports=0,LastTeleport=0,Key=key,Travel=0,
                    MaxDistance=math.clamp((plan.Point-r.Position).Magnitude+4,6,35)}
            end
        end
    end
    function controller.Assist(dt)
        local active=assist
        if not active then return end
        local now=os.clock()
        local model,r,ball=active.Model,active.Root,active.Ball
        local body=model.Parent and model:GetAttribute("BodyState")
        local source=Ball.getSource and Ball.getSource()
        local key=tostring(ball:GetAttribute("ReleasedAt"))..":"..tostring(ball:GetAttribute("PossessionId"))
        if not S.Loaded or not C.AutoSave or C.KeeperMode~="Blatant"or LP.Character~=model or not r.Parent or not ball.Parent
            or Ball.getBall()~=ball or key~=active.Key
            or active.Method~=(C.KeeperAssist or "Boost")
            or model:GetAttribute("Role")~="Goalkeeper"or now>active.Ends
            or(source and source~="free"and source~="released")
            or(tonumber(ball:GetAttribute("Possessor"))or 0)~=0 or Mannequin.keeperBusy()then assist=nil return end
        if body~="Diving"then
            if now-active.Started>.22 then assist=nil end
            return
        end
        local position,velocity=Ball.freeState()
        if typeof(position)~="Vector3"or typeof(velocity)~="Vector3"then assist=nil return end
        if (position-active.Plan.Point):Dot(active.Plan.Normal)<-active.Plan.Radius*1.5 then assist=nil return end
        local targetTime=math.max(0,active.Plan.ETA-(now-active.Started))
        local target=active.Plan.Point
        if now>=(active.UpdateAt or 0)and targetTime>.025 then
            active.UpdateAt=now+.06
            local path=trajectory(position,velocity,workspace:GetServerTimeNow(),math.min(1,targetTime+.18))
            local crossingTime,crossing=planeCrossing(path,active.Plan.Point,active.Plan.Normal)
            if crossingTime and(crossing-active.Plan.Point).Magnitude<6 then
                active.Target=crossing
                active.ContactAt=now+crossingTime
            end
        end
        target=active.Target or target
        if active.ContactAt then targetTime=math.max(0,active.ContactAt-now)end
        if targetTime==0 and now-active.Started>active.Plan.ETA+.04 then assist=nil return end
        local contact,gap=contactFor(model,target,tonumber(KeeperHands.SAVE_PAD)or .3)
        if not contact then assist=nil return end
        if gap<=active.Plan.Radius+.12 then return end
        if active.Method=="Teleport"then
            if targetTime>.11 or now-active.Started<.06 or active.Teleports>=1 or now-active.LastTeleport<.045 then return end
            local liveContact,liveGap=contactFor(model,position,tonumber(KeeperHands.SAVE_PAD)or .3)
            if not liveContact or liveGap<=active.Plan.Radius+.12 then return end
            local delta=position-liveContact
            if delta.Magnitude>active.MaxDistance or delta.Magnitude<.15 then return end
            if not shiftDive(active,delta)then return end
            model:PivotTo(model:GetPivot()+delta)
            active.Teleports+=1 active.LastTeleport=now
        else
            local delta=target-contact
            if delta.Magnitude>active.Plan.Radius+.1 then delta*=math.max(0,1-(active.Plan.Radius+.1)/delta.Magnitude)else return end
            local direction=active.Plan.WorldDirection
            local current=active.Offset or Vector3.zero
            local side=math.clamp(current:Dot(direction)+delta:Dot(direction),-9,9)
            local depth=current:Dot(active.Plan.Normal)
            if targetTime<.12 then depth=math.clamp(depth+delta:Dot(active.Plan.Normal),-1.25,1.25)end
            local lift=active.Plan.Ground and 0 or math.clamp(current.Y+delta.Y,-.25,1.2)
            local wanted=direction*side+active.Plan.Normal*depth+Vector3.new(0,lift,0)
            if wanted.Magnitude>10 then wanted=wanted.Unit*10 end
            local shift=wanted-current
            local rate=10+4*math.clamp(C.KeeperBoost or 2,1,6)
            local limit=rate*math.clamp(dt,0,.04)
            if shift.Magnitude>limit then shift=shift.Unit*limit end
            if shift.Magnitude>.005 and shiftDive(active,shift)then active.Offset=current+shift end
        end
    end
    return controller
end)()
S.KeeperController=keeperController


local positionTarget,positionAt,positionMoving=nil,0,false
local function keeperPositionStep(r,model)
    if not C.KeeperPosition or model:GetAttribute("Role")~="Goalkeeper"or Mannequin.keeperBusy and Mannequin.keeperBusy()then
        positionTarget=nil positionMoving=false return
    end
    local state=model:GetAttribute("BodyState")
    if state and state~="Animated"or not model:FindFirstChildOfClass("ControllerManager")then return end
    local goal,nearest
    for _,frame in ipairs(CS:GetTagged("SoccerGoalFrame"))do
        if frame:IsA("BasePart")and frame:IsDescendantOf(workspace)then
            local distance=(frame.Position-r.Position).Magnitude
            if not nearest or distance<nearest then goal,nearest=frame,distance end
        end
    end
    if not goal or nearest>45 then positionTarget=nil positionMoving=false return end
    local now=os.clock()
    if now-positionAt>.12 then
        positionAt=now
        local ball=Ball.getBall()
        local possessor=ball and ball:GetAttribute("Possessor")
        local origin,facing
        if type(possessor)=="number"and possessor~=0 then
            for _,player in ipairs(Players:GetPlayers())do
                local character=player.Character
                local carrier=character and character:FindFirstChild("Root")
                if carrier and character:GetAttribute("DribbleId")==possessor then
                    if character:GetAttribute("Team")~=model:GetAttribute("Team")then
                        origin=Ball.getPosition()or carrier.Position
                        facing=carrier.CFrame.LookVector
                    end
                    break
                end
            end
        else
            local source=Ball.getSource()
            if source=="free"or source=="released"then
                local point,velocity=Ball.freeState()
                if typeof(point)=="Vector3"and typeof(velocity)=="Vector3"
                    and velocity.Magnitude<18 and (point-goal.Position).Magnitude<C.PositionRange then origin=point end
            end
        end
        local wanted=goal.Position.Z
        if origin and (origin-goal.Position).Magnitude<C.PositionRange then
            local span=goal.Position.X-origin.X
            if math.abs(span)>4 then
                local fraction=math.clamp((r.Position.X-origin.X)/span,0,1)
                wanted=origin.Z+(goal.Position.Z-origin.Z)*fraction
                if facing and facing.X*span>0 and math.abs(facing.X)>.25 then
                    local aimed=origin.Z+facing.Z/facing.X*(r.Position.X-origin.X)
                    wanted+=math.clamp(aimed-wanted,-8,8)*.35
                end
            else
                wanted=origin.Z
            end
        end
        wanted=math.clamp(wanted,goal.Position.Z-goal.Size.Z*.5+2,goal.Position.Z+goal.Size.Z*.5-2)
        positionTarget=positionTarget and positionTarget+(wanted-positionTarget)*.28 or wanted
    end
    if not positionTarget then return end
    local delta=positionTarget-r.Position.Z
    if positionMoving then
        if math.abs(delta)<1.5 then positionMoving=false end
    elseif math.abs(delta)>3 then
        positionMoving=true
    end
    if positionMoving then
        local strength=math.clamp(math.abs(delta)/8,.25,.8)
        movementWish=Vector3.new(0,0,delta>0 and strength or -strength)
        movementWishAt=now
        movementSource="Keeper"
    end
    S.PositionTarget=positionTarget
    S.PositionMoving=positionMoving
end
local function tuningStep()
    for key,value in pairs(Tuning.Speed)do
        if type(value)=="number"and not tostring(key):find("Grip")then
            local original=patches[Tuning.Speed]and patches[Tuning.Speed][key]
            patch(Tuning.Speed,key,(original and original.Value or value)*C.SpeedMultiplier,C.SpeedBoost)
        end
    end
    patch(Tuning.Slide,"Cooldown",0,C.NoSlideCooldown)
    patch(Tuning.Slide,"Boost",1.05*C.SlideBoost,C.SlideBoost~=1)
    patch(Tuning,"AccelSmooth",0.08/C.Acceleration,C.Acceleration~=1)
    patch(Tuning,"TurnAccel",259.2*C.TurnSpeed,C.TurnSpeed~=1)
    patch(Tuning.Dive,"SpeedPower",16*C.DiveBoost,C.DiveBoost~=1 and not C.AutoSave)
    patch(Dribble.Rules.Move,"SpeedFactor",1,C.NoDribbleSlowdown)
    patch(Dribble.Rules.Touch,"MinGap",0.01,C.NoDribbleCooldown)
    patch(Dribble.Rules.Touch,"SprintMinGap",0.01,C.NoDribbleCooldown)
    patch(Dribble.Rules.Touch,"KeepReach",1.25*C.Reach,C.BallReach)
    patch(Dribble.Rules.Touch,"ReachSide",C.Reach,C.BallReach)
    patch(Dribble.Rules.Touch,"ReachAlong",1.6*C.Reach,C.BallReach)
    patch(KeeperHands,"CATCH_EASY",1000,C.AlwaysCatch and not(C.AutoSave and C.KeeperMode=="Legit"))
    patch(KeeperHands,"SMOTHER_REACH",1.3*C.CatchReach,C.CatchReach~=1 and not(C.AutoSave and C.KeeperMode=="Legit"))

end
local magnetController=(function()
    local controller={}
    local lastBall,lastCharacter,lastPossession
    local correctionAt,settleUntil,corrections=0,0,0
    local armed=true
    local approach
    local settledPosition
    local function horizontal(v)return Vector3.new(v.X,0,v.Z)end
    local function localOwner(ball,model)
        local possessor=tonumber(ball:GetAttribute("Possessor"))or 0
        return possessor~=0 and possessor==model:GetAttribute("DribbleId")
    end
    function controller.Reset()
        lastBall=nil lastCharacter=nil lastPossession=nil
        correctionAt=0 settleUntil=0 corrections=0 armed=true approach=nil settledPosition=nil
    end
    function controller.Step(position,velocity,r,model,now)
        local ball=Ball.getBall()
        local body=model:GetAttribute("BodyState")
        if not S.Loaded or not C.BallMagnet or not ball or not ball.Parent
            or model:GetAttribute("Role")=="Goalkeeper"or(body and body~="Animated")
            or Window.IsOpen or UIS:GetFocusedTextBox()or DribbleClient.kickState()then
            controller.Reset()return false
        end
        if localOwner(ball,model)then
            armed=false settleUntil=now+.5
            return false
        end
        local possessor=tonumber(ball:GetAttribute("Possessor"))or 0
        if possessor~=0 then
            local enemy
            for _,player in ipairs(Players:GetPlayers())do
                local character=player.Character
                if character and character:GetAttribute("DribbleId")==possessor then enemy=character break end
            end
            if not enemy or enemy:GetAttribute("Role")=="Goalkeeper"
                or enemy:GetAttribute("Team")==model:GetAttribute("Team")then return false end
        end
        local possession=ball:GetAttribute("PossessionId")
        if ball~=lastBall or model~=lastCharacter or possession~=lastPossession then
            lastBall,lastCharacter,lastPossession=ball,model,possession
            corrections=0 armed=true approach=nil settledPosition=nil
        end
        local delta=horizontal(position-r.Position)
        local gap=delta.Magnitude
        local range=math.clamp(tonumber(C.MagnetRange)or 8,3,20)
        if gap>range+1.5 then armed=true corrections=0 approach=nil settledPosition=nil return false end
        if gap>range or gap<.01 then return false end
        local radius=ball:IsA("BasePart")and ball.Size.Y*.5 or Dribble.Rules.BALL_RADIUS or .84
        local rootHeight=tonumber(model:GetAttribute("RootHeight"))or 4.7
        local groundY=r.Position.Y-rootHeight
        local relativeHeight=position.Y-(groundY+radius)
        if relativeHeight>Dribble.Rules.Pickup.MaxHeight or relativeHeight<-.8 then return false end
        velocity=typeof(velocity)=="Vector3"and velocity or Vector3.zero
        local rootVelocity=r.AssemblyLinearVelocity
        if not Dribble.Rules.takeable(velocity,rootVelocity)then return false end
        local direction=approach or delta/gap
        local standOff=math.clamp(radius+.8,1.5,2.4)
        local stopBand=standOff+.45
        if not armed and settledPosition and now>=settleUntil
            and horizontal(position-settledPosition).Magnitude>2.5 and gap>stopBand+1 then
            armed=true corrections=0 approach=nil settledPosition=nil
            direction=delta/gap
        end
        if gap<=stopBand then
            armed=false settleUntil=math.max(settleUntil,now+.35)
            settledPosition=settledPosition or position
            local toward=rootVelocity:Dot(direction)
            if toward>0 then r.AssemblyLinearVelocity=rootVelocity-direction*toward end
            return false
        end
        local maximumCorrections=math.clamp(math.ceil((range-standOff)/8),1,3)
        if now<settleUntil or not armed or corrections>=maximumCorrections
            or now-correctionAt<math.max(.3,C.MagnetCooldown or .8)then return false end
        if not approach then approach=direction end
        local serverNow=workspace:GetServerTimeNow()
        local lead=math.clamp(LP:GetNetworkPing()*.35+1/120,0,.045)
        local source=Ball.getSource()
        local predicted=(source=="free"or source=="released")and Ball.freeSample(serverNow+lead)or position+velocity*lead
        if typeof(predicted)~="Vector3"or horizontal(predicted-position).Magnitude>.8 then predicted=position end
        local desired=Vector3.new(predicted.X,r.Position.Y,predicted.Z)-direction*standOff
        local correction=horizontal(desired-r.Position)
        local along=correction:Dot(direction)
        local maximum=math.max(0,gap-standOff)
        if along<=.2 then return false end
        if along>maximum then correction-=direction*(along-maximum)end
        if correction.Magnitude>8 then correction=correction.Unit*8 end
        if correction.Magnitude<.2 then return false end
        local params=RaycastParams.new()
        params.FilterType=Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances={model,ball}
        params.RespectCanCollide=true
        local obstacle=workspace:Raycast(r.Position,correction,params)
        if obstacle then
            local allowed=math.max(0,obstacle.Distance-.75)
            if allowed<.25 then return false end
            correction=correction.Unit*math.min(correction.Magnitude,allowed)
        end
        local target=r.Position+correction
        local rootFrame=CFrame.lookAt(target,target+direction)
        model:PivotTo(rootFrame*r.CFrame:Inverse()*model:GetPivot())
        local alongVelocity=horizontal(rootVelocity):Dot(direction)
        local lateral=horizontal(rootVelocity)-direction*alongVelocity
        local speed=math.clamp(horizontal(velocity):Dot(direction),0,10)
        local destinationSpeed=direction*speed+lateral*.2+Vector3.new(0,rootVelocity.Y,0)
        local seen={}
        for _,part in ipairs(model:GetDescendants())do
            if part:IsA("BasePart")and not part.Anchored then
                local assembly=part.AssemblyRootPart or part
                if not seen[assembly]then seen[assembly]=true assembly.AssemblyLinearVelocity=destinationSpeed end
            end
        end
        correctionAt=now settleUntil=now+.35 corrections+=1
        if horizontal(position-target).Magnitude<=stopBand then armed=false settledPosition=position end
        return true
    end
    return controller
end)()

local function possessionFollow(position,velocity,r,model,now)
    if not C.StickToBall or model:GetAttribute("Role")=="Goalkeeper"or Window.IsOpen
        or UIS:GetFocusedTextBox()or DribbleClient.kickState()then return end
    local body=model:GetAttribute("BodyState")
    if body and body~="Animated"then return end
    local ball=Ball.getBall()
    if not ball or(tonumber(ball:GetAttribute("Possessor"))or 0)~=0 then return end
    local delta=Vector3.new(position.X-r.Position.X,0,position.Z-r.Position.Z)
    local gap=delta.Magnitude
    if gap>.01 and gap<=C.FollowRange then
        local direction=delta/gap
        local closing=math.max(0,r.AssemblyLinearVelocity:Dot(direction))
        local stopBand=2.3+math.min(1.4,closing*.045)
        if gap>stopBand then
            local strength=math.clamp((gap-stopBand)/4,0,1)
            movementWish=direction*strength movementWishAt=now movementSource="Possession"
        end
    end
end

local followBinding="AxisSoccerPossession"
RS:BindToRenderStep(followBinding,Enum.RenderPriority.Input.Value,function()
    movementWish=nil
    movementSource=nil
    if not S.Loaded then return end
    if UIS:GetFocusedTextBox()then return end
    safe(function()
        local r,model=root()
        if not r then return end
        if Window.IsOpen then return end
        if C.KeeperPosition and model:GetAttribute("Role")=="Goalkeeper"then keeperPositionStep(r,model) return end
        local position=Ball.getPosition()
        if position then possessionFollow(position,Vector3.zero,r,model,os.clock())end
    end)
end)
connect(RS.PreSimulation,function(dt)
    if S.Loaded then safe(keeperController.Assist,dt)end
end)
local elapsed,slow=0,0
connect(RS.Heartbeat,function(dt)
    if not S.Loaded then return end
    safe(function()
        local now=os.clock()
        if S.Shooting then S.Shooting.Observe()end
        local position=Ball.getPosition()
        local r,model=root()
        if position and r then
            local velocity=lastPosition and now>lastAt and (position-lastPosition)/(now-lastAt)or Vector3.zero
            local source=Ball.getSource()
            if source=="free"or source=="released"then
                local freePosition,freeVelocity=Ball.freeState()
                if typeof(freePosition)=="Vector3"and typeof(freeVelocity)=="Vector3"then
                    keeperController.Step(freePosition,freeVelocity,r,model,now)
                else
                    keeperController.Step(position,velocity,r,model,now)
                end
            else
                keeperController.Reset()
            end
            local gap=(position-r.Position).Magnitude
            local freeVelocity=velocity
            if source=="free"or source=="released"then
                local _,observedVelocity=Ball.freeState()
                if typeof(observedVelocity)=="Vector3"then freeVelocity=observedVelocity end
            end
            magnetController.Step(position,freeVelocity,r,model,now)
            if C.AutoScore and not Window.IsOpen and now-lastShot>C.ShotGap
                and shotInRange(r.Position)
                and (DribbleClient.kickState()or gap<7)then
                shootNow()
            end
            lastPosition,lastAt=position,now
        end
        elapsed+=dt slow+=dt
        if elapsed>=0.1 then
            elapsed=0
            tuningStep()
            correction.Enabled=C.ColorCorrection correction.Saturation=C.Saturation correction.Contrast=C.Contrast
            bloom.Enabled=C.Bloom bloom.Intensity=C.BloomIntensity
            sun.Enabled=C.SunRays sun.Intensity=C.SunIntensity
            property(Lighting,"ClockTime",C.ClockTime,C.CustomClock)
            property(Lighting,"FogEnd",100000,C.RemoveFog)
            for _,object in ipairs(Lighting:GetChildren())do if object:IsA("Atmosphere")then property(object,"Density",0,C.RemoveFog)end end
            property(workspace.CurrentCamera,"FieldOfView",C.FOV,C.CustomFOV)
            sky.Parent=C.CustomSky and Lighting or nil
            if C.CustomSky then for _,face in ipairs({"Bk","Dn","Ft","Lf","Rt","Up"})do sky["Skybox"..face]=C["Sky"..face]end end
            attribute(LP,"Coins",C.Coins,C.SpoofCoins)
            attribute(LP,"Ping",C.Ping,C.SpoofPing)
            attribute(LP,"MatchGoals",C.MatchGoals,C.SpoofGoals)
            attribute(LP,"OVR",C.OVR,C.SpoofOVR)
            property(LP,"DisplayName",C.DisplayName,C.SpoofName)
            attribute(LP,"DisplayName",C.DisplayName,C.SpoofName)
            if C.SpoofCareer or C.SpoofOVR then
                local original=attributes[LP]and attributes[LP].Career
                local json=original and original.Value or LP:GetAttribute("Career")or "{}"
                local value=HS:JSONDecode(json)
                if C.SpoofCareer then
                    for _,key in ipairs({"Matches","Goals","Assists","Wins","TimePlayed"})do value[key]=C["Career"..key]end
                    value.Rounds=C.CareerMatches
                end
                if C.SpoofOVR then value.Ratings={C.OVR/10} value.Weights={1} value.Rated=1 value.RatedDiscount=0 value.RatingSum=C.OVR/10 end
                attribute(LP,"Career",HS:JSONEncode(value),true)
                attribute(LP,"Stat_Goals",C.CareerGoals,C.SpoofCareer)
                attribute(LP,"Stat_Assists",C.CareerAssists,C.SpoofCareer)
                attribute(LP,"Stat_TimePlayed",C.CareerTimePlayed,C.SpoofCareer)
            elseif attributes[LP]and attributes[LP].Career then
                for _,key in ipairs({"Career","Stat_Goals","Stat_Assists","Stat_TimePlayed"})do attribute(LP,key,nil,false)end
            end
            local ui=LP.PlayerGui:FindFirstChild("GameUI")
            if ui and ui:FindFirstChild("HighPing")then property(ui.HighPing,"Visible",false,C.HideHighPing)end
            if C.AutoSkipReplays and Replay.playing()then Replay.stopLocal()action("InstantReplaySkip","SkipReplay")end
        end
        if slow>=1 then
            slow=0
            local ui=LP.PlayerGui:FindFirstChild("GameUI")
            if C.AutoTeamSwitch and ui and ui:FindFirstChild("TeamSwitchCard")and visible(ui.TeamSwitchCard)then action("TeamSwitch","Take")end
            if C.AutoJoin and ui and ui:FindFirstChild("Play")then local button=ui.Play:IsA("GuiButton")and ui.Play or ui.Play:FindFirstChildWhichIsA("GuiButton",true)click(button)end
            if C.AutoQuests then
                local data=HS:JSONDecode(LP:GetAttribute("Quests")or "{}")
                for index,quest in ipairs(data.list or {})do if not quest.claimed and quest.n>=quest.goal then Net:Invoke("QuestClaim",index,quest.id)end end
            end
            local blockers=workspace:FindFirstChild("PlayerBlockers")
            if blockers then for _,object in ipairs(blockers:GetDescendants())do
                if object:IsA("BasePart")and object.Name:lower():find("net",1,true)then property(object,"CanCollide",false,C.WalkThroughNets)end
            end end
            for _,object in ipairs(Lighting:GetChildren())do
                if object:IsA("PostEffect")and object~=correction and object~=bloom and object~=sun then property(object,"Enabled",false,C.FPSMode~="Off")end
            end
            property(Lighting,"GlobalShadows",false,C.FPSMode=="Performance"or C.FPSMode=="Maximum")
            if C.FPSMode=="Maximum"then
                for _,object in ipairs(workspace:GetDescendants())do
                    if object:IsA("ParticleEmitter")or object:IsA("Trail")then property(object,"Enabled",false,true)end
                end
            else
                for object,props in pairs(originals)do if props.Enabled and(object:IsA("ParticleEmitter")or object:IsA("Trail"))and object.Parent then property(object,"Enabled",nil,false)end end
            end
        end
    end)
end)
connect(LP.Idled,function()
    if C.AntiAFK then safe(function()local virtual=game:GetService("VirtualUser")virtual:CaptureController()virtual:ClickButton2(Vector2.zero)end)end
end)
connect(LP.CharacterAdded,function()
    S.AutoChargePending=nil
    S.ShotPlan=nil
    magnetController.Reset()
    keeperController.Reset()
    S.KeeperBody=nil
    lastPosition=nil
    task.delay(1,function()
        if not S.Loaded then return end
        if C.CosmeticOverride then safe(applyCosmetics)end
        safe(updatePreview)
    end)
end)
local nativeUnload=Library.Unload
function S.Unload()
    if not S.Loaded then return end
    if S.AutoChargePending then action("Kick","KickShoot",true)S.AutoChargePending=nil end
    S.Loaded=false
    magnetController.Reset()
    keeperController.Reset()
    movementWish=nil
    RS:UnbindFromRenderStep(followBinding)
    if Library.FlushAutosave then safe(function()Library:FlushAutosave()end)end
    for _,connection in ipairs(S.Connections)do connection:Disconnect()end
    for _,record in ipairs(S.Hooks)do safe(function()if restorefunction then restorefunction(record.Function)else hookfunction(record.Function,record.Original)end end)end
    for object,values in pairs(patches)do for key,entry in pairs(values)do pcall(function()object[key]=entry.Value end)end end
    for object,values in pairs(originals)do if object.Parent then for key,entry in pairs(values)do pcall(function()object[key]=entry.Value end)end end end
    for object,values in pairs(attributes)do if object.Parent then for key,entry in pairs(values)do pcall(function()object:SetAttribute(key,entry.Value)end)end end end
    local models={}for model in pairs(worn)do models[#models+1]=model end
    for _,model in ipairs(models)do restoreCosmetics(model)end
    for _,object in ipairs(instances)do object:Destroy()end
    if C.UnlockFPS and setfpscap then setfpscap(60)end
    nativeUnload(Library)
end
function Library:Unload()S.Unload()end
Library:CreateSettingsPage(Window)
Window:Init()
if Library.StartAutosave then safe(function()Library:StartAutosave()end)end
safe(updatePreview)
end)
if not ok then local s=getgenv().AxisSoccer if s and s.Unload then pcall(s.Unload)end end
