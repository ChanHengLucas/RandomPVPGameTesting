--[[
	PotionDefs.lua
	World-spawn potions only. Regen: +3 HP/s 20s. Heal: +45 HP instant; 10s cooldown.
	Superiority: set HP to max; +10% damage; +10% defense; +10% speed for 30s. Speed does not stack.
]]

return {
	RegenPotion = { effectId = "Regen", duration = 20 },
	HealPotion = { hp = 45, instant = true, cooldown = 10 },
	SuperiorityPotion = { effectId = "Superiority", duration = 30 },
}
