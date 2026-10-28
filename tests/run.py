#!/usr/bin/env python3
"""Run the Lua test-suite (tests/suite_*.lua) inside a Lua VM with the Roblox mock."""
import sys, pathlib
from lupa import LuaRuntime

root = pathlib.Path(__file__).resolve().parent.parent
lua = LuaRuntime()
lua.execute(f'package.path = "{root.as_posix()}/?.lua;" .. package.path')
only = sys.argv[1:]
lua.globals().EXAMPLE_FILES = lua.table_from([p.relative_to(root).as_posix() for p in sorted((root / "examples").glob("0*.lua"))])
suites = sorted((root / "tests").glob("suite_*.lua"))
if only:
    suites = [s for s in suites if any(o in s.name for o in only)]
import os
os.chdir(root)
failed = 0
for s in suites:
    print(f"== {s.name}")
    lua.execute("package.loaded['tests.mock_roblox'] = nil")
    try:
        lua.execute(f'dofile("tests/{s.name}")')
        failed += int(lua.eval("(_G.__FAILED or 0)"))
    except Exception as e:
        failed += 1
        print("SUITE ERROR:", str(e)[:1500])
print("\nRESULT:", "FAILED" if failed else "all suites passed")
sys.exit(1 if failed else 0)
