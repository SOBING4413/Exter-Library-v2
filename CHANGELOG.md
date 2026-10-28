# Changelog

## v2.0

### Added
- **Extension system.** Elements and systems live in `src/` and are loaded in parallel at startup; fail-soft, with `ExterLibraryNoExtensions`, `Extensions.LocalRoot` and `Extensions.BaseUrl` controls.
- **Display elements:** `CreateProgressBar`, `CreateStat`, `CreateCallout`, `CreateCodeBlock` (Lua syntax highlighting), `CreateDataTable`, `CreateLiveGraph`, `CreateKeyValue`, `CreateProfileCard`, `CreateImageCard`.
- **Input elements:** `CreateStepper`, `CreateRangeSlider`, `CreateSegmented`, `CreateCheckboxGroup`, `CreateRadioGroup`, `CreateTextArea`, `CreateSecretInput`, `CreateRating`, `CreateTagInput`, `CreateColorPalette`, `CreateListPicker`.
- **Containers:** `CreateAccordion` and `CreateSubTabs`, which host core and extension elements and nest.
- **Systems:** `Library:Dialog`, `Library:Confirm`, `Library:Prompt`, `Library:CreateWatermark`, `Library:AttachTooltip` (and `Tooltip =` on elements), command palette (`RegisterCommand`, `EnableCommandPalette`, ...).
- **Shared element API:** `:Set`, `:OnChanged`, `Changed` signal, `:SetVisible`, `:SetDisabled`, `:Flash`, `:Destroy`.
- **Config:** extension elements save and restore through `Library._Parsers`; secrets and display elements are skipped.
- **Tooling:** strict Roblox mock, 52 automated tests, portable-syntax checker, runnable examples `01` to `07`.
- **Docs:** rewritten README, element reference, extension guide, architecture notes.

### Changed (core)
- Version bump, `Library.Version`, `Library._Internal` bridge, extension hooks at the end of `CreateTab` and `CreateSection`, and parser lookups in `SaveConfig` / `LoadConfig`. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#what-changed-in-the-core).

## v1.3.0

Previous release (core library).
