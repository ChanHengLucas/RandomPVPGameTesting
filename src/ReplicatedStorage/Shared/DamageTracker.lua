--[[
	DamageTracker.lua
	Tracks last damager per Humanoid for drop attribution.
	CombatService (and GunsService) call RecordDamage before TakeDamage.
]]

local lastDamager = {}

return {
	RecordDamage = function(humanoid, attacker)
		if humanoid and attacker then
			lastDamager[humanoid] = attacker
		end
	end,
	GetKiller = function(humanoid)
		return lastDamager[humanoid]
	end,
	Clear = function(humanoid)
		lastDamager[humanoid] = nil
	end,
}
