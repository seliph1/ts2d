# 🎯 TS2D (Tactical-Strike 2D)

[![LÖVE Framework](https://img.shields.io/badge/L%C3%96VE-11.x%20%2F%2012.x-ff0055.svg)](https://love2d.org)
[![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

**TS2D** is a fast-paced, highly customizable, and lightweight 2D top-down shooter inspired by classic tactical top-down games (such as CS2D), built from the ground up using the [LÖVE](https://love2d.org/) framework.

Designed for speed, modularity, and smooth gameplay, TS2D features an in-game map editor, client/server networking, and a refined custom UI system with full keyboard spatial navigation.

---

## ✨ Features

- 🎮 **In-Game Map Editor**: Create, edit, and play custom maps with real-time editing tools.
- 🕹️ **Multiple Game Modes & Spectating**: Play intense tactical matches or spectate live players with dynamic spectator controls.
- 🌐 **Client & Dedicated Server Architecture**: Play locally, host listen servers, or run dedicated headless servers (`--server`).
- ⌨️ **Full Keyboard & Spatial Navigation**: Complete UI keyboard navigation system supporting directional arrows, hotkey activations, state-aware focus highlights, and active tab filtering.
- 🎨 **Enhanced Custom LoveFrames Engine**: Refactored GUI library featuring re-entrancy protection, state-aware visibility (`:OnState()` & `:IsVisible()`), and zero-latency layout updates.
- 🌟 **Lightweight & High Performance**: Optimized rendering and minimal resource footprint, ensuring high FPS on any system.
- 💻 **Cross-Platform**: Runs seamlessly on Windows, Linux, and macOS.

---

## 🎮 Controls & UI Navigation

| Action | Control / Key |
| :--- | :--- |
| **Navigate UI** | Arrow Keys (`Up` / `Down` / `Left` / `Right`) |
| **Activate UI Element** | `Enter` / `Space` |
| **Element Shortcut** | Custom assigned `navActivationKey` |
| **Toggle Console** | `~` (Tilde) |

---

## 🚀 Getting Started

### Prerequisites

Ensure you have [LÖVE (Love2D)](https://love2d.org/) version 11.x or 12.x installed.

### Installation & Running

1. **Clone the repository:**
   ```bash
   git clone https://github.com/seliph1/ts2d.git
   cd ts2d
   ```

2. **Run the Client:**
   ```bash
   love .
   ```

3. **Run Dedicated Server:**
   ```bash
   love . --server
   ```

---

## 🛠️ Project Structure

- `core/`: Core game engine, map engine, client/server networking, input bindings, and user interface.
- `lib/loveframes/`: Custom LoveFrames GUI framework with improved spatial navigation (`utils.lua`) and re-entrant update safety (`base.lua`).
- `gfx/`, `sfx/`, `maps/`: Assets and map data.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
