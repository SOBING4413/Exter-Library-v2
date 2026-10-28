--[[
	Exter Library | 07 - Writing your own element
	--------------------------------------------------------------------
	Kit.Register adds a new Create<Name> method to every Tab, Section and
	container (existing and future). You get theming, animation, the shared
	element API (:SetVisible, :SetDisabled, :OnChanged, :Destroy, flags, tooltips)
	and config saving for free.

	See docs/EXTENDING.md for the full walkthrough.
]]

local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()

local Kit = Exter.Kit -- the toolkit the built-in elements use
local P = Kit.Palette

-- 1. Describe the element: a title on the left, a number, and a [+] button.
Kit.Register("Counter", function(ctx, settings, flag)
	local s = Kit.Defaults({ Name = "Counter", CurrentValue = 0, Step = 1 }, settings)

	local card = Kit.Card(ctx, { Name = s.Name .. " - Counter", Height = 44 })
	Kit.Pad(card, 12, 0, 8, 0)
	Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(1, -110, 1, 0) })
	local valueLabel = Kit.Text(card, {
		Name = "Value", TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = P.TextDim,
		Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -104, 0, 0),
	})
	local button = Kit.Button(card, {
		Name = "Add", Text = "+", TextColor3 = P.Text, BackgroundTransparency = 0.2, BackgroundColor3 = P.Track,
		Size = UDim2.fromOffset(32, 26), Position = UDim2.new(1, -40, 0.5, -13),
	})
	Kit.Corner(button, 6)

	-- 2. Wrap it in the shared element object.
	local el = Kit.Element(ctx, "Counter", card, s, flag)
	el.CurrentValue = s.CurrentValue

	function el:Set(new)
		new = new or {}
		if new.CurrentValue ~= nil then
			el.CurrentValue = new.CurrentValue
			valueLabel.Text = tostring(el.CurrentValue)
			el:_emit(el.CurrentValue) -- fires Callback + the Changed signal
		end
	end
	function el:GetValue() return el.CurrentValue end

	button.MouseButton1Click:Connect(function()
		el:Set({ CurrentValue = el.CurrentValue + s.Step })
	end)

	valueLabel.Text = tostring(el.CurrentValue)
	return el
end)

-- 3. Optional: let BuildConfigSection save and restore it.
Kit.Persist("Counter", function(option) return option.CurrentValue end, function(option, saved)
	option:Set({ CurrentValue = tonumber(saved) or 0 })
end)

-- 4. Use it like any built-in element.
local Window = Exter:CreateWindow({ Name = "Custom element", Subtitle = "Kit.Register" })
local Tab = Window:CreateTab({ Name = "Demo", Icon = "tune", ImageSource = "Material" })

local clicks = Tab:CreateCounter({
	Name = "Clicks",
	Step = 5,
	Tooltip = "Adds five each time",
	Callback = function(value) print("count:", value) end,
}, "Clicks")

clicks:OnChanged(function(value)
	if value >= 20 then Exter:Notification({ Title = "Nice", Content = "You reached " .. value, Duration = 3 }) end
end)

-- It also works inside containers, sections and sub tabs automatically.
local group = Tab:CreateAccordion({ Name = "Inside a group", Open = true })
group:CreateCounter({ Name = "Nested counter" })
