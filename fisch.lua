pcall(function()
    if type(isfile)=="function" and type(delfile)=="function" and isfile("Axis/Fisch/autoload.lua") then
        delfile("Axis/Fisch/autoload.lua")
    end
end)
pcall(function()
local Sources={UI=[=[
return function(context)
    local config=context.Config
    local state=context.State
    local loadLibrary=loadstring(game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua"))
    if not loadLibrary then return end
    local library=loadLibrary()
    local playerGui=game:GetService("Players").LocalPlayer.PlayerGui
    library.Holder.Instance.Parent=playerGui
    library.UnusedHolder.Instance.Parent=playerGui
    local function disableAutomaticTranslation(object)
        if object:IsA("GuiBase2d") then
            object.AutoLocalize=false
        end
    end
    for _,holder in ipairs({library.Holder.Instance,library.UnusedHolder.Instance}) do
        disableAutomaticTranslation(holder)
        for _,object in ipairs(holder:GetDescendants()) do
            disableAutomaticTranslation(object)
        end
        context.Connect(holder.DescendantAdded,disableAutomaticTranslation)
    end
    local logo=library.Folders.Assets.."/axis-logo.png"
    if not isfile(logo) then writefile(logo,game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/assets/axis-logo.png"))end
    library.MenuKeybind=tostring(Enum.KeyCode.RightShift)
    local window=library:Window({Name="",SubName="",Logo=getcustomasset(logo),Wordmark=true})
    local controls={}
    local bindsReady=false
    local function compactRow(section,name)
        local row=Instance.new("Frame")
        row.Name="AxisCompactRow"
        row.BackgroundTransparency=1
        row.Size=UDim2.new(1,0,0,22)
        row.Parent=section.Items.Content.Instance
        local text=Instance.new("TextLabel")
        text.BackgroundTransparency=1
        text.Size=UDim2.new(1,-28,1,0)
        text.TextXAlignment=Enum.TextXAlignment.Left
        text.Text=name
        text.TextSize=14
        text.FontFace=library.Font
        text.TextColor3=library.Theme.Text
        text.TextTransparency=.3
        text.Parent=row
        return row
    end
    local function toggle(section,key,name,bind)
        local control=section:Toggle({Name=name,Flag="FS_"..key,Default=config[key],Callback=function(value)context.Set(key,value)end})
        controls[key]=control
        if bind then control:GetBind({Flag="FS_"..key.."Key",Default=Enum.KeyCode.Backspace,Mode="Toggle",Callback=function(value)
            if bindsReady and not library.RestoringConfig then control:Set(value)end
        end})end
        return control
    end
    local function slider(section,key,name,minimum,maximum,step)
        controls[key]=section:Slider({Name=name,Flag="FS_"..key,Default=config[key],Min=minimum,Max=maximum,Decimals=step or 1,Callback=function(value)context.Set(key,value)end})
    end
    local function dropdown(section,key,name,items,multi)
        local control=section:Dropdown({Name=name,Flag="FS_"..key,Default=config[key],Items=items,Multi=multi or false,Callback=function(value)
            context.Set(key,multi and table.clone(value) or value)
        end})
        controls[key]=control
        return control
    end
    local fishing=window:Page({Name="Fishing",Icon="112148279212860"})
    local automation=fishing:Section({Name="Automation",Side=1})
    toggle(automation,"AutoFish","Auto fish",true)
    dropdown(automation,"CastTiming","Cast timing",{"Random","Perfect"})
    toggle(automation,"AutoBait","Auto bait",true)
    dropdown(automation,"Bait","Bait",context.BaitNames())
    toggle(automation,"AutoShake","Auto shake",true)
    toggle(automation,"AutoReel","Auto reel",true)
    dropdown(automation,"ReelMode","Reel mode",{"Legit","Blatant","Rage"})
    local status=fishing:Section({Name="Status",Side=2})
    local statusLine=status:Label("Idle")
    local shakeLine=status:Label("Shake: idle")
    local reelLine=status:Label("Reel: idle")
    local catchLine=status:Label("Catches: 0")
    local earningsLine=status:Label("Earnings: 0")
    local lastCatchLine=status:Label("Last catch: none")
    local baitLine=status:Label("Bait: none")
    local sell=fishing:Section({Name="Selling",Side=2})
    toggle(sell,"AutoSell","Auto sell",true)
    dropdown(sell,"SellMode","Sell mode",{"Everything","Selected"})
    toggle(sell,"KeepShiny","Keep shiny and sparkling")
    toggle(sell,"ProtectFavourites","Protect favourites")
    local search=sell:Textbox({Name="Search fish",Flag="FS_FishSearch",Default="",Placeholder="Fish name",Finished=false,Callback=function(value)
        context.Set("FishSearch",value)
    end})
    local selected=dropdown(sell,"SelectedFish","Selected fish",context.FishNames(""),true)
    dropdown(sell,"Rarities","Rarities",context.RarityNames(),true)
    local preview=sell:Label("Sale preview: 0 fish")
    local lastSale=sell:Label("Last sale: none")
    sell:Button({Name="Sell now",Callback=context.SellNow})
    local visuals=window:Page({Name="Visuals",Icon="100033680381365"})
    local atmosphere=visuals:Section({Name="Lighting",Side=1})
    local colorToggle=toggle(atmosphere,"ColorCorrection","Color correction")
    local lightingToggle=toggle(atmosphere,"CustomLighting","Custom lighting")
    controls.LightingColor=lightingToggle:Colorpicker({Flag="FS_LightingColor",Default=config.LightingColor,Alpha=1,Callback=function(value)context.Set("LightingColor",value)end})
    local fogToggle=toggle(atmosphere,"Fog","Fog")
    controls.FogColor=fogToggle:Colorpicker({Flag="FS_FogColor",Default=config.FogColor,Alpha=1,Callback=function(value)context.Set("FogColor",value)end})
    controls.SkyTint=colorToggle:Colorpicker({Flag="FS_SkyTint",Default=config.SkyTint,Alpha=1,Callback=function(value)context.Set("SkyTint",value)end})
    toggle(atmosphere,"Skybox","Skybox")
    toggle(atmosphere,"Weather","Weather")
    toggle(atmosphere,"Lightning","Lightning")
    toggle(atmosphere,"DepthOfField","Depth of field")
    local utility=window:Page({Name="Utility",Icon="112148279212860"})
    local travel=utility:Section({Name="Islands",Side=1})
    local islands=dropdown(travel,"Island","Island",context.IslandNames())
    travel:Button({Name="Teleport",Callback=context.TeleportIsland})
    travel:Button({Name="Refresh islands",Callback=function() islands:Refresh(context.IslandNames(),config.Island) end})
    local people=utility:Section({Name="Players",Side=2})
    local playerList=dropdown(people,"TeleportPlayer","Player",context.PlayerNames())
    people:Button({Name="Teleport",Callback=context.TeleportPlayer})
    people:Button({Name="Refresh players",Callback=function() playerList:Refresh(context.PlayerNames(),config.TeleportPlayer) end})
    local positions=utility:Section({Name="Positions",Side=1})
    positions:Button({Name="Go back",Callback=context.ReturnPosition})
    positions:Button({Name="Save position",Callback=context.SavePosition})
    positions:Button({Name="Teleport to saved",Callback=context.TeleportSaved})
    local travelStatus=positions:Label("Ready")
    local general=utility:Section({Name="General",Side=2})
    toggle(general,"AntiAFK","Anti AFK")
    local shopping=fishing:Section({Name="Daily shop",Side=1})
    toggle(shopping,"AutoBuy","Auto buy",true)
    local buyList=dropdown(shopping,"BuyItem","Item",context.ShopNames())
    shopping:Button({Name="Refresh items",Callback=function() buyList:Refresh(context.ShopNames(),config.BuyItem) end})
    slider(shopping,"BuyInterval","Interval",3,60,1)
    slider(shopping,"BuyLimit","Purchase limit",1,100,1)
    slider(shopping,"KeepCoins","Keep coins",0,100000,100)
    shopping:Button({Name="Buy now",Callback=context.BuyNow})
    shopping:Button({Name="Reset limit",Callback=context.ResetPurchases})
    local buyStatus=shopping:Label("Open the daily shop to load items")
    local nativeToggle=library.Sections.Toggle
    library.Sections.Toggle=function(section,data)
        if data and data.Flag=="WatermarkToggle" then return end
        return nativeToggle(section,data)
    end
    local settingsCreated=pcall(library.CreateSettingsPage,library,window)
    library.Sections.Toggle=nativeToggle
    if not settingsCreated then return end
    local logs=utility:Section({Name="Catch logs",Side=2})
    local logsToggle=toggle(logs,"WebhookEnabled","Enabled")
    controls.WebhookColor=logsToggle:Colorpicker({Flag="FS_WebhookColor",Default=config.WebhookColor,Alpha=1,
        Callback=function(value)context.Set("WebhookColor",value)end})
    logs:Textbox({Name="Webhook URL",Flag="FS_WebhookURL",Default=config.WebhookURL,
        Placeholder="Discord webhook URL",Finished=true,Callback=function(value)context.Set("WebhookURL",value)end})
    dropdown(logs,"WebhookRarities","Rarities",context.RarityNames(),true)
    slider(logs,"WebhookMinWeight","Min weight",0,10000,1)
    toggle(logs,"WebhookSpecialOnly","Special catches only")
    toggle(logs,"WebhookImages","Fish images")
    local webhookStatus=logs:Label("Disabled")
    local session=window.Pages[#window.Pages]:Section({Name="Session",Side=2})
    local menuKey
    menuKey=session:Keybind({Name="Menu key",Flag="FS_MenuKey",Default=Enum.KeyCode.RightShift,Mode="Toggle",Callback=function()
        if bindsReady then
            local key=menuKey:Get()
            if key and key~=tostring(Enum.KeyCode.Backspace)then library.MenuKeybind=key end
        end
    end})
    local menuRow=compactRow(session,"Menu key")
    local gear=Instance.new("ImageButton")
    gear.BackgroundTransparency=1
    gear.Image="rbxassetid://122669828593160"
    gear.ImageColor3=library.Theme.Text
    gear.ImageTransparency=.3
    gear.Size=UDim2.fromOffset(18,18)
    gear.AnchorPoint=Vector2.new(1,.5)
    gear.Position=UDim2.new(1,0,.5,0)
    gear.Parent=menuRow
    local modal=Instance.new("ScreenGui")
    modal.Name="AxisMenuBindPopup"
    modal.ResetOnSpawn=false
    modal.Enabled=false
    modal.IgnoreGuiInset=library.Holder.Instance.IgnoreGuiInset
    modal.DisplayOrder=library.Holder.Instance.DisplayOrder+100
    modal.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    modal.Parent=playerGui
    table.insert(library.ToClean,modal)
    local backdrop=Instance.new("TextButton")
    backdrop.Size=UDim2.fromScale(1,1)
    backdrop.BackgroundTransparency=1
    backdrop.Text=""
    backdrop.Active=true
    backdrop.Modal=false
    backdrop.Parent=modal
    local popup=Instance.new("Frame")
    popup.Name="MenuBindPopup"
    popup.Size=UDim2.fromOffset(240,82)
    popup.BackgroundColor3=library.Theme["Section Background 2"]
    popup.BorderSizePixel=0
    popup.Active=true
    popup.ZIndex=2
    popup.Parent=modal
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,5)
    corner.Parent=popup
    menuKey.Items.Label.Instance.Parent=popup
    menuKey.Items.Label.Instance.Position=UDim2.fromOffset(10,8)
    menuKey.Items.Label.Instance.Size=UDim2.new(1,-20,1,-16)
    menuKey.Items.Text.Instance.Visible=false
    menuKey.Items.Modes.Instance.Size=UDim2.new(1,0,0,25)
    menuKey.Items.SubElements.Instance.Position=UDim2.fromOffset(0,34)
    local blocked={}
    local function closeMenuBind()
        modal.Enabled=false
        backdrop.Modal=false
        for object,value in pairs(blocked) do if object.Parent then object.Interactable=value end end
        table.clear(blocked)
    end
    context.Connect(backdrop.MouseButton1Click,closeMenuBind)
    context.Connect(gear.MouseButton1Click,function()
        if modal.Enabled then closeMenuBind() return end
        for _,frame in pairs(library.OpenFrames) do frame:SetOpen(false) end
        local point=gear.AbsolutePosition
        local size=library.Holder.Instance.AbsoluteSize
        popup.Position=UDim2.fromOffset(math.clamp(point.X-222,8,math.max(8,size.X-248)),
            math.clamp(point.Y+24,8,math.max(8,size.Y-90)))
        for _,object in ipairs(library.Holder.Instance:GetDescendants()) do
            if object:IsA("GuiButton") or object:IsA("TextBox") then
                blocked[object]=object.Interactable
                object.Interactable=false
            end
        end
        modal.Enabled=true
        backdrop.Modal=true
        library.OpenFrames.MenuKey={SetOpen=function(_,value) if not value then closeMenuBind() end end}
    end)
    context.Connect(game:GetService("RunService").Heartbeat,function()
        if modal.Enabled and not window.IsOpen then closeMenuBind() end
    end)
    toggle(session,"LoadOnTeleport","Load on teleport")
    toggle(session,"SilentMode","Silent mode")
    session:Button({Name="Unload script",Callback=context.Unload})
    local nativeUnload=library.Unload
    local unloading=false
    function library:Unload()
        if unloading then return end
        unloading=true
        if state.Alive then context.Unload() end
        nativeUnload(self)
    end
    window:Init()
    bindsReady=true
    local restored=menuKey:Get()
    if restored and restored~=tostring(Enum.KeyCode.Backspace)then library.MenuKeybind=restored end
    local elapsed=0
    context.Connect(game:GetService("RunService").Heartbeat,function(dt)
        elapsed+=dt
        if elapsed<.3 then return end
        elapsed=0
        webhookStatus:SetText(config.WebhookEnabled and (state.WebhookStatus or "Waiting for catches") or "Disabled")
        travelStatus:SetText(state.TravelStatus or "Ready")
        buyStatus:SetText(state.BuyStatus or "Open the daily shop to load items")
        statusLine:SetText(state.Status or "Idle")
        shakeLine:SetText("Shake: "..(state.ShakeStatus or "idle"))
        reelLine:SetText("Reel: "..(state.ReelStatus or "idle"))
        catchLine:SetText("Catches: "..tostring(state.Catches or 0))
        earningsLine:SetText(string.format("Earnings: %s total / %s hourly",tostring(state.Earnings or 0),tostring(state.HourlyEarnings or 0)))
        lastCatchLine:SetText("Last catch: "..(state.LastCatch or "none"))
        baitLine:SetText("Bait: "..(state.Bait or "none"))
        preview:SetText("Sale preview: "..tostring(state.SaleCount or 0).." fish")
        lastSale:SetText("Last sale: "..(state.LastSale or "none"))
    end)
    return {Library=library,Window=window,Controls=controls,Search=search,Selected=selected}
end
]=]}
local env=getgenv and getgenv() or _G
if env.AxisFisch and env.AxisFisch.Unload then env.AxisFisch.Unload()end
if game.GameId~=5750914919 then return end

local players=game:GetService("Players")
local runService=game:GetService("RunService")
local lighting=game:GetService("Lighting")
local storage=game:GetService("ReplicatedStorage")
local localPlayer=players.LocalPlayer
local controller=storage.client.legacyControllers
local data=require(controller.DataController)
local reelController=require(controller.ReelController)
local shakeController=require(controller.LureShakeController)
local legacyData=require(storage.client.modules.legacyLocalPlayerData)
local libraryData=require(storage.shared.modules.library)
local net=require(storage.packages.Net)
local biteTypes=require(storage.shared.modules.fishing.BiteTypes)
local baitRemote=net:RemoteEvent("Bait/Equip")
local state={Alive=true,Connections={},Errors={},Status="Idle",ShakeStatus="idle",ReelStatus="idle",Catches=0,Earnings=0,HourlyEarnings=0,Started=os.clock(),Seen={},Income={}}
local config={
    AutoFish=false,CastTiming="Perfect",AutoBait=false,Bait="Auto",AutoShake=false,AutoReel=false,ReelMode="Blatant",
    AutoBuy=false,BuyItem="None",BuyInterval=5,BuyLimit=1,KeepCoins=1000,Island="Moosewood",TeleportPlayer="None",AntiAFK=false,
    AutoSell=false,SellMode="Everything",KeepShiny=true,ProtectFavourites=true,FishSearch="",
    SelectedFish={},Rarities={},ColorCorrection=false,CustomLighting=false,Fog=false,
    LightingColor=Color3.new(1,1,1),FogColor=Color3.fromRGB(100,150,190),SkyTint=Color3.fromRGB(255,255,255),
    Skybox=true,Weather=true,Lightning=true,DepthOfField=false,LoadOnTeleport=false,SilentMode=false,
    WebhookEnabled=false,WebhookURL="",WebhookRarities={},WebhookMinWeight=0,
    WebhookSpecialOnly=false,WebhookImages=true,WebhookColor=Color3.fromRGB(65,155,255),
}
local previous=env.AxisFisch and env.AxisFisch.Config
if previous then for key,value in pairs(previous)do if typeof(value)==typeof(config[key])then config[key]=value end end end
local library,window,ui
local function queue_teleport()
    if not config.LoadOnTeleport then return end
    local queue=queue_on_teleport or (syn and syn.queue_on_teleport)
    if queue then
        queue('pcall(function()local run=loadstring(game:HttpGet("https://raw.githubusercontent.com/smcpresezzi/xd/main/fisch.lua"))if run then run()end end)')
    end
end
local function set_external(key,value)
    if ui and ui.Controls and ui.Controls[key] and ui.Controls[key].Set then ui.Controls[key]:Set(value)
    else config[key]=value end
end
local update_visuals
local lastAction={}
local function ready(name,interval)
    local now=os.clock()
    if now-(lastAction[name] or 0)<interval then return false end
    lastAction[name]=now
    return true
end
local function connect(signal,callback)
    local connection=signal:Connect(callback)
    state.Connections[#state.Connections+1]=connection
    return connection
end
local function guarded(name,callback,...)
    local result=table.pack(pcall(callback,...))
    if not result[1]then state.Errors[name]=tostring(result[2])return nil end
    state.Errors[name]=nil
    return table.unpack(result,2,result.n)
end
local function stats()
    local folder=legacyData.fetch()
    return folder and folder:FindFirstChild("Stats")
end
local function rod()
    local character=localPlayer.Character
    if not character then return nil end
    for _,tool in ipairs(character:GetChildren())do
        if tool:IsA("Tool") and tool:FindFirstChild("rodClient") and tool:FindFirstChild("values")then return tool end
    end
    return nil
end
local function selected_bait()
    local folder=stats()
    local bait=folder and folder:FindFirstChild("bait")
    if not bait then return nil end
    if config.Bait~="Auto" then
        local value=bait:FindFirstChild("bait_"..config.Bait)
        return value and value.Value>0 and config.Bait or nil
    end
    local best
    for _,value in ipairs(bait:GetChildren())do
        if value:IsA("NumberValue") and value.Name:sub(1,5)=="bait_" and value.Value>0 then
            local name=value.Name:sub(6)
            if libraryData.bait[name] and (not best or value.Value>best.Count)then best={Name=name,Count=value.Value}end
        end
    end
    return best and best.Name
end
local function bait_names()
    local names={"Auto"}
    for name in pairs(libraryData.bait)do if type(name)=="string"then names[#names+1]=name end end
    table.sort(names,function(a,b)if a=="Auto"then return b~="Auto"end if b=="Auto"then return false end return a<b end)
    return names
end
local function fish_names(query)
    local names={}
    query=tostring(query or ""):lower()
    for name in pairs(libraryData.fish)do
        if type(name)=="string" and (query=="" or name:lower():find(query,1,true))then names[#names+1]=name end
    end
    table.sort(names)
    while #names>120 do table.remove(names)end
    return names
end
local function rarity_names()
    local names={}
    for name in pairs(libraryData.rarities.Rarities)do if type(name)=="string"then names[#names+1]=name end end
    table.sort(names)
    return names
end
local function inventory()
    local replicator=data.InventoryReplicator
    return replicator and replicator.Data and replicator.Data.Inventory or {}
end
local function protected(item)
    local sub=item.sub or {}
    if config.ProtectFavourites and (item.favourite or item.favorite or sub.Favourite or sub.Favorite)then return true end
    if config.KeepShiny then
        local mutation=tostring(sub.Mutation or sub.mutation or ""):lower()
        if mutation:find("shiny",1,true) or mutation:find("sparkling",1,true) or sub.Shiny or sub.Sparkling then return true end
    end
    return false
end
local function sale_items()
    local out={}
    for id,item in pairs(inventory())do
        local fish=libraryData.fish[item.name]
        if fish and not protected(item) then
            local allowed=config.SellMode=="Everything"
                or table.find(config.SelectedFish,item.name)~=nil
                or table.find(config.Rarities,fish.Rarity)~=nil
            if allowed then out[#out+1]={Id=id,Name=item.name,Price=fish.Price or 0,Count=item.sub and item.sub.Stack or 1}end
        end
    end
    table.sort(out,function(a,b)return a.Name<b.Name end)
    return out
end
local function sell_now()
    if state.Selling then return end
    local items=sale_items()
    if #items==0 then state.LastSale="nothing selected" return end
    state.Selling=true
    state.Status="Selling"
    if config.SellMode=="Everything" and not config.KeepShiny and not config.ProtectFavourites then
        local result=guarded("sell all",function()return storage.events.SellAll:InvokeServer()end)
        state.LastSale=result and tostring(result)or "request sent"
        state.Selling=false
        return
    end
    local sold=0
    for _,item in ipairs(items)do
        local result=guarded("sell item",function()return storage.events.Sell:InvokeServer(item.Id)end)
        if result~=nil and result~=false then sold+=1 end
        task.wait(.12)
    end
    state.LastSale=tostring(sold).." of "..tostring(#items).." selected"
    state.Selling=false
end
local function cast_input(pressed,tool)
    local scriptObject=tool and tool:FindFirstChild("rodClient")
    local mobile=localPlayer.PlayerGui:FindFirstChild("FishButtonMobile")
    local frame=mobile and mobile:FindFirstChild("Frame")
    local button=frame and frame:FindFirstChild("button")
    if not button or not scriptObject or not getconnections then return false end
    local callbacks={}
    local signal=pressed and button.InputBegan or button.InputEnded
    for _,connection in ipairs(getconnections(signal)) do
        local callback=connection.Function
        if callback then
            local ok,environment=pcall(getfenv,callback)
            if ok and environment.script==scriptObject then callbacks[#callbacks+1]=callback end
        end
    end
    if #callbacks==0 then return false end
    local input={UserInputType=Enum.UserInputType.MouseButton1,KeyCode=Enum.KeyCode.Unknown,
        UserInputState=pressed and Enum.UserInputState.Begin or Enum.UserInputState.End}
    if pressed then state.CastTool=tool end
    for _,callback in ipairs(callbacks) do
        if pressed then
            task.spawn(function()
                local ok,message=pcall(callback,input)
                if not ok then state.Errors.CastInput=tostring(message) end
            end)
        else
            local ok,message=pcall(callback,input)
            if not ok then state.Errors.CastInput=tostring(message) end
        end
    end
    if not pressed then state.CastTool=nil end
    return true
end
local function reel_input(pressed)
    local reel=reelController.ActiveReel
    local movement=reel and reel.core and reel.core.rod
    if not movement or movement.Disabled then return false end
    local callback=pressed and movement.InputBegan or movement.InputEnded
    if type(callback)~="function" then return false end
    callback(movement)
    state.ReelInput=pressed and movement or nil
    return true
end
local function release_reel()
    local movement=state.ReelInput
    state.ReelInput=nil
    state.ReelHeld=false
    if movement and type(movement.InputEnded)=="function" then pcall(movement.InputEnded,movement) end
end
local function island_names()
    local names={}
    local world=workspace:FindFirstChild("world")
    local spawns=world and world:FindFirstChild("spawns")
    if spawns then
        for _,folder in ipairs(spawns:GetChildren()) do
            if folder:IsA("Folder") and folder.Name~="TpSpots" and folder.Name~="TeleportDelay" then
                if folder:FindFirstChildWhichIsA("BasePart",true) then names[#names+1]=folder.Name end
            end
        end
    end
    table.sort(names)
    return names
end
local function player_names()
    local names={"None"}
    for _,player in ipairs(players:GetPlayers()) do
        if player~=localPlayer then names[#names+1]=player.Name end
    end
    table.sort(names)
    return names
end
local function teleport_to(destination,remember)
    local character=localPlayer.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health<=0 then return end
    if state.CastHeld or state.ReelHeld or reelController.ActiveReel then
        state.TravelStatus="Finish fishing before teleporting"
        return
    end
    if humanoid.SeatPart then
        state.TravelStatus="Leave your seat before teleporting"
        return
    end
    if remember then state.ReturnPosition=root.CFrame end
    character:PivotTo(destination * root.CFrame:ToObjectSpace(character:GetPivot()))
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    state.TravelStatus="Teleported"
end
local function teleport_island()
    local world=workspace:FindFirstChild("world")
    local spawns=world and world:FindFirstChild("spawns")
    local folder=spawns and spawns:FindFirstChild(config.Island)
    local part=folder and folder:FindFirstChildWhichIsA("BasePart",true)
    if part then teleport_to(part.CFrame+Vector3.new(0,4,0),true)
    else state.TravelStatus="Destination unavailable" end
end
local function teleport_player()
    local player=players:FindFirstChild(config.TeleportPlayer)
    local root=player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root then teleport_to(root.CFrame*CFrame.new(4,1,0),true)
    else state.TravelStatus="Player unavailable" end
end
local function shop_entries()
    local entries={}
    local hud=localPlayer.PlayerGui:FindFirstChild("hud")
    local safezone=hud and hud:FindFirstChild("safezone")
    local shop=safezone and safezone:FindFirstChild("DailyShop")
    local list=shop and shop:FindFirstChild("List")
    if list then
        for _,entry in ipairs(list:GetChildren()) do
            local label=entry:FindFirstChild("Label")
            local buy=entry:FindFirstChild("BuyButton")
            local priceLabel=buy and buy:FindFirstChild("Label")
            local sold=entry:FindFirstChild("SoldOut")
            if label and label:IsA("TextLabel") and priceLabel and priceLabel:IsA("TextLabel") and entry:IsA("GuiObject") and entry.Visible then
                local price=priceLabel.Text:match("^C%$(.*)")
                price=price and tonumber((price:gsub(",","")))
                if price and not (sold and sold.Visible) then
                    local name=label.Text.." ["..entry.Name.."]"
                    entries[name]={Id=entry.Name,Price=price}
                end
            end
        end
    end
    return entries
end
local function shop_names()
    local names={"None"}
    for name in pairs(shop_entries()) do names[#names+1]=name end
    table.sort(names)
    return names
end
local function buy_now()
    if state.BuyBusy then return end
    local item=shop_entries()[config.BuyItem]
    if not item then state.BuyStatus="Open the daily shop and refresh items" return end
    local coins=stats() and stats():FindFirstChild("coins")
    if not coins or coins.Value-item.Price<config.KeepCoins then state.BuyStatus="Coin reserve reached" return end
    if (state.Purchases or 0)>=config.BuyLimit then state.BuyStatus="Purchase limit reached" return end
    state.BuyBusy=true
    state.BuyStatus="Buying"
    local before=coins.Value
    task.spawn(function()
        local ok,message=pcall(function()
            net:RemoteEvent("DailyShop/Purchase"):FireServer(item.Id)
            local started=os.clock()
            repeat task.wait(.1) until not state.Alive or coins.Value~=before or os.clock()-started>=3
        end)
        if state.Alive then
            if ok and coins.Value<=before-item.Price then
                state.Purchases=(state.Purchases or 0)+1
                state.BuyStatus="Bought "..tostring(state.Purchases).." / "..tostring(config.BuyLimit)
            else
                state.BuyStatus="Purchase not confirmed"
                if not ok then state.Errors.Buy=tostring(message) end
                config.AutoBuy=false
                if ui and ui.Controls.AutoBuy then ui.Controls.AutoBuy:Set(false) end
            end
        end
        state.BuyBusy=false
    end)
end
local function set_config(key,value)
    config[key]=value
    if key=="BuyItem" then state.Purchases=0 end
    if key=="CastTiming" and value~="Random" and value~="Perfect" then config.CastTiming="Perfect" end
    if key=="AutoFish" and not value and state.CastHeld then
        state.CastHeld=false
        cast_input(false,state.CastTool)
    end
    if key=="AutoReel" and not value then state.RageRejects=0 state.RageAttempt=nil end
    if key=="FishSearch" and ui and ui.Selected then
        ui.Selected:Refresh(fish_names(value),config.SelectedFish)
    end
    if update_visuals and table.find({"ColorCorrection","CustomLighting","Fog","FogColor","SkyTint","LightingColor","Skybox","Weather","Lightning","DepthOfField"},key)then
        update_visuals()
    end
end
local original={FogEnd=lighting.FogEnd,FogColor=lighting.FogColor,Ambient=lighting.Ambient,OutdoorAmbient=lighting.OutdoorAmbient,Brightness=lighting.Brightness}
local atmosphere=lighting:FindFirstChildOfClass("Atmosphere")
if atmosphere then original.AtmosphereColor=atmosphere.Color original.AtmosphereDensity=atmosphere.Density end
local colorEffect=Instance.new("ColorCorrectionEffect")
colorEffect.Name="AxisFischColor"
colorEffect.Enabled=false
colorEffect.Parent=lighting
local depthEffect=Instance.new("DepthOfFieldEffect")
depthEffect.Name="AxisFischDepth"
depthEffect.Enabled=false
depthEffect.Parent=lighting
local hiddenSky={}
local weatherFolder=workspace:FindFirstChild("world") and workspace.world:FindFirstChild("weather")
local weatherOriginal=setmetatable({}, {__mode="k"})
local function weather_visible(object)
    if not weatherFolder or not object:IsDescendantOf(weatherFolder)then return end
    local name=object.Name:lower()
    local visible=config.Weather and (config.Lightning or not name:find("lightning",1,true))
    if object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail")then
        if weatherOriginal[object]==nil then weatherOriginal[object]=object.Enabled end
        object.Enabled=visible and weatherOriginal[object] or false
    elseif object:IsA("BasePart")then
        if weatherOriginal[object]==nil then weatherOriginal[object]=object.Transparency end
        object.Transparency=visible and weatherOriginal[object] or 1
    end
end
update_visuals=function()
    colorEffect.Enabled=config.ColorCorrection
    colorEffect.TintColor=config.SkyTint
    colorEffect.Saturation=.12
    depthEffect.Enabled=config.DepthOfField
    depthEffect.FarIntensity=.4
    depthEffect.FocusDistance=65
    depthEffect.InFocusRadius=40
    lighting.FogEnd=config.Fog and 500 or original.FogEnd
    lighting.FogColor=config.Fog and config.FogColor or original.FogColor
    lighting.Ambient=config.CustomLighting and config.LightingColor or original.Ambient
    lighting.OutdoorAmbient=config.CustomLighting and config.LightingColor or original.OutdoorAmbient
    lighting.Brightness=config.CustomLighting and 2 or original.Brightness
    if atmosphere then
        atmosphere.Color=config.SkyTint==Color3.new(1,1,1) and original.AtmosphereColor or config.SkyTint
        atmosphere.Density=config.Fog and .55 or original.AtmosphereDensity
    end
    if config.Skybox then
        for sky in pairs(hiddenSky)do if sky.Parent==nil then sky.Parent=lighting end hiddenSky[sky]=nil end
    else
        for _,sky in ipairs(lighting:GetChildren())do if sky:IsA("Sky")then hiddenSky[sky]=true sky.Parent=nil end end
    end
    if weatherFolder then
        for _,object in ipairs(weatherFolder:GetDescendants())do weather_visible(object)end
    end
end
local httpService=game:GetService("HttpService")
local httpRequest=request or http_request or (syn and syn.request)
local webhookQueue={}
local thumbnailCache={}
local pendingCatches={}
local webhookBusy=false
local nextWebhook=0
local catchConnection
local function webhook_endpoint()
    local url=tostring(config.WebhookURL or ""):match("^%s*(.-)%s*$")
    if url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+$")
        or url:match("^https://discordapp%.com/api/webhooks/%d+/[%w_%-]+$") then return url end
end
local function fish_image(fish)
    local icon=tostring(fish.Icon or "")
    local id=icon:match("rbxassetid://(%d+)") or icon:match("[?&]id=(%d+)")
    if not id then return end
    local cached=thumbnailCache[id]
    if cached then return cached end
    local body=game:HttpGet("https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false")
    local result=httpService:JSONDecode(body)
    local image=result.data and result.data[1]
    if image and image.state=="Completed" and type(image.imageUrl)=="string" then
        thumbnailCache[id]=image.imageUrl
        return image.imageUrl
    end
end
local function webhook_payload(item,count)
    local fish=libraryData.fish[item.name]
    if not fish then return end
    local sub=item.sub or {}
    local weight=tonumber(sub.Weight) or 0
    local mutation=tostring(sub.Mutation or sub.mutation or "Normal")
    local fields={
        {name="Rarity",value=tostring(fish.Rarity or "Unknown"),inline=true},
        {name="Weight",value=string.format("%.2f kg",weight),inline=true},
        {name="Quantity",value=tostring(count),inline=true},
        {name="Mutation",value=mutation,inline=true},
    }
    if sub.Shiny then fields[#fields+1]={name="Shiny",value="Yes",inline=true} end
    if sub.Sparkling then fields[#fields+1]={name="Sparkling",value="Yes",inline=true} end
    local color=config.WebhookColor
    local embed={title=tostring(item.name):sub(1,256),description="New catch",fields=fields,
        color=math.floor(color.R*255)*65536+math.floor(color.G*255)*256+math.floor(color.B*255),
        timestamp=DateTime.now():ToIsoDate(),footer={text="Axis Fisch"}}
    if config.WebhookImages then
        local ok,image=pcall(fish_image,fish)
        if ok and image then embed.thumbnail={url=image} end
    end
    return {username="Axis Fisch",allowed_mentions={parse={}},embeds={embed}}
end
local function queue_catch(item,count)
    if not config.WebhookEnabled then return end
    local pending=pendingCatches[item.name]
    if not pending or pending.Expires<os.clock() then return end
    pendingCatches[item.name]=nil
    local fish=libraryData.fish[item.name]
    local sub=item.sub or {}
    if sub.CaughtBy and tonumber(sub.CaughtBy)~=localPlayer.UserId then return end
    if #config.WebhookRarities>0 and not table.find(config.WebhookRarities,fish.Rarity) then return end
    if (tonumber(sub.Weight) or 0)<config.WebhookMinWeight then return end
    local mutation=tostring(sub.Mutation or sub.mutation or "Normal")
    if config.WebhookSpecialOnly and not sub.Shiny and not sub.Sparkling and mutation=="Normal" then return end
    if #webhookQueue>=100 then state.WebhookStatus="Log queue full" return end
    webhookQueue[#webhookQueue+1]={Item={name=item.name,sub=table.clone(sub)},Count=count,Attempts=0}
    state.WebhookStatus="Queued "..tostring(#webhookQueue)
end
local function watch_catch(reel)
    if catchConnection then catchConnection:Disconnect() catchConnection=nil end
    if not reel or not reel.OnMinigameEnd then return end
    catchConnection=reel.OnMinigameEnd:Connect(function(success)
        if not state.Alive or not success or not config.WebhookEnabled then return end
        local name=reel.fish and reel.fish.Name
        if name then pendingCatches[name]={Expires=os.clock()+20} end
    end)
end
local function send_webhook()
    if webhookBusy or not config.WebhookEnabled or #webhookQueue==0 or os.clock()<nextWebhook then return end
    local url=webhook_endpoint()
    if not url then state.WebhookStatus="Enter a Discord webhook URL" return end
    if type(httpRequest)~="function" then state.WebhookStatus="HTTP requests unavailable" return end
    local entry=table.remove(webhookQueue,1)
    entry.Attempts+=1
    webhookBusy=true
    task.spawn(function()
        local ok,response=pcall(function()
            local payload=entry.Payload or webhook_payload(entry.Item,entry.Count)
            entry.Payload=payload
            if not state.Alive or not config.WebhookEnabled or webhook_endpoint()~=url then return end
            return httpRequest({Url=url,Method="POST",Headers={["Content-Type"]="application/json"},
                Body=httpService:JSONEncode(payload)})
        end)
        nextWebhook=os.clock()+2
        if state.Alive and config.WebhookEnabled then
            local status=ok and type(response)=="table" and tonumber(response.StatusCode)
            if status and status>=200 and status<300 then
                state.WebhookSent=(state.WebhookSent or 0)+1
                state.WebhookStatus="Sent "..tostring(state.WebhookSent)
            elseif status==429 then
                local delay=5
                local decoded,body=pcall(httpService.JSONDecode,httpService,response.Body or "")
                if decoded and type(body)=="table" then delay=math.clamp(tonumber(body.retry_after) or 5,1,120) end
                nextWebhook=os.clock()+delay
                if entry.Attempts<3 then table.insert(webhookQueue,1,entry) end
                state.WebhookStatus="Rate limited; waiting"
            elseif not status or status>=500 then
                if entry.Attempts<3 then table.insert(webhookQueue,1,entry) end
                nextWebhook=os.clock()+5
                state.WebhookStatus="Delivery failed"
            else
                state.WebhookStatus="Webhook HTTP "..tostring(status)
                if status==401 or status==403 or status==404 then table.clear(webhookQueue) end
            end
        end
        webhookBusy=false
    end)
end
local function update_inventory()
    local current={}
    for id,item in pairs(inventory())do
        current[id]=item.sub and item.sub.Stack or 1
        if state.SeenReady and not state.Seen[id] and libraryData.fish[item.name]then
            state.Catches+=current[id]
            state.LastCatch=item.name
            queue_catch(item,current[id])
        elseif state.SeenReady and state.Seen[id] and current[id]>state.Seen[id] and libraryData.fish[item.name]then
            state.Catches+=current[id]-state.Seen[id]
            state.LastCatch=item.name
            queue_catch(item,current[id]-state.Seen[id])
        end
    end
    state.Seen=current
    state.SeenReady=true
    local coins=stats() and stats():FindFirstChild("coins")
    if coins then
        if state.LastCoins and coins.Value>state.LastCoins then
            local delta=coins.Value-state.LastCoins
            state.Earnings+=delta
            state.Income[#state.Income+1]={At=os.clock(),Value=delta}
        end
        state.LastCoins=coins.Value
    end
    local hourly=0
    for i=#state.Income,1,-1 do
        if os.clock()-state.Income[i].At>3600 then table.remove(state.Income,i)
        else hourly+=state.Income[i].Value end
    end
    state.HourlyEarnings=hourly
    state.SaleCount=0
    for _,item in ipairs(sale_items())do state.SaleCount+=item.Count end
    if state.RageAttempt and state.Catches>state.RageAttempt.Catches then
        state.RageAttempt=nil
        state.RageRejects=0
    end
end
local function fish_step()
    local tool=rod()
    if not tool and config.AutoFish and ready("equip rod",2)then
        local character=localPlayer.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            for _,candidate in ipairs(localPlayer.Backpack:GetChildren())do
                if candidate:IsA("Tool") and candidate:FindFirstChild("rodClient")then
                    humanoid:EquipTool(candidate)
                    break
                end
            end
        end
    end
    local values=tool and tool:FindFirstChild("values")
    local phase=values and values:FindFirstChild("state") and values.state.Value
    local reel=reelController.ActiveReel
    if state.RageAttempt and os.clock()-state.RageAttempt.At>8 then
        state.RageRejects=(state.RageRejects or 0)+1
        state.RageAttempt=nil
    end
    state.ShakeStatus=(phase==biteTypes.RodState.Luring or phase==biteTypes.RodState.Searching) and "waiting" or "idle"
    state.ReelStatus=reel and string.format("%.0f%%",reel.progress or 0) or "idle"
    local baitFolder=stats() and stats():FindFirstChild("bait")
    state.Bait=baitFolder and baitFolder.Value or "none"
    if (state.RageRejects or 0)>=2 then state.ReelStatus=state.ReelStatus.." (Blatant fallback)"end
    if config.AutoBait and ready("bait",2)then
        local bait=selected_bait()
        local folder=stats()
        local selected=folder and folder:FindFirstChild("bait")
        if bait and selected and selected.Value~=bait then guarded("bait",function()baitRemote:FireServer(bait)end)end
    end
    if not tool or not phase then state.Status="Equip a rod" return end
    state.Status=phase==biteTypes.RodState.Reeling and "Reeling" or phase==biteTypes.RodState.Luring and "Waiting for bite" or phase==biteTypes.RodState.Equipped and "Ready to cast" or "Fishing"
    local shakeGui=localPlayer.PlayerGui:FindFirstChild("shakeui")
    local shakeButton=shakeGui and shakeGui:FindFirstChildWhichIsA("GuiButton",true)
    state.ShakeStatus=shakeButton and "ready" or state.ShakeStatus
    if (config.AutoFish or config.AutoShake) and shakeButton and shakeButton.Visible and ready("shake",.25) then
        guarded("shake",function()firesignal(shakeButton.Activated)end)
        state.ShakeStatus="shaking"
    end
    if reel and reel.active and (config.AutoFish or config.AutoReel)then
        local mode=config.ReelMode
        if mode=="Rage" and (state.RageRejects or 0)<2 and not state.RageAttempt
            and reel.active and ready("rage reel",1)then
            state.RageAttempt={At=os.clock(),Catches=state.Catches}
            guarded("rage reel",function()reel:EndMinigame(true)end)
        elseif mode=="Blatant" or mode=="Rage"then
            if ready("reel progress",.2)then guarded("reel progress",function()reel:AddProgress(12)end)end
        else
            local center=reel.barPosition or .5
            local hold=(reel.fishPosition or .5)>center
            if hold and not state.ReelHeld then state.ReelHeld=reel_input(true)
            elseif not hold and state.ReelHeld then release_reel() end
        end
    elseif state.ReelHeld then release_reel() end
    if config.AutoFish and not state.CastHeld and phase==biteTypes.RodState.Equipped and ready("cast",2.5)then
        if getconnections then
            state.CastHeld=true
            local castTool=tool
            local castMode=config.CastTiming
            local randomDuration=Random.new():NextNumber(.35,1.1)
            task.spawn(function()
                local started=os.clock()
                local meter
                local meterConnection
                local releasedAtPeak=false
                local function releaseAtPeak()
                    if meter and meter.Parent and meter.Size.Y.Scale>=.98 and state.CastHeld then
                        releasedAtPeak=true
                        state.CastHeld=false
                        cast_input(false,castTool)
                    end
                end
                local ok,message=pcall(function()
                    if not cast_input(true,castTool) then
                        state.Errors.CastInput="Rod input callbacks unavailable"
                        return
                    end
                    while state.Alive and config.AutoFish and state.CastHeld and castTool.Parent==localPlayer.Character do
                        local duration=os.clock()-started
                        if castMode=="Random" and duration>=randomDuration then break end
                        if castMode=="Perfect" then
                            if not meter or not meter.Parent then
                                local character=localPlayer.Character
                                local root=character and character:FindFirstChild("HumanoidRootPart")
                                local powerGui=root and (root:FindFirstChild("power") or root:FindFirstChild("thunderpower"))
                                powerGui=powerGui or (character and (character:FindFirstChild("power") or character:FindFirstChild("thunderpower")))
                                local powerbar=powerGui and powerGui:FindFirstChild("powerbar")
                                meter=powerbar and powerbar:FindFirstChild("bar")
                                if meter and meter:IsA("GuiObject") then
                                    if meterConnection then meterConnection:Disconnect() end
                                    meterConnection=meter:GetPropertyChangedSignal("Size"):Connect(releaseAtPeak)
                                elseif powerGui and powerGui.Name=="thunderpower" then
                                    releasedAtPeak=true
                                    break
                                end
                            end
                            if meter and meter:IsA("GuiObject") then
                                releaseAtPeak()
                                if releasedAtPeak then break end
                            end
                        end
                        if duration>=5 then break end
                        runService.Heartbeat:Wait()
                    end
                end)
                if meterConnection then meterConnection:Disconnect() end
                if state.CastHeld then
                    state.CastHeld=false
                    pcall(cast_input,false,castTool)
                end
                if not ok then
                    state.Errors.Cast=tostring(message)
                elseif castMode=="Perfect" and not releasedAtPeak and state.Alive and config.AutoFish then
                    state.Errors.Cast="Cast meter peak was not observed"
                else
                    state.Errors.Cast=nil
                end
            end)
        end
    end
end
local function unload()
    if not state.Alive then return end
    state.Alive=false
    if catchConnection then catchConnection:Disconnect() end
    table.clear(webhookQueue)
    release_reel()
    if state.CastHeld then pcall(cast_input,false,state.CastTool)state.CastHeld=false end
    if library and library.FlushAutosave then pcall(function()library:FlushAutosave()end)end
    for _,connection in ipairs(state.Connections)do connection:Disconnect()end
    config.Skybox=true
    config.Weather=true
    config.Lightning=true
    update_visuals()
    lighting.FogEnd=original.FogEnd
    lighting.FogColor=original.FogColor
    lighting.Ambient=original.Ambient
    lighting.OutdoorAmbient=original.OutdoorAmbient
    lighting.Brightness=original.Brightness
    if atmosphere then atmosphere.Color=original.AtmosphereColor atmosphere.Density=original.AtmosphereDensity end
    colorEffect:Destroy()
    depthEffect:Destroy()
    if library then library:Unload()end
    if env.AxisFisch and env.AxisFisch.State==state then env.AxisFisch=nil end
end
env.AxisFisch={Config=config,State=state,Unload=unload,Set=set_external,SellNow=sell_now,PreviewWebhook=webhook_payload}
local ok,errorMessage=xpcall(function()
    local createUI=loadstring(Sources.UI)
    if not createUI then unload() return end
    ui=createUI()({Config=config,State=state,Set=set_config,Unload=unload,Connect=connect,
        BaitNames=bait_names,FishNames=fish_names,RarityNames=rarity_names,SellNow=sell_now,
        IslandNames=island_names,PlayerNames=player_names,ShopNames=shop_names,
        TeleportIsland=teleport_island,TeleportPlayer=teleport_player,
        ReturnPosition=function() if state.ReturnPosition then teleport_to(state.ReturnPosition,false) end end,
        SavePosition=function()
            local character=localPlayer.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            if root then state.SavedPosition=root.CFrame state.TravelStatus="Position saved" end
        end,
        TeleportSaved=function() if state.SavedPosition then teleport_to(state.SavedPosition,true) end end,
        BuyNow=buy_now,ResetPurchases=function() state.Purchases=0 state.BuyStatus="Limit reset" end})
    library,window=ui.Library,ui.Window
    queue_teleport()
    connect(localPlayer.OnTeleport,queue_teleport)
    connect(localPlayer.Idled,function()
        if config.AntiAFK then
            guarded("anti afk",function()
                local virtualUser=game:GetService("VirtualUser")
                virtualUser:CaptureController()
                virtualUser:ClickButton2(Vector2.zero)
            end)
        end
    end)
    env.AxisFisch.UI=ui
    update_visuals()
    if weatherFolder then connect(weatherFolder.DescendantAdded,weather_visible)end
    update_inventory()
    connect(reelController.OnReelCreated,watch_catch)
    watch_catch(reelController.ActiveReel)
    local elapsed=0
    connect(runService.Heartbeat,function(dt)
        if not state.Alive then return end
        elapsed+=dt
        if elapsed<.15 then return end
        elapsed=0
        guarded("fishing",fish_step)
        if not config.WebhookEnabled then table.clear(webhookQueue) table.clear(pendingCatches) end
        send_webhook()
        if config.AutoBuy and ready("auto buy",config.BuyInterval) then guarded("buy",buy_now) end
        if ready("inventory",.7)then guarded("inventory",update_inventory)end
        if config.AutoSell and state.SaleCount>0 and ready("auto sell",30)then task.spawn(sell_now)end
    end)
end,function(message)return tostring(message)end)
if not ok then state.Errors.Startup=errorMessage unload()end

end)
