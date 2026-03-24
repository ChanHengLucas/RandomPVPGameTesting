--[[
	ToolStats.lua
	Single source of truth for non-combat tool stats.
	AxePower: durability damage per chop. Pickaxe power is in MiningDefs.ToolPower.
	Map ToolName -> { axePower?, pickaxePower? }
]]

return {
	-- Axes (chopping)
	WoodAxeTool = { axePower = 1 },
	StoneAxeTool = { axePower = 2 },
	CopperAxeTool = { axePower = 2 },
	IronAxeTool = { axePower = 3 },
	GoldAxeTool = { axePower = 4 },
	SapphireAxeTool = { axePower = 5 },
	EmeraldAxeTool = { axePower = 6 },
	RubyAxeTool = { axePower = 7 },
	DiamondAxeTool = { axePower = 8 },
	GodlyAxeTool = { axePower = 9 },
	UnholyAxeTool = { axePower = 9 },
}
