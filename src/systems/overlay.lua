--[[
	Exter Library | Overlay systems
	Tooltip · Dialog / Confirm / Prompt · Watermark · Command Palette

	These live above the window (not inside a tab), so they are exposed on the
	Library object:  Library:Dialog, Library:Confirm, Library:Prompt,
	Library:CreateWatermark, Library:RegisterCommand, Library:EnableCommandPalette,
	Library:AttachTooltip
]]

return function(Library, Kit)
	local P = Kit.Palette
	local I = Library._Internal
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local FULL = UDim.new(1, 0)

	----------------------------------------------------------------------
	-- Overlay root (one full-screen, click-through layer above the window)
	----------------------------------------------------------------------
	local root
	function Kit.Overlay()
		if root and root.Parent then return root end
		root = Kit.Frame(I.GetGui(), { Name = "ExterOverlay", Size = UDim2.new(1, 0, 1, 0), ZIndex = 500, Active = false })
		return root
	end

	function Kit.MakeDraggable(handle, target)
		local dragging, startX, startY, origin = false, 0, 0, nil
		I.Track(handle.InputBegan:Connect(function(input)
			if Kit.IsPointer(input) then
				dragging, startX, startY, origin = true, input.Position.X, input.Position.Y, target.Position
			end
		end))
		I.Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + (input.Position.X - startX), origin.Y.Scale, origin.Y.Offset + (input.Position.Y - startY))
			end
		end))
		I.Track(UserInputService.InputEnded:Connect(function(input)
			if dragging and Kit.IsPointer(input) then dragging = false end
		end))
	end

	local function labelWidth(text, size) return #tostring(text) * (size or 13) * 0.55 end

	-- Styled dialog button (Primary = accent fill, Danger = red, default = ghost).
	local function styledButton(parent, def, order)
		local b = Kit.Button(parent, {
			Name = "Btn_" .. tostring(def.Name), Text = tostring(def.Name), LayoutOrder = order,
			Size = UDim2.fromOffset(math.max(84, labelWidth(def.Name, 14) + 30), 32), ZIndex = 515,
			FontFace = Kit.Font(Enum.FontWeight.SemiBold), TextSize = Kit.Style.Title - 1,
			BackgroundTransparency = 0, BackgroundColor3 = P.Track, TextColor3 = P.TextDim,
		})
		Kit.Corner(b, 7)
		local stroke = Kit.Stroke(b, P.Stroke, 0.3)
		if def.Danger then
			b.BackgroundColor3 = P.Error; b.TextColor3 = Color3.new(1, 1, 1); stroke.Transparency = 1
		elseif def.Primary then
			b.BackgroundColor3 = Color3.new(1, 1, 1); b.TextColor3 = Color3.new(1, 1, 1); stroke.Transparency = 1
			Kit.Gradient(b)
		else
			b.MouseEnter:Connect(function() Kit.Tween(b, { BackgroundColor3 = P.SurfaceHi, TextColor3 = P.Text }, 0.12) end)
			b.MouseLeave:Connect(function() Kit.Tween(b, { BackgroundColor3 = P.Track, TextColor3 = P.TextDim }, 0.15) end)
		end
		return b
	end

	----------------------------------------------------------------------
	-- Tooltips
	----------------------------------------------------------------------
	local tip, tipOwner
	local function ensureTip()
		if tip and tip.Frame.Parent then return tip end
		local frame = Kit.Frame(Kit.Overlay(), { Name = "Tooltip", Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundColor3 = P.SurfaceAlt, BackgroundTransparency = 0.04, Visible = false, ZIndex = 540 })
		Kit.Corner(frame, 6)
		Kit.Stroke(frame, P.StrokeHover, 0.2)
		Kit.Pad(frame, 9, 6, 9, 6)
		Kit.new("UISizeConstraint", { MaxSize = Vector2.new(280, math.huge), Parent = frame })
		local label = Kit.Text(frame, { Name = "Text", Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY, TextWrapped = true, TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextDim, ZIndex = 541 })
		tip = { Frame = frame, Label = label }
		I.Track(UserInputService.InputChanged:Connect(function(input)
			if frame.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
				local abs, size, mine = root.AbsolutePosition, root.AbsoluteSize, frame.AbsoluteSize
				local x = math.min(input.Position.X + 14 - abs.X, math.max(0, size.X - mine.X - 6))
				local y = math.min(input.Position.Y + 18 - abs.Y, math.max(0, size.Y - mine.Y - 6))
				frame.Position = UDim2.fromOffset(x, y)
			end
		end))
		return tip
	end

	local function showTip(handle)
		local t = ensureTip()
		local text = handle.Text
		if type(text) == "function" then local ok, out = pcall(text); text = ok and out or "" end
		if text == nil or text == "" then return end
		tipOwner = handle
		t.Label.Text = tostring(text)
		local loc = UserInputService:GetMouseLocation()
		local abs = root.AbsolutePosition
		t.Frame.Position = UDim2.fromOffset(loc.X + 14 - abs.X, loc.Y + 18 - abs.Y)
		t.Frame.Visible = true
	end

	local function hideTip(handle)
		if tip and (handle == nil or tipOwner == handle) then tip.Frame.Visible = false; tipOwner = nil end
	end

	function Kit.AttachTooltip(gui, text)
		local handle = { Text = text }
		local token, hovering = 0, false
		local enter = gui.MouseEnter:Connect(function()
			hovering = true; token = token + 1
			local mine = token
			task.delay(0.4, function() if hovering and mine == token and gui.Parent then showTip(handle) end end)
		end)
		local leave = gui.MouseLeave:Connect(function() hovering = false; token = token + 1; hideTip(handle) end)
		function handle:SetText(new) handle.Text = new; if tipOwner == handle and tip then tip.Label.Text = tostring(new) end end
		function handle:Disconnect() enter:Disconnect(); leave:Disconnect(); hideTip(handle) end
		return handle
	end
	function Library:AttachTooltip(gui, text) return Kit.AttachTooltip(gui, text) end

	----------------------------------------------------------------------
	-- Dialog
	----------------------------------------------------------------------
	local TYPE_ICON = { Info = "info", Success = "check_circle", Warning = "warning", Error = "error" }

	function Library:Dialog(opts)
		opts = Kit.Defaults({
			Title = "Dialog", Content = "", Type = nil, Icon = nil, ImageSource = "Material",
			Buttons = { { Name = "OK", Primary = true } }, Dismissible = true, Width = 340, Body = nil,
		}, opts)
		local overlay = Kit.Overlay()
		local dlg = { Closed = Kit.Signal.new(), IsOpen = true }

		local backdrop = Kit.Button(overlay, { Name = "DialogBackdrop", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 510, Active = true })
		Kit.Tween(backdrop, { BackgroundTransparency = 0.45 }, 0.25)
		local panel = Kit.Button(backdrop, { Name = "Dialog", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0, opts.Width, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.SurfaceAlt, BackgroundTransparency = 1, ZIndex = 511, Active = true })
		Kit.Corner(panel, 12)
		local stroke = Kit.Stroke(panel, P.StrokeHover, 1)
		Kit.Pad(panel, 20, 18, 20, 18)
		local list = Kit.List(panel, 12)
		local scale = Kit.new("UIScale", { Scale = 0.92, Parent = panel })
		Kit.Tween(scale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
		Kit.Tween(panel, { BackgroundTransparency = 0.02 }, 0.2)
		Kit.Tween(stroke, { Transparency = 0.25 }, 0.3)

		local color = opts.Type and ({ Info = P.Info, Success = P.Success, Warning = P.Warning, Error = P.Error })[opts.Type] or Kit.Accent()
		local head = Kit.Frame(panel, { Name = "Head", Size = UDim2.new(1, 0, 0, 24), LayoutOrder = 1, ZIndex = 512 })
		local textLeft = 0
		local iconName = opts.Icon or (opts.Type and TYPE_ICON[opts.Type])
		if iconName then
			textLeft = 28
			Kit.Icon(head, iconName, opts.ImageSource, { Size = UDim2.fromOffset(20, 20), Position = UDim2.new(0, 0, 0.5, -10), ImageColor3 = color, ZIndex = 513 })
		end
		Kit.Text(head, { Name = "Title", Text = opts.Title, TextSize = Kit.Style.Title + 3, Weight = Enum.FontWeight.Bold, Position = UDim2.new(0, textLeft, 0, 0), Size = UDim2.new(1, -textLeft, 1, 0), ZIndex = 513 })
		if opts.Content ~= "" then
			Kit.Text(panel, { Name = "Content", Text = opts.Content, TextWrapped = true, TextColor3 = P.TextDim, TextSize = Kit.Style.Title - 1, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, ZIndex = 513, RichText = opts.RichText == true })
		end
		if opts.Body then
			local body = Kit.Frame(panel, { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 3, ZIndex = 513 })
			local ok, err = pcall(opts.Body, body, dlg)
			if not ok then warn("[Exter] Dialog Body error: " .. tostring(err)) end
		end
		local row = Kit.Frame(panel, { Name = "Buttons", Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 4, ZIndex = 513 })
		Kit.List(row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

		local escape
		function dlg:Close(result)
			if not dlg.IsOpen then return end
			dlg.IsOpen = false
			if escape then escape:Disconnect() end
			Kit.Tween(scale, { Scale = 0.94 }, 0.18)
			Kit.Tween(panel, { BackgroundTransparency = 1 }, 0.18)
			Kit.Tween(stroke, { Transparency = 1 }, 0.18)
			Kit.Tween(backdrop, { BackgroundTransparency = 1 }, 0.2)
			task.delay(0.22, function() if backdrop.Parent then backdrop:Destroy() end end)
			dlg.Closed:Fire(result)
		end
		dlg.Backdrop, dlg.Panel = backdrop, panel

		for i, def in ipairs(opts.Buttons) do
			local b = styledButton(row, def, i)
			b.MouseButton1Click:Connect(function()
				if def.Callback then
					local ok, err = pcall(def.Callback, dlg)
					if not ok then print("Exter Library | Dialog button '" .. tostring(def.Name) .. "' error " .. tostring(err)) end
				end
				if def.Keep ~= true then dlg:Close(def.Name) end
			end)
		end

		if opts.Dismissible then
			backdrop.MouseButton1Click:Connect(function() dlg:Close(nil) end)
			escape = I.Track(UserInputService.InputBegan:Connect(function(input)
				if input.KeyCode == Enum.KeyCode.Escape then dlg:Close(nil) end
			end))
		end
		return dlg
	end

	-- Yields until the user decides. Pass a callback(bool) to stay non-blocking.
	function Library:Confirm(opts, callback)
		opts = Kit.Defaults({ Title = "Are you sure?", Content = "", Confirm = "Confirm", Cancel = "Cancel", Danger = false, Type = nil }, opts)
		local dlg = Library:Dialog({
			Title = opts.Title, Content = opts.Content, Type = opts.Type or (opts.Danger and "Warning" or nil), Dismissible = opts.Dismissible ~= false,
			Buttons = { { Name = opts.Cancel }, { Name = opts.Confirm, Primary = not opts.Danger, Danger = opts.Danger } },
		})
		if callback then
			dlg.Closed:Once(function(result) callback(result == opts.Confirm) end)
			return dlg
		end
		return dlg.Closed:Wait() == opts.Confirm
	end

	-- Yields and returns the entered text (or nil when cancelled).
	function Library:Prompt(opts, callback)
		opts = Kit.Defaults({ Title = "Enter a value", Content = "", Placeholder = "", Default = "", Confirm = "OK", Cancel = "Cancel", Validate = nil, MaxLength = 0 }, opts)
		local box, errorLabel
		local dlg
		dlg = Library:Dialog({
			Title = opts.Title, Content = opts.Content, Dismissible = opts.Dismissible ~= false,
			Body = function(body)
				Kit.List(body, 6)
				box = Kit.new("TextBox", {
					Name = "Input", BackgroundColor3 = P.Track, BackgroundTransparency = 0.1, BorderSizePixel = 0, ClearTextOnFocus = false, Text = tostring(opts.Default),
					PlaceholderText = opts.Placeholder, PlaceholderColor3 = P.TextMute, TextColor3 = P.Text, FontFace = Kit.Font(), TextSize = Kit.Style.Title - 1,
					TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, ZIndex = 514, Parent = body,
				})
				Kit.Corner(box, 7)
				local st = Kit.Stroke(box, P.Stroke, 0.3)
				Kit.Pad(box, 10, 0, 10, 0)
				box.Focused:Connect(function() Kit.Tween(st, { Color = Kit.Accent(), Transparency = 0 }, 0.15) end)
				box.FocusLost:Connect(function(enter)
					Kit.Tween(st, { Color = P.Stroke, Transparency = 0.3 }, 0.2)
					if enter and dlg then dlg.Submit() end
				end)
				if opts.MaxLength > 0 then
					box:GetPropertyChangedSignal("Text"):Connect(function() if #box.Text > opts.MaxLength then box.Text = box.Text:sub(1, opts.MaxLength) end end)
				end
				errorLabel = Kit.Text(body, { Name = "Error", Text = "", TextColor3 = P.Error, TextSize = Kit.Style.Desc, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2, ZIndex = 514, Visible = false })
				task.delay(0.1, function() if box.Parent then box:CaptureFocus() end end)
			end,
			Buttons = {
				{ Name = opts.Cancel },
				{ Name = opts.Confirm, Primary = true, Keep = true, Callback = function() dlg.Submit() end },
			},
		})
		function dlg.Submit()
			if not dlg.IsOpen then return end
			local text = box.Text
			if opts.Validate then
				local ok, valid, message = pcall(opts.Validate, text)
				if ok and valid == false then
					errorLabel.Text = tostring(message or "Invalid value"); errorLabel.Visible = true
					return
				end
			end
			dlg.Value = text
			dlg:Close(opts.Confirm)
		end
		if callback then
			dlg.Closed:Once(function(result) callback(result == opts.Confirm and dlg.Value or nil) end)
			return dlg
		end
		local result = dlg.Closed:Wait()
		return result == opts.Confirm and dlg.Value or nil
	end

	----------------------------------------------------------------------
	-- Watermark / HUD
	----------------------------------------------------------------------
	local fps, frames, acc = 60, 0, 0
	local fpsHooked = false
	local function hookFps()
		if fpsHooked then return end
		fpsHooked = true
		I.Track(RunService.RenderStepped:Connect(function(dt)
			frames = frames + 1; acc = acc + dt
			if acc >= 0.5 then fps = math.floor(frames / acc + 0.5); frames, acc = 0, 0 end
		end))
	end

	local function readPing()
		local ok, value = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
		return ok and math.floor(value + 0.5) or 0
	end

	local ANCHORS = {
		TopLeft = { Vector2.new(0, 0), UDim2.new(0, 12, 0, 12) }, TopRight = { Vector2.new(1, 0), UDim2.new(1, -12, 0, 12) },
		BottomLeft = { Vector2.new(0, 1), UDim2.new(0, 12, 1, -12) }, BottomRight = { Vector2.new(1, 1), UDim2.new(1, -12, 1, -12) },
		TopCenter = { Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 12) },
	}

	function Library:CreateWatermark(opts)
		opts = Kit.Defaults({ Text = "{name} | {fps} fps | {ping} ms | {time}", Position = "TopRight", Draggable = true, Visible = true, Variables = {}, Interval = 0.5 }, opts)
		hookFps()
		local anchor = ANCHORS[opts.Position] or ANCHORS.TopRight
		local frame = Kit.Frame(Kit.Overlay(), { Name = "Watermark", AnchorPoint = anchor[1], Position = anchor[2], Size = UDim2.new(0, 0, 0, 28), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = P.SurfaceAlt, BackgroundTransparency = 0.08, ZIndex = 505, Visible = opts.Visible })
		Kit.Corner(frame, 7)
		Kit.Stroke(frame, P.Stroke, 0.35)
		local line = Kit.Frame(frame, { Name = "Accent", Size = UDim2.new(1, -14, 0, 2), Position = UDim2.new(0, 7, 0, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 507 })
		Kit.Corner(line, FULL)
		Kit.Gradient(line)
		Kit.Pad(frame, 12, 0, 12, 0)
		local label = Kit.Text(frame, { Name = "Text", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = Kit.Style.Desc + 1, TextColor3 = P.Text, ZIndex = 506 })

		local wm = { Frame = frame, Variables = opts.Variables, Alive = true }
		local builtin = {
			fps = function() return fps end, ping = readPing,
			time = function() return os.date("%H:%M:%S") end, date = function() return os.date("%d/%m/%Y") end,
			name = function() local lp = Players.LocalPlayer return lp and (lp.DisplayName or lp.Name) or "Player" end,
		}
		function wm:Render()
			label.Text = (tostring(opts.Text):gsub("{(%w+)}", function(key)
				local source = wm.Variables[key]
				if source == nil then source = builtin[key] end
				if type(source) == "function" then local ok, out = pcall(source) return ok and tostring(out) or "?" end
				if source ~= nil then return tostring(source) end
				return "{" .. key .. "}"
			end))
		end
		function wm:SetText(text) opts.Text = text; wm:Render() end
		function wm:SetVariable(key, value) wm.Variables[key] = value; wm:Render() end
		function wm:SetVisible(state) frame.Visible = state and true or false end
		function wm:Destroy() wm.Alive = false; frame:Destroy() end

		if opts.Draggable then Kit.MakeDraggable(frame, frame) end
		task.spawn(function()
			while wm.Alive and frame.Parent and not Library._destroyed do
				wm:Render()
				task.wait(opts.Interval)
			end
		end)
		wm:Render()
		return wm
	end

	----------------------------------------------------------------------
	-- Command palette
	----------------------------------------------------------------------
	local commands = {}

	function Library:RegisterCommand(def)
		def = Kit.Defaults({ Name = "Command", Description = nil, Icon = "bolt", Keywords = nil, Callback = function() end }, def)
		commands[#commands + 1] = def
		return { Remove = function() for i, c in ipairs(commands) do if c == def then table.remove(commands, i) break end end end }
	end

	local function score(name, query)
		if query == "" then return 1 end
		local n, q = name:lower(), query:lower()
		local pos = n:find(q, 1, true)
		if pos then return 1000 - pos - #n * 0.1 + (pos == 1 and 100 or 0) end
		local qi, last, total = 1, 0, 0
		for i = 1, #n do
			if n:sub(i, i) == q:sub(qi, qi) then
				total = total + (i == last + 1 and 5 or 1)
				last, qi = i, qi + 1
				if qi > #q then return total end
			end
		end
		return nil
	end
	Kit.FuzzyScore = score

	local function collect()
		local list = {}
		for _, c in ipairs(commands) do
			list[#list + 1] = { Name = c.Name, Hint = c.Description or "Command", Icon = c.Icon, Keywords = c.Keywords, Run = c.Callback }
		end
		for _, t in ipairs(Library._Tabs or {}) do
			list[#list + 1] = { Name = "Go to " .. tostring(t.Name), Hint = "Tab", Icon = "chevron_right", Run = function() if t.Tab and t.Tab.Activate then t.Tab:Activate() end end }
		end
		for _, e in ipairs(Kit.Registry) do
			local n = e.Settings and e.Settings.Name
			if type(n) == "string" and not e._destroyed then
				local tabName = e.Tab and e.Tab.Name or "Element"
				list[#list + 1] = { Name = n, Hint = tabName .. "  /  " .. e.Class, Icon = "tune", Run = function()
					if e.Tab and e.Tab.Activate then e.Tab:Activate() end
					task.delay(0.2, function() if not e._destroyed then e:Flash() end end)
				end }
			end
		end
		return list
	end

	local palette
	function Library:IsCommandPaletteOpen() return palette ~= nil and palette.Open end

	function Library:CloseCommandPalette()
		if not palette or not palette.Open then return end
		palette.Open = false
		local p = palette
		Kit.Tween(p.Backdrop, { BackgroundTransparency = 1 }, 0.15)
		Kit.Tween(p.Scale, { Scale = 0.96 }, 0.15)
		Kit.Tween(p.Panel, { BackgroundTransparency = 1 }, 0.15)
		if p.Keys then p.Keys:Disconnect() end
		task.delay(0.18, function() if p.Backdrop.Parent then p.Backdrop:Destroy() end end)
		palette = nil
	end

	function Library:OpenCommandPalette()
		if palette and palette.Open then return end
		local overlay = Kit.Overlay()
		local p = { Open = true, Selected = 1, Rows = {}, Results = {} }
		palette = p
		p.Backdrop = Kit.Button(overlay, { Name = "PaletteBackdrop", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), ZIndex = 530, Active = true })
		Kit.Tween(p.Backdrop, { BackgroundTransparency = 0.5 }, 0.2)
		p.Panel = Kit.Button(p.Backdrop, { Name = "Palette", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.14, 0), Size = UDim2.new(0, 440, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = P.SurfaceAlt, BackgroundTransparency = 1, ZIndex = 531, Active = true })
		Kit.Corner(p.Panel, 12)
		local stroke = Kit.Stroke(p.Panel, P.StrokeHover, 1)
		p.Scale = Kit.new("UIScale", { Scale = 0.96, Parent = p.Panel })
		Kit.Tween(p.Scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quint)
		Kit.Tween(p.Panel, { BackgroundTransparency = 0.02 }, 0.2)
		Kit.Tween(stroke, { Transparency = 0.25 }, 0.25)
		Kit.List(p.Panel, 0)

		local top = Kit.Frame(p.Panel, { Name = "Top", Size = UDim2.new(1, 0, 0, 48), LayoutOrder = 1, ZIndex = 532 })
		Kit.Icon(top, "search", "Material", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 16, 0.5, -9), ImageColor3 = P.TextMute, ZIndex = 533 })
		local box = Kit.new("TextBox", {
			Name = "Query", BackgroundTransparency = 1, BorderSizePixel = 0, ClearTextOnFocus = false, Text = "", PlaceholderText = "Search commands, tabs and settings...",
			PlaceholderColor3 = P.TextMute, TextColor3 = P.Text, FontFace = Kit.Font(), TextSize = Kit.Style.Title + 1, TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 44, 0, 0), Size = UDim2.new(1, -60, 1, 0), ZIndex = 533, Parent = top,
		})
		Kit.Frame(p.Panel, { Name = "Line", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Stroke, BackgroundTransparency = 0.4, LayoutOrder = 2, ZIndex = 532 })
		local list = Kit.new("ScrollingFrame", {
			Name = "Results", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.None, LayoutOrder = 3, ZIndex = 532,
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = P.StrokeHover, Parent = p.Panel,
		})
		Kit.Pad(list, 6, 6, 6, 6)
		Kit.List(list, 2)
		local foot = Kit.Text(p.Panel, { Name = "Hint", Text = "Up / Down  navigate      Enter  run      Esc  close", TextSize = Kit.Style.Desc - 1, TextColor3 = P.TextMute, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 4, ZIndex = 532 })

		local all = collect()
		local function paintSelection()
			for i, row in ipairs(p.Rows) do
				local on = i == p.Selected
				Kit.Tween(row, { BackgroundTransparency = on and 0.8 or 1 }, 0.1)
			end
		end

		local function run(index)
			local item = p.Results[index]
			if not item then return end
			Library:CloseCommandPalette()
			task.defer(function()
				local ok, err = pcall(item.Run)
				if not ok then print("Exter Library | Command '" .. tostring(item.Name) .. "' error " .. tostring(err)) end
			end)
		end
		p.Run = run

		local function refresh()
			for _, r in ipairs(p.Rows) do r:Destroy() end
			p.Rows, p.Results = {}, {}
			local q = box.Text
			local scored = {}
			for _, item in ipairs(all) do
				local s = score(item.Name, q)
				if not s and item.Keywords then
					for _, k in ipairs(item.Keywords) do local ks = score(k, q) if ks then s = (s or 0) + ks * 0.5 end end
				end
				if s then scored[#scored + 1] = { item = item, score = s } end
			end
			table.sort(scored, function(a, b) if a.score ~= b.score then return a.score > b.score end return a.item.Name < b.item.Name end)
			for i = 1, math.min(#scored, 30) do
				local item = scored[i].item
				p.Results[i] = item
				local row = Kit.Button(list, { Name = "Row" .. i, Size = UDim2.new(1, 0, 0, 36), LayoutOrder = i, BackgroundColor3 = Kit.Accent(), BackgroundTransparency = 1, ZIndex = 533 })
				Kit.Corner(row, 7)
				Kit.Icon(row, item.Icon or "bolt", "Material", { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 10, 0.5, -8), ImageColor3 = P.TextDim, ZIndex = 534 })
				Kit.Text(row, { Name = "Name", Text = item.Name, Position = UDim2.new(0, 36, 0, 0), Size = UDim2.new(0.55, -36, 1, 0), TextSize = Kit.Style.Title - 1, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 534 })
				Kit.Text(row, { Name = "Hint", Text = item.Hint or "", Position = UDim2.new(0.55, 0, 0, 0), Size = UDim2.new(0.45, -10, 1, 0), TextSize = Kit.Style.Desc, TextColor3 = P.TextMute, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 534 })
				row.MouseEnter:Connect(function() p.Selected = i; paintSelection() end)
				row.MouseButton1Click:Connect(function() run(i) end)
				p.Rows[i] = row
			end
			if #scored == 0 then
				local none = Kit.Text(list, { Name = "None", Text = "No matches", TextColor3 = P.TextMute, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 40), ZIndex = 533 })
				p.Rows[1] = none
			end
			p.Selected = 1
			list.Size = UDim2.new(1, 0, 0, math.min(math.max(#scored, 1), 8) * 38 + 12)
			paintSelection()
		end

		box:GetPropertyChangedSignal("Text"):Connect(refresh)
		box.FocusLost:Connect(function(enter) if enter then run(p.Selected) end end)
		p.Backdrop.MouseButton1Click:Connect(function() Library:CloseCommandPalette() end)
		p.Keys = I.Track(UserInputService.InputBegan:Connect(function(input)
			local k = input.KeyCode
			if k == Enum.KeyCode.Escape then Library:CloseCommandPalette()
			elseif k == Enum.KeyCode.Down then p.Selected = math.min(#p.Results, p.Selected + 1); paintSelection()
			elseif k == Enum.KeyCode.Up then p.Selected = math.max(1, p.Selected - 1); paintSelection() end
		end))

		refresh()
		task.delay(0.05, function() if box.Parent then box:CaptureFocus() end end)
		p.Box = box
		return p
	end

	function Library:ToggleCommandPalette()
		if palette and palette.Open then Library:CloseCommandPalette() else Library:OpenCommandPalette() end
	end

	-- Bind a hotkey (default Ctrl+P). Returns a handle with :Disable().
	function Library:EnableCommandPalette(opts)
		opts = Kit.Defaults({ Bind = Enum.KeyCode.P, Modifier = Enum.KeyCode.LeftControl }, opts)
		local conn = I.Track(UserInputService.InputBegan:Connect(function(input, processed)
			if processed or input.KeyCode ~= opts.Bind then return end
			local held = true
			if opts.Modifier then
				held = UserInputService:IsKeyDown(opts.Modifier) or (opts.Modifier == Enum.KeyCode.LeftControl and UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) or false
			end
			if held then Library:ToggleCommandPalette() end
		end))
		return { Disable = function() conn:Disconnect() end }
	end
end
