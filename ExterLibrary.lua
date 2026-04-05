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
-- THEME CONFIGURATION
-- All colors are carefully chosen for readability on dark bg
-- ═══════════════════════════════════════════════════════════════
local Theme = {
    -- Backgrounds
    Background      = Color3.fromRGB(15, 15, 22),
    Surface         = Color3.fromRGB(22, 24, 34),
    Surface2        = Color3.fromRGB(30, 33, 46),
    Surface3        = Color3.fromRGB(38, 42, 58),
    SurfaceHover    = Color3.fromRGB(45, 50, 68),

    -- Borders
    Border          = Color3.fromRGB(50, 56, 78),
    BorderLight     = Color3.fromRGB(60, 66, 88),

    -- Text - HIGH CONTRAST for readability (no blue tint)
    Text            = Color3.fromRGB(240, 242, 250),
    TextSecondary   = Color3.fromRGB(200, 205, 218),
    TextDim         = Color3.fromRGB(170, 175, 192),
    TextMuted       = Color3.fromRGB(130, 136, 158),
    TextDisabled    = Color3.fromRGB(90, 96, 118),

    -- Accents
    Accent          = Color3.fromRGB(130, 100, 255),
    Accent2         = Color3.fromRGB(80, 170, 255),
    AccentSoft      = Color3.fromRGB(100, 78, 200),
    AccentGlow      = Color3.fromRGB(100, 80, 220),

    -- Value display color (bright, readable)
    ValueText       = Color3.fromRGB(180, 160, 255),

    -- Status colors
    Success         = Color3.fromRGB(72, 210, 145),
    Error           = Color3.fromRGB(220, 70, 70),
    Warning         = Color3.fromRGB(255, 190, 60),
    Info            = Color3.fromRGB(100, 180, 255),

    -- Component-specific
    SliderTrack     = Color3.fromRGB(50, 54, 72),
    SliderFill      = Color3.fromRGB(130, 100, 255),
    ToggleOn        = Color3.fromRGB(72, 210, 145),
    ToggleOff       = Color3.fromRGB(60, 64, 82),
    InputBg         = Color3.fromRGB(36, 40, 56),
    InputFocusBg    = Color3.fromRGB(42, 46, 64),

    -- Dropdown
    DropdownBg      = Color3.fromRGB(26, 28, 40),
    DropdownItem    = Color3.fromRGB(34, 38, 52),
    DropdownHover   = Color3.fromRGB(130, 100, 255),
}

-- ═══════════════════════════════════════════════════════════════
-- UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════

--- Create a new Instance with properties applied
local function Create(instanceType, props)
    local obj = Instance.new(instanceType)
    for k, v in pairs(props) do
        obj[k] = v
    end
    return obj
end

--- Round a number to the nearest bracket
local function Round(num, bracket)
    bracket = bracket or 1
    if bracket == 0 then return num end
    return math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket
end

--- Play a tween animation on an object
local function Tween(obj, duration, props, style, dir)
    if not obj or not obj.Parent then return nil end
    local tweenInfo = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quad,
        dir or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, tweenInfo, props)
    tw:Play()
    return tw
end

--- Add UICorner to a parent
local function AddCorner(parent, radius)
    return Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = parent,
    })
end

--- Add UIStroke to a parent
local function AddStroke(parent, color, thickness, transparency)
    return Create("UIStroke", {
        Color = color or Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent,
    })
end

--- Add UIGradient to a parent
local function AddGradient(parent, c1, c2, rot)
    return Create("UIGradient", {
        Color = ColorSequence.new(c1 or Theme.Accent, c2 or Theme.Accent2),
        Rotation = rot or 45,
        Parent = parent,
    })
end

--- Add UIPadding to a parent
local function AddPadding(parent, top, bottom, left, right)
    return Create("UIPadding", {
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        Parent = parent,
    })
end

--- Add UIListLayout to a parent
local function AddListLayout(parent, padding, direction, hAlign, vAlign, sortOrder)
    return Create("UIListLayout", {
        Padding = UDim.new(0, padding or 6),
        FillDirection = direction or Enum.FillDirection.Vertical,
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
        SortOrder = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent,
    })
end

--- Make a frame draggable via a handle
local function MakeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

--- Make a frame resizable via a handle
local function MakeResizable(handle, target, minSize, maxSize)
    local dragging = false
    local dragStart, startSize

    minSize = minSize or Vector2.new(480, 360)
    maxSize = maxSize or Vector2.new(1200, 800)

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local newW = math.clamp(startSize.X + delta.X, minSize.X, maxSize.X)
            local newH = math.clamp(startSize.Y + delta.Y, minSize.Y, maxSize.Y)
            target.Size = UDim2.fromOffset(newW, newH)
        end
    end)
end

--- Ripple effect on click
local function AddRipple(button, color)
    button.ClipsDescendants = true
    button.MouseButton1Click:Connect(function()
        local ripple = Create("Frame", {
            BackgroundColor3 = color or Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.7,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(0, 0),
            Parent = button,
        })
        AddCorner(ripple, 999)

        local maxDim = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        Tween(ripple, 0.4, {
            Size = UDim2.fromOffset(maxDim, maxDim),
            BackgroundTransparency = 1,
        })
        task.delay(0.45, function()
            if ripple and ripple.Parent then
                ripple:Destroy()
            end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- LOADING SCREEN
-- ═══════════════════════════════════════════════════════════════
local function ShowLoadingScreen(screen, config)
    local loadingTitle = config.LoadingTitle or config.Title or "Exter Hub"
    local loadingSubtitle = config.LoadingSubtitle or "Initializing..."

    -- Full-screen overlay
    local loadingFrame = Create("Frame", {
        Name = "LoadingScreen",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(8, 8, 14),
        BackgroundTransparency = 0,
        ZIndex = 100,
        Parent = screen,
    })

    -- Subtle gradient overlay
    local bgOverlay = Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.88,
        ZIndex = 101,
        Parent = loadingFrame,
    })
    AddGradient(bgOverlay, Theme.Accent, Theme.Accent2, 135)

    -- Center container
    local centerContainer = Create("Frame", {
        Size = UDim2.fromOffset(400, 220),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ZIndex = 102,
        Parent = loadingFrame,
    })

    -- Logo circle with gradient
    local logoCircle = Create("Frame", {
        Size = UDim2.fromOffset(70, 70),
        Position = UDim2.new(0.5, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Theme.Accent,
        ZIndex = 103,
        Parent = centerContainer,
    })
    AddCorner(logoCircle, 999)
    AddGradient(logoCircle, Theme.Accent, Theme.Accent2, 45)

    -- Logo letter
    Create("TextLabel", {
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
    Create("TextLabel", {
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
    Create("TextLabel", {
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
        Size = UDim2.new(0.65, 0, 0, 6),
        Position = UDim2.new(0.175, 0, 0, 158),
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
        Position = UDim2.fromOffset(0, 176),
        BackgroundTransparency = 1,
        Text = "Loading modules...",
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextColor3 = Theme.TextMuted,
        ZIndex = 103,
        Parent = centerContainer,
    })

    -- Loading steps
    local loadingSteps = {
        { progress = 0.12, text = "Loading modules..." },
        { progress = 0.28, text = "Initializing UI..." },
        { progress = 0.45, text = "Setting up features..." },
        { progress = 0.62, text = "Connecting services..." },
        { progress = 0.80, text = "Preparing workspace..." },
        { progress = 0.92, text = "Almost ready..." },
        { progress = 1.00, text = "Welcome!" },
    }

    -- Logo pulse animation
    task.spawn(function()
        while loadingFrame and loadingFrame.Parent do
            Tween(logoCircle, 0.8, {
                Size = UDim2.fromOffset(76, 76),
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
            if not (loadingFrame and loadingFrame.Parent) then break end
            Tween(logoCircle, 0.8, {
                Size = UDim2.fromOffset(70, 70),
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.8)
        end
    end)

    -- Progress animation
    for _, step in ipairs(loadingSteps) do
        statusLabel.Text = step.text
        Tween(progressFill, 0.35, {
            Size = UDim2.new(step.progress, 0, 1, 0),
        })
        task.wait(0.3 + math.random() * 0.15)
    end

    task.wait(0.25)

    -- Fade out everything
    Tween(loadingFrame, 0.5, { BackgroundTransparency = 1 })
    for _, child in pairs(loadingFrame:GetDescendants()) do
        if child:IsA("TextLabel") then
            Tween(child, 0.4, { TextTransparency = 1 })
        elseif child:IsA("Frame") then
            Tween(child, 0.4, { BackgroundTransparency = 1 })
        elseif child:IsA("UIStroke") then
            Tween(child, 0.4, { Transparency = 1 })
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
    local toggleKey = config.ToggleKey or Enum.KeyCode.RightShift

    -- ═══════════════════════════════════════
    -- SCREEN GUI
    -- ═══════════════════════════════════════
    local screen = Create("ScreenGui", {
        Name = "ExterPremiumUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = PlayerGui,
    })

    -- Show loading screen
    if loadingEnabled then
        ShowLoadingScreen(screen, config)
    end

    -- ═══════════════════════════════════════
    -- MAIN HOLDER
    -- ═══════════════════════════════════════
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

    -- Drop shadow
    Create("ImageLabel", {
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

    -- Accent line on top
    local accentLine = Create("Frame", {
        Size = UDim2.new(0.4, 0, 0, 2),
        Position = UDim2.new(0.3, 0, 0, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = topbar,
    })
    AddCorner(accentLine, 999)
    AddGradient(accentLine, Theme.Accent, Theme.Accent2, 0)

    -- Title label
    Create("TextLabel", {
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

    -- Subtitle label
    Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -140, 0, 14),
        Position = UDim2.fromOffset(16, 30),
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

    Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = topBtnContainer,
    })

    -- Helper: create topbar icon button
    local function CreateTopbarButton(text, parent)
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
            Tween(btn, 0.12, {
                BackgroundColor3 = Theme.Surface3,
                TextColor3 = Theme.Text,
            })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.12, {
                BackgroundColor3 = Theme.Surface2,
                TextColor3 = Theme.TextDim,
            })
        end)

        return btn
    end

    local minimizeBtn = CreateTopbarButton("—", topBtnContainer)
    local unloadBtn = CreateTopbarButton("⏻", topBtnContainer)
    local closeBtn = CreateTopbarButton("✕", topBtnContainer)

    -- Close button special hover (red)
    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.12, {
            BackgroundColor3 = Theme.Error,
            TextColor3 = Color3.fromRGB(255, 255, 255),
        })
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.12, {
            BackgroundColor3 = Theme.Surface2,
            TextColor3 = Theme.TextDim,
        })
    end)

    -- ═══════════════════════════════════════
    -- BODY CONTAINER
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

    -- Tab scroll area
    local tabScroll = Create("ScrollingFrame", {
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.fromOffset(5, 5),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarThickness = 3,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = tabSidebar,
    })

    local tabList = Create("UIListLayout", {
        Padding = UDim.new(0, 5),
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
        ClipsDescendants = false,
        Parent = body,
    })
    AddCorner(contentArea, 10)
    AddStroke(contentArea, Theme.Border, 1, 0)

    -- ═══════════════════════════════════════
    -- RESIZE HANDLE
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
        Tween(resizeHandle, 0.1, { TextColor3 = Theme.Accent })
    end)
    resizeHandle.MouseLeave:Connect(function()
        Tween(resizeHandle, 0.1, { TextColor3 = Theme.TextMuted })
    end)

    MakeResizable(resizeHandle, holder, Vector2.new(500, 360), Vector2.new(1200, 800))

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
    -- DROPDOWN OVERLAY CONTAINER
    -- Dropdowns render here so they appear
    -- above all other content (fixes z-index)
    -- ═══════════════════════════════════════
    local dropdownOverlay = Create("Frame", {
        Name = "DropdownOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 50,
        Parent = screen,
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
        _dropdownOverlay = dropdownOverlay,
        _panelTransparency = panelTransparency,
        _windowTransparency = windowTransparency,
        _unloadCallbacks = {},
        _visible = true,
    }

    -- ═══════════════════════════════════════
    -- TOGGLE UI VISIBILITY (keybind)
    -- ═══════════════════════════════════════
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == toggleKey then
            window._visible = not window._visible
            holder.Visible = window._visible
        end
    end)

    -- ═══════════════════════════════════════
    -- MINIMIZE LOGIC
    -- ═══════════════════════════════════════
    local minimized = false
    local savedSize = nil

    minimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            savedSize = holder.Size
            body.Visible = false
            resizeHandle.Visible = false
            Tween(holder, 0.25, {
                Size = UDim2.fromOffset(holder.AbsoluteSize.X, 68),
            })
            minimizeBtn.Text = "+"
        else
            body.Visible = true
            resizeHandle.Visible = true
            Tween(holder, 0.25, {
                Size = savedSize or size,
            })
            minimizeBtn.Text = "—"
        end
    end)

    -- ═══════════════════════════════════════
    -- CLOSE LOGIC
    -- ═══════════════════════════════════════
    closeBtn.MouseButton1Click:Connect(function()
        Tween(holder, 0.3, {
            Size = UDim2.fromOffset(holder.AbsoluteSize.X, 0),
        })
        task.wait(0.35)
        screen:Destroy()
    end)

    -- ═══════════════════════════════════════
    -- UNLOAD LOGIC
    -- ═══════════════════════════════════════
    unloadBtn.MouseButton1Click:Connect(function()
        for _, cb in ipairs(window._unloadCallbacks) do
            pcall(cb)
        end
        Tween(holder, 0.3, { BackgroundTransparency = 1 })
        for _, child in pairs(holder:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                pcall(function() Tween(child, 0.25, { TextTransparency = 1 }) end)
            end
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                pcall(function() Tween(child, 0.25, { BackgroundTransparency = 1 }) end)
            end
            if child:IsA("UIStroke") then
                pcall(function() Tween(child, 0.25, { Transparency = 1 }) end)
            end
        end
        task.wait(0.35)
        screen:Destroy()
    end)

    -- ═══════════════════════════════════════
    -- NOTIFY METHOD
    -- ═══════════════════════════════════════
    function window:Notify(cfg)
        cfg = cfg or {}
        local nTitle = cfg.Title or "Notification"
        local nText = cfg.Content or ""
        local duration = cfg.Duration or 3
        local nType = cfg.Type or "info"

        local accentColor = Theme.Info
        if nType == "success" then
            accentColor = Theme.Success
        elseif nType == "error" then
            accentColor = Theme.Error
        elseif nType == "warning" then
            accentColor = Theme.Warning
        end

        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            BackgroundTransparency = 0,
            Parent = notificationHolder,
        })
        AddCorner(card, 10)
        AddStroke(card, Theme.Border, 1, 0)

        -- Accent line on left
        local line = Create("Frame", {
            Size = UDim2.new(0, 4, 1, -12),
            Position = UDim2.fromOffset(6, 6),
            BackgroundColor3 = accentColor,
            BorderSizePixel = 0,
            Parent = card,
        })
        AddCorner(line, 999)

        -- Notification title
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

        -- Notification content
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

        -- Animate in from right
        card.BackgroundTransparency = 1
        local origPos = card.Position
        card.Position = origPos + UDim2.fromOffset(40, 0)
        Tween(card, 0.25, { BackgroundTransparency = 0, Position = origPos })

        for _, child in pairs(card:GetDescendants()) do
            if child:IsA("TextLabel") then
                child.TextTransparency = 1
                Tween(child, 0.25, { TextTransparency = 0 })
            elseif child:IsA("Frame") then
                local origTrans = child.BackgroundTransparency
                child.BackgroundTransparency = 1
                Tween(child, 0.25, { BackgroundTransparency = origTrans })
            elseif child:IsA("UIStroke") then
                child.Transparency = 1
                Tween(child, 0.25, { Transparency = 0 })
            end
        end

        -- Auto-dismiss
        task.delay(duration, function()
            if card and card.Parent then
                Tween(card, 0.25, {
                    BackgroundTransparency = 1,
                    Position = origPos + UDim2.fromOffset(40, 0),
                })
                for _, child in pairs(card:GetDescendants()) do
                    if child:IsA("TextLabel") then
                        Tween(child, 0.2, { TextTransparency = 1 })
                    elseif child:IsA("Frame") then
                        Tween(child, 0.2, { BackgroundTransparency = 1 })
                    elseif child:IsA("UIStroke") then
                        Tween(child, 0.2, { Transparency = 1 })
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
    -- CLOSE ANY OPEN DROPDOWN
    -- Utility to close all open dropdowns
    -- ═══════════════════════════════════════
    local activeDropdown = nil

    local function CloseActiveDropdown()
        if activeDropdown then
            activeDropdown()
            activeDropdown = nil
        end
    end

    -- ═══════════════════════════════════════
    -- CREATE TAB BUTTON (sidebar)
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

        -- Active indicator bar (left side)
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

        -- Tab name label
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
            Tween(btn, 0.12, { BackgroundTransparency = 0.15 })
            Tween(label, 0.12, { TextColor3 = Theme.TextDim })
        end)
        btn.MouseLeave:Connect(function()
            if window._activeTab and window._activeTab.button == btn then return end
            Tween(btn, 0.12, { BackgroundTransparency = 0.3 })
            Tween(label, 0.12, { TextColor3 = Theme.TextMuted })
        end)

        return btn, label, indicator
    end

    -- ═══════════════════════════════════════
    -- CREATE TAB
    -- ═══════════════════════════════════════
    function window:CreateTab(name)
        local tabName = name or "Tab"

        local btn, btnLabel, btnIndicator = createTabButton(tabName)

        -- Scrollable page for this tab
        local page = Create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, -16, 1, -16),
            Position = UDim2.fromOffset(8, 8),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarThickness = 3,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            ClipsDescendants = true,
            Parent = contentArea,
        })

        local layout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = page,
        })

        AddPadding(page, 2, 8, 0, 0)

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 16)
        end)

        local tab = {
            _page = page,
            _layout = layout,
            _window = window,
        }

        -- Base control container factory
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
        -- SECTION HEADER
        -- ═══════════════════════════════════════
        function tab:CreateSection(text)
            local sectionFrame = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundTransparency = 1,
                Parent = page,
            })

            -- Accent underline
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
        -- LABEL
        -- ═══════════════════════════════════════
        function tab:CreateLabel(cfg)
            cfg = cfg or {}
            local text = cfg.Text or cfg.Name or "Label"

            local control = createBaseControl(36)

            local lbl = Create("TextLabel", {
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

            local api = {}
            function api:Set(newText)
                lbl.Text = tostring(newText)
            end
            function api:Get()
                return lbl.Text
            end
            return api
        end

        -- ═══════════════════════════════════════
        -- PARAGRAPH
        -- ═══════════════════════════════════════
        function tab:CreateParagraph(cfg)
            cfg = cfg or {}
            local pTitle = cfg.Title or "Info"
            local pContent = cfg.Content or ""

            -- Calculate height based on content lines
            local lineCount = 1
            for _ in pContent:gmatch("\n") do
                lineCount = lineCount + 1
            end
            local height = math.max(60, 32 + lineCount * 16)

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

            local contentLabel = Create("TextLabel", {
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
                ClipsDescendants = true,
                Parent = control,
            })
            AddCorner(button, 7)
            AddGradient(button, Theme.Accent, Theme.Accent2, 25)

            -- Hover scale effect
            button.MouseEnter:Connect(function()
                Tween(button, 0.1, {
                    Size = UDim2.new(1, -10, 1, -8),
                    Position = UDim2.fromOffset(5, 4),
                })
            end)
            button.MouseLeave:Connect(function()
                Tween(button, 0.1, {
                    Size = UDim2.new(1, -12, 1, -10),
                    Position = UDim2.fromOffset(6, 5),
                })
            end)

            -- Click ripple + callback
            AddRipple(button, Color3.fromRGB(255, 255, 255))
            button.MouseButton1Click:Connect(function()
                callback()
            end)

            local api = {}
            function api:SetText(txt)
                button.Text = tostring(txt)
            end
            return api
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

            -- Toggle label
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

            -- Toggle track
            local toggleBtn = Create("TextButton", {
                Size = UDim2.fromOffset(44, 24),
                Position = UDim2.new(1, -56, 0.5, -12),
                BackgroundColor3 = current and Theme.ToggleOn or Theme.ToggleOff,
                Text = "",
                AutoButtonColor = false,
                Parent = control,
            })
            AddCorner(toggleBtn, 999)

            -- Toggle knob
            local knob = Create("Frame", {
                Size = UDim2.fromOffset(18, 18),
                Position = current and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                Parent = toggleBtn,
            })
            AddCorner(knob, 999)

            local function setToggle(v, skipCallback)
                current = v
                Tween(toggleBtn, 0.15, {
                    BackgroundColor3 = current and Theme.ToggleOn or Theme.ToggleOff,
                })
                Tween(knob, 0.15, {
                    Position = current and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
                })
                if not skipCallback then
                    callback(current)
                end
            end

            toggleBtn.MouseButton1Click:Connect(function()
                setToggle(not current)
            end)

            return {
                Set = function(v) setToggle(v) end,
                Get = function() return current end,
            }
        end

        -- ═══════════════════════════════════════
        -- SLIDER
        -- ═══════════════════════════════════════
        function tab:CreateSlider(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Slider"
            local range = cfg.Range or { 0, 100 }
            local minVal, maxVal = range[1], range[2]
            local inc = cfg.Increment or 1
            local suffix = cfg.Suffix or ""
            local value = math.clamp(cfg.CurrentValue or minVal, minVal, maxVal)
            local callback = cfg.Callback or function() end

            local control = createBaseControl(62)

            -- Slider name
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

            -- Value display (readable color, not blue)
            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -70, 0, 6),
                Size = UDim2.fromOffset(58, 16),
                Text = tostring(value) .. suffix,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = Theme.ValueText,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = control,
            })

            -- Slider track
            local bar = Create("Frame", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.fromOffset(12, 36),
                BackgroundColor3 = Theme.SliderTrack,
                BorderSizePixel = 0,
                Parent = control,
            })
            AddCorner(bar, 999)

            -- Slider fill
            local initialAlpha = math.clamp((value - minVal) / (maxVal - minVal), 0, 1)
            local fill = Create("Frame", {
                Size = UDim2.new(initialAlpha, 0, 1, 0),
                BackgroundColor3 = Theme.SliderFill,
                BorderSizePixel = 0,
                Parent = bar,
            })
            AddCorner(fill, 999)
            AddGradient(fill, Theme.Accent, Theme.Accent2, 0)

            -- Slider knob
            local knobSize = 14
            local knobFrame = Create("Frame", {
                Size = UDim2.fromOffset(knobSize, knobSize),
                Position = UDim2.new(initialAlpha, -knobSize / 2, 0.5, -knobSize / 2),
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

            -- Click on bar to set value
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragInput = input
                    local scale = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromScale(scale)
                end
            end)

            -- Drag from knob
            knobFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
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
                if dragging and dragInput
                    and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
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
        -- DROPDOWN (FIXED - no more scroll bugs)
        -- The dropdown list now renders as an
        -- overlay on the screen, not inside the
        -- scrolling content. This prevents the
        -- parent container from resizing and
        -- causing layout shift / scroll glitches.
        -- ═══════════════════════════════════════
        function tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Dropdown"
            local options = cfg.Options or {}
            local current = cfg.CurrentOption or (options[1] or "None")
            local callback = cfg.Callback or function() end

            -- Fixed-height control (never changes size)
            local control = createBaseControl(48)

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

            -- Dropdown label (left)
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

            -- Selected value (right, readable color)
            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.5, 0, 0, 0),
                Size = UDim2.new(0.5, -26, 1, 0),
                Text = tostring(current),
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Theme.ValueText,
                Parent = mainBtn,
            })

            -- Arrow icon
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

            -- Hover effect on main button
            mainBtn.MouseEnter:Connect(function()
                Tween(mainBtn, 0.1, { BackgroundColor3 = Theme.SurfaceHover })
            end)
            mainBtn.MouseLeave:Connect(function()
                Tween(mainBtn, 0.1, { BackgroundColor3 = Theme.Surface3 })
            end)

            local opened = false
            local listFrame = nil
            local optionButtons = {}

            -- Build the dropdown list as an OVERLAY
            -- (not inside the scrolling page)
            local function buildDropdownList()
                if listFrame then return end

                -- Calculate position in screen space
                local absPos = mainBtn.AbsolutePosition
                local absSize = mainBtn.AbsoluteSize

                listFrame = Create("Frame", {
                    Size = UDim2.fromOffset(absSize.X, 0),
                    Position = UDim2.fromOffset(absPos.X, absPos.Y + absSize.Y + 4),
                    BackgroundColor3 = Theme.DropdownBg,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 100,
                    Parent = dropdownOverlay,
                })
                AddCorner(listFrame, 8)
                AddStroke(listFrame, Theme.BorderLight, 1, 0)

                -- Inner scroll for many options
                local listScroll = Create("ScrollingFrame", {
                    Size = UDim2.new(1, -8, 1, -8),
                    Position = UDim2.fromOffset(4, 4),
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ScrollBarImageColor3 = Theme.Accent,
                    ScrollBarThickness = 3,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 101,
                    Parent = listFrame,
                })

                local listLayout = Create("UIListLayout", {
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 3),
                    Parent = listScroll,
                })

                AddPadding(listScroll, 2, 2, 2, 2)

                optionButtons = {}
                for _, option in ipairs(options) do
                    local isSelected = (tostring(option) == tostring(current))

                    local opt = Create("TextButton", {
                        Size = UDim2.new(1, 0, 0, 28),
                        BackgroundColor3 = isSelected and Theme.AccentSoft or Theme.DropdownItem,
                        BorderSizePixel = 0,
                        Text = tostring(option),
                        Font = Enum.Font.GothamSemibold,
                        TextSize = 11,
                        TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Theme.TextSecondary,
                        AutoButtonColor = false,
                        ZIndex = 102,
                        Parent = listScroll,
                    })
                    AddCorner(opt, 6)

                    opt.MouseEnter:Connect(function()
                        Tween(opt, 0.08, {
                            BackgroundColor3 = Theme.DropdownHover,
                            TextColor3 = Color3.fromRGB(255, 255, 255),
                        })
                    end)
                    opt.MouseLeave:Connect(function()
                        local sel = (tostring(option) == tostring(current))
                        Tween(opt, 0.08, {
                            BackgroundColor3 = sel and Theme.AccentSoft or Theme.DropdownItem,
                            TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Theme.TextSecondary,
                        })
                    end)

                    opt.MouseButton1Click:Connect(function()
                        current = option
                        valueLabel.Text = tostring(option)
                        callback(option)
                        -- Close dropdown
                        closeDropdown()
                    end)

                    table.insert(optionButtons, opt)
                end

                -- Update canvas size
                local totalH = (#optionButtons * 28) + (math.max(0, #optionButtons - 1) * 3) + 4
                listScroll.CanvasSize = UDim2.fromOffset(0, totalH)

                -- Max visible height (cap at 6 items)
                local maxItems = math.min(#optionButtons, 6)
                local targetH = (maxItems * 28) + (math.max(0, maxItems - 1) * 3) + 12

                -- Animate open
                Tween(listFrame, 0.18, {
                    Size = UDim2.fromOffset(absSize.X, targetH),
                })
            end

            -- Close the dropdown
            function closeDropdown()
                if not opened then return end
                opened = false
                Tween(icon, 0.14, { Rotation = 0 })

                if listFrame then
                    Tween(listFrame, 0.14, {
                        Size = UDim2.fromOffset(listFrame.AbsoluteSize.X, 0),
                    })
                    local ref = listFrame
                    task.delay(0.16, function()
                        if ref and ref.Parent then
                            ref:Destroy()
                        end
                    end)
                    listFrame = nil
                end

                activeDropdown = nil
            end

            -- Toggle dropdown
            mainBtn.MouseButton1Click:Connect(function()
                if opened then
                    closeDropdown()
                else
                    -- Close any other open dropdown first
                    CloseActiveDropdown()

                    opened = true
                    Tween(icon, 0.14, { Rotation = 180 })
                    buildDropdownList()
                    activeDropdown = closeDropdown
                end
            end)

            -- Close dropdown when scrolling the page
            page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                if opened then
                    closeDropdown()
                end
            end)

            return {
                Set = function(v)
                    current = v
                    valueLabel.Text = tostring(v)
                    callback(v)
                end,
                Get = function() return current end,
                Refresh = function(newOptions)
                    options = newOptions
                    if opened then
                        closeDropdown()
                    end
                end,
            }
        end

        -- ═══════════════════════════════════════
        -- INPUT / TEXT BOX
        -- ═══════════════════════════════════════
        function tab:CreateInput(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Input"
            local placeholder = cfg.PlaceholderText or "Type here..."
            local callback = cfg.Callback or function() end

            local control = createBaseControl(60)

            -- Input label
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

            -- Text input box
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
                    Tween(stroke, 0.15, { Color = Theme.Accent, Transparency = 0 })
                end
                Tween(input, 0.15, { BackgroundColor3 = Theme.InputFocusBg })
            end)

            input.FocusLost:Connect(function(enterPressed)
                local stroke = input:FindFirstChildOfClass("UIStroke")
                if stroke then
                    Tween(stroke, 0.15, { Color = Theme.Border, Transparency = 0.3 })
                end
                Tween(input, 0.15, { BackgroundColor3 = Theme.InputBg })
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
        -- KEYBIND
        -- ═══════════════════════════════════════
        function tab:CreateKeybind(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Keybind"
            local currentKey = cfg.CurrentKeybind or "None"
            local callback = cfg.Callback or function() end

            local control = createBaseControl(48)

            -- Keybind label
            Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -120, 1, 0),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            -- Keybind button
            local keyBtn = Create("TextButton", {
                Size = UDim2.fromOffset(90, 28),
                Position = UDim2.new(1, -102, 0.5, -14),
                BackgroundColor3 = Theme.InputBg,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = currentKey,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextColor3 = Theme.ValueText,
                Parent = control,
            })
            AddCorner(keyBtn, 6)
            AddStroke(keyBtn, Theme.Border, 1, 0.3)

            local listening = false

            keyBtn.MouseEnter:Connect(function()
                if not listening then
                    Tween(keyBtn, 0.1, { BackgroundColor3 = Theme.SurfaceHover })
                end
            end)
            keyBtn.MouseLeave:Connect(function()
                if not listening then
                    Tween(keyBtn, 0.1, { BackgroundColor3 = Theme.InputBg })
                end
            end)

            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                keyBtn.Text = "..."
                Tween(keyBtn, 0.1, { BackgroundColor3 = Theme.AccentSoft })

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name
                        keyBtn.Text = currentKey
                        listening = false
                        Tween(keyBtn, 0.1, { BackgroundColor3 = Theme.InputBg })
                        conn:Disconnect()
                    end
                end)
            end)

            -- Listen for keybind press
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed or listening then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if input.KeyCode.Name == currentKey then
                        callback(currentKey)
                    end
                end
            end)

            return {
                Set = function(key)
                    currentKey = key
                    keyBtn.Text = key
                end,
                Get = function() return currentKey end,
            }
        end

        -- ═══════════════════════════════════════
        -- COLOR PICKER
        -- ═══════════════════════════════════════
        function tab:CreateColorPicker(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Color"
            local currentColor = cfg.Color or Color3.fromRGB(130, 100, 255)
            local callback = cfg.Callback or function() end

            local control = createBaseControl(48)

            -- Color picker label
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

            -- Color preview button
            local colorBtn = Create("TextButton", {
                Size = UDim2.fromOffset(36, 28),
                Position = UDim2.new(1, -48, 0.5, -14),
                BackgroundColor3 = currentColor,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = control,
            })
            AddCorner(colorBtn, 6)
            AddStroke(colorBtn, Theme.Border, 1, 0.2)

            local pickerOpen = false
            local pickerFrame = nil

            local function closeColorPicker()
                if not pickerOpen then return end
                pickerOpen = false
                if pickerFrame then
                    Tween(pickerFrame, 0.14, { BackgroundTransparency = 1 })
                    local ref = pickerFrame
                    task.delay(0.16, function()
                        if ref and ref.Parent then ref:Destroy() end
                    end)
                    pickerFrame = nil
                end
            end

            colorBtn.MouseButton1Click:Connect(function()
                if pickerOpen then
                    closeColorPicker()
                    return
                end

                pickerOpen = true

                -- Create picker overlay
                local absPos = colorBtn.AbsolutePosition
                local absSize = colorBtn.AbsoluteSize

                pickerFrame = Create("Frame", {
                    Size = UDim2.fromOffset(200, 180),
                    Position = UDim2.fromOffset(absPos.X - 160, absPos.Y + absSize.Y + 6),
                    BackgroundColor3 = Theme.DropdownBg,
                    BorderSizePixel = 0,
                    ZIndex = 100,
                    Parent = dropdownOverlay,
                })
                AddCorner(pickerFrame, 10)
                AddStroke(pickerFrame, Theme.BorderLight, 1, 0)

                -- Title
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 6),
                    Size = UDim2.new(1, -20, 0, 16),
                    Text = "Pick a Color",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 101,
                    Parent = pickerFrame,
                })

                -- Preset colors grid
                local presetColors = {
                    Color3.fromRGB(255, 60, 60),
                    Color3.fromRGB(255, 120, 50),
                    Color3.fromRGB(255, 200, 50),
                    Color3.fromRGB(100, 220, 100),
                    Color3.fromRGB(50, 200, 180),
                    Color3.fromRGB(80, 170, 255),
                    Color3.fromRGB(130, 100, 255),
                    Color3.fromRGB(200, 80, 220),
                    Color3.fromRGB(255, 100, 180),
                    Color3.fromRGB(255, 255, 255),
                    Color3.fromRGB(180, 180, 180),
                    Color3.fromRGB(100, 100, 100),
                    Color3.fromRGB(60, 60, 60),
                    Color3.fromRGB(30, 30, 30),
                    Color3.fromRGB(0, 0, 0),
                }

                local gridContainer = Create("Frame", {
                    Size = UDim2.new(1, -20, 0, 100),
                    Position = UDim2.fromOffset(10, 28),
                    BackgroundTransparency = 1,
                    ZIndex = 101,
                    Parent = pickerFrame,
                })

                local gridLayout = Create("UIGridLayout", {
                    CellSize = UDim2.fromOffset(30, 30),
                    CellPadding = UDim2.fromOffset(5, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Parent = gridContainer,
                })

                for _, color in ipairs(presetColors) do
                    local colorSwatch = Create("TextButton", {
                        BackgroundColor3 = color,
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = "",
                        ZIndex = 102,
                        Parent = gridContainer,
                    })
                    AddCorner(colorSwatch, 6)
                    AddStroke(colorSwatch, Theme.Border, 1, 0.4)

                    colorSwatch.MouseEnter:Connect(function()
                        local s = colorSwatch:FindFirstChildOfClass("UIStroke")
                        if s then Tween(s, 0.1, { Color = Theme.Text, Transparency = 0 }) end
                    end)
                    colorSwatch.MouseLeave:Connect(function()
                        local s = colorSwatch:FindFirstChildOfClass("UIStroke")
                        if s then Tween(s, 0.1, { Color = Theme.Border, Transparency = 0.4 }) end
                    end)

                    colorSwatch.MouseButton1Click:Connect(function()
                        currentColor = color
                        colorBtn.BackgroundColor3 = color
                        callback(color)
                        closeColorPicker()
                    end)
                end

                -- Hex input
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromOffset(10, 138),
                    Size = UDim2.fromOffset(30, 24),
                    Text = "Hex:",
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 10,
                    TextColor3 = Theme.TextDim,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 101,
                    Parent = pickerFrame,
                })

                local hexInput = Create("TextBox", {
                    Size = UDim2.new(1, -60, 0, 24),
                    Position = UDim2.fromOffset(42, 138),
                    BackgroundColor3 = Theme.InputBg,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    Text = string.format("#%02X%02X%02X",
                        math.floor(currentColor.R * 255),
                        math.floor(currentColor.G * 255),
                        math.floor(currentColor.B * 255)
                    ),
                    TextColor3 = Theme.Text,
                    PlaceholderText = "#FFFFFF",
                    PlaceholderColor3 = Theme.TextMuted,
                    ClearTextOnFocus = false,
                    ZIndex = 102,
                    Parent = pickerFrame,
                })
                AddCorner(hexInput, 6)
                AddPadding(hexInput, 0, 0, 6, 6)

                hexInput.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        local hex = hexInput.Text:gsub("#", "")
                        if #hex == 6 then
                            local r = tonumber(hex:sub(1, 2), 16) or 0
                            local g = tonumber(hex:sub(3, 4), 16) or 0
                            local b = tonumber(hex:sub(5, 6), 16) or 0
                            currentColor = Color3.fromRGB(r, g, b)
                            colorBtn.BackgroundColor3 = currentColor
                            callback(currentColor)
                            closeColorPicker()
                        end
                    end
                end)
            end)

            -- Close picker when scrolling
            page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                if pickerOpen then
                    closeColorPicker()
                end
            end)

            return {
                Set = function(color)
                    currentColor = color
                    colorBtn.BackgroundColor3 = color
                    callback(color)
                end,
                Get = function() return currentColor end,
            }
        end

        -- ═══════════════════════════════════════
        -- DIVIDER / SEPARATOR
        -- ═══════════════════════════════════════
        function tab:CreateDivider()
            local divider = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 8),
                BackgroundTransparency = 1,
                Parent = page,
            })

            local line = Create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.fromScale(0, 0.5),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Parent = divider,
            })

            return divider
        end

        -- ═══════════════════════════════════════
        -- TAB ACTIVATION LOGIC
        -- ═══════════════════════════════════════
        local function activate()
            -- Close any open dropdown when switching tabs
            CloseActiveDropdown()

            -- Deactivate previous tab
            if window._activeTab then
                window._activeTab.page.Visible = false
                Tween(window._activeTab.button, 0.15, { BackgroundTransparency = 0.3 })
                Tween(window._activeTab.label, 0.15, { TextColor3 = Theme.TextMuted })
                Tween(window._activeTab.indicator, 0.15, { BackgroundTransparency = 1 })
            end

            -- Activate this tab
            page.Visible = true
            Tween(btn, 0.15, {
                BackgroundTransparency = 0,
                BackgroundColor3 = Theme.Surface3,
            })
            Tween(btnLabel, 0.15, { TextColor3 = Theme.Text })
            Tween(btnIndicator, 0.15, { BackgroundTransparency = 0 })

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

        -- Auto-activate first tab
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
            Range = { 0, 90 },
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
            Range = { 0, 90 },
            Increment = 5,
            CurrentValue = math.floor(panelTransparency * 100),
            Suffix = "%",
            Callback = function(v)
                local t = v / 100
                window._panelTransparency = t
                topbar.BackgroundTransparency = t
                tabSidebar.BackgroundTransparency = t
                contentArea.BackgroundTransparency = t
            end,
        })

        settingsTab:CreateSection("UI Toggle")

        settingsTab:CreateLabel({
            Text = "Press " .. toggleKey.Name .. " to toggle UI visibility",
        })

        settingsTab:CreateDivider()

        settingsTab:CreateSection("Actions")

        settingsTab:CreateButton({
            Name = "🔄 Reset Position",
            Callback = function()
                holder.Position = UDim2.fromScale(0.5, 0.5)
                window:Notify({
                    Title = "Reset",
                    Content = "Window position reset!",
                    Duration = 2,
                    Type = "success",
                })
            end,
        })

        settingsTab:CreateButton({
            Name = "📐 Reset Size",
            Callback = function()
                Tween(holder, 0.2, { Size = size })
                window:Notify({
                    Title = "Reset",
                    Content = "Window size reset!",
                    Duration = 2,
                    Type = "success",
                })
            end,
        })

        settingsTab:CreateButton({
            Name = "⏻ Unload Script",
            Callback = function()
                for _, cb in ipairs(window._unloadCallbacks) do
                    pcall(cb)
                end
                Tween(holder, 0.3, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(holder.AbsoluteSize.X, 0),
                })
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
                .. "\nJob ID: " .. tostring(game.JobId):sub(1, 24) .. "...",
        })

        infoTab:CreateParagraph({
            Title = "📊 Server Stats",
            Content = "Players: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers)
                .. "\nServer Age: " .. tostring(math.floor(game.Workspace.DistributedGameTime / 60)) .. " min"
                .. "\nGravity: " .. tostring(game.Workspace.Gravity),
        })

        infoTab:CreateDivider()

        infoTab:CreateSection("Quick Actions")

        infoTab:CreateButton({
            Name = "📋 Copy Place ID",
            Callback = function()
                pcall(function() setclipboard(tostring(game.PlaceId)) end)
                window:Notify({
                    Title = "Copied",
                    Content = "Place ID copied to clipboard!",
                    Duration = 2,
                    Type = "success",
                })
            end,
        })

        infoTab:CreateButton({
            Name = "📋 Copy Job ID",
            Callback = function()
                pcall(function() setclipboard(tostring(game.JobId)) end)
                window:Notify({
                    Title = "Copied",
                    Content = "Job ID copied to clipboard!",
                    Duration = 2,
                    Type = "success",
                })
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
                .. "\nAccount Age: " .. tostring(LocalPlayer.AccountAge) .. " days",
        })

        local membershipText = "None"
        if LocalPlayer.MembershipType == Enum.MembershipType.Premium then
            membershipText = "Premium"
        end

        playerTab:CreateParagraph({
            Title = "💎 Membership",
            Content = "Type: " .. membershipText
                .. "\nTeam: " .. tostring(LocalPlayer.Team and LocalPlayer.Team.Name or "None"),
        })

        playerTab:CreateDivider()

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
            Content = getCharStats(),
        })

        playerTab:CreateButton({
            Name = "🔄 Refresh Stats",
            Callback = function()
                local textLabel = nil
                for _, child in pairs(statsParagraph:GetDescendants()) do
                    if child:IsA("TextLabel")
                        and child.TextXAlignment == Enum.TextXAlignment.Left
                        and child.TextYAlignment == Enum.TextYAlignment.Top then
                        textLabel = child
                        break
                    end
                end
                if textLabel then
                    textLabel.Text = getCharStats()
                end
                window:Notify({
                    Title = "Refreshed",
                    Content = "Character stats updated!",
                    Duration = 2,
                    Type = "success",
                })
            end,
        })

        return playerTab
    end

    -- ═══════════════════════════════════════
    -- MAKE WINDOW DRAGGABLE
    -- ═══════════════════════════════════════
    MakeDraggable(topbar, holder)

    -- ═══════════════════════════════════════
    -- INTRO ANIMATION
    -- ═══════════════════════════════════════
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(size.X.Offset, 0)
    Tween(holder, 0.35, {
        BackgroundTransparency = windowTransparency,
        Size = size,
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return window
end

return setmetatable({}, Exter)
