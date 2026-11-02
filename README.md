# acq hub

Centralized, universal Roblox Script Hub architecture featuring automatic game detection, one loadstring entry point, and modular game script structure.

---

## 🚀 Quick Start (Single Loadstring)

Execute the universal loader below in your executor. The loader automatically detects the current game via `PlaceId` / `UniverseId` and loads the appropriate dedicated script.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/<OWNER>/acq-hub/main/loader.lua"))()
```

---

## 📁 Repository Structure

```
acq-hub/
│
├── loader.lua              # Central universal loader & game dispatcher
│
├── games/                  # Dedicated game modules (1 per game)
│   ├── fortune_fighters.lua # PlaceId: 16212191055
│   └── ...                 # Future game scripts
│
├── libraries/              # Shared libraries & utilities
│   ├── shared.lua          # Cleanup manager, character & task helpers
│   └── ...
│
└── README.md               # Project documentation & changelog
```

---

## 🎮 Supported Games

| Game | PlaceId | Status | Script File |
| :--- | :--- | :--- | :--- |
| **Fortune Fighters** | `16212191055` | 🟡 Setup in progress | [`games/fortune_fighters.lua`](games/fortune_fighters.lua) |

---

## ⚙️ How It Works

1. **Detection**: `loader.lua` checks `game.PlaceId` and `game.GameId`.
2. **Lookup**: Checks against the internal manifest of supported games.
3. **Fetching**: Fetches raw Lua code from the centralized GitHub repository via `game:HttpGet`.
4. **Execution**: Safely executes the game script with error boundaries.
5. **Teardown**: Scripts use a shared cleaner to unbind connections, loops, and drawing instances when reloading.

---

## 📝 Changelog

- **v1.0.0**: Initial release of the central loader and repository architecture.
