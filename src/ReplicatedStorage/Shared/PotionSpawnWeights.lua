--[[
	PotionSpawnWeights.lua
	Weights for potion spawn selection. Regen 50, Heal 45, SuperiorityWeight(t) = 5 + (t/300)^1.5 * 15
]]

local function superiorityWeight(t)
	local timeRatio = math.min(t or 0, 300) / 300
	return 5 + (timeRatio ^ 1.5) * 15
end

return {
	RegenPotion = 50,
	HealPotion = 45,
	SuperiorityWeight = superiorityWeight,
}
