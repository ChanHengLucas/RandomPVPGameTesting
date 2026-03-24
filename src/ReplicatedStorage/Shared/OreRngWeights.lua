--[[
	OreRngWeights.lua
	Time-weighted ore drop RNG for generic OreNode.
	timeRatio = currentRoundTime / 300
	rareBoost = timeRatio^1.5
	weight[ore] = baseWeight[ore] + rareBoost * rareMultiplier[ore]
]]

local baseWeights = {
	Rock = 50,
	CopperOre = 30,
	IronOre = 15,
	GoldOre = 3,
	SapphireOre = 2,
	EmeraldOre = 2,
	RubyOre = 1,
	DiamondOre = 1,
}

local rareMultipliers = {
	Rock = 0,
	CopperOre = 0,
	IronOre = 0,
	GoldOre = 12,
	SapphireOre = 10,
	EmeraldOre = 8,
	RubyOre = 6,
	DiamondOre = 5,
}

local ORE_ORDER = { "Rock", "CopperOre", "IronOre", "GoldOre", "SapphireOre", "EmeraldOre", "RubyOre", "DiamondOre" }

local function getWeights(roundTime)
	local timeRatio = math.max(0, roundTime or 0) / 300
	local rareBoost = timeRatio ^ 1.5
	local weights = {}
	local total = 0
	for _, ore in ipairs(ORE_ORDER) do
		local w = (baseWeights[ore] or 0) + rareBoost * (rareMultipliers[ore] or 0)
		weights[ore] = math.max(0, w)
		total = total + weights[ore]
	end
	return weights, total
end

local function RollOreDrop(roundTime)
	local weights, total = getWeights(roundTime)
	if total <= 0 then
		return "Rock", 1
	end
	local roll = math.random() * total
	for _, ore in ipairs(ORE_ORDER) do
		local w = weights[ore] or 0
		if roll < w then
			return ore, 1
		end
		roll = roll - w
	end
	return "Rock", 1
end

-- Debug-only: log probability snapshots at t=0, 60, 180, 300 for validation
local function LogProbabilitySnapshots()
	local times = { 0, 60, 180, 300 }
	for _, t in ipairs(times) do
		local weights, total = getWeights(t)
		local parts = {}
		for _, ore in ipairs(ORE_ORDER) do
			local w = weights[ore] or 0
			local pct = total > 0 and string.format("%.2f%%", 100 * w / total) or "0%"
			table.insert(parts, ore .. "=" .. pct)
		end
		print(string.format("[OreRngWeights] t=%d: %s", t, table.concat(parts, " ")))
	end
end

return {
	baseWeights = baseWeights,
	rareMultipliers = rareMultipliers,
	RollOreDrop = RollOreDrop,
	getWeights = getWeights,
	LogProbabilitySnapshots = LogProbabilitySnapshots,
}
