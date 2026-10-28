--[[
	Exter Library | Display elements
	ProgressBar · Stat · Callout · CodeBlock · DataTable · LiveGraph · KeyValue · ProfileCard · ImageCard
]]

return function(Library, Kit)
	local P = Kit.Palette
	local Players = game:GetService("Players")
	local atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
	local FULL = UDim.new(1, 0)

	local function hasText(v) return v ~= nil and v ~= "" end
	local function typeColor(t)
		return ({ Info = P.Info, Success = P.Success, Warning = P.Warning, Error = P.Error })[t] or P.Info
	end

	----------------------------------------------------------------------
	-- ProgressBar
	----------------------------------------------------------------------
	Kit.Register("ProgressBar", function(ctx, s, flag)
		s = Kit.Defaults({
			Name = "Progress", Description = nil, Value = 0, Min = 0, Max = 100, Suffix = "%", Decimals = 0,
			ShowValue = true, Indeterminate = false, Color = nil, Format = nil,
		}, s)

		local desc = hasText(s.Description)
		local card = Kit.Card(ctx, { Name = s.Name .. " - ProgressBar", Height = desc and 62 or 48 })
		Kit.Pad(card, 12, 9, 12, 9)
		local _, title, descLabel = Kit.Header(card, s.Name, s.Description, { Size = UDim2.new(0.7, 0, 0, desc and 32 or 16) })
		local valueLabel = Kit.Text(card, {
			Name = "Value", Size = UDim2.new(0.3, 0, 0, 16), Position = UDim2.new(0.7, 0, 0, 0),
			TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = P.TextDim, Weight = Enum.FontWeight.SemiBold,
			Visible = s.ShowValue,
		})
		local track = Kit.Frame(card, {
			Name = "Track", BackgroundColor3 = P.Track, BackgroundTransparency = 0,
			Position = UDim2.new(0, 0, 1, -8), Size = UDim2.new(1, 0, 0, 8), ClipsDescendants = true,
		})
		Kit.Corner(track, FULL)
		local fill = Kit.Frame(track, { Name = "Fill", BackgroundColor3 = s.Color or Color3.new(1, 1, 1), BackgroundTransparency = 0, Size = UDim2.new(0, 0, 1, 0) })
		Kit.Corner(fill, FULL)
		if not s.Color then Kit.Gradient(fill) end

		local el = Kit.Element(ctx, "ProgressBar", card, s, flag)
		el.IgnoreConfig = true
		el.Value = s.Value
		local runToken = 0

		local function alpha()
			local span = s.Max - s.Min
			if span == 0 then return 0 end
			return Kit.Clamp((el.Value - s.Min) / span, 0, 1)
		end

		local function render(animate)
			local a = alpha()
			local text
			if s.Format then
				local ok, out = pcall(s.Format, el.Value, s.Max, a)
				text = ok and tostring(out) or "?"
			elseif s.Suffix == "%" then
				text = string.format("%." .. s.Decimals .. "f%%", a * 100)
			else
				text = Kit.FormatNumber(el.Value, s.Decimals) .. " / " .. Kit.FormatNumber(s.Max, s.Decimals) .. (s.Suffix ~= "" and (" " .. s.Suffix) or "")
			end
			valueLabel.Text = text
			if s.Indeterminate then return end
			local goal = UDim2.new(a, 0, 1, 0)
			if animate == false then fill.Size = goal else Kit.Tween(fill, { Size = goal }, 0.45, Enum.EasingStyle.Quint) end
		end

		local function runIndeterminate()
			runToken = runToken + 1
			local mine = runToken
			fill.Size = UDim2.new(0.3, 0, 1, 0)
			task.spawn(function()
				while mine == runToken and card.Parent do
					fill.Position = UDim2.new(-0.3, 0, 0, 0)
					Kit.Tween(fill, { Position = UDim2.new(1, 0, 0, 0) }, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					task.wait(1.3)
				end
			end)
		end

		function el:SetValue(v)
			v = Kit.Clamp(tonumber(v) or s.Min, math.min(s.Min, s.Max), math.max(s.Min, s.Max))
			local old = el.Value
			el.Value = v
			render()
			if v ~= old then el:_emit(v, alpha()) end
		end
		function el:GetValue() return el.Value end
		function el:GetPercent() return alpha() * 100 end
		function el:Increment(n) el:SetValue(el.Value + (n or 1)) end

		function el:SetIndeterminate(state)
			s.Indeterminate = state and true or false
			if s.Indeterminate then
				valueLabel.Visible = false
				runIndeterminate()
			else
				runToken = runToken + 1
				fill.Position = UDim2.new(0, 0, 0, 0)
				valueLabel.Visible = s.ShowValue
				render(false)
			end
		end

		function el:SetColor(color)
			s.Color = color
			fill.BackgroundColor3 = color or Color3.new(1, 1, 1)
			local g = fill:FindFirstChildOfClass("UIGradient")
			if color and g then g.Enabled = false elseif g then g.Enabled = true end
		end

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; title.Text = new.Name end
			if new.Description ~= nil then s.Description = new.Description; descLabel.Text = new.Description; descLabel.Visible = hasText(new.Description) end
			if new.Max then s.Max = new.Max end
			if new.Min then s.Min = new.Min end
			if new.Suffix ~= nil then s.Suffix = new.Suffix end
			if new.Decimals ~= nil then s.Decimals = new.Decimals end
			if new.ShowValue ~= nil then s.ShowValue = new.ShowValue; valueLabel.Visible = new.ShowValue and not s.Indeterminate end
			if new.Color ~= nil then el:SetColor(new.Color) end
			if new.Indeterminate ~= nil then el:SetIndeterminate(new.Indeterminate) end
			if new.Value ~= nil then el:SetValue(new.Value) else render() end
		end

		el.Value = Kit.Clamp(tonumber(s.Value) or s.Min, math.min(s.Min, s.Max), math.max(s.Min, s.Max))
		if s.Indeterminate then valueLabel.Visible = false; runIndeterminate() else render(false) end
		return el
	end)

	----------------------------------------------------------------------
	-- Stat
	----------------------------------------------------------------------
	Kit.Register("Stat", function(ctx, s, flag)
		s = Kit.Defaults({
			Name = "Stat", Value = 0, Description = nil, Trend = nil, TrendSuffix = "%", Prefix = "", Suffix = "",
			Decimals = 0, Icon = nil, ImageSource = "Material", Color = nil,
		}, s)

		local card = Kit.Card(ctx, { Name = s.Name .. " - Stat", Height = 82 })
		Kit.Pad(card, 14, 10, 14, 10)
		local left = s.Icon and 40 or 0
		if s.Icon then
			local badge = Kit.Frame(card, { Name = "IconBadge", Size = UDim2.fromOffset(32, 32), Position = UDim2.new(0, 0, 0.5, -16), BackgroundColor3 = P.Track, BackgroundTransparency = 0 })
			Kit.Corner(badge, 8)
			local icon = Kit.Icon(badge, s.Icon, s.ImageSource, { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0.5, -9, 0.5, -9) })
			Kit.AccentColor(icon, "ImageColor3")
		end
		local nameLabel = Kit.Text(card, { Name = "Title", Text = s.Name, TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextMute, Position = UDim2.new(0, left, 0, 0), Size = UDim2.new(1, -left - 70, 0, 14) })
		local valueLabel = Kit.Text(card, { Name = "Value", TextSize = 24, Weight = Enum.FontWeight.Bold, TextColor3 = s.Color or P.Text, Position = UDim2.new(0, left, 0, 16), Size = UDim2.new(1, -left - 70, 0, 28) })
		local descLabel = Kit.Text(card, { Name = "Desc", Text = s.Description or "", TextSize = Kit.Style.Desc, TextColor3 = P.TextMute, Position = UDim2.new(0, left, 0, 46), Size = UDim2.new(1, -left, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Visible = hasText(s.Description) })

		local chip = Kit.Frame(card, { Name = "Trend", Size = UDim2.fromOffset(64, 22), Position = UDim2.new(1, -64, 0, 2), BackgroundTransparency = 0.82, BackgroundColor3 = P.Success })
		Kit.Corner(chip, FULL)
		local chipText = Kit.Text(chip, { Size = UDim2.new(1, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Center, TextSize = Kit.Style.Desc, Weight = Enum.FontWeight.SemiBold })

		local el = Kit.Element(ctx, "Stat", card, s, flag)
		el.IgnoreConfig = true
		el.Value = s.Value
		local countToken = 0

		local function formatValue(v)
			if type(v) == "number" then return s.Prefix .. Kit.FormatNumber(v, s.Decimals) .. s.Suffix end
			return s.Prefix .. tostring(v) .. s.Suffix
		end

		local function renderTrend()
			local t = s.Trend
			chip.Visible = type(t) == "number"
			if type(t) ~= "number" then return end
			local color = t > 0 and P.Success or (t < 0 and P.Error or P.TextDim)
			chip.BackgroundColor3 = color
			chipText.TextColor3 = color
			chipText.Text = string.format("%s%s%s", t > 0 and "+" or "", Kit.FormatNumber(t, 1), s.TrendSuffix)
		end

		local function render()
			nameLabel.Text = s.Name
			valueLabel.Text = formatValue(el.Value)
			descLabel.Text = s.Description or ""
			descLabel.Visible = hasText(s.Description)
			renderTrend()
		end

		function el:Set(new)
			new = new or {}
			countToken = countToken + 1
			for _, k in ipairs({ "Name", "Description", "Trend", "Prefix", "Suffix", "Decimals" }) do
				if new[k] ~= nil then s[k] = new[k] end
			end
			if new.Value ~= nil then el.Value = new.Value end
			if new.Color then valueLabel.TextColor3 = new.Color end
			render()
		end
		function el:GetValue() return el.Value end

		-- animated number count-up/down
		function el:Count(to, duration)
			local from = tonumber(el.Value) or 0
			to = tonumber(to) or from
			duration = duration or 0.8
			countToken = countToken + 1
			local mine = countToken
			task.spawn(function()
				local t0 = os.clock()
				while mine == countToken and card.Parent do
					local a = Kit.Clamp((os.clock() - t0) / duration, 0, 1)
					local eased = 1 - (1 - a) ^ 3
					el.Value = from + (to - from) * eased
					valueLabel.Text = formatValue(el.Value)
					if a >= 1 then break end
					task.wait(0.03)
				end
				if mine == countToken then el.Value = to; valueLabel.Text = formatValue(to); el:_emit(to) end
			end)
		end

		render()
		return el
	end)

	----------------------------------------------------------------------
	-- Callout
	----------------------------------------------------------------------
	Kit.Register("Callout", function(ctx, s, flag)
		s = Kit.Defaults({ Type = "Info", Title = "Heads up", Content = "", Icon = nil, ImageSource = "Material", Dismissible = false, Color = nil }, s)
		s.Name = s.Name or s.Title
		local color = s.Color or typeColor(s.Type)
		local iconName = s.Icon or ({ Info = "info", Success = "check_circle", Warning = "warning", Error = "error" })[s.Type] or "info"

		local card = Kit.Card(ctx, { Name = s.Name .. " - Callout", Height = 0, Auto = true, Hover = false })
		card.BackgroundColor3 = P.Surface:Lerp(color, 0.1)
		local stroke = card:FindFirstChildOfClass("UIStroke")
		stroke.Color = color
		Kit.Pad(card, 16, 10, s.Dismissible and 34 or 14, 11)

		local bar = Kit.Frame(card, { Name = "Accent", BackgroundColor3 = color, BackgroundTransparency = 0, Size = UDim2.new(0, 3, 1, 0), Position = UDim2.new(0, -16, 0, 0) })
		-- bar sits in the left padding strip; card clips nothing, so keep it inside the rounded corner
		bar.Position = UDim2.new(0, -13, 0, 0)

		local body = Kit.Frame(card, { Name = "Body", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		Kit.List(body, 4)
		local titleRow = Kit.Frame(body, { Name = "TitleRow", Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1 })
		local icon = Kit.Icon(titleRow, iconName, s.ImageSource, { Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 0, 0.5, -8), ImageColor3 = color })
		local title = Kit.Text(titleRow, { Name = "Title", Text = s.Title, Weight = Enum.FontWeight.SemiBold, Position = UDim2.new(0, 24, 0, 0), Size = UDim2.new(1, -24, 1, 0), TextColor3 = P.Text })
		local content = Kit.Text(body, {
			Name = "Content", Text = s.Content, TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextDim, TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2,
			Visible = hasText(s.Content), RichText = s.RichText == true,
		})

		local el = Kit.Element(ctx, "Callout", card, s, flag)
		el.IgnoreConfig = true
		el.Dismissed = Kit.Signal.new()

		if s.Dismissible then
			local close = Kit.Button(card, { Name = "Dismiss", Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, 18, 0, -3) })
			local x = Kit.Icon(close, "close", "Material", { Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0.5, -7, 0.5, -7), ImageColor3 = P.TextMute })
			close.MouseEnter:Connect(function() Kit.Tween(x, { ImageColor3 = P.Text }, 0.15) end)
			close.MouseLeave:Connect(function() Kit.Tween(x, { ImageColor3 = P.TextMute }, 0.15) end)
			close.MouseButton1Click:Connect(function() el:Dismiss() end)
		end

		function el:Dismiss()
			if el._destroyed then return end
			el.Dismissed:Fire()
			Kit.Tween(card, { BackgroundTransparency = 1 }, 0.25)
			task.delay(0.26, function() el:Destroy() end)
		end

		function el:Set(new)
			new = new or {}
			if new.Title then title.Text = new.Title; s.Title = new.Title end
			if new.Content ~= nil then content.Text = new.Content; content.Visible = hasText(new.Content) end
			if new.Type or new.Color then
				local c = new.Color or typeColor(new.Type)
				color = c
				bar.BackgroundColor3 = c; icon.ImageColor3 = c; stroke.Color = c
				card.BackgroundColor3 = P.Surface:Lerp(c, 0.1)
				if new.Type and not new.Icon then Library._Internal.ApplyIcon(icon, ({ Info = "info", Success = "check_circle", Warning = "warning", Error = "error" })[new.Type], "Material") end
			end
			if new.Icon then Library._Internal.ApplyIcon(icon, new.Icon, new.ImageSource or "Material") end
		end

		return el
	end)

	----------------------------------------------------------------------
	-- CodeBlock (with built-in Lua syntax highlighting)
	----------------------------------------------------------------------
	local KEYWORDS, BUILTINS = {}, {}
	for w in ([[and break do else elseif end false for function goto if in local nil not or repeat return then true until while continue]]):gmatch("%S+") do KEYWORDS[w] = true end
	for w in ([[print warn error assert pairs ipairs next type typeof tostring tonumber pcall xpcall select require unpack setmetatable getmetatable rawget rawset rawequal game workspace script task math string table os coroutine Instance Vector2 Vector3 CFrame Color3 UDim UDim2 Enum TweenInfo wait spawn delay loadstring getgenv tick]]):gmatch("%S+") do BUILTINS[w] = true end

	local function esc(s) return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end

	local CODE_COLORS = {
		Keyword = "#C792EA", String = "#A5E075", Number = "#F5A97F", Comment = "#6B7089",
		Builtin = "#7DCFFF", Func = "#82AAFF", Member = "#B4BEFE",
	}

	function Kit.HighlightLua(code, colors)
		colors = colors or CODE_COLORS
		local out, i, n = {}, 1, #code
		local function push(text, color)
			text = esc(text)
			out[#out + 1] = color and ('<font color="' .. color .. '">' .. text .. "</font>") or text
		end
		local plainStart
		while i <= n do
			local c = code:sub(i, i)
			if code:sub(i, i + 1) == "--" then
				local e = code:find("\n", i, true) or (n + 1)
				push(code:sub(i, e - 1), colors.Comment); i = e
			elseif c == '"' or c == "'" then
				local j = i + 1
				while j <= n do
					local d = code:sub(j, j)
					if d == "\\" then j = j + 2
					elseif d == c then break
					elseif d == "\n" then j = j - 1 break
					else j = j + 1 end
				end
				j = math.min(j, n)
				push(code:sub(i, j), colors.String); i = j + 1
			elseif c:match("%d") then
				local _, e = code:find("^0[xX]%x+", i)
				if not e then _, e = code:find("^%d+%.?%d*", i) end
				push(code:sub(i, e), colors.Number); i = e + 1
			elseif c:match("[%a_]") then
				local _, e = code:find("^[%w_]+", i)
				local word = code:sub(i, e)
				local prev = code:sub(1, i - 1):match("([%.:])%s*$")
				local color
				if prev then
					color = colors.Member
				elseif KEYWORDS[word] then color = colors.Keyword
				elseif BUILTINS[word] then color = colors.Builtin
				elseif code:find("^%s*%(", e + 1) then color = colors.Func end
				push(word, color); i = e + 1
			else
				local _, e = code:find("^[^%w_\"'%-]+", i)
				if not e then e = i end
				push(code:sub(i, e), nil); i = e + 1
			end
		end
		return table.concat(out)
	end

	local function copyToClipboard(text)
		local fn = setclipboard or toclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set)
		if not fn then return false end
		return (pcall(fn, text))
	end
	Kit.CopyToClipboard = copyToClipboard

	Kit.Register("CodeBlock", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Code", Code = "", Language = "lua", Copy = true, MaxHeight = 170, LineNumbers = true, TextSize = 13 }, s)
		local function stats(code)
			local _, lines = code:gsub("\n", "\n")
			return lines + 1
		end
		local lineH = s.TextSize + 3
		local function heightFor(code) return math.min(s.MaxHeight, stats(code) * lineH + 16) end

		local card = Kit.Card(ctx, { Name = s.Name .. " - CodeBlock", Height = 34 + heightFor(s.Code), Hover = false })
		card.BackgroundColor3 = P.Track
		card.BackgroundTransparency = 0.15
		local top = Kit.Frame(card, { Name = "Bar", Size = UDim2.new(1, 0, 0, 30) })
		Kit.Pad(top, 12, 0, 6, 0)
		local langLabel = Kit.Text(top, { Name = "Language", Text = string.upper(s.Name ~= "Code" and s.Name or s.Language), TextSize = Kit.Style.Desc, TextColor3 = P.TextMute, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(1, -80, 1, 0) })
		local copyBtn = Kit.Button(top, { Name = "Copy", Size = UDim2.fromOffset(72, 22), Position = UDim2.new(1, -72, 0.5, -11), BackgroundTransparency = 0.8, BackgroundColor3 = P.SurfaceHi, Visible = s.Copy })
		Kit.Corner(copyBtn, 6)
		local copyIcon = Kit.Icon(copyBtn, "content_copy", "Material", { Size = UDim2.fromOffset(13, 13), Position = UDim2.new(0, 8, 0.5, -6), ImageColor3 = P.TextDim })
		local copyText = Kit.Text(copyBtn, { Name = "Label", Text = "Copy", TextSize = Kit.Style.Desc, TextColor3 = P.TextDim, Position = UDim2.new(0, 27, 0, 0), Size = UDim2.new(1, -27, 1, 0) })

		local scroll = Kit.new("ScrollingFrame", {
			Name = "Scroll", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(1, 0, 1, -30),
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.XY, ScrollBarThickness = 4,
			ScrollBarImageColor3 = P.StrokeHover, ScrollingDirection = Enum.ScrollingDirection.XY, Parent = card,
		})
		Kit.Pad(scroll, 12, 4, 12, 8)
		local gutter = Kit.Text(scroll, { Name = "Gutter", Text = "", FontFace = Font.fromEnum(Enum.Font.Code), TextSize = s.TextSize, TextColor3 = P.TextMute, TextTransparency = 0.35, TextYAlignment = Enum.TextYAlignment.Top, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 26, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Visible = s.LineNumbers })
		local codeLabel = Kit.Text(scroll, {
			Name = "Code", Text = "", FontFace = Font.fromEnum(Enum.Font.Code), TextSize = s.TextSize, RichText = true,
			TextWrapped = false, TextYAlignment = Enum.TextYAlignment.Top, TextColor3 = Color3.fromRGB(205, 208, 224),
			Position = UDim2.new(0, s.LineNumbers and 36 or 0, 0, 0), Size = UDim2.new(0, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		})

		local el = Kit.Element(ctx, "CodeBlock", card, s, flag)
		el.IgnoreConfig = true
		el.Code = s.Code

		local function render()
			local code = tostring(el.Code):gsub("\t", "    ")
			codeLabel.Text = Kit.HighlightLua(code)
			local numbers = {}
			for i = 1, stats(code) do numbers[i] = tostring(i) end
			gutter.Text = table.concat(numbers, "\n")
			card.Size = UDim2.new(Kit.Style.Width.Scale, Kit.Style.Width.Offset, 0, 34 + heightFor(code))
		end

		function el:Copy()
			local ok = copyToClipboard(el.Code)
			copyText.Text = ok and "Copied" or "Failed"
			copyIcon.ImageColor3 = ok and P.Success or P.Error
			task.delay(1.2, function()
				if copyBtn.Parent then copyText.Text = "Copy"; copyIcon.ImageColor3 = P.TextDim end
			end)
			if not ok then Library:Notification({ Title = "Copy unavailable", Content = "This executor has no clipboard function.", Type = "Warning" }) end
			return ok
		end
		copyBtn.MouseButton1Click:Connect(function() el:Copy() end)
		copyBtn.MouseEnter:Connect(function() Kit.Tween(copyBtn, { BackgroundTransparency = 0.5 }, 0.15) end)
		copyBtn.MouseLeave:Connect(function() Kit.Tween(copyBtn, { BackgroundTransparency = 0.8 }, 0.15) end)

		function el:Set(new)
			new = new or {}
			if new.Language then langLabel.Text = string.upper(new.Language) end
			if new.Code ~= nil then el.Code = new.Code end
			render()
		end
		function el:GetCode() return el.Code end

		render()
		return el
	end)

	----------------------------------------------------------------------
	-- DataTable
	----------------------------------------------------------------------
	Kit.Register("DataTable", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Table", Columns = { "Column" }, Rows = {}, MaxRows = 6, RowHeight = 28, Striped = true, Sortable = true, Callback = nil }, s)

		local cols = {}
		for i, c in ipairs(s.Columns) do
			if type(c) == "table" then cols[i] = { Name = c.Name or ("Col" .. i), Width = c.Width, Align = c.Align or "Left" }
			else cols[i] = { Name = tostring(c), Align = "Left" } end
		end
		local fixed, flex = 0, 0
		for _, c in ipairs(cols) do if c.Width then fixed = fixed + c.Width else flex = flex + 1 end end
		for _, c in ipairs(cols) do
			if not c.Width then c.Width = flex > 0 and (math.max(0.05, 1 - fixed) / flex) or 0 end
		end
		local function colWidth(i) return UDim2.new(cols[i].Width, 0, 1, 0) end
		local aligns = { Left = Enum.TextXAlignment.Left, Center = Enum.TextXAlignment.Center, Right = Enum.TextXAlignment.Right }

		local headH = 30
		local card = Kit.Card(ctx, { Name = s.Name .. " - DataTable", Height = headH + s.RowHeight * s.MaxRows + 2, Clip = true, Hover = false })

		local head = Kit.Frame(card, { Name = "Head", Size = UDim2.new(1, 0, 0, headH), BackgroundTransparency = 0.6, BackgroundColor3 = P.Track })
		local headRow = Kit.Frame(head, { Name = "Row" })
		Kit.List(headRow, 0, Enum.FillDirection.Horizontal)
		Kit.Pad(headRow, 12, 0, 12, 0)
		local headers = {}
		for i, c in ipairs(cols) do
			local b = Kit.Button(headRow, { Name = c.Name, Size = colWidth(i), LayoutOrder = i, Text = string.upper(c.Name), TextSize = Kit.Style.Desc - 1, TextColor3 = P.TextMute, TextXAlignment = aligns[c.Align] or aligns.Left, FontFace = Kit.Font(Enum.FontWeight.Bold) })
			headers[i] = b
		end

		local list = Kit.new("ScrollingFrame", {
			Name = "Rows", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, headH), Size = UDim2.new(1, 0, 1, -headH),
			CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = P.StrokeHover,
			ScrollingDirection = Enum.ScrollingDirection.Y, Parent = card,
		})
		Kit.List(list, 0)

		local el = Kit.Element(ctx, "DataTable", card, s, flag)
		el.IgnoreConfig = true
		el.Rows = {}
		el.SortColumn, el.SortAscending = nil, true
		el.RowSelected = Kit.Signal.new()

		local function cmp(a, b)
			local x, y = a[el.SortColumn], b[el.SortColumn]
			local nx, ny = tonumber(x), tonumber(y)
			local less
			if nx and ny then less = nx < ny else less = tostring(x):lower() < tostring(y):lower() end
			if el.SortAscending then return less end
			if nx and ny then return nx > ny end
			return tostring(x):lower() > tostring(y):lower()
		end

		local function render()
			for _, ch in ipairs(list:GetChildren()) do
				if ch:IsA("GuiObject") then ch:Destroy() end
			end
			local rows = {}
			for i, row in ipairs(el.Rows) do rows[i] = row end
			if el.SortColumn then table.sort(rows, cmp) end
			for r, row in ipairs(rows) do
				local line = Kit.Button(list, { Name = "Row" .. r, Size = UDim2.new(1, 0, 0, s.RowHeight), LayoutOrder = r, BackgroundTransparency = (s.Striped and r % 2 == 0) and 0.88 or 1, BackgroundColor3 = P.SurfaceHi })
				local inner = Kit.Frame(line, { Name = "Cells" })
				Kit.List(inner, 0, Enum.FillDirection.Horizontal)
				Kit.Pad(inner, 12, 0, 12, 0)
				for i = 1, #cols do
					Kit.Text(inner, { Name = "Cell" .. i, Text = tostring(row[i] == nil and "" or row[i]), Size = colWidth(i), LayoutOrder = i, TextSize = Kit.Style.Desc + 1, TextColor3 = P.TextDim, TextXAlignment = aligns[cols[i].Align] or aligns.Left, TextTruncate = Enum.TextTruncate.AtEnd })
				end
				local base = line.BackgroundTransparency
				line.MouseEnter:Connect(function() Kit.Tween(line, { BackgroundTransparency = 0.7 }, 0.12) end)
				line.MouseLeave:Connect(function() Kit.Tween(line, { BackgroundTransparency = base }, 0.18) end)
				line.MouseButton1Click:Connect(function()
					el.RowSelected:Fire(row, r)
					if s.Callback then
						local ok, err = pcall(s.Callback, row, r)
						if not ok then print("Exter Library | " .. s.Name .. " Callback Error " .. tostring(err)) end
					end
				end)
			end
			for i, h in ipairs(headers) do
				local mark = ""
				if el.SortColumn == i then mark = el.SortAscending and "  ^" or "  v" end
				h.Text = string.upper(cols[i].Name) .. mark
				h.TextColor3 = el.SortColumn == i and Kit.Accent() or P.TextMute
			end
		end

		if s.Sortable then
			for i, h in ipairs(headers) do
				h.MouseButton1Click:Connect(function()
					if el.SortColumn == i then el.SortAscending = not el.SortAscending else el.SortColumn, el.SortAscending = i, true end
					render()
				end)
			end
		end

		function el:SetRows(rows) el.Rows = rows or {}; render() end
		function el:AddRow(row) el.Rows[#el.Rows + 1] = row; render() end
		function el:RemoveRow(index) table.remove(el.Rows, index); render() end
		function el:Clear() el.Rows = {}; render() end
		function el:GetRows() return el.Rows end
		function el:Sort(column, ascending) el.SortColumn, el.SortAscending = column, ascending ~= false; render() end
		function el:Set(new) if new and new.Rows then el:SetRows(new.Rows) end end

		el.Rows = s.Rows
		render()
		return el
	end)

	----------------------------------------------------------------------
	-- LiveGraph
	----------------------------------------------------------------------
	Kit.Register("LiveGraph", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Graph", Samples = 60, Min = nil, Max = nil, Suffix = "", Decimals = 0, Height = 120, Color = nil, Initial = nil }, s)
		s.Samples = math.max(3, math.floor(s.Samples))
		local auto = s.Min == nil or s.Max == nil

		local card = Kit.Card(ctx, { Name = s.Name .. " - LiveGraph", Height = s.Height + 30, Hover = true })
		Kit.Pad(card, 12, 8, 12, 10)
		local title = Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(0.6, 0, 0, 16) })
		local current = Kit.Text(card, { Name = "Current", TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(0.6, 0, 0, 0), Size = UDim2.new(0.4, 0, 0, 16), TextColor3 = P.TextDim, Weight = Enum.FontWeight.SemiBold })
		local plot = Kit.Frame(card, { Name = "Plot", Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 1, -24), ClipsDescendants = true, BackgroundColor3 = P.Track, BackgroundTransparency = 0.35 })
		Kit.Corner(plot, 6)
		for i = 1, 3 do
			Kit.Frame(plot, { Name = "Grid" .. i, Position = UDim2.new(0, 0, i / 4, 0), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Stroke, BackgroundTransparency = 0.7 })
		end
		local maxLabel = Kit.Text(plot, { Name = "Max", TextSize = Kit.Style.Desc - 2, TextColor3 = P.TextMute, Position = UDim2.new(0, 6, 0, 2), Size = UDim2.new(0.5, 0, 0, 12), ZIndex = 3 })
		local minLabel = Kit.Text(plot, { Name = "Min", TextSize = Kit.Style.Desc - 2, TextColor3 = P.TextMute, Position = UDim2.new(0, 6, 1, -14), Size = UDim2.new(0.5, 0, 0, 12), ZIndex = 3 })

		local el = Kit.Element(ctx, "LiveGraph", card, s, flag)
		el.IgnoreConfig = true
		el.Data = {}
		local segs, dot = {}, nil

		local function fmt(v) return Kit.FormatNumber(v, s.Decimals) .. s.Suffix end

		local function redraw()
			local data, n = el.Data, #el.Data
			local size = plot.AbsoluteSize
			local w = size.X > 0 and size.X or 300
			local h = size.Y > 0 and size.Y or (s.Height - 24)
			local lo, hi = s.Min, s.Max
			if auto and n > 0 then
				lo, hi = math.huge, -math.huge
				for _, v in ipairs(data) do lo = math.min(lo, v); hi = math.max(hi, v) end
				if s.Min ~= nil then lo = s.Min end
				if s.Max ~= nil then hi = s.Max end
				local pad = (hi - lo) * 0.1
				if pad == 0 then pad = math.max(1, math.abs(hi) * 0.1) end
				if s.Min == nil then lo = lo - pad end
				if s.Max == nil then hi = hi + pad end
			end
			lo, hi = lo or 0, hi or 100
			local range = hi - lo
			if range <= 0 then range = 1 end
			maxLabel.Text = fmt(hi); minLabel.Text = fmt(lo)
			current.Text = n > 0 and fmt(data[n]) or "-"

			local pts = {}
			for i = 1, n do
				local x = (i - 1 + (s.Samples - n)) / (s.Samples - 1) * w
				local y = h - Kit.Clamp((data[i] - lo) / range, 0, 1) * (h - 4) - 2
				pts[i] = { x, y }
			end
			local color = s.Color or Kit.Accent()
			for i = 1, n - 1 do
				local a, b = pts[i], pts[i + 1]
				local seg = segs[i]
				if not seg then
					seg = Kit.Frame(plot, { Name = "Seg" .. i, AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 0, ZIndex = 2 })
					Kit.Corner(seg, FULL)
					segs[i] = seg
				end
				local dx, dy = b[1] - a[1], b[2] - a[2]
				seg.BackgroundColor3 = color
				seg.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1.5, 2)
				seg.Position = UDim2.fromOffset((a[1] + b[1]) / 2, (a[2] + b[2]) / 2)
				seg.Rotation = math.deg(atan2(dy, dx))
				seg.Visible = true
			end
			for i = math.max(n, 1), #segs do segs[i].Visible = false end
			if n > 0 then
				if not dot then
					dot = Kit.Frame(plot, { Name = "Dot", AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 7), BackgroundTransparency = 0, ZIndex = 4 })
					Kit.Corner(dot, FULL)
				end
				dot.BackgroundColor3 = color
				dot.Position = UDim2.fromOffset(pts[n][1], pts[n][2])
			end
		end

		el:Connect(plot:GetPropertyChangedSignal("AbsoluteSize"), redraw)
		Kit.OnTheme(function() if card.Parent then redraw() end end)

		function el:Push(value)
			value = tonumber(value)
			if not value then return end
			el.Data[#el.Data + 1] = value
			if #el.Data > s.Samples then table.remove(el.Data, 1) end
			redraw()
			return value
		end
		function el:SetData(list) el.Data = {}; for _, v in ipairs(list or {}) do el.Data[#el.Data + 1] = tonumber(v) or 0 end; while #el.Data > s.Samples do table.remove(el.Data, 1) end; redraw() end
		function el:GetData() return el.Data end
		function el:Clear() el.Data = {}; redraw() end
		function el:Set(new)
			new = new or {}
			if new.Name then title.Text = new.Name; s.Name = new.Name end
			if new.Min ~= nil then s.Min = new.Min end
			if new.Max ~= nil then s.Max = new.Max end
			auto = s.Min == nil or s.Max == nil
			if new.Color then s.Color = new.Color end
			if new.Data then el:SetData(new.Data) else redraw() end
		end

		if s.Initial then el:SetData(s.Initial) else redraw() end
		return el
	end)

	----------------------------------------------------------------------
	-- KeyValue
	----------------------------------------------------------------------
	Kit.Register("KeyValue", function(ctx, s, flag)
		s = Kit.Defaults({ Name = nil, Items = {}, RowHeight = 26 }, s)
		local card = Kit.Card(ctx, { Name = (s.Name or "KeyValue") .. " - KeyValue", Height = 0, Auto = true, Hover = false })
		Kit.Pad(card, 14, 6, 14, 6)
		local body = Kit.Frame(card, { Name = "Rows", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y })
		Kit.List(body, 0)

		local el = Kit.Element(ctx, "KeyValue", card, s, flag)
		el.IgnoreConfig = true
		el.Items, el.Rows = {}, {}

		local function addRow(key, value, color, index)
			local row = Kit.Frame(body, { Name = "Row_" .. tostring(key), Size = UDim2.new(1, 0, 0, s.RowHeight), LayoutOrder = index })
			local k = Kit.Text(row, { Name = "Key", Text = tostring(key), TextColor3 = P.TextMute, TextSize = Kit.Style.Desc + 1, Size = UDim2.new(0.45, 0, 1, 0) })
			local v = Kit.Text(row, { Name = "Value", Text = tostring(value), TextColor3 = color or P.Text, Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Weight = Enum.FontWeight.SemiBold, TextSize = Kit.Style.Desc + 1 })
			if index > 1 then Kit.Frame(row, { Name = "Line", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Stroke, BackgroundTransparency = 0.75 }) end
			el.Rows[key] = { Row = row, Value = v }
		end

		local function build(items)
			for _, r in pairs(el.Rows) do r.Row:Destroy() end
			el.Rows, el.Items = {}, {}
			for i, item in ipairs(items or {}) do
				local key = item.Key or item[1]
				local value = item.Value
				if value == nil then value = item[2] end
				el.Items[#el.Items + 1] = { Key = key, Value = value }
				addRow(key, value, item.Color, i)
			end
		end

		function el:SetItems(items) build(items) end
		function el:Set(key, value, color)
			if type(key) == "table" then return el:SetItems(key.Items or key) end
			local r = el.Rows[key]
			if not r then
				el.Items[#el.Items + 1] = { Key = key, Value = value }
				return addRow(key, value, color, #el.Items)
			end
			r.Value.Text = tostring(value)
			if color then r.Value.TextColor3 = color end
			for _, it in ipairs(el.Items) do if it.Key == key then it.Value = value end end
		end
		function el:GetValue(key) for _, it in ipairs(el.Items) do if it.Key == key then return it.Value end end end

		build(s.Items)
		return el
	end)

	----------------------------------------------------------------------
	-- ProfileCard
	----------------------------------------------------------------------
	Kit.Register("ProfileCard", function(ctx, s, flag)
		local lp = Players.LocalPlayer
		s = Kit.Defaults({ UserId = lp and lp.UserId or 1, Name = lp and (lp.DisplayName or lp.Name) or "Player", Subtitle = lp and ("@" .. lp.Name) or "", Badges = {}, Image = nil }, s)

		local card = Kit.Card(ctx, { Name = "ProfileCard", Height = 76 })
		Kit.Pad(card, 14, 10, 14, 10)
		local avatar = Kit.new("ImageLabel", { Name = "Avatar", BackgroundColor3 = P.Track, BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 0, 0.5, -27), ScaleType = Enum.ScaleType.Crop, Image = s.Image or "", Parent = card })
		Kit.Corner(avatar, FULL)
		local ring = Kit.Stroke(avatar, Kit.Accent(), 0.2, 2)
		Kit.AccentColor(ring, "Color")
		local nameLabel = Kit.Text(card, { Name = "Title", Text = s.Name, TextSize = Kit.Style.Title + 2, Weight = Enum.FontWeight.Bold, Position = UDim2.new(0, 68, 0, 6), Size = UDim2.new(1, -68, 0, 20) })
		local sub = Kit.Text(card, { Name = "Subtitle", Text = s.Subtitle, TextSize = Kit.Style.Desc, TextColor3 = P.TextMute, Position = UDim2.new(0, 68, 0, 26), Size = UDim2.new(1, -68, 0, 14) })
		local badgeRow = Kit.Frame(card, { Name = "Badges", Position = UDim2.new(0, 68, 0, 44), Size = UDim2.new(1, -68, 0, 16) })
		Kit.List(badgeRow, 6, Enum.FillDirection.Horizontal)

		local el = Kit.Element(ctx, "ProfileCard", card, s, flag)
		el.IgnoreConfig = true

		local function setBadges(list)
			for _, c in ipairs(badgeRow:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
			for i, text in ipairs(list or {}) do
				local label = type(text) == "table" and text.Text or tostring(text)
				local color = type(text) == "table" and text.Color or Kit.Accent()
				local chip = Kit.Frame(badgeRow, { Name = "Badge" .. i, Size = UDim2.fromOffset(#label * 6.5 + 16, 16), BackgroundColor3 = color, BackgroundTransparency = 0.8, LayoutOrder = i })
				Kit.Corner(chip, FULL)
				Kit.Text(chip, { Text = label, TextSize = Kit.Style.Desc - 2, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 1, 0), Weight = Enum.FontWeight.Bold })
			end
		end

		local function loadAvatar()
			if s.Image then avatar.Image = s.Image; return end
			task.spawn(function()
				local ok, url = pcall(Players.GetUserThumbAsync, Players, s.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				if ok and url and avatar.Parent then avatar.Image = url end
			end)
		end

		function el:Set(new)
			new = new or {}
			if new.Name then s.Name = new.Name; nameLabel.Text = new.Name end
			if new.Subtitle then s.Subtitle = new.Subtitle; sub.Text = new.Subtitle end
			if new.Badges then setBadges(new.Badges) end
			if new.UserId then s.UserId = new.UserId; s.Image = nil; loadAvatar() end
			if new.Image then s.Image = new.Image; loadAvatar() end
		end

		setBadges(s.Badges)
		loadAvatar()
		return el
	end)

	----------------------------------------------------------------------
	-- ImageCard
	----------------------------------------------------------------------
	Kit.Register("ImageCard", function(ctx, s, flag)
		s = Kit.Defaults({ Name = "Image", Image = "", Caption = nil, Height = 140, ScaleType = "Crop", Callback = nil }, s)
		local card = Kit.Card(ctx, { Name = s.Name .. " - ImageCard", Height = s.Height, Clip = true })
		local img = Kit.new("ImageLabel", { Name = "Image", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, 0), Image = s.Image, ScaleType = Enum.ScaleType[s.ScaleType] or Enum.ScaleType.Crop, Parent = card })
		local shade = Kit.Frame(card, { Name = "Shade", Position = UDim2.new(0, 0, 0.55, 0), Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0, ZIndex = 2 })
		Kit.new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) }), Parent = shade })
		local caption = Kit.Text(card, { Name = "Caption", Text = s.Caption or s.Name, Weight = Enum.FontWeight.SemiBold, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.new(0, 12, 1, -28), Size = UDim2.new(1, -24, 0, 20), ZIndex = 3, Visible = s.Caption ~= false })
		local hit = Kit.Button(card, { Name = "Hit", ZIndex = 4 })

		local el = Kit.Element(ctx, "ImageCard", card, s, flag)
		el.IgnoreConfig = true
		hit.MouseButton1Click:Connect(function() el:_emit() end)
		hit.MouseEnter:Connect(function() Kit.Tween(img, { ImageTransparency = 0.12 }, 0.2) end)
		hit.MouseLeave:Connect(function() Kit.Tween(img, { ImageTransparency = 0 }, 0.25) end)

		function el:Set(new)
			new = new or {}
			if new.Image then img.Image = new.Image end
			if new.Caption then caption.Text = new.Caption end
			if new.Height then card.Size = UDim2.new(Kit.Style.Width.Scale, Kit.Style.Width.Offset, 0, new.Height) end
		end
		return el
	end)
end
