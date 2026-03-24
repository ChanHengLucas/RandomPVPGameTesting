--[[
	TierDefs.lua
	Single source of truth for material tier system.
	TierOrder: ascending progression. RarityWeights: for RNG drops (higher = more common).
]]

return {
	-- Tier order (ascending): 1 = lowest, 10 = Diamond. Godly/Unholy are special (11/12).
	TierOrder = {
		Stone = 1,
		Copper = 3,
		Iron = 4,
		Gold = 5,
		Sapphire = 6,
		Emerald = 7,
		Ruby = 8,
		Diamond = 9,
		Godly = 10,
		Unholy = 11,
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
		Godly = 1,
		Unholy = 1,
	},
}
