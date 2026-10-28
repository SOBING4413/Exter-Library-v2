--[[
	Exter Library | Layout elements
	Accordion · SubTabs

	Both return a *container*: they expose every Create* method, including the
	original core elements (CreateToggle, CreateSlider, ...) and all extension
	elements, so groups can be nested and mixed freely.
]]

return function(Library, Kit)
	local P = Kit.Palette
	local FULL = UDim.new(1, 0)
	local pack = table.pack or function(...) return { n = select("#", ...), ... } end
	local unpack = table.unpack or unpack

	-- Core element builders that must be proxied into a group.
	local CORE = { "Button", "Toggle", "Slider", "Dropdown", "Input", "ColorPicker", "Bind", "Keybind", "Label", "Paragraph", "Divider" }

	-- Builds a container object whose elements land inside `frame`.
	-- Extension elements parent to ctx.Frame directly. Core elements are built by
	-- the original library inside its own page, so we catch what it adds and
	-- re-parent it into the group.
	local function makeGroup(target, parentCtx, frame)
		local ctx = {
			Frame = frame, Tab = parentCtx.Tab, Section = parentCtx.Section, Window = parentCtx.Window,
			Kind = "Group", RootFrame = parentCtx.RootFrame, RootObject = parentCtx.RootObject, Parent = parentCtx,
		}
		for _, name in ipairs(CORE) do
			local key = "Create" .. name
			if rawget(target, key) == nil then
				target[key] = function(_, ...)
					local root, rootFrame = ctx.RootObject, ctx.RootFrame
					local fn = root and root[key]
					if not fn then error("Exter Library | " .. key .. " is not available in this container", 2) end
					local added = {}
					local conn = rootFrame.ChildAdded:Connect(function(child) added[#added + 1] = child end)
					local res = pack(pcall(fn, root, ...))
					conn:Disconnect()
					for _, child in ipairs(added) do
						if child:IsA("GuiObject") then child.Parent = frame end
					end
					if not res[1] then error(res[2], 0) end
					return unpack(res, 2, res.n)
				end
			end
		end
		Kit.Extend(target, ctx)
		return ctx
	end

	----------------------------------------------------------------------
	-- Accordion
	----------------------------------------------------------------------
	Kit.Register("Accordion", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Group", Description = nil, Icon = nil, ImageSource = "Material", Open = false }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - Accordion", Height = 0, Auto = true, Hover = false, Clip = true })
		Kit.List(card, 0)

		local hasDesc = s.Description and s.Description ~= ""
		local header = Kit.Button(card, { Name = "Header", Size = UDim2.new(1, 0, 0, hasDesc and 52 or Kit.Style.Height + 2), LayoutOrder = 1 })
		Kit.Pad(header, 12, 0, 12, 0)
		local left = 0
		if s.Icon then
			left = 28
			local icon = Kit.Icon(header, s.Icon, s.ImageSource, { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 0, 0.5, -9) })
			Kit.AccentColor(icon, "ImageColor3")
		end
		local _, title, descLabel = Kit.Header(header, s.Name, s.Description, { Size = UDim2.new(1, -left - 28, 0, hasDesc and 34 or 18), Position = UDim2.new(0, left, 0.5, hasDesc and -17 or -9) })
		local chevron = Kit.Icon(header, "chevron_right", "Material", { Name = "Chevron", Size = UDim2.fromOffset(18, 18), Position = UDim2.new(1, -18, 0.5, -9), ImageColor3 = P.TextDim, Rotation = 0 })

		local content = Kit.Frame(card, { Name = "Content", Size = UDim2.new(1, 0, 0, 0), ClipsDescendants = true, LayoutOrder = 2, Visible = false })
		local divider = Kit.Frame(content, { Name = "Divider", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Stroke, BackgroundTransparency = 0.6 })
		local inner = Kit.Frame(content, { Name = "Inner", Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.None })
		Kit.Pad(inner, 8, 8, 8, 10)
		local layout = Kit.List(inner, 6)

		local el = Kit.Element(ctx, "Accordion", card, s, flag)
		el.IgnoreConfig = true
		el.IsExpanded = false
		makeGroup(el, ctx, inner)

		local function contentHeight() return layout.AbsoluteContentSize.Y + 18 + 1 end

		local function apply(animate)
			if el.IsExpanded then
				content.Visible = true
				local h = contentHeight()
				inner.Size = UDim2.new(1, 0, 0, h - 1)
				if animate then Kit.Tween(content, { Size = UDim2.new(1, 0, 0, h) }, 0.32) else content.Size = UDim2.new(1, 0, 0, h) end
				Kit.Tween(chevron, { Rotation = 90, ImageColor3 = Kit.Accent() }, animate and 0.25 or 0)
			else
				if animate then
					Kit.Tween(content, { Size = UDim2.new(1, 0, 0, 0) }, 0.28)
					task.delay(0.3, function() if not el.IsExpanded then content.Visible = false end end)
				else
					content.Size = UDim2.new(1, 0, 0, 0); content.Visible = false
				end
				Kit.Tween(chevron, { Rotation = 0, ImageColor3 = P.TextDim }, animate and 0.25 or 0)
			end
		end

		-- keep the open height in sync when elements are added/removed/resized
		el:Connect(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			if el.IsExpanded then
				local h = contentHeight()
				inner.Size = UDim2.new(1, 0, 0, h - 1)
				content.Size = UDim2.new(1, 0, 0, h)
			end
		end)

		function el:Open() if not el.IsExpanded then el.IsExpanded = true; apply(true); el:_emit(true) end end
		function el:Close() if el.IsExpanded then el.IsExpanded = false; apply(true); el:_emit(false) end end
		function el:Toggle() if el.IsExpanded then el:Close() else el:Open() end end
		function el:IsOpen() return el.IsExpanded end
		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Description ~= nil then descLabel.Text = new.Description; descLabel.Visible = new.Description ~= "" end
			if new.Open ~= nil then if new.Open then el:Open() else el:Close() end end
		end

		header.MouseButton1Click:Connect(function() el:Toggle() end)
		header.MouseEnter:Connect(function() Kit.Tween(chevron, { ImageColor3 = el.IsExpanded and Kit.Accent() or P.Text }, 0.12) end)
		header.MouseLeave:Connect(function() Kit.Tween(chevron, { ImageColor3 = el.IsExpanded and Kit.Accent() or P.TextDim }, 0.18) end)

		el.IsExpanded = s.Open and true or false
		apply(false)
		return el
	end)

	----------------------------------------------------------------------
	-- SubTabs
	----------------------------------------------------------------------
	Kit.Register("SubTabs", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "SubTabs", Tabs = { "General", "Advanced" }, Default = nil }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - SubTabs", Height = 0, Auto = true, Plain = true })
		Kit.List(card, 8)

		local bar = Kit.Frame(card, { Name = "Bar", Size = UDim2.new(1, 0, 0, 34), LayoutOrder = 1, BackgroundColor3 = P.Surface, BackgroundTransparency = 0.5 })
		Kit.Corner(bar, Kit.Style.Corner)
		Kit.Stroke(bar, P.Stroke, 0.5)
		local indicator = Kit.Frame(bar, { Name = "Indicator", AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 3 })
		Kit.Corner(indicator, FULL)
		Kit.Gradient(indicator)

		local pages = Kit.Frame(card, { Name = "Pages", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2 })

		local el = Kit.Element(ctx, "SubTabs", card, s, flag)
		el.IgnoreConfig = true
		el.Pages, el.Buttons, el.Order = {}, {}, {}
		el.Current = nil

		local function paint(animate)
			local n = #el.Order
			for i, name in ipairs(el.Order) do
				local on = name == el.Current
				Kit.Tween(el.Buttons[name], { TextColor3 = on and P.Text or P.TextMute }, animate and 0.18 or 0)
				el.Pages[name].Frame.Visible = on
				if on and n > 0 then
					local goal = { Position = UDim2.new((i - 1) / n, 8, 1, -2), Size = UDim2.new(1 / n, -16, 0, 2) }
					if animate then Kit.Tween(indicator, goal, 0.3) else indicator.Position, indicator.Size = goal.Position, goal.Size end
				end
			end
		end

		function el:AddTab(name)
			if el.Pages[name] then return el.Pages[name].Group end
			el.Order[#el.Order + 1] = name
			local frame = Kit.Frame(pages, { Name = "Page_" .. name, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = false })
			Kit.List(frame, 6)
			local group = {}
			makeGroup(group, ctx, frame)
			el.Pages[name] = { Frame = frame, Group = group }
			-- rebuild equal-width buttons
			for _, b in pairs(el.Buttons) do b:Destroy() end
			el.Buttons = {}
			local n = #el.Order
			for i, tabName in ipairs(el.Order) do
				local b = Kit.Button(bar, { Name = "Tab_" .. tabName, Text = tabName, Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0), TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextMute, FontFace = Kit.Font(Enum.FontWeight.SemiBold), ZIndex = 2 })
				b.MouseButton1Click:Connect(function() el:Select(tabName) end)
				b.MouseEnter:Connect(function() if el.Current ~= tabName then Kit.Tween(b, { TextColor3 = P.TextDim }, 0.12) end end)
				b.MouseLeave:Connect(function() if el.Current ~= tabName then Kit.Tween(b, { TextColor3 = P.TextMute }, 0.15) end end)
				el.Buttons[tabName] = b
			end
			if not el.Current then el.Current = name end
			paint(false)
			return group
		end

		function el:Tab(name) return el.Pages[name] and el.Pages[name].Group or el:AddTab(name) end
		function el:Select(name)
			if not el.Pages[name] or el.Current == name then return end
			el.Current = name
			paint(true)
			el:_emit(name)
		end
		function el:GetSelected() return el.Current end

		for _, name in ipairs(s.Tabs) do el:AddTab(name) end
		if s.Default and el.Pages[s.Default] then el.Current = s.Default end
		paint(false)
		return el
	end)
end
