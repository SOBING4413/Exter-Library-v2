# Element reference

Complete settings, methods and signals for every extension element.
Core elements (`CreateButton`, `CreateToggle`, `CreateSlider`, `CreateDropdown`, `CreateInput`, `CreateColorPicker`, `CreateBind`, `CreateKeybind`, `CreateLabel`, `CreateParagraph`, `CreateSection`, `CreateDivider`) are documented at <http://exter-library.gt.tc/>.

- [Shared API](#shared-api)
- [Display](#display): [ProgressBar](#createprogressbar) · [Stat](#createstat) · [Callout](#createcallout) · [CodeBlock](#createcodeblock) · [DataTable](#createdatatable) · [LiveGraph](#createlivegraph) · [KeyValue](#createkeyvalue) · [ProfileCard](#createprofilecard) · [ImageCard](#createimagecard)
- [Input](#input): [Stepper](#createstepper) · [RangeSlider](#createrangeslider) · [Segmented](#createsegmented) · [CheckboxGroup](#createcheckboxgroup) · [RadioGroup](#createradiogroup) · [TextArea](#createtextarea) · [SecretInput](#createsecretinput) · [Rating](#createrating) · [TagInput](#createtaginput) · [ColorPalette](#createcolorpalette) · [ListPicker](#createlistpicker)
- [Layout](#layout): [Accordion](#createaccordion) · [SubTabs](#createsubtabs)
- [Library-level systems](#library-level-systems): [Dialog](#librarydialog) · [Confirm](#libraryconfirm) · [Prompt](#libraryprompt) · [Watermark](#librarycreatewatermark) · [Command palette](#command-palette) · [Tooltips](#tooltips)

Conventions: `Tab:CreateX(settings, flag?)` also exists on `Section` and on every container. A bare string is accepted as the name: `Tab:CreateProgressBar("Loading")`. Types use Luau notation; `?` means optional.

---

## Shared API

Every extension element returns an object with these members.

### Common settings

| Setting | Type | Description |
|---|---|---|
| `Name` | string | Title shown on the element (also what the command palette searches) |
| `Callback` | function | Called with the element's value(s) when the user (or `:Set`) changes it |
| `Tooltip` | string? | Hover tooltip |
| `Visible` | boolean? | `false` creates it hidden |
| `Disabled` | boolean? | `true` creates it dimmed and non-interactive |

The second argument of every `CreateX` is an optional **flag**. Flagged elements are stored in `Library.Options[flag]` and saved by the config system (see [persistence](#persistence)).

### Common members

| Member | Description |
|---|---|
| `el:Set(table)` | Update settings and/or value; the accepted keys are listed per element |
| `el:OnChanged(fn)` | Subscribe to changes. Returns a connection with `:Disconnect()` |
| `el.Changed` | The underlying signal: `:Connect`, `:Once`, `:Wait`, `:DisconnectAll` |
| `el:SetVisible(bool)` / `el:IsVisible()` | Show or hide |
| `el:SetDisabled(bool)` | Dim and block input; `el.Disabled` reflects the state |
| `el:Flash(color?)` | Briefly highlight the border |
| `el:GetFrame()` | The root `Frame` (for custom styling) |
| `el:Destroy()` | Remove the element, its flag and its connections (idempotent) |
| `el.Class`, `el.Flag`, `el.Settings`, `el.Frame`, `el.Tab`, `el.Section`, `el.Window` | Context fields |
| `el.IgnoreConfig` | When `true` the element is skipped by config saving |

Callback errors are caught: the message is printed with the element name and the element flashes red.

### Persistence

| Class | Saved value | Notes |
|---|---|---|
| `Stepper`, `Rating` | number | |
| `RangeSlider` | `{ min, max }` | |
| `Segmented`, `RadioGroup` | string | |
| `CheckboxGroup`, `TagInput` | list | |
| `ListPicker` | string or list | list when `MultiSelect = true` |
| `ColorPalette` | number | selected index |
| `TextArea` | string | |
| `SecretInput` | string | **`IgnoreConfig = true` by default**; set `el.IgnoreConfig = false` to opt in |
| Display elements | n/a | `IgnoreConfig = true`, never saved |

---

## Display

### CreateProgressBar

Animated bar with gradient fill. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Progress"` | Title |
| `Description` | string? | | Second line under the title |
| `Value` | number | `0` | Initial value |
| `Min`, `Max` | number | `0`, `100` | Range |
| `Suffix` | string | `"%"` | `"%"` shows a percentage; any other suffix shows `value / max suffix` |
| `Decimals` | number | `0` | Decimal places in the label |
| `ShowValue` | boolean | `true` | Show the right-hand label |
| `Indeterminate` | boolean | `false` | Looping bar for unknown progress |
| `Color` | Color3? | theme | Solid color instead of the theme gradient |
| `Format` | function? | | `Format(value, max, alpha) -> string` replaces the label |

Methods: `:SetValue(n)` · `:GetValue()` · `:GetPercent()` · `:Increment(n = 1)` · `:SetIndeterminate(bool)` · `:SetColor(Color3?)` · `:Set{ Name, Description, Value, Min, Max, Suffix, Decimals, ShowValue, Color, Indeterminate }`
Callback / `Changed`: `(value, alpha)`, only when the value actually changes.

```lua
local bar = Tab:CreateProgressBar({ Name = "Download", Description = "assets.pak", Value = 0 })
bar:SetValue(40)
bar:Set({ Name = "Done", Color = Color3.fromRGB(86, 214, 140), Value = 100 })
```

### CreateStat

Metric card with optional icon and trend chip. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Stat"` | Label above the number |
| `Value` | number or string | `0` | Main figure (numbers get thousands separators) |
| `Description` | string? | | Small line below |
| `Trend` | number? | | Shows a chip: green when positive, red when negative |
| `TrendSuffix` | string | `"%"` | Chip suffix |
| `Prefix`, `Suffix` | string | `""` | Around the value, e.g. `"$"` / `" ms"` |
| `Decimals` | number | `0` | |
| `Icon`, `ImageSource` | string | | Icon badge on the left (`"Material"` default) |
| `Color` | Color3? | | Value color |

Methods: `:Set{ Name, Value, Description, Trend, Prefix, Suffix, Decimals, Color }` · `:GetValue()` · `:Count(to, duration = 0.8)` animates the number and fires `Changed(to)` at the end. `Trend = false` hides the chip.

### CreateCallout

Auto-sizing message box.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Type` | `"Info" \| "Success" \| "Warning" \| "Error"` | `"Info"` | Picks color and icon |
| `Title` | string | `"Heads up"` | |
| `Content` | string | `""` | Wrapped text (hidden when empty) |
| `Icon`, `ImageSource` | string? | by type | Override the icon |
| `Color` | Color3? | by type | Override the accent |
| `Dismissible` | boolean | `false` | Adds a close button |
| `RichText` | boolean | `false` | Allow `<b>` style markup in `Content` |

Methods: `:Set{ Title, Content, Type, Color, Icon }` · `:Dismiss()` · signal `el.Dismissed`.

### CreateCodeBlock

Monospace block with built-in Lua syntax highlighting. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Code"` | Header label (falls back to the language) |
| `Code` | string | `""` | Source text; tabs become four spaces |
| `Language` | string | `"lua"` | Header label (highlighting is Lua) |
| `Copy` | boolean | `true` | Show the copy button |
| `MaxHeight` | number | `170` | Scrolls beyond this height |
| `LineNumbers` | boolean | `true` | |
| `TextSize` | number | `13` | |

Methods: `:Set{ Code, Language }` · `:GetCode()` · `:Copy() -> boolean` (uses `setclipboard` / `toclipboard` when the executor provides one, otherwise shows a notification).
`Kit.HighlightLua(code)` returns the RichText string if you want to reuse the highlighter.

### CreateDataTable

Scrollable, optionally sortable table. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Table"` | |
| `Columns` | list | `{ "Column" }` | Strings, or `{ Name, Width = 0..1, Align = "Left" \| "Center" \| "Right" }`; columns without `Width` share the rest equally |
| `Rows` | list of lists | `{}` | Cell values by column position |
| `MaxRows` | number | `6` | Visible rows before scrolling |
| `RowHeight` | number | `28` | |
| `Striped` | boolean | `true` | |
| `Sortable` | boolean | `true` | Click a header to sort; numeric-aware |
| `Callback` | function? | | `Callback(row, index)` when a row is clicked |

Methods: `:SetRows(rows)` · `:AddRow(row)` · `:RemoveRow(index)` · `:Clear()` · `:GetRows()` · `:Sort(columnIndex, ascending = true)` · signal `el.RowSelected(row, index)`.

### CreateLiveGraph

Streaming line graph. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Graph"` | |
| `Samples` | number | `60` | Ring-buffer length (newest on the right) |
| `Min`, `Max` | number? | auto | Fix either bound; a missing bound auto-scales with 10% padding |
| `Suffix`, `Decimals` | string, number | `""`, `0` | Number format in the labels |
| `Height` | number | `120` | Plot height |
| `Color` | Color3? | accent | Line color |
| `Initial` | list? | | Starting data |

Methods: `:Push(value)` · `:SetData(list)` · `:GetData()` · `:Clear()` · `:Set{ Name, Min, Max, Color, Data }`.

### CreateKeyValue

Compact information list. Display only.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Items` | list | `{}` | `{ Key = "FPS", Value = 60, Color? }` or `{ "FPS", 60 }` |
| `RowHeight` | number | `26` | |

Methods: `:SetItems(items)` · `:Set(key, value, color?)` (adds the row when the key is new) · `:GetValue(key)`.

### CreateProfileCard

| Setting | Type | Default | Description |
|---|---|---|---|
| `UserId` | number | local player | Avatar is fetched with `Players:GetUserThumbAsync` |
| `Name`, `Subtitle` | string | display name, `@username` | |
| `Badges` | list | `{}` | Strings or `{ Text, Color }` |
| `Image` | string? | | Use this image instead of the avatar |

Methods: `:Set{ Name, Subtitle, Badges, UserId, Image }`.

### CreateImageCard

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Image"` | |
| `Image` | string | `""` | `rbxassetid://...` |
| `Caption` | string or `false` | name | `false` hides the caption |
| `Height` | number | `140` | |
| `ScaleType` | string | `"Crop"` | Any `Enum.ScaleType` name |
| `Callback` | function? | | Called with no arguments when clicked |

Methods: `:Set{ Image, Caption, Height }`.

---

## Input

### CreateStepper

`[-] value [+]`. Hold the buttons to repeat (accelerates), or click the number and type.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name`, `Description` | string | | |
| `Range` | `{ min, max }` | `{ 0, 100 }` | |
| `Increment` | number | `1` | Values snap to `min + n * Increment`; decimals are supported |
| `CurrentValue` | number | `0` | |
| `Suffix` | string | `""` | Shown when not editing |

Callback: `(value)`. Methods: `:Set{ Name, Description, Range, Increment, Suffix, CurrentValue }` · `:GetValue()`.

### CreateRangeSlider

Two handles; the nearest handle moves and handles never cross.

| Setting | Type | Default |
|---|---|---|
| `Range` | `{ min, max }` | `{ 0, 100 }` |
| `Increment` | number | `1` |
| `CurrentValue` | `{ low, high }` | `{ 25, 75 }` |
| `Suffix` | string | `""` |

Callback: `(min, max)`. Methods: `:Set{ Name, Range, Increment, Suffix, CurrentValue }` · `:GetValue() -> min, max`.

### CreateSegmented

| Setting | Type | Default |
|---|---|---|
| `Options` | list of strings | `{ "One", "Two" }` |
| `CurrentOption` | string? | first option |

Callback: `(option)`. Methods: `:Set{ Name, Options, CurrentOption }` · `:SetOptions(list)` · `:GetOption()`. Unknown options passed to `:Set` are ignored.

### CreateCheckboxGroup

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name`, `Description` | string | | |
| `Options` | list | `{ "A", "B", "C" }` | |
| `CurrentOptions` | list | `{}` | |
| `Min` | number | `0` | Cannot untick below this count |
| `Max` | number? | | Cannot tick above this count |

Callback: `(list)` in option order. Methods: `:Set{ Name, Options, CurrentOptions }` · `:GetSelected() -> list` · `:IsSelected(option)` · `:Clear()`.

### CreateRadioGroup

Same as `CheckboxGroup` with a single `CurrentOption`. Callback: `(option)`. `:GetSelected()` returns the option; re-selecting the current option does not fire the callback.

### CreateTextArea

| Setting | Type | Default | Description |
|---|---|---|---|
| `Name` | string | | |
| `Placeholder` | string | `"Type here..."` | |
| `CurrentValue` | string | `""` | |
| `MaxLength` | number | `0` | `0` = unlimited; input is trimmed |
| `Height` | number | `96` | Box height |
| `ShowCounter` | boolean | `true` | Character counter |
| `RealTime` | boolean | `false` | Fire the callback on every keystroke instead of on focus loss |

Callback: `(text)`. Methods: `:Set{ Name, MaxLength, Placeholder, CurrentValue }` · `:GetValue()`.

### CreateSecretInput

Masked input with a reveal button. The value is committed on focus loss.

| Setting | Type | Default |
|---|---|---|
| `Name`, `Description`, `Placeholder` | string | |
| `CurrentValue` | string | `""` |
| `Reveal` | boolean | `true` (shows the eye button) |
| `Mask` | string | a bullet character |

Callback: `(text)`. Methods: `:Set{ Name, CurrentValue, Reveal }` · `:SetRevealed(bool)` · `:GetValue()`. **Not saved to config by default.** The masking hides text on screen only, it is not encryption.

### CreateRating

| Setting | Type | Default |
|---|---|---|
| `Max` | number | `5` |
| `CurrentValue` | number | `0` |
| `AllowClear` | boolean | `true` (clicking the current star resets to 0) |

Callback: `(value)`. Methods: `:Set{ Name, CurrentValue }` · `:GetValue()`.

### CreateTagInput

Type and press Enter, or type a comma. Blurring the box commits pending text.

| Setting | Type | Default |
|---|---|---|
| `Tags` | list | `{}` |
| `Placeholder` | string | `"Add tag"` |
| `MaxTags` | number? | |
| `AllowDuplicates` | boolean | `false` |

Callback: `(list)`. Methods: `:AddTag(tag) -> boolean` · `:RemoveTag(tag) -> boolean` · `:GetTags()` · `:Clear()` · `:Set{ Name, Tags }`.

### CreateColorPalette

| Setting | Type | Default |
|---|---|---|
| `Colors` | list of Color3 | 10 built-in swatches |
| `Selected` | number | `1` |
| `Size` | number | `26` |

Callback: `(color, index)`. Methods: `:Set{ Name, Colors, Selected, Color }` · `:GetColor() -> color, index`.

### CreateListPicker

Inline list with a search box.

| Setting | Type | Default | Description |
|---|---|---|---|
| `Options` | list | `{}` | |
| `MultiSelect` | boolean | `false` | |
| `Searchable` | boolean | `true` | |
| `Height` | number | `180` | List height |
| `CurrentOption` / `CurrentOptions` | string / list | | |
| `Placeholder` | string | `"Search..."` | |

Callback: `(option)` or `(list)` when `MultiSelect`. Methods: `:Refresh(options)` (keeps still-valid selections) · `:Set{ Name, Options, CurrentOption, CurrentOptions }` · `:GetSelected()` · `:Clear()`.

---

## Layout

Containers return an object that has every `Create*` method, **including the core ones**. Core elements are built by the original library and moved into the group; creation order is preserved.

### CreateAccordion

| Setting | Type | Default |
|---|---|---|
| `Name`, `Description` | string | |
| `Icon`, `ImageSource` | string? | |
| `Open` | boolean | `false` |

Callback: `(isOpen)`. Methods: `:Open()` · `:Close()` · `:Toggle()` · `:IsOpen()` · `:Set{ Name, Description, Open }`. The open height follows the content as elements are added.

### CreateSubTabs

| Setting | Type | Default |
|---|---|---|
| `Tabs` | list of strings | `{ "General", "Advanced" }` |
| `Default` | string? | first tab |

Callback: `(tabName)`. Methods: `:Tab(name) -> container` (creates the page when missing) · `:AddTab(name)` · `:Select(name)` · `:GetSelected()`.

```lua
local pages = Tab:CreateSubTabs({ Tabs = { "Volume", "Devices" } })
pages:Tab("Volume"):CreateSlider({ Name = "Master", Range = { 0, 100 }, Increment = 1, CurrentValue = 80 })
pages:Tab("Devices"):CreateRadioGroup({ Name = "Output", Options = { "Speakers", "Headphones" } })
```

---

## Library-level systems

These float above the window and are called on the library object (`Exter:Dialog(...)`).

### Library:Dialog

```lua
local dialog = Exter:Dialog({
    Title = "Update available", Content = "Version 2.4 is ready.", Type = "Info",
    Buttons = { { Name = "Later" }, { Name = "Update", Primary = true, Callback = function(d) print("go") end } },
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Title`, `Content` | string | | |
| `Type` | `"Info" \| "Success" \| "Warning" \| "Error"` | | Adds an icon and color |
| `Icon`, `ImageSource` | string? | | |
| `Buttons` | list | one `OK` | `{ Name, Primary?, Danger?, Keep?, Callback?(dialog) }`; `Keep = true` leaves the dialog open |
| `Dismissible` | boolean | `true` | Escape key and backdrop click close it |
| `Width` | number | `340` | |
| `Body` | function? | | `Body(frame, dialog)` to add custom content |
| `RichText` | boolean | `false` | For `Content` |

Returns a dialog with `:Close(result?)`, `.Closed` (signal, receives the result: the clicked button name or `nil`), `.IsOpen`, `.Panel`, `.Backdrop`.

### Library:Confirm

`Exter:Confirm({ Title, Content, Confirm = "Confirm", Cancel = "Cancel", Danger = false, Type, Dismissible }, callback?)`

Without `callback` it **yields** and returns `true` / `false`. With a callback it returns the dialog immediately and calls `callback(accepted)` later. Call the blocking form from a thread that may yield (button callbacks are fine).

### Library:Prompt

`Exter:Prompt({ Title, Content, Placeholder, Default, Confirm = "OK", Cancel = "Cancel", Validate, MaxLength, Dismissible }, callback?)`

Returns the entered text, or `nil` when cancelled (or passes it to `callback`). `Validate(text) -> ok, message` keeps the dialog open and shows `message` when `ok == false`. Enter submits.

### Library:CreateWatermark

| Option | Type | Default | Description |
|---|---|---|---|
| `Text` | string | `"{name} \| {fps} fps \| {ping} ms \| {time}"` | Placeholders in braces |
| `Position` | string | `"TopRight"` | `TopLeft`, `TopRight`, `BottomLeft`, `BottomRight`, `TopCenter` |
| `Draggable` | boolean | `true` | |
| `Visible` | boolean | `true` | |
| `Variables` | table | `{}` | `name = value` or `name = function() return string end` |
| `Interval` | number | `0.5` | Refresh period in seconds |

Built-in placeholders: `{fps}`, `{ping}`, `{time}`, `{date}`, `{name}`. Unknown placeholders are left as-is.
Methods: `:SetText(text)` · `:SetVariable(key, valueOrFunction)` · `:SetVisible(bool)` · `:Render()` · `:Destroy()`; `.Frame` is the root.

### Command palette

```lua
Exter:RegisterCommand({ Name = "Toggle HUD", Description = "Show or hide the watermark", Icon = "visibility", Keywords = { "overlay" }, Callback = function() end })
Exter:EnableCommandPalette({ Bind = Enum.KeyCode.P, Modifier = Enum.KeyCode.LeftControl }) -- these are the defaults
```

The palette lists your commands, a **Go to <tab>** entry for every tab, and every extension element that has a `Name` (selecting one activates its tab and flashes it). Search is fuzzy (substring first, then subsequence). Arrow keys navigate, Enter runs, Escape closes.

`RegisterCommand` returns `{ Remove = fn }`. `EnableCommandPalette` returns `{ Disable = fn }`. You can also drive it directly: `:OpenCommandPalette()`, `:CloseCommandPalette()`, `:ToggleCommandPalette()`, `:IsCommandPaletteOpen()`.

### Tooltips

Pass `Tooltip = "text"` on any extension element, or attach one to any GUI object:

```lua
local handle = Exter:AttachTooltip(someGuiObject, "Hello")   -- or a function returning a string
handle:SetText("Updated")
handle:Disconnect()
```
