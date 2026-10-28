# Contributing

Thanks for helping improve Exter Library.

## Setup

```bash
pip install lupa
python tests/run.py          # must stay green
python tests/syntax_check.py # portable-syntax check
```

## Guidelines

- **New elements** go in `src/elements/` (or `src/systems/` for things that float above the window). Use `Kit.Register`; see [docs/EXTENDING.md](docs/EXTENDING.md).
- **Keep modules portable Lua.** No `+=`, `continue` or type annotations inside `src/` so the checker and tests can run them outside Roblox. The core file (`ExterLibrary.lua`) is Luau.
- **Add a test** for every element or behavior change. The mock is strict, so property-name typos are caught.
- **Document it**: add the element to [docs/ELEMENTS.md](docs/ELEMENTS.md) and, if it is user facing, to the README catalog.
- **Don't edit core element code** unless you are fixing a bug in it; extend instead.
- **No secrets in config.** Anything sensitive must default to `IgnoreConfig = true`.
- Keep UI text plain (no emoji) so it renders in every font.

## Pull requests

Describe what changed and how you checked it. If you changed visuals, say what you looked at in game, since the automated tests do not render pixels.
