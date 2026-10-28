--[[
	Exter Library | 03 - Forms and inputs
	--------------------------------------------------------------------
	Every input element, wired with flags so BuildConfigSection can save and
	restore them, plus the three ways to react to a change:

	  1. Callback = function(...)            -- classic
	  2. Exter.Options.Flag:OnChanged(fn)    -- subscribe anywhere, any time
	  3. element:GetValue()                  -- read on demand
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({
	Name = "Forms",
	Subtitle = "Input elements",
	ConfigSettings = { ConfigFolder = "ExterForms" },
})

local Form = Window:CreateTab({ Name = "Profile", Icon = "person", ImageSource = "Material" })

local Basics = Form:CreateSection("Basics")

Basics:CreateSegmented({
	Name = "Mode",
	Options = { "Casual", "Ranked", "Custom" },
	CurrentOption = "Casual",
	Tooltip = "Changes which presets are offered below",
}, "Mode")

Basics:CreateStepper({ Name = "Team size", Range = { 1, 10 }, CurrentValue = 4, Increment = 1 }, "TeamSize")
Basics:CreateRangeSlider({ Name = "Level range", Range = { 1, 100 }, CurrentValue = { 20, 60 }, Callback = function(min, max) print("levels", min, max) end }, "LevelRange")
Basics:CreateRating({ Name = "Satisfaction", Max = 5, CurrentValue = 4 }, "Satisfaction")

local Choices = Form:CreateSection("Choices")

Choices:CreateRadioGroup({
	Name = "Region",
	Options = { "Europe", "Asia", "Americas" },
	CurrentOption = "Europe",
}, "Region")

Choices:CreateCheckboxGroup({
	Name = "Notifications",
	Description = "Pick at least one",
	Options = { "Friend joins", "Server updates", "Event reminders", "Marketing" },
	CurrentOptions = { "Server updates" },
	Min = 1,
}, "Notifications")

Choices:CreateColorPalette({ Name = "Accent colour", Selected = 7, Callback = function(color) print("accent", color) end }, "Accent")
Choices:CreateListPicker({ Name = "Favourite maps", Options = { "Alpine", "Arctic", "Canyon", "Desert", "Forest", "Harbour", "Jungle", "Tundra" }, MultiSelect = true, Height = 150 }, "Maps")

local Text = Form:CreateSection("Text")

Text:CreateTagInput({ Name = "Interests", Placeholder = "Add tag", Tags = { "building", "racing" }, MaxTags = 6 }, "Interests")
Text:CreateTextArea({ Name = "About me", Placeholder = "Say something about yourself...", MaxLength = 200, Height = 90 }, "About")
Text:CreateSecretInput({ Name = "API token", Placeholder = "Paste token", Description = "Never written to config files" }, "Token")

-- 2. subscribe from anywhere
Exter.Options.Mode:OnChanged(function(mode)
	Exter:Notification({ Title = "Mode changed", Content = "Now playing: " .. tostring(mode), Duration = 2 })
end)

-- 3. read on demand
Form:CreateButton({
	Name = "Print summary",
	Callback = function()
		local lo, hi = Exter.Options.LevelRange:GetValue()
		print(("mode=%s team=%d levels=%d-%d tags=%s"):format(
			tostring(Exter.Options.Mode:GetOption()),
			Exter.Options.TeamSize:GetValue(),
			lo, hi,
			table.concat(Exter.Options.Interests:GetTags(), ",")
		))
	end,
})

local Settings = Window:CreateTab({ Name = "Settings", Icon = "settings", ImageSource = "Material" })
Settings:BuildConfigSection() -- saves/loads every flagged element above
Settings:BuildThemeSection()
Exter:LoadAutoloadConfig()
