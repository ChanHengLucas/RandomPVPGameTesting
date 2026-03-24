--[[
	DropDefs.lua
	Categorizes items for death drop logic.
	STARTER_TOOLS_NEVER_DROP: tools that never drop on death.
	MATERIALS: ores, ingots, ammo, raw - subject to 30% drop in infinite-life.
]]

return {
	STARTER_TOOLS_NEVER_DROP = {
		WoodPickaxeTool = true,
		WoodAxeTool = true,
		WoodSwordTool = true,
	},

	-- Items in MATERIALS category: 30% dropped in infinite-life mode
	MATERIALS = {
		-- Ores
		Stone = true,
		CopperOre = true,
		IronOre = true,
		GoldOre = true,
		SapphireOre = true,
		EmeraldOre = true,
		RubyOre = true,
		DiamondOre = true,
		GodlyOre = true,
		UnholyOre = true,
		Rock = true,
		-- Ingots
		CopperIngot = true,
		IronIngot = true,
		GoldIngot = true,
		SapphireIngot = true,
		EmeraldIngot = true,
		RubyIngot = true,
		DiamondIngot = true,
		GodlyIngot = true,
		UnholyIngot = true,
		-- Ammo
		PistolAmmo = true,
		RifleAmmo = true,
		SniperAmmo = true,
		-- Raw materials
		Wood = true,
		Leather = true,
		RawMeat = true,
		String = true,
		Apple = true,
		Orange = true,
	},
}
