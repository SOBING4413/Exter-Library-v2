--[[
	Exter Library | 06 - Full showcase
	--------------------------------------------------------------------
	One window, every extension element. Handy as a visual regression check
	after changing the theme, and as a copy-paste source for real scripts.
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({
	Name = "Showcase",
	Subtitle = "Exter Library " .. tostring(Exter.Version),
	Bind = Enum.KeyCode.K,
	ConfigSettings = { ConfigFolder = "ExterShowcase" },
})

----------------------------------------------------------------------
-- Display
----------------------------------------------------------------------
local Display = Window:CreateTab({ Name = "Display", Icon = "dashboard", ImageSource = "Material" })

Display:CreateProfileCard({ Subtitle = "Showcase session", Badges = { "PRO", { Text = "BETA", Color = Color3.fromRGB(250, 204, 82) } } })

Display:CreateCallout({ Type = "Success", Title = "Everything loaded", Content = "All extension modules initialised without errors." })
Display:CreateCallout({ Type = "Warning", Title = "Experimental", Content = "Callouts wrap long text automatically and can be dismissed.", Dismissible = true })
Display:CreateCallout({ Type = "Error", Title = "Something failed", Content = "Errors get a red accent." })

Display:CreateStat({ Name = "Active users", Value = 12840, Trend = 8.4, Icon = "person", Description = "vs. last week" })
Display:CreateStat({ Name = "Crash rate", Value = 0.42, Decimals = 2, Suffix = "%", Trend = -12.5, Icon = "bolt" })

local bar = Display:CreateProgressBar({ Name = "Upload", Description = "scene.rbxm", Value = 64 })
Display:CreateProgressBar({ Name = "Syncing", Indeterminate = true })
Display:CreateProgressBar({ Name = "XP", Value = 3200, Max = 5000, Suffix = "XP", Color = Color3.fromRGB(168, 85, 247) })

Display:CreateCodeBlock({
	Name = "Snippet",
	Code = 'local Players = game:GetService("Players")\n\nfor _, player in ipairs(Players:GetPlayers()) do\n\tprint(player.Name, player.UserId) -- 100% highlighted\nend',
})

Display:CreateDataTable({
	Name = "Leaderboard",
	Columns = { "Player", { Name = "Score", Align = "Right" }, { Name = "Rank", Align = "Right", Width = 0.2 } },
	Rows = { { "Nova", 9120, 1 }, { "Kite", 8730, 2 }, { "Moss", 7410, 3 }, { "Echo", 6980, 4 }, { "Pyro", 5120, 5 }, { "Zed", 3300, 6 } },
	MaxRows = 5,
})

local graph = Display:CreateLiveGraph({ Name = "Signal", Samples = 60, Min = -1, Max = 1, Height = 100 })
task.spawn(function()
	local t = 0
	while not Exter._destroyed do
		t = t + 0.2
		graph:Push(math.sin(t) * 0.8 + math.sin(t * 2.3) * 0.2)
		task.wait(0.1)
	end
end)

Display:CreateKeyValue({ Items = { { "Build", "2026.10.27" }, { "Channel", "stable" }, { "Region", "EU-West" } } })

----------------------------------------------------------------------
-- Inputs
----------------------------------------------------------------------
local Inputs = Window:CreateTab({ Name = "Inputs", Icon = "tune", ImageSource = "Material" })

Inputs:CreateStepper({ Name = "Stepper", Range = { 0, 20 }, CurrentValue = 5 }, "ShowStepper")
Inputs:CreateRangeSlider({ Name = "Range slider", Range = { 0, 100 }, CurrentValue = { 30, 70 } }, "ShowRange")
Inputs:CreateSegmented({ Name = "Segmented", Options = { "Day", "Week", "Month" }, CurrentOption = "Week" }, "ShowSegmented")
Inputs:CreateRadioGroup({ Name = "Radio group", Options = { "One", "Two", "Three" }, CurrentOption = "Two" }, "ShowRadio")
Inputs:CreateCheckboxGroup({ Name = "Checkbox group", Options = { "Alpha", "Beta", "Gamma" }, CurrentOptions = { "Alpha", "Gamma" } }, "ShowChecks")
Inputs:CreateRating({ Name = "Rating", CurrentValue = 3 }, "ShowRating")
Inputs:CreateColorPalette({ Name = "Colour palette", Selected = 4 }, "ShowPalette")
Inputs:CreateTagInput({ Name = "Tag input", Tags = { "lua", "roblox" } }, "ShowTags")
Inputs:CreateListPicker({ Name = "List picker", Options = { "Apple", "Banana", "Cherry", "Grape", "Mango", "Peach" }, Height = 140 }, "ShowList")
Inputs:CreateTextArea({ Name = "Text area", Placeholder = "Multi-line text", MaxLength = 120 }, "ShowArea")
Inputs:CreateSecretInput({ Name = "Secret input", Placeholder = "Hidden value" }, "ShowSecret")

----------------------------------------------------------------------
-- Layout
----------------------------------------------------------------------
local Layout = Window:CreateTab({ Name = "Layout", Icon = "view_in_ar", ImageSource = "Material" })

local group = Layout:CreateAccordion({ Name = "Accordion", Description = "Hosts core and extension elements", Icon = "tune", Open = true })
group:CreateToggle({ Name = "Core toggle", CurrentValue = true })
group:CreateStepper({ Name = "Extension stepper", Range = { 0, 10 }, CurrentValue = 3 })

local tabs = Layout:CreateSubTabs({ Tabs = { "First", "Second" } })
tabs:Tab("First"):CreateProgressBar({ Name = "Inside a sub tab", Value = 40 })
tabs:Tab("Second"):CreateRating({ Name = "Rate this tab", CurrentValue = 5 })

----------------------------------------------------------------------
-- Overlays
----------------------------------------------------------------------
local Overlays = Window:CreateTab({ Name = "Overlays", Icon = "chat", ImageSource = "Material" })

Overlays:CreateButton({ Name = "Dialog", Callback = function()
	Exter:Dialog({ Title = "Dialog", Content = "Backdrop, scale-in animation, Escape to close.", Type = "Info" })
end })
Overlays:CreateButton({ Name = "Confirm", Callback = function()
	print("confirmed:", Exter:Confirm({ Title = "Proceed?", Content = "Returns true or false." }))
end })
Overlays:CreateButton({ Name = "Prompt", Callback = function()
	print("entered:", Exter:Prompt({ Title = "Your name", Placeholder = "Type here" }))
end })
Overlays:CreateButton({ Name = "Command palette (Ctrl+P)", Callback = function() Exter:OpenCommandPalette() end })

Exter:CreateWatermark({ Text = "Showcase | {fps} fps | {time}", Position = "TopLeft" })
Exter:EnableCommandPalette()

local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings", ImageSource = "Material" })
Settings:BuildConfigSection()
Settings:BuildThemeSection()
Exter:LoadAutoloadConfig()
