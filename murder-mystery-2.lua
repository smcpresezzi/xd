


local UI_LIBRARY_URL = "https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua"

local function createAxisAdapter(native)
    local onUnload=Instance.new("BindableEvent")
    local adapter={Options={},Themes={Default=true},Native=native,Unloaded=false,OnUnload=onUnload.Event}
    local icons={["Coin Farm"]="7743866529",Combat="7743872758",Visuals="7733774602",Movement="7734021165",Misc="7734053495",["Auto Farm"]="7733942651",House="7733960981",Shop="7734056747",["Trade License"]="7734056411",Notifications="7734053595",Performance="7733799969",Settings="7734053495"}
    local function option(id,data,kind,control)
        local item={Type=kind,Value=data.Default,Values=data.Values or {},Multi=data.Multi==true,Min=data.Min,Max=data.Max,Mode="Toggle",Changed={},Native=control}
        function item:OnChanged(callback)table.insert(self.Changed,callback)end
        function item:Emit(value)
            self.Value=value
            if data.Callback then data.Callback(value)end
            for _,callback in ipairs(self.Changed)do callback(value)end
        end
        function item:SetValue(value)
            if self.Multi and type(value)=="table" then
                local list={}
                for key,selected in pairs(value)do if type(key)=="number" then table.insert(list,selected)elseif selected then table.insert(list,key)end end
                value=list
            end
            self.Native:Set(value)
        end
        item.SetValueRGB=item.SetValue
        function item:SetValues(values)self.Values=values self.Native:Refresh(values)end
        function item:GetBind()return Enum.KeyCode.RightShift end
        adapter.Options[id]=item
        return item
    end
    local function section(raw)
        local result={Native=raw}
        function result:CreateToggle(id,data)
            data.Default=id=="Autosave" and data.Default~=false
            local item
            local control=raw:Toggle({Name=data.Title,Flag="MM2_"..id,Default=data.Default,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Toggle",control)
            return item
        end
        function result:CreateSlider(id,data)
            local item
            local control=raw:Slider({Name=data.Title,Flag="MM2_"..id,Min=data.Min,Max=data.Max,Default=data.Default,Decimals=10^-(data.Rounding or 0),Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Slider",control)return item
        end
        function result:CreateDropdown(id,data)
            local item
            local control=raw:Dropdown({Name=data.Title,Flag="MM2_"..id,Items=data.Values,Default=data.Default,Multi=data.Multi,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Dropdown",control)return item
        end
        function result:CreateListbox(id,data)
            local item
            local control=raw:Listbox({Flag="MM2_"..id,Items=data.Values or {},Multi=false,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Dropdown",control)return item
        end
        function result:CreateInput(id,data)
            raw:Label(data.Title)
            local item
            local control=raw:Textbox({Flag="MM2_"..id,Default=data.Default,Placeholder=data.Placeholder or "",Numeric=data.Numeric,Finished=data.Finished,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Input",control)return item
        end
        function result:CreateKeybind(id,data)
            local aliases={FlyKey="Fly",NoclipKey="Noclip",ClickTpKey="ClickTp"}
            if id=="MenuKeybind" then
                raw:Label("Menu key: Right Shift")
                local item={Type="Keybind",Value="RightShift",Mode="Toggle",Changed={}}
                function item:GetBind()return Enum.KeyCode.RightShift end
                function item:SetValue()end
                function item:OnChanged(callback)table.insert(self.Changed,callback)end
                adapter.Options[id]=item return item
            end
            local feature=adapter.Options[aliases[id]]
            local parent=feature and feature.Native
            local key=Enum.KeyCode[data.Default] or Enum.KeyCode.Backspace
            local bind=(parent and parent.GetBind and parent:GetBind({Flag="MM2_"..id,Default=key,Mode=data.Mode or "Toggle",Callback=function(active)
                if feature then feature:SetValue(active)end
            end}))
            assert(bind,"Keybind requires a feature toggle")
            local item=option(id,data,"Keybind",bind)
            function item:GetBind()
                local key=self.Native.Key
                if typeof(key)=="EnumItem"then return key end
                local name=tostring(key):match("Enum%.[%w]+%.(.+)")or tostring(key)
                if name=="MouseButton1"then return Enum.UserInputType.MouseButton1 end
                if name=="MouseButton2"then return Enum.UserInputType.MouseButton2 end
                return Enum.KeyCode[name] or Enum.KeyCode.Backspace
            end
            function item:SetValue(value,mode)
                local name=tostring(type(value)=="table" and value.Key or value):gsub("^Enum%.[%w]+%.","")
                local keys={MouseButton1=Enum.UserInputType.MouseButton1,MouseButton2=Enum.UserInputType.MouseButton2,MouseLeft=Enum.UserInputType.MouseButton1,MouseRight=Enum.UserInputType.MouseButton2}
                self.Native:Set({Key=keys[name] or Enum.KeyCode[name] or Enum.KeyCode.Backspace,Mode=mode or (type(value)=="table" and value.Mode)or self.Native.ModeSelected or "Toggle"})
            end
            return item
        end
        function result:CreateColorpicker(id,data)
            local control=raw:Toggle({Name=data.Title,Flag="MM2_"..id.."Row",Default=false})
            local item
            local picker=control:Colorpicker({Flag="MM2_"..id,Default=data.Default,Callback=function(value)if item then item:Emit(value)end end})
            item=option(id,data,"Colorpicker",picker)return item
        end
        function result:CreateButton(data)return raw:Button({Name=data.Title,Callback=data.Callback})end
        function result:CreateCallout()return {}end
        function result:CreateParagraph(data)
            local frame=Instance.new("Frame")
            frame.Name="AxisStatus"
            frame.ZIndex=2
            frame.BackgroundTransparency=1
            frame.Size=UDim2.new(1,0,0,0)
            frame.AutomaticSize=Enum.AutomaticSize.Y
            frame.Parent=raw.Items.Content.Instance
            local padding=Instance.new("UIPadding")
            padding.PaddingTop=UDim.new(0,4)
            padding.PaddingBottom=UDim.new(0,6)
            padding.Parent=frame
            local label=Instance.new("TextLabel")
            label.Name="Text"
            label.ZIndex=3
            label.BackgroundTransparency=1
            label.Size=UDim2.new(1,0,0,0)
            label.AutomaticSize=Enum.AutomaticSize.Y
            label.TextWrapped=true
            label.TextXAlignment=Enum.TextXAlignment.Left
            label.TextYAlignment=Enum.TextYAlignment.Top
            label.FontFace=native.Font
            label.TextSize=12
            label.TextColor3=native.Theme.Text
            label.TextTransparency=.3
            label.Parent=frame
            local item={Frame=frame,Text=label}
            function item:SetContent(value)
                label.Text=(data.Title=="Status" and "" or data.Title..": ")..tostring(value)
            end
            item.SetDesc=item.SetContent
            item:SetContent(data.Content or "")
            return item
        end
        function result:CreateStat(id,data)
            local item=self:CreateParagraph({Title=data.Title,Content=data.Value})
            item.Type="Stat" item.SetValue=item.SetContent return item
        end
        return result
    end
    function adapter:CreateWindow()
        native.MenuKeybind=tostring(Enum.KeyCode.RightShift)
        local path=native.Folders.Assets.."/axis-logo.png"
        if not isfile(path)then writefile(path,game:HttpGet("https://raw.githubusercontent.com/lofaif1234/axisui/main/assets/axis-logo.png"))end
        local raw=native:Window({Name="",SubName="",Logo=getcustomasset(path),Wordmark=true})
        local window={Native=raw,Pages={},MinimizeKey=Enum.KeyCode.RightShift}
        function window:Divider()end
        
        
        
        
        function window:SetKeybind()native.MenuKeybind=tostring(Enum.KeyCode.RightShift)end
        function window:SelectTab(value)
            local page=type(value)=="number" and self.Pages[value] or nil
            if not page then for _,entry in ipairs(self.Pages)do if entry.Title==value then page=entry break end end end
            if page then for _,entry in ipairs(self.Pages)do entry.Native:Turn(entry==page)end end
        end
        function window:CreateTab(data)
            local page={Title=data.Title,Native=raw:Page({Name=data.Title,Icon=icons[data.Title] or "7733954760"})}
            function page:Left(name)return section(self.Native:Section({Name=name,Side=1}))end
            function page:Right(name)return section(self.Native:Section({Name=name,Side=2}))end
            table.insert(self.Pages,page)return page
        end
        window._axisWindow=window
        self.Window=window
        return window
    end
    function adapter:Finish()self.Window.Native:Init()end
    function adapter:Notify(data)native:Notification({Title="Axis",Description=data.Content or data.Title,Duration=data.Duration or 4})end
    function adapter:Destroy()if self.Unloaded then return end self.Unloaded=true onUnload:Fire() native:Unload()end
    return adapter
end


local function loadInterfaceLibrary()
	local uiSource = game:HttpGet(UI_LIBRARY_URL)
	local chunk, raised = loadstring(uiSource, "Axis UI")

	if not chunk then
		error(raised, 0)
	end

	return createAxisAdapter(chunk())
end

export type Bag = {
	Amount: number,
	Limit: number,
}

export type FarmState = {
	Done: { [unknown]: unknown },
	Fails: { [unknown]: unknown },
	Avoid: { [unknown]: unknown },
	BagHandled: boolean,
	Last: unknown?,
	LastPos: unknown?,
}

export type AcrylicLibrary = {
	ToggleAcrylic: (self: AcrylicLibrary, isEnabled: boolean) -> (),
}

type VectorFields = { X: number, Y: number, Z: number, Magnitude: number }
type Vector = typeof(setmetatable({} :: VectorFields, {
	__add = function(left: VectorFields, right: VectorFields): VectorFields return left end,
	__sub = function(left: VectorFields, right: VectorFields): VectorFields return left end,
}))
type Frame = { Position: Vector }
type Coin = { Position: Vector, Parent: unknown }
type Part = { Position: Vector, CFrame: Frame }
type Character = { FindFirstChild: (self: Character, name: string) -> Part? }
type LookupCharacter = {
	FindFirstChild: (self: LookupCharacter, name: string) -> unknown,
	FindFirstChildOfClass: (self: LookupCharacter, className: string) -> unknown,
}
type LookupPlayer = { Character: LookupCharacter? }
type PingPlayer = { GetNetworkPing: (self: PingPlayer) -> unknown }
type Player = { Character: Character? }
type Heartbeat = { Wait: (self: Heartbeat) -> () }
type AttributeCoin = { GetAttribute: (self: AttributeCoin, name: string) -> unknown }
type Option = { Value: unknown }
type MapCandidate = {
	Parent: unknown,
	IsA: (self: MapCandidate, className: string) -> boolean,
	FindFirstChild: (self: MapCandidate, name: string) -> unknown,
}
type MapWorld = { GetChildren: (self: MapWorld) -> { MapCandidate } }
export type MapDependencies = {
	State: { MapCache: MapCandidate?, NextScan: number },
	Workspace: MapWorld,
	Clock: () -> number,
}
type RoundPlayer = { Name: string }
type RoleInfo = { Dead: unknown, Role: unknown }
type RoleRound = {
	Info: (unknown) -> RoleInfo?,
	Tool: (unknown, string) -> unknown,
}
type AliveRound = { Info: (unknown) -> RoleInfo? }
type HealthHumanoid = { Health: number }
type Tool = {
	IsA: (self: Tool, className: string) -> boolean,
	HasTag: (self: Tool, tag: string) -> boolean,
}
type ToolContainer = { GetChildren: (self: ToolContainer) -> { Tool } }
type ToolPlayer = {
	Character: ToolContainer?,
	FindFirstChildOfClass: (self: ToolPlayer, className: string) -> ToolContainer?,
}
type CoinCandidate = {
	Parent: unknown,
	IsA: (self: CoinCandidate, className: string) -> boolean?,
	FindFirstChild: (self: CoinCandidate, name: string) -> unknown,
}
type Humanoid = { Health: number }
type FullBagFarm = {
	Status: string,
	BagHandled: boolean,
	HideHere: () -> (),
	Surface: () -> (),
}
type SurfaceMover = { Owner: string?, Release: (string, Frame?) -> () }
type SurfaceFarm = { SafeSpot: () -> Frame? }
type SafeFarm = { Last: { Parent: unknown, Position: Vector }?, LastPos: Vector? }
type HideMover = { Owner: string?, Target: Frame?, Current: () -> Frame, Hold: (string, Frame) -> () }
type HideFarm = { BagHandled: boolean, Deep: (Vector) -> Frame }
type RunningFarm = { Status: string, Enabled: () -> boolean, Surface: () -> (), Step: () -> () }
export type FarmGeometry = {
	ReadOption: (string, number) -> number,
	NewVector: (number, number, number) -> Vector,
	NewFrame: (VectorFields) -> Frame,
}
export type SafeSpotDependencies = {
	Farm: SafeFarm,
	GroundAt: (Vector) -> Frame?,
	SpawnPoint: () -> Frame?,
	Fallback: () -> Frame?,
}
export type HideDependencies = {
	Mover: HideMover,
	Farm: HideFarm,
	CharacterParts: () -> Part?,
	NewVector: (number, number, number) -> Vector,
	NewFrame: (VectorFields) -> Frame,
}
export type FarmLoopDependencies = {
	IsRunning: () -> boolean,
	Farm: RunningFarm,
	Log: (string) -> (),
	Mover: { Owner: string? },
	Wait: (number?) -> (),
}
type CoinContainer = { GetChildren: (self: CoinContainer) -> { Coin } }
type FarmMap = { FindFirstChild: (self: FarmMap, name: string) -> CoinContainer? }
type CoinRound = { Map: () -> FarmMap? }
type SpawnPart = { Position: Vector }
type SpawnFolder = { FindFirstChildWhichIsA: (self: SpawnFolder, className: string, recursive: boolean) -> SpawnPart? }
type SpawnMap = { FindFirstChild: (self: SpawnMap, name: string) -> SpawnFolder? }
export type SpawnDependencies = {
	Round: { Map: () -> SpawnMap? },
	NewFrame: (VectorFields) -> Frame?,
	Offset: Vector,
}
export type LobbySpawnDependencies = {
	Workspace: { FindFirstChild: (self: unknown, name: string) -> SpawnMap? },
	NewFrame: (VectorFields) -> Frame?,
	Offset: Vector,
}
export type GroundDependencies = {
	GroundPosition: (Vector) -> Vector?,
	NewFrame: (VectorFields) -> Frame?,
	Offset: Vector,
}
type GroundRayMap = {
	FindFirstChild: (self: GroundRayMap, name: string) -> unknown,
	CoinContainer: unknown,
}
type GroundRayWorld = {
	Raycast: (self: GroundRayWorld, origin: VectorFields, direction: Vector, parameters: RaycastParameters) -> { Position: Vector }?,
}
export type GroundRayDependencies = {
	Player: { Character: unknown },
	Round: { Map: () -> GroundRayMap? },
	Parameters: RaycastParameters,
	Workspace: GroundRayWorld,
	OriginOffset: Vector,
	Direction: Vector,
}
type ExposedCoin = { Position: Vector, Parent: unknown }
type PlayerWithCharacter = { Character: unknown }
type PlayerService = { GetPlayers: (self: PlayerService) -> { PlayerWithCharacter } }
type RaycastParameters = { FilterDescendantsInstances: { unknown } }
type RaycastWorld = {
	Raycast: (self: RaycastWorld, origin: Vector, direction: Vector, parameters: RaycastParameters) -> unknown,
}
export type ExposureDependencies = {
	Cache: { [ExposedCoin]: boolean },
	Players: PlayerService,
	Parameters: RaycastParameters,
	Farm: { Hidden: (Vector) -> Frame },
	Workspace: RaycastWorld,
	RayDirection: Vector,
}
type MoveFrame = {
	Position: Vector,
	Lerp: (self: MoveFrame, goal: MoveFrame, alpha: number) -> MoveFrame,
}
type MoveRoot = { CFrame: MoveFrame }
type MovementState = {
	Owner: string?,
	Conn: unknown,
	Target: unknown,
	Current: () -> MoveFrame?,
	Hold: (string, MoveFrame) -> boolean,
}
type CollisionPart = {
	Parent: unknown,
	CanCollide: boolean,
	IsA: (self: CollisionPart, className: string) -> boolean,
}
type HeldRoot = {
	CFrame: unknown,
	AssemblyLinearVelocity: unknown,
	AssemblyAngularVelocity: unknown,
}
type HeldCharacter = {
	FindFirstChild: (self: HeldCharacter, name: string) -> HeldRoot?,
	GetDescendants: (self: HeldCharacter) -> { CollisionPart },
}
type HeldPlayer = { Character: HeldCharacter? }
type HeldMover = {
	Conn: unknown,
	Char: HeldCharacter?,
	Saved: { [CollisionPart]: boolean }?,
	Owner: string?,
	Target: unknown,
	Stop: () -> (),
}
type HoldSignal = { Connect: (self: HoldSignal, callback: () -> ()) -> unknown }
type HoldConnection = { Disconnect: (self: HoldConnection) -> () }
export type HoldDependencies = {
	Player: HeldPlayer,
	Mover: HeldMover,
	Heartbeat: HoldSignal,
	OnFrame: () -> (),
}
export type FrameDependencies = {
	Player: HeldPlayer,
	Mover: HeldMover,
	TypeOf: (unknown) -> string,
	ZeroVelocity: unknown,
}
export type StopDependencies = {
	Player: HeldPlayer,
	Mover: HeldMover,
	ZeroVelocity: unknown,
}
export type CurrentDependencies = {
	Mover: { Target: unknown },
	CharacterParts: () -> MoveRoot?,
	TypeOf: (unknown) -> string,
}
export type Mover = {
	Conn: unknown,
	Char: HeldCharacter?,
	Saved: { [CollisionPart]: boolean }?,
	Owner: string?,
	Target: unknown,
	Stop: (unknown?) -> (),
	Hold: (string, unknown) -> boolean,
	Current: () -> MoveFrame?,
	Release: (string, unknown?) -> (),
	Glide: (string, MoveFrame, number, (() -> boolean)?) -> boolean,
}
export type MoverDependencies = {
	Player: HeldPlayer,
	Heartbeat: Heartbeat & HoldSignal,
	CharacterParts: () -> MoveRoot?,
	Maximum: (number, number) -> number,
	Clock: () -> number,
	IsAlive: () -> boolean,
	Minimum: (number, number) -> number,
	TypeOf: (unknown) -> string,
	ZeroVelocity: unknown,
}
export type MovementDependencies = {
	Mover: MovementState,
	CharacterParts: () -> MoveRoot?,
	Maximum: (number, number) -> number,
	Clock: () -> number,
	IsAlive: () -> boolean,
	Minimum: (number, number) -> number,
	Heartbeat: Heartbeat,
}
type CoinFarm = {
	Done: { [Coin]: boolean },
	Fails: { [Coin]: number },
	Avoid: { [Coin]: number },
	Threat: () -> Coin?,
	BagFull: (Coin) -> boolean,
	Exposed: (Coin) -> boolean,
}
export type CoinSelectionDependencies = {
	Round: CoinRound,
	Farm: CoinFarm,
	ReadNumber: (string, number) -> number,
	ReadBoolean: (string, boolean) -> boolean,
	Clock: () -> number,
	IsCoin: (Coin) -> boolean,
}
type FarmMover = {
	Owner: string?,
	Target: Frame?,
	Current: () -> Frame,
	Hold: (string, Frame) -> (),
	Glide: (string, Frame, number, () -> boolean) -> boolean,
}
type ActiveFarm = {
	Status: string,
	Last: Coin?,
	LastPos: Vector?,
	LastCollect: number,
	Count: number,
	Done: { [Coin]: boolean },
	Fails: { [Coin]: number },
	Avoid: { [Coin]: number },
	Enabled: () -> boolean,
	AllFull: () -> boolean,
	OnBagFull: () -> (),
	Deep: (Vector) -> Frame,
	Pick: (VectorFields) -> Coin?,
	Hidden: (Vector) -> Frame,
	Threat: () -> Coin?,
	TouchCF: (Coin) -> Frame,
}
type FarmRound = {
	InRound: () -> boolean,
	Info: (Player) -> unknown,
}
export type FarmStepDependencies = {
	Round: FarmRound,
	Farm: ActiveFarm,
	Player: Player,
	Mover: FarmMover,
	CharacterParts: () -> Part?,
	SpawnPoint: () -> Part?,
	NewVector: (number, number, number) -> Vector,
	NewFrame: (number, number, number) -> Frame,
	ReadOption: (string, number) -> number,
	IsAlive: () -> boolean,
	IsCoin: (Coin) -> boolean,
	Minimum: (number, number) -> number,
	Maximum: (number, number) -> number,
	Clock: () -> number,
	BaseDelay: number,
	Jitter: () -> number,
	Touch: ((Part, Coin, number) -> ())?,
	Heartbeat: Heartbeat,
	Wait: (number) -> (),
}
type ApplicationRound = {
	Bags: { [string]: Bag },
	InRound: () -> boolean,
	Info: (Player) -> unknown,
	Map: () -> FarmMap?,
	MyRole: () -> string,
	Murderer: () -> unknown,
}
export type FarmController = {
	Done: { [Coin]: boolean },
	Fails: { [Coin]: number },
	Avoid: { [Coin]: number },
	BagHandled: boolean,
	Last: Coin?,
	LastPos: Vector?,
	LastCollect: number,
	Count: number,
	Status: string,
	Enabled: () -> boolean,
	BagOf: (Coin) -> Bag?,
	BagFull: (Coin) -> boolean,
	AllFull: () -> boolean,
	BagText: () -> string,
	Hidden: (Vector) -> Frame,
	Deep: (Vector) -> Frame,
	TouchCF: (Coin) -> Frame,
	Threat: () -> Coin?,
	Exposed: (Coin) -> boolean,
	Pick: (Vector) -> Coin?,
	SafeSpot: () -> Frame?,
	Surface: () -> (),
	HideHere: () -> (),
	OnBagFull: () -> (),
	Step: () -> (),
	Reset: () -> (),
}
export type FarmDependencies = {
	Round: ApplicationRound,
	Player: Player,
	Mover: Mover,
	CharacterParts: () -> (Part?, Humanoid?),
	PlayerCharacterParts: (unknown) -> (unknown, unknown),
	GroundAt: (Vector) -> Frame?,
	SpawnPoint: () -> Frame?,
	Fallback: () -> Frame?,
	NewVector: (number, number, number) -> Vector,
	NewFrameAt: (VectorFields) -> Frame,
	NewFrame: (number, number, number) -> Frame,
	ReadNumber: (string, number) -> number,
	ReadBoolean: (string, boolean) -> boolean,
	ReadString: (string, string) -> string,
	IsAlive: () -> boolean,
	IsCoin: (Coin) -> boolean,
	Minimum: (number, number) -> number,
	Maximum: (number, number) -> number,
	Clock: () -> number,
	BaseDelay: number,
	Jitter: () -> number,
	Touch: ((Part, Coin, number) -> ())?,
	Heartbeat: Heartbeat,
	Wait: (number) -> (),
	Players: PlayerService,
	Parameters: RaycastParameters,
	Workspace: RaycastWorld,
	RayDirection: Vector,
}

local Farm = {}
local Appearance = {}
local Movement = {}
local Options = {}
local Lifecycle = {}
local Characters = {}
local Network = {}
local Round = {}
local Inventory = {}
local Quest = {}
local Helpers = {}
local Popups = {}
local Spectate = {}
local Server = {}
local Webhook = {}
local Esp = {}
local Hooks = {}
local Interface = { loadLibrary = loadInterfaceLibrary }
local Combat = {}
local Config = {}
local Application = {}
local Settings = {}

function Application.createEnvironment(host: any, uiSource: string?): (any, any)
	local executor: any = if type(host.getgenv) == "function" then (host.getgenv :: any)() else host
	local hostGame, hostCompile = host.game, host.loadstring
	local hostHttp = hostGame:GetService("HttpService")
	local environment: any, serviceCache: any, denied: any = {}, {}, {}

	local function lookup(name: string): any
		local value = host[name]
		if value ~= nil then return value end
		return executor[name]
	end

	for name in string.gmatch([[
		assert error pcall xpcall pairs ipairs next select tonumber tostring type typeof
		rawget rawset rawequal rawlen setmetatable getmetatable unpack print warn
		buffer bit32 string table math coroutine vector os utf8 task wait spawn delay tick time
		Enum Instance Color3 Vector2 Vector3 Vector2int16 Vector3int16 CFrame UDim UDim2 Rect
		Ray Region3 Region3int16 BrickColor TweenInfo Font NumberRange NumberSequence
		NumberSequenceKeypoint ColorSequence ColorSequenceKeypoint PhysicalProperties
		RaycastParams OverlapParams Axes Faces DateTime Random PathWaypoint Content
		Drawing gethui protectgui firetouchinterest fireclickdetector fireproximityprompt
		sethiddenproperty gethiddenproperty setclipboard toclipboard setfpscap getfpscap
		isnetworkowner getconnections getgc getrawmetatable setrawmetatable setreadonly
		isreadonly checkcaller getnamecallmethod newcclosure iscclosure islclosure hookfunction hookmetamethod
		restorefunction mouse1press mouse1release mouse1click mouse2press mouse2release
		mouse2click mousemoverel mousemoveabs keypress keyrelease setthreadidentity
		set_thread_identity setidentity getthreadidentity identifyexecutor
		readfile writefile appendfile isfile isfolder makefolder listfiles delfile delfolder
		getcustomasset getsynasset UserSettings settings version
	]], "%S+") do
		environment[name] = lookup(name)
	end

	local hostDebug = lookup("debug")
	if hostDebug then environment.debug = { info = hostDebug.info, traceback = hostDebug.traceback } end

	environment._G, environment.shared = environment, {}
	environment.getgenv = function() return environment end
	environment.getfenv = function() return environment end
	environment.getrenv = function() return environment end
	environment.setfenv = function(callback: any) return host.setfenv(callback, environment) end

	local function unavailable(route: any): any
		local path = string.match(tostring(route), "^[^?]+") or tostring(route)
		if not denied[path] then
			denied[path] = true
		end
		return { Success = false, StatusCode = 503, StatusMessage = "Unavailable offline", Body = "", Headers = {} }
	end

	local function localRequest(options: any): any
		assert(type(options) == "table" and type(options.Url) == "string", "Request requires a URL")
		if options.Url == UI_LIBRARY_URL and (options.Method == nil or options.Method == "GET") then
			if uiSource == nil then
				uiSource = hostGame:HttpGet(UI_LIBRARY_URL)
			end

			return { Success = true, StatusCode = 200, StatusMessage = "UI library", Body = uiSource, Headers = {} }
		end
		local request=lookup("request") or lookup("http_request") or (executor.syn and executor.syn.request)
        if type(request)=="function" and (options.Url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+") or options.Url:match("^https://thumbnails%.roblox%.com/") or options.Url:match("^https://games%.roblox%.com/"))then return request(options)end
        return unavailable(options.Url)
    end

	local function localGet(_: any, url: string): string
		local response = localRequest({ Url = url, Method = "GET" })
		if not response.Success then error("Resource is not embedded: " .. tostring(url), 0) end
		return response.Body
	end

	local function disabledSocket()
		error("WebSocket is disabled in the local build", 0)
	end

    local queueTeleport=lookup("queue_on_teleport") or lookup("queueonteleport")
    if type(queueTeleport)~="function" and type(executor.syn)=="table"then queueTeleport=executor.syn.queue_on_teleport end

	environment.request, environment.http_request = localRequest, localRequest
	environment.http = { request = localRequest }
	environment.WebSocket, environment.websocket = { connect = disabledSocket }, { connect = disabledSocket }
	environment.queue_on_teleport, environment.queueonteleport = queueTeleport, queueTeleport
	
	environment.clearteleportqueue = function() end
	environment.clear_teleport_queue = environment.clearteleportqueue
	environment.syn = {
		request = localRequest, protect_gui = environment.protectgui,
		getcustomasset = environment.getcustomasset, queue_on_teleport = queueTeleport,
		clear_teleport_queue = environment.clearteleportqueue,
		websocket = { connect = disabledSocket },
	}

	local httpProxy = setmetatable({}, {
		__index = function(_, name: string): any
			if name == "GetAsync" then return localGet end
			if name == "RequestAsync" then return function(_, options) return localRequest(options) end end
			if name == "PostAsync" then
				return function(_, url)
					unavailable(url)
					error("POST is unavailable offline: " .. tostring(url), 0)
				end
			end
			if name == "JSONEncode" or name == "JSONDecode" or name == "GenerateGUID" or name == "UrlEncode" then
				return function(_, ...) return hostHttp[name](hostHttp, ...) end
			end
			error("HttpService member is unavailable offline: " .. tostring(name), 0)
		end,
	})

	local function service(_: any, name: string): any
		if name == "HttpService" then return httpProxy end
		if name == "HttpRbxApiService" then error("HTTP API is unavailable offline", 0) end
		if not serviceCache[name] then serviceCache[name] = hostGame:GetService(name) end
		return serviceCache[name]
	end

	environment.game = setmetatable({}, {
		__index = function(_, name: string): any
			if name == "GetService" or name == "FindService" or name == "service" then return service end
			if name == "HttpGet" or name == "HttpGetAsync" then return localGet end
			if name == "HttpService" then return httpProxy end
			if name == "HttpPost" or name == "HttpPostAsync" then
				return function(_, url)
					unavailable(url)
					error("POST is unavailable offline: " .. tostring(url), 0)
				end
			end
			local value = hostGame[name]
			if type(value) == "function" then return function(_, ...) return (value :: any)(hostGame, ...) end end
			return value
		end,
	})
	environment.workspace = hostGame:GetService("Workspace")
	local hostClone = lookup("cloneref")
	environment.cloneref = function(value: any)
		if value == environment.game or value == httpProxy then return value end
		if hostClone then return (hostClone :: any)(value) end
		return value
	end

	environment.require = function(module: any)
		assert(host.typeof(module) == "Instance" and module:IsA("ModuleScript"), "Numeric and external require are disabled")
		return host.require(module)
	end

	environment.loadstring = function(source: any, name: any)
		assert(type(source) == "string", "Local compiler requires source text")
		local chunk, failure = hostCompile(source, name)
		if not chunk then return nil, failure end
		return host.setfenv(chunk, environment)
	end
	environment.load = environment.loadstring

	return environment, { denied = denied, executorGlobals = environment }
end

export type RoundDependencies = {
	Players: any,
	Player: any,
	Workspace: any,
	Clock: () -> number,
	GetPlayerDataState: () -> any,
}

function Round.create(dependencies: RoundDependencies): any
	local round: any = {
		Bags = {},
		CollectedThisRound = 0,
		Mode = "Classic",
		NextScan = 0,
		Watchers = {},
	}

	function round.Data() return Round.data(dependencies.GetPlayerDataState()) end
	function round.Info(player: any) return Round.info(round, player) end
	function round.Tool(player: any, tag: string) return Round.tool(Inventory.findTool, player, tag) end
	function round.IsAlive(player: any) return Round.isAlive(round, Characters.parts :: any, player) end
	function round.Role(player: any) return Round.role(round, player) end
	function round.FindRole(role: string) return Round.findRole(dependencies.Players, round, role) end
	function round.Murderer() return Round.murderer(round) end
	function round.Sheriff() return Round.sheriff(dependencies.Players, round) end
	function round.Map() return Round.map({ State = round, Workspace = dependencies.Workspace, Clock = dependencies.Clock }) end
	function round.MyRole() return Round.myRole(round, dependencies.Player) end
	function round.InRound() return Round.inRound(round, dependencies.Player) end
	function round.GunDrop() return Round.gunDrop(round, dependencies.Workspace) end

	return round
end

function Options.read(options: { [string]: Option? }, name: string, default: unknown): unknown
	local option = options[name]

	if option ~= nil and option.Value ~= nil then
		return option.Value
	end

	return default
end

function Options.readNumber(readOption: (string, number?) -> unknown, name: string, default: number?): number?
	return tonumber(readOption(name, default) :: string) or default
end

function Settings.setFps(setFpsCap: any, value: any)
	if not setFpsCap or value == "Off" then return end
	local cap = if value == "Unlimited" then 0 else tonumber(value) or 60
	pcall(setFpsCap, cap)
end

function Settings.set3D(runService: any, enabled: any)
	pcall(function() runService:Set3dRenderingEnabled(enabled) end)
end

function Settings.reduceObject(settings: any, effectTypes: any, object: any)
	if not effectTypes[object.ClassName] or settings.Saved[object] ~= nil then return end
	settings.Saved[object] = object.Enabled
	object.Enabled = false
end

export type LowGraphicsDependencies = {
	Settings: any,
	Lighting: any,
	Workspace: any,
	Visuals: any,
	Reduce: (any) -> (),
	Throttle: () -> (),
	GetSettings: () -> any,
	LowestQuality: () -> any,
}

function Settings.lowGraphics(dependencies: LowGraphicsDependencies, enabled: any)
	local settings, lighting = dependencies.Settings, dependencies.Lighting
	if settings.Low == enabled then return end
	settings.Low = enabled

	if enabled then
		settings.Lighting = { GlobalShadows = lighting.GlobalShadows }
		lighting.GlobalShadows = false
		local snapshot = settings.Lighting
		pcall(function()
			snapshot.Quality = dependencies.GetSettings().Rendering.QualityLevel
			dependencies.GetSettings().Rendering.QualityLevel = dependencies.LowestQuality()
		end)
		for _, object: any in ipairs(dependencies.Workspace:GetDescendants() :: any) do
			pcall(dependencies.Reduce, object)
			dependencies.Throttle()
		end
		settings.Conn = dependencies.Workspace.DescendantAdded:Connect(function(object)
			if settings.Low then pcall(dependencies.Reduce, object) end
		end)
		return
	end

	if settings.Conn then
		settings.Conn:Disconnect()
		settings.Conn = nil
	end
	for object: any, value in pairs(settings.Saved) do
		pcall(function() object.Enabled = value end)
	end
	table.clear(settings.Saved)
	if settings.Lighting then
		if not dependencies.Visuals.Saved then lighting.GlobalShadows = settings.Lighting.GlobalShadows end
		if settings.Lighting.Quality then
			pcall(function() dependencies.GetSettings().Rendering.QualityLevel = settings.Lighting.Quality end)
		end
	end
	settings.Lighting = nil
end

export type SettingsDependencies = {
	Lighting: any,
	Workspace: any,
	Visuals: any,
	RunService: any,
	SetFpsCap: any,
	Throttle: () -> (),
	GetSettings: () -> any,
	LowestQuality: () -> any,
}

function Settings.create(dependencies: SettingsDependencies): any
	local settings: any = {
		FpsChoices = { "Off", "15", "30", "60", "90", "120", "144", "240", "Unlimited" },
		Saved = {},
		Low = false,
	}
	local effectTypes = { Trail = true, Beam = true, ParticleEmitter = true, Smoke = true, Sparkles = true, Fire = true }

	function settings.LowGraphics(enabled: any)
		Settings.lowGraphics({
			Settings = settings,
			Lighting = dependencies.Lighting,
			Workspace = dependencies.Workspace,
			Visuals = dependencies.Visuals,
			Reduce = function(object) Settings.reduceObject(settings, effectTypes, object) end,
			Throttle = dependencies.Throttle,
			GetSettings = dependencies.GetSettings,
			LowestQuality = dependencies.LowestQuality,
		}, enabled)
	end

	function settings.SetFps(value: any) Settings.setFps(dependencies.SetFpsCap, value) end
	function settings.Set3D(enabled: any) Settings.set3D(dependencies.RunService, enabled) end
	return settings
end

function Popups.find(root: any, signal: any): (any, any)
	if not root then return nil end
	local container = root:FindFirstChild("Container")
	local button = container and container:FindFirstChild("Claim")
	if root.Visible and button then return button, signal end
	return nil
end

function Popups.open(player: any, find: (any, any) -> (any, any)): (any, any)
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then return nil end
	local crossPlatform = gui:FindFirstChild("CrossPlatform")
	local newItem = crossPlatform and crossPlatform:FindFirstChild("NewItem")
	local medium = newItem and newItem:FindFirstChild("Medium")
	local button, signal = find(medium, "Activated")
	if button then return button, signal end
	local mainGui = gui:FindFirstChild("MainGUI")
	local gameGui = mainGui and mainGui:FindFirstChild("Game")
	local mainItem = gameGui and gameGui:FindFirstChild("NewItem")
	return find(mainItem, "MouseButton1Click")
end

function Popups.press(button: any, signalName: any, getConnections: any, fireSignal: any): boolean
	local signal = button[signalName]
	local fired = false
	if getConnections then
		for _, connection: any in ipairs((getConnections :: any)(signal) :: any) do
			if connection.Fire then
				local success = pcall(function() (connection.Fire :: any)(connection) end)
				if success then fired = true end
			end
		end
	end
	if not fired and fireSignal then fired = pcall(fireSignal, signal) end
	return fired
end

function Popups.claimAll(popups: any): number
	local claimed = 0
	for _ = 1, 25 do
		local button, signal = popups.Open()
		if not button or not popups.Press(button, signal) then break end
		claimed += 1
	end
	popups.Claimed += claimed
	return claimed
end

function Popups.step(readOption: (string, any) -> any, popups: any)
	if readOption("AutoClaimPopups", false) then popups.Open() end
end

function Popups.create(player: any, getConnections: any, fireSignal: any): any
	local popups: any = { Claimed = 0 }
	function popups.Open() return Popups.open(player, Popups.find) end
	function popups.Press(button: any, signal: any) return Popups.press(button, signal, getConnections, fireSignal) end
	function popups.ClaimAll() return Popups.claimAll(popups) end
	return popups
end

function Spectate.set(state: any, workspace: any, parts: (any) -> (any, any, any), localParts: () -> (any, any), player: any): boolean
	local camera = workspace.CurrentCamera
	local _, _, humanoid = parts(player)
	if player and humanoid then
		state.Target = player
		camera.CameraSubject = humanoid
		return true
	end
	state.Target = nil
	local _, ownHumanoid = localParts()
	if ownHumanoid then camera.CameraSubject = ownHumanoid end
	return false
end

function Spectate.create(workspace: any, parts: (any) -> (any, any, any), localParts: () -> (any, any)): any
	local spectate: any = {}
	function spectate.Set(player: any) return Spectate.set(spectate, workspace, parts, localParts, player) end
	return spectate
end

function Esp.createFolder(newInstance: (string) -> any, coreGui: any): any
	local folder = newInstance("Folder")
	folder.Name = "AxisMM2Visuals"
	folder.Parent = coreGui
	return folder
end

function Esp.palette(newColor: (number, number, number) -> any): any
	return {
		Murderer = newColor(1, 0.23529411852359772, 0.23529411852359772),
		Sheriff = newColor(0.23529411852359772, 0.5490196347236633, 1),
		Hero = newColor(1, 0.8039215803146362, 0.23529411852359772),
		Innocent = newColor(0.3137255012989044, 0.9019607901573181, 0.47058823704719543),
		Zombie = newColor(0.5882353186607361, 0.23529411852359772, 0.7843137383460999),
		Survivor = newColor(0.3137255012989044, 0.9019607901573181, 0.47058823704719543),
	}
end

local AXIS_VISUALS=[====[
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
        entry.Name=text()entry.Distance=text()entry.Tags=text()entry.Tracer=line()
        entry.Warning=create("Highlight",{Adornee=model,FillTransparency=1,
            OutlineColor=config.WarningColor,Enabled=false,
            DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},model)
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
        for _,key in ipairs({"Box","Name","Distance","Tags","Tracer","Health","Warning"})do entry[key]:Destroy()end
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
            or config.PlayerTracers or config.PlayerChams or config.PlayerGlow or config.PlayerShader or config.TackleWarning
        if any then for _,actor in ipairs(state.Actors)do
            local model=actor.Character
            if model.Parent and actor.Root.Parent and(not actor.Friendly or config.ShowTeammates)and(actor.Root.Position-origin).Magnitude<=config.ESPDistance then
                seen[model]=true
                local entry=entries[model]or makeEntry(model)
                entry.Box.Visible=false entry.Name.Visible=false entry.Distance.Visible=false entry.Tags.Visible=false entry.Tracer.Visible=false entry.Health.Visible=false
                entry.Warning.Enabled=config.TackleWarning and state.HadBall and actor.Threat
                    and not actor.Friendly and (actor.Root.Position-origin).Magnitude<25
                entry.Warning.OutlineColor=config.WarningColor
                for _,bone in ipairs(entry.Bones)do bone.Line.Visible=false end
                local color=actor.Color or (actor.Friendly and config.TeamColor or config.EnemyColor)
                local top,topVisible=project(camera,actor.Root.Position+Vector3.new(0,3.5,0))
                local bottom,bottomVisible=project(camera,actor.Root.Position-Vector3.new(0,3.5,0))
                if topVisible and bottomVisible then
                    local height=math.abs(bottom.Y-top.Y)local width=height*.55
                    local x,y=top.X-width/2,math.min(top.Y,bottom.Y)
                    entry.Box.Position=UDim2.fromOffset(x,y)entry.Box.Size=UDim2.fromOffset(width,height)
                    entry.Stroke.Color=config.BoxColor or color entry.Box.Visible=config.PlayerESP
                    entry.Name.Text=actor.Name entry.Name.TextColor3=config.NameColor
                    entry.Name.Position=UDim2.fromOffset(top.X,y-2)entry.Name.Visible=config.PlayerNames
                    entry.Tags.Text=table.concat(actor.Tags or {}," · ")
                    entry.Tags.TextColor3=color
                    entry.Tags.Position=UDim2.fromOffset(top.X,y+height+36)
                    entry.Tags.Visible=config.PlayerNames and #entry.Tags.Text>0
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
]====]
local AXIS_CHAMS=[====[

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
]====]
function Esp.create(dependencies)
    local overlay=Instance.new("ScreenGui")
    overlay.Name="AxisMM2Visuals" overlay.IgnoreGuiInset=true overlay.ResetOnSpawn=false overlay.DisplayOrder=3
    overlay.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    overlay.Parent=type(gethui)=="function" and gethui() or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local config={ESPDistance=1500,ShowTeammates=true,TackleWarning=false,SkeletonThickness=1.2,ChamsMaterial="Neon",ChamsTransparency=.25}
    local state={Actors={}}
    local function create(class,properties,parent)
        local item=Instance.new(class)
        for key,value in pairs(properties)do item[key]=value end
        item.Parent=parent return item
    end
    local renderer=assert(loadstring(AXIS_VISUALS))()({Config=config,State=state,Overlay=overlay,Create=create,Chams=AXIS_CHAMS})
    local read=dependencies.ReadOption
    local color=Color3.fromRGB(45,140,255)
    local gunLabel=create("TextLabel",{Name="DroppedGun",BackgroundTransparency=1,Size=UDim2.fromOffset(180,20),AnchorPoint=Vector2.new(.5,.5),TextSize=13,Font=Enum.Font.GothamMedium,TextStrokeTransparency=.4,Visible=false},overlay)
    local esp={HasDrawing=false,Entries={},Folder=overlay}
    local connection
    local enabled=true
    function esp.Color(role)return read("Color"..tostring(role),dependencies.Palette[role] or color)end
    function esp.Update()
        if not enabled then return end
        table.clear(state.Actors)
        local master=read("EspOn",false)
        local roles=Config.selection(read("EspRoles",{}))
        local root=select(1,dependencies.LocalParts())
        local camera=workspace.CurrentCamera
        if not camera then return end
        for _,player in ipairs(dependencies.Players:GetPlayers())do
            if player~=dependencies.Player then
                local model,part=dependencies.CharacterParts(player)
                local role=dependencies.Round.Role(player)or "Innocent"
                if master and model and part and roles[role]then
                    state.Actors[#state.Actors+1]={Character=model,Root=part,Friendly=false,Name=player.DisplayName,Tags={role},Color=esp.Color(role)}
                end
            end
        end
        local mapping={PlayerESP="EspBoxes",PlayerNames="EspNames",PlayerDistance="EspDistance",PlayerHealth="EspHealth",PlayerSkeletons="EspSkeletons",PlayerTracers="EspTracers",PlayerChams="EspChams",PlayerGlow="EspGlow",PlayerShader="EspShader"}
        for key,flag in pairs(mapping)do config[key]=master and read(flag,false)end
        for _,key in ipairs({"BoxColor","NameColor","DistanceColor","HealthColor","SkeletonColor","TracerColor","ChamsColor","GlowColor","ShaderColor"})do config[key]=read(key,color)end
        config.EnemyColor=color config.TeamColor=color config.WarningColor=color
        config.SkeletonThickness=read("SkeletonThickness",1.2)
        config.ESPDistance=read("EspMaxDistance",1500)
        config.ChamsMaterial=read("ChamsMaterial","Neon")
        config.ChamsTransparency=read("ChamsTransparency",.25)
        renderer.Render(camera,root and root.Position or camera.CFrame.Position)
        gunLabel.Visible=false
        local gun=read("EspGun",false)and dependencies.Round.GunDrop()
        local point=gun and dependencies.ObjectPosition(gun)
        if point then
            local position,visible=camera:WorldToViewportPoint(point)
            if visible and position.Z>0 then
                gunLabel.Position=UDim2.fromOffset(position.X,position.Y)
                gunLabel.Text="Dropped gun" gunLabel.TextColor3=read("GunColor",color)gunLabel.Visible=true
            end
        end
        esp.ActorCount=#state.Actors
    end
    function esp.Remove(player)
        for i=#state.Actors,1,-1 do if state.Actors[i].Character==player.Character then table.remove(state.Actors,i)end end
        task.defer(esp.Update)
    end
    function esp.Destroy()
        if not enabled then return end enabled=false
        if connection then connection:Disconnect()end
        renderer.Cleanup()overlay:Destroy()
        if dependencies.Folder then dependencies.Folder:Destroy()end
    end
    connection=game:GetService("RunService").RenderStepped:Connect(esp.Update)
    return esp
end

function Hooks.point(player: any, readOption: (string, boolean) -> any, parts: (any) -> (any, any, ...any), round: any, combat: any, ping: () -> number): any
	local character = player.Character
	if not character then return nil end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return nil end

	if tool:HasTag("Weapon_Gun") and readOption("GunSilentAim", false) then
		local _, root = parts(round.Murderer())
		if not root then return nil end
		local aim = combat.Aim(root)
		return aim
	end
	if tool:HasTag("Weapon_Knife") and readOption("KnifeSilentAim", false) then
		local target = if readOption("KnifeAimSheriff", true) then round.Sheriff() else nil
		if not target then
			local targets = combat.Targets()
			target = if targets[1] then targets[1].Player else nil
		end
		local _, root = parts(target)
		if not root then return nil end
		local handle = tool:FindFirstChild("Handle")
		local travel = if handle then (root.Position - handle.Position).Magnitude / 96 else 0
		return root.Position + root.AssemblyLinearVelocity * (travel + ping())
	end
	return nil
end

function Hooks.installMethod(cache: any, service: any, hooks: any, name: string, convert: (any) -> ...any)
	local original = cache[name] or service[name]
	if type(original) ~= "function" then return end
	cache[name] = original
	hooks.Orig[name] = original
	service[name] = function(...: any): (...any)
		local point = hooks.Point
		local ok, target = pcall(point)
		if ok and target then return convert(target) end
		return (original :: any)(...)
	end
end

function Hooks.install(service: any, hooks: any, installMethod: (string, (any) -> ...any) -> (), newFrame: (any) -> ...any)
	if not service then return end
	if next(hooks.Orig) then return end
	installMethod("GetMouseTargetCFrame", function(point) return newFrame(point) end)
	installMethod("GetTargetPosition", function(point) return newFrame(point) end)
end

function Hooks.remove(hooks: any, service: any)
	for name, original in pairs(hooks.Orig) do
		if service then service[name] = original end
	end
	table.clear(hooks.Orig)
end

export type HooksDependencies = {
	Service: any,
	Cache: any?,
	Player: any,
	ReadOption: (string, boolean) -> any,
	CharacterParts: (any) -> (any, any, ...any),
	Round: any,
	Combat: any,
	Ping: () -> number,
	NewFrame: (any) -> ...any,
}

function Hooks.cache(environment: any): any
	local cache = environment.AxisMM2WeaponOriginals or {}
	environment.AxisMM2WeaponOriginals = cache
	return cache
end

function Hooks.create(dependencies: HooksDependencies): any
	local hooks: any = { Orig = {} }
	local cache = dependencies.Cache or {}
	function hooks.Point()
		return Hooks.point(dependencies.Player, dependencies.ReadOption, dependencies.CharacterParts, dependencies.Round, dependencies.Combat, dependencies.Ping)
	end
	function hooks.Install()
		Hooks.install(dependencies.Service, hooks, function(name, convert)
			Hooks.installMethod(cache, dependencies.Service, hooks, name, convert)
		end, dependencies.NewFrame)
	end
	function hooks.Remove() Hooks.remove(hooks, dependencies.Service) end
	return hooks
end

function Server.list(gameObject: any, http: any, order: any): (any, string?)
	local sortOrder = if order == "Fewest" then "Asc" else "Desc"
	local url = "https://games.roblox.com/v1/games/" .. gameObject.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100&excludeFullGames=true"
	local fetched, body = pcall(function() return gameObject:HttpGet(url) end)
	if not fetched then return nil, "Could not get the server list" end
	local decoded, data = pcall(function() return http:JSONDecode(body) end)
	if not decoded or type(data) ~= "table" or type(data.data) ~= "table" then return nil, "Bad server list" end
	local servers = {}
	for _, server: any in ipairs(data.data :: any) do
		if server.id ~= gameObject.JobId and type(server.playing) == "number" and type(server.maxPlayers) == "number" and server.playing < server.maxPlayers and (order ~= "Fewest" or server.playing > 1) then
			table.insert(servers, server)
		end
	end
	table.sort(servers, function(a: any, b: any)
		return if order == "Fewest" then a.playing < b.playing else a.playing > b.playing
	end)
	return servers
end

function Server.hop(server: any, minimum: (number, number) -> number, random: (number, number) -> number, teleport: any, gameObject: any, player: any, order: any): (boolean, any)
	local servers, failure = server.List(order)
	if not servers then return false, failure end
	if #servers == 0 then return false, "No other server found" end
	local selected = servers[random(1, minimum(5, #servers))]
	local action = teleport.TeleportToPlaceInstance
	local ok, result = pcall(action, teleport, gameObject.PlaceId, selected.id, player)
	if not ok then return false, result end
	return true, string.format("%d/%d players", selected.playing, selected.maxPlayers)
end

function Server.rejoin(players: any, teleport: any, gameObject: any, player: any): (boolean, ...any)
	local count = #players:GetPlayers()
	if count <= 1 then
		local action = teleport.Teleport
		return pcall(action, teleport, gameObject.PlaceId, player)
	end
	local action = teleport.TeleportToPlaceInstance
	return pcall(action, teleport, gameObject.PlaceId, gameObject.JobId, player)
end

export type ServerDependencies = {
	Game: any,
	Http: any,
	Players: any,
	Teleport: any,
	Player: any,
	Minimum: (number, number) -> number,
	Random: (number, number) -> number,
}

function Server.create(dependencies: ServerDependencies): any
	local server: any = {}
	function server.List(order: any) return Server.list(dependencies.Game, dependencies.Http, order) end
	function server.Hop(order: any) return Server.hop(server, dependencies.Minimum, dependencies.Random, dependencies.Teleport, dependencies.Game, dependencies.Player, order) end
	function server.Rejoin() return Server.rejoin(dependencies.Players, dependencies.Teleport, dependencies.Game, dependencies.Player) end
	return server
end

function Webhook.url(readOption: (string, any) -> any, allowedHosts: { [string]: boolean }): string?
	local value = readOption("_WebhookURL", "")
	if type(value) ~= "string" then return nil end
	local url = string.match(value, "^%s*(.-)%s*$") :: string
	local host = string.match(url, "^https://([^/]+)/api/webhooks/%d+/[%w_%-]+$")
	if not host or not allowedHosts[host] then return nil end
	return url
end

function Webhook.wants(readOption: (string, any) -> any, selectOptions: (any) -> any, event: any): boolean
	local selected = selectOptions(readOption("WebhookEvents", {}))
	return selected[event] == true
end

function Webhook.embed(readOption: (string, any) -> any, player: any, dateTime: any, title: any, description: any, color: any, fields: any): any
	local timestamp = dateTime.now():ToIsoDate()
	local name = if readOption("WebhookHideName", false) then "Hidden" else player.Name
	return {
		title = title,
		description = description,
		color = color or 4891615,
		fields = fields or {},
		timestamp = timestamp,
		footer = { text = "Axis | Murder Mystery 2 | " .. name },
	}
end

function Webhook.decorate(readOption: (string, any) -> any, player: any, webhook: any, embed: any): any
	if not readOption("WebhookHideName", false) then
		embed.author = { name = player.Name, icon_url = webhook.GetAvatar() }
	end
	return embed
end

function Webhook.getAvatar(webhook: any, request: any, player: any, http: any): any
	if webhook.Avatar ~= nil then return webhook.Avatar or nil end
	webhook.Avatar = false
	if not request then return nil end
	local url = string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=150x150&format=Png", player.UserId)
	local ok, response = pcall(request, { Url = url, Method = "GET" })
	if ok and response and response.StatusCode == 200 then
		local decoded, result = pcall(function() return http:JSONDecode(response.Body or "") end)
		if decoded and result and result.data and result.data[1] and result.data[1].imageUrl then
			webhook.Avatar = result.data[1].imageUrl
		end
	end
	return webhook.Avatar or nil
end

function Webhook.send(readOption: (string, any) -> any, wants: (any) -> any, webhook: any, event: any, payload: any)
	if not readOption("WebhookEnabled", false) or not wants(event) or not webhook.Url() then return end
	if #webhook.Queue >= 20 then table.remove(webhook.Queue, 1) end
	table.insert(webhook.Queue, payload)
end

function Webhook.post(webhook: any, request: any, http: any, payload: any): (boolean, ...string?)
	local url = webhook.Url()
	if not url then return false, "Invalid webhook URL" end
	if not request then return false, "Your executor has no request function" end
	local body = http:JSONEncode(payload)
	local ok, response = pcall(request, { Url = url, Method = "POST", Body = body, Headers = { ["Content-Type"] = "application/json" } })
	if not ok or not response then return false, "Request failed" end
	if response.StatusCode == 200 or response.StatusCode == 204 then return true end
	return false, "HTTP " .. tostring(response.StatusCode)
end

function Webhook.step(webhook: any, clock: () -> number, makeEmbed: (any) -> any, readOption: (string, any) -> any, log: (string) -> ())
	if #webhook.Queue == 0 or clock() - webhook.LastSent < 2.5 then return end
	local embeds = {}
	while #webhook.Queue > 0 and #embeds < 5 do
		table.insert(embeds, makeEmbed(table.remove(webhook.Queue, 1)))
	end
	local ping = string.match(tostring(readOption("_WebhookPing", "")), "%d+")
	local content = if ping then "<@" .. ping .. ">" else nil
	webhook.LastSent = clock()
	local ok, failure = webhook.Post({ username = "Axis", content = content, embeds = embeds })
	if not ok then log("Webhook: " .. tostring(failure)) end
end

function Webhook.summary(webhook: any, fields: () -> any, decorate: (any) -> any, forced: any): (...any)
	local makeEmbed = webhook.Embed
	local embed = makeEmbed("Session summary", nil, 4891615, fields())
	if forced then
		local post = webhook.Post
		return post({ username = "Axis", embeds = { decorate(embed) } })
	end
	webhook.Send("Session Summary", embed)
end

function Webhook.duration(seconds: number, maximum: (number, number) -> number, floor: (number) -> number): string
	local value = maximum(0, floor(seconds))
	if value >= 3600 then return string.format("%dh %02dm", value // 3600, value % 3600 // 60) end
	return string.format("%dm %02ds", value // 60, value % 60)
end

function Webhook.summaryFields(formatNumber: (any) -> any, stats: any, maximum: (number, number) -> number, duration: (number) -> any, now: () -> number): { any }
	local fields = {
		{ name = "Coins This Session", value = formatNumber(stats.Coins), inline = true },
		{ name = "Rounds", value = formatNumber(stats.Rounds), inline = true },
		{ name = "Kills", value = formatNumber(stats.Kills), inline = true },
	}

	return fields
end

function Webhook.summaryStep(timer: any, readOption: (string, any) -> any, clock: () -> number, summary: (boolean) -> ...any)
	local option = readOption("WebhookSummaryEvery", "30 min")
	local interval = if option == "15 min" then 900 else if option == "60 min" then 3600 else 1800
	if clock() - timer.LastSummary >= interval then
		timer.LastSummary = clock()
		summary(false)
	end
end

export type WebhookDependencies = {
	ReadOption: (string, any) -> any,
	Player: any,
	DateTime: any,
	Http: any,
	Request: any,
	Clock: () -> number,
	Log: (string) -> (),
}

function Webhook.create(dependencies: WebhookDependencies): (any, () -> ())
	local webhook: any = { Queue = {}, LastSent = 0 }
	local hosts = { ["discord.com"] = true, ["discordapp.com"] = true, ["canary.discord.com"] = true, ["ptb.discord.com"] = true }
	function webhook.Url() return Webhook.url(dependencies.ReadOption, hosts) end
	function webhook.GetAvatar() return Webhook.getAvatar(webhook, dependencies.Request, dependencies.Player, dependencies.Http) end
	function webhook.Embed(title: any, description: any, color: any, fields: any)
		return Webhook.embed(dependencies.ReadOption, dependencies.Player, dependencies.DateTime, title, description, color, fields)
	end
	function webhook.Send(event: any, payload: any)
		Webhook.send(dependencies.ReadOption, function(name) return Webhook.wants(dependencies.ReadOption, Config.selection, name) end, webhook, event, payload)
	end
	function webhook.Post(payload: any) return Webhook.post(webhook, dependencies.Request, dependencies.Http, payload) end
	local function step()
		Webhook.step(webhook, dependencies.Clock, function(embed) return Webhook.decorate(dependencies.ReadOption, dependencies.Player, webhook, embed) end, dependencies.ReadOption, dependencies.Log)
	end
	return webhook, step
end

export type CombatStepDependencies = {
	Combat: any,
	Round: any,
	Player: any,
	Quest: any,
	ReadOption: (string, any) -> any,
	Ready: (string, any) -> any,
	ReadNumber: (string, number) -> any,
	CharacterParts: (any) -> (any, any, ...any),
	ObjectPosition: (any) -> any,
}

function Combat.step(dependencies: CombatStepDependencies)
	local combat, round = dependencies.Combat, dependencies.Round
	local readOption, readNumber, ready = dependencies.ReadOption, dependencies.ReadNumber, dependencies.Ready
	if combat.Busy or not round.InRound() then return end

	if round.MyRole() == "Murderer" then
		if not round.Tool(dependencies.Player, "Weapon_Knife") then return end
		local throwing = false
		if (readOption("AutoKillAll", false) or throwing) and ready("autokill", readNumber("KillAllDelay", 3)) then
			if throwing then combat.ThrowAll() else combat.KillAll() end
			return
		end
		if readOption("AutoKillSheriff", false) then
			local sheriff = round.Sheriff()
			if sheriff and ready("autosheriff", 1.5) then
				combat.KillOne(sheriff)
				return
			end
		end
		if readOption("KillAura", false) then
			local range = readNumber("KillAuraRange", 12)
			for _, target: any in ipairs(combat.Targets() :: any) do
				if target.Dist <= range and ready("aura" .. target.Player.UserId, 0.5) then
					combat.StabAt(target.Player, false)
				end
			end
		end
		return
	end

	if round.Tool(dependencies.Player, "Weapon_Gun") then
		local wantsShoot = false
		if (readOption("AutoShoot", false) or wantsShoot) and ready("autoshoot", readNumber("ShootCooldown", 15) / 10) then
			combat.ShootMurderer(readOption("ShootTeleport", false) or wantsShoot)
		end
		return
	end

	if (readOption("AutoGrabGun", false)) and round.GunDrop() and ready("grabgun", 2) then
		local drop = round.GunDrop()
		local murderer = round.Murderer()
		local _, murdererRoot = dependencies.CharacterParts(murderer)
		local dropPosition = dependencies.ObjectPosition(drop)
		if dropPosition and (not murdererRoot or (murdererRoot.Position - dropPosition).Magnitude >= readNumber("GrabSafeRadius", 15)) then
			combat.GrabGun()
		end
	end
end

function Config.keybind(option: any, typeOf: (any) -> string, keyCodes: any): any
	if not option then return nil end

	local getBind = option.GetBind
	local binding

	if getBind then
		local ok, result = pcall(getBind, option)
		if ok then binding = result end
	end

	binding = binding or option.Value
	if typeOf(binding) == "EnumItem" then return binding end
	if type(binding) ~= "string" then return nil end
    binding=binding:gsub("^Enum.KeyCode%.","")

	local ok, key = pcall(function() return keyCodes[binding] end)
	return if ok then key else nil
end

function Config.selection(value: any): { [string]: boolean }
	local selected = {}
	if type(value) ~= "table" then return selected end

	for key, item in pairs(value) do
		if type(key) == "number" then
			selected[tostring(item)] = true
			continue
		end

		if item then selected[tostring(key)] = true end
	end

	return selected
end

function Config.selectionsEqual(first: any, second: any): boolean
	for key in pairs(first) do
		if not second[key] then return false end
	end

	for key in pairs(second) do
		if not first[key] then return false end
	end

	return true
end

function Config.validKeybind(value: any, keyCodes: any): boolean
	if type(value) ~= "string" then return false end
	if value == "MouseLeft" or value == "MouseRight" then return true end

	local ok = pcall(function() return keyCodes[value] end)
	return ok
end

local base64Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

function Config.name(value: any): string?
	local name = tostring(value or "")
	name = string.gsub(name, "[^%w%s%-_]", "")
	name = string.gsub(name, "^%s+", "")
	name = string.gsub(name, "%s+$", "")
	if name == "" or name:lower()=="autosave" or name:lower()=="private" then return nil end

	return string.sub(name, 1, 32)
end

function Config.skippedSuffix(count: number): string
	if count > 0 then return ", " .. tostring(count) .. " skipped" end
	return ""
end

function Config.ensureFolder(isFolder: any, makeFolder: any, path: any)
	if not isFolder or not makeFolder then return end
	if not (isFolder :: any)(path) then pcall(makeFolder, path) end
end

function Config.writeJson(ensureFolder: (any) -> (), paths: any, http: any, writeFile: any, path: any, data: any): boolean
	if not writeFile then return false end

	ensureFolder(paths.Root)
	ensureFolder(paths.Game)
    ensureFolder(paths.Configs)
	local encoded, json = pcall(http.JSONEncode, http, data)
	if not encoded then return false end

	local ok = pcall(writeFile, path, json)
	return ok
end

function Config.readJson(http: any, isFile: any, readFile: any, path: any): any
	if not isFile or not readFile or not (isFile :: any)(path) then return nil end

	local ok, data = pcall(function()
		local decode = http.JSONDecode
		return decode(http, (readFile :: any)(path))
	end)
	if ok and type(data) == "table" then return data end
	return nil
end

function Config.restore(config: any, paths: any, readJson: (any) -> any, options: any, environment: any)
	local resume = environment.AxisMM2Resume == true
	environment.AxisMM2Resume = nil
	config.Loading = true

	local saved = readJson(paths.Autosave)
	if saved and saved.Autosave ~= false then config.Apply(saved) end

	local private = readJson(paths.Private)
	if private then
		for flag in pairs(config.Private) do
			local value, option = private[flag], options[flag]
			if type(value) == "string" and option then
				pcall(function() option:SetValue(value) end)
			end
		end
	end
	config.Loading = false
end

function Config.autosave(config: any, readOption: (string, boolean) -> any, http: any, writeJson: (any, any) -> any, paths: any, options: any)
	if config.Loading or not readOption("Autosave", true) then return end

	local data = config.Collect()
	local encoded, json = pcall(http.JSONEncode, http, data)

	if encoded and json ~= config.Last then
		config.Last = json
		writeJson(paths.Autosave, data)
	end

	local private = {}
	for flag in pairs(config.Private) do
		if options[flag] then private[flag] = options[flag].Value end
	end

	local privateEncoded, privateJson = pcall(http.JSONEncode, http, private)
	if privateEncoded and privateJson ~= config.LastPrivate then
		config.LastPrivate = privateJson
		writeJson(paths.Private, private)
	end
end

function Config.list(paths: any, listFiles: any, isFolder: any): { string }
	local names = {}
	if not listFiles or not isFolder or not (isFolder :: any)(paths.Configs) then return names end

	for _, path in ipairs((listFiles :: any)(paths.Configs)) do
		local name = string.match(tostring(path), "([^/\\]+)%.json$")
		if name and name~="private" then table.insert(names, name) end
	end

	table.sort(names)
	return names
end

function Config.throttle(state: { LastYield: number }, clock: () -> number, wait: () -> ())
	if clock() - state.LastYield > 0.02 then
		wait()
		state.LastYield = clock()
	end
end

export type ConfigOptionDependencies = {
	Clamp: (number, number, number) -> number,
	ValidKeybind: (any) -> boolean,
	Keybind: (any) -> any,
	Selection: (any) -> { [string]: boolean },
	SelectionsEqual: (any, any) -> boolean,
	FromHex: (string) -> any,
}

function Config.applyOption(dependencies: ConfigOptionDependencies, option: any, value: any): boolean
	local kind = option.Type

	if kind == "Toggle" then
		if type(value) ~= "boolean" then return false end
		if option.Value ~= value then pcall(option.SetValue, option, value) end
		return true
	end

	if kind == "Slider" then
		local number = tonumber(value)
		if number == nil then return false end

		number = dependencies.Clamp(number, option.Min or number, option.Max or number)
		if option.Value ~= number then pcall(option.SetValue, option, number) end
		return true
	end

	if kind == "Input" then
		if type(value) ~= "string" and type(value) ~= "number" then return false end

		local text = tostring(value)
		if option.Value ~= text then pcall(option.SetValue, option, text) end
		return true
	end

	if kind == "Keybind" then
        if type(value)=="table"then
            local key=value.Key
            if type(key)~="string"then return false end
            local ok=pcall(option.SetValue,option,key,value.Mode)
            return ok
        end
		if not dependencies.ValidKeybind(value) then return false end

		local current = dependencies.Keybind(option)
		if current and current.Name == value then return true end

		pcall(option.SetValue, option, value, option.Mode)
		return true
	end

	if kind == "Dropdown" then
		if option.Multi then
			local selected = dependencies.Selection(value)
			local choices = {}

			for choice in pairs(selected) do
				if not table.find(option.Values or {}, choice) then
					selected[choice] = nil
					continue
				end

				table.insert(choices, choice)
			end

			local current = dependencies.Selection(option.Value)
			if not dependencies.SelectionsEqual(selected, current) then pcall(option.SetValue, option, choices) end
			return true
		end

		if type(value) ~= "string" or not table.find(option.Values or {}, value) then return false end
		if option.Value ~= value then pcall(option.SetValue, option, value) end
		return true
	end

	if kind == "Colorpicker" then
		if type(value) ~= "string" then return false end

		local ok, color = pcall(dependencies.FromHex, value)
		if not ok then return false end

		pcall(option.SetValueRGB, option, color)
		return true
	end

	return false
end

function Config.collect(options: any, keybind: (any) -> any, typeOf: (any) -> string): any
	local allowed = { Toggle = true, Slider = true, Input = true, Keybind = true, Dropdown = true, Colorpicker = true }
	local result = {}

	for flag, option in pairs(options) do
		if string.sub(tostring(flag), 1, 1) == "_" or not allowed[option.Type] then continue end

		if option.Type == "Colorpicker" then
			local color = option.Value
			if typeOf(color) == "Color3" then result[flag] = option.Value:ToHex() end
			continue
		end

		if option.Type == "Keybind" then
			local key = keybind(option)
			if key then result[flag] = {Key=key.Name,Mode=option.Native and option.Native.ModeSelected or "Toggle"}end
			continue
		end

		result[flag] = option.Value
	end

	result._version = 1
	return result
end

function Config.apply(options: any, safeToggles: any, applyOption: (any, any) -> any, throttle: () -> (), data: any, safeMode: any): (number, number)
	if type(data) ~= "table" then return 0, 0 end

	local applied, failed = 0, 0

	for flag, value in pairs(data) do
		local option = options[flag]
		if flag == "_version" then continue end

		if not option or string.sub(tostring(flag), 1, 1) == "_" then
			failed += 1
			continue
		end

		if safeMode and option.Type == "Toggle" and not safeToggles[flag] then continue end

		local success = applyOption(option, value)
		if success then applied += 1 end
		if not success then failed += 1 end

		throttle()
	end

	return applied, failed
end

export type ConfigDependencies = {
	Options: any,
	Http: any,
	Paths: any,
	ReadOption: (string, boolean) -> any,
	TypeOf: (any) -> string,
	KeyCodes: any,
	FromHex: (string) -> any,
	Clamp: (number, number, number) -> number,
	Throttle: () -> (),
	IsFolder: any,
	MakeFolder: any,
	WriteFile: any,
	ListFiles: any,
}

function Config.paths(): any
	return {
		Root = "Axis",
		Game = "Axis/Config",
		Configs = "Axis/Config/"..tostring(game.GameId),
		Autosave = "Axis/Config/"..tostring(game.GameId).."/autosave.json",
		Private = "Axis/Config/"..tostring(game.GameId).."/private.json",
		
	}
end

function Config.create(dependencies: ConfigDependencies): any
	local config: any = {
		Loading = false,
		Last = "",
		LastPrivate = "",
		Private = { _WebhookURL = true, _WebhookPing = true },
	}
	local safeToggles = {
		AnnounceGun = true, AnnounceRoles = true, AntiAFK = true, AutoClaimPopups = true, AutoRejoin = true,
		Autosave = true, AvoidMurderer = true, EspDistance = true, EspGun = true, EspHighlight = true,
		EspNames = true, EspOn = true, EspTracers = true, Fullbright = true, KnifeAimSheriff = true,
		LowGraphics = true, SheriffFirst = true, SkipUpperCoins = true, UIAcrylic = true,
		WebhookEnabled = true, WebhookHideName = true,
	}
	local codec = { Encode = Config.encode, Decode = Config.decode }
	local function keybind(option: any) return Config.keybind(option, dependencies.TypeOf, dependencies.KeyCodes) end
	local optionDependencies = {
		Clamp = dependencies.Clamp,
		ValidKeybind = function(value: any) return Config.validKeybind(value, dependencies.KeyCodes) end,
		Keybind = keybind, Selection = Config.selection, SelectionsEqual = Config.selectionsEqual,
		FromHex = dependencies.FromHex,
	}
	local function ensureFolder(path: any) Config.ensureFolder(dependencies.IsFolder, dependencies.MakeFolder, path) end
	local function writeJson(path: any, data: any)
		return Config.writeJson(ensureFolder, dependencies.Paths, dependencies.Http, dependencies.WriteFile, path, data)
	end

	function config.Collect() return Config.collect(dependencies.Options, keybind, dependencies.TypeOf) end
	function config.Apply(data: any, safeMode: any)
		return Config.apply(dependencies.Options, safeToggles, function(option: any, value: any)
			return Config.applyOption(optionDependencies :: any, option, value)
		end, dependencies.Throttle, data, safeMode)
	end
	function config.Autosave() Config.autosave(config, dependencies.ReadOption, dependencies.Http, writeJson, dependencies.Paths, dependencies.Options) end
	function config.List() return Config.list(dependencies.Paths, dependencies.ListFiles, dependencies.IsFolder) end

	return config
end

function Lifecycle.isRunning(state: { Running: boolean? }, getEnvironment: () -> { AxisMM2Session: unknown }, session: unknown): boolean?
	return state.Running and getEnvironment().AxisMM2Session == session
end

function Lifecycle.resetPrevious(environment: any)
	for _, name in { "AxisMM2", "AxisMM2MM2" } do
		local previous = environment[name]
		if type(previous) == "table" and previous.Unload then pcall(previous.Unload) end
		environment[name] = nil
	end
end

function Lifecycle.initializeSession(environment: any, http: any): (any, any)
	local state = { Running = true, Log = "Loading...", Connections = {} }
	environment.AxisMM2 = state
	local session = http:GenerateGUID(false)
	environment.AxisMM2Session = session
	return state, session
end

function Lifecycle.startSession(environment: any, http: any): (any, any)
	Lifecycle.resetPrevious(environment)
	return Lifecycle.initializeSession(environment, http)
end

function Lifecycle.createStats(time: () -> number): any
	return { Coins = 0, Rounds = 0, Kills = 0, StartedAt = time() }
end

function Lifecycle.log(state: any, date: (string) -> string, message: any)
	state.Log = date("%H:%M:%S") .. "  " .. tostring(message)
end

function Lifecycle.finishSession(state: any, modules: any, date: (string) -> string)
	state.Modules = {
		Stats = modules.Stats, Combat = modules.Combat, Spectate = modules.Spectate,
		Opti = modules.Opti, ESP = modules.ESP, Round = modules.Round, Quest = modules.Quest,
		Server = modules.Server, Move = modules.Move, SilentAim = modules.SilentAim, Mover = modules.Mover,
		Config = modules.Config, Farm = modules.Farm, Webhook = modules.Webhook,
		Popups = modules.Popups, World = modules.World,
	}
	state.Ready = true
	Lifecycle.log(state, date, "Hub loaded")
end

function Lifecycle.protect(log: (string) -> (), callback: (...any) -> ...any, ...: any): boolean
	local ok, raised = pcall(callback, ...)
	if not ok then log("Error: " .. tostring(raised)) end
	return ok
end

function Lifecycle.schedule(spawn: (...any) -> ...any, protect: (...any) -> ...any, callback: (...any) -> ...any, ...: any): (...any)
	return spawn(protect, callback, ...)
end

function Lifecycle.delay(delay: (...any) -> ...any, protect: (...any) -> ...any, seconds: any, callback: (...any) -> ...any, ...: any): (...any)
	return delay(seconds, protect, callback, ...)
end

function Lifecycle.callback(protect: (...any) -> ...any, callback: (...any) -> ...any): (...any) -> ()
	return function(...: any) protect(callback, ...) end
end

function Lifecycle.ready(timers: any, clock: () -> number, key: any, interval: any): boolean
	local now = clock()
	if now < (timers[key] or 0) then return false end
	timers[key] = now + interval
	return true
end

function Lifecycle.idled(readOption: (string, boolean) -> any, virtualUser: any, zero: any)
	if not readOption("AntiAFK", true) then return end
	pcall(function()
		virtualUser:CaptureController()
		virtualUser:ClickButton2(zero)
	end)
end

export type DisconnectDependencies = {
	Service: any,
	Ready: (string, number) -> any,
	Webhook: any,
	Fields: () -> any,
	State: any,
	ReadOption: (string, any) -> any,
	Delay: (number, () -> ()) -> (),
	Teleport: any,
	Game: any,
	Player: any,
	QueueTeleport: any,
}

function Lifecycle.installTeleport(state,player,teleport,queue,gameId,flush)
    if type(queue)~="function"then state.TeleportAutoload="Unavailable"return false end
    local bootstrap=string.format([==[
if not game:IsLoaded()then game.Loaded:Wait()end
if game.GameId~=%d then return end
local env=getgenv()
if env.AxisMM2TeleportJob==game.JobId then return end
local previous=env.AxisMM2App
if previous and previous.State and previous.State.Running then return end
local ok=pcall(function()
    local source=game:HttpGet("https://raw.githubusercontent.com/smcpresezzi/xd/main/murder-mystery-2.lua")
    local run=loadstring(source,"Axis MM2")
    if not run then return end
    env.AxisMM2TeleportJob=game.JobId
    env.AxisMM2Resume=true
    run()
end)
if not ok then env.AxisMM2TeleportJob=nil end
]==],gameId)
    local queued=false
    local function enqueue(teleportState)
        if not state.Running or queued then return end
        if teleportState~=Enum.TeleportState.Started and teleportState~=Enum.TeleportState.InProgress then return end
        if flush then pcall(flush)end
        local ok=pcall(queue,bootstrap)
        queued=ok
        state.TeleportAutoload=ok and "Queued" or "Failed"
    end
    table.insert(state.Connections,player.OnTeleport:Connect(enqueue))
    table.insert(state.Connections,teleport.TeleportInitFailed:Connect(function(who)
        if who==player then queued=false state.TeleportAutoload="Ready"end
    end))
    state.TeleportAutoload="Ready"
    return true
end

function Lifecycle.disconnected(dependencies: DisconnectDependencies)
	local message = dependencies.Service:GetErrorMessage()
	if message == nil or message == "" then return end
	if dependencies.Ready("disconnectHook", 30) then
		local send = dependencies.Webhook.Send
		local embed = dependencies.Webhook.Embed
		send("Disconnected", embed("Disconnected", message, 15158332, dependencies.Fields()))
	end
	if dependencies.State.Rejoining or not dependencies.ReadOption("AutoRejoin", false) then return end
	dependencies.State.Rejoining = true
	dependencies.Delay(3, function()
		pcall(function()
			local teleport = dependencies.Teleport
			local action = teleport.Teleport
			action(teleport, dependencies.Game.PlaceId, dependencies.Player)
		end)
		dependencies.Delay(20, function() dependencies.State.Rejoining = false end)
	end)
end

function Lifecycle.loop(isRunning: () -> any, callback: () -> (), log: (string) -> (), name: any, wait: (any) -> (), delay: any)
	while isRunning() do
		local ok, raised = pcall(callback)
		if not ok then
			local suffix = if name then " in " .. name else ""
			log("Error" .. suffix .. ": " .. tostring(raised))
		end

		wait(delay)
	end
end

export type TaskDependencies = {
	Spawn: (...any) -> ...any,
	Protect: (...any) -> ...any,
	IsRunning: () -> any,
	Log: (string) -> (),
	Wait: (any) -> (),
	Farm: () -> (),
	InstallHooks: () -> (),
	Combat: () -> (),
	Esp: () -> (),
	Fullbright: () -> (),
	Movement: () -> (),
	Popups: () -> (),
	Quests: () -> (),
	Webhook: () -> (),
	PrepareSummary: () -> (),
	Summary: () -> (),
	Stats: () -> (),
	ConnectGameplay: () -> (),
	PrepareInterface: () -> (),
	FinishInterface: () -> (),
	PopulateServers: () -> (),
	Interface: () -> (),
	RestoreConfig: () -> (),
	Autosave: () -> (),
	State: any,
	Players: any,
	RunService: any,
	Input: any,
	Player: any,
	Workspace: any,
	GuiService: any,
	Library: any,
	RemoveEsp: (...any) -> (),
	HasDrawing: boolean,
	Tracers: (...any) -> (),
	NoclipFrame: (...any) -> (),
	JumpRequest: (...any) -> (),
	InputBegan: (...any) -> (),
	CharacterAdded: (...any) -> (),
	WatchMap: (any) -> (),
	ChildAdded: (...any) -> (),
	ChildRemoved: (...any) -> (),
	Disconnected: (...any) -> (),
	Idled: (...any) -> (),
	PlayerAdded: (...any) -> (),
	PlayerRemoving: (...any) -> (),
	Unload: (...any) -> (),
}

function Lifecycle.startRuntime(dependencies: TaskDependencies)
	local function start(name: string, callback: () -> (), delay: number)
		dependencies.Spawn(function()
			Lifecycle.loop(dependencies.IsRunning, callback, dependencies.Log, name, dependencies.Wait, delay)
		end)
	end
	local function connect(signal: any, callback: (...any) -> ())
		local connection = signal:Connect(Lifecycle.callback(dependencies.Protect, callback))
		table.insert(dependencies.State.Connections, connection)
	end

	dependencies.Spawn(dependencies.Farm)
	dependencies.InstallHooks()
	start("combat", dependencies.Combat, 0.12)
	connect(dependencies.Players.PlayerRemoving, dependencies.RemoveEsp)
	if dependencies.HasDrawing then connect(dependencies.RunService.RenderStepped, dependencies.Tracers) end
	start("fullbright", dependencies.Fullbright, 0.5)
	connect(dependencies.RunService.Stepped, dependencies.NoclipFrame)
	start("movement", dependencies.Movement, 0.1)
	connect(dependencies.Input.JumpRequest, dependencies.JumpRequest)
	connect(dependencies.Input.InputBegan, dependencies.InputBegan)
	connect(dependencies.Player.CharacterAdded, dependencies.CharacterAdded)
	start("popups", dependencies.Popups, 0.5)
	start("webhook", dependencies.Webhook, 1)
	dependencies.PrepareSummary()
	start("summary", dependencies.Summary, 30)
	dependencies.ConnectGameplay()
	for _, child: any in ipairs(dependencies.Workspace:GetChildren()) do
		if child:IsA("Model") then dependencies.WatchMap(child) end
	end
	connect(dependencies.Workspace.ChildAdded, dependencies.ChildAdded)
	connect(dependencies.Workspace.ChildRemoved, dependencies.ChildRemoved)
	connect(dependencies.GuiService.ErrorMessageChanged, dependencies.Disconnected)
	connect(dependencies.Player.Idled, dependencies.Idled)
	dependencies.PrepareInterface()
	
	connect(dependencies.Players.PlayerAdded, dependencies.PlayerAdded)
	connect(dependencies.Players.PlayerRemoving, dependencies.PlayerRemoving)
	dependencies.State.Unload = dependencies.Unload
	connect(dependencies.Library.OnUnload, dependencies.Unload)
	dependencies.FinishInterface()
	start("ui", dependencies.Interface, 0.5)
	dependencies.RestoreConfig()
	start("autosave", dependencies.Autosave, 5)
end

export type UnloadDependencies = {
	State: any,
	Mover: any,
	Farm: any,
	Movement: any,
	Hooks: any,
	Esp: any,
	Visuals: any,
	Settings: any,
	Spectate: any,
	LocalParts: () -> (any, any, ...any),
	Round: any,
	Library: any,
}

function Lifecycle.unload(dependencies: UnloadDependencies)
	local state = dependencies.State
	if not state.Running then return end

	state.Running = false
	if dependencies.Mover.Owner == "farm" then pcall(dependencies.Farm.Surface) end
	pcall(dependencies.Mover.Stop)
	pcall(dependencies.Movement.StopFly)
	pcall(dependencies.Movement.SetNoclip, false)
	pcall(dependencies.Hooks.Remove)
	pcall(dependencies.Esp.Destroy)
	pcall(dependencies.Visuals.Fullbright, false)
	pcall(dependencies.Settings.LowGraphics, false)
	pcall(dependencies.Settings.Set3D, true)
	pcall(dependencies.Spectate.Set, nil)

	pcall(function()
		local _, humanoid = dependencies.LocalParts()
		if not humanoid then return end
		if dependencies.Movement.SpeedSet then humanoid.WalkSpeed = 16 end
		if dependencies.Movement.JumpSet then humanoid.JumpPower = 50 end
	end)

	for _, connection in ipairs(state.Connections) do
		pcall(function() (connection :: any):Disconnect() end)
	end

	for _, connection in pairs(dependencies.Round.Watchers) do
		pcall(function() connection:Disconnect() end)
	end
	table.clear(dependencies.Round.Watchers)

	if not dependencies.Library.Unloaded then
		pcall(function() dependencies.Library:Destroy() end)
	end
end

function Characters.parts(player: LookupPlayer?): (LookupCharacter?, ...unknown)
	local character = player and player.Character

	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	return character, root, humanoid
end

function Characters.localParts(player: LookupPlayer?): (unknown, unknown)
	local _, root, humanoid = Characters.parts(player)
	return root, humanoid
end

function Network.ping(player: PingPlayer): number
	local getPing = player.GetNetworkPing
	local ok, value = pcall(getPing, player)

	if not ok then
		return 0.1
	end

	return tonumber(value :: string) or 0.1
end

function Helpers.formatNumber(value: any): string
	local text = tostring(math.floor(tonumber(value) or 0))
	local reversed = string.reverse(text)
	local grouped = string.gsub(reversed, "(%d%d%d)", "%1,")
	return (string.gsub(string.reverse(grouped), "^,", ""))
end

function Helpers.findModule(getModule: () -> any, requireModule: (any) -> any): any
	local ok, result = pcall(function() return requireModule(getModule()) end)
	if ok then return result end
	return nil
end

function Application.loadGameData(storage: any, requireModule: (any) -> any): (any, any, any)
	local round = Helpers.findModule(function() return storage.Modules.CurrentRoundClient end, requireModule)
	local weapons = Helpers.findModule(function() return storage.ClientServices.WeaponService end, requireModule)
	local profile = Helpers.findModule(function() return storage.Modules.ProfileData end, requireModule)
	return round, weapons, profile
end

function Application.cleanCoreGui(coreGui: any)
	for _, child: any in ipairs(coreGui:GetChildren()) do
		if child:IsA("ScreenGui") and (child.Name == "AxisMM2" or child.Name == "AxisMM2Visuals") then
			pcall(function() child:Destroy() end)
		end
	end
end

function Application.waitForGame(gameObject: any)
	if not gameObject:IsLoaded() then gameObject.Loaded:Wait() end
end

function Application.gameplayRemotes(storage: any): any
	local remotes = storage:WaitForChild("Remotes", 30)
	return remotes and remotes:WaitForChild("Gameplay", 30)
end

function Application.createRaycastParameters(newParameters: () -> any, getExclude: () -> any): (any, any)
	local ground = newParameters()
	ground.FilterType = getExclude()
	local exposure = newParameters()
	exposure.FilterType = getExclude()
	exposure.RespectCanCollide = true
	return ground, exposure
end

function Quest.formatName(value: any): string
	return (string.gsub(tostring(value or ""), "(%l)(%u)", "%1 %2"))
end

export type GameStateDependencies = {
	Storage: any,
	Require: (any) -> any,
	Players: any,
	Player: any,
	Workspace: any,
	Clock: () -> number,
	Wait: (number) -> (),
	ReadOption: (string, any) -> any,
}

function Application.createGameState(dependencies: GameStateDependencies): any
	local roundData, weapons, profileData = Application.loadGameData(dependencies.Storage, dependencies.Require)
	local round = Round.create({
		Players = dependencies.Players,
		Player = dependencies.Player,
		Workspace = dependencies.Workspace,
		Clock = dependencies.Clock,
		GetPlayerDataState = function() return roundData end,
	})
	return {Round=round,Weapons=weapons}

end

export type CombatTargetDependencies = {
	LocalParts: () -> (any, ...any),
	Players: any,
	Player: any,
	Round: any,
	CharacterParts: (any) -> (any, ...any),
}

function Combat.targets(dependencies: CombatTargetDependencies): { any }
	local localRoot = dependencies.LocalParts()
	local targets: { any } = {}

	for _, player in ipairs(dependencies.Players:GetPlayers()) do
		if player ~= dependencies.Player and dependencies.Round.IsAlive(player) then
			local _, root = dependencies.CharacterParts(player)
			local distance = if localRoot then (root.Position - localRoot.Position).Magnitude else 0
			table.insert(targets, { Player = player, Root = root, Dist = distance })
		end
	end

	table.sort(targets, function(left: any, right: any) return left.Dist < right.Dist end)
	return targets
end

function Combat.ordered(combat: any, round: any, readOption: (string, boolean) -> any): any
	local targets = combat.Targets()
	local sheriff = round.Sheriff()

	if sheriff and readOption("SheriffFirst", true) then
		for index, target in ipairs(targets) do
			if target.Player == sheriff then
				table.insert(targets, 1, table.remove(targets, index))
				break
			end
		end
	end

	return targets
end

function Combat.nearestRole(combat: any, round: any, role: string): any
	for _, target in ipairs(combat.Targets()) do
		if round.Role(target.Player) == role then return target.Player end
	end

	return nil
end

function Combat.shootMurderer(round: any, combat: any, moveToTarget: any): (...any)
	local murderer = round.Murderer()
	if not murderer then return false, "No murderer found" end

	return combat.ShootAt(murderer, moveToTarget)
end

function Combat.killAll(round: any, combat: any): (boolean, ...string?)
	if round.MyRole() ~= "Murderer" then return false, "You are not the murderer" end

	local targets = combat.Ordered()
	if #targets == 0 then return false, "Nobody left to kill" end

	combat.KillList(targets)
	return true
end

function Combat.killOne(round: any, combat: any, player: any): (boolean, ...string?)
	if round.MyRole() ~= "Murderer" then return false, "You are not the murderer" end
	if not round.IsAlive(player) then return false, "Target is not alive" end

	combat.KillList({ { Player = player } })
	return true
end

function Combat.killList(combat: any, isRunning: () -> any, round: any, targets: { any }): (...any)
	return combat.Run(function()
		for _, target in ipairs(targets) do
			if not isRunning() or not round.InRound() or round.MyRole() ~= "Murderer" then break end

			for _ = 1, 2 do
				if not round.IsAlive(target.Player) then break end
				combat.StabAt(target.Player, true)
			end
		end
	end)
end

export type CombatRunDependencies = {
	Combat: any,
	Mover: any,
	LocalParts: () -> (any, ...any),
	Player: any,
	Log: (string) -> (),
}

function Combat.run(dependencies: CombatRunDependencies, action: () -> ()): boolean
	local combat, mover = dependencies.Combat, dependencies.Mover
	if combat.Busy then return false end

	combat.Busy = true
	local previousOwner = mover.Owner
	local previousTarget = mover.Target
	local root = dependencies.LocalParts()
	local previousFrame = root and root.CFrame
	local character = dependencies.Player.Character
	local ok, failure = pcall(action)

	if not ok then dependencies.Log("Combat: " .. tostring(failure)) end

	if dependencies.Player.Character == character then
		if previousOwner and previousOwner ~= "combat" then
			mover.Hold(previousOwner, previousTarget)
		else
			mover.Release("combat", previousFrame)
		end
	end

	combat.Busy = false
	return ok
end

export type CombatEquipDependencies = {
	Round: any,
	Player: any,
	CharacterParts: (any) -> (any, any, any),
	Clock: () -> number,
	Wait: () -> (),
}

function Combat.equip(dependencies: CombatEquipDependencies, tag: string): any
	local tool = dependencies.Round.Tool(dependencies.Player, tag)
	local character, _, humanoid = dependencies.CharacterParts(dependencies.Player)
	if not tool or not character or not humanoid then return nil end

	if tool.Parent ~= character then
		humanoid:EquipTool(tool)
		local started = dependencies.Clock()

		while tool.Parent ~= character and dependencies.Clock() - started < 0.5 do
			dependencies.Wait()
		end
	end

	return if tool.Parent == character then tool else nil
end

function Combat.waitForDeath(clock: () -> number, round: any, wait: (number) -> (), player: any, timeout: number): boolean
	local started = clock()

	while clock() - started < timeout do
		if not round.IsAlive(player) then return true end
		wait(0.05)
	end

	return not round.IsAlive(player)
end

function Combat.throwCooldown(tool: any): number
	local speed = tonumber(tool:GetAttribute("ThrowSpeed")) or 1
	return speed * 2 + 0.1
end

export type CombatVisibilityDependencies = {
	Player: any,
	Parameters: any,
	Workspace: any,
}

function Combat.visible(dependencies: CombatVisibilityDependencies, origin: any, character: any, target: any): boolean
	local ignored = { dependencies.Player.Character, character }
	dependencies.Parameters.FilterDescendantsInstances = ignored
	local direction = target - origin

	for _ = 1, 6 do
		local hit = dependencies.Workspace:Raycast(origin, direction, dependencies.Parameters)
		if not hit then return true end
		if hit.Instance.Transparency < 1 and hit.Instance.CanCollide then return false end

		table.insert(ignored, hit.Instance)
		dependencies.Parameters.FilterDescendantsInstances = ignored
	end

	return false
end

export type CombatSpotDependencies = {
	Combat: any,
	NewVector: (number, number, number) -> any,
	LookAt: (any, any) -> any,
}

function Combat.shotSpot(dependencies: CombatSpotDependencies, root: any, character: any): any
	for _, radius in ipairs({ 8, 12, 5 }) do
		for index = 0, 11 do
			local angle = math.rad(index * 30)
			local position = root.Position + dependencies.NewVector(math.cos(angle) * radius, 1.5, math.sin(angle) * radius)

			if dependencies.Combat.Visible(position, character, root.Position) then
				return dependencies.LookAt(position, root.Position)
			end
		end
	end

	return nil
end

function Combat.aim(readNumber: (string, number) -> number, ping: () -> number, root: any): any
	return root.Position + root.AssemblyLinearVelocity * (readNumber("GunPrediction", 10) / 100 + ping() / 2)
end

function Combat.fire(localParts: () -> (any, ...any), combat: any, newFrame: (any) -> any, gun: any, targetRoot: any): boolean
	local root = localParts()
	local shoot = gun and gun:FindFirstChild("Shoot")
	if not root or not shoot or not targetRoot then return false end

	local attachment = root:FindFirstChild("GunRaycastAttachment")
	local fireServer = shoot.FireServer
	fireServer(shoot, attachment and attachment.WorldCFrame or nil, newFrame(combat.Aim(targetRoot)))
	return true
end

export type CombatShootDependencies = {
	CharacterParts: (any) -> (any, any, ...any),
	Round: any,
	Player: any,
	Combat: any,
	ReadNumber: (string, number) -> number,
	WaitForDeath: (any, number) -> any,
	Stats: any,
	Mover: any,
	LookAt: (any, any) -> any,
	Wait: (number) -> (),
}

function Combat.shootAt(dependencies: CombatShootDependencies, player: any, moveToTarget: any): (boolean, ...string?)
	local character, root = dependencies.CharacterParts(player)
	if not root then return false, "No target found" end

	local gun = dependencies.Round.Tool(dependencies.Player, "Weapon_Gun")
	if not gun then return false, "You have no gun" end

	local localCharacter = dependencies.Player.Character
	local head = localCharacter and localCharacter:FindFirstChild("Head")
	local combat = dependencies.Combat
	local visible = head and combat.Visible(head.Position, character, root.Position)
		and (root.Position - head.Position).Magnitude <= dependencies.ReadNumber("ShootRange", 120)

	if not visible then
		if not moveToTarget then return false, "Target is not visible" end

		local spot = combat.ShotSpot(root, character)
		if not spot then return false, "No clear shot" end

		combat.Run(function()
			local equipped = combat.Equip("Weapon_Gun")
			if not equipped then return end

			dependencies.Mover.Hold("combat", function()
				local _, currentRoot = dependencies.CharacterParts(player)
				return dependencies.LookAt(spot.Position, (currentRoot or root).Position)
			end)
			dependencies.Wait(combat.Settle())
			combat.Fire(equipped, root)
			if dependencies.WaitForDeath(player, 0.5) then dependencies.Stats.Kills += 1 end
		end)

		return true
	end

	local equipped = combat.Equip("Weapon_Gun")
	if not equipped then return false, "Could not equip the gun" end

	combat.Fire(equipped, root)
	if dependencies.WaitForDeath(player, 0.5) then dependencies.Stats.Kills += 1 end
	return true
end

export type CombatThrowDependencies = {
	Combat: any,
	CharacterParts: (any) -> (any, any, ...any),
	Ping: () -> number,
	NewFrame: (any) -> any,
}

function Combat.throw(dependencies: CombatThrowDependencies, player: any): boolean
	local knife = dependencies.Combat.Equip("Weapon_Knife")
	local events = knife and knife:FindFirstChild("Events")
	local thrown = events and events:FindFirstChild("KnifeThrown")
	local handle = knife and knife:FindFirstChild("Handle")
	local _, root = dependencies.CharacterParts(player)
	if not thrown or not handle or not root then return false end

	local distance = (root.Position - handle.Position).Magnitude
	local predicted = root.Position + root.AssemblyLinearVelocity * (distance / 96 + dependencies.Ping())
	local fireServer = thrown.FireServer
	fireServer(thrown, handle.CFrame, dependencies.NewFrame(predicted))
	return true
end

export type CombatThrowKillDependencies = {
	Combat: any,
	CharacterParts: (any) -> (any, any, ...any),
	Mover: any,
	Maximum: (number, number) -> number,
	Clock: () -> number,
	Round: any,
	WaitForDeath: (any, number) -> any,
	Stats: any,
	LookAt: (any, any) -> any,
	Wait: (number) -> (),
}

function Combat.throwKill(dependencies: CombatThrowKillDependencies, player: any): any
	local combat = dependencies.Combat
	local knife = combat.Equip("Weapon_Knife")
	local character, root = dependencies.CharacterParts(player)
	if not knife or not root then return false end

	local spot = combat.ShotSpot(root, character)
	if not spot then return false end

	dependencies.Mover.Hold("combat", function()
		local _, currentRoot = dependencies.CharacterParts(player)
		return dependencies.LookAt(spot.Position, (currentRoot or root).Position)
	end)

	local delay = dependencies.Maximum(combat.Settle(), combat.LastThrow + combat.ThrowCooldown(knife) - dependencies.Clock())
	dependencies.Wait(delay)
	if not dependencies.Round.IsAlive(player) then return true end
	if not combat.Throw(player) then return false end

	combat.LastThrow = dependencies.Clock()
	local killed = dependencies.WaitForDeath(player, 1.2)
	if killed then dependencies.Stats.Kills += 1 end

	return killed
end

function Combat.throwAll(round: any, combat: any, isRunning: () -> any): (boolean, ...string?)
	if round.MyRole() ~= "Murderer" then return false, "You are not the murderer" end

	local targets = combat.Ordered()
	if #targets == 0 then return false, "Nobody left to kill" end

	combat.Run(function()
		for _, target in ipairs(targets) do
			if not isRunning() or not round.InRound() or round.MyRole() ~= "Murderer" then break end
			if not round.IsAlive(target.Player) then continue end
			if combat.ThrowKill(target.Player) then continue end

			if round.IsAlive(target.Player) then
				combat.StabAt(target.Player, true)
			end
		end
	end)

	return true
end

export type CombatGrabDependencies = {
	Round: any,
	Player: any,
	Combat: any,
	Clock: () -> number,
	Mover: any,
	Position: (any) -> any,
	NewVector: () -> any,
	NewFrame: (any) -> any,
	Wait: (number) -> (),
}

function Combat.grabGun(dependencies: CombatGrabDependencies): (boolean, ...string?)
	local round, player = dependencies.Round, dependencies.Player
	local drop = round.GunDrop()
	if not drop then return false, "No dropped gun" end
	if round.MyRole() == "Murderer" then return false, "The murderer cannot pick up the gun" end
	if not round.InRound() then return false, "You are not in the round" end
	if round.Tool(player, "Weapon_Gun") then return false, "You already have the gun" end

	dependencies.Combat.Run(function()
		local started = dependencies.Clock()
		dependencies.Mover.Hold("combat", function()
			return dependencies.NewFrame(dependencies.Position(drop) or dependencies.NewVector())
		end)

		while dependencies.Clock() - started < 2 and drop.Parent and not round.Tool(player, "Weapon_Gun") do
			dependencies.Wait(0.05)
		end
	end)

	return round.Tool(player, "Weapon_Gun") ~= nil
end

export type CombatStabDependencies = {
	Combat: any,
	CharacterParts: (any) -> (any, any, ...any),
	Mover: any,
	WaitForDeath: (any, number) -> any,
	Stats: any,
	NewFrame: (number, number, number) -> any,
	Wait: (number) -> (),
}

function Combat.stabFrame(characterParts: (any) -> (any, any, ...any), player: any, originalRoot: any, newFrame: (number, number, number) -> any): any
	local _, root = characterParts(player)
	return (root or originalRoot).CFrame * newFrame(0, 0, 2.2)
end

function Combat.stabAt(dependencies: CombatStabDependencies, player: any, moveToTarget: any): any
	local combat = dependencies.Combat
	local knife = combat.Equip("Weapon_Knife")
	local events = knife and knife:FindFirstChild("Events")
	local stab = events and events:FindFirstChild("KnifeStabbed")
	local touch = events and events:FindFirstChild("HandleTouched")
	local _, root = dependencies.CharacterParts(player)
	if not stab or not touch or not root then return false end

	if moveToTarget then
		dependencies.Mover.Hold("combat", function()
			return Combat.stabFrame(dependencies.CharacterParts, player, root, dependencies.NewFrame)
		end)
		dependencies.Wait(combat.Settle())
	end

	stab:FireServer()
	touch:FireServer(root)

	local killed = dependencies.WaitForDeath(player, if moveToTarget then 0.6 else 0.25)
	if not killed then return killed end

	dependencies.Stats.Kills += 1
	return killed
end

export type CombatDependencies = {
	Round: any,
	Players: any,
	Player: any,
	CharacterParts: (any) -> (any, any, any),
	LocalParts: () -> (any, ...any),
	Mover: any,
	ReadOption: (string, boolean) -> any,
	ReadNumber: (string, number) -> number,
	IsRunning: () -> any,
	Clock: () -> number,
	Ping: () -> number,
	Maximum: (number, number) -> number,
	Wait: (number?) -> (),
	Sample: () -> number,
	Stats: any,
	NewFrame: (number, number, number) -> any,
	NewFrameAt: (any) -> any,
	NewVector: (number, number, number) -> any,
	NewZeroVector: () -> any,
	LookAt: (any, any) -> any,
	Workspace: any,
	VisibilityParameters: any,
	Log: (string) -> (),
}

function Combat.create(dependencies: CombatDependencies): any
	local combat: any = { Busy = false, LastThrow = 0 }
	local equip = {
		Round = dependencies.Round, Player = dependencies.Player, CharacterParts = dependencies.CharacterParts,
		Clock = dependencies.Clock, Wait = dependencies.Wait,
	}
	local run = {
		Combat = combat, Mover = dependencies.Mover, LocalParts = dependencies.LocalParts,
		Player = dependencies.Player, Log = dependencies.Log,
	}
	local targets = {
		LocalParts = dependencies.LocalParts, Players = dependencies.Players, Player = dependencies.Player,
		Round = dependencies.Round, CharacterParts = dependencies.CharacterParts,
	}
	local function waitForDeath(player: any, timeout: number)
		return Combat.waitForDeath(dependencies.Clock, dependencies.Round, dependencies.Wait, player, timeout)
	end
	local stab = {
		Combat = combat, CharacterParts = dependencies.CharacterParts, Mover = dependencies.Mover,
		Stats = dependencies.Stats, NewFrame = dependencies.NewFrame, Wait = dependencies.Wait,
		WaitForDeath = waitForDeath,
	}
	local visibility = {
		Player = dependencies.Player, Parameters = dependencies.VisibilityParameters, Workspace = dependencies.Workspace,
	}
	local spot = { Combat = combat, NewVector = dependencies.NewVector, LookAt = dependencies.LookAt }
	local throw = {
		Combat = combat, CharacterParts = dependencies.CharacterParts, Ping = dependencies.Ping,
		NewFrame = dependencies.NewFrameAt,
	}
	local throwKill = {
		Combat = combat, CharacterParts = dependencies.CharacterParts, Mover = dependencies.Mover,
		Maximum = dependencies.Maximum, Clock = dependencies.Clock, Round = dependencies.Round,
		WaitForDeath = waitForDeath, Stats = dependencies.Stats, LookAt = dependencies.LookAt, Wait = dependencies.Wait,
	}
	local shoot = {
		CharacterParts = dependencies.CharacterParts, Round = dependencies.Round, Player = dependencies.Player,
		Combat = combat, ReadNumber = dependencies.ReadNumber, WaitForDeath = waitForDeath,
		Stats = dependencies.Stats, Mover = dependencies.Mover, LookAt = dependencies.LookAt, Wait = dependencies.Wait,
	}
	local grab = {
		Round = dependencies.Round, Player = dependencies.Player, Combat = combat, Clock = dependencies.Clock,
		Mover = dependencies.Mover, Position = Inventory.position, NewVector = dependencies.NewZeroVector,
		NewFrame = dependencies.NewFrameAt, Wait = dependencies.Wait,
	}

	function combat.Equip(tag: string) return Combat.equip(equip :: any, tag) end
	function combat.Settle() return 0.15 + dependencies.Sample() * 1.5 end
	function combat.Run(action: () -> ()) return Combat.run(run, action) end
	function combat.Targets() return Combat.targets(targets) end
	function combat.StabAt(player: any, moveToTarget: any) return Combat.stabAt(stab :: any, player, moveToTarget) end
	function combat.KillList(list: { any }) return Combat.killList(combat, dependencies.IsRunning, dependencies.Round, list) end
	function combat.Ordered() return Combat.ordered(combat, dependencies.Round, dependencies.ReadOption) end
	function combat.NearestRole(role: string) return Combat.nearestRole(combat, dependencies.Round, role) end
	function combat.KillAll() return Combat.killAll(dependencies.Round, combat) end
	function combat.KillOne(player: any) return Combat.killOne(dependencies.Round, combat, player) end
	function combat.Visible(origin: any, character: any, target: any) return Combat.visible(visibility, origin, character, target) end
	function combat.ShotSpot(root: any, character: any) return Combat.shotSpot(spot, root, character) end
	function combat.Aim(root: any) return Combat.aim(dependencies.ReadNumber, dependencies.Ping, root) end
	function combat.Fire(gun: any, root: any) return Combat.fire(dependencies.LocalParts, combat, dependencies.NewFrameAt, gun, root) end
	function combat.ThrowCooldown(tool: any) return Combat.throwCooldown(tool) end
	function combat.Throw(player: any) return Combat.throw(throw :: any, player) end
	function combat.ThrowKill(player: any) return Combat.throwKill(throwKill :: any, player) end
	function combat.ThrowAll() return Combat.throwAll(dependencies.Round, combat, dependencies.IsRunning) end
	function combat.GrabGun() return Combat.grabGun(grab :: any) end
	function combat.ShootAt(player: any, moveToTarget: any) return Combat.shootAt(shoot :: any, player, moveToTarget) end
	function combat.ShootMurderer(moveToTarget: any) return Combat.shootMurderer(dependencies.Round, combat, moveToTarget) end

	return combat
end

function Round.map(dependencies: MapDependencies): MapCandidate?
	local state, workspace = dependencies.State, dependencies.Workspace
	local cached = state.MapCache

	if cached and cached.Parent == workspace and cached:FindFirstChild("CoinContainer") then
		return cached
	end

	state.MapCache = nil
	local now = dependencies.Clock()

	if now < state.NextScan then
		return nil
	end

	state.NextScan = now + 0.5

	for _, candidate in ipairs(workspace:GetChildren()) do
		if candidate:IsA("Model") and candidate:FindFirstChild("CoinContainer") then
			state.MapCache = candidate
			state.NextScan = 0
			return candidate
		end
	end

	return nil
end

function Round.data(state: { PlayerData: unknown }?): { [string]: unknown }
	local data = state and state.PlayerData

	if type(data) == "table" then
		return data :: { [string]: unknown }
	end

	return {}
end

function Round.info(round: { Data: () -> { [string]: unknown } }, player: RoundPlayer?): unknown
	return player and round.Data()[player.Name]
end

function Round.role(round: RoleRound, player: unknown): unknown
	local info = round.Info(player)
	if not info then return nil end
	if info.Dead then return "Dead" end

	local role = tostring(info.Role or "Innocent")

	if role == "Innocent" and round.Tool(player, "Weapon_Gun") then
		return "Hero"
	end

	return role
end

function Round.isAlive(round: AliveRound, characterParts: (unknown) -> (unknown, unknown, HealthHumanoid?), player: unknown): boolean
	local info = round.Info(player)
	if not info or info.Dead then return false end

	local _, root, humanoid = characterParts(player)
	if root == nil or humanoid == nil then return false end

	return humanoid.Health > 0
end

function Round.tool(findTool: (ToolContainer?, string) -> Tool?, player: ToolPlayer?, tag: string): Tool?
	if not player then return nil end

	return findTool(player.Character, tag) or findTool(player:FindFirstChildOfClass("Backpack"), tag)
end

function Round.findRole(players: { GetPlayers: (unknown) -> { unknown } }, round: { Role: (unknown) -> unknown, IsAlive: (unknown) -> unknown }, role: unknown): unknown
	for _, player in ipairs(players:GetPlayers()) do
		if round.Role(player) == role and round.IsAlive(player) then
			return player
		end
	end

	return nil
end

function Round.sheriff(players: { GetPlayers: (unknown) -> { unknown } }, round: { IsAlive: (unknown) -> unknown, Tool: (unknown, string) -> unknown, Role: (unknown) -> unknown, FindRole: (string) -> unknown }): unknown
	for _, player in ipairs(players:GetPlayers()) do
		if round.IsAlive(player) and round.Tool(player, "Weapon_Gun") then
			local role = round.Role(player)
			if role == "Sheriff" or role == "Hero" then return player end
		end
	end

	return round.FindRole("Sheriff")
end

function Round.gunDrop(round: { Gun: { Parent: unknown }?, Map: () -> { FindFirstChild: (unknown, string) -> unknown }? }, workspace: { FindFirstChild: (unknown, string) -> unknown }): unknown
	local gun = round.Gun
	if gun and gun.Parent then return gun end

	round.Gun = nil
	local map = round.Map()
	local found = (map and map:FindFirstChild("GunDrop")) or workspace:FindFirstChild("GunDrop")

	if found then round.Gun = found :: { Parent: unknown } end
	return found
end

function Round.myRole(round: { Role: (unknown) -> ...unknown }, player: unknown): (...unknown)
	return round.Role(player)
end

function Round.inRound(round: { IsAlive: (unknown) -> ...unknown }, player: unknown): (...unknown)
	return round.IsAlive(player)
end

function Round.murderer(round: { FindRole: (string) -> ...unknown }): (...unknown)
	return round.FindRole("Murderer")
end

function Round.childAdded(gunAdded: (any) -> (), mapAdded: (any) -> (), child: any)
	if child.Name == "GunDrop" then
		gunAdded(child)
		return
	end
	if child:IsA("Model") then mapAdded(child) end
end

function Round.coinsStarted(round: any, farm: any, data: any)
	table.clear(round.Bags)
	if type(data) == "table" then
		for id, bag: any in pairs(data) do
			if type(bag) == "table" then
				round.Bags[tostring(id)] = {
					Limit = tonumber(bag.CollectionLimit) or 0,
					Amount = tonumber(bag.CollectedAmount) or 0,
				}
			end
		end
	end
	farm.Reset()
end

function Round.coinCollected(round: any, stats: any, farm: any, notify: (string) -> (), webhook: any, fields: () -> any, coinId: any, amount: any, limit: any)
	local id = tostring(coinId)
	local bag = round.Bags[id]
	if not bag then
		bag = { Amount = 0, Limit = 0 }
		round.Bags[id] = bag
	end
	local current = tonumber(amount) or 0
	if current > bag.Amount then
		stats.Coins += current - bag.Amount
		round.CollectedThisRound += current - bag.Amount
	end
	bag.Amount = current
	bag.Limit = tonumber(limit) or bag.Limit
	farm.Count += 1
	if bag.Limit > 0 and bag.Amount >= bag.Limit then
		if farm.Enabled() then notify("Coin bag full") end
		local embed = webhook.Embed("Coin bag full", tostring(bag.Amount) .. "/" .. tostring(bag.Limit) .. " collected", 15844367, fields())
		webhook.Send("Bag Full", embed)
	end
end

function Round.playerDataChanged(round: any, data: any)
	if type(data) == "table" and next(data) == nil then
		table.clear(round.Bags)
		round.Gun = nil
	end
end

function Round.roleDetails(round: any): string?
	local murderer = round.FindRole("Murderer")
	local sheriff = round.FindRole("Sheriff")
	local roles = {}
	if murderer then table.insert(roles, "Murderer: " .. murderer.DisplayName) end
	if sheriff then table.insert(roles, "Sheriff: " .. sheriff.DisplayName) end
	if #roles == 0 then return nil end
	return table.concat(roles, " | ")
end

function Round.roleSelected(round: any, stats: any, farm: any, delay: (number, () -> ()) -> (), details: () -> any, readOption: (string, boolean) -> any, notify: (string) -> (), webhook: any, formatName: (any) -> any, role: any)
	round.MyRoleName = tostring(role)
	round.Mode = "Classic"
	round.CollectedThisRound = 0
	round.Gun = nil
	stats.Rounds += 1
	farm.Reset()
	delay(0.6, function()
		local roles = details()
		if readOption("AnnounceRoles", true) and roles then notify(roles) end
		local map = round.Map()
		local description = "You are " .. tostring(role) .. " | " .. formatName(round.Mode)
		if map then description ..= " | " .. map.Name end
		local embed = webhook.Embed("Round started", description, 5763719, { { name = "Roles", value = roles or "Unknown", inline = false } })
		webhook.Send("Round Start", embed)
	end)
end

function Round.victory(round: any, webhook: any, fields: () -> any, formatName: (any) -> any, _: any, message: any, title: any)
	local name = formatName(title or message or "Round over")
	local description = "You were " .. tostring(round.MyRoleName or "?") .. " | " .. tostring(round.CollectedThisRound) .. " coins this round"
	local embed = webhook.Embed("Round over | " .. name, description, 4891615, fields())
	webhook.Send("Round End", embed)
end

function Round.connectGameplay(gameplay: any, state: any, protect: (...any) -> ...any, handlers: any)
	if not gameplay then return end
	for _, name in { "RoleSelect", "CoinsStarted", "CoinCollected", "VictoryScreen", "PlayerDataChanged" } do
		local remote = gameplay:FindFirstChild(name)
		if remote and remote:IsA("RemoteEvent") then
			local connection = remote.OnClientEvent:Connect(Lifecycle.callback(protect, handlers[name]))
			table.insert(state.Connections, connection)
		end
	end
end

function Round.gunAdded(round: any, readOption: (string, boolean) -> any, notify: (string) -> (), gun: any)
	round.Gun = gun
	if readOption("AnnounceGun", true) then notify("The gun was dropped") end
end

function Round.watchMap(round: any, protect: (...any) -> ...any, gunAdded: (any) -> (), map: any)
	if round.Watchers[map] then return end
	local watchers = round.Watchers
	watchers[map] = map.ChildAdded:Connect(function(child: any)
		if child.Name == "GunDrop" then protect(gunAdded, child) end
	end)
end

function Round.childRemoved(round: any, child: any)
	local watcher = round.Watchers[child]
	if watcher then
		watcher:Disconnect()
		round.Watchers[child] = nil
	end
	if round.MapCache == child then round.MapCache = nil end
end

function Inventory.findTool(container: ToolContainer?, tag: string): Tool?
	if not container then return nil end

	for _, tool in ipairs(container:GetChildren()) do
		if tool:IsA("Tool") and tool:HasTag(tag) then
			return tool
		end
	end

	return nil
end

function Inventory.position(instance: any): any
	if not instance then return nil end
	if instance:IsA("BasePart") then return instance.Position end

	local ok, pivot = pcall(function() return instance:GetPivot() end)
	if not ok then return nil end

	return pivot.Position
end

function Movement.playerFrame(parts: (any) -> (any, any, ...any), newFrame: (number, number, number) -> any, player: any): any
	local _, root = parts(player)
	if not root then return nil end
	return root.CFrame * newFrame(0, 0, 3)
end

function Movement.teleport(localParts: () -> (any, ...any), mover: any, zero: any, destination: any): boolean
	if not destination then return false end
	local root = localParts()
	if not root then return false end
	if mover.Conn then mover.Stop() end
	root.CFrame = destination
	root.AssemblyLinearVelocity = zero
	return true
end

function Farm.create(dependencies: FarmDependencies): FarmController
	local farm = {
		Done = {}, Fails = {}, Avoid = {}, BagHandled = false,
		LastCollect = 0, Count = 0, Status = "Off",
	} :: FarmController
	local geometry: FarmGeometry = {
		ReadOption = dependencies.ReadNumber,
		NewVector = dependencies.NewVector,
		NewFrame = dependencies.NewFrameAt,
	}
	local exposure: ExposureDependencies = {
		Cache = {}, Players = dependencies.Players, Parameters = dependencies.Parameters,
		Farm = farm :: { Hidden: (Vector) -> Frame }, Workspace = dependencies.Workspace,
		RayDirection = dependencies.RayDirection,
	}
	local selection: CoinSelectionDependencies = {
		Round = dependencies.Round :: CoinRound, Farm = farm :: CoinFarm,
		ReadNumber = dependencies.ReadNumber, ReadBoolean = dependencies.ReadBoolean,
		Clock = dependencies.Clock, IsCoin = dependencies.IsCoin,
	}
	local safeSpot: SafeSpotDependencies = {
		Farm = farm :: SafeFarm, GroundAt = dependencies.GroundAt,
		SpawnPoint = dependencies.SpawnPoint, Fallback = dependencies.Fallback,
	}
	local hide: HideDependencies = {
		Mover = dependencies.Mover :: HideMover, Farm = farm :: HideFarm,
		CharacterParts = dependencies.CharacterParts :: () -> Part?, NewVector = dependencies.NewVector,
		NewFrame = dependencies.NewFrameAt,
	}
	local step: FarmStepDependencies = {
		Round = dependencies.Round :: FarmRound, Farm = farm :: ActiveFarm,
		Player = dependencies.Player, Mover = dependencies.Mover :: FarmMover,
		CharacterParts = dependencies.CharacterParts :: () -> Part?, SpawnPoint = dependencies.SpawnPoint :: () -> Part?,
		NewVector = dependencies.NewVector, NewFrame = dependencies.NewFrame,
		ReadOption = dependencies.ReadNumber, IsAlive = dependencies.IsAlive, IsCoin = dependencies.IsCoin,
		Minimum = dependencies.Minimum, Maximum = dependencies.Maximum, Clock = dependencies.Clock,
		BaseDelay = dependencies.BaseDelay, Jitter = dependencies.Jitter, Touch = dependencies.Touch,
		Heartbeat = dependencies.Heartbeat, Wait = dependencies.Wait,
	}

	function farm.Enabled() return Farm.wantsCoins(dependencies.ReadBoolean) end
	function farm.BagOf(coin)
		local coinId = (coin :: AttributeCoin):GetAttribute("CoinID")
		if not coinId then return nil end
		return dependencies.Round.Bags[tostring(coinId)] or nil
	end
	function farm.BagFull(coin) return Farm.isBagFull(farm.BagOf(coin)) end
	function farm.AllFull() return Farm.areAllBagsFull(dependencies.Round.Bags) end
	function farm.BagText() return Farm.describeBags(dependencies.Round.Bags) end
	function farm.Hidden(position) return Farm.hidden(geometry, position) end
	function farm.Deep(position) return Farm.deep(geometry, position) end
	function farm.TouchCF(coin) return Farm.touchFrame(geometry, coin) end
	function farm.Threat()
		return Farm.threat(dependencies.ReadBoolean, dependencies.Round, dependencies.PlayerCharacterParts) :: Coin?
	end
	function farm.Exposed(coin) return Farm.isExposed(exposure, coin) end
	function farm.Pick(origin) return Farm.pick(selection, origin) end
	function farm.SafeSpot() return Farm.safeSpot(safeSpot) end
	function farm.Surface() Farm.surface(dependencies.Mover :: SurfaceMover, farm :: SurfaceFarm) end
	function farm.HideHere() Farm.hideHere(hide) end
	function farm.OnBagFull()
		Farm.handleBagFull(farm :: FullBagFarm, dependencies.ReadString, dependencies.CharacterParts)
	end
	function farm.Step() Farm.step(step) end
	function farm.Reset() Farm.reset(farm :: FarmState) end

	return farm
end

function Farm.wantsCoins(readOption)
    return readOption("AutoCoins",false)
end

function Farm.isBagFull(bag: Bag?): boolean
	if bag == nil then
		return false
	end

	if not (bag.Limit > 0) then
		return false
	end

	return bag.Amount >= bag.Limit
end

function Farm.isCoin(coin: CoinCandidate?): boolean?
	return coin and coin.Parent ~= nil and coin:IsA("BasePart") and coin:FindFirstChild("TouchInterest") ~= nil
end

function Farm.bagOf(coin: AttributeCoin, bags: { [string]: Bag }): Bag?
	local coinId = coin:GetAttribute("CoinID")

	if not coinId then
		return nil
	end

	return bags[tostring(coinId)] or nil
end

function Farm.areAllBagsFull(bags: { [string]: Bag }): boolean
	local hasLimitedBag = false

	for _, bag in pairs(bags) do
		if bag.Limit <= 0 then
			continue
		end

		local amount, limit = bag.Amount, bag.Limit
		hasLimitedBag = true

		if amount < limit then
			return false
		end
	end

	return hasLimitedBag
end

function Farm.describeBags(bags: { [string]: Bag }): string
	local labels = {}

	for name, bag in pairs(bags) do
		table.insert(labels, ("%s %d/%d"):format(name, bag.Amount, bag.Limit))
	end

	table.sort(labels)

	if #labels == 0 then
		return "No bag yet"
	end

	return table.concat(labels, " | ")
end

function Farm.handleBagFull(
	farm: FullBagFarm,
	readOption: (string, string) -> string,
	characterParts: () -> (unknown, Humanoid?)
)
	local action = readOption("BagFullAction", "Stay Hidden")

	if action == "Stay Hidden" then
		farm.Status = "Bag full | hiding under the map"
		farm.HideHere()
	end

	if action == "Surface" then
		farm.Status = "Bag full"
		if not farm.BagHandled then farm.Surface() end
	end

	if action == "Reset Character" then
		farm.Status = "Bag full | reset"

		if not farm.BagHandled then
			farm.Surface()
			local _, humanoid = characterParts()
			if humanoid then humanoid.Health = 0 end
		end
	end

	farm.BagHandled = true
end

function Farm.surface(mover: SurfaceMover, farm: SurfaceFarm)
	if mover.Owner ~= "farm" then
		return
	end

	mover.Release("farm", farm.SafeSpot())
end

function Farm.hidden(geometry: FarmGeometry, position: Vector): Frame
	local newFrame = geometry.NewFrame
	local depth = geometry.ReadOption("HideDepth", 8)

	return newFrame(position - geometry.NewVector(0, depth, 0))
end

function Farm.deep(geometry: FarmGeometry, position: Vector): Frame
	local newFrame = geometry.NewFrame
	local depth = geometry.ReadOption("HideDepth", 8) + 15

	return newFrame(position - geometry.NewVector(0, depth, 0))
end

function Farm.touchFrame(geometry: FarmGeometry, coin: Coin): Frame
	local newFrame = geometry.NewFrame
	local position = coin.Position

	return newFrame(position - geometry.NewVector(0, 2.8, 0))
end

function Farm.threat(
	readOption: (string, boolean) -> boolean,
	round: { MyRole: () -> string, Murderer: () -> unknown },
	characterParts: (unknown) -> (unknown, unknown)
): unknown
	if not readOption("AvoidMurderer", true) then return nil end
	if round.MyRole() == "Murderer" then return nil end

	local murderer = round.Murderer()
	local _, root = characterParts(murderer)
	return root
end

function Farm.safeSpot(dependencies: SafeSpotDependencies): Frame?
	local farm = dependencies.Farm
	local last = farm.Last
	local destination = last and last.Parent and dependencies.GroundAt(last.Position)

	if destination then return destination end

	if farm.LastPos then
		destination = dependencies.GroundAt(farm.LastPos)
		if destination then return destination end
	end

	destination = dependencies.SpawnPoint()
	if destination then return destination end
	return (dependencies.Fallback())
end

function Farm.spawnPoint(dependencies: SpawnDependencies): Frame?
	local map = dependencies.Round.Map()
	if not map then return nil end

	return Farm._spawnIn(map, dependencies)
end

function Farm.lobbySpawn(dependencies: LobbySpawnDependencies): Frame?
	local lobby = dependencies.Workspace:FindFirstChild("Lobby")
	if not lobby then return nil end

	return Farm._spawnIn(lobby, dependencies)
end

function Farm.groundAt(dependencies: GroundDependencies, position: Vector): Frame?
	local ground = dependencies.GroundPosition(position)
	if not ground then return nil end

	return dependencies.NewFrame(ground + dependencies.Offset) or nil
end

function Farm.groundPosition(dependencies: GroundRayDependencies, position: Vector, extra: unknown?): Vector?
	local ignored = { dependencies.Player.Character }
	local map = dependencies.Round.Map()

	if map and map:FindFirstChild("CoinContainer") then
		table.insert(ignored, map.CoinContainer)
	end

	if extra then
		table.insert(ignored, extra)
	end

	dependencies.Parameters.FilterDescendantsInstances = ignored
	local workspace = dependencies.Workspace
	local raycast = workspace.Raycast
	local hit = raycast(workspace, position + dependencies.OriginOffset, dependencies.Direction, dependencies.Parameters)

	return hit and hit.Position or nil
end

function Farm.createLocations(dependencies: any): any
	local offset = dependencies.NewVector(0, 3.200000047683716, 0)
	local spawn = { Round = dependencies.Round, Workspace = dependencies.Workspace, NewFrame = dependencies.NewFrame, Offset = offset }
	local ray = {
		Player = dependencies.Player,
		Round = dependencies.Round,
		Workspace = dependencies.Workspace,
		Parameters = dependencies.Parameters,
		OriginOffset = dependencies.NewVector(0, 4, 0),
		Direction = dependencies.NewVector(0, -40, 0),
	}
	local function groundPosition(position: any, extra: any?) return Farm.groundPosition(ray, position, extra) end
	return {
		SpawnPoint = function() return Farm.spawnPoint(spawn) end,
		LobbySpawn = function() return Farm.lobbySpawn(spawn) end,
		GroundPosition = groundPosition,
		GroundAt = function(position: any)
			return Farm.groundAt({ GroundPosition = groundPosition, NewFrame = dependencies.NewFrame, Offset = offset }, position)
		end,
	}
end

function Farm._spawnIn(map: SpawnMap, dependencies: { NewFrame: (VectorFields) -> Frame?, Offset: Vector }): Frame?
	local spawns = map:FindFirstChild("Spawns")
	if not spawns then return nil end

	local part = spawns:FindFirstChildWhichIsA("BasePart", true)
	if not part then return nil end

	return dependencies.NewFrame(part.Position + dependencies.Offset) or nil
end

function Farm.hideHere(dependencies: HideDependencies)
	local mover, farm = dependencies.Mover, dependencies.Farm

	if mover.Owner == "farm" then
		if farm.BagHandled then return end
		mover.Target = dependencies.NewFrame(mover.Current().Position - dependencies.NewVector(0, 15, 0))
		return
	end

	local root = dependencies.CharacterParts()
	if not root then return end
	mover.Hold("farm", farm.Deep(root.Position))
end

function Farm.run(dependencies: FarmLoopDependencies)
	while dependencies.IsRunning() do
		local farm = dependencies.Farm

		if not farm.Enabled() then
			if dependencies.Mover.Owner == "farm" then farm.Surface() end
			farm.Status = "Off"
			dependencies.Wait(0.3)
			continue
		end

		local ok, raised = pcall(farm.Step)

		if not ok then
			dependencies.Log("Farm: " .. tostring(raised))
			dependencies.Wait(0.5)
		end

		dependencies.Wait()
	end
end

function Farm.pick(dependencies: CoinSelectionDependencies, origin: Vector): Coin?
	local map = dependencies.Round.Map()

	if not map then
		return nil
	end

	local container = map:FindFirstChild("CoinContainer")

	if not container then
		return nil
	end

	local farm = dependencies.Farm
	local threat = farm.Threat()
	local avoidRadius = dependencies.ReadNumber("AvoidRadius", 20)
	local skipUpperCoins = dependencies.ReadBoolean("SkipUpperCoins", true)
	local now = dependencies.Clock()
	local nearest: Coin? = nil
	local nearestDistance: number? = nil

	for _, coin in ipairs(container:GetChildren()) do
		if not dependencies.IsCoin(coin) then continue end
		if farm.Done[coin] then continue end
		if not ((farm.Fails[coin] or 0) < 2) then continue end
		if not ((farm.Avoid[coin] or 0) < now) then continue end
		if farm.BagFull(coin) then continue end

		if threat and (threat.Position - coin.Position).Magnitude < avoidRadius then
			continue
		end

		if skipUpperCoins and farm.Exposed(coin) then
			continue
		end

		local distance = (coin.Position - origin).Magnitude

		if not nearestDistance or distance < nearestDistance then
			nearest, nearestDistance = coin, distance
		end
	end

	return nearest
end

function Farm.isExposed(dependencies: ExposureDependencies, coin: ExposedCoin): boolean
	local cached = dependencies.Cache[coin]

	if cached ~= nil then
		return cached
	end

	local ignored = { coin.Parent }

	for _, player in ipairs(dependencies.Players:GetPlayers()) do
		if player.Character then
			table.insert(ignored, player.Character)
		end
	end

	dependencies.Parameters.FilterDescendantsInstances = ignored
	local workspace = dependencies.Workspace
	local raycast = workspace.Raycast
	local origin = dependencies.Farm.Hidden(coin.Position).Position
	local hit = raycast(workspace, origin, dependencies.RayDirection, dependencies.Parameters)
	local isExposed = hit ~= nil

	dependencies.Cache[coin] = isExposed
	return isExposed
end

function Farm.reset(state: FarmState)
	table.clear(state.Done)
	table.clear(state.Fails)
	table.clear(state.Avoid)
	state.BagHandled = false
	state.Last, state.LastPos = nil, nil
end

function Farm.step(dependencies: FarmStepDependencies)
	local round, farm = dependencies.Round, dependencies.Farm
	local player, mover = dependencies.Player, dependencies.Mover

	if not round.InRound() then
		farm.Status = if round.Info(player) then "You are dead | waiting for next round" else "Waiting for a round"
		dependencies.Wait(0.4)
		return
	end

	if mover.Owner and mover.Owner ~= "farm" then
		farm.Status = "Paused while another action runs"
		dependencies.Wait(0.15)
		return
	end

	if farm.AllFull() then
		farm.OnBagFull()
		dependencies.Wait(0.4)
		return
	end

	local root = dependencies.CharacterParts()

	if not root then
		dependencies.Wait(0.3)
		return
	end

	local origin = mover.Owner == "farm" and mover.Current() or root.CFrame

	if mover.Owner ~= "farm" then
		local spawn = dependencies.SpawnPoint()

		if spawn and (root.Position - spawn.Position).Magnitude > 800 then
			farm.Status = "Waiting to spawn on the map"
			dependencies.Wait(0.3)
			return
		end

		mover.Hold("farm", farm.Deep(root.Position))
		origin = mover.Current()
	end

	local coin = farm.Pick(origin.Position + dependencies.NewVector(0, dependencies.ReadOption("HideDepth", 8), 0))

	if not coin then
		farm.Status = "Hidden | waiting for coins"
		dependencies.Wait(0.3)
		return
	end

	Farm._collect(dependencies, coin)
end

function Farm._collect(dependencies: FarmStepDependencies, coin: Coin)
	local round, farm, mover = dependencies.Round, dependencies.Farm, dependencies.Mover
	local readOption, clock = dependencies.ReadOption, dependencies.Clock

	local function canContinue()
		return dependencies.IsAlive() and farm.Enabled() and dependencies.IsCoin(coin) and round.InRound()
	end

	farm.Status = "Moving under a coin"
	local hidden = farm.Hidden(coin.Position)
	local speed = readOption("TravelSpeed", 30)
	local current = mover.Current().Position
	local travelY = dependencies.Minimum(current.Y, hidden.Position.Y)

	if current.Y - travelY > 1 then
		local down = dependencies.NewFrame(current.X, travelY, current.Z)
		if not mover.Glide("farm", down, speed, canContinue) then return end
	end

	local startFlat = dependencies.NewVector(current.X, 0, current.Z)
	local finishFlat = dependencies.NewVector(hidden.Position.X, 0, hidden.Position.Z)

	if (startFlat - finishFlat).Magnitude > 1 then
		local across = dependencies.NewFrame(hidden.Position.X, travelY, hidden.Position.Z)
		if not mover.Glide("farm", across, speed, canContinue) then return end
	end

	if not mover.Glide("farm", hidden, speed, canContinue) then return end

	farm.LastPos = coin.Position
	local readyAt = dependencies.Maximum(clock() + dependencies.BaseDelay + dependencies.Jitter(), farm.LastCollect + readOption("CoinDelay", 1))
	farm.Status = "Waiting under a coin"

	while clock() < readyAt do
		if not canContinue() then return end
		if mover.Owner ~= "farm" then return end
		dependencies.Wait(0.05)
	end

	local threat = farm.Threat()

	if threat and (threat.Position - coin.Position).Magnitude < readOption("AvoidRadius", 20) then
		farm.Avoid[coin] = clock() + 4
		farm.Status = "Murderer close | skipping coin"
		return
	end

	Farm._touchCoin(dependencies, coin)
end

function Farm._touchCoin(dependencies: FarmStepDependencies, coin: Coin)
	local farm, mover = dependencies.Farm, dependencies.Mover
	local heartbeat = dependencies.Heartbeat
	local countBefore = farm.Count
	farm.Status = "Collecting"

	Farm._beginTouch(dependencies, coin, countBefore)

	local started = dependencies.Clock()
	local collected = false

	while dependencies.Clock() - started < 1 and mover.Owner == "farm" do
		heartbeat:Wait()

		if farm.Count > countBefore then
			collected = true
			break
		end

		if not dependencies.IsCoin(coin) then break end
	end

	if mover.Owner == "farm" then mover.Target = farm.Hidden(coin.Position) end
	farm.Last = coin

	if collected then
		farm.Done[coin] = true
		farm.LastCollect = dependencies.Clock()
		return
	end

	farm.Fails[coin] = (farm.Fails[coin] or 0) + 1
end

function Farm._beginTouch(dependencies: FarmStepDependencies, coin: Coin, countBefore: number)
	local touch = dependencies.Touch

	if not touch then
		dependencies.Mover.Target = dependencies.Farm.TouchCF(coin)
		return
	end

	local farm, character = dependencies.Farm, dependencies.Player.Character

	for _, name in ipairs({ "Head", "HumanoidRootPart" }) do
		local part = character and character:FindFirstChild(name)
		if not part or farm.Count ~= countBefore or not dependencies.IsCoin(coin) then continue end

		pcall(touch, part, coin, 0)
		dependencies.Heartbeat:Wait()
		pcall(touch, part, coin, 1)
	end
end


export type ClickTeleportDependencies = {
	ReadOption: (string, boolean) -> any,
	GetBind: (any) -> any,
	Options: any,
	Input: any,
	Player: any,
	LocalParts: () -> (any, ...any),
	MouseButton: () -> any,
	KeyCodes: () -> any,
	NewFrame: (any) -> any,
	Offset: any,
	Zero: any,
}

function Movement.clickTeleport(dependencies: ClickTeleportDependencies, input: any, processed: any)
	if processed or input.UserInputType ~= dependencies.MouseButton() or not dependencies.ReadOption("ClickTp", false) then return end
	local bind = dependencies.GetBind(dependencies.Options.ClickTpKey)
	if not bind or bind.EnumType ~= dependencies.KeyCodes() or not dependencies.Input:IsKeyDown(bind) then return end
	local mouse = dependencies.Player:GetMouse()
	local root = dependencies.LocalParts()
	if root and mouse.Hit then
		root.CFrame = dependencies.NewFrame(mouse.Hit.Position + dependencies.Offset)
		root.AssemblyLinearVelocity = dependencies.Zero
	end
end

function Movement.updateCharacter(localParts: () -> (any, any), readOption: (string, boolean) -> any, readNumber: (string, number) -> any, movement: any)
	local _, humanoid = localParts()
	if not humanoid then return end

	local speedEnabled = readOption("SpeedOn", false)
	if speedEnabled then
		humanoid.WalkSpeed = readNumber("SpeedValue", 24)
		movement.SpeedSet = true
	end
	if not speedEnabled and movement.SpeedSet then
		humanoid.WalkSpeed = 16
		movement.SpeedSet = false
	end

	local jumpEnabled = readOption("JumpOn", false)
	if jumpEnabled then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = readNumber("JumpValue", 70)
		movement.JumpSet = true
	end
	if not jumpEnabled and movement.JumpSet then
		humanoid.JumpPower = 50
		movement.JumpSet = false
	end

	if readOption("Fly", false) and (not movement.Fly or not movement.Fly.Velocity.Parent) then movement.StartFly() end
	if not readOption("Fly", false) and movement.Fly then movement.StopFly() end
end

function Movement.setNoclip(player: any, movement: any, mover: any, enabled: any)
	if enabled then
		local character = player.Character
		if not character then return end
		if movement.NoclipChar ~= character then
			movement.NoclipChar = character
			movement.NoclipSaved = {}
			for _, part: any in ipairs(character:GetDescendants() :: any) do
				if part:IsA("BasePart") then movement.NoclipSaved[part] = part.CanCollide end
			end
		end

		for part: any in pairs(movement.NoclipSaved :: any) do
			if part.Parent then part.CanCollide = false end
		end
		return
	end

	if not movement.NoclipSaved then return end
	if movement.NoclipChar == player.Character and not mover.Conn then
		for part: any, canCollide in pairs(movement.NoclipSaved :: any) do
			if part.Parent then part.CanCollide = canCollide end
		end
	end
	movement.NoclipSaved = nil
	movement.NoclipChar = nil
end

function Movement.noclipFrame(readOption: (string, boolean) -> any, movement: any)
	if readOption("Noclip", false) then movement.SetNoclip(true) end
end

function Movement.cleanFly(movement: any, fly: any)
	if fly.Conn then fly.Conn:Disconnect() end
	pcall(function() fly.Velocity:Destroy() end)
	pcall(function() fly.Gyro:Destroy() end)
	if fly.Humanoid and fly.Humanoid.Parent then fly.Humanoid.PlatformStand = false end
	if movement.Fly == fly then movement.Fly = nil end
end

function Movement.stopFly(movement: any, clean: (any) -> ())
	if movement.Fly then clean(movement.Fly) end
end

function Appearance.fullbright(visuals: any, lighting: any, enabled: any)
	if enabled then
		if visuals.Saved then return end
		local properties = {
			Brightness = lighting.Brightness,
			ClockTime = lighting.ClockTime,
			FogEnd = lighting.FogEnd,
			FogStart = lighting.FogStart,
			GlobalShadows = lighting.GlobalShadows,
			Ambient = lighting.Ambient,
			OutdoorAmbient = lighting.OutdoorAmbient,
		}
		local atmospheres = {}
		for _, child: any in ipairs(lighting:GetChildren() :: any) do
			if child:IsA("Atmosphere") then atmospheres[child] = child.Density end
		end
		visuals.Saved = { Props = properties, Atmos = atmospheres }
		return
	end

	if not visuals.Saved then return end
	for key, value in pairs(visuals.Saved.Props) do
		pcall(function() lighting[key] = value end)
	end
	for atmosphere: any, density in pairs(visuals.Saved.Atmos) do
		pcall(function() atmosphere.Density = density end)
	end
	visuals.Saved = nil
end

function Appearance.updateFullbright(visuals: any, lighting: any, ambient: any)
	if not visuals.Saved then return end
	lighting.Brightness = 2
	lighting.ClockTime = 14
	lighting.FogEnd = 1000000
	lighting.FogStart = 1000000
	lighting.GlobalShadows = false
	lighting.Ambient = ambient
	lighting.OutdoorAmbient = ambient
	for atmosphere: any in pairs(visuals.Saved.Atmos) do
		pcall(function() atmosphere.Density = 0 end)
	end
end

function Appearance.create(lighting: any, ambient: any): (any, () -> ())
	local visuals: any = {}
	function visuals.Fullbright(enabled: any) Appearance.fullbright(visuals, lighting, enabled) end
	return visuals, function() Appearance.updateFullbright(visuals, lighting, ambient) end
end

function Movement.jumpRequest(readOption: (string, boolean) -> any, localParts: () -> (any, any), jumping: () -> any)
	if not readOption("InfJump", false) then return end
	local _, humanoid = localParts()
	if not humanoid then return end
	local changeState = humanoid.ChangeState
	changeState(humanoid, jumping())
end

function Movement.characterAdded(movement: any)
	movement.StopFly()
	movement.NoclipSaved = nil
	movement.NoclipChar = nil
	movement.SpeedSet = false
	movement.JumpSet = false
end

export type FlightFrameDependencies = {
	Movement: any,
	Fly: any,
	Root: any,
	Velocity: any,
	Humanoid: any,
	Gyro: any,
	Workspace: any,
	Input: any,
	KeyCodes: any,
	NewVector: (number, number, number) -> any,
	Zero: any,
	Up: any,
	ReadNumber: (string, number) -> any,
	Clean: (any) -> (),
}

function Movement.flyFrame(dependencies: FlightFrameDependencies)
	local movement, fly = dependencies.Movement, dependencies.Fly
	local root, velocity = dependencies.Root, dependencies.Velocity
	if movement.Fly ~= fly or not root.Parent or not velocity.Parent then
		dependencies.Clean(fly)
		return
	end

	local camera = dependencies.Workspace.CurrentCamera
	local look = camera.CFrame.LookVector
	local right = camera.CFrame.RightVector
	local flatLook = dependencies.NewVector(look.X, 0, look.Z)
	local flatRight = dependencies.NewVector(right.X, 0, right.Z)
	local forward = if flatLook.Magnitude > 0 then flatLook.Unit else dependencies.Zero
	local side = if flatRight.Magnitude > 0 then flatRight.Unit else dependencies.Zero
	local move = dependencies.Humanoid.MoveDirection
	local direction = look * move:Dot(forward) + right * move:Dot(side)

	local input, keys = dependencies.Input, dependencies.KeyCodes
	if not input:GetFocusedTextBox() then
		if input:IsKeyDown(keys.Space) or input:IsKeyDown(keys.E) then direction += dependencies.Up end
		if input:IsKeyDown(keys.Q) then direction -= dependencies.Up end
	end
	if direction.Magnitude > 1 then direction = direction.Unit end

	velocity.Velocity = direction * dependencies.ReadNumber("FlySpeed", 60)
	dependencies.Gyro.CFrame = camera.CFrame
	dependencies.Humanoid.PlatformStand = true
end

function Movement.startFly(movement: any, localParts: () -> (any, any), newInstance: (string) -> any, runService: any, force: any, zero: any, onFrame: (any, any, any, any, any) -> ())
	movement.StopFly()
	local root, humanoid = localParts()
	if not root or not humanoid then return end

	local velocity = newInstance("BodyVelocity")
	velocity.MaxForce = force
	velocity.Velocity = zero
	velocity.Parent = root

	local gyro = newInstance("BodyGyro")
	gyro.MaxTorque = force
	gyro.P = 90000
	gyro.CFrame = root.CFrame
	gyro.Parent = root

	local fly: any = { Velocity = velocity, Gyro = gyro, Humanoid = humanoid }
	movement.Fly = fly
	humanoid.PlatformStand = true
	fly.Conn = runService.RenderStepped:Connect(function() onFrame(fly, root, velocity, humanoid, gyro) end)
end

export type CharacterMovementDependencies = {
	Player: any,
	Mover: any,
	LocalParts: () -> (any, any),
	NewInstance: (string) -> any,
	RunService: any,
	Workspace: any,
	Input: any,
	KeyCodes: any,
	NewVector: (number, number, number) -> any,
	Force: any,
	Zero: any,
	Up: any,
	ReadOption: (string, boolean) -> any,
	ReadNumber: (string, number) -> any,
}

function Movement.createCharacter(dependencies: CharacterMovementDependencies): (any, () -> ())
	local movement: any = { SpeedSet = false, JumpSet = false }
	local function clean(fly: any) Movement.cleanFly(movement, fly) end

	function movement.StopFly() Movement.stopFly(movement, clean) end
	function movement.SetNoclip(enabled: any) Movement.setNoclip(dependencies.Player, movement, dependencies.Mover, enabled) end
	function movement.StartFly()
		Movement.startFly(movement, dependencies.LocalParts, dependencies.NewInstance, dependencies.RunService, dependencies.Force, dependencies.Zero, function(fly, root, velocity, humanoid, gyro)
			Movement.flyFrame({
				Movement = movement, Fly = fly, Root = root, Velocity = velocity, Humanoid = humanoid, Gyro = gyro,
				Workspace = dependencies.Workspace, Input = dependencies.Input, KeyCodes = dependencies.KeyCodes,
				NewVector = dependencies.NewVector, Zero = dependencies.Zero, Up = dependencies.Up,
				ReadNumber = dependencies.ReadNumber, Clean = clean,
			})
		end)
	end

	return movement, function()
		Movement.updateCharacter(dependencies.LocalParts, dependencies.ReadOption, dependencies.ReadNumber, movement)
	end
end

function Movement.create(dependencies: MoverDependencies): Mover
	local mover = {} :: Mover
	local heldMover = mover :: HeldMover
	local movementMover = mover :: MovementState
	local currentMover = mover :: { Target: unknown }
	local frame: FrameDependencies = { Player = dependencies.Player, Mover = heldMover, TypeOf = dependencies.TypeOf, ZeroVelocity = dependencies.ZeroVelocity }
	local stop: StopDependencies = { Player = dependencies.Player, Mover = heldMover, ZeroVelocity = dependencies.ZeroVelocity }
	local current: CurrentDependencies = { Mover = currentMover, CharacterParts = dependencies.CharacterParts, TypeOf = dependencies.TypeOf }
	local hold: HoldDependencies = {
		Player = dependencies.Player,
		Mover = heldMover,
		Heartbeat = dependencies.Heartbeat :: HoldSignal,
		OnFrame = function() Movement.onFrame(frame) end,
	}
	local movement: MovementDependencies = {
		Mover = movementMover,
		CharacterParts = dependencies.CharacterParts,
		Maximum = dependencies.Maximum,
		Clock = dependencies.Clock,
		IsAlive = dependencies.IsAlive,
		Minimum = dependencies.Minimum,
		Heartbeat = dependencies.Heartbeat :: Heartbeat,
	}

	function mover.Stop(destination) Movement.stop(stop, destination) end
	function mover.Hold(owner, target) return Movement.hold(hold, owner, target) end
	function mover.Current() return Movement.current(current) end
	function mover.Release(owner, destination) Movement.release(mover, owner, destination) end
	function mover.Glide(owner, goal, speed, canContinue)
		return Movement.glide(movement, owner, goal, speed, canContinue)
	end

	return mover
end

function Application.createAutomation(dependencies: any): any
	local function localParts() return Characters.localParts(dependencies.Player) end
	local mover = Movement.create({
		Player = dependencies.Player,
		Heartbeat = dependencies.Heartbeat,
		CharacterParts = localParts :: any,
		Maximum = math.max,
		Clock = dependencies.Clock,
		IsAlive = dependencies.IsRunning,
		Minimum = math.min,
		TypeOf = dependencies.TypeOf,
		ZeroVelocity = dependencies.Zero,
	})
	local locations = Farm.createLocations({
		Round = dependencies.Round,
		Workspace = dependencies.Workspace,
		Player = dependencies.Player,
		Parameters = dependencies.GroundParameters,
		NewVector = dependencies.NewVector,
		NewFrame = dependencies.NewFrame,
	})
	local farm = Farm.create({
		Round = dependencies.Round,
		Player = dependencies.Player,
		Mover = mover,
		CharacterParts = localParts :: any,
		PlayerCharacterParts = Characters.parts :: any,
		GroundAt = locations.GroundAt,
		SpawnPoint = locations.SpawnPoint,
		Fallback = locations.LobbySpawn,
		NewVector = dependencies.NewVector,
		NewFrameAt = dependencies.NewFrame,
		NewFrame = dependencies.NewFrame,
		ReadNumber = dependencies.ReadNumber,
		ReadBoolean = dependencies.ReadOption,
		ReadString = dependencies.ReadOption,
		IsAlive = dependencies.IsRunning,
		IsCoin = Farm.isCoin :: any,
		Minimum = math.min,
		Maximum = math.max,
		Clock = dependencies.Clock,
		BaseDelay = 0.35,
		Jitter = dependencies.Ping,
		Touch = dependencies.Touch,
		Heartbeat = dependencies.Heartbeat,
		Wait = dependencies.Wait,
		Players = dependencies.Players,
		Parameters = dependencies.ExposureParameters,
		Workspace = dependencies.Workspace,
		RayDirection = dependencies.NewVector(0, -7, 0),
	})
	return { Mover = mover, Farm = farm, Locations = locations }
end

function Application.createControllers(dependencies: any): any
	local function localParts() return Characters.localParts(dependencies.Player) end
	local movement, movementStep = Movement.createCharacter({
		Player = dependencies.Player,
		Mover = dependencies.Mover,
		LocalParts = localParts,
		NewInstance = dependencies.NewInstance,
		RunService = dependencies.RunService,
		Workspace = dependencies.Workspace,
		Input = dependencies.Input,
		KeyCodes = dependencies.KeyCodes,
		NewVector = dependencies.NewVector,
		Force = dependencies.NewVector(8999999488, 8999999488, 8999999488),
		Zero = dependencies.Zero,
		Up = dependencies.NewVector(0, 1, 0),
		ReadOption = dependencies.ReadOption,
		ReadNumber = dependencies.ReadNumber,
	})
	local combat = Combat.create({
		Round = dependencies.Round,
		Players = dependencies.Players,
		Player = dependencies.Player,
		CharacterParts = Characters.parts :: any,
		LocalParts = localParts,
		Mover = dependencies.Mover,
		ReadOption = dependencies.ReadOption,
		ReadNumber = dependencies.ReadNumber,
		IsRunning = dependencies.IsRunning,
		Clock = dependencies.Clock,
		Ping = dependencies.Ping,
		Maximum = math.max,
		Wait = dependencies.Wait,
		Sample = dependencies.Ping,
		Stats = dependencies.Stats,
		NewFrame = dependencies.NewFrame,
		NewFrameAt = dependencies.NewFrame,
		NewVector = dependencies.NewVector,
		NewZeroVector = function() return dependencies.NewVector() end,
		LookAt = dependencies.LookAt,
		Workspace = dependencies.Workspace,
		VisibilityParameters = dependencies.GroundParameters,
		Log = dependencies.Log,
	})
	local hooks = Hooks.create({
		Service = dependencies.Weapons,
		Cache = dependencies.HookCache,
		Player = dependencies.Player,
		ReadOption = dependencies.ReadOption,
		CharacterParts = Characters.parts :: any,
		Round = dependencies.Round,
		Combat = combat,
		Ping = dependencies.Ping,
		NewFrame = dependencies.NewFrame,
	})
	return { Movement = movement, MovementStep = movementStep, Combat = combat, Hooks = hooks }
end

function Application.createVisuals(dependencies: any): any
	local function localParts() return Characters.localParts(dependencies.Player) end
	local palette = Esp.palette(dependencies.NewColor)
	local folder = Esp.createFolder(dependencies.NewInstance, dependencies.CoreGui)
	local hasDrawing = false
	local white = dependencies.NewColor(1, 1, 1)
	local esp = Esp.create({
		Folder = folder,
		Entry = {
			NewInstance = dependencies.NewInstance,
			NewDrawing = if hasDrawing then dependencies.Drawing.new else nil,
			HasDrawing = hasDrawing,
			DepthMode = dependencies.DepthMode,
			BillboardSize = dependencies.NewUDim2(0, 200, 0, 40),
			Offset = dependencies.NewVector(0, 2.5999999046325684, 0),
			LabelSize = dependencies.NewUDim2(1, 0, 1, 0),
			Font = dependencies.Font,
			White = white,
		},
		Options = dependencies.Options,
		Palette = palette,
		White = white,
		TypeOf = dependencies.TypeOf,
		ReadOption = dependencies.ReadOption,
		ReadNumber = dependencies.ReadNumber,
		Select = Config.selection,
		LocalParts = localParts,
		Players = dependencies.Players,
		Player = dependencies.Player,
		Round = dependencies.Round,
		CharacterParts = Characters.parts :: any,
		Floor = math.floor,
		ObjectPosition = Inventory.position,
		Workspace = dependencies.Workspace,
		NewVector2 = dependencies.NewVector2,
	})
	local visuals, visualsStep = Appearance.create(dependencies.Lighting, dependencies.NewColor(0.6980392336845398, 0.6980392336845398, 0.6980392336845398))
	local settings = Settings.create({
		Lighting = dependencies.Lighting,
		Workspace = dependencies.Workspace,
		Visuals = visuals,
		RunService = dependencies.RunService,
		SetFpsCap = dependencies.SetFpsCap,
		Throttle = dependencies.Throttle,
		GetSettings = dependencies.GetSettings,
		LowestQuality = dependencies.LowestQuality,
	})
	return { Esp = esp, Visuals = visuals, VisualsStep = visualsStep, Settings = settings }
end

function Application.createSupport(dependencies: any): any
	local function localParts() return Characters.localParts(dependencies.Player) end
	local popups = Popups.create(dependencies.Player, dependencies.GetConnections, dependencies.FireSignal)
	local spectate = Spectate.create(dependencies.Workspace, Characters.parts :: any, localParts)
	local server = Server.create({
		Game = dependencies.Game,
		Http = dependencies.Http,
		Players = dependencies.Players,
		Teleport = dependencies.Teleport,
		Player = dependencies.Player,
		Minimum = math.min,
		Random = dependencies.Random,
	})
	local webhook, webhookStep = Webhook.create({
		ReadOption = dependencies.ReadOption,
		Player = dependencies.Player,
		DateTime = dependencies.DateTime,
		Http = dependencies.Http,
		Request = dependencies.Request,
		Clock = dependencies.Clock,
		Log = dependencies.Log,
	})
	local paths = Config.paths()
	local config = Config.create({
		Options = dependencies.Options,
		Http = dependencies.Http,
		Paths = paths,
		ReadOption = dependencies.ReadOption,
		TypeOf = dependencies.TypeOf,
		KeyCodes = dependencies.KeyCodes,
		FromHex = dependencies.FromHex,
		Clamp = math.clamp,
		Throttle = dependencies.Throttle,
		IsFolder = dependencies.IsFolder,
		MakeFolder = dependencies.MakeFolder,
		WriteFile = dependencies.WriteFile,
		ListFiles = dependencies.ListFiles,
	})
		local function fields()
		return Webhook.summaryFields(Helpers.formatNumber, dependencies.Stats, math.max, function(seconds)
			return Webhook.duration(seconds, math.max, math.floor)
		end, dependencies.Time)
	end
	local function decorate(embed: any) return Webhook.decorate(dependencies.ReadOption, dependencies.Player, webhook, embed) end
	local function summary(forced: any) return Webhook.summary(webhook, fields, decorate, forced) end
	return {
		Popups = popups, Spectate = spectate, Server = server, Webhook = webhook, WebhookStep = webhookStep,
		Paths = paths, Config = config, Fields = fields, Decorate = decorate, Summary = summary,
	}
end

function Movement.hold(dependencies: HoldDependencies, owner: string, target: unknown): boolean
	local character = dependencies.Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return false
	end

	local mover = dependencies.Mover

	if mover.Conn and mover.Char ~= character then
		mover.Stop()
	end

	mover.Owner = owner
	mover.Target = target

	if not mover.Conn then
		mover.Char = character
		mover.Saved = {}

		for _, part in ipairs((character :: HeldCharacter):GetDescendants()) do
			if part:IsA("BasePart") then
				(mover.Saved :: { [CollisionPart]: boolean })[part] = part.CanCollide
			end
		end

		mover.Conn = dependencies.Heartbeat:Connect(dependencies.OnFrame)
	end

	dependencies.OnFrame()
	return true
end

function Movement.onFrame(dependencies: FrameDependencies)
	local mover = dependencies.Mover
	local character = mover.Char
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root or character ~= dependencies.Player.Character then
		mover.Stop()
		return
	end

	local target = mover.Target

	if type(target) == "function" then
		local ok, value = pcall(target :: () -> unknown)
		target = if ok then value else nil
	end

	if dependencies.TypeOf(target) ~= "CFrame" then
		return
	end

	for part in pairs(mover.Saved :: { [CollisionPart]: boolean }) do
		if part.Parent then
			part.CanCollide = false
		end
	end

	root.CFrame = target
	root.AssemblyLinearVelocity = dependencies.ZeroVelocity
	root.AssemblyAngularVelocity = dependencies.ZeroVelocity
end

function Movement.stop(dependencies: StopDependencies, destination: unknown?)
	local mover = dependencies.Mover

	if mover.Conn then
		(mover.Conn :: HoldConnection):Disconnect()
		mover.Conn = nil
	end

	local character = mover.Char
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root and destination and dependencies.Player.Character == character then
		root.CFrame = destination
		root.AssemblyLinearVelocity = dependencies.ZeroVelocity
	end

	if mover.Saved then
		for part, canCollide in pairs(mover.Saved :: { [CollisionPart]: boolean }) do
			if part.Parent then
				part.CanCollide = canCollide
			end
		end
	end

	mover.Saved = nil
	mover.Char = nil
	mover.Owner = nil
	mover.Target = nil
end

function Movement.release(mover: { Owner: string?, Stop: (unknown?) -> () }, owner: string, destination: unknown?)
	if mover.Owner ~= owner then
		return
	end

	mover.Stop(destination)
end

function Movement.current(dependencies: CurrentDependencies): MoveFrame?
	local target = dependencies.Mover.Target

	if type(target) == "function" then
		local ok, value = pcall(target :: () -> unknown)
		target = if ok then value else nil
	end

	if dependencies.TypeOf(target) == "CFrame" then
		return target :: MoveFrame
	end

	local root = dependencies.CharacterParts()
	return root and root.CFrame or nil
end

function Movement.glide(
	dependencies: MovementDependencies,
	owner: string,
	goal: MoveFrame,
	speed: number,
	canContinue: (() -> boolean)?
): boolean
	local mover = dependencies.Mover
	local start = mover.Owner == owner and mover.Current()

	if not start then
		local root = dependencies.CharacterParts()
		if not root then return false end
		start = root.CFrame
	end

	local startFrame = start :: MoveFrame
	local distance = (goal.Position - startFrame.Position).Magnitude
	local duration = distance / dependencies.Maximum(speed, 1)

	if not mover.Hold(owner, startFrame) then
		return false
	end

	local started = dependencies.Clock()

	while true do
		if not dependencies.IsAlive() then return false end
		if mover.Owner ~= owner then return false end
		if not mover.Conn then return false end
		if canContinue and not canContinue() then return false end

		local alpha = 1

		if duration > 0 then
			alpha = dependencies.Minimum((dependencies.Clock() - started) / duration, 1)
		end

		mover.Target = startFrame:Lerp(goal, alpha)

		if alpha >= 1 then
			return true
		end

		dependencies.Heartbeat:Wait()
	end
end

export type InterfaceDependencies = {
	Library: any,
	Callbacks: { [string]: (...any) -> ...any },
	OnWindow: ((any) -> ())?,
	PlayerOptions: (() -> { any })?,
	ConfigOptions: (() -> { string })?,
	Throttle: (() -> ())?,
	DeferSettings: boolean?,
	NewColor3: (number, number, number) -> any,
	NewVector2: (number, number) -> any,
	NewUDim2: (number, number, number, number) -> any,
	MenuKey: any,
}

local function buildCoinFarmInterface(tabs: any, controls: any, dependencies: InterfaceDependencies)
	local section

	section = tabs["Coin Farm"]:Left("Auto Collect")
	controls["Coin Farm/Auto Collect/Status"] = section:CreateParagraph({ Content = "Loading...", Title = "Status" })
	controls["AutoCoins"] = section:CreateToggle("AutoCoins", {
		Default = false,
		Description = "Stays hidden under the map and grabs coins from below",
		Title = "Auto Collect Coins",
	})
	controls["CoinDelay"] = section:CreateSlider("CoinDelay", {
		Default = 1,
		Description = "Going faster than 1 coin per second can get you kicked",
		Max = 5,
		Min = 1,
		Rounding = 1,
		Title = "Seconds Per Coin",
	})
	controls["TravelSpeed"] = section:CreateSlider("TravelSpeed", {
		Default = 30,
		Description = "Studs per second while moving under the map",
		Max = 60,
		Min = 15,
		Rounding = 0,
		Title = "Travel Speed",
	})
	controls["HideDepth"] = section:CreateSlider("HideDepth", {
		Default = 8,
		Description = "How far under the floor you stay",
		Max = 15,
		Min = 6,
		Rounding = 0,
		Title = "Hide Depth",
	})
	controls["BagFullAction"] = section:CreateDropdown("BagFullAction", {
		AllowNull = false,
		Default = "Stay Hidden",
		Searchable = true,
		Title = "When Bag Is Full",
		Values = { "Stay Hidden", "Surface", "Reset Character" },
	})

	section = tabs["Coin Farm"]:Right("Safety")
	controls["AvoidMurderer"] = section:CreateToggle("AvoidMurderer", { Default = true, Description = "Skips coins close to the murderer", Title = "Avoid Murderer" })
	controls["AvoidRadius"] = section:CreateSlider("AvoidRadius", { Default = 20, Max = 60, Min = 8, Rounding = 0, Title = "Avoid Radius" })
	controls["SkipUpperCoins"] = section:CreateToggle("SkipUpperCoins", {
		Default = true,
		Description = "Skips coins where the hiding spot would be inside a room below",
		Title = "Skip Upper Floor Coins",
	})
	controls["Coin Farm/Safety/How it works"] = section:CreateCallout({
		Content = "You wait under the floor below each coin and grab it from there, so nobody can reach you. Turning the farm off brings you back up next to the last coin.",
		Style = "Info",
		Title = "How it works",
	})
end

local function buildCombatInterface(tabs: any, controls: any, dependencies: InterfaceDependencies)
	local section

	section = tabs["Combat"]:Left("Murderer")
	controls["Combat/Murderer/Round"] = section:CreateParagraph({ Content = "Loading...", Title = "Round" })
	controls["Combat/Murderer/Kill Everyone"] = section:CreateButton({
		Callback = assert(dependencies.Callbacks["Kill Everyone"]),
		Description = "Teleports to each player and stabs them",
		Title = "Kill Everyone",
	})
	controls["AutoKillAll"] = section:CreateToggle("AutoKillAll", { Default = false, Title = "Auto Kill Everyone" })
	controls["KillAllDelay"] = section:CreateSlider("KillAllDelay", {
		Default = 3,
		Description = "Seconds between kill rounds",
		Max = 15,
		Min = 1,
		Rounding = 0,
		Title = "Auto Kill Interval",
	})
	controls["SheriffFirst"] = section:CreateToggle("SheriffFirst", { Default = true, Description = "Kill the gun holder before anyone else", Title = "Sheriff First" })
	controls["AutoKillSheriff"] = section:CreateToggle("AutoKillSheriff", {
		Default = false,
		Description = "Goes for the sheriff or hero as soon as they have the gun",
		Title = "Auto Kill Sheriff",
	})
	controls["KillAura"] = section:CreateToggle("KillAura", { Default = false, Description = "Stabs players that come close, no teleport", Title = "Kill Aura" })
	controls["KillAuraRange"] = section:CreateSlider("KillAuraRange", { Default = 12, Max = 20, Min = 5, Rounding = 0, Title = "Kill Aura Range" })
	controls["Combat/Murderer/Throw Knife At Sheriff"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Throw Knife At Sheriff"]), Title = "Throw Knife At Sheriff" })
	controls["KnifeSilentAim"] = section:CreateToggle("KnifeSilentAim", { Default = false, Description = "Your knife throws go to the target", Title = "Knife Silent Aim" })
	controls["KnifeAimSheriff"] = section:CreateToggle("KnifeAimSheriff", { Default = true, Title = "Aim At Sheriff First" })

	section = tabs["Combat"]:Right("Sheriff")
	controls["Combat/Sheriff/Shoot Murderer"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Shoot Murderer"]), Title = "Shoot Murderer" })
	controls["AutoShoot"] = section:CreateToggle("AutoShoot", {
		Default = false,
		Description = "Fires when you hold the gun and have a clear shot",
		Title = "Auto Shoot Murderer",
	})
	controls["ShootTeleport"] = section:CreateToggle("ShootTeleport", {
		Default = false,
		Description = "Auto shoot moves you next to the murderer when a wall is in the way",
		Title = "Teleport For A Clear Shot",
	})
	controls["ShootCooldown"] = section:CreateSlider("ShootCooldown", {
		Default = 15,
		Description = "In tenths of a second",
		Max = 40,
		Min = 5,
		Rounding = 0,
		Title = "Auto Shoot Cooldown",
	})
	controls["ShootRange"] = section:CreateSlider("ShootRange", { Default = 120, Max = 300, Min = 30, Rounding = 0, Title = "Max Shot Distance" })
	controls["GunSilentAim"] = section:CreateToggle("GunSilentAim", { Default = false, Description = "Your shots go to the murderer", Title = "Gun Silent Aim" })
	controls["GunPrediction"] = section:CreateSlider("GunPrediction", {
		Default = 10,
		Description = "Leads moving targets, in hundredths of a second",
		Max = 40,
		Min = 0,
		Rounding = 0,
		Title = "Shot Prediction",
	})

	section = tabs["Combat"]:Right("Dropped Gun")
	controls["Combat/Dropped Gun/Grab Gun"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Grab Gun"]), Title = "Grab Gun" })
	controls["AutoGrabGun"] = section:CreateToggle("AutoGrabGun", { Default = false, Description = "Picks up the gun when the sheriff dies", Title = "Auto Grab Gun" })
	controls["GrabSafeRadius"] = section:CreateSlider("GrabSafeRadius", {
		Default = 15,
		Description = "Waits if the murderer is this close to the gun",
		Max = 50,
		Min = 0,
		Rounding = 0,
		Title = "Grab Safe Radius",
	})
end

local function buildVisualsInterface(tabs,controls,dependencies)
    local section=tabs.Visuals:Left("Player ESP")
    controls.EspOn=section:CreateToggle("EspOn",{Title="Enabled",Default=false})
    controls.EspRoles=section:CreateDropdown("EspRoles",{Title="Roles",Values={"Murderer","Sheriff","Hero","Innocent","Zombie","Survivor"},Default={"Murderer","Sheriff","Hero","Innocent","Zombie","Survivor"},Multi=true})
    local function visual(group,flag,name,palette)
        local item=group:CreateToggle(flag,{Title=name,Default=false})controls[flag]=item
        if palette then
            local picker
            local n=item.Native:Colorpicker({Flag="MM2_"..palette,Default=Color3.fromRGB(45,140,255),Callback=function(v)if picker then picker:Emit(v)end end})
            picker={Value=Color3.fromRGB(45,140,255),Type="Colorpicker",Changed={}}
            function picker:Emit(v)self.Value=v for _,fn in ipairs(self.Changed)do fn(v)end end
            function picker:SetValueRGB(v)n:Set(v)end
            function picker:OnChanged(fn)table.insert(self.Changed,fn)end
            dependencies.Library.Options[palette]=picker
        end
    end
    visual(section,"EspBoxes","Boxes","BoxColor")
    visual(section,"EspNames","Names and roles","NameColor")
    visual(section,"EspDistance","Distance","DistanceColor")
    visual(section,"EspHealth","Health","HealthColor")
    visual(section,"EspSkeletons","Skeletons","SkeletonColor")
    controls.SkeletonThickness=section:CreateSlider("SkeletonThickness",{Title="Skeleton thickness",Min=1,Max=4,Default=1.2,Rounding=1})
    visual(section,"EspTracers","Tracers","TracerColor")
    visual(section,"EspGun","Dropped gun","GunColor")
    controls.EspMaxDistance=section:CreateSlider("EspMaxDistance",{Title="Max distance",Min=50,Max=3000,Default=1500,Rounding=0})
    section=tabs.Visuals:Right("Chams")
    visual(section,"EspChams","Enabled","ChamsColor")
    controls.ChamsMaterial=section:CreateDropdown("ChamsMaterial",{Title="Material",Values={"SmoothPlastic","Plastic","Neon","ForceField","Glass","Metal","DiamondPlate","Foil","Wood","Marble","Ice","Fabric"},Default="Neon"})
    controls.ChamsTransparency=section:CreateSlider("ChamsTransparency",{Title="Transparency",Min=0,Max=.9,Default=.25,Rounding=2})
    visual(section,"EspGlow","Glow","GlowColor")visual(section,"EspShader","Shader chams","ShaderColor")
    section=tabs.Visuals:Right("Alerts")
    controls.AnnounceRoles=section:CreateToggle("AnnounceRoles",{Title="Round roles",Default=false})
    controls.AnnounceGun=section:CreateToggle("AnnounceGun",{Title="Gun dropped",Default=false})
    section=tabs.Visuals:Right("World")
    controls.Fullbright=section:CreateToggle("Fullbright",{Title="Fullbright",Default=false,Callback=dependencies.Callbacks.Fullbright})
end

local function buildMovementInterface(tabs: any, controls: any, dependencies: InterfaceDependencies)
	local section

	section = tabs["Movement"]:Left("Character")
	controls["SpeedOn"] = section:CreateToggle("SpeedOn", { Default = false, Title = "Custom Walk Speed" })
	controls["SpeedValue"] = section:CreateSlider("SpeedValue", { Default = 24, Max = 100, Min = 16, Rounding = 0, Title = "Walk Speed" })
	controls["JumpOn"] = section:CreateToggle("JumpOn", { Default = false, Title = "Custom Jump Power" })
	controls["JumpValue"] = section:CreateSlider("JumpValue", { Default = 70, Max = 200, Min = 50, Rounding = 0, Title = "Jump Power" })
	controls["InfJump"] = section:CreateToggle("InfJump", { Default = false, Title = "Infinite Jump" })

	section = tabs["Movement"]:Left("Fly And Noclip")
	controls["Fly"] = section:CreateToggle("Fly", {
		Default = false,
		Description = "Move with your normal controls, Space or E to go up, Q to go down",
		Title = "Fly",
	})
	controls["FlySpeed"] = section:CreateSlider("FlySpeed", { Default = 60, Max = 200, Min = 10, Rounding = 0, Title = "Fly Speed" })
	controls["FlyKey"] = section:CreateKeybind("FlyKey", { Callback = assert(dependencies.Callbacks["FlyKey"]), Default = "F", Mode = "Toggle", Title = "Fly Key" })
	controls["Noclip"] = section:CreateToggle("Noclip", { Callback = assert(dependencies.Callbacks["Noclip"]), Default = false, Title = "Noclip" })
	controls["NoclipKey"] = section:CreateKeybind("NoclipKey", {
		Callback = assert(dependencies.Callbacks["NoclipKey"]),
		Default = "N",
		Mode = "Toggle",
		Title = "Noclip Key",
	})
	controls["ClickTp"] = section:CreateToggle("ClickTp", { Default = false, Description = "Hold the key below and click to teleport", Title = "Click Teleport" })
	controls["ClickTpKey"] = section:CreateKeybind("ClickTpKey", { Default = "LeftAlt", Mode = "Hold", Title = "Click Teleport Key" })

	section = tabs["Movement"]:Right("Teleport")
	controls["Movement/Teleport/To Lobby"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["To Lobby"]), Title = "To Lobby" })
	controls["Movement/Teleport/To Map"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["To Map"]), Title = "To Map" })
	controls["Movement/Teleport/To Murderer"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["To Murderer"]), Title = "To Murderer" })
	controls["Movement/Teleport/To Sheriff"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["To Sheriff"]), Title = "To Sheriff" })
	controls["Movement/Teleport/To Dropped Gun"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["To Dropped Gun"]), Title = "To Dropped Gun" })
	controls["_TpPlayer"] = section:CreateDropdown("_TpPlayer", { Searchable = true, Title = "Player", Values = if dependencies.PlayerOptions then dependencies.PlayerOptions() else {} })
	controls["Movement/Teleport/Teleport To Player"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Teleport To Player"]), Title = "Teleport To Player" })
end

local function buildNotificationsInterface(tabs: any, controls: any, dependencies: InterfaceDependencies)
	local section

	section = tabs["Notifications"]:Left("Discord Webhook")
	controls["_WebhookURL"] = section:CreateInput("_WebhookURL", {
		Default = "",
		Description = "Stays on this PC, never exported",
		Finished = true,
		Placeholder = "https://discord.com/api/webhooks/...",
		Title = "Webhook URL",
	})
	controls["_WebhookPing"] = section:CreateInput("_WebhookPing", {
		Default = "",
		Finished = true,
		Numeric = true,
		Placeholder = "Optional",
		Title = "Discord User ID To Ping",
	})
	controls["WebhookEnabled"] = section:CreateToggle("WebhookEnabled", { Default = false, Title = "Send Notifications" })
	controls["WebhookHideName"] = section:CreateToggle("WebhookHideName", { Default = false, Title = "Hide Username" })

	section = tabs["Notifications"]:Right("Events")
	controls["WebhookEvents"] = section:CreateDropdown("WebhookEvents", {
		Default = { "Round End", "Bag Full", "Disconnected", "Session Summary" },
		Multi = true,
		Searchable = true,
		Title = "Events",
		Values = { "Round Start", "Round End", "Bag Full", "Disconnected", "Session Summary" },
	})
	controls["WebhookSummaryEvery"] = section:CreateDropdown("WebhookSummaryEvery", {
		AllowNull = false,
		Default = "30 min",
		Searchable = true,
		Title = "Summary Interval",
		Values = { "15 min", "30 min", "60 min" },
	})
	controls["Notifications/Events/Send Test Message"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Send Test Message"]), Title = "Send Test Message" })
	controls["Notifications/Events/Send Summary Now"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Send Summary Now"]), Title = "Send Summary Now" })
end

local function buildMiscInterface(tabs: any, controls: any, dependencies: InterfaceDependencies)
	local section

	section = tabs["Misc"]:Left("Spectate")
	controls["_SpecPlayer"] = section:CreateDropdown("_SpecPlayer", { Searchable = true, Title = "Player", Values = if dependencies.PlayerOptions then dependencies.PlayerOptions() else {} })
	controls["Misc/Spectate/Spectate Player"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Spectate Player"]), Title = "Spectate Player" })
	controls["Misc/Spectate/Spectate Murderer"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Spectate Murderer"]), Title = "Spectate Murderer" })
	controls["Misc/Spectate/Stop Spectating"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Stop Spectating"]), Title = "Stop Spectating" })

	section = tabs["Misc"]:Left("Server")
	controls["Misc/Server/Join Fuller Server"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Join Fuller Server"]), Title = "Join Fuller Server" })
	controls["Misc/Server/Join Emptier Server"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Join Emptier Server"]), Title = "Join Emptier Server" })
	controls["Misc/Server/Rejoin"] = section:CreateButton({ Callback = assert(dependencies.Callbacks["Rejoin"]), Title = "Rejoin" })
	controls["AntiAFK"] = section:CreateToggle("AntiAFK", { Default = true, Title = "Anti AFK" })
	controls["AutoRejoin"] = section:CreateToggle("AutoRejoin", { Default = false, Description = "Joins back when you get kicked or disconnected", Title = "Auto Rejoin" })

	section = tabs["Misc"]:Right("Performance")
	controls["FpsCap"] = section:CreateDropdown("FpsCap", {
		AllowNull = false,
		Callback = assert(dependencies.Callbacks["FpsCap"]),
		Default = "Off",
		Searchable = true,
		Title = "FPS Cap",
		Values = { "Off", "15", "30", "60", "90", "120", "144", "240", "Unlimited" },
	})
	controls["No3D"] = section:CreateToggle("No3D", { Callback = assert(dependencies.Callbacks["No3D"]), Default = false, Title = "Disable 3D Rendering" })
	controls["LowGraphics"] = section:CreateToggle("LowGraphics", {
		Callback = assert(dependencies.Callbacks["LowGraphics"]),
		Default = false,
		Description = "No shadows or particles",
		Title = "Low Graphics",
	})
end

local function buildSettingsInterface(tabs,controls,dependencies)
    local callbacks=dependencies.Callbacks
    local section=tabs.Settings:Left("Configs")
    controls._ConfigSelect=section:CreateListbox("_ConfigSelect",{Values=dependencies.ConfigOptions and dependencies.ConfigOptions() or {}})
    controls._ConfigName=section:CreateInput("_ConfigName",{Title="Name",Default="",Placeholder="Name",Finished=false})
    section:CreateButton({Title="Create",Callback=callbacks["Save Config"]})
    section:CreateButton({Title="Delete",Callback=callbacks["Delete Config"]})
    section:CreateButton({Title="Load",Callback=callbacks["Load Config"]})
    section:CreateButton({Title="Save",Callback=function()local value=controls._ConfigSelect.Value if value then controls._ConfigName:SetValue(value)callbacks["Save Config"]()end end})
    section:CreateButton({Title="Refresh",Callback=function()controls._ConfigSelect:SetValues(dependencies.ConfigOptions())end})
    section=tabs.Settings:Right("UI Settings")
    section:CreateToggle("Watermark",{Title="Watermark",Default=false,Callback=function(v)dependencies.Library.Native:SetWatermarkVisible(v)end})
    section:CreateToggle("KeybindList",{Title="Keybind List",Default=false,Callback=function(v)(dependencies.Library.Native.KeyList or dependencies.Library.Native:KeybindList("Keybinds")):SetVisibility(v)end})
    section=tabs.Settings:Right("Session")
    controls.Autosave=section:CreateToggle("Autosave",{Title="Autosave",Default=true})
    controls.MenuKeybind=section:CreateKeybind("MenuKeybind",{Title="Menu key",Default="RightShift"})
    section:CreateButton({Title="Unload script",Callback=callbacks["Unload Hub"]})
    dependencies.Library:Finish()
end

export type CombatInterfaceDependencies = {
	Round: any,
	Combat: any,
	Spawn: (() -> ()) -> (),
	ShowMessage: (string) -> (),
	ShowResult: (...any) -> (),
}

function Interface.combatCallbacks(dependencies: CombatInterfaceDependencies): { [string]: () -> () }
	local round, combat = dependencies.Round, dependencies.Combat

	return {
		["Kill Everyone"] = function()
			dependencies.Spawn(function() dependencies.ShowResult(combat.KillAll()) end)
		end,
		["Shoot Murderer"] = function()
			dependencies.Spawn(function() dependencies.ShowResult(combat.ShootMurderer(true)) end)
		end,
		["Grab Gun"] = function()
			dependencies.Spawn(function() dependencies.ShowResult(combat.GrabGun()) end)
		end,
		["Throw Knife At Sheriff"] = function()
			local sheriff = round.Sheriff()
			if round.MyRole() ~= "Murderer" then
				dependencies.ShowMessage("You are not the murderer")
				return
			end
			if not sheriff then
				dependencies.ShowMessage("No sheriff found")
				return
			end

			dependencies.ShowResult(combat.Throw(sheriff), "Could not throw the knife")
		end,
	}
end

export type TeleportInterfaceDependencies = {
	Round: any,
	Lobby: () -> any,
	Map: () -> any,
	PlayerPosition: (any) -> any,
	ObjectPosition: (any) -> any,
	Offset: any,
	NewFrame: (any) -> any,
	ReadOption: (string) -> any,
	Teleport: (any) -> any,
	ShowMessage: (string) -> ...any,
	ShowResult: (any, string) -> (),
}

function Interface.teleportCallbacks(dependencies: TeleportInterfaceDependencies): { [string]: () -> ...any }
	local round = dependencies.Round

	return {
		["To Lobby"] = function()
			dependencies.ShowResult(dependencies.Teleport(dependencies.Lobby()), "Lobby not found")
		end,
		["To Map"] = function()
			dependencies.ShowResult(dependencies.Teleport(dependencies.Map()), "No map loaded")
		end,
		["To Murderer"] = function()
			dependencies.ShowResult(dependencies.Teleport(dependencies.PlayerPosition(round.Murderer())), "No murderer found")
		end,
		["To Sheriff"] = function()
			dependencies.ShowResult(dependencies.Teleport(dependencies.PlayerPosition(round.Sheriff())), "No sheriff found")
		end,
		["To Dropped Gun"] = function()
			local position = dependencies.ObjectPosition(round.GunDrop())
			local frame = if position then dependencies.NewFrame(position + dependencies.Offset) else nil
			dependencies.ShowResult(dependencies.Teleport(frame), "No dropped gun")
		end,
		["Teleport To Player"] = function()
			local player = dependencies.ReadOption("_TpPlayer")
			if not player then
				return dependencies.ShowMessage("Select a player")
			end

			dependencies.ShowResult(dependencies.Teleport(dependencies.PlayerPosition(player)), "Player has no character")
		end,
	}
end

export type MiscInterfaceDependencies = {
	Popups: any,
	Round: any,
	Spectate: any,
	Schedule: (() -> ()) -> (),
	ReadOption: (string) -> any,
	ShowMessage: (string) -> (),
	ShowResult: (any, string, string?) -> (),
}

function Interface.miscCallbacks(dependencies: MiscInterfaceDependencies): { [string]: () -> () }
	return {
		["Claim Pop Ups Now"] = function()
			dependencies.Schedule(function()
				local count = dependencies.Popups.ClaimAll()
				local message = if count > 0 then "Claimed " .. count .. " pop ups" else "No pop up open"
				dependencies.ShowMessage(message)
			end)
		end,
		["Spectate Player"] = function()
			local player = dependencies.ReadOption("_SpecPlayer")
			if not player then
				dependencies.ShowMessage("Select a player")
				return
			end
			dependencies.ShowResult(dependencies.Spectate.Set(player), "Player has no character", "Spectating " .. player.DisplayName)
		end,
		["Spectate Murderer"] = function()
			local player = dependencies.Round.Murderer()
			local ok = if player then dependencies.Spectate.Set(player) else nil
			dependencies.ShowResult(ok, "No murderer found", if player then "Spectating " .. player.DisplayName else nil)
		end,
	}
end

function Interface.serverCallbacks(server: any, schedule: (() -> ()) -> (), showResult: (...any) -> ()): { [string]: () -> () }
	return {
		["Join Fuller Server"] = function()
			schedule(function() showResult(server.Hop("Most")) end)
		end,
		["Join Emptier Server"] = function()
			schedule(function() showResult(server.Hop("Fewest")) end)
		end,
	}
end

function Interface.notify(library: any, message: any)
	pcall(function() library:Notify({ Title = "Axis", Content = message, Duration = 4 }) end)
end

function Interface.showResult(notify: (any) -> (), success: any, failure: any, message: any)
	if success then
		if message then notify(message) end
		return
	end
	notify(failure or "Failed")
end

function Interface.playerAdded(delay: (number, () -> ()) -> (), refresh: () -> ())
	delay(0.5, refresh)
end

function Interface.playerOptions(players: any, localPlayer: any): { any }
	local values = {}
	for _, player in ipairs(players:GetPlayers()) do
		if player ~= localPlayer then table.insert(values, player.Name) end
	end
	table.sort(values, function(a: string, b: string) return string.lower(a) < string.lower(b) end)
	return values
end

function Interface.selectedPlayer(readOption: (string, any) -> any, players: any, name: string): any
	local selected = readOption(name, nil)
	if type(selected) ~= "string" then return nil end
	return players:FindFirstChild(selected)
end

function Interface.setContent(cache: any, control: any, value: any)
	if not control or cache[control] == value then return end
	cache[control] = value
	if control.SetContent then
		control:SetContent(value)
	else
		control:SetDesc(value)
	end
end

function Interface.setValue(cache: any, control: any, value: any)
	if not control or cache[control] == value then return end
	cache[control] = value
	local setValue = control.SetValue
	pcall(setValue, control, value)
end

function Interface.syncMenuKey(keybind: (any) -> any, options: any, ui: any, library: any)
	local key = keybind(options.MenuKeybind)
	if not key or key == ui.LastMenuKey then return end

	library.MinimizeKey = key
	if library._axisWindow then
		pcall(function() library._axisWindow:SetKeybind(key) end)
	end
	ui.LastMenuKey = key
end

function Interface.createState(controls: any, keybind: (any) -> any, options: any, library: any): any
	local ui: any = {
		FarmStatus = controls["Coin Farm/Auto Collect/Status"],
		CombatInfo = controls["Combat/Murderer/Round"],
		TpPlayer = controls._TpPlayer,
		SpecPlayer = controls._SpecPlayer,
		ConfigList = controls._ConfigSelect,
	}
	function ui.SyncMenuKey() Interface.syncMenuKey(keybind, options, ui, library) end
	return ui
end

export type InterfaceUpdateDependencies = {
	Farm: any,
	FormatNumber: (any) -> any,
	Stats: any,
	SetContent: (any, any) -> (),
	Ui: any,
	SetValue: (any, any) -> (),
	Round: any,
	Player: any,
	FormatName: (any) -> any,
	Minimum: (number, number) -> number,
	ReadOption: (string, any) -> any,
	Quest: any,
}

function Interface.update(dependencies: InterfaceUpdateDependencies)
	local farm, stats, ui = dependencies.Farm, dependencies.Stats, dependencies.Ui
	local format, setContent, setValue = dependencies.FormatNumber, dependencies.SetContent, dependencies.SetValue
	local farmText = string.format("%s\nBags: %s\nCoins this session: %s", farm.Status, farm.BagText(), format(stats.Coins))
	setContent(ui.FarmStatus, farmText)
	setContent(ui.HomeFarm, if farm.Enabled() then farmText else "Off")
	setValue(ui.CoinsCard, format(stats.Coins))
	setValue(ui.RoundsCard, format(stats.Rounds))
	setValue(ui.KillsCard, format(stats.Kills))
	if ui.SyncMenuKey then (ui.SyncMenuKey :: any)() end

	local round = dependencies.Round
	local map, info = round.Map(), round.Info(dependencies.Player)
	local roundText
	if info then
		local role, murderer, sheriff = round.MyRole(), round.Murderer(), round.Sheriff()
		local sheriffRole = if sheriff and round.Role(sheriff) == "Hero" then "Hero" else "Sheriff"
		local gun = if round.GunDrop() then "The gun is on the ground" else "Gun is not dropped"
		roundText = string.format("Map: %s | You: %s\nMurderer: %s\n%s: %s\n%s", (if map then map.Name else "Loading") :: any, role, (if murderer then murderer.DisplayName else "None alive") :: any, sheriffRole, (if sheriff then sheriff.DisplayName else "None alive") :: any, gun)
	elseif map then
		roundText = "Round in progress | you are not in it"
	else
		roundText = "Waiting for the next round"
	end
	setContent(ui.HomeRound, roundText)
	setContent(ui.CombatInfo, roundText)


end

function Interface.refreshPlayers(list: () -> any, ui: any)
	local values = list()
	local teleport, spectate = ui.TpPlayer, ui.SpecPlayer
	if teleport then
		teleport:SetValues(values)
		if spectate then spectate:SetValues(values) end
	end
end

function Interface.playerRemoving(spectate: any, delay: (number, () -> ()) -> (), refresh: () -> (), player: any)
	if spectate.Target == player then spectate.Set(nil) end
	delay(0.5, refresh)
end

export type WebhookInterfaceDependencies = {
	Webhook: any,
	Notify: (string) -> (),
	Schedule: (() -> ()) -> (),
	Decorate: (any) -> any,
	Summary: (boolean) -> (any, any),
}

function Interface.webhookCallbacks(dependencies: WebhookInterfaceDependencies): { [string]: () -> () }
	local webhook = dependencies.Webhook
	local function ready(): boolean
		if webhook.Url() then return true end
		dependencies.Notify("Enter a valid Discord webhook URL first")
		return false
	end
	return {
		["Send Test Message"] = function()
			if not ready() then return end
			dependencies.Schedule(function()
				local post = webhook.Post
				local embed = webhook.Embed("Webhook connected", "Notifications from Axis | Murder Mystery 2 will appear here.", 5763719)
				local ok, failure = post({ username = "Axis", embeds = { dependencies.Decorate(embed) } })
				dependencies.Notify(if ok then "Test message sent" else "Webhook failed: " .. tostring(failure))
			end)
		end,
		["Send Summary Now"] = function()
			if not ready() then return end
			dependencies.Schedule(function()
				local ok, failure = dependencies.Summary(true)
				dependencies.Notify(if ok then "Summary sent" else "Webhook failed: " .. tostring(failure))
			end)
		end,
	}
end

export type MovementInterfaceDependencies = {
	Movement: any,
	Input: any,
	Options: any,
}

export type SimpleInterfaceDependencies = {
	Window: any,
	Library: any,
	Visuals: any,
	Settings: any,
	Spectate: any,
	Server: any,
	Unload: () -> (),
}

function Interface.simpleCallbacks(dependencies: SimpleInterfaceDependencies): { [string]: (...any) -> () }
	local window, settings = dependencies.Window, dependencies.Settings
	return {
		["Open Coin Farm"] = function() window:SelectTab("Coin Farm") end,
		["Open Combat"] = function() window:SelectTab("Combat") end,
		Fullbright = function(enabled: any) dependencies.Visuals.Fullbright(enabled) end,
		FpsCap = function(value: any) settings.SetFps(value) end,
		No3D = function(enabled: any) settings.Set3D(not enabled) end,
		LowGraphics = function(enabled: any) settings.LowGraphics(enabled) end,
		["Stop Spectating"] = function() dependencies.Spectate.Set(nil) end,
		Rejoin = function() dependencies.Server.Rejoin() end,
		["Unload Hub"] = dependencies.Unload,
	}
end

function Interface.movementCallbacks(dependencies: MovementInterfaceDependencies): { [string]: (...any) -> () }
	local movement, input, options = dependencies.Movement, dependencies.Input, dependencies.Options
	return {
		Noclip = function(enabled: any)
			if not enabled then movement.SetNoclip(false) end
		end,
		FlyKey = function()
			if input:GetFocusedTextBox() or not options.Fly then return end
			local option = options.Fly
			local setValue = option.SetValue
			setValue(option, not options.Fly.Value)
		end,
		NoclipKey = function()
			if input:GetFocusedTextBox() or not options.Noclip then return end
			local option = options.Noclip
			local setValue = option.SetValue
			setValue(option, not options.Noclip.Value)
		end,
	}
end

export type ConfigInterfaceDependencies = {
	ReadOption: (string, any) -> any,
	Notify: (string) -> (),
	EnsureFolder: (any) -> (),
	Paths: any,
	WriteJson: (any, any) -> any,
	ReadJson: (any) -> any,
	Config: any,
	Ui: any,
	DeleteFile: any,
	Clipboard: any,
	Print: (...any) -> (),
}

function Interface.configCallbacks(dependencies: ConfigInterfaceDependencies): { [string]: () -> () }
	local config, paths = dependencies.Config, dependencies.Paths

	return {
		["Save Config"] = function()
			local name = Config.name(dependencies.ReadOption("_ConfigName", ""))
			if not name then
				dependencies.Notify("Enter a config name")
				return
			end

			dependencies.EnsureFolder(paths.Root)
			dependencies.EnsureFolder(paths.Game)
			dependencies.EnsureFolder(paths.Configs)
			if not dependencies.WriteJson(paths.Configs .. "/" .. name .. ".json", config.Collect()) then
				dependencies.Notify("Saving is not supported by your executor")
				return
			end

			dependencies.Notify("Config saved: " .. name)
			local list = dependencies.Ui.ConfigList
			local setValues = list.SetValues
			setValues(list, config.List())
		end,
		["Load Config"] = function()
			local name = dependencies.ReadOption("_ConfigSelect", nil)
			if not name then
				dependencies.Notify("Select a config")
				return
			end

			local data = dependencies.ReadJson(paths.Configs .. "/" .. name .. ".json")
			if not data then
				dependencies.Notify("Could not read " .. name)
				return
			end

			local applied, skipped = config.Apply(data)
			dependencies.Notify(string.format("Loaded %s (%d settings%s)", name, applied, Config.skippedSuffix(skipped)))
		end,
		["Delete Config"] = function()
			local name = dependencies.ReadOption("_ConfigSelect", nil)
			if not name or not dependencies.DeleteFile then
				dependencies.Notify("Select a config")
				return
			end

			pcall(dependencies.DeleteFile, paths.Configs .. "/" .. name .. ".json")
			local list = dependencies.Ui.ConfigList
			local setValues = list.SetValues
			setValues(list, config.List())
			dependencies.Notify("Deleted " .. name)
		end,

	}
end

function Interface.create(dependencies: InterfaceDependencies): any
	local library = dependencies.Library
	local tabs = {}
	local controls = {}
	local window = library:CreateWindow({
		MinSize = dependencies.NewVector2(700, 480),
		MinimizeKey = dependencies.MenuKey,
		Size = dependencies.NewUDim2(0, 1040, 0, 720),
		SubTitle = "Murder Mystery 2",
		TabWidth = 160,
		Title = "Axis",
	})
	if dependencies.OnWindow then dependencies.OnWindow(window) end
	window:Divider("Dashboard")
	window:Divider("Gameplay")
	tabs["Coin Farm"] = window:CreateTab({ Icon = "coins", Title = "Coin Farm" })
	tabs["Combat"] = window:CreateTab({ Icon = "swords", Title = "Combat" })
	tabs["Visuals"] = window:CreateTab({ Icon = "eye", Title = "Visuals" })
	tabs["Movement"] = window:CreateTab({ Icon = "move", Title = "Movement" })
	window:Divider("Activities")
	window:Divider("Utility & Settings")
	tabs["Notifications"] = window:CreateTab({ Icon = "send", Title = "Notifications" })
	tabs["Misc"] = window:CreateTab({ Icon = "gauge", Title = "Misc" })
	tabs["Settings"] = window:CreateTab({ Icon = "settings", Title = "Settings" })

	local layoutTabs = tabs
	local throttle = dependencies.Throttle
	if throttle then
		layoutTabs = {}
		for name, tab: any in pairs(tabs) do
			layoutTabs[name] = setmetatable({}, { __index = function(_, side)
				return function(_, ...)
					throttle()
					local section = tab[side](tab, ...)
					throttle()
					return setmetatable({}, { __index = function(_, method)
						return function(_, ...)
							throttle()
							local result = section[method](section, ...)
							throttle()
							return result
						end
					end })
				end
			end })
		end
	end
	buildCoinFarmInterface(layoutTabs, controls, dependencies)
	buildCombatInterface(layoutTabs, controls, dependencies)
	buildVisualsInterface(layoutTabs, controls, dependencies)
	buildMovementInterface(layoutTabs, controls, dependencies)
	buildNotificationsInterface(layoutTabs, controls, dependencies)
	buildMiscInterface(layoutTabs, controls, dependencies)
	local function finishSettings() buildSettingsInterface(layoutTabs, controls, dependencies) end
	if not dependencies.DeferSettings then finishSettings() end

	return { Window = window, Tabs = tabs, Controls = controls, FinishSettings = finishSettings }
end

function Application.createInterface(dependencies: any): any
	local window: any, ui: any
	local windowProxy = {
		SelectTab = function(_, name) return window:SelectTab(name) end,
	}
	local uiProxy = setmetatable({}, { __index = function(_, name) return ui[name] end })
	local function notify(message: any) Interface.notify(dependencies.Library, message) end
	local function showResult(success: any, failure: any, message: any)
		Interface.showResult(notify, success, failure, message)
	end
	local function schedule(callback: () -> ())
		Lifecycle.schedule(dependencies.Spawn, dependencies.Protect, callback)
	end
	local function localParts() return Characters.localParts(dependencies.Player) end
	local function selected(name: string) return Interface.selectedPlayer(dependencies.ReadOption, dependencies.Players, name) end
	local function ensureFolder(path: any) Config.ensureFolder(dependencies.IsFolder, dependencies.MakeFolder, path) end
	local function writeJson(path: any, data: any)
		return Config.writeJson(ensureFolder, dependencies.Support.Paths, dependencies.Http, dependencies.WriteFile, path, data)
	end
	local function readJson(path: any) return Config.readJson(dependencies.Http, dependencies.IsFile, dependencies.ReadFile, path) end
	local callbacks: any = {}
	for _, group in {
		Interface.simpleCallbacks({
			Window = windowProxy, Library = dependencies.Library, Visuals = dependencies.Visuals,
			Settings = dependencies.Settings, Spectate = dependencies.Support.Spectate, Server = dependencies.Support.Server,
			Unload = function() dependencies.State.Unload() end,
		}),
		Interface.movementCallbacks({ Movement = dependencies.Movement, Input = dependencies.Input, Options = dependencies.Options }),
		Interface.combatCallbacks({
			Round = dependencies.Round, Combat = dependencies.Combat, Spawn = dependencies.Spawn,
			ShowMessage = notify, ShowResult = showResult,
		}),
		Interface.teleportCallbacks({
			Round = dependencies.Round, Lobby = dependencies.Locations.LobbySpawn, Map = dependencies.Locations.SpawnPoint,
			PlayerPosition = function(player) return Movement.playerFrame(Characters.parts :: any, dependencies.NewFrame, player) end,
			ObjectPosition = Inventory.position, Offset = dependencies.NewVector(0, 3.200000047683716, 0),
			NewFrame = dependencies.NewFrame, ReadOption = selected,
			Teleport = function(frame) return Movement.teleport(localParts, dependencies.Mover, dependencies.Zero, frame) end,
			ShowMessage = notify, ShowResult = showResult,
		}),
		Interface.miscCallbacks({
			Popups = dependencies.Support.Popups, Round = dependencies.Round, Spectate = dependencies.Support.Spectate,
			Schedule = schedule, ReadOption = selected, ShowMessage = notify, ShowResult = showResult,
		}),
		Interface.serverCallbacks(dependencies.Support.Server, schedule, showResult),
		Interface.webhookCallbacks({
			Webhook = dependencies.Support.Webhook, Notify = notify, Schedule = schedule,
			Decorate = dependencies.Support.Decorate, Summary = dependencies.Support.Summary,
		}),
		Interface.configCallbacks({
			ReadOption = dependencies.ReadOption, Notify = notify, EnsureFolder = ensureFolder,
			Paths = dependencies.Support.Paths, WriteJson = writeJson, ReadJson = readJson,
			Config = dependencies.Support.Config, Ui = uiProxy, DeleteFile = dependencies.DeleteFile,
			Clipboard = dependencies.Clipboard, Print = dependencies.Print,
		}),
	} do
		for name, callback in pairs(group) do callbacks[name] = callback end
	end
	local result = Interface.create({
		Library = dependencies.Library,
		Callbacks = callbacks,
		OnWindow = function(value) window = value end,
		PlayerOptions = function() return Interface.playerOptions(dependencies.Players, dependencies.Player) end,
		ConfigOptions = dependencies.Support.Config.List,
		Throttle = dependencies.Throttle,
		DeferSettings = dependencies.DeferSettings,
		NewColor3 = dependencies.NewColor,
		NewVector2 = dependencies.NewVector2,
		NewUDim2 = dependencies.NewUDim2,
		MenuKey = dependencies.MenuKey,
	})
	ui = Interface.createState(result.Controls, dependencies.Keybind, dependencies.Options, dependencies.Library)
	local function finish()
		if not dependencies.DeferSettings then return end
		result.FinishSettings()
		ui.ConfigList = result.Controls._ConfigSelect
	end
	return { Window = result.Window, Tabs = result.Tabs, Controls = result.Controls, Ui = ui, Finish = finish, Notify = notify, ShowResult = showResult }
end

function Application.runRuntime(dependencies: any)
	local round, farm, combat = dependencies.Round, dependencies.Farm, dependencies.Combat
	local esp, movement, support = dependencies.Esp, dependencies.Movement, dependencies.Support
	local readOption, readNumber, ready = dependencies.ReadOption, dependencies.ReadNumber, dependencies.Ready
	local function localParts() return Characters.localParts(dependencies.Player) end
	local function gunAdded(gun: any) Round.gunAdded(round, readOption, dependencies.Notify, gun) end
	local function watchMap(map: any) Round.watchMap(round, dependencies.Protect, gunAdded, map) end
	local function refreshPlayers()
		Interface.refreshPlayers(function() return Interface.playerOptions(dependencies.Players, dependencies.Player) end, dependencies.Ui)
	end
	local cache = {}
	local activeInterface: any
	local function setContent(control: any, value: any) Interface.setContent(cache, control, value) end
	local function setValue(control: any, value: any) Interface.setValue(cache, control, value) end

	Lifecycle.startRuntime({
		Spawn = dependencies.Spawn,
		Protect = dependencies.Protect,
		IsRunning = dependencies.IsRunning,
		Log = dependencies.Log,
		Wait = dependencies.Wait,
		Farm = function()
			Farm.run({ IsRunning = dependencies.IsRunning, Farm = farm, Mover = dependencies.Mover, Wait = dependencies.Wait, Log = dependencies.Log })
		end,
		InstallHooks = dependencies.Hooks.Install,
		Combat = function()
			Combat.step({
				Combat = combat, Round = round, Player = dependencies.Player, Quest = dependencies.Quest,
				ReadOption = readOption, Ready = ready, ReadNumber = readNumber,
				CharacterParts = Characters.parts :: any, ObjectPosition = Inventory.position,
			})
		end,
		Esp = esp.Update,
		Fullbright = dependencies.VisualsStep,
		Movement = dependencies.MovementStep,
		Popups = function() Popups.step(readOption, support.Popups) end,
		Webhook = support.WebhookStep,
		PrepareSummary = function() dependencies.SummaryTimer.LastSummary = dependencies.Clock() end,
		Summary = function() Webhook.summaryStep(dependencies.SummaryTimer, readOption, dependencies.Clock, support.Summary) end,
		ConnectGameplay = function()
			Round.connectGameplay(dependencies.Gameplay, dependencies.State, dependencies.Protect, {
				RoleSelect = function(role)
					Round.roleSelected(round, dependencies.Stats, farm, function(seconds, callback)
						Lifecycle.delay(dependencies.Delay, dependencies.Protect, seconds, callback)
					end, function() return Round.roleDetails(round) end, readOption, dependencies.Notify, support.Webhook, Quest.formatName, role)
				end,
				CoinsStarted = function(data) Round.coinsStarted(round, farm, data) end,
				CoinCollected = function(id, amount, limit)
					Round.coinCollected(round, dependencies.Stats, farm, dependencies.Notify, support.Webhook, support.Fields, id, amount, limit)
				end,
				VictoryScreen = function(first, message, title)
					Round.victory(round, support.Webhook, support.Fields, Quest.formatName, first, message, title)
				end,
				PlayerDataChanged = function(data) Round.playerDataChanged(round, data) end,
			})
		end,
		PrepareInterface = function()
			activeInterface = dependencies.PrepareInterface()
			dependencies.Ui, dependencies.Window = activeInterface.Ui, activeInterface.Window
			
			
		end,
		FinishInterface = function() activeInterface.Finish() end,
		
		Interface = function()
			Interface.update({
				Farm = farm, FormatNumber = Helpers.formatNumber, Stats = dependencies.Stats, SetContent = setContent,
				Ui = dependencies.Ui, SetValue = setValue, Round = round, Player = dependencies.Player,
				FormatName = Quest.formatName, Minimum = math.min, ReadOption = readOption, Quest = dependencies.Quest,
			})
		end,
		Autosave = support.Config.Autosave,
		RestoreConfig = dependencies.RestoreConfig,
		State = dependencies.State,
		Players = dependencies.Players,
		RunService = dependencies.RunService,
		Input = dependencies.Input,
		Player = dependencies.Player,
		Workspace = dependencies.Workspace,
		GuiService = dependencies.GuiService,
		Library = dependencies.Library,
		RemoveEsp = esp.Remove,
		HasDrawing = esp.HasDrawing,
		Tracers = esp.Tracers,
		NoclipFrame = function() Movement.noclipFrame(readOption, movement) end,
		JumpRequest = function() Movement.jumpRequest(readOption, localParts, dependencies.Jumping) end,
		InputBegan = function(input, processed)
			Movement.clickTeleport({
				ReadOption = readOption, GetBind = dependencies.Keybind, Options = dependencies.Options, Input = dependencies.Input,
				Player = dependencies.Player, LocalParts = localParts, MouseButton = dependencies.MouseButton, KeyCodes = dependencies.KeyCodes,
				NewFrame = dependencies.NewFrame, Offset = dependencies.NewVector(0, 3.200000047683716, 0), Zero = dependencies.Zero,
			}, input, processed)
		end,
		CharacterAdded = function() Movement.characterAdded(movement) end,
		WatchMap = watchMap,
		ChildAdded = function(child) Round.childAdded(gunAdded, watchMap, child) end,
		ChildRemoved = function(child) Round.childRemoved(round, child) end,
		Disconnected = function()
			Lifecycle.disconnected({
				Service = dependencies.GuiService, Ready = ready, Webhook = support.Webhook, Fields = support.Fields,
				State = dependencies.State, ReadOption = readOption, Delay = dependencies.Delay, Teleport = dependencies.Teleport,
				Game = dependencies.Game, Player = dependencies.Player, QueueTeleport = dependencies.QueueTeleport,
			})
		end,
		Idled = function() Lifecycle.idled(readOption, dependencies.VirtualUser, dependencies.Zero2) end,
		PlayerAdded = function() Interface.playerAdded(dependencies.Delay, refreshPlayers) end,
		PlayerRemoving = function(player) Interface.playerRemoving(support.Spectate, dependencies.Delay, refreshPlayers, player) end,
		Unload = dependencies.Unload,
	})
end

function Application.start(host: any, uiSource: string?, loadLibrary: ((any) -> any)?): any
	local environment, diagnostics = Application.createEnvironment(host, uiSource)
	local gameObject = environment.game
	local function service(name: string) return environment.cloneref(gameObject:GetService(name)) end
	Lifecycle.resetPrevious(environment)
	local coreGui = service("CoreGui")
	Application.cleanCoreGui(coreGui)
	Application.waitForGame(gameObject)
	local players = service("Players")
	local player = players.LocalPlayer
	local workspace = environment.workspace
	local runService = service("RunService")
	local storage = service("ReplicatedStorage")
	local input = service("UserInputService")
	local teleport = service("TeleportService")
	local guiService = service("GuiService")
	local lighting = service("Lighting")
	local virtualUser = service("VirtualUser")
	local http = service("HttpService")
	local state, session = Lifecycle.initializeSession(environment, http)
	local clock, wait = environment.os.clock, environment.task.wait
	local function isRunning() return Lifecycle.isRunning(state, environment.getgenv, session) end
	local function log(message: any) Lifecycle.log(state, environment.os.date, message) end
	local function protect(callback: (...any) -> ...any, ...: any) return Lifecycle.protect(log, callback, ...) end
	local timers: any = {}
	local function ready(key: string, interval: number) return Lifecycle.ready(timers, clock, key, interval) end
	local throttleState = { LastYield = clock() }
	local function throttle() Config.throttle(throttleState, clock, wait) end
	local library = if loadLibrary then loadLibrary(environment) else Interface.loadLibrary()
	local options = library.Options
	state.Options = options
	throttle()
	local gameplay = Application.gameplayRemotes(storage)
	throttle()
	local function readOption(name: string, default: any) return Options.read(options, name, default) end
	local function readNumber(name: string, default: number) return Options.readNumber(readOption, name, default) end
	local function keybind(option: any) return Config.keybind(option, environment.typeof, environment.Enum.KeyCode) end
	local function ping() return Network.ping(player) end
	local vector, frame = environment.Vector3.new, environment.CFrame.new
	local zero = vector(0, 0, 0)
	local groundParameters, exposureParameters = Application.createRaycastParameters(environment.RaycastParams.new, function()
		return environment.Enum.RaycastFilterType.Exclude
	end)
	local stats = Lifecycle.createStats(environment.os.time)
	local gameState = Application.createGameState({
		Storage = storage, Require = environment.require, Players = players, Player = player,
		Workspace = workspace, Clock = clock, Wait = wait, ReadOption = readOption,
	})
	local automation = Application.createAutomation({
		Player = player, Players = players, Round = gameState.Round, Quest = gameState.Quest,
		Workspace = workspace, Heartbeat = runService.Heartbeat, GroundParameters = groundParameters,
		ExposureParameters = exposureParameters, Clock = clock, Wait = wait, NewVector = vector,
		NewFrame = frame, Zero = zero, TypeOf = environment.typeof, ReadOption = readOption,
		ReadNumber = readNumber, IsRunning = isRunning, Ping = ping, Touch = environment.firetouchinterest,
	})
	local controllers = Application.createControllers({
		Player = player, Players = players, Round = gameState.Round, Mover = automation.Mover,
		NewInstance = environment.Instance.new, RunService = runService, Workspace = workspace, Input = input,
		KeyCodes = environment.Enum.KeyCode, NewVector = vector, Zero = zero, ReadOption = readOption,
		ReadNumber = readNumber, IsRunning = isRunning, Clock = clock, Ping = ping, Wait = wait, Stats = stats,
		NewFrame = frame, LookAt = environment.CFrame.lookAt, GroundParameters = groundParameters, Log = log,
		Weapons = gameState.Weapons, HookCache = Hooks.cache(environment),
	})
	local visual = Application.createVisuals({
		Player = player, Players = players, Round = gameState.Round, Options = options, CoreGui = coreGui,
		Lighting = lighting, NewColor = environment.Color3.new, NewInstance = environment.Instance.new,
		NewUDim2 = environment.UDim2.new, NewVector = vector, NewVector2 = environment.Vector2.new,
		DepthMode = function() return environment.Enum.HighlightDepthMode.AlwaysOnTop end,
		Font = function() return environment.Enum.Font.GothamBold end,
		Drawing = environment.Drawing, TypeOf = environment.typeof, ReadOption = readOption, ReadNumber = readNumber,
		Workspace = workspace, RunService = runService, SetFpsCap = environment.setfpscap, Throttle = throttle,
		GetSettings = function() return environment.settings() end,
		LowestQuality = function() return environment.Enum.QualityLevel.Level01 end,
	})
	local support = Application.createSupport({
		Player = player, Players = players, Game = gameObject, Workspace = workspace,
		Stats = stats, Teleport = teleport, Http = http, DateTime = environment.DateTime, ReadOption = readOption,
		Request = environment.request, Clock = clock, Time = environment.os.time, Log = log, Random = environment.math.random,
		Options = options, TypeOf = environment.typeof, KeyCodes = environment.Enum.KeyCode,
		FromHex = environment.Color3.fromHex, Throttle = throttle, IsFolder = environment.isfolder,
		MakeFolder = environment.makefolder, WriteFile = environment.writefile, ListFiles = environment.listfiles,
		GetConnections = environment.getconnections, FireSignal = environment.firesignal,
	})
	local interface: any
	local function prepareInterface()
		throttle()
		interface = Application.createInterface({
			Library = library, Options = options, State = state, Player = player, Players = players,
			ReadOption = readOption, Input = input, Movement = controllers.Movement, Round = gameState.Round,
			Combat = controllers.Combat, Mover = automation.Mover, Visuals = visual.Visuals,
			Settings = visual.Settings, Support = support, Locations = automation.Locations,
			Spawn = environment.task.spawn, Protect = protect, Http = http, IsFolder = environment.isfolder,
			MakeFolder = environment.makefolder, IsFile = environment.isfile, ReadFile = environment.readfile,
			WriteFile = environment.writefile, DeleteFile = environment.delfile, Clipboard = environment.setclipboard,
			NewFrame = frame, NewVector = vector, Zero = zero, NewColor = environment.Color3.new,
			NewVector2 = environment.Vector2.new, NewUDim2 = environment.UDim2.new,
			MenuKey = environment.Enum.KeyCode.RightShift, Keybind = keybind, Print = environment.print,
			Throttle = throttle, DeferSettings = true,
		})
		return interface
	end
	local function unload()
		Lifecycle.unload({
			State = state, Mover = automation.Mover, Farm = automation.Farm, Movement = controllers.Movement,
			Hooks = controllers.Hooks, Esp = visual.Esp, Visuals = visual.Visuals, Settings = visual.Settings,
			Spectate = support.Spectate, LocalParts = function() return Characters.localParts(player) end,
			Round = gameState.Round, Library = library,
		})
	end
	local function restoreConfig()
		Config.restore(support.Config, support.Paths, function(path)
			return Config.readJson(http, environment.isfile, environment.readfile, path)
		end, options, environment)
	end
	Application.runRuntime({
		State = state, Round = gameState.Round, Farm = automation.Farm, Combat = controllers.Combat, Gameplay = gameplay,
		Mover = automation.Mover, Movement = controllers.Movement, Support = support, Esp = visual.Esp,
		Player = player, Players = players, Workspace = workspace, RunService = runService, Input = input,
		GuiService = guiService, Library = library,
		ReadOption = readOption, ReadNumber = readNumber, Ready = ready, Options = options, Keybind = keybind,
		Jumping = function() return environment.Enum.HumanoidStateType.Jumping end,
		MouseButton = function() return environment.Enum.UserInputType.MouseButton1 end,
		KeyCodes = function() return environment.Enum.KeyCode end, NewFrame = frame, NewVector = vector,
		Zero = zero, Zero2 = environment.Vector2.new(0, 0), VirtualUser = virtualUser, Game = gameObject, Teleport = teleport, Stats = stats,
		SummaryTimer = {}, Hooks = controllers.Hooks, VisualsStep = visual.VisualsStep,
		MovementStep = controllers.MovementStep, IsRunning = isRunning, Clock = clock, Log = log, Wait = wait,
		Spawn = environment.task.spawn, Protect = protect, Delay = environment.task.delay,
		Notify = function(message) Interface.notify(library, message) end, PrepareInterface = prepareInterface,
		QueueTeleport = environment.queue_on_teleport, Unload = unload, RestoreConfig = restoreConfig,
	})
    Lifecycle.installTeleport(state,player,teleport,environment.queue_on_teleport,gameObject.GameId,support.Config.Autosave)
    for _,option in pairs(options)do if option.OnChanged then option:OnChanged(support.Config.Autosave)end end
	Lifecycle.finishSession(state, {
		Stats = stats, Combat = controllers.Combat, Spectate = support.Spectate, Opti = visual.Settings,
		ESP = visual.Esp, Round = gameState.Round, Server = support.Server,
		Move = controllers.Movement, SilentAim = controllers.Hooks, Mover = automation.Mover,
		Config = support.Config, Farm = automation.Farm, Webhook = support.Webhook,
		Popups = support.Popups, World = visual.Visuals,
	}, environment.os.date)
	interface.Window:SelectTab(1)
	
	getgenv().AxisMM2App={State=state,Interface=interface,Visual=visual,Controllers=controllers,GameState=gameState,Support=support,Options=options}
	return diagnostics
end


local exports = {
	Farm = Farm,
	Appearance = Appearance,
	Movement = Movement,
	Options = Options,
	Lifecycle = Lifecycle,
	Characters = Characters,
	Network = Network,
	Round = Round,
	Inventory = Inventory,
	Quest = Quest,
	
	Popups = Popups,
	Spectate = Spectate,
	Server = Server,
	Webhook = Webhook,
	Esp = Esp,
	Hooks = Hooks,
	Interface = Interface,
	Combat = Combat,
	Config = Config,
	Application = Application,
	Settings = Settings,
}

local host = getfenv()
if host.game then
    local ok,result=pcall(Application.start,host)
    if not ok then getgenv().AxisMM2StartupError=tostring(result)return false end
    getgenv().AxisMM2StartupError=nil
    return result
end
return exports
