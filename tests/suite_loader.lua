local H = dofile("tests/harness.lua")
local Mock = H.Mock
print("-- Loader (extracted from ExterLibrary.lua)")

-- Pull the real loader text out of the core and make it plain-Lua compatible
-- (Luau compound assignment is the only non-portable syntax inside it).
local function readAll(p) local f = assert(io.open(p, "rb")) local s = f:read("a") f:close() return s end
local core = readAll("ExterLibrary.lua")
local startAt = core:find("%-%- Extension system", 1)
local snippet = core:sub(startAt)
snippet = snippet:gsub("pending %-= 1", "pending = pending - 1"):gsub("failures %+= 1", "failures = failures + 1")

local function runLoader(Library, root, modules)
	_G.isfile = function(p) local f = io.open(p, "rb") if f then f:close() return true end return false end
	_G.readfile = readAll
	_G.loadstring = function(src, name) return load(src, name) end
	local env = setmetatable({ Sobing = Library, ExterLibrary = Library, __env = {} }, { __index = _G })
	local chunk = assert(load("local Sobing, ExterLibrary, __env = ...\n" .. snippet, "loader", "t", env))
	chunk(Library, Library, env.__env)
	return env
end

H.test("loads every module in order and wires Kit + elements + overlays", function()
	local Library = H.newLibrary()
	Library.Extensions = nil
	runLoader(Library)
	H.expect(Library.Extensions and #Library.Extensions.Modules == 5, "module list defined")
	Library.Extensions.LocalRoot = ""
	H.expect(Library:LoadExtensions(true), "LoadExtensions(force) succeeded")
	H.eq(#Library.Extensions.Loaded >= 5, true, "all modules initialised")
	H.expect(Library.Kit ~= nil, "Library.Kit exposed")
	local Tab = H.newTab(Library, Library.Kit)
	H.expect(type(Tab.CreateProgressBar) == "function" and type(Tab.CreateAccordion) == "function" and type(Tab.CreateStepper) == "function", "elements attached to tabs")
	H.expect(type(Library.Dialog) == "function" and type(Library.CreateWatermark) == "function" and type(Library.EnableCommandPalette) == "function", "overlay API on Library")
	Mock.advance(1)
end)

H.test("a failing module is reported but does not stop the others", function()
	local Library = H.newLibrary()
	runLoader(Library)
	local ext = Library.Extensions
	ext.LocalRoot = ""
	ext.Modules = { "src/Kit.lua", "src/elements/DOES_NOT_EXIST.lua", "src/elements/display.lua" }
	local warned = 0
	local oldWarn = warn
	warn = function() warned = warned + 1 end
	_G.game = setmetatable({ HttpGet = function() error("offline") end }, { __index = game })
	local ok = Library:LoadExtensions(true)
	warn = oldWarn
	H.eq(ok, false, "reports partial failure")
	H.expect(ext.Failed["src/elements/DOES_NOT_EXIST.lua"], "failure recorded")
	H.expect(warned >= 1, "warning emitted")
	local Tab = H.newTab(Library, Library.Kit)
	H.expect(type(Tab.CreateProgressBar) == "function", "later modules still loaded")
	Mock.advance(1)
end)

H.test("missing Kit disables extensions gracefully", function()
	local Library = H.newLibrary()
	runLoader(Library)
	local ext = Library.Extensions
	ext.LocalRoot = ""
	ext.Modules = { "src/NOPE.lua", "src/elements/display.lua" }
	local oldWarn = warn; warn = function() end
	_G.game = setmetatable({ HttpGet = function() error("offline") end }, { __index = game })
	local ok = Library:LoadExtensions(true)
	warn = oldWarn
	H.eq(ok, false, "returns false")
	H.eq(Library.Kit, nil, "no Kit")
	Mock.advance(1)
end)

H.test("getgenv().ExterLibraryNoExtensions skips the loader", function()
	local Library = H.newLibrary()
	local env = { Sobing = Library, ExterLibrary = Library, __env = { ExterLibraryNoExtensions = true } }
	setmetatable(env, { __index = _G })
	local chunk = assert(load("local Sobing, ExterLibrary, __env = ...\n" .. snippet, "loader", "t", env))
	chunk(Library, Library, env.__env)
	H.eq(Library._extensionsLoaded, nil, "nothing ran automatically")
end)

_G.__FAILED = H.failed
print(string.format("   %d passed, %d failed", H.passed, H.failed))
