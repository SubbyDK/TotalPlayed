# TotalPlayed (Turtle WoW Addon)

TotalPlayed is a World of Warcraft 1.12 (Turtle WoW) addon that tracks and displays **total /played time across all your characters**, including **quests completed** and **death counter**.  
It provides a clean summary in chat, with names shown in **class colors**, and remembers your display preferences.

---

## ✨ Features

- Tracks `/played` time for all characters across realms and factions.
- Parses Turtle WoW’s extra `/played` output:
  - **Quests completed**
  - **Death counter**
- Displays character names in **class colors**.
- Shows a **total account time** and per‑realm breakdown.
- Sorts characters by total played time.
- Slash command `/totalplayed`:
  - `/totalplayed` → show totals with your saved preference.
  - `/totalplayed 5` → show top 5 characters per realm (saved for next login).
  - `/totalplayed all` → show all characters per realm.
- Automatically prints totals **30 seconds after login**.
- Updates quietly on login/logout without chat spam.

---

## 📦 Installation

1. Download or clone this repository.
2. Place the folder `TotalPlayed` into your WoW `Interface/AddOns` directory.
3. Restart the game and enable **TotalPlayed** in the AddOns menu.

---

## 🔧 Usage

- Type `/totalplayed` in chat to see your totals.
- Add a number to limit how many characters are shown per realm:
  - `/totalplayed 3` → shows top 3 characters per realm.
- Use `/totalplayed all` to reset and show all characters.
- Your preference is saved and remembered across sessions.

---

## 🖼 Example Output

[TotalPlayed] Total account time: 12d 04:22:10 (Top 3 per realm)  
  Realm: TurtleWoW  
  Total time: 8d 02:11:05  
    • WarriorName   | 5d 12:33:44 | Quests: 120 | Deaths: 8  
    • MageName      | 2d 14:55:21 | Quests: 95  | Deaths: 3  
    • PriestName    | 1d 10:42:00 | Quests: 80  | Deaths: 5  

---

## ⚙️ Technical Notes

- Written for **Lua 5.0** (Vanilla WoW 1.12).
- Hooks chat frames to intercept `/played` output and hide default lines.
- Stores all data in `TotalPlayedDB` (SavedVariables).

---

## 📜 License

This addon is released under the MIT License.  
Feel free to fork, modify, and share improvements.
