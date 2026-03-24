# FastCraft PvP - Studio Setup

Before the game runs, create these instances in Roblox Studio. Rojo syncs scripts only; maps, UI layout, and RemoteEvents are managed in Studio.

## Required Instances

### ReplicatedStorage

Create a folder named **Remotes** with these RemoteEvents:

| RemoteEvent     | Direction       | Purpose                    |
|-----------------|-----------------|----------------------------|
| RequestPickup   | Client → Server | Player picks up a part     |
| InventoryUpdate | Server → Client | Server pushes inventory    |
| RequestCraft    | Client → Server | Player crafts an item      |
| RequestEquip    | Client → Server | Player equips an item      |
| RequestAttack   | Client → Server | Player attacks             |
| RequestMine     | Client → Server | Player mines ore node      |
| RequestChop      | Client → Server | Player chops tree (Phase 3) |
| RequestConsume   | Client → Server | Player consumes food/potion |
| RequestShoot     | Client → Server | Player shoots gun          |
| RequestReload   | Client → Server | Player reloads gun         |
| RequestOffhandUse | Client → Server | Player uses offhand (F)  |
| RequestThrow    | Client → Server | Player throws item (Q)     |
| RequestEquipArmor | Client → Server | Player equips armor slot  |
| RequestVoteMap   | Client → Server | Player votes for map       |
| RequestVoteMode  | Client → Server | Player votes for mode      |
| StaminaUpdate   | Server → Client | Server pushes stamina      |
| StatusEffectUpdate | Server → Client | Server pushes buffs     |
| OffhandUsed     | Server → Client | Offhand effect activated   |
| VotingUpdate    | Server → Client | Map/mode vote state         |
| RoundStateUpdate | Server → Client | Round state, mode, timeLeft |
| WinnerNotification | Server → Client | Winner name/team at round end |

### Workspace

Create a folder named **Pickups**. Add parts whose names match `ItemDefs.Pickups`:
- **RockPickup**
- **WoodPickup** (Phase 2)

Create a folder named **Ores**. Add ore node parts (basic Parts are fine):
- **StoneOreNode**, **CopperOreNode**, **IronOreNode**, **GoldOreNode**
- **SapphireOreNode**, **EmeraldOreNode**, **RubyOreNode**, **DiamondOreNode** (see MiningDefs for stats)

Create a folder named **Trees**. Add tree parts:
- **OakTree**, **AppleTree**, **OrangeTree** (see ChoppingDefs)

Create a folder named **Mobs**. Add Model instances (with Humanoid + HumanoidRootPart):
- **Cow**, **Pig**, **Zombie**, **Spider**, **Angel**, **Demon**, **Soldier** (name = model name, see MobDefs)

Create folders for hazards:
- **Lava** – Parts that deal DoT when touched
- **Void** – Parts that cause instant death when touched

### ServerStorage

Create a folder **Maps** with 4 map Models. Each map must have:
- **SpawnPoints** (Folder): **FFA**, **Team1**, **Team2** (each Folder of Parts for spawn positions)
- **Center** (Part): storm target
- **PotionSpawnPoints** (Folder of Parts)
- **StormMaxRadius** (REQUIRED for SL_*): Set via `ActiveMap:SetAttribute("StormMaxRadius", number)` or child Part named "StormRadius" with `Radius` attribute or Size.X

### ServerStorage (continued)

Create a Tool named **StoneSwordTool** with:

- **Handle** (BasePart) – required for melee hit detection
- **ToolScript** (LocalScript) – fires `RequestAttack` when the tool is activated (player clicks while holding it)

Example ToolScript (place inside StoneSwordTool):

```lua
local tool = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestAttack = remotes:WaitForChild("RequestAttack")

tool.Activated:Connect(function()
	requestAttack:FireServer()
end)
```

This Tool is cloned into the player's Backpack when they equip StoneSword.

**All tools** (each needs a **Handle** BasePart; weapons need LocalScript for `RequestAttack`, guns for `RequestShoot`):
- Pickaxes: WoodPickaxeTool, StonePickaxeTool, CopperPickaxeTool, IronPickaxeTool, GoldPickaxeTool, etc.
- Swords/Spears: StoneSwordTool, CopperSwordTool, IronSwordTool, etc. (LocalScript: `RequestAttack`)
- Axes: WoodAxeTool, StoneAxeTool, etc. (ChoppingClient handles clicks)
- Guns: PistolTool, RifleTool, SniperTool (each needs **Muzzle** or Handle for raycast origin; LocalScript: `RequestShoot`)
- Misc: TorchTool, ShieldTool, BucketTool

### StarterGui

Create **InventoryGui** (ScreenGui) with:

- **InventoryText** (TextLabel) – displays inventory contents
- **CraftStoneSwordButton** (TextButton)
- **EquipStoneSwordButton** (TextButton)
- **InventoryUI** (LocalScript)
- **Phase 2 (optional):** **CraftWoodPickaxeButton**, **CraftStonePickaxeButton**, **CraftIronPickaxeButton**, **CraftIronSwordButton**, **EquipIronSwordButton**, etc. Wire these in InventoryUI to fire `RequestCraft` / `RequestEquip` with the appropriate item/recipe name.

#### InventoryUI LocalScript

The LocalScript must:

1. Listen to `InventoryUpdate` on `ReplicatedStorage.Remotes` and update `InventoryText` with the inventory snapshot.
2. On `CraftStoneSwordButton.MouseButton1Click`, fire `RequestCraft:FireServer("StoneSword")`
3. On `EquipStoneSwordButton.MouseButton1Click`, fire `RequestEquip:FireServer("StoneSword")`

Example (place inside InventoryUI LocalScript):

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local inventoryUpdate = remotes:WaitForChild("InventoryUpdate")
local requestCraft = remotes:WaitForChild("RequestCraft")
local requestEquip = remotes:WaitForChild("RequestEquip")

local gui = script.Parent
local inventoryText = gui:WaitForChild("InventoryText")
local craftBtn = gui:WaitForChild("CraftStoneSwordButton")
local equipBtn = gui:WaitForChild("EquipStoneSwordButton")

inventoryUpdate.OnClientEvent:Connect(function(snapshot)
	local parts = {}
	for item, count in pairs(snapshot) do
		table.insert(parts, item .. ": " .. tostring(count))
	end
	inventoryText.Text = table.concat(parts, "\n") or "Empty"
end)

craftBtn.MouseButton1Click:Connect(function()
	requestCraft:FireServer("StoneSword")
end)

equipBtn.MouseButton1Click:Connect(function()
	requestEquip:FireServer("StoneSword")
end)
```

**Phase 2 – InventoryUI additions** (add to the same LocalScript):

```lua
-- Craft and equip pickaxes, IronSword (extend pattern as needed)
-- Example: RequestCraft:FireServer("WoodPickaxe"), RequestEquip:FireServer("WoodPickaxe")
```

---

## Quick Reference

| Location          | Required |
|-------------------|----------|
| ReplicatedStorage | Folder `Remotes` with all RemoteEvents (see table above) |
| Workspace         | `Pickups`, `Ores`, `Trees`, `Mobs`, `Lava`, `Void` folders |
| ServerStorage     | All tool templates (see CraftingRecipes/EquipService) |
| StarterGui        | `InventoryGui` (E toggles via InputHandler) |
