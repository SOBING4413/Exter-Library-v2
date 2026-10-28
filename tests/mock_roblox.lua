--[[
	Minimal Roblox runtime mock used by the test-suite.

	Not a full emulator: it implements the slice of the Roblox API that the
	Exter extension modules touch, and (importantly) it is STRICT - reading or
	writing a property that does not exist on a class raises the same kind of
	error Roblox does, so typos in property names fail the tests instead of
	failing silently in-game.
]]

local Mock = { clock = 0, clipboard = nil }
local unpack = table.unpack or unpack

----------------------------------------------------------------------
-- scheduler (virtual time)
----------------------------------------------------------------------
local sleepers, runQueue = {}, {}

local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then print("[mock] thread error: " .. tostring(err)) Mock.lastThreadError = tostring(err) end
	return ok
end

task = {}
function task.spawn(fnOrThread, ...)
	local co = type(fnOrThread) == "thread" and fnOrThread or coroutine.create(fnOrThread)
	resume(co, ...)
	return co
end
function task.defer(fn, ...) local args = { ... }; runQueue[#runQueue + 1] = function() task.spawn(fn, unpack(args)) end end
function task.delay(t, fn, ...)
	local args = { ... }
	sleepers[#sleepers + 1] = { wake = Mock.clock + (t or 0), fn = function() task.spawn(fn, unpack(args)) end }
end
function task.wait(t)
	t = t or 0.03
	if coroutine.isyieldable() then
		local co = coroutine.running()
		sleepers[#sleepers + 1] = { wake = Mock.clock + t, fn = function() resume(co, t) end }
		return coroutine.yield()
	end
	Mock.advance(t)
	return t
end
function task.cancel() end
wait = task.wait

function Mock.advance(dt)
	local target = Mock.clock + dt
	local guard = 0
	while guard < 5000 do
		guard = guard + 1
		while #runQueue > 0 do local q = runQueue; runQueue = {}; for _, f in ipairs(q) do f() end end
		local idx, best
		for i, s in ipairs(sleepers) do
			if s.wake <= target and (not best or s.wake < best.wake) then idx, best = i, s end
		end
		if not best then break end
		table.remove(sleepers, idx)
		Mock.clock = math.max(Mock.clock, best.wake)
		best.fn()
	end
	Mock.clock = target
end

os.clock = function() return Mock.clock end
tick = function() return Mock.clock end
time = function() return Mock.clock end

----------------------------------------------------------------------
-- math / table polyfills that Luau provides
----------------------------------------------------------------------
function math.clamp(n, lo, hi) return math.max(lo, math.min(hi, n)) end
function math.round(n) return math.floor(n + 0.5) end
function math.sign(n) return n > 0 and 1 or (n < 0 and -1 or 0) end
math.atan2 = math.atan2 or function(y, x) return math.atan(y, x) end
function math.lerp(a, b, t) return a + (b - a) * t end
function table.find(t, v) for i, x in ipairs(t) do if x == v then return i end end end
function table.clear(t) for k in pairs(t) do t[k] = nil end end
function table.create(n, v) local t = {} for i = 1, n do t[i] = v end return t end
if not table.pack then table.pack = function(...) return { n = select("#", ...), ... } end end

----------------------------------------------------------------------
-- signals
----------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal
local function newSignal() return setmetatable({ list = {} }, Signal) end
function Signal:Connect(fn)
	local c = { Connected = true, fn = fn }
	function c:Disconnect() self.Connected = false end
	c.disconnect = c.Disconnect
	self.list[#self.list + 1] = c
	return c
end
Signal.connect = Signal.Connect
function Signal:Once(fn) local c; c = self:Connect(function(...) c:Disconnect() fn(...) end) return c end
function Signal:Wait() local co = coroutine.running(); self:Once(function(...) task.spawn(co, ...) end) return coroutine.yield() end
function Signal:Fire(...)
	for _, c in ipairs({ unpack(self.list) }) do
		if c.Connected then
			local ok, err = pcall(c.fn, ...)
			if not ok then print("[mock] signal handler error: " .. tostring(err)) Mock.lastSignalError = tostring(err) end
		end
	end
end
Mock.NewSignal = newSignal

----------------------------------------------------------------------
-- data types
----------------------------------------------------------------------
local function typed(name, t) t.__type = name return t end

UDim = {}
UDim.__index = UDim
UDim.__type = "UDim"
function UDim.new(s, o) return setmetatable({ Scale = s or 0, Offset = o or 0 }, UDim) end
UDim.__eq = function(a, b) return a.Scale == b.Scale and a.Offset == b.Offset end
UDim.__add = function(a, b) return UDim.new(a.Scale + b.Scale, a.Offset + b.Offset) end

UDim2 = {}
UDim2.__index = UDim2
UDim2.__type = "UDim2"
function UDim2.new(xs, xo, ys, yo)
	if type(xs) == "table" then return setmetatable({ X = xs, Y = xo }, UDim2) end
	return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UDim2)
end
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
UDim2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
UDim2.__add = function(a, b) return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset) end
function UDim2:Lerp(o, a) return UDim2.new(self.X.Scale + (o.X.Scale - self.X.Scale) * a, self.X.Offset + (o.X.Offset - self.X.Offset) * a, self.Y.Scale + (o.Y.Scale - self.Y.Scale) * a, self.Y.Offset + (o.Y.Offset - self.Y.Offset) * a) end

Vector2 = {}
Vector2.__type = "Vector2"
Vector2.__index = function(t, k) if k == "Magnitude" then return math.sqrt(t.X * t.X + t.Y * t.Y) end return Vector2[k] end
function Vector2.new(x, y) return setmetatable({ X = x or 0, Y = y or 0 }, Vector2) end
Vector2.__add = function(a, b) return Vector2.new(a.X + b.X, a.Y + b.Y) end
Vector2.__sub = function(a, b) return Vector2.new(a.X - b.X, a.Y - b.Y) end
Vector2.__mul = function(a, b) if type(b) == "number" then return Vector2.new(a.X * b, a.Y * b) end return Vector2.new(a.X * b.X, a.Y * b.Y) end
Vector2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
Vector2.zero = Vector2.new(0, 0)

Vector3 = {}
Vector3.__type = "Vector3"
Vector3.__index = Vector3
function Vector3.new(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3) end

Color3 = {}
Color3.__type = "Color3"
Color3.__index = Color3
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3) end
function Color3.fromRGB(r, g, b) return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255) end
function Color3.fromHSV(h, s, v)
	local i = math.floor(h * 6); local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	local r, g, b
	if i == 0 then r, g, b = v, t, p elseif i == 1 then r, g, b = q, v, p elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v elseif i == 4 then r, g, b = t, p, v else r, g, b = v, p, q end
	return Color3.new(r, g, b)
end
function Color3:Lerp(o, a) return Color3.new(self.R + (o.R - self.R) * a, self.G + (o.G - self.G) * a, self.B + (o.B - self.B) * a) end
function Color3:ToHSV()
	local r, g, b = self.R, self.G, self.B
	local mx, mn = math.max(r, g, b), math.min(r, g, b)
	local d = mx - mn
	local h = 0
	if d ~= 0 then
		if mx == r then h = ((g - b) / d) % 6 elseif mx == g then h = (b - r) / d + 2 else h = (r - g) / d + 4 end
		h = h / 6
	end
	return h, mx == 0 and 0 or d / mx, mx
end
Color3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end

ColorSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
ColorSequence = { __type = "ColorSequence" }
function ColorSequence.new(a, b)
	local kp
	if typeof and type(a) == "table" and a.R == nil then kp = a
	elseif b then kp = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b) }
	else kp = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, a) } end
	return setmetatable({ Keypoints = kp }, ColorSequence)
end
ColorSequence.__index = ColorSequence
NumberSequenceKeypoint = { new = function(t, v) return { Time = t, Value = v } end }
NumberSequence = { new = function(a, b)
	if type(a) == "table" then return setmetatable({ Keypoints = a, __type = "NumberSequence" }, { __index = {} }) end
	return { Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) }, __type = "NumberSequence" }
end }
NumberRange = { new = function(a, b) return { Min = a, Max = b or a, __type = "NumberRange" } end }
Rect = { new = function(a, b, c, d) return { Min = a, Max = b, __type = "Rect" } end }

TweenInfo = { new = function(t, style, dir, rep, rev, delay) return { Time = t or 1, EasingStyle = style, EasingDirection = dir, __type = "TweenInfo" } end }

Font = { __type = "Font" }
Font.__index = Font
function Font.new(family, weight, style) return setmetatable({ Family = family, Weight = weight, Style = style }, Font) end
function Font.fromEnum(e) return Font.new("rbxasset://fonts/families/" .. tostring(e), nil, nil) end

local enumDefs = {
	AutomaticSize = { "None", "X", "Y", "XY" },
	TextXAlignment = { "Left", "Center", "Right" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	TextTruncate = { "None", "AtEnd" },
	FillDirection = { "Horizontal", "Vertical" },
	HorizontalAlignment = { "Left", "Center", "Right" },
	VerticalAlignment = { "Top", "Center", "Bottom" },
	SortOrder = { "Name", "LayoutOrder", "Custom" },
	ApplyStrokeMode = { "Contextual", "Border" },
	ScaleType = { "Stretch", "Slice", "Tile", "Fit", "Crop" },
	EasingStyle = { "Linear", "Sine", "Back", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Cubic" },
	EasingDirection = { "In", "Out", "InOut" },
	FontWeight = { "Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Heavy" },
	FontStyle = { "Normal", "Italic" },
	Font = { "Code", "Gotham", "GothamMedium", "GothamBold", "GothamSemibold", "SourceSans", "Arial", "RobotoMono" },
	UserInputType = { "MouseButton1", "MouseButton2", "MouseMovement", "MouseWheel", "Touch", "Keyboard", "Focus" },
	UserInputState = { "Begin", "Change", "End", "Cancel", "None" },
	KeyCode = { "Unknown", "K", "P", "F", "F2", "LeftControl", "RightControl", "LeftShift", "Return", "Escape", "Up", "Down", "Left", "Right", "Backspace", "Tab", "Comma", "Space", "A", "B", "C", "D", "E", "G", "H", "I", "J", "L", "M", "N", "O", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "One", "Two", "Three" },
	ThumbnailType = { "HeadShot", "AvatarBust", "AvatarThumbnail" },
	ThumbnailSize = { "Size48x48", "Size60x60", "Size100x100", "Size150x150", "Size180x180", "Size352x352" },
	ScrollingDirection = { "X", "Y", "XY" },
	SizeConstraint = { "RelativeXY", "RelativeXX", "RelativeYY" },
	ZIndexBehavior = { "Global", "Sibling" },
	AspectType = { "FitWithinMaxSize", "ScaleWithParentSize" },
	DominantAxis = { "Width", "Height" },
	BorderMode = { "Outline", "Middle", "Inset" },
	LineJoinMode = { "Round", "Bevel", "Miter" },
	ElasticBehavior = { "WhenScrollable", "Always", "Never" },
	ResamplerMode = { "Default", "Pixelated" },
}
Enum = {}
local enumItemMT = { __tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end }
for typeName, items in pairs(enumDefs) do
	local set = {}
	for i, n in ipairs(items) do set[n] = setmetatable({ Name = n, Value = i - 1, EnumType = typeName, __type = "EnumItem" }, enumItemMT) end
	Enum[typeName] = setmetatable(set, { __index = function(_, k) error("'" .. tostring(k) .. "' is not a valid member of Enum." .. typeName, 2) end })
end
setmetatable(Enum, { __index = function(_, k) error("'" .. tostring(k) .. "' is not a valid Enum type", 2) end })

local rawtypeof
function typeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt and mt.__type then return mt.__type end
		if v.__type then return v.__type end
		if v.__isInstance then return "Instance" end
		if v.__type == nil and rawget(v, "EnumType") then return "EnumItem" end
	end
	return type(v)
end

----------------------------------------------------------------------
-- Instances
----------------------------------------------------------------------
local classes = {}
local function def(name, parent, props, events)
	classes[name] = { parent = parent, props = props or {}, events = events or {} }
end
local function set(...) local t = {} for _, v in ipairs({ ... }) do t[v] = true end return t end

def("Instance", nil, set("Name", "Parent", "ClassName", "Archivable"), set("ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving", "Destroying", "AncestryChanged", "Changed"))
def("GuiObject", "Instance", set("Active", "AnchorPoint", "AutomaticSize", "BackgroundColor3", "BackgroundTransparency", "BorderColor3", "BorderMode", "BorderSizePixel", "ClipsDescendants", "LayoutOrder", "Position", "Rotation", "Selectable", "Size", "SizeConstraint", "Visible", "ZIndex", "AbsolutePosition", "AbsoluteSize", "AbsoluteRotation", "Interactable", "SelectionOrder"),
	set("InputBegan", "InputEnded", "InputChanged", "MouseEnter", "MouseLeave", "MouseMoved", "MouseWheelForward", "MouseWheelBackward", "SelectionGained", "SelectionLost"))
def("Frame", "GuiObject", set("Style"))
def("CanvasGroup", "GuiObject", set("GroupTransparency", "GroupColor3"))
local textProps = set("Font", "FontFace", "Text", "TextColor3", "TextSize", "TextTransparency", "TextStrokeColor3", "TextStrokeTransparency", "TextWrapped", "TextScaled", "TextXAlignment", "TextYAlignment", "TextTruncate", "RichText", "LineHeight", "MaxVisibleGraphemes", "TextBounds", "TextFits", "ContentText", "LocalizationMatchIdentifier", "AutoLocalize", "TextDirection")
def("TextLabel", "GuiObject", textProps)
def("TextButton", "GuiObject", (function() local t = {} for k in pairs(textProps) do t[k] = true end t.AutoButtonColor = true t.Modal = true t.Style = true t.Selected = true return t end)(), set("MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "MouseButton2Click", "MouseButton2Down", "MouseButton2Up", "Activated"))
def("TextBox", "GuiObject", (function() local t = {} for k in pairs(textProps) do t[k] = true end for _, k in ipairs({ "PlaceholderText", "PlaceholderColor3", "ClearTextOnFocus", "MultiLine", "TextEditable", "CursorPosition", "SelectionStart", "ShowNativeInput" }) do t[k] = true end return t end)(), set("FocusLost", "Focused", "ReturnPressedFromOnScreenKeyboard"))
def("ImageLabel", "GuiObject", set("Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode", "IsLoaded"))
def("ImageButton", "GuiObject", set("Image", "ImageColor3", "ImageTransparency", "ImageRectOffset", "ImageRectSize", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode", "AutoButtonColor", "Modal", "Style", "Selected", "HoverImage", "PressedImage"), set("MouseButton1Click", "MouseButton1Down", "MouseButton1Up", "MouseButton2Click", "Activated"))
def("ScrollingFrame", "GuiObject", set("CanvasSize", "CanvasPosition", "ScrollBarThickness", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollingEnabled", "ScrollingDirection", "AutomaticCanvasSize", "ElasticBehavior", "TopImage", "MidImage", "BottomImage", "VerticalScrollBarInset", "HorizontalScrollBarInset", "VerticalScrollBarPosition", "AbsoluteCanvasSize", "AbsoluteWindowSize"))
def("ScreenGui", "Instance", set("DisplayOrder", "ResetOnSpawn", "IgnoreGuiInset", "ZIndexBehavior", "Enabled"))
def("UICorner", "Instance", set("CornerRadius"))
def("UIStroke", "Instance", set("Color", "Thickness", "Transparency", "ApplyStrokeMode", "LineJoinMode", "Enabled"))
def("UIPadding", "Instance", set("PaddingLeft", "PaddingTop", "PaddingRight", "PaddingBottom"))
def("UIListLayout", "Instance", set("Padding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "Wraps", "AbsoluteContentSize", "AbsoluteWindowSize", "HorizontalFlex", "VerticalFlex", "ItemLineAlignment"))
def("UIGridLayout", "Instance", set("CellSize", "CellPadding", "FillDirection", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "AbsoluteContentSize", "StartCorner", "FillDirectionMaxCells"))
def("UIGradient", "Instance", set("Color", "Transparency", "Rotation", "Offset", "Enabled"))
def("UIScale", "Instance", set("Scale"))
def("UISizeConstraint", "Instance", set("MinSize", "MaxSize"))
def("UIAspectRatioConstraint", "Instance", set("AspectRatio", "AspectType", "DominantAxis"))
def("BoolValue", "Instance", set("Value"))
def("StringValue", "Instance", set("Value"))
def("Folder", "Instance")

local function classChain(name)
	local out = {}
	while name do out[#out + 1] = name name = classes[name] and classes[name].parent end
	return out
end

local function hasProp(cls, key)
	for _, c in ipairs(classChain(cls)) do if classes[c].props[key] then return true end end
	return false
end
local function hasEvent(cls, key)
	for _, c in ipairs(classChain(cls)) do if classes[c].events[key] then return true end end
	return false
end

local defaults = {
	GuiObject = { Visible = true, BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 1, Size = UDim2.new(0, 100, 0, 100), Position = UDim2.new(0, 0, 0, 0), AnchorPoint = Vector2.new(0, 0), ZIndex = 1, LayoutOrder = 0, Rotation = 0, ClipsDescendants = false, Active = false, AutomaticSize = "None" },
	TextLabel = { Text = "Label", TextSize = 14, TextTransparency = 0, TextColor3 = Color3.new(0, 0, 0), TextXAlignment = "Center", TextWrapped = false, RichText = false, TextTruncate = "None" },
	TextButton = { Text = "Button", TextSize = 14, TextTransparency = 0, TextColor3 = Color3.new(0, 0, 0), AutoButtonColor = true, RichText = false },
	TextBox = { Text = "", TextSize = 14, TextTransparency = 0, TextColor3 = Color3.new(0, 0, 0), PlaceholderText = "", ClearTextOnFocus = true, MultiLine = false, TextEditable = true, CursorPosition = -1, RichText = false },
	ImageLabel = { Image = "", ImageTransparency = 0, ImageColor3 = Color3.new(1, 1, 1) },
	ImageButton = { Image = "", ImageTransparency = 0, ImageColor3 = Color3.new(1, 1, 1) },
	ScrollingFrame = { CanvasSize = UDim2.new(0, 0, 2, 0), CanvasPosition = Vector2.new(0, 0), ScrollBarThickness = 12 },
	UICorner = { CornerRadius = UDim.new(0, 8) }, UIStroke = { Thickness = 1, Transparency = 0, Enabled = true, Color = Color3.new(0, 0, 0) },
	UIGradient = { Rotation = 0, Enabled = true, Offset = Vector2.new(0, 0) },
	UIListLayout = { Padding = UDim.new(0, 0), SortOrder = "Name" }, UIScale = { Scale = 1 },
	BoolValue = { Value = false }, StringValue = { Value = "" },
	UIPadding = { PaddingLeft = UDim.new(0, 0), PaddingTop = UDim.new(0, 0), PaddingRight = UDim.new(0, 0), PaddingBottom = UDim.new(0, 0) },
}

local Instance = {}
local InstMT = {}

local function isInstance(v) return type(v) == "table" and rawget(v, "__isInstance") == true end

local function fireChanged(self, key)
	local sigs = rawget(self, "__propSignals")
	if sigs[key] then sigs[key]:Fire() end
	rawget(self, "__events").Changed:Fire(key)
end

local function descendants(self, out)
	for _, c in ipairs(rawget(self, "__children")) do out[#out + 1] = c descendants(c, out) end
	return out
end

local function setParent(self, parent)
	local old = rawget(self, "__parent")
	if old == parent then return end
	if old then
		local ch = rawget(old, "__children")
		for i, c in ipairs(ch) do if c == self then table.remove(ch, i) break end end
		rawget(old, "__events").ChildRemoved:Fire(self)
	end
	rawset(self, "__parent", parent)
	if parent then
		local ch = rawget(parent, "__children")
		ch[#ch + 1] = self
		rawget(parent, "__events").ChildAdded:Fire(self)
		local p = parent
		while p do rawget(p, "__events").DescendantAdded:Fire(self) p = rawget(p, "__parent") end
	end
	rawget(self, "__events").AncestryChanged:Fire(self, parent)
	fireChanged(self, "Parent")
end

local function destroy(self)
	if rawget(self, "__destroyed") then return end
	rawset(self, "__destroyed", true)
	rawget(self, "__events").Destroying:Fire()
	for _, c in ipairs({ unpack(rawget(self, "__children")) }) do destroy(c) end
	setParent(self, nil)
	rawset(self, "__parent", nil)
end

local computeSize

local methods = {}
function methods:Destroy() destroy(self) end
function methods:ClearAllChildren() for _, c in ipairs({ unpack(rawget(self, "__children")) }) do destroy(c) end end
function methods:GetChildren() return { unpack(rawget(self, "__children")) } end
function methods:GetDescendants() return descendants(self, {}) end
function methods:FindFirstChild(name, recursive)
	for _, c in ipairs(rawget(self, "__children")) do if c.Name == name then return c end end
	if recursive then for _, c in ipairs(descendants(self, {})) do if c.Name == name then return c end end end
	return nil
end
function methods:WaitForChild(name) return self:FindFirstChild(name) end
function methods:FindFirstChildOfClass(cls) for _, c in ipairs(rawget(self, "__children")) do if c.ClassName == cls then return c end end end
function methods:FindFirstChildWhichIsA(cls) for _, c in ipairs(rawget(self, "__children")) do if c:IsA(cls) then return c end end end
function methods:IsA(cls) for _, c in ipairs(classChain(self.ClassName)) do if c == cls then return true end end return false end
function methods:IsDescendantOf(anc) local p = rawget(self, "__parent") while p do if p == anc then return true end p = rawget(p, "__parent") end return false end
function methods:SetAttribute(k, v) rawget(self, "__attrs")[k] = v end
function methods:GetAttribute(k) return rawget(self, "__attrs")[k] end
function methods:GetPropertyChangedSignal(key)
	local sigs = rawget(self, "__propSignals")
	sigs[key] = sigs[key] or newSignal()
	return sigs[key]
end
function methods:IsFocused() return rawget(self, "__attrs").__focused == true end
function methods:CaptureFocus()
	rawget(self, "__attrs").__focused = true
	rawget(self, "__events").Focused = rawget(self, "__events").Focused or newSignal()
	rawget(self, "__events").Focused:Fire()
end
function methods:ReleaseFocus(submitted)
	rawget(self, "__attrs").__focused = false
	rawget(self, "__events").FocusLost = rawget(self, "__events").FocusLost or newSignal()
	rawget(self, "__events").FocusLost:Fire(submitted ~= false)
end
function methods:Clone()
	local c = Instance.new(self.ClassName)
	for k, v in pairs(rawget(self, "__props")) do rawget(c, "__props")[k] = v end
	for _, ch in ipairs(rawget(self, "__children")) do methods.Clone(ch).Parent = c end
	return c
end

InstMT.__index = function(self, key)
	if methods[key] then return methods[key] end
	local props = rawget(self, "__props")
	local cls = rawget(self, "__class")
	if key == "ClassName" then return cls end
	if key == "Parent" then return rawget(self, "__parent") end
	if key == "Name" then return props.Name end
	local events = rawget(self, "__events")
	if events[key] then return events[key] end
	if hasEvent(cls, key) then events[key] = newSignal() return events[key] end
	if key == "AbsoluteSize" then return computeSize(self) end
	if key == "AbsolutePosition" then return props.AbsolutePosition or Vector2.new(0, 0) end
	if key == "AbsoluteContentSize" then
		local h, w = 0, 0
		local par = rawget(self, "__parent")
		if par then for _, c in ipairs(rawget(par, "__children")) do if c:IsA("GuiObject") and c.Visible then h = h + c.AbsoluteSize.Y w = math.max(w, c.AbsoluteSize.X) end end end
		return Vector2.new(w, h)
	end
	if key == "TextBounds" then return Vector2.new(#tostring(props.Text or "") * (props.TextSize or 14) * 0.5, (props.TextSize or 14) + 2) end
	if key == "TextFits" then return true end
	if key == "ContentText" then return props.Text end
	for _, c in ipairs(rawget(self, "__children")) do if c.Name == key then return c end end
	if hasProp(cls, key) then
		local v = props[key]
		if v == nil then
			for _, c in ipairs(classChain(cls)) do local d = defaults[c] if d and d[key] ~= nil then v = d[key] break end end
			if type(v) == "string" and enumDefs[key] then v = Enum[key][v] end
		end
		return v
	end
	error(string.format("%s is not a valid member of %s \"%s\"", tostring(key), cls, tostring(props.Name)), 2)
end

InstMT.__newindex = function(self, key, value)
	local cls = rawget(self, "__class")
	if key == "Parent" then
		assert(value == nil or isInstance(value), "Parent must be an Instance")
		setParent(self, value)
		return
	end
	local props = rawget(self, "__props")
	if key == "Name" then props.Name = tostring(value) fireChanged(self, key) return end
	if not hasProp(cls, key) then
		error(string.format("%s is not a valid member of %s \"%s\"", tostring(key), cls, tostring(props.Name)), 2)
	end
	if key == "AbsoluteSize" or key == "AbsolutePosition" or key == "TextBounds" or key == "AbsoluteContentSize" then
		props[key] = value fireChanged(self, key) return
	end
	if value == nil and key ~= "Image" then error(string.format("Unable to assign property %s. %s expected, got nil", key, key), 2) end
	if enumDefs[key] and type(value) == "string" then error("Unable to assign property " .. key .. ". Enum item expected, got string", 2) end
	if (key == "Text" or key == "PlaceholderText" or key == "Image") and type(value) ~= "string" then error("Unable to assign property " .. key .. ". string expected, got " .. type(value), 2) end
	if (key == "TextSize" or key == "BackgroundTransparency" or (key == "Transparency" and cls ~= "UIGradient") or key == "TextTransparency" or key == "ImageTransparency" or key == "Rotation" or key == "Thickness" or key == "ZIndex" or key == "LayoutOrder") and type(value) ~= "number" then
		error("Unable to assign property " .. key .. ". number expected, got " .. typeof(value), 2)
	end
	if (key == "Size" or key == "Position") and typeof(value) ~= "UDim2" then error("Unable to assign property " .. key .. ". UDim2 expected, got " .. typeof(value), 2) end
	if (key == "AnchorPoint") and typeof(value) ~= "Vector2" then error("Unable to assign property AnchorPoint. Vector2 expected, got " .. typeof(value), 2) end
	if (key:match("Color3$") or key == "Color") and key ~= "Color" and typeof(value) ~= "Color3" then error("Unable to assign property " .. key .. ". Color3 expected, got " .. typeof(value), 2) end
	if key == "Color" and cls == "UIStroke" and typeof(value) ~= "Color3" then error("UIStroke.Color expects Color3", 2) end
	if key == "Color" and cls == "UIGradient" and typeof(value) ~= "ColorSequence" then error("UIGradient.Color expects ColorSequence", 2) end
	if (key == "FontFace") and typeof(value) ~= "Font" then error("Unable to assign property FontFace. Font expected, got " .. typeof(value), 2) end
	if (key == "Padding" or key == "CornerRadius" or key:match("^Padding")) and typeof(value) ~= "UDim" then error("Unable to assign property " .. key .. ". UDim expected, got " .. typeof(value), 2) end
	local old = props[key]
	props[key] = value
	if old ~= value then fireChanged(self, key) end
end

InstMT.__tostring = function(self) return rawget(self, "__props").Name end

computeSize = function(self)
	local props = rawget(self, "__props")
	if props.AbsoluteSize then return props.AbsoluteSize end
	local par = rawget(self, "__parent")
	local pw, ph = 400, 300
	if par and isInstance(par) and par:IsA("GuiObject") then local ps = par.AbsoluteSize pw, ph = ps.X, ps.Y end
	local sz = self.Size
	if typeof(sz) ~= "UDim2" then return Vector2.new(0, 0) end
	return Vector2.new(sz.X.Scale * pw + sz.X.Offset, sz.Y.Scale * ph + sz.Y.Offset)
end

function Instance.new(class, parent)
	if not classes[class] or class == "GuiObject" or class == "Instance" then error("Unable to create an Instance of type \"" .. tostring(class) .. "\"", 2) end
	local self = setmetatable({}, InstMT)
	rawset(self, "__isInstance", true)
	rawset(self, "__class", class)
	rawset(self, "__props", { Name = class })
	rawset(self, "__children", {})
	rawset(self, "__attrs", {})
	rawset(self, "__events", { ChildAdded = newSignal(), ChildRemoved = newSignal(), DescendantAdded = newSignal(), DescendantRemoving = newSignal(), Destroying = newSignal(), AncestryChanged = newSignal(), Changed = newSignal() })
	rawset(self, "__propSignals", {})
	if parent then setParent(self, parent) end
	return self
end
_G.Instance = Instance

Mock.isInstance = isInstance

----------------------------------------------------------------------
-- services
----------------------------------------------------------------------
local TweenService = {}
function TweenService:Create(obj, info, goal)
	local tween = { Completed = newSignal(), PlaybackState = "Begin" }
	function tween:Play()
		for k, v in pairs(goal) do obj[k] = v end
		self.PlaybackState = "Completed"
		self.Completed:Fire("Completed")
	end
	function tween:Cancel() end
	function tween:Pause() end
	function tween:Destroy() end
	return tween
end

local UserInputService = {
	InputBegan = newSignal(), InputEnded = newSignal(), InputChanged = newSignal(),
	TouchEnabled = false, KeyboardEnabled = true, MouseLocation = Vector2.new(300, 200),
}
function UserInputService:GetMouseLocation() return self.MouseLocation end
Mock.keysDown = {}
function UserInputService:IsKeyDown(code) return Mock.keysDown[code.Name] == true end
function UserInputService:IsMouseButtonPressed() return false end

local RunService = { Heartbeat = newSignal(), RenderStepped = newSignal(), Stepped = newSignal() }
function RunService:IsStudio() return false end
function RunService:BindToRenderStep() end
function RunService:UnbindFromRenderStep() end

local Players = { LocalPlayer = { Name = "Tester", DisplayName = "Test User", UserId = 1, AccountAge = 1200 }, PlayerAdded = newSignal(), PlayerRemoving = newSignal() }
function Players:GetUserThumbAsync(id) return "rbxthumb://type=AvatarHeadShot&id=" .. tostring(id) .. "&w=150&h=150", true end
function Players:GetPlayers() return { self.LocalPlayer } end

local Stats = { Network = { ServerStatsItem = { ["Data Ping"] = { GetValue = function() return 42.5 end } } } }
function Stats:GetTotalMemoryUsageMb() return 512.4 end
local HttpService = { }
function HttpService:GenerateGUID() return "GUID-" .. tostring(math.random(1e6)) end
local Lighting = {}
local CoreGui = Instance.new("Folder"); CoreGui.Name = "CoreGui"

local services = { TweenService = TweenService, UserInputService = UserInputService, RunService = RunService, Players = Players, Stats = Stats, HttpService = HttpService, Lighting = Lighting, CoreGui = CoreGui, TextService = {}, GuiService = {} }
game = { PlaceId = 1, GameId = 1, JobId = "job-1" }
function game:GetService(name)
	if services[name] then return services[name] end
	error("Mock: service " .. tostring(name) .. " is not implemented", 2)
end
function game:HttpGet() error("HttpGet is not available in the mock", 2) end
workspace = { CurrentCamera = { ViewportSize = Vector2.new(1280, 720) } }

Mock.UserInputService, Mock.RunService, Mock.CoreGui = UserInputService, RunService, CoreGui
def("UISizeConstraint", "Instance", set("MinSize", "MaxSize"))

-- input helpers ---------------------------------------------------
function Mock.input(inputType, x, y, keyCode)
	return { UserInputType = Enum.UserInputType[inputType], Position = Vector3.new(x or 0, y or 0, 0), KeyCode = keyCode and Enum.KeyCode[keyCode] or Enum.KeyCode.Unknown, UserInputState = Enum.UserInputState.Begin }
end
function Mock.click(gui)
	if gui.MouseButton1Click then gui.MouseButton1Click:Fire() end
	if gui.Activated then gui.Activated:Fire() end
end
function Mock.press(gui, x, y)
	local i = Mock.input("MouseButton1", x, y)
	gui.InputBegan:Fire(i)
	return i
end
function Mock.release(gui, x, y)
	local i = Mock.input("MouseButton1", x, y)
	if gui then gui.InputEnded:Fire(i) end
	UserInputService.InputEnded:Fire(i)
end
function Mock.drag(gui, x, y)
	Mock.press(gui, x, y)
end
function Mock.move(x, y)
	UserInputService.InputChanged:Fire(Mock.input("MouseMovement", x, y))
end
function Mock.type(box, text, enter)
	box:CaptureFocus()
end
function Mock.setText(box, text, enter)
	box:CaptureFocus()
	box.Text = text
	box:ReleaseFocus(enter ~= false)
end
function Mock.key(code)
	local i = Mock.input("Keyboard", 0, 0, code)
	UserInputService.InputBegan:Fire(i, false)
	return i
end

-- misc exec-environment globals ------------------------------------
function getgenv() return _G end
function setclipboard(t) Mock.clipboard = t end
function identifyexecutor() return "MockExecutor", "1.0" end
function isfile() return false end
function writefile() end
function readfile() return "" end

return Mock
