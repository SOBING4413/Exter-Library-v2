--[[
    Exter Library v2
    Single-file Roblox UI library inspired by modern exploit/game hubs.

    Features:
    - Window + draggable topbar
    - Tabs
    - Sections
    - Button, Toggle, Slider, Dropdown, Input
    - Notification system
    - Premium dark style with gradients + smooth tween

    Usage:
    local Exter = loadstring(readfile("ExterLibrary.lua"))()

    local win = Exter:CreateWindow({
        Title = "Exter Premium",
        Subtitle = "by you",
        Size = UDim2.fromOffset(620, 420)
    })

    local main = win:CreateTab("Main")
    main:CreateSection("Actions")

    main:CreateButton({
        Name = "Print Hello",
        Callback = function()
            print("hello")
        end
    })

    local toggleState = false
    main:CreateToggle({
        Name = "Auto Farm",
        CurrentValue = false,
        Callback = function(v)
            toggleState = v
        end
    })

    main:CreateSlider({
        Name = "WalkSpeed",
        Range = {16, 120},
        Increment = 1,
        CurrentValue = 16,
        Suffix = " ws",
        Callback = function(v)
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    })

    main:CreateDropdown({
        Name = "Select Team",
        Options = {"Red", "Blue", "Green"},
        CurrentOption = "Red",
        Callback = function(opt)
            print("Selected:", opt)
        end
    })

    main:CreateInput({
        Name = "Player Name",
        PlaceholderText = "Type username...",
        Callback = function(txt)
            print("Input:", txt)
        end
    })

    win:Notify({
        Title = "Loaded",
        Content = "Exter Premium is ready!",
        Duration = 3
    })
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Exter = {}
Exter.__index = Exter

local Theme = {
    Background = Color3.fromRGB(12, 14, 20),
    Surface = Color3.fromRGB(19, 22, 31),
    Surface2 = Color3.fromRGB(26, 30, 42),
    Border = Color3.fromRGB(45, 52, 72),
    Text = Color3.fromRGB(232, 236, 244),
    TextDim = Color3.fromRGB(157, 166, 187),
    Accent = Color3.fromRGB(125, 95, 255),
    Accent2 = Color3.fromRGB(53, 159, 255),
    Success = Color3.fromRGB(68, 202, 139),
}

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

local function Tween(obj, t, props)
    local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
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
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Exter:CreateWindow(config)
    config = config or {}

    local title = config.Title or "Exter Premium"
    local subtitle = config.Subtitle or "UI Library"
    local size = config.Size or UDim2.fromOffset(640, 440)

    local screen = Create("ScreenGui", {
        Name = "ExterPremiumUI",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        Parent = PlayerGui,
    })

    local holder = Create("Frame", {
        Name = "Holder",
        Size = size,
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = screen,
    })
    AddCorner(holder, 14)
    AddStroke(holder, Theme.Border, 1.25, 0)

    local topGlow = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 120),
        Parent = holder,
    })
    AddGradient(topGlow, Theme.Accent, Theme.Accent2, 20)

    local topbar = Create("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, -16, 0, 56),
        Position = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = holder,
    })
    AddCorner(topbar, 12)
    AddStroke(topbar, Theme.Border, 1, 0)

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 0, 24),
        Position = UDim2.fromOffset(16, 8),
        Text = title,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.Text,
        Parent = topbar,
    })

    local subtitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 0, 16),
        Position = UDim2.fromOffset(16, 30),
        Text = subtitle,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Theme.TextDim,
        Parent = topbar,
    })

    local closeBtn = Create("TextButton", {
        Size = UDim2.fromOffset(34, 34),
        Position = UDim2.new(1, -42, 0.5, -17),
        BackgroundColor3 = Theme.Surface2,
        AutoButtonColor = false,
        Text = "✕",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        Parent = topbar,
    })
    AddCorner(closeBtn, 9)
    AddStroke(closeBtn, Theme.Border, 1, 0)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(170, 58, 58)})
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, 0.15, {BackgroundColor3 = Theme.Surface2})
    end)
    closeBtn.MouseButton1Click:Connect(function()
        screen:Destroy()
    end)

    local body = Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -16, 1, -72),
        Position = UDim2.fromOffset(8, 64),
        BackgroundTransparency = 1,
        Parent = holder,
    })

    local tabButtons = Create("Frame", {
        Name = "TabButtons",
        Size = UDim2.new(0, 170, 1, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = body,
    })
    AddCorner(tabButtons, 12)
    AddStroke(tabButtons, Theme.Border, 1, 0)

    local tabList = Create("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tabButtons,
    })

    local tabPadding = Create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 12),
        Parent = tabButtons,
    })

    local content = Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -178, 1, 0),
        Position = UDim2.fromOffset(178, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = body,
    })
    AddCorner(content, 12)
    AddStroke(content, Theme.Border, 1, 0)

    local notificationHolder = Create("Frame", {
        Name = "Notifications",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 320, 1, -20),
        Position = UDim2.new(1, -330, 0, 10),
        Parent = screen,
    })

    local notifList = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent = notificationHolder,
    })

    local window = {
        _screen = screen,
        _content = content,
        _tabButtons = tabButtons,
        _activeTab = nil,
        _tabs = {},
        _notifHolder = notificationHolder,
    }

    function window:Notify(cfg)
        cfg = cfg or {}
        local nTitle = cfg.Title or "Notification"
        local nText = cfg.Content or ""
        local duration = cfg.Duration or 3

        local card = Create("Frame", {
            Size = UDim2.new(1, 0, 0, 74),
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            BackgroundTransparency = 0.05,
            Parent = notificationHolder,
        })
        AddCorner(card, 10)
        AddStroke(card, Theme.Border, 1, 0)

        local line = Create("Frame", {
            Size = UDim2.new(0, 4, 1, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Parent = card,
        })
        AddCorner(line, 8)
        AddGradient(line, Theme.Accent, Theme.Accent2, 90)

        local t1 = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.new(1, -20, 0, 20),
            Text = nTitle,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.Text,
            Parent = card,
        })

        local t2 = Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.new(1, -20, 0, 34),
            Text = nText,
            TextWrapped = true,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextColor3 = Theme.TextDim,
            Parent = card,
        })

        card.BackgroundTransparency = 1
        card.Position = card.Position + UDim2.fromOffset(30, 0)
        Tween(card, 0.2, {BackgroundTransparency = 0.05, Position = card.Position - UDim2.fromOffset(30, 0)})

        task.delay(duration, function()
            if card and card.Parent then
                local tw = Tween(card, 0.2, {BackgroundTransparency = 1, Position = card.Position + UDim2.fromOffset(30, 0)})
                tw.Completed:Wait()
                card:Destroy()
            end
        end)
    end

    local function createTabButton(name)
        local btn = Create("TextButton", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Theme.Surface2,
            AutoButtonColor = false,
            Text = "",
            Parent = tabButtons,
        })
        AddCorner(btn, 9)
        AddStroke(btn, Theme.Border, 1, 0)

        local label = Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -18, 1, 0),
            Position = UDim2.fromOffset(12, 0),
            Text = name,
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = Theme.TextDim,
            Parent = btn,
        })

        return btn, label
    end

    function window:CreateTab(name)
        local tabName = name or "Tab"

        local btn, btnLabel = createTabButton(tabName)

        local page = Create("ScrollingFrame", {
            Name = tabName .. "Page",
            Size = UDim2.new(1, -18, 1, -18),
            Position = UDim2.fromOffset(9, 9),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarImageColor3 = Theme.Accent,
            ScrollBarThickness = 4,
            BackgroundTransparency = 1,
            Visible = false,
            Parent = content,
        })

        local layout = Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 10),
            Parent = page,
        })

        Create("UIPadding", {
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
            Parent = page,
        })

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
        end)

        local tab = {
            _page = page,
            _layout = layout,
            _window = window,
        }

        local function createBaseControl(height)
            local container = Create("Frame", {
                Size = UDim2.new(1, 0, 0, height),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Parent = page,
            })
            AddCorner(container, 10)
            AddStroke(container, Theme.Border, 1, 0)
            return container
        end

        function tab:CreateSection(text)
            local label = Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
                Text = text or "Section",
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = page,
            })
            return label
        end

        function tab:CreateButton(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Button"
            local callback = cfg.Callback or function() end

            local control = createBaseControl(44)

            local button = Create("TextButton", {
                Size = UDim2.new(1, -12, 1, -12),
                Position = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                Parent = control,
            })
            AddCorner(button, 8)
            AddGradient(button, Theme.Accent, Theme.Accent2, 25)

            button.MouseEnter:Connect(function()
                Tween(button, 0.12, {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5)})
            end)
            button.MouseLeave:Connect(function()
                Tween(button, 0.12, {Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6)})
            end)
            button.MouseButton1Click:Connect(function()
                callback()
            end)

            return button
        end

        function tab:CreateToggle(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Toggle"
            local current = cfg.CurrentValue or false
            local callback = cfg.Callback or function() end

            local control = createBaseControl(52)

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -90, 1, 0),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local toggleBtn = Create("TextButton", {
                Size = UDim2.fromOffset(46, 24),
                Position = UDim2.new(1, -58, 0.5, -12),
                BackgroundColor3 = current and Theme.Success or Color3.fromRGB(64, 68, 82),
                Text = "",
                AutoButtonColor = false,
                Parent = control,
            })
            AddCorner(toggleBtn, 999)

            local knob = Create("Frame", {
                Size = UDim2.fromOffset(20, 20),
                Position = current and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2),
                BackgroundColor3 = Theme.Text,
                BorderSizePixel = 0,
                Parent = toggleBtn,
            })
            AddCorner(knob, 999)

            local function setToggle(v)
                current = v
                Tween(toggleBtn, 0.14, {BackgroundColor3 = current and Theme.Success or Color3.fromRGB(64, 68, 82)})
                Tween(knob, 0.14, {Position = current and UDim2.fromOffset(24, 2) or UDim2.fromOffset(2, 2)})
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

        function tab:CreateSlider(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Slider"
            local range = cfg.Range or {0, 100}
            local minVal, maxVal = range[1], range[2]
            local inc = cfg.Increment or 1
            local suffix = cfg.Suffix or ""
            local value = cfg.CurrentValue or minVal
            local callback = cfg.Callback or function() end

            local control = createBaseControl(68)

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 6),
                Size = UDim2.new(1, -24, 0, 18),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(1, -70, 0, 6),
                Size = UDim2.fromOffset(60, 18),
                Text = tostring(value) .. suffix,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextColor3 = Theme.TextDim,
                TextXAlignment = Enum.TextXAlignment.Right,
                Parent = control,
            })

            local bar = Create("Frame", {
                Size = UDim2.new(1, -24, 0, 8),
                Position = UDim2.fromOffset(12, 40),
                BackgroundColor3 = Color3.fromRGB(54, 59, 75),
                BorderSizePixel = 0,
                Parent = control,
            })
            AddCorner(bar, 999)

            local fill = Create("Frame", {
                Size = UDim2.new((value - minVal) / (maxVal - minVal), 0, 1, 0),
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Parent = bar,
            })
            AddCorner(fill, 999)
            AddGradient(fill, Theme.Accent, Theme.Accent2, 0)

            local dragging = false

            local function setFromScale(scale)
                scale = math.clamp(scale, 0, 1)
                local raw = minVal + (maxVal - minVal) * scale
                local snapped = Round(raw, inc)
                snapped = math.clamp(snapped, minVal, maxVal)
                value = snapped

                local alpha = (value - minVal) / (maxVal - minVal)
                fill.Size = UDim2.new(alpha, 0, 1, 0)
                valueLabel.Text = tostring(value) .. suffix
                callback(value)
            end

            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    local scale = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
                    setFromScale(scale)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
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

        function tab:CreateDropdown(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Dropdown"
            local options = cfg.Options or {}
            local current = cfg.CurrentOption or options[1] or "None"
            local callback = cfg.Callback or function() end

            local control = createBaseControl(52)
            local opened = false

            local mainBtn = Create("TextButton", {
                Size = UDim2.new(1, -12, 1, -12),
                Position = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Color3.fromRGB(49, 54, 69),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                Parent = control,
            })
            AddCorner(mainBtn, 8)
            AddStroke(mainBtn, Theme.Border, 1, 0)

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(0.55, 0, 1, 0),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextColor3 = Theme.Text,
                Parent = mainBtn,
            })

            local valueLabel = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.new(0.55, 0, 0, 0),
                Size = UDim2.new(0.45, -20, 1, 0),
                Text = tostring(current),
                Font = Enum.Font.Gotham,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = Theme.TextDim,
                Parent = mainBtn,
            })

            local icon = Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(20, 20),
                Position = UDim2.new(1, -22, 0.5, -10),
                Text = "▾",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Theme.TextDim,
                Parent = mainBtn,
            })

            local listFrame = Create("Frame", {
                Visible = false,
                Size = UDim2.new(1, -12, 0, 0),
                Position = UDim2.fromOffset(6, 46),
                BackgroundColor3 = Theme.Surface2,
                BorderSizePixel = 0,
                Parent = control,
                ClipsDescendants = true,
            })
            AddCorner(listFrame, 8)
            AddStroke(listFrame, Theme.Border, 1, 0)

            local listLayout = Create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
                Parent = listFrame,
            })

            local padding = Create("UIPadding", {
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
                Parent = listFrame,
            })

            local buttons = {}
            for _, option in ipairs(options) do
                local opt = Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = Color3.fromRGB(56, 62, 78),
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    Font = Enum.Font.Gotham,
                    TextSize = 12,
                    TextColor3 = Theme.Text,
                    AutoButtonColor = false,
                    Parent = listFrame,
                })
                AddCorner(opt, 6)

                opt.MouseButton1Click:Connect(function()
                    current = option
                    valueLabel.Text = tostring(option)
                    callback(option)
                    opened = false
                    Tween(icon, 0.14, {Rotation = 0})
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 52)})
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
                return (count * 28) + ((count - 1) * 4) + 12
            end

            mainBtn.MouseButton1Click:Connect(function()
                opened = not opened
                Tween(icon, 0.14, {Rotation = opened and 180 or 0})

                if opened then
                    listFrame.Visible = true
                    local h = getListHeight()
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 52 + h + 8)})
                    Tween(listFrame, 0.16, {Size = UDim2.new(1, -12, 0, h)})
                else
                    Tween(control, 0.16, {Size = UDim2.new(1, 0, 0, 52)})
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

        function tab:CreateInput(cfg)
            cfg = cfg or {}
            local nameText = cfg.Name or "Input"
            local placeholder = cfg.PlaceholderText or "Type here..."
            local callback = cfg.Callback or function() end

            local control = createBaseControl(64)

            local label = Create("TextLabel", {
                BackgroundTransparency = 1,
                Position = UDim2.fromOffset(12, 6),
                Size = UDim2.new(1, -24, 0, 18),
                Text = nameText,
                Font = Enum.Font.GothamSemibold,
                TextSize = 13,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = control,
            })

            local input = Create("TextBox", {
                Size = UDim2.new(1, -24, 0, 30),
                Position = UDim2.fromOffset(12, 28),
                BackgroundColor3 = Color3.fromRGB(50, 55, 70),
                BorderSizePixel = 0,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                PlaceholderText = placeholder,
                PlaceholderColor3 = Theme.TextDim,
                TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                ClearTextOnFocus = false,
                Parent = control,
            })
            AddCorner(input, 8)
            AddStroke(input, Theme.Border, 1, 0)

            input.FocusLost:Connect(function(enterPressed)
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

        local function activate()
            if window._activeTab then
                window._activeTab.page.Visible = false
                Tween(window._activeTab.button, 0.12, {BackgroundColor3 = Theme.Surface2})
                window._activeTab.label.TextColor3 = Theme.TextDim
            end

            page.Visible = true
            Tween(btn, 0.12, {BackgroundColor3 = Color3.fromRGB(57, 65, 86)})
            btnLabel.TextColor3 = Theme.Text

            window._activeTab = {
                page = page,
                button = btn,
                label = btnLabel,
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

    MakeDraggable(topbar, holder)

    return window
end

return setmetatable({}, Exter)
