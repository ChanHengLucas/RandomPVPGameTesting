--[[
	ArmorStats.lua
	Single source of truth for armor damage reduction.
	Per-tier full-set DR: Copper 10%, Iron 20%, Gold 30%, Sapphire 35%, Emerald 40%, Ruby 45%, Diamond 50%, Angelic 60%, Demonic 60%
	Piece distribution: Helmet 20%, Chest 40%, Legs 25%, Boots 15%
	affinity: "godly" | "unholy" for Angelic/Demonic multiplier in combat
]]

-- reduction = tierDR * pieceWeight; piece weights: Helmet 20%, Chest 40%, Legs 25%, Boots 15%
return {
	-- Copper 10%
	CopperHelmet = { reduction = 0.02 },
	CopperChestplate = { reduction = 0.04 },
	CopperLeggings = { reduction = 0.025 },
	CopperBoots = { reduction = 0.015 },
	-- Iron 20%
	IronHelmet = { reduction = 0.04 },
	IronChestplate = { reduction = 0.08 },
	IronLeggings = { reduction = 0.05 },
	IronBoots = { reduction = 0.03 },
	-- Gold 30%
	GoldHelmet = { reduction = 0.06 },
	GoldChestplate = { reduction = 0.12 },
	GoldLeggings = { reduction = 0.075 },
	GoldBoots = { reduction = 0.045 },
	-- Sapphire 35%
	SapphireHelmet = { reduction = 0.07 },
	SapphireChestplate = { reduction = 0.14 },
	SapphireLeggings = { reduction = 0.0875 },
	SapphireBoots = { reduction = 0.0525 },
	-- Emerald 40%
	EmeraldHelmet = { reduction = 0.08 },
	EmeraldChestplate = { reduction = 0.16 },
	EmeraldLeggings = { reduction = 0.10 },
	EmeraldBoots = { reduction = 0.06 },
	-- Ruby 45%
	RubyHelmet = { reduction = 0.09 },
	RubyChestplate = { reduction = 0.18 },
	RubyLeggings = { reduction = 0.1125 },
	RubyBoots = { reduction = 0.0675 },
	-- Diamond 50%
	DiamondHelmet = { reduction = 0.10 },
	DiamondChestplate = { reduction = 0.20 },
	DiamondLeggings = { reduction = 0.125 },
	DiamondBoots = { reduction = 0.075 },
	-- Angelic/Godly 60%
	GodlyHelmet = { reduction = 0.12, affinity = "godly" },
	GodlyChestplate = { reduction = 0.24, affinity = "godly" },
	GodlyLeggings = { reduction = 0.15, affinity = "godly" },
	GodlyBoots = { reduction = 0.09, affinity = "godly" },
	-- Demonic/Unholy 60%
	UnholyHelmet = { reduction = 0.12, affinity = "unholy" },
	UnholyChestplate = { reduction = 0.24, affinity = "unholy" },
	UnholyLeggings = { reduction = 0.15, affinity = "unholy" },
	UnholyBoots = { reduction = 0.09, affinity = "unholy" },
}
