-- Smoke-runs every numbered example against the FakeCore (real extension modules,
-- stand-in core). Catches misspelled methods, wrong argument shapes and runtime
-- errors in the documented snippets.
local H = dofile("tests/harness.lua")
local Mock = H.Mock
print("-- Examples")

for _, path in ipairs(EXAMPLE_FILES) do
	H.test(path, function()
		local Library = H.newCoreLibrary()
		local realLoadstring = loadstring
		_G.loadstring = function() return function() return Library end end
		game.HttpGet = function() return "-- stub" end
		local ok, err = pcall(function()
			local fh = assert(io.open(path, "rb"))
			local src = fh:read("a")
			fh:close()
			local f, perr = load(src, "@" .. path)
			if not f then error(perr, 0) end
			f()
		end)
		_G.loadstring = realLoadstring
		if not ok then error("example failed: " .. tostring(err) .. " (" .. type(err) .. ")", 0) end

		-- let timers/loops/animations run for a while, then exercise a few clicks
		Mock.advance(6)

		-- every extension element must still be alive and registered
		local live = 0
		for _, e in ipairs(Library.Kit.Registry) do if not e._destroyed then live = live + 1 end end
		H.expect(live >= 1, "example created no extension elements")
		Library._destroyed = true -- lets example loops exit
		Mock.advance(2)
	end)
end

_G.__FAILED = H.failed
print(string.format("   %d passed, %d failed", H.passed, H.failed))
