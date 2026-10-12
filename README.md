# OnePanel_Character

**OnePanel_Character** is an enhanced Character Sheet and paperdoll plugin for the **OnePanel** suite, featuring an interactive 3D player model, complete equipment slots, collapsible stats breakdown, resistance badges, and equipment set management.

Part of the **OneSuite** family of addons.

---

## 🚀 Features

- 👤 **Interactive 3D Player Portrait**:
  - Full 3D player character model with authentic Blizzard controls (mouse drag rotation, pan, zoom, and reset).
  - Dynamic race-specific backdrop art and animated lighting.
- 🛡️ **Comprehensive Equipment Layout**:
  - Full 19-slot paperdoll arrangement (Head, Neck, Shoulders, Back, Chest, Shirt, Tabard, Wrists, Hands, Waist, Legs, Feet, Rings, Trinkets, Weapons).
  - Automatic class-aware detection for Relic vs. Ranged weapon slots (Druid, Paladin, Shaman, Death Knight).
  - Dynamic item quality borders, durability tinting, and hover tooltips.
- 🔮 **Spell School Resistance Badges**:
  - Dedicated resistance indicators for Arcane, Fire, Frost, Nature, and Shadow with high-contrast numerical readouts.
- 📊 **Collapsible Stats Sidebar**:
  - Detailed breakdown of Attributes (Strength, Agility, Stamina, Intellect, Spirit).
  - Role-specific combat ratings (Melee, Ranged, Spell, and Defense).
  - Expandable/collapsible drawer syncing smoothly with OnePanel's master frame width.
- 👔 **Equipment Set Management**:
  - Full integration with equipment sets and quick-swapping routines.
  - Auto-updates on `EQUIPMENT_SETS_CHANGED` and `PLAYER_EQUIPMENT_CHANGED`.
- 📑 **Seamless OnePanel Docking**: Automatically registers into OnePanel as the default first tab; accessible instantly via the native `C` keybind or `/op`.

---

## 🛠️ Installation

Copy the `OnePanel_Character` directory (along with `OnePanel` and `OnePanelUtils`) into your World of Warcraft `Interface/AddOns/` directory:

```text
World of Warcraft/Interface/AddOns/OnePanel_Character/
├── OnePanel_Character.toc
├── Core.lua
├── CHANGELOG.md
├── CONTEXT.md
└── README.md
```

Then start or reload World of Warcraft (`/reload`).

---

## 💻 Slash Commands & Access

`OnePanel_Character` docks directly inside the OnePanel master frame:

| Command / Hotkey | Description |
|---|---|
| `C` (Default Keybind) | Open OnePanel directly to the Character tab |
| `/op` or `/onepanel` | Toggle the OnePanel master window |

---

For detailed version history and release notes, see [CHANGELOG.md](CHANGELOG.md).
