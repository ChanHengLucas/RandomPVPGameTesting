--[[
	ModeDefs.lua
	Game modes. Order: SL_FFA, SL_TDM, R_FFA, R_TDM (defines tie-break).
	First round: lastPlayedMode default = SL_TDM, so options = { SL_FFA, R_FFA, R_TDM }.
]]

return {
	SL_FFA = { displayName = "Single Life FFA", order = 1 },
	SL_TDM = { displayName = "Single Life TDM", order = 2 },
	R_FFA = { displayName = "Respawn FFA", order = 3 },
	R_TDM = { displayName = "Respawn TDM", order = 4 },
}
