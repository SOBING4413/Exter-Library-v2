-- Config round-trip: every flagged extension element must Save to a JSON-safe value
-- and restore itself exactly through Library._Parsers (what SaveConfig/LoadConfig use).
local H = dofile("tests/harness.lua")
local Mock = H.Mock
print("-- Config persistence")

local function jsonSafe(v, depth)
	depth = depth or 0
	if depth > 4 then return false end
	local t = type(v)
	if t == "number" or t == "string" or t == "boolean" then return true end
	if t == "table" then
		for k, x in pairs(v) do
			if type(k) ~= "number" and type(k) ~= "string" then return false end
			if not jsonSafe(x, depth + 1) then return false end
		end
		return true
	end
	return false
end

H.test("example 03 round-trips through the parsers", function()
	local Library = H.newCoreLibrary()
	_G.loadstring = function() return function() return Library end end
	game.HttpGet = function() return "" end
	local fh = assert(io.open("examples/03_forms_and_inputs.lua", "rb")); local src = fh:read("a"); fh:close()
	assert(load(src, "@example03"))()
	Mock.advance(1)

	local saved, count = {}, 0
	for flag, opt in pairs(Library.Options) do
		local parser = Library._Parsers[opt.Class]
		if parser and not opt.IgnoreConfig then
			local data = parser.Save(flag, opt)
			H.eq(data.type, opt.Class, flag .. ": type tag")
			H.eq(data.flag, flag, flag .. ": flag tag")
			H.expect(jsonSafe(data.value), flag .. ": value is JSON-safe (" .. type(data.value) .. ")")
			saved[flag] = data
			count = count + 1
		end
	end
	H.eq(count, 10, "10 persistable elements (Token is ignored on purpose)")
	H.expect(Library._Parsers.SecretInput ~= nil and Library.Options.Token.IgnoreConfig == true, "secrets are skipped by default")

	-- mutate a few values, then restore from the snapshot
	Library.Options.TeamSize:Set({ CurrentValue = 9 })
	Library.Options.LevelRange:Set({ CurrentValue = { 1, 2 } })
	Library.Options.Mode:Set({ CurrentOption = "Ranked" })
	Library.Options.Notifications:Set({ CurrentOptions = { "Marketing" } })
	Library.Options.Interests:Set({ Tags = { "x" } })
	Library.Options.Accent:Set({ Selected = 1 })
	Library.Options.Satisfaction:Set({ CurrentValue = 1 })
	Library.Options.About:Set({ CurrentValue = "changed" })
	Library.Options.Maps:Set({ CurrentOptions = { "Alpine" } })
	Library.Options.Region:Set({ CurrentOption = "Asia" })

	for flag, data in pairs(saved) do Library._Parsers[data.type].Load(flag, data) end

	H.eq(Library.Options.TeamSize:GetValue(), 4, "stepper restored")
	local lo, hi = Library.Options.LevelRange:GetValue()
	H.eq(lo, 20, "range min restored"); H.eq(hi, 60, "range max restored")
	H.eq(Library.Options.Mode:GetOption(), "Casual", "segmented restored")
	H.eq(table.concat(Library.Options.Notifications:GetSelected(), ","), "Server updates", "checkboxes restored")
	H.eq(table.concat(Library.Options.Interests:GetTags(), ","), "building,racing", "tags restored")
	H.eq(select(2, Library.Options.Accent:GetColor()), 7, "palette restored")
	H.eq(Library.Options.Satisfaction:GetValue(), 4, "rating restored")
	H.eq(Library.Options.About:GetValue(), "", "text area restored")
	H.eq(Library.Options.Region:GetSelected(), "Europe", "radio restored")
	H.eq(#Library.Options.Maps:GetSelected() == 0 and "none" or "some", "none", "list picker restored (empty)")
end)

_G.__FAILED = H.failed
print(string.format("   %d passed, %d failed", H.passed, H.failed))
