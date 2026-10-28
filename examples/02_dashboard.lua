--[[
	Exter Library | 02 - Live dashboard
	--------------------------------------------------------------------
	A server monitor built only from display elements: Stat cards, LiveGraph,
	DataTable, KeyValue, ProfileCard and a Watermark HUD.

	Shows the "push data in a loop" pattern - the elements never poll, you feed
	them with :Set / :Push whenever you have something new.
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Window = Exter:CreateWindow({ Name = "Server Monitor", Subtitle = "Live dashboard" })
local Tab = Window:CreateTab({ Name = "Monitor", Icon = "insights", ImageSource = "Material" })

Tab:CreateProfileCard({ Badges = { "LIVE", { Text = "LOCAL", Color = Color3.fromRGB(104, 170, 255) } } })

local playersStat = Tab:CreateStat({ Name = "Players", Value = #Players:GetPlayers(), Icon = "person", Description = "in this server" })
local pingStat = Tab:CreateStat({ Name = "Ping", Value = 0, Suffix = " ms", Icon = "speed", Description = "round trip to the server" })
local memoryStat = Tab:CreateStat({ Name = "Memory", Value = 0, Suffix = " MB", Icon = "analytics", Decimals = 0 })

local fpsGraph = Tab:CreateLiveGraph({ Name = "Frame rate", Samples = 90, Suffix = " fps", Min = 0, Height = 110 })
local pingGraph = Tab:CreateLiveGraph({ Name = "Ping", Samples = 90, Suffix = " ms", Min = 0, Height = 110 })

local roster = Tab:CreateDataTable({
	Name = "Players",
	Columns = { "Name", { Name = "Account age (days)", Align = "Right" } },
	MaxRows = 5,
	Callback = function(row) Exter:Notification({ Title = tostring(row[1]), Content = "Selected from the roster", Duration = 2 }) end,
})

local info = Tab:CreateKeyValue({
	Items = {
		{ Key = "Place id", Value = game.PlaceId },
		{ Key = "Job id", Value = tostring(game.JobId) },
		{ Key = "Executor", Value = (identifyexecutor and identifyexecutor()) or "unknown" },
	},
})

local function refreshRoster()
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		rows[#rows + 1] = { player.DisplayName or player.Name, player.AccountAge or 0 }
	end
	roster:SetRows(rows)
	playersStat:Set({ Value = #rows })
end

refreshRoster()
Players.PlayerAdded:Connect(refreshRoster)
Players.PlayerRemoving:Connect(function() task.defer(refreshRoster) end)

-- A small HUD pinned to the corner of the screen. {fps} {ping} {time} {name} are built in.
local hud = Exter:CreateWatermark({ Text = "Exter | {name} | {fps} fps | {ping} ms | {time}", Position = "TopRight" })

-- FPS from Heartbeat, everything else from Stats; one loop feeds every element.
local frames, elapsed = 0, 0
RunService.Heartbeat:Connect(function(dt)
	frames = frames + 1
	elapsed = elapsed + dt
end)

task.spawn(function()
	while not Exter._destroyed do
		task.wait(0.5)
		local fps = elapsed > 0 and (frames / elapsed) or 0
		frames, elapsed = 0, 0

		local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		ping = ok and ping or 0
		local okMem, memory = pcall(function() return Stats:GetTotalMemoryUsageMb() end)

		fpsGraph:Push(fps)
		pingGraph:Push(ping)
		pingStat:Set({ Value = math.floor(ping + 0.5) })
		memoryStat:Set({ Value = okMem and math.floor(memory) or 0 })
		info:Set("Uptime", string.format("%ds", math.floor(time())))
	end
end)

Window:CreateTab({ Name = "Settings", Icon = "settings", ImageSource = "Material" }):BuildThemeSection()
