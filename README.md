# Exter Library

<div align="center">

**A modern, modular UI library for Roblox: 30+ elements, animated containers, dialogs and a command palette.**

*Created by [Sobing4413](https://github.com/SOBING4413) · Exter Interactive*

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-v2.0-7c6cff.svg)](CHANGELOG.md)
[![Roblox](https://img.shields.io/badge/Platform-Roblox-red.svg)](https://www.roblox.com)
[![Language](https://img.shields.io/badge/Language-Lua%20%2F%20Luau-purple.svg)](ExterLibrary.lua)
[![Tests](https://img.shields.io/badge/Tests-52%20passing-brightgreen.svg)](tests/)
[![Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?logo=discord&logoColor=white)](https://discord.gg/77WnqnJcPu)

[Documentation](http://exter-library.gt.tc/) · [Element reference](docs/ELEMENTS.md) · [Examples](examples/) · [Extending](docs/EXTENDING.md) · [Discord](https://discord.gg/77WnqnJcPu)

</div>

---

## Contents

- [Highlights](#highlights)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Element catalog](#element-catalog)
- [Shared element API](#shared-element-api)
- [Containers](#containers)
- [Dialogs, HUD and command palette](#dialogs-hud-and-command-palette)
- [Flags and config saving](#flags-and-config-saving)
- [Notifications, icons and theme](#notifications-icons-and-theme)
- [Examples](#examples)
- [Architecture](#architecture)
- [Development](#development)
- [Credits](#credits) · [Community](#community) · [License](#license)

## Highlights

| | |
|---|---|
| **30+ elements** | Buttons, toggles, sliders and dropdowns from the core, plus progress bars, stat cards, live graphs, data tables, code blocks, range sliders, steppers, tag inputs, list pickers and more |
| **Containers that host anything** | `Accordion` and `SubTabs` accept the original core elements *and* every new element, and nest freely |
| **System overlays** | `Dialog`, `Confirm`, `Prompt`, a configurable HUD watermark, element tooltips, and a `Ctrl+P` command palette that searches your tabs and settings |
| **One consistent API** | Every new element has the same settings, `:Set`, `:Destroy`, `:SetDisabled`, `:OnChanged` and a `Changed` signal |
| **Theme-aware** | New elements follow the gradient theme live and sample typography and corner radius from the real window template, so they match it |
| **Config-ready** | Flagged elements save and restore through the existing config system; display-only elements and secrets are skipped automatically |
| **Modular and fail-soft** | The core stays one readable file. Elements live in `src/` and load in parallel; if a module is missing the core still works |
| **Tested** | The extension logic ships with 52 automated tests that run against a strict Roblox API mock |

## Installation

One line. The extension modules in `src/` are fetched automatically from the same repository.

```lua
local Exter = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"
))()
```

> **Note:** Make sure `HttpService` is enabled in your game settings if you're testing in Studio.

<details>
<summary><b>Offline, pinned or self-hosted installs</b></summary>

```lua
-- 1) Core elements only: skip the extension modules entirely
getgenv().ExterLibraryNoExtensions = true
local Exter = loadstring(game:HttpGet("https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"))()
```

```lua
-- 2) Local copy: put the repository in workspace/ExterLibrary/ (keep the src/ folder)
getgenv().ExterLibraryNoExtensions = true                      -- stop the automatic remote load
local Exter = loadstring(readfile("ExterLibrary/ExterLibrary.lua"))()
Exter.Extensions.LocalRoot = "ExterLibrary/"                    -- read modules from disk
Exter:LoadExtensions()
```

To fork the library, point `Exter.Extensions.BaseUrl` at your own raw URL. Inspect the result with `Exter.Extensions.Loaded` and `Exter.Extensions.Failed`.
</details>

## Quick start

```lua
local Exter = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/SOBING4413/Exter-Library/main/ExterLibrary.lua"
))()

local Window = Exter:CreateWindow({ Name = "My Script", Subtitle = "Exter " .. Exter.Version })
local Tab = Window:CreateTab({ Name = "Main", Icon = "dashboard", ImageSource = "Material" })

Tab:CreateCallout({ Type = "Info", Title = "Welcome", Content = "Built with Exter Library.", Dismissible = true })

local progress = Tab:CreateProgressBar({ Name = "Loading", Value = 0 })
for i = 1, 100 do progress:SetValue(i) task.wait(0.02) end

Tab:CreateSegmented({
    Name = "Quality", Options = { "Low", "Medium", "High" }, CurrentOption = "Medium",
    Callback = function(option) print("Quality:", option) end,
}, "Quality")

Tab:CreateButton({
    Name = "Reset",
    Callback = function()
        if Exter:Confirm({ Title = "Reset?", Content = "This restores defaults.", Danger = true }) then
            Exter:Notification({ Title = "Done", Content = "Settings restored.", Duration = 3 })
        end
    end,
})
```

`Window` accepts an optional `LogoID` (a numeric Roblox asset id) if you want a custom logo instead of the default one. `Icon` names are only used on tabs and other elements, not on the window itself.

## Element catalog

Every `Tab:CreateX(settings, flag?)` call works the same on a `Section` and inside any container.
The complete settings, methods and signals for each element are in the [element reference](docs/ELEMENTS.md).

### Core elements

| Element | Description |
|---|---|
| `CreateButton` | Clickable button with callback |
| `CreateToggle` | On/off toggle switch |
| `CreateSlider` | Numeric value slider |
| `CreateDropdown` | Selection dropdown menu, with single or multiple selection |
| `CreateInput` | Text input field |
| `CreateColorPicker` | RGB/HSV color picker |
| `CreateBind` / `CreateKeybind` | Keybind capture input |
| `CreateLabel` / `CreateParagraph` | Static text |
| `CreateSection` / `CreateDivider` | Section header and separator |

### Display

| Element | Description |
|---|---|
| `CreateProgressBar` | Animated bar with gradient fill, custom format, indeterminate mode |
| `CreateStat` | Metric card with icon, trend chip and animated `:Count()` |
| `CreateCallout` | Info / Success / Warning / Error box, auto-sizing and dismissible |
| `CreateCodeBlock` | Syntax-highlighted Lua, line numbers, one-click copy |
| `CreateDataTable` | Sortable, scrollable table with striped rows and row callbacks |
| `CreateLiveGraph` | Streaming line graph with auto-scaling (`:Push(value)`) |
| `CreateKeyValue` | Compact information list you update by key |
| `CreateProfileCard` | Avatar thumbnail, name and badges |
| `CreateImageCard` | Image banner with caption and click callback |

### Input

| Element | Description |
|---|---|
| `CreateStepper` | `[-] value [+]` with hold-to-repeat and typed input |
| `CreateRangeSlider` | Two-handle slider returning `min, max` |
| `CreateSegmented` | Animated pill selector |
| `CreateCheckboxGroup` | Multi-select with `Min` / `Max` rules |
| `CreateRadioGroup` | Single choice list |
| `CreateTextArea` | Multi-line input with limit and counter |
| `CreateSecretInput` | Masked input with reveal toggle (never saved by default) |
| `CreateRating` | Star rating |
| `CreateTagInput` | Chip input with comma and Enter handling |
| `CreateColorPalette` | Swatch picker |
| `CreateListPicker` | Inline searchable list, single or multiple |

### Layout

| Element | Description |
|---|---|
| `CreateAccordion` | Animated collapsible group |
| `CreateSubTabs` | Page switcher inside a tab |

### Library-level

| API | Description |
|---|---|
| `Library:Dialog / Confirm / Prompt` | Modal dialogs; `Confirm` and `Prompt` return the answer |
| `Library:CreateWatermark` | Draggable HUD with `{fps}`, `{ping}`, `{time}`, `{name}` and your own variables |
| `Library:AttachTooltip` | Hover tooltip for any GUI object (or `Tooltip = "..."` on elements) |
| `Library:RegisterCommand` / `EnableCommandPalette` | Command palette with fuzzy search |

## Shared element API

All new elements share one base. Details in [docs/ELEMENTS.md](docs/ELEMENTS.md#shared-api).

```lua
local stepper = Tab:CreateStepper({
    Name = "Count", Range = { 0, 10 },
    Tooltip = "Hold the buttons to repeat",   -- hover tooltip
    Visible = true, Disabled = false,
    Callback = function(value) print(value) end,
}, "CountFlag")                               -- optional flag

stepper:Set({ CurrentValue = 4 })
stepper:OnChanged(function(value) print("changed", value) end)  -- subscribe any time
stepper:SetDisabled(true)
stepper:Flash()                                -- draw attention to it
stepper:SetVisible(false)
stepper:Destroy()

Exter.Options.CountFlag:GetValue()             -- reach it by flag from anywhere
```

Callback errors never escape: they are printed with the element name and the element flashes red.

## Containers

`Accordion` and `SubTabs` return containers with the **same Create methods as a Tab**, including the core ones.

```lua
local graphics = Tab:CreateAccordion({ Name = "Graphics", Description = "Quality and effects", Icon = "tune", Open = true })
graphics:CreateToggle({ Name = "VSync", CurrentValue = true })            -- core element, hosted in the group
graphics:CreateStepper({ Name = "Shadow size", Range = { 512, 4096 }, Increment = 512 })

local advanced = graphics:CreateAccordion({ Name = "Advanced" })          -- nesting works
advanced:CreateCallout({ Type = "Warning", Title = "Careful", Content = "Uses more video memory." })

local audio = Tab:CreateSubTabs({ Tabs = { "Volume", "Devices" } })
audio:Tab("Volume"):CreateSlider({ Name = "Master", Range = { 0, 100 }, Increment = 1, CurrentValue = 80 })
audio:Tab("Devices"):CreateRadioGroup({ Name = "Output", Options = { "Speakers", "Headphones" } })
```

## Dialogs, HUD and command palette

```lua
-- Blocking helpers return the answer
local sure = Exter:Confirm({ Title = "Delete save?", Content = "This cannot be undone.", Confirm = "Delete", Danger = true })
local name = Exter:Prompt({ Title = "Rename", MaxLength = 16, Validate = function(t) return #t >= 3, "At least 3 characters" end })

-- Free-form dialog
Exter:Dialog({
    Title = "Update available", Content = "Version 2.4 is ready.", Type = "Info",
    Buttons = { { Name = "Later" }, { Name = "Update", Primary = true, Callback = function() print("updating") end } },
})

-- HUD with live placeholders
local hud = Exter:CreateWatermark({ Text = "{name} | {fps} fps | {ping} ms | {mode}", Position = "TopRight", Variables = { mode = "Standard" } })
hud:SetVariable("mode", "Compact")

-- Command palette: tabs and every named element are searchable out of the box
Exter:RegisterCommand({ Name = "Toggle HUD", Keywords = { "watermark" }, Callback = function() hud:SetVisible(not hud.Frame.Visible) end })
Exter:EnableCommandPalette()   -- Ctrl+P, or { Bind = Enum.KeyCode.K, Modifier = Enum.KeyCode.LeftShift }
```

Pass a function as the second argument of `Confirm` / `Prompt` to stay non-blocking.

## Flags and config saving

Pass a flag as the second argument and the element is registered in `Exter.Options` and saved by `Settings:BuildConfigSection()`.

| Element | Saved value |
|---|---|
| `Stepper`, `Rating` | number |
| `RangeSlider` | `{ min, max }` |
| `Segmented`, `RadioGroup` | option name |
| `CheckboxGroup`, `ListPicker` (multi), `TagInput` | list |
| `ColorPalette` | selected index |
| `TextArea` | text |
| `SecretInput` | **not saved by default** (set `element.IgnoreConfig = false` to opt in) |
| Display elements | never saved |

## Notifications, icons and theme

```lua
Exter:Notification({ Title = "Hello!", Content = "This is a notification.", Duration = 5 })
```

Exter Library includes two built-in icon sets: **Material Icons** (default) and **Lucide**. Use icon names as strings on tabs and elements; add `ImageSource = "Lucide"` for the other set. Browse the full list inside `ExterLibrary.lua`, or refer to the [documentation](http://exter-library.gt.tc/).

The library uses a customizable gradient theme. The default gradient transitions from blue to teal to pink:

```lua
ColorSequence.new{
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(117, 164, 206)),  -- Blue
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(123, 201, 201)),  -- Teal
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(224, 138, 175)),  -- Pink
}
```

Extension elements read the gradient live, so a theme change recolors progress fills, indicators, selected states and graphs immediately.

## Examples

| File | Shows |
|---|---|
| [`01_quickstart.lua`](examples/01_quickstart.lua) | The smallest useful script: callout, progress, segmented, stepper, confirm |
| [`02_dashboard.lua`](examples/02_dashboard.lua) | Live server monitor: stat cards, graphs, data table, HUD |
| [`03_forms_and_inputs.lua`](examples/03_forms_and_inputs.lua) | Every input element, flags, `OnChanged`, config saving |
| [`04_layout_containers.lua`](examples/04_layout_containers.lua) | Accordion and SubTabs hosting core and new elements, nesting |
| [`05_overlays_and_palette.lua`](examples/05_overlays_and_palette.lua) | Dialog, Confirm, Prompt, watermark, tooltips, command palette |
| [`06_full_showcase.lua`](examples/06_full_showcase.lua) | One window with every extension element |
| [`all_elements.lua`](examples/all_elements.lua) / [`basic_example.lua`](examples/basic_example.lua) | Original core-element examples |

All numbered examples are smoke-tested on every change (`tests/suite_examples.lua`).

## Architecture

```
ExterLibrary.lua            core: window, tabs, core elements, themes, config, notifications
│                           + a small internal bridge and a fail-soft module loader
├── src/Kit.lua             shared toolkit: builders, motion, theming, element base class, registry
├── src/elements/
│   ├── display.lua         ProgressBar · Stat · Callout · CodeBlock · DataTable · LiveGraph · KeyValue · ProfileCard · ImageCard
│   ├── input.lua           Stepper · RangeSlider · Segmented · Checkbox/Radio · TextArea · SecretInput · Rating · TagInput · ColorPalette · ListPicker
│   └── layout.lua          Accordion · SubTabs (containers)
└── src/systems/overlay.lua Tooltip · Dialog / Confirm / Prompt · Watermark · Command palette
```

The core is touched in only a handful of places (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)): a version bump, an internal bridge table, one hook each in `CreateTab` and `CreateSection`, config-parser lookups, and the loader. No existing element code was changed.

Want to add your own element? It is about 40 lines: [docs/EXTENDING.md](docs/EXTENDING.md).

## Development

The extension modules are portable Lua and are tested headless with a strict Roblox mock (reading or writing a property that does not exist on a class throws, like Roblox does).

```bash
pip install lupa
python tests/run.py            # all suites (52 tests)
python tests/run.py input      # only suites whose name contains "input"
python tests/syntax_check.py   # portable-syntax check of every module
```

What the tests do and do not cover is described in [tests/README.md](tests/README.md). Contributions are welcome, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

| Role | Name |
|---|---|
| Created By | Sobing4413 |
| Organization | Exter Interactive |
| Icons | [Latte Softworks](https://github.com/latte-soft) (Lucide), qweery (Material) |

## Community

Join the Discord server for support, updates, and to share your scripts:

[![Discord](https://img.shields.io/badge/Discord-Join%20Server-5865F2?logo=discord&logoColor=white&style=for-the-badge)](https://discord.gg/77WnqnJcPu)

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
