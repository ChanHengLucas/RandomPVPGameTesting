--[[
	MapDefs.lua
	Votable maps. Order defines tie-break (first in order wins).
]]

return {
	-- mapId -> { displayName, order }
	-- Add 4 maps; ensure ServerStorage.Maps has matching Models
	ForestArena = { displayName = "Forest Arena", order = 1 },
	DesertDunes = { displayName = "Desert Dunes", order = 2 },
	IceCavern = { displayName = "Ice Cavern", order = 3 },
	VolcanicRift = { displayName = "Volcanic Rift", order = 4 },
}
