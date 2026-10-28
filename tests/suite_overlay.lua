local H = dofile("tests/harness.lua")
local Mock = H.Mock
local Library = H.newLibrary()
local Kit = H.load("src/Kit.lua")(Library)
H.load("src/elements/display.lua")(Library, Kit)
H.load("src/elements/input.lua")(Library, Kit)
H.load("src/systems/overlay.lua")(Library, Kit)
print("-- Overlay systems")

local function find(root, name) return root:FindFirstChild(name, true) end
local gui = Library._gui

H.test("Tooltip: delayed show, hide, setText", function()
	local Tab = H.newTab(Library, Kit)
	local p = Tab:CreateProgressBar({ Name = "Tip", Tooltip = "Hello tooltip" })
	p.Frame.MouseEnter:Fire()
	local tipFrame = find(gui, "Tooltip")
	H.expect(tipFrame == nil or tipFrame.Visible == false, "not shown immediately")
	Mock.advance(0.5)
	tipFrame = find(gui, "Tooltip")
	H.expect(tipFrame and tipFrame.Visible, "shown after delay")
	H.eq(find(tipFrame, "Text").Text, "Hello tooltip", "text")
	p.Frame.MouseLeave:Fire()
	H.eq(tipFrame.Visible, false, "hidden on leave")
	local h = Library:AttachTooltip(p.Frame, function() return "dynamic" end)
	p.Frame.MouseEnter:Fire(); Mock.advance(0.5)
	H.eq(find(find(gui, "Tooltip"), "Text").Text, "dynamic", "function text")
	h:Disconnect()
end)

H.test("Dialog: buttons, callbacks, escape, backdrop", function()
	local hits = {}
	local d = Library:Dialog({ Title = "Delete?", Content = "This cannot be undone.", Type = "Warning", Buttons = { { Name = "No" }, { Name = "Yes", Primary = true, Callback = function() hits[#hits + 1] = "yes" end } } })
	H.eq(find(d.Panel, "Title").Text, "Delete?", "title")
	local result
	d.Closed:Connect(function(r) result = r end)
	Mock.click(find(gui, "Btn_Yes"))
	H.eq(result, "Yes", "closed with button name")
	H.eq(hits[1], "yes", "button callback ran")
	H.eq(d.IsOpen, false, "closed")
	Mock.advance(1)
	H.eq(find(gui, "DialogBackdrop"), nil, "backdrop removed")
	local d2 = Library:Dialog({ Title = "Esc" })
	Mock.key("Escape")
	H.eq(d2.IsOpen, false, "escape closes")
	local d3 = Library:Dialog({ Title = "Sticky", Dismissible = false })
	Mock.key("Escape")
	H.eq(d3.IsOpen, true, "non-dismissible ignores escape")
	d3:Close("x"); Mock.advance(1)
	local d4 = Library:Dialog({ Title = "Backdrop" })
	Mock.click(d4.Backdrop)
	H.eq(d4.IsOpen, false, "backdrop click closes")
	Mock.advance(1)
end)

H.test("Confirm yields and returns a boolean; callback mode is non-blocking", function()
	local answer
	task.spawn(function() answer = Library:Confirm({ Title = "Sure?", Confirm = "Do it", Danger = true }) end)
	H.eq(answer, nil, "still waiting")
	Mock.click(find(gui, "Btn_Do it"))
	H.eq(answer, true, "confirm -> true")
	Mock.advance(1)
	task.spawn(function() answer = Library:Confirm({ Title = "Sure?" }) end)
	Mock.click(find(gui, "Btn_Cancel"))
	H.eq(answer, false, "cancel -> false")
	Mock.advance(1)
	local cb
	Library:Confirm({ Title = "cb" }, function(v) cb = v end)
	Mock.click(find(gui, "Btn_Confirm"))
	H.eq(cb, true, "callback variant")
	Mock.advance(1)
end)

H.test("Prompt: validation keeps dialog open, returns text", function()
	local value
	task.spawn(function() value = Library:Prompt({ Title = "Name", Default = "", Validate = function(t) if #t < 3 then return false, "Too short" end return true end }) end)
	Mock.advance(0.2)
	local box = find(gui, "Input")
	box.Text = "ab"
	Mock.click(find(gui, "Btn_OK"))
	H.eq(value, nil, "invalid keeps waiting")
	H.eq(find(gui, "Error").Text, "Too short", "error message shown")
	box.Text = "alice"
	Mock.click(find(gui, "Btn_OK"))
	H.eq(value, "alice", "returns entered text")
	Mock.advance(1)
	local got = "unset"
	task.spawn(function() got = Library:Prompt({ Title = "Cancel me" }) end)
	Mock.click(find(gui, "Btn_Cancel"))
	H.eq(got, nil, "cancel returns nil")
	Mock.advance(1)
end)

H.test("Watermark: variables, live updates, destroy", function()
	local wm = Library:CreateWatermark({ Text = "{name} | {fps} fps | {custom} | {missing}", Variables = { custom = function() return "X" end } })
	local label = find(wm.Frame, "Text")
	H.expect(label.Text:find("Test User", 1, true), "name variable")
	H.expect(label.Text:find("| X |", 1, true), "custom variable")
	H.expect(label.Text:find("{missing}", 1, true), "unknown placeholders preserved")
	Mock.RunService.RenderStepped:Fire(1 / 60)
	for _ = 1, 40 do Mock.RunService.RenderStepped:Fire(1 / 60) end
	Mock.advance(1)
	H.expect(label.Text:find("60 fps", 1, true), "fps measured from RenderStepped (" .. label.Text .. ")")
	wm:SetVariable("custom", "Y")
	H.expect(label.Text:find("| Y |", 1, true), "SetVariable")
	wm:SetText("static")
	H.eq(label.Text, "static", "SetText")
	wm:Destroy()
	Mock.advance(2)
end)

H.test("Command palette: fuzzy search, navigation, run", function()
	Library._Tabs = { { Name = "Combat", Tab = { Activate = function() Library.lastTab = "Combat" end, Name = "Combat" } } }
	local ran = {}
	Library:RegisterCommand({ Name = "Toggle Dark Mode", Description = "Theme", Callback = function() ran[#ran + 1] = "dark" end })
	Library:RegisterCommand({ Name = "Reload Config", Callback = function() ran[#ran + 1] = "reload" end })
	local Tab = H.newTab(Library, Kit)
	Tab.Name = "Combat"; Tab.Activate = function() Library.lastTab = "Combat" end
	Tab:CreateStepper({ Name = "Aim Speed" })
	H.eq(Kit.FuzzyScore("Toggle Dark Mode", "dark") ~= nil, true, "substring score")
	H.expect(Kit.FuzzyScore("Toggle Dark Mode", "tdm") ~= nil, "subsequence score")
	H.eq(Kit.FuzzyScore("abc", "xyz"), nil, "no match")

	Library:OpenCommandPalette()
	Mock.advance(0.2)
	H.eq(Library:IsCommandPaletteOpen(), true, "open")
	local box = find(gui, "Query")
	box.Text = "dark"
	H.eq(find(gui, "Row1"):FindFirstChild("Name").Text, "Toggle Dark Mode", "best match first")
	H.eq(find(gui, "Row2"), nil, "non matches filtered")
	box:ReleaseFocus(true) -- Enter
	Mock.advance(0.3)
	H.eq(ran[1], "dark", "enter runs the selected command")
	H.eq(Library:IsCommandPaletteOpen(), false, "closes after run")
	Mock.advance(1)

	Library:OpenCommandPalette(); Mock.advance(0.2)
	find(gui, "Query").Text = "aim"
	Mock.key("Down"); Mock.key("Up")
	Mock.click(find(gui, "Row1"))
	Mock.advance(0.5)
	H.eq(Library.lastTab, "Combat", "element result activates its tab")

	Library:OpenCommandPalette(); Mock.advance(0.2)
	find(gui, "Query").Text = "go to"
	H.eq(find(gui, "Row1"):FindFirstChild("Name").Text, "Go to Combat", "tabs are searchable")
	Mock.key("Escape")
	H.eq(Library:IsCommandPaletteOpen(), false, "escape closes")
	Mock.advance(1)

	local h = Library:EnableCommandPalette({})
	Mock.keysDown.LeftControl = true
	Mock.key("P"); Mock.advance(0.1)
	H.eq(Library:IsCommandPaletteOpen(), true, "Ctrl+P opens")
	Mock.key("P")
	H.eq(Library:IsCommandPaletteOpen(), false, "Ctrl+P toggles closed")
	Mock.keysDown.LeftControl = false
	Mock.key("P")
	H.eq(Library:IsCommandPaletteOpen(), false, "bare P does nothing")
	h.Disable()
	Mock.advance(1)
end)

_G.__FAILED = H.failed
print(string.format("   %d passed, %d failed", H.passed, H.failed))
