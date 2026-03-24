--[[
	HazardDefs.lua
	Single source of truth for hazard behavior.
	Part names or tags map to hazard types.
]]

return {
	Lava = {
		damagePerSecond = 25,
		tickInterval = 0.5,
	},
	Water = {
		slowMultiplier = 0.5,
		extinguishTorch = true,
	},
	Void = {
		instantDeath = true,
	},
	Darkness = {
		overlayAlpha = 0.8,
	},
}
