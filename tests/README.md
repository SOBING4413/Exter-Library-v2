# Tests

The extension logic runs headless against a strict Roblox API mock, using the Lua runtime from the `lupa` package.

```bash
pip install lupa
python tests/run.py              # every suite
python tests/run.py input layout # only suites whose file name contains one of these words
python tests/syntax_check.py     # parse every module with a real Lua parser
```

| Suite | Covers |
|---|---|
| `suite_kit.lua` | Style sampling (including lazy), number helpers, signals, registration, element lifecycle, config parsers, drag and hold-repeat |
| `suite_display.lua` | Every display element |
| `suite_input.lua` | Every input element |
| `suite_layout.lua` | Accordion, SubTabs, hosting core elements, nesting |
| `suite_overlay.lua` | Tooltips, dialogs, Confirm, Prompt, watermark, command palette |
| `suite_loader.lua` | The real loader text from `ExterLibrary.lua`: order, partial failure, missing Kit, opt-out flag |
| `suite_config.lua` | Save and restore round-trip for every persistable element |
| `suite_examples.lua` | Runs each `examples/0*.lua` against a stand-in core for six virtual seconds |

## How the mock helps

- Unknown properties, events and enum items **throw**, like Roblox.
- Basic property types are checked (UDim2, Color3, number, string, Font, ...).
- Time is virtual: `Mock.advance(seconds)` runs `task.delay`, `task.wait` loops and tween completions deterministically.
- Helpers simulate input: `Mock.click`, `Mock.press`, `Mock.move`, `Mock.release`, `Mock.key`, `Mock.setText`.

## What it cannot tell you

Rendering. Spacing, fonts and how the sampled style looks against the real window template can only be judged in Roblox. Likewise the real `ExterLibrary.lua` needs the Roblox asset template, so it is covered by extracting and running the loader rather than by running the whole file.
