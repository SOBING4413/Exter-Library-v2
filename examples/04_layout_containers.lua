--[[
	Exter Library | 04 - Layout containers
	--------------------------------------------------------------------
	Accordion and SubTabs are *containers*: they expose the same Create*
	methods as a Tab, for the original core elements (CreateToggle, CreateSlider,
	...) and for every extension element. They can be nested freely.
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({ Name = "Layout", Subtitle = "Containers" })
local Tab = Window:CreateTab({ Name = "Groups", Icon = "view_in_ar", ImageSource = "Material" })

-- 1. Accordion: collapsible group, animated, height follows its content
local graphics = Tab:CreateAccordion({
	Name = "Graphics",
	Description = "Resolution, effects and sharpening",
	Icon = "tune",
	Open = true,
})

graphics:CreateToggle({ Name = "VSync", CurrentValue = true }, "VSync") -- core element, hosted inside the group
graphics:CreateSlider({ Name = "Field of view", Range = { 40, 120 }, Increment = 1, CurrentValue = 70, Suffix = "°" }, "Fov")
graphics:CreateSegmented({ Name = "Shadows", Options = { "Off", "Soft", "Sharp" }, CurrentOption = "Soft" }, "Shadows")

-- Containers nest: an Accordion inside an Accordion
local advanced = graphics:CreateAccordion({ Name = "Advanced", Description = "Only change if you know why" })
advanced:CreateStepper({ Name = "Shadow map size", Range = { 512, 4096 }, Increment = 512, CurrentValue = 2048 }, "ShadowMap")
advanced:CreateCallout({ Type = "Warning", Title = "Heads up", Content = "Large shadow maps use a lot of video memory." })

-- 2. SubTabs: page switcher inside a tab
local audio = Tab:CreateSubTabs({
	Tabs = { "Volume", "Devices", "Effects" },
	Default = "Volume",
	Callback = function(name) print("sub tab ->", name) end,
})

local volume = audio:Tab("Volume")
volume:CreateSlider({ Name = "Master", Range = { 0, 100 }, Increment = 1, CurrentValue = 80, Suffix = "%" }, "Master")
volume:CreateProgressBar({ Name = "Input level", Value = 35 })

local devices = audio:Tab("Devices")
devices:CreateRadioGroup({ Name = "Output", Options = { "Speakers", "Headphones", "HDMI" }, CurrentOption = "Speakers" }, "Output")

local effects = audio:Tab("Effects")
effects:CreateCheckboxGroup({ Name = "Enhancements", Options = { "Bass boost", "Loudness", "Surround" }, CurrentOptions = { "Loudness" } }, "Enhancements")

-- Containers also work inside a Section
local Section = Tab:CreateSection("Inside a section")
local group = Section:CreateAccordion({ Name = "Collapsed by default" })
group:CreateLabel({ Text = "Labels, paragraphs, buttons... everything works in a group." })
group:CreateButton({ Name = "A core button", Callback = function() print("hosted core button works") end })

-- Programmatic control
Tab:CreateButton({
	Name = "Toggle Graphics group",
	Callback = function() graphics:Toggle() end,
})
