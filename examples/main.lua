-- Exter Universal v1.3.0  |  UI: Exter Library (Exter Interactive)

local env = (getgenv and getgenv()) or _G
if env.ExterUniversalUnload then
    pcall(env.ExterUniversalUnload)
end

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

-- ============================================================
-- VARIABEL GLOBAL
-- ============================================================
env.ExterUniversal = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        VisibilityCheck = true,
        TargetPlayers = true,
        TargetNPCs = true,
        StickyTarget = true,      -- kunci satu target selama tombol ditahan
        HitChance = 100,          -- dilempar sekali saat mengunci target (100 = selalu)
        Smoothness = 0,           -- 0 = langsung tepat di target
        SelectedPart = "Body",    -- Body | Head | HumanoidRootPart | Random
        FOVRadius = 180,
        ShowFOV = true,
        MaxDistance = 1500,
        TargetKey = "MouseButton2",
        AimMethod = "Camera",     -- Camera | Mouse
        Prediction = false,
        PredictionAmount = 0.165
    },
    ESP = {
        Enabled = false,
        Boxes = true,
        HealthBar = true,
        NameTag = true,
        Tracers = false,
        TeamColor = true,
        Distance = false,
        MaxDistance = 1000
    },
    Movement = {
        Walkspeed = 16,
        JumpPower = 50,
        NoClip = false,
        AntiFall = false,
        Fly = false,
        FlySpeed = 50
    },
    Character = {
        InfiniteJump = false,
        NoSlowdown = false,
        AutoClick = false,
        ClickInterval = 0.1,
        GodMode = false
    },
    Visuals = {
        FullBright = false,
        FOV = 70,
        NoFog = false,
        NightMode = false
    },
    Misc = {
        Rejoin = function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
        end,
        PanicKey = Enum.KeyCode.P,
        AntiAFK = true,
        ChatSpam = false,
        ChatMessage = "Exter Universal",
        ChatInterval = 3
    }
}

local E = env.ExterUniversal
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local connections = {}
local function track(conn)
    connections[#connections + 1] = conn
    return conn
end

track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end))

local function resolveOptionValue(value)
    if type(value) == "table" then
        return value[1]
    end
    return value
end

local function notify(title, content, icon, duration)
    Exter:Notification({
        Title = title,
        Content = content,
        Icon = icon or "info",
        ImageSource = "Material",
        Duration = duration or 3
    })
end

-- ============================================================
-- AIMBOT: TARGET (PLAYER + NPC)
-- ============================================================
local PART_ALIASES = {
    Body = {"UpperTorso", "Torso", "HumanoidRootPart"},
    Head = {"Head"},
    HumanoidRootPart = {"HumanoidRootPart"},
}
local RANDOM_PARTS = {"Head", "Body"}

local function resolvePart(model, partName)
    local list = PART_ALIASES[partName] or PART_ALIASES.Body
    for _, name in ipairs(list) do
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
    end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

-- NPC = Model ber-Humanoid yang bukan karakter pemain (cache, tanpa scan workspace tiap frame)
local NPCs = {}

local function registerNPC(inst)
    if not inst:IsA("Humanoid") then return end
    local model = inst.Parent
    if not model or not model:IsA("Model") then return end
    if Players:GetPlayerFromCharacter(model) then return end
    NPCs[model] = inst
end

track(workspace.DescendantAdded:Connect(function(inst)
    task.defer(registerNPC, inst)
end))

track(workspace.DescendantRemoving:Connect(function(inst)
    if inst:IsA("Humanoid") and inst.Parent then
        NPCs[inst.Parent] = nil
    end
    NPCs[inst] = nil
end))

task.spawn(function()
    local count = 0
    for _, inst in ipairs(workspace:GetDescendants()) do
        registerNPC(inst)
        count = count + 1
        if count % 3000 == 0 then task.wait() end
    end
end)

local function collectTargets()
    local list = {}
    local A = E.Aimbot

    if A.TargetPlayers then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local sameTeam = false
                    if A.TeamCheck and plr.Team ~= nil and Player.Team ~= nil then
                        sameTeam = (plr.Team == Player.Team)
                    end
                    if not sameTeam then
                        list[#list + 1] = {model = char, hum = hum}
                    end
                end
            end
        end
    end

    if A.TargetNPCs then
        for model, hum in pairs(NPCs) do
            if model.Parent and hum.Parent == model and hum.Health > 0
                and model ~= Player.Character and not Players:GetPlayerFromCharacter(model) then
                list[#list + 1] = {model = model, hum = hum}
            end
        end
    end

    return list
end

-- Garis pandang: abaikan part tembus pandang / tanpa collision (daun, kaca, dll)
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(part, model)
    if not E.Aimbot.VisibilityCheck then return true end
    if not part then return false end

    local origin = Camera.CFrame.Position
    local offset = part.Position - origin
    local direction = offset.Unit * (offset.Magnitude + 2)

    local ignore = {Player.Character}
    for _ = 1, 5 do
        rayParams.FilterDescendantsInstances = ignore
        local result = workspace:Raycast(origin, direction, rayParams)
        if not result then return true end

        local hit = result.Instance
        if hit:IsDescendantOf(model) then return true end
        if hit.Transparency >= 0.8 or not hit.CanCollide then
            ignore[#ignore + 1] = hit
        else
            return false
        end
    end
    return false
end

local function screenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function pickPartName()
    local name = E.Aimbot.SelectedPart
    if name == "Random" then
        name = RANDOM_PARTS[math.random(1, #RANDOM_PARTS)]
    end
    return name
end

local function bestTarget()
    local A = E.Aimbot
    local center = screenCenter()
    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    local partName = pickPartName()

    local best, bestDist = nil, math.huge
    for _, target in ipairs(collectTargets()) do
        local part = resolvePart(target.model, partName)
        if part then
            local inRange = true
            if myRoot then
                inRange = (part.Position - myRoot.Position).Magnitude <= A.MaxDistance
            end
            if inRange then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if dist <= A.FOVRadius and dist < bestDist and isVisible(part, target.model) then
                        best, bestDist = target, dist
                    end
                end
            end
        end
    end
    return best, partName
end

-- ============================================================
-- AIMBOT ENGINE
-- ============================================================
local FOVCircle
if Drawing and Drawing.new then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Visible = false
    FOVCircle.NumSides = 64
    FOVCircle.Transparency = 0.7
end

local function updateFOV()
    if not FOVCircle then return end
    FOVCircle.Radius = E.Aimbot.FOVRadius
    FOVCircle.Position = screenCenter()
    FOVCircle.Visible = E.Aimbot.Enabled and E.Aimbot.ShowFOV
end

local function isTargeting()
    if UserInputService:GetFocusedTextBox() then return false end
    local key = E.Aimbot.TargetKey
    if key == "MouseButton2" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif key == "MouseButton1" then
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    local ok, keyCode = pcall(function() return Enum.KeyCode[key] end)
    if ok and keyCode then
        return UserInputService:IsKeyDown(keyCode)
    end
    return false
end

local lock = {model = nil, hum = nil, partName = nil, skip = false}

local function lockedPart()
    local model, hum = lock.model, lock.hum
    if not model or not model.Parent or not hum or hum.Health <= 0 then return nil end
    local part = resolvePart(model, lock.partName)
    if not part then return nil end
    local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen or screenPos.Z <= 0 then return nil end
    if not isVisible(part, model) then return nil end
    return part
end

local function aimAt(targetPos)
    local A = E.Aimbot
    local alpha = 1
    if A.Smoothness > 0 then
        alpha = math.clamp(1 / A.Smoothness, 0.01, 1)
    end

    if A.AimMethod == "Mouse" and mousemoverel then
        -- untuk game FPS dengan kamera custom (hasil bergantung sensitivitas mouse)
        local screenPos = Camera:WorldToViewportPoint(targetPos)
        local delta = Vector2.new(screenPos.X, screenPos.Y) - screenCenter()
        mousemoverel(delta.X * alpha, delta.Y * alpha)
    else
        local camPos = Camera.CFrame.Position
        local targetCFrame = CFrame.lookAt(camPos, targetPos)
        if alpha < 1 then
            Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, alpha)
        else
            Camera.CFrame = targetCFrame
        end
    end
end

local function aimStep()
    local A = E.Aimbot
    if not A.Enabled or not isTargeting() then
        lock.model = nil
        lock.skip = false
        return
    end
    if lock.skip then return end

    local part
    if lock.model and A.StickyTarget then
        part = lockedPart()
        if not part then lock.model = nil end
    else
        lock.model = nil
    end

    if not lock.model then
        local target, partName = bestTarget()
        if not target then return end
        if A.StickyTarget and math.random(1, 100) > A.HitChance then
            lock.skip = true
            return
        end
        lock.model, lock.hum, lock.partName = target.model, target.hum, partName
        part = resolvePart(target.model, partName)
        if not part then
            lock.model = nil
            return
        end
    end

    local targetPos = part.Position
    if A.Prediction then
        local root = lock.model:FindFirstChild("HumanoidRootPart") or part
        targetPos = targetPos + (root.AssemblyLinearVelocity * A.PredictionAmount)
    end

    aimAt(targetPos)
end

-- jalan SETELAH skrip kamera Roblox supaya CFrame kamera tidak ditimpa
RunService:BindToRenderStep("ExterUniversalAim", Enum.RenderPriority.Camera.Value + 1, function()
    local ok, err = pcall(aimStep)
    if not ok and not lock.warned then
        lock.warned = true
        warn("[ExterUniversal] aimbot error: " .. tostring(err))
    end
end)

-- ============================================================
-- ESP ENGINE
-- ============================================================
local ESPObjects = {}
local hasDrawing = Drawing and Drawing.new

local function createESP(plr)
    if not hasDrawing or ESPObjects[plr] then return end
    ESPObjects[plr] = {}

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Visible = false
    ESPObjects[plr].Box = box

    local hpBg = Drawing.new("Square")
    hpBg.Filled = true
    hpBg.Color = Color3.fromRGB(0, 0, 0)
    hpBg.Transparency = 0.5
    hpBg.Visible = false
    ESPObjects[plr].HPBg = hpBg

    local hpFill = Drawing.new("Square")
    hpFill.Filled = true
    hpFill.Visible = false
    ESPObjects[plr].HPFill = hpFill

    local nameTag = Drawing.new("Text")
    nameTag.Size = 14
    nameTag.Center = true
    nameTag.Outline = true
    nameTag.Visible = false
    ESPObjects[plr].NameTag = nameTag

    local distText = Drawing.new("Text")
    distText.Size = 12
    distText.Center = true
    distText.Outline = true
    distText.Visible = false
    ESPObjects[plr].DistText = distText

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Visible = false
    ESPObjects[plr].Tracer = tracer
end

local function hideESP(obj)
    if not obj then return end
    for _, drawing in pairs(obj) do
        drawing.Visible = false
    end
end

local function updateESP(plr)
    local obj = ESPObjects[plr]
    if not obj then return end
    local char = plr.Character
    if not char then
        hideESP(obj)
        return
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        hideESP(obj)
        return
    end

    local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if myRoot and (hrp.Position - myRoot.Position).Magnitude > E.ESP.MaxDistance then
        hideESP(obj)
        return
    end

    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then
        hideESP(obj)
        return
    end

    local rootPos = hrp.Position
    local topPos, topOnScreen = Camera:WorldToViewportPoint(rootPos + Vector3.new(0, 3, 0))
    local bottomPos, bottomOnScreen = Camera:WorldToViewportPoint(rootPos - Vector3.new(0, 4.5, 0))
    if not topOnScreen or not bottomOnScreen then
        hideESP(obj)
        return
    end

    local boxHeight = math.abs(topPos.Y - bottomPos.Y)
    local boxWidth = boxHeight * 0.55
    local boxSize = Vector2.new(boxWidth, boxHeight)
    local boxPos = Vector2.new(screenPos.X - boxWidth / 2, topPos.Y)

    local espColor = Color3.fromRGB(255, 255, 255)
    if E.ESP.TeamColor then
        pcall(function() espColor = plr.TeamColor.Color end)
    end

    local health = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

    if E.ESP.Boxes then
        obj.Box.Size = boxSize
        obj.Box.Position = boxPos
        obj.Box.Color = espColor
        obj.Box.Visible = true
    else
        obj.Box.Visible = false
    end

    if E.ESP.HealthBar then
        local hpX = boxPos.X - 6
        local hpY = boxPos.Y
        obj.HPBg.Size = Vector2.new(4, boxHeight)
        obj.HPBg.Position = Vector2.new(hpX, hpY)
        obj.HPBg.Visible = true

        local fillHeight = boxHeight * health
        obj.HPFill.Size = Vector2.new(4, fillHeight)
        obj.HPFill.Position = Vector2.new(hpX, hpY + (boxHeight - fillHeight))
        obj.HPFill.Color = Color3.fromRGB(math.floor((1 - health) * 255), math.floor(health * 255), 0)
        obj.HPFill.Visible = true
    else
        obj.HPBg.Visible = false
        obj.HPFill.Visible = false
    end

    if E.ESP.NameTag then
        obj.NameTag.Position = Vector2.new(screenPos.X, boxPos.Y - 18)
        obj.NameTag.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
        obj.NameTag.Color = espColor
        obj.NameTag.Visible = true
    else
        obj.NameTag.Visible = false
    end

    if E.ESP.Distance and myRoot then
        local dist = (hrp.Position - myRoot.Position).Magnitude
        obj.DistText.Position = Vector2.new(screenPos.X, boxPos.Y + boxHeight + 4)
        obj.DistText.Text = math.floor(dist) .. " studs"
        obj.DistText.Color = Color3.fromRGB(200, 200, 200)
        obj.DistText.Visible = true
    else
        obj.DistText.Visible = false
    end

    if E.ESP.Tracers then
        obj.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        obj.Tracer.To = Vector2.new(screenPos.X, boxPos.Y + boxHeight)
        obj.Tracer.Color = espColor
        obj.Tracer.Visible = true
    else
        obj.Tracer.Visible = false
    end
end

local function espLoop()
    if not E.ESP.Enabled then
        for _, obj in pairs(ESPObjects) do
            hideESP(obj)
        end
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            createESP(plr)
            updateESP(plr)
        end
    end
end

track(Players.PlayerRemoving:Connect(function(plr)
    if ESPObjects[plr] then
        for _, drawing in pairs(ESPObjects[plr]) do
            pcall(function() drawing:Remove() end)
        end
        ESPObjects[plr] = nil
    end
end))

-- ============================================================
-- MOVEMENT ENGINE
-- ============================================================
local function applyMovement()
    if not Player.Character then return end
    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    hum.WalkSpeed = E.Movement.Walkspeed
    hum.JumpPower = E.Movement.JumpPower
end

track(Player.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    applyMovement()
end))

local noclipParts, noclipChar, noclipStamp = {}, nil, 0

local function noclipLoop()
    if not E.Movement.NoClip then return end
    local char = Player.Character
    if not char then return end

    local now = os.clock()
    if noclipChar ~= char or now - noclipStamp > 1 then
        noclipChar, noclipStamp = char, now
        noclipParts = {}
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                noclipParts[#noclipParts + 1] = part
            end
        end
    end
    for _, part in ipairs(noclipParts) do
        if part.Parent and part.CanCollide then
            part.CanCollide = false
        end
    end
end

local lastSafePosition = CFrame.new(0, 50, 0)

local function antiFallLoop()
    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = Player.Character.HumanoidRootPart

    if hrp.Position.Y > 0 then
        lastSafePosition = hrp.CFrame
    end

    if not E.Movement.AntiFall then return end
    if hrp.Position.Y < -50 then
        hrp.CFrame = lastSafePosition
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end

-- ============================================================
-- FLY ENGINE
-- ============================================================
local flyBodyVelocity = nil
local flyBodyGyro = nil

local function startFly()
    if not Player.Character then return end
    local hrp = Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if flyBodyVelocity then pcall(function() flyBodyVelocity:Destroy() end) end
    if flyBodyGyro then pcall(function() flyBodyGyro:Destroy() end) end

    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 9e4
    flyBodyGyro.D = 1000
    flyBodyGyro.Parent = hrp

    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = true
    end
end

local function stopFly()
    if flyBodyVelocity then
        pcall(function() flyBodyVelocity:Destroy() end)
        flyBodyVelocity = nil
    end
    if flyBodyGyro then
        pcall(function() flyBodyGyro:Destroy() end)
        flyBodyGyro = nil
    end
    if Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.PlatformStand = false
        end
    end
end

local function flyLoop()
    if not E.Movement.Fly then
        if flyBodyVelocity then stopFly() end
        return
    end

    if not flyBodyVelocity or not flyBodyVelocity.Parent then
        startFly()
    end
    if not flyBodyVelocity then return end

    local direction = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end

    if direction.Magnitude > 0 then
        direction = direction.Unit * E.Movement.FlySpeed
    end

    flyBodyVelocity.Velocity = direction
    flyBodyGyro.CFrame = Camera.CFrame
end

-- ============================================================
-- CHARACTER FEATURES
-- ============================================================
track(UserInputService.JumpRequest:Connect(function()
    if E.Character.InfiniteJump and Player.Character then
        local hum = Player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local noSlowApplied = false
local function noSlowdownLoop()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if E.Character.NoSlowdown then
        noSlowApplied = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, false)
    elseif noSlowApplied then
        noSlowApplied = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
        hum:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics, true)
    end
end

local autoClickThread = nil

local function startAutoClick()
    if autoClickThread then return end
    autoClickThread = task.spawn(function()
        while E.Character.AutoClick do
            pcall(function()
                mouse1click()
            end)
            task.wait(E.Character.ClickInterval)
        end
        autoClickThread = nil
    end)
end

local function stopAutoClick()
    E.Character.AutoClick = false
    autoClickThread = nil
end

local godApplied = false
local function godModeLoop()
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if E.Character.GodMode then
        godApplied = true
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    elseif godApplied then
        godApplied = false
        hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
    end
end

-- ============================================================
-- VISUALS ENGINE
-- ============================================================
local originalBrightness = Lighting.Brightness
local originalFogEnd = Lighting.FogEnd
local originalFogStart = Lighting.FogStart
local originalAmbient = Lighting.Ambient
local originalOutdoorAmbient = Lighting.OutdoorAmbient
local originalClockTime = Lighting.ClockTime
local originalGlobalShadows = Lighting.GlobalShadows

local function setEffects(enabled)
    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("Atmosphere") or effect:IsA("BloomEffect") or effect:IsA("ColorCorrectionEffect") then
            effect.Enabled = enabled
        end
    end
end

local function applyVisuals()
    if E.Visuals.FullBright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.GlobalShadows = false
        setEffects(false)
    else
        Lighting.Brightness = originalBrightness
        Lighting.Ambient = originalAmbient
        Lighting.OutdoorAmbient = originalOutdoorAmbient
        Lighting.GlobalShadows = originalGlobalShadows
        setEffects(true)
    end

    if E.Visuals.NoFog then
        Lighting.FogEnd = 1e10
        Lighting.FogStart = 1e10
    else
        Lighting.FogEnd = originalFogEnd
        Lighting.FogStart = originalFogStart
    end

    if E.Visuals.NightMode then
        Lighting.ClockTime = 0
    else
        Lighting.ClockTime = originalClockTime
    end

    if Camera then
        Camera.FieldOfView = E.Visuals.FOV
    end
end

-- ============================================================
-- ANTI AFK
-- ============================================================
track(Player.Idled:Connect(function()
    if E.Misc.AntiAFK then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end))

-- ============================================================
-- SERVER HOP / CHAT SPAM / TELEPORT
-- ============================================================
local function serverHop()
    local success, servers = pcall(function()
        return HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/" .. game.GameId .. "/servers/Public?sortOrder=Asc&limit=100")
        )
    end)

    if not success or not servers or not servers.data then
        notify("Server Hop", "Failed to fetch servers!", "error")
        return
    end

    for _, server in ipairs(servers.data) do
        if server.id ~= game.JobId and server.playing < server.maxPlayers then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
            return
        end
    end

    notify("Server Hop", "No available servers found!", "warning")
end

local chatSpamThread = nil

local function startChatSpam()
    if chatSpamThread then return end
    chatSpamThread = task.spawn(function()
        while E.Misc.ChatSpam do
            pcall(function()
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(E.Misc.ChatMessage, "All")
            end)
            task.wait(E.Misc.ChatInterval)
        end
        chatSpamThread = nil
    end)
end

local function stopChatSpam()
    E.Misc.ChatSpam = false
    chatSpamThread = nil
end

local function teleportToPlayer(targetName)
    local query = targetName:lower()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and (plr.Name:lower():find(query, 1, true) or plr.DisplayName:lower():find(query, 1, true)) then
            local theirRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local myRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot and myRoot then
                myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, 3, 0)
                notify("Teleport", "Teleported to " .. plr.DisplayName, "check_circle", 2)
                return
            end
        end
    end
    notify("Teleport", "Player not found!", "error", 2)
end

local TOGGLE_FLAGS = {
    "AimbotEnabled", "ESPEnabled", "Fly", "NoClip", "AntiFall", "InfiniteJump",
    "NoSlowdown", "GodMode", "AutoClick", "FullBright", "NoFog", "NightMode", "ChatSpam"
}

local function disableAllFeatures()
    E.Aimbot.Enabled = false
    E.ESP.Enabled = false
    E.Movement.NoClip = false
    E.Movement.AntiFall = false
    E.Movement.Fly = false
    E.Character.InfiniteJump = false
    E.Character.NoSlowdown = false
    E.Character.AutoClick = false
    E.Character.GodMode = false
    E.Visuals.FullBright = false
    E.Visuals.NoFog = false
    E.Visuals.NightMode = false
    E.Misc.ChatSpam = false
    stopFly()
    stopAutoClick()
    stopChatSpam()
    applyVisuals()

    -- samakan tampilan toggle di menu dengan kondisi sebenarnya
    for _, flag in ipairs(TOGGLE_FLAGS) do
        local option = Exter.Options and Exter.Options[flag]
        if option and option.UpdateState then
            pcall(function() option:UpdateState(false) end)
        end
    end
end

-- ============================================================
-- LOOP ENGINE
-- ============================================================
track(RunService.RenderStepped:Connect(function()
    updateFOV()
    espLoop()
    flyLoop()
    noclipLoop()
    antiFallLoop()
    godModeLoop()
    noSlowdownLoop()
end))

local visualStateCache = {}
track(RunService.Heartbeat:Connect(function()
    local V = E.Visuals
    if visualStateCache.FullBright ~= V.FullBright
        or visualStateCache.NoFog ~= V.NoFog
        or visualStateCache.NightMode ~= V.NightMode
        or visualStateCache.FOV ~= V.FOV then
        visualStateCache.FullBright = V.FullBright
        visualStateCache.NoFog = V.NoFog
        visualStateCache.NightMode = V.NightMode
        visualStateCache.FOV = V.FOV
        applyVisuals()
    end
end))

track(RunService.Stepped:Connect(function()
    applyMovement()
end))

-- ============================================================
-- UI WINDOW
-- ============================================================
local Window = Exter:CreateWindow({
    Name = "Exter Universal",
    Subtitle = "v1.3.0 - Premium Edition",
    Bind = Enum.KeyCode.K,
    ConfigSettings = {
        ConfigFolder = "ExterUniversal",
        RootFolder = "ExterConfigs"
    }
})

-- ============================================================
-- TAB: AIMBOT
-- ============================================================
local AimbotTab = Window:CreateTab({ Name = "Aimbot", Icon = "gavel", ImageSource = "Material" })

AimbotTab:CreateSection("Main Settings")

AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    Description = "Tahan klik kanan (scope) untuk mengunci ke badan target",
    CurrentValue = E.Aimbot.Enabled,
    Callback = function(v) E.Aimbot.Enabled = v end
}, "AimbotEnabled")

AimbotTab:CreateToggle({
    Name = "Sticky Target",
    Description = "Tetap di satu target selama tombol ditahan",
    CurrentValue = E.Aimbot.StickyTarget,
    Callback = function(v) E.Aimbot.StickyTarget = v end
}, "AimbotSticky")

AimbotTab:CreateSlider({
    Name = "Hit Chance",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = E.Aimbot.HitChance,
    Callback = function(v) E.Aimbot.HitChance = v end
}, "AimbotHitChance")

AimbotTab:CreateSlider({
    Name = "Smoothness (0 = Instant)",
    Range = {0, 20},
    Increment = 1,
    CurrentValue = E.Aimbot.Smoothness,
    Callback = function(v) E.Aimbot.Smoothness = v end
}, "AimbotSmoothness")

AimbotTab:CreateSection("Targeting")

AimbotTab:CreateToggle({
    Name = "Target Players",
    CurrentValue = E.Aimbot.TargetPlayers,
    Callback = function(v) E.Aimbot.TargetPlayers = v end
}, "AimbotPlayers")

AimbotTab:CreateToggle({
    Name = "Target NPCs",
    CurrentValue = E.Aimbot.TargetNPCs,
    Callback = function(v) E.Aimbot.TargetNPCs = v end
}, "AimbotNPCs")

AimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Body", "Head", "HumanoidRootPart", "Random"},
    CurrentOption = {E.Aimbot.SelectedPart},
    MultipleOptions = false,
    Callback = function(v) E.Aimbot.SelectedPart = resolveOptionValue(v) end
}, "AimbotPart")

AimbotTab:CreateDropdown({
    Name = "Trigger Key",
    Options = {"MouseButton2", "MouseButton1", "E", "Q", "F", "C", "X"},
    CurrentOption = {E.Aimbot.TargetKey},
    MultipleOptions = false,
    Callback = function(v) E.Aimbot.TargetKey = resolveOptionValue(v) end
}, "AimbotKey")

AimbotTab:CreateDropdown({
    Name = "Aim Method",
    Description = "Camera = putar kamera. Mouse = geser mouse (game FPS dengan kamera custom)",
    Options = {"Camera", "Mouse"},
    CurrentOption = {E.Aimbot.AimMethod},
    MultipleOptions = false,
    Callback = function(v) E.Aimbot.AimMethod = resolveOptionValue(v) end
}, "AimbotMethod")

AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = E.Aimbot.TeamCheck,
    Callback = function(v) E.Aimbot.TeamCheck = v end
}, "AimbotTeamCheck")

AimbotTab:CreateToggle({
    Name = "Visibility Check",
    Description = "Tidak mengunci target yang terhalang tembok",
    CurrentValue = E.Aimbot.VisibilityCheck,
    Callback = function(v) E.Aimbot.VisibilityCheck = v end
}, "AimbotVisibility")

AimbotTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 5000},
    Increment = 50,
    CurrentValue = E.Aimbot.MaxDistance,
    Callback = function(v) E.Aimbot.MaxDistance = v end
}, "AimbotMaxDistance")

AimbotTab:CreateSection("Prediction")

AimbotTab:CreateToggle({
    Name = "Enable Prediction",
    CurrentValue = E.Aimbot.Prediction,
    Callback = function(v) E.Aimbot.Prediction = v end
}, "AimbotPrediction")

AimbotTab:CreateSlider({
    Name = "Prediction Amount",
    Range = {0, 1},
    Increment = 0.01,
    CurrentValue = E.Aimbot.PredictionAmount,
    Callback = function(v) E.Aimbot.PredictionAmount = v end
}, "AimbotPredictionAmount")

AimbotTab:CreateSection("FOV Settings")

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = E.Aimbot.FOVRadius,
    Callback = function(v) E.Aimbot.FOVRadius = v end
}, "AimbotFOV")

AimbotTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = E.Aimbot.ShowFOV,
    Callback = function(v) E.Aimbot.ShowFOV = v end
}, "AimbotShowFOV")

-- ============================================================
-- TAB: ESP
-- ============================================================
local ESPTab = Window:CreateTab({ Name = "ESP", Icon = "visibility", ImageSource = "Material" })

ESPTab:CreateSection("Main Settings")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = E.ESP.Enabled,
    Callback = function(v) E.ESP.Enabled = v end
}, "ESPEnabled")

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 50,
    CurrentValue = E.ESP.MaxDistance,
    Callback = function(v) E.ESP.MaxDistance = v end
}, "ESPMaxDistance")

ESPTab:CreateSection("ESP Elements")

ESPTab:CreateToggle({ Name = "Boxes", CurrentValue = E.ESP.Boxes, Callback = function(v) E.ESP.Boxes = v end }, "ESPBoxes")
ESPTab:CreateToggle({ Name = "Health Bar", CurrentValue = E.ESP.HealthBar, Callback = function(v) E.ESP.HealthBar = v end }, "ESPHealth")
ESPTab:CreateToggle({ Name = "Name Tags", CurrentValue = E.ESP.NameTag, Callback = function(v) E.ESP.NameTag = v end }, "ESPNames")
ESPTab:CreateToggle({ Name = "Tracers", CurrentValue = E.ESP.Tracers, Callback = function(v) E.ESP.Tracers = v end }, "ESPTracers")
ESPTab:CreateToggle({ Name = "Show Distance", CurrentValue = E.ESP.Distance, Callback = function(v) E.ESP.Distance = v end }, "ESPDistance")
ESPTab:CreateToggle({ Name = "Team Color", CurrentValue = E.ESP.TeamColor, Callback = function(v) E.ESP.TeamColor = v end }, "ESPTeamColor")

-- ============================================================
-- TAB: MOVEMENT
-- ============================================================
local MovementTab = Window:CreateTab({ Name = "Movement", Icon = "open_with", ImageSource = "Material" })

MovementTab:CreateSection("Speed & Jump")

MovementTab:CreateSlider({
    Name = "Walkspeed",
    Range = {1, 250},
    Increment = 1,
    CurrentValue = E.Movement.Walkspeed,
    Callback = function(v) E.Movement.Walkspeed = v end
}, "Walkspeed")

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = E.Movement.JumpPower,
    Callback = function(v) E.Movement.JumpPower = v end
}, "JumpPower")

MovementTab:CreateSection("Fly")

MovementTab:CreateToggle({
    Name = "Enable Fly (WASD + Space/Shift)",
    CurrentValue = E.Movement.Fly,
    Callback = function(v)
        E.Movement.Fly = v
        if not v then stopFly() end
    end
}, "Fly")

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = E.Movement.FlySpeed,
    Callback = function(v) E.Movement.FlySpeed = v end
}, "FlySpeed")

MovementTab:CreateSection("Utilities")

MovementTab:CreateToggle({ Name = "NoClip", CurrentValue = E.Movement.NoClip, Callback = function(v) E.Movement.NoClip = v end }, "NoClip")
MovementTab:CreateToggle({ Name = "Anti Fall", CurrentValue = E.Movement.AntiFall, Callback = function(v) E.Movement.AntiFall = v end }, "AntiFall")

-- ============================================================
-- TAB: CHARACTER
-- ============================================================
local CharTab = Window:CreateTab({ Name = "Character", Icon = "account_circle", ImageSource = "Material" })

CharTab:CreateSection("Character Options")

CharTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = E.Character.InfiniteJump, Callback = function(v) E.Character.InfiniteJump = v end }, "InfiniteJump")
CharTab:CreateToggle({ Name = "No Slowdown", CurrentValue = E.Character.NoSlowdown, Callback = function(v) E.Character.NoSlowdown = v end }, "NoSlowdown")
CharTab:CreateToggle({ Name = "God Mode (Client-Side)", CurrentValue = E.Character.GodMode, Callback = function(v) E.Character.GodMode = v end }, "GodMode")

CharTab:CreateSection("Auto Click")

CharTab:CreateToggle({
    Name = "Auto Click",
    CurrentValue = E.Character.AutoClick,
    Callback = function(v)
        E.Character.AutoClick = v
        if v then
            startAutoClick()
        else
            stopAutoClick()
        end
    end
}, "AutoClick")

CharTab:CreateSlider({
    Name = "Click Interval (ms)",
    Range = {50, 500},
    Increment = 10,
    CurrentValue = E.Character.ClickInterval * 1000,
    Callback = function(v) E.Character.ClickInterval = v / 1000 end
}, "ClickInterval")

-- ============================================================
-- TAB: VISUALS
-- ============================================================
local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = "perm_media", ImageSource = "Material" })

VisualsTab:CreateSection("Visual Settings")

VisualsTab:CreateSlider({
    Name = "Field of View",
    Range = {30, 120},
    Increment = 1,
    CurrentValue = E.Visuals.FOV,
    Callback = function(v) E.Visuals.FOV = v end
}, "FOV")

VisualsTab:CreateToggle({ Name = "Full Bright", CurrentValue = E.Visuals.FullBright, Callback = function(v) E.Visuals.FullBright = v end }, "FullBright")
VisualsTab:CreateToggle({ Name = "Remove Fog", CurrentValue = E.Visuals.NoFog, Callback = function(v) E.Visuals.NoFog = v end }, "NoFog")
VisualsTab:CreateToggle({ Name = "Night Mode", CurrentValue = E.Visuals.NightMode, Callback = function(v) E.Visuals.NightMode = v end }, "NightMode")

-- ============================================================
-- TAB: MISC
-- ============================================================
local MiscTab = Window:CreateTab({ Name = "Misc", Icon = "settings", ImageSource = "Material" })

MiscTab:CreateSection("Server Options")

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Description = "Kick & rejoin current server",
    Callback = E.Misc.Rejoin
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Description = "Join a different server",
    Callback = serverHop
})

MiscTab:CreateToggle({ Name = "Anti AFK", CurrentValue = E.Misc.AntiAFK, Callback = function(v) E.Misc.AntiAFK = v end }, "AntiAFK")

MiscTab:CreateSection("Teleport")

MiscTab:CreateInput({
    Name = "Teleport to Player",
    PlaceholderText = "Enter player name...",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        if text and text ~= "" then
            teleportToPlayer(text)
        end
    end
})

MiscTab:CreateSection("Chat Spam")

MiscTab:CreateToggle({
    Name = "Chat Spam",
    CurrentValue = E.Misc.ChatSpam,
    Callback = function(v)
        E.Misc.ChatSpam = v
        if v then
            startChatSpam()
        else
            stopChatSpam()
        end
    end
}, "ChatSpam")

MiscTab:CreateInput({
    Name = "Spam Message",
    PlaceholderText = "Enter message...",
    RemoveTextAfterFocusLost = true,
    Callback = function(text)
        if text and text ~= "" then
            E.Misc.ChatMessage = text
        end
    end
})

MiscTab:CreateSlider({
    Name = "Spam Interval (sec)",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = E.Misc.ChatInterval,
    Callback = function(v) E.Misc.ChatInterval = v end
}, "ChatInterval")

MiscTab:CreateSection("Config")

MiscTab:BuildConfigSection()
MiscTab:BuildThemeSection()

MiscTab:CreateSection("Quick Actions")

MiscTab:CreateButton({
    Name = "Panic: Disable All Features",
    Description = "Emergency stop for all active enhancements",
    Callback = function()
        disableAllFeatures()
        notify("Panic Mode", "All features have been disabled.", "warning")
    end
})

MiscTab:CreateButton({
    Name = "Reset Movement Defaults",
    Description = "Restore Walkspeed 16 / JumpPower 50",
    Callback = function()
        E.Movement.Walkspeed = 16
        E.Movement.JumpPower = 50
        applyMovement()
        notify("Movement", "Movement defaults restored.", "check_circle", 2)
    end
})

MiscTab:CreateSection("Credits")

MiscTab:CreateLabel({ Text = "Exter Universal v1.3.0" })
MiscTab:CreateLabel({ Text = "Powered by Exter Library" })
MiscTab:CreateLabel({ Text = "by SOBING4413 - Exter Interactive" })

-- ============================================================
-- STARTUP
-- ============================================================
notify("Exter Universal v1.3.0", "Loaded! Press K to toggle menu.", "check_circle", 5)

applyVisuals()

pcall(function()
    Exter:LoadAutoloadConfig()
end)

track(UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == E.Misc.PanicKey then
        disableAllFeatures()
        notify("Panic Key", "Emergency disable triggered (P).", "warning")
    end
end))

env.ExterUniversalUnload = function()
    disableAllFeatures()
    pcall(function() RunService:UnbindFromRenderStep("ExterUniversalAim") end)
    for _, conn in ipairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, obj in pairs(ESPObjects) do
        for _, drawing in pairs(obj) do
            pcall(function() drawing:Remove() end)
        end
    end
    if FOVCircle then pcall(function() FOVCircle:Remove() end) end
    pcall(function() Exter:Destroy() end)
    env.ExterUniversalUnload = nil
end
