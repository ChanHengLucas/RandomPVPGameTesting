--[[
	CraftingRecipes.lua
	Single source of truth for crafting recipes.
	Map itemName -> { requires = { [material] = amount }, yields = number }
	Inventory crafting only (no station).
]]

return {
	-- Wood tier (starter tools given directly; these for crafting if needed)
	WoodSword = {
		requires = { Wood = 3, Rock = 2 },
		yields = 1,
	},
	WoodSpear = {
		requires = { Wood = 4, Rock = 1 },
		yields = 1,
	},
	-- Stone tier
	StoneAxe = {
		requires = { Rock = 2, Wood = 5 },
		yields = 1,
	},
	StoneSword = {
		requires = { Rock = 5, Wood = 2 },
		yields = 1,
	},
	StonePickaxe = {
		requires = { Rock = 3, Wood = 4 },
		yields = 1,
	},
	-- Copper tier
	CopperPickaxe = {
		requires = { CopperIngot = 3, Wood = 4 },
		yields = 1,
	},
	CopperSword = {
		requires = { CopperIngot = 5, Wood = 2 },
		yields = 1,
	},
	CopperAxe = {
		requires = { CopperIngot = 2, Wood = 5 },
		yields = 1,
	},
	CopperSpear = {
		requires = { CopperIngot = 4, Wood = 2 },
		yields = 1,
	},
	-- Iron tier
	IronPickaxe = {
		requires = { IronIngot = 3, Wood = 4 },
		yields = 1,
	},
	IronSword = {
		requires = { IronIngot = 5, Wood = 2 },
		yields = 1,
	},
	IronAxe = {
		requires = { IronIngot = 2, Wood = 5 },
		yields = 1,
	},
	IronSpear = {
		requires = { IronIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Gold tier
	GoldPickaxe = {
		requires = { GoldIngot = 3, Wood = 4 },
		yields = 1,
	},
	GoldSword = {
		requires = { GoldIngot = 5, Wood = 2 },
		yields = 1,
	},
	GoldAxe = {
		requires = { GoldIngot = 2, Wood = 5 },
		yields = 1,
	},
	GoldSpear = {
		requires = { GoldIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Sapphire tier
	SapphirePickaxe = {
		requires = { SapphireIngot = 3, Wood = 4 },
		yields = 1,
	},
	SapphireSword = {
		requires = { SapphireIngot = 5, Wood = 2 },
		yields = 1,
	},
	SapphireAxe = {
		requires = { SapphireIngot = 2, Wood = 5 },
		yields = 1,
	},
	SapphireSpear = {
		requires = { SapphireIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Emerald tier
	EmeraldPickaxe = {
		requires = { EmeraldIngot = 3, Wood = 4 },
		yields = 1,
	},
	EmeraldSword = {
		requires = { EmeraldIngot = 5, Wood = 2 },
		yields = 1,
	},
	EmeraldAxe = {
		requires = { EmeraldIngot = 2, Wood = 5 },
		yields = 1,
	},
	EmeraldSpear = {
		requires = { EmeraldIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Ruby tier
	RubyPickaxe = {
		requires = { RubyIngot = 3, Wood = 4 },
		yields = 1,
	},
	RubySword = {
		requires = { RubyIngot = 5, Wood = 2 },
		yields = 1,
	},
	RubyAxe = {
		requires = { RubyIngot = 2, Wood = 5 },
		yields = 1,
	},
	RubySpear = {
		requires = { RubyIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Diamond tier
	DiamondPickaxe = {
		requires = { DiamondIngot = 3, Wood = 4 },
		yields = 1,
	},
	DiamondSword = {
		requires = { DiamondIngot = 5, Wood = 2 },
		yields = 1,
	},
	DiamondAxe = {
		requires = { DiamondIngot = 2, Wood = 5 },
		yields = 1,
	},
	DiamondSpear = {
		requires = { DiamondIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Godly / Unholy tier
	GodlyPickaxe = {
		requires = { GodlyIngot = 3, Wood = 4 },
		yields = 1,
	},
	GodlySword = {
		requires = { GodlyIngot = 5, Wood = 2 },
		yields = 1,
	},
	GodlyAxe = {
		requires = { GodlyIngot = 2, Wood = 5 },
		yields = 1,
	},
	GodlySpear = {
		requires = { GodlyIngot = 4, Wood = 3 },
		yields = 1,
	},
	UnholyPickaxe = {
		requires = { UnholyIngot = 3, Wood = 4 },
		yields = 1,
	},
	UnholySword = {
		requires = { UnholyIngot = 5, Wood = 2 },
		yields = 1,
	},
	UnholyAxe = {
		requires = { UnholyIngot = 2, Wood = 5 },
		yields = 1,
	},
	UnholySpear = {
		requires = { UnholyIngot = 4, Wood = 3 },
		yields = 1,
	},
	-- Guns and ammo
	Pistol = {
		requires = { IronIngot = 8, String = 2 },
		yields = 1,
	},
	Rifle = {
		requires = { IronIngot = 12, GoldIngot = 2, String = 3 },
		yields = 1,
	},
	Sniper = {
		requires = { DiamondIngot = 4, GoldIngot = 4, String = 4 },
		yields = 1,
	},
	PistolAmmo = {
		requires = { IronIngot = 1 },
		yields = 10,
	},
	RifleAmmo = {
		requires = { IronIngot = 2 },
		yields = 15,
	},
	SniperAmmo = {
		requires = { IronIngot = 3, GoldIngot = 1 },
		yields = 5,
	},
	-- Misc
	Torch = {
		requires = { Wood = 2 },
		yields = 1,
	},
	Shield = {
		requires = { IronIngot = 4, Wood = 2 },
		yields = 1,
	},
	Bucket = {
		requires = { IronIngot = 3 },
		yields = 1,
	},
	-- Armor
	CopperHelmet = { requires = { CopperIngot = 4 }, yields = 1 },
	CopperChestplate = { requires = { CopperIngot = 8 }, yields = 1 },
	CopperLeggings = { requires = { CopperIngot = 6 }, yields = 1 },
	CopperBoots = { requires = { CopperIngot = 4 }, yields = 1 },
	IronHelmet = { requires = { IronIngot = 4 }, yields = 1 },
	IronChestplate = { requires = { IronIngot = 8 }, yields = 1 },
	IronLeggings = { requires = { IronIngot = 6 }, yields = 1 },
	IronBoots = { requires = { IronIngot = 4 }, yields = 1 },
	GoldHelmet = { requires = { GoldIngot = 4 }, yields = 1 },
	GoldChestplate = { requires = { GoldIngot = 8 }, yields = 1 },
	GoldLeggings = { requires = { GoldIngot = 6 }, yields = 1 },
	GoldBoots = { requires = { GoldIngot = 4 }, yields = 1 },
	SapphireHelmet = { requires = { SapphireIngot = 4 }, yields = 1 },
	SapphireChestplate = { requires = { SapphireIngot = 8 }, yields = 1 },
	SapphireLeggings = { requires = { SapphireIngot = 6 }, yields = 1 },
	SapphireBoots = { requires = { SapphireIngot = 4 }, yields = 1 },
	EmeraldHelmet = { requires = { EmeraldIngot = 4 }, yields = 1 },
	EmeraldChestplate = { requires = { EmeraldIngot = 8 }, yields = 1 },
	EmeraldLeggings = { requires = { EmeraldIngot = 6 }, yields = 1 },
	EmeraldBoots = { requires = { EmeraldIngot = 4 }, yields = 1 },
	RubyHelmet = { requires = { RubyIngot = 4 }, yields = 1 },
	RubyChestplate = { requires = { RubyIngot = 8 }, yields = 1 },
	RubyLeggings = { requires = { RubyIngot = 6 }, yields = 1 },
	RubyBoots = { requires = { RubyIngot = 4 }, yields = 1 },
	DiamondHelmet = { requires = { DiamondIngot = 4 }, yields = 1 },
	DiamondChestplate = { requires = { DiamondIngot = 8 }, yields = 1 },
	DiamondLeggings = { requires = { DiamondIngot = 6 }, yields = 1 },
	DiamondBoots = { requires = { DiamondIngot = 4 }, yields = 1 },
	GodlyHelmet = { requires = { GodlyIngot = 4 }, yields = 1 },
	GodlyChestplate = { requires = { GodlyIngot = 8 }, yields = 1 },
	GodlyLeggings = { requires = { GodlyIngot = 6 }, yields = 1 },
	GodlyBoots = { requires = { GodlyIngot = 4 }, yields = 1 },
	UnholyHelmet = { requires = { UnholyIngot = 4 }, yields = 1 },
	UnholyChestplate = { requires = { UnholyIngot = 8 }, yields = 1 },
	UnholyLeggings = { requires = { UnholyIngot = 6 }, yields = 1 },
	UnholyBoots = { requires = { UnholyIngot = 4 }, yields = 1 },
}
