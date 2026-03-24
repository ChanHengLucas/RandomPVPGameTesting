# RandomPvP (FastCraft PvP)

A fast-paced PvP game where players collect resources, craft instantly, and fight. Built with Roblox Luau and Rojo.

## Getting Started

1. **Build and sync** – Rojo syncs scripts to Studio. Use either:

   ```bash
   rojo build -o "RandomPvP.rbxlx"
   ```

   Or run the Rojo server while Studio is open:

   ```bash
   rojo serve
   ```

2. **Studio setup** – Create RemoteEvents, Pickups/Ores folders, tool templates, and InventoryGui in Roblox Studio. See [STUDIO_SETUP.md](STUDIO_SETUP.md).

## Systems

**Core**
- **Inventory** – Server-authoritative per-player item storage
- **Pickups** – Click parts in `workspace.Pickups` to collect resources
- **Crafting** – Recipes for tools, weapons, armor, stations
- **Equip** – Equip tools, guns, armor from inventory
- **Combat** – Melee (sword, spear), guns, godly/unholy affinity

**Gathering**
- **Mining** – Ore nodes (Stone→Diamond, Godly, Unholy)
- **Chopping** – Trees for Wood, fruit (RNG)
- **AutoSmelt** – Ores to ingots automatically (no fuel)
- **AutoConvert** – Raw meat → CookedMeat, fruit → juices

**Conversion & Consumables**
- **AutoSmelt** – Automatic ore→ingot processing
- **AutoConvert** – Food/juice conversions
- **Potions** – World spawn only

**Combat & Effects**
- **Consumables** – Food, juices, potions (HP, stamina)
- **Status effects** – Regen, Heal, Superiority buffs
- **Stamina** – Per-player stamina (sprint in Phase 8)
- **Mobs** – Cows, pigs, zombies, spiders, angels, demons, soldiers (drops)

**Weapons & Tools**
- **Melee** – Swords, spears (all tiers)
- **Guns** – Pistol, Rifle, Sniper (ammo, reload)
- **Tools** – Pickaxes, axes
- **Misc** – Torch, Shield, Bucket, throwing (Q)

**Hazards & Respawn**
- **Hazards** – Lava DoT, Void instant death
- **Respawn** – Starter kit on spawn

For more on Rojo, see [the Rojo documentation](https://rojo.space/docs).