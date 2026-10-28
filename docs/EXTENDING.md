# Writing your own element

An element is a function that builds some `Instance`s inside a container and returns an object.
`Kit.Register` plugs it into every `Tab`, `Section` and container (accordion, sub tab) at once, including ones that already exist.

The complete, runnable version of this guide is [`examples/07_custom_element.lua`](../examples/07_custom_element.lua) (it is part of the automated smoke tests).

## The five steps

```lua
local Kit = Exter.Kit          -- the toolkit the built-in elements use
local P = Kit.Palette

Kit.Register("Counter", function(ctx, settings, flag)
    -- 1. settings with defaults (never mutates the caller's table)
    local s = Kit.Defaults({ Name = "Counter", CurrentValue = 0, Step = 1 }, settings)

    -- 2. chrome: Kit.Card gives the standard rounded, stroked, fading-in surface
    local card = Kit.Card(ctx, { Name = s.Name .. " - Counter", Height = 44 })
    Kit.Pad(card, 12, 0, 8, 0)
    Kit.Text(card, { Name = "Title", Text = s.Name, Weight = Enum.FontWeight.SemiBold, Size = UDim2.new(1, -110, 1, 0) })
    local value = Kit.Text(card, { Name = "Value", TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.new(0, 60, 1, 0), Position = UDim2.new(1, -104, 0, 0) })
    local add = Kit.Button(card, { Text = "+", BackgroundTransparency = 0.2, BackgroundColor3 = P.Track, Size = UDim2.fromOffset(32, 26), Position = UDim2.new(1, -40, 0.5, -13) })
    Kit.Corner(add, 6)

    -- 3. wrap it in the shared element object (flag, Changed, SetDisabled, Destroy, tooltip, ...)
    local el = Kit.Element(ctx, "Counter", card, s, flag)
    el.CurrentValue = s.CurrentValue

    -- 4. public methods; _emit fires the Callback and the Changed signal
    function el:Set(new)
        if new and new.CurrentValue ~= nil then
            el.CurrentValue = new.CurrentValue
            value.Text = tostring(el.CurrentValue)
            el:_emit(el.CurrentValue)
        end
    end
    function el:GetValue() return el.CurrentValue end
    add.MouseButton1Click:Connect(function() el:Set({ CurrentValue = el.CurrentValue + s.Step }) end)

    value.Text = tostring(el.CurrentValue)
    return el
end)

-- 5. optional: make BuildConfigSection save and restore it
Kit.Persist("Counter", function(option) return option.CurrentValue end, function(option, saved) option:Set({ CurrentValue = tonumber(saved) or 0 }) end)

-- use it
local counter = Tab:CreateCounter({ Name = "Clicks", Step = 5, Tooltip = "Adds five" }, "Clicks")
counter:OnChanged(print)
```

## Rules of thumb

- **Parent to `ctx.Frame`.** `Kit.Card` does this for you. Never assume you are directly inside a Tab; you may be in a section, accordion or sub tab.
- **Leave `LayoutOrder` at 0.** Core elements all use 0 and rely on creation order; a higher number would sort your element after everything else.
- **Don't reuse core method names** (`CreateButton`, `CreateToggle`, ...). `Kit.Register` never overwrites an existing method, so a collision silently loses.
- **Use `el:Connect(signal, fn)`** for connections that should die with the element; they are also tracked by the library, so `Library:Destroy()` releases them.
- **Use `Kit.OnTheme` / `Kit.Gradient` / `Kit.AccentColor`** for anything that should follow the theme. They clean up after themselves when the instance is gone.
- **Display-only elements** should set `el.IgnoreConfig = true`.
- **Never store secrets in a persisted element** unless the user opts in.
- **Contain failure.** `_emit` already wraps the callback in `pcall`. Wrap your own risky calls too.

## Kit reference

### Builders
| Function | Description |
|---|---|
| `Kit.new(class, props, children?)` | `Instance.new` with a property table; `Parent` is applied last |
| `Kit.Frame(parent, props)` | Transparent full-size `Frame` |
| `Kit.Text(parent, props)` | `TextLabel` with themed font/color; `Weight = Enum.FontWeight.X` |
| `Kit.Button(parent, props)` | Transparent `TextButton` (no auto color) |
| `Kit.Icon(parent, name, source?, props?)` | `ImageLabel` filled through the library's icon system |
| `Kit.Corner / Stroke / Pad / List` | `UICorner`, `UIStroke`, `UIPadding`, `UIListLayout` helpers |
| `Kit.Card(ctx, opts)` | Element surface. Options: `Name`, `Height`, `Auto` (auto height), `Clip`, `Hover = false`, `Transparency`, `Plain` (no chrome) |
| `Kit.Header(parent, title, description?, opts?)` | Title + optional description stack; returns `holder, titleLabel, descLabel` |

### Style and motion
| Function | Description |
|---|---|
| `Kit.Palette` | `Surface`, `SurfaceAlt`, `SurfaceHi`, `Track`, `Stroke`, `StrokeHover`, `Text`, `TextDim`, `TextMute`, `Success`, `Warning`, `Error`, `Info` |
| `Kit.Style` | Font family, title/description sizes, corner, height, width sampled from the real window template |
| `Kit.Font(weight?)` | `Font` object in the sampled family |
| `Kit.Tween(obj, goal, time?, style?, direction?)` | Honors the library's animation-speed setting |
| `Kit.Accent()` | Current first gradient color |
| `Kit.Gradient(inst, rotation?)` | `UIGradient` bound to the live theme |
| `Kit.AccentColor(inst, property?)` | Keep a property equal to the accent color |
| `Kit.OnTheme(fn)` | Run `fn` now and on every theme change; returns `{ Disconnect }` |

### Input and behavior
| Function | Description |
|---|---|
| `Kit.Drag(handle, onUpdate(x, y), onEnd?)` | Pointer drag with press/move/release handling |
| `Kit.HoldRepeat(button, fn)` | Fire once, then repeat (accelerating) while held |
| `Kit.MakeDraggable(handle, target)` | Move `target` by dragging `handle` |
| `Kit.AttachTooltip(gui, text)` | Hover tooltip; returns `{ SetText, Disconnect }` |
| `Kit.IsPointer(input)` | Mouse button 1 or touch |

### Elements and registration
| Function | Description |
|---|---|
| `Kit.Register(name, builder)` | Adds `Create<Name>` everywhere; `builder(ctx, settings, flag)` |
| `Kit.Extend(obj, ctx)` | Give a custom container object every `Create*` method |
| `Kit.Element(ctx, class, card, settings, flag)` | Shared element object (see [shared API](ELEMENTS.md#shared-api)) |
| `Kit.Persist(class, save, load)` | Config parser: `save(option) -> value`, `load(option, value)` |
| `Kit.Registry` | List of live extension elements |
| `Kit.Signal.new()` | `Connect`, `Once`, `Wait`, `Fire`, `DisconnectAll` |

### Utilities
`Kit.Defaults`, `Kit.Clamp`, `Kit.Snap(value, increment, min)`, `Kit.Decimals`, `Kit.FormatNumber(n, decimals)`, `Kit.Hex`, `Kit.FromHex`, `Kit.HighlightLua`, `Kit.CopyToClipboard`, `Kit.FuzzyScore`, `Kit.Overlay()`.

### The `ctx` object

| Field | Meaning |
|---|---|
| `ctx.Frame` | Where to parent your element |
| `ctx.Tab`, `ctx.Section`, `ctx.Window` | Owning objects (`Section` is `nil` on tab level) |
| `ctx.Kind` | `"Tab"`, `"Section"` or `"Group"` |
| `ctx.RootFrame`, `ctx.RootObject` | Where the original core builders live (used to host core elements in groups) |

## Building a container

A container exposes the same `Create*` methods as a Tab for a custom frame. Give it a context and extend it:

```lua
local group = {}
Kit.Extend(group, { Frame = myFrame, Tab = ctx.Tab, Window = ctx.Window, Kind = "Group", RootFrame = ctx.RootFrame, RootObject = ctx.RootObject })
group:CreateStepper({ Name = "inside my frame" })
```

`src/elements/layout.lua` shows the full pattern, including hosting the original core elements by capturing and re-parenting what they add.

## Testing your element

Add a suite next to the existing ones (`tests/suite_*.lua`). The mock is strict, so a misspelled property fails the test instead of failing in game. See [tests/README.md](../tests/README.md).
