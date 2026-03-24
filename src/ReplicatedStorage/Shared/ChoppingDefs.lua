--[[
	ChoppingDefs.lua
	Tree node definitions. Generic TreeNode: same drop logic for all.
	HITS_TO_BREAK: integer hits per axe tier (like MiningDefs).
	Cadence: 0.45s. Wood [3,5] random, Apple 35%, Orange 20%. Respawn 18s per tree.
	Tree density: ~50 trees typical; forest maps more, desert maps fewer.
]]

local HITS_TO_BREAK = {
	WoodAxeTool = 10,
	StoneAxeTool = 8,
	CopperAxeTool = 7,
	IronAxeTool = 6,
	GoldAxeTool = 5,
	SapphireAxeTool = 4,
	EmeraldAxeTool = 4,
	RubyAxeTool = 3,
	DiamondAxeTool = 3,
	GodlyAxeTool = 2,
	UnholyAxeTool = 2,
}

local TIER_ORDER = {
	WoodAxeTool = 1,
	StoneAxeTool = 2,
	CopperAxeTool = 3,
	IronAxeTool = 4,
	GoldAxeTool = 5,
	SapphireAxeTool = 6,
	EmeraldAxeTool = 7,
	RubyAxeTool = 8,
	DiamondAxeTool = 9,
	GodlyAxeTool = 10,
	UnholyAxeTool = 10,
}

return {
	NodeDefs = {
		TreeNode = {
			respawnTime = 18,
			minAxeTier = "WoodAxeTool",
		},
		OakTree = { respawnTime = 18, minAxeTier = "WoodAxeTool" },
		AppleTree = { respawnTime = 18, minAxeTier = "WoodAxeTool" },
		OrangeTree = { respawnTime = 18, minAxeTier = "WoodAxeTool" },
	},
	HitsToBreak = HITS_TO_BREAK,
	TierOrder = TIER_ORDER,
}
