--[[
	DropTables.lua
	Single source of truth for mob drop tables.
	Map mobType -> { { itemName, weight } }
	Weight: higher = more likely. Roll random; sum weights, pick.
]]

return {
	Cow = {
		{ itemName = "Leather", weight = 30 },
		{ itemName = "RawMeat", weight = 50 },
	},
	Pig = {
		{ itemName = "Leather", weight = 30 },
		{ itemName = "RawMeat", weight = 50 },
	},
	Zombie = {},
	Spider = {
		{ itemName = "String", weight = 40 },
	},
	Angel = {
		{ itemName = "GodlyOre", weight = 25 },
	},
	Demon = {
		{ itemName = "UnholyOre", weight = 25 },
	},
	Soldier = {
		{ itemName = "Pistol", weight = 5 },
		{ itemName = "PistolAmmo", weight = 20 },
		{ itemName = "RifleAmmo", weight = 15 },
	},
}
