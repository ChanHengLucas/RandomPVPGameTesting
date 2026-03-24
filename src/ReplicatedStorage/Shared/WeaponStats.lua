--[[
	WeaponStats.lua
	Single source of truth for weapon stats.
	Map ToolName -> { damage, range, cooldown, pierce?, affinity? }
	affinity: "godly" | "unholy" for Angelic/Demonic multiplier
	pierce: 0..1, reduces effective armor DR
]]

return {
	-- Swords (cooldown 0.55s)
	WoodSwordTool = { damage = 14, range = 8, cooldown = 0.55 },
	StoneSwordTool = { damage = 18, range = 8, cooldown = 0.55 },
	CopperSwordTool = { damage = 22, range = 8, cooldown = 0.55 },
	IronSwordTool = { damage = 28, range = 8, cooldown = 0.55 },
	GoldSwordTool = { damage = 32, range = 8, cooldown = 0.55 },
	SapphireSwordTool = { damage = 34, range = 8, cooldown = 0.55 },
	EmeraldSwordTool = { damage = 36, range = 8, cooldown = 0.55 },
	RubySwordTool = { damage = 38, range = 8, cooldown = 0.55 },
	DiamondSwordTool = { damage = 40, range = 8, cooldown = 0.55 },
	GodlySwordTool = { damage = 46, range = 8, cooldown = 0.55, affinity = "godly" },
	UnholySwordTool = { damage = 46, range = 8, cooldown = 0.55, affinity = "unholy" },

	-- Spears (cooldown 0.45s, 30% pierce)
	WoodSpearTool = { damage = 10, range = 12, cooldown = 0.45, pierce = 0.30 },
	StoneSpearTool = { damage = 13, range = 12, cooldown = 0.45, pierce = 0.30 },
	CopperSpearTool = { damage = 16, range = 12, cooldown = 0.45, pierce = 0.30 },
	IronSpearTool = { damage = 20, range = 12, cooldown = 0.45, pierce = 0.30 },
	GoldSpearTool = { damage = 23, range = 12, cooldown = 0.45, pierce = 0.30 },
	SapphireSpearTool = { damage = 24, range = 12, cooldown = 0.45, pierce = 0.30 },
	EmeraldSpearTool = { damage = 25, range = 12, cooldown = 0.45, pierce = 0.30 },
	RubySpearTool = { damage = 26, range = 12, cooldown = 0.45, pierce = 0.30 },
	DiamondSpearTool = { damage = 28, range = 12, cooldown = 0.45, pierce = 0.30 },
	GodlySpearTool = { damage = 34, range = 12, cooldown = 0.45, pierce = 0.30, affinity = "godly" },
	UnholySpearTool = { damage = 34, range = 12, cooldown = 0.45, pierce = 0.30, affinity = "unholy" },

	-- Axes (cooldown 0.75s, 10% pierce)
	WoodAxeTool = { damage = 18, range = 8, cooldown = 0.75, pierce = 0.10 },
	StoneAxeTool = { damage = 24, range = 8, cooldown = 0.75, pierce = 0.10 },
	CopperAxeTool = { damage = 28, range = 8, cooldown = 0.75, pierce = 0.10 },
	IronAxeTool = { damage = 34, range = 8, cooldown = 0.75, pierce = 0.10 },
	GoldAxeTool = { damage = 38, range = 8, cooldown = 0.75, pierce = 0.10 },
	SapphireAxeTool = { damage = 40, range = 8, cooldown = 0.75, pierce = 0.10 },
	EmeraldAxeTool = { damage = 42, range = 8, cooldown = 0.75, pierce = 0.10 },
	RubyAxeTool = { damage = 44, range = 8, cooldown = 0.75, pierce = 0.10 },
	DiamondAxeTool = { damage = 46, range = 8, cooldown = 0.75, pierce = 0.10 },
	GodlyAxeTool = { damage = 52, range = 8, cooldown = 0.75, pierce = 0.10, affinity = "godly" },
	UnholyAxeTool = { damage = 52, range = 8, cooldown = 0.75, pierce = 0.10, affinity = "unholy" },

	-- Pickaxes (PvP cooldown 0.70s, mine power in MiningDefs)
	WoodPickaxeTool = { damage = 8, range = 8, cooldown = 0.70 },
	StonePickaxeTool = { damage = 10, range = 8, cooldown = 0.70 },
	CopperPickaxeTool = { damage = 12, range = 8, cooldown = 0.70 },
	IronPickaxeTool = { damage = 14, range = 8, cooldown = 0.70 },
	GoldPickaxeTool = { damage = 15, range = 8, cooldown = 0.70 },
	SapphirePickaxeTool = { damage = 16, range = 8, cooldown = 0.70 },
	EmeraldPickaxeTool = { damage = 17, range = 8, cooldown = 0.70 },
	RubyPickaxeTool = { damage = 18, range = 8, cooldown = 0.70 },
	DiamondPickaxeTool = { damage = 19, range = 8, cooldown = 0.70 },
	GodlyPickaxeTool = { damage = 22, range = 8, cooldown = 0.70, affinity = "godly" },
	UnholyPickaxeTool = { damage = 22, range = 8, cooldown = 0.70, affinity = "unholy" },

	-- Guns (damage, range, fireInterval, pierce, ammoType, magSize, reloadTime)
	PistolTool = { damage = 16, range = 80, fireInterval = 0.30, pierce = 0.15, ammoType = "PistolAmmo", magSize = 10, reloadTime = 1.4 },
	RifleTool = { damage = 14, range = 120, fireInterval = 0.12, pierce = 0.10, ammoType = "RifleAmmo", magSize = 24, reloadTime = 1.8 },
	SniperTool = { damage = 55, range = 250, fireInterval = 1.2, pierce = 0.30, ammoType = "SniperAmmo", magSize = 5, reloadTime = 2.2 },
}
