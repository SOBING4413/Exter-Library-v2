local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Exter = {}
Exter.__index = Exter

-- ═══════════════════════════════════════════════════════════════
-- THEME - Fixed colors for readability
-- ═══════════════════════════════════════════════════════════════
local Theme = {
    Background    = Color3.fromRGB(15, 15, 22),
    Surface       = Color3.fromRGB(22, 24, 34),
    Surface2      = Color3.fromRGB(30, 33, 46),
    Surface3      = Color3.fromRGB(38, 42, 58),
    Border        = Color3.fromRGB(50, 56, 78),
    Text          = Color3.fromRGB(240, 242, 250),      -- bright white for main text
    TextDim       = Color3.fromRGB(170, 178, 200),       -- readable dim text (NOT blue)
    TextMuted     = Color3.fromRGB(120, 128, 150),       -- muted but still readable
    Accent        = Color3.fromRGB(130, 100, 255),       -- purple accent
    Accent2       = Color3.fromRGB(80, 170, 255),        -- blue accent
    AccentGlow    = Color3.fromRGB(100, 80, 220),
    Success       = Color3.fromRGB(72, 210, 145),
    Error         = Color3.fromRGB(220, 70, 70),
    Warning       = Color3.fromRGB(255, 190, 60),
    SliderTrack   = Color3.fromRGB(55, 60, 78),
    ToggleOff     = Color3.fromRGB(65, 70, 88),
    InputBg       = Color3.fromRGB(42, 46, 62),
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════
local function Create(instanceType, props)
    local obj = Instance.new(instanceType)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

local function Round(num, bracket)
    bracket = bracket or 1
    return math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket
end

local function Tween(obj, t, props, style, dir)
    local tw = TweenService:Create(
        obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props
    )
    tw:Play()
    return tw
end

local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

local function AddGradient(parent, c1, c2, rot)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1 or Theme.Accent, c2 or Theme.Accent2),
        Rotation = rot or 45,
        Parent = parent,
    })
end

local function AddPadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    })
end

local function MakeDraggable(topbar, target)
    local dragging = false
    local dragStart, startPos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function MakeResizable(resizeHandle, target, minSize, maxSize)
    local dragging = false
    local dragStart, startSize

    minSize = minSize or Vector2.new(480, 360)
    maxSize = maxSize or Vector2.new(1000, 700)

    resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startSize = target.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newW = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            target.Size = UDim2.fromOffset(newW, newH)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ═══════════════════════════════════════════════════════════════
local function ShowLoadingScreen(screen, config)
    local loadingTitle = config.LoadingTitle or config.Title or "Exter Hub"
    local loadingSubtitle = config.LoadingSubtitle or "Initializing..."

    local loadingFrame = Create("Frame", {
        Name = "LoadingScreen",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(8, 8, 14),
        BackgroundTransparency = 0,
        ZIndex = 100,
        Parent = screen,
    })

    -- Background gradient overlay
    local bgOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.85,
        ZIndex = 101,
        Parent = loadingFrame,
    })
    AddGradient(bgOverlay, Theme.Accent, Theme.Accent2, 135)

    -- Center container
    local centerContainer = Create("Frame", {
        Size = UDim2.fromOffset(400, 200),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 102,
        Parent = loadingFrame,
    })

    -- Logo / Icon circle
    local logoCircle = Create("Frame", {
        Size = UDim2.fromOffset(70, 70),
        Position = UDim2.new(0.5, -35, 0, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 103,
        Parent = centerContainer,
    })
    AddCorner(logoCircle, 999)
    AddGradient(logoCircle, Theme.Accent, Theme.Accent2, 45)

    local logoText = Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "E",
        Font = Enum.Font.GothamBold,
        TextSize = 36,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 104,
        Parent = logoCircle,
    })

    -- Title
    local titleLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.fromOffset(0, 82),
        BackgroundTransparency = 1,
        Text = loadingTitle,
        Font = Enum.Font.GothamBold,
        TextSize = 28,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 103,
        Parent = centerContainer,
    })

    -- Subtitle
    local subLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.fromOffset(0, 118),
        BackgroundTransparency = 1,
        Text = loadingSubtitle,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextColor3 = Theme.TextDim,
        ZIndex = 103,
        Parent = centerContainer,
    })

    -- Progress bar background
    local progressBg = Create("Frame", {
        Size = UDim2.new(0.7, 0, 0, 6),
        Position = UDim2.new(0.15, 0, 0, 155),
        BackgroundColor3 = Color3.fromRGB(40, 42, 55),
        ZIndex = 103,
        Parent = centerContainer,
    })
    AddCorner(progressBg, 999)

    -- Progress bar fill
    local progressFill = Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 104,
        Parent = progressBg,
    })
    AddCorner(progressFill, 999)
    AddGradient(progressFill, Theme.Accent, Theme.Accent2, 0)

    -- Status text
    local statusLabel = Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.fromOffset(0, 170),
        BackgroundTransparency = 1,
        Text = "Loading modules...",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.TextMuted,
        ZIndex = 103,
        Parent = centerContainer,
    })

    -- Animate loading
    local loadingSteps = {
        {progress = 0.15, text = "Loading modules..."},
        {progress = 0.35, text = "Initializing UI..."},
        {progress = 0.55, text = "Setting up features..."},
        {progress = 0.75, text = "Connecting services..."},
        {progress = 0.90, text = "Almost ready..."},
        {progress = 1.00, text = "Welcome!"},
    }

    -- Logo pulse animation
    task.spawn(function()
        while loadingFrame and loadingFrame.Parent do
            Tween(logoCircle, 0.8, {Size = UDim2.fromOffset(76, 76), Position = UDim2.new(0.5, -38, 0, -3)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
            if not (loadingFrame and loadingFrame.Parent) then break end
            Tween(logoCircle, 0.8, {Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0.5, -35, 0, 0)}, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
        end
    end)

    -- Progress animation
    for i, step in ipairs(loadingSteps) do
        statusLabel.Text = step.text
        Tween(progressFill, 0.4, {Size = UDim2.new(step.progress, 0, 1, 0)})
        task.wait(0.35 + math.random() * 0.2)
    end

    task.wait(0.3)

    -- Fade out
    Tween(loadingFrame, 0.5, {BackgroundTransparency = 1})
    for _, child in pairs(loadingFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            Tween(child, 0.4, {TextTransparency = 1})
        elseif child:IsA("Frame") then
            Tween(child, 0.4, {BackgroundTransparency = 1})
        end
    end

    task.wait(0.55)
    loadingFrame:Destroy()
end

-- ═══════════════════════════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════
function Exter:CreateWindow(config)
    config = config or {}

    local title = config.Title or "Exter Premium"
    local subtitle = config.Subtitle or "UI Library"
    local size = config.Size or UDim2.fromOffset(660, 460)
    local loadingEnabled = config.LoadingEnabled ~= false
    local windowTransparency = math.clamp(config.WindowTransparency or 0.05, 0, 0.9)
    local panelTransparency = math.clamp(config.PanelTransparency or 0.02, 0, 0.9)

    -- ScreenGui
    local screen = Create("ScreenGui", {
        Name = "ExterPremiumUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })

    -- Show loading screen first
    if loadingEnabled then
        ShowLoadingScreen(screen, config)
    end

    -- Main holder
    local holder = Create("Frame", {
        Name = "Holder",
        Size = size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = windowTransparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = screen,
    })
    AddCorner(holder, 14)
    AddStroke(holder, Theme.Border, 1.5, 0)

    -- Shadow
    local shadow = Create("ImageLabel", {
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.fromOffset(-20, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6015897843",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.5,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        ZIndex = -1,
        Parent = holder,
    })

    -- ═══════════════════════════════════════
    -- TOPBAR
    -- ═══════════════════════════════════════
    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, -16, 0, 52),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = panelTransparency,
        BorderSizePixel = 0,
        Parent = holder,
    })
    AddCorner(topbar, 10)
    AddStroke(topbar, Theme.Border, 1, 0)

    -- Accent line on top of topbar
    local accentLine = Create("Frame", {
        Size = UDim2.new(0.4, 0, 0, 2),
        Position = UDim2.new(0.3, 0, 0, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    AddCorner(accentLine, 999)
    AddGradient(accentLine, Theme.Accent, Theme.Accent2, 0)

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 22),
        Position = UDim2.fromOffset(16, 7),
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Text,
        Parent = topbar,
    })

    local subtitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 14),
        Position = UDim2.fromOffset(16, 29),
        Text = subtitle,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.TextMuted,
        Parent = topbar,
    })

    -- Topbar buttons container
    local topBtnContainer = Create("Frame", {
        Size = UDim2.fromOffset(110, 34),
        Position = UDim2.new(1, -120, 0.5, -17),
        BackgroundTransparency = 1,
        Parent = topbar,
    })

    local topBtnLayout = Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = topBtnContainer,
    })

    -- Helper: create topbar icon button
    local function CreateTopbarButton(text, tooltip, parent)
        local btn = Create("TextButton", {
            Size = UDim2.fromOffset(32, 32),
            BackgroundColor3 = Theme.Surface2,
            AutoButtonColor = false,
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = Theme.TextDim,
            Parent = parent,
        })
        AddCorner(btn, 8)
        AddStroke(btn, Theme.Border, 1, 0)

        btn.MouseEnter:Connect(function()
            Tween(btn, 0.12, {BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.Text})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.12, {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.TextDim})
        end)

        return btn
    end

    -- Minimize button
    local minimized = false
    local savedSize = nil
    local minimizeBtn = CreateTopbarButton("—", "Minimize", topBtnContainer)

    -- Unload button
    local unloadBtn = CreateTopbarButton("⏻", "Unload", topBtnContainer)

    -- Close button
    local closeBtn = CreateTopbarButton("✕", "Close", topBtnContainer)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.12, {BackgroundColor3 = Theme.Error, TextColor3 = Theme.Text})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.12, {BackgroundColor3 = Theme.Surface2, TextColor3 = Theme.TextDim})
    end)

    -- ═══════════════════════════════════════
    -- BODY
    -- ═══════════════════════════════════════
    local body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -16, 1, -68),
        Position = UDim2.fromOffset(8, 62),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = holder,
    })

    -- Tab sidebar
    local tabSidebar = Create("Frame", {
        Name = "TabSidebar",
        Size = UDim2.new(0, 160, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = panelTransparency,
        BorderSizePixel = 0,
        Parent = body,
    })
    AddCorner(tabSidebar, 10)
    AddStroke(tabSidebar, Theme.Border, 1, 0)

    local tabScroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.fromOffset(5, 5),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarThickness = 3,
        BackgroundTransparency = 1,
        Parent = tabSidebar,
    })

    local tabList = Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabScroll,
    })

    AddPadding(tabScroll, 6, 6, 4, 4)

    tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabScroll.CanvasSize = UDim2.fromOffset(0, tabList.AbsoluteContentSize.Y + 16)
    end)

    -- Content area
    local contentArea = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -168, 1, 0),
        Position = UDim2.fromOffset(168, 0),
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = panelTransparency,
        BorderSizePixel = 0,
        Parent = body,
    })
    AddCorner(contentArea, 10)
    AddStroke(contentArea, Theme.Border, 1, 0)

    -- ═══════════════════════════════════════
    -- RESIZE HANDLE (bottom-right corner)
    -- ═══════════════════════════════════════
    local resizeHandle = Create("TextButton", {
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -20, 1, -20),
        BackgroundTransparency = 1,
        Text = "⋱",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.TextMuted,
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = holder,
    })

    resizeHandle.MouseEnter:Connect(function()
        Tween(resizeHandle, 0.1, {TextColor3 = Theme.Accent})
    end)
    resizeHandle.MouseLeave:Connect(function()
        Tween(resizeHandle, 0.1, {TextColor3 = Theme.TextMuted})
    end)

    MakeResizable(resizeHandle, holder, Vector2.new(500, 360), Vector2.new(1000, 700))

    -- ═══════════════════════════════════════
    -- NOTIFICATION SYSTEM
    -- ═══════════════════════════════════════
    local notificationHolder = Create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -330, 0, 10),
        Parent = screen,
    })

    Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = notificationHolder,
    })

    -- ═══════════════════════════════════════
    -- WINDOW OBJECT
    -- ═══════════════════════════════════════
    local window = {
        _screen = screen,
        _holder = holder,
        _body = body,
        _contentArea = contentArea,
        _tabScroll = tabScroll,
        _tabSidebar = tabSidebar,
        _activeTab = nil,
        _tabs = {},
        _notifHolder = notificationHolder,
        _panelTransparency = panelTransparency,
        _windowTransparency = windowTransparency,
        _unloadCallbacks = {},
    }

    -- ═══════════════════════════════════════
    -- MINIMIZE LOGIC
    -- ═══════════════════════════════════════
    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedSize = holder.Size
            body.Visible = false
            resizeHandle.Visible = false
            Tween(holder, 0.25, {Size = UDim2.fromOffset(holder.AbsoluteSize.X, 68)})
            minimizeBtn.Text = "+"
        else
            body.Visible = true
            resizeHandle.Visible = true
            Tween(holder, 0.25, {Size = savedSize or size})
            minimizeBtn.Text = "—"
        end
    end)

    -- ═══════════════════════════════════════
    -- CLOSE LOGIC
    -- ═══════════════════════════════════════
    closeBtn.MouseButton1Click:Connect(function()
        Tween(holder, 0.3, {Size = UDim2.fromOffset(holder.AbsoluteSize.X, 0)})
        task.wait(0.35)
        screen:Destroy()
    end)

    -- ═══════════════════════════════════════
    -- UNLOAD LOGIC
    -- ═══════════════════════════════════════
    unloadBtn.MouseButton1Click:Connect(function()
        -- Call all registered unload callbacks
        for _, cb in ipairs(window._unloadCallbacks) do
            pcall(cb)
        end
        -- Animate out
        Tween(holder, 0.3, {BackgroundTransparency = 1})
        for _, child in pairs(holder:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                pcall(function() Tween(child, 0.25, {TextTransparency = 1}) end)
            end
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                pcall(function() Tween(child, 0.25, {BackgroundTransparency = 1}) end)
            end
        end
        task.wait(0.35)
        screen:Destroy()
    end)

    -- ═══════════════════════════════════════
    -- NOTIFY
    -- ═══════════════════════════════════════
    function window:Notify(cfg)
        cfg = cfg or {}
        local nTitle = cfg.Title or "Notification"
        local nText = cfg.Content or ""
        local duration = cfg.Duration or 3
        local nType = cfg.Type or "info" -- info, success, error, warning

        local accentColor = Theme.Accent
        if nType == "success" then accentColor = Theme.Success
        elseif nType == "error" then accentColor = Theme.Error
        elseif nType == "warning" then accentColor = Theme.Warning end

        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            Parent = notificationHolder,
        })
        AddCorner(card, 10)
        AddStroke(card, Theme.Border, 1, 0)

        -- Accent line
        local line = Create("Frame", {
            Size = UDim2.new(0, 4, 1, -12),
            Position = UDim2.fromOffset(6, 6),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            Parent = card,
        })
        AddCorner(line, 999)

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(18, 10),
            Size = UDim2.new(1, -28, 0, 18),
            Text = nTitle,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Text,
            Parent = card,
        })

        Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(18, 30),
            Size = UDim2.new(1, -28, 0, 34),
            Text = nText,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextColor3 = Theme.TextDim,
            Parent = card,
        })

        -- Animate in
        card.BackgroundTransparency = 1
        local origPos = card.Position
        card.Position = origPos + UDim2.fromOffset(40, 0)
        Tween(card, 0.25, {BackgroundTransparency = 0, Position = origPos})

        -- Fade children in
        for _, child in pairs(card:GetDescendants()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
                Tween(child, 0.25, {TextTransparency = 0})
            elseif child:IsA("Frame") then
                local origTrans = child.BackgroundTransparency
                child.BackgroundTransparency = 1
                Tween(child, 0.25, {BackgroundTransparency = origTrans})
            end
        end

        task.delay(duration, function()
            if card and card.Parent then
                Tween(card, 0.25, {BackgroundTransparency = 1, Position = origPos + UDim2.fromOffset(40, 0)})
                for _, child in pairs(card:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        Tween(child, 0.2, {TextTransparency = 1})
                    elseif child:IsA("Frame") then
                        Tween(child, 0.2, {BackgroundTransparency = 1})
                    end
                end
                task.wait(0.3)
                if card and card.Parent then card:Destroy() end
            end
        end)
    end

    -- ═══════════════════════════════════════
    -- ON UNLOAD CALLBACK
    -- ═══════════════════════════════════════
    function window:OnUnload(callback)
        table.insert(window._unloadCallbacks, callback)
    end

    -- ═══════════════════════════════════════
    -- CREATE TAB BUTTON
    -- ═══════════════════════════════════════
    local function createTabButton(name)
        local btn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = Theme.Surface2,
            BackgroundTransparency = 0.3,
            AutoButtonColor = false,
            Text = "",
            Parent = tabScroll,
        })
        AddCorner(btn, 8)

        -- Active indicator
        local indicator = Create("Frame", {
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0),
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = btn,
        })
        AddCorner(indicator, 999)
        AddGradient(indicator, Theme.Accent, Theme.Accent2, 90)

        local label = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 1, 0),
            Position = UDim2.fromOffset(14, 0),
            Text = name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.TextMuted,
            Parent = btn,
        })

        btn.MouseEnter:Connect(function()
            if window._activeTab and window._activeTab.button == btn then return end
            Tween(btn, 0.12, {BackgroundTransparency = 0.15})
            Tween(label, 0.12, {TextColor3 = Theme.TextDim})
        end)
        btn.MouseLeave:Connect(function()
            if window._activeTab and window._activeTab.button == btn then return end
            Tween(btn, 0.12, {BackgroundTransparency = 0.3})
            Tween(label, 0.12, {TextColor3 = Theme.TextMuted})
        end)

        return btn, label, indicator
    end

    -- ═══════════════════════════════════════
    -- CREATE TAB
    -- ═══════════════════════════════════════
    function window:CreateTab(name)
        local tabName = name or "Tab"

        local btn, btnLabel, btnIndicator = createTabButton(tabName)

        local page = Create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.fromOffset(8, 8),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarThickness = 3,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = contentArea,
        })

        local layout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = page,
        })

        AddPadding(page, 2, 6, 0, 0)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 12)
        end)

        local tab = {
            _page = page,
            _layout = layout,
            _window = window,
        }

        -- Base control creator
        local function createBaseControl(height)
            local container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.Surface2,
                BackgroundTransparency = panelTransparency + 0.02,
                BorderSizePixel = 0,
                Parent = page,
            })
            AddCorner(container, 8)
            AddStroke(container, Theme.Border, 1, 0.3)
            return container
        end

        -- ═══════════════════════════════════════
        -- SECTION
        -- ═══════════════════════════════════════
        function tab:CreateSection(text)
            local sectionFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Parent = page,
            })

            local sectionLine = Create("Frame", {
                Size = UDim2.new(0.15, 0, 0, 2),
                Position = UDim2.fromOffset(0, 22),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = sectionFrame,
            })
            AddCorner(sectionLine, 999)
            AddGradient(sectionLine, Theme.Accent, Theme.Accent2, 0)

            Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                Position = UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1,
                Text = text or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sectionFrame,
            })

            return sectionFrame
        end

        -- ═══════════════════════════════════════
        -- LABEL / PARAGRAPH
        -- ═══════════════════════════════════════
        function tab:CreateLabel(cfg)
            cfg = cfg or {}
            local text = cfg.Text or cfg.Name or "Label"

            local control = createBaseControl(36)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -24, 1, 0),
                Text = text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextWrapped = true,
                Parent = control,
            })

            return control
        end

        function tab:CreateParagraph(cfg)
            cfg = cfg or {}
            local pTitle = cfg.Title or "Info"
            local pContent = cfg.Content or ""

            -- Calculate height based on content
            local lineCount = 1
            for _ in pContent:gmatch("\n") do lineCount = lineCount + 1 end
            local height = math.max(60, 30 + lineCount * 16)

            local control = createBaseControl(height)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 8),
                Size = UDim2.new(1, -24, 0, 16),
                Text = pTitle,
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 28),
                Size = UDim2.new(1, -24, 1, -34),
                Text = pContent,
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top,
                TextWrapped = true,
                Parent = control,
            })

            return control
        end

        -- ═══════════════════════════════════════
        -- BUTTON
        -- ═══════════════════════════════════════
        function tab:CreateButton(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Button"
            local callback = cfg.Callback or function() end

            local control = createBaseControl(42)

            local button = Create("TextButton", {
                Size = UDim2.new(1, -12, 1, -10),
                Position = UDim2.fromOffset(6, 5),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                Parent = control,
            })
            AddCorner(button, 7)
            AddGradient(button, Theme.Accent, Theme.Accent2, 25)

            button.MouseEnter:Connect(function()
                Tween(button, 0.1, {Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4)})
            end)
            button.MouseLeave:Connect(function()
                Tween(button, 0.1, {Size = UDim2.new(1, -12, 1, -10), Position = UDim2.fromOffset(6, 5)})
            end)
            button.MouseButton1Click:Connect(function()
                -- Click flash effect
                Tween(button, 0.05, {BackgroundTransparency = 0.3})
                task.delay(0.1, function()
                    Tween(button, 0.1, {BackgroundTransparency = 0})
                end)
                callback()
            end)

            return button
        end

        -- ═══════════════════════════════════════
        -- TOGGLE
        -- ═══════════════════════════════════════
        function tab:CreateToggle(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Toggle"
            local current = cfg.CurrentValue or false
            local callback = cfg.Callback or function() end

            local control = createBaseControl(48)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -80, 1, 0),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local toggleBtn = Create("TextButton", {
                Size = UDim2.fromOffset(44, 24),
                Position = UDim2.new(1, -56, 0.5, -12),
                BackgroundColor3 = current and Theme.Success or Theme.ToggleOff,
                Text = "",
                AutoButtonColor = false,
                Parent = control,
            })
            AddCorner(toggleBtn, 999)

            local knob = Create("Frame", {
                Size = UDim2.fromOffset(18, 18),
                Position = current and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = toggleBtn,
            })
            AddCorner(knob, 999)

            local function setToggle(v)
                current = v
                Tween(toggleBtn, 0.15, {BackgroundColor3 = current and Theme.Success or Theme.ToggleOff})
                Tween(knob, 0.15, {Position = current and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)})
                callback(current)
            end

            toggleBtn.MouseButton1Click:Connect(function()
                setToggle(not current)
            end)

            return {
                Set = setToggle,
                Get = function() return current end,
            }
        end

        -- ═══════════════════════════════════════
        -- SLIDER
        -- ═══════════════════════════════════════
        function tab:CreateSlider(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Slider"
            local range = cfg.Range or {0, 100}
            local minVal, maxVal = range[1], range[2]
            local inc = cfg.Increment or 1
            local suffix = cfg.Suffix or ""
            local value = cfg.CurrentValue or minVal
            local callback = cfg.Callback or function() end

            local control = createBaseControl(62)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 6),
                Size = UDim2.new(1, -24, 0, 16),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -70, 0, 6),
                Size = UDim2.fromOffset(58, 16),
                Text = tostring(value) .. suffix,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = Theme.Accent2,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = control,
            })

            local bar = Create("Frame", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.fromOffset(12, 36),
                BackgroundColor3 = Theme.SliderTrack,
                BorderSizePixel = 0,
                Parent = control,
            })
            AddCorner(bar, 999)

            local fill = Create("Frame", {
                Size = UDim2.new(math.clamp((value - minVal) / (maxVal - minVal), 0, 1), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = bar,
            })
            AddCorner(fill, 999)
            AddGradient(fill, Theme.Accent, Theme.Accent2, 0)

            -- Knob
            local knobSize = 14
            local knobFrame = Create("Frame", {
                Size = UDim2.fromOffset(knobSize, knobSize),
                Position = UDim2.new(math.clamp((value - minVal) / (maxVal - minVal), 0, 1), -knobSize / 2, 0.5, -knobSize / 2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = bar,
            })
            AddCorner(knobFrame, 999)

            local dragging = false
            local lastValue = value
            local dragInput = nil

            local function setFromScale(scale)
                scale = math.clamp(scale, 0, 1)
                local raw = minVal + (maxVal - minVal) * scale
                local snapped = Round(raw, inc)
                snapped = math.clamp(snapped, minVal, maxVal)
                if snapped == lastValue then return end
                value = snapped
                lastValue = snapped

                local alpha = (value - minVal) / (maxVal - minVal)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                knobFrame.Position = UDim2.new(alpha, -knobSize / 2, 0.5, -knobSize / 2)
                valueLabel.Text = tostring(value) .. suffix
                callback(value)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragInput = input
                    local scale = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromScale(scale)
                end
            end)

            knobFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    dragInput = input
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if dragInput and input == dragInput then
                    dragging = false
                    dragInput = nil
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and dragInput and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local scale = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromScale(scale)
                end
            end)

            return {
                Set = function(v)
                    setFromScale((v - minVal) / (maxVal - minVal))
                end,
                Get = function() return value end,
            }
        end

        -- ═══════════════════════════════════════
        -- DROPDOWN
        -- ═══════════════════════════════════════
        function tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Dropdown"
            local options = cfg.Options or {}
            local current = cfg.CurrentOption or options[1] or "None"
            local callback = cfg.Callback or function() end

            local control = createBaseControl(48)
            local opened = false

            local mainBtn = Create("TextButton", {
                Size = UDim2.new(1, -12, 1, -10),
                Position = UDim2.fromOffset(6, 5),
                BackgroundColor3 = Theme.Surface3,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = control,
            })
            AddCorner(mainBtn, 7)
            AddStroke(mainBtn, Theme.Border, 1, 0.3)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(0.5, 0, 1, 0),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Theme.Text,
                Parent = mainBtn,
            })

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(0.5, -26, 1, 0),
                Text = tostring(current),
                Font = Enum.Font.Gotham,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Theme.Accent2,
                Parent = mainBtn,
            })

            local icon = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(18, 18),
                Position = UDim2.new(1, -22, 0.5, -9),
                Text = "▾",
                Font = Enum.Font.GothamBold,
                TextSize = 12,
                TextColor3 = Theme.TextMuted,
                Parent = mainBtn,
            })

            local listFrame = Create("Frame", {
                Visible = false,
                Size = UDim2.new(1, -12, 0, 0),
                Position = UDim2.fromOffset(6, 44),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Parent = control,
                ClipsDescendants = true,
            })
            AddCorner(listFrame, 7)
            AddStroke(listFrame, Theme.Border, 1, 0.3)

            Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 3),
                Parent = listFrame,
            })

            AddPadding(listFrame, 5, 5, 5, 5)

            local buttons = {}
            for _, option in ipairs(options) do
                local opt = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundColor3 = Theme.Surface3,
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = Theme.Text,
                    AutoButtonColor = false,
                    Parent = listFrame,
                })
                AddCorner(opt, 5)

                opt.MouseEnter:Connect(function()
                    Tween(opt, 0.1, {BackgroundColor3 = Theme.Accent, TextColor3 = Color3.fromRGB(255, 255, 255)})
                end)
                opt.MouseLeave:Connect(function()
                    Tween(opt, 0.1, {BackgroundColor3 = Theme.Surface3, TextColor3 = Theme.Text})
                end)

                opt.MouseButton1Click:Connect(function()
                    current = option
                    valueLabel.Text = tostring(option)
                    callback(option)
                    opened = false
                    Tween(icon, 0.14, {Rotation = 0})
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 48)})
                    Tween(listFrame, 0.16, {Size = UDim2.new(1, -12, 0, 0)})
                    task.delay(0.16, function()
                        listFrame.Visible = false
                    end)
                end)

                table.insert(buttons, opt)
            end

            local function getListHeight()
                local count = #buttons
                if count == 0 then return 0 end
                return (count * 26) + ((count - 1) * 3) + 10
            end

            mainBtn.MouseButton1Click:Connect(function()
                opened = not opened
                Tween(icon, 0.14, {Rotation = opened and 180 or 0})

                if opened then
                    listFrame.Visible = true
                    local h = getListHeight()
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 48 + h + 6)})
                    Tween(listFrame, 0.16, {Size = UDim2.new(1, -12, 0, h)})
                else
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 48)})
                    Tween(listFrame, 0.16, {Size = UDim2.new(1, -12, 0, 0)})
                    task.delay(0.16, function()
                        listFrame.Visible = false
                    end)
                end
            end)

            return {
                Set = function(v)
                    current = v
                    valueLabel.Text = tostring(v)
                    callback(v)
                end,
                Get = function() return current end,
            }
        end

        -- ═══════════════════════════════════════
        -- INPUT
        -- ═══════════════════════════════════════
        function tab:CreateInput(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Input"
            local placeholder = cfg.PlaceholderText or "Type here..."
            local callback = cfg.Callback or function() end

            local control = createBaseControl(60)

            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 6),
                Size = UDim2.new(1, -24, 0, 16),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 12,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local input = Create("TextBox", {
                Size = UDim2.new(1, -24, 0, 26),
                Position = UDim2.fromOffset(12, 28),
                BackgroundColor3 = Theme.InputBg,
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                PlaceholderText = placeholder,
                PlaceholderColor3 = Theme.TextMuted,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = control,
            })
            AddCorner(input, 6)
            AddStroke(input, Theme.Border, 1, 0.3)
            AddPadding(input, 0, 0, 8, 8)

            -- Focus highlight
            input.Focused:Connect(function()
                local stroke = input:FindFirstChildOfClass("UIStroke")
                if stroke then
                    Tween(stroke, 0.15, {Color = Theme.Accent, Transparency = 0})
                end
            end)
            input.FocusLost:Connect(function(enterPressed)
                local stroke = input:FindFirstChildOfClass("UIStroke")
                if stroke then
                    Tween(stroke, 0.15, {Color = Theme.Border, Transparency = 0.3})
                end
                if enterPressed then
                    callback(input.Text)
                end
            end)

            return {
                Set = function(v)
                    input.Text = tostring(v)
                    callback(input.Text)
                end,
                Get = function() return input.Text end,
            }
        end

        -- ═══════════════════════════════════════
        -- TAB ACTIVATION
        -- ═══════════════════════════════════════
        local function activate()
            if window._activeTab then
                window._activeTab.page.Visible = false
                Tween(window._activeTab.button, 0.15, {BackgroundTransparency = 0.3})
                Tween(window._activeTab.label, 0.15, {TextColor3 = Theme.TextMuted})
                Tween(window._activeTab.indicator, 0.15, {BackgroundTransparency = 1})
            end

            page.Visible = true
            Tween(btn, 0.15, {BackgroundTransparency = 0, BackgroundColor3 = Theme.Surface3})
            Tween(btnLabel, 0.15, {TextColor3 = Theme.Text})
            Tween(btnIndicator, 0.15, {BackgroundTransparency = 0})

            window._activeTab = {
                page = page,
                button = btn,
                label = btnLabel,
                indicator = btnIndicator,
            }
        end

        btn.MouseButton1Click:Connect(activate)

        table.insert(window._tabs, {
            name = tabName,
            activate = activate,
        })

        if #window._tabs == 1 then
            activate()
        end

        return tab
    end

    -- ═══════════════════════════════════════
    -- BUILT-IN: SETTINGS TAB
    -- ═══════════════════════════════════════
    function window:CreateSettingsTab()
        local settingsTab = window:CreateTab("⚙ Settings")

        settingsTab:CreateSection("Appearance")

        settingsTab:CreateSlider({
            Name = "Window Transparency",
            Range = {0, 90},
            Increment = 5,
            CurrentValue = math.floor(windowTransparency * 100),
            Suffix = "%",
            Callback = function(v)
                local t = v / 100
                holder.BackgroundTransparency = t
                window._windowTransparency = t
            end,
        })

        settingsTab:CreateSlider({
            Name = "Panel Transparency",
            Range = {0, 90},
            Increment = 5,
            CurrentValue = math.floor(panelTransparency * 100),
            Suffix = "%",
            Callback = function(v)
                local t = v / 100
                window._panelTransparency = t
                -- Update all panels
                topbar.BackgroundTransparency = t
                tabSidebar.BackgroundTransparency = t
                contentArea.BackgroundTransparency = t
            end,
        })

        settingsTab:CreateSection("Actions")

        settingsTab:CreateButton({
            Name = "🔄 Reset Position",
            Callback = function()
                holder.Position = UDim2.fromScale(0.5, 0.5)
                window:Notify({Title = "Reset", Content = "Window position reset!", Duration = 2})
            end,
        })

        settingsTab:CreateButton({
            Name = "📐 Reset Size",
            Callback = function()
                Tween(holder, 0.2, {Size = size})
                window:Notify({Title = "Reset", Content = "Window size reset!", Duration = 2})
            end,
        })

        settingsTab:CreateButton({
            Name = "⏻ Unload Script",
            Callback = function()
                for _, cb in ipairs(window._unloadCallbacks) do
                    pcall(cb)
                end
                Tween(holder, 0.3, {BackgroundTransparency = 1, Size = UDim2.fromOffset(holder.AbsoluteSize.X, 0)})
                task.wait(0.35)
                screen:Destroy()
            end,
        })

        return settingsTab
    end

    -- ═══════════════════════════════════════
    -- BUILT-IN: SERVER INFO TAB
    -- ═══════════════════════════════════════
    function window:CreateServerInfoTab()
        local infoTab = window:CreateTab("🌐 Server")

        infoTab:CreateSection("Server Information")

        local gameName = "Unknown"
        pcall(function()
            gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)

        infoTab:CreateParagraph({
            Title = "🎮 Game",
            Content = "Name: " .. gameName
                .. "\nPlace ID: " .. tostring(game.PlaceId)
                .. "\nJob ID: " .. tostring(game.JobId):sub(1, 24) .. "..."
        })

        infoTab:CreateParagraph({
            Title = "📊 Server Stats",
            Content = "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
                .. "\nServer Age: " .. tostring(math.floor(game.Workspace.DistributedGameTime / 60)) .. " min"
                .. "\nGravity: " .. tostring(game.Workspace.Gravity)
        })

        infoTab:CreateSection("Quick Actions")

        infoTab:CreateButton({
            Name = "📋 Copy Place ID",
            Callback = function()
                pcall(function() setclipboard(tostring(game.PlaceId)) end)
                window:Notify({Title = "Copied", Content = "Place ID copied!", Duration = 2, Type = "success"})
            end,
        })

        infoTab:CreateButton({
            Name = "📋 Copy Job ID",
            Callback = function()
                pcall(function() setclipboard(tostring(game.JobId)) end)
                window:Notify({Title = "Copied", Content = "Job ID copied!", Duration = 2, Type = "success"})
            end,
        })

        return infoTab
    end

    -- ═══════════════════════════════════════
    -- BUILT-IN: PLAYER INFO TAB
    -- ═══════════════════════════════════════
    function window:CreatePlayerInfoTab()
        local playerTab = window:CreateTab("👤 Player Info")

        playerTab:CreateSection("Your Profile")

        playerTab:CreateParagraph({
            Title = "👤 Account",
            Content = "Username: " .. LocalPlayer.Name
                .. "\nDisplay Name: " .. LocalPlayer.DisplayName
                .. "\nUser ID: " .. tostring(LocalPlayer.UserId)
                .. "\nAccount Age: " .. tostring(LocalPlayer.AccountAge) .. " days"
        })

        local membershipText = "None"
        if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
            membershipText = "Premium"
        end

        playerTab:CreateParagraph({
            Title = "💎 Membership",
            Content = "Type: " .. membershipText
                .. "\nTeam: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "None")
        })

        playerTab:CreateSection("Character Stats")

        local function getCharStats()
            local char = LocalPlayer.Character
            if not char then return "No character loaded" end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum then return "No humanoid found" end
            return "Health: " .. tostring(math.floor(hum.Health)) .. "/" .. tostring(math.floor(hum.MaxHealth))
                .. "\nWalkSpeed: " .. tostring(hum.WalkSpeed)
                .. "\nJumpPower: " .. tostring(hum.JumpPower)
                .. "\nJump Height: " .. string.format("%.1f", hum.JumpHeight)
        end

        local statsParagraph = playerTab:CreateParagraph({
            Title = "📊 Live Stats",
            Content = getCharStats()
        })

        playerTab:CreateButton({
            Name = "🔄 Refresh Stats",
            Callback = function()
                -- Update the paragraph text
                local textLabel = nil
                for _, child in pairs(statsParagraph:GetDescendants()) do
                    if child:IsA("TextLabel") and child.TextXAlignment == Enum.TextXAlignment.Left and child.TextYAlignment == Enum.TextYAlignment.Top then
                        textLabel = child
                        break
                    end
                end
                if textLabel then
                    textLabel.Text = getCharStats()
                end
                window:Notify({Title = "Refreshed", Content = "Stats updated!", Duration = 2, Type = "success"})
            end,
        })

        return playerTab
    end

    -- Make window draggable
    MakeDraggable(topbar, holder)

    -- Intro animation
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(size.X.Offset, 0)
    Tween(holder, 0.35, {BackgroundTransparency = windowTransparency, Size = size}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return window
end

return setmetatable({}, Exter)
