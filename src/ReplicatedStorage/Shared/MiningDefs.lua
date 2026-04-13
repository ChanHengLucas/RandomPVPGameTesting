--[[
	MiningDefs.lua
	Single source of truth for ore node definitions.
	Generic OreNode: same tier for all.
	HITS_TO_BREAK: integer hits required per pickaxe tier.
]]

-- Hits required to break a node (integer per hit)
local HITS_TO_BREAK = {
	WoodPickaxeTool = 15,
	StonePickaxeTool = 12,
	CopperPickaxeTool = 11,
	IronPickaxeTool = 10,
	GoldPickaxeTool = 9,
	SapphirePickaxeTool = 8,
	EmeraldPickaxeTool = 6,
	RubyPickaxeTool = 5,
	DiamondPickaxeTool = 4,
	AngelicPickaxeTool = 3,
	DemonicPickaxeTool = 3,
}

-- Tier order for "X or better" checks (higher index = better)
local TIER_ORDER = {
	WoodPickaxeTool = 1,
	StonePickaxeTool = 2,
	CopperPickaxeTool = 3,
	IronPickaxeTool = 4,
	GoldPickaxeTool = 5,
	SapphirePickaxeTool = 6,
	EmeraldPickaxeTool = 7,
	RubyPickaxeTool = 8,
	DiamondPickaxeTool = 9,
	AngelicPickaxeTool = 10,
	DemonicPickaxeTool = 10,
}

return {
	NodeDefs = {
		OreNode = {
			respawnTime = 10,
			drops = nil, -- RNG at break
			minPickaxeTier = "WoodPickaxeTool",
		},
	},
	HitsToBreak = HITS_TO_BREAK,
	TierOrder = TIER_ORDER,
}
