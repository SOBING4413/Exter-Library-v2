local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Window = Exter:CreateWindow({
    Name = "Example Hub",
    Subtitle = "Release v1.2.8 — Premium",
    Bind = Enum.KeyCode.K,
    ConfigSettings = {
        ConfigFolder = "ExampleHub"
    }
})

local MainTab = Window:CreateTab({ Name = "Main", Icon = "home", ImageSource = "Material" })
MainTab:CreateButton({
    Name = "Rejoin Server",
    Description = "Reconnect to current server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
    end
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) getgenv().InfJump = v end
}, "InfJumpToggle")

local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "settings", ImageSource = "Material" })
SettingsTab:BuildConfigSection()
SettingsTab:BuildThemeSection()

Exter:LoadAutoloadConfig()
