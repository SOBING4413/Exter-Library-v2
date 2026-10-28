--[[
	Exter Library | Input elements
	Stepper · RangeSlider · Segmented · CheckboxGroup · RadioGroup · TextArea ·
	SecretInput · Rating · TagInput · ColorPalette · ListPicker
]]

return function(Library, Kit)
	local P = Kit.Palette
	local FULL = UDim.new(1, 0)
	local GOLD = Color3.fromRGB(250, 204, 82)

	local function copyList(list)
		local out = {}
		for i, v in ipairs(list or {}) do out[i] = v end
		return out
	end

	local function contains(list, value)
		for i, v in ipairs(list) do if v == value then return i end end
		return nil
	end

	-- A styled TextBox that glows with the accent colour while focused.
	local function makeBox(parent, props)
		local base = {
			Name = "Box", BackgroundColor3 = P.Track, BackgroundTransparency = 0.15, BorderSizePixel = 0,
			ClearTextOnFocus = false, Text = "", PlaceholderText = "", PlaceholderColor3 = P.TextMute,
			TextColor3 = P.Text, FontFace = Kit.Font(Enum.FontWeight.Medium), TextSize = Kit.Style.Title - 1,
			TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
		}
		for k, v in pairs(props or {}) do base[k] = v end
		local box = Kit.new("TextBox", base)
		Kit.Corner(box, 6)
		local stroke = Kit.Stroke(box, P.Stroke, 0.3)
		Kit.Pad(box, 8, 0, 8, 0)
		box.Focused:Connect(function() Kit.Tween(stroke, { Color = Kit.Accent(), Transparency = 0 }, 0.15) end)
		box.FocusLost:Connect(function() Kit.Tween(stroke, { Color = P.Stroke, Transparency = 0.3 }, 0.2) end)
		return box, stroke
	end

	local function smallButton(parent, iconName, props)
		local b = Kit.Button(parent, props)
		b.BackgroundTransparency = 0.25
		b.BackgroundColor3 = P.Track
		Kit.Corner(b, 6)
		local icon = Kit.Icon(b, iconName, "Material", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0.5, -7, 0.5, -7), ImageColor3 = P.TextDim })
		b.MouseEnter:Connect(function() Kit.Tween(b, { BackgroundTransparency = 0 }, 0.12); Kit.Tween(icon, { ImageColor3 = P.Text }, 0.12) end)
		b.MouseLeave:Connect(function() Kit.Tween(b, { BackgroundTransparency = 0.25 }, 0.18); Kit.Tween(icon, { ImageColor3 = P.TextDim }, 0.18) end)
		return b, icon
	end

	----------------------------------------------------------------------
	-- Stepper
	----------------------------------------------------------------------
	Kit.Register("Stepper", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Stepper", Description = nil, Range = { 0, 100 }, Increment = 1, CurrentValue = 0, Suffix = "" }, s)
		local desc = s.Description and s.Description ~= ""
		local card = Kit.Card(ctx, { Name = s.Name .. " - Stepper", Height = desc and 52 or Kit.Style.Height + 4 })
		Kit.Pad(card, 12, 0, 8, 0)
		local _, title, descLabel = Kit.Header(card, s.Name, s.Description, { Size = UDim2.new(1, -130, 0, desc and 34 or 18), Position = UDim2.new(0, 0, 0.5, desc and -17 or -9) })

		local ctl = Kit.Frame(card, { Name = "Controls", Size = UDim2.fromOffset(120, 28), Position = UDim2.new(1, -120, 0.5, -14) })
		local minus, minusIcon = smallButton(ctl, "remove", { Name = "Minus", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(0, 0, 0, 0) })
		local plus, plusIcon = smallButton(ctl, "add", { Name = "Plus", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 0, 0) })
		local box = makeBox(ctl, { Name = "Value", Size = UDim2.new(1, -64, 1, 0), Position = UDim2.new(0, 32, 0, 0), TextXAlignment = Enum.TextXAlignment.Center })

		local el = Kit.Element(ctx, "Stepper", card, s, flag)
		el.CurrentValue = s.CurrentValue

		local function bounds() return math.min(s.Range[1], s.Range[2]), math.max(s.Range[1], s.Range[2]) end
		local function plain(n)
			local str = string.format("%." .. Kit.Decimals(s.Increment) .. "f", n)
			if str:find(".", 1, true) then str = str:gsub("0+$", ""):gsub("%.$", "") end
			return str
		end
		local function show(focused)
			if focused then box.Text = plain(el.CurrentValue)
			else box.Text = Kit.FormatNumber(el.CurrentValue, Kit.Decimals(s.Increment)) .. s.Suffix end
			local lo, hi = bounds()
			minusIcon.ImageTransparency = el.CurrentValue <= lo and 0.6 or 0
			plusIcon.ImageTransparency = el.CurrentValue >= hi and 0.6 or 0
		end

		local function commit(v, silent)
			local lo, hi = bounds()
			v = Kit.Clamp(Kit.Snap(tonumber(v) or el.CurrentValue, s.Increment, lo), lo, hi)
			local changed = v ~= el.CurrentValue
			el.CurrentValue = v
			s.CurrentValue = v
			show(box:IsFocused())
			if changed and not silent then el:_emit(v) end
		end

		Kit.HoldRepeat(minus, function() commit(el.CurrentValue - s.Increment) end)
		Kit.HoldRepeat(plus, function() commit(el.CurrentValue + s.Increment) end)
		box.Focused:Connect(function() show(true) end)
		box.FocusLost:Connect(function()
			local typed = tonumber((box.Text:gsub("[^%d%.%-]", "")))
			commit(typed or el.CurrentValue)
			show(false)
		end)

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Description ~= nil then s.Description = new.Description; descLabel.Text = new.Description; descLabel.Visible = new.Description ~= "" end
			if new.Range then s.Range = new.Range end
			if new.Increment then s.Increment = new.Increment end
			if new.Suffix ~= nil then s.Suffix = new.Suffix end
			commit(new.CurrentValue ~= nil and new.CurrentValue or el.CurrentValue)
		end
		function el:GetValue() return el.CurrentValue end

		commit(s.CurrentValue, true)
		show(false)
		return el
	end)
	Kit.Persist("Stepper", function(o) return o.CurrentValue end, function(o, v) o:Set({ CurrentValue = tonumber(v) }) end)

	----------------------------------------------------------------------
	-- RangeSlider (two handles)
	----------------------------------------------------------------------
	Kit.Register("RangeSlider", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Range", Range = { 0, 100 }, Increment = 1, CurrentValue = { 25, 75 }, Suffix = "" }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - RangeSlider", Height = 62 })
		Kit.Pad(card, 14, 9, 14, 9)
		local title = Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(0.6, 0, 0, 16) })
		local readout = Kit.Text(card, { Name = "Value", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.4, 0, 0, 16), TextColor3 = P.TextDim, Weight = Enum.FontWeight.SemiBold })
		local track = Kit.Frame(card, { Name = "Track", Position = UDim2.new(0, 0, 1, -16), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = P.Track, BackgroundTransparency = 0 })
		Kit.Corner(track, FULL)
		local fill = Kit.Frame(track, { Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
		Kit.Corner(fill, FULL)
		Kit.Gradient(fill)
		local function handle(name)
			local h = Kit.Frame(track, { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 3 })
			Kit.Corner(h, FULL)
			local st = Kit.Stroke(h, Kit.Accent(), 0, 2)
			Kit.AccentColor(st, "Color")
			return h
		end
		local h1, h2 = handle("HandleMin"), handle("HandleMax")
		local hit = Kit.Button(card, { Name = "Hit", Position = UDim2.new(0, -6, 1, -28), Size = UDim2.new(1, 12, 0, 28), ZIndex = 5 })

		local el = Kit.Element(ctx, "RangeSlider", card, s, flag)
		el.CurrentValue = { s.CurrentValue[1], s.CurrentValue[2] }

		local function lo() return math.min(s.Range[1], s.Range[2]) end
		local function hi() return math.max(s.Range[1], s.Range[2]) end
		local function alpha(v) local span = hi() - lo() return span == 0 and 0 or (v - lo()) / span end

		local function render(animate)
			local a, b = alpha(el.CurrentValue[1]), alpha(el.CurrentValue[2])
			local d = Kit.Decimals(s.Increment)
			readout.Text = Kit.FormatNumber(el.CurrentValue[1], d) .. " - " .. Kit.FormatNumber(el.CurrentValue[2], d) .. s.Suffix
			local fp, fs = UDim2.new(a, 0, 0, 0), UDim2.new(b - a, 0, 1, 0)
			if animate then
				Kit.Tween(fill, { Position = fp, Size = fs }, 0.2); Kit.Tween(h1, { Position = UDim2.new(a, 0, 0.5, 0) }, 0.2); Kit.Tween(h2, { Position = UDim2.new(b, 0, 0.5, 0) }, 0.2)
			else
				fill.Position, fill.Size = fp, fs
				h1.Position, h2.Position = UDim2.new(a, 0, 0.5, 0), UDim2.new(b, 0, 0.5, 0)
			end
		end

		local function setValues(a, b, animate, silent)
			a = Kit.Clamp(Kit.Snap(a, s.Increment, lo()), lo(), hi())
			b = Kit.Clamp(Kit.Snap(b, s.Increment, lo()), lo(), hi())
			if a > b then a, b = b, a end
			local changed = a ~= el.CurrentValue[1] or b ~= el.CurrentValue[2]
			el.CurrentValue = { a, b }
			s.CurrentValue = { a, b }
			render(animate)
			if changed and not silent then el:_emit(a, b) end
		end

		local active
		Kit.Drag(hit, function(x)
			local w = track.AbsoluteSize.X
			if w <= 0 then return end
			local v = lo() + Kit.Clamp((x - track.AbsolutePosition.X) / w, 0, 1) * (hi() - lo())
			if not active then
				local a, b = el.CurrentValue[1], el.CurrentValue[2]
				if a == b then active = v < a and 1 or 2 else active = math.abs(v - a) <= math.abs(v - b) and 1 or 2 end
			end
			if active == 1 then setValues(math.min(v, el.CurrentValue[2]), el.CurrentValue[2], false)
			else setValues(el.CurrentValue[1], math.max(v, el.CurrentValue[1]), false) end
		end, function() active = nil end)

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Range then s.Range = new.Range end
			if new.Increment then s.Increment = new.Increment end
			if new.Suffix ~= nil then s.Suffix = new.Suffix end
			local v = new.CurrentValue or el.CurrentValue
			setValues(v[1], v[2], true)
		end
		function el:GetValue() return el.CurrentValue[1], el.CurrentValue[2] end

		setValues(el.CurrentValue[1], el.CurrentValue[2], false, true)
		return el
	end)
	Kit.Persist("RangeSlider", function(o) return { o.CurrentValue[1], o.CurrentValue[2] } end, function(o, v) if type(v) == "table" then o:Set({ CurrentValue = { tonumber(v[1]) or 0, tonumber(v[2]) or 0 } }) end end)

	----------------------------------------------------------------------
	-- Segmented control
	----------------------------------------------------------------------
	Kit.Register("Segmented", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Segmented", Options = { "One", "Two" }, CurrentOption = nil }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - Segmented", Height = Kit.Style.Height + 6 })
		Kit.Pad(card, 12, 0, 8, 0)
		local title = Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(0.35, 0, 0, 18), Position = UDim2.new(0, 0, 0.5, -9) })
		local bar = Kit.Frame(card, { Name = "Bar", Size = UDim2.new(0.62, 0, 0, 30), Position = UDim2.new(0.38, 0, 0.5, -15), BackgroundColor3 = P.Track, BackgroundTransparency = 0.15 })
		Kit.Corner(bar, 8)
		Kit.Pad(bar, 3)
		local thumb = Kit.Frame(bar, { Name = "Thumb", BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0, ZIndex = 1 })
		Kit.Corner(thumb, 6)
		Kit.Gradient(thumb)
		local buttons = {}

		local el = Kit.Element(ctx, "Segmented", card, s, flag)
		el.CurrentOption = s.CurrentOption or s.Options[1]

		local function render(animate)
			local n = #s.Options
			if n == 0 then thumb.Visible = false return end
			thumb.Visible = true
			local idx = contains(s.Options, el.CurrentOption) or 1
			local goalPos, goalSize = UDim2.new((idx - 1) / n, 0, 0, 0), UDim2.new(1 / n, 0, 1, 0)
			if animate then Kit.Tween(thumb, { Position = goalPos, Size = goalSize }, 0.28, Enum.EasingStyle.Quint) else thumb.Position, thumb.Size = goalPos, goalSize end
			for i, b in ipairs(buttons) do
				Kit.Tween(b, { TextColor3 = i == idx and Color3.new(1, 1, 1) or P.TextMute }, 0.2)
			end
		end

		local function build()
			for _, b in ipairs(buttons) do b:Destroy() end
			buttons = {}
			local n = #s.Options
			for i, opt in ipairs(s.Options) do
				local b = Kit.Button(bar, { Name = "Opt" .. i, Text = tostring(opt), Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0), TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextMute, FontFace = Kit.Font(Enum.FontWeight.SemiBold), ZIndex = 2 })
				b.MouseButton1Click:Connect(function() el:Set({ CurrentOption = opt }) end)
				buttons[i] = b
			end
		end

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Options then s.Options = copyList(new.Options); build() end
			if new.CurrentOption ~= nil and not contains(s.Options, new.CurrentOption) then return end
			local target = new.CurrentOption
			if target == nil then target = contains(s.Options, el.CurrentOption) and el.CurrentOption or s.Options[1] end
			local changed = target ~= el.CurrentOption
			el.CurrentOption = target
			s.CurrentOption = target
			render(true)
			if changed then el:_emit(target) end
		end
		function el:SetOptions(list) el:Set({ Options = list }) end
		function el:GetOption() return el.CurrentOption end

		build()
		render(false)
		return el
	end)
	Kit.Persist("Segmented", function(o) return o.CurrentOption end, function(o, v) o:Set({ CurrentOption = v }) end)

	----------------------------------------------------------------------
	-- CheckboxGroup & RadioGroup
	----------------------------------------------------------------------
	local function choiceGroup(multi)
		local className = multi and "CheckboxGroup" or "RadioGroup"
		return function(ctx, s, flag)
			s = Kit.Defaults({ Name = multi and "Checkboxes" or "Radio", Description = nil, Options = { "A", "B", "C" }, CurrentOptions = {}, CurrentOption = nil, Min = 0, Max = nil }, s)
			local card = Kit.Card(ctx, { Name = s.Name .. " - " .. className, Height = 0, Auto = true, Hover = false })
			Kit.Pad(card, 12, 8, 12, 8)
			local body = Kit.Frame(card, { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
			Kit.List(body, 2)
			local head, title, descLabel = Kit.Header(body, s.Name, s.Description, { Size = UDim2.new(1, 0, 0, (s.Description and s.Description ~= "") and 34 or 20) })
			head.LayoutOrder = 0
			Kit.Frame(body, { Name = "Spacer", Size = UDim2.new(1, 0, 0, 2), LayoutOrder = 1 })

			local el = Kit.Element(ctx, className, card, s, flag)
			el.Selected = multi and copyList(s.CurrentOptions) or {}
			if not multi and s.CurrentOption ~= nil then el.Selected = { s.CurrentOption } end
			local rows = {}

			local function paint(row, on, animate)
				local t = animate and 0.18 or 0
				local goalBox = on and { BackgroundTransparency = 0 } or { BackgroundTransparency = 0.2 }
				if animate then Kit.Tween(row.Box, goalBox, t) else for k, v in pairs(goalBox) do row.Box[k] = v end end
				if animate then Kit.Tween(row.Mark, { ImageTransparency = on and 0 or 1 }, t) else row.Mark.ImageTransparency = on and 0 or 1 end
				if animate then Kit.Tween(row.Label, { TextColor3 = on and P.Text or P.TextDim }, t) else row.Label.TextColor3 = on and P.Text or P.TextDim end
				row.Gradient.Enabled = on
			end

			local function refresh(animate)
				for opt, row in pairs(rows) do paint(row, contains(el.Selected, opt) ~= nil, animate) end
			end

			local function ordered()
				local out = {}
				for _, opt in ipairs(s.Options) do if contains(el.Selected, opt) then out[#out + 1] = opt end end
				return out
			end

			local function emit()
				if multi then el:_emit(ordered()) else el:_emit(el.Selected[1]) end
			end

			local function toggle(opt)
				if multi then
					local at = contains(el.Selected, opt)
					if at then
						if #el.Selected <= (s.Min or 0) then return end
						table.remove(el.Selected, at)
					else
						if s.Max and #el.Selected >= s.Max then return end
						el.Selected[#el.Selected + 1] = opt
					end
				else
					if el.Selected[1] == opt then return end
					el.Selected = { opt }
				end
				refresh(true)
				emit()
			end

			local function build()
				for _, r in pairs(rows) do r.Frame:Destroy() end
				rows = {}
				for i, opt in ipairs(s.Options) do
					local f = Kit.Button(body, { Name = "Option_" .. tostring(opt), Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i + 1 })
					local box = Kit.Frame(f, { Name = "Box", Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 0, 0.5, -9), BackgroundColor3 = multi and Color3.new(1, 1, 1) or Color3.new(1, 1, 1), BackgroundTransparency = 0.2 })
					box.BackgroundColor3 = P.Track
					Kit.Corner(box, multi and 5 or FULL)
					Kit.Stroke(box, P.StrokeHover, 0.2)
					local grad = Kit.Gradient(box)
					grad.Enabled = false
					box.BackgroundColor3 = Color3.new(1, 1, 1)
					local mark
					if multi then mark = Kit.Icon(box, "check", "Material", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0.5, -6, 0.5, -6), ImageColor3 = Color3.new(1, 1, 1), ImageTransparency = 1 })
					else
						mark = Kit.new("ImageLabel", { Name = "Dot", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = box })
						-- radio uses a real dot frame instead of an icon
						local dot = Kit.Frame(box, { Name = "DotFrame", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0 })
						Kit.Corner(dot, FULL)
						mark.Changed:Connect(function() dot.BackgroundTransparency = mark.ImageTransparency end)
						dot.BackgroundTransparency = 1
					end
					local label = Kit.Text(f, { Name = "Label", Text = tostring(opt), Position = UDim2.new(0, 28, 0, 0), Size = UDim2.new(1, -28, 1, 0), TextColor3 = P.TextDim, TextSize = Kit.Style.Title - 1 })
					f.MouseEnter:Connect(function() if contains(el.Selected, opt) == nil then Kit.Tween(label, { TextColor3 = P.Text }, 0.12) end end)
					f.MouseLeave:Connect(function() if contains(el.Selected, opt) == nil then Kit.Tween(label, { TextColor3 = P.TextDim }, 0.15) end end)
					f.MouseButton1Click:Connect(function() toggle(opt) end)
					rows[opt] = { Frame = f, Box = box, Mark = mark, Label = label, Gradient = grad }
				end
				refresh(false)
			end

			function el:Set(new)
				new = new or {}
				if new.Name then s.Name = new.Name; title.Text = new.Name end
				if new.Options then s.Options = copyList(new.Options); build() end
				local want = multi and new.CurrentOptions or (new.CurrentOption ~= nil and { new.CurrentOption } or nil)
				if want then
					local clean = {}
					for _, o in ipairs(want) do if contains(s.Options, o) and not contains(clean, o) then clean[#clean + 1] = o end end
					if not multi and #clean > 1 then clean = { clean[1] } end
					if s.Max and multi then while #clean > s.Max do table.remove(clean) end end
					el.Selected = clean
					refresh(true)
					emit()
				end
			end
			function el:GetSelected() if multi then return ordered() end return el.Selected[1] end
			function el:IsSelected(opt) return contains(el.Selected, opt) ~= nil end
			function el:Clear() el.Selected = {}; refresh(true); emit() end

			build()
			return el
		end
	end
	Kit.Register("CheckboxGroup", choiceGroup(true))
	Kit.Register("RadioGroup", choiceGroup(false))
	Kit.Persist("CheckboxGroup", function(o) return o:GetSelected() end, function(o, v) o:Set({ CurrentOptions = v }) end)
	Kit.Persist("RadioGroup", function(o) return o:GetSelected() end, function(o, v) o:Set({ CurrentOption = v }) end)

	----------------------------------------------------------------------
	-- TextArea
	----------------------------------------------------------------------
	Kit.Register("TextArea", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Text Area", Placeholder = "Type here...", CurrentValue = "", MaxLength = 0, Height = 96, ShowCounter = true, RealTime = false }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - TextArea", Height = s.Height + 40, Hover = false })
		Kit.Pad(card, 12, 9, 12, 9)
		local title = Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(0.6, 0, 0, 16) })
		local counter = Kit.Text(card, { Name = "Counter", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.4, 0, 0, 16), TextSize = Kit.Style.Desc, TextColor3 = P.TextMute, Visible = s.ShowCounter })
		local box = makeBox(card, { Name = "Area", Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 1, -24), MultiLine = true, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, PlaceholderText = s.Placeholder, Text = s.CurrentValue })
		Kit.Pad(box, 0, 6, 0, 6)

		local el = Kit.Element(ctx, "TextArea", card, s, flag)
		el.CurrentValue = s.CurrentValue

		local function count()
			local n = #box.Text
			counter.Text = s.MaxLength > 0 and (n .. " / " .. s.MaxLength) or (n .. " chars")
			counter.TextColor3 = (s.MaxLength > 0 and n >= s.MaxLength) and P.Warning or P.TextMute
		end

		local function commit(text, silent)
			if s.MaxLength > 0 and #text > s.MaxLength then text = text:sub(1, s.MaxLength) end
			if box.Text ~= text then box.Text = text end
			local changed = text ~= el.CurrentValue
			el.CurrentValue = text
			s.CurrentValue = text
			count()
			if changed and not silent then el:_emit(text) end
		end

		el:Connect(box:GetPropertyChangedSignal("Text"), function()
			if s.MaxLength > 0 and #box.Text > s.MaxLength then box.Text = box.Text:sub(1, s.MaxLength) return end
			count()
			if s.RealTime then commit(box.Text) end
		end)
		el:Connect(box.FocusLost, function() commit(box.Text) end)

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.MaxLength then s.MaxLength = new.MaxLength end
			if new.Placeholder then box.PlaceholderText = new.Placeholder end
			if new.CurrentValue ~= nil then commit(tostring(new.CurrentValue)) end
		end
		function el:GetValue() return el.CurrentValue end

		commit(s.CurrentValue, true)
		return el
	end)
	Kit.Persist("TextArea", function(o) return o.CurrentValue end, function(o, v) o:Set({ CurrentValue = tostring(v) }) end)

	----------------------------------------------------------------------
	-- SecretInput (masked, optional reveal)
	----------------------------------------------------------------------
	Kit.Register("SecretInput", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Secret", Description = nil, Placeholder = "Enter value", CurrentValue = "", Reveal = true, Mask = "\u{2022}" }, s)
		local desc = s.Description and s.Description ~= ""
		local card = Kit.Card(ctx, { Name = s.Name .. " - SecretInput", Height = desc and 52 or Kit.Style.Height + 4 })
		Kit.Pad(card, 12, 0, 8, 0)
		local _, title, descLabel = Kit.Header(card, s.Name, s.Description, { Size = UDim2.new(0.4, 0, 0, desc and 34 or 18), Position = UDim2.new(0, 0, 0.5, desc and -17 or -9) })
		local holder = Kit.Frame(card, { Name = "Field", Size = UDim2.new(0.56, 0, 0, 28), Position = UDim2.new(0.44, 0, 0.5, -14) })
		local box = makeBox(holder, { Name = "Value", Size = UDim2.new(1, s.Reveal and -34 or 0, 1, 0), PlaceholderText = s.Placeholder, FontFace = Font.fromEnum(Enum.Font.Code), TextSize = Kit.Style.Title })
		local overlay = Kit.Text(box, { Name = "Mask", Size = UDim2.new(1, 0, 1, 0), FontFace = Font.fromEnum(Enum.Font.Code), TextSize = Kit.Style.Title, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 2, Active = false })
		local eye, eyeIcon
		if s.Reveal then
			eye, eyeIcon = smallButton(holder, "visibility_off", { Name = "Reveal", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -28, 0, 0) })
		end

		local el = Kit.Element(ctx, "SecretInput", card, s, flag)
		el.IgnoreConfig = true -- secrets are not written to config files unless you opt in
		el.CurrentValue = s.CurrentValue
		el.Revealed = false

		local function mask()
			if el.Revealed then
				box.TextTransparency = 0
				overlay.Visible = false
			else
				box.TextTransparency = 1
				overlay.Visible = true
				overlay.Text = string.rep(s.Mask, #box.Text)
			end
		end

		el:Connect(box:GetPropertyChangedSignal("Text"), mask)
		el:Connect(box.FocusLost, function()
			local changed = box.Text ~= el.CurrentValue
			el.CurrentValue = box.Text
			s.CurrentValue = box.Text
			if changed then el:_emit(box.Text) end
		end)
		if eye then
			eye.MouseButton1Click:Connect(function() el:SetRevealed(not el.Revealed) end)
		end

		function el:SetRevealed(state)
			el.Revealed = state and true or false
			if eyeIcon then Library._Internal.ApplyIcon(eyeIcon, el.Revealed and "visibility" or "visibility_off", "Material") end
			mask()
		end
		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.CurrentValue ~= nil then
				box.Text = tostring(new.CurrentValue)
				el.CurrentValue = box.Text
				mask()
				el:_emit(box.Text)
			end
			if new.Reveal ~= nil then el:SetRevealed(new.Reveal) end
		end
		function el:GetValue() return el.CurrentValue end

		box.Text = s.CurrentValue
		mask()
		return el
	end)
	Kit.Persist("SecretInput", function(o) return o.CurrentValue end, function(o, v) o:Set({ CurrentValue = tostring(v) }) end)

	----------------------------------------------------------------------
	-- Rating
	----------------------------------------------------------------------
	Kit.Register("Rating", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Rating", Description = nil, Max = 5, CurrentValue = 0, AllowClear = true }, s)
		local desc = s.Description and s.Description ~= ""
		local card = Kit.Card(ctx, { Name = s.Name .. " - Rating", Height = desc and 52 or Kit.Style.Height + 2 })
		Kit.Pad(card, 12, 0, 12, 0)
		local _, title = Kit.Header(card, s.Name, s.Description, { Size = UDim2.new(1, -s.Max * 24 - 10, 0, desc and 34 or 18), Position = UDim2.new(0, 0, 0.5, desc and -17 or -9) })
		local row = Kit.Frame(card, { Name = "Stars", Size = UDim2.fromOffset(s.Max * 24, 24), Position = UDim2.new(1, -s.Max * 24, 0.5, -12) })
		Kit.List(row, 0, Enum.FillDirection.Horizontal)
		local stars = {}

		local el = Kit.Element(ctx, "Rating", card, s, flag)
		el.CurrentValue = s.CurrentValue

		local function paint(upTo)
			for i, st in ipairs(stars) do
				Kit.Tween(st, { ImageColor3 = i <= upTo and GOLD or P.TextMute, ImageTransparency = i <= upTo and 0 or 0.35 }, 0.12)
			end
		end

		for i = 1, s.Max do
			local b = Kit.Button(row, { Name = "Star" .. i, Size = UDim2.fromOffset(24, 24), LayoutOrder = i })
			stars[i] = Kit.Icon(b, "star_rate", "Material", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0.5, -9, 0.5, -9), ImageColor3 = P.TextMute })
			b.MouseEnter:Connect(function() paint(i) end)
			b.MouseLeave:Connect(function() paint(el.CurrentValue) end)
			b.MouseButton1Click:Connect(function()
				if s.AllowClear and el.CurrentValue == i then el:Set({ CurrentValue = 0 }) else el:Set({ CurrentValue = i }) end
			end)
		end

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.CurrentValue ~= nil then
				local v = Kit.Clamp(math.floor(tonumber(new.CurrentValue) or 0), 0, s.Max)
				local changed = v ~= el.CurrentValue
				el.CurrentValue = v; s.CurrentValue = v
				paint(v)
				if changed then el:_emit(v) end
			end
		end
		function el:GetValue() return el.CurrentValue end

		paint(el.CurrentValue)
		return el
	end)
	Kit.Persist("Rating", function(o) return o.CurrentValue end, function(o, v) o:Set({ CurrentValue = tonumber(v) }) end)

	----------------------------------------------------------------------
	-- TagInput
	----------------------------------------------------------------------
	Kit.Register("TagInput", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Tags", Description = nil, Placeholder = "Add tag", Tags = {}, MaxTags = nil, AllowDuplicates = false }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - TagInput", Height = 0, Auto = true, Hover = false })
		Kit.Pad(card, 12, 8, 12, 10)
		local body = Kit.Frame(card, { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		Kit.List(body, 6)
		local head, title = Kit.Header(body, s.Name, s.Description, { Size = UDim2.new(1, 0, 0, (s.Description and s.Description ~= "") and 34 or 18) })
		head.LayoutOrder = 0
		local flow = Kit.Frame(body, { Name = "Flow", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
		local layout = Kit.List(flow, 6, Enum.FillDirection.Horizontal)
		layout.Wraps = true

		local el = Kit.Element(ctx, "TagInput", card, s, flag)
		el.Tags = copyList(s.Tags)
		local box

		local function emit() el:_emit(copyList(el.Tags)) end

		local function render()
			for _, c in ipairs(flow:GetChildren()) do if c:IsA("GuiObject") and c.Name ~= "Entry" then c:Destroy() end end
			for i, tag in ipairs(el.Tags) do
				local chip = Kit.Frame(flow, { Name = "Tag_" .. i, Size = UDim2.new(0, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = Kit.Accent(), BackgroundTransparency = 0.78, LayoutOrder = i })
				Kit.Corner(chip, FULL)
				Kit.Stroke(chip, Kit.Accent(), 0.55)
				Kit.Pad(chip, 10, 0, 4, 0)
				Kit.List(chip, 4, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
				Kit.Text(chip, { Name = "Label", Text = tostring(tag), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, TextSize = Kit.Style.Desc + 1, LayoutOrder = 1 })
				local x = Kit.Button(chip, { Name = "Remove", Size = UDim2.fromOffset(18, 18), LayoutOrder = 2 })
				Kit.Icon(x, "close", "Material", { Size = UDim2.fromOffset(11, 11), Position = UDim2.new(0.5, -5, 0.5, -5), ImageColor3 = P.TextDim })
				x.MouseButton1Click:Connect(function() el:RemoveTag(tag) end)
			end
			if box then box.LayoutOrder = #el.Tags + 1 end
		end

		box = makeBox(flow, { Name = "Entry", Size = UDim2.fromOffset(110, 24), PlaceholderText = s.Placeholder, TextSize = Kit.Style.Desc + 1, LayoutOrder = 9999 })

		function el:AddTag(tag)
			tag = tostring(tag or ""):gsub("^%s+", ""):gsub("%s+$", "")
			if tag == "" then return false end
			if not s.AllowDuplicates and contains(el.Tags, tag) then return false end
			if s.MaxTags and #el.Tags >= s.MaxTags then return false end
			el.Tags[#el.Tags + 1] = tag
			render(); emit()
			return true
		end
		function el:RemoveTag(tag)
			local at = contains(el.Tags, tag)
			if at then table.remove(el.Tags, at); render(); emit() end
			return at ~= nil
		end
		function el:GetTags() return copyList(el.Tags) end
		function el:Clear() el.Tags = {}; render(); emit() end
		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Tags then el.Tags = copyList(new.Tags); render(); emit() end
		end

		el:Connect(box:GetPropertyChangedSignal("Text"), function()
			if box.Text:find(",", 1, true) then
				for piece in box.Text:gmatch("[^,]+") do el:AddTag(piece) end
				box.Text = ""
			end
		end)
		el:Connect(box.FocusLost, function()
			if box.Text ~= "" then el:AddTag(box.Text) end
			box.Text = ""
		end)

		render()
		return el
	end)
	Kit.Persist("TagInput", function(o) return o:GetTags() end, function(o, v) if type(v) == "table" then o:Set({ Tags = v }) end end)

	----------------------------------------------------------------------
	-- ColorPalette
	----------------------------------------------------------------------
	local DEFAULT_SWATCHES = {
		Color3.fromRGB(239, 68, 68), Color3.fromRGB(249, 115, 22), Color3.fromRGB(250, 204, 21), Color3.fromRGB(74, 222, 128),
		Color3.fromRGB(45, 212, 191), Color3.fromRGB(56, 189, 248), Color3.fromRGB(99, 102, 241), Color3.fromRGB(168, 85, 247),
		Color3.fromRGB(236, 72, 153), Color3.fromRGB(226, 232, 240),
	}

	Kit.Register("ColorPalette", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Palette", Description = nil, Colors = DEFAULT_SWATCHES, Selected = 1, Size = 26 }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - ColorPalette", Height = 0, Auto = true, Hover = false })
		Kit.Pad(card, 12, 8, 12, 10)
		local body = Kit.Frame(card, { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		Kit.List(body, 8)
		local head, title = Kit.Header(body, s.Name, s.Description, { Size = UDim2.new(1, 0, 0, (s.Description and s.Description ~= "") and 34 or 18) })
		head.LayoutOrder = 0
		local flow = Kit.Frame(body, { Name = "Swatches", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 })
		local layout = Kit.List(flow, 8, Enum.FillDirection.Horizontal)
		layout.Wraps = true

		local el = Kit.Element(ctx, "ColorPalette", card, s, flag)
		el.Selected = s.Selected
		local swatches = {}

		local function paint(animate)
			for i, sw in ipairs(swatches) do
				local on = i == el.Selected
				Kit.Tween(sw.Stroke, { Transparency = on and 0 or 1, Thickness = on and 2 or 1 }, animate and 0.15 or 0)
				Kit.Tween(sw.Button, { Size = UDim2.fromOffset(on and s.Size + 2 or s.Size, on and s.Size + 2 or s.Size) }, animate and 0.15 or 0)
			end
		end

		local function build()
			for _, sw in ipairs(swatches) do sw.Button:Destroy() end
			swatches = {}
			for i, color in ipairs(s.Colors) do
				local b = Kit.Button(flow, { Name = "Swatch" .. i, Size = UDim2.fromOffset(s.Size, s.Size), BackgroundColor3 = color, BackgroundTransparency = 0, LayoutOrder = i })
				Kit.Corner(b, 7)
				local st = Kit.Stroke(b, Color3.new(1, 1, 1), 1, 1)
				b.MouseButton1Click:Connect(function() el:Set({ Selected = i }) end)
				swatches[i] = { Button = b, Stroke = st }
			end
			paint(false)
		end

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Colors then s.Colors = new.Colors; build() end
			local pick = new.Selected
			if new.Color then
				for i, c in ipairs(s.Colors) do if c == new.Color then pick = i end end
			end
			if pick and s.Colors[pick] then
				local changed = pick ~= el.Selected
				el.Selected = pick; s.Selected = pick
				paint(true)
				if changed then el:_emit(s.Colors[pick], pick) end
			end
		end
		function el:GetColor() return s.Colors[el.Selected], el.Selected end

		build()
		return el
	end)
	Kit.Persist("ColorPalette", function(o) return o.Selected end, function(o, v) o:Set({ Selected = tonumber(v) }) end)

	----------------------------------------------------------------------
	-- ListPicker (inline searchable list)
	----------------------------------------------------------------------
	Kit.Register("ListPicker", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "List", Options = {}, MultiSelect = false, Searchable = true, Height = 180, CurrentOption = nil, CurrentOptions = nil, Placeholder = "Search..." }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - ListPicker", Height = s.Height + 36 + (s.Searchable and 34 or 0), Hover = false })
		Kit.Pad(card, 10, 8, 10, 10)
		local title = Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(0.6, 0, 0, 16), Position = UDim2.new(0, 2, 0, 0) })
		local count = Kit.Text(card, { Name = "Count", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.4, -2, 0, 16), TextSize = Kit.Style.Desc, TextColor3 = P.TextMute })
		local top = 24
		local search
		if s.Searchable then
			search = makeBox(card, { Name = "Search", Position = UDim2.new(0, 0, 0, top), Size = UDim2.new(1, 0, 0, 28), PlaceholderText = s.Placeholder, TextSize = Kit.Style.Desc + 1 })
			top = top + 34
		end
		local list = Kit.new("ScrollingFrame", {
			Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, top), Size = UDim2.new(1, 0, 1, -top),
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = P.StrokeHover,
			ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
		})
		Kit.List(list, 2)

		local el = Kit.Element(ctx, "ListPicker", card, s, flag)
		el.Selected = {}
		if s.MultiSelect then el.Selected = copyList(s.CurrentOptions or {}) elseif s.CurrentOption ~= nil then el.Selected = { s.CurrentOption } end

		local function summary()
			count.Text = s.MultiSelect and (#el.Selected .. " selected") or (el.Selected[1] and tostring(el.Selected[1]) or "")
		end

		local function emit()
			summary()
			if s.MultiSelect then el:_emit(copyList(el.Selected)) else el:_emit(el.Selected[1]) end
		end

		local function render()
			for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
			local query = search and search.Text:lower() or ""
			local n = 0
			for i, opt in ipairs(s.Options) do
				local text = tostring(opt)
				if query == "" or text:lower():find(query, 1, true) then
					n = n + 1
					local on = contains(el.Selected, opt) ~= nil
					local row = Kit.Button(list, { Name = "Item_" .. text, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = i, BackgroundColor3 = Kit.Accent(), BackgroundTransparency = on and 0.82 or 1 })
					Kit.Corner(row, 6)
					Kit.Text(row, { Name = "Label", Text = text, Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -36, 1, 0), TextColor3 = on and P.Text or P.TextDim, TextSize = Kit.Style.Desc + 1, TextTruncate = Enum.TextTruncate.AtEnd })
					if on then Kit.Icon(row, "check", "Material", { Name = "Check", Size = UDim2.fromOffset(14, 14), Position = UDim2.new(1, -24, 0.5, -7), ImageColor3 = Kit.Accent() }) end
					row.MouseEnter:Connect(function() if contains(el.Selected, opt) == nil then Kit.Tween(row, { BackgroundTransparency = 0.92 }, 0.1) end end)
					row.MouseLeave:Connect(function() if contains(el.Selected, opt) == nil then Kit.Tween(row, { BackgroundTransparency = 1 }, 0.15) end end)
					row.MouseButton1Click:Connect(function()
						if s.MultiSelect then
							local at = contains(el.Selected, opt)
							if at then table.remove(el.Selected, at) else el.Selected[#el.Selected + 1] = opt end
						else
							el.Selected = { opt }
						end
						render(); emit()
					end)
				end
			end
			if n == 0 then
				Kit.Text(list, { Name = "Empty", Text = "No results", TextColor3 = P.TextMute, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 40) })
			end
		end

		if search then el:Connect(search:GetPropertyChangedSignal("Text"), render) end

		function el:Refresh(options) s.Options = copyList(options); local keep = {} for _, o in ipairs(el.Selected) do if contains(s.Options, o) then keep[#keep + 1] = o end end el.Selected = keep; render(); summary() end
		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Options then el:Refresh(new.Options) end
			local want = new.CurrentOptions or (new.CurrentOption ~= nil and { new.CurrentOption } or nil)
			if want then
				local clean = {}
				for _, o in ipairs(want) do if contains(s.Options, o) and not contains(clean, o) then clean[#clean + 1] = o end end
				if not s.MultiSelect and #clean > 1 then clean = { clean[1] } end
				el.Selected = clean
				render(); emit()
			end
		end
		function el:GetSelected() if s.MultiSelect then return copyList(el.Selected) end return el.Selected[1] end
		function el:Clear() el.Selected = {}; render(); emit() end

		render(); summary()
		return el
	end)
	Kit.Persist("ListPicker", function(o) return o:GetSelected() end, function(o, v) if type(v) == "table" then o:Set({ CurrentOptions = v }) else o:Set({ CurrentOption = v }) end end)
end
