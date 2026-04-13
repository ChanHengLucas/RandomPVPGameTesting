--[[
	TierDefs.lua
	Single source of truth for material tier system.
	TierOrder: ascending progression. RarityWeights: for RNG drops (higher = more common).
]]

return {
	-- Tier order (ascending): 1 = lowest, 10 = Diamond. Angelic/Demonic are special (11/12).
	TierOrder = {
		Stone = 1,
		Copper = 3,
		Iron = 4,
		Gold = 5,
		Sapphire = 6,
		Emerald = 7,
		Ruby = 8,
		Diamond = 9,
		Angelic = 10,
		Demonic = 11,
	},

	-- Rarity weights for RNG drops (higher = more common)
	RarityWeights = {
		Stone = 100,
		Copper = 60,
		Iron = 40,
		Gold = 25,
		Sapphire = 15,
		Emerald = 10,
		Ruby = 8,
		Diamond = 5,
		Angelic = 1,
		Demonic = 1,
	},
}
