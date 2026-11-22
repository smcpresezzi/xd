local UI_LIBRARY_URL = "https://raw.githubusercontent.com/lofaif1234/axisui/main/source/library.lua"



local function createSessionFiles()
	local files = {}
	local folders = { [""] = true }

	local function normalize(path)
		assert(type(path) == "string", "File path must be a string")

		local segments = {}

		for segment in path:gsub("\\", "/"):gmatch("[^/]+") do
			if segment == ".." then
				assert(#segments > 0, "File path escapes the session root")
				table.remove(segments)
				continue
			end

			if segment ~= "." then
				segments[#segments + 1] = segment
			end
		end

		return table.concat(segments, "/")
	end

	local function parent(path)
		return path:match("^(.*)/[^/]+$") or ""
	end

	local function makeFolder(path)
		path = normalize(path)

		local prefix = ""

		for segment in path:gmatch("[^/]+") do
			prefix = if prefix == "" then segment else prefix .. "/" .. segment
			folders[prefix] = true
		end
	end

	local function writeFile(path, contents)
		assert(type(contents) == "string", "File contents must be a string")

		path = normalize(path)
		assert(path ~= "", "File path is empty")

		makeFolder(parent(path))
		files[path] = contents
	end

	local function readFile(path)
		local contents = files[normalize(path)]
		assert(contents ~= nil, "File does not exist in this session")

		return contents
	end

	local function listFiles(path)
		path = normalize(path)

		local result = {}

		for name in files do
			if parent(name) == path then
				result[#result + 1] = name
			end
		end

		for name in folders do
			if name ~= "" and parent(name) == path then
				result[#result + 1] = name
			end
		end

		table.sort(result)
		return result
	end

	local function deleteFolder(path)
		path = normalize(path)
		assert(path ~= "", "Cannot delete the session root")

		local prefix = path .. "/"

		for name in files do
			if name:sub(1, #prefix) == prefix then
				files[name] = nil
			end
		end

		for name in folders do
			if name == path or name:sub(1, #prefix) == prefix then
				folders[name] = nil
			end
		end
	end

	local function unavailableAsset()
		return ""
	end

	return {
		readfile = readFile,
		writefile = writeFile,
		appendfile = function(path, contents)
			local current = files[normalize(path)] or ""
			writeFile(path, current .. contents)
		end,
		isfile = function(path)
			return files[normalize(path)] ~= nil
		end,
		isfolder = function(path)
			return folders[normalize(path)] == true
		end,
		makefolder = makeFolder,
		listfiles = listFiles,
		delfile = function(path)
			files[normalize(path)] = nil
		end,
		delfolder = deleteFolder,
		getcustomasset = unavailableAsset,
		getsynasset = unavailableAsset,
	}
end

local function createEnvironment(uiSource)
	local host = getfenv()
	local executor = type(getgenv) == "function" and getgenv() or host
	local hostGame = game
	local hostCompile = loadstring
	local hostHttp = hostGame:GetService("HttpService")

	local environment = {}
	local serviceCache = {}
	local denied = {}

	local function lookup(name)
		local value = host[name]

		if value ~= nil then
			return value
		end

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
		UserSettings settings version
	]], "%S+") do
		environment[name] = lookup(name)
	end

	for name, callback in createSessionFiles() do
		environment[name] = lookup(name) or callback
	end

	local hostDebug = lookup("debug")

	if hostDebug then
		environment.debug = { info = hostDebug.info, traceback = hostDebug.traceback }
	end

	environment._G = environment
	environment.shared = {}
	environment.getgenv = function()
		return environment
	end
	environment.getfenv = function()
		return environment
	end
	environment.getrenv = function()
		return environment
	end
	environment.setfenv = function(callback)
		return setfenv(callback, environment)
	end

	local function unavailable(route)
		local path = tostring(route):match("^[^?]+") or tostring(route)

		if not denied[path] then
			denied[path] = true
		end

		return { Success = false, StatusCode = 503, StatusMessage = "Unavailable offline", Body = "", Headers = {} }
	end

	local function localRequest(options)
		assert(type(options) == "table" and type(options.Url) == "string", "Request requires a URL")

		if options.Url == UI_LIBRARY_URL and (options.Method == nil or options.Method == "GET") then
			if uiSource == nil then
				uiSource = hostGame:HttpGet(UI_LIBRARY_URL)
			end

			return { Success = true, StatusCode = 200, StatusMessage = "UI library", Body = uiSource, Headers = {} }
		end

        local request=lookup("request") or lookup("http_request")
        if not request and type(executor.syn)=="table" then request=executor.syn.request end
        local discord=options.Url:match("^https://discord%.com/api/webhooks/%d+/[%w_%-]+")
        if discord then
            if type(request)~="function" then return {Success=false,StatusCode=0,StatusMessage="Executor request unavailable",Body=""}end
            return request(options)
        end
        if type(request)=="function" and options.Method=="GET" and options.Url:match("^https://thumbnails%.roblox%.com/")then return request(options)end
        return unavailable(options.Url)
    end

	local function localGet(_, url)
		local response = localRequest({ Url = url, Method = "GET" })

		if not response.Success then
			error("Resource is not embedded: " .. tostring(url), 0)
		end

		return response.Body
	end

	local function disabledSocket()
		error("WebSocket is disabled in the local build", 0)
	end

	local function disabledQueue()
	end

	environment.request = localRequest
	environment.http_request = localRequest
	environment.http = { request = localRequest }
	environment.WebSocket = { connect = disabledSocket }
	environment.websocket = { connect = disabledSocket }
	environment.queue_on_teleport = disabledQueue
	environment.queueonteleport = disabledQueue
	environment.clearteleportqueue = function() end
	environment.clear_teleport_queue = environment.clearteleportqueue
	environment.syn = {
		request = localRequest,
		protect_gui = environment.protectgui,
		getcustomasset = environment.getcustomasset,
		queue_on_teleport = disabledQueue,
		clear_teleport_queue = environment.clearteleportqueue,
		websocket = { connect = disabledSocket },
	}

	local httpProxy = setmetatable({}, {
		__index = function(_, name)
			if name == "GetAsync" then
				return localGet
			end

			if name == "RequestAsync" then
				return function(_, options)
					return localRequest(options)
				end
			end

			if name == "PostAsync" then
				return function(_, url)
					unavailable(url)
					error("POST is unavailable offline", 0)
				end
			end

			if name == "JSONEncode" or name == "JSONDecode" or name == "GenerateGUID" or name == "UrlEncode" then
				return function(_, ...)
					return hostHttp[name](hostHttp, ...)
				end
			end

			error("HttpService member is unavailable offline: " .. tostring(name), 0)
		end,
	})

	local function service(_, name)
		if name == "HttpService" then
			return httpProxy
		end

		if name == "HttpRbxApiService" then
			error("HTTP API is unavailable offline", 0)
		end

		if not serviceCache[name] then
			serviceCache[name] = hostGame:GetService(name)
		end

		return serviceCache[name]
	end

	environment.game = setmetatable({}, {
		__index = function(_, name)
			if name == "GetService" or name == "FindService" or name == "service" then
				return service
			end

			if name == "HttpGet" or name == "HttpGetAsync" then
				return localGet
			end

			if name == "HttpService" then
				return httpProxy
			end

			if name == "HttpPost" or name == "HttpPostAsync" then
				return function(_, url)
					unavailable(url)
					error("POST is unavailable offline", 0)
				end
			end

			local value = hostGame[name]

			if type(value) == "function" then
				return function(_, ...)
					return value(hostGame, ...)
				end
			end

			return value
		end,
	})

	environment.workspace = hostGame:GetService("Workspace")

	local hostClone = lookup("cloneref")

	environment.cloneref = function(value)
		if value == environment.game or value == httpProxy then
			return value
		end

		if hostClone then
			return hostClone(value)
		end

		return value
	end

	environment.require = function(module)
		assert(typeof(module) == "Instance" and module:IsA("ModuleScript"), "Numeric and external require are disabled")
		return host.require(module)
	end

	environment.loadstring = function(source, name)
		assert(type(source) == "string", "Local compiler requires source text")

		local chunk, failure = hostCompile(source, name)

		if not chunk then
			return nil, failure
		end

		return setfenv(chunk, environment)
	end
	environment.load = environment.loadstring

	return environment, { denied = denied, executorGlobals = environment }
end


local function collectSelection(value)
	local selected = {}

	if type(value) ~= "table" then
		return selected
	end

	for key, isSelected in pairs(value) do
		if type(key) == "number" then
			selected[tostring(isSelected)] = true
			continue
		end

		if isSelected then
			selected[tostring(key)] = true
		end
	end

	return selected
end

local function collectConfig(options)
	local result = {}

	for flag, option in pairs(options) do
		if option.Type ~= "Toggle" and option.Type ~= "Slider" and option.Type ~= "Dropdown"
			and option.Type ~= "Input" and option.Type ~= "Keybind" then
			continue
		end

		if tostring(flag):find("^_") then
			continue
		end

		local value = option.Value

		if option.Type == "Keybind" then
			if option.GetBind then
				value = option:GetBind() or value
			end

			if typeof(value) == "EnumItem" then
				value = value.Name
			end

			result[flag] = value
			continue
		end

		if option.Multi then
			value = collectSelection(value)
		end

		result[flag] = value
	end

	result._version = 2
	return result
end

local function setOptionValue(option, value)
	if option.Value ~= value then
		pcall(option.SetValue, option, value)
	end
end

local function selectionsEqual(first, second)
	for key in pairs(first) do
		if not second[key] then
			return false
		end
	end

	for key in pairs(second) do
		if not first[key] then
			return false
		end
	end

	return true
end

local function applyDropdown(option, value)
	local values = option.Values or {}

	if option.Multi then
		local selected = {}

		for choice in pairs(collectSelection(value)) do
			if table.find(values, choice) then
				selected[choice] = true
			end
		end

		local current = collectSelection(option.Value)

		if not selectionsEqual(selected, current) then
			pcall(option.SetValue, option, selected)
		end

		return true
	end

	if type(value) ~= "string" or not table.find(values, value) then
		return false
	end

	setOptionValue(option, value)
	return true
end

local function applyOption(option, value)
	if option.Type == "Toggle" then
		if type(value) ~= "boolean" then
			return false
		end

		setOptionValue(option, value)
		return true
	end

	if option.Type == "Slider" then
		local number = tonumber(value)

		if number == nil then
			return false
		end

		if option.Min then
			number = math.max(option.Min, number)
		end

		if option.Max then
			number = math.min(option.Max, number)
		end

		setOptionValue(option, number)
		return true
	end

	if option.Type == "Input" then
		if type(value) ~= "string" and type(value) ~= "number" then
			return false
		end

		setOptionValue(option, tostring(value))
		return true
	end

	if option.Type == "Keybind" then
		if type(value) ~= "string" then
			return false
		end

		if value ~= "MouseLeft" and value ~= "MouseRight" then
			local ok = pcall(function()
				return Enum.KeyCode[value]
			end)

			if not ok then
				return false
			end
		end

		local current

		if option.GetBind then
			current = option:GetBind()
		end

		if typeof(current) == "EnumItem" and current.Name == value then
			return true
		end

		pcall(option.SetValue, option, value, option.Mode)
		return true
	end

	if option.Type == "Dropdown" then
		return applyDropdown(option, value)
	end

	return false
end

local function applyConfig(options, config)
	if type(config) ~= "table" then
		return 0, 0
	end

	local version = tonumber(config._version) or 0
	local isLegacy = version < 2
	local applied = 0
	local failed = 0

	for flag, value in pairs(config) do
		local option = options[flag]

		if flag == "_version" or tostring(flag):find("^_") then
			continue
		end

		if not option or (isLegacy and (flag == "Theme" or flag == "MenuKeybind")) then
			failed += 1
			continue
		end

		if applyOption(option, value) then
			applied += 1
			continue
		end

		failed += 1
	end

	return applied, failed
end

local function sanitizeConfigName(name)
	local value = tostring(name or "")
	value = value:gsub("[^%w%s%-_]", "")
	value = value:gsub("^%s+", "")
	value = value:gsub("%s+$", "")

	if value == "" or value:lower()=="private" or value:lower()=="autosave" then
		return nil
	end

	return value:sub(1, 32)
end

local CONFIG_DIRECTORY = "Axis/Config/" .. tostring(game and game.GameId or "adopt-me")

local function listConfigs(environment)
	local names = {}

	if environment.listfiles and environment.isfolder and environment.isfolder(CONFIG_DIRECTORY) then
		for _, path in ipairs(environment.listfiles(CONFIG_DIRECTORY)) do
			local name = tostring(path):match("([^/\\]+)%.json$")

			if name and name~="private" then
				table.insert(names, name)
			end
		end
	end

	table.sort(names)
	return names
end

local function createConfigFiles(environment, httpService)
	local function ensureFolder(path)
		if not environment.isfolder or not environment.makefolder then
			return
		end

		if not environment.isfolder(path) then
			pcall(environment.makefolder, path)
		end
	end

	local function save(path, data)
		if not environment.writefile then
			return false
		end

		ensureFolder("Axis")
		ensureFolder("Axis/Config")
        ensureFolder(CONFIG_DIRECTORY)

		local ok = pcall(function()
			environment.writefile(path, httpService:JSONEncode(data))
		end)

		return ok
	end

	local function load(path)
		if not environment.isfile or not environment.readfile or not environment.isfile(path) then
			return nil
		end

		local ok, result = pcall(function()
			return httpService:JSONDecode(environment.readfile(path))
		end)

		if ok and type(result) == "table" then
			return result
		end

		return nil
	end

	return { ensureFolder = ensureFolder, save = save, load = load }
end

local PRIVATE_CONFIG_FLAGS = {
	_WebhookURL = true,
	_WebhookPing = true,
}

local function collectPrivateConfig(options)
	local result = {}

	for flag in pairs(PRIVATE_CONFIG_FLAGS) do
		local option = options[flag]

		if option then
			result[flag] = option.Value
		end
	end

	return result
end

local function autosave(manager, dependencies)
	if manager.Loading or not dependencies.readOption("Autosave", true) then
		return
	end

	local ok, json = pcall(dependencies.httpService.JSONEncode, dependencies.httpService, manager.Collect())

	if ok and json ~= manager.Last then
		manager.Last = json
		dependencies.saveFile(CONFIG_DIRECTORY .. "/autosave.json", manager.Collect())
	end

	dependencies.saveFile(CONFIG_DIRECTORY .. "/private.json", manager.CollectPrivate())
end


local function readOption(options, flag, default)
	local option = options[flag]

	if option == nil or option.Value == nil then
		return default
	end

	return option.Value
end

local function createConfigManager(dependencies)
	local options = dependencies.options
	local environment = dependencies.environment
	local httpService = dependencies.httpService
	local files = createConfigFiles(environment, httpService)
	local manager = { Loading = true, Last = "" }

	manager.Collect = function()
		return collectConfig(options)
	end
	manager.CollectPrivate = function()
		return collectPrivateConfig(options)
	end
	manager.Apply = function(config)
		return applyConfig(options, config)
	end
	manager.List = function()
		return listConfigs(environment)
	end
	manager.Autosave = function()
		autosave(manager, {
			readOption = function(flag, default)
				return readOption(options, flag, default)
			end,
			httpService = httpService,
			saveFile = files.save,
		})
	end

	return manager
end

local function createAxisAdapter(native)
    local adapter={Options={},Themes={Default=true},Native=native,Unloaded=false}
    local icons={["Auto Farm"]="7733942651",House="7733960981",Shop="7734056747",["Trade License"]="7734056411",Notifications="7734053595",Performance="7733799969",Settings="7734053495"}
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
        function item:SetValues(values)self.Values=values self.Native:Refresh(values)end
        function item:GetBind()return Enum.KeyCode.RightShift end
        adapter.Options[id]=item
        return item
    end
    local function section(raw)
        local result={Native=raw}
        function result:CreateToggle(id,data)
            data.Default=id=="Autosave" and data.Default~=false or false
            local item
            local control=raw:Toggle({Name=data.Title,Flag="AM_"..id,Default=data.Default,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Toggle",control)
            return item
        end
        function result:CreateSlider(id,data)
            local item
            local control=raw:Slider({Name=data.Title,Flag="AM_"..id,Min=data.Min,Max=data.Max,Default=data.Default,Decimals=10^-(data.Rounding or 0),Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Slider",control)return item
        end
        function result:CreateDropdown(id,data)
            local item
            local control=raw:Dropdown({Name=data.Title,Flag="AM_"..id,Items=data.Values,Default=data.Default,Multi=data.Multi,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Dropdown",control)return item
        end
        function result:CreateListbox(id,data)
            local item
            local control=raw:Listbox({Flag="AM_"..id,Items=data.Values or {},Multi=false,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Dropdown",control)return item
        end
        function result:CreateInput(id,data)
            raw:Label(data.Title)
            local item
            local control=raw:Textbox({Flag="AM_"..id,Default=data.Default,Placeholder=data.Placeholder or "",Numeric=data.Numeric,Finished=data.Finished,Callback=function(v)if item then item:Emit(v)end end})
            item=option(id,data,"Input",control)return item
        end
        function result:CreateKeybind(id,data)
            local control=raw:Toggle({Name=data.Title,Flag="AM_"..id.."Enabled",Default=true})
            local bind=control:GetBind({Flag="AM_"..id,Default=Enum.KeyCode.RightShift,Mode="Toggle"})
            local item=option(id,{Default="RightShift"},"Keybind",bind)
            return item
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
    function adapter:SetTheme()end
    function adapter:ToggleAcrylic()end
    function adapter:Notify(data)native:Notification({Title="Axis",Description=data.Content or data.Title,Duration=data.Duration or 4})end
    function adapter:Destroy()self.Unloaded=true native:Unload()end
    return adapter
end

local function createHubWindow(library, geometry, onWindow)
	local window = library:CreateWindow({
		Title = "Axis",
		SubTitle = "Adopt Me!",
		TabWidth = 160,
		MinimizeKey = geometry.Enum.KeyCode.RightShift,
		Size = geometry.UDim2.new(0, 1040, 0, 720),
		MinSize = geometry.Vector2.new(700, 480),
		Acrylic = true,
		Theme = "Cobalt",
		ToggleButton = true,
		StatusBar = true,
		Resize = true,
	})
	if onWindow then onWindow(window) end

	local tabs = {}
	window:Divider("Dashboard")
	window:Divider("Farming")
	tabs.farm = window:CreateTab({ Title = "Auto Farm", Icon = "heart" })
	window:Divider("House & Items")
	tabs.house = window:CreateTab({ Title = "House", Icon = "house" })
	tabs.shop = window:CreateTab({ Title = "Shop", Icon = "gift" })
	tabs.tradeLicense = window:CreateTab({ Title = "Trade License", Icon = "shield-check" })
	window:Divider("Utility & Settings")
	tabs.notifications = window:CreateTab({ Title = "Notifications", Icon = "send" })
	tabs.performance = window:CreateTab({ Title = "Performance", Icon = "gauge" })
	tabs.settings = window:CreateTab({ Title = "Settings", Icon = "settings" })

	return window, tabs
end

local FARM_QUEST_LABELS = {
	{ "hungry", "Hungry" },
	{ "thirsty", "Thirsty" },
	{ "sleepy", "Sleepy" },
	{ "dirty", "Dirty" },
	{ "toilet", "Potty" },
	{ "school", "School" },
	{ "salon", "Salon" },
	{ "pizza_party", "Pizza Party" },
	{ "cat_cafe", "Cat Cafe" },
	{ "sick", "Sick" },
	{ "bored", "Bored" },
	{ "camping", "Camping" },
	{ "beach_party", "Beach Party" },
	{ "diving_board", "Diving Board" },
	{ "leaf_pile", "Leaf Pile" },
	{ "rain_puddle", "Rain Puddle" },
	{ "snowman", "Snowman" },
	{ "pet_me", "Pet Me" },
	{ "play", "Play" },
	{ "walk", "Walk" },
	{ "ride", "Ride" },
	{ "mystery", "Mystery" },
}

local function createFarmInterface(tab, potionKinds, defaultPotionKinds)
	local farm = tab:Left("Pet Quests")
	local status = farm:CreateParagraph({ Title = "Status", Content = "..." })

	farm:CreateToggle("AutoFarm", {
		Title = "Auto Farm",
		Default = false,
		Description = "Completes the quests of your pets and of your player, fastest first",
	})
	farm:CreateDropdown("FarmPriority", {
		Title = "Priority",
		Searchable = true,
		Values = { "Balanced", "Pets First", "Player First" },
		Default = "Balanced",
		AllowNull = false,
		Description = "Whose quests to do first when both have some",
	})
	farm:CreateToggle("PlayerQuests", {
		Title = "Player Quests",
		Default = true,
		Description = "Also does your own needs when you play as a baby",
	})
	farm:CreateToggle("PlayAsBaby", {
		Title = "Play As Baby",
		Default = false,
		Description = "Switches you to the Babies team so you get player quests too",
	})
	farm:CreateToggle("BuyFood", {
		Title = "Buy Food When Needed",
		Default = true,
		Description = "Buys an apple or water (1 buck) when you have nothing to eat or drink",
	})
	farm:CreateToggle("StayHome", {
		Title = "Wait At Home",
		Default = true,
		Description = "Goes back home when there is nothing to do",
	})
	farm:CreateToggle("AutoPopups", {
		Title = "Accept Popups",
		Default = true,
		Description = "Cash Out paychecks, Nice on minigame rewards, Okay on license dialogs",
	})
	farm:CreateToggle("AutoDailies", { Title = "Claim Daily Tasks", Default = true })
	farm:CreateToggle("AutoClaimDrops", {
		Title = "Claim Pet Drops",
		Default = true,
		Description = "Picks up the rewards your pets drop on the ground",
	})

	local pets = tab:Left("Pets")
	pets:CreateToggle("AutoAgeUp", {
		Title = "Auto Age Up",
		Default = false,
		Description = "When the pet is Full Grown, equips the next pet that is not and keeps going",
	})
	pets:CreateDropdown("PetMode", {
		Title = "Pet",
		Searchable = true,
		Values = { "Keep Equipped", "Eggs First" },
		Default = "Keep Equipped",
		AllowNull = false,
		Description = "Eggs First equips an egg so it hatches, then the next one",
	})

	local potions = tab:Right("Age Up Potions")
	local potionStatus = potions:CreateParagraph({ Title = "Potions", Content = "..." })
	potions:CreateToggle("AutoAgePotions", {
		Title = "Auto Age Up Potions",
		Default = false,
		Description = "Feeds your age up potions to your pet until it is Full Grown",
	})
	potions:CreateDropdown("AgePotionKinds", {
		Title = "Potions To Use",
		Searchable = true,
		Values = potionKinds,
		Default = defaultPotionKinds,
		Multi = true,
		Description = "Tradable potions (Super, Sugar Skull) start off",
	})
	potions:CreateDropdown("AgePotionTarget", {
		Title = "Use On",
		Searchable = true,
		Values = { "Equipped Pet", "Any Pet" },
		Default = "Equipped Pet",
		AllowNull = false,
		Description = "Any Pet equips the pet closest to Full Grown when yours is done",
	})
	potions:CreateToggle("AgePotionNoWaste", {
		Title = "Don't Waste XP",
		Default = true,
		Description = "With Auto Farm on, quests finish the last bit instead of a potion that would overflow",
	})

	local quests = tab:Right("Quests To Do")

	for _, quest in ipairs(FARM_QUEST_LABELS) do
		quests:CreateToggle("Quest_" .. quest[1], { Title = quest[2], Default = true })
	end

	return { status = status, potionStatus = potionStatus }
end

local function createHouseInterface(tab, buildHouse)
	local furniture = tab:Left("Farm Furniture")
	local status = furniture:CreateParagraph({ Title = "Your house", Content = "..." })
	furniture:CreateButton({
		Title = "Build Farm House",
		Description = "Places the missing quest furniture: food bowl, water bowl, bed, bathtub and toilet (free ones first)",
		Callback = buildHouse,
	})
	furniture:CreateToggle("AutoBuildHouse", {
		Title = "Auto Build Missing Furniture",
		Default = false,
		Description = "Checks your house while farming and buys what is missing",
	})

	local help = tab:Right("How it works")
	help:CreateCallout({
		Title = "Quest furniture",
		Style = "Info",
		Content = "The farm uses a food bowl, a water bowl, a bed, a bathtub and a toilet in your house. Free ones are bought first, only while you are inside your own house.",
	})

	return { status = status }
end

local function createShopInterface(tab, eggChoices, giftChoices)
	local eggs = tab:Left("Auto Buy Egg")
	eggs:CreateDropdown("EggToBuy", { Title = "Egg", Values = eggChoices, Default = eggChoices[1], Searchable = true })
	eggs:CreateToggle("AutoBuyEgg", {
		Title = "Auto Buy Egg",
		Default = false,
		Description = "Buys the egg every time you can afford it. Waits for minigames to end first",
	})

	local gifts = tab:Right("Auto Buy Gift")
	gifts:CreateDropdown("GiftToBuy", { Title = "Gift", Values = giftChoices, Default = giftChoices[1], Searchable = true })
	gifts:CreateToggle("AutoBuyGift", {
		Title = "Auto Buy Gift",
		Default = false,
		Description = "Buys the gift every time you can afford it. Waits for minigames to end first",
	})
	gifts:CreateToggle("AutoOpenGift", {
		Title = "Auto Open Gift",
		Default = false,
		Description = "Opens every gift box in your inventory",
	})
end

local function hasTradeLicense(getInventory)
	for _, item in pairs(getInventory("toys")) do
		if item.id == "trade_license" then
			return true
		end
	end

	return false
end

local function updateHubDisplay(interface, widget, value)
	if not widget then
		return
	end

	local text = tostring(value)
	if interface.Shown[widget] == text then
		return
	end

	interface.Shown[widget] = text
	pcall(function()
		if widget.Type == "Stat" then
			widget:SetValue(text)
		elseif widget.SetContent then
			widget:SetContent(text)
		elseif widget.SetDesc then
			widget:SetDesc(text)
		end
	end)
end

local function updateHouseAndLicenseStatus(dependencies)
	local missing = if dependencies.isHome() then dependencies.missingFurniture() else nil
	local houseStatus = "Go home to check your furniture"
	if dependencies.isHome() then
		houseStatus = "Everything the farm needs is in your house"
		if #missing > 0 then
			local labels = {}
			for _, item in ipairs(missing) do
				table.insert(labels, item.label)
			end

			houseStatus = "Missing: " .. table.concat(labels, ", ")
		end
	end

	dependencies.update(dependencies.houseStatus, houseStatus)
	dependencies.update(dependencies.licenseStatus, if dependencies.trade.Has() then "Unlocked" else "Not unlocked yet")
end

local function takeTradeQuiz(trade, dependencies)
	if not dependencies.travel("TradeLicenseZone", "MainDoor") then
		error("Could not reach the Trade License office")
	end

	dependencies.wait(1)
	if not dependencies.getData("trade_license_quiz_manager") then
		dependencies.fireRemote("TradeAPI/BeginQuiz")
	end

	local started = dependencies.clock()
	while not dependencies.getData("trade_license_quiz_manager") and dependencies.clock() - started < 8 do
		dependencies.wait(0.25)
	end

	if not dependencies.getData("trade_license_quiz_manager") then
		error("The quiz did not start")
	end

	for _ = 1, 6 do
		local quiz = dependencies.getData("trade_license_quiz_manager")
		if not quiz or trade.Has() then
			break
		end

		local question = quiz.quiz and quiz.quiz[quiz.question_index]
		if not question or not question.answer then
			break
		end

		dependencies.fireRemote("TradeAPI/AnswerQuizQuestion", question.answer)
		dependencies.wait(2.5)
	end

	local location = dependencies.getLocation()
	local interior = location and location.interior
	local license = interior and interior:FindFirstChild("License")
	local part = license and (license:FindFirstChild("License") or license:FindFirstChildWhichIsA("BasePart", true))
	if part then
		dependencies.moveTo(part.Position)
		dependencies.wait(2)
	end
end

local function runTradeLicense(trade, dependencies)
	if trade.Running then
		return
	end

	if trade.Has() then
		dependencies.notify("You already have a Trade License")
		return
	end

	trade.Running = true
	dependencies.state.Busy = "Trade License"
	local ok, raised = pcall(takeTradeQuiz, trade, dependencies)
	trade.Running = false
	dependencies.state.Busy = nil

	local unlocked = trade.Has()
	if unlocked then
		dependencies.notify("Trade License unlocked")
		local item = dependencies.getCatalogItem("toys", "trade_license")
		local embed = dependencies.webhook.Embed("Trade License unlocked", "You can now trade Ultra-Rare and Legendary items.", 5763719, nil, item and item.image)
		dependencies.webhook.Send("Trade License", embed)
		dependencies.goHome()
	else
		dependencies.notify("Trade License failed: " .. tostring(if ok then "license not granted" else raised))
	end

	dependencies.updateStatus(dependencies.status, if unlocked then "Unlocked" else "Not unlocked yet")
end

local function createTradeLicenseController(dependencies)
	local trade = { Running = false }
	trade.Has = function()
		return hasTradeLicense(dependencies.getInventory)
	end
	trade.Run = function()
		return runTradeLicense(trade, dependencies)
	end

	return trade
end

local function createTradeLicenseInterface(tab, getInventory, getLicense)
	local trade = tab:Left("Trade License")
	local status = trade:CreateParagraph({ Title = "Status", Content = if hasTradeLicense(getInventory) then "Unlocked" else "Not unlocked yet" })
	trade:CreateButton({
		Title = "Get Trade License",
		Description = "Takes the trading test (3 practice trades) and claims the license",
		Callback = getLicense,
	})

	local about = tab:Right("About")
	about:CreateCallout({
		Title = "Why a license",
		Style = "Info",
		Content = "The license lets you trade Ultra-Rare and Legendary items. The hub answers the quiz for you, then goes back home.",
	})

	return { status = status }
end

local function createNotificationsInterface(tab, sendTest)
	local webhook = tab:Left("Discord Webhook")
	webhook:CreateInput("_WebhookURL", {
		Title = "Webhook URL",
		Placeholder = "https://discord.com/api/webhooks/...",
		Default = "",
		Finished = true,
		Description = "Stays on this PC, never exported",
	})
	webhook:CreateInput("_WebhookPing", {
		Title = "Discord User ID To Ping",
		Placeholder = "Optional",
		Default = "",
		Numeric = true,
		Finished = true,
	})
	webhook:CreateToggle("WebhookEnabled", { Title = "Send Notifications", Default = false })
	webhook:CreateToggle("WebhookHideName", { Title = "Hide Username", Default = false })
	webhook:CreateButton({ Title = "Send Test Message", Callback = sendTest })

	local events = tab:Right("Events")
	events:CreateDropdown("WebhookEvents", {
		Title = "Events",
		Values = { "Quest Completed", "Egg Hatched", "Pet Aged Up", "Item Bought", "Trade License", "Farm Summary" },
		Default = { "Egg Hatched", "Pet Aged Up", "Trade License", "Farm Summary" },
		Multi = true,
		Searchable = true,
	})
	events:CreateSlider("SummaryMinutes", { Title = "Farm Summary Every (minutes)", Min = 5, Max = 120, Default = 30, Rounding = 0 })
end

local function createPerformanceInterface(tab, goHome)
	local general = tab:Left("General")
	general:CreateToggle("AntiAFK", { Title = "Anti AFK", Default = true })
	general:CreateButton({ Title = "Go Home", Callback = goHome })

	local performance = tab:Right("Performance")
	performance:CreateToggle("Disable3D", {
		Title = "Disable 3D Rendering",
		Default = false,
		Description = "Stops drawing the world, the game keeps running",
	})
	performance:CreateToggle("BlackScreen", {
		Title = "Black Screen",
		Default = false,
		Description = "Covers the game to save GPU while AFK",
	})
	performance:CreateSlider("FPSCap", { Title = "FPS Cap", Min = 0, Max = 240, Default = 0, Rounding = 0, Description = "0 = no limit" })
end

local function saveNamedConfig(dependencies)
	local name = sanitizeConfigName(dependencies.readOption("_ConfigName", ""))

	if not name then
		dependencies.notify("Enter a config name")
		return
	end

	dependencies.files.ensureFolder("Axis")
	dependencies.files.ensureFolder("Axis/Config")
	dependencies.files.ensureFolder(CONFIG_DIRECTORY)

	if not dependencies.files.save(CONFIG_DIRECTORY .. "/" .. name .. ".json", dependencies.config.Collect()) then
		dependencies.notify("Saving is not supported by your executor")
		return
	end

	dependencies.notify("Config saved: " .. name)

	local setValues = dependencies.configList.SetValues
	setValues(dependencies.configList, dependencies.config.List())
end

local function loadNamedConfig(dependencies)
	local name = dependencies.readOption("_ConfigSelect")

	if not name then
		dependencies.notify("Select a config")
		return
	end

	local config = dependencies.files.load(CONFIG_DIRECTORY .. "/" .. name .. ".json")

	if not config then
		dependencies.notify("Could not read " .. name)
		return
	end

	local applied, failed = dependencies.config.Apply(config)
	local skipped = if failed > 0 then ", " .. failed .. " skipped" else ""
	dependencies.notify(string.format("Loaded %s (%d settings%s)", name, applied, skipped))
end

local function deleteNamedConfig(dependencies)
	local name = dependencies.readOption("_ConfigSelect")

	if not name or not dependencies.deleteFile then
		dependencies.notify("Select a config")
		return
	end

	pcall(dependencies.deleteFile, CONFIG_DIRECTORY .. "/" .. name .. ".json")

	local setValues = dependencies.configList.SetValues
	setValues(dependencies.configList, dependencies.config.List())

	dependencies.notify("Deleted " .. name)
end

local function createSettingsInterface(tab, themes, configNames, callbacks)
    local configs=tab:Left("Configs")
    local list=configs:CreateListbox("_ConfigSelect",{Values=configNames})
    configs:CreateInput("_ConfigName",{Title="Name",Placeholder="Name",Default="",Finished=false})
    configs:CreateButton({Title="Create",Callback=callbacks.saveConfig})
    configs:CreateButton({Title="Delete",Callback=callbacks.deleteConfig})
    configs:CreateButton({Title="Load",Callback=callbacks.loadConfig})
    configs:CreateButton({Title="Save",Callback=callbacks.saveSelected})
    configs:CreateButton({Title="Refresh",Callback=callbacks.refreshConfigs})
    local settings=tab:Right("UI Settings")
    settings:CreateToggle("Watermark",{Title="Watermark",Default=false,Callback=callbacks.watermark})
    settings:CreateToggle("KeybindList",{Title="Keybind List",Default=false,Callback=callbacks.keybindList})
    local session=tab:Right("Session")
    session:CreateToggle("Autosave",{Title="Autosave",Default=true})
    session:CreateParagraph({Title="Menu key",Content="Right Shift"})
    session:CreateButton({Title="Unload script",Callback=callbacks.unload})
    return list
end

local function createHubShell(library, geometry, potionKinds, defaultPotionKinds, dependencies)
	local window, tabs = dependencies.window, dependencies.tabs
	if not window then
		window, tabs = createHubWindow(library, geometry)
	end
	local farm = createFarmInterface(tabs.farm, potionKinds, defaultPotionKinds)
	local house = createHouseInterface(tabs.house, function()
		dependencies.spawn(function()
			dependencies.state.BuildHouse(false)
		end)
	end)
	createShopInterface(tabs.shop, dependencies.eggChoices, dependencies.giftChoices)
	local callbacks = dependencies.callbacks
	local trade = createTradeLicenseInterface(tabs.tradeLicense, dependencies.getInventory, function()
		dependencies.spawn(dependencies.trade.Run)
	end)
	createNotificationsInterface(tabs.notifications, callbacks.sendTest)
	createPerformanceInterface(tabs.performance, function()
		dependencies.spawn(dependencies.goHome)
	end)
	if dependencies.bindPerformance then
		dependencies.bindPerformance()
	end
	local settingsCallbacks = table.clone(callbacks)
	local configList
	local function namedConfigDependencies()
		return {
			readOption = dependencies.readOption,
			notify = dependencies.notify,
			files = dependencies.configFiles,
			config = dependencies.config,
			configList = configList,
			deleteFile = dependencies.deleteFile,
		}
	end
	settingsCallbacks.saveConfig = settingsCallbacks.saveConfig or function()
		saveNamedConfig(namedConfigDependencies())
	end
	settingsCallbacks.loadConfig = settingsCallbacks.loadConfig or function()
		loadNamedConfig(namedConfigDependencies())
	end
	settingsCallbacks.deleteConfig = settingsCallbacks.deleteConfig or function()
		deleteNamedConfig(namedConfigDependencies())
	end
	settingsCallbacks.changeTheme = function(theme)
		library:SetTheme(theme)
	end
	settingsCallbacks.changeAcrylic = function(enabled)
		library:ToggleAcrylic(enabled)
	end
	settingsCallbacks.unload = function()
		dependencies.state.Unload()
	end
	settingsCallbacks.refreshConfigs=function()configList:SetValues(dependencies.config.List())end
    settingsCallbacks.saveSelected=function()
        local selected=dependencies.readOption("_ConfigSelect")
        if not selected then dependencies.notify("Select a config")return end
        library.Options._ConfigName:SetValue(selected)
        saveNamedConfig(namedConfigDependencies())
    end
    settingsCallbacks.watermark=function(value)library.Native:SetWatermarkVisible(value)end
    settingsCallbacks.keybindList=function(value)(library.Native.KeyList or library.Native:KeybindList("Keybinds")):SetVisibility(value)end
    configList = createSettingsInterface(tabs.settings, dependencies.themes, dependencies.configNames, settingsCallbacks)

	library:Finish()
	return { window = window, tabs = tabs, farm = farm, house = house, trade = trade, configList = configList }
end

local function findRemote(folder, name)
	if not folder then
		return nil
	end

	return folder:FindFirstChild(name)
end

local function invokeRemote(lookup, name, ...)
	local remote = lookup(name)

	if not remote then
		return false
	end

	return pcall(remote.InvokeServer, remote, ...)
end

local function fireRemote(lookup, name, ...)
	local remote = lookup(name)

	if not remote then
		return false
	end

	return pcall(remote.FireServer, remote, ...)
end

local function getCurrentLocation(modules)
	local ok, location = pcall(modules.Interiors.get_current_location)
	return if ok and location then location else nil
end

local function getLocationName(getLocation)
	local location = getLocation()
	return location and location.destination_id
end

local function isOwnHome(getLocation, player)
	local location = getLocation()
	return location ~= nil and location.destination_id == "housing" and location.house_owner == player
end

local function safeIdentityCall(getIdentity, setIdentity, callback, ...)
	local previous = 8

	if getIdentity then
		local ok, identity = pcall(getIdentity)

		if ok and type(identity) == "number" then
			previous = identity
		end
	end

	if setIdentity then
		pcall(setIdentity, 2)
	end

	local result = table.pack(pcall(callback, ...))

	if setIdentity then
		pcall(setIdentity, previous)
	end

	return table.unpack(result, 1, result.n)
end

local function travelToInterior(destination, door, options, dependencies)
	if dependencies.locationName() == destination and destination ~= "housing" then
		return true
	end

	if dependencies.modules.Interiors.entering then
		local started = dependencies.clock()

		while dependencies.modules.Interiors.entering and dependencies.clock() - started < 10 do
			dependencies.wait(0.25)
		end
	end

	local ok, reason = dependencies.safeCall(dependencies.modules.Interiors.enter, destination, door or "MainDoor", options or {})

	if not ok then
		dependencies.log("Teleport to " .. destination .. " failed: " .. tostring(reason))
		return false
	end

	local started = dependencies.clock()

	while dependencies.clock() - started < 12 do
		if dependencies.locationName() == destination and not dependencies.modules.Interiors.entering then
			return true
		end

		dependencies.wait(0.25)
	end

	return dependencies.locationName() == destination
end

local function goHome(isHome, travel, player)
	if isHome() then
		return true
	end

	travel("housing", "MainDoor", { house_owner = player })
	return isHome()
end

local function goMainMap(locationName, travel)
	if locationName() == "MainMap" then
		return true
	end

	return travel("MainMap", "Neighborhood/MainDoor")
end

local function getCharacterParts(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character, root, humanoid
end

local function moveToPosition(position, dependencies)
	local _, root = dependencies.getCharacterParts()

	if not root then
		return
	end

	root.CFrame = dependencies.createCFrame(position + dependencies.offset)
	root.AssemblyLinearVelocity = dependencies.zero
end

local function getPlayerState(modules, player)
	local ok, state = pcall(function()
		return modules.ClientData.get_data()[player.Name]
	end)

	return if ok and state then state else nil
end

local function getStateValue(getState, key)
	local state = getState()
	return state and state[key]
end

local function getCatalogItem(modules, category, id)
	if not modules.InventoryDB or not modules.InventoryDB[category] then
		return nil
	end

	return modules.InventoryDB[category][id]
end

local function getItemLabel(getItem, category, id)
	local item = getItem(category, id)
	return item and item.name or tostring(id)
end

local function getPetImage(getItem, id)
	local item = getItem("pets", id)
	return item and item.image
end

local function getPetAilments(getData, key)
	local manager = getData("ailments_manager")
	return manager and manager.ailments and manager.ailments[key] or {}
end

local function getSubjectAilments(dependencies, subject)
	if not subject.baby then
		return dependencies.petAilments(subject.key)
	end

	local manager = dependencies.getData("ailments_manager")
	return manager and manager.baby_ailments or {}
end

local function getPetWrappers(getData)
	local wrappers = {}

	for _, wrapper in pairs(getData("pet_char_wrappers") or {}) do
		if type(wrapper) == "table" and wrapper.pet_unique and wrapper.char and wrapper.char.Parent then
			table.insert(wrappers, wrapper)
		end
	end

	return wrappers
end

local QUEST_HANDLERS = {
	toilet = { "home", "home" },
	hungry = { "home", "home" },
	sleepy = { "home", "home" },
	thirsty = { "home", "home" },
	dirty = { "home", "home" },
	salon = { "interior:Salon", "interior" },
	school = { "interior:School", "interior" },
	sick = { "interior:Hospital", "interior" },
	cat_cafe = { "interior:CatCafe", "interior" },
	pizza_party = { "interior:PizzaShop", "interior" },
	bored = { "mainmap", "mainmap" },
	camping = { "mainmap", "mainmap" },
	beach_party = { "mainmap", "mainmap" },
	rain_puddle = { "mainmap", "weather" },
	snowman = { "mainmap", "weather" },
	leaf_pile = { "mainmap", "weather" },
	diving_board = { "mainmap", "weather" },
	play = { "home", "play" },
	pet_me = { "home", "pet_me" },
	walk = { "home", "walk" },
	ride = { "home", "ride" },
	mystery = { "home", "mystery" },
}

local function findFarmQuestHandler(handlers, kind)
	local definition = QUEST_HANDLERS[kind]

	if not definition then
		return nil
	end

	return definition[1], handlers[definition[2]]
end

local function collectFarmSubjects(dependencies)
	local subjects = {}

	for _, wrapper in ipairs(dependencies.wrappers()) do
		table.insert(subjects, {
			key = wrapper.pet_unique,
			pw = wrapper,
			char = wrapper.char,
			baby = false,
			label = dependencies.label("pets", wrapper.pet_id),
			image = dependencies.image(wrapper.pet_id),
		})
	end

	if dependencies.readOption("PlayerQuests", true) and dependencies.getData("team") == "Babies" and dependencies.player.Character then
		table.insert(subjects, {
			key = "__player",
			char = dependencies.player.Character,
			baby = true,
			label = "You",
		})
	end

	return subjects
end

local QUEST_DURATIONS = {
	camping = 30,
	hungry = 4,
	sick = 25,
	thirsty = 4,
	snowman = 25,
	bored = 30,
	salon = 35,
	play = 12,
	cat_cafe = 35,
	toilet = 4,
	beach_party = 30,
	ride = 35,
	walk = 35,
	dirty = 6,
	rain_puddle = 25,
	leaf_pile = 25,
	diving_board = 25,
	pet_me = 6,
	school = 35,
	sleepy = 8,
	mystery = 3,
	pizza_party = 35,
}

local function estimateFarmQuest(farm, kind)
	return farm.Learned[kind] or QUEST_DURATIONS[kind] or 30
end

local function learnFarmQuest(farm, kind, elapsed)
	if elapsed <= 0 or elapsed > 300 then
		return
	end

	local previous = farm.Learned[kind] or QUEST_DURATIONS[kind] or elapsed
	farm.Learned[kind] = previous * 0.7 + elapsed * 0.3
end

local BABY_IGNORED_QUESTS = {
	pet_me = true,
	play = true,
	walk = true,
	ride = true,
	mystery = true,
}

local function collectFarmQuests(dependencies)
	local farm = dependencies.farm
	local quests = {}

	for _, subject in ipairs(dependencies.subjects()) do
		for kind in pairs(dependencies.ailments(subject)) do
			local key = subject.key .. kind

			if not (subject.baby and BABY_IGNORED_QUESTS[kind]) and not dependencies.ignored[kind] then
				if (farm.SkipUntil[key] or 0) < dependencies.clock() then
					if dependencies.readOption("Quest_" .. kind, true) then
						local group, handler = dependencies.handler(kind)

						if handler then
							table.insert(quests, { s = subject, kind = kind, group = group, fn = handler })
						end
					end
				end
			end
		end
	end

	local location

	if dependencies.isHome() then
		location = "home"
	elseif dependencies.location() == "MainMap" then
		location = "mainmap"
	else
		location = "interior:" .. tostring(dependencies.location())
	end

	local groupCounts = {}

	for _, quest in ipairs(quests) do
		groupCounts[quest.group] = (groupCounts[quest.group] or 0) + 1
	end

	local priority = dependencies.readOption("FarmPriority", "Balanced")

	for _, quest in ipairs(quests) do
		local travel = if quest.group == "any" or quest.group == location then 0 else 6
		local cost = dependencies.estimate(quest.kind) + travel / groupCounts[quest.group]

		if farm.Resume == quest.s.key .. quest.kind then
			cost -= 2000
		end

		if priority == "Pets First" and quest.s.baby or priority == "Player First" and not quest.s.baby then
			cost += 1000
		end

		quest.cost = cost
	end

	table.sort(quests, function(first, second)
		if math.abs(first.cost - second.cost) > 0.01 then
			return first.cost < second.cost
		end

		if first.group ~= second.group then
			return first.group < second.group
		end

		return first.kind < second.kind
	end)

	return quests
end

local function waitForFarmQuest(subject, kind, timeout, stallTimeout, dependencies)
	local started = dependencies.clock()
	local lastChange = dependencies.clock()
	local lastProgress = -1

	while dependencies.isActive() and dependencies.readOption("AutoFarm", false) and not dependencies.state.Busy and dependencies.clock() - started < timeout do
		local ailment = dependencies.ailments(subject)[kind]

		if not ailment then
			return true
		end

		local progress = tonumber(ailment.progress) or 0
		local rate = tonumber(ailment.rate) or 0

		if rate > 0 or progress ~= lastProgress then
			lastChange = dependencies.clock()
			lastProgress = progress
		end

		if stallTimeout and dependencies.clock() - lastChange > stallTimeout then
			return false
		end

		if dependencies.isInMinigame() then
			return false
		end

		dependencies.wait(0.5)
	end

	return not dependencies.ailments(subject)[kind]
end

local function isAppVisible(modules, name)
	local ok, visible = pcall(modules.UI.is_visible, name)
	return if ok then visible else false
end

local function closePetFocus(dependencies)
	if not dependencies.isAppVisible("FocusPetApp") then
		return
	end

	dependencies.safeCall(function()
		dependencies.modules.UI.apps.FocusPetApp:release_focus()
	end)
	dependencies.wait(0.3)
end

local function releaseBabySeat(fireRemote, wait)
	fireRemote("AdoptAPI/ExitSeatStates")
	wait(0.3)
end

local function getFurnitureEntry(modules, id)
	local database = modules.FurnitureDB
	local entry = database and database[id]

	if not entry then
		return nil
	end

	local kind = entry.interactable_kind and database[entry.interactable_kind]

	if not kind then
		return entry
	end

	return setmetatable({
		type = entry.type or kind.type,
		subtype = entry.subtype or kind.subtype,
	}, { __index = kind })
end

local function listHouseFurniture(getData, getFurnitureEntry, workspace)
	local interior = getData("house_interior")
	local result = {}

	if not interior or not interior.furniture then
		return result
	end

	local models = {}
	local interiors = workspace:FindFirstChild("HouseInteriors")
	local furniture = if interiors then workspace.HouseInteriors:FindFirstChild("furniture") else nil

	if furniture then
		for _, container in ipairs(furniture:GetChildren()) do
			local unique = container.Name:match("/([^/]+)$")

			if unique then
				models[unique] = container:FindFirstChildWhichIsA("Model")
			end
		end
	end

	for unique, item in pairs(interior.furniture) do
		table.insert(result, {
			unique = unique,
			id = item.id,
			entry = getFurnitureEntry(item.id),
			model = models[unique],
			cframe = item.cframe,
		})
	end

	return result
end

local FARM_FURNITURE_PREDICATES = {
	hungry = function(entry) return entry.subtype == "Food" end,
	thirsty = function(entry) return entry.subtype == "Drink" end,
	sleepy = function(entry) return entry.type == "Sleep" end,
	dirty = function(entry) return entry.subtype == "Baths" or entry.subtype == "Showers" end,
	toilet = function(entry, id) return entry.subtype == "Toilets" or id:find("litter_box") ~= nil end,
}

local FARM_FURNITURE_REQUIREMENTS = {
	{ need = "hungry", label = "Food Bowl", kinds = { "ailments_refresh_2024_cheap_food_bowl", "pet_food_bowl" } },
	{ need = "thirsty", label = "Water Bowl", kinds = { "ailments_refresh_2024_cheap_water_bowl", "pet_water_bowl" } },
	{ need = "sleepy", label = "Bed", kinds = { "basicbed", "basiccrib" } },
	{ need = "dirty", label = "Bathtub", kinds = { "cheapbathtub", "modernshower" } },
	{ need = "toilet", label = "Toilet", kinds = { "toilet", "ailments_refresh_2024_litter_box" } },
}

local function findFarmFurniture(kind, baby, supplied, dependencies)
	local matches = dependencies.predicates[kind]
	local result = {}

	if not matches then
		return result
	end

	for _, item in ipairs(supplied or dependencies.list()) do
		if not item.entry or not item.model or not matches(item.entry, item.id) then
			continue
		end

		if baby and (item.id:find("pet_") or item.id:find("bowl") or item.id:find("litter_box")) then
			continue
		end

		table.insert(result, item)
	end

	table.sort(result, function(first, second)
		local firstPriority = if first.entry.subtype == "Baths" then 0 else 1
		local secondPriority = if second.entry.subtype == "Baths" then 0 else 1
		return firstPriority < secondPriority
	end)

	return result
end

local function findMissingFarmFurniture(requirements, dependencies)
	local furniture = dependencies.list()
	local missing = {}
	for _, requirement in ipairs(requirements) do
		if #dependencies.find(requirement.need, false, furniture) == 0 then
			table.insert(missing, requirement)
		end
	end

	return missing
end

local function findHousePosition(reserved, housePosition, dependencies)
	local furniture = dependencies.listFurniture()
	local params = dependencies.newRaycastParams()
	params.FilterType = dependencies.includeFilter
	local interiors = dependencies.workspace:FindFirstChild("HouseInteriors")
	local blueprint = interiors and dependencies.workspace.HouseInteriors:FindFirstChild("blueprint")
	params.FilterDescendantsInstances = if blueprint then { blueprint } else {}

	for _, item in ipairs(furniture) do
		local origin = item.cframe and item.cframe.Position
		if not origin or math.abs(origin.Y) >= 1 then
			continue
		end

		for _, offset in ipairs(dependencies.offsets) do
			local candidate = origin + offset
			local hit
			if blueprint then
				local rayOrigin = housePosition + candidate + dependencies.vector(0, 8, 0)
				hit = dependencies.workspace:Raycast(rayOrigin, dependencies.vector(0, -14, 0), params)
			end

			if not hit or math.abs(hit.Normal.Y) <= 0.9 then
				continue
			end

			local occupied = false
			for _, position in ipairs(reserved) do
				if (dependencies.horizontal(position) - dependencies.horizontal(candidate)).Magnitude < 5 then
					occupied = true
					break
				end
			end

			if occupied then
				continue
			end

			local y = hit.Position.Y - housePosition.Y
			if math.abs(y - origin.Y) <= 1 then
				y = origin.Y
			end

			return dependencies.cframe(candidate.X, y, candidate.Z)
		end
	end
end

local function buildFarmHouse(automatic, dependencies)
	if not dependencies.isHome() then
		if automatic then
			return
		end

		dependencies.goHome()
	end

	if not dependencies.isHome() then
		if not automatic then
			dependencies.notify("Could not reach your house")
		end
		return
	end

	local missing = dependencies.missingFurniture()
	if #missing == 0 then
		if not automatic then
			dependencies.notify("Your house already has everything the farm needs")
		end
		return
	end

	local house = dependencies.getData("house_interior")
	local position = house and house.house_pos
	if dependencies.typeOf(position) == "CFrame" then
		position = position.Position
	end

	if dependencies.typeOf(position) ~= "Vector3" then
		dependencies.notify("House position not found")
		return
	end

	local reserved = {}
	for _, furniture in ipairs(dependencies.listFurniture()) do
		if dependencies.typeOf(furniture.cframe) == "CFrame" then
			table.insert(reserved, furniture.cframe.Position)
		end
	end

	local bought = {}
	for _, requirement in ipairs(missing) do
		local purchased = false
		for _, kind in ipairs(requirement.kinds) do
			local item = dependencies.modules.FurnitureDB and dependencies.modules.FurnitureDB[kind]
			local cost = item and tonumber(item.cost)
			if not cost or cost > (tonumber(dependencies.getData("money")) or 0) then
				continue
			end

			local frame = dependencies.findPosition(reserved, position)
			if not frame then
				break
			end

			local ok, result = dependencies.remote("HousingAPI/BuyFurnitures", { { kind = kind, properties = { cframe = frame } } })
			if ok and type(result) == "table" and result.success then
				table.insert(reserved, frame.Position)
				table.insert(bought, requirement.label .. " (" .. (item.name or kind) .. ")")
				dependencies.wait(1)
				purchased = true
				break
			end
		end

		if not purchased and not automatic then
			dependencies.notify("Could not buy a " .. requirement.label .. " (not enough bucks or no space)")
		end
	end

	if #bought > 0 then
		local summary = table.concat(bought, ", ")
		dependencies.notify("Bought: " .. summary)
		dependencies.log("House built: " .. summary)
	end
end

local function useFarmFurniture(furniture, character, dependencies)
	if not furniture.model then
		return false
	end

	local blocks = furniture.model:FindFirstChild("UseBlocks")

	if not blocks then
		return false
	end

	local block = blocks:FindFirstChildWhichIsA("BasePart")

	if not block then
		return false
	end

	dependencies.spawn(dependencies.remote, "HousingAPI/ActivateFurniture", dependencies.player, furniture.unique, block.Name, { cframe = block.CFrame }, character)
	return true
end

local MAINMAP_QUEST_TARGETS = {
	bored = { "Park", "BoredAilmentTarget" },
	camping = { "Campsite", "CampsiteOrigin" },
	beach_party = { "Beach", "BeachPartyAilmentTarget" },
}

local function shouldStopFarmWalker(dependencies)
	return not dependencies.isActive()
		or not dependencies.readOption("AutoFarm", false)
		or dependencies.state.Busy ~= nil
		or dependencies.modules.Interiors.entering
		or dependencies.isInMinigame()
end

local function stopFarmWalker(walker, dependencies)
	local active = walker.active

	if not active then
		return
	end

	walker.active = nil

	if active.conn then
		pcall(function() active.conn:Disconnect() end)
	end

	if active.platform then
		pcall(function() active.platform:Destroy() end)
	end

	local _, root, humanoid = dependencies.getCharacterParts()

	if humanoid then
		pcall(humanoid.Move, humanoid, dependencies.zero, false)
	end

	if root and root.Parent then
		root.AssemblyLinearVelocity = dependencies.zero

		if active.sky and dependencies.locationName() == active.location and not dependencies.modules.Interiors.entering then
			root.CFrame = active.home
		end
	end
end

local function stepFarmWalker(walker, active, root, humanoid, center, radius, speed, elapsed, dependencies)
	if walker.active ~= active then
		return
	end

	if dependencies.clock() >= active.checkAt then
		active.checkAt = dependencies.clock() + 0.5

		if not root.Parent or humanoid.Health <= 0 or dependencies.locationName() ~= active.location or walker.ShouldStop() then
			dependencies.spawn(walker.Stop)
			return
		end
	end

	active.angle += elapsed * speed / radius
	local angle = active.angle
	local position = center + dependencies.vector(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local direction = dependencies.vector(-math.sin(angle), 0, math.cos(angle))
	root.CFrame = dependencies.lookAt(position, position + direction)
	root.AssemblyLinearVelocity = direction * speed
	humanoid:Move(direction, false)
end

local function startFarmWalker(walker, sky, radius, speed, dependencies)
	walker.Stop()
	local _, root, humanoid = dependencies.getCharacterParts()

	if not root or not humanoid then
		return false
	end

	local active = {
		sky = sky,
		home = root.CFrame,
		location = dependencies.locationName(),
		angle = 0,
		checkAt = 0,
	}
	local height = humanoid.HipHeight + root.Size.Y / 2
	local center = root.Position + dependencies.vector(0, if sky then 300 else 0, 0)

	if sky then
		local platform = dependencies.newPart("Part")
		platform.Name = "AxisAdoptMePath"
		platform.Anchored = true
		platform.CanCollide = true
		platform.CanQuery = false
		platform.CanTouch = false
		platform.Size = dependencies.vector(radius * 2 + 60, 2, radius * 2 + 60)
		platform.CFrame = dependencies.cframe(center - dependencies.vector(0, height + 1, 0))
		platform.Material = dependencies.platformMaterial
		platform.Color = dependencies.platformColor
		platform.Transparency = 0.5
		platform.Parent = dependencies.workspace
		active.platform = platform
	end

	walker.active = active
	active.conn = dependencies.heartbeat:Connect(function(elapsed)
		stepFarmWalker(walker, active, root, humanoid, center, radius, speed, elapsed, dependencies)
	end)
	return true
end

local function createFarmWalker(dependencies)
	local walker = {}
	walker.ShouldStop = function()
		return shouldStopFarmWalker(dependencies)
	end
	walker.Stop = function()
		stopFarmWalker(walker, dependencies)
	end
	walker.Start = function(sky, radius, speed)
		return startFarmWalker(walker, sky, radius, speed, dependencies)
	end
	return walker
end

local function walkUntil(subject, kind, timeout, air, radius, stallTimeout, dependencies)
	local walker = dependencies.walker

	if not walker.Start(air, radius, stallTimeout) then
		return false
	end

	local started = dependencies.clock()
	local ok = pcall(function()
		while walker.active and dependencies.clock() - started < timeout do
			if not dependencies.ailments(subject)[kind] then
				break
			end

			dependencies.wait(0.5)
		end
	end)
	walker.Stop()

	if not ok then
		return false
	end

	return not dependencies.ailments(subject)[kind]
end

local function walkWithPet(subject, kind, timeout, dependencies)
	local _, root, humanoid = dependencies.getCharacterParts()

	if not root or not humanoid or subject.baby then
		return false
	end

	dependencies.closePetFocus()
	dependencies.remote("AdoptAPI/HoldBaby", subject.char)
	dependencies.wait(0.4)
	local completed = dependencies.walker.Until(subject, kind, timeout, false, 2.5, 10)
	dependencies.fireRemote("AdoptAPI/EjectBaby", subject.char)
	return completed
end

local function performWalkQuest(subject, kind, dependencies)
	dependencies.goHome()
	dependencies.releaseBaby()
	return dependencies.walk(subject, kind, 75)
end

local function performMainMapQuest(subject, kind, dependencies)
	if not dependencies.goMainMap() then
		return false
	end

	if not dependencies.workspace:FindFirstChild("StaticMap") then
		return false
	end

	local targetInfo = MAINMAP_QUEST_TARGETS[kind]
	local area = dependencies.workspace.StaticMap:FindFirstChild(targetInfo[1])

	if not area then
		return false
	end

	local target = area:WaitForChild(targetInfo[2], 10)

	if not target then
		return false
	end

	dependencies.moveTo(target.Position)
	return dependencies.waitForQuest(subject, kind, 90, 25)
end

local WEATHER_QUEST_TARGETS = {
	rain_puddle = "RainPuddles",
	snowman = "Snowmen",
	leaf_pile = "LeafPiles",
	diving_board = "DivingBoards",
}

local function performWeatherQuest(subject, kind, dependencies)
	if not dependencies.goMainMap() then
		return false
	end

	local workspace = dependencies.workspace
	local folder = workspace:FindFirstChild("StaticMap") and workspace.StaticMap:FindFirstChild(WEATHER_QUEST_TARGETS[kind])

	if not folder then
		return false
	end

	local _, root = dependencies.getCharacterParts()
	local target, nearest

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local distance = if root then (descendant.Position - root.Position).Magnitude else 0

			if not nearest or distance < nearest then
				target, nearest = descendant, distance
			end
		end
	end

	if not target then
		return false
	end

	dependencies.moveTo(target.Position)
	return dependencies.waitForQuest(subject, kind, 60, 20)
end

local INTERIOR_QUEST_DESTINATIONS = {
	salon = "Salon",
	school = "School",
	sick = "Hospital",
	cat_cafe = "CatCafe",
	pizza_party = "PizzaShop",
}

local function findInteriorFurniture(workspace, interior, kind)
	local houses = workspace:FindFirstChild("HouseInteriors")
	local furniture = houses and workspace.HouseInteriors:FindFirstChild("furniture")

	if not furniture then
		return nil
	end

	for _, container in ipairs(furniture:GetChildren()) do
		if string.find(container.Name, "/" .. interior .. "/") then
			for _, model in ipairs(container:GetChildren()) do
				if model:IsA("Model") and model:GetAttribute("furniture_kind") == kind then
					return model, model:GetAttribute("furniture_unique") or container.Name:match("/([^/]+)$")
				end
			end
		end
	end

	return nil
end

local function healSubject(subject, dependencies)
	local started = dependencies.clock()
	local model, unique

	repeat
		model, unique = dependencies.findInteriorFurniture("Hospital", "doctor")

		if model then
			break
		end

		dependencies.wait(0.5)
	until dependencies.clock() - started > 8

	if not model then
		return false
	end

	local blocks = model:FindFirstChild("UseBlocks")
	local block = blocks and blocks:FindFirstChildWhichIsA("BasePart")
	local target = block or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")

	if target then
		dependencies.moveTo(target.Position + target.CFrame.LookVector * 4)
		dependencies.wait(0.5)
	end

	local context = { cframe = target.CFrame }
	local character = if subject.baby then dependencies.player.Character else subject.char
	dependencies.spawn(dependencies.remote, "HousingAPI/ActivateInteriorFurniture", unique, if block then block.Name else "UseBlock", context, character)
	return dependencies.waitForQuest(subject, "sick", 15, 10)
end

local function performInteriorQuest(subject, kind, dependencies)
	if not dependencies.travel(INTERIOR_QUEST_DESTINATIONS[kind], "MainDoor") then
		return false
	end

	if kind == "sick" then
		if dependencies.heal(subject) then
			return true
		end

		local location = dependencies.getLocation()
		local interior = location and location.interior
		local target = interior and interior:FindFirstChild("SickAilmentTarget", true)

		if target and target:IsA("BasePart") then
			dependencies.moveTo(target.Position)
		end
	end

	return dependencies.waitForQuest(subject, kind, 90, 25)
end

local function getInventoryCategory(getData, category)
	local inventory = getData("inventory") or {}
	return inventory[category] or {}
end

local function findQuestItems(kind, category, dependencies)
	local definition = dependencies.modules.AilmentsDB and dependencies.modules.AilmentsDB[kind]
	local matches = {}

	for unique, item in pairs(dependencies.inventory(category)) do
		local entry = dependencies.getItem(category, item.id)

		if entry then
			local ok, accepted = true, true

			if definition and definition.filter_callback then
				ok, accepted = dependencies.safeCall(definition.filter_callback, entry)
			end

			if ok and accepted then
				table.insert(matches, unique)
			end
		end
	end

	return matches
end

local function equipInventoryItem(unique, remote)
	return remote("ToolAPI/Equip", unique, { use_sound_delay = true, equip_as_last = false })
end

local function isItemForSale(id, dependencies)
	local forSale = dependencies.modules.ForSale

	if not forSale or not forSale.is_for_sale then
		return false
	end

	local ok, result = dependencies.safeCall(forSale.is_for_sale, id)
	return ok and result == true
end

local function getShopBalance(currency, getData)
	local key = if currency == "bucks" then "money" else currency
	return tonumber(getData(key)) or 0
end

local function formatShopNumber(value)
	local digits = tostring(math.floor(tonumber(value) or 0))
	return (digits:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function findShopChoice(choices, selected)
	for _, choice in ipairs(choices) do
		if choice.label == selected then
			return choice
		end
	end

	return nil
end

local function getShopCatalog(category, eggsOnly, dependencies)
	local database = dependencies.modules.InventoryDB
	local items = database and database[category] or {}
	local choices = {}

	for kind, item in pairs(items) do
		if type(item.cost) ~= "number" or item.cost <= 0 or eggsOnly and not item.is_egg then
			continue
		end

		if not dependencies.forSale(kind) then
			continue
		end

		local currency = item.currency_id or "bucks"
		local currencyName = dependencies.currencies[currency] or currency
		table.insert(choices, {
			kind = kind,
			category = category,
			cost = item.cost,
			currency = currency,
			image = item.image,
			label = string.format("%s | %s %s", item.name or kind, dependencies.format(item.cost), currencyName),
		})
	end

	table.sort(choices, function(first, second)
		if first.currency ~= second.currency then
			return first.currency == "bucks"
		end

		return first.cost < second.cost
	end)

	return choices
end

local function buyShopItems(dependencies)
	if dependencies.state.Busy or dependencies.busy() or dependencies.modules.Interiors.entering then
		return
	end

	local types = {
		{ toggle = "AutoBuyEgg", choice = "EggToBuy", catalog = dependencies.eggs },
		{ toggle = "AutoBuyGift", choice = "GiftToBuy", catalog = dependencies.gifts },
	}

	for _, itemType in ipairs(types) do
		if not dependencies.readOption(itemType.toggle, false) then
			continue
		end

		local selected = dependencies.readOption(itemType.choice, nil)
		local choice = dependencies.find(itemType.catalog, selected)

		if not choice or dependencies.shop.Balance(choice.currency) < choice.cost then
			continue
		end

		if dependencies.clock() <= (dependencies.shop.Failed[choice.kind] or 0) then
			continue
		end

		local ok, result = dependencies.remote("ShopAPI/BuyItem", choice.category, choice.kind, {})

		if ok and result == "success" then
			dependencies.stats.Bought += 1
			dependencies.log("Bought " .. choice.label)
			local embed = dependencies.webhook.Embed("Item bought", "Bought **" .. choice.label .. "**", 1752220, {
				{ name = "Bucks left", value = dependencies.format(dependencies.getData("money")), inline = true },
				{ name = "Bought this session", value = tostring(dependencies.stats.Bought), inline = true },
			}, choice.image)
			dependencies.webhook.Send("Item Bought", embed)
		else
			dependencies.shop.Failed[choice.kind] = dependencies.clock() + 60
			dependencies.log("Could not buy " .. choice.label .. ": " .. tostring(result))
		end

		dependencies.wait(1)
	end
end

local function openShopGift(dependencies)
	if not dependencies.readOption("AutoOpenGift", false) or dependencies.state.Busy or dependencies.busy() then
		return
	end

	for unique, gift in pairs(dependencies.inventory("gifts")) do
		local entry = dependencies.getItem("gifts", gift.id)

		if not entry or entry.tool ~= "GiftTool" then
			continue
		end

		if dependencies.clock() <= (dependencies.shop.Failed[unique] or 0) then
			continue
		end

		local ok, result = dependencies.remote("ShopAPI/OpenGift", unique)

		if ok and result then
			dependencies.stats.Opened += 1
			dependencies.log("Opened " .. (entry.name or gift.id))
		else
			dependencies.shop.Failed[unique] = dependencies.clock() + 120
		end

		dependencies.wait(1)
		return
	end
end

local SHOP_CURRENCY_NAMES = {
	bucks = "Bucks",
	pet_recycler_tickets_2026 = "Tickets",
}

local function createShopController(dependencies)
	local shop = { Failed = {} }
	shop.Balance = function(currency) return getShopBalance(currency, dependencies.getData) end
	shop.Catalog = function(category, eggsOnly)
		return getShopCatalog(category, eggsOnly, {
			modules = dependencies.modules,
			forSale = dependencies.forSale,
			format = formatShopNumber,
			currencies = SHOP_CURRENCY_NAMES,
		})
	end

	local eggs = shop.Catalog("pets", true)
	local gifts = shop.Catalog("gifts", false)
	local eggChoices, giftChoices = {}, {}

	for _, egg in ipairs(eggs) do
		table.insert(eggChoices, egg.label)
	end

	for _, gift in ipairs(gifts) do
		table.insert(giftChoices, gift.label)
	end

	local context = table.clone(dependencies)
	context.shop = shop
	context.eggs = eggs
	context.gifts = gifts
	context.find = findShopChoice
	context.format = formatShopNumber

	return {
		shop = shop,
		eggChoices = eggChoices,
		giftChoices = giftChoices,
		buy = function() buyShopItems(context) end,
		open = function() openShopGift(context) end,
	}
end

local function findStroller(dependencies)
	for unique in pairs(dependencies.inventory("strollers")) do
		return unique
	end

	local database = dependencies.modules.InventoryDB
	local strollers = database and database.strollers
	local cheapest, price

	for id, item in pairs(strollers or {}) do
		if type(item.cost) == "number" and item.cost > 0 and not item.currency_id and (not price or item.cost < price) and dependencies.isForSale(id) then
			cheapest, price = id, item.cost
		end
	end

	if not cheapest or (tonumber(dependencies.getData("money")) or 0) < price then
		return nil
	end

	dependencies.remote("ShopAPI/BuyItem", "strollers", cheapest, {})
	dependencies.wait(1)

	for unique in pairs(dependencies.inventory("strollers")) do
		return unique
	end

	return nil
end

local function findStrollerSeat(player, collectionService)
	local character = player.Character

	if not character then
		return nil
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if collectionService:HasTag(descendant, "StrollerSeat") then
			return descendant
		end
	end

	return nil
end

local function performRideQuest(subject, kind, dependencies)
	if subject.baby then
		return false
	end

	dependencies.goHome()
	dependencies.closePetFocus()
	dependencies.releaseBaby()
	local stroller = dependencies.findStroller()

	if not stroller then
		return false
	end

	dependencies.equip(stroller)
	local started = dependencies.clock()
	local model

	repeat
		dependencies.wait(0.3)
		model = dependencies.findStrollerModel()
	until model or dependencies.clock() - started > 5

	if not model then
		dependencies.remote("ToolAPI/Unequip", stroller, {})
		return false
	end

	dependencies.remote("AdoptAPI/UseStroller", dependencies.player, subject.char, model)
	dependencies.wait(0.5)
	local completed = dependencies.walker.Until(subject, kind, 120, true, 14, 14)
	dependencies.remote("ToolAPI/Unequip", stroller, {})
	return completed
end

local function performPlayQuest(subject, kind, dependencies)
	if subject.baby then
		return false
	end

	dependencies.goHome()
	local toys = dependencies.findItems("play", "toys")

	if #toys == 0 then
		for unique, item in pairs(dependencies.inventory("toys")) do
			if item.id == "squeaky_bone_default" then
				table.insert(toys, unique)
			end
		end
	end

	if #toys == 0 then
		return false
	end

	local toy = toys[1]

	for _ = 1, 8 do
		if not dependencies.ailments(subject)[kind] then
			return true
		end

		dependencies.equip(toy)
		dependencies.wait(0.4)
		dependencies.remote("PetObjectAPI/CreatePetObject", "__Enum_PetObjectCreatorType_1", {
			unique_id = toy,
			reaction_name = "ThrowToyReaction",
		})
		dependencies.wait(3.5)
	end

	return not dependencies.ailments(subject)[kind]
end

local MYSTERY_QUEST_PREFERENCES = {
	"hungry", "thirsty", "sleepy", "dirty", "toilet", "pet_me", "play", "walk", "ride",
	"school", "salon", "pizza_party", "cat_cafe", "bored", "beach_party", "camping", "sick",
}

local function performMysteryQuest(subject, kind, dependencies)
	if subject.baby then
		return false
	end

	dependencies.goHome()
	local ok, slots, ailmentKey = dependencies.safeCall(function()
		local modules = dependencies.modules

		if not modules then
			return nil
		end

		local client = modules.AilmentsClient
		local current = client.get_ailments_for_pet(subject.pw)

		for _, ailment in pairs(current or {}) do
			if ailment.kind == "mystery" and ailment.action and ailment.action.options then
				local options = ailment.action.options

				if options.get_ailment_slots then
					return options.get_ailment_slots(options.random_seed, client.get_ailments_for_pet(subject.pw), subject.pw), options.ailment_key
				end
			end
		end
	end)

	if not ok or type(slots) ~= "table" then
		return false
	end

	local bestIndex, bestRank

	for index, slot in ipairs(slots) do
		local name = if type(slot) == "table" and slot.kind then slot.kind else slot
		local rank = table.find(MYSTERY_QUEST_PREFERENCES, name) or 99

		if not bestRank or rank < bestRank then
			bestIndex, bestRank = index, rank
		end
	end

	if not bestIndex then
		return false
	end

	dependencies.fireRemote("AilmentsAPI/ChooseMysteryAilment", subject.key, ailmentKey or "mystery", bestIndex, slots[bestIndex])
	dependencies.wait(1.5)
	return not dependencies.ailments(subject)[kind]
end

local function performPetMeQuest(subject, kind, dependencies)
	if subject.baby then
		return false
	end

	dependencies.goHome()
	dependencies.closePetFocus()
	dependencies.remote("PetAPI/ExitFurnitureUseStates")
	dependencies.safeCall(function()
		local app = dependencies.modules.UI.apps.FocusPetApp
		app:capture_focus(subject.pw)
		local started = dependencies.clock()

		while not app.char_wrapper and dependencies.clock() - started < 5 do
			dependencies.wait(0.1)
		end

		if not app.char_wrapper then
			return false
		end

		dependencies.wait(1)
		local handler = app.petting_handler
		local camera = dependencies.workspace.CurrentCamera
		local count = 0
		local finished = false
		handler.get_position = function()
			count += 1
			return camera.ViewportSize * 0.5 + dependencies.vector2(math.sin(count) * 6, math.cos(count) * 4)
		end
		dependencies.spawn(function()
			while not finished do
				handler.is_holding_pet_button = true
				dependencies.wait()
			end
		end)
		handler:start_petting("pet_me")
		finished = true
		handler.get_position = nil
	end)
	dependencies.wait(2)
	dependencies.closePetFocus()
	return not dependencies.ailments(subject)[kind]
end

local function findBabyFood(kind, dependencies)
	local best, bestUses

	for unique, item in pairs(dependencies.inventory("food")) do
		local entry = dependencies.getItem("food", item.id)

		if entry and entry.ailment_to_boost == kind and not entry.cannot_feed_to_self then
			local uses = tonumber(entry.uses) or 1

			if not bestUses or uses < bestUses then
				best, bestUses = unique, uses
			end
		end
	end

	return best, bestUses
end

local function feedBaby(subject, kind, dependencies)
	local unique = dependencies.findFood(kind)

	if not unique and dependencies.readOption("BuyFood", true) then
		local id = ({ hungry = "apple", thirsty = "water" })[kind]

		if id then
			local entry = dependencies.getItem("food", id)

			if entry and (tonumber(dependencies.getData("money")) or 0) >= (tonumber(entry.cost) or 0) then
				dependencies.remote("ShopAPI/BuyItem", "food", id, {})
				dependencies.wait(1)
				unique = dependencies.findFood(kind)
			end
		end
	end

	if not unique then
		return false
	end

	for _ = 1, 3 do
		if not dependencies.ailments(subject)[kind] then
			break
		end

		dependencies.equip(unique)
		dependencies.wait(0.3)
		dependencies.remote("ToolAPI/ServerUseTool", unique, "START")
		dependencies.wait(1.1)
		dependencies.remote("ToolAPI/ServerUseTool", unique, "END")
		dependencies.wait(0.6)
	end

	dependencies.remote("ToolAPI/Unequip", unique, {})
	return not dependencies.ailments(subject)[kind]
end

local function performHomeQuest(subject, kind, dependencies)
	if subject.baby and (kind == "hungry" or kind == "thirsty") and dependencies.feedBaby(subject, kind) then
		return true
	end

	if not dependencies.goHome() then
		return false
	end

	dependencies.closePetFocus()

	if not subject.baby then
		dependencies.remote("PetAPI/ExitFurnitureUseStates")
	end

	local furniture = dependencies.furniture(kind, subject.baby)

	for _, item in ipairs(furniture) do
		if not dependencies.ailments(subject)[kind] then
			break
		end

		local character = if subject.baby then dependencies.player.Character else subject.char
		dependencies.useFurniture(item, character)
		local completed = dependencies.waitForQuest(subject, kind, 25, 12)

		if subject.baby then
			dependencies.releaseBaby()
		end

		if completed then
			return true
		end
	end

	return not dependencies.ailments(subject)[kind]
end

local function performFarmQuest(quest, dependencies)
	local farm = dependencies.farm
	local subject = quest.s
	farm.LastAction = string.format("%s | %s", subject.label, dependencies.describeKind(quest.kind))
	dependencies.log(string.format("Doing %s for %s", dependencies.describeKind(quest.kind), subject.label))

	local started = dependencies.clock()
	local ok, result = pcall(quest.fn, subject, quest.kind)
	local key = subject.key .. quest.kind

	if ok and result then
		farm.Failures[key] = nil

		if farm.Resume == key then
			farm.Resume = nil
		end

		farm.Learn(quest.kind, dependencies.clock() - started)
		return
	end

	local failures = (farm.Failures[key] or 0) + 1
	farm.Failures[key] = failures

	local delay = math.min(failures * 30, 180)
	farm.SkipUntil[key] = dependencies.clock() + delay

	local reason = if ok then "" else ": " .. tostring(result)
	dependencies.log(string.format("Could not finish %s yet (retry in %ds)%s", dependencies.describeKind(quest.kind), delay, reason))
end

local function stepFarm(dependencies)
	local farm = dependencies.farm
	local state = dependencies.state
	local readOption = dependencies.readOption

	if not readOption("AutoFarm", false) then
		farm.LastAction = "Idle"
		return
	end

	if state.Busy then
		farm.LastAction = "Paused: " .. state.Busy
		return
	end

	if dependencies.isInMinigame() then
		farm.LastAction = "Paused: in a minigame"
		return
	end

	if readOption("PlayerQuests", true) and readOption("PlayAsBaby", false) and dependencies.getData("team") ~= "Babies" then
		dependencies.remote("TeamAPI/ChooseTeam", "Babies", { dont_respawn = true })
		dependencies.wait(2)
	end

	dependencies.prepare()

	if readOption("AutoAgePotions", false) then
		pcall(dependencies.potion.Run)
	end

	local pets = dependencies.pets()

	if #pets == 0 then
		farm.LastAction = "No pet to farm with"
		return
	end

	if readOption("AutoBuildHouse", false) and dependencies.isHome() then
		if dependencies.clock() - (farm.LastBuild or -999) > 60 then
			farm.LastBuild = dependencies.clock()
			pcall(state.BuildHouse, true)
		end
	end

	local quests = dependencies.quests()

	if #quests == 0 then
		farm.LastAction = "Waiting for new quests"

		if readOption("StayHome", true) and not dependencies.isHome() then
			dependencies.goHome()
		end

		return
	end

	performFarmQuest(quests[1], dependencies)
end

local function isInMinigame(modules)
	if not modules.Minigames then
		return false
	end

	local ok, games = pcall(modules.Minigames.get_all)

	if not ok then
		return false
	end

	for _, minigame in pairs(games) do
		if minigame.is_participating then
			return true
		end
	end

	return false
end

local runtimeHelpers = {}

runtimeHelpers.questLabels = {
	camping = "Camping", hungry = "Hungry", sleepy = "Sleepy", thirsty = "Thirsty", snowman = "Snowman",
	party_zone = "Party", bored = "Bored", salon = "Salon", play = "Play", cat_cafe = "Cat Cafe",
	toilet = "Potty", beach_party = "Beach Party", at_work = "At Work", ride = "Ride", leaf_pile = "Leaf Pile",
	dirty = "Dirty", rain_puddle = "Rain Puddle", sick = "Sick", diving_board = "Diving Board", pet_me = "Pet Me",
	school = "School", walk = "Walk", mystery = "Mystery", pizza_party = "Pizza Party",
}

function runtimeHelpers.describeQuestKind(kind)
	return runtimeHelpers.questLabels[kind] or tostring(kind):gsub("_", " ")
end

function runtimeHelpers.trackCompletedQuests(tracker, dependencies)
	local current = {}
	for _, subject in ipairs(dependencies.subjects()) do
		local list = {}
		for kind in pairs(dependencies.ailments(subject)) do
			list[kind] = true
		end
		current[subject.key] = { s = subject, list = list }
	end
	for key, entry in pairs(current) do
		local previous = tracker.previous[key]
		if previous then
			for kind in pairs(previous.list) do
				if not entry.list[kind] then
					dependencies.stats.Quests += 1
					local description = string.format("**%s** finished **%s**", entry.s.label, dependencies.describeKind(kind))
					local fields = {
						{ name = "Quests this session", value = dependencies.format(dependencies.stats.Quests), inline = true },
						{ name = "Bucks", value = dependencies.format(dependencies.getData("money")), inline = true },
					}
					dependencies.webhook.Send("Quest Completed", dependencies.webhook.Embed("Quest completed", description, 5793266, fields, entry.s.image))
				end
			end
		end
	end
	tracker.previous = current
end

function runtimeHelpers.trackPetAges(tracker, dependencies)
	for unique, pet in pairs(dependencies.inventory("pets")) do
		local age = pet.properties and pet.properties.age
		local previous = tracker.previous[unique]
		if previous and age and previous.age and age > previous.age then
			dependencies.stats.AgeUps += 1
			local description = string.format("**%s** is now **%s**", dependencies.label("pets", pet.id), dependencies.ageNames[age] or "age " .. tostring(age))
			local fields = { { name = "Age ups this session", value = tostring(dependencies.stats.AgeUps), inline = true } }
			dependencies.webhook.Send("Pet Aged Up", dependencies.webhook.Embed("Pet aged up", description, 5763719, fields, dependencies.image(pet.id)))
		end
		tracker.previous[unique] = { id = pet.id, age = age }
	end
end

function runtimeHelpers.trackPetHatches(tracker, dependencies)
	local current = {}
	for unique, pet in pairs(dependencies.inventory("pets")) do
		local entry = dependencies.catalog("pets", pet.id)
		if entry and entry.is_egg then
			current[unique] = pet.id
		end
	end
	for unique, egg in pairs(tracker.previous or {}) do
		if not current[unique] then
			dependencies.stats.Hatched += 1
			local pet = dependencies.inventory("pets")[unique]
			local label = dependencies.label("pets", egg)
			local description = if pet then string.format("**%s** hatched into **%s**", label, dependencies.label("pets", pet.id)) else string.format("**%s** hatched", label)
			local fields = { { name = "Eggs hatched", value = tostring(dependencies.stats.Hatched), inline = true } }
			dependencies.webhook.Send("Egg Hatched", dependencies.webhook.Embed("Egg hatched", description, 15418782, fields, dependencies.image(if pet then pet.id else egg)))
		end
	end
	tracker.previous = current
end

function runtimeHelpers.sendFarmSummary(tracker, dependencies)
	local minutes = tonumber(dependencies.readOption("SummaryMinutes", 30)) or 30
	if dependencies.clock() - tracker.last < minutes * 60 then
		return
	end
	tracker.last = dependencies.clock()
	if not dependencies.readOption("AutoFarm", false) then
		return
	end
	local stats = dependencies.stats
	local elapsed = math.floor((dependencies.time() - stats.StartedAt) / 60)
	local wrappers = dependencies.wrappers()
	local format = dependencies.format
	local fields = {
		{ name = "Quests", value = format(stats.Quests), inline = true },
		{ name = "Eggs hatched", value = format(stats.Hatched), inline = true },
		{ name = "Age ups", value = format(stats.AgeUps), inline = true },
		{ name = "Bucks", value = format(dependencies.getData("money")), inline = true },
	}
	local image = if wrappers[1] then dependencies.image(wrappers[1].pet_id) else nil
	dependencies.webhook.Send("Farm Summary", dependencies.webhook.Embed("Farm summary", string.format("Running for %d min", elapsed), 15903035, fields, image))
end

function runtimeHelpers.updateHubStatus(dependencies)
	local stats, interface = dependencies.stats, dependencies.interface
	local format, getData, update = dependencies.format, dependencies.getData, dependencies.update
	local lines = { "Doing: " .. dependencies.farm.LastAction }
	for _, subject in ipairs(dependencies.subjects()) do
		local ailments = {}
		for kind in pairs(dependencies.ailments(subject)) do
			table.insert(ailments, dependencies.describeKind(kind))
		end
		table.sort(ailments)
		local label = subject.label
		if subject.pw then
			local progression = subject.pw.pet_progression
			local age = progression and progression.age or 1
			label = string.format("%s (%s)", label, dependencies.ageNames[age] or "?")
		end
		table.insert(lines, label .. ": " .. (if #ailments > 0 then table.concat(ailments, ", ") else "no quests"))
	end
	table.insert(lines, string.format("Session: %d quests | %d eggs hatched | %d age ups | %d bought | %d opened", stats.Quests, stats.Hatched, stats.AgeUps, stats.Bought, stats.Opened))
	table.insert(lines,"Bucks: "..format(getData("money")))
	table.insert(lines, dependencies.state.Log)
	update(interface.FarmStatus, table.concat(lines, "\n"))
	update(interface.PotionStatus, dependencies.potion.Describe())
    if interface.SyncMenuKey then interface.SyncMenuKey()end
end

function runtimeHelpers.getMinigameCountdown(id, getData, getServerTime)
	local cycle = getData(id .. "_cycle_timestamp")
	local timestamp = if type(cycle) == "table" then tonumber(cycle.timestamp) else nil
	if timestamp then
		return timestamp - getServerTime()
	end
end

function runtimeHelpers.getMinigame(modules, id)
	local ok, game = pcall(modules.Minigames.get, id)
	return if ok and game then game else nil
end

function runtimeHelpers.connectHubSignal(state, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(state.Connections, connection)
	return connection
end

function runtimeHelpers.handleIdle(readOption, virtualUser, vector2)
	if not readOption("AntiAFK", true) then
		return
	end

	pcall(function()
		virtualUser:CaptureController()
		virtualUser:ClickButton2(vector2())
	end)
end

function runtimeHelpers.setBlackScreen(state, enabled, dependencies)
	if enabled and not state.BlackScreen then
		local screen = dependencies.Instance.new("ScreenGui")
		screen.Name = "AxisAdoptMeBlack"
		screen.IgnoreGuiInset = true
		screen.DisplayOrder = 999999
		screen.ResetOnSpawn = false
		local background = dependencies.Instance.new("Frame")
		background.Size = dependencies.UDim2.new(1, 0, 1, 0)
		background.BackgroundColor3 = dependencies.Color3.new(0, 0, 0)
		background.BorderSizePixel = 0
		background.Parent = screen
		local label = dependencies.Instance.new("TextLabel")
		label.Size = dependencies.UDim2.new(1, 0, 0.10000000149011612, 0)
		label.Position = dependencies.UDim2.new(0, 0, 0.44999998807907104, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = dependencies.Color3.new(0.47058823704719543, 0.47058823704719543, 0.47058823704719543)
		label.Font = dependencies.Enum.Font.GothamMedium
		label.TextSize = 18
		label.Text = "Axis | Adopt Me!"
		label.Parent = background
		screen.Parent = dependencies.player:WaitForChild("PlayerGui")
		state.BlackScreen = screen
	elseif not enabled and state.BlackScreen then
		state.BlackScreen:Destroy()
		state.BlackScreen = nil
	end
end

function runtimeHelpers.setRenderingDisabled(runService, disabled)
	pcall(runService.Set3dRenderingEnabled, runService, not disabled)
end

function runtimeHelpers.setFrameRate(setfpscap, value)
	if not setfpscap then
		return
	end
	local limit = tonumber(value) or 0
	pcall(setfpscap, if limit > 0 then limit else 999)
end

function runtimeHelpers.bindPerformanceSettings(options, dependencies)
	options.BlackScreen:OnChanged(function(value)
		runtimeHelpers.setBlackScreen(dependencies.state, value, dependencies)
	end)
	options.Disable3D:OnChanged(function(value)
		runtimeHelpers.setRenderingDisabled(dependencies.runService, value)
	end)
	options.FPSCap:OnChanged(function(value)
		runtimeHelpers.setFrameRate(dependencies.setfpscap, value)
	end)
end

function runtimeHelpers.syncMenuKey(options, interface, window, typeOf)
	local option = options.MenuKeybind
	if not option then
		return
	end
	local key = option:GetBind()
	if typeOf(key) ~= "EnumItem" or interface.LastMenuKey == key then
		return
	end
	interface.LastMenuKey = key
	window.MinimizeKey = key
	pcall(function()
		window._axisWindow:SetKeybind(key)
	end)
end

function runtimeHelpers.getGameTime(modules, workspace)
	if modules.LiveOpsTime then
		local ok, value = pcall(modules.LiveOpsTime.now)
		if ok and type(value) == "number" then
			return value
		end
	end

	return workspace:GetServerTimeNow()
end

function runtimeHelpers.createHubStats(startedAt)
	return {
		StartedAt = startedAt,
		Quests = 0, AgeUps = 0, Hatched = 0, Potions = 0, Bought = 0, Opened = 0, 
	}
end

local function createFarmState()
	local farm = { Failures = {}, Learned = {}, SkipUntil = {}, LastAction = "Idle" }
	farm.Learn = function(kind, elapsed)
		learnFarmQuest(farm, kind, elapsed)
	end
	return farm
end

local function claimDailyRewards(dependencies)
	if not dependencies.readOption("AutoDailies", true) or not dependencies.modules.Dailies then
		return
	end

	local manager = dependencies.getData("dailies_manager")
	local tabs = manager and manager.serialized_tabs or {}

	for tabId, tab in pairs(tabs) do
		local allComplete = true
		local count = 0

		for _, daily in pairs(tab.active_dailies or {}) do
			count += 1
			local state = daily.state or {}

			if (state.steps_completed or 0) >= (state.steps_to_complete or 1) then
				dependencies.safeCall(dependencies.modules.Dailies.try_to_claim_daily_rewards, tabId)
			else
				allComplete = false
			end
		end

		if count > 0 and allComplete then
			dependencies.safeCall(dependencies.modules.Dailies.try_to_claim_tab_reward, tabId)
		end
	end
end

local function collectPaycheck(dependencies)
	if not dependencies.isVisible("PlaytimePayoutsApp") then
		return
	end

	dependencies.fire("PayAPI/Collect")
	dependencies.wait(0.6)
	dependencies.safeCall(dependencies.modules.UI.set_app_visibility, "PlaytimePayoutsApp", false)
	dependencies.log("Cashed out paycheck")
end

local function clickGuiObject(object, dependencies)
	if not object or not object:IsA("GuiObject") then
		return false
	end

	local inset = dependencies.guiService:GetGuiInset()
	local x = object.AbsolutePosition.X + object.AbsoluteSize.X / 2
	local y = object.AbsolutePosition.Y + object.AbsoluteSize.Y / 2 + inset.Y
	local screen = dependencies.blackScreenHandle ~= nil and dependencies.state.BlackScreen
	local wasEnabled = screen and screen.Enabled

	if wasEnabled then
		screen.Enabled = false
	end

	local ok = pcall(function()
		dependencies.wait()
		dependencies.input:SendMouseButtonEvent(x, y, 0, true, dependencies.game, 1)
		dependencies.wait(0.06)
		dependencies.input:SendMouseButtonEvent(x, y, 0, false, dependencies.game, 1)
	end)

	if wasEnabled then
		screen.Enabled = true
	end

	return ok
end

local function isGuiObjectVisible(object, stop)
	while object and object ~= stop do
		if object:IsA("GuiObject") and not object.Visible then
			return false
		end

		if object:IsA("LayerCollector") and not object.Enabled then
			return false
		end

		object = object.Parent
	end

	return true
end

local function closeMinigameRewards(dependencies)
	if not dependencies.isVisible("MinigameRewardsApp") then
		return
	end

	local app = dependencies.player.PlayerGui:FindFirstChild("MinigameRewardsApp")
	local button = app and app:FindFirstChild("Body") and app.Body:FindFirstChild("Button")

	if button then
		dependencies.click(button)
	end

	if dependencies.isVisible("MinigameRewardsApp") then
		dependencies.safeCall(dependencies.modules.UI.set_app_visibility, "MinigameRewardsApp", false)
	end
end

local DIALOG_RULES = {
	{ text = "Congratulations! You passed!", button = "Okay" },
	{ text = "That answer was wrong", button = "Okay" },
	{ text = "is starting soon! Teleport there now?", button = "No", option = "AutoFarm" },
}

local function getDialogButton(text, dependencies)
	for _, rule in ipairs(dependencies.rules or DIALOG_RULES) do
		if not text:find(rule.text, 1, true) or rule.also and not text:find(rule.also, 1, true) then
			continue
		end

		if rule.option and not dependencies.readOption(rule.option, false) then
			continue
		end

		local button = rule.button

		if rule.minigame then
			local ok, minigame = pcall(dependencies.modules.Minigames.get, rule.minigame)

			if ok and minigame and (minigame.is_queued or minigame.is_participating) then
				button = "No"
			end
		end

		return button
	end

	return nil
end

local function handleDialog(popup, dependencies)
	local app = dependencies.player.PlayerGui:FindFirstChild("DialogApp")

	if not app or not app.Enabled then
		return
	end

	local text

	for _, object in ipairs(app:GetDescendants()) do
		if object:IsA("TextLabel") and object.Name == "TextLabel" and object.Parent and object.Parent.Name == "Info" and dependencies.visible(object, app) then
			text = object.Text
			break
		end
	end

	if not text then
		return
	end

	local choice = getDialogButton(text, dependencies)

	if not choice then
		return
	end

	local attempt = popup.Attempts[text]

	if attempt and attempt.count >= 3 and dependencies.clock() - attempt.at < 20 then
		return
	end

	if not attempt or dependencies.clock() - attempt.at >= 20 then
		attempt = { count = 0, at = dependencies.clock() }
	end

	for _, object in ipairs(app:GetDescendants()) do
		if not object:IsA("TextLabel") or object.Text ~= choice or not dependencies.visible(object, app) then
			continue
		end

		local button = object:FindFirstAncestorWhichIsA("GuiButton")

		if button then
			attempt.count += 1
			popup.Attempts[text] = attempt
			dependencies.click(button)
			dependencies.log("Popup: " .. choice)
			return true
		end
	end
end

local function handlePopups(popup, readOption)
	if not readOption("AutoPopups", true) then
		return
	end

	pcall(popup.Paycheck)
	pcall(popup.MinigameRewards)
	pcall(popup.Dialog)
end

local function createPopupController(dependencies)
	local popup = { Attempts = {} }
	local context = table.clone(dependencies)

	context.visible = isGuiObjectVisible
	context.click = function(object)
		local handle = dependencies.blackScreenHandle

		if dependencies.getBlackScreenHandle then
			handle = dependencies.getBlackScreenHandle()
		end

		return clickGuiObject(object, {
			guiService = dependencies.guiService,
			input = dependencies.input,
			game = dependencies.game,
			state = dependencies.state,
			blackScreenHandle = handle,
			wait = dependencies.wait,
		})
	end

	popup.Paycheck = function() return collectPaycheck(context) end
	popup.MinigameRewards = function() return closeMinigameRewards(context) end
	popup.Dialog = function() return handleDialog(popup, context) end

	return popup
end

local function getPendingPetDrops(getData)
	local pending = {}
	local manager = getData("pet_progression_rewards_manager")

	if type(manager) ~= "table" or type(manager.boxes) ~= "table" then
		return pending
	end

	for pet, boxes in pairs(manager.boxes) do
		if type(boxes) ~= "table" then
			continue
		end

		for box, items in pairs(boxes) do
			if type(items) ~= "table" then
				continue
			end

			for item in pairs(items) do
				table.insert(pending, { pet = pet, box = box, item = item })
			end
		end
	end

	return pending
end

local function walkOntoPetDrops(dependencies)
	local _, root = dependencies.getCharacterParts()

	if not root then
		return
	end

	local original = root.CFrame
	local moved = false

	for _, object in ipairs(dependencies.workspace:GetChildren()) do
		if object:GetAttribute("pet_unique") == nil or not (object:IsA("Model") or object:IsA("BasePart")) then
			continue
		end

		local position = object:GetPivot().Position

		if (position - root.Position).Magnitude < 300 then
			root.AssemblyLinearVelocity = dependencies.zero
			root.CFrame = dependencies.cframe(position + dependencies.offset)
			dependencies.wait(0.35)
			moved = true
		end
	end

	if moved and root.Parent then
		root.CFrame = original
	end
end

local function claimPetDrops(drop, dependencies)
	if not dependencies.readOption("AutoClaimDrops", true) then
		return
	end

	local pending = drop.Pending()

	if #pending == 0 then
		drop.Tried = {}
		return
	end

	local shouldWalk = false

	for _, item in ipairs(pending) do
		local key = item.box .. "/" .. item.item
		local previous = drop.Tried[key]

		if previous and dependencies.clock() - previous.at <= 4 then
			continue
		end

		drop.Tried[key] = { at = dependencies.clock(), n = (previous and previous.n or 0) + 1 }
		dependencies.fire("PetAPI/ClaimProgressionReward", item.pet, item.box, item.item)

		if previous and previous.n >= 2 then
			shouldWalk = true
		end
	end

	if shouldWalk and not dependencies.walker.active and not dependencies.busy() and not dependencies.modules.Interiors.entering then
		drop.WalkOnto()
	end
end

local function equipFarmPet(unique, reason, dependencies)
	dependencies.equip(unique)
	local started = dependencies.clock()
	local equipped = false

	repeat
		dependencies.wait(0.25)

		for _, wrapper in ipairs(dependencies.wrappers()) do
			if wrapper.pet_unique == unique then
				equipped = true
				break
			end
		end
	until equipped or dependencies.clock() - started > 5

	local pet = dependencies.inventory("pets")[unique]
	dependencies.log(string.format("Equipped %s%s", dependencies.label("pets", pet and pet.id), reason))
	return dependencies.wrappers()
end

local function canPetTakeAgePotion(pet, getItem)
	local entry = getItem("pets", pet.id)

	if not entry or entry.is_egg or entry.is_doll or entry.temporary then
		return false
	end

	local properties = pet.properties or {}
	return (tonumber(properties.age) or 0) < 6
end

local function getAgePotionKinds(dependencies)
	local potion = dependencies.potion

	if potion.List then
		return potion.List
	end

	local candidates = {}

	for kind, effect in pairs(dependencies.modules.PotionDB or {}) do
		if type(effect) ~= "table" or not effect.is_age_potion then
			continue
		end

		local ok, xp = pcall(dependencies.getUpvalue, effect.consume, 1)

		if not ok or type(xp) ~= "number" then
			local item = dependencies.getItem("food", kind)
			local description = item and item.custom_tooltip_description or ""
			local tasks = tonumber(string.match(tostring(description), "(%d+) tasks")) or 0
			xp = tasks * 100
		end

		if xp > 0 then
			table.insert(candidates, { kind = kind, xp = xp })
		end
	end

	if #candidates == 0 then
		candidates = {
			{ kind = "super_age_potion", xp = 18300 },
			{ kind = "pet_age_potion", xp = 3000 },
			{ kind = "tiny_pet_age_potion", xp = 300 },
		}
	end

	local kinds = {}

	for _, candidate in ipairs(candidates) do
		local name = dependencies.label("food", candidate.kind)
		local item = dependencies.getItem("food", candidate.kind)
		table.insert(kinds, {
			kind = candidate.kind,
			xp = candidate.xp,
			name = name,
			tradable = item and item.donatable == true or false,
		})
	end

	table.sort(kinds, function(first, second)
		return first.xp > second.xp
	end)

	potion.List = kinds
	return kinds
end

local function collectAgePotionStock(dependencies)
	local selected = collectSelection(dependencies.readOption("AgePotionKinds", {}))
	local stock, byKind = {}, {}

	for _, potion in ipairs(dependencies.potion.Kinds()) do
		if selected[potion.name] then
			local item = { kind = potion.kind, xp = potion.xp, name = potion.name, uniques = {} }
			byKind[potion.kind] = item
			table.insert(stock, item)
		end
	end

	for unique, item in pairs(dependencies.inventory("food")) do
		local potion = byKind[item.id]

		if potion then
			local locks = dependencies.modules.Locks
			local ok, locked = dependencies.safeCall(locks and locks.is_locked, item)

			if not ok or not locked then
				table.insert(potion.uniques, unique)
			end
		end
	end

	for index = #stock, 1, -1 do
		if #stock[index].uniques == 0 then
			table.remove(stock, index)
		end
	end

	return stock
end

local function describeAgePotions(dependencies)
	local counts = {}

	for _, item in pairs(dependencies.inventory("food")) do
		counts[item.id] = (counts[item.id] or 0) + 1
	end

	local inventory = {}

	for _, potion in ipairs(dependencies.potion.Kinds()) do
		local count = counts[potion.kind]

		if count then
			table.insert(inventory, string.format("%s x%d", potion.name, count))
		end
	end

	local status = dependencies.readOption("AutoAgePotions", false) and dependencies.potion.Status or "Off"
	local items = if #inventory > 0 then table.concat(inventory, ", ") else "none"
	return string.format("%s\nIn your inventory: %s\nUsed this session: %d", status, items, dependencies.stats.Potions)
end

local function getPetAgeXpNeeded(pet, dependencies)
	local properties = pet.properties or {}
	local age = tonumber(properties.age) or 0

	if age >= 6 then
		return 0
	end

	local ok, levels = dependencies.safeCall(function()
		return dependencies.modules.PetProgressionDB.get_xp_per_age(dependencies.modules.KindDB[pet.kind or pet.id])
	end)

	if not ok or type(levels) ~= "table" then
		return nil
	end

	local total = 0

	for index = math.max(1, age), #levels do
		total += tonumber(levels[index]) or 0
	end

	return math.max(0, total - (tonumber(properties.xp) or 0))
end

local function planAgePotions(stock, needed, noWaste)
	if #stock == 0 then
		return nil
	end

	local best
	local counts = {}

	local function consider(total, count)
		if noWaste and total > needed and total > 0 then
			return
		end

		if best then
			local reachesTarget = total >= needed
			local bestReachesTarget = best.total >= needed
			local better

			if not noWaste and reachesTarget ~= bestReachesTarget then
				better = reachesTarget
			elseif noWaste or not reachesTarget then
				better = total > best.total or total == best.total and count < best.count
			else
				better = total < best.total or total == best.total and count < best.count
			end

			if not better then
				return
			end
		end

		best = table.clone(counts)
		best.total = total
		best.count = count
	end

	local function search(index, total, count)
		if index > #stock then
			consider(total, count)
			return
		end

		local item = stock[index]

		if index == #stock then
			local amount = (needed - total) / item.xp
			amount = if noWaste then math.floor(amount) else math.ceil(amount)
			amount = math.clamp(amount, 0, #item.uniques)
			counts[index] = amount
			consider(total + amount * item.xp, count + amount)
			return
		end

		local limit = math.clamp(math.floor((needed - total) / item.xp) + (if noWaste then 0 else 1), 0, #item.uniques)

		for amount = 0, limit do
			counts[index] = amount
			search(index + 1, total + amount * item.xp, count + amount)
		end
	end

	search(1, 0, 0)

	if best then
		best.count = nil
	end

	return best
end

local function selectAgePotionStep(pet, stock, noWaste, potion)
	if not potion.Takes(pet) then
		return nil
	end

	local needed = potion.Needed(pet)

	if not needed or needed <= 0 then
		return nil
	end

	local compatible = {}

	for _, item in ipairs(stock) do
		if potion.Takes(pet, item.kind) then
			table.insert(compatible, item)
		end
	end

	local plan = potion.Plan(compatible, needed, noWaste)

	if not plan or plan.total <= 0 then
		return nil
	end

	for index, item in ipairs(compatible) do
		local amount = plan[index] or 0

		if amount > 0 then
			return {
				s = item,
				n = math.min(amount, math.ceil(needed / item.xp)),
				need = needed,
				waste = math.max(0, plan.total - needed),
			}
		end
	end

	return nil
end

local function feedAgePotions(pet, step, dependencies)
	local uniques = table.move(step.s.uniques, 1, step.n, 1, {})
	local additional = table.move(uniques, 2, #uniques, 1, {})
	local objectType = dependencies.modules.PetObjectType
	local foodType = objectType and objectType.PetFood or "__Enum_PetObjectCreatorType_2"
	local ok, object = dependencies.remote("PetObjectAPI/CreatePetObject", foodType, {
		unique_id = uniques[1],
		pet_unique = pet.pet_unique,
		additional_consume_uniques = additional,
	})

	if not ok or not object then
		return 0
	end

	local started = dependencies.clock()
	local consumed = 0

	repeat
		dependencies.wait(0.25)
		local inventory = dependencies.inventory("food")
		consumed = 0

		for _, unique in ipairs(uniques) do
			if not inventory[unique] then
				consumed += 1
			end
		end
	until consumed == #uniques or dependencies.clock() - started > 15 or not dependencies.isActive()

	return consumed
end

local function runAgePotions(potion, dependencies)
	if potion.Running then
		return
	end

	if dependencies.state.Busy or dependencies.busy() or dependencies.modules.Interiors.entering then
		potion.Status = "Paused"
		return
	end

	local stock = potion.Stock()

	if #stock == 0 then
		potion.Status = "No selected potion left in your inventory"
		return
	end

	potion.Running = true
	local ok, result = pcall(potion.Tick, stock)
	potion.Running = false

	if not ok then
		dependencies.log("Age potions: " .. tostring(result))
	end
end

local function stepStandaloneAgePotions(potion, readOption)
	if not readOption("AutoAgePotions", false) or readOption("AutoFarm", false) then
		return
	end

	potion.Run()
end

local function findAgePotionPet(potion, pets, equipped, stock, noWaste, dependencies)
	local best

	for unique, pet in pairs(pets) do
		local entry = dependencies.getItem("pets", pet.id)

		if not entry or entry.progression_locked or equipped[unique] then
			continue
		end

		local step = potion.Step(pet, stock, noWaste)

		if step and (not best or step.waste < best.step.waste or step.waste == best.step.waste and step.need < best.step.need) then
			best = { unique = unique, pet = pet, step = step }
		end
	end

	return best
end

local function feedEquippedAgePotion(potion, pet, wrapper, step, dependencies)
	local name = dependencies.label("pets", pet.id)
	local actions = dependencies.modules.PetActions
	local ok, allowed = dependencies.safeCall(actions and actions.can_feed_pet, wrapper)

	if ok and not allowed then
		potion.Status = "Waiting for " .. name .. " to be free"
		return
	end

	potion.Status = string.format("Feeding %d %s to %s", step.n, step.s.name, name)
	local consumed = potion.Feed(wrapper, step)

	if consumed > 0 then
		dependencies.stats.Potions += consumed
		dependencies.log(string.format("Fed %d %s to %s", consumed, step.s.name, name))
		return
	end

	potion.Failed[wrapper.pet_unique] = dependencies.clock() + 30
	dependencies.log(string.format("%s did not drink the %s, retrying in 30s", name, step.s.name))
end

local function tickAgePotions(potion, stock, dependencies)
	local noWaste = dependencies.readOption("AgePotionNoWaste", true) and dependencies.readOption("AutoFarm", false)
	local pets = dependencies.inventory("pets")
	local wrappers, equipped = {}, {}

	for _, wrapper in ipairs(dependencies.wrappers()) do
		if pets[wrapper.pet_unique] then
			table.insert(wrappers, wrapper)
			equipped[wrapper.pet_unique] = true
		end
	end

	for _, wrapper in ipairs(wrappers) do
		local pet = pets[wrapper.pet_unique]

		if (potion.Failed[wrapper.pet_unique] or 0) >= dependencies.clock() then
			continue
		end

		local step = potion.Step(pet, stock, noWaste)

		if not step then
			continue
		end

		feedEquippedAgePotion(potion, pet, wrapper, step, dependencies)
		return
	end

	local unavailableStatus

	if #wrappers > 0 then
		local wrapper = wrappers[1]
		local pet = pets[wrapper.pet_unique]
		local name = dependencies.label("pets", pet.id)
		local age = tonumber(pet.properties and pet.properties.age) or 0

		if age >= 6 then
			unavailableStatus = name .. " is Full Grown"
		elseif potion.Takes(pet) then
			if (potion.Failed[wrapper.pet_unique] or 0) >= dependencies.clock() then
				potion.Status = "Retrying " .. name .. " soon"
			else
				potion.Status = name .. " gets the last XP from quests"
			end

			return
		else
			unavailableStatus = name .. " cannot drink age potions"
		end
	end

	if dependencies.readOption("AgePotionTarget", "Equipped Pet") ~= "Any Pet" then
		potion.Status = unavailableStatus or "Equip a pet to use your potions"
		return
	end

	if #wrappers > 0 then
		local pet = pets[wrappers[1].pet_unique]
		local entry = dependencies.getItem("pets", pet.id)

		if entry and entry.is_egg then
			potion.Status = "Waiting for the egg to hatch"
			return
		end
	end

	if dependencies.clock() < potion.ScanAt then
		return
	end

	local best = findAgePotionPet(potion, pets, equipped, stock, noWaste, dependencies)

	if not best then
		potion.ScanAt = dependencies.clock() + 30
		potion.Status = "No other pet can use your potions"
		return
	end

	potion.Status = "Equipping " .. dependencies.label("pets", best.pet.id)
	dependencies.equip(best.unique, " to use age potions")
end

local function createAgePotionController(dependencies)
	local potion = { ScanAt = 0, Status = "Off", Failed = {} }
	local context = table.clone(dependencies)
	context.potion = potion

	potion.Kinds = function() return getAgePotionKinds(context) end
	potion.Stock = function() return collectAgePotionStock(context) end
	potion.Describe = function() return describeAgePotions(context) end
	potion.Takes = function(pet) return canPetTakeAgePotion(pet, context.getItem) end
	potion.Needed = function(pet) return getPetAgeXpNeeded(pet, context) end
	potion.Plan = planAgePotions
	potion.Step = function(pet, stock, noWaste) return selectAgePotionStep(pet, stock, noWaste, potion) end
	potion.Feed = function(pet, step) return feedAgePotions(pet, step, context) end
	potion.Tick = function(stock) return tickAgePotions(potion, stock, context) end
	potion.Run = function() return runAgePotions(potion, context) end

	return potion
end

local function chooseNextFarmPet(excluded, dependencies)
	local preferEggs = dependencies.readOption("PetMode", "Keep Equipped") == "Eggs First"
	local best, bestScore

	for unique, pet in pairs(dependencies.inventory("pets")) do
		local entry = dependencies.getItem("pets", pet.id)
		local properties = pet.properties or {}
		local age = tonumber(properties.age) or 0

		if entry and unique ~= excluded and not entry.is_doll and not entry.progression_locked and not entry.temporary then
			if preferEggs and entry.is_egg or not entry.is_egg and age < 6 then
				local score = (if entry.is_egg then 10 else age) * 100000 + (tonumber(properties.xp) or 0)

				if not bestScore or score > bestScore then
					best, bestScore = unique, score
				end
			end
		end
	end

	return best
end

local function selectFarmPet(dependencies)
	local pets = dependencies.inventory("pets")

	if not pets then
		error("attempt to call a nil value", 0)
	end

	local mode = dependencies.readOption("PetMode", "Keep Equipped")

	if mode == "Eggs First" then
		for unique, pet in pairs(pets) do
			local entry = dependencies.getItem("pets", pet.id)

			if entry and entry.is_egg then
				return unique
			end
		end
	end

	for _, unique in ipairs(dependencies.getData("last_equipped_pets") or {}) do
		if pets[unique] then
			return unique
		end
	end

	local best, bestAge

	for unique, pet in pairs(pets) do
		local entry = dependencies.getItem("pets", pet.id)

		if entry and not entry.is_doll and not entry.progression_locked and not entry.temporary then
			local age = pet.properties and pet.properties.age or 0

			if not bestAge or age < bestAge then
				best, bestAge = unique, age
			end
		end
	end

	return best
end

local function prepareFarmPets(dependencies)
	local wrappers = dependencies.wrappers()
	local mode = dependencies.readOption("PetMode", "Keep Equipped")
	local autoAge = dependencies.readOption("AutoAgeUp", false)
	local current = wrappers[1]

	if autoAge and current then
		local pet = dependencies.inventory("pets")[current.pet_unique]
		local age = tonumber(pet and pet.properties and pet.properties.age) or 0
		local entry = dependencies.getItem("pets", current.pet_id)

		if not (entry and entry.is_egg) and age >= 6 then
			local nextPet = dependencies.nextPet(current.pet_unique)

			if nextPet then
				return dependencies.equipPet(nextPet, " to age it up")
			end
		end
	end

	if #wrappers > 0 then
		if mode == "Eggs First" then
			local entry = dependencies.getItem("pets", current.pet_id)

			if not (entry and entry.is_egg) then
				for unique, pet in pairs(dependencies.inventory("pets")) do
					local candidate = dependencies.getItem("pets", pet.id)

					if candidate and candidate.is_egg and unique ~= current.pet_unique then
						return dependencies.equipPet(unique, " to hatch it")
					end
				end
			end
		end

		return wrappers
	end

	local selected = dependencies.selectPet()

	if selected then
		return dependencies.equipPet(selected, "")
	end

	return dependencies.wrappers()
end

local function unloadHub(state, dependencies)
	if not state.Running then
		return
	end

	state.Running = false
	pcall(dependencies.walker.Stop)


	for _, connection in ipairs(state.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	pcall(dependencies.blackScreen, false)
	pcall(dependencies.runService.Set3dRenderingEnabled, dependencies.runService, true)

	if dependencies.library and not dependencies.library.Unloaded then
		pcall(function()
			dependencies.library:Destroy()
		end)
	end

	if dependencies.getEnvironment().AxisAdoptMe == state then
		dependencies.getEnvironment().AxisAdoptMe = nil
	end
end

local function initializeHubSession(game, getEnvironment)
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	local services = {
		Players = game:GetService("Players"),
		ReplicatedStorage = game:GetService("ReplicatedStorage"),
		RunService = game:GetService("RunService"),
		HttpService = game:GetService("HttpService"),
		VirtualUser = game:GetService("VirtualUser"),
		VirtualInputManager = game:GetService("VirtualInputManager"),
		GuiService = game:GetService("GuiService"),
		CollectionService = game:GetService("CollectionService"),
	}
	local player = services.Players.LocalPlayer
	local state = { Running = true, Connections = {}, Log = "Loading..." }
	getEnvironment().AxisAdoptMe = state
	local token = services.HttpService:GenerateGUID(false)
	getEnvironment().AxisAdoptMeSession = token
	return state, token, player, services
end

local function loadCoreModules(replicatedStorage, modules, requireModule)
	local framework = requireModule(replicatedStorage:WaitForChild("Fsys"))
	modules.load = framework.load
	modules.ClientData = modules.load("ClientData")
	modules.Interiors = modules.load("InteriorsM")
	modules.UI = modules.load("UIManager")
	modules.Minigames = modules.load("MinigameClientManager")
	modules.LiveOpsTime = modules.load("LiveOpsTime")
	modules.FurnitureDB = modules.load("FurnitureDB")
	modules.InventoryDB = modules.load("InventoryDB")
end

local function loadGameModules(replicatedStorage, requireModule)
	local modules = {}
	pcall(loadCoreModules, replicatedStorage, modules, requireModule)
	pcall(function()
		local ailments = replicatedStorage.new.modules.Ailments
		modules.AilmentsDB = requireModule(ailments.AilmentsDB)
		modules.AilmentsClient = requireModule(ailments.AilmentsClient)
	end)
	pcall(function()
		modules.Dailies = requireModule(replicatedStorage.new.modules.Dailies.DailiesNetService)
	end)
	pcall(function()
		modules.ForSale = requireModule(replicatedStorage.new.modules.ForSaleManager)
	end)
	pcall(function()
		modules.AltCurrency = modules.load("AltCurrencyData")
	end)

	local additional = {
		PotionDB = "PetPotionEffectsDB",
		KindDB = "KindDB",
		PetProgressionDB = "PetProgressionDB",
		PetActions = "PetActions",
		Locks = "BackpackLockTracker",
		PetObjectType = "AdoptMeEnums/PetEntities/PetObjectCreatorType",
	}

	for key, name in pairs(additional) do
		local ok, value = pcall(function()
			return modules.load(name)
		end)

		if ok then
			modules[key] = value
		end
	end

	return modules
end

local function initializeHubRuntime(game, getEnvironment, requireModule)
	local state, token, player, services = initializeHubSession(game, getEnvironment)
	local remotes = services.ReplicatedStorage:WaitForChild("API")
	local modules = loadGameModules(services.ReplicatedStorage, requireModule)
	return {
		state = state,
		token = token,
		player = player,
		services = services,
		remotes = remotes,
		modules = modules,
	}
end

local function createFarmController(dependencies)
	local modules = dependencies.modules
	local player = dependencies.player
	local farm = dependencies.farm or createFarmState()
	local readOptionValue = dependencies.readOption
	local stats = dependencies.stats or runtimeHelpers.createHubStats(os.time())

	local function safeCall(callback, ...)
		return safeIdentityCall(dependencies.getIdentity, dependencies.setIdentity, callback, ...)
	end

	local moveOffset = dependencies.geometry.Vector3.new(0, 3, 0)
	local zeroVelocity = dependencies.geometry.Vector3.new(0, 0, 0)

	local function moveTo(position)
		moveToPosition(position, {
			getCharacterParts = function() return getCharacterParts(player) end,
			createCFrame = dependencies.geometry.CFrame.new,
			offset = moveOffset,
			zero = zeroVelocity,
		})
	end

	local function getLocation()
		return getCurrentLocation(modules)
	end

	local function locationName()
		return getLocationName(getLocation)
	end

	local function isHome()
		return isOwnHome(getLocation, player)
	end

	local function travel(destination, door, options)
		return travelToInterior(destination, door, options, {
			locationName = locationName,
			modules = modules,
			safeCall = safeCall,
			clock = dependencies.clock,
			wait = dependencies.wait,
			log = dependencies.log,
		})
	end

	local function returnHome()
		return goHome(isHome, travel, player)
	end

	local function getData(key)
		return getStateValue(function()
			return getPlayerState(modules, player)
		end, key)
	end

	local function ailments(subject)
		return getSubjectAilments({
			getData = getData,
			petAilments = function(key)
				return getPetAilments(getData, key)
			end,
		}, subject)
	end

	local function subjects()
		return collectFarmSubjects({
			wrappers = function() return getPetWrappers(getData) end,
			label = function(category, id)
				return getItemLabel(function(...) return getCatalogItem(modules, ...) end, category, id)
			end,
			image = function(id)
				return getPetImage(function(...) return getCatalogItem(modules, ...) end, id)
			end,
			readOption = readOptionValue,
			getData = getData,
			player = player,
		})
	end

	local function inMinigame()
		return isInMinigame(modules)
	end

	local function lookupRemote(name)
		return findRemote(dependencies.remoteFolder, name)
	end

	local function callRemote(name, ...)
		return invokeRemote(lookupRemote, name, ...)
	end

	local function sendRemote(name, ...)
		return fireRemote(lookupRemote, name, ...)
	end

	local function listFurniture()
		return listHouseFurniture(getData, function(id) return getFurnitureEntry(modules, id) end, dependencies.workspace)
	end

	local function furnitureFor(kind, baby, supplied)
		return findFarmFurniture(kind, baby, supplied, { predicates = FARM_FURNITURE_PREDICATES, list = listFurniture })
	end

	local function missingFurniture()
		return findMissingFarmFurniture(FARM_FURNITURE_REQUIREMENTS, { list = listFurniture, find = furnitureFor })
	end

	local placementOffsets
	local function findPosition(reserved, position)
		if dependencies.findHousePosition then
			return dependencies.findHousePosition(reserved, position)
		end

		local vector = dependencies.geometry.Vector3.new
		if not placementOffsets then
			placementOffsets = {
				vector(6, 0, 0), vector(-6, 0, 0), vector(0, 0, 6), vector(0, 0, -6),
				vector(9, 0, 9), vector(-9, 0, -9), vector(9, 0, -9), vector(-9, 0, 9),
			}
		end

		return findHousePosition(reserved, position, {
			listFurniture = listFurniture,
			newRaycastParams = dependencies.newRaycastParams or RaycastParams.new,
			includeFilter = dependencies.includeFilter or Enum.RaycastFilterType.Include,
			workspace = dependencies.workspace,
			offsets = placementOffsets,
			vector = vector,
			horizontal = function(value) return vector(value.X, 0, value.Z) end,
			cframe = dependencies.geometry.CFrame.new,
		})
	end

	dependencies.state.BuildHouse = function(automatic)
		return buildFarmHouse(automatic, {
			isHome = isHome,
			goHome = returnHome,
			notify = dependencies.notify,
			missingFurniture = missingFurniture,
			getData = getData,
			listFurniture = listFurniture,
			modules = modules,
			typeOf = dependencies.typeOf or typeof,
			findPosition = findPosition,
			remote = callRemote,
			log = dependencies.log,
			wait = dependencies.wait,
		})
	end

	local function closeFocus()
		closePetFocus({
			isAppVisible = function(name) return isAppVisible(modules, name) end,
			safeCall = safeCall,
			modules = modules,
			wait = dependencies.wait,
		})
	end

	local function releaseBaby()
		releaseBabySeat(sendRemote, dependencies.wait)
	end

	local function waitForQuest(actor, questKind, timeout, stallTimeout)
		return waitForFarmQuest(actor, questKind, timeout, stallTimeout, {
			clock = dependencies.clock,
			isActive = dependencies.isActive,
			readOption = readOptionValue,
			state = dependencies.state,
			ailments = ailments,
			isInMinigame = inMinigame,
			wait = dependencies.wait,
		})
	end

	local walker = dependencies.walker
	local function getWalker()
		if walker then
			return walker
		end

		walker = createFarmWalker({
			isActive = dependencies.isActive,
			readOption = readOptionValue,
			state = dependencies.state,
			modules = modules,
			isInMinigame = inMinigame,
			getCharacterParts = function() return getCharacterParts(player) end,
			locationName = locationName,
			zero = zeroVelocity,
			clock = dependencies.clock,
			spawn = dependencies.spawn,
			vector = dependencies.geometry.Vector3.new,
			cframe = dependencies.geometry.CFrame.new,
			lookAt = dependencies.geometry.CFrame.lookAt,
			newPart = dependencies.newPart,
			platformMaterial = dependencies.platformMaterial,
			platformColor = dependencies.platformColor,
			workspace = dependencies.workspace,
			heartbeat = dependencies.heartbeat,
		})
		return walker
	end

	local function walkUntilQuest(actor, kind, timeout, air, radius, speed)
		return walkUntil(actor, kind, timeout, air, radius, speed, {
			walker = getWalker(),
			clock = dependencies.clock,
			ailments = ailments,
			wait = dependencies.wait,
		})
	end

	local handlers = table.clone(dependencies.handlers)
	handlers.home = function(subject, kind)
		return performHomeQuest(subject, kind, {
			feedBaby = function(actor, questKind)
				return feedBaby(actor, questKind, {
					findFood = function(foodKind)
						return findBabyFood(foodKind, {
							inventory = function(category) return getInventoryCategory(getData, category) end,
							getItem = function(...) return getCatalogItem(modules, ...) end,
						})
					end,
					readOption = readOptionValue,
					getItem = function(...) return getCatalogItem(modules, ...) end,
					getData = getData,
					remote = callRemote,
					wait = dependencies.wait,
					ailments = ailments,
					equip = function(unique) return equipInventoryItem(unique, callRemote) end,
				})
			end,
			goHome = returnHome,
			closePetFocus = closeFocus,
			remote = callRemote,
			furniture = furnitureFor,
			ailments = ailments,
			useFurniture = function(item, character)
				return useFarmFurniture(item, character, { spawn = dependencies.spawn, remote = callRemote, player = player })
			end,
			waitForQuest = waitForQuest,
			releaseBaby = releaseBaby,
			player = player,
		})
	end

	handlers.interior = function(subject, kind)
		return performInteriorQuest(subject, kind, {
			travel = travel,
			heal = function(actor)
				return healSubject(actor, {
					findInteriorFurniture = function(interior, furnitureKind)
						return findInteriorFurniture(dependencies.workspace, interior, furnitureKind)
					end,
					moveTo = moveTo,
					remote = callRemote,
					player = player,
					waitForQuest = waitForQuest,
					clock = dependencies.clock,
					wait = dependencies.wait,
					spawn = dependencies.spawn,
				})
			end,
			getLocation = getLocation,
			moveTo = moveTo,
			waitForQuest = waitForQuest,
		})
	end

	handlers.mainmap = function(subject, kind)
		return performMainMapQuest(subject, kind, {
			goMainMap = function() return goMainMap(locationName, travel) end,
			workspace = dependencies.workspace,
			moveTo = moveTo,
			waitForQuest = waitForQuest,
		})
	end

	handlers.weather = function(subject, kind)
		return performWeatherQuest(subject, kind, {
			goMainMap = function() return goMainMap(locationName, travel) end,
			workspace = dependencies.workspace,
			getCharacterParts = function() return getCharacterParts(player) end,
			moveTo = moveTo,
			waitForQuest = waitForQuest,
		})
	end

	handlers.play = function(subject, kind)
		local function inventory(category)
			return getInventoryCategory(getData, category)
		end

		return performPlayQuest(subject, kind, {
			goHome = returnHome,
			inventory = inventory,
			findItems = function(questKind, category)
				return findQuestItems(questKind, category, {
					modules = modules,
					inventory = inventory,
					getItem = function(...) return getCatalogItem(modules, ...) end,
					safeCall = safeCall,
				})
			end,
			ailments = ailments,
			equip = function(unique) return equipInventoryItem(unique, callRemote) end,
			wait = dependencies.wait,
			remote = callRemote,
		})
	end

	handlers.pet_me = function(subject, kind)
		return performPetMeQuest(subject, kind, {
			goHome = returnHome,
			closePetFocus = closeFocus,
			remote = callRemote,
			safeCall = safeCall,
			modules = modules,
			clock = dependencies.clock,
			wait = dependencies.wait,
			spawn = dependencies.spawn,
			workspace = dependencies.workspace,
			vector2 = dependencies.geometry.Vector2.new,
			ailments = ailments,
		})
	end

	handlers.mystery = function(subject, kind)
		return performMysteryQuest(subject, kind, {
			goHome = returnHome,
			safeCall = safeCall,
			modules = modules,
			fireRemote = sendRemote,
			wait = dependencies.wait,
			ailments = ailments,
		})
	end

	handlers.ride = function(subject, kind)
		return performRideQuest(subject, kind, {
			goHome = returnHome,
			closePetFocus = closeFocus,
			releaseBaby = releaseBaby,
			findStroller = function()
				return findStroller({
					inventory = function(category) return getInventoryCategory(getData, category) end,
					modules = modules,
					isForSale = function(id) return isItemForSale(id, { modules = modules, safeCall = safeCall }) end,
					getData = getData,
					remote = callRemote,
					wait = dependencies.wait,
				})
			end,
			equip = function(unique) return equipInventoryItem(unique, callRemote) end,
			findStrollerModel = function() return findStrollerSeat(player, dependencies.collectionService) end,
			remote = callRemote,
			player = player,
			walker = { Until = walkUntilQuest },
			clock = dependencies.clock,
			wait = dependencies.wait,
		})
	end

	handlers.walk = function(subject, kind)
		return performWalkQuest(subject, kind, {
			goHome = returnHome,
			releaseBaby = releaseBaby,
			walk = function(actor, questKind, timeout)
				return walkWithPet(actor, questKind, timeout, {
					getCharacterParts = function() return getCharacterParts(player) end,
					closePetFocus = closeFocus,
					remote = callRemote,
					wait = dependencies.wait,
					walker = { Until = walkUntilQuest },
					fireRemote = sendRemote,
				})
			end,
		})
	end

	local function quests()
		return collectFarmQuests({
			farm = farm,
			subjects = subjects,
			ailments = ailments,
			ignored = { at_work = true, party_zone = true },
			readOption = readOptionValue,
			handler = function(kind) return findFarmQuestHandler(handlers, kind) end,
			isHome = isHome,
			location = locationName,
			estimate = function(kind) return estimateFarmQuest(farm, kind) end,
			clock = dependencies.clock,
		})
	end

	local function inventory(category)
		return getInventoryCategory(getData, category)
	end

	local function item(category, id)
		return getCatalogItem(modules, category, id)
	end

	local function wrappers()
		return getPetWrappers(getData)
	end

	local function equipPet(unique, reason)
		return equipFarmPet(unique, reason, {
			equip = function(petUnique) return equipInventoryItem(petUnique, callRemote) end,
			clock = dependencies.clock,
			wait = dependencies.wait,
			wrappers = wrappers,
			inventory = inventory,
			label = function(category, id) return getItemLabel(item, category, id) end,
			log = dependencies.log,
		})
	end

	local function preparePets()
		return prepareFarmPets({
			wrappers = wrappers,
			readOption = readOptionValue,
			inventory = inventory,
			getItem = item,
			nextPet = function(excluded)
				return chooseNextFarmPet(excluded, { readOption = readOptionValue, inventory = inventory, getItem = item })
			end,
			selectPet = function()
				return selectFarmPet({ inventory = inventory, readOption = readOptionValue, getItem = item, getData = getData })
			end,
			equipPet = equipPet,
		})
	end

	local potion = dependencies.potion or dependencies.state.Potion

	if not potion then
		potion = createAgePotionController({
			state = dependencies.state,
			modules = modules,
			stats = stats,
			readOption = readOptionValue,
			inventory = inventory,
			wrappers = wrappers,
			getItem = item,
			getUpvalue = dependencies.getUpvalue,
			label = function(category, id) return getItemLabel(item, category, id) end,
			safeCall = safeCall,
			busy = inMinigame,
			remote = callRemote,
			equip = equipPet,
			clock = dependencies.clock,
			wait = dependencies.wait,
			isActive = dependencies.isActive,
			log = dependencies.log,
		})
		dependencies.state.Potion = potion
	end

	local function step()
		stepFarm({
			farm = farm,
			state = dependencies.state,
			readOption = readOptionValue,
			isInMinigame = inMinigame,
			getData = getData,
			remote = callRemote,
			wait = dependencies.wait,
			prepare = dependencies.prepare or preparePets,
			potion = potion,
			pets = subjects,
			isHome = isHome,
			clock = dependencies.clock,
			quests = quests,
			goHome = returnHome,
			describeKind = dependencies.describeKind,
			log = dependencies.log,
		})
	end

	local function stepDailies()
		claimDailyRewards({
			readOption = readOptionValue,
			modules = modules,
			getData = getData,
			safeCall = safeCall,
		})
	end

	local drops = { Tried = {} }
	drops.Pending = function()
		return getPendingPetDrops(getData)
	end
	drops.WalkOnto = function()
		return walkOntoPetDrops({
			getCharacterParts = function() return getCharacterParts(player) end,
			workspace = dependencies.workspace,
			zero = zeroVelocity,
			offset = dependencies.geometry.Vector3.new(0, 2.5, 0),
			cframe = dependencies.geometry.CFrame.new,
			wait = dependencies.wait,
		})
	end

	local function stepDrops()
		claimPetDrops(drops, {
			readOption = readOptionValue,
			clock = dependencies.clock,
			fire = sendRemote,
			walker = getWalker(),
			busy = inMinigame,
			modules = modules,
		})
	end

	local popup = createPopupController({
		player = player,
		state = dependencies.state,
		modules = modules,
		game = dependencies.game,
		guiService = dependencies.guiService,
		input = dependencies.virtualInputManager,
		getBlackScreenHandle = dependencies.getBlackScreenHandle,
		blackScreenHandle = dependencies.blackScreenHandle,
		isVisible = function(name) return isAppVisible(modules, name) end,
		readOption = readOptionValue,
		safeCall = safeCall,
		fire = sendRemote,
		wait = dependencies.wait,
		clock = dependencies.clock,
		log = dependencies.log,
	})

	local shop = createShopController({
		state = dependencies.state,
		modules = modules,
		stats = stats,
		readOption = readOptionValue,
		getData = getData,
		getItem = item,
		inventory = inventory,
		forSale = function(kind) return isItemForSale(kind, { modules = modules, safeCall = safeCall }) end,
		busy = inMinigame,
		remote = callRemote,
		webhook = dependencies.webhook,
		clock = dependencies.clock,
		wait = dependencies.wait,
		log = dependencies.log,
	})

	local display = { Shown = {} }
	local tradeDependencies = {
		state = dependencies.state,
		getInventory = inventory,
		travel = travel,
		getData = getData,
		fireRemote = sendRemote,
		getLocation = getLocation,
		moveTo = moveTo,
		notify = dependencies.notify,
		getCatalogItem = item,
		webhook = dependencies.webhook,
		goHome = returnHome,
		updateStatus = function(widget, text) updateHubDisplay(display, widget, text) end,
		clock = dependencies.clock,
		wait = dependencies.wait,
	}
	local trade = createTradeLicenseController(tradeDependencies)
	local function bindInterface(shell)
		display.HouseStatus = shell.house.status
		display.LicenseStatus = shell.trade.status
		tradeDependencies.status = display.LicenseStatus
	end

	local function stepHouseStatus()
		updateHouseAndLicenseStatus({
			isHome = isHome,
			missingFurniture = missingFurniture,
			update = tradeDependencies.updateStatus,
			houseStatus = display.HouseStatus,
			licenseStatus = display.LicenseStatus,
			trade = trade,
		})
	end


	return {
		farm = farm,
		potion = potion,
		drops = drops,
		popup = popup,
		shop = shop,
		webhook = dependencies.webhook,
		trade = trade,
		bindInterface = bindInterface,
		stepHouseStatus = stepHouseStatus,
		step = step,
		stepPotions = function() stepStandaloneAgePotions(potion, readOptionValue) end,
		stepDailies = stepDailies,
		stepDrops = stepDrops,
		stepPopups = function() handlePopups(popup, readOptionValue) end,
		stepShop = shop.buy,
		stepGifts = shop.open,
		subjects = subjects,
		ailments = ailments,
		quests = quests,
		getData = getData,
		inventory = inventory,
		getItem = item,
		wrappers = wrappers,
		goHome = returnHome,
		getLocation = getLocation,
		getWalker = getWalker,
		stopWalker = function() if walker then walker.Stop() end end,
	}
end

local function isSessionActive(state, dependencies)
	return state.Running and dependencies.getEnvironment().AxisAdoptMeSession == dependencies.token
end

local function runLoop(dependencies)
	while dependencies.isAlive() do
		if dependencies.beforeEach then
			pcall(dependencies.beforeEach)
		end

		local ok, raised = pcall(dependencies.callback)

		if not ok then
			dependencies.log("Error: " .. tostring(raised))
		end

		local interval = dependencies.interval

		if type(interval) == "function" then
			interval = interval()
		end

		dependencies.wait(interval)
	end
end

local function startLoop(dependencies)
	dependencies.spawn(function()
		runLoop(dependencies)
	end)
end

function runtimeHelpers.startHubTasks(tasks, schedule)
	schedule(tasks.webhook, 1)
	schedule(tasks.potions, 2)
	schedule(tasks.popups, 1)
	schedule(tasks.trackQuests, 1)
	schedule(tasks.trackPets, 5)
	schedule(tasks.farm, 0.5)
	schedule(tasks.dailies, 30)
	schedule(tasks.drops, 2)
	schedule(tasks.shop, 3)
	schedule(tasks.gifts, 2)
	schedule(tasks.status, 1)
	schedule(tasks.houseStatus, 5)
	schedule(tasks.summary, 30)
	schedule(tasks.autosave, 5)
end

function runtimeHelpers.getWebhookUrl(readOption)
	local url = tostring(readOption("_WebhookURL", "")):gsub("%s", "")
	local host = url:match("^https://([%w%.]+)/api/webhooks/%d+/[%w_%-]+$")
	if host == "discord.com" or host == "discordapp.com" or host == "ptb.discord.com" or host == "canary.discord.com" then
		return url
	end
end

function runtimeHelpers.isWebhookEventEnabled(event, readOption)
	local selected = collectSelection(readOption("WebhookEvents", {}))
	return selected[event] == true
end

function runtimeHelpers.createWebhookEmbed(title, description, color, fields, image, dependencies)
	local name = if dependencies.readOption("WebhookHideName", false) then "Hidden" else dependencies.player.Name
	return {
		title = title,
		description = description,
		color = color or 15903035,
		fields = fields or {},
		timestamp = dependencies.dateTime.now():ToIsoDate(),
		footer = { text = "Axis | Adopt Me! | " .. name },
		_image = dependencies.gameImage and dependencies.gameImage() or image,
	}
end

function runtimeHelpers.resolveWebhookEmbed(embed, dependencies)
	local image = embed._image
	embed._image = nil
	if image then
		local url = dependencies.webhook.Image(image)
		if url then
			embed.thumbnail = { url = url }
		end
	end

	if not dependencies.readOption("WebhookHideName", false) then
		local avatar = dependencies.webhook.Avatar()
		if avatar then
			embed.author = { name = dependencies.player.Name, icon_url = avatar }
		end
	end

	return embed
end

function runtimeHelpers.getWebhookAssetImages(webhook, assetIds, dependencies)
	if not dependencies.request then
		return webhook.Cache
	end

	local missing = {}
	for _, asset in ipairs(assetIds) do
		local id = tonumber(tostring(asset):match("%d+"))
		if id and webhook.Cache[id] == nil then
			table.insert(missing, id)
		end
	end

	if #missing > 0 then
		local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. table.concat(missing, ",") .. "&returnPolicy=PlaceHolder&size=420x420&format=Png&isCircular=false"
		local ok, response = pcall(dependencies.request, { Url = url, Method = "GET" })
		if ok and response and response.StatusCode == 200 then
			local decoded, body = pcall(dependencies.httpService.JSONDecode, dependencies.httpService, response.Body)
			if decoded and type(body) == "table" and body.data then
				for _, item in ipairs(body.data) do
					webhook.Cache[item.targetId] = item.state == "Completed" and item.imageUrl or false
				end
			end
		end

		for _, id in ipairs(missing) do
			if webhook.Cache[id] == nil then
				webhook.Cache[id] = false
			end
		end
	end

	return webhook.Cache
end

function runtimeHelpers.getWebhookImage(webhook, asset)
	local id = tonumber(tostring(asset or ""):match("%d+"))
	if not id then
		return nil
	end

	return webhook.AssetImages({ id })[id]
end

function runtimeHelpers.getWebhookAvatar(webhook, dependencies)
	if webhook.Cache.avatar ~= nil then
		return webhook.Cache.avatar or nil
	end

	if not dependencies.request then
		return nil
	end

	local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. dependencies.player.UserId .. "&size=150x150&format=Png&isCircular=false"
	local ok, response = pcall(dependencies.request, { Url = url, Method = "GET" })
	local avatar
	if ok and response and response.StatusCode == 200 then
		local decoded, body = pcall(dependencies.httpService.JSONDecode, dependencies.httpService, response.Body)
		if decoded and type(body) == "table" and body.data and body.data[1] then
			avatar = body.data[1].imageUrl
		end
	end

	webhook.Cache.avatar = avatar or false
	return avatar
end

function runtimeHelpers.postWebhook(payload, dependencies)
	local url = dependencies.getUrl()
	if not url then
		return false, "Invalid webhook URL"
	end

	if not dependencies.request then
		return false, "Your executor has no request function"
	end

	local options = {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = dependencies.httpService:JSONEncode(payload),
	}
	local ok, response = pcall(dependencies.request, options)
	if not ok or not response then
		return false, "Request failed"
	end

	if response.StatusCode == 200 or response.StatusCode == 204 then
		return true
	end

	if response.StatusCode == 429 then
		local decoded, body = pcall(dependencies.httpService.JSONDecode, dependencies.httpService, response.Body)
		local delay = if decoded and type(body) == "table" then tonumber(body.retry_after) or 2 else 2
		return false, "rate", delay
	end

	return false, "HTTP " .. tostring(response.StatusCode)
end

function runtimeHelpers.enqueueWebhookEvent(webhook, event, embed, dependencies, force)
	if not force and (not dependencies.readOption("WebhookEnabled", false) or not dependencies.eventEnabled(event)) then
		return
	end

	if not dependencies.getUrl() then
		return
	end

	if #webhook.Queue >= 20 then
		table.remove(webhook.Queue, 1)
	end

	table.insert(webhook.Queue, { event = event, embed = embed })
end

function runtimeHelpers.flushWebhookQueue(webhook, dependencies)
	if #webhook.Queue == 0 or dependencies.clock() - webhook.LastSent < 2.5 then
		return
	end

	local embeds = {}
	for _ = 1, math.min(#webhook.Queue, 5) do
		local item = table.remove(webhook.Queue, 1)
		table.insert(embeds, dependencies.resolveEmbed(item.embed))
	end

	local payload = { username = "Axis", embeds = embeds }
	local userId = tostring(dependencies.readOption("_WebhookPing", "")):gsub("%D", "")
	if userId ~= "" then
		payload.content = "<@" .. userId .. ">"
		payload.allowed_mentions = { parse = {}, users = { userId } }
	end

	webhook.LastSent = dependencies.clock()
	local ok, raised = webhook.Post(payload)
	if ok then
		return
	end

	if raised == "rate" then
		for index = #embeds, 1, -1 do
			table.insert(webhook.Queue, 1, { embed = embeds[index] })
		end
		webhook.LastSent = dependencies.clock() + 2
		return
	end

	dependencies.log("Webhook: " .. tostring(raised))
end

function runtimeHelpers.createWebhookController(dependencies)
	local webhook = { Queue = {}, Cache = {}, LastSent = 0 }
	local function getUrl()
		return runtimeHelpers.getWebhookUrl(dependencies.readOption)
	end

	webhook.Post = function(payload)
		return runtimeHelpers.postWebhook(payload, { getUrl = getUrl, request = dependencies.request, httpService = dependencies.httpService })
	end
	webhook.AssetImages = function(assetIds)
		return runtimeHelpers.getWebhookAssetImages(webhook, assetIds, dependencies)
	end
	webhook.Image = function(asset)
		return runtimeHelpers.getWebhookImage(webhook, asset)
	end
	webhook.Avatar = function()
		return runtimeHelpers.getWebhookAvatar(webhook, dependencies)
	end
	webhook.Embed = function(title, description, color, fields, image)
		return runtimeHelpers.createWebhookEmbed(title, description, color, fields, image, dependencies)
	end
	webhook.Send = function(event, embed, force)
		return runtimeHelpers.enqueueWebhookEvent(webhook, event, embed, {
			readOption = dependencies.readOption,
			eventEnabled = function(name) return runtimeHelpers.isWebhookEventEnabled(name, dependencies.readOption) end,
			getUrl = getUrl,
		}, force)
	end
	webhook.step = function()
		return runtimeHelpers.flushWebhookQueue(webhook, {
			resolveEmbed = function(embed) return runtimeHelpers.resolveWebhookEmbed(embed, { webhook = webhook, readOption = dependencies.readOption, player = dependencies.player }) end,
			readOption = dependencies.readOption,
			clock = dependencies.clock,
			log = dependencies.log,
		})
	end

	return webhook
end

function runtimeHelpers.sendWebhookTest(dependencies)
	dependencies.spawn(function()
		if not dependencies.getUrl() then
			dependencies.notify("Enter a valid Discord webhook URL first")
			return
		end
		local fields = {
			{ name = "Bucks", value = dependencies.format(dependencies.getData("money")), inline = true },
		}
		local embed = dependencies.webhook.Embed("Webhook connected", "Notifications from Axis | Adopt Me! will appear here.", 5763719, fields, dependencies.gameImage())
		local ok, reason = dependencies.webhook.Post({ username = "Axis", embeds = { dependencies.resolve(embed) } })
		dependencies.notify(if ok then "Test message sent" else "Webhook failed: " .. tostring(reason))
	end)
end

function runtimeHelpers.notify(library, message, duration)
	pcall(function()
		library:Notify({ Title = "Axis", Content = message, Duration = duration or 4 })
	end)
end

function runtimeHelpers.createTrackingTasks(dependencies)
	local quests = { previous = {} }
	local ages = { previous = {} }
	local hatches = {}
	local summary = { last = dependencies.clock() }
	local ageNames = { "Newborn", "Junior", "Pre-Teen", "Teen", "Post-Teen", "Full Grown" }
	local common = {
		stats = dependencies.stats,
		webhook = dependencies.webhook,
		inventory = dependencies.inventory,
		catalog = dependencies.catalog,
		label = dependencies.label,
		image = dependencies.image,
		ageNames = ageNames,
	}
	local tasks = {}
	tasks.trackQuests = function()
		runtimeHelpers.trackCompletedQuests(quests, {
			subjects = dependencies.subjects,
			ailments = dependencies.ailments,
			stats = dependencies.stats,
			webhook = dependencies.webhook,
			describeKind = runtimeHelpers.describeQuestKind,
			format = dependencies.format,
			getData = dependencies.getData,
		})
	end
	tasks.trackPets = function()
        runtimeHelpers.trackPetAges(ages,common)
        runtimeHelpers.trackPetHatches(hatches,common)
	end
	tasks.summary = function()
		runtimeHelpers.sendFarmSummary(summary, dependencies)
	end
	tasks.status = function()
		local statusDependencies = table.clone(dependencies)
		statusDependencies.describeKind = runtimeHelpers.describeQuestKind
		statusDependencies.ageNames = ageNames
		runtimeHelpers.updateHubStatus(statusDependencies)
	end
	return tasks
end

function runtimeHelpers.createHubTaskCallbacks(controller, callbacks)
	local tasks = table.clone(callbacks)
	if controller.webhook and controller.webhook.step then
		tasks.webhook = controller.webhook.step
	end
	tasks.potions = controller.stepPotions
	tasks.popups = controller.stepPopups
	tasks.farm = controller.step
	tasks.dailies = controller.stepDailies
	tasks.drops = controller.stepDrops
	tasks.shop = controller.stepShop
	tasks.gifts = controller.stepGifts
	tasks.houseStatus = controller.stepHouseStatus
	return tasks
end

function runtimeHelpers.startHubTaskLoops(tasks, dependencies)
	runtimeHelpers.startHubTasks(tasks, function(callback, interval)
		startLoop({
			spawn = dependencies.spawn,
			isAlive = dependencies.isAlive,
			callback = callback,
			log = dependencies.log,
			wait = dependencies.wait,
			interval = interval,
		})
	end)
end

local function restoreConfig(manager, options, files)
	local config = files.load(CONFIG_DIRECTORY .. "/autosave.json")

	if config and config.Autosave ~= false then
		manager.Apply(config)
	end

	local private = files.load(CONFIG_DIRECTORY .. "/private.json")

	if private then
		for flag in pairs(PRIVATE_CONFIG_FLAGS) do
			if type(private[flag]) == "string" and options[flag] then
				pcall(options[flag].SetValue, options[flag], private[flag])
			end
		end
	end

	manager.Loading = false
end

function runtimeHelpers.createHubApplication(dependencies)
	local runtime, environment, library = dependencies.runtime, dependencies.environment, dependencies.library
	local state, player, services, modules = runtime.state, runtime.player, runtime.services, runtime.modules
	local geometry, workspace = dependencies.geometry, dependencies.workspace
	local options = library.Options
	state.Options = options
	local stats = runtimeHelpers.createHubStats(dependencies.time())
	local function read(flag, default) return readOption(options, flag, default) end
	local function getData(key) return getStateValue(function() return getPlayerState(modules, player) end, key) end
	local function inventory(category) return getInventoryCategory(getData, category) end
	local function item(category, id) return getCatalogItem(modules, category, id) end
	local function label(category, id) return getItemLabel(item, category, id) end
	local function image(id) return getPetImage(item, id) end
	local function isAlive() return isSessionActive(state, { getEnvironment = environment.getgenv, token = runtime.token }) end
	local function log(message) state.Log = dependencies.date("%H:%M:%S") .. "  " .. message end
	local function notify(message, duration) runtimeHelpers.notify(library, message, duration) end
	local function parts() return getCharacterParts(player) end
	local function location() return getCurrentLocation(modules) end
	local function gameTime() return runtimeHelpers.getGameTime(modules, workspace) end
	local function countdown(id) return runtimeHelpers.getMinigameCountdown(id, getData, gameTime) end
	local zero, up = geometry.Vector3.new(0, 0, 0), geometry.Vector3.new(0, 1, 0)
	local function raycastParams(filter)
		local params = dependencies.newRaycastParams()
		params.FilterType = filter
		return params
	end
	local webhookDependencies = {
		readOption = read, player = player, dateTime = dependencies.dateTime,
		request = environment.request, httpService = services.HttpService, clock = dependencies.clock, log = log,
	}
    local iconAsset
    local function gameImage()
        if not iconAsset then
            local ok,info=pcall(game:GetService("MarketplaceService").GetProductInfo,game:GetService("MarketplaceService"),game.PlaceId)
            if ok and info and tonumber(info.IconImageAssetId) and info.IconImageAssetId>0 then iconAsset=info.IconImageAssetId end
        end
        return iconAsset
    end
    webhookDependencies.gameImage=gameImage
	local webhook = runtimeHelpers.createWebhookController(webhookDependencies)
	local window, tabs = createHubWindow(library, geometry, function(value) state.Window = value end)
	local farm = createFarmController({
		modules = modules, player = player, geometry = geometry, state = state, stats = stats, handlers = {},
		readOption = read, isActive = isAlive, workspace = workspace, game = environment.game,
		remoteFolder = runtime.remotes, collectionService = services.CollectionService, guiService = services.GuiService,
		virtualInputManager = services.VirtualInputManager, getBlackScreenHandle = function() return state.BlackScreen end,
		getIdentity = environment.getthreadidentity, setIdentity = environment.setthreadidentity or environment.set_thread_identity or environment.setidentity,
		getUpvalue = environment.debug and environment.debug.getupvalue, describeKind = runtimeHelpers.describeQuestKind,
		clock = dependencies.clock, wait = dependencies.wait, spawn = dependencies.spawn, delay = dependencies.delay,
		heartbeat = services.RunService.Heartbeat, newPart = function() return dependencies.Instance.new("Part") end,
		platformMaterial = geometry.Enum.Material.SmoothPlastic, platformColor = dependencies.Color3.new(60 / 255, 60 / 255, 70 / 255),
		newRaycastParams = dependencies.newRaycastParams, includeFilter = geometry.Enum.RaycastFilterType.Include,
		webhook = webhook, notify = notify, log = log,
	})
	state.Stride = farm.getWalker()
	local config = createConfigManager({ options = options, environment = environment, httpService = services.HttpService })
	local configFiles = createConfigFiles(environment, services.HttpService)
	local potionKinds, potionDefaults = {}, {}
	for _, potion in ipairs(farm.potion.Kinds()) do
		table.insert(potionKinds, potion.name)
		if not potion.tradable then table.insert(potionDefaults, potion.name) end
	end
	state.Unload = function()
		unloadHub(state, {
			walker = state.Stride, runService = services.RunService, library = library,
			blackScreen = function(enabled) runtimeHelpers.setBlackScreen(state, enabled, dependencies) end,
			getEnvironment = environment.getgenv,
		})
	end
	local function sendTest()
		runtimeHelpers.sendWebhookTest({
			spawn = dependencies.spawn, getUrl = function() return runtimeHelpers.getWebhookUrl(read) end,
			notify = notify, webhook = webhook, format = formatShopNumber, getData = getData,
			gameImage = gameImage,
			resolve = function(embed) return runtimeHelpers.resolveWebhookEmbed(embed, { webhook = webhook, readOption = read, player = player }) end,
		})
	end
	local display = { Shown = {} }
	local tasks = runtimeHelpers.createTrackingTasks({
		clock = dependencies.clock, time = dependencies.time, stats = stats, webhook = webhook, inventory = inventory,
		catalog = item, label = label, image = image, subjects = farm.subjects, ailments = farm.ailments, getData = getData,
		readOption = read, format = formatShopNumber, gameImage = gameImage,
		wrappers = farm.wrappers, farm = farm.farm, state = state, interface = display, potion = farm.potion,
		countdown = countdown,
		update = function(widget, value) updateHubDisplay(display, widget, value) end,
	})
	tasks.autosave = config.Autosave
	tasks = runtimeHelpers.createHubTaskCallbacks(farm, tasks)
	local function schedule(callback, interval)
		startLoop({ spawn = dependencies.spawn, isAlive = isAlive, callback = callback, log = log, wait = dependencies.wait, interval = interval })
	end
	schedule(tasks.webhook, 1)
	schedule(tasks.potions, 2)
	schedule(tasks.popups, 1)
	schedule(tasks.trackQuests, 1)
	schedule(tasks.trackPets, 5)
	schedule(tasks.farm, 0.5)
	schedule(tasks.dailies, 30)
	schedule(tasks.drops, 2)
	schedule(tasks.shop, 3)
	schedule(tasks.gifts, 2)
	local shell = createHubShell(library, geometry, potionKinds, potionDefaults, {
		window = window, tabs = tabs, spawn = dependencies.spawn, state = state, trade = farm.trade, getInventory = inventory, goHome = farm.goHome,
		eggChoices = farm.shop.eggChoices, giftChoices = farm.shop.giftChoices, themes = library.Themes,
		configNames = config.List(), callbacks = { sendTest = sendTest }, readOption = read, notify = notify,
		configFiles = configFiles, config = config, deleteFile = environment.delfile,
		setClipboard = environment.setclipboard or environment.toclipboard,
		bindPerformance = function()
			runtimeHelpers.bindPerformanceSettings(options, {
				state = state, player = player, Instance = dependencies.Instance, UDim2 = geometry.UDim2,
				Color3 = dependencies.Color3, Enum = geometry.Enum, runService = services.RunService, setfpscap = environment.setfpscap,
			})
		end,
	})
	farm.bindInterface(shell)
	display.FarmStatus, display.PotionStatus = shell.farm.status, shell.farm.potionStatus
	display.SyncMenuKey = function() runtimeHelpers.syncMenuKey(options, display, shell.window, dependencies.typeOf) end
	schedule(tasks.status, 1)
	schedule(tasks.houseStatus, 5)
	schedule(tasks.summary, 30)
	runtimeHelpers.connectHubSignal(state, player.Idled, function()
		runtimeHelpers.handleIdle(read, services.VirtualUser, geometry.Vector2.new)
	end)
	schedule(tasks.autosave, 5)
	restoreConfig(config, options, configFiles)
    for _,option in pairs(options)do option:OnChanged(function()config.Autosave()end)end
	display.SyncMenuKey()
	pcall(function() shell.window:SelectTab(1) end)
	log("Hub loaded")

	return { state = state, shell = shell, farm = farm, tasks = tasks, stats = stats }
end

function runtimeHelpers.cleanupPreviousSession(game, getEnvironment, getGui)
	for _, key in ipairs({ "AxisAdoptMe", "AxisAdoptMeAdoptMe" }) do
		local previous = getEnvironment()[key]
		if type(previous) == "table" and type(previous.Unload) == "function" then
			pcall(previous.Unload)
		end
		getEnvironment()[key] = nil
	end
	local roots = { game:GetService("CoreGui") }
	local ok, gui = pcall(getGui)
	if ok and gui then table.insert(roots, gui) end
	for _, root in ipairs(roots) do
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name == "AxisAdoptMe" then
				pcall(child.Destroy, child)
			end
		end
	end
end

function runtimeHelpers.launchHub()
	local environment = createEnvironment()
	local ok, result = pcall(function()
		runtimeHelpers.cleanupPreviousSession(environment.game, environment.getgenv, environment.gethui)
		local runtime = initializeHubRuntime(environment.game, environment.getgenv, environment.require)
        local chunk,raised=loadstring(game:HttpGet(UI_LIBRARY_URL),"Axis UI")
        if not chunk then error(raised,0)end
        local library=createAxisAdapter(chunk())
		return runtimeHelpers.createHubApplication({
			runtime = runtime, environment = environment, library = library, workspace = environment.workspace,
			geometry = { Vector2 = environment.Vector2, Vector3 = environment.Vector3, UDim2 = environment.UDim2, CFrame = environment.CFrame, Enum = environment.Enum },
			clock = environment.os.clock, time = environment.os.time, date = environment.os.date,
			spawn = environment.task.spawn, wait = environment.task.wait, delay = environment.task.delay,
			Instance = environment.Instance, Color3 = environment.Color3, newRaycastParams = environment.RaycastParams.new,
			typeOf = environment.typeof, dateTime = environment.DateTime,
		})
	end)
    if not ok then
        getgenv().AxisAdoptMeStartupError=tostring(result)
        return false,result
    end
    getgenv().AxisAdoptMeApp=result
    getgenv().AxisAdoptMeStartupError=nil
    return result
end

if game then
	runtimeHelpers.launchHub()
	return
end

return {
	uiLibraryUrl = UI_LIBRARY_URL,
	getMinigameCountdown = runtimeHelpers.getMinigameCountdown,
	describeQuestKind = runtimeHelpers.describeQuestKind,
	trackCompletedQuests = runtimeHelpers.trackCompletedQuests,
	trackPetAges = runtimeHelpers.trackPetAges,
	trackPetHatches = runtimeHelpers.trackPetHatches,
	sendFarmSummary = runtimeHelpers.sendFarmSummary,
	updateHubStatus = runtimeHelpers.updateHubStatus,
	createHubApplication = runtimeHelpers.createHubApplication,
	launchHub = runtimeHelpers.launchHub,
	cleanupPreviousSession = runtimeHelpers.cleanupPreviousSession,
	getMinigame = runtimeHelpers.getMinigame,
	connectHubSignal = runtimeHelpers.connectHubSignal,
	handleIdle = runtimeHelpers.handleIdle,
	setBlackScreen = runtimeHelpers.setBlackScreen,
	setRenderingDisabled = runtimeHelpers.setRenderingDisabled,
	setFrameRate = runtimeHelpers.setFrameRate,
	bindPerformanceSettings = runtimeHelpers.bindPerformanceSettings,
	syncMenuKey = runtimeHelpers.syncMenuKey,
	getGameTime = runtimeHelpers.getGameTime,
	createHubStats = runtimeHelpers.createHubStats,
	startHubTasks = runtimeHelpers.startHubTasks,
	getWebhookUrl = runtimeHelpers.getWebhookUrl,
	isWebhookEventEnabled = runtimeHelpers.isWebhookEventEnabled,
	createWebhookEmbed = runtimeHelpers.createWebhookEmbed,
	resolveWebhookEmbed = runtimeHelpers.resolveWebhookEmbed,
	getWebhookAssetImages = runtimeHelpers.getWebhookAssetImages,
	getWebhookImage = runtimeHelpers.getWebhookImage,
	getWebhookAvatar = runtimeHelpers.getWebhookAvatar,
	postWebhook = runtimeHelpers.postWebhook,
	enqueueWebhookEvent = runtimeHelpers.enqueueWebhookEvent,
	flushWebhookQueue = runtimeHelpers.flushWebhookQueue,
	createWebhookController = runtimeHelpers.createWebhookController,
	sendWebhookTest = runtimeHelpers.sendWebhookTest,
	notify = runtimeHelpers.notify,
	createTrackingTasks = runtimeHelpers.createTrackingTasks,
	createHubTaskCallbacks = runtimeHelpers.createHubTaskCallbacks,
	startHubTaskLoops = runtimeHelpers.startHubTaskLoops,
	hasTradeLicense = hasTradeLicense,
	updateHubDisplay = updateHubDisplay,
	updateHouseAndLicenseStatus = updateHouseAndLicenseStatus,
	takeTradeQuiz = takeTradeQuiz,
	runTradeLicense = runTradeLicense,
	createTradeLicenseController = createTradeLicenseController,
	createTradeLicenseInterface = createTradeLicenseInterface,
	createNotificationsInterface = createNotificationsInterface,
	createPerformanceInterface = createPerformanceInterface,
	createSettingsInterface = createSettingsInterface,
	saveNamedConfig = saveNamedConfig,
	loadNamedConfig = loadNamedConfig,
	deleteNamedConfig = deleteNamedConfig,
	createShopInterface = createShopInterface,
	createHouseInterface = createHouseInterface,
	createHubShell = createHubShell,
	createHubWindow = createHubWindow,
	createFarmInterface = createFarmInterface,
	findRemote = findRemote,
	invokeRemote = invokeRemote,
	fireRemote = fireRemote,
	safeIdentityCall = safeIdentityCall,
	travelToInterior = travelToInterior,
	goMainMap = goMainMap,
	goHome = goHome,
	getCurrentLocation = getCurrentLocation,
	getLocationName = getLocationName,
	isOwnHome = isOwnHome,
	getCharacterParts = getCharacterParts,
	moveToPosition = moveToPosition,
	getPlayerState = getPlayerState,
	getStateValue = getStateValue,
	getCatalogItem = getCatalogItem,
	getItemLabel = getItemLabel,
	getPetImage = getPetImage,
	getPetAilments = getPetAilments,
	getSubjectAilments = getSubjectAilments,
	getPetWrappers = getPetWrappers,
	findFarmQuestHandler = findFarmQuestHandler,
	collectFarmSubjects = collectFarmSubjects,
	learnFarmQuest = learnFarmQuest,
	estimateFarmQuest = estimateFarmQuest,
	collectFarmQuests = collectFarmQuests,
	createFarmState = createFarmState,
	createFarmController = createFarmController,
	claimDailyRewards = claimDailyRewards,
	collectPaycheck = collectPaycheck,
	clickGuiObject = clickGuiObject,
	isGuiObjectVisible = isGuiObjectVisible,
	closeMinigameRewards = closeMinigameRewards,
	handleDialog = handleDialog,
	dialogRules = DIALOG_RULES,
	handlePopups = handlePopups,
	createPopupController = createPopupController,
	getPendingPetDrops = getPendingPetDrops,
	walkOntoPetDrops = walkOntoPetDrops,
	claimPetDrops = claimPetDrops,
	loadCoreModules = loadCoreModules,
	loadGameModules = loadGameModules,
	initializeHubSession = initializeHubSession,
	unloadHub = unloadHub,
	initializeHubRuntime = initializeHubRuntime,
	prepareFarmPets = prepareFarmPets,
	canPetTakeAgePotion = canPetTakeAgePotion,
	getAgePotionKinds = getAgePotionKinds,
	collectAgePotionStock = collectAgePotionStock,
	describeAgePotions = describeAgePotions,
	getPetAgeXpNeeded = getPetAgeXpNeeded,
	planAgePotions = planAgePotions,
	selectAgePotionStep = selectAgePotionStep,
	feedAgePotions = feedAgePotions,
	runAgePotions = runAgePotions,
	stepStandaloneAgePotions = stepStandaloneAgePotions,
	tickAgePotions = tickAgePotions,
	createAgePotionController = createAgePotionController,
	equipFarmPet = equipFarmPet,
	chooseNextFarmPet = chooseNextFarmPet,
	selectFarmPet = selectFarmPet,
	stepFarm = stepFarm,
	isAppVisible = isAppVisible,
	closePetFocus = closePetFocus,
	releaseBabySeat = releaseBabySeat,
	waitForFarmQuest = waitForFarmQuest,
	getFurnitureEntry = getFurnitureEntry,
	listHouseFurniture = listHouseFurniture,
	farmFurniturePredicates = FARM_FURNITURE_PREDICATES,
	farmFurnitureRequirements = FARM_FURNITURE_REQUIREMENTS,
	findFarmFurniture = findFarmFurniture,
	findMissingFarmFurniture = findMissingFarmFurniture,
	findHousePosition = findHousePosition,
	buildFarmHouse = buildFarmHouse,
	useFarmFurniture = useFarmFurniture,
	shouldStopFarmWalker = shouldStopFarmWalker,
	stopFarmWalker = stopFarmWalker,
	createFarmWalker = createFarmWalker,
	startFarmWalker = startFarmWalker,
	stepFarmWalker = stepFarmWalker,
	walkUntil = walkUntil,
	walkWithPet = walkWithPet,
	performWalkQuest = performWalkQuest,
	performMainMapQuest = performMainMapQuest,
	performWeatherQuest = performWeatherQuest,
	performInteriorQuest = performInteriorQuest,
	healSubject = healSubject,
	findInteriorFurniture = findInteriorFurniture,
	performHomeQuest = performHomeQuest,
	feedBaby = feedBaby,
	findBabyFood = findBabyFood,
	performPetMeQuest = performPetMeQuest,
	performMysteryQuest = performMysteryQuest,
	performPlayQuest = performPlayQuest,
	performRideQuest = performRideQuest,
	findStrollerSeat = findStrollerSeat,
	findStroller = findStroller,
	isItemForSale = isItemForSale,
	getShopBalance = getShopBalance,
	formatShopNumber = formatShopNumber,
	findShopChoice = findShopChoice,
	getShopCatalog = getShopCatalog,
	buyShopItems = buyShopItems,
	openShopGift = openShopGift,
	createShopController = createShopController,
	getInventoryCategory = getInventoryCategory,
	findQuestItems = findQuestItems,
	equipInventoryItem = equipInventoryItem,
	performFarmQuest = performFarmQuest,
	isInMinigame = isInMinigame,
	isSessionActive = isSessionActive,
	startLoop = startLoop,
	runLoop = runLoop,
	restoreConfig = restoreConfig,
	createConfigManager = createConfigManager,
	readOption = readOption,
	sanitizeConfigName = sanitizeConfigName,
	listConfigs = listConfigs,
	createConfigFiles = createConfigFiles,
	autosave = autosave,
	collectPrivateConfig = collectPrivateConfig,
	applyConfig = applyConfig,
	applyOption = applyOption,
	collectConfig = collectConfig,
	createEnvironment = createEnvironment,
	createSessionFiles = createSessionFiles,
}
