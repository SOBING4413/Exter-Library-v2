--[[
	Exter Library | 01 - Quick start
	--------------------------------------------------------------------
	The smallest script that shows what the extension elements feel like:
	a callout, an animated progress bar, a segmented control, a stepper and
	a confirm dialog. Everything below is a normal Tab:CreateX call.
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({
	Name = "Quick Start",
	Subtitle = "Exter Library " .. tostring(Exter.Version),
})

local Tab = Window:CreateTab({ Name = "Overview", Icon = "dashboard", ImageSource = "Material" })

-- A dismissible callout: Type = Info | Success | Warning | Error
Tab:CreateCallout({
	Type = "Info",
	Title = "Welcome",
	Content = "Every element on this page was created with one call. Hover things, drag things, press Ctrl+P.",
	Dismissible = true,
})

-- Progress bars animate on their own; just call :SetValue
local progress = Tab:CreateProgressBar({
	Name = "Streaming assets",
	Description = "Textures and meshes",
	Value = 0,
})

task.spawn(function()
	for i = 1, 100 do
		if Exter._destroyed then return end
		progress:SetValue(i)
		task.wait(0.03)
	end
	progress:Set({ Name = "Assets ready", Description = "Everything is streamed in", Color = Color3.fromRGB(86, 214, 140) })
end)

-- Segmented control: a nicer radio for 2-4 short options
local quality = Tab:CreateSegmented({
	Name = "Quality",
	Options = { "Low", "Medium", "High" },
	CurrentOption = "Medium",
	Callback = function(option) print("Quality ->", option) end,
}, "Quality")

-- Stepper: [-] 200 studs [+]  (hold the buttons to repeat, or type a value)
Tab:CreateStepper({
	Name = "Render distance",
	Description = "How far the world is drawn",
	Range = { 50, 500 },
	Increment = 25,
	CurrentValue = 200,
	Suffix = " studs",
	Callback = function(value) print("Distance ->", value) end,
}, "RenderDistance")

-- Confirm yields until the user decides and returns a boolean
Tab:CreateButton({
	Name = "Reset all settings",
	Callback = function()
		local sure = Exter:Confirm({
			Title = "Reset settings?",
			Content = "Quality and render distance go back to their defaults.",
			Confirm = "Reset",
			Danger = true,
		})
		if sure then
			quality:Set({ CurrentOption = "Medium" })
			Exter.Options.RenderDistance:Set({ CurrentValue = 200 })
			Exter:Notification({ Title = "Done", Content = "Settings restored.", Duration = 3 })
		end
	end,
})
