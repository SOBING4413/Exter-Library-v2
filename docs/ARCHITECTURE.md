# Architecture

## Goals

1. Add many elements and systems **without growing or destabilising the core file**.
2. Make new elements **match the window** (typography, corners, theme) instead of looking bolted on.
3. Keep everything **fail-soft**: if an extension cannot load, the core library keeps working.
4. Make the extension logic **testable outside Roblox**.

## Layout

```
ExterLibrary.lua             core (window, tabs, core elements, themes, config, notifications)
src/Kit.lua                  toolkit + element base class + registry
src/elements/display.lua     9 display elements
src/elements/input.lua       11 input elements
src/elements/layout.lua      2 containers
src/systems/overlay.lua      tooltips, dialogs, watermark, command palette
tests/                       strict Roblox mock, harness, suites, runner
```

Every module returns a function:

```lua
return function(Library, Kit) ... end      -- elements and systems
return function(Library) ... return Kit end -- Kit.lua
```

## Load sequence

1. `ExterLibrary.lua` runs as before and finishes defining the library.
2. At the end of the file the loader calls `Library:LoadExtensions()` unless `getgenv().ExterLibraryNoExtensions` is set.
3. All module sources are fetched **in parallel** (`task.spawn` per file; local files are used first when `Extensions.LocalRoot` is set). The loader waits up to 12 seconds.
4. Modules are compiled with `loadstring` and executed **in order**: `Kit` first, then each module receives `(Library, Kit)`.
5. If `Kit` fails, extensions are disabled with a warning. If any other module fails, the others still load, the failure is recorded in `Library.Extensions.Failed`, and a warning is printed.

## What changed in the core

The core is touched in a handful of places. No existing element, theme or config code was rewritten.

| Where | Change |
|---|---|
| Top of file | `Release = "v2.0"`; `_Parsers`, `_Tabs` and `Version` added to the library table |
| After `BindTheme` | `Sobing._Internal`: a table exposing `Track`, `BindTheme`, `Kwargify`, `ApplyIcon`, `GetIcon`, `SmoothTweenInfo` and getters for the GUI roots (`GetGui`, `GetElements`, `GetMain`, `GetNavigation`) |
| End of `Window:CreateTab` | Registers the tab in `Library._Tabs`, sets `Tab.Name`, calls `Library._Extend(Tab, ctx)` |
| End of `Tab:CreateSection` | Sets `Section.Tab`, calls `Library._Extend(Section, ctx)` |
| `SaveConfig` / `LoadConfig` | Look up `Library._Parsers[class]` when the built-in parser table has no entry |
| End of file | The extension loader |

UI references are exposed as **getters** because those locals are assigned later (inside `CreateWindow`).

## Registration

`Kit.Register(name, builder)` stores the builder and attaches `Create<name>` to every container that exists, and to every container created later (`Kit.Extend`). A weak table remembers the containers.

Existing methods are never overwritten (`rawget` check), so a core method always wins over an extension with the same name.

## Matching the window: style sampling

The original elements are cloned from a template asset, so their font, text size and corner radius are not in the Lua source. `Kit.RefreshStyle` reads them from `Elements.Template` at runtime (font family from `Button.Title.FontFace`, text size, `UICorner`, height and width). The template only exists after `CreateWindow`, so sampling is **lazy**: it retries on each `Kit.Card` / `Kit.Font` call until it succeeds, then stops. If anything is missing it falls back to defaults, so nothing errors.

Colors use the same values as the core elements (surface `32,30,38`, stroke `64,61,76`, hover stroke `87,84,104`, element transparency `0.5`). Gradients and accents are read live from `Library.ThemeGradient` and rebound on every theme change through one shared `BindTheme` listener.

## Element lifecycle

`Kit.Element` creates the shared object: flag registration, `Changed` signal, `_emit` (callback with error containment), `SetDisabled` (a click-blocking mask), `Flash`, tooltip hookup, and `Destroy`, which disconnects the element's connections, releases the flag, removes it from `Kit.Registry` and destroys the frame. Connections made through `el:Connect` are also tracked by the library, so `Library:Destroy()` releases everything.

## Containers and hosting core elements

Extension elements parent themselves to `ctx.Frame`, so they work in any container.

The original core builders are closures bound to a specific page, so a group cannot ask them to build elsewhere. `makeGroup` (in `layout.lua`) instead:

1. listens to `ChildAdded` on the root page frame,
2. calls the original builder (`root:CreateToggle(...)`),
3. re-parents whatever instances it added into the group frame,
4. returns the builder's result untouched.

This works because the builders add their frames synchronously. The hover brightening the core attaches to direct page children is applied by the core before the move (it hooks `ChildAdded` on the page), so moved elements keep it.

Limitations: a `Section` has no `CreateKeybind` (it never had), so a group inside a section reports a clear error for it; core elements keep the width rules of their template.

## Overlay systems

`Kit.Overlay()` lazily creates one full-screen, click-through `Frame` above the window inside the library's ScreenGui. Dialogs and the palette add a click-blocking backdrop; tooltips and the watermark live on the base layer. `Confirm` and `Prompt` yield by waiting on the dialog's `Closed` signal.

The command palette collects commands at open time from three sources: `RegisterCommand`, `Library._Tabs` and `Kit.Registry`. Selecting an element result activates its tab and flashes the element.

## Persistence

`Kit.Persist(class, save, load)` fills `Library._Parsers[class]`. The core's config code asks the built-in `ClassParser` first, then `_Parsers`. Saved values are plain numbers, strings, booleans or lists so they survive `JSONEncode`. Display elements and `SecretInput` set `IgnoreConfig`.

## Testing strategy

`tests/mock_roblox.lua` implements the slice of the Roblox API the modules use (instances, signals, tweens, input, a virtual-time scheduler). It is **strict**: reading or writing a property that does not exist on a class throws, enum items must exist, and basic value types are checked. `tests/harness.lua` provides a fake core (`H.newCoreLibrary`) that performs the same `_Extend` calls as the patched core, so examples run end to end.

Suites cover the Kit, each module, the loader (the real loader text is extracted from `ExterLibrary.lua` and executed), config round-trips, and a smoke run of every numbered example.

**What is not covered:** pixel-level rendering inside Roblox (spacing, fonts, how the sampled style looks against your template), the real `ExterLibrary.lua` executing end to end (it needs the Roblox asset template), and executor-specific functions such as `setclipboard`. Treat the first in-game run as the visual review and report anything that looks off.
