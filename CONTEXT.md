# AI Context & Living Specification — OnePanel_Character

> **Living Document**: This file serves as the primary context, architectural specification, and state-handoff document for AI-assisted development across sessions. Update this file on every development cycle ("spin").

---

## 🎯 Overview & Scope

- **Addon Name**: OnePanel_Character
- **Current Version**: 0.0.2
- **Suite**: Part of the **OneSuite** family (OnePanel Plugin)
- **GitHub Repository**:
  - Exists: TRUE
  - URL: https://github.com/Nuros-WoW-Forever-Addons/OnePanel_Character
  *(For any new addon, initialize with Exists: FALSE until first commit/push)*
- **Branching Policy**: All new features must be developed on a branch != `main` (e.g. `feature/<name>`)
- **Live Sync Path**: `/Applications/World of Warcraft/_classic_beta_/Interface/AddOns/OnePanel_Character/`
- **Rollback Target**: Last working `main` branch commit
- **Release Package**: `.github/workflows/package.yml` generates `OnePanel_Character-latest.zip` on push to `main`
- **Dependencies**: `OnePanel`, `OnePanelUtils`
- **Target WoW Runtimes**: WoW Forever Beta (v1.60.1 / Interface 16001), Vanilla 1.12 (`11200`), WotLK 3.3.5 (`30300`), Modern WoW (`110000+`)
- **Primary Goal**: Deliver a rich, interactive Character Sheet plugin for OnePanel featuring a 3D rotating model, full paperdoll equipment slots, class-aware relic handling, resistance readouts, and collapsible combat stat summaries.

---

## 🏗️ Architecture & Component Map

### File Structure
- `OnePanel_Character.toc`: Manifest, declares dependencies on `OnePanel` and `OnePanelUtils`.
- `Core.lua`: Complete plugin implementation:
  - Equipment slot tables (`EquipmentSlotsLeft`, `EquipmentSlotsRight`, `EquipmentSlotsBottom`).
  - Resistance school indices and icon definitions.
  - 3D Model setup (`PlayerModel` / `DressUpModel`) with mouse rotation scripts.
  - Item stats inspector, slot tooltip binders, durability alerts, and equipment set event listeners.
  - Plugin registration with OnePanel (`OnePanel:RegisterPlugin`).

### Registration Payload with OnePanel
```lua
OnePanel:RegisterPlugin({
    id = "Character",
    name = "Character",
    icon = "Interface\\Icons\\INV_Chest_Chain_05",
    order = 1,
    frame = characterContainer,
    onShow = function() ... end,
    onHide = function() ... end,
})
```

---

## 🔄 AI Development Cycle & Handoff Protocol

When picking up development on this addon:

1. **Orientation**: Read `CONTEXT.md` (this file) to verify current state, known issues, and active backlog items.
2. **Implementation**: Execute changes. For code refactoring or boilerplate, delegate to `qwen2.5-coder:32b` via the local `gx10_ollama` MCP server as mandated by user rules.
3. **Verification**: Verify in-game syntax and test by pressing `C` or running `/op`.
4. **Handoff Update**:
   - Move completed tasks from **Upcoming Backlog** to **Recent Completed Work**.
   - If user-facing features or commands changed, update `README.md` and append a new section in `CHANGELOG.md`.
   - Document newly discovered backlog items or edge cases in **Upcoming Backlog**.

---

## ✅ Recent Completed Work (Latest Spins)

### Spin 0.0.2 (2026-10-12)
- Fixed missing tooltips when mousing over items in the PaperDoll and Equipment Manager frames (`GameTooltip:SetInventoryItem("player", slotId)`).
- Converted equipment slot buttons to `SecureActionButtonTemplate` to support applying enchants and armor kits (e.g. Medium Armor Kit).
- Delegated spell targeting clicks to native Blizzard `Character<Slot>` buttons (`CharacterChestSlot`, etc.) via `clickbutton` attributes to bypass third-party restrictions on `PickupInventoryItem`.
- Resolved silent click failures by explicitly setting `useOnKeyDown` to `false` and mapping `target-item` attributes on slot buttons.

### Spin 0.0.1 (2026-10-10)
- Full 19-slot paperdoll implementation with item link tooltips and rarity borders.
- Class-aware detection for Relic vs. Ranged slots.
- Rotating 3D character model with race-specific background textures.
- Collapsible sidebar for attributes and combat stats.
- Synchronized expand state with `ONEPANEL_EXPAND_STATE_CHANGED` event bus.

---

## 📋 Living Roadmap & Upcoming Backlog (Next Spins)

### Priority 1: High Priority (Immediate Next Spin)
- [ ] **Item Level (ilvl) Overlay**: Display item level badge in the corner of each equipped gear slot.
- [ ] **Enchant & Gem Missing Badges**: Highlight empty gem sockets or missing enchantments on gear pieces.

### Priority 2: Medium Priority (Enhancements)
- [ ] **Average Item Level Header**: Prominently display equipped vs. overall bag item level in the top header.
- [ ] **Equipment Set Quick Switcher**: Add dropdown selector directly above model for 1-click set swapping.

### Priority 3: Low Priority / Exploration
- [ ] **Character Titles Dropdown**: Interactive title selector integrated into character name banner.

---

## 🧪 Testing & Verification Guide

- **Open Panel**: Press `C` — confirm OnePanel opens with Character tab selected and 3D model visible.
- **Model Interaction**: Click and drag across player model — confirm smooth 360-degree rotation.
- **Equip/Unequip**: Swap an item in bags — confirm slot icon, border, and stats update immediately.
- **Drawer Toggle**: Click expand arrow — confirm stats sidebar expands smoothly and OnePanel master frame widens.
- **Item Enchants / Kits**: Use armor kit or enchant scroll in bag, then click equipped slot (e.g. Chest) — confirm enchantment applies cleanly without Lua errors.

---

## ⚠️ Technical Constraints & Engine Gotchas

- **DressUpModel API Variances**: Different WoW engine versions use slightly different model methods (`SetUnit("player")` vs `RefreshUnit()`). Always wrap model initialization in safe compatibility checks.
- **Spell Targeting & Insecure Lua Restrictions**: Applying an enchant or armor kit to an equipped item requires `PickupInventoryItem(slotId)`. Third-party addon code calling `PickupInventoryItem` or `SpellTargetItem` while `SpellCanTargetItem()` is true will trigger `Forbidden function call`. Instead, inherit `SecureActionButtonTemplate` and delegate click to native Blizzard frame (`clickbutton = Character<Slot>Slot`).
- **`useOnKeyDown` on SecureActionButtons**: In modern WoW / Classic Beta clients, the CVar `ActionButtonUseKeyDown` defaults to `true`. Third-party buttons registered for mouse-up (`LeftButtonUp`) will evaluate `clickAction` as `false` and silently fail unless `btn:SetAttribute("useOnKeyDown", false)` is explicitly set.
