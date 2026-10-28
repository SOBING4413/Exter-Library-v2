--[[ Test harness: fake ExterLibrary core + helpers to load extension modules. ]]
local Mock = dofile("tests/mock_roblox.lua")
local H = { Mock = Mock }

local function readAll(path)
	local f = assert(io.open(path, "rb"))
	local s = f:read("a")
	f:close()
	return s
end

function H.load(path, ...)
	local chunk, err = load(readAll(path), "@" .. path)
	if not chunk then error(err) end
	return chunk(...)
end

function H.newLibrary()
	local Library = {
		Options = {}, _Parsers = {}, _Tabs = {}, _animSpeed = 1, _destroyed = false,
		ThemeGradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(117, 164, 206)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(123, 201, 201)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(224, 138, 175)),
		}),
		Notifications = {},
	}
	local gui = Instance.new("ScreenGui"); gui.Name = "ExterGui"
	local remote = Instance.new("BoolValue")

	-- fake template (what Kit.RefreshStyle samples)
	local elements = Instance.new("Frame"); elements.Name = "Interactions"
	local tpl = Instance.new("Frame"); tpl.Name = "Template"; tpl.Parent = elements
	local btn = Instance.new("Frame"); btn.Name = "Button"; btn.Size = UDim2.new(1, -10, 0, 42); btn.Parent = tpl
	local title = Instance.new("TextLabel"); title.Name = "Title"; title.TextSize = 15; title.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal); title.Parent = btn
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = btn

	local conns = {}
	local I = {
		Track = function(c) conns[#conns + 1] = c return c end,
		BindTheme = function(fn) pcall(fn) remote:GetPropertyChangedSignal("Value"):Connect(fn) end,
		GetElements = function() return elements end,
		GetGui = function() return gui end,
		GetMain = function() return Instance.new("Frame") end,
		ApplyIcon = function(img, icon) img.Image = "rbxassetid://icon:" .. tostring(icon) end,
		GetIcon = function(icon) return "rbxassetid://icon:" .. tostring(icon) end,
	}
	Library._Internal = I
	function Library:Notification(d) Library.Notifications[#Library.Notifications + 1] = d end
	function Library:SetTheme(c)
		Library.ThemeGradient = ColorSequence.new({ ColorSequenceKeypoint.new(0, c[1]), ColorSequenceKeypoint.new(0.5, c[2]), ColorSequenceKeypoint.new(1, c[3]) })
		remote.Value = not remote.Value
	end
	Library._gui, Library._conns = gui, conns
	return Library
end

-- builds a Tab-like container: a frame + a few core-style Create* methods
function H.newTab(Library, Kit)
	local page = Instance.new("ScrollingFrame"); page.Name = "Page"
	page.Parent = Library._gui
	local Tab = { Name = "TestTab" }
	function Tab:CreateButton(s) -- mimics core: element is parented straight into the page
		local f = Instance.new("Frame"); f.Name = s.Name or "Button"; f.Parent = page
		return { Frame = f, Settings = s }
	end
	function Tab:Activate() Tab.Active = true end
	local ctx = { Frame = page, Tab = Tab, Window = { Name = "TestWindow" }, Kind = "Tab", RootFrame = page, RootObject = Tab }
	Kit.Extend(Tab, ctx)
	return Tab, ctx, page
end

-- A stand-in for the real core: same public surface the examples use
-- (CreateWindow / CreateTab / CreateSection + core element methods) and the same
-- _Extend hook calls the patched ExterLibrary.lua makes.
function H.newCoreLibrary()
	local Library = H.newLibrary()
	local Kit = H.load("src/Kit.lua")(Library)
	for _, m in ipairs({ "src/elements/display.lua", "src/elements/input.lua", "src/elements/layout.lua", "src/systems/overlay.lua" }) do
		H.load(m)(Library, Kit)
	end
	Library.Kit = Kit
	Library.Version = "v-test"
	Library.CoreCalls = {}

	local function coreElement(page, calls, name)
		return function(_, s, flag)
			s = type(s) == "table" and s or { Name = s }
			local f = Instance.new("Frame"); f.Name = s.Name or s.Text or s.Title or name; f.Parent = page
			calls[#calls + 1] = name
			local el = { Frame = f, Settings = s, CurrentValue = s.CurrentValue }
			function el:Set(v) el.CurrentValue = v end
			if flag then Library.Options[flag] = el end
			return el
		end
	end
	local CORE = { "Button", "Toggle", "Slider", "Dropdown", "Input", "ColorPicker", "Bind", "Keybind", "Label", "Paragraph", "Divider" }

	function Library:CreateWindow(settings)
		local Window = { Settings = settings, Tabs = {} }
		function Window:CreateTab(ts)
			ts = type(ts) == "table" and ts or { Name = ts }
			local page = Instance.new("ScrollingFrame"); page.Name = ts.Name; page.Parent = Library._gui
			local Tab = {}
			for _, n in ipairs(CORE) do Tab["Create" .. n] = coreElement(page, Library.CoreCalls, n) end
			function Tab:Activate() Tab.Active = true end
			function Tab:CreateSection(name)
				local Section = { Name = name }
				local frame = Instance.new("Frame"); frame.Name = "Section_" .. tostring(name); frame.Parent = page
				for _, n in ipairs(CORE) do if n ~= "Keybind" then Section["Create" .. n] = coreElement(frame, Library.CoreCalls, n) end end
				Section.Tab = Tab
				Library._Extend(Section, { Frame = frame, Tab = Tab, Section = Section, Window = Window, Kind = "Section", RootFrame = frame, RootObject = Section })
				return Section
			end
			function Tab:BuildConfigSection() Library.CoreCalls[#Library.CoreCalls + 1] = "BuildConfigSection" end
			function Tab:BuildThemeSection() Library.CoreCalls[#Library.CoreCalls + 1] = "BuildThemeSection" end
			Tab.Name = ts.Name
			Library._Tabs[#Library._Tabs + 1] = { Name = ts.Name, Tab = Tab }
			Library._Extend(Tab, { Frame = page, Tab = Tab, Window = Window, Kind = "Tab", RootFrame = page, RootObject = Tab })
			Window.Tabs[#Window.Tabs + 1] = Tab
			return Tab
		end
		return Window
	end
	function Library:LoadAutoloadConfig() end
	return Library
end

function H.expect(cond, msg)
	if not cond then error("ASSERT FAILED: " .. tostring(msg), 2) end
end
function H.eq(a, b, msg)
	if a ~= b then error(string.format("ASSERT FAILED: %s (expected %s, got %s)", tostring(msg), tostring(b), tostring(a)), 2) end
end
function H.near(a, b, msg, eps)
	if math.abs(a - b) > (eps or 1e-6) then error(string.format("ASSERT FAILED: %s (expected ~%s, got %s)", tostring(msg), tostring(b), tostring(a)), 2) end
end

H.passed, H.failed = 0, 0
function H.test(name, fn)
	Mock.lastThreadError, Mock.lastSignalError = nil, nil
	local ok, err = xpcall(fn, function(e) return tostring(e) .. "\n" .. debug.traceback("", 2) end)
	if ok and Mock.lastThreadError then ok, err = false, "thread error: " .. Mock.lastThreadError end
	if ok and Mock.lastSignalError then ok, err = false, "signal error: " .. Mock.lastSignalError end
	if ok then H.passed = H.passed + 1; print("  ok   " .. name)
	else H.failed = H.failed + 1; print("  FAIL " .. name .. "\n       " .. tostring(err):gsub("\n", "\n       ")) end
end

return H
