# Changelog — OnePanel_Character

All notable changes to **OnePanel_Character** are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.2] - 2026-10-12
### Fixed
- **PaperDoll & Equipment Manager Tooltips**: Restored standard item tooltips when mousing over equipped gear slots across both the main PaperDoll and Equipment Manager frames.
- **Armor Kit & Enchant Application**: Converted paperdoll slot buttons to `SecureActionButtonTemplate` and delegated spell targeting clicks to native Blizzard `Character<Slot>` buttons (`CharacterChestSlot`, etc.) via `clickbutton` attributes, resolving `Forbidden function call: PickupInventoryItem()` errors.
- **Secure Action Mouse-Up Triggering**: Explicitly set `useOnKeyDown` to `false` and mapped `target-item` attributes on slot buttons, ensuring mouse-up clicks properly execute item enchantment targeting when `ActionButtonUseKeyDown` is enabled globally.

## [0.0.1] - 2026-10-10
### Added
- **Interactive 3D Character Model**: Integrated rotating 3D player portrait with race-specific background art.
- **Complete Paperdoll Equipment Matrix**: 19 slots with quality border colors, durability checks, and Relic/Ranged slot handling.
- **Spell School Resistance Matrix**: Displays Arcane, Fire, Frost, Nature, and Shadow resistance values.
- **Collapsible Stats Sidebar**: Detailed attributes, combat ratings, and defensive stats.
- **OnePanel Host Docking**: Direct integration via `OnePanel:RegisterPlugin` as the primary Character Sheet tab.
