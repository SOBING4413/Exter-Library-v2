--[[
	Exter Library | 05 - Overlays, dialogs and the command palette
	--------------------------------------------------------------------
	Everything here lives on the Library object because it floats above the
	window:  Dialog · Confirm · Prompt · CreateWatermark · AttachTooltip ·
	RegisterCommand · EnableCommandPalette (Ctrl+P by default)
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({ Name = "Overlays", Subtitle = "Dialogs and palette" })
local Tab = Window:CreateTab({ Name = "Dialogs", Icon = "chat", ImageSource = "Material" })

-- 1. Dialog with custom buttons. Buttons may have callbacks; Keep = true leaves it open.
Tab:CreateButton({
	Name = "Open a dialog",
	Tooltip = "Three buttons, one primary",
	Callback = function()
		Exter:Dialog({
			Title = "Update available",
			Content = "Version 2.4 adds new maps and fixes several bugs.",
			Type = "Info",
			Buttons = {
				{ Name = "Later" },
				{ Name = "Release notes", Callback = function() print("opening notes") end, Keep = true },
				{ Name = "Update now", Primary = true, Callback = function() print("updating") end },
			},
		})
	end,
})

-- 2. Confirm: blocks the calling thread, returns true / false
Tab:CreateButton({
	Name = "Delete save file",
	Callback = function()
		if Exter:Confirm({ Title = "Delete save?", Content = "This cannot be undone.", Confirm = "Delete", Danger = true }) then
			Exter:Notification({ Title = "Deleted", Content = "Save file removed", Duration = 3 })
		end
	end,
})

-- 3. Prompt: asks for text, with validation. Returns the text, or nil when cancelled.
Tab:CreateButton({
	Name = "Rename profile",
	Callback = function()
		local name = Exter:Prompt({
			Title = "Rename profile",
			Content = "3 to 16 characters.",
			Placeholder = "Profile name",
			MaxLength = 16,
			Validate = function(text)
				if #text < 3 then return false, "Use at least 3 characters" end
				return true
			end,
		})
		if name then Exter:Notification({ Title = "Renamed", Content = "Now called " .. name, Duration = 3 }) end
	end,
})

-- Non-blocking variants take a callback instead
Tab:CreateButton({
	Name = "Confirm (callback style)",
	Callback = function()
		Exter:Confirm({ Title = "Continue?" }, function(accepted) print("accepted:", accepted) end)
	end,
})

-- 4. Watermark / HUD - placeholders update twice a second, add your own with Variables
local hud = Exter:CreateWatermark({
	Text = "{name} | {fps} fps | {ping} ms | {mode}",
	Position = "BottomLeft",
	Variables = { mode = "Standard" },
})

Tab:CreateSegmented({
	Name = "HUD mode",
	Options = { "Standard", "Compact" },
	Callback = function(mode) hud:SetVariable("mode", mode) end,
})

-- 5. Command palette: Ctrl+P. Tabs and every named element are searchable already.
Exter:RegisterCommand({
	Name = "Toggle HUD",
	Description = "Show or hide the watermark",
	Icon = "visibility",
	Keywords = { "watermark", "overlay" },
	Callback = function() hud:SetVisible(not hud.Frame.Visible) end,
})

Exter:RegisterCommand({
	Name = "Say hello",
	Callback = function() Exter:Notification({ Title = "Hello", Content = "From the command palette", Duration = 2 }) end,
})

Exter:EnableCommandPalette() -- Ctrl+P.  Custom: { Bind = Enum.KeyCode.K, Modifier = Enum.KeyCode.LeftShift }
