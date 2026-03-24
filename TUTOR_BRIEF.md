# RandomPvP – Studio Setup Brief for Tutor/Contractor

## Context

Roblox Luau + Rojo game. Codebase is implemented and syncing. The game does not run until Studio instances are created manually (Rojo syncs scripts only).

## Goal

Get the game playable with **one minimal test map** so we can test: round flow, spawning, voting, mining, chopping, auto-smelt, auto-convert, consumables, storm, and basic combat.

## Deliverables (in order)

1. **ReplicatedStorage.Remotes** – Create a Folder, add 21 RemoteEvents (14 client→server, 7 server→client). See full plan for exact names.

2. **ServerStorage** – Add 3 Tool templates as direct children: `WoodPickaxeTool`, `WoodAxeTool`, `WoodSwordTool`. Each needs a Handle (BasePart). WoodSwordTool needs a LocalScript that fires `RequestAttack` on Activated.

3. **ServerStorage.Maps.ForestArena** – One Model with: SpawnPoints (FFA, Team1, Team2 folders, each with ≥1 Part), Center (Part), PotionSpawnPoints (Folder with ≥1 Part), and `StormMaxRadius` attribute (e.g. 200) on the Model.

4. **Workspace** – Create Folders: `Pickups`, `Ores`, `Trees`. Add a few Parts as direct children of Ores and Trees (named e.g. OreNode, OakTree). Pickups can stay empty initially.

5. **StarterGui.InventoryGui** – ScreenGui with InventoryText (TextLabel), CraftStoneSwordButton, EquipStoneSwordButton, and InventoryUI (LocalScript) wired to InventoryUpdate, RequestCraft, RequestEquip.

## Reference

- Full step-by-step plan: `.cursor/plans/` or ask the client for the detailed Studio setup checklist.
- Codebase layout: `src/` – ServerScriptService, ReplicatedStorage, StarterPlayer, ServerStorage.Maps.
- Existing docs: `STUDIO_SETUP.md` in project root.

## Outcome

After setup: Play → Lobby → Voting → Intermission → spawn on map → mine ores, chop trees, craft, equip, fight. Storm works in SL_FFA/SL_TDM modes.
