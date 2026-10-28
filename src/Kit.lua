--[[
	Exter Library | Kit
	-------------------------------------------------------------------
	Shared toolkit used by every extension module (elements & systems).

	It gives modules a tiny, consistent vocabulary:
	  * Kit.new / Corner / Stroke / Pad / List / Text   - instance builders
	  * Kit.Tween / Kit.Gradient / Kit.OnTheme          - motion + live theming
	  * Kit.Card / Kit.Element                          - element chrome + lifecycle
	  * Kit.Register / Kit.Persist                      - plug a new element into every Tab/Section
	  * Kit.Signal                                      - lightweight event objects

	Loaded automatically by ExterLibrary.lua. You normally never require it
	yourself, but it is public: Library.Kit.
]]

return function(Library)
	local I = assert(Library._Internal, "[ExterKit] ExterLibrary core is missing its _Internal bridge")

	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")
	local unpack = table.unpack or unpack

	local Kit = { Version = "1.0.0" }

	----------------------------------------------------------------------
	-- Palette & style
	----------------------------------------------------------------------
	local P = {
		Surface     = Color3.fromRGB(32, 30, 38),
		SurfaceAlt  = Color3.fromRGB(24, 23, 31),
		SurfaceHi   = Color3.fromRGB(44, 42, 54),
		Track       = Color3.fromRGB(20, 19, 26),
		Stroke      = Color3.fromRGB(64, 61, 76),
		StrokeHover = Color3.fromRGB(87, 84, 104),
		Text        = Color3.fromRGB(245, 245, 255),
		TextDim     = Color3.fromRGB(176, 174, 192),
		TextMute    = Color3.fromRGB(122, 120, 140),
		Success     = Color3.fromRGB(86, 214, 140),
		Warning     = Color3.fromRGB(250, 204, 82),
		Error       = Color3.fromRGB(240, 92, 92),
		Info        = Color3.fromRGB(104, 170, 255),
		ErrorFill   = Color3.fromRGB(85, 0, 0),
	}
	Kit.Palette = P

	-- Sampled from the real template at runtime so new elements match the
	-- window's typography/corners even if the template asset changes.
	Kit.Style = {
		Family   = "rbxasset://fonts/families/GothamSSm.json",
		Title    = 14,
		Desc     = 12,
		Corner   = UDim.new(0, 6),
		Height   = 38,
		Width    = UDim.new(1, 0),
		Pad      = 12,
	}

	local styleSampled = false

	-- The page template only exists after Library:CreateWindow(), so sampling is
	-- retried lazily (cheap no-op once it has succeeded).
	function Kit.RefreshStyle()
		local ok = pcall(function()
			local tpl = I.GetElements().Template
			local sample = tpl:FindFirstChild("Button") or tpl:FindFirstChild("Toggle")
			if not sample then error("template not ready") end
			local title = sample:FindFirstChild("Title")
			if title then
				local gotFace, face = pcall(function() return title.FontFace end)
				if gotFace and face and face.Family and face.Family ~= "" then Kit.Style.Family = face.Family end
				if type(title.TextSize) == "number" and title.TextSize > 0 then Kit.Style.Title = title.TextSize end
			end
			local descTpl = tpl:FindFirstChild("ButtonDesc")
			local desc = descTpl and descTpl:FindFirstChild("Desc")
			if desc and type(desc.TextSize) == "number" and desc.TextSize > 0 then Kit.Style.Desc = desc.TextSize end
			local corner = sample:FindFirstChildOfClass("UICorner")
			if corner then Kit.Style.Corner = corner.CornerRadius end
			if sample.Size.Y.Offset >= 28 then Kit.Style.Height = sample.Size.Y.Offset end
			Kit.Style.Width = UDim.new(sample.Size.X.Scale, sample.Size.X.Offset)
		end)
		if ok then styleSampled = true end
		return ok
	end

	function Kit.EnsureStyle()
		if not styleSampled then Kit.RefreshStyle() end
	end

	function Kit.Font(weight)
		Kit.EnsureStyle()
		return Font.new(Kit.Style.Family, weight or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	end

	----------------------------------------------------------------------
	-- Small utilities
	----------------------------------------------------------------------
	function Kit.Defaults(defaults, passed)
		local out = {}
		for k, v in pairs(passed or {}) do out[k] = v end
		for k, v in pairs(defaults) do
			if out[k] == nil then out[k] = v end
		end
		return out
	end

	function Kit.Clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end

	function Kit.Snap(value, increment, min)
		increment = (increment and increment > 0) and increment or 1
		min = min or 0
		local snapped = min + math.floor((value - min) / increment + 0.5) * increment
		-- tame floating point noise (0.30000000000000004 -> 0.3)
		return tonumber(string.format("%.10g", snapped))
	end

	function Kit.Decimals(increment)
		local s = string.format("%.10g", increment or 1)
		local frac = s:match("%.(%d+)")
		return frac and #frac or 0
	end

	function Kit.FormatNumber(n, decimals)
		n = tonumber(n) or 0
		local s = string.format("%." .. (decimals or 0) .. "f", n)
		local int, frac = s:match("^(-?%d+)%.?(%d*)$")
		if not int then return s end
		int = int:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""):gsub("^%-,", "-")
		return (frac ~= "" and (int .. "." .. frac)) or int
	end

	function Kit.Hex(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end

	function Kit.FromHex(hex)
		hex = tostring(hex or ""):gsub("#", "")
		if #hex ~= 6 then return nil end
		local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
		if not (r and g and b) then return nil end
		return Color3.fromRGB(r, g, b)
	end

	function Kit.Accent()
		return Library.ThemeGradient.Keypoints[1].Value
	end

	----------------------------------------------------------------------
	-- Signal
	----------------------------------------------------------------------
	local Signal = {}
	Signal.__index = Signal

	function Signal.new()
		return setmetatable({ _list = {} }, Signal)
	end

	function Signal:Connect(fn)
		local conn = { Connected = true, _fn = fn }
		function conn:Disconnect()
			self.Connected = false
			self._fn = nil
		end
		conn.disconnect = conn.Disconnect
		self._list[#self._list + 1] = conn
		return conn
	end
	Signal.connect = Signal.Connect

	function Signal:Once(fn)
		local conn
		conn = self:Connect(function(...)
			conn:Disconnect()
			fn(...)
		end)
		return conn
	end

	function Signal:Fire(...)
		local live = {}
		for _, c in ipairs(self._list) do
			if c.Connected then live[#live + 1] = c end
		end
		self._list = live
		for _, c in ipairs({ unpack(live) }) do
			if c.Connected then
				local ok, err = pcall(c._fn, ...)
				if not ok then warn("[ExterKit] signal handler error: " .. tostring(err)) end
			end
		end
	end

	function Signal:Wait()
		local co = coroutine.running()
		self:Once(function(...) task.spawn(co, ...) end)
		return coroutine.yield()
	end

	function Signal:DisconnectAll()
		for _, c in ipairs(self._list) do c.Connected = false; c._fn = nil end
		self._list = {}
	end

	Kit.Signal = Signal

	----------------------------------------------------------------------
	-- Instance builders
	----------------------------------------------------------------------
	function Kit.new(class, props, children)
		local obj = Instance.new(class)
		local parent
		if props then
			for k, v in pairs(props) do
				if k == "Parent" then parent = v else obj[k] = v end
			end
		end
		if children then
			for _, child in ipairs(children) do child.Parent = obj end
		end
		if parent then obj.Parent = parent end
		return obj
	end

	function Kit.Corner(parent, radius)
		local r = radius
		if typeof(r) ~= "UDim" then r = UDim.new(0, r or 6) end
		return Kit.new("UICorner", { CornerRadius = r, Parent = parent })
	end

	function Kit.Stroke(parent, color, transparency, thickness)
		return Kit.new("UIStroke", {
			Color = color or P.Stroke,
			Transparency = transparency == nil and 0.5 or transparency,
			Thickness = thickness or 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Parent = parent,
		})
	end

	function Kit.Pad(parent, l, t, r, b)
		if t == nil then t, r, b = l, l, l end
		return Kit.new("UIPadding", {
			PaddingLeft = UDim.new(0, l or 0), PaddingTop = UDim.new(0, t or 0),
			PaddingRight = UDim.new(0, r or 0), PaddingBottom = UDim.new(0, b or 0),
			Parent = parent,
		})
	end

	function Kit.List(parent, padding, direction, hAlign, vAlign)
		return Kit.new("UIListLayout", {
			Padding = UDim.new(0, padding or 0),
			FillDirection = direction or Enum.FillDirection.Vertical,
			HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
			VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = parent,
		})
	end

	function Kit.Frame(parent, props)
		local base = { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Parent = parent }
		for k, v in pairs(props or {}) do base[k] = v end
		return Kit.new("Frame", base)
	end

	function Kit.Text(parent, props)
		props = props or {}
		local weight = props.Weight
		local base = {
			BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
			FontFace = Kit.Font(weight or Enum.FontWeight.Medium),
			TextSize = Kit.Style.Title, TextColor3 = P.Text,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			Size = UDim2.new(1, 0, 0, 18), Parent = parent,
		}
		for k, v in pairs(props) do
			if k ~= "Weight" then base[k] = v end
		end
		return Kit.new("TextLabel", base)
	end

	function Kit.Button(parent, props)
		local base = { BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Size = UDim2.new(1, 0, 1, 0), Parent = parent }
		for k, v in pairs(props or {}) do base[k] = v end
		return Kit.new("TextButton", base)
	end

	function Kit.Icon(parent, icon, source, props)
		local img = Kit.new("ImageLabel", {
			BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(16, 16),
			ImageColor3 = P.TextDim, Parent = parent,
		})
		for k, v in pairs(props or {}) do img[k] = v end
		I.ApplyIcon(img, icon, source or "Material")
		return img
	end

	----------------------------------------------------------------------
	-- Motion
	----------------------------------------------------------------------
	function Kit.Tween(obj, goal, time, style, direction)
		local speed = Library._animSpeed or 1
		local tween = TweenService:Create(obj, TweenInfo.new((time or 0.25) / speed, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out), goal)
		tween:Play()
		return tween
	end

	----------------------------------------------------------------------
	-- Live theming (one shared listener, per-element callbacks)
	----------------------------------------------------------------------
	local themeCallbacks, themeHooked = {}, false
	function Kit.OnTheme(fn)
		if not themeHooked then
			themeHooked = true
			I.BindTheme(function()
				for cb in pairs(themeCallbacks) do pcall(cb) end
			end)
		end
		themeCallbacks[fn] = true
		pcall(fn)
		return { Disconnect = function() themeCallbacks[fn] = nil end }
	end

	function Kit.Gradient(inst, rotation)
		local g = Kit.new("UIGradient", { Rotation = rotation or 0, Color = Library.ThemeGradient, Parent = inst })
		local handle
		handle = Kit.OnTheme(function()
			if not g.Parent then handle.Disconnect() return end
			g.Color = Library.ThemeGradient
		end)
		return g, handle
	end

	-- Makes `inst` follow the accent colour (first gradient stop).
	function Kit.AccentColor(inst, prop)
		prop = prop or "BackgroundColor3"
		local handle
		handle = Kit.OnTheme(function()
			if not inst.Parent then handle.Disconnect() return end
			inst[prop] = Kit.Accent()
		end)
		return handle
	end

	----------------------------------------------------------------------
	-- Input helpers
	----------------------------------------------------------------------
	local function isPointer(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end
	Kit.IsPointer = isPointer

	-- Pointer drag on a handle. onUpdate(x, y) fires on press and every move.
	function Kit.Drag(handle, onUpdate, onEnd)
		local dragging = false
		local conns = {}
		conns[#conns + 1] = I.Track(handle.InputBegan:Connect(function(input)
			if isPointer(input) then
				dragging = true
				onUpdate(input.Position.X, input.Position.Y)
			end
		end))
		conns[#conns + 1] = I.Track(UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				onUpdate(input.Position.X, input.Position.Y)
			end
		end))
		conns[#conns + 1] = I.Track(UserInputService.InputEnded:Connect(function(input)
			if dragging and isPointer(input) then
				dragging = false
				if onEnd then onEnd() end
			end
		end))
		return {
			IsDragging = function() return dragging end,
			Disconnect = function() for _, c in ipairs(conns) do c:Disconnect() end end,
		}
	end

	-- Fires fn once on press, then repeatedly (accelerating) while held.
	function Kit.HoldRepeat(button, fn)
		local token = 0
		local function stop() token = token + 1 end
		button.InputBegan:Connect(function(input)
			if not isPointer(input) then return end
			token = token + 1
			local mine = token
			fn()
			task.spawn(function()
				local delay = 0.4
				task.wait(delay)
				while mine == token and button.Parent do
					fn()
					delay = math.max(0.04, delay * 0.82)
					task.wait(delay)
				end
			end)
		end)
		button.InputEnded:Connect(function(input) if isPointer(input) then stop() end end)
		button.MouseLeave:Connect(stop)
		return stop
	end

	----------------------------------------------------------------------
	-- Element chrome
	----------------------------------------------------------------------
	function Kit.Card(ctx, o)
		o = o or {}
		Kit.EnsureStyle()
		local card = Kit.new("Frame", {
			Name = o.Name or "Card",
			BackgroundColor3 = P.Surface,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(Kit.Style.Width.Scale, Kit.Style.Width.Offset, 0, o.Height or Kit.Style.Height),
			AutomaticSize = o.Auto and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
			ClipsDescendants = o.Clip == true,
			Parent = ctx.Frame,
		})
		card:SetAttribute("ExterExtension", true)
		if o.Plain then return card, nil end -- layout-only wrapper: no chrome

		Kit.Corner(card, Kit.Style.Corner)
		local stroke = Kit.Stroke(card, P.Stroke, 1)

		-- fade in like core elements
		Kit.Tween(card, { BackgroundTransparency = o.Transparency or 0.5 }, 0.7, Enum.EasingStyle.Exponential)
		Kit.Tween(stroke, { Transparency = 0.5 }, 0.7, Enum.EasingStyle.Exponential)

		if o.Hover ~= false then
			card.MouseEnter:Connect(function() Kit.Tween(stroke, { Color = P.StrokeHover }, 0.2) end)
			card.MouseLeave:Connect(function() Kit.Tween(stroke, { Color = P.Stroke }, 0.25) end)
		end
		return card, stroke
	end

	-- Title (+ optional description) stacked on the left of a card.
	function Kit.Header(card, title, desc, o)
		o = o or {}
		local holder = Kit.Frame(card, {
			Name = "Header", Size = o.Size or UDim2.new(1, 0, 0, desc and desc ~= "" and 34 or 18),
			Position = o.Position or UDim2.new(0, 0, 0, 0), AutomaticSize = o.Auto and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		})
		Kit.List(holder, 2)
		local t = Kit.Text(holder, { Name = "Title", Text = tostring(title or ""), Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1 })
		local d = Kit.Text(holder, {
			Name = "Desc", Text = tostring(desc or ""), TextSize = Kit.Style.Desc, TextColor3 = P.TextMute,
			Size = UDim2.new(1, 0, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, LayoutOrder = 2,
			Visible = desc ~= nil and desc ~= "",
		})
		return holder, t, d
	end

	local function flashError(el)
		local card = el.Frame
		if not card or not card.Parent then return end
		local stroke = card:FindFirstChildOfClass("UIStroke")
		local original = card.BackgroundColor3
		Kit.Tween(card, { BackgroundColor3 = P.ErrorFill, BackgroundTransparency = 0.2 }, 0.2)
		task.delay(0.6, function()
			if card.Parent then Kit.Tween(card, { BackgroundColor3 = original, BackgroundTransparency = 0.5 }, 0.5) end
		end)
		if stroke then stroke.Color = P.Error; task.delay(0.6, function() if stroke.Parent then stroke.Color = P.Stroke end end) end
	end

	----------------------------------------------------------------------
	-- Element base class
	----------------------------------------------------------------------
	local Element = {}
	Element.__index = Element
	Kit.ElementClass = Element

	Kit.Registry = {} -- every extension element, used by the command palette

	function Kit.Element(ctx, class, card, settings, flag)
		local self = setmetatable({
			Class = class, Settings = settings, Frame = card, Flag = flag,
			Changed = Signal.new(), IgnoreConfig = false,
			Tab = ctx.Tab, Section = ctx.Section, Window = ctx.Window, Container = ctx,
			_conns = {}, _destroyed = false,
		}, Element)

		if flag then Library.Options[flag] = self end
		Kit.Registry[#Kit.Registry + 1] = self

		if settings.Visible == false then card.Visible = false end
		if settings.Disabled == true then self:SetDisabled(true) end
		if settings.Tooltip and Kit.AttachTooltip then Kit.AttachTooltip(card, settings.Tooltip) end
		return self
	end

	function Element:Connect(signal, fn)
		local c = I.Track(signal:Connect(fn))
		self._conns[#self._conns + 1] = c
		return c
	end

	function Element:GetFrame() return self.Frame end
	function Element:IsDestroyed() return self._destroyed end

	function Element:SetVisible(state)
		if self.Frame then self.Frame.Visible = state and true or false end
	end

	function Element:IsVisible()
		return self.Frame ~= nil and self.Frame.Visible
	end

	function Element:SetDisabled(state)
		state = state and true or false
		self.Disabled = state
		local mask = self.Frame:FindFirstChild("ExterDisabledMask")
		if state and not mask then
			mask = Kit.new("TextButton", {
				Name = "ExterDisabledMask", Text = "", AutoButtonColor = false, Active = true,
				BackgroundColor3 = P.Track, BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0), ZIndex = 50, Parent = self.Frame,
			})
			Kit.Corner(mask, Kit.Style.Corner)
			Kit.Tween(mask, { BackgroundTransparency = 0.45 }, 0.2)
		elseif not state and mask then
			Kit.Tween(mask, { BackgroundTransparency = 1 }, 0.15)
			task.delay(0.16, function() if mask.Parent then mask:Destroy() end end)
		end
	end

	function Element:Flash(color)
		local stroke = self.Frame:FindFirstChildOfClass("UIStroke")
		if not stroke then return end
		stroke.Color = color or Kit.Accent()
		stroke.Transparency = 0
		Kit.Tween(stroke, { Color = P.Stroke, Transparency = 0.5 }, 0.8)
	end

	-- Fire Changed + user Callback (errors never escape).
	function Element:_emit(...)
		self.Changed:Fire(...)
		local cb = self.Settings.Callback
		if cb then
			local ok, err = pcall(cb, ...)
			if not ok then
				print("Exter Library | " .. tostring(self.Settings.Name or self.Class) .. " Callback Error " .. tostring(err))
				flashError(self)
			end
		end
	end

	function Element:OnChanged(fn) return self.Changed:Connect(fn) end

	function Element:Destroy()
		if self._destroyed then return end
		self._destroyed = true
		for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
		self._conns = {}
		self.Changed:DisconnectAll()
		if self.Flag and Library.Options[self.Flag] == self then Library.Options[self.Flag] = nil end
		for i, e in ipairs(Kit.Registry) do
			if e == self then table.remove(Kit.Registry, i) break end
		end
		if self.Frame then
			self.Frame.Visible = false
			self.Frame:Destroy()
		end
	end

	----------------------------------------------------------------------
	-- Registration: make `Tab:CreateX` / `Section:CreateX` / group:CreateX exist
	----------------------------------------------------------------------
	local builders = {}
	local containers = setmetatable({}, { __mode = "k" })

	local function attach(obj, ctx, name)
		local key = "Create" .. name
		if rawget(obj, key) ~= nil then return end
		obj[key] = function(_, settings, flag)
			if type(settings) ~= "table" then settings = { Name = settings } end
			return builders[name](ctx, settings, flag)
		end
	end

	function Kit.Register(name, builder)
		builders[name] = builder
		for obj, ctx in pairs(containers) do attach(obj, ctx, name) end
	end

	function Kit.Extend(obj, ctx)
		containers[obj] = ctx
		for name in pairs(builders) do attach(obj, ctx, name) end
		return obj
	end

	function Kit.Builders() return builders end

	-- Core hook: called by ExterLibrary for every Tab and Section.
	Library._Extend = function(obj, ctx) return Kit.Extend(obj, ctx) end

	----------------------------------------------------------------------
	-- Config persistence for flagged elements
	----------------------------------------------------------------------
	function Kit.Persist(class, save, load)
		Library._Parsers[class] = {
			Save = function(flag, option)
				return { type = class, flag = flag, value = save(option) }
			end,
			Load = function(flag, data)
				local option = Library.Options[flag]
				if option and data.value ~= nil then load(option, data.value) end
			end,
		}
	end

	----------------------------------------------------------------------
	-- Hooks that systems fill in later
	----------------------------------------------------------------------
	Kit.AttachTooltip = nil

	Kit.RefreshStyle()
	return Kit
end
