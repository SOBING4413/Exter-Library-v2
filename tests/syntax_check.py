#!/usr/bin/env python3
"""Syntax-check every .lua file with a real Lua parser (plain Lua subset; Luau-only
syntax such as `+=`, `continue` or type annotations is reported, so new modules stay portable)."""
import sys, pathlib
from lupa import LuaRuntime

lua = LuaRuntime()
check = lua.eval("function(src, name) local f, err = load(src, name); if f then return nil end return err end")

root = pathlib.Path(__file__).resolve().parent.parent
targets = [pathlib.Path(a) for a in sys.argv[1:]] or sorted(p for p in root.rglob("*.lua") if p.name != "ExterLibrary.lua" and "examples/main.lua" not in p.as_posix())
bad = 0
for p in targets:
    err = check(p.read_text(encoding="utf-8"), p.as_posix())
    if err:
        bad += 1
        print("FAIL", err)
    else:
        print("ok  ", p.relative_to(root) if p.is_absolute() and root in p.parents else p)
sys.exit(1 if bad else 0)
